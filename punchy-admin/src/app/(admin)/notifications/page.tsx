'use client';
import { useEffect, useState } from 'react';
import { api, type Notification } from '@/lib/api';

const TARGET_OPTIONS = [
  { value: 'ALL', label: '🌐 Everyone (all users)' },
  { value: 'BUSINESSES', label: '🏪 All Businesses' },
  { value: 'CUSTOMERS', label: '👥 All Customers' },
];

export default function NotificationsPage() {
  const [notifications, setNotifications] = useState<Notification[]>([]);
  const [loading, setLoading] = useState(true);
  const [sending, setSending] = useState(false);
  const [form, setForm] = useState({ title: '', body: '', targetType: 'ALL' });
  const [success, setSuccess] = useState('');
  const [error, setError] = useState('');

  function load() {
    api.get<{ notifications: Notification[] }>('/notifications')
      .then(d => setNotifications(d.notifications))
      .catch(console.error)
      .finally(() => setLoading(false));
  }

  useEffect(() => { load(); }, []);

  async function handleSend(e: React.FormEvent) {
    e.preventDefault();
    setSending(true);
    setError('');
    try {
      await api.post('/notifications', form);
      setSuccess('Notification sent!');
      setForm({ title: '', body: '', targetType: 'ALL' });
      load();
      setTimeout(() => setSuccess(''), 3000);
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Failed to send');
    } finally {
      setSending(false);
    }
  }

  return (
    <div className="page-content">
      <div className="page-header">
        <h1 className="page-title">Notifications</h1>
        <p className="page-subtitle">Send platform-wide announcements and view history</p>
      </div>

      <div className="grid-2">
        {/* Compose */}
        <div className="card card-padded">
          <h2 className="text-lg font-semibold mb-5">Send Announcement</h2>
          {success && <div className="alert alert-success">{success}</div>}
          {error && <div className="alert alert-danger">{error}</div>}
          <form onSubmit={handleSend}>
            <div className="form-group">
              <label className="form-label">Audience</label>
              <select
                className="form-select"
                value={form.targetType}
                onChange={e => setForm(f => ({ ...f, targetType: e.target.value }))}
              >
                {TARGET_OPTIONS.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
              </select>
            </div>
            <div className="form-group">
              <label className="form-label">Title</label>
              <input
                className="form-input"
                placeholder="Notification title"
                value={form.title}
                onChange={e => setForm(f => ({ ...f, title: e.target.value }))}
                required
              />
            </div>
            <div className="form-group">
              <label className="form-label">Message</label>
              <textarea
                className="form-textarea"
                placeholder="Notification body text…"
                value={form.body}
                onChange={e => setForm(f => ({ ...f, body: e.target.value }))}
                required
              />
            </div>
            <button type="submit" className="btn btn-primary w-full" disabled={sending}>
              {sending ? 'Sending…' : '🔔 Send Notification'}
            </button>
          </form>
        </div>

        {/* History */}
        <div>
          <h2 className="text-lg font-semibold mb-4">Recent History</h2>
          <div className="table-container">
            {loading ? (
              <div className="loading-page"><div className="loading-spinner" /></div>
            ) : notifications.length === 0 ? (
              <div className="empty-state">
                <div className="empty-state-icon">🔔</div>
                <div className="empty-state-title">No notifications sent yet</div>
              </div>
            ) : (
              <table className="data-table">
                <thead><tr><th>Title</th><th>Audience</th><th>Sent</th></tr></thead>
                <tbody>
                  {notifications.map(n => (
                    <tr key={n.id}>
                      <td>
                        <div className="font-medium">{n.title}</div>
                        <div className="text-xs text-muted truncate" style={{ maxWidth: 200 }}>{n.body}</div>
                      </td>
                      <td>
                        <span className="badge badge-active">{n.targetType}</span>
                      </td>
                      <td>
                        <span className="text-sm text-muted">
                          {n.sentAt ? new Date(n.sentAt).toLocaleDateString() : 'Scheduled'}
                        </span>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
