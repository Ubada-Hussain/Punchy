import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/loyalty/card_palette.dart';
import '../../../core/loyalty/card_color.dart';
import '../../../core/loyalty/loyalty_card_surface.dart';
import '../../../core/loyalty/loyalty_punch_token.dart';

import 'package:google_fonts/google_fonts.dart';

const deckCream = Color(0xFFFAF6EF);
const deckTeal = Color(0xFF08786F);
const deckInk = Color(0xFF18211F);
const deckGold = Color(0xFFF4C95D);

/// A view over the existing customer-card API response, without new reward rules.
class LoyaltyDeckData {
  final Map<String, dynamic> raw;
  const LoyaltyDeckData(this.raw);

  Map get card => raw['card'] is Map ? raw['card'] as Map : const {};
  Map get business =>
      card['business'] is Map ? card['business'] as Map : const {};
  String get name =>
      (business['name'] ?? card['title'] ?? 'Loyalty card').toString();
  String get category => (business['category'] ?? '').toString();
  String get logo => (business['logo'] ?? '').toString();
  int get punches => (raw['punchCount'] as num?)?.toInt() ?? 0;
  int get required => (card['punchesRequired'] as num?)?.toInt() ?? 0;
  bool get completed => raw['isCompleted'] == true;
  bool get expired => raw['isExpired'] == true;
  DateTime? get expiry =>
      DateTime.tryParse((card['validUntil'] ?? '').toString());
  String get initials {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    return words
        .take(2)
        .map((word) => word.characters.first)
        .join()
        .toUpperCase();
  }

  Color get color => CardColor.fromCard(card);
  CardPalette get palette => CardPalette.fromColor(color);
}

class LoyaltyCardDeck extends StatefulWidget {
  final List<Map<String, dynamic>> cards;
  final double cardHeight;
  final ValueChanged<Map<String, dynamic>> onOpen;
  final ValueChanged<Map<String, dynamic>> onLongPress;

  const LoyaltyCardDeck({
    super.key,
    required this.cards,
    required this.cardHeight,
    required this.onOpen,
    required this.onLongPress,
  });

  @override
  State<LoyaltyCardDeck> createState() => _LoyaltyCardDeckState();
}

class _LoyaltyCardDeckState extends State<LoyaltyCardDeck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shuffle;
  int _index = 0;
  String? _focusedId;
  bool _settling = false;

  @override
  void initState() {
    super.initState();
    _shuffle = AnimationController(
      vsync: this,
      lowerBound: -1,
      upperBound: 1,
      value: 0,
      duration: const Duration(milliseconds: 360),
    );
    _focusedId = widget.cards.firstOrNull?['id']?.toString();
  }

  @override
  void didUpdateWidget(covariant LoyaltyCardDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    final retained = widget.cards.indexWhere(
      (card) => card['id']?.toString() == _focusedId,
    );
    _index = retained >= 0 ? retained : 0;
    _focusedId = widget.cards.isNotEmpty
        ? widget.cards[_index]['id']?.toString()
        : null;
  }

  @override
  void dispose() {
    _shuffle.dispose();
    super.dispose();
  }

  Future<void> _settle(double target) async {
    if (_settling || widget.cards.length < 2) return;
    _settling = true;
    await _shuffle.animateTo(target, curve: Curves.easeOutCubic);
    if (!mounted) return;
    if (target != 0 && widget.cards.isNotEmpty) {
      setState(() {
        _index =
            (_index + (target > 0 ? 1 : -1) + widget.cards.length) %
            widget.cards.length;
        _focusedId = widget.cards[_index]['id']?.toString();
      });
    }
    _shuffle.value = 0;
    _settling = false;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = math.min(constraints.maxWidth * .77, 410.0);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: widget.cards.length < 2
                  ? null
                  : (details) {
                      if (!_settling) {
                        _shuffle.value =
                            (_shuffle.value - details.delta.dx / width).clamp(
                              -1.0,
                              1.0,
                            );
                      }
                    },
              onHorizontalDragEnd: widget.cards.length < 2
                  ? null
                  : (details) {
                      final velocity = details.primaryVelocity ?? 0;
                      final target = velocity.abs() > 450
                          ? (velocity < 0 ? 1.0 : -1.0)
                          : _shuffle.value.abs() > .18
                          ? _shuffle.value.sign
                          : 0.0;
                      _settle(target);
                    },
              onHorizontalDragCancel: () => _settle(0),
              child: SizedBox(
                height: widget.cardHeight + 48,
                width: constraints.maxWidth,
                child: AnimatedBuilder(
                  animation: _shuffle,
                  builder: (context, _) {
                    final progress = _shuffle.value;
                    final direction = progress < 0 ? -1 : 1;
                    final t = progress.abs();
                    final roles = widget.cards.length > 2
                        ? [-direction, direction, 0]
                        : widget.cards.length == 2
                        ? [direction, 0]
                        : [0];
                    return Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: roles.map((role) {
                        final index =
                            (_index + role + widget.cards.length) %
                            widget.cards.length;
                        final incoming = role == direction;
                        final x = role == 0
                            ? -direction * width * .65 * t
                            : role * width * .43 * (incoming ? 1 - t : 1);
                        final angle = role == 0
                            ? -direction * .16 * t
                            : role * .16 * (incoming ? 1 - t : 1);
                        final scale = role == 0
                            ? 1 - .08 * t
                            : .92 + (incoming ? .08 * t : 0);
                        return Transform.translate(
                          offset: Offset(
                            x,
                            role == 0 ? 0 : 12 * (incoming ? 1 - t : 1),
                          ),
                          child: Transform.rotate(
                            angle: angle,
                            child: Transform.scale(
                              scale: scale,
                              child: IgnorePointer(
                                ignoring: role != 0 || _settling,
                                child: SizedBox(
                                  width: width,
                                  height: widget.cardHeight,
                                  child: LoyaltyDeckCard(
                                    data: LoyaltyDeckData(widget.cards[index]),
                                    onOpen: () =>
                                        widget.onOpen(widget.cards[index]),
                                    onLongPress: () =>
                                        widget.onLongPress(widget.cards[index]),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 9),
        DeckPager(count: widget.cards.length, active: _index),
        const SizedBox(height: 16),
        Text(
          widget.cards.length > 1
              ? 'Swipe the deck to shuffle · tap to open'
              : 'Tap to open · hold for card options',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: const Color(0xFF596663),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class LoyaltyDeckCard extends StatelessWidget {
  final LoyaltyDeckData data;
  final VoidCallback onOpen;
  final VoidCallback onLongPress;
  const LoyaltyDeckCard({
    super.key,
    required this.data,
    required this.onOpen,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final palette = data.palette;
    return Semantics(
      button: true,
      label:
          '${data.name}, ${data.punches} of ${data.required} punches. Tap to open, long press for options.',
      child: GestureDetector(
        onTap: onOpen,
        onLongPress: onLongPress,
        child: LoyaltyCardSurface(
          palette: palette,
          radius: 30,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(29),
            child: Stack(
              children: [
                Positioned(
                  top: -66,
                  right: -80,
                  child: IgnorePointer(
                    child: SizedBox(
                      width: 240,
                      height: 240,
                      child: CustomPaint(
                        painter: _RingPainter(palette.emptyToken),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxHeight < 420;
                      final logoSize = compact ? 48.0 : 64.0;
                      return SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: logoSize,
                                    height: logoSize,
                                    decoration: BoxDecoration(
                                      color: palette.tokenFill,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: .08,
                                          ),
                                          blurRadius: 14,
                                          offset: const Offset(0, 7),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: data.logo.isEmpty
                                          ? _initials()
                                          : Image.network(
                                              data.logo,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) =>
                                                  _initials(),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data.name,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: compact ? 20 : 23,
                                            fontWeight: FontWeight.w800,
                                            color: palette.text,
                                            height: 1.1,
                                          ),
                                        ),
                                        if (data.category.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            data.category,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 12,
                                              color: palette.secondaryText,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: compact ? 16 : 28),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: AlignmentDirectional.centerStart,
                                child: Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '${data.punches}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: compact ? 60 : 74,
                                        height: 1,
                                        letterSpacing: -3,
                                        fontWeight: FontWeight.w800,
                                        color: palette.text,
                                      ),
                                    ),
                                    Text(
                                      ' / ${data.required > 0 ? data.required : '—'}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        color: palette.secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'punches collected',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: compact ? 12 : 14,
                                  fontWeight: FontWeight.w700,
                                  color: palette.text,
                                ),
                              ),
                              SizedBox(height: compact ? 16 : 28),
                              if (data.required > 0)
                                PunchTokenRow(
                                  palette: palette,
                                  required: data.required,
                                  collected: data.punches,
                                ),
                              const SizedBox(height: 12),
                              Text(
                                data.completed
                                    ? 'Reward unlocked!'
                                    : data.expired
                                    ? 'Card expired'
                                    : data.required == 0
                                    ? 'Collect punches toward your reward'
                                    : '${math.max(0, data.required - data.punches)} more to unlock your reward',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: compact ? 11.5 : 13,
                                  height: 1.3,
                                  fontWeight: FontWeight.w800,
                                  color: palette.text,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  if (data.expiry != null)
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: palette.overlay,
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                        ),
                                        child: Text(
                                          '${data.expired ? 'Expired' : 'Expires'} ${_date(data.expiry!)}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10.5,
                                            color: palette.text,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    const Spacer(),
                                  const SizedBox(width: 12),
                                  SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: IconButton.filled(
                                      tooltip: 'Open ${data.name}',
                                      style: IconButton.styleFrom(
                                        backgroundColor: palette.tokenFill,
                                        foregroundColor: palette.tokenCheck,
                                      ),
                                      onPressed: onOpen,
                                      icon: const Icon(
                                        Icons.chevron_right_rounded,
                                        size: 27,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _initials() => Center(
    child: Text(
      data.initials,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: data.color,
      ),
    ),
  );
  String _date(DateTime date) =>
      '${date.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1]} ${date.year}';
}

class PunchTokenRow extends StatelessWidget {
  final CardPalette palette;
  final int required;
  final int collected;
  const PunchTokenRow({
    super.key,
    required this.palette,
    required this.required,
    required this.collected,
  });

  @override
  Widget build(BuildContext context) {
    // Wrap into rows for large programs; every real punch keeps its own position.
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: palette.overlay,
        borderRadius: BorderRadius.circular(34),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final gap = required > 14 ? 3.0 : 6.0;
          final columns = math.max(
            math.min(required, 7),
            math.sqrt(required * constraints.maxWidth / 54).ceil(),
          );
          final diameter =
              ((constraints.maxWidth - (columns - 1) * gap) / columns).clamp(
                3.0,
                36.0,
              );
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            alignment: WrapAlignment.center,
            children: List.generate(
              required,
              (index) => PunchToken(
                palette: palette,
                size: diameter,
                filled: index < collected,
                reward: index == required - 1,
              ),
            ),
          );
        },
      ),
    );
  }
}

class PunchToken extends StatelessWidget {
  const PunchToken({
    super.key,
    required this.palette,
    required this.size,
    required this.filled,
    required this.reward,
  });
  final CardPalette palette;
  final double size;
  final bool filled, reward;
  @override
  Widget build(BuildContext context) => LoyaltyPunchToken(
    palette: palette,
    size: size,
    filled: filled,
    reward: reward,
  );
}

class DeckPager extends StatelessWidget {
  final int count;
  final int active;
  const DeckPager({super.key, required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    final visible = math.min(count, 5);
    final start = (active - 2).clamp(0, math.max(0, count - visible));
    return Semantics(
      label: 'Card ${active + 1} of $count',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(visible, (index) {
          final selected = start + index == active;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: selected ? 22 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: selected ? deckTeal : const Color(0xFFCDE0DA),
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: .12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(size.center(Offset.zero), 115, paint);
    canvas.drawCircle(size.center(Offset.zero), 76, paint);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) => oldDelegate.color != color;
}
