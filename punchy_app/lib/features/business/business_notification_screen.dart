import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_colors.dart';

class BusinessNotificationScreen extends StatefulWidget {
  const BusinessNotificationScreen({super.key});

  @override
  State<BusinessNotificationScreen> createState() => _BusinessNotificationScreenState();
}

class _BusinessNotificationScreenState extends State<BusinessNotificationScreen> {
  final _api = ApiClient();
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final title = _title.text.trim();
    final body = _body.text.trim();
    if (title.length < 2 || body.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add a title and a message first.')));
      return;
    }
    setState(() => _sending = true);
    try {
      await _api.post('/notifications', {
        'title': title,
        'body': body,
        'targetType': 'CUSTOMERS',
      });
      if (!mounted) return;
      _title.clear();
      _body.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification sent to your customers.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.tealDark),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.line)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.line)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        title: Text('Notify Customers', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppColors.ink)),
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.teal.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(18)),
            child: Row(children: [
              const Icon(Icons.groups_rounded, color: AppColors.tealDark, size: 28),
              const SizedBox(width: 12),
              Expanded(child: Text('Send a professional update to customers who joined your loyalty card.', style: GoogleFonts.plusJakartaSans(color: AppColors.tealDark, fontWeight: FontWeight.w600))),
            ]),
          ),
          const SizedBox(height: 22),
          TextField(controller: _title, maxLength: 60, decoration: _decoration('Notification title', Icons.title_rounded)),
          const SizedBox(height: 14),
          TextField(controller: _body, maxLength: 300, maxLines: 5, decoration: _decoration('Message', Icons.notes_rounded)),
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _sending ? null : _send,
              icon: _sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded),
              label: Text(_sending ? 'Sending...' : 'Send to Customers'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ),
        ],
      ),
    );
  }
}
