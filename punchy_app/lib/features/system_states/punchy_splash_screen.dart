import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/providers/auth_provider.dart';

class PunchySplashScreen extends StatefulWidget {
  const PunchySplashScreen({super.key});

  @override
  State<PunchySplashScreen> createState() => _PunchySplashScreenState();
}

class _PunchySplashScreenState extends State<PunchySplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;
  Timer? _navigationPoll;

  @override
  void initState() {
    super.initState();
    _progress = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    )..forward();
    _progress.addStatusListener((status) {
      if (status == AnimationStatus.completed) _navigateWhenReady();
    });
  }

  void _navigateWhenReady() {
    final auth = context.read<AuthProvider>();
    if (auth.isReady) {
      _goToStart(auth);
      return;
    }
    _navigationPoll ??= Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (!mounted) return;
      final current = context.read<AuthProvider>();
      if (current.isReady) {
        _navigationPoll?.cancel();
        _navigationPoll = null;
        _goToStart(current);
      }
    });
  }

  void _goToStart(AuthProvider auth) {
    if (!mounted) return;
    final role = auth.user?['role'];
    if (!auth.isAuthenticated) return context.go('/login');
    if (auth.isSuspended) return context.go('/suspended');
    if (role == 'BUSINESS') return context.go('/business');
    if (role == 'STAFF') return context.go('/staff');
    if (role == 'ADMIN') return context.go('/admin');
    context.go('/');
  }

  @override
  void dispose() {
    _navigationPoll?.cancel();
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _progress,
          builder: (context, child) => Stack(
            children: [
              Center(
                child: Transform.translate(
                  offset: const Offset(0, -40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/punchy_splash_mark.png', width: width * .46, height: width * .46, fit: BoxFit.contain),
                      const SizedBox(height: 22),
                      const Text('Punchy', style: TextStyle(color: Color(0xFF0EA893), fontSize: 54, fontWeight: FontWeight.w800, letterSpacing: -2)),
                      const SizedBox(height: 14),
                      RichText(text: const TextSpan(style: TextStyle(color: Color(0xFF202124), fontSize: 14, letterSpacing: 3.1, fontWeight: FontWeight.w500), children: [
                        TextSpan(text: 'THE ULTIMATE '),
                        TextSpan(text: 'LOYALTY', style: TextStyle(color: Color(0xFF0EA893))),
                        TextSpan(text: ' APP'),
                      ])),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: width * .22,
                right: width * .22,
                bottom: 92,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(height: 14, child: LinearProgressIndicator(value: _progress.value, backgroundColor: const Color(0xFFD7E9E5), valueColor: const AlwaysStoppedAnimation(Color(0xFF0EA893)))),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
