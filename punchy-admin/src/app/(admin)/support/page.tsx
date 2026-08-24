'use client';
import { useEffect, useState, useCallback } from 'react';
import Link from 'next/link';
import { api, type SupportTicket } from '@/lib/api';

const STATUS_TABS = ['ALL', 'OPEN', 'IN_PROGRESS', 'RESOLVED'] as const;

export default function SupportPage() {
  const [tickets, setTickets] = useState<SupportTicket[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [status, setStatus] = useState<string>('ALL');
  const [page, setPage] = useState(1);
  const limit = 20;

  const load = useCallback(async () => {
    setLoading(true);
    const params = new URLSearchParams({ page: String(page), limit: String(limit) });
    if (status !== 'ALL') params.set('status', status);
    const data = await api.get<{ tickets: SupportTicket[]; total: number }>(`/tickets?${params}`);
    setTickets(data.tickets);
    setTotal(data.total);
    setLoading(false);
  }, [status, page]);

  useEffect(() => { load(); }, [load]);

  async function resolve(id: string) {
    await api.patch(`/tickets/${id}`, { status: 'RESOLVED' });
    load();
  }

  async function updateStatus(id: string, s: string) {
    await api.patch(`/tickets/${id}`, { status: s });
    load();
  }

  const pages = Math.ceil(total / limit);

  return (
    <div className="page-content">
      <div className="page-header">
        <h1 className="page-title">Support Tickets</h1>
        <p className="page-subtitle">{total} tickets</p>
      </div>

      <div className="tab-bar">
        {STATUS_TABS.map(s => (
          <button key={s} className={`tab-item${status === s ? ' active' : ''}`} onClick={() => { setStatus(s); setPage(1); }}>
            {s === 'ALL' ? 'All Tickets' : s.replace('_', ' ')}
          </button>
        ))}
      </div>

      <div className="table-container">
        {loading ? (
          <div className="loading-page"><div className="loading-spinner" /></div>
        ) : tickets.length === 0 ? (
          <div className="empty-state">
            <div className="empty-state-icon">🎫</div>
            <div className="empty-state-title">No tickets found</div>
          </div>
        ) : (
          <>
            <table className="data-table">
              <thead><tr><th>Subject</th><th>From</th><th>Role</th><th>Status</th><th>Created</th><th>Actions</th></tr></thead>
              <tbody>
                {tickets.map(t => (
                  <tr key={t.id}>
                    <td>
                      <div className="font-medium">{t.subject}</div>
                      <div className="text-xs text-muted truncate" style={{ maxWidth: 220 }}>{t.body}</div>
                    </td>
                    <td><span className="text-sm">{t.author?.email}</span></td>
                    <td><span className="badge badge-active">{t.author?.role}</span></td>
                    <td>
                      <span className={`badge badge-${t.status.toLowerCase().replace('_', '-')}`}>
                        {t.status.replace('_', ' ')}
                      </span>
                    </td>
                    <td><span className="text-sm text-muted">{new Date(t.createdAt).toLocaleDateString()}</span></td>
                    <td>
                      <div className="flex gap-2">
                        {t.status === 'OPEN' && (
                          <button onClick={() => updateStatus(t.id, 'IN_PROGRESS')} className="btn btn-secondary btn-sm">In Progress</button>
                        )}
                        {t.status !== 'RESOLVED' && (
                          <button onClick={() => resolve(t.id)} className="btn btn-success btn-sm">Resolve</button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
            <div className="pagination">
              <span className="pagination-info">{(page - 1) * limit + 1}–{Math.min(page * limit, total)} of {total}</span>
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
