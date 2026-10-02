'use client';

import Link from 'next/link';
import { useCallback, useEffect, useState } from 'react';
import { api, type User } from '@/lib/api';

type CustomerResponse = { customers: User[]; total: number; page: number; limit: number; totalPages: number };

export default function CustomersPage() {
  const [data, setData] = useState<CustomerResponse | null>(null);
  const [search, setSearch] = useState(''); const [status, setStatus] = useState('ALL'); const [page, setPage] = useState(1);
  const [loading, setLoading] = useState(true); const [error, setError] = useState(''); const [working, setWorking] = useState('');
  const load = useCallback(() => {
    setLoading(true); setError('');
    const params = new URLSearchParams({ page: String(page), limit: '25' }); if (search.trim()) params.set('search', search.trim()); if (status !== 'ALL') params.set('status', status);
    api.get<CustomerResponse>(`/admin/customers?${params}`).then(setData).catch(err => setError(err instanceof Error ? err.message : 'Unable to load customers')).finally(() => setLoading(false));
  }, [page, search, status]);
  useEffect(() => { const timer = window.setTimeout(load, 250); return () => window.clearTimeout(timer); }, [load]);

  async function toggle(customer: User) {
    const verb = customer.isBlocked ? 'restore' : 'suspend';
    if (!confirm(`${verb[0].toUpperCase()}${verb.slice(1)} ${customer.name || customer.email}?`)) return;
    setWorking(customer.id); setError('');
    try { await api.post(`/admin/customers/${customer.id}/toggle-block`, {}); await load(); }
    catch (err) { setError(err instanceof Error ? err.message : `Unable to ${verb} customer`); }
    finally { setWorking(''); }
  }

  async function remove(customer: User) {
    if (working) return;
    if (!confirm(`Permanently delete ${customer.name || customer.email}? This cannot be undone.`)) return;
    const confirmationKey = prompt('Enter the permanent deletion key to continue:');
    if (!confirmationKey) return;
    setWorking(customer.id); setError('');
    try {
      await api.delete(`/admin/customers/${customer.id}`, { confirmationKey });
      await load();
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Unable to delete customer');
    } finally {
      setWorking('');
    }
  }

  return <><div className="admin-topbar"><div><h3>Customers</h3><span className="topbar-subtitle">Search, review and manage customer accounts</span></div></div><div className="admin-content">
    <div className="filter-bar"><div className="search-in"><input value={search} onChange={event => { setSearch(event.target.value); setPage(1); }} placeholder="Name, email, phone or customer ID…" /></div><div className="chip-set">{['ALL','ACTIVE','SUSPENDED'].map(item => <button key={item} className={`fchip ${status === item ? 'on' : ''}`} onClick={() => { setStatus(item); setPage(1); }}>{item === 'ALL' ? 'All accounts' : item[0] + item.slice(1).toLowerCase()}</button>)}</div></div>
    {error && <div className="notice notice-error">{error}</div>}
    <div className="panel" style={{padding:0}}>{loading ? <div className="loading-page"><div className="loading-spinner"/></div> : !data?.customers.length ? <div className="empty-state"><span className="empty-state-icon">◎</span>No customers match these filters</div> : <table className="atable"><thead><tr><th>Customer</th><th>Customer ID</th><th>Contact</th><th>Country</th><th>Joined</th><th>Status</th><th>Actions</th></tr></thead><tbody>{data.customers.map(customer => <tr key={customer.id}><td><div className="row-biz"><div className="row-logo customer-avatar">{(customer.name || customer.email).slice(0,2).toUpperCase()}</div><div><Link className="row-name row-link" href={`/customers/${customer.id}`}>{customer.name || 'Unnamed customer'}</Link><div className="row-sub">{customer.email}</div></div></div></td><td>{customer.publicId || '—'}</td><td>{customer.phone || <span className="row-sub">No phone</span>}</td><td>{customer.countryCode || '—'}</td><td>{new Date(customer.createdAt).toLocaleDateString()}</td><td><span className={`badge ${customer.isBlocked ? 'b-suspended' : 'b-active'}`}>{customer.isBlocked ? 'SUSPENDED' : 'ACTIVE'}</span></td><td><div className="table-actions"><Link href={`/customers/${customer.id}`} className="btn btn-outline btn-xs">View</Link><button disabled={working === customer.id} className={`btn btn-xs ${customer.isBlocked ? 'btn-primary' : 'btn-danger-ghost'}`} onClick={() => toggle(customer)}>{working === customer.id ? 'Saving…' : customer.isBlocked ? 'Restore' : 'Suspend'}</button><button disabled={working === customer.id} className="btn btn-danger-ghost btn-xs" onClick={() => remove(customer)}>Delete</button></div></td></tr>)}</tbody></table>}</div>
    {data && <div className="pagination"><span>Showing {data.customers.length} of {data.total.toLocaleString()} customers</span><div><button className="btn btn-outline btn-xs" disabled={page <= 1} onClick={() => setPage(value => value - 1)}>Previous</button><b>Page {data.page} of {Math.max(1, data.totalPages)}</b><button className="btn btn-outline btn-xs" disabled={page >= data.totalPages} onClick={() => setPage(value => value + 1)}>Next</button></div></div>}
  </div></>;
}
