import 'dotenv/config';
import express from 'express';
import path from 'path';
import cors from 'cors';
import helmet from 'helmet';
import crypto from 'crypto';

import authRouter from './routes/auth';
import businessesRouter from './routes/businesses';
import cardsRouter from './routes/cards';
import punchMethodsRouter from './routes/punchMethods';
import punchRouter from './routes/punch';
import customerRouter from './routes/customer';
import analyticsRouter from './routes/analytics';
import notificationsRouter from './routes/notifications';
import ticketsRouter from './routes/tickets';
import adminRouter from './routes/admin';
import businessPortalRouter from './routes/businessPortal';
import { maintenanceGuard } from './middleware/maintenance';
import prisma from './lib/prisma';
import { processScheduledNotifications, processDailyCustomerReminders } from './services/scheduledNotificationService';
import { processCardLifecycle } from './services/cardLifecycleService';
import { ensureBusinessLocationIndex } from './lib/international';

const app = express();

app.set('trust proxy', 1);
app.use(helmet());
const allowedOrigins = (process.env.CORS_ORIGIN || 'http://localhost:3000')
  .split(',').map((origin) => origin.trim()).filter(Boolean);
app.use(cors({
  origin: (origin, callback) => {
    if (!origin || allowedOrigins.includes('*') || allowedOrigins.includes(origin)) return callback(null, true);
    return callback(new Error('Origin is not allowed by CORS'));
  },
  credentials: true,
}));
app.use((req, res, next) => {
  const requestId = req.header('x-request-id') || crypto.randomUUID();
  res.setHeader('x-request-id', requestId);
  res.locals.requestId = requestId;
  next();
});
app.use(express.json({ limit: '1mb' }));
app.use('/uploads', express.static(path.resolve(process.env.UPLOAD_DIR || '/var/www/punchy-backend/uploads')));
app.use(maintenanceGuard);

// Health check
app.get(['/health', '/api/health'], async (_req, res) => {
  const row = await prisma.adminConfig.findUnique({ where: { key: 'maintenanceMode' } }).catch(() => null);
  res.json({ status: 'ok', maintenance: row?.value === true || row?.value === 'true', timestamp: new Date().toISOString() });
});

// Register routes on both direct paths and /api prefix for clean proxying
const apiRoutes: [string, express.Router][] = [
  ['/auth', authRouter],
  ['/businesses', businessesRouter],
  ['/business', businessPortalRouter],
  ['/cards', cardsRouter],
  ['/punch-methods', punchMethodsRouter],
  ['/punch', punchRouter],
  ['/customer', customerRouter],
  ['/analytics', analyticsRouter],
  ['/notifications', notificationsRouter],
  ['/tickets', ticketsRouter],
  ['/admin', adminRouter],
];

for (const [routePath, router] of apiRoutes) {
  app.use(routePath, router);
  app.use(`/api${routePath}`, router);
}

// 404 handler
app.use((_req, res) => res.status(404).json({ error: 'Route not found' }));

// Global error handler
app.use((err: Error, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  const requestId = res.locals.requestId;
  console.error(JSON.stringify({ requestId, name: err.name, message: err.message }));
  res.status(500).json({ error: 'Internal server error', requestId });
});

const PORT = parseInt(process.env.PORT || '4000');
const weakSecrets = ['change-me-to-a-long-random-secret', 'change-me-to-another-long-random-secret'];
if (process.env.NODE_ENV === 'production' && (!process.env.JWT_SECRET || !process.env.JWT_REFRESH_SECRET || weakSecrets.includes(process.env.JWT_SECRET) || weakSecrets.includes(process.env.JWT_REFRESH_SECRET))) {
  throw new Error('Production JWT secrets are missing or use a default value. Refusing to start.');
}
app.listen(PORT, () => console.log(`Punchy API listening on port ${PORT}`));
void ensureBusinessLocationIndex(prisma);
if (process.env.NODE_ENV !== 'test') {
  const intervalMs = 30_000;
  void processCardLifecycle().catch((error) => console.error('Initial card lifecycle pass failed', error));
  setInterval(() => {
    void processScheduledNotifications().catch((error) => console.error('Scheduled notification worker failed', error));
    void processDailyCustomerReminders().catch((error) => console.error('Daily customer reminders worker failed', error));
    void processCardLifecycle().catch((error) => console.error('Card lifecycle worker failed', error));
  }, intervalMs).unref();
}
export default app;
