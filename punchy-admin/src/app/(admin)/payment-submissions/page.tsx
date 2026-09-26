'use client';

import { useCallback, useEffect, useState } from 'react';
import { api } from '@/lib/api';

type Submission = {
  id: string; businessId: string; paymentMethodName: string; plan: 'MONTHLY' | 'YEARLY';
  transactionId: string; amount: number; currency: string; status: 'PENDING' | 'APPROVED' | 'REJECTED';
  accountName: string; accountNumber?: string | null; bankName?: string | null; iban?: string | null;
  instructions?: string | null; adminNote?: string | null; createdAt: string; verifiedAt?: string | null;
  business: { id: string; name: string; countryCode?: string | null; user: { publicId?: string | null } };
  verifiedBy?: { email: string } | null;
};

export default function PaymentSubmissionsPage() {
  const [rows, setRows] = useState<Submission[]>([]);
  const [selected, setSelected] = useState<Submission | null>(null);
  const [filter, setFilter] = useState('ALL');
  const [loading, setLoading] = useState(true);
  const [working, setWorking] = useState(false);
  const [message, setMessage] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    try { setRows(await api.get<Submission[]>('/subscriptions/payments')); }
    catch (error) { setMessage(error instanceof Error ? error.message : 'Unable to load payment submissions.'); }
    finally { setLoading(false); }
  }, []);
  useEffect(() => { const handle = window.setTimeout(() => { void load(); }, 0); return () => window.clearTimeout(handle); }, [load]);

  async function decide(action: 'APPROVE' | 'REJECT') {
    if (!selected || working) return;
    const label = action === 'APPROVE' ? 'approve and activate this subscription' : 'reject this payment';
    if (!window.confirm(`Are you sure you want to ${label}?`)) return;
    setWorking(true); setMessage('');
    try {
      await api.post(`/subscriptions/payments/${selected.id}/decision`, { action });
      setMessage(action === 'APPROVE' ? 'Payment approved and subscription activated.' : 'Payment rejected. The business can submit again.');
      setSelected(null); await load();
    } catch (error) { setMessage(error instanceof Error ? error.message : 'Unable to review this payment.'); }
    finally { setWorking(false); }
  }

  const visible = filter === 'ALL' ? rows : rows.filter(row => row.status === filter);
  const date = (value?: string | null) => value ? new Intl.DateTimeFormat(undefined, { dateStyle: 'medium', timeStyle: 'short' }).format(new Date(value)) : '—';
  const badge = (status: string) => <span className={`badge ${status === 'APPROVED' ? 'b-active' : status === 'PENDING' ? 'b-pending' : 'b-suspended'}`}>{status}</span>;

  return <>
    <div className="admin-topbar"><h3>Payment Submissions</h3></div>
    <div className="admin-content">
      <div className="panel" style={{ marginBottom: 16, display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 12, flexWrap: 'wrap' }}>
        <div><div className="panel-title">Manual subscription payments</div><p style={{ margin: '4px 0 0', color: 'var(--ink-soft)', fontSize: 12.5 }}>Approve verified transfers to activate the selected subscription period.</p></div>
        <select aria-label="Filter submissions" value={filter} onChange={event => setFilter(event.target.value)} style={{ minWidth: 150 }}><option value="ALL">All statuses</option><option value="PENDING">Pending</option><option value="APPROVED">Approved</option><option value="REJECTED">Rejected</option></select>
      </div>
      {message && <div className="panel" role="status" style={{ marginBottom: 14, color: 'var(--ink-soft)' }}>{message}</div>}
      <div className="panel" style={{ padding: 0, overflowX: 'auto' }}>
        {loading ? <div className="loading-page"><div className="loading-spinner" /></div> : visible.length === 0 ? <div className="empty-state"><span className="empty-state-icon">🧾</span>No payment submissions found</div> : (
          <table className="atable"><thead><tr><th>Business</th><th>Unique ID</th><th>Country</th><th>Plan</th><th>Amount</th><th>Method</th><th>Transaction ID</th><th>Submitted</th><th>Status</th><th>Review</th></tr></thead>
            <tbody>{visible.map(row => <tr key={row.id}>
              <td><button className="btn btn-outline btn-xs" onClick={() => setSelected(row)}>{row.business.name}</button></td>
              <td>{row.business.user.publicId || row.business.id}</td><td>{row.business.countryCode || '—'}</td>
              <td>{row.plan === 'YEARLY' ? 'Yearly' : 'Monthly'}</td><td>{row.currency} {row.amount}</td>
              <td>{row.paymentMethodName}</td><td><code>{row.transactionId}</code></td><td>{date(row.createdAt)}</td>
              <td>{badge(row.status)}</td><td><button className="btn btn-outline btn-xs" onClick={() => setSelected(row)}>Details</button></td>
            </tr>)}</tbody>
          </table>
        )}
      </div>
      {selected && <div role="presentation" onClick={event => { if (event.target === event.currentTarget && !working) setSelected(null); }} style={{ position: 'fixed', inset: 0, zIndex: 1000, background: 'rgba(8,20,17,.55)', display: 'grid', placeItems: 'center', padding: 18 }}>
        <section role="dialog" aria-modal="true" aria-labelledby="payment-detail-title" className="panel" style={{ width: 'min(640px,100%)', maxHeight: '90vh', overflowY: 'auto', boxShadow: '0 24px 80px rgba(0,0,0,.22)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', gap: 12, alignItems: 'start' }}><div><div className="panel-title" id="payment-detail-title">{selected.business.name}</div><p style={{ margin: '4px 0 0', color: 'var(--ink-soft)', fontSize: 12.5 }}>Business ID: <b>{selected.business.user.publicId || selected.business.id}</b> · {selected.business.countryCode || 'Country unavailable'}</p></div><button className="btn btn-outline btn-xs" onClick={() => setSelected(null)} disabled={working}>Close</button></div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(180px,1fr))', gap: 14, marginTop: 20 }}>
            <Detail label="Plan" value={selected.plan === 'YEARLY' ? 'Yearly (12 months)' : 'Monthly (1 month)'} />
            <Detail label="Amount" value={`${selected.currency} ${selected.amount}`} />
            <Detail label="Payment method" value={selected.paymentMethodName} />
            <Detail label="Transaction ID" value={selected.transactionId} />
            <Detail label="Submitted" value={date(selected.createdAt)} />
            <Detail label="Status" value={selected.status} />
            <Detail label="Account name" value={selected.accountName} />
            <Detail label="Account / mobile" value={selected.accountNumber || '—'} />
            <Detail label="Bank" value={selected.bankName || '—'} />
            <Detail label="IBAN" value={selected.iban || '—'} />
            {selected.instructions && <Detail label="Instructions at submission" value={selected.instructions} />}
            {selected.verifiedBy && <Detail label="Reviewed by" value={`${selected.verifiedBy.email} · ${date(selected.verifiedAt)}`} />}
            {selected.adminNote && <Detail label="Admin note" value={selected.adminNote} />}
          </div>
          {selected.status === 'PENDING' && <div style={{ display: 'flex', justifyContent: 'flex-end', gap: 10, marginTop: 24, flexWrap: 'wrap' }}>
            <button className="btn btn-outline" onClick={() => void decide('REJECT')} disabled={working}>{working ? 'Processing…' : 'Reject'}</button>
            <button className="btn btn-primary" onClick={() => void decide('APPROVE')} disabled={working}>{working ? 'Processing…' : 'Approve & activate'}</button>
          </div>}
        </section>
      </div>}
    </div>
  </>;
}

function Detail({ label, value }: { label: string; value: string }) {
  return <div style={{ padding: '12px 14px', borderRadius: 12, background: 'var(--surface-alt, #f4f7f5)' }}><div style={{ color: 'var(--ink-soft)', fontSize: 11, marginBottom: 5 }}>{label}</div><div style={{ fontSize: 13, fontWeight: 700, wordBreak: 'break-word' }}>{value}</div></div>;
}