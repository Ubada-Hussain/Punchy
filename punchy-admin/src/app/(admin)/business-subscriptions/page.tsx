'use client';

import { useEffect, useMemo, useState } from 'react';
import { api } from '@/lib/api';

type Subscription = { id: string; status: string; plan: string; price: number; currency: string; startDate: string; endDate: string; trialStart?: string; trialEnd?: string; freeMonths?: number | null };
type Business = { id: string; name: string; countryCode?: string; user: { publicId?: string }; subscriptions: Subscription[] };
type Pricing = { countryCode: string; currencyCode: string; monthlyPrice: number; yearlyPrice: number; isActive: boolean };

const date = (value?: string) => value ? new Date(value).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' }) : '—';
const freeDuration = (subscription?: Subscription) => {
  if (!subscription || subscription.plan !== 'TRIAL') return '';
  if (subscription.freeMonths) return String(subscription.freeMonths);
  if (!subscription.trialStart || !subscription.trialEnd) return '';
  const start = new Date(subscription.trialStart);
  const end = new Date(subscription.trialEnd);
  return String((end.getFullYear() - start.getFullYear()) * 12 + end.getMonth() - start.getMonth());
};

export default function BusinessSubscriptionsPage() {
  const [query, setQuery] = useState('');
  const [items, setItems] = useState<Business[]>([]);
  const [pricing, setPricing] = useState<Pricing[]>([]);
  const [selected, setSelected] = useState<Business | null>(null);
  const [loading, setLoading] = useState(true);
  const [assigning, setAssigning] = useState(false);
  const [savingFree, setSavingFree] = useState(false);
  const [freeStatus, setFreeStatus] = useState<'ACTIVE' | 'INACTIVE'>('INACTIVE');
  const [freeMonths, setFreeMonths] = useState('');
  const [message, setMessage] = useState('');

  async function load(search = '') {
    setLoading(true);
    try {
      const [businesses, prices] = await Promise.all([
        api.get<Business[]>(`/subscriptions/businesses?search=${encodeURIComponent(search)}`),
        api.get<Pricing[]>('/subscriptions/pricing'),
      ]);
      setItems(businesses);
      setPricing(prices);
      setSelected(current => businesses.find(business => business.id === current?.id) ?? null);
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Unable to load businesses.');
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    const handle = window.setTimeout(() => { void load(query); }, 250);
    return () => window.clearTimeout(handle);
  }, [query]);

  const current = selected?.subscriptions[0];
  const countryPricing = useMemo(
    () => pricing.find(item => item.countryCode === selected?.countryCode && item.isActive),
    [pricing, selected?.countryCode],
  );

  async function assign(plan: 'MONTHLY' | 'YEARLY') {
    if (!selected || assigning) return;
    setAssigning(true);
    setMessage('');
    try {
      await api.post(`/subscriptions/businesses/${selected.id}/assign`, { plan });
      setMessage(`${plan === 'YEARLY' ? 'Yearly' : 'Monthly'} subscription assigned successfully.`);
      await load(query);
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Unable to assign subscription.');
    } finally {
      setAssigning(false);
    }
  }

  async function saveFree() {
    if (!selected || savingFree) return;
    const months = Number(freeMonths);
    if (!Number.isInteger(months) || months < 1 || months > 120) {
      setMessage('Choose a free subscription duration from 1 to 120 months.');
      return;
    }
    setSavingFree(true);
    setMessage('');
    try {
      await api.put(`/subscriptions/businesses/${selected.id}/free-subscription`, { status: freeStatus, months });
      setMessage('Free subscription updated successfully.');
      await load(query);
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Unable to update free subscription.');
    } finally {
      setSavingFree(false);
    }
  }

  return (
    <>
      <div className="admin-topbar"><h3>Business Subscriptions</h3></div>
      <div className="admin-content">
        <div className="filter-bar" style={{ marginBottom: 18 }}>
          <div className="search-in">
            <svg width="15" height="15" viewBox="0 0 24 24" style={{ stroke:'currentColor', fill:'none', strokeWidth:1.8 }}><circle cx="11" cy="11" r="6.5"/><path d="M20 20l-4.5-4.5"/></svg>
            <input value={query} onChange={event => setQuery(event.target.value)} placeholder="Search by business name or Business ID…" />
          </div>
        </div>

        <div className="panel" style={{ padding: 0, marginBottom: 18 }}>
          {loading ? <div className="loading-page"><div className="loading-spinner" /></div> : items.length === 0 ? (
            <div className="empty-state"><span className="empty-state-icon">🏪</span>No businesses found</div>
          ) : (
            <table className="atable">
              <thead><tr><th>Business</th><th>Business ID</th><th>Plan</th><th>Duration</th><th>Price</th><th>Currency</th><th>Start date</th><th>End date</th><th>Status</th><th>Actions</th></tr></thead>
              <tbody>{items.map(business => {
                const subscription = business.subscriptions[0];
                return <tr key={business.id}>
                  <td><div className="row-name">{business.name}</div><div className="row-sub">{business.countryCode ?? 'No country'}</div></td>
                  <td style={{ fontWeight: 700 }}>{business.user?.publicId ?? business.id}</td>
                  <td>{subscription?.plan ?? 'TRIAL'}</td><td>{subscription?.plan === 'YEARLY' ? '1 Year' : subscription?.plan === 'MONTHLY' ? '1 Month' : freeDuration(subscription) ? `${freeDuration(subscription)} ${freeDuration(subscription) === '1' ? 'Month' : 'Months'}` : '—'}</td>
                  <td>{subscription?.price ?? 0}</td><td>{subscription?.currency ?? '—'}</td><td>{date(subscription?.startDate)}</td><td>{date(subscription?.endDate)}</td>
                  <td><span className={`badge ${subscription?.status === 'ACTIVE' || subscription?.status === 'TRIALING' ? 'b-active' : 'b-suspended'}`}>{subscription?.plan === 'TRIAL' && subscription.status === 'TRIALING' ? 'ACTIVE' : subscription?.status ?? 'INACTIVE'}</span></td>
                  <td><button className="btn btn-outline btn-xs" onClick={() => { setSelected(business); setFreeStatus(subscription?.status === 'TRIALING' ? 'ACTIVE' : 'INACTIVE'); setFreeMonths(freeDuration(subscription)); setMessage(''); }}>Manage</button></td>
                </tr>;
              })}</tbody>
            </table>
          )}
        </div>

        {selected && <div className="panel">
          <div className="panel-title">Assign subscription</div>
          <div style={{ marginTop: 8, marginBottom: 16 }}>
            <div className="row-name">{selected.name}</div>
            <div className="row-sub">Business ID: {selected.user?.publicId ?? selected.id}</div>
          </div>
          {current && <div style={{ padding: 12, background: 'var(--bg)', borderRadius: 10, fontSize: 12.5, lineHeight: 1.7, marginBottom: 16 }}>
            Current: <b>{current.plan}</b> · {current.currency} {current.price} · {date(current.startDate)} – {date(current.endDate)} · <b>{current.plan === 'TRIAL' && current.status === 'TRIALING' ? 'ACTIVE' : current.status}</b>
          </div>}
          {(!current || current.plan === 'TRIAL') && <div style={{ marginBottom: 18 }}>
            <div className="panel-title">Free subscription</div>
            <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', alignItems: 'end', marginTop: 10 }}>
              <label style={{ fontSize: 12.5 }}>Status<br /><select value={freeStatus} disabled={savingFree} onChange={event => setFreeStatus(event.target.value as 'ACTIVE' | 'INACTIVE')}><option value="ACTIVE">Active</option><option value="INACTIVE">Inactive</option></select></label>
              <label style={{ fontSize: 12.5 }}>Free months<br /><input type="number" min="1" max="120" step="1" placeholder="Select months" value={freeMonths} disabled={savingFree} onChange={event => setFreeMonths(event.target.value)} /></label>
              <button className="btn btn-primary" disabled={savingFree || !freeMonths} onClick={() => void saveFree()}>{savingFree ? 'Saving…' : 'Save free subscription'}</button>
            </div>
          </div>}
          {!countryPricing ? <p style={{ color: 'var(--coral-dark)', fontSize: 12.5 }}>Set active subscription pricing for {selected.countryCode ?? 'this business country'} before assigning a plan.</p> : (
            <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
              <button className="btn btn-primary" disabled={assigning} onClick={() => void assign('MONTHLY')}>{assigning ? 'Processing…' : `Assign 1 Month · ${countryPricing.currencyCode} ${countryPricing.monthlyPrice}`}</button>
              <button className="btn btn-outline" disabled={assigning} onClick={() => void assign('YEARLY')}>{assigning ? 'Processing…' : `Assign 1 Year · ${countryPricing.currencyCode} ${countryPricing.yearlyPrice}`}</button>
            </div>
          )}
          {message && <p style={{ color: message.includes('successfully') ? 'var(--teal-dark)' : 'var(--coral-dark)', fontSize: 12.5, margin: '14px 0 0' }}>{message}</p>}
        </div>}
      </div>
    </>
  );
}
