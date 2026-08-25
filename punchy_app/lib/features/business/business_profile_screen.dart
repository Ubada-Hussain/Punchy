import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../system_states/support_sheet.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  bool _notifyNewCustomer = true;
  bool _notifyCardCompleted = true;
  bool _weeklySummary = true;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;
    final email = user?['email'] ?? 'brew@punchy.app';

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
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
                    'Business Profile',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push('/business/setup'),
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
                  // Business Header Card
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: AppColors.gradTeal,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.teal.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text('☕', style: TextStyle(fontSize: 28)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Brew & Co.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Cafe & Bakery • $email',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppColors.inkSoft,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.coral.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.storefront_rounded, color: AppColors.coralDark, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    'BUSINESS OWNER',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.coralDark,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Summary Strip (3 Stat boxes)
                  Row(
                    children: [
                      Expanded(child: _buildSummaryBox('Active Cards', '1 Card', Icons.credit_card_rounded)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildSummaryBox('Customers', '312 joined', Icons.people_alt_rounded)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildSummaryBox('Member Since', 'Aug 2026', Icons.calendar_today_rounded)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Business Account Settings Section
                  Text(
                    'Business Account',
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
                        _buildSettingsRow(
                          'Edit Business Profile',
                          'Name, logo, category & address',
                          Icons.store_outlined,
                          onTap: () => context.push('/business/setup'),
                        ),
                        const Divider(height: 1, color: AppColors.line),
                        _buildSettingsRow(
                          'Customer Loyalty List',
                          'View punch progress & confirm rewards',
                          Icons.people_outline_rounded,
                          onTap: () => context.push('/business/customers'),
                        ),
                        const Divider(height: 1, color: AppColors.line),
                        _buildSettingsRow(
                          'Privacy & Security',
                          'Merchant encryption & data policies',
                          Icons.shield_outlined,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.ink,
                                content: Text('Merchant data and transactions are encrypted 🔒', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 1, color: AppColors.line),
                        _buildSettingsRow(
                          'Terms & Conditions',
                          'Merchant and loyalty service agreement',
                          Icons.description_outlined,
                          onTap: () => context.push('/terms'),
                        ),
                        const Divider(height: 1, color: AppColors.line),
                        _buildSettingsRow(
                          'Help & Support',
                          'Contact merchant partner care',
                          Icons.help_outline_rounded,
                          onTap: () => SupportSheet.show(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Business Notification Preferences
                  Text(
                    'Merchant Notifications',
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
                        _buildNotificationToggle(
                          title: 'New customer joined',
                          subtitle: 'Alert when a customer adds your loyalty card',
                          value: _notifyNewCustomer,
                          onChanged: (v) => setState(() => _notifyNewCustomer = v),
                        ),
                        const Divider(height: 1, color: AppColors.line),
                        _buildNotificationToggle(
                          title: 'Card completed by customer',
                          subtitle: 'Alert when a customer reaches reward redemption',
                          value: _notifyCardCompleted,
                          onChanged: (v) => setState(() => _notifyCardCompleted = v),
                        ),
                        const Divider(height: 1, color: AppColors.line),
                        _buildNotificationToggle(
                          title: 'Weekly activity digest',
                          subtitle: 'Summary email of punches and active members',
                          value: _weeklySummary,
                          onChanged: (v) => setState(() => _weeklySummary = v),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Switch to Customer View button
                  GestureDetector(
                    onTap: () => context.go('/'),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🙋', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(
                            'Switch to Customer App View',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.tealDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

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
                            'Log out of Business Account',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.coralDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBox(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.tealDark),
          const SizedBox(height: 6),
          Text(
            title.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.inkSoft, letterSpacing: 0.3),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsRow(String title, String subtitle, IconData icon, {VoidCallback? onTap}) {
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.inkFaint, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.inkSoft),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: AppColors.teal,
            activeThumbColor: Colors.white,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
