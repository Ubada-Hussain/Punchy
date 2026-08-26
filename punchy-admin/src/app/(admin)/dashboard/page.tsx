'use client';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import { api, type PlatformAnalytics, type Business, type SupportTicket } from '@/lib/api';

function SearchIcon() {
  return (
    <svg width="14" height="14" viewBox="0 0 24 24" style={{ stroke:'var(--ink-faint)', fill:'none', strokeWidth:1.8, strokeLinecap:'round' }}>
      <circle cx="11" cy="11" r="6.5"/><path d="M20 20l-4.5-4.5"/>
    </svg>
  );
}
function BellIcon() {
  return (
    <svg width="16" height="16" viewBox="0 0 24 24" style={{ stroke:'currentColor', fill:'none', strokeWidth:1.8, strokeLinecap:'round', strokeLinejoin:'round' }}>
      <path d="M6 9a6 6 0 0 1 12 0c0 4 1.5 5.5 1.5 5.5H4.5S6 13 6 9Z"/><path d="M9.5 19a2.5 2.5 0 0 0 5 0"/>
    </svg>
  );
}

function statusBadge(s: string) {
  const map: Record<string, string> = {
    APPROVED: 'b-active', ACTIVE: 'b-active',
    PENDING: 'b-pending',
    SUSPENDED: 'b-suspended',
    OPEN: 'b-open',
    IN_PROGRESS: 'b-progress',
    RESOLVED: 'b-resolved',
  };
  return <span className={`badge ${map[s] ?? 'b-pending'}`}>{s.replace('_', ' ')}</span>;
}

export default function DashboardPage() {
  const [analytics, setAnalytics] = useState<PlatformAnalytics | null>(null);
  const [pending, setPending] = useState<Business[]>([]);
  const [tickets, setTickets] = useState<SupportTicket[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    Promise.all([
      api.get<PlatformAnalytics>('/analytics/platform'),
      api.get<{ businesses: Business[] }>('/businesses?status=PENDING&limit=5'),
      api.get<{ tickets: SupportTicket[] }>('/tickets?status=OPEN&limit=5'),
    ]).then(([a, b, t]) => {
      setAnalytics(a);
      setPending(b.businesses);
      setTickets(t.tickets);
    }).catch(console.error).finally(() => setLoading(false));
  }, []);

  async function approve(id: string) {
    await api.patch(`/businesses/${id}`, { status: 'APPROVED' });
    setPending(p => p.filter(b => b.id !== id));
  }

  if (loading) return (
    <div className="admin-content">
      <div className="loading-page"><div className="loading-spinner"/><span>Loading dashboard…</span></div>
    </div>
  );

  const t = analytics?.totals;
  const p = analytics?.period;

  return (
    <>
      <div className="admin-topbar">
        <h3>Dashboard</h3>
        <div className="top-actions">
          <div className="top-search"><SearchIcon/>Search platform…</div>
          <button className="top-icon"><BellIcon/></button>
        </div>
      </div>
      <div className="admin-content">
        {/* Stats */}
        <div className="astat-row">
          <div className="astat">
            <span>Total Businesses</span>
            <b>{t?.totalBusinesses?.toLocaleString() ?? '—'}
              {p && <em>+{p.newBusinesses} this wk</em>}
            </b>
          </div>
          <div className="astat">
            <span>Total Customers</span>
            <b>{t?.totalCustomers?.toLocaleString() ?? '—'}
              {p && <em>+{p.newCustomers} this wk</em>}
            </b>
          </div>
          <div className="astat">
            <span>Total Punches</span>
            <b>{t?.totalPunches?.toLocaleString() ?? '—'}</b>
          </div>
          <div className="astat">
            <span>Redemptions</span>
            <b>{t?.totalRedemptions?.toLocaleString() ?? '—'}</b>
          </div>
        </div>

        {/* Two columns */}
        <div className="two-col">
          {/* Pending Businesses */}
          <div className="panel">
            <div className="panel-head">
              <h4>Pending Businesses</h4>
              <Link href="/businesses" className="btn-ghost btn" style={{ fontSize:12 }}>View all →</Link>
            </div>
            {pending.length === 0 ? (
              <div className="empty-state"><span className="empty-state-icon">✅</span>No pending businesses</div>
            ) : (
              <table className="atable">
                <thead><tr><th>Business</th><th>Category</th><th></th></tr></thead>
                <tbody>
                  {pending.map(b => (
                    <tr key={b.id}>
                      <td>
                        <div className="row-biz">
                          <div className="row-logo" style={{ background:'var(--grad-teal)', color:'#fff' }}>{b.logo || b.name[0]}</div>
                          <div className="row-name">{b.name}</div>
                        </div>
                      </td>
                      <td style={{ color:'var(--ink-soft)', fontSize:12 }}>{b.category}</td>
                      <td>
                        <div style={{ display:'flex', gap:6 }}>
                          <button className="btn btn-primary btn-xs" onClick={() => approve(b.id)}>Approve</button>
                          <Link href={`/businesses/${b.id}`} className="btn btn-outline btn-xs">View</Link>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>

          {/* Open Tickets */}
          <div className="panel">
            <div className="panel-head">
              <h4>Open Support Tickets</h4>
              <Link href="/support" className="btn-ghost btn" style={{ fontSize:12 }}>View all →</Link>
            </div>
            {tickets.length === 0 ? (
              <div className="empty-state"><span className="empty-state-icon">🎫</span>No open tickets</div>
            ) : (
              <table className="atable">
                <thead><tr><th>User</th><th>Subject</th><th>Status</th></tr></thead>
                <tbody>
                  {tickets.map(tk => (
                    <tr key={tk.id}>
                      <td className="row-name">{tk.author?.email?.split('@')[0] ?? 'User'}</td>
                      <td className="row-sub">{tk.subject}</td>
                      <td>{statusBadge(tk.status)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>

        {/* Quick Actions */}
        <div className="panel">
          <div className="panel-head"><h4>Quick Actions</h4></div>
          <div style={{ display:'flex', gap:10, flexWrap:'wrap' }}>
            <Link href="/businesses?status=PENDING" className="btn btn-outline btn-xs">
              <svg width="14" height="14" viewBox="0 0 24 24" style={{ stroke:'currentColor', fill:'none', strokeWidth:1.8, strokeLinecap:'round', strokeLinejoin:'round' }}><path d="M4 9l1-4h14l1 4"/><path d="M4 9a2.2 2.2 0 0 0 4.4.2A2.2 2.2 0 0 0 12 9a2.2 2.2 0 0 0 3.6.2A2.2 2.2 0 0 0 20 9"/><path d="M5 9v9a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V9"/></svg>
              Approve Businesses
            </Link>
            <Link href="/analytics" className="btn btn-outline btn-xs">
              <svg width="14" height="14" viewBox="0 0 24 24" style={{ stroke:'currentColor', fill:'none', strokeWidth:1.8, strokeLinecap:'round', strokeLinejoin:'round' }}><path d="M4 20V10M10 20V4M16 20v-7M20 20H4"/></svg>
              View Analytics
            </Link>
            <Link href="/notifications" className="btn btn-outline btn-xs">
              <svg width="14" height="14" viewBox="0 0 24 24" style={{ stroke:'currentColor', fill:'none', strokeWidth:1.8, strokeLinecap:'round', strokeLinejoin:'round' }}><path d="M6 9a6 6 0 0 1 12 0c0 4 1.5 5.5 1.5 5.5H4.5S6 13 6 9Z"/><path d="M9.5 19a2.5 2.5 0 0 0 5 0"/></svg>
              Send Notification
            </Link>
            <Link href="/support" className="btn btn-outline btn-xs">
              <svg width="14" height="14" viewBox="0 0 24 24" style={{ stroke:'currentColor', fill:'none', strokeWidth:1.8, strokeLinecap:'round', strokeLinejoin:'round' }}><path d="M3 9a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v1.5a1.6 1.6 0 0 0 0 3V16a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-2.5a1.6 1.6 0 0 0 0-3Z"/><path d="M14 7v10" strokeDasharray="2 2"/></svg>
              Support Tickets
            </Link>
          </div>
        </div>
      </div>
    </>
  );
}
