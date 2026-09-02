import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/api/api_client.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportSheet extends StatefulWidget {
  const SupportSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const SupportSheet(),
    );
  }

  @override
  State<SupportSheet> createState() => _SupportSheetState();
}

class _SupportSheetState extends State<SupportSheet> {
  final _subject = TextEditingController();
  final _body = TextEditingController();
  bool _sending = false;

  @override
  void dispose() { _subject.dispose(); _body.dispose(); super.dispose(); }

  Future<void> _openChat() async {
    final subject = _subject.text.trim();
    final body = _body.text.trim();
    if (subject.length < 5 || body.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a subject and describe your issue.')));
      return;
    }
    setState(() => _sending = true);
    try {
      await ApiClient().post('/tickets', {'subject': subject, 'body': body});
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Support request submitted. An agent will respond soon.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e is ApiException ? e.message : 'Could not submit support request.')));
    } finally { if (mounted) setState(() => _sending = false); }
  }

  Future<void> _showChatForm() async {
    await showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Live Chat with Agent'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: _subject, decoration: const InputDecoration(labelText: 'Subject')),
        TextField(controller: _body, maxLines: 4, decoration: const InputDecoration(labelText: 'Describe your issue')),
      ]),
      actions: [TextButton(onPressed: _sending ? null : () => Navigator.pop(dialogContext), child: const Text('Cancel')), ElevatedButton(onPressed: _sending ? null : _openChat, child: Text(_sending ? 'Sending…' : 'Send'))],
    ));
  }

  Future<void> _openEmailSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'ubadahussain23@gmail.com',
      queryParameters: {'subject': 'Punchy Support Request'},
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No email app is available on this device.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(Icons.help_outline_rounded, size: 18, color: AppColors.tealDark),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Punchy Support',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.inkSoft),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'How can our team help you today?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),

            // Options
            _buildOption(
              icon: Icons.mail_outline_rounded,
              title: 'Email Support',
              subtitle: 'ubadahussain23@gmail.com',
              onTap: _openEmailSupport,
            ),
            const SizedBox(height: 10),
            _buildOption(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Live Chat with Agent',
              subtitle: 'Average response time: 2 mins',
              onTap: () { _showChatForm(); },
            ),
            const SizedBox(height: 10),
            _buildOption(
              icon: Icons.article_outlined,
              title: 'Help Center & FAQs',
              subtitle: 'Troubleshooting guides and policies',
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(10),
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
                          fontSize: 11.5,
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
      ),
    );
  }
}
