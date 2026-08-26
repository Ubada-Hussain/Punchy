'use client';
import { useEffect, useState } from 'react';
import { api, type Business } from '@/lib/api';

export default function ModerationPage() {
  const [pending, setPending] = useState<Business[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    // Reusing the pending businesses endpoint for moderation review
    api.get<{ businesses: Business[] }>('/businesses?status=PENDING&limit=10')
      .then(res => setPending(res.businesses))
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  async function approve(id: string) {
    await api.patch(`/businesses/${id}`, { status: 'APPROVED' });
    setPending(p => p.filter(b => b.id !== id));
  }

  async function suspend(id: string) {
    if (!confirm('Suspend this business?')) return;
    await api.patch(`/businesses/${id}`, { status: 'SUSPENDED' });
    setPending(p => p.filter(b => b.id !== id));
  }

  return (
    <>
      <div className="admin-topbar">
        <h3>Moderation</h3>
      </div>
      <div className="admin-content">
        <div className="panel">
          <div className="panel-head"><h4>Pending Review (Businesses)</h4></div>
          {loading ? (
             <div className="loading-page" style={{ minHeight:100 }}><div className="loading-spinner"/></div>
          ) : pending.length === 0 ? (
            <div className="empty-state" style={{ padding:20 }}><span className="empty-state-icon">🛡️</span>Nothing to review</div>
          ) : (
            pending.map(b => (
              <div key={b.id} className="mod-row">
                <div className="mod-thumb" style={{ background:'var(--grad-teal)', color:'#fff', display:'flex', alignItems:'center', justifyContent:'center', fontWeight:800 }}>
                  {b.logo || b.name[0]}
                </div>
                <div style={{ flex:1 }}>
                  <div className="row-name">{b.name}</div>
                  <div className="row-sub">Category: {b.category}</div>
                </div>
                <button className="btn btn-primary btn-xs" onClick={() => approve(b.id)}>Approve</button>
                <button className="btn btn-danger-ghost btn-xs" onClick={() => suspend(b.id)}>Suspend</button>
              </div>
            ))
          )}
        </div>

        <div className="panel">
          <div className="panel-head"><h4>Flagged Content</h4></div>
          <div className="empty-state" style={{ padding:20 }}>
            <span className="empty-state-icon">🚩</span>No flagged content
          </div>
        </div>
      </div>
    </>
  );
}
