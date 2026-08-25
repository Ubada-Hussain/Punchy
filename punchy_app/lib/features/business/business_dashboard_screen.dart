import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/theme/app_colors.dart';
import 'create_card_screen.dart';

class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key});

  @override
  State<BusinessDashboardScreen> createState() => _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> {
  final ApiClient _api = ApiClient();
  int _activeNavIndex = 0;

  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.get('/business/dashboard');
      if (res is Map<String, dynamic> && mounted) {
        setState(() {
          _dashboardData = res;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    // Fallback data if offline
    if (mounted) {
      setState(() {
        _dashboardData = {
          'business': {'name': 'Brew & Co.', 'category': 'Cafe & Bakery'},
          'stats': {'totalCustomers': 312, 'punchesToday': 48, 'rewardsRedeemed': 19},
          'cards': [
            {
              'id': 'c1',
              'title': 'Coffee Lovers Card',
              'punchesRequired': 10,
              'rewardDescription': '1 Free Specialty Beverage',
              'visualStyle': {'theme': 'teal'},
            }
          ],
          'recentActivity': [
            {'customerEmail': 'ayesha@email.com', 'cardTitle': 'Coffee Lovers Card', 'timestamp': DateTime.now().subtract(const Duration(minutes: 2)).toIso8601String()},
            {'customerEmail': 'bilal.r@gmail.com', 'cardTitle': 'Coffee Lovers Card', 'timestamp': DateTime.now().subtract(const Duration(minutes: 40)).toIso8601String()},
            {'customerEmail': 'sana.m@outlook.com', 'cardTitle': 'Coffee Lovers Card', 'timestamp': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String()},
          ],
        };
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final business = _dashboardData?['business'] ?? {'name': 'Brew & Co.'};
    final stats = _dashboardData?['stats'] ?? {'totalCustomers': 312, 'punchesToday': 48, 'rewardsRedeemed': 19};
    final cards = (_dashboardData?['cards'] as List?) ?? [];
    final activeCard = cards.isNotEmpty ? cards.first : null;
    final recentActivity = (_dashboardData?['recentActivity'] as List?) ?? [];

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.teal))
                  : RefreshIndicator(
                      color: AppColors.teal,
                      onRefresh: _loadDashboard,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        children: [
                    // Top Row (Greeting + Switch view + Setup)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good morning ☕',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              business['name'] ?? 'Brew & Co.',
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
                            // Switch to Customer view button
                            GestureDetector(
                              onTap: () => context.go('/'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.line),
                                ),
                                child: Row(
                                  children: [
                                    const Text('🙋', style: TextStyle(fontSize: 12)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Customer',
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
                            // Business Setup Gear Button
                            GestureDetector(
                              onTap: () => context.push('/business/setup'),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  border: Border.all(color: AppColors.line),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: const Center(
                                  child: Icon(Icons.settings_outlined, color: AppColors.ink, size: 18),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Stat Row
                    Row(
                      children: [
                        Expanded(child: _buildStatBox('Customers', '${stats['totalCustomers'] ?? 0}')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStatBox('Punches today', '${stats['punchesToday'] ?? 0}')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildStatBox('Redeemed', '${stats['rewardsRedeemed'] ?? 0}')),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Your Loyalty Card Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your loyalty card',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        if (activeCard != null)
                          GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CreateCardScreen(
                                  cardId: activeCard['id'],
                                  initialData: activeCard,
                                ),
                              ),
                            ).then((_) => _loadDashboard()),
                            child: Text(
                              'Edit',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.tealDark,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Punch Card Preview
                    if (activeCard != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: AppColors.gradTeal,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.teal.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Center(
                                child: Text('☕', style: TextStyle(fontSize: 16)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activeCard['title'] ?? 'Coffee Lovers Card',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    '${activeCard['punchesRequired'] ?? 10} punches → ${activeCard['rewardDescription'] ?? 'Free Coffee'}',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withValues(alpha: 0.85),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 24),
                          ],
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () => context.push('/business/cards/new'),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.line),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_circle_outline_rounded, color: AppColors.tealDark),
                              const SizedBox(width: 8),
                              Text(
                                'Create Your First Loyalty Card',
                                style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Quick Actions (New Card + Customers)
                    Text(
                      'Quick actions',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => context.push('/business/cards/new'),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.coral,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.coral.withValues(alpha: 0.4),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'New card',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => context.push('/business/customers'),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.line, width: 1.5),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.people_outline_rounded, color: AppColors.ink, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Customers',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Recent Activity (Customer Punches / Redemptions)
                    Text(
                      'Recent activity',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Column(
                        children: recentActivity.isNotEmpty
                            ? recentActivity.map((a) {
                                return Column(
                                  children: [
                                    _buildActivityRow(
                                      '${a['customerEmail'] ?? 'Customer'} — punch recorded',
                                      'Recent in-store activity',
                                      Icons.qr_code_2_rounded,
                                    ),
                                    const Divider(height: 1, color: AppColors.line),
                                  ],
                                );
                              }).toList()
                            : [
                                _buildActivityRow('Ayesha K. — punch added', '2 minutes ago', Icons.qr_code_2_rounded),
                                const Divider(height: 1, color: AppColors.line),
                                _buildActivityRow('Bilal R. — redeemed reward', '40 minutes ago', Icons.card_giftcard_rounded),
                                const Divider(height: 1, color: AppColors.line),
                                _buildActivityRow('Sana M. — joined card', '1 hour ago', Icons.person_add_alt_1_rounded),
                              ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom Nav: Home, Cards, Scan, Customers, Profile
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.inkSoft,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityRow(String title, String sub, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: AppColors.tealDark, size: 16),
          ),
          const SizedBox(width: 11),
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
                  sub,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
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
          _buildNavItem(0, Icons.home_rounded, 'Home', onTap: () {}),
          _buildNavItem(1, Icons.credit_card_rounded, 'Cards', onTap: () => context.push('/business/cards/new')),
          // Center Raised Add Card FAB
          GestureDetector(
            onTap: () => context.push('/business/cards/new'),
            child: Container(
              width: 46,
              height: 46,
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
                Icons.add_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
          _buildNavItem(2, Icons.people_alt_rounded, 'Customers', onTap: () => context.push('/business/customers')),
          _buildNavItem(3, Icons.person_outline_rounded, 'Profile', onTap: () => context.push('/business/profile')),
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
