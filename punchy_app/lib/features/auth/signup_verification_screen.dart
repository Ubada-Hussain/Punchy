import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';

class SignupVerificationScreen extends StatefulWidget {
  const SignupVerificationScreen({super.key});
  @override State<SignupVerificationScreen> createState() => _SignupVerificationScreenState();
}

class _SignupVerificationScreenState extends State<SignupVerificationScreen> {
  final _code = TextEditingController();
  @override void dispose() { _code.dispose(); super.dispose(); }
  Future<void> _verify() async {
    if (!RegExp(r'^\d{6}$').hasMatch(_code.text.trim())) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter the 6-digit code from your email.'))); return; }
    final auth = context.read<AuthProvider>();
    if (await auth.verifySignup(_code.text.trim()) && mounted) {
      context.go(auth.user?['role'] == 'BUSINESS' ? '/business/setup' : '/');
    } else if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(auth.errorMessage ?? 'Invalid or expired code.')));
  }
  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    appBar: AppBar(title: const Text('Verify your email'), backgroundColor: AppColors.bg, elevation: 0),
    body: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 28), const Icon(Icons.mark_email_read_rounded, size: 64, color: AppColors.teal),
      const SizedBox(height: 20), const Text('Check your inbox', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
      const SizedBox(height: 8), Text('We sent a 6-digit verification code to ${context.watch<AuthProvider>().pendingSignup?['email'] ?? 'your email'}.', textAlign: TextAlign.center),
      const SizedBox(height: 28), TextField(controller: _code, keyboardType: TextInputType.number, maxLength: 6, textAlign: TextAlign.center, decoration: const InputDecoration(labelText: 'Verification code', border: OutlineInputBorder())),
      const SizedBox(height: 14), ElevatedButton(onPressed: context.watch<AuthProvider>().isLoading ? null : _verify, child: const Text('Verify and create account')),
    ])),
  );
}
