import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/providers/auth_provider.dart';
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
      final query =
          '?search=${_searchController.text.trim()}&category=$categoryParam';

      final res = await _api.get('/customer/explore$query');
      if (res is List && mounted) {
        setState(() {
          _businesses = res;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _businesses = [];
        _isLoading = false;
      });
    }
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

  Future<void> _addCardToWallet(String cardId, String businessName) async {
    try {
      final res = await _api.post('/customer/cards/join', {'cardId': cardId});
      final msg =
          res?['message'] ?? 'Added card from $businessName to your wallet! 🎉';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.ink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.teal,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    msg,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.ink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            content: Text(
              'Could not add card to wallet. Please check connection.',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _openBusinessLocation(String address) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeQueryComponent(address)}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName =
        context.watch<AuthProvider>().user?['name']?.toString() ?? '';
    final nameParts = userName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    final initials = nameParts.length > 1
        ? '${nameParts.first[0]}${nameParts.last[0]}'.toUpperCase()
        : (userName.isNotEmpty
              ? userName
                    .substring(0, userName.length >= 2 ? 2 : 1)
                    .toUpperCase()
              : 'P');
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
                      child: Center(
                        child: Text(
                          initials,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
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
                  style: GoogleFonts.plusJakartaSans(
                    color: AppColors.ink,
                    fontSize: 13.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search cafes, salons, fitness...',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: AppColors.inkFaint,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: AppColors.inkSoft,
                    ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 6,
                ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.teal : AppColors.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isSelected ? AppColors.teal : AppColors.line,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          cat,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : AppColors.inkSoft,
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
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.teal),
                    )
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
                      separatorBuilder: (_, index) =>
                          const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final b = _businesses[index];
                        final cards = (b['loyaltyCards'] as List?) ?? [];
                        final card = cards.isNotEmpty ? cards.first : null;

                        return _buildReferenceBusinessCard(b, card, index);
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

  String _themeForExploreCard(dynamic card, int index) {
    final style = card is Map ? card['visualStyle'] : null;
    final visualStyle = style is Map ? style : const <String, dynamic>{};
    final rawTheme = visualStyle['theme']?.toString().toLowerCase().trim();
    const aliases = <String, String>{
      'teal': 'teal',
      'mint': 'teal',
      'green': 'teal',
      'coral': 'coral',
      'orange': 'coral',
      'red': 'coral',
      'purple': 'purple',
      'violet': 'purple',
      'gold': 'gold',
      'yellow': 'gold',
      'amber': 'gold',
    };
    if (rawTheme != null && aliases.containsKey(rawTheme)) {
      return aliases[rawTheme]!;
    }

    // Older cards stored a hex primaryColor instead of a theme name.
    final primary = visualStyle['primaryColor']
        ?.toString()
        .toLowerCase()
        .replaceAll('#', '');
    if (primary != null && primary.length == 6) {
      final value = int.tryParse(primary, radix: 16);
      if (value != null) {
        final color = Color(0xFF000000 | value);
        final colorValue = color.toARGB32();
        final red = (colorValue >> 16) & 0xFF;
        final green = (colorValue >> 8) & 0xFF;
        final blue = colorValue & 0xFF;
        final candidates = <String, Color>{
          'teal': AppColors.teal,
          'coral': AppColors.coral,
          'purple': AppColors.purple,
          'gold': AppColors.gold,
        };
        String nearest = 'teal';
        var distance = double.infinity;
        for (final entry in candidates.entries) {
          final entryValue = entry.value.toARGB32();
          final entryRed = (entryValue >> 16) & 0xFF;
          final entryGreen = (entryValue >> 8) & 0xFF;
          final entryBlue = entryValue & 0xFF;
          final dr = red - entryRed;
          final dg = green - entryGreen;
          final db = blue - entryBlue;
          final current = (dr * dr + dg * dg + db * db).toDouble();
          if (current < distance) {
            distance = current;
            nearest = entry.key;
          }
        }
        return nearest;
      }
    }

    // Keep legacy records visually distinct until their card is edited/saved.
    return const ['teal', 'coral', 'purple', 'gold'][index % 4];
  }

  Widget _buildReferenceBusinessCard(
    dynamic business,
    dynamic card,
    int index,
  ) {
    final address =
        (business['locations'] is List &&
            (business['locations'] as List).isNotEmpty)
        ? ((business['locations'] as List).first['address']?.toString() ?? '')
        : (business['address']?.toString() ?? '');
    final logo = business['logo']?.toString() ?? '';
    final theme = _themeForExploreCard(card, index);
    final bg = theme == 'coral'
        ? const Color(0xFFFFF1E9)
        : theme == 'purple'
        ? const Color(0xFFF8F0FB)
        : theme == 'gold'
        ? const Color(0xFFFFF7E5)
        : const Color(0xFFEFF9F5);
    final accent = theme == 'coral'
        ? const Color(0xFFE85D45)
        : theme == 'purple'
        ? const Color(0xFF7B3FA0)
        : theme == 'gold'
        ? const Color(0xFFD98A16)
        : AppColors.tealDark;
    final punches = card?['punchesRequired'] ?? 0;
    final currency = card?['currency']?.toString() ?? 'PKR';
    final price = card?['pricePerPunch'];
    final priceText = price == null
        ? 'Not set'
        : '$currency ${price is num && price % 1 == 0 ? price.toInt() : price}';
    final description = business['description']?.toString().trim() ?? '';
    return GestureDetector(
      onTap: card == null
          ? null
          : () => _addCardToWallet(
              card['id'],
              business['name']?.toString() ?? 'Business',
            ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accent.withValues(alpha: 0.18)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: logo.startsWith('http')
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Image.network(
                            logo,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.storefront,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.storefront_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                ),
                const SizedBox(height: 9),
                SizedBox(
                  width: 82,
                  child: ElevatedButton(
                    onPressed: card == null
                        ? null
                        : () => _addCardToWallet(
                            card['id'],
                            business['name']?.toString() ?? 'Business',
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Join Card',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          business['name']?.toString() ?? 'Business',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: accent,
                        size: 24,
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    business['category']?.toString() ?? 'Business',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _openBusinessLocation(address),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: accent,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              address,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                color: AppColors.inkSoft,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 7),
                  Text(
                    description.isEmpty
                        ? 'Join this business loyalty card and collect punches.'
                        : description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$punches',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: accent,
                                ),
                              ),
                              Text(
                                'Total punches',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  color: AppColors.inkSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                priceText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: accent,
                                ),
                              ),
                              Text(
                                'per punch',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  color: AppColors.inkSoft,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessCard(dynamic business, dynamic card) {
    final theme = card?['visualStyle']?['theme']?.toString() ?? 'teal';
    LinearGradient cardGrad = AppColors.gradTeal;
    if (theme == 'coral') cardGrad = AppColors.gradCoral;
    if (theme == 'purple') cardGrad = AppColors.gradPurple;
    if (theme == 'gold') cardGrad = AppColors.gradGold;
    final locations = business['locations'] is List
        ? business['locations'] as List
        : const [];
    final address = locations.isNotEmpty && locations.first is Map
        ? (locations.first['address']?.toString() ?? '')
        : (business['address']?.toString() ?? '');
    final businessLogo = business['logo']?.toString();

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
                    child:
                        businessLogo != null && businessLogo.startsWith('http')
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              businessLogo,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _businessCategoryIcon(business),
                            ),
                          )
                        : _businessCategoryIcon(business),
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
                      if (address.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: AppColors.inkSoft,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                address,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  color: AppColors.inkSoft,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        GestureDetector(
                          onTap: () => _openBusinessLocation(address),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.map_outlined,
                                size: 14,
                                color: AppColors.tealDark,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Open in Google Maps',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  color: AppColors.tealDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
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
                      const Icon(
                        Icons.card_giftcard_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
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
                  if (card['validUntil'] != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '⏳ Valid till: ${_formatDate(card['validUntil'])}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ],
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
                        _addCardToWallet(
                          card['id'] ?? 'demo',
                          business['name'] ?? '',
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_circle_outline_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Add to Wallet',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
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
          ),
        ],
      ),
    );
  }

  Widget _businessCategoryIcon(dynamic business) {
    final name = business['name']?.toString() ?? '';
    return const Icon(
      Icons.storefront_rounded,
      color: AppColors.tealDark,
      size: 23,
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
              _buildNavItem(
                Icons.wallet_rounded,
                'Wallet',
                false,
                onTap: () => context.go('/'),
              ),
              _buildNavItem(
                Icons.explore_rounded,
                'Explore',
                true,
                onTap: () {},
              ),
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
                    child: Icon(
                      Icons.qr_code_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
              _buildNavItem(
                Icons.notifications_none_rounded,
                'Alerts',
                false,
                onTap: () => context.push('/notifications'),
              ),
              _buildNavItem(
                Icons.person_outline_rounded,
                'Profile',
                false,
                onTap: () => context.push('/profile'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool active, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 22,
            color: active ? AppColors.tealDark : AppColors.inkFaint,
          ),
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
