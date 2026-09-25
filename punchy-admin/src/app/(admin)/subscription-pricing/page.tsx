'use client';

import { FormEvent, useCallback, useEffect, useMemo, useState } from 'react';
import { api } from '@/lib/api';

type Country = { code: string; name: string; flag: string; currencyCode: string };
type Pricing = { countryCode: string; currencyCode: string; monthlyPrice: number; yearlyPrice: number; isActive: boolean };

const emptyForm = { countryCode: '', currencyCode: '', monthlyPrice: '', yearlyPrice: '', isActive: true };

export default function SubscriptionPricingPage() {
  const [countries, setCountries] = useState<Country[]>([]);
  const [rows, setRows] = useState<Pricing[]>([]);
  const [form, setForm] = useState(emptyForm);
  const [editing, setEditing] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const [countryData, pricingData] = await Promise.all([
        api.get<Country[]>('/subscriptions/countries'),
        api.get<Pricing[]>('/subscriptions/pricing'),
      ]);
      setCountries(countryData);
      setRows(pricingData);
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Unable to load subscription pricing.');
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    const handle = window.setTimeout(() => { void load(); }, 0);
    return () => window.clearTimeout(handle);
  }, [load]);

  const selectedCountry = useMemo(
    () => countries.find(country => country.code === form.countryCode),
    [countries, form.countryCode],
  );

  function chooseCountry(countryCode: string) {
    const country = countries.find(item => item.code === countryCode);
    setForm(current => ({ ...current, countryCode, currencyCode: country?.currencyCode ?? current.currencyCode }));
  }

  function edit(row: Pricing) {
    setEditing(row.countryCode);
    setForm({
      countryCode: row.countryCode,
      currencyCode: row.currencyCode,
      monthlyPrice: String(row.monthlyPrice),
      yearlyPrice: String(row.yearlyPrice),
      isActive: row.isActive,
    });
    setMessage('');
  }

  function reset() {
    setEditing(null);
    setForm(emptyForm);
    setMessage('');
  }

  async function save(event: FormEvent) {
    event.preventDefault();
    if (saving || !form.countryCode) return;
    setSaving(true);
    setMessage('');
    try {
      const payload = {
        countryCode: form.countryCode,
        currencyCode: form.currencyCode.trim().toUpperCase(),
        monthlyPrice: Number(form.monthlyPrice),
        yearlyPrice: Number(form.yearlyPrice),
        isActive: form.isActive,
      };
      if (!payload.currencyCode || !Number.isFinite(payload.monthlyPrice) || !Number.isFinite(payload.yearlyPrice)) {
        throw new Error('Enter a currency code and valid monthly and yearly prices.');
      }
      await (editing
        ? api.put<Pricing>(`/subscriptions/pricing/${editing}`, payload)
        : api.post<Pricing>('/subscriptions/pricing', payload));
      reset();
      await load();
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Unable to save pricing.');
    } finally {
      setSaving(false);
    }
  }

  async function toggle(row: Pricing) {
    if (saving) return;
    setSaving(true);
    setMessage('');
    try {
      await api.put<Pricing>(`/subscriptions/pricing/${row.countryCode}`, { ...row, isActive: !row.isActive });
      await load();
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Unable to update pricing status.');
    } finally {
      setSaving(false);
    }
  }

  const countryName = (code: string) => countries.find(country => country.code === code);

  return (
    <>
      <div className="admin-topbar"><h3>Subscription Pricing</h3></div>
      <div className="admin-content">
        <div className="panel" style={{ marginBottom: 18 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', gap: 16, alignItems: 'center', marginBottom: 16 }}>
            <div>
              <div className="panel-title">{editing ? 'Edit country pricing' : 'Add country pricing'}</div>
              <p style={{ margin: '4px 0 0', color: 'var(--ink-soft)', fontSize: 12.5 }}>
                Prices are saved by country; no exchange-rate conversion is used.
              </p>
            </div>
            {editing && <button className="btn btn-outline btn-sm" onClick={reset} disabled={saving}>Cancel edit</button>}
          </div>
          <form onSubmit={save} style={{ display: 'grid', gridTemplateColumns: 'minmax(220px,2fr) repeat(3,minmax(120px,1fr)) auto', gap: 12, alignItems: 'end' }}>
            <div className="field">
              <label>Country</label>
              <select value={form.countryCode} onChange={event => chooseCountry(event.target.value)} disabled={saving || !!editing} required>
                <option value="">Choose a country…</option>
                {countries.map(country => <option key={country.code} value={country.code}>{country.flag} {country.name} ({country.code})</option>)}
              </select>
            </div>
            <div className="field"><label>Currency (ISO)</label><input value={form.currencyCode} maxLength={3} onChange={event => setForm({ ...form, currencyCode: event.target.value.toUpperCase() })} placeholder={selectedCountry?.currencyCode ?? 'PKR'} required disabled={saving} /></div>
            <div className="field"><label>Monthly price</label><input type="number" min="0" step="0.01" value={form.monthlyPrice} onChange={event => setForm({ ...form, monthlyPrice: event.target.value })} required disabled={saving} /></div>
            <div className="field"><label>Yearly price</label><input type="number" min="0" step="0.01" value={form.yearlyPrice} onChange={event => setForm({ ...form, yearlyPrice: event.target.value })} required disabled={saving} /></div>
            <button className="btn btn-primary" type="submit" disabled={saving}>{saving ? 'Saving…' : editing ? 'Save changes' : 'Add pricing'}</button>
          </form>
          <label style={{ display: 'inline-flex', alignItems: 'center', gap: 8, marginTop: 14, fontSize: 12.5, fontWeight: 700 }}>
            <input type="checkbox" checked={form.isActive} onChange={event => setForm({ ...form, isActive: event.target.checked })} disabled={saving} /> Pricing is active
          </label>
          {message && <p style={{ color: 'var(--coral-dark)', margin: '12px 0 0', fontSize: 12.5 }}>{message}</p>}
        </div>

        <div className="panel" style={{ padding: 0 }}>
          {loading ? <div className="loading-page"><div className="loading-spinner" /></div> : rows.length === 0 ? (
            <div className="empty-state"><span className="empty-state-icon">💳</span>No country pricing configured yet</div>
          ) : (
            <table className="atable">
              <thead><tr><th>Country</th><th>Currency</th><th>Monthly</th><th>Yearly</th><th>Status</th><th>Actions</th></tr></thead>
              <tbody>{rows.map(row => {
                const country = countryName(row.countryCode);
                return <tr key={row.countryCode}>
                  <td><div className="row-name">{country ? `${country.flag} ${country.name}` : row.countryCode}</div><div className="row-sub">{row.countryCode}</div></td>
                  <td>{row.currencyCode}</td><td>{row.monthlyPrice}</td><td>{row.yearlyPrice}</td>
                  <td><span className={`badge ${row.isActive ? 'b-active' : 'b-suspended'}`}>{row.isActive ? 'ACTIVE' : 'INACTIVE'}</span></td>
                  <td><div style={{ display: 'flex', gap: 6 }}><button className="btn btn-outline btn-xs" onClick={() => edit(row)} disabled={saving}>Edit</button><button className="btn btn-xs btn-danger-ghost" onClick={() => void toggle(row)} disabled={saving}>{row.isActive ? 'Deactivate' : 'Activate'}</button></div></td>
                </tr>;
              })}</tbody>
            </table>
          )}
        </div>
      </div>
    </>
  );
}