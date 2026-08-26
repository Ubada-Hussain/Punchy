const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000';

function getToken(): string | null {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem('punchy_admin_token');
}

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const token = getToken();
  const res = await fetch(`${API_BASE}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(options.headers ?? {}),
    },
  });

  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    throw new Error(body.error || `HTTP ${res.status}`);
  }

  return res.json() as Promise<T>;
}

export const api = {
  get:    <T>(path: string) => request<T>(path),
  post:   <T>(path: string, body?: unknown) => request<T>(path, { method: 'POST',  body: JSON.stringify(body) }),
  patch:  <T>(path: string, body?: unknown) => request<T>(path, { method: 'PATCH', body: JSON.stringify(body) }),
  put:    <T>(path: string, body?: unknown) => request<T>(path, { method: 'PUT',   body: JSON.stringify(body) }),
  delete: <T>(path: string) => request<T>(path, { method: 'DELETE' }),

  // Auth helpers
  login: (email: string, password: string) =>
    api.post<{ user: AdminUser; accessToken: string; refreshToken: string }>('/auth/login', { email, password }),

  saveSession: (token: string, user: AdminUser) => {
    localStorage.setItem('punchy_admin_token', token);
    localStorage.setItem('punchy_admin_user', JSON.stringify(user));
  },

  clearSession: () => {
    localStorage.removeItem('punchy_admin_token');
    localStorage.removeItem('punchy_admin_user');
  },

  getSession: (): AdminUser | null => {
    if (typeof window === 'undefined') return null;
    const raw = localStorage.getItem('punchy_admin_user');
    return raw ? JSON.parse(raw) : null;
  },
};

// ── Shared Types ─────────────────────────────────────────────────────────────

export interface AdminUser {
  id: string;
  email: string;
  role: 'ADMIN';
}

export interface Business {
  id: string;
  name: string;
  category: string;
  logo?: string;
  description?: string;
  website?: string;
  status: 'PENDING' | 'APPROVED' | 'SUSPENDED';
  subscriptionTier: 'FREE' | 'PREMIUM';
  locations: { address: string; lat?: number; lng?: number }[];
  createdAt: string;
  user?: { email: string; phone?: string; createdAt: string };
  loyaltyCards?: LoyaltyCard[];
  _count?: { loyaltyCards: number };
}

export interface LoyaltyCard {
  id: string;
  businessId: string;
  title: string;
  punchesRequired: number;
  rewardDescription: string;
  visualStyle: { primaryColor: string; bgColor: string; iconType: string };
  validUntil?: string;
  isActive: boolean;
  createdAt: string;
  punchMethods?: PunchMethod[];
  _count?: { customerCards: number };
}

export interface PunchMethod {
  id: string;
  cardId: string;
  type: 'QR' | 'NFC';
  identifier: string;
  label?: string;
  isActive: boolean;
  createdAt: string;
}

export interface User {
  id: string;
  email: string;
  phone?: string;
  role: 'CUSTOMER' | 'BUSINESS' | 'ADMIN' | 'STAFF';
  isBlocked: boolean;
  isStaffActive?: boolean;
  businessId?: string;
  createdAt: string;
  businessProfile?: { name: string; status: string };
}

export interface SupportTicket {
  id: string;
  authorId: string;
  subject: string;
  body: string;
  status: 'OPEN' | 'IN_PROGRESS' | 'RESOLVED';
  createdAt: string;
  resolvedAt?: string;
  author?: { email: string; role: string };
}

export interface Notification {
  id: string;
  targetType: string;
  title: string;
  body: string;
  sentAt?: string;
  createdAt: string;
  creator?: { email: string; role: string };
}

export interface PlatformAnalytics {
  totals: {
    totalBusinesses: number;
    totalCustomers: number;
    totalPunches: number;
    totalRedemptions: number;
    pendingBusinesses: number;
  };
  period: { days: number; newBusinesses: number; newCustomers: number; recentPunches: number };
  topBusinesses: { id: string; name: string; category: string; logo?: string; totalPunches: number }[];
}
