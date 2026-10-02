import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/auth_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/punchy_async_button.dart';

class SessionExpiredDialog extends StatelessWidget {
  const SessionExpiredDialog({super.key});

  /// Displays the modal dialog over any screen with barrier dismissal disabled
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          const PopScope(canPop: false, child: SessionExpiredDialog()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Lock Icon Badge
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.line, width: 1.5),
                ),
                child: const Center(
                  child: Icon(
                    Icons.lock_clock_rounded,
                    size: 30,
                    color: AppColors.tealDark,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Heading
            Text(
              'Session expired',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),

            // Subtext
            Text(
              'Your secure login session has ended. Please log in again to continue accessing your cards.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Primary "Log In" Button
            SizedBox(
              height: 48,
              child: PunchyAsyncButton(
                label: 'Log In',
                processingLabel: 'Logging out…',
                onPressed: () async {
                  await Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  ).logout();
                  return true;
                },
                onSuccess: () {
                  Navigator.of(context, rootNavigator: true).pop();
                  context.go('/login');
                },
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  shadowColor: AppColors.teal.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
