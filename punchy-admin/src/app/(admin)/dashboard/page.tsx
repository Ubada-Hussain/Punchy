'use client';

import Link from 'next/link';
import { useEffect, useState } from 'react';
import { api } from '@/lib/api';

type Overview = {
  generatedAt: string;
  customers: { total: number; active: number; new: number; suspended: number };
  businesses: { total: number };
  subscriptions: { active: number; trialing: number; expired: number; upcomingExpirations: number };
  payments: { pending: number; approved: number; rejected: number; revenueByCurrency: { currency: string; amount: number }[] };
  support: { open: number };
  trends: { key: string; label: string; customers: number; revenue: number }[];
  distributions: { plans: { label: string; value: number }[]; countries: { label: string; value: number }[] };
  recentActions: { id: string; action: string; metadata: unknown; createdAt: string; user: { email: string; role: string } }[];
};

const number = (value: number) => value.toLocaleString();
const label = (value: string) => value.toLowerCase().replaceAll('_', ' ').replace(/\b\w/g, char => char.toUpperCase());

function Metric({ title, value, note, tone }: { title: string; value: number; note?: string; tone?: 'warn' | 'danger' }) {
  return <div className={`metric-card ${tone ? `metric-${tone}` : ''}`}><span>{title}</span><b>{number(value)}</b>{note && <small>{note}</small>}</div>;
}

function Distribution({ title, rows }: { title: string; rows: { label: string; value: number }[] }) {
  const max = Math.max(...rows.map(row => row.value), 1);
  return <div className="panel"><div className="panel-head"><h4>{title}</h4></div><div className="distribution-list">
    {rows.length === 0 && <div className="inline-empty">No data yet</div>}
    {rows.map(row => <div className="distribution-row" key={row.label}><div><b>{label(row.label)}</b><span>{number(row.value)}</span></div><div className="distribution-track"><i style={{ width: `${Math.max(4, row.value / max * 100)}%` }} /></div></div>)}
  </div></div>;
}

export default function DashboardPage() {
  const [data, setData] = useState<Overview | null>(null);
  const [error, setError] = useState('');
  useEffect(() => { api.get<Overview>('/admin/overview').then(setData).catch(err => setError(err instanceof Error ? err.message : 'Unable to load dashboard')); }, []);

  if (error) return <><div className="admin-topbar"><h3>Dashboard</h3></div><div className="admin-content"><div className="error-state"><b>Dashboard unavailable</b><span>{error}</span><button className="btn btn-outline" onClick={() => location.reload()}>Try again</button></div></div></>;
  if (!data) return <div className="admin-content"><div className="loading-page"><div className="loading-spinner"/><span>Loading live platform data…</span></div></div>;
  const maxCustomers = Math.max(...data.trends.map(item => item.customers), 1);
  const revenueText = data.payments.revenueByCurrency.map(row => `${row.currency} ${number(row.amount)}`).join(' · ') || 'No approved revenue';

  return <>
    <div className="admin-topbar"><div><h3>Dashboard</h3><span className="topbar-subtitle">Live operational overview</span></div><div className="dashboard-updated">Updated {new Date(data.generatedAt).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</div></div>
    <div className="admin-content">
      <section className="dashboard-section"><div className="section-title"><div><span className="section-kicker">Customers</span><h2>Customer health</h2></div><Link href="/customers" className="btn btn-ghost">View customers →</Link></div><div className="metric-grid metric-grid-4">
        <Metric title="Total customers" value={data.customers.total} />
        <Metric title="Active customers" value={data.customers.active} />
        <Metric title="New · 30 days" value={data.customers.new} />
        <Metric title="Suspended" value={data.customers.suspended} tone={data.customers.suspended ? 'warn' : undefined} />
      </div></section>

      <section className="dashboard-section"><div className="section-title"><div><span className="section-kicker">Subscriptions & payments</span><h2>Revenue operations</h2></div><Link href="/payment-submissions" className="btn btn-ghost">Review payments →</Link></div><div className="metric-grid metric-grid-4">
        <Metric title="Active subscriptions" value={data.subscriptions.active} />
        <Metric title="Trials" value={data.subscriptions.trialing} />
        <Metric title="Expiring · 30 days" value={data.subscriptions.upcomingExpirations} tone={data.subscriptions.upcomingExpirations ? 'warn' : undefined} />
        <Metric title="Expired" value={data.subscriptions.expired} />
        <Metric title="Pending payments" value={data.payments.pending} tone={data.payments.pending ? 'warn' : undefined} />
        <Metric title="Approved payments" value={data.payments.approved} note={revenueText} />
        <Metric title="Rejected payments" value={data.payments.rejected} />
        <Metric title="Open support tickets" value={data.support.open} tone={data.support.open ? 'warn' : undefined} />
      </div></section>

      <div className="dashboard-main-grid">
        <div className="panel trend-panel"><div className="panel-head"><div><span className="section-kicker">Six-month view</span><h4>Customer growth</h4></div><span className="panel-note">New registrations by month</span></div><div className="trend-chart">
          {data.trends.map(item => <div className="trend-column" key={item.key}><span>{item.customers}</span><div><i style={{ height: `${Math.max(5, item.customers / maxCustomers * 100)}%` }} /></div><small>{item.label}</small></div>)}
        </div></div>
        <Distribution title="Plan distribution" rows={data.distributions.plans} />
        <Distribution title="Country distribution" rows={data.distributions.countries} />
      </div>

      <div className="panel"><div className="panel-head"><div><span className="section-kicker">Audit trail</span><h4>Recent platform actions</h4></div><Link href="/audit-log" className="btn btn-ghost">Full audit log →</Link></div>
        {data.recentActions.length === 0 ? <div className="inline-empty">No recorded activity yet</div> : <div className="activity-list">{data.recentActions.map(event => <div className="activity-item" key={event.id}><div className="activity-mark"/><div><b>{label(event.action)}</b><span>{event.user.email} · {event.user.role}</span></div><time>{new Date(event.createdAt).toLocaleString()}</time></div>)}</div>}
      </div>
    </div>
  </>;
}
