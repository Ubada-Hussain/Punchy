'use client';

import Link from 'next/link';
import { useEffect, useRef, useState } from 'react';
import { api } from '@/lib/api';

type SearchResults = {
  customers: { id: string; publicId?: string; name?: string; email: string; isBlocked: boolean }[];
  businesses: { id: string; name: string; status: string; user: { email: string; publicId?: string } }[];
  payments: { id: string; transactionId: string; status: string; business: { name: string } }[];
  tickets: { id: string; subject: string; status: string; author: { email: string } }[];
};

export default function GlobalSearch() {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<SearchResults | null>(null);
  const [loading, setLoading] = useState(false);
  const box = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (query.trim().length < 2) return;
    const timer = window.setTimeout(() => {
      setLoading(true);
      api.get<SearchResults>(`/admin/search?q=${encodeURIComponent(query.trim())}`)
        .then(setResults).catch(() => setResults(null)).finally(() => setLoading(false));
    }, 250);
    return () => window.clearTimeout(timer);
  }, [query]);

  useEffect(() => {
    const close = (event: MouseEvent) => { if (!box.current?.contains(event.target as Node)) setResults(null); };
    document.addEventListener('mousedown', close);
    return () => document.removeEventListener('mousedown', close);
  }, []);

  const count = results ? Object.values(results).reduce((sum, rows) => sum + rows.length, 0) : 0;
  return <div className="global-search" ref={box}>
    <div className="global-search-input">
      <svg width="15" height="15" viewBox="0 0 24 24"><circle cx="11" cy="11" r="6.5"/><path d="M20 20l-4.5-4.5"/></svg>
      <input aria-label="Search Punchy Admin" value={query} onChange={event => { const value = event.target.value; setQuery(value); if (value.trim().length < 2) setResults(null); }} placeholder="Search everything…" />
      {loading && <span className="search-dot" />}
    </div>
    {results && <div className="global-search-results">
      {count === 0 && <div className="global-search-empty">No matching records</div>}
      {results.customers.map(row => <Link onClick={() => { setResults(null); setQuery(''); }} href={`/customers/${row.id}`} key={`c-${row.id}`} className="global-search-result"><span className="search-kind">Customer</span><b>{row.name || row.email}</b><small>{row.publicId || row.email}</small></Link>)}
      {results.businesses.map(row => <Link onClick={() => { setResults(null); setQuery(''); }} href={`/businesses/${row.id}`} key={`b-${row.id}`} className="global-search-result"><span className="search-kind">Business</span><b>{row.name}</b><small>{row.user.publicId || row.user.email}</small></Link>)}
      {results.payments.map(row => <Link onClick={() => { setResults(null); setQuery(''); }} href="/payment-submissions" key={`p-${row.id}`} className="global-search-result"><span className="search-kind">Payment</span><b>{row.transactionId}</b><small>{row.business.name} · {row.status}</small></Link>)}
      {results.tickets.map(row => <Link onClick={() => { setResults(null); setQuery(''); }} href="/support" key={`t-${row.id}`} className="global-search-result"><span className="search-kind">Ticket</span><b>{row.subject}</b><small>{row.author.email} · {row.status}</small></Link>)}
    </div>}
  </div>;
}
