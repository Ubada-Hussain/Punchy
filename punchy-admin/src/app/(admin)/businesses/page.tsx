'use client';
import { Suspense, useEffect, useState, useCallback } from 'react';
import Link from 'next/link';
import { useSearchParams, useRouter } from 'next/navigation';
import { api, type Business } from '@/lib/api';

const STATUSES = ['ALL', 'PENDING', 'APPROVED', 'SUSPENDED'] as const;

function BusinessesList() {
  const searchParams = useSearchParams();
  const router = useRouter();
  const [businesses, setBusinesses] = useState<Business[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState<string>(searchParams.get('status') ?? 'ALL');
  const [page, setPage] = useState(1);
  const limit = 20;

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams({ page: String(page), limit: String(limit) });
      if (search) params.set('search', search);
      if (status !== 'ALL') params.set('status', status);
      const data = await api.get<{ businesses: Business[]; total: number }>(`/businesses?${params}`);
      setBusinesses(data.businesses);
      setTotal(data.total);
    } catch (err) { console.error(err); }
    finally { setLoading(false); }
  }, [search, status, page]);

  useEffect(() => { load(); }, [load]);

  async function approve(id: string) {
    await api.post(`/businesses/${id}/approve`);
    load();
  }

  async function suspend(id: string) {
    if (!confirm('Suspend this business?')) return;
    await api.post(`/businesses/${id}/suspend`);
    load();
  }

  const pages = Math.ceil(total / limit);

  return (
    <div className="page-content">
      <div className="page-header">
        <h1 className="page-title">Businesses</h1>
        <p className="page-subtitle">{total.toLocaleString()} businesses registered on the platform</p>
      </div>

      {/* Toolbar */}
      <div className="toolbar">
        <div className="toolbar-search input-with-icon">
          <svg className="input-icon" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"/></svg>
          <input
            className="form-input"
            placeholder="Search businesses…"
            value={search}
            onChange={e => { setSearch(e.target.value); setPage(1); }}
          />
        </div>
        <div className="flex gap-2">
          {STATUSES.map(s => (
            <button
              key={s}
              onClick={() => { setStatus(s); setPage(1); }}
              className={`btn btn-sm ${status === s ? 'btn-primary' : 'btn-secondary'}`}
            >
              {s === 'ALL' ? 'All' : s.charAt(0) + s.slice(1).toLowerCase()}
            </button>
          ))}
        </div>
      </div>

      {/* Table */}
      <div className="table-container">
        {loading ? (
          <div className="loading-page"><div className="loading-spinner" /></div>
        ) : businesses.length === 0 ? (
          <div className="empty-state">
            <div className="empty-state-icon">🏪</div>
            <div className="empty-state-title">No businesses found</div>
            <p>Try adjusting your search or filters.</p>
          </div>
        ) : (
          <>
            <table className="data-table">
              <thead>
                <tr>
                  <th>Business</th>
                  <th>Category</th>
                  <th>Status</th>
                  <th>Cards</th>
                  <th>Joined</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {businesses.map(b => (
                  <tr key={b.id}>
                    <td>
                      <div className="flex items-center gap-3">
                        <div className="avatar avatar-md">{b.name[0].toUpperCase()}</div>
                        <div>
                          <div className="font-medium">{b.name}</div>
                          <div className="text-xs text-muted">{b.user?.email}</div>
                        </div>
                      </div>
                    </td>
                    <td><span className="text-sm text-muted">{b.category}</span></td>
                    <td>
                      <span className={`badge badge-${b.status.toLowerCase()}`}>{b.status}</span>
                    </td>
                    <td><span className="font-medium">{b._count?.loyaltyCards ?? 0}</span></td>
                    <td><span className="text-sm text-muted">{new Date(b.createdAt).toLocaleDateString()}</span></td>
                    <td>
                      <div className="flex gap-2">
                        <Link href={`/businesses/${b.id}`} className="btn btn-secondary btn-sm">View</Link>
                        {b.status === 'PENDING' && (
                          <button onClick={() => approve(b.id)} className="btn btn-success btn-sm">Approve</button>
                        )}
                        {b.status === 'APPROVED' && (
                          <button onClick={() => suspend(b.id)} className="btn btn-danger btn-sm">Suspend</button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>

            {/* Pagination */}
            <div className="pagination">
              <span className="pagination-info">
                Showing {(page - 1) * limit + 1}–{Math.min(page * limit, total)} of {total}
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

export default function BusinessesPage() {
  return (
    <Suspense fallback={<div className="loading-page"><div className="loading-spinner" /></div>}>
      <BusinessesList />
    </Suspense>
  );
}
