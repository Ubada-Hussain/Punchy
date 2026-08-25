import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/clerk_auth_service.dart';
import '../../core/theme/app_colors.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController(text: 'Ayesha Khan');
  final _emailController = TextEditingController(text: 'ayesha@email.com');
  final _passwordController = TextEditingController(text: 'Customer1234!');
  final _formKey = GlobalKey<FormState>();
  int _roleIndex = 0; // 0 = Customer, 1 = Business

  void _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      // For demo, login or mock register
      await auth.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        if (_roleIndex == 1) {
          context.go('/business');
        } else {
          context.go('/');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create your account',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Join in a few seconds',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppColors.inkSoft,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Segmented Switcher (Customer / Business)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildSegButton(0, '🙋 Customer'),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: _buildSegButton(1, '🏪 Business'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Full Name
                  Text(
                    'Full name',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameController,
                    style: GoogleFonts.plusJakartaSans(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      hintText: 'Your name',
                      prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.inkFaint, size: 18),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email
                  Text(
                    'Email',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.plusJakartaSans(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      hintText: 'name@example.com',
                      prefixIcon: Icon(Icons.mail_outline_rounded, color: AppColors.inkFaint, size: 18),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password
                  Text(
                    'Password',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: GoogleFonts.plusJakartaSans(color: AppColors.ink, fontSize: 14, fontWeight: FontWeight.w600),
                    decoration: const InputDecoration(
                      hintText: 'Create a password',
                      prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.inkFaint, size: 18),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: _roleIndex == 1 ? AppColors.coral : AppColors.teal,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (_roleIndex == 1 ? AppColors.coral : AppColors.teal).withValues(alpha: 0.45),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isLoading ? null : _handleSignup,
                        borderRadius: BorderRadius.circular(12),
                        child: Center(
                          child: Text(
                            _roleIndex == 1 ? 'Start Business Account' : 'Create Account',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.line)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          'OR CONTINUE WITH',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: AppColors.inkFaint,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppColors.line)),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Social Row (Powered by Clerk)
                  Row(
                    children: [
                      Expanded(
                        child: _buildSocialBtn('Google', Icons.g_mobiledata_rounded, onTap: () {
                          ClerkAuthService.signInWithGoogle(context, role: _roleIndex == 1 ? 'BUSINESS' : 'CUSTOMER');
                        }),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSocialBtn('Apple', Icons.apple_rounded, onTap: () {
                          ClerkAuthService.signInWithApple(context, role: _roleIndex == 1 ? 'BUSINESS' : 'CUSTOMER');
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'By continuing you agree to our Terms & Privacy Policy',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.inkSoft),
                      ),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Text(
                          'Log in',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.tealDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSegButton(int index, String label) {
    final isSelected = _roleIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _roleIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: isSelected ? AppColors.ink : AppColors.inkSoft,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialBtn(String label, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line, width: 1.5),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: AppColors.ink),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
