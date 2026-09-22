'use client';
import { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';
import Link from 'next/link';
import { api, type User } from '@/lib/api';

type CustomerCard = {
  id: string;
  punchCount: number;
  joinedAt: string;
  card: { title: string; punchesRequired: number; rewardDescription: string; business: { name: string } };
};

function statusBadge(isBlocked: boolean) {
  if (isBlocked) return <span className="badge b-suspended">BLOCKED</span>;
  return <span className="badge b-active">ACTIVE</span>;
}

export default function CustomerDetailPage() {
  const params = useParams();
  const id = params.id as string;
  const [user, setUser] = useState<(User & { name?: string; customerCards?: CustomerCard[] }) | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get<{ customer: User }>(`/admin/customers/${id}`)
      .then(res => setUser(res.customer))
      .catch(console.error)
      .finally(() => setLoading(false));
  }, [id]);

  if (loading) return (
    <div className="admin-content">
      <div className="loading-page"><div className="loading-spinner"/><span>Loading customer…</span></div>
    </div>
  );

  if (!user) return (
    <div className="admin-content">
      <div className="empty-state">Customer not found</div>
    </div>
  );

  const name = user.name || user.email.split('@')[0];

  return (
    <>
      <div className="admin-topbar">
        <div style={{ display:'flex', alignItems:'center', gap:10 }}>
          <Link href="/customers" style={{ color:'var(--ink)', display:'flex' }}>
            <svg width="24" height="24" viewBox="0 0 24 24" style={{ stroke:'currentColor', fill:'none', strokeWidth:1.8, strokeLinecap:'round', strokeLinejoin:'round' }}>
              <path d="M19 12H5M11 5l-7 7 7 7"/>
            </svg>
          </Link>
          <h3>{name}</h3>
        </div>
        <div className="top-actions">
          {user.isBlocked ? (
            <button className="btn btn-primary btn-xs">Unblock Account</button>
          ) : (
            <button className="btn btn-danger-ghost btn-xs">Block Account</button>
          )}
        </div>
      </div>
      <div className="admin-content">
        <div className="panel">
          <div className="profile-hero">
            <div className="p-logo" style={{ background:'var(--grad-purple)', color:'#fff' }}>
              {name.substring(0,2).toUpperCase()}
            </div>
            <div style={{ flex:1 }}>
              <div className="p-name">{name}</div>
              <div className="p-meta">
                {user.email} · {user.phone || 'No phone'} · Joined {new Date(user.createdAt).toLocaleDateString('en-US', { month:'short', day:'numeric', year:'numeric' })}
              </div>
            </div>
            {statusBadge(user.isBlocked)}
          </div>
        </div>

        <div className="panel" style={{ padding:0 }}>
          <div className="panel-head" style={{ padding:'16px 18px 0' }}><h4>Loyalty Cards</h4></div>
          {!user.customerCards?.length ? <div className="empty-state" style={{ padding:20 }}>No loyalty cards added yet.</div> : (
            <table className="atable"><thead><tr><th>Business</th><th>Card</th><th>Progress</th><th>Reward</th><th>Joined</th></tr></thead><tbody>
              {user.customerCards.map(item => <tr key={item.id}><td>{item.card.business.name}</td><td>{item.card.title}</td><td>{item.punchCount}/{item.card.punchesRequired}</td><td>{item.card.rewardDescription}</td><td>{new Date(item.joinedAt).toLocaleDateString()}</td></tr>)}
            </tbody></table>
          )}
        </div>

        <div className="panel" style={{ padding:0 }}>
          <div className="panel-head" style={{ padding:'16px 18px 0' }}><h4>Activity Log</h4></div>
          <div className="empty-state" style={{ padding:20 }}>
            No activity found.
          </div>
        </div>
      </div>
    </>
  );
}
