"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
require("dotenv/config");
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const helmet_1 = __importDefault(require("helmet"));
const auth_1 = __importDefault(require("./routes/auth"));
const businesses_1 = __importDefault(require("./routes/businesses"));
const cards_1 = __importDefault(require("./routes/cards"));
const punchMethods_1 = __importDefault(require("./routes/punchMethods"));
const punch_1 = __importDefault(require("./routes/punch"));
const customer_1 = __importDefault(require("./routes/customer"));
const analytics_1 = __importDefault(require("./routes/analytics"));
const notifications_1 = __importDefault(require("./routes/notifications"));
const tickets_1 = __importDefault(require("./routes/tickets"));
const admin_1 = __importDefault(require("./routes/admin"));
const businessPortal_1 = __importDefault(require("./routes/businessPortal"));
const app = (0, express_1.default)();
app.use((0, helmet_1.default)());
app.use((0, cors_1.default)({ origin: process.env.CORS_ORIGIN || '*' }));
app.use(express_1.default.json());
// Health check
app.get(['/health', '/api/health'], (_req, res) => res.json({ status: 'ok', timestamp: new Date().toISOString() }));
// Register routes on both direct paths and /api prefix for clean proxying
const apiRoutes = [
    ['/auth', auth_1.default],
    ['/businesses', businesses_1.default],
    ['/business', businessPortal_1.default],
    ['/cards', cards_1.default],
    ['/punch-methods', punchMethods_1.default],
    ['/punch', punch_1.default],
    ['/customer', customer_1.default],
    ['/analytics', analytics_1.default],
    ['/notifications', notifications_1.default],
    ['/tickets', tickets_1.default],
    ['/admin', admin_1.default],
];
for (const [routePath, router] of apiRoutes) {
    app.use(routePath, router);
    app.use(`/api${routePath}`, router);
}
// 404 handler
app.use((_req, res) => res.status(404).json({ error: 'Route not found' }));
// Global error handler
app.use((err, _req, res, _next) => {
    console.error(err);
    res.status(500).json({ error: 'Internal server error' });
});
const PORT = parseInt(process.env.PORT || '4000');
app.listen(PORT, () => console.log(`🟠 Punchy API running on http://localhost:${PORT}`));
exports.default = app;
//# sourceMappingURL=index.js.map