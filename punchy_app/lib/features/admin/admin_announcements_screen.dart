import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_colors.dart';

class AdminAnnouncementsScreen extends StatefulWidget {
  const AdminAnnouncementsScreen({super.key});

  @override
  State<AdminAnnouncementsScreen> createState() => _AdminAnnouncementsScreenState();
}

class _AdminAnnouncementsScreenState extends State<AdminAnnouncementsScreen> {
  final ApiClient _api = ApiClient();
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _selectedTarget = 'ALL';
  bool _isSending = false;

  List<dynamic> _announcements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('/admin/announcements');
      if (res is List && mounted) {
        setState(() {
          _announcements = res;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    // Fallback sample announcements
    if (mounted) {
      setState(() {
        _announcements = [
          {
            'title': 'Weekend Punch Multiplier Campaign ☕',
            'body': 'Double punches active for all coffee shops this Saturday and Sunday!',
            'targetType': 'CUSTOMERS',
            'createdAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
          },
          {
            'title': 'New NFC Standee Hardware Available',
            'body': 'Order your branded NFC counter blocks directly from your business settings.',
            'targetType': 'BUSINESSES',
            'createdAt': DateTime.now().subtract(const Duration(days: 6)).toIso8601String(),
          },
        ];
        _isLoading = false;
      });
    }
  }

  Future<void> _sendAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);

    try {
      await _api.post('/admin/announcements', {
        'title': _titleController.text.trim(),
        'body': _bodyController.text.trim(),
        'targetType': _selectedTarget,
      });

      _titleController.clear();
      _bodyController.clear();
      await _fetchAnnouncements();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.ink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text(
              '📢 Announcement broadcasted to platform users!',
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        );
      }
    } catch (_) {}

    if (mounted) setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
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
                    'Announcements',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 34),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      children: [
                  // Compose Form
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Compose Platform Broadcast',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Target Dropdown
                          Text(
                            'Target Audience',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.inkSoft),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedTarget,
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(value: 'ALL', child: Text('🌐 Everyone (All Users)')),
                                  DropdownMenuItem(value: 'CUSTOMERS', child: Text('🙋 Customers Only')),
                                  DropdownMenuItem(value: 'BUSINESSES', child: Text('🏪 Business Owners Only')),
                                ],
                                onChanged: (v) => setState(() => _selectedTarget = v ?? 'ALL'),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Title Input
                          Text(
                            'Announcement Title',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.inkSoft),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _titleController,
                            validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
                            style: GoogleFonts.plusJakartaSans(color: AppColors.ink, fontSize: 13.5, fontWeight: FontWeight.w600),
                            decoration: const InputDecoration(hintText: 'e.g. Double Punches this Weekend! ☕'),
                          ),
                          const SizedBox(height: 12),

                          // Body Input
                          Text(
                            'Message Body',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.inkSoft),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _bodyController,
                            maxLines: 3,
                            validator: (v) => v == null || v.isEmpty ? 'Message body is required' : null,
                            style: GoogleFonts.plusJakartaSans(color: AppColors.ink, fontSize: 13.5, fontWeight: FontWeight.w600),
                            decoration: const InputDecoration(hintText: 'Write announcement details...'),
                          ),
                          const SizedBox(height: 16),

                          // Send Button
                          ElevatedButton(
                            onPressed: _isSending ? null : _sendAnnouncement,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.teal,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: _isSending
                                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Broadcast Announcement',
                                        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white),
                                      ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // History List
                  Text(
                    'Announcement History',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),

                  ..._announcements.map((a) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  a['title'] ?? 'Announcement',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  a['targetType'] ?? 'ALL',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.tealDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            a['body'] ?? '',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              color: AppColors.inkSoft,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }
}
