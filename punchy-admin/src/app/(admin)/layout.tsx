'use client';

import Sidebar from '@/components/Sidebar';
import { useEffect, useState } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import { api } from '@/lib/api';

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const router = useRouter();
  const pathname = usePathname();
  const [authorized, setAuthorized] = useState(false);

  useEffect(() => {
    const user = api.getSession();
    if (!user || user.role !== 'ADMIN') { setAuthorized(false); router.replace('/login'); return; }
    api.get<{ user: { role: string } }>('/auth/me')
      .then(({ user: liveUser }) => {
        if (liveUser.role === 'ADMIN') setAuthorized(true);
        else { api.clearSession(); setAuthorized(false); router.replace('/login'); }
      })
      .catch(() => setAuthorized(false));
  }, [pathname, router]);

  if (!authorized) {
    return (
      <div style={{
        height: '100vh',
        width: '100vw',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        background: '#0e1726',
        color: '#fff',
        fontFamily: 'system-ui, sans-serif'
      }}>
        <div style={{ textAlign: 'center' }}>
          <div className="loading-spinner" style={{ width: 32, height: 32, borderWidth: 3, margin: '0 auto 16px' }} />
          <p style={{ margin: 0, fontSize: 14, opacity: 0.7 }}>Verifying authentication...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="app-shell">
      <Sidebar />
      <main className="app-main">
        {children}
      </main>
    </div>
  );
}
