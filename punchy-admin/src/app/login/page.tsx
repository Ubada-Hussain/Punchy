'use client';
import { useState, FormEvent } from 'react';
import { useRouter } from 'next/navigation';
import { api } from '@/lib/api';
import styles from './login.module.css';

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
    <div className={styles.page}>
      <div className={styles.card}>
        <div className={styles.logo}>
          <div className={styles.logoMark}>P</div>
          <span className={styles.logoText}>Punchy</span>
          <span className={styles.logoBadge}>Admin</span>
        </div>

        <h1 className={styles.title}>Welcome back</h1>
        <p className={styles.sub}>Sign in to the Punchy admin dashboard</p>

        {error && (
          <div className="alert alert-danger" style={{ marginBottom: 20 }}>
            {error}
          </div>
        )}

        <form onSubmit={handleSubmit} className={styles.form}>
          <div className="form-group">
            <label className="form-label" htmlFor="email">Email address</label>
            <input
              id="email"
              type="email"
              className="form-input"
              value={email}
              onChange={e => setEmail(e.target.value)}
              placeholder="admin@punchy.app"
              required
              autoFocus
            />
          </div>

          <div className="form-group">
            <label className="form-label" htmlFor="password">Password</label>
            <input
              id="password"
              type="password"
              className="form-input"
              value={password}
              onChange={e => setPassword(e.target.value)}
              placeholder="••••••••"
              required
            />
          </div>

          <button type="submit" className="btn btn-primary w-full" disabled={loading}>
            {loading ? (
              <><span className="loading-spinner" style={{ width: 16, height: 16, borderWidth: 2 }} /> Signing in…</>
            ) : 'Sign in'}
          </button>
        </form>

        <p className={styles.hint}>
          Not an admin? Download the{' '}
          <a href="/" className={styles.hintLink}>Punchy app →</a>
        </p>
      </div>
    </div>
  );
}
