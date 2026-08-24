'use client';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { api } from '@/lib/api';

interface NavItem {
  href: string;
  label: string;
  icon: string;
  badge?: number;
}

const NAV: { section?: string; items: NavItem[] }[] = [
  {
    items: [
      { href: '/dashboard', label: 'Dashboard', icon: '▦' },
    ],
  },
  {
    section: 'Platform',
    items: [
      { href: '/businesses', label: 'Businesses', icon: '🏪' },
      { href: '/customers', label: 'Customers', icon: '👥' },
      { href: '/analytics', label: 'Analytics', icon: '📊' },
    ],
  },
  {
    section: 'Operations',
    items: [
      { href: '/nfc-qr', label: 'NFC & QR', icon: '📲' },
      { href: '/notifications', label: 'Notifications', icon: '🔔' },
      { href: '/support', label: 'Support', icon: '🎫' },
      { href: '/moderation', label: 'Moderation', icon: '🛡️' },
    ],
  },
  {
    section: 'Admin',
    items: [
      { href: '/settings', label: 'Settings', icon: '⚙️' },
    ],
  },
];

export default function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();

  function handleLogout() {
    api.clearSession();
    router.push('/login');
  }

  return (
    <aside className="app-sidebar">
      {/* Logo */}
      <div className="sidebar-logo">
        <div className="sidebar-logo-mark">P</div>
        <span className="sidebar-logo-text">Punchy</span>
        <span className="sidebar-logo-badge">Admin</span>
      </div>

      {/* Navigation */}
      <nav className="sidebar-nav">
        {NAV.map((group, gi) => (
          <div key={gi}>
            {group.section && (
              <div className="sidebar-section-label">{group.section}</div>
            )}
            {group.items.map(item => {
              const active = pathname === item.href || pathname.startsWith(item.href + '/');
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  className={`sidebar-item${active ? ' active' : ''}`}
                >
                  <span style={{ fontSize: 16 }}>{item.icon}</span>
                  {item.label}
                  {item.badge != null && (
                    <span className="sidebar-badge">{item.badge}</span>
                  )}
                </Link>
              );
            })}
          </div>
        ))}
      </nav>

      {/* Footer */}
      <div className="sidebar-footer">
        <button className="sidebar-item" onClick={handleLogout} style={{ color: '#DC2626' }}>
          <span style={{ fontSize: 16 }}>↩</span>
          Sign out
        </button>
      </div>
    </aside>
  );
}
