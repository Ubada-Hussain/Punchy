'use client';
import { useEffect, useState } from 'react';
import { useParams } from 'next/navigation';
import Link from 'next/link';
import { api } from '@/lib/api';

interface CustomerDetail {
  id: string;
  email: string;
  phone?: string;
  isBlocked: boolean;
  createdAt: string;
  customerCards: {
    id: string;
    punchCount: number;
    isCompleted: boolean;
    joinedAt: string;
    card: { title: string; punchesRequired: number; business: { name: string } };
  }[];
  activityLogs: { id: string; action: string; metadata: Record<string, unknown>; createdAt: string }[];
}

export default function CustomerDetailPage() {
  const { id } = useParams<{ id: string }>();
  const [customer, setCustomer] = useState<CustomerDetail | null>(null);
  const [loading, setLoading] = useState(true);

  function load() {
    api.get<CustomerDetail>(`/admin/users/${id}`)
      .then(setCustomer)
      .catch(console.error)
      .finally(() => setLoading(false));
  }

  useEffect(() => { load(); }, [id]);

  async function toggleBlock() {
    if (!customer) return;
    const action = customer.isBlocked ? 'unblock' : 'block';
    if (!customer.isBlocked && !confirm(`Block ${customer.email}?`)) return;
    await api.post(`/admin/users/${id}/${action}`);
    load();
  }

  if (loading) return <div className="page-content"><div className="loading-page"><div className="loading-spinner" /></div></div>;
  if (!customer) return <div className="page-content"><div className="empty-state"><div className="empty-state-title">Customer not found</div></div></div>;

  return (
    <div className="page-content">
      <div className="flex items-center gap-2 text-sm text-muted mb-6">
        <Link href="/customers" style={{ color: '#FF6B35' }}>Customers</Link>
        <span>›</span>
        <span>{customer.email}</span>
      </div>

      <div className="flex items-start justify-between mb-6">
        <div className="flex items-center gap-4">
          <div className="avatar avatar-xl">{customer.email[0].toUpperCase()}</div>
          <div>
            <h1 className="page-title" style={{ marginBottom: 4 }}>{customer.email}</h1>
            <div className="flex items-center gap-3">
              {customer.isBlocked
                ? <span className="badge badge-blocked">Blocked</span>
                : <span className="badge badge-active">Active</span>}
              <span className="text-sm text-muted">Joined {new Date(customer.createdAt).toLocaleDateString('en-US', { dateStyle: 'long' })}</span>
            </div>
          </div>
        </div>
        <button
          onClick={toggleBlock}
          className={`btn ${customer.isBlocked ? 'btn-success' : 'btn-danger'}`}
        >
          {customer.isBlocked ? 'Unblock Account' : 'Block Account'}
        </button>
      </div>

      <div className="grid-2">
        {/* Loyalty Cards */}
        <div>
          <h2 className="text-lg font-semibold mb-4">Loyalty Cards ({customer.customerCards.length})</h2>
          {customer.customerCards.length === 0 ? (
            <div className="card card-padded">
              <div className="empty-state" style={{ padding: '24px 0' }}>
                <div className="empty-state-icon">🃏</div>
                <div className="empty-state-title">No cards yet</div>
                <p>Customer hasn't scanned any businesses.</p>
              </div>
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              {customer.customerCards.map(cc => (
                <div key={cc.id} className="card card-padded">
                  <div className="flex items-center justify-between mb-2">
                    <span className="font-semibold">{cc.card.title}</span>
                    {cc.isCompleted && <span className="badge badge-active">Ready!</span>}
                  </div>
                  <div className="text-sm text-muted mb-2">{cc.card.business.name}</div>
                  <div style={{ height: 6, background: '#F0F0EE', borderRadius: 3, overflow: 'hidden' }}>
                    <div style={{
                      height: '100%',
                      width: `${Math.min(100, (cc.punchCount / cc.card.punchesRequired) * 100)}%`,
                      background: '#FF6B35',
                      borderRadius: 3,
                    }} />
                  </div>
                  <div className="text-xs text-muted mt-2">{cc.punchCount} / {cc.card.punchesRequired} punches</div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Activity Log */}
        <div>
          <h2 className="text-lg font-semibold mb-4">Recent Activity</h2>
          <div className="table-container">
            {customer.activityLogs.length === 0 ? (
              <div className="empty-state"><div className="empty-state-title">No activity yet</div></div>
            ) : (
              <table className="data-table">
                <thead><tr><th>Action</th><th>Time</th></tr></thead>
                <tbody>
                  {customer.activityLogs.map(log => (
                    <tr key={log.id}>
                      <td>
                        <span className="text-sm font-medium">{log.action.replace(/_/g, ' ')}</span>
                      </td>
                      <td>
                        <span className="text-sm text-muted">{new Date(log.createdAt).toLocaleString()}</span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
