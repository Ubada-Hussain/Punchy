'use client';
import { useEffect, useState } from 'react';
import { api, type Business } from '@/lib/api';

interface PunchMethodInfo {
  id: string;
  type: 'QR' | 'NFC';
  identifier: string;
  label?: string;
  isActive: boolean;
  createdAt: string;
  cardTitle: string;
  businessName: string;
  businessId: string;
}

export default function NfcQrPage() {
  const [businesses, setBusinesses] = useState<Business[]>([]);
  const [loading, setLoading] = useState(true);
  const [methods, setMethods] = useState<PunchMethodInfo[]>([]);
  const [filter, setFilter] = useState<'ALL' | 'QR' | 'NFC'>('ALL');

  useEffect(() => {
    api.get<{ businesses: Business[]; total: number }>('/businesses?status=APPROVED&limit=100')
      .then(async data => {
        setBusinesses(data.businesses);
        // Aggregate all punch methods across all businesses' cards
        const allMethods: PunchMethodInfo[] = [];
        for (const biz of data.businesses) {
          if (!biz.loyaltyCards) continue;
          for (const card of biz.loyaltyCards) {
            if (!card.punchMethods) continue;
            for (const m of card.punchMethods) {
              allMethods.push({
                ...m,
                cardTitle: card.title,
                businessName: biz.name,
                businessId: biz.id,
              });
            }
          }
        }
        setMethods(allMethods);
      })
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  const filtered = methods.filter(m => filter === 'ALL' || m.type === filter);
  const qrCount  = methods.filter(m => m.type === 'QR').length;
  const nfcCount = methods.filter(m => m.type === 'NFC').length;
  const activeCount = methods.filter(m => m.isActive).length;

  return (
    <div className="page-content">
      <div className="page-header">
        <h1 className="page-title">NFC & QR Management</h1>
        <p className="page-subtitle">Track all punch identifiers across the platform</p>
      </div>

      <div className="kpi-grid" style={{ gridTemplateColumns: 'repeat(3, 1fr)', marginBottom: 24 }}>
        <div className="kpi-card" style={{ '--kpi-color': '#2563EB', '--kpi-bg': 'rgba(37,99,235,0.1)' } as React.CSSProperties}>
          <div className="kpi-icon">📱</div>
          <div className="kpi-label">QR Codes</div>
          <div className="kpi-value">{qrCount}</div>
        </div>
        <div className="kpi-card" style={{ '--kpi-color': '#7C3AED', '--kpi-bg': 'rgba(124,58,237,0.1)' } as React.CSSProperties}>
          <div className="kpi-icon">📲</div>
          <div className="kpi-label">NFC Tags</div>
          <div className="kpi-value">{nfcCount}</div>
        </div>
        <div className="kpi-card" style={{ '--kpi-color': '#16A34A', '--kpi-bg': 'rgba(22,163,74,0.1)' } as React.CSSProperties}>
          <div className="kpi-icon">✅</div>
          <div className="kpi-label">Active Methods</div>
          <div className="kpi-value">{activeCount}</div>
        </div>
      </div>

      <div className="flex gap-2 mb-5">
        {(['ALL', 'QR', 'NFC'] as const).map(f => (
          <button key={f} onClick={() => setFilter(f)} className={`btn btn-sm ${filter === f ? 'btn-primary' : 'btn-secondary'}`}>
            {f === 'ALL' ? 'All Methods' : f}
          </button>
        ))}
      </div>

      <div className="table-container">
        {loading ? (
          <div className="loading-page"><div className="loading-spinner" /></div>
        ) : filtered.length === 0 ? (
          <div className="empty-state">
            <div className="empty-state-icon">📲</div>
            <div className="empty-state-title">No punch methods found</div>
          </div>
        ) : (
          <table className="data-table">
            <thead>
              <tr><th>Type</th><th>Business</th><th>Card</th><th>Identifier</th><th>Status</th><th>Created</th></tr>
            </thead>
            <tbody>
              {filtered.map(m => (
                <tr key={m.id}>
                  <td><span className={`badge badge-${m.type.toLowerCase()}`}>{m.type}</span></td>
                  <td>
                    <a href={`/businesses/${m.businessId}`} style={{ color: '#FF6B35', fontWeight: 500 }}>{m.businessName}</a>
                  </td>
                  <td><span className="text-sm">{m.cardTitle}</span></td>
                  <td>
                    <code style={{ fontSize: 11, color: '#6B6B66', background: '#F5F5F3', padding: '2px 6px', borderRadius: 4 }}>
                      {m.identifier}
                    </code>
                  </td>
                  <td>
                    <span className={`badge badge-${m.isActive ? 'active' : 'suspended'}`}>
                      {m.isActive ? 'Active' : 'Inactive'}
                    </span>
                  </td>
                  <td><span className="text-sm text-muted">{new Date(m.createdAt).toLocaleDateString()}</span></td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}
