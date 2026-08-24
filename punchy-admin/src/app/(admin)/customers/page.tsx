'use client';
import { useEffect, useState, useCallback } from 'react';
import Link from 'next/link';
import { api, type User } from '@/lib/api';

export default function CustomersPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(1);
  const limit = 20;

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams({ role: 'CUSTOMER', page: String(page), limit: String(limit) });
      if (search) params.set('search', search);
      const data = await api.get<{ users: User[]; total: number }>(`/admin/users?${params}`);
      setUsers(data.users);
      setTotal(data.total);
    } catch (err) { console.error(err); }
    finally { setLoading(false); }
  }, [search, page]);

  useEffect(() => { load(); }, [load]);

  async function toggleBlock(user: User) {
    const action = user.isBlocked ? 'unblock' : 'block';
    if (!user.isBlocked && !confirm(`Block ${user.email}?`)) return;
    await api.post(`/admin/users/${user.id}/${action}`);
    load();
  }

  const pages = Math.ceil(total / limit);

  return (
    <div className="page-content">
      <div className="page-header">
        <h1 className="page-title">Customers</h1>
        <p className="page-subtitle">{total.toLocaleString()} customers registered</p>
      </div>

      <div className="toolbar">
        <div className="toolbar-search input-with-icon">
          <svg className="input-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
          <input
            className="form-input"
            placeholder="Search by email…"
            value={search}
            onChange={e => { setSearch(e.target.value); setPage(1); }}
          />
        </div>
      </div>

      <div className="table-container">
        {loading ? (
          <div className="loading-page"><div className="loading-spinner" /></div>
        ) : users.length === 0 ? (
          <div className="empty-state">
            <div className="empty-state-icon">👥</div>
            <div className="empty-state-title">No customers found</div>
          </div>
        ) : (
          <>
            <table className="data-table">
              <thead>
                <tr><th>Customer</th><th>Phone</th><th>Status</th><th>Joined</th><th>Actions</th></tr>
              </thead>
              <tbody>
                {users.map(u => (
                  <tr key={u.id}>
                    <td>
                      <div className="flex items-center gap-3">
                        <div className="avatar avatar-sm">{u.email[0].toUpperCase()}</div>
                        <span className="font-medium">{u.email}</span>
                      </div>
                    </td>
                    <td><span className="text-sm text-muted">{u.phone ?? '—'}</span></td>
                    <td>
                      {u.isBlocked
                        ? <span className="badge badge-blocked">Blocked</span>
                        : <span className="badge badge-active">Active</span>}
                    </td>
                    <td><span className="text-sm text-muted">{new Date(u.createdAt).toLocaleDateString()}</span></td>
                    <td>
                      <div className="flex gap-2">
                        <Link href={`/customers/${u.id}`} className="btn btn-secondary btn-sm">View</Link>
                        <button
                          onClick={() => toggleBlock(u)}
                          className={`btn btn-sm ${u.isBlocked ? 'btn-success' : 'btn-danger'}`}
                        >
                          {u.isBlocked ? 'Unblock' : 'Block'}
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            <div className="pagination">
              <span className="pagination-info">
                {(page - 1) * limit + 1}–{Math.min(page * limit, total)} of {total}
              </span>
              <div className="pagination-controls">
                <button className="page-btn" disabled={page === 1} onClick={() => setPage(p => p - 1)}>←</button>
                {Array.from({ length: Math.min(pages, 5) }, (_, i) => i + 1).map(p => (
                  <button key={p} className={`page-btn${p === page ? ' active' : ''}`} onClick={() => setPage(p)}>{p}</button>
                ))}
                <button className="page-btn" disabled={page >= pages} onClick={() => setPage(p => p + 1)}>→</button>
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  );
}
