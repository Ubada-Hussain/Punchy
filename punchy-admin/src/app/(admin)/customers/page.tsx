'use client';
import { useEffect, useState, useCallback } from 'react';
import Link from 'next/link';
import { api, type User } from '@/lib/api';

function statusBadge(isBlocked: boolean) {
  if (isBlocked) return <span className="badge b-suspended">BLOCKED</span>;
  return <span className="badge b-active">ACTIVE</span>;
}

export default function CustomersPage() {
  const [customers, setCustomers] = useState<User[]>([]);
  const [total, setTotal] = useState(0);
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams({ limit: '50' });
      if (search) params.set('search', search);
      const data = await api.get<{ customers: User[]; total: number }>(`/customers?${params}`);
      setCustomers(data.customers);
      setTotal(data.total);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  }, [search]);

  useEffect(() => { load(); }, [load]);

  async function toggleBlock(user: User) {
    if (!user.isBlocked && !confirm(`Block ${user.email}?`)) return;
    await api.patch(`/customers/${user.id}`, { isBlocked: !user.isBlocked });
    load();
  }

  const gradients = ['var(--grad-purple)', 'var(--grad-coral)', 'var(--grad-teal)', 'var(--grad-gold)'];

  return (
    <>
      <div className="admin-topbar">
        <h3>Customers</h3>
        <div className="top-actions">
          <button className="top-icon">
            <svg width="16" height="16" viewBox="0 0 24 24" style={{ stroke:'currentColor', fill:'none', strokeWidth:1.8, strokeLinecap:'round', strokeLinejoin:'round' }}>
              <path d="M6 9a6 6 0 0 1 12 0c0 4 1.5 5.5 1.5 5.5H4.5S6 13 6 9Z"/><path d="M9.5 19a2.5 2.5 0 0 0 5 0"/>
            </svg>
          </button>
        </div>
      </div>
      <div className="admin-content">
        <div className="filter-bar">
          <div className="search-in">
            <svg width="15" height="15" viewBox="0 0 24 24" style={{ stroke:'var(--ink-faint)', fill:'none', strokeWidth:1.8, strokeLinecap:'round' }}>
              <circle cx="11" cy="11" r="6.5"/><path d="M20 20l-4.5-4.5"/>
            </svg>
            <input
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="Search customers by name or email…"
            />
          </div>
        </div>

        <div className="panel" style={{ padding:0 }}>
          {loading ? (
            <div className="loading-page"><div className="loading-spinner"/></div>
          ) : customers.length === 0 ? (
            <div className="empty-state">
              <span className="empty-state-icon">👥</span>
              No customers found
            </div>
          ) : (
            <table className="atable">
              <thead>
                <tr>
                  <th>Customer</th>
                  <th>Email</th>
                  <th>Joined</th>
                  <th>Role</th>
                  <th>Status</th>
                  <th>Action</th>
                </tr>
              </thead>
              <tbody>
                {customers.map((c, i) => (
                  <tr key={c.id}>
                    <td>
                      <div className="row-biz">
                        <div className="row-logo" style={{ background: gradients[i % gradients.length], color:'#fff' }}>
                          {c.email.substring(0, 2).toUpperCase()}
                        </div>
                        <div className="row-name">{c.email.split('@')[0]}</div>
                      </div>
                    </td>
                    <td className="row-sub">{c.email}</td>
                    <td>
                      {new Date(c.createdAt).toLocaleDateString('en-US', { month:'short', day:'numeric', year:'numeric' })}
                    </td>
                    <td style={{ color:'var(--ink-soft)', fontSize:12 }}>
                      {c.role === 'BUSINESS' ? 'Business Owner' : 'Customer'}
                    </td>
                    <td>{statusBadge(c.isBlocked)}</td>
                    <td>
                      <div style={{ display:'flex', gap:6 }}>
                        <button
                          className={`btn btn-xs ${c.isBlocked ? 'btn-primary' : 'btn-danger-ghost'}`}
                          onClick={() => toggleBlock(c)}
                        >
                          {c.isBlocked ? 'Unblock' : 'Block'}
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>

        {!loading && (
          <p style={{ fontSize:12, color:'var(--ink-faint)', fontWeight:600 }}>
            Showing {customers.length} of {total} customers
          </p>
        )}
      </div>
    </>
  );
}
