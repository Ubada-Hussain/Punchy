'use client';
import { useEffect, useState, FormEvent } from 'react';
import { api, type Notification } from '@/lib/api';

export default function NotificationsPage() {
  const [history, setHistory] = useState<Notification[]>([]);
  const [loading, setLoading] = useState(true);
  const [form, setForm] = useState({ title: '', body: '', targetType: 'ALL' });
  const [sending, setSending] = useState(false);

  useEffect(() => {
    api.get<{ notifications: Notification[] }>('/notifications')
      .then(res => setHistory(res.notifications))
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  async function handleSend(e: FormEvent) {
    e.preventDefault();
    if (!form.title || !form.body) return;
    setSending(true);
    try {
      const res = await api.post<{ notification: Notification }>('/notifications', form);
      setHistory(prev => [res.notification, ...prev]);
      setForm({ title: '', body: '', targetType: 'ALL' });
      alert('Notification sent!');
    } catch (err: unknown) {
      alert(err instanceof Error ? err.message : 'Failed to send');
    } finally {
      setSending(false);
    }
  }

  return (
    <>
      <div className="admin-topbar">
        <h3>Notifications</h3>
      </div>
      <div className="admin-content">
        <div className="panel">
          <div className="panel-head"><h4>Compose Announcement</h4></div>
          <form onSubmit={handleSend} style={{ display:'flex', flexDirection:'column', gap:12 }}>
            <div className="field">
              <label>Target</label>
              <select
                value={form.targetType}
                onChange={e => setForm({ ...form, targetType: e.target.value })}
              >
                <option value="ALL">All Users</option>
                <option value="CUSTOMERS">Customers Only</option>
                <option value="BUSINESSES">Businesses Only</option>
              </select>
            </div>
            <div className="field">
              <label>Title</label>
              <input
                type="text"
                value={form.title}
                onChange={e => setForm({ ...form, title: e.target.value })}
                placeholder="Weekend double-punch event! 🎉"
                required
              />
            </div>
            <div className="field">
              <label>Body</label>
              <textarea
                rows={3}
                value={form.body}
                onChange={e => setForm({ ...form, body: e.target.value })}
                placeholder="Earn 2x punches at any participating business..."
                required
              />
            </div>
            <button type="submit" className="btn btn-coral" style={{ width:'fit-content' }} disabled={sending}>
              {sending ? 'Sending...' : 'Send Notification'}
            </button>
          </form>
        </div>

        <div className="panel">
          <div className="panel-head"><h4>History</h4></div>
          {loading ? (
             <div className="loading-page" style={{ minHeight:100 }}><div className="loading-spinner"/></div>
          ) : history.length === 0 ? (
            <div className="empty-state" style={{ padding:20 }}>
              <span className="empty-state-icon">📭</span>No notifications sent yet
            </div>
          ) : (
            <table className="atable">
              <thead>
                <tr>
                  <th>Title</th>
                  <th>Target</th>
                  <th>Sent</th>
                  <th>Delivered</th>
                </tr>
              </thead>
              <tbody>
                {history.map(n => (
                  <tr key={n.id}>
                    <td className="row-name">{n.title}</td>
                    <td>{n.targetType}</td>
                    <td>
                      {new Date(n.createdAt).toLocaleDateString('en-US', { month:'short', day:'numeric', year:'numeric' })}
                    </td>
                    <td>—</td>
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
