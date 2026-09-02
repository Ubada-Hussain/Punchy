import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'core/providers/auth_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/auth/forgot_password_screen.dart';
import 'features/customer/dashboard_screen.dart';
import 'features/customer/explore_screen.dart';
import 'features/customer/customer_barcode_screen.dart';
import 'features/customer/notifications_screen.dart';
import 'features/business/business_dashboard_screen.dart';
import 'features/business/create_card_screen.dart';
import 'features/business/business_setup_screen.dart';
import 'features/business/customer_list_screen.dart';
import 'features/business/business_profile_screen.dart';
import 'features/business/business_scanner_screen.dart';
import 'features/business/business_staff_screen.dart';
import 'features/staff/staff_portal_screen.dart';
import 'features/admin/admin_dashboard_screen.dart';
import 'features/admin/admin_businesses_screen.dart';
import 'features/admin/admin_customers_screen.dart';
import 'features/admin/admin_announcements_screen.dart';
import 'features/shared/profile_screen.dart';
import 'features/shared/edit_profile_screen.dart';
import 'features/shared/terms_screen.dart';
import 'features/system_states/offline_screen.dart';
import 'features/system_states/server_error_screen.dart';
import 'features/system_states/account_suspended_screen.dart';
import 'features/system_states/not_found_screen.dart';
import 'features/system_states/maintenance_screen.dart';
import 'features/system_states/app_update_screen.dart';
import 'features/system_states/system_states_demo_screen.dart';
import 'features/system_states/punchy_splash_screen.dart';

import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/services/notification_service.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await NotificationService().initialize();
      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
      };
      runApp(
        MultiProvider(
          providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
          child: const PunchyApp(),
        ),
      );
    },
    (error, stack) {
      debugPrint('Uncaught app error: $error\n$stack');
    },
  );
}

class PunchyApp extends StatefulWidget {
  const PunchyApp({super.key});

  @override
  State<PunchyApp> createState() => _PunchyAppState();
}

class _PunchyAppState extends State<PunchyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    _router = GoRouter(
      initialLocation: '/splash',
      refreshListenable: authProvider,
      errorBuilder: (context, state) => const NotFoundScreen(),
      redirect: (context, state) {
        final loggedIn = authProvider.isAuthenticated;
        final loc = state.matchedLocation;
        final user = authProvider.user;
        final role = user?['role'] ?? 'CUSTOMER';
        final isSuspended = authProvider.isSuspended;

        // If user is suspended, they can ONLY be on /suspended or /terms
        if (isSuspended) {
          if (loc != '/suspended' && loc != '/terms') {
            return '/suspended';
          }
          return null;
        }

        // If on /suspended but not suspended, redirect home
        if (loc == '/suspended' && !isSuspended && loggedIn) {
          if (role == 'BUSINESS') return '/business';
          if (role == 'STAFF') return '/staff';
          if (role == 'ADMIN') return '/admin';
          return '/';
        }

        final isPublic =
            loc == '/login' ||
            loc == '/splash' ||
            loc == '/signup' ||
            loc == '/forgot-password' ||
            loc == '/terms' ||
            loc.startsWith('/system-states') ||
            loc == '/offline' ||
            loc == '/server-error' ||
            loc == '/suspended' ||
            loc == '/maintenance' ||
            loc == '/update' ||
            loc == '/not-found';

        if (!loggedIn && !isPublic) return '/login';

        if (loggedIn) {
          if (loc == '/login' || loc == '/signup') {
            if (role == 'BUSINESS') return '/business';
            if (role == 'STAFF') return '/staff';
            if (role == 'ADMIN') return '/admin';
            return '/';
          }

          // Strict Role Security: STAFF can ONLY access /staff (and public error pages)
          if (role == 'STAFF') {
            if (loc != '/staff' && !isPublic) {
              return '/staff';
            }
          }

          // Strict Role Security: Customers cannot visit business, staff, or admin routes
          if (role == 'CUSTOMER') {
            if (loc.startsWith('/business') ||
                loc == '/staff' ||
                loc.startsWith('/admin')) {
              return '/';
            }
          }

          // Strict Role Security: Businesses cannot visit customer wallet, staff portal, or admin routes
          if (role == 'BUSINESS') {
            if (loc == '/' ||
                loc == '/explore' ||
                loc == '/barcode' ||
                loc == '/staff' ||
                loc.startsWith('/admin')) {
              return '/business';
            }
          }
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/splash',
          builder: (context, state) => const PunchySplashScreen(),
        ),
        // Auth
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/forgot-password',
          builder: (context, state) => const ForgotPasswordScreen(),
        ),

        // Customer Routes
        GoRoute(
          path: '/',
          builder: (context, state) => const CustomerDashboardScreen(),
        ),
        GoRoute(
          path: '/explore',
          builder: (context, state) => const ExploreScreen(),
        ),
        GoRoute(
          path: '/barcode',
          builder: (context, state) => const CustomerBarcodeScreen(),
        ),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),

        // Staff Portal Route (pure scanner view)
        GoRoute(
          path: '/staff',
          builder: (context, state) => const StaffPortalScreen(),
        ),

        // Business Portal Routes
        GoRoute(
          path: '/business',
          builder: (context, state) => const BusinessDashboardScreen(),
        ),
        GoRoute(
          path: '/business/scan',
          builder: (context, state) => const BusinessScannerScreen(),
        ),
        GoRoute(
          path: '/business/cards/new',
          builder: (context, state) => const CreateCardScreen(),
        ),
        GoRoute(
          path: '/business/cards/:id/edit',
          builder: (context, state) => CreateCardScreen(
            cardId: state.pathParameters['id'],
            initialData: state.extra as Map<String, dynamic>?,
          ),
        ),
        GoRoute(
          path: '/business/setup',
          builder: (context, state) => const BusinessSetupScreen(),
        ),
        GoRoute(
          path: '/business/customers',
          builder: (context, state) => const CustomerListScreen(),
        ),
        GoRoute(
          path: '/business/profile',
          builder: (context, state) => const BusinessProfileScreen(),
        ),
        GoRoute(
          path: '/business/staff',
          builder: (context, state) => const BusinessStaffScreen(),
        ),

        // Admin Portal Routes
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: '/admin/businesses',
          builder: (context, state) => const AdminBusinessesScreen(),
        ),
        GoRoute(
          path: '/admin/customers',
          builder: (context, state) => const AdminCustomersScreen(),
        ),
        GoRoute(
          path: '/admin/notifications',
          builder: (context, state) => const AdminAnnouncementsScreen(),
        ),

        // Shared & System States
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/edit-profile',
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: '/terms',
          builder: (context, state) => const TermsScreen(),
        ),
        GoRoute(
          path: '/system-states',
          builder: (context, state) => const SystemStatesDemoScreen(),
        ),
        GoRoute(
          path: '/offline',
          builder: (context, state) => const OfflineScreen(),
        ),
        GoRoute(
          path: '/server-error',
          builder: (context, state) => const ServerErrorScreen(),
        ),
        GoRoute(
          path: '/suspended',
          builder: (context, state) => const AccountSuspendedScreen(),
        ),
        GoRoute(
          path: '/maintenance',
          builder: (context, state) => const MaintenanceScreen(),
        ),
        GoRoute(
          path: '/update',
          builder: (context, state) => const AppUpdateScreen(),
        ),
        GoRoute(
          path: '/not-found',
          builder: (context, state) => const NotFoundScreen(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Punchy — Loyalty & Rewards',
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}
