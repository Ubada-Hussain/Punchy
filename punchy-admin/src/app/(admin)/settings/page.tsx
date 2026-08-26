'use client';
import { useState } from 'react';

export default function SettingsPage() {
  const [maintenance, setMaintenance] = useState(false);

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
            <span style={{ color:'var(--teal-dark)', fontWeight:700, fontSize:12.5, cursor:'pointer' }}>v2.1.0 — Edit</span>
          </div>
          <div className="settings-row">
            <div>
              <div className="st">Support email</div>
              <div className="ss">Shown in the app's contact support sheet</div>
            </div>
            <span style={{ color:'var(--teal-dark)', fontWeight:700, fontSize:12.5, cursor:'pointer' }}>support@punchy.app — Edit</span>
          </div>
          <div className="settings-row">
            <div>
              <div className="st">Terms & Conditions URL</div>
              <div className="ss">Linked from Profile → Terms & Conditions</div>
            </div>
            <span style={{ color:'var(--teal-dark)', fontWeight:700, fontSize:12.5, cursor:'pointer' }}>trypunchy.site/terms — Edit</span>
          </div>
          <div className="settings-row">
            <div>
              <div className="st">Default trial period</div>
              <div className="ss">Days new businesses get before billing (if enabled)</div>
            </div>
            <span style={{ color:'var(--teal-dark)', fontWeight:700, fontSize:12.5, cursor:'pointer' }}>30 days — Edit</span>
          </div>
        </div>

        <button className="btn btn-primary" style={{ width:'fit-content' }}>
          Save Settings
        </button>
      </div>
    </>
  );
}
