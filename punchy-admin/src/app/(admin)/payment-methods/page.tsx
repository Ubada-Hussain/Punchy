'use client';

import { FormEvent, useCallback, useEffect, useState } from 'react';
import { api } from '@/lib/api';

type PaymentMethod = {
  id: string; name: string; logoUrl?: string | null; accountName: string;
  accountNumber?: string | null; bankName?: string | null; iban?: string | null;
  instructions?: string | null; isActive: boolean; sortOrder: number;
};
type Form = Omit<PaymentMethod, 'id' | 'logoUrl'>;
const blank: Form = { name: '', accountName: '', accountNumber: '', bankName: '', iban: '', instructions: '', isActive: true, sortOrder: 0 };

export default function PaymentMethodsPage() {
  const [rows, setRows] = useState<PaymentMethod[]>([]);
  const [form, setForm] = useState<Form>(blank);
  const [editing, setEditing] = useState<string | null>(null);
  const [logo, setLogo] = useState<File | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    try { setRows(await api.get<PaymentMethod[]>('/subscriptions/payment-methods')); }
    catch (error) { setMessage(error instanceof Error ? error.message : 'Unable to load payment methods.'); }
    finally { setLoading(false); }
  }, []);
  useEffect(() => { const handle = window.setTimeout(() => { void load(); }, 0); return () => window.clearTimeout(handle); }, [load]);

  function edit(row: PaymentMethod) {
    setEditing(row.id);
    setForm({ name: row.name, accountName: row.accountName, accountNumber: row.accountNumber ?? '', bankName: row.bankName ?? '', iban: row.iban ?? '', instructions: row.instructions ?? '', isActive: row.isActive, sortOrder: row.sortOrder });
    setLogo(null); setMessage('');
  }
  function reset() { setEditing(null); setForm(blank); setLogo(null); setMessage(''); }

  async function save(event: FormEvent) {
    event.preventDefault();
    if (saving) return;
    setSaving(true); setMessage('');
    try {
      if (!form.name.trim() || !form.accountName.trim()) throw new Error('Enter a payment method name and account or business name.');
      const saved = await (editing
        ? api.put<PaymentMethod>(`/subscriptions/payment-methods/${editing}`, form)
        : api.post<PaymentMethod>('/subscriptions/payment-methods', form));
      if (logo) {
        const data = new FormData(); data.append('logo', logo);
        await api.upload(`/subscriptions/payment-methods/${saved.id}/logo`, data);
      }
      setMessage('Payment method saved.'); reset(); await load();
    } catch (error) { setMessage(error instanceof Error ? error.message : 'Unable to save payment method.'); }
    finally { setSaving(false); }
  }

  async function toggle(row: PaymentMethod) {
    if (saving) return;
    setSaving(true); setMessage('');
    try {
      await api.put(`/subscriptions/payment-methods/${row.id}`, { ...row, isActive: !row.isActive });
      await load();
    } catch (error) { setMessage(error instanceof Error ? error.message : 'Unable to update payment method.'); }
    finally { setSaving(false); }
  }

  async function remove(row: PaymentMethod) {
    if (saving || !window.confirm(`Delete ${row.name}? Existing submissions will retain their payment details.`)) return;
    setSaving(true); setMessage('');
    try { await api.delete(`/subscriptions/payment-methods/${row.id}`); await load(); }
    catch (error) { setMessage(error instanceof Error ? error.message : 'Unable to delete payment method.'); }
    finally { setSaving(false); }
  }

  const field = (label: string, key: 'name' | 'accountName' | 'accountNumber' | 'bankName' | 'iban' | 'instructions', placeholder = '') => (
    <div className="field"><label>{label}</label>
      {key === 'instructions'
        ? <textarea rows={3} value={String(form[key])} placeholder={placeholder} disabled={saving} onChange={e => setForm(current => ({ ...current, [key]: e.target.value }))} />
        : <input value={String(form[key])} placeholder={placeholder} disabled={saving} onChange={e => setForm(current => ({ ...current, [key]: e.target.value }))} />}
    </div>
  );

  return <>
    <div className="admin-topbar"><h3>Payment Methods</h3></div>
    <div className="admin-content">
      <div className="panel" style={{ marginBottom: 18 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', gap: 16, alignItems: 'center', marginBottom: 16 }}>
          <div><div className="panel-title">{editing ? 'Edit payment method' : 'Add payment method'}</div><p style={{ margin: '4px 0 0', color: 'var(--ink-soft)', fontSize: 12.5 }}>Changes appear in the business app as soon as they are saved.</p>{rows.length === 0 && !editing && <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap', marginTop: 10 }}>{['Easypaisa', 'JazzCash', 'Meezan Bank'].map(name => <button key={name} type="button" className="btn btn-outline btn-xs" onClick={() => setForm(current => ({ ...current, name }))}>{`Configure ${name}`}</button>)}</div>}</div>
          {editing && <button className="btn btn-outline btn-sm" onClick={reset} disabled={saving}>Cancel edit</button>}
        </div>
        <form onSubmit={save} style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit,minmax(210px,1fr))', gap: 12, alignItems: 'end' }}>
          {field('Method name', 'name', 'Bank or wallet name')}
          {field('Account / business name', 'accountName', 'Name shown on the receiving account')}
          {field('Account / mobile number', 'accountNumber', 'Optional')}
          {field('Bank name', 'bankName', 'Optional')}
          {field('IBAN', 'iban', 'Optional')}
          {field('Payment instructions', 'instructions', 'Any steps or reference guidance')}
          <div className="field"><label>Logo</label><input type="file" accept="image/*" disabled={saving} onChange={e => setLogo(e.target.files?.[0] ?? null)} /></div>
          <div className="field"><label>Display order</label><input type="number" min="0" value={form.sortOrder} disabled={saving} onChange={e => setForm(current => ({ ...current, sortOrder: Number(e.target.value) || 0 }))} /></div>
          <label style={{ display: 'inline-flex', alignItems: 'center', gap: 8, fontSize: 12.5, fontWeight: 700 }}><input type="checkbox" checked={form.isActive} disabled={saving} onChange={e => setForm(current => ({ ...current, isActive: e.target.checked }))} /> Active in the app</label>
          <button className="btn btn-primary" type="submit" disabled={saving}>{saving ? 'Saving…' : editing ? 'Save changes' : 'Add payment method'}</button>
        </form>
        {message && <p role="status" style={{ color: 'var(--coral-dark)', margin: '12px 0 0', fontSize: 12.5 }}>{message}</p>}
      </div>
      <div className="panel" style={{ padding: 0 }}>
        {loading ? <div className="loading-page"><div className="loading-spinner" /></div> : rows.length === 0 ? <div className="empty-state"><span className="empty-state-icon">💳</span>No payment methods added yet</div> : (
          <table className="atable"><thead><tr><th>Payment method</th><th>Account name</th><th>Number / IBAN</th><th>Status</th><th>Actions</th></tr></thead>
            <tbody>{rows.map(row => <tr key={row.id}>
              <td><div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>{row.logoUrl ? <img src={row.logoUrl} alt="" style={{ width: 38, height: 38, objectFit: 'contain', borderRadius: 8 }} /> : <span className="row-logo">{row.name.slice(0, 1)}</span>}<div><div className="row-name">{row.name}</div>{row.bankName && <div className="row-sub">{row.bankName}</div>}</div></div></td>
              <td>{row.accountName}</td><td>{row.accountNumber || row.iban || '—'}</td>
              <td><span className={`badge ${row.isActive ? 'b-active' : 'b-suspended'}`}>{row.isActive ? 'ACTIVE' : 'INACTIVE'}</span></td>
              <td><div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}><button className="btn btn-outline btn-xs" onClick={() => edit(row)} disabled={saving}>Edit</button><button className="btn btn-outline btn-xs" onClick={() => void toggle(row)} disabled={saving}>{row.isActive ? 'Deactivate' : 'Activate'}</button><button className="btn btn-xs btn-danger-ghost" onClick={() => void remove(row)} disabled={saving}>Delete</button></div></td>
            </tr>)}</tbody>
          </table>
        )}
      </div>
    </div>
  </>;
}