import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

/// A consistent, single-submit confirmation dialog for destructive actions.
class PunchyConfirmationDialog extends StatefulWidget {
  const PunchyConfirmationDialog({
    super.key,
    required this.title,
    required this.description,
    required this.confirmLabel,
    required this.onConfirm,
    this.destructive = true,
  });

  final String title;
  final String description;
  final String confirmLabel;
  final Future<void> Function() onConfirm;
  final bool destructive;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String description,
    required String confirmLabel,
    required Future<void> Function() onConfirm,
    bool destructive = true,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => PunchyConfirmationDialog(
            title: title,
            description: description,
            confirmLabel: confirmLabel,
            onConfirm: onConfirm,
            destructive: destructive,
          ),
        ) ??
        false;
  }

  @override
  State<PunchyConfirmationDialog> createState() =>
      _PunchyConfirmationDialogState();
}

class _PunchyConfirmationDialogState extends State<PunchyConfirmationDialog> {
  bool _isProcessing = false;
  String? _error;

  Future<void> _confirm() async {
    if (_isProcessing) return;
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      await widget.onConfirm();
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _error = 'We could not complete this action. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final confirmColor = widget.destructive ? AppColors.coral : AppColors.teal;
    return PopScope(
      canPop: !_isProcessing,
      child: AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          widget.title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.description,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                height: 1.4,
                color: AppColors.inkSoft,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.coralDark,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isProcessing
                ? null
                : () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _isProcessing ? null : _confirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    widget.confirmLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
