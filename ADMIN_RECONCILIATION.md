# Punchy Admin reconciliation report

Discovery date: 2026-09-27

This report maps the target Admin specification to the implementation that existed before the current Admin evolution work. Existing systems remain the source of truth unless explicitly noted.

| Target feature | Current implementation | Current location | Existing API / model | Classification | Action |
| --- | --- | --- | --- | --- | --- |
| Dashboard | Four live platform counters | `/dashboard`, `punchy-admin/src/app/(admin)/dashboard/page.tsx` | `GET /analytics/platform`; `User`, `BusinessProfile`, `PunchTransaction`, `Redemption` | Partial | Extend the live aggregate; do not use the static `growthData` in `/admin/stats` |
| Customers | Search, suspend/restore, destructive deletion, detail page | `/customers`, `/customers/[id]` | `GET /admin/customers`, `GET /admin/customers/:id`, `POST /admin/customers/:id/toggle-block`; `User`, `CustomerCard`, `ActivityLog` | Partial | Extend the same endpoints with pagination, filters, unified detail, and safe actions |
| Businesses | List, detail, suspend/restore, delete | `/businesses`, `/businesses/[id]` | `/businesses`; `BusinessProfile`, `User`, `LoyaltyCard` | Already exists / partial | Keep as the business-owner management surface; reuse from search and customer context |
| Subscription engine | Trial creation, active subscriptions, manual assignment, expiry | `/business-subscriptions` and Flutter business subscription screen | `/subscriptions/business/current`, `/subscriptions/businesses`, `/subscriptions/businesses/:businessId/assign`; `BusinessSubscription` | Partial | Keep `BusinessSubscription` authoritative and introduce one transition path instead of another engine |
| Plans and country pricing | Monthly/yearly country pricing | `/subscription-pricing` | `/subscriptions/pricing`; `CountrySubscriptionPricing` | Partial | Extend existing pricing; preserve subscription price snapshots |
| Manual payment methods | Configurable methods, activation, account/bank/IBAN/instructions/logo | `/payment-methods` | `/subscriptions/payment-methods`; `PaymentMethod` | Already exists | Keep and improve validation/UI only |
| Payment submissions | Idempotent submission, duplicate transaction protection, approve/reject, atomic subscription activation | `/payment-submissions` | `/subscriptions/payments`; `SubscriptionPayment`, `BusinessSubscription` | Partial | Extend this workflow; do not add another payment model |
| Support / complaints | Ticket creation, list, detail, status update, idempotency | `/support` | `/tickets`; `SupportTicket` | Partial | Extend the same ticket system with richer statuses/messages later |
| Communication | In-app/push notification creation, user/segment targeting, scheduling worker | `/notifications` | `/notifications`; `Notification`; `scheduledNotificationService` | Partial | Keep this infrastructure and add delivery metadata only when supported |
| Global search | Per-page search only | Customer/business/subscription pages | Existing list APIs | Missing centrally | Build one federated Admin search endpoint and one shared search UI |
| Analytics | Platform totals, period counts, top businesses, business analytics | `/analytics` | `/analytics/platform`, `/analytics/business/:businessId` | Partial | Extend real aggregates; never use seeded/static figures |
| Reports / CSV | No Admin report/export surface | — | Existing models can supply bounded exports | Missing | Add audited, bounded CSV reports using existing data |
| Coupons | No equivalent found | — | — | Missing | Defer until the core subscription/payment audit foundation is in place |
| Content and settings | Key/value platform config for maintenance, support, version, terms, trial | `/settings` | `/admin/config`; `AdminConfig` | Partial | Extend the existing versionless config system; do not add a parallel settings store |
| Feature flags | No equivalent found | — | — | Missing | Defer; future implementation should use one centralized model/service |
| Operations center | `/health`, request IDs, slow-request logging, scheduled in-process workers | no Admin page | `GET /health`; `scheduledNotificationService`, `cardLifecycleService` | Partial | Surface sanitized live health and worker metadata; do not expose secrets |
| Background jobs | In-process scheduled notification/card lifecycle loops | backend startup | service functions only; no job model | Partial | Surface what is real; do not pretend a persistent queue exists |
| Security center | Password policy, rate limiting, refresh tokens, suspension checks | no Admin page | auth routes/middleware; `RefreshToken`, `PasswordResetOtp`, `ActivityLog` | Partial | Expose safe security aggregates from existing records and close auth gaps incrementally |
| Admin authentication | ADMIN role with JWT access/refresh tokens | hidden Admin login route and Admin layout | `/auth/login`, `/auth/me`, `/auth/refresh`; `User`, `RefreshToken` | Partial | Preserve auth, isolate Admin entry, then add owner/2FA/session hardening without replacing JWT auth |
| Audit log | `ActivityLog` records several Admin/customer/business actions | no Admin audit page | `ActivityLog` | Partial | Treat it as the current source; add a read-only Admin view and record new Admin operations |
| Read-only impersonation | No equivalent found | — | — | Missing | Defer until recent-reauth and dedicated session primitives exist |
| Bulk operations | No equivalent found | — | — | Missing | Defer until persistent job tracking exists; never add bulk permanent delete |
| Gateway-ready architecture | Manual payments only | subscription routes | `SubscriptionPayment` | Missing provider-event layer | Do not integrate a gateway; add provider-neutral entities only with a real provider project |
| NFC / QR operations | Method inventory | `/nfc-qr` | `/punch-methods`; `PunchMethod` | Exists under target Operations concept | Reorganize navigation; do not duplicate |

## Existing source-of-truth chains

```text
Customers
→ /customers and /customers/[id]
→ CustomersPage / CustomerDetailPage
→ /admin/customers and /admin/customers/:id
→ admin router
→ User, CustomerCard, ActivityLog, SupportTicket

Subscriptions and pricing
→ /business-subscriptions and /subscription-pricing
→ BusinessSubscriptionsPage / SubscriptionPricingPage
→ /subscriptions/businesses and /subscriptions/pricing
→ subscriptions router
→ BusinessSubscription, CountrySubscriptionPricing

Manual payments
→ /payment-methods and /payment-submissions
→ PaymentMethodsPage / PaymentSubmissionsPage
→ /subscriptions/payment-methods and /subscriptions/payments
→ subscriptions router
→ PaymentMethod, SubscriptionPayment, BusinessSubscription

Support
→ /support
→ SupportPage
→ /tickets
→ tickets router
→ SupportTicket

Communication
→ /notifications
→ NotificationsPage
→ /notifications
→ notifications router + scheduledNotificationService
→ Notification

Settings
→ /settings
→ SettingsPage
→ /admin/config
→ admin router + maintenance middleware
→ AdminConfig
```

## Conflicts and consolidation decisions

- `/admin/businesses` and `/businesses` overlap. The web Admin currently uses `/businesses`; no third business-management API should be added.
- `/admin/announcements` overlaps `/notifications`. `/notifications` is the broader current implementation and is the communication source of truth.
- `/admin/stats` contains static `growthData`; it must not power the Admin. Real aggregates belong in the analytics/dashboard APIs.
- `ActivityLog` is the only current audit-like record. New Admin actions should append to it until a deliberate audit migration is implemented.
- Permanent customer/business deletion conflicts with the target soft-delete rule. It should not be promoted as the normal Admin action.
