'use client';
import { useEffect, useState } from 'react';
import { api } from '@/lib/api';

const DEFAULT_SETTINGS = [
  { key: 'defaultPunchLimit', label: 'Default Punch Limit', type: 'number', description: 'Default number of punches required for new loyalty cards.' },
  { key: 'maintenanceMode', label: 'Maintenance Mode', type: 'boolean', description: 'When enabled, the API returns 503 for all requests.' },
  { key: 'appVersion', label: 'App Version', type: 'text', description: 'Current published version of the Punchy mobile app.' },
];

export default function SettingsPage() {
  const [config, setConfig] = useState<Record<string, unknown>>({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState<string | null>(null);
  const [saved, setSaved] = useState<string | null>(null);

  useEffect(() => {
    api.get<Record<string, unknown>>('/admin/config')
      .then(setConfig)
      .catch(console.error)
      .finally(() => setLoading(false));
  }, []);

  async function saveSetting(key: string, value: unknown) {
    setSaving(key);
    try {
      await api.put(`/admin/config/${key}`, { value });
      setConfig(c => ({ ...c, [key]: value }));
      setSaved(key);
      setTimeout(() => setSaved(null), 2000);
    } catch (err) { console.error(err); }
    finally { setSaving(null); }
  }

  return (
    <div className="page-content">
      <div className="page-header">
        <h1 className="page-title">Settings</h1>
        <p className="page-subtitle">Platform-wide configuration</p>
      </div>

      {loading ? (
        <div className="loading-page"><div className="loading-spinner" /></div>
      ) : (
        <>
          <div className="card card-padded mb-6">
            <h2 className="text-lg font-semibold mb-5">Platform Configuration</h2>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 24 }}>
              {DEFAULT_SETTINGS.map(s => {
                const val = config[s.key];
                return (
                  <div key={s.key} style={{ display: 'flex', alignItems: 'center', gap: 24, paddingBottom: 20, borderBottom: '1px solid #F0F0EE' }}>
                    <div style={{ flex: 1 }}>
                      <div className="font-medium">{s.label}</div>
                      <div className="text-sm text-muted mt-1">{s.description}</div>
                    </div>
                    <div className="flex items-center gap-3" style={{ flexShrink: 0 }}>
                      {s.type === 'boolean' ? (
                        <label style={{ display: 'flex', alignItems: 'center', gap: 10, cursor: 'pointer' }}>
                          <div
                            style={{
                              width: 44, height: 24, borderRadius: 12,
                              background: val ? '#FF6B35' : '#D4D4D0',
                              position: 'relative', transition: 'background 200ms',
                              cursor: 'pointer',
                            }}
                            onClick={() => saveSetting(s.key, !val)}
                          >
                            <div style={{
                              position: 'absolute', top: 3, left: val ? 23 : 3,
                              width: 18, height: 18, borderRadius: '50%', background: 'white',
                              transition: 'left 200ms', boxShadow: '0 1px 3px rgba(0,0,0,0.2)',
                            }} />
                          </div>
                          <span className="text-sm font-medium">{val ? 'Enabled' : 'Disabled'}</span>
                        </label>
                      ) : (
                        <div className="flex gap-2">
                          <input
                            type={s.type}
                            className="form-input"
                            style={{ width: 160 }}
                            value={String(val ?? '')}
                            onChange={e => setConfig(c => ({ ...c, [s.key]: s.type === 'number' ? Number(e.target.value) : e.target.value }))}
                          />
                          <button
                            className="btn btn-primary btn-sm"
                            onClick={() => saveSetting(s.key, config[s.key])}
                            disabled={saving === s.key}
                          >
                            {saved === s.key ? '✓ Saved' : saving === s.key ? '…' : 'Save'}
                          </button>
                        </div>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Future: paid tier placeholder */}
          <div className="card card-padded" style={{ borderStyle: 'dashed', background: '#FFFBEB', borderColor: '#FDE68A' }}>
            <div className="flex items-center gap-3 mb-3">
              <span style={{ fontSize: 24 }}>💰</span>
              <h2 className="text-lg font-semibold">Financial & Monetisation</h2>
              <span className="badge badge-pending">Future</span>
            </div>
            <p className="text-sm text-muted">
              This section is reserved for future monetisation features, including the Premium Setup Service add-on
              and subscription tier management. The data model already supports <code>subscriptionTier</code> on all
              business profiles — no schema migration needed when this is introduced.
            </p>
          </div>
        </>
      )}
    </div>
  );
}
