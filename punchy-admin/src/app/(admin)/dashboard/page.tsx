'use client';
import { useEffect, useState } from 'react';
import { api, type PlatformAnalytics } from '@/lib/api';

function SearchIcon() { return <svg width="14" height="14" viewBox="0 0 24 24" style={{ stroke:'var(--ink-faint)', fill:'none', strokeWidth:1.8, strokeLinecap:'round' }}><circle cx="11" cy="11" r="6.5"/><path d="M20 20l-4.5-4.5"/></svg>; }
function BellIcon() { return <svg width="16" height="16" viewBox="0 0 24 24" style={{ stroke:'currentColor', fill:'none', strokeWidth:1.8, strokeLinecap:'round', strokeLinejoin:'round' }}><path d="M6 9a6 6 0 0 1 12 0c0 4 1.5 5.5 1.5 5.5H4.5S6 13 6 9Z"/><path d="M9.5 19a2.5 2.5 0 0 0 5 0"/></svg>; }

export default function DashboardPage() {
  const [analytics, setAnalytics] = useState<PlatformAnalytics | null>(null);
  const [loading, setLoading] = useState(true);
  useEffect(() => { api.get<PlatformAnalytics>('/analytics/platform').then(setAnalytics).catch(console.error).finally(() => setLoading(false)); }, []);
  if (loading) return <div className="admin-content"><div className="loading-page"><div className="loading-spinner"/><span>Loading dashboard…</span></div></div>;
  const t = analytics?.totals; const p = analytics?.period;
  return <>
    <div className="admin-topbar"><h3>Dashboard</h3><div className="top-actions"><div className="top-search"><SearchIcon/>Search platform…</div><button className="top-icon"><BellIcon/></button></div></div>
    <div className="admin-content"><div className="astat-row">
      <div className="astat"><span>Total Businesses</span><b>{t?.totalBusinesses?.toLocaleString() ?? '—'}{p && <em>+{p.newBusinesses} this wk</em>}</b></div>
      <div className="astat"><span>Total Customers</span><b>{t?.totalCustomers?.toLocaleString() ?? '—'}{p && <em>+{p.newCustomers} this wk</em>}</b></div>
      <div className="astat"><span>Total Punches</span><b>{t?.totalPunches?.toLocaleString() ?? '—'}</b></div>
      <div className="astat"><span>Redemptions</span><b>{t?.totalRedemptions?.toLocaleString() ?? '—'}</b></div>
    </div></div>
  </>;
}
