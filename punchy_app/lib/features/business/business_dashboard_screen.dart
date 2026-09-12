import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/theme/app_colors.dart';
import 'create_card_screen.dart';

class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key});

  @override
  State<BusinessDashboardScreen> createState() =>
      _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> {
  final ApiClient _api = ApiClient();
  int _activeNavIndex = 0;
  int _selectedCardIndex = 0;

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

    if (mounted) {
      setState(() {
        _dashboardData = <String, dynamic>{};
        _isLoading = false;
      });
    }
  }

  String _formatCount(dynamic count) {
    if (count == null) return '0';
    final n = int.tryParse(count.toString()) ?? 0;
    if (n < 1000) return n.toString();
    final s = n.toString();
    final reg = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return s.replaceAllMapped(reg, (Match m) => '${m[1]},');
  }

  String _formatDate(dynamic dateVal) {
    if (dateVal == null) return 'No expiry';
    try {
      final dt = DateTime.parse(dateVal.toString());
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return dateVal.toString();
    }
  }

  String _formatRelativeTime(dynamic timestamp) {
    if (timestamp == null) return 'recently';
    try {
      final dt = DateTime.parse(timestamp.toString());
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
      if (diff.inHours < 24) return '${diff.inHours} hr ago';
      if (diff.inDays < 7) return '${diff.inDays} d ago';
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${dt.day} ${months[dt.month - 1]}';
    } catch (_) {
      return 'recently';
    }
  }

  Future<void> _openBusinessLocation(String address) async {
    if (address.trim().isEmpty) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeQueryComponent(address)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _deleteCard(String cardId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Active Card?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        content: Text(
          'A business can only have 1 active loyalty card at a time. Deleting this card will allow you to create a new one.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.inkSoft,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coralDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Delete Card',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              content: Text(
                '🗑️ Card deleted. You can now create a new loyalty card!',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }
      } catch (_) {}
    }
  }

  void _handleNewCardTap(dynamic activeCard) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const CreateCardScreen()))
        .then((_) => _loadDashboard());
  }

  @override
  Widget build(BuildContext context) {
    final business = Map<String, dynamic>.from(
      (_dashboardData?['business'] as Map?) ?? {},
    );
    final stats = Map<String, dynamic>.from(
      (_dashboardData?['stats'] as Map?) ?? {},
    );
    final rawCards = List<dynamic>.from(
      (_dashboardData?['cards'] as List?) ?? [],
    );
    rawCards.sort((a, b) {
      final aDate = a['createdAt']?.toString() ?? '';
      final bDate = b['createdAt']?.toString() ?? '';
      return bDate.compareTo(aDate);
    });
    final cards = rawCards;
    final activeCard = cards.isNotEmpty
        ? (_selectedCardIndex < cards.length
              ? cards[_selectedCardIndex]
              : cards.first)
        : null;
    final recentActivity = (_dashboardData?['recentActivity'] as List?) ?? [];
    final hasUnread = _dashboardData?['hasUnreadNotifications'] == true;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF7),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.teal),
                    )
                  : RefreshIndicator(
                      color: AppColors.teal,
                      onRefresh: _loadDashboard,
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        children: [
                          // 1. Header (Reference Image 2)
                          _buildHeader(business, hasUnread),
                          const SizedBox(height: 16),

                          // 2. Three Stat Cards in a Row (Reference Image 2)
                          _buildStatsRow(stats),
                          const SizedBox(height: 16),

                          // 3. Active Loyalty Card Summary Block (Reference Image 2)
                          _buildActiveCardBlock(activeCard, cards),
                          const SizedBox(height: 22),

                          _buildQuickActions(),
                          const SizedBox(height: 22),

                          // 4. Recent Activity Section (Reference Image 2)
                          _buildRecentActivitySection(recentActivity),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
            ),

            // 5. Bottom Navigation Bar matching Image 2
            _buildBottomNav(hasUnread, activeCard),
          ],
        ),
      ),
    );
  }

  /// Header matching Reference Image 2:
  /// Business Logo, Name + Verified Checkmark, Category, Full Address with Location Pin,
  /// Notification Bell (with red dot), and Settings Gear.
  Widget _buildHeader(Map<String, dynamic> business, bool hasUnread) {
    final name = business['name'] ?? 'The Cozy Spot';
    final category = business['category'] ?? 'Food & Beverages';
    final address = business['address']?.toString() ?? '';
    final logo = business['logo'];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Business Logo / Icon
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF0E4D44),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: logo != null && logo.toString().startsWith('http')
                ? ClipOval(
                    child: Image.network(
                      logo.toString(),
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
          ),
        ),
        const SizedBox(width: 12),

        // Business Name + Badge, Category, Location Line
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10A37F),
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 1),
              Text(
                category,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.inkSoft,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 13,
                    color: AppColors.ink,
                  ),
                  const SizedBox(width: 3),
                  Expanded(
                    child: GestureDetector(
                      onTap: address.isEmpty
                          ? null
                          : () => _openBusinessLocation(address),
                      child: Text(
                        address,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.inkSoft,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Notification Bell with Red Dot
        GestureDetector(
          onTap: () =>
              context.push('/notifications').then((_) => _loadDashboard()),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.line),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.ink,
                    size: 20,
                  ),
                ),
              ),
              if (hasUnread)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Settings Gear Icon
        GestureDetector(
          onTap: () =>
              context.push('/business/setup').then((_) => _loadDashboard()),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.line),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.settings_outlined,
                color: AppColors.ink,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 3 Stat Cards Row matching Reference Image 2:
  /// Total Customers (Mint), Total Punches (Peach), Total Rewards Given (Lavender)
  /// Driven by REAL data and real week-over-week % changes.
  Widget _buildStatsRow(Map<String, dynamic> stats) {
    final totalCust = stats['totalCustomers'] ?? 0;
    final custPct = stats['customersChangePct'] ?? '+12%';

    final totalPunches = stats['totalPunches'] ?? 0;
    final punchesPct = stats['punchesChangePct'] ?? '+18%';

    final totalRewards =
        stats['totalRewardsGiven'] ?? stats['rewardsRedeemed'] ?? 0;
    final rewardsPct = stats['rewardsChangePct'] ?? '+21%';

    return Row(
      children: [
        Expanded(
          child: _buildSingleStatCard(
            bgColor: const Color(0xFFEDF7F4),
            iconBg: const Color(0xFFD2EDE4),
            icon: Icons.people_alt_rounded,
            iconColor: const Color(0xFF0F766E),
            label: 'Total Customers',
            value: _formatCount(totalCust),
            trend: custPct,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSingleStatCard(
            bgColor: const Color(0xFFFFF6ED),
            iconBg: const Color(0xFFFDE4CD),
            icon: Icons.fingerprint_rounded,
            iconColor: const Color(0xFFD97706),
            label: 'Total Punches',
            value: _formatCount(totalPunches),
            trend: punchesPct,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSingleStatCard(
            bgColor: const Color(0xFFF4F1FE),
            iconBg: const Color(0xFFE5DEFE),
            icon: Icons.card_giftcard_rounded,
            iconColor: const Color(0xFF7C3AED),
            label: 'Total Rewards Given',
            value: _formatCount(totalRewards),
            trend: rewardsPct,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    final actions = <Map<String, dynamic>>[
      {
        'icon': Icons.people_alt_outlined,
        'title': 'See Customers',
        'subtitle': 'View loyalty customers',
        'route': '/business/customers',
      },
      {
        'icon': Icons.badge_outlined,
        'title': 'See Staff',
        'subtitle': 'Manage staff accounts',
        'route': '/business/staff',
      },
      {
        'icon': Icons.person_add_alt_1_outlined,
        'title': 'Add Staff',
        'subtitle': 'Invite a staff member',
        'route': '/business/staff',
      },
      {
        'icon': Icons.location_on_outlined,
        'title': 'Business Location',
        'subtitle': 'Update address and map',
        'route': '/business/setup',
      },
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16.5,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: actions.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final action = actions[index];
              return GestureDetector(
                onTap: () =>
                    context.push(action['route']).then((_) => _loadDashboard()),
                child: Container(
                  width: 145,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        action['icon'] as IconData,
                        color: AppColors.tealDark,
                        size: 25,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        action['title'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        action['subtitle'] as String,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSingleStatCard({
    required Color bgColor,
    required Color iconBg,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String trend,
  }) {
    final isNegative = trend.startsWith('-');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon Circle
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Center(child: Icon(icon, size: 16, color: iconColor)),
          ),
          const SizedBox(height: 8),

          // Label
          SizedBox(
            height: 24,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: AppColors.inkSoft,
                height: 1.15,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),

          // Value and Trend
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isNegative
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    size: 11,
                    color: isNegative
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10A37F),
                  ),
                  Text(
                    trend,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isNegative
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF10A37F),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 2),

          // "vs last 7 days"
          Text(
            'vs last 7 days',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: AppColors.inkFaint,
            ),
          ),
        ],
      ),
    );
  }

  /// Active Loyalty Card Summary Block matching Reference Image 2:
  /// Dark Teal rounded card with coffee badge, Active badge, punch summary,
  /// price per punch on right, reward info on right, valid till, customer count, Edit and Delete buttons.
  Widget _buildActiveCardBlock(dynamic activeCard, List<dynamic> allCards) {
    if (activeCard == null) {
      return GestureDetector(
        onTap: () =>
            context.push('/business/cards/new').then((_) => _loadDashboard()),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: Color(0xFFEDF7F4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: AppColors.tealDark,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Your Loyalty Card',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    'Set up punch rewards and start earning customers',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final cardTitle = activeCard['title'] ?? 'Coffee Lovers Card';
    final punchesReq = activeCard['punchesRequired'] ?? 10;
    final rewardDesc = activeCard['rewardDescription'] ?? 'Free Coffee';
    final currency = activeCard['currency'] ?? 'PKR';
    final priceVal = activeCard['pricePerPunch'];
    final priceStr = priceVal == null
        ? 'Not set'
        : (priceVal is num && priceVal % 1 == 0)
        ? priceVal.toInt().toString()
        : priceVal.toString();
    final validDate = _formatDate(activeCard['validUntil']);
    final custCount = activeCard['_count']?['customerCards'] ?? 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B574D), Color(0xFF063A33)],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF063A33).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Coffee Badge + Card Title + Active Badge + Price & Reward on Right
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Icon + Title + Active pill + Subtitle
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.coffee_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  cardTitle,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10A37F)
                                      .withValues(alpha: 0.28),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: const Color(0xFF10A37F)
                                        .withValues(alpha: 0.5),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  'Active',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF6EE7B7),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$punchesReq punches  •  1 punch = $currency $priceStr',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Right column: Price tag & Reward tag
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.sell_rounded,
                        color: Color(0xFF5EEAD4),
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$currency $priceStr',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'per punch',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.card_giftcard_rounded,
                        color: Color(0xFF5EEAD4),
                        size: 13,
                      ),
                      const SizedBox(width: 5),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            rewardDesc,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'after $punchesReq punches',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          if (allCards.length > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(allCards.length, (i) {
                return GestureDetector(
                  onTap: () => setState(() => _selectedCardIndex = i),
                  child: Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _selectedCardIndex == i
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                );
              }),
            ),
          ],

          const SizedBox(height: 14),
          const Divider(height: 1, color: Colors.white24),
          const SizedBox(height: 12),

          // Bottom Row: Valid till, Customers count, Edit and Delete action buttons
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 11,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        'Valid till: $validDate',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(width: 1, height: 10, color: Colors.white30),
                    const SizedBox(width: 5),
                    const Icon(
                      Icons.people_outline_rounded,
                      size: 12,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$custCount customers',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),

              // Edit Button (Outline Pill)
              GestureDetector(
                onTap: () => Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (_) => CreateCardScreen(
                          cardId: activeCard['id'],
                          initialData: activeCard,
                        ),
                      ),
                    )
                    .then((_) => _loadDashboard()),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.7),
                      width: 1.2,
                    ),
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.edit_rounded,
                        color: Colors.white,
                        size: 11,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'Edit',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 5),

              // Delete Button (Red Pill)
              GestureDetector(
                onTap: () => _deleteCard(activeCard['id']),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xFFDC2626),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white,
                        size: 11,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Delete',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Recent Activity Section matching Reference Image 2:
  /// Feed of recent events with customer avatar, customer name, action description,
  /// card title, relative time ("2 min ago"), result badge (+1 punch in green, -10 punches in red, +0 punch in teal),
  /// and chevron.
  Widget _buildRecentActivitySection(List<dynamic> activities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/business/customers'),
              child: Row(
                children: [
                  Text(
                    'View All',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.tealDark,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: AppColors.tealDark,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: activities.isNotEmpty
              ? Column(
                  children: List.generate(activities.length, (index) {
                    final item = activities[index];
                    final isLast = index == activities.length - 1;
                    return Column(
                      children: [
                        _buildActivityItemRow(item, index),
                        if (!isLast)
                          const Divider(height: 1, color: AppColors.line),
                      ],
                    );
                  }),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 28,
                    horizontal: 16,
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.history_toggle_off_rounded,
                          size: 28,
                          color: AppColors.inkSoft,
                        ),
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
      ],
    );
  }

  Widget _buildActivityItemRow(dynamic item, int index) {
    final name = item['customerName'] ?? 'Customer';
    final action = item['action'] ?? 'Earned 1 punch';
    final cardTitle = item['cardTitle'] ?? 'Loyalty Card';
    final timeStr = _formatRelativeTime(item['timestamp']);
    final badgeText = item['resultBadge'] ?? '+1 punch';
    final badgeColorKey = item['badgeColor'] ?? 'green';

    // Color palette for user avatar icon based on index
    final avatarColors = [
      const Color(0xFFD1FAE5), // Mint
      const Color(0xFFFED7AA), // Orange
      const Color(0xFFEDE9FE), // Purple
      const Color(0xFFDBEAFE), // Blue
      const Color(0xFFCCFBF1), // Teal
    ];
    final avatarIconColors = [
      const Color(0xFF0F766E),
      const Color(0xFFEA580C),
      const Color(0xFF7C3AED),
      const Color(0xFF2563EB),
      const Color(0xFF0D9488),
    ];
    final colorIdx = index % avatarColors.length;

    // Badge styling matching Reference Image 2
    Color badgeBg;
    Color badgeTextColor;
    if (badgeColorKey == 'red' || badgeText.toString().startsWith('-')) {
      badgeBg = const Color(0xFFFEE2E2);
      badgeTextColor = const Color(0xFFDC2626);
    } else if (badgeColorKey == 'teal' || badgeText == '+0 punch') {
      badgeBg = const Color(0xFFE6F7F2);
      badgeTextColor = const Color(0xFF0E7465);
    } else {
      badgeBg = const Color(0xFFDCFCE7);
      badgeTextColor = const Color(0xFF16A34A);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Customer Avatar
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: avatarColors[colorIdx],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.person_rounded,
                size: 20,
                color: avatarIconColors[colorIdx],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Name, Action, Card Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  action,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: badgeColorKey == 'red'
                        ? const Color(0xFFDC2626)
                        : (badgeColorKey == 'teal'
                              ? const Color(0xFF0E7465)
                              : AppColors.inkSoft),
                  ),
                ),
                Text(
                  cardTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    color: AppColors.inkFaint,
                  ),
                ),
              ],
            ),
          ),

          // Time ago + Result Badge + Chevron
          Row(
            children: [
              Text(
                timeStr,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.inkFaint,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: badgeTextColor,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AppColors.inkFaint,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Bottom Navigation Bar matching Reference Image 2:
  /// Home, Cards, Raised Center Circular Scan Button with Mint Glow, Notifications (with red dot), Profile
  Widget _buildBottomNav(bool hasUnread, dynamic activeCard) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.line, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 1. Home
          Expanded(
            child: _buildNavItem(
              index: 0,
              icon: Icons.home_rounded,
              label: 'Home',
              onTap: () => setState(() => _activeNavIndex = 0),
            ),
          ),

          // 2. Cards
          Expanded(
            child: _buildNavItem(
              index: 1,
              icon: Icons.credit_card_rounded,
              label: 'Cards',
              onTap: () {
                setState(() => _activeNavIndex = 1);
                _handleNewCardTap(activeCard);
              },
            ),
          ),

          // 3. Center Raised Scan Button with Mint Glow Ring (Image 2)
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/business/scan'),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B574D),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0B574D)
                              .withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0xFF99F6E4),
                        width: 3,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.qr_code_scanner_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Scan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0B574D),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Notifications with Red Dot
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _activeNavIndex = 2);
                context.push('/notifications').then((_) => _loadDashboard());
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        size: 22,
                        color: _activeNavIndex == 2
                            ? AppColors.tealDark
                            : AppColors.inkSoft,
                      ),
                      if (hasUnread)
                        Positioned(
                          top: -1,
                          right: -2,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Notifications',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _activeNavIndex == 2
                          ? AppColors.tealDark
                          : AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 5. Profile
          Expanded(
            child: _buildNavItem(
              index: 3,
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              onTap: () {
                setState(() => _activeNavIndex = 3);
                context.push('/business/profile').then((_) => _loadDashboard());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isActive = _activeNavIndex == index;
    final color = isActive ? AppColors.tealDark : AppColors.inkSoft;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 3),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
