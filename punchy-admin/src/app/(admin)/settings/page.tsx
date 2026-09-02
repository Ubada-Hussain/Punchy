'use client';
import { useEffect, useState } from 'react';
import { api } from '@/lib/api';

export default function SettingsPage() {
  const [maintenance, setMaintenance] = useState(false);
  const [supportEmail, setSupportEmail] = useState('ubadahussain23@gmail.com');
  const [minimumAppVersion, setMinimumAppVersion] = useState('2.1.0');
  const [termsUrl, setTermsUrl] = useState('https://www.trypunchy.site/terms');
  const [trialPeriodDays, setTrialPeriodDays] = useState('30');
  const [saving, setSaving] = useState(false);
  useEffect(() => { api.get<Record<string, unknown>>('/admin/config').then(c => { if (typeof c.maintenanceMode === 'boolean') setMaintenance(c.maintenanceMode); if (typeof c.supportEmail === 'string') setSupportEmail(c.supportEmail); if (typeof c.minimumAppVersion === 'string') setMinimumAppVersion(c.minimumAppVersion); if (typeof c.termsUrl === 'string') setTermsUrl(c.termsUrl); if (typeof c.trialPeriodDays === 'number' || typeof c.trialPeriodDays === 'string') setTrialPeriodDays(String(c.trialPeriodDays)); }).catch(console.error); }, []);
  async function save() {
    setSaving(true);
      try { await api.patch('/admin/config', { maintenanceMode: maintenance, supportEmail, minimumAppVersion, termsUrl, trialPeriodDays: Number(trialPeriodDays) || 0 }); alert('Settings saved'); }
    catch (e) { alert(e instanceof Error ? e.message : 'Failed to save settings'); }
    finally { setSaving(false); }
  }

  return (
    <>
      <div className="admin-topbar">
        <h3>Platform Settings</h3>
      </div>
      <div className="admin-content">
        <div className="panel" style={{ borderColor: 'var(--coral)', background: 'rgba(255,107,87,.06)' }}>
          <div className="settings-row" style={{ border: 'none', padding: '2px 0' }}>
            <div>
              <div className="st">Maintenance Mode</div>
              <div className="ss">When ON, all API requests return 503 and users see the maintenance screen</div>
            </div>
            <button
              className={`toggle ${maintenance ? 'on' : ''}`}
              onClick={() => setMaintenance(!maintenance)}
              type="button"
            />
          </div>
        </div>

        <div className="panel">
          <div className="settings-row">
            <div>
              <div className="st">Minimum app version</div>
              <div className="ss">Forces update screen below this version</div>
            </div>
            <input value={minimumAppVersion} onChange={e => setMinimumAppVersion(e.target.value)} style={{ width:150 }} />
          </div>
          <div className="settings-row">
            <div>
              <div className="st">Support email</div>
              <div className="ss">Shown in the app's contact support sheet</div>
            </div>
              <input value={supportEmail} onChange={e => setSupportEmail(e.target.value)} style={{ width:240 }} />
          </div>
          <div className="settings-row">
            <div>
              <div className="st">Terms & Conditions URL</div>
              <div className="ss">Linked from Profile → Terms & Conditions</div>
            </div>
            <input value={termsUrl} onChange={e => setTermsUrl(e.target.value)} style={{ width:260 }} />
          </div>
          <div className="settings-row">
            <div>
              <div className="st">Default trial period</div>
              <div className="ss">Days new businesses get before billing (if enabled)</div>
            </div>
            <input value={trialPeriodDays} onChange={e => setTrialPeriodDays(e.target.value)} style={{ width:90 }} />
          </div>
        </div>

        <button className="btn btn-primary" style={{ width:'fit-content' }} onClick={save} disabled={saving}>
          {saving ? 'Saving…' : 'Save Settings'}
        </button>
      </div>
    </>
  );
}
