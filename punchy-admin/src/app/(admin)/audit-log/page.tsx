'use client';

import { useCallback, useEffect, useState } from 'react';
import { api } from '@/lib/api';

type Event = { id: string; action: string; metadata: unknown; createdAt: string; user: { email: string; role: string } };
type Audit = { events: Event[]; total: number; page: number; totalPages: number };
const title = (value: string) => value.toLowerCase().replaceAll('_', ' ').replace(/\b\w/g, c => c.toUpperCase());

export default function AuditLogPage() {
  const [data, setData] = useState<Audit | null>(null); const [page, setPage] = useState(1); const [search, setSearch] = useState(''); const [loading, setLoading] = useState(true); const [error, setError] = useState('');
  const load = useCallback(() => { setLoading(true); setError(''); const params = new URLSearchParams({ page: String(page), limit: '25' }); if (search.trim()) params.set('search', search.trim()); api.get<Audit>(`/admin/audit?${params}`).then(setData).catch(err => setError(err instanceof Error ? err.message : 'Unable to load audit log')).finally(() => setLoading(false)); }, [page, search]);
  useEffect(() => { const timer = window.setTimeout(load, 250); return () => window.clearTimeout(timer); }, [load]);
  return <><div className="admin-topbar"><div><h3>Audit log</h3><span className="topbar-subtitle">Read-only platform history</span></div></div><div className="admin-content"><div className="filter-bar"><div className="search-in"><input value={search} onChange={event => { setSearch(event.target.value); setPage(1); }} placeholder="Search action or actor email…" /></div></div>
    {error && <div className="notice notice-error">{error}</div>}{loading ? <div className="loading-page"><div className="loading-spinner"/></div> : <div className="panel" style={{padding:0}}><table className="atable"><thead><tr><th>Timestamp</th><th>Actor</th><th>Action</th><th>Metadata</th></tr></thead><tbody>{data?.events.map(event => <tr key={event.id}><td>{new Date(event.createdAt).toLocaleString()}</td><td><b>{event.user.email}</b><div className="row-sub">{event.user.role}</div></td><td><span className="badge b-open">{title(event.action)}</span></td><td className="audit-metadata">{JSON.stringify(event.metadata)}</td></tr>)}</tbody></table>{!data?.events.length && <div className="inline-empty">No matching audit events</div>}</div>}
    {data && <div className="pagination"><span>{data.total.toLocaleString()} events</span><div><button className="btn btn-outline btn-xs" disabled={page <= 1} onClick={() => setPage(value => value - 1)}>Previous</button><b>Page {data.page} of {Math.max(1, data.totalPages)}</b><button className="btn btn-outline btn-xs" disabled={page >= data.totalPages} onClick={() => setPage(value => value + 1)}>Next</button></div></div>}
  </div></>;
}
