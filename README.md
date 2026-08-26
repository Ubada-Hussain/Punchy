# ☕ Punchy — Next-Gen Digital Loyalty & Punch Card Platform

<div align="center">

![Punchy Banner](https://img.shields.io/badge/Punchy-Loyalty%20%26%20Rewards-0EA893?style=for-the-badge&logo=flutter&logoColor=white)
[![Flutter](https://img.shields.io/badge/Flutter-3.47+-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-Express%20%7C%20TypeScript-339933?style=flat-square&logo=node.js&logoColor=white)](https://nodejs.org)
[![Prisma](https://img.shields.io/badge/Prisma-MongoDB%20Replica%20Set-2D3748?style=flat-square&logo=prisma&logoColor=white)](https://prisma.io)
[![License: MIT](https://img.shields.io/badge/License-MIT-FF6B57?style=flat-square)](LICENSE)

**Punchy** is a modern, cross-platform digital loyalty card application that replaces wasteful paper punch cards with seamless **QR Code** and **NFC Tap** interactions. Built with a fresh, tactile design system, Punchy empowers cafes, salons, gyms, and local merchants to retain customers while offering shoppers a unified digital wallet for all their rewards.

[Features](#-key-features) • [Tech Stack](#-tech-stack) • [Architecture](#-project-architecture) • [Getting Started](#-getting-started) • [Routes & Navigation](#-routes--navigation) • [Security](#-fraud-prevention--security)

</div>

---

## 🌟 Why Punchy?

Traditional paper punch cards get lost, damaged, or forgotten at home. Punchy digitizes the entire loyalty experience with rich micro-animations, digital stamp tear-lines, and fraud-proof punch tracking:

- 🎟️ **No Lost Cards**: All loyalty cards live in one clean, centralized digital wallet.
- ⚡ **Instant Punches**: Customers tap counter NFC standees or scan counter QR codes to earn punches in seconds.
- 🏪 **Merchant Empowerment**: Business owners can design branded cards, track customer progress, and verify redemptions in real-time.
- 🛡️ **Anti-Fraud Security**: Customers earn punches exclusively via hardware scanning; staff actions are restricted to verifying completed reward redemptions.

---

## ✨ Key Features

### 🙋 Customer Experience
- **Digital Loyalty Wallet (`/`)**: Displays active punch cards with live stamp progress, perforation tear-line motifs, and reward countdowns.
- **Discover & Explore (`/explore`)**: Browse all participating local businesses with real-time search, category filters (Café, Salon, Fitness, Dining, Retail), and one-tap *"Add to Wallet"*.
- **Hardware-Aware Scanner (`/scanner`)**: Integrated with `mobile_scanner` (camera viewfinder) and `nfc_manager` (NFC tag discovery) with adaptive fallback simulations for desktop/web testing.
- **Card Detail View**: View punch history timestamps, reward terms, and business contact information.
- **Profile & Preferences (`/profile`)**: Manage profile name, notification toggles, terms of service, and support sheets.

### 🏪 Business Portal (`/business`)
- **Merchant Dashboard (`/business`)**: Real-time stats (*Total Customers*, *Punches Today*, *Rewards Redeemed*), active card preview with expiration countdown, quick action cards, and in-store customer activity feeds.
- **Single Active Card Limit**: Businesses can maintain **1 active loyalty card** at any given time. New card creation is dynamically locked until the existing card is deleted or replaced.
- **Loyalty Card Studio (`/business/cards/new` & `/business/cards/:id/edit`)**:
  - **Card Validity ("Valid Till") Date**: Set precise expiration dates with quick presets (*3 Months, 6 Months, 1 Year, Custom Date Picker*).
  - Live interactive card preview with instant visual updates and validity badge.
  - Stepper for required punches (3 to 20 punches).
  - Curated gradient themes (*Teal, Coral, Purple, Gold*).
  - Hardware toggles for QR and NFC punch enablement.
  - One-tap **"Delete This Loyalty Card"** action with confirmation safety dialog.
- **Staff & Terminal Management (`/business/staff`)**:
  - Add and manage child **Staff accounts** linked to the business.
  - Instant **Scanner Activation Toggle**: Enable or disable scanner permissions for any staff terminal with real-time enforcement.
- **Customer List & Redemption Verification (`/business/customers`)**:
  - Track customer loyalty progress bars (e.g. `8/10` punches).
  - Tapping a customer reveals detailed join date and visit logs.
  - **One-tap "Confirm Redemption"** button when a customer completes their card.
- **Business Profile & Setup (`/business/setup` & `/business/profile`)**:
  - Manage business name, category, address, and merchant notifications (*"New customer joined"*, *"Card completed"*).

### 📱 Staff Scanner Portal (`/staff`)
- **Minimalist Child Terminal**: Purpose-built for cashier and floor staff. Contains exclusively the customer barcode scanner with laser viewfinder, manual email/ID entry, and simulation triggers.
- **Remote Activation Lock**: Terminal is operable *only* when the business owner activates that staff ID. When deactivated, displays a secure lock screen with real-time status check.
- **Zero Distraction**: Staff accounts have no access to business financials, card studio, or customer wallets.

### 👑 Platform Administration Suite (`/admin`)
- **Admin Overview (`/admin`)**: Platform-wide metrics, signup growth analytics chart powered by `fl_chart`, and audit activity stream.
- **Business Moderation (`/admin/businesses`)**: Inspect business applications with filter tabs (*Pending, Approved, Suspended*) and approve or suspend merchants.
- **Customer Management (`/admin/customers`)**: Search customer accounts, view active card counts, and toggle account suspensions.
- **Platform Announcements (`/admin/notifications`)**: Broadcast announcements to all users, customers only, or businesses only.

### 🛡️ System & Error States
Robust, user-friendly fallback screens designed to handle real runtime states:
- **Account Suspended (`/suspended`)**: Dedicated suspension page displayed automatically when an account or business is flagged or suspended by platform admins. Includes status refresh and support contact triggers.
- **Offline / Network Error (`/offline`)**: Automatic retry mechanism and offline indicators.
- **Server Error (`/server-error`)**: 500 error handling with direct support bottom sheets.
- **Session Expired (`session_expired_dialog.dart`)**: Non-dismissible re-login modal.
- **404 Not Found (`/not-found`)**: Registered with GoRouter `errorBuilder`.
- **Maintenance & Updates (`/maintenance`, `/update`)**: Seamless maintenance banners and update prompts.

---

## 🎨 Design System

Punchy uses a custom, refreshing color palette inspired by modern cafe culture and clean fintech aesthetics:

| Token | Hex / Value | Description |
|---|---|---|
| **Background** | `#F5F9F6` | Refreshing off-white / light mint |
| **Surface** | `#FFFFFF` | Card backgrounds and containers |
| **Primary Accent** | `#0EA893` | Teal (Action buttons, active tabs, primary badges) |
| **Secondary Accent**| `#FF6B57` | Coral (Floating action buttons, rewards, warnings) |
| **Purple Accent** | `#7C6FF0` | VIP badges, profile gradients, NFC indicators |
| **Gold Accent** | `#FFC145` | Laser scanner brackets, achievement stars |
| **Ink / Typography**| `#142420` | High-contrast dark ink for crisp readability |
| **Typography** | `Plus Jakarta Sans` | Applied universally across all weights (400–800) |

---

## 🛠️ Tech Stack

### Frontend (Mobile & Web)
- **Framework**: [Flutter](https://flutter.dev) (v3.47+) & Dart
- **Routing**: [GoRouter](https://pub.dev/packages/go_router) with state-aware auth redirection & 404 handling
- **State Management**: [Provider](https://pub.dev/packages/provider)
- **Typography**: [Google Fonts](https://pub.dev/packages/google_fonts) (`Plus Jakarta Sans`)
- **Hardware Integration**:
  - [mobile_scanner](https://pub.dev/packages/mobile_scanner) — Camera QR scanning
  - [nfc_manager](https://pub.dev/packages/nfc_manager) — Native NFC tag reading
  - [permission_handler](https://pub.dev/packages/permission_handler) — Dynamic runtime permissions
- **Data Visualization**: [fl_chart](https://pub.dev/packages/fl_chart)

### Backend & Database
- **Runtime & Language**: [Node.js](https://nodejs.org) & [TypeScript](https://www.typescriptlang.org)
- **Web Framework**: [Express.js](https://expressjs.com)
- **Database**: [MongoDB](https://www.mongodb.com) (Replica Set `rs0` for transaction support)
- **ORM**: [Prisma ORM](https://www.prisma.io)
- **Authentication**: JWT authentication & [Clerk](https://clerk.com) Social Authentication SDK
- **Push Notifications**: Firebase Cloud Messaging (FCM) dispatch helper

---

## 📂 Project Architecture

```
Punchy/
├── punchy-backend/               # Node.js & TypeScript API Server
│   ├── prisma/
│   │   └── schema.prisma         # Prisma data models (User, Business, LoyaltyCard, Punch)
│   ├── src/
│   │   ├── lib/
│   │   │   ├── notifications.ts  # Push notification dispatcher
│   │   │   └── prisma.ts         # Prisma client singleton
│   │   ├── middleware/
│   │   │   └── auth.ts           # JWT authentication & role-based guards
│   │   ├── routes/
│   │   │   ├── auth.ts           # Login, signup & Clerk social authentication
│   │   │   ├── businessPortal.ts # Merchant dashboard, card CRUD, customers & redemptions
│   │   │   ├── customer.ts       # Customer wallet, explore & join card
│   │   │   ├── admin.ts          # Admin stats, moderation & announcements
│   │   │   └── punch.ts          # QR & NFC punch recording endpoint
│   │   └── index.ts              # Express application entry point
│   ├── package.json
│   └── tsconfig.json
│
└── punchy_app/                   # Flutter Mobile & Web Client
    ├── lib/
    │   ├── core/
    │   │   ├── api/              # ApiClient with JWT header interceptors
    │   │   ├── providers/        # AuthProvider state
    │   │   ├── services/         # HardwareScannerService & NotificationService
    │   │   ├── theme/            # AppColors, AppTheme & Plus Jakarta Sans typography
    │   │   └── widgets/          # PunchyEmptyState & reusable UI components
    │   ├── features/
    │   │   ├── auth/             # Login & Signup screens (Clerk Google/Apple auth)
    │   │   ├── customer/         # Dashboard (Wallet), Explore, Card Detail & Scanner
    │   │   ├── business/         # Business Dashboard, Create Card, Setup, Customers & Profile
    │   │   ├── admin/            # Admin Overview, Businesses, Customers & Announcements
    │   │   ├── shared/           # ProfileScreen, EditProfileScreen, TermsScreen
    │   │   └── system_states/    # Offline, Server Error, Suspended, Maintenance screens
    │   └── main.dart             # GoRouter setup & application entry point
    └── pubspec.yaml              # Dependencies and asset declarations
```

---

## 🚀 Getting Started

### Prerequisites
1. **Flutter SDK** (v3.24 or higher): [Install Flutter](https://docs.flutter.dev/get-started/install)
2. **Node.js** (v18 or higher): [Install Node.js](https://nodejs.org)
3. **MongoDB** (v7+ or v8+ running as a Replica Set `rs0`):
   ```bash
   mongod --dbpath <data-dir> --replSet rs0 --port 27018
   ```

---

### 1. Backend Setup

1. Navigate to the backend directory:
   ```bash
   cd punchy-backend
   ```
2. Install dependencies:
   ```bash
   npm install
   ```
3. Configure your `.env` file:
   ```env
   PORT=4000
   DATABASE_URL="mongodb://127.0.0.1:27018/punchy?replicaSet=rs0"
   JWT_SECRET="punchy-super-secret-jwt-key"
   CLERK_SECRET_KEY="sk_test_..."
   NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY="pk_test_..."
   ```
4. Push Prisma schema to MongoDB:
   ```bash
   npx prisma db push
   ```
5. Start the development server:
   ```bash
   npm run dev
   ```
   *The backend will start on `http://localhost:4000`.*

---

### 2. Flutter App Setup

1. Navigate to the Flutter app directory:
   ```bash
   cd punchy_app
   ```
2. Get Flutter packages:
   ```bash
   flutter pub get
   ```
3. Run the app on Chrome (Web), Android, iOS, or Windows:
   ```bash
   # Run on Chrome
   flutter run -d chrome

   # Run on Android Device / Emulator
   flutter run -d android

   # Run on Windows Desktop
   flutter run -d windows
   ```

---

## 🗺️ Routes & Navigation

| Route | Screen Name | Role / Access | Description |
|---|---|---|---|
| `/` | `CustomerDashboardScreen` | Customer | Customer digital wallet (active joined cards only) |
| `/explore` | `ExploreScreen` | Public / Customer | Discover all businesses and add cards to wallet |
| `/scanner` | `ScannerScreen` | Customer | Real Camera QR scanner & NFC tag reader |
| `/terms` | `TermsScreen` | Public / All | Platform terms of service and reward guidelines |
| `/edit-profile` | `EditProfileScreen` | Customer | Minimal name edit screen |
| `/profile` | `ProfileScreen` | Customer | Customer profile, notifications & portal switchers |
| `/business` | `BusinessDashboardScreen` | Business | Merchant metrics, loyalty card preview & activity |
| `/business/cards/new` | `CreateCardScreen` | Business | Interactive loyalty card creation studio |
| `/business/cards/:id/edit`| `CreateCardScreen` | Business | Edit existing loyalty card parameters |
| `/business/customers` | `CustomerListScreen` | Business | Customer loyalty list, history & reward redemptions |
| `/business/setup` | `BusinessSetupScreen` | Business | Business profile, address & hardware toggles |
| `/business/profile` | `BusinessProfileScreen` | Business | Merchant profile, summary strip & notification settings |
| `/admin` | `AdminDashboardScreen` | Admin | Platform overview, stats & growth chart |
| `/admin/businesses` | `AdminBusinessesScreen` | Admin | Approve, review, or suspend business accounts |
| `/admin/customers` | `AdminCustomersScreen` | Admin | Customer accounts moderation & block toggle |
| `/admin/notifications` | `AdminAnnouncementsScreen`| Admin | Broadcast announcements to platform users |
| `/system-states` | `SystemStatesDemoScreen` | All | Developer showcase of all error and system states |

---

## 🔒 Fraud Prevention & Security

Punchy enforces strict security guarantees across all user roles:

1. **No Manual Punching**:
   - Punches can **ONLY** be added by the customer themselves by scanning the verified counter QR code or tapping the counter NFC hardware.
   - Staff/business owners **cannot manually add punches**, preventing employee collusion or fraudulent stamp creation.
2. **Merchant Redemption Confirmation**:
   - When a customer's card reaches the required punch count, the card status updates to `isCompleted: true`.
   - The merchant confirms the redemption via their dashboard (`POST /business/redeem-confirm`), resetting or completing the cycle safely.
3. **Role-Based Access Control (RBAC)**:
   - Express middleware validates JWT claims and restricts access to `/business/*` and `/admin/*` endpoints based on user roles (`CUSTOMER`, `BUSINESS`, `ADMIN`).

---

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

<div align="center">
Built with ☕, Flutter, and TypeScript.
</div>