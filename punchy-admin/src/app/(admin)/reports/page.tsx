'use client';

import { useState } from 'react';
import { api } from '@/lib/api';

const reports = [
  { id: 'customers', title: 'Customer directory', description: 'Customer IDs, contact fields, country, account status and registration date.' },
  { id: 'subscriptions', title: 'Subscription status', description: 'Historical subscriptions with plan, status, original price and effective dates.' },
  { id: 'payments', title: 'Manual payment reconciliation', description: 'Transaction references, submitted amounts, review state and reviewer.' },
  { id: 'support', title: 'Support performance', description: 'Ticket ownership, state, created and resolved timestamps.' },
  { id: 'activity', title: 'Owner activity', description: 'Read-only activity events with actor, action, timestamp and sanitized metadata.' },
] as const;

export default function ReportsPage() {
  const [downloading, setDownloading] = useState('');
  const [error, setError] = useState('');
  async function download(id: string) {
    setDownloading(id); setError('');
    try { await api.download(`/admin/reports/${id}.csv`); }
    catch (err) { setError(err instanceof Error ? err.message : 'Export failed'); }
    finally { setDownloading(''); }
  }
  return <><div className="admin-topbar"><div><h3>Reports</h3><span className="topbar-subtitle">Bounded, audited CSV exports</span></div></div><div className="admin-content">
    <div className="page-intro"><span className="section-kicker">Reporting</span><h1>Operational exports</h1><p>Every download is generated from the current database and recorded in the audit trail. Exports are capped at 5,000 rows for safe synchronous delivery.</p></div>
    {error && <div className="notice notice-error">{error}</div>}
    <div className="report-grid">{reports.map(report => <div className="report-card" key={report.id}><div className="report-icon">CSV</div><div><h3>{report.title}</h3><p>{report.description}</p></div><button className="btn btn-primary" disabled={Boolean(downloading)} onClick={() => download(report.id)}>{downloading === report.id ? 'Preparing…' : 'Export CSV'}</button></div>)}</div>
  </div></>;
}
