import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/api/api_client.dart';
import '../../core/formatting/currency.dart';
import '../../core/theme/app_colors.dart';

class CardDetailScreen extends StatefulWidget {
  final Map<String, dynamic> cardData;

  const CardDetailScreen({super.key, required this.cardData});

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  final ApiClient _api = ApiClient();
  late Map<String, dynamic> _card;
  List<dynamic> _transactions = [];

  @override
  void initState() {
    super.initState();
    _card = widget.cardData;
    _fetchFullDetails();
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

  Future<void> _fetchFullDetails() async {
    final cardId = _card['id'];
    if (cardId == null) return;
    try {
      final res = await _api.get('/customer/cards/$cardId');
      if (res != null && mounted) {
        setState(() {
          _card = res;
          _transactions = res['punchTransactions'] ?? [];
        });
      }
    } catch (_) {}
  }

  Future<void> _openBusinessLocation(String address) async {
    if (address.isEmpty) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeQueryComponent(address)}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _callBusiness(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    await launchUrl(uri);
  }

  Future<void> _confirmRemoveCard() async {
    final cardId = _card['id'];
    if (cardId == null) return;
    final cardInfo = _card['card'] ?? {};
    final biz = cardInfo['business'] ?? {};
    final title = biz['name'] ?? cardInfo['title'] ?? 'this loyalty card';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Remove Card?',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: AppColors.ink,
          ),
        ),
        content: Text(
          'Are you sure you want to remove "$title" from your wallet? Your punch progress on this card will be removed.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppColors.inkSoft,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: AppColors.inkSoft,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Confirm',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _api.delete('/customer/cards/$cardId');
        if (mounted) {
          context.pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to remove card: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardInfo = _card['card'] ?? {};
    final biz = cardInfo['business'] ?? {};
    final bizName = biz['name'] ?? cardInfo['title'] ?? 'Business';
    final bizCat = biz['category'] ?? '';
    final bizLocations = (biz['locations'] is List)
        ? biz['locations'] as List
        : const [];
    final bizAddress = bizLocations.isNotEmpty && bizLocations.first is Map
        ? (bizLocations.first['address'] ?? '').toString()
        : '';
    final bizPhone = (biz['user']?['phone'] ?? '').toString().trim();
    final bizLogo = (biz['logo'] != null && biz['logo'].toString().isNotEmpty)
        ? biz['logo'].toString()
        : (cardInfo['visualStyle']?['icon'] ?? '🎟️');
    final punchCount = _card['punchCount'] as int? ?? 0;
    final punchesRequired = cardInfo['punchesRequired'] as int? ?? 10;
    final reward = cardInfo['rewardDescription'] ?? 'Reward';
    final isCompleted =
        _card['isCompleted'] == true || punchCount >= punchesRequired;
    final expiry = DateTime.tryParse((cardInfo['validUntil'] ?? '').toString());
    final isExpired =
        _card['isExpired'] == true ||
        (expiry != null && expiry.isBefore(DateTime.now()));
    final isReactivated = !isExpired && cardInfo['reactivatedAt'] != null;

    final themeStr = (cardInfo['visualStyle']?['theme'] ?? 'teal')
        .toString()
        .toLowerCase();
    final gradient = themeStr == 'coral'
        ? AppColors.gradCoral
        : themeStr == 'purple'
        ? AppColors.gradPurple
        : themeStr == 'gold'
        ? AppColors.gradGold
        : AppColors.gradTeal;

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
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 14,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    bizName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  GestureDetector(
                    onTap: _confirmRemoveCard,
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.line),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.delete_outline_rounded,
                          size: 16,
                          color: AppColors.coral,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 6,
                ),
                children: [
                  // Signature Punch Card with Tear Line
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: gradient.colors.last.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Top
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.22,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: bizLogo.startsWith('http')
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              child: Image.network(
                                                bizLogo,
                                                width: 34,
                                                height: 34,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, _, _) =>
                                                    const Text(
                                                      '🏪',
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                              ),
                                            )
                                          : Text(
                                              bizLogo,
                                              style: const TextStyle(
                                                fontSize: 15,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 9),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          bizName,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          bizCat,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white.withValues(
                                              alpha: 0.85,
                                            ),
                                          ),
                                        ),
                                        if (bizAddress.isNotEmpty)
                                          GestureDetector(
                                            onTap: () => _openBusinessLocation(
                                              bizAddress,
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(
                                                  Icons.location_on_rounded,
                                                  size: 13,
                                                  color: Colors.white,
                                                ),
                                                const SizedBox(width: 3),
                                                Expanded(
                                                  child: Text(
                                                    bizAddress,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style:
                                                        GoogleFonts.plusJakartaSans(
                                                          fontSize: 11,
                                                          color: Colors.white
                                                              .withValues(
                                                                alpha: 0.95,
                                                              ),
                                                        ),
                                                  ),
                                                ),
                                                const Icon(
                                                  Icons.open_in_new_rounded,
                                                  size: 12,
                                                  color: Colors.white,
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isExpired
                                          ? AppColors.coral
                                          : Colors.white.withValues(
                                              alpha: 0.22,
                                            ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      isCompleted
                                          ? (isExpired
                                                ? 'REWARD READY • EXPIRED'
                                                : 'REWARD READY')
                                          : (isExpired
                                                ? 'EXPIRED • RESET'
                                                : (isReactivated
                                                      ? 'REACTIVATED'
                                                      : 'ACTIVE')),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                  if (cardInfo['validUntil'] != null) ...[
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.25,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '⏳ Valid: ${_formatDate(cardInfo['validUntil'])}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white.withValues(
                                            alpha: 0.9,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Reward
                        Text(
                          '🎁 Reward: $reward',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Tear Line Effect
                        _buildTearLine(),
                        const SizedBox(height: 12),

                        // Stamp Row
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(punchesRequired, (i) {
                            final isFilled = i < punchCount;
                            return Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isFilled
                                    ? Colors.white
                                    : Colors.transparent,
                                border: isFilled
                                    ? null
                                    : Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.55,
                                        ),
                                        width: 1.6,
                                      ),
                              ),
                              child: Center(
                                child: isFilled
                                    ? Icon(
                                        Icons.check_rounded,
                                        color: gradient.colors.last,
                                        size: 16,
                                      )
                                    : Text(
                                        '${i + 1}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white.withValues(
                                            alpha: 0.8,
                                          ),
                                        ),
                                      ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 12),

                        // Progress Note
                        Text(
                          isCompleted
                              ? (isExpired
                                    ? '🎉 This card expired, but your reward is still ready to redeem.'
                                    : '🎉 Reward unlocked! Ready to redeem.')
                              : (isExpired
                                    ? 'This card expired and incomplete progress was reset. It will restart at 0 when reactivated.'
                                    : (isReactivated
                                          ? 'This card has been reactivated. Collect punches from 0 for this new cycle.'
                                          : '${punchesRequired - punchCount} more punches until your free reward!')),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About this card',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          'Visit $bizName and get a punch for every qualifying purchase. $punchesRequired punches unlock the listed reward.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            height: 1.45,
                            color: AppColors.inkSoft,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _detailStat(
                                Icons.calendar_today_outlined,
                                'Valid till',
                                _formatDate(cardInfo['validUntil']),
                              ),
                            ),
                            Expanded(
                              child: _detailStat(
                                Icons.sell_outlined,
                                'Minimum order',
                                Currency.price(
                                  cardInfo['currency'],
                                  cardInfo['pricePerPunch'],
                                ),
                              ),
                            ),
                            Expanded(
                              child: _detailStat(
                                Icons.stars_outlined,
                                'Punches required',
                                '$punchesRequired',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  const SizedBox(height: 4),

                  // Recent Activity Title
                  Text(
                    'Recent activity',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Activity Card
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: _transactions.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 24,
                              horizontal: 16,
                            ),
                            child: Center(
                              child: Text(
                                'No punches recorded yet.\nScan QR or Tap NFC to collect your first stamp!',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  color: AppColors.inkSoft,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          )
                        : Column(
                            children: _transactions.asMap().entries.map((
                              entry,
                            ) {
                              final idx = entry.key;
                              final tx = entry.value;
                              final method = tx['method'] ?? 'QR';
                              final ts = tx['timestamp'] != null
                                  ? tx['timestamp']
                                        .toString()
                                        .substring(
                                          0,
                                          tx['timestamp'].toString().length >=
                                                  16
                                              ? 16
                                              : tx['timestamp']
                                                    .toString()
                                                    .length,
                                        )
                                        .replaceAll('T', ' ')
                                  : 'Just now';
                              return Column(
                                children: [
                                  _buildActivityRow(
                                    'Punch via $method',
                                    ts,
                                    '+1',
                                    method == 'NFC'
                                        ? Icons.nfc_rounded
                                        : Icons.check_rounded,
                                  ),
                                  if (idx < _transactions.length - 1)
                                    const Divider(
                                      height: 1,
                                      color: AppColors.line,
                                    ),
                                ],
                              );
                            }).toList(),
                          ),
                  ),
                  if (bizAddress.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.tealDark,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              bizAddress,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppColors.inkSoft,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          OutlinedButton(
                            onPressed: () => _openBusinessLocation(bizAddress),
                            child: const Text('Map'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (bizPhone.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.phone_outlined,
                            color: AppColors.tealDark,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              bizPhone,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppColors.inkSoft,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => _callBusiness(bizPhone),
                            icon: const Icon(Icons.call_rounded, size: 16),
                            label: const Text('Call'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Center(
                    child: TextButton.icon(
                      onPressed: _confirmRemoveCard,
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: AppColors.coral,
                      ),
                      label: Text(
                        'Remove Card from Wallet',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.coral,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTearLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            // Left Notch
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.bg,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: CustomPaint(
                  painter: DashedLinePainter(
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                  size: const Size(double.infinity, 2),
                ),
              ),
            ),
            // Right Notch
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.bg,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _detailStat(IconData icon, String label, String value) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    decoration: BoxDecoration(
      color: AppColors.surfaceAlt,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.tealDark),
        const SizedBox(height: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9.5,
            color: AppColors.inkSoft,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
      ],
    ),
  );

  Widget _buildActivityRow(
    String title,
    String sub,
    String meta,
    IconData icon,
  ) {
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
          Text(
            meta,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: meta == '+1' ? AppColors.tealDark : AppColors.coral,
            ),
          ),
        ],
      ),
    );
  }
}

class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    var max = size.width;
    var dashWidth = 6.0;
    var dashSpace = 5.0;
    double currentX = 0;
    while (currentX < max) {
      canvas.drawLine(
        Offset(currentX, 0),
        Offset(currentX + dashWidth, 0),
        paint,
      );
      currentX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
