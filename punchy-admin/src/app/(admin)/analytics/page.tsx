'use client';
import { useEffect, useState } from 'react';
import { api, type PlatformAnalytics } from '@/lib/api';

export default function AnalyticsPage() {
  const [data, setData] = useState<PlatformAnalytics | null>(null);
  const [period, setPeriod] = useState(30);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    api.get<PlatformAnalytics>(`/analytics/platform?period=${period}`)
      .then(setData)
      .catch(console.error)
      .finally(() => setLoading(false));
  }, [period]);

  return (
    <div className="page-content">
      <div className="page-header flex items-center justify-between">
        <div>
          <h1 className="page-title">Analytics</h1>
          <p className="page-subtitle">Platform-wide performance overview</p>
        </div>
        <div className="flex gap-2">
          {[7, 30, 90].map(d => (
            <button key={d} onClick={() => setPeriod(d)} className={`btn btn-sm ${period === d ? 'btn-primary' : 'btn-secondary'}`}>
              {d}d
            </button>
          ))}
        </div>
      </div>

      {loading ? (
        <div className="loading-page"><div className="loading-spinner" style={{ width: 32, height: 32, borderWidth: 3 }} /></div>
      ) : !data ? null : (
        <>
          {/* Totals */}
          <div className="kpi-grid">
            {[
              { label: 'Total Businesses', value: data.totals.totalBusinesses, icon: '🏪', color: '#FF6B35', bg: 'rgba(255,107,53,0.1)', sub: `${data.period.newBusinesses} new this period` },
              { label: 'Total Customers', value: data.totals.totalCustomers, icon: '👥', color: '#0D9488', bg: 'rgba(13,148,136,0.1)', sub: `${data.period.newCustomers} new this period` },
              { label: 'Total Punches', value: data.totals.totalPunches.toLocaleString(), icon: '👊', color: '#7C3AED', bg: 'rgba(124,58,237,0.1)', sub: `${data.period.recentPunches.toLocaleString()} this period` },
              { label: 'Rewards Redeemed', value: data.totals.totalRedemptions, icon: '🎁', color: '#D97706', bg: 'rgba(217,119,6,0.1)', sub: 'all time' },
              { label: 'Pending Approvals', value: data.totals.pendingBusinesses, icon: '⏳', color: '#DC2626', bg: 'rgba(220,38,38,0.1)', sub: 'awaiting review' },
            ].map(k => (
              <div key={k.label} className="kpi-card" style={{ '--kpi-color': k.color, '--kpi-bg': k.bg } as React.CSSProperties}>
                <div className="kpi-icon">{k.icon}</div>
                <div className="kpi-label">{k.label}</div>
                <div className="kpi-value">{k.value}</div>
                <div className="kpi-trend neutral">{k.sub}</div>
              </div>
            ))}
          </div>

          {/* Top Businesses */}
          <div className="mt-6">
            <h2 className="text-lg font-semibold mb-4">Top Businesses by Punch Volume</h2>
            <div className="table-container">
              <table className="data-table">
                <thead><tr><th>Rank</th><th>Business</th><th>Category</th><th>Total Punches</th><th></th></tr></thead>
                <tbody>
                  {data.topBusinesses.map((b, i) => (
                    <tr key={b.id}>
                      <td>
                        <span style={{
                          width: 28, height: 28, borderRadius: '50%',
                          background: i === 0 ? '#FEF9C3' : i === 1 ? '#F0F0EE' : i === 2 ? '#FEF0E6' : 'transparent',
                          display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
                          fontWeight: 700, fontSize: 13,
                          color: i === 0 ? '#B45309' : i === 1 ? '#6B7280' : i === 2 ? '#C2410C' : '#6B6B66',
                        }}>
                          {i === 0 ? '🥇' : i === 1 ? '🥈' : i === 2 ? '🥉' : `#${i + 1}`}
                        </span>
                      </td>
                      <td>
                        <div className="flex items-center gap-3">
                          <div className="avatar avatar-sm">{b.name[0]}</div>
                          <span className="font-medium">{b.name}</span>
                        </div>
                      </td>
                      <td><span className="text-sm text-muted">{b.category}</span></td>
                      <td>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                          <span className="font-bold text-lg">{b.totalPunches.toLocaleString()}</span>
                          <div style={{ width: 100, height: 6, background: '#F0F0EE', borderRadius: 3, overflow: 'hidden' }}>
                            <div style={{
                              height: '100%',
                              width: `${data.topBusinesses[0].totalPunches > 0 ? (b.totalPunches / data.topBusinesses[0].totalPunches) * 100 : 0}%`,
                              background: '#FF6B35',
                              borderRadius: 3,
                            }} />
                          </div>
                        </div>
                      </td>
                      <td>
                        <a href={`/businesses/${b.id}`} className="btn btn-ghost btn-sm">View →</a>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </>
      )}
    </div>
  );
}
