'use client';
import { useEffect, useState } from 'react';
import Link from 'next/link';
import { api, type PlatformAnalytics, type Business, type SupportTicket } from '@/lib/api';

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

  if (loading) return (
    <div className="page-content">
      <div className="loading-page">
        <div className="loading-spinner" style={{ width: 32, height: 32, borderWidth: 3 }} />
        <span>Loading dashboard…</span>
      </div>
    </div>
  );

  const t = analytics?.totals;
  const p = analytics?.period;

  return (
    <div className="page-content">
      <div className="page-header">
        <h1 className="page-title">Dashboard</h1>
        <p className="page-subtitle">Platform overview — last 30 days</p>
      </div>

      {/* KPI Cards */}
      <div className="kpi-grid">
        <div className="kpi-card" style={{ '--kpi-color': '#FF6B35', '--kpi-bg': 'rgba(255,107,53,0.1)' } as React.CSSProperties}>
          <div className="kpi-icon">🏪</div>
          <div className="kpi-label">Total Businesses</div>
          <div className="kpi-value">{t?.totalBusinesses ?? '—'}</div>
          <div className="kpi-trend up">↑ {p?.newBusinesses} this period</div>
        </div>
        <div className="kpi-card" style={{ '--kpi-color': '#0D9488', '--kpi-bg': 'rgba(13,148,136,0.1)' } as React.CSSProperties}>
          <div className="kpi-icon">👥</div>
          <div className="kpi-label">Total Customers</div>
          <div className="kpi-value">{t?.totalCustomers ?? '—'}</div>
          <div className="kpi-trend up">↑ {p?.newCustomers} this period</div>
        </div>
        <div className="kpi-card" style={{ '--kpi-color': '#7C3AED', '--kpi-bg': 'rgba(124,58,237,0.1)' } as React.CSSProperties}>
          <div className="kpi-icon">👊</div>
          <div className="kpi-label">Total Punches</div>
          <div className="kpi-value">{t?.totalPunches?.toLocaleString() ?? '—'}</div>
          <div className="kpi-trend up">↑ {p?.recentPunches} this period</div>
        </div>
        <div className="kpi-card" style={{ '--kpi-color': '#D97706', '--kpi-bg': 'rgba(217,119,6,0.1)' } as React.CSSProperties}>
          <div className="kpi-icon">🎁</div>
          <div className="kpi-label">Rewards Redeemed</div>
          <div className="kpi-value">{t?.totalRedemptions ?? '—'}</div>
          <div className="kpi-trend neutral">all time</div>
        </div>
        {(t?.pendingBusinesses ?? 0) > 0 && (
          <div className="kpi-card" style={{ '--kpi-color': '#DC2626', '--kpi-bg': 'rgba(220,38,38,0.1)' } as React.CSSProperties}>
            <div className="kpi-icon">⏳</div>
            <div className="kpi-label">Awaiting Approval</div>
            <div className="kpi-value">{t?.pendingBusinesses}</div>
            <Link href="/businesses?status=PENDING" className="kpi-trend" style={{ color: '#DC2626', textDecoration: 'none' }}>
              Review now →
            </Link>
          </div>
        )}
      </div>

      <div className="grid-2">
        {/* Pending Businesses */}
        <div>
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold">Pending Approvals</h2>
            <Link href="/businesses?status=PENDING" className="btn btn-ghost btn-sm">View all</Link>
          </div>
          <div className="table-container">
            {pending.length === 0 ? (
              <div className="empty-state">
                <div className="empty-state-icon">✅</div>
                <div className="empty-state-title">All clear!</div>
                <p>No businesses awaiting approval.</p>
              </div>
            ) : (
              <table className="data-table">
                <thead><tr><th>Business</th><th>Category</th><th>Action</th></tr></thead>
                <tbody>
                  {pending.map(b => (
                    <tr key={b.id}>
                      <td>
                        <div className="flex items-center gap-3">
                          <div className="avatar avatar-sm">{b.name[0]}</div>
                          <div>
                            <div className="font-medium">{b.name}</div>
                            <div className="text-xs text-muted">{b.user?.email}</div>
                          </div>
                        </div>
                      </td>
                      <td><span className="text-sm text-muted">{b.category}</span></td>
                      <td>
                        <Link href={`/businesses/${b.id}`} className="btn btn-secondary btn-sm">Review</Link>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>

        {/* Open Tickets */}
        <div>
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold">Open Support Tickets</h2>
            <Link href="/support" className="btn btn-ghost btn-sm">View all</Link>
          </div>
          <div className="table-container">
            {tickets.length === 0 ? (
              <div className="empty-state">
                <div className="empty-state-icon">🎫</div>
                <div className="empty-state-title">No open tickets</div>
                <p>Everything is resolved!</p>
              </div>
            ) : (
              <table className="data-table">
                <thead><tr><th>Subject</th><th>From</th><th>Action</th></tr></thead>
                <tbody>
                  {tickets.map(ticket => (
                    <tr key={ticket.id}>
                      <td>
                        <div className="font-medium truncate" style={{ maxWidth: 180 }}>{ticket.subject}</div>
                        <div className="text-xs text-muted">{new Date(ticket.createdAt).toLocaleDateString()}</div>
                      </td>
                      <td><span className="text-sm text-muted">{ticket.author?.email}</span></td>
                      <td>
                        <Link href={`/support/${ticket.id}`} className="btn btn-secondary btn-sm">View</Link>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>
      </div>

      {/* Top Businesses */}
      {(analytics?.topBusinesses?.length ?? 0) > 0 && (
        <div className="mt-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="text-lg font-semibold">Most Active Businesses</h2>
            <Link href="/analytics" className="btn btn-ghost btn-sm">Full analytics</Link>
          </div>
          <div className="table-container">
            <table className="data-table">
              <thead>
                <tr><th>#</th><th>Business</th><th>Category</th><th>Total Punches</th></tr>
              </thead>
              <tbody>
                {analytics?.topBusinesses.map((b, i) => (
                  <tr key={b.id}>
                    <td><span className="text-muted font-medium">#{i + 1}</span></td>
                    <td>
                      <div className="flex items-center gap-3">
                        <div className="avatar avatar-sm">{b.name[0]}</div>
                        <Link href={`/businesses/${b.id}`} className="font-medium" style={{ color: '#FF6B35' }}>{b.name}</Link>
                      </div>
                    </td>
                    <td><span className="text-sm text-muted">{b.category}</span></td>
                    <td><span className="font-semibold">{b.totalPunches.toLocaleString()}</span></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}
