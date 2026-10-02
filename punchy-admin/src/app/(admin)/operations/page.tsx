'use client';

import { useEffect, useState } from 'react';
import { api } from '@/lib/api';

type Operations = { checkedAt: string; maintenanceMode: boolean; services: { name: string; status: 'healthy' | 'attention'; detail: string }[] };

export default function OperationsPage() {
  const [data, setData] = useState<Operations | null>(null); const [error, setError] = useState('');
  useEffect(() => { api.get<Operations>('/admin/operations').then(setData).catch(err => setError(err instanceof Error ? err.message : 'Unable to load operations')); }, []);
  return <><div className="admin-topbar"><div><h3>Operations</h3><span className="topbar-subtitle">Sanitized service health</span></div>{data && <span className={`badge ${data.maintenanceMode ? 'b-suspended' : 'b-active'}`}>{data.maintenanceMode ? 'MAINTENANCE' : 'LIVE'}</span>}</div><div className="admin-content">
    {!data && !error && <div className="loading-page"><div className="loading-spinner"/></div>}
    {error && <div className="error-state"><b>Operations unavailable</b><span>{error}</span></div>}
    {data && <><div className="page-intro"><span className="section-kicker">System health</span><h1>Operations center</h1><p>Live checks expose operational state without environment values, credentials, sensitive stack traces, or customer data.</p></div><div className="health-grid">{data.services.map(service => <div className="health-card" key={service.name}><div className={`health-light ${service.status}`}/><div><h3>{service.name}</h3><p>{service.detail}</p></div><span>{service.status}</span></div>)}</div><div className="panel operation-note"><b>Background processing</b><p>Punchy currently runs scheduled notifications and subscription/card lifecycle work in the existing application worker. This view reports that real implementation and does not imply a persistent queue or retries where none exists.</p><small>Checked {new Date(data.checkedAt).toLocaleString()}</small></div></>}
  </div></>;
}
