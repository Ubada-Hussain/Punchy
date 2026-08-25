import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_colors.dart';
import 'card_detail_screen.dart';

class CustomerDashboardScreen extends StatefulWidget {
  const CustomerDashboardScreen({super.key});

  @override
  State<CustomerDashboardScreen> createState() => _CustomerDashboardScreenState();
}

class _CustomerDashboardScreenState extends State<CustomerDashboardScreen> {
  final ApiClient _api = ApiClient();
  bool _isLoading = true;
  List<dynamic> _cards = [];
  int _activeNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('/customer/cards');
      if (res != null && res is List && res.isNotEmpty) {
        setState(() {
          _cards = res;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    // Mock fallback matching punchy-app-ui.html exactly
    setState(() {
      _cards = [
        {
          'id': 'card-1',
          'punchCount': 6,
          'isCompleted': false,
          'card': {
            'id': 'c1',
            'title': 'Brew & Co.',
            'punchesRequired': 10,
            'rewardDescription': '1 Free Coffee',
            'visualStyle': {'theme': 'teal', 'icon': '☕'},
            'business': {'name': 'Brew & Co.', 'logo': '☕', 'category': '☕ Café'}
          },
          'punchTransactions': [
            {'method': 'QR', 'timestamp': 'Today, 10:24 AM'},
            {'method': 'QR', 'timestamp': 'Aug 21, 5:10 PM'},
          ]
        },
        {
          'id': 'card-2',
          'punchCount': 2,
          'isCompleted': false,
          'card': {
            'id': 'c2',
            'title': 'Glow Salon',
            'punchesRequired': 5,
            'rewardDescription': 'Free Hair Treatment',
            'visualStyle': {'theme': 'coral', 'icon': '💇'},
            'business': {'name': 'Glow Salon', 'logo': '💇', 'category': '💇 Salon'}
          },
          'punchTransactions': [
            {'method': 'NFC', 'timestamp': 'Aug 18, 3:15 PM'},
          ]
        },
        {
          'id': 'card-3',
          'punchCount': 8,
          'isCompleted': true,
          'card': {
            'id': 'c3',
            'title': 'FitZone Gym',
            'punchesRequired': 8,
            'rewardDescription': '1 Free Protein Shake',
            'visualStyle': {'theme': 'purple', 'icon': '🏋️'},
            'business': {'name': 'FitZone Gym', 'logo': '🏋️', 'category': '🏋️ Fitness'}
          },
          'punchTransactions': [
            {'method': 'QR', 'timestamp': 'Yesterday, 6:00 PM'},
          ]
        }
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadCards,
                color: AppColors.teal,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  children: [
                    // Top Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi Ayesha 👋',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Let's collect some punches",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppColors.inkSoft,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Switch to Business view button
                            GestureDetector(
                              onTap: () => context.push('/business'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.line),
                                ),
                                child: Row(
                                  children: [
                                    const Text('🏪', style: TextStyle(fontSize: 12)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Business',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.tealDark,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Bell icon
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                border: Border.all(color: AppColors.line),
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Center(
                                child: Icon(Icons.notifications_none_rounded, color: AppColors.ink, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Search Bar -> Navigates to Explore
                    GestureDetector(
                      onTap: () => context.push('/explore'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.line, width: 1.5),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, color: AppColors.inkFaint, size: 18),
                            const SizedBox(width: 9),
                            Text(
                              'Find a business or card...',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppColors.inkFaint,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Your Cards Title + See All
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your cards',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          'See all',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.tealDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Wallet Cards List
                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(30),
                          child: CircularProgressIndicator(color: AppColors.teal),
                        ),
                      )
                    else if (_cards.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceAlt,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.credit_card_off_rounded, color: AppColors.tealDark, size: 26),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Your wallet is empty',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Explore nearby businesses to join loyalty cards and start collecting punches!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppColors.inkSoft,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => context.push('/explore'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.teal,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                              ),
                              child: Text(
                                'Explore Businesses',
                                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: _cards.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _buildWalletCard(c),
                        )).toList(),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Bar
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletCard(Map<String, dynamic> cardData) {
    final cardInfo = cardData['card'] ?? {};
    final biz = cardInfo['business'] ?? {};
    final bizName = biz['name'] ?? cardInfo['title'] ?? 'Brew & Co.';
    final bizCat = biz['category'] ?? '☕ Café';
    final bizLogo = biz['logo'] ?? cardInfo['visualStyle']?['icon'] ?? '☕';
    final punchCount = cardData['punchCount'] as int? ?? 6;
    final punchesRequired = cardInfo['punchesRequired'] as int? ?? 10;
    final isCompleted = cardData['isCompleted'] == true || punchCount >= punchesRequired;

    final themeStr = (cardInfo['visualStyle']?['theme'] ?? 'teal').toString().toLowerCase();
    final gradient = themeStr == 'coral'
        ? AppColors.gradCoral
        : themeStr == 'purple'
            ? AppColors.gradPurple
            : themeStr == 'gold'
                ? AppColors.gradGold
                : AppColors.gradTeal;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CardDetailScreen(cardData: cardData),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.last.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bizName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bizCat,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: Text(bizLogo, style: const TextStyle(fontSize: 15)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Bottom Row (Dots + Badge)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Small indicator dots
                Wrap(
                  spacing: 4,
                  children: List.generate(punchesRequired, (i) {
                    final isOn = i < punchCount;
                    return Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOn ? Colors.white : Colors.white.withValues(alpha: 0.4),
                      ),
                    );
                  }),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isCompleted ? '$punchCount/$punchesRequired 🎉' : '$punchCount/$punchesRequired',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.line)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.home_rounded, 'Home'),
          _buildNavItem(1, Icons.explore_rounded, 'Explore', onTap: () => context.push('/explore')),
          // Center Coral Scan FAB
          GestureDetector(
            onTap: () => context.push('/scanner'),
            child: Container(
              width: 46,
              height: 46,
              margin: const EdgeInsets.only(top: 0),
              decoration: BoxDecoration(
                gradient: AppColors.gradCoral,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.coral.withValues(alpha: 0.6),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          _buildNavItem(2, Icons.notifications_none_rounded, 'Alerts', onTap: () => context.push('/system-states')),
          _buildNavItem(3, Icons.person_outline_rounded, 'Profile', onTap: () => context.push('/profile')),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {VoidCallback? onTap}) {
    final isActive = _activeNavIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _activeNavIndex = index);
        if (onTap != null) onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 21,
            color: isActive ? AppColors.teal : AppColors.inkFaint,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isActive ? AppColors.teal : AppColors.inkFaint,
            ),
          ),
        ],
      ),
    );
  }
}
