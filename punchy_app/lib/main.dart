import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'core/providers/auth_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/customer/dashboard_screen.dart';
import 'features/customer/scanner_screen.dart';
import 'features/business/business_dashboard_screen.dart';
import 'features/business/create_card_screen.dart';
import 'features/shared/profile_screen.dart';
import 'features/system_states/offline_screen.dart';
import 'features/system_states/server_error_screen.dart';
import 'features/system_states/account_suspended_screen.dart';
import 'features/system_states/not_found_screen.dart';
import 'features/system_states/maintenance_screen.dart';
import 'features/system_states/app_update_screen.dart';
import 'features/system_states/system_states_demo_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const PunchyApp(),
    ),
  );
}

class PunchyApp extends StatelessWidget {
  const PunchyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final GoRouter router = GoRouter(
      initialLocation: authProvider.isAuthenticated ? '/' : '/login',
      refreshListenable: authProvider,
      errorBuilder: (context, state) => const NotFoundScreen(),
      redirect: (context, state) {
        final loggedIn = authProvider.isAuthenticated;
        final loc = state.matchedLocation;
        final isPublic = loc == '/login' ||
            loc == '/signup' ||
            loc.startsWith('/system-states') ||
            loc == '/offline' ||
            loc == '/server-error' ||
            loc == '/suspended' ||
            loc == '/maintenance' ||
            loc == '/update' ||
            loc == '/not-found';

        if (!loggedIn && !isPublic) return '/login';
        if (loggedIn && (loc == '/login' || loc == '/signup')) return '/';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const CustomerDashboardScreen(),
        ),
        GoRoute(
          path: '/scanner',
          builder: (context, state) => const ScannerScreen(),
        ),
        GoRoute(
          path: '/business',
          builder: (context, state) => const BusinessDashboardScreen(),
        ),
        GoRoute(
          path: '/business/create-card',
          builder: (context, state) => const CreateCardScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
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

    return MaterialApp.router(
      title: 'Punchy — Loyalty & Rewards',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
