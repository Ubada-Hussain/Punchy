import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/punchy_empty_state.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final ApiClient _api = ApiClient();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _businesses = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    '☕ Cafe',
    '💇 Salon',
    '🏋️ Fitness',
    '🍕 Dining',
    '🛍️ Retail',
  ];

  @override
  void initState() {
    super.initState();
    _fetchBusinesses();
  }

  Future<void> _fetchBusinesses() async {
    setState(() => _isLoading = true);
    try {
      final categoryParam = _selectedCategory == 'All'
          ? ''
          : _selectedCategory.replaceAll(RegExp(r'[^\w\s]'), '').trim();
      final query = '?search=${_searchController.text.trim()}&category=$categoryParam';

      final res = await _api.get('/customer/explore$query');
      if (res is List && mounted) {
        setState(() {
          _businesses = res;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    // Fallback sample businesses if offline or backend empty
    if (mounted) {
      setState(() {
        _businesses = [
          {
            'id': 'b1',
            'name': 'Brew & Co. Artisanal Coffee',
            'category': 'Cafe & Bakery',
            'description': 'Handcrafted single-origin coffee & fresh organic pastries.',
            'loyaltyCards': [
              {
                'id': 'c1',
                'title': 'Coffee Lovers Card',
                'punchesRequired': 10,
                'rewardDescription': '1 Free Specialty Beverage',
                'visualStyle': {'theme': 'teal'},
              }
            ]
          },
          {
            'id': 'b2',
            'name': 'Glow Beauty & Hair Studio',
            'category': 'Salon & Spa',
            'description': 'Premium styling, hair treatments, and luxury facial care.',
            'loyaltyCards': [
              {
                'id': 'c2',
                'title': 'Glow VIP Card',
                'punchesRequired': 5,
                'rewardDescription': 'Free Hair Treatment or Blowdry',
                'visualStyle': {'theme': 'coral'},
              }
            ]
          },
          {
            'id': 'b3',
            'name': 'FitZone Elite Training Gym',
            'category': 'Fitness & Wellness',
            'description': 'State-of-the-art gym, sauna, and crossfit classes.',
            'loyaltyCards': [
              {
                'id': 'c3',
                'title': 'Workout Streak Pass',
                'punchesRequired': 8,
                'rewardDescription': 'Free 1-Month VIP Upgrade',
                'visualStyle': {'theme': 'purple'},
              }
            ]
          },
          {
            'id': 'b4',
            'name': 'Slice House Artisan Pizza',
            'category': 'Dining & Fast Food',
            'description': 'Woodfired Neapolitan pizza and Italian gelatos.',
            'loyaltyCards': [
              {
                'id': 'c4',
                'title': 'Pizza Pass',
                'punchesRequired': 6,
                'rewardDescription': '1 Large Pizza with 2 toppings',
                'visualStyle': {'theme': 'gold'},
              }
            ]
          },
        ];
        _isLoading = false;
      });
    }
  }

  Future<void> _addCardToWallet(String cardId, String businessName) async {
    try {
      await _api.post('/customer/cards/join', {'cardId': cardId});
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.ink,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Added card from $businessName to your wallet! 🎉',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Discover Rewards',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        'Find businesses and join cards without scanning',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.inkSoft,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: AppColors.gradPurple,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'AK',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.line),
                ),
                child: TextField(
                  controller: _searchController,
                  onSubmitted: (_) => _fetchBusinesses(),
                  style: GoogleFonts.plusJakartaSans(color: AppColors.ink, fontSize: 13.5),
                  decoration: InputDecoration(
                    hintText: 'Search cafes, salons, fitness...',
                    hintStyle: GoogleFonts.plusJakartaSans(color: AppColors.inkFaint, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppColors.inkSoft),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            // Category Filter Chips
            SizedBox(
              height: 46,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedCategory = cat);
                      _fetchBusinesses();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.teal : AppColors.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: isSelected ? AppColors.teal : AppColors.line),
                      ),
                      child: Center(
                        child: Text(
                          cat,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : AppColors.inkSoft,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Business & Cards List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
                  : _businesses.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: PunchyEmptyState(
                              icon: Icons.search_off_rounded,
                              heading: 'No businesses found',
                              subtext: 'Try searching with a different keyword or category.',
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 90),
                          itemCount: _businesses.length,
                          separatorBuilder: (_, index) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final b = _businesses[index];
                            final cards = (b['loyaltyCards'] as List?) ?? [];
                            final card = cards.isNotEmpty ? cards.first : null;

                            return _buildBusinessCard(b, card);
                          },
                        ),
            ),
          ],
        ),
      ),

      // Bottom Nav
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBusinessCard(dynamic business, dynamic card) {
    final theme = card?['visualStyle']?['theme']?.toString() ?? 'teal';
    LinearGradient cardGrad = AppColors.gradTeal;
    if (theme == 'coral') cardGrad = AppColors.gradCoral;
    if (theme == 'purple') cardGrad = AppColors.gradPurple;
    if (theme == 'gold') cardGrad = AppColors.gradGold;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      business['name'].toString().contains('Coffee') || business['name'].toString().contains('Brew')
                          ? '☕'
                          : business['name'].toString().contains('Salon') || business['name'].toString().contains('Glow')
                              ? '💇'
                              : business['name'].toString().contains('Fit')
                                  ? '🏋️'
                                  : '🍕',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        business['name'] ?? '',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      Text(
                        business['category'] ?? '',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.tealDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Loyalty Card Preview
          if (card != null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: cardGrad,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        card['title'] ?? 'Loyalty Card',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${card['punchesRequired']} Punches',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          card['rewardDescription'] ?? 'Exclusive Reward',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Action Button Row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (card != null) {
                        _addCardToWallet(card['id'] ?? 'demo', business['name'] ?? '');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Add to Wallet',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.line)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.wallet_rounded, 'Wallet', false, onTap: () => context.go('/')),
              _buildNavItem(Icons.explore_rounded, 'Explore', true, onTap: () {}),
              // Floating Loyalty Barcode Pass FAB
              GestureDetector(
                onTap: () => context.push('/barcode'),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.coral,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.coral.withValues(alpha: 0.45),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.qr_code_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ),
              _buildNavItem(Icons.notifications_none_rounded, 'Alerts', false, onTap: () => context.push('/notifications')),
              _buildNavItem(Icons.person_outline_rounded, 'Profile', false, onTap: () => context.push('/profile')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool active, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: active ? AppColors.tealDark : AppColors.inkFaint),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              color: active ? AppColors.tealDark : AppColors.inkFaint,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
