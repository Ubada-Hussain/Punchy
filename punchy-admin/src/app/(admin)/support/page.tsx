'use client';
import { useEffect, useState } from 'react';
import { api, type SupportTicket } from '@/lib/api';

function statusBadge(s: string) {
  const map: Record<string, string> = {
    OPEN: 'b-open',
    IN_PROGRESS: 'b-progress',
    RESOLVED: 'b-resolved',
  };
  return <span className={`badge ${map[s] ?? 'b-pending'}`}>{s.replace('_', ' ')}</span>;
}

export default function SupportPage() {
  const [tickets, setTickets] = useState<SupportTicket[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);

  const load = async () => {
    setLoading(true);
    try {
      const data = await api.get<{ tickets: SupportTicket[]; total: number }>('/tickets?limit=50');
      setTickets(data.tickets);
      setTotal(data.total);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { load(); }, []);

  async function updateStatus(id: string, s: string) {
    await api.patch(`/tickets/${id}`, { status: s });
    load();
  }

  const openCount = tickets.filter(t => t.status === 'OPEN').length;
  const progressCount = tickets.filter(t => t.status === 'IN_PROGRESS').length;

  return (
    <>
      <div className="admin-topbar">
        <h3>Support Tickets</h3>
      </div>
      <div className="admin-content">
        <div className="astat-row">
          <div className="astat">
            <span>Open</span>
            <b>{openCount}</b>
          </div>
          <div className="astat">
            <span>In Progress</span>
            <b>{progressCount}</b>
          </div>
          <div className="astat">
            <span>Resolved (30d)</span>
            <b>{total - openCount - progressCount}</b>
          </div>
        </div>

        <div className="panel" style={{ padding:0 }}>
          {loading ? (
            <div className="loading-page"><div className="loading-spinner"/></div>
          ) : tickets.length === 0 ? (
            <div className="empty-state">
              <span className="empty-state-icon">🎫</span>
              No tickets found
            </div>
          ) : (
            <table className="atable">
              <thead>
                <tr>
                  <th>Ticket</th>
                  <th>User</th>
                  <th>Subject</th>
                  <th>Status</th>
                  <th>Created</th>
                  <th></th>
                </tr>
              </thead>
              <tbody>
                {tickets.map(t => (
                  <tr key={t.id}>
                    <td className="row-sub">#{t.id.slice(-4).toUpperCase()}</td>
                    <td className="row-name">{t.author?.email?.split('@')[0] ?? 'User'}</td>
                    <td className="row-sub">{t.subject}</td>
                    <td>{statusBadge(t.status)}</td>
                    <td>
                      {new Date(t.createdAt).toLocaleDateString('en-US', { month:'short', day:'numeric' })}
                    </td>
                    <td>
                      <div style={{ display:'flex', gap:6 }}>
                        {t.status === 'OPEN' && (
                          <button className="btn btn-outline btn-xs" onClick={() => updateStatus(t.id, 'IN_PROGRESS')}>Start</button>
                        )}
                        {t.status === 'IN_PROGRESS' && (
                          <button className="btn btn-primary btn-xs" onClick={() => updateStatus(t.id, 'RESOLVED')}>Resolve</button>
                        )}
                        {t.status === 'RESOLVED' && (
                          <button className="btn btn-outline btn-xs" onClick={() => updateStatus(t.id, 'OPEN')}>Reopen</button>
                        )}
                      </div>
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
