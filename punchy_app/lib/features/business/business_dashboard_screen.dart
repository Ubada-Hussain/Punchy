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
        _dashboardData = <String, dynamic>{};
        _isLoading = false;
      });
    }
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return 'No expiry';
    try {
      final dt = DateTime.parse(dateVal.toString());
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return dateVal.toString();
    }
  }

  Future<void> _deleteCard(String cardId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Active Card?',
          style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.ink),
        ),
        content: Text(
          'A business can only have 1 active loyalty card at a time. Deleting this card will allow you to create a new one.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.inkSoft, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: AppColors.inkSoft, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coralDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Delete Card', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _api.delete('/business/cards/$cardId');
        await _loadDashboard();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.ink,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              content: Text(
                '🗑️ Card deleted. You can now create a new loyalty card!',
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          );
        }
      } catch (_) {}
    }
  }

  void _handleNewCardTap(dynamic activeCard) {
    if (activeCard != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.coralDark, size: 22),
              const SizedBox(width: 8),
              Text(
                'Active Card Limit',
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
            ],
          ),
          content: Text(
            'Each business can only have 1 active card at a time. To add a new card, please delete or edit your existing active card first.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.inkSoft, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Got It', style: GoogleFonts.plusJakartaSans(color: AppColors.inkSoft, fontWeight: FontWeight.w700)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => CreateCardScreen(
                      cardId: activeCard['id'],
                      initialData: activeCard,
                    ),
                  ),
                ).then((_) => _loadDashboard());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('Edit / Delete Card', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    } else {
      context.push('/business/cards/new').then((_) => _loadDashboard());
    }
  }

  @override
  Widget build(BuildContext context) {
    final business = _dashboardData?['business'] ?? {};
    final stats = _dashboardData?['stats'] ?? {'totalCustomers': 0, 'punchesToday': 0, 'rewardsRedeemed': 0};
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
                    // Top Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              business['name'] ?? 'My Business',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Merchant Dashboard',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppColors.inkSoft,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        // Actions: Staff + Setup Gear Button
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => context.push('/business/staff'),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  border: Border.all(color: AppColors.line),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: const Center(
                                  child: Icon(Icons.badge_outlined, color: AppColors.tealDark, size: 18),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => context.push('/business/setup'),
                              child: Container(
                                width: 36,
                                height: 36,
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
                          Row(
                            children: [
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
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => _deleteCard(activeCard['id']),
                                child: Text(
                                  'Delete',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.coralDark,
                                  ),
                                ),
                              ),
                            ],
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
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
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '⏳ Valid till: ${_formatDate(activeCard['validUntil'])}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.95),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () => context.push('/business/cards/new').then((_) => _loadDashboard()),
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
                                'Create Your Loyalty Card (1 Active Max)',
                                style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.ink),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Quick Actions (New Card + Staff + Customers)
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
                            onTap: () => _handleNewCardTap(activeCard),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: activeCard == null ? AppColors.coral : AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: activeCard == null ? null : Border.all(color: AppColors.line, width: 1.5),
                                boxShadow: activeCard == null
                                    ? [
                                        BoxShadow(
                                          color: AppColors.coral.withValues(alpha: 0.4),
                                          blurRadius: 14,
                                          offset: const Offset(0, 6),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_rounded,
                                    color: activeCard == null ? Colors.white : AppColors.inkSoft,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    activeCard == null ? 'New card' : 'Card (1/1)',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: activeCard == null ? Colors.white : AppColors.inkSoft,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => context.push('/business/staff'),
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.teal.withValues(alpha: 0.5), width: 1.5),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.badge_outlined, color: AppColors.tealDark, size: 17),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Staff',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.tealDark,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                                  const Icon(Icons.people_outline_rounded, color: AppColors.ink, size: 17),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Customers',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
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
                      child: recentActivity.isNotEmpty
                          ? Column(
                              children: recentActivity.map((a) {
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
                              }).toList(),
                            )
                          : Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                              child: Center(
                                child: Column(
                                  children: [
                                    const Icon(Icons.history_toggle_off_rounded, size: 28, color: AppColors.inkSoft),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No recent activity yet',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Customer punches and redemptions will appear here live.',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        color: AppColors.inkSoft,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
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
          Expanded(child: _buildNavItem(0, Icons.home_rounded, 'Home', onTap: () {})),
          Expanded(child: _buildNavItem(1, Icons.credit_card_rounded, 'Cards', onTap: () => context.push('/business/cards/new'))),
          // Center Raised Scanner FAB
          Expanded(child: GestureDetector(
            onTap: () => context.push('/business/scan'),
            child: Center(child: Container(
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
                Icons.qr_code_scanner_rounded,
                color: Colors.white,
                size: 26,
              ),
            )),
          )),
          Expanded(child: _buildNavItem(2, Icons.notifications_none_rounded, 'Notifications', onTap: () => context.push('/notifications'))),
          Expanded(child: _buildNavItem(3, Icons.person_outline_rounded, 'Profile', onTap: () => context.push('/business/profile'))),
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
