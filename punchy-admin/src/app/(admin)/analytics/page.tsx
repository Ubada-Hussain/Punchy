'use client';
import { useEffect, useState } from 'react';
import { api, type PlatformAnalytics } from '@/lib/api';

export default function AnalyticsPage() {
  const [analytics, setAnalytics] = useState<PlatformAnalytics | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get<PlatformAnalytics>('/analytics/platform')
      .then(setAnalytics)
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  if (loading) return (
    <div className="admin-content">
      <div className="loading-page"><div className="loading-spinner"/><span>Loading analytics…</span></div>
    </div>
  );

  const t = analytics?.totals;
  const p = analytics?.period;

  return (
    <>
      <div className="admin-topbar">
        <h3>Analytics</h3>
        <div className="top-actions">
          <button className="btn btn-outline btn-xs">Export CSV</button>
        </div>
      </div>
      <div className="admin-content">
        <div className="astat-row">
          <div className="astat">
            <span>Punches ({p?.days || 30}d)</span>
            <b>{p?.recentPunches?.toLocaleString() ?? 0}</b>
          </div>
          <div className="astat">
            <span>New Signups ({p?.days || 30}d)</span>
            <b>{p?.newCustomers?.toLocaleString() ?? 0}</b>
          </div>
          <div className="astat">
            <span>Redemption Rate</span>
            <b>
              {t?.totalPunches && t.totalPunches > 0
                ? Math.round((t.totalRedemptions / t.totalPunches) * 100) + '%'
                : '0%'}
            </b>
          </div>
        </div>

        <div className="panel">
          <div className="panel-head"><h4>Signups — last 7 weeks</h4></div>
          <div className="bar-chart">
            {/* Dummy data for chart visual */}
            <div className="bar-col"><div className="bar" style={{ height:'38%' }}/> <span className="bar-lbl">W1</span></div>
            <div className="bar-col"><div className="bar" style={{ height:'52%' }}/> <span className="bar-lbl">W2</span></div>
            <div className="bar-col"><div className="bar" style={{ height:'46%' }}/> <span className="bar-lbl">W3</span></div>
            <div className="bar-col"><div className="bar" style={{ height:'68%' }}/> <span className="bar-lbl">W4</span></div>
            <div className="bar-col"><div className="bar" style={{ height:'60%' }}/> <span className="bar-lbl">W5</span></div>
            <div className="bar-col"><div className="bar" style={{ height:'82%' }}/> <span className="bar-lbl">W6</span></div>
            <div className="bar-col"><div className="bar" style={{ height:'100%', background:'var(--grad-coral)' }}/> <span className="bar-lbl">W7</span></div>
          </div>
        </div>

        <div className="panel">
          <div className="panel-head"><h4>Top Businesses by Punch Volume</h4></div>
          <div style={{ display:'flex', flexDirection:'column', gap:10 }}>
            {analytics?.topBusinesses.length === 0 ? (
              <p style={{ color:'var(--ink-faint)', fontSize:13 }}>No punch data available yet.</p>
            ) : (
              analytics?.topBusinesses.map((b, i, arr) => {
                const max = arr[0].totalPunches;
                const pct = max > 0 ? (b.totalPunches / max) * 100 : 0;
                return (
                  <div key={b.id} className="hbar-row">
                    <div className="hbar-name">{b.name}</div>
                    <div className="hbar-track">
                      <div className="hbar-fill" style={{ width: `${Math.max(2, pct)}%` }} />
                    </div>
                    <div className="hbar-val">{b.totalPunches.toLocaleString()}</div>
                  </div>
                );
              })
            )}
          </div>
        </div>
      </div>
    </>
  );
}
