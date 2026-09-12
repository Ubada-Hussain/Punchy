import { Request, Response, NextFunction } from 'express';
import prisma from '../lib/prisma';

// Keep the flag cached briefly so normal API traffic does not create a
// database read for every request while still letting an admin toggle mode
// without restarting the service.
let cachedMode = false;
let cachedAt = 0;
const CACHE_MS = 5000;

export async function maintenanceGuard(req: Request, res: Response, next: NextFunction): Promise<void> {
  // Health checks, login, and all admin endpoints must remain available. The
  // admin is the only role that can disable maintenance mode, so blocking the
  // admin API would lock everyone out permanently.
  const isAdminRoute = req.path === '/admin' || req.path.startsWith('/admin/') || req.path === '/api/admin' || req.path.startsWith('/api/admin/');
  const isAuthBootstrapRoute = req.path === '/auth/login' || req.path === '/api/auth/login' || req.path === '/auth/me' || req.path === '/api/auth/me';
  if (req.path === '/health' || req.path === '/api/health' || isAdminRoute || isAuthBootstrapRoute) {
    next();
    return;
  }

  try {
    if (Date.now() - cachedAt > CACHE_MS) {
      const row = await prisma.adminConfig.findUnique({ where: { key: 'maintenanceMode' } });
      cachedMode = row?.value === true || row?.value === 'true';
      cachedAt = Date.now();
    }
    if (cachedMode) {
      res.status(503).json({
        error: 'Maintenance mode is active',
        maintenance: true,
        message: 'Punchy is temporarily unavailable while we make improvements. Please try again shortly.',
      });
      return;
    }
    next();
  } catch (error) {
    // Do not take the whole platform down if the settings lookup is briefly
    // unavailable; normal route-level error handling remains authoritative.
    next();
  }
}

export function clearMaintenanceCache(): void {
  cachedAt = 0;
}
