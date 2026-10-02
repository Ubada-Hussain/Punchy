'use client';

import Link from 'next/link';
import { useParams } from 'next/navigation';
import { useCallback, useEffect, useState } from 'react';
import { api, type User } from '@/lib/api';

type Customer = User & {
  customerCards: { id: string; punchCount: number; isCompleted: boolean; card: { title: string; business: { name: string } } }[];
  supportTickets: { id: string; subject: string; status: string; createdAt: string; resolvedAt?: string }[];
  activityLogs: { id: string; action: string; metadata: unknown; createdAt: string }[];
  refreshTokens: { id: string; createdAt: string; expiresAt: string }[];
};
const title = (value: string) => value.toLowerCase().replaceAll('_', ' ').replace(/\b\w/g, c => c.toUpperCase());

export default function CustomerDetailPage() {
  const id = useParams<{ id: string }>().id;
  const [customer, setCustomer] = useState<Customer | null>(null); const [loading, setLoading] = useState(true); const [error, setError] = useState(''); const [working, setWorking] = useState(false);
  const load = useCallback(() => { setLoading(true); api.get<{customer: Customer}>(`/admin/customers/${id}`).then(result => setCustomer(result.customer)).catch(err => setError(err instanceof Error ? err.message : 'Unable to load customer')).finally(() => setLoading(false)); }, [id]);
  useEffect(() => { const timer = window.setTimeout(load, 0); return () => window.clearTimeout(timer); }, [load]);
  async function toggle() { if (!customer) return; const verb = customer.isBlocked ? 'restore' : 'suspend'; if (!confirm(`${verb[0].toUpperCase()}${verb.slice(1)} ${customer.name || customer.email}?`)) return; setWorking(true); try { await api.post(`/admin/customers/${id}/toggle-block`, {}); await load(); } catch (err) { setError(err instanceof Error ? err.message : 'Unable to update account'); } finally { setWorking(false); } }
  if (loading) return <div className="admin-content"><div className="loading-page"><div className="loading-spinner"/><span>Loading customer profile…</span></div></div>;
  if (!customer) return <div className="admin-content"><div className="error-state"><b>Customer unavailable</b><span>{error || 'Customer not found'}</span><Link href="/customers" className="btn btn-outline">Back to customers</Link></div></div>;
  const name = customer.name || customer.email.split('@')[0];
  return <><div className="admin-topbar"><div className="back-title"><Link href="/customers" aria-label="Back to customers">←</Link><div><h3>{name}</h3><span className="topbar-subtitle">{customer.publicId || customer.id}</span></div></div><button disabled={working} className={`btn btn-xs ${customer.isBlocked ? 'btn-primary' : 'btn-danger-ghost'}`} onClick={toggle}>{working ? 'Saving…' : customer.isBlocked ? 'Restore account' : 'Suspend account'}</button></div><div className="admin-content">
    {error && <div className="notice notice-error">{error}</div>}
    <div className="panel"><div className="profile-hero"><div className="p-logo customer-avatar">{name.slice(0,2).toUpperCase()}</div><div style={{flex:1}}><div className="p-name">{name}</div><div className="p-meta">{customer.email} · Joined {new Date(customer.createdAt).toLocaleDateString()}</div></div><span className={`badge ${customer.isBlocked ? 'b-suspended' : 'b-active'}`}>{customer.isBlocked ? 'SUSPENDED' : 'ACTIVE'}</span></div><div className="profile-facts"><div><span>Phone</span><b>{customer.phone || 'Not provided'}</b></div><div><span>Country</span><b>{customer.countryCode || 'Unknown'}</b></div><div><span>Active sessions</span><b>{customer.refreshTokens.length}</b></div><div><span>Last profile update</span><b>{new Date(customer.updatedAt || customer.createdAt).toLocaleDateString()}</b></div></div></div>
    <div className="two-col"><div className="panel"><div className="panel-head"><h4>Loyalty usage</h4><span className="panel-note">{customer.customerCards.length} cards</span></div>{customer.customerCards.length ? <div className="compact-list">{customer.customerCards.map(card => <div key={card.id}><div><b>{card.card.title}</b><span>{card.card.business.name}</span></div><strong>{card.punchCount} punches</strong></div>)}</div> : <div className="inline-empty">No loyalty cards</div>}</div><div className="panel"><div className="panel-head"><h4>Support history</h4><span className="panel-note">{customer.supportTickets.length} recent</span></div>{customer.supportTickets.length ? <div className="compact-list">{customer.supportTickets.map(ticket => <div key={ticket.id}><div><b>{ticket.subject}</b><span>{new Date(ticket.createdAt).toLocaleDateString()}</span></div><span className={`badge ${ticket.status === 'RESOLVED' ? 'b-resolved' : 'b-open'}`}>{title(ticket.status)}</span></div>)}</div> : <div className="inline-empty">No support tickets</div>}</div></div>
    <div className="panel"><div className="panel-head"><div><span className="section-kicker">Unified timeline</span><h4>Customer activity</h4></div></div>{customer.activityLogs.length ? <div className="activity-list">{customer.activityLogs.map(event => <div className="activity-item" key={event.id}><div className="activity-mark"/><div><b>{title(event.action)}</b><span>{JSON.stringify(event.metadata)}</span></div><time>{new Date(event.createdAt).toLocaleString()}</time></div>)}</div> : <div className="inline-empty">No recorded activity</div>}</div>
  </div></>;
}
