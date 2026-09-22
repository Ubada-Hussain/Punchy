'use client';
import { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';
import Link from 'next/link';
import { api, type Business } from '@/lib/api';

function statusBadge(s: string) {
  const map: Record<string, string> = { APPROVED:'b-active', ACTIVE:'b-active', SUSPENDED:'b-suspended' };
  return <span className={`badge ${map[s] ?? 'b-pending'}`}>{s.replace('_', ' ')}</span>;
}

export default function BusinessDetailPage() {
  const params = useParams();
  const id = params.id as string;
  const [biz, setBiz] = useState<Business | null>(null);
  const [loading, setLoading] = useState(true);

  async function changeStatus() {
    if (!biz) return;
    const suspended = biz.status === 'SUSPENDED';
    if (!confirm(suspended ? 'Unban this business?' : 'Suspend this business?')) return;
    await api.post(`/businesses/${id}/${suspended ? 'unban' : 'suspend'}`, {});
    setBiz({ ...biz, status: suspended ? 'APPROVED' : 'SUSPENDED' });
  }

  useEffect(() => {
    api.get<Business | { business: Business }>(`/businesses/${id}`)
      .then(res => setBiz('business' in res ? res.business : res))
      .catch(console.error)
      .finally(() => setLoading(false));
  }, [id]);

  if (loading) return (
    <div className="admin-content">
      <div className="loading-page"><div className="loading-spinner"/><span>Loading business…</span></div>
    </div>
  );

  if (!biz) return (
    <div className="admin-content">
      <div className="empty-state">Business not found</div>
    </div>
  );

  return (
    <>
      <div className="admin-topbar">
        <div style={{ display:'flex', alignItems:'center', gap:10 }}>
          <Link href="/businesses" style={{ color:'var(--ink)', display:'flex' }}>
            <svg width="24" height="24" viewBox="0 0 24 24" style={{ stroke:'currentColor', fill:'none', strokeWidth:1.8, strokeLinecap:'round', strokeLinejoin:'round' }}>
              <path d="M19 12H5M11 5l-7 7 7 7"/>
            </svg>
          </Link>
          <h3>{biz.name}</h3>
        </div>
        <div className="top-actions">
          <button className={`btn btn-xs ${biz.status === 'SUSPENDED' ? 'btn-primary' : 'btn-danger-ghost'}`} onClick={changeStatus}>{biz.status === 'SUSPENDED' ? 'Unban' : 'Suspend'}</button>
        </div>
      </div>
      <div className="admin-content">
        <div className="panel">
          <div className="profile-hero">
            <div className="p-logo" style={{ background:'var(--grad-teal)', color:'#fff' }}>
              {biz.logo || biz.name[0]}
            </div>
            <div style={{ flex:1 }}>
              <div className="p-name">{biz.name}</div>
              <div className="p-meta">
                {biz.category} · {biz.locations?.[0]?.address ?? 'No address'} · Joined {new Date(biz.createdAt).toLocaleDateString('en-US', { month:'short', day:'numeric', year:'numeric' })}
              </div>
            </div>
            {statusBadge(biz.status)}
          </div>
        </div>

        <div className="astat-row">
          <div className="astat">
            <span>Punch Cards</span>
            <b>{biz.loyaltyCards?.length ?? 0}</b>
          </div>
          <div className="astat">
            <span>Customers</span>
            <b>{biz._count?.loyaltyCards ?? 0}</b>
          </div>
          <div className="astat">
            <span>Total Punches</span>
            <b>0</b>
          </div>
        </div>

        <div className="panel" style={{ padding:0 }}>
          <div className="panel-head" style={{ padding:'16px 18px 0' }}><h4>Punch Cards</h4></div>
          {!biz.loyaltyCards?.length ? (
            <div className="empty-state" style={{ padding:20 }}>No punch cards created yet.</div>
          ) : (
            <table className="atable">
              <thead>
                <tr>
                  <th>Card</th>
                  <th>Punches Req.</th>
                  <th>Reward</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {biz.loyaltyCards.map(c => (
                  <tr key={c.id}>
                    <td className="row-name">{c.title}</td>
                    <td>{c.punchesRequired}</td>
                    <td>{c.rewardDescription}</td>
                    <td>{statusBadge(c.isActive ? 'ACTIVE' : 'SUSPENDED')}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>

        <div className="panel" style={{ padding:0 }}>
          <div className="panel-head" style={{ padding:'16px 18px 0' }}><h4>Recent Customers</h4></div>
          <div className="empty-state" style={{ padding:20 }}>
            No customer activity yet.
          </div>
        </div>
      </div>
    </>
  );
}
