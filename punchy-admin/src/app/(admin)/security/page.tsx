'use client';

import { useEffect, useState } from 'react';
import { api } from '@/lib/api';

type SecurityData = { activeSessions: number; suspendedAccounts: number; passwordResetRequests: number; events: { id: string; action: string; createdAt: string; user: { email: string; role: string } }[] };
const title = (value: string) => value.toLowerCase().replaceAll('_', ' ').replace(/\b\w/g, c => c.toUpperCase());

export default function SecurityPage() {
  const [data, setData] = useState<SecurityData | null>(null); const [error, setError] = useState('');
  useEffect(() => { api.get<SecurityData>('/admin/security').then(setData).catch(err => setError(err instanceof Error ? err.message : 'Unable to load security')); }, []);
  return <><div className="admin-topbar"><div><h3>Security</h3><span className="topbar-subtitle">Account and session posture</span></div></div><div className="admin-content">
    {!data && !error && <div className="loading-page"><div className="loading-spinner"/></div>}{error && <div className="error-state"><b>Security data unavailable</b><span>{error}</span></div>}
    {data && <><div className="metric-grid metric-grid-3"><div className="metric-card"><span>Active sessions</span><b>{data.activeSessions.toLocaleString()}</b><small>Unexpired refresh-token sessions</small></div><div className="metric-card"><span>Suspended accounts</span><b>{data.suspendedAccounts.toLocaleString()}</b></div><div className="metric-card"><span>Password resets · 30 days</span><b>{data.passwordResetRequests.toLocaleString()}</b></div></div><div className="panel"><div className="panel-head"><div><span className="section-kicker">Recent signals</span><h4>Security-related activity</h4></div></div>{data.events.length === 0 ? <div className="inline-empty">No recorded security events</div> : <div className="activity-list">{data.events.map(event => <div className="activity-item" key={event.id}><div className="activity-mark"/><div><b>{title(event.action)}</b><span>{event.user.email} · {event.user.role}</span></div><time>{new Date(event.createdAt).toLocaleString()}</time></div>)}</div>}</div></>}
  </div></>;
}
