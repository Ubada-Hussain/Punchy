import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
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

  Future<void> _mockPunch(String method) async {
    final cardId = _card['cardId'] ?? _card['card']?['id'];
    final customerCardId = _card['id'];
    if (customerCardId == null) return;

    try {
      await _api.post('/punch', {
        'identifier': method == 'QR' ? 'qr-demo-001' : 'nfc-demo-001',
        'type': method,
        'cardId': cardId,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.ink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text(
              'Punch Added via $method! +1 🌟',
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        );
        _fetchFullDetails();
      }
    } catch (e) {
      // Offline fallback state update
      setState(() {
        final cur = (_card['punchCount'] as int? ?? 6);
        final max = (_card['card']?['punchesRequired'] as int? ?? 10);
        final next = (cur + 1).clamp(0, max);
        _card['punchCount'] = next;
        _card['isCompleted'] = next >= max;
        _transactions.insert(0, {
          'method': method,
          'timestamp': 'Just now',
        });
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.ink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text(
              'Punch added successfully! +1 🌟',
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cardInfo = _card['card'] ?? {};
    final biz = cardInfo['business'] ?? {};
    final bizName = biz['name'] ?? cardInfo['title'] ?? 'Brew & Co.';
    final bizCat = biz['category'] ?? 'Café · Gulberg';
    final bizLogo = biz['logo'] ?? cardInfo['visualStyle']?['icon'] ?? '☕';
    final punchCount = _card['punchCount'] as int? ?? 6;
    final punchesRequired = cardInfo['punchesRequired'] as int? ?? 10;
    final reward = cardInfo['rewardDescription'] ?? '1 Free Coffee';
    final isCompleted = _card['isCompleted'] == true || punchCount >= punchesRequired;

    final themeStr = (cardInfo['visualStyle']?['theme'] ?? 'teal').toString().toLowerCase();
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
                        child: Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: AppColors.ink),
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
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.line),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Center(
                      child: Icon(Icons.settings_outlined, size: 16, color: AppColors.ink),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
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
                            Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(bizLogo, style: const TextStyle(fontSize: 15)),
                                  ),
                                ),
                                const SizedBox(width: 9),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                        color: Colors.white.withValues(alpha: 0.85),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                isCompleted ? 'REWARD READY' : 'ACTIVE',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
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
                                color: isFilled ? Colors.white : Colors.transparent,
                                border: isFilled
                                    ? null
                                    : Border.all(
                                        color: Colors.white.withValues(alpha: 0.55),
                                        width: 1.6,
                                      ),
                              ),
                              child: Center(
                                child: isFilled
                                    ? Icon(Icons.check_rounded, color: gradient.colors.last, size: 16)
                                    : Text(
                                        '${i + 1}',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white.withValues(alpha: 0.8),
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
                              ? '🎉 Reward unlocked! Ready to redeem.'
                              : '${punchesRequired - punchCount} more punches until your free reward!',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Action Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => context.push('/scanner'),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.teal,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.teal.withValues(alpha: 0.45),
                                  blurRadius: 14,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Scan QR',
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
                          onTap: () => _mockPunch('NFC'),
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
                                const Icon(Icons.nfc_rounded, color: AppColors.ink, size: 16),
                                const SizedBox(width: 8),
                                Text(
                                  'Tap NFC',
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
                    child: Column(
                      children: [
                        _buildActivityRow('Punch added', 'Today, 10:24 AM', '+1', Icons.check_rounded),
                        const Divider(height: 1, color: AppColors.line),
                        _buildActivityRow('Punch added', 'Aug 21, 5:10 PM', '+1', Icons.check_rounded),
                        const Divider(height: 1, color: AppColors.line),
                        _buildActivityRow('Card started', 'Aug 10, 9:02 AM', '🎉', Icons.card_giftcard_rounded),
                      ],
                    ),
                  ),
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
                  painter: DashedLinePainter(color: Colors.white.withValues(alpha: 0.55)),
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

  Widget _buildActivityRow(String title, String sub, String meta, IconData icon) {
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
      canvas.drawLine(Offset(currentX, 0), Offset(currentX + dashWidth, 0), paint);
      currentX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
