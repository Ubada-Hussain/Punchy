'use client';
// Moderation page — content review for business logos/profiles
// MVP: shows approved businesses that could be flagged for review
import { useEffect, useState } from 'react';
import Link from 'next/link';
import { api, type Business } from '@/lib/api';

export default function ModerationPage() {
  const [businesses, setBusinesses] = useState<Business[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get<{ businesses: Business[] }>('/businesses?status=APPROVED&limit=50')
      .then(d => setBusinesses(d.businesses.filter(b => b.logo)))
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  async function suspend(id: string) {
    if (!confirm('Suspend this business?')) return;
    await api.post(`/businesses/${id}/suspend`);
    setBusinesses(bs => bs.filter(b => b.id !== id));
  }

  return (
    <div className="page-content">
      <div className="page-header">
        <h1 className="page-title">Content Moderation</h1>
        <p className="page-subtitle">Review business profile images and flag inappropriate content</p>
      </div>

      <div className="alert alert-info mb-6">
        <span>ℹ️</span>
        <span>MVP moderation view shows businesses with uploaded logos for manual review. Automated AI moderation can be added in a future sprint.</span>
      </div>

      {loading ? (
        <div className="loading-page"><div className="loading-spinner" /></div>
      ) : businesses.length === 0 ? (
        <div className="empty-state">
          <div className="empty-state-icon">🛡️</div>
          <div className="empty-state-title">Nothing to review</div>
          <p>No businesses with uploaded logos at this time.</p>
        </div>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: 16 }}>
          {businesses.map(b => (
            <div key={b.id} className="card card-padded card-hover">
              <div style={{ width: '100%', height: 120, background: '#F5F5F3', borderRadius: 8, marginBottom: 14, overflow: 'hidden', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                {b.logo ? (
                  <img src={b.logo} alt={b.name} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                ) : (
                  <span style={{ fontSize: 40 }}>🏪</span>
                )}
              </div>
              <div className="font-semibold mb-1">{b.name}</div>
              <div className="text-sm text-muted mb-3">{b.category}</div>
              <div className="flex gap-2">
                <Link href={`/businesses/${b.id}`} className="btn btn-secondary btn-sm flex-1">View Profile</Link>
                <button onClick={() => suspend(b.id)} className="btn btn-danger btn-sm">Suspend</button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
