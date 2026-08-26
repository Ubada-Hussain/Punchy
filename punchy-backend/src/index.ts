import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';

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

const app = express();

app.use(helmet());
app.use(cors({ origin: process.env.CORS_ORIGIN || '*' }));
app.use(express.json());

// Health check
app.get(['/health', '/api/health'], (_req, res) => res.json({ status: 'ok', timestamp: new Date().toISOString() }));

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
  console.error(err);
  res.status(500).json({ error: 'Internal server error' });
});

const PORT = parseInt(process.env.PORT || '4000');
app.listen(PORT, () => console.log(`🟠 Punchy API running on http://localhost:${PORT}`));

export default app;
