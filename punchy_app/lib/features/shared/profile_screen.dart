import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../system_states/support_sheet.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _pushNotifications = true;
  bool _emailUpdates = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final email = user?['email'] ?? 'customer@punchy.app';
    final name = user?['name'] ?? (email.contains('@') ? email.split('@')[0] : 'User');
    final role = user?['role'] ?? 'CUSTOMER';

    String initials = 'P';
    if (name.trim().isNotEmpty) {
      final parts = name.trim().split(RegExp(r'\s+'));
      if (parts.length > 1) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        initials = name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
      }
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.line),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Center(
                        child: Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: AppColors.ink),
                      ),
                    ),
                  ),
                  Text(
                    'Profile & Settings',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/edit-profile'),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.line),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Center(
                        child: Icon(Icons.edit_outlined, size: 16, color: AppColors.ink),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                children: [
                  // User Profile Card
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: AppColors.gradPurple,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.purple.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: AppColors.inkSoft,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text('ID: ${user?['publicId'] ?? '—'}', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.tealDark)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.person_outline_rounded, color: AppColors.tealDark, size: 12),
                                const SizedBox(width: 4),
                                Text(
                                  role == 'BUSINESS' ? 'Business Owner' : 'Customer',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.tealDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Account Section
                  Text(
                    'Account & Preferences',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      children: [
                        _buildSettingsRow('Edit profile', Icons.edit_outlined, onTap: () => context.push('/edit-profile')),
                        const Divider(height: 1, color: AppColors.line),
                        _buildSettingsRow('My Loyalty Pass (Barcode)', Icons.qr_code_rounded, onTap: () => context.push('/barcode')),
                        const Divider(height: 1, color: AppColors.line),
                        _buildSettingsRow('Punch Notifications', Icons.notifications_none_rounded, onTap: () => context.push('/notifications')),
                        const Divider(height: 1, color: AppColors.line),
                        _buildSettingsRow('Explore Businesses', Icons.explore_outlined, onTap: () => context.push('/explore')),
                        const Divider(height: 1, color: AppColors.line),
                        _buildSettingsRow('Privacy & security', Icons.shield_outlined, onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.ink,
                              content: Text('Your data and punches are encrypted & secure 🔒', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                            ),
                          );
                        }),
                        const Divider(height: 1, color: AppColors.line),
                        _buildSettingsRow('Terms & Conditions', Icons.description_outlined, onTap: () => context.push('/terms')),
                        const Divider(height: 1, color: AppColors.line),
                        _buildSettingsRow('Help & support', Icons.help_outline_rounded, onTap: () => SupportSheet.show(context)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Notifications Section
                  Text(
                    'Notifications',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.ink),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Push notifications',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
                                  ),
                                  Text(
                                    'Punches, rewards & reminders',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.inkSoft),
                                  ),
                                ],
                              ),
                              Switch.adaptive(
                                value: _pushNotifications,
                                activeTrackColor: AppColors.teal,
                                activeThumbColor: Colors.white,
                                onChanged: (v) => setState(() => _pushNotifications = v),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1, color: AppColors.line),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Email updates',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
                                  ),
                                  Text(
                                    'Offers from businesses you follow',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.inkSoft),
                                  ),
                                ],
                              ),
                              Switch.adaptive(
                                value: _emailUpdates,
                                activeTrackColor: AppColors.teal,
                                activeThumbColor: Colors.white,
                                onChanged: (v) => setState(() => _emailUpdates = v),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSettingsRow('Delete profile', Icons.delete_forever_outlined, onTap: _confirmDeleteAccount),
                  const SizedBox(height: 20),

                  // Log Out Button
                  GestureDetector(
                    onTap: () {
                      authProvider.logout();
                      context.go('/login');
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.line, width: 1.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.logout_rounded, color: AppColors.coralDark, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Log out',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.coralDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete profile?'),
        content: const Text('This permanently deletes your account and loyalty data.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final ok = await context.read<AuthProvider>().deleteAccount();
    if (mounted) {
      if (ok) {
        context.go('/login');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not delete profile.')));
      }
    }
  }

  Widget _buildSettingsRow(String title, IconData icon, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: AppColors.tealDark, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
