'use client';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { api } from '@/lib/api';

const Icons = {
  grid: (
    <svg className="icon" width="16" height="16" viewBox="0 0 24 24">
      <rect x="3" y="3" width="8" height="8" rx="1.5"/>
      <rect x="13" y="3" width="8" height="8" rx="1.5"/>
      <rect x="3" y="13" width="8" height="8" rx="1.5"/>
      <rect x="13" y="13" width="8" height="8" rx="1.5"/>
    </svg>
  ),
  store: (
    <svg className="icon" width="16" height="16" viewBox="0 0 24 24">
      <path d="M4 9l1-4h14l1 4" strokeLinecap="round" strokeLinejoin="round"/>
      <path d="M4 9a2.2 2.2 0 0 0 4.4.2A2.2 2.2 0 0 0 12 9a2.2 2.2 0 0 0 3.6.2A2.2 2.2 0 0 0 20 9" strokeLinecap="round"/>
      <path d="M5 9v9a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V9" strokeLinecap="round"/>
    </svg>
  ),
  users: (
    <svg className="icon" width="16" height="16" viewBox="0 0 24 24">
      <circle cx="9" cy="8" r="3"/>
      <path d="M3.5 19c.8-3.2 3-4.8 5.5-4.8s4.7 1.6 5.5 4.8" strokeLinecap="round"/>
      <circle cx="17" cy="9" r="2.3"/>
      <path d="M15.5 14.3c2 .2 3.5 1.6 4 4.2" strokeLinecap="round"/>
    </svg>
  ),
  chart: (
    <svg className="icon" width="16" height="16" viewBox="0 0 24 24">
      <path d="M4 20V10M10 20V4M16 20v-7M20 20H4" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  ),
  flag: (
    <svg className="icon" width="16" height="16" viewBox="0 0 24 24">
      <path d="M5 21V4" strokeLinecap="round"/>
      <path d="M5 4h11l-2.5 3.5L16 11H5" strokeLinejoin="round"/>
    </svg>
  ),
  nfc: (
    <svg className="icon" width="16" height="16" viewBox="0 0 24 24">
      <path d="M6 16a8 8 0 0 1 0-8" strokeLinecap="round"/>
      <path d="M9 13.5a3.5 3.5 0 0 1 0-3" strokeLinecap="round"/>
      <circle cx="13" cy="12" r="1.3" fill="currentColor" stroke="none"/>
      <path d="M17 8a8 8 0 0 1 0 8" strokeLinecap="round"/>
    </svg>
  ),
  bell: (
    <svg className="icon" width="16" height="16" viewBox="0 0 24 24">
      <path d="M6 9a6 6 0 0 1 12 0c0 4 1.5 5.5 1.5 5.5H4.5S6 13 6 9Z" strokeLinejoin="round"/>
      <path d="M9.5 19a2.5 2.5 0 0 0 5 0"/>
    </svg>
  ),
  ticket: (
    <svg className="icon" width="16" height="16" viewBox="0 0 24 24">
      <path d="M3 9a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2v1.5a1.6 1.6 0 0 0 0 3V16a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-2.5a1.6 1.6 0 0 0 0-3Z" strokeLinejoin="round"/>
      <path d="M14 7v10" strokeDasharray="2 2"/>
    </svg>
  ),
  settings: (
    <svg className="icon" width="16" height="16" viewBox="0 0 24 24">
      <circle cx="12" cy="12" r="3"/>
      <path d="M12 3v2.2M12 18.8V21M4.9 4.9l1.6 1.6M17.5 17.5l1.6 1.6M3 12h2.2M18.8 12H21M4.9 19.1l1.6-1.6M17.5 6.5l1.6-1.6" strokeLinecap="round"/>
    </svg>
  ),
  logout: (
    <svg className="icon" width="16" height="16" viewBox="0 0 24 24">
      <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" strokeLinecap="round"/>
      <path d="M16 17l5-5-5-5" strokeLinecap="round" strokeLinejoin="round"/>
      <path d="M21 12H9" strokeLinecap="round"/>
    </svg>
  ),
  star: (
    <svg width="17" height="17" viewBox="0 0 24 24" style={{fill:'#fff',stroke:'none'}}>
      <path d="M12 3.5l2.6 5.4 5.9.8-4.3 4.2 1 5.9-5.2-2.8-5.2 2.8 1-5.9-4.3-4.2 5.9-.8Z"/>
    </svg>
  ),
};

const NAV = [
  { href: '/dashboard',     label: 'Dashboard',     icon: 'grid'     },
  { href: '/businesses',    label: 'Businesses',     icon: 'store'    },
  { href: '/customers',     label: 'Customers',      icon: 'users'    },
  { href: '/analytics',     label: 'Analytics',      icon: 'chart'    },
  { href: '/moderation',    label: 'Moderation',     icon: 'flag'     },
  { href: '/nfc-qr',        label: 'NFC & QR',       icon: 'nfc'      },
  { href: '/notifications', label: 'Notifications',  icon: 'bell'     },
  { href: '/support',       label: 'Support',        icon: 'ticket'   },
  { href: '/settings',      label: 'Settings',       icon: 'settings' },
] as const;

export default function Sidebar() {
  const pathname = usePathname();
  const router   = useRouter();
  const user     = api.getSession();

  function handleLogout() {
    api.clearSession();
    router.replace('/login');
  }

  const initials = user?.email?.slice(0, 2).toUpperCase() ?? 'AD';

  return (
    <aside className="admin-sidebar">
      {/* Logo */}
      <div className="side-logo">
        <div className="side-logo-mark">{Icons.star}</div>
        <b>Punchy Admin</b>
      </div>

      {/* Navigation */}
      <nav className="side-nav">
        {NAV.map(item => {
          const active = pathname === item.href || pathname.startsWith(item.href + '/');
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`side-item${active ? ' active' : ''}`}
            >
              {Icons[item.icon as keyof typeof Icons]}
              {item.label}
            </Link>
          );
        })}
      </nav>

      {/* Footer */}
      <div className="side-foot">
        <div className="side-foot-av">{initials}</div>
        <div className="side-foot-info">
          <b>{user?.email?.split('@')[0] ?? 'Admin'}</b>
          {user?.email ?? 'admin@punchy.app'}
        </div>
      </div>

      <button
        className="side-item"
        onClick={handleLogout}
        style={{ color: 'rgba(255,255,255,0.5)', marginTop: 4 }}
      >
        {Icons.logout}
        Sign out
      </button>
    </aside>
  );
}
