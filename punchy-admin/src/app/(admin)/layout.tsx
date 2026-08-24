import Sidebar from '@/components/Sidebar';
import type { Metadata } from 'next';

export const metadata: Metadata = { title: 'Admin' };

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="app-shell">
      <Sidebar />
      <main className="app-main">
        {children}
      </main>
    </div>
  );
}
