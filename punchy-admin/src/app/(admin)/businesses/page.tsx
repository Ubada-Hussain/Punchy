'use client';
import { useEffect, useState, useCallback } from 'react';
import Link from 'next/link';
import { api, type Business } from '@/lib/api';

const FILTERS = ['ALL', 'APPROVED', 'SUSPENDED'] as const;

function statusBadge(s: string) {
  const map: Record<string, string> = { APPROVED:'b-active', SUSPENDED:'b-suspended' };
  return <span className={`badge ${map[s] ?? 'b-pending'}`}>{s}</span>;
}

export default function BusinessesPage() {
  const [businesses, setBusinesses] = useState<Business[]>([]);
  const [total, setTotal] = useState(0);
  const [filter, setFilter] = useState<string>('ALL');
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams({ limit: '50' });
      if (filter !== 'ALL') params.set('status', filter);
      if (search) params.set('search', search);
      const data = await api.get<{ businesses: Business[]; total: number }>(`/businesses?${params}`);
      setBusinesses(data.businesses);
      setTotal(data.total);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  }, [filter, search]);

  useEffect(() => { load(); }, [load]);

  async function suspend(id: string) {
    if (!confirm('Suspend this business?')) return;
    await api.post(`/businesses/${id}/suspend`, {});
    load();
  }

  async function unban(id: string) {
    if (!confirm('Unban this business?')) return;
    await api.post(`/businesses/${id}/unban`, {});
    load();
  }

  const gradients = ['var(--grad-teal)','var(--grad-purple)','var(--grad-coral)','var(--grad-gold)'];

  return (
    <>
      <div className="admin-topbar">
        <h3>Businesses</h3>
        <div className="top-actions">
          <button className="top-icon">
            <svg width="16" height="16" viewBox="0 0 24 24" style={{ stroke:'currentColor', fill:'none', strokeWidth:1.8, strokeLinecap:'round', strokeLinejoin:'round' }}>
              <path d="M6 9a6 6 0 0 1 12 0c0 4 1.5 5.5 1.5 5.5H4.5S6 13 6 9Z"/><path d="M9.5 19a2.5 2.5 0 0 0 5 0"/>
            </svg>
          </button>
        </div>
      </div>
      <div className="admin-content">
        {/* Filter bar */}
        <div className="filter-bar">
          <div className="search-in">
            <svg width="15" height="15" viewBox="0 0 24 24" style={{ stroke:'var(--ink-faint)', fill:'none', strokeWidth:1.8, strokeLinecap:'round' }}>
              <circle cx="11" cy="11" r="6.5"/><path d="M20 20l-4.5-4.5"/>
            </svg>
            <input
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="Search businesses…"
            />
          </div>
          <div className="chip-set">
            {FILTERS.map(f => (
              <button key={f} className={`fchip${filter === f ? ' on' : ''}`} onClick={() => setFilter(f)}>
                {f === 'ALL' ? 'All' : f.charAt(0) + f.slice(1).toLowerCase()}
              </button>
            ))}
          </div>
        </div>

        {/* Table */}
        <div className="panel" style={{ padding:0 }}>
          {loading ? (
            <div className="loading-page"><div className="loading-spinner"/></div>
          ) : businesses.length === 0 ? (
            <div className="empty-state">
              <span className="empty-state-icon">🏪</span>
              No businesses found
            </div>
          ) : (
            <table className="atable">
              <thead>
                <tr>
                  <th>Business</th>
                  <th>Public ID</th>
                  <th>Category</th>
                  <th>Customers</th>
                  <th>Status</th>
                  <th>Joined</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {businesses.map((b, i) => (
                  <tr key={b.id}>
                    <td>
                      <div className="row-biz">
                        <div className="row-logo" style={{ background: gradients[i % gradients.length], color:'#fff' }}>
                          {b.logo || b.name[0]}
                        </div>
                        <div>
                          <div className="row-name">{b.name}</div>
                          <div className="row-sub">{b.locations?.[0]?.address ?? ''}</div>
                        </div>
                      </div>
                    </td>
                    <td>{b.user?.publicId ?? '—'}</td>
                    <td style={{ color:'var(--ink-soft)', fontSize:12 }}>{b.category}</td>
                    <td style={{ fontWeight:700 }}>{b._count?.loyaltyCards ?? 0}</td>
                    <td>{statusBadge(b.status)}</td>
                    <td style={{ color:'var(--ink-soft)', fontSize:12 }}>
                      {new Date(b.createdAt).toLocaleDateString('en-US', { month:'short', day:'numeric', year:'numeric' })}
                    </td>
                    <td>
                      <div style={{ display:'flex', gap:6 }}>
                        {b.status === 'APPROVED' && (
                          <button className="btn btn-danger-ghost btn-xs" onClick={() => suspend(b.id)}>Suspend</button>
                        )}
                        {b.status === 'SUSPENDED' && (
                          <button className="btn btn-primary btn-xs" onClick={() => unban(b.id)}>Unban</button>
                        )}
                        <Link href={`/businesses/${b.id}`} className="btn btn-outline btn-xs">View</Link>
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
            Showing {businesses.length} of {total} businesses
          </p>
        )}
      </div>
    </>
  );
}
