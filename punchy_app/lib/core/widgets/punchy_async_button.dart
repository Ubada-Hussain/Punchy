import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Button for actions backed by an async operation. Loading starts synchronously
/// on tap, so rapid taps cannot launch duplicate requests.
class PunchyAsyncButton extends StatefulWidget {
  const PunchyAsyncButton({
    super.key,
    required this.label,
    required this.processingLabel,
    required this.onPressed,
    this.onSuccess,
    this.errorMessage = 'Could not complete this action. Please try again.',
    this.backgroundColor = AppColors.teal,
    this.foregroundColor = Colors.white,
    this.enabled = true,
    this.style,
  });

  final String label;
  final String processingLabel;
  final Future<bool?> Function() onPressed;
  final VoidCallback? onSuccess;
  final String errorMessage;
  final Color backgroundColor;
  final Color foregroundColor;
  final bool enabled;
  final ButtonStyle? style;

  @override
  State<PunchyAsyncButton> createState() => _PunchyAsyncButtonState();
}

class _PunchyAsyncButtonState extends State<PunchyAsyncButton> {
  bool _processing = false;

  Future<void> _run() async {
    if (_processing) return;
    setState(() => _processing = true);
    try {
      final succeeded = await widget.onPressed();
      if (!mounted) return;
      if (succeeded == true) {
        widget.onSuccess?.call();
      } else if (succeeded == false) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(widget.errorMessage)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(widget.errorMessage)));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: _processing || !widget.enabled ? null : _run,
    style:
        widget.style?.copyWith(
          backgroundColor: WidgetStatePropertyAll(widget.backgroundColor),
          foregroundColor: WidgetStatePropertyAll(widget.foregroundColor),
        ) ??
        ElevatedButton.styleFrom(
          backgroundColor: widget.backgroundColor,
          foregroundColor: widget.foregroundColor,
        ),
    child: _processing
        ? Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 17,
                height: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: widget.foregroundColor,
                ),
              ),
              const SizedBox(width: 9),
              Text(widget.processingLabel),
            ],
          )
        : Text(widget.label),
  );
}
