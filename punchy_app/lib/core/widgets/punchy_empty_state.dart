import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class PunchyEmptyState extends StatelessWidget {
  final IconData icon;
  final String heading;
  final String subtext;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  const PunchyEmptyState({
    super.key,
    required this.icon,
    required this.heading,
    required this.subtext,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  /// Factory: Customer wallet has no cards yet
  factory PunchyEmptyState.noCards({required VoidCallback onScanNow}) {
    return PunchyEmptyState(
      icon: Icons.credit_card_off_rounded,
      heading: 'No cards yet',
      subtext: 'Scan a QR code at your favorite business to get started',
      actionLabel: 'Scan Now',
      onAction: onScanNow,
      iconColor: AppColors.tealDark,
    );
  }

  /// Factory: Card detail has no activity logs yet
  factory PunchyEmptyState.noActivity() {
    return const PunchyEmptyState(
      icon: Icons.receipt_long_rounded,
      heading: 'No activity yet',
      subtext: 'Your punches and rewards will show up here',
      iconColor: AppColors.inkSoft,
    );
  }

  /// Factory: Business dashboard has no customer punches yet
  factory PunchyEmptyState.noCustomers({VoidCallback? onShareQR}) {
    return PunchyEmptyState(
      icon: Icons.people_outline_rounded,
      heading: 'No customers yet',
      subtext: 'Share your QR code or NFC tag to get your first customer',
      actionLabel: onShareQR != null ? 'View Counter QR' : null,
      onAction: onShareQR,
      iconColor: AppColors.coralDark,
    );
  }

  /// Factory: Alerts/notifications is empty
  factory PunchyEmptyState.noNotifications() {
    return const PunchyEmptyState(
      icon: Icons.notifications_none_rounded,
      heading: "You're all caught up",
      subtext: 'New punches and rewards will appear here',
      iconColor: AppColors.tealDark,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon in soft circular badge
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.line),
            ),
            child: Icon(
              icon,
              size: 26,
              color: iconColor ?? AppColors.tealDark,
            ),
          ),
          const SizedBox(height: 14),

          // Heading
          Text(
            heading,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // Subtext
          Text(
            subtext,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              color: AppColors.inkSoft,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),

          // Optional CTA Button
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            SizedBox(
              height: 42,
              child: ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  actionLabel!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
