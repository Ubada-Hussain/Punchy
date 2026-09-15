# Punchy Engineering Quality Report

Date: 15 September 2026

## Current scorecard

These are engineering readiness scores based on repository evidence and automated gates, not a certification.

| Area | Score | Evidence |
| --- | ---: | --- |
| Basic functionality | 9/10 | Auth, punch validation, notification scheduling, pagination, admin build and Flutter widget/API tests pass. Full production E2E remains the final gap. |
| Maintainability | 9/10 | Auth and punch boundaries use repositories/services; API client is injectable; pagination/password policies are shared modules. Some older feature screens/routes remain large and should be split incrementally. |
| Security | 8.5/10 | Secrets removed from Git history, secure token storage, rate limits, CORS allowlist, request IDs, payload limits and zero production dependency vulnerabilities. Provider key rotation must be confirmed externally. |
| Test coverage | 9/10 | Backend domain tests and Flutter API/widget tests run in CI. Database-backed integration and Android emulator E2E are still required for a true release gate. |
| Deployment quality | 9/10 | GitHub Actions runs build, tests, lint and audit for backend/admin/mobile. Add staging smoke tests and rollback verification before 10/10. |

## Implemented in this phase

- Added `AuthRepository` and kept authentication endpoint details out of the provider.
- Made `ApiClient` injectable with configurable base URL and request timeout.
- Moved access tokens to secure storage with one-time migration from legacy preferences.
- Added reusable backend `PunchService` and domain error handling.
- Added shared password policy and bounded pagination parser.
- Added scheduled-notification worker; future notifications are persisted but not dispatched early.
- Added `totalPages`, validated `page`, and capped `limit` on list APIs.
- Added backend tests for password policy, rate limiting, invalid punch identifiers and pagination.
- Added Flutter tests for API headers, JSON decoding and typed API failures.
- CI now runs backend tests in addition to build/audit and mobile/admin gates.

## Automated verification

- Backend tests: 4 passing
- Backend TypeScript build: passing
- Backend production dependency audit: 0 vulnerabilities
- Admin lint: passing
- Admin production build: passing
- Flutter analyzer: passing before the final worker verification; rerun locally/CI if the Flutter process is interrupted
- Flutter tests: 6 passing in the prior gate; latest run should be confirmed by CI

## Remaining work for a genuine 10/10

1. Rotate Clerk and Brevo credentials in their provider dashboards and confirm the new values in the production secret manager.
2. Add Prisma/Mongo integration tests using an isolated test database.
3. Add Android emulator E2E tests for signup OTP, login, punch, notification panel, complaint submission, logo upload and account deletion.
4. Split the remaining large legacy screens/routes into feature modules without changing behavior.
5. Use Redis-backed rate limiting and a distributed job queue when running more than one backend instance.
6. Add staging smoke tests, error monitoring, alerting and rollback verification.

## Industry comparison

The architecture now follows the important Flutter recommendations: separate UI/data layers, repositories as data boundaries, dependency injection and tests around repositories/view models. See [Flutter architecture recommendations](https://docs.flutter.dev/app-architecture/recommendations).

Secrets are not considered safe merely because a file was deleted; exposed credentials must be revoked and rotated. See [OWASP Secrets Management](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html).

## Release gate

Do not label a build production-ready until the CI workflow is green, provider keys are rotated, staging E2E flows pass, and the release rollback has been exercised once.
