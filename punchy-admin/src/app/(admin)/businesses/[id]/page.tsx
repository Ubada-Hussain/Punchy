'use client';
import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import { api, type Business } from '@/lib/api';

export default function BusinessDetailPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const [business, setBusiness] = useState<Business | null>(null);
  const [loading, setLoading] = useState(true);
  const [actioning, setActioning] = useState(false);
  const [analytics, setAnalytics] = useState<{ totals: { totalCustomers: number; totalPunches: number; totalRedemptions: number } } | null>(null);

  useEffect(() => {
    Promise.all([
      api.get<Business>(`/businesses/${id}`),
      api.get<{ totals: { totalCustomers: number; totalPunches: number; totalRedemptions: number } }>(`/analytics/business/${id}`),
    ]).then(([b, a]) => {
      setBusiness(b);
      setAnalytics(a);
    }).catch(console.error).finally(() => setLoading(false));
  }, [id]);

  async function handleAction(action: 'approve' | 'suspend') {
    if (action === 'suspend' && !confirm('Suspend this business? They will be unable to accept punches.')) return;
    setActioning(true);
    try {
      const updated = await api.post<Business>(`/businesses/${id}/${action}`);
      setBusiness(updated);
    } catch (err) { console.error(err); }
    finally { setActioning(false); }
  }

  if (loading) return (
    <div className="page-content">
      <div className="loading-page"><div className="loading-spinner" style={{ width: 32, height: 32, borderWidth: 3 }} /></div>
    </div>
  );

  if (!business) return (
    <div className="page-content">
      <div className="empty-state"><div className="empty-state-title">Business not found</div></div>
    </div>
  );

  return (
    <div className="page-content">
      {/* Breadcrumb */}
      <div className="flex items-center gap-2 text-sm text-muted mb-6">
        <Link href="/businesses" style={{ color: '#FF6B35' }}>Businesses</Link>
        <span>›</span>
        <span>{business.name}</span>
      </div>

      {/* Header */}
      <div className="flex items-start justify-between mb-6">
        <div className="flex items-center gap-4">
          <div className="avatar avatar-xl">{business.name[0].toUpperCase()}</div>
          <div>
            <div className="flex items-center gap-3">
              <h1 className="page-title" style={{ marginBottom: 0 }}>{business.name}</h1>
              <span className={`badge badge-${business.status.toLowerCase()}`}>{business.status}</span>
              <span className={`badge badge-${business.subscriptionTier.toLowerCase()}`}>{business.subscriptionTier}</span>
            </div>
            <div className="text-sm text-muted mt-1">{business.category}</div>
            {business.description && <p className="text-sm mt-2" style={{ maxWidth: 480 }}>{business.description}</p>}
          </div>
        </div>

        {/* Actions */}
        <div className="flex gap-3">
          {business.status === 'PENDING' && (
            <button className="btn btn-success" onClick={() => handleAction('approve')} disabled={actioning}>
              ✓ Approve Business
            </button>
          )}
          {business.status === 'APPROVED' && (
            <button className="btn btn-danger" onClick={() => handleAction('suspend')} disabled={actioning}>
              Suspend
            </button>
          )}
          {business.status === 'SUSPENDED' && (
            <button className="btn btn-success" onClick={() => handleAction('approve')} disabled={actioning}>
              Re-approve
            </button>
          )}
        </div>
      </div>

      <div className="grid-3 mb-6">
        <div className="kpi-card" style={{ '--kpi-color': '#0D9488', '--kpi-bg': 'rgba(13,148,136,0.1)' } as React.CSSProperties}>
          <div className="kpi-icon">👥</div>
          <div className="kpi-label">Customers</div>
          <div className="kpi-value">{analytics?.totals.totalCustomers ?? '—'}</div>
        </div>
        <div className="kpi-card" style={{ '--kpi-color': '#7C3AED', '--kpi-bg': 'rgba(124,58,237,0.1)' } as React.CSSProperties}>
          <div className="kpi-icon">👊</div>
          <div className="kpi-label">Total Punches</div>
          <div className="kpi-value">{analytics?.totals.totalPunches?.toLocaleString() ?? '—'}</div>
        </div>
        <div className="kpi-card" style={{ '--kpi-color': '#D97706', '--kpi-bg': 'rgba(217,119,6,0.1)' } as React.CSSProperties}>
          <div className="kpi-icon">🎁</div>
          <div className="kpi-label">Redemptions</div>
          <div className="kpi-value">{analytics?.totals.totalRedemptions ?? '—'}</div>
        </div>
      </div>

      <div className="grid-2">
        {/* Business Info */}
        <div className="card card-padded">
          <h2 className="text-lg font-semibold mb-4">Business Details</h2>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
            <div className="stat-row"><span>Owner email</span><strong>{business.user?.email}</strong></div>
            {business.user?.phone && <div className="stat-row"><span>Phone</span><strong>{business.user.phone}</strong></div>}
            {business.website && <div className="stat-row"><span>Website</span><a href={business.website} target="_blank" rel="noopener noreferrer" style={{ color: '#FF6B35' }}>{business.website}</a></div>}
            <div className="stat-row"><span>Registered</span><strong>{new Date(business.createdAt).toLocaleDateString('en-US', { dateStyle: 'long' })}</strong></div>
            {(business.locations as { address: string }[]).length > 0 && (
              <div>
                <div className="text-sm text-muted mb-2">Locations</div>
                {(business.locations as { address: string }[]).map((loc, i) => (
                  <div key={i} className="text-sm">{loc.address}</div>
                ))}
              </div>
            )}
          </div>
        </div>

        {/* Loyalty Cards */}
        <div>
          <h2 className="text-lg font-semibold mb-4">Loyalty Cards ({business.loyaltyCards?.length ?? 0})</h2>
          {(business.loyaltyCards?.length ?? 0) === 0 ? (
            <div className="card card-padded">
              <div className="empty-state" style={{ padding: '24px 0' }}>
                <div className="empty-state-icon">🃏</div>
                <div className="empty-state-title">No cards yet</div>
                <p>Business hasn't created a loyalty card.</p>
              </div>
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
              {business.loyaltyCards?.map(card => (
                <div key={card.id} className="card card-padded card-hover">
                  <div className="flex items-center justify-between mb-2">
                    <span className="font-semibold">{card.title}</span>
                    <span className={`badge badge-${card.isActive ? 'active' : 'suspended'}`}>
                      {card.isActive ? 'Active' : 'Inactive'}
                    </span>
                  </div>
                  <p className="text-sm text-muted mb-3">{card.rewardDescription}</p>
                  <div className="flex gap-3">
                    <span className="text-sm"><strong>{card.punchesRequired}</strong> punches required</span>
                    <span className="text-sm"><strong>{card._count?.customerCards ?? 0}</strong> customers</span>
                  </div>
                  <div className="flex gap-2 mt-3">
                    {card.punchMethods?.map(m => (
                      <span key={m.id} className={`badge badge-${m.type.toLowerCase()}`}>{m.type}</span>
                    ))}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
