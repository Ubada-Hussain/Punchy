import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/punchy_empty_state.dart';
import 'offline_screen.dart';
import 'server_error_screen.dart';
import 'session_expired_dialog.dart';
import 'account_suspended_screen.dart';
import 'not_found_screen.dart';
import 'maintenance_screen.dart';
import 'app_update_screen.dart';
import 'support_sheet.dart';

class SystemStatesDemoScreen extends StatelessWidget {
  const SystemStatesDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text(
          'System & Error States',
          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          children: [
            Text(
              'Interactive System States Preview',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 12),

            // 1. Offline
            _buildStateTile(
              context,
              icon: Icons.wifi_off_rounded,
              title: '1. No Internet / Offline',
              subtitle: "Full-screen 'You're offline' state with retry",
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OfflineScreen()),
              ),
            ),

            // 2. Server Error
            _buildStateTile(
              context,
              icon: Icons.cloud_off_rounded,
              title: '2. Timeout / Server Unreachable',
              subtitle: "Something went wrong on our end + Contact Support",
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ServerErrorScreen()),
              ),
            ),

            // 3. Session Expired
            _buildStateTile(
              context,
              icon: Icons.lock_clock_rounded,
              title: '3. Session Expired (401/403)',
              subtitle: 'Modal popup forcing re-login',
              onTap: () => SessionExpiredDialog.show(context),
            ),

            // 4. Account Suspended
            _buildStateTile(
              context,
              icon: Icons.shield_outlined,
              title: '4. Account Suspended',
              subtitle: 'Full-screen notice with appeal options & Log Out',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AccountSuspendedScreen()),
              ),
            ),

            // 5. 404 Not Found
            _buildStateTile(
              context,
              icon: Icons.explore_off_rounded,
              title: '5. Page Not Found (404)',
              subtitle: 'Invalid deep link or missing page',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotFoundScreen()),
              ),
            ),

            // 6. Maintenance Mode
            _buildStateTile(
              context,
              icon: Icons.handyman_rounded,
              title: '6. Maintenance Mode',
              subtitle: "We'll be right back with estimated timer",
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MaintenanceScreen()),
              ),
            ),

            // 7. Mandatory App Update
            _buildStateTile(
              context,
              icon: Icons.system_update_rounded,
              title: '7. Mandatory App Update',
              subtitle: 'Blocking update screen',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AppUpdateScreen()),
              ),
            ),

            // 8. Support Sheet
            _buildStateTile(
              context,
              icon: Icons.help_outline_rounded,
              title: '8. Contact Support Modal',
              subtitle: 'Email, live chat, and FAQ help desk',
              onTap: () => SupportSheet.show(context),
            ),

            const SizedBox(height: 24),
            Text(
              'Contextual Empty States Preview',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            const SizedBox(height: 12),

            // Empty State A: No Cards
            PunchyEmptyState.noCards(onScanNow: () => context.push('/scanner')),
            const SizedBox(height: 14),

            // Empty State B: No Activity
            PunchyEmptyState.noActivity(),
            const SizedBox(height: 14),

            // Empty State C: No Customers
            PunchyEmptyState.noCustomers(onShareQR: () {}),
            const SizedBox(height: 14),

            // Empty State D: No Notifications
            PunchyEmptyState.noNotifications(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStateTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: AppColors.tealDark, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.inkFaint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
