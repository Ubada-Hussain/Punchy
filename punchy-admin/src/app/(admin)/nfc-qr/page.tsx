'use client';
import { useEffect, useState } from 'react';
import { api, type PunchMethod } from '@/lib/api';

type PopulatedMethod = PunchMethod & {
  card?: { title: string; business?: { name: string } };
};

export default function NfcQrPage() {
  const [methods, setMethods] = useState<PopulatedMethod[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'ALL'|'QR'|'NFC'>('ALL');
  const [search, setSearch] = useState('');

  useEffect(() => {
    api.get<{ methods: PopulatedMethod[] }>('/punch-methods')
      .then(res => setMethods(res.methods))
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  const filtered = methods.filter(m => {
    if (filter !== 'ALL' && m.type !== filter) return false;
    if (search) {
      const q = search.toLowerCase();
      return m.identifier.toLowerCase().includes(q) ||
             m.card?.business?.name?.toLowerCase().includes(q) ||
             m.card?.title?.toLowerCase().includes(q);
    }
    return true;
  });

  return (
    <>
      <div className="admin-topbar">
        <h3>NFC & QR Identifiers</h3>
      </div>
      <div className="admin-content">
        <div className="filter-bar">
          <div className="search-in">
            <svg width="15" height="15" viewBox="0 0 24 24" style={{ stroke:'var(--ink-faint)', fill:'none', strokeWidth:1.8, strokeLinecap:'round' }}>
              <circle cx="11" cy="11" r="6.5"/><path d="M20 20l-4.5-4.5"/>
            </svg>
            <input
              value={search}
              onChange={e => setSearch(e.target.value)}
              placeholder="Search identifier or business…"
            />
          </div>
          <div className="chip-set">
            {(['ALL','QR','NFC'] as const).map(f => (
              <button key={f} className={`fchip${filter === f ? ' on' : ''}`} onClick={() => setFilter(f)}>
                {f === 'ALL' ? 'All' : f}
              </button>
            ))}
          </div>
        </div>

        <div className="panel" style={{ padding:0 }}>
          {loading ? (
            <div className="loading-page"><div className="loading-spinner"/></div>
          ) : filtered.length === 0 ? (
            <div className="empty-state">
              <span className="empty-state-icon">📲</span>
              No punch methods found
            </div>
          ) : (
            <table className="atable">
              <thead>
                <tr>
                  <th>Identifier</th>
                  <th>Type</th>
                  <th>Business</th>
                  <th>Card</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map(m => (
                  <tr key={m.id}>
                    <td className="row-sub">{m.identifier}</td>
                    <td>
                      {m.type === 'QR' ? <span className="badge b-qr">QR</span> : <span className="badge b-nfc">NFC</span>}
                    </td>
                    <td className="row-name">{m.card?.business?.name ?? '—'}</td>
                    <td>{m.card?.title ?? '—'}</td>
                    <td>
                      {m.isActive ? <span className="badge b-active">ACTIVE</span> : <span className="badge b-suspended">INACTIVE</span>}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>
    </>
  );
}
