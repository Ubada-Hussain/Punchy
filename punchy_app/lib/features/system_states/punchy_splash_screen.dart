import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/providers/auth_provider.dart';
import 'splash/splash_page.dart';

/// Adapts the existing auth readiness signal without changing initialization.
class PunchySplashScreen extends StatefulWidget {
  const PunchySplashScreen({super.key});

  @override
  State<PunchySplashScreen> createState() => _PunchySplashScreenState();
}

class _PunchySplashScreenState extends State<PunchySplashScreen> {
  final _initialization = Completer<void>();
  late final AuthProvider _auth;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthProvider>();
    _auth.addListener(_checkReady);
    _checkReady();
  }

  void _checkReady() {
    if (_auth.isReady && !_initialization.isCompleted) {
      _initialization.complete();
    }
  }

  void _goToStart() {
    if (!mounted) return;
    if (_auth.isOffline) return context.go('/offline');
    final role = _auth.user?['role'];
    if (!_auth.isAuthenticated) return context.go('/login');
    if (_auth.isSuspended) return context.go('/suspended');
    if (role == 'BUSINESS') return context.go('/business');
    if (role == 'STAFF') return context.go('/staff');
    if (role == 'ADMIN') return context.go('/admin');
    context.go('/');
  }

  @override
  void dispose() {
    _auth.removeListener(_checkReady);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PunchyIntroPage(
    initialization: _initialization.future,
    onReady: _goToStart,
  );
}
