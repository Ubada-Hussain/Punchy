import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/punchy_empty_state.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiClient _api = ApiClient();
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  int _selectedFilter = 0; // 0 = All Updates, 1 = Broadcasts, 2 = Direct

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('/notifications');
      if (res is Map<String, dynamic> && res['notifications'] is List && mounted) {
        setState(() {
          _notifications = res['notifications'];
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _notifications = [];
        _isLoading = false;
      });
    }
  }

  String _formatTime(dynamic dateVal) {
    if (dateVal == null) return 'Recently';
    try {
      final dt = DateTime.parse(dateVal.toString());
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]}';
    } catch (_) {
      return 'Recently';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _notifications.where((n) {
      final target = (n['targetType'] ?? 'ALL').toString().toUpperCase();
      if (_selectedFilter == 1) return target == 'ALL' || target == 'CUSTOMERS' || target == 'BUSINESSES';
      if (_selectedFilter == 2) return target == 'USER';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
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
                    'Punch Notifications',
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

            // Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Row(
                children: [
                  _buildFilterChip(0, 'All Updates'),
                  const SizedBox(width: 8),
                  _buildFilterChip(1, '📢 Broadcasts'),
                  const SizedBox(width: 8),
                  _buildFilterChip(2, '👤 Personal'),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Notifications List / Empty State
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
                  : RefreshIndicator(
                      color: AppColors.teal,
                      onRefresh: _loadNotifications,
                      child: filteredList.isEmpty
                          ? Center(
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: PunchyEmptyState.noNotifications(),
                                ),
                              ),
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
                              itemCount: filteredList.length,
                              separatorBuilder: (_, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final notif = filteredList[index];
                                final creatorName = notif['creator']?['name'] ?? notif['creator']?['email']?.split('@')[0] ?? 'Punchy Platform';
                                final time = _formatTime(notif['sentAt'] ?? notif['createdAt']);
                                final target = (notif['targetType'] ?? 'ALL').toString();

                                return Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.line),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.03),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Top row with creator and time
                                      Row(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: AppColors.surfaceAlt,
                                              borderRadius: BorderRadius.circular(11),
                                            ),
                                            child: const Center(
                                              child: Icon(Icons.notifications_active_outlined, size: 18, color: AppColors.tealDark),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  creatorName,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 13.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: AppColors.ink,
                                                  ),
                                                ),
                                                Text(
                                                  time,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 11,
                                                    color: AppColors.inkFaint,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppColors.teal.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              target,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.tealDark,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // Title
                                      Text(
                                        notif['title'] ?? 'Notification',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                      const SizedBox(height: 4),

                                      // Message body
                                      Text(
                                        notif['body'] ?? '',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12.5,
                                          color: AppColors.inkSoft,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.teal : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: isSelected ? AppColors.teal : AppColors.line),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }
}
