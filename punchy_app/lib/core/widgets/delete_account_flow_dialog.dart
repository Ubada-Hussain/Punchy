import 'package:flutter/material.dart';

import '../providers/auth_provider.dart';

/// Shared OTP and deletion flow used by customer and business profile screens.
class DeleteAccountFlowDialog extends StatefulWidget {
  const DeleteAccountFlowDialog({super.key, required this.auth});

  final AuthProvider auth;

  static Future<bool> show(BuildContext context, AuthProvider auth) async =>
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => DeleteAccountFlowDialog(auth: auth),
      ) ??
      false;

  @override
  State<DeleteAccountFlowDialog> createState() =>
      _DeleteAccountFlowDialogState();
}

class _DeleteAccountFlowDialogState extends State<DeleteAccountFlowDialog> {
  final _code = TextEditingController();
  bool _codeSent = false;
  bool _processing = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<bool> Function() operation) async {
    if (_processing) return;
    setState(() {
      _processing = true;
      _error = null;
    });
    bool succeeded;
    try {
      succeeded = await operation();
    } catch (_) {
      succeeded = false;
    }
    if (!mounted) return;
    if (succeeded) {
      if (!_codeSent) {
        setState(() {
          _codeSent = true;
          _processing = false;
        });
      } else {
        Navigator.of(context).pop(true);
      }
    } else {
      setState(() {
        _processing = false;
        _error =
            widget.auth.errorMessage ??
            (_codeSent
                ? 'Could not delete profile. Check the code and try again.'
                : 'Could not send verification code. Please retry.');
      });
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_processing,
    child: AlertDialog(
      title: Text(_codeSent ? 'Confirm profile deletion' : 'Verify your email'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _codeSent
                ? 'Enter the 6-digit code sent to your email.'
                : 'We will email you a code to confirm this action.',
          ),
          if (_codeSent) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _code,
              enabled: !_processing,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(labelText: '6-digit code'),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _processing
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _processing
              ? null
              : () {
                  if (_codeSent && _code.text.trim().isEmpty) {
                    setState(
                      () => _error = 'Enter the verification code to continue.',
                    );
                    return;
                  }
                  _run(
                    _codeSent
                        ? () => widget.auth.deleteAccount(_code.text.trim())
                        : widget.auth.requestDeleteAccountOtp,
                  );
                },
          child: _processing
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(_codeSent ? 'Deleting…' : 'Sending code…'),
                  ],
                )
              : Text(_codeSent ? 'Delete profile' : 'Send code'),
        ),
      ],
    ),
  );
}
