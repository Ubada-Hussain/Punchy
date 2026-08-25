import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _selectedFilter = 0; // 0 = All, 1 = Rewards Ready, 2 = Punches

  final List<Map<String, dynamic>> _notifications = [
    {
      'id': 'n1',
      'type': 'REWARD_READY',
      'business': 'Glow Beauty & Salon',
      'logo': '💇',
      'title': '🎉 Loyalty Card Complete!',
      'message': 'Congratulations! You collected all 5 punches on your Glow VIP Card. Your Free Hair Treatment is ready to redeem in-store.',
      'punches': '5/5 punches',
      'time': '10 minutes ago',
      'isUnread': true,
      'gradient': AppColors.gradCoral,
    },
    {
      'id': 'n2',
      'type': 'PUNCH_PROGRESS',
      'business': 'Brew & Co. Coffee',
      'logo': '☕',
      'title': '☕ Only 2 punches left!',
      'message': 'You are super close! Just 2 more punches on your Coffee Lovers Card to get your Free Specialty Beverage.',
      'punches': '8/10 punches',
      'time': '2 hours ago',
      'isUnread': true,
      'gradient': AppColors.gradTeal,
    },
    {
      'id': 'n3',
      'type': 'PUNCH_ADDED',
      'business': 'FitZone Gym',
      'logo': '🏋️',
      'title': '⭐ Punch Added!',
      'message': 'You earned 1 punch on your Workout Streak Pass. 6 of 8 punches completed. Keep the streak going!',
      'punches': '6/8 punches',
      'time': 'Yesterday',
      'isUnread': false,
      'gradient': AppColors.gradPurple,
    },
    {
      'id': 'n4',
      'type': 'WELCOME_CARD',
      'business': 'Slice House Pizza',
      'logo': '🍕',
      'title': '🍕 Card Joined & First Punch!',
      'message': 'Welcome to Slice House Pizza Pass! 1 of 6 punches collected. 5 more until your Free Large Pizza.',
      'punches': '1/6 punches',
      'time': '2 days ago',
      'isUnread': false,
      'gradient': AppColors.gradGold,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredList = _notifications.where((n) {
      if (_selectedFilter == 1) return n['type'] == 'REWARD_READY';
      if (_selectedFilter == 2) return n['type'] == 'PUNCH_PROGRESS' || n['type'] == 'PUNCH_ADDED';
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
                  _buildFilterChip(1, '🎉 Rewards Ready'),
                  const SizedBox(width: 8),
                  _buildFilterChip(2, '☕ Punches'),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Notifications List
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
                itemCount: filteredList.length,
                separatorBuilder: (_, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final notif = filteredList[index];
                  final isReward = notif['type'] == 'REWARD_READY';

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isReward ? AppColors.coral.withValues(alpha: 0.35) : AppColors.line,
                        width: isReward ? 1.5 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isReward ? AppColors.coral.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top row with business and time
                        Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: Center(
                                child: Text(notif['logo'], style: const TextStyle(fontSize: 18)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notif['business'],
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  Text(
                                    notif['time'],
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isReward
                                    ? AppColors.coral.withValues(alpha: 0.15)
                                    : AppColors.teal.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                notif['punches'],
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  color: isReward ? AppColors.coralDark : AppColors.tealDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Title
                        Text(
                          notif['title'],
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isReward ? AppColors.coralDark : AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Message body
                        Text(
                          notif['message'],
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
