'use client';

import { useEffect, useMemo, useState } from 'react';
import { api } from '@/lib/api';

type Subscription = { id: string; status: string; plan: string; price: number; currency: string; startDate: string; endDate: string; trialStart?: string; trialEnd?: string };
type Business = { id: string; name: string; countryCode?: string; user: { publicId?: string }; subscriptions: Subscription[] };
type Pricing = { countryCode: string; currencyCode: string; monthlyPrice: number; yearlyPrice: number; isActive: boolean };

const date = (value?: string) => value ? new Date(value).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' }) : '—';

export default function BusinessSubscriptionsPage() {
  const [query, setQuery] = useState('');
  const [items, setItems] = useState<Business[]>([]);
  const [pricing, setPricing] = useState<Pricing[]>([]);
  const [selected, setSelected] = useState<Business | null>(null);
  const [loading, setLoading] = useState(true);
  const [assigning, setAssigning] = useState(false);
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
                  <td>{subscription?.plan ?? 'TRIAL'}</td><td>{subscription?.plan === 'YEARLY' ? '1 Year' : subscription?.plan === 'MONTHLY' ? '1 Month' : '2 Months'}</td>
                  <td>{subscription?.price ?? 0}</td><td>{subscription?.currency ?? '—'}</td><td>{date(subscription?.startDate)}</td><td>{date(subscription?.endDate)}</td>
                  <td><span className={`badge ${subscription?.status === 'ACTIVE' ? 'b-active' : subscription?.status === 'TRIALING' ? 'b-pending' : 'b-suspended'}`}>{subscription?.status ?? 'TRIALING'}</span></td>
                  <td><button className="btn btn-outline btn-xs" onClick={() => { setSelected(business); setMessage(''); }}>Manage</button></td>
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
            Current: <b>{current.plan}</b> · {current.currency} {current.price} · {date(current.startDate)} – {date(current.endDate)} · <b>{current.status}</b>
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