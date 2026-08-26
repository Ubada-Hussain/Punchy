'use client';
import { useState, FormEvent } from 'react';
import { useRouter } from 'next/navigation';
import { api } from '@/lib/api';

export default function LoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      const { user, accessToken } = await api.login(email, password);
      if (user.role !== 'ADMIN') {
        setError('This portal is for Punchy admin accounts only.');
        setLoading(false);
        return;
      }
      api.saveSession(accessToken, user);
      router.push('/dashboard');
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Login failed');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="login-wrap">
      <div className="login-card">
        {/* Logo mark */}
        <div className="login-mark">
          <svg width="22" height="22" viewBox="0 0 24 24" style={{ fill:'#fff', stroke:'none' }}>
            <path d="M12 3.5l2.6 5.4 5.9.8-4.3 4.2 1 5.9-5.2-2.8-5.2 2.8 1-5.9-4.3-4.2 5.9-.8Z"/>
          </svg>
        </div>

        {/* Title */}
        <div style={{ textAlign:'center' }}>
          <h3 style={{ margin:0, fontSize:18, fontWeight:800 }}>Punchy Admin</h3>
          <p style={{ color:'var(--ink-soft)', fontSize:13, margin:'4px 0 0' }}>Sign in to manage the platform</p>
        </div>

        {/* Error */}
        {error && <div className="error-alert">{error}</div>}

        {/* Form */}
        <form onSubmit={handleSubmit} style={{ display:'flex', flexDirection:'column', gap:12 }}>
          <div className="field">
            <label htmlFor="email">Email</label>
            <div style={{ display:'flex', alignItems:'center', gap:8, background:'var(--surface)', border:'1.5px solid var(--line)', borderRadius:10, padding:'10px 12px' }}>
              <svg width="15" height="15" viewBox="0 0 24 24" style={{ stroke:'var(--ink-faint)', fill:'none', strokeWidth:1.8, strokeLinecap:'round', strokeLinejoin:'round', flexShrink:0 }}>
                <rect x="3.5" y="6" width="17" height="12" rx="1.5"/><path d="M4 7l8 6 8-6"/>
              </svg>
              <input
                id="email"
                type="email"
                value={email}
                onChange={e => setEmail(e.target.value)}
                placeholder="admin@punchy.app"
                required
                autoFocus
                style={{ border:'none', outline:'none', background:'transparent', fontFamily:'inherit', fontSize:13, color:'var(--ink)', width:'100%' }}
              />
            </div>
          </div>

          <div className="field">
            <label htmlFor="password">Password</label>
            <div style={{ display:'flex', alignItems:'center', gap:8, background:'var(--surface)', border:'1.5px solid var(--line)', borderRadius:10, padding:'10px 12px' }}>
              <svg width="15" height="15" viewBox="0 0 24 24" style={{ stroke:'var(--ink-faint)', fill:'none', strokeWidth:1.8, strokeLinecap:'round', strokeLinejoin:'round', flexShrink:0 }}>
                <rect x="5.5" y="10.5" width="13" height="9" rx="1.5"/><path d="M8 10.5V8a4 4 0 0 1 8 0v2.5" strokeLinecap="round"/>
              </svg>
              <input
                id="password"
                type="password"
                value={password}
                onChange={e => setPassword(e.target.value)}
                placeholder="••••••••••••"
                required
                style={{ border:'none', outline:'none', background:'transparent', fontFamily:'inherit', fontSize:13, color:'var(--ink)', width:'100%' }}
              />
            </div>
          </div>

          <button
            type="submit"
            className="btn btn-primary btn-full"
            style={{ padding:12, marginTop:2 }}
            disabled={loading}
          >
            {loading ? (
              <>
                <div className="loading-spinner" style={{ width:16, height:16, borderWidth:2 }}/>
                Signing in…
              </>
            ) : 'Log In'}
          </button>
        </form>

        <div className="cred-hint">
          Admin access only — not a regular user login
        </div>
      </div>
    </div>
  );
}
