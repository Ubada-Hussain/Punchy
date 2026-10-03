import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/widgets/punchy_async_button.dart';
import 'explore/explore_clipper.dart';
import 'explore/explore_style.dart';

class ExploreBusinessDetailScreen extends StatefulWidget {
  const ExploreBusinessDetailScreen({
    super.key,
    required this.business,
    required this.card,
    required this.color,
    required this.onJoin,
    this.customerCard,
  });
  final Map<String, dynamic> business;
  final Map<String, dynamic>? card, customerCard;
  final Color color;
  final Future<bool> Function() onJoin;
  @override
  State<ExploreBusinessDetailScreen> createState() =>
      _ExploreBusinessDetailScreenState();
}

class _ExploreBusinessDetailScreenState
    extends State<ExploreBusinessDetailScreen> {
  late bool _added = widget.customerCard != null;
  @override
  Widget build(BuildContext context) {
    final business = widget.business;
    final required = explorePunches(widget.card);
    final punches = (widget.customerCard?['punchCount'] as num?)?.toInt() ?? 0;
    final price = explorePrice(business, widget.card);
    final address = exploreAddress(business);
    final description = (business['description'] ?? '').toString().trim();
    final reward = (widget.card?['rewardDescription'] ?? '').toString().trim();
    final phone = business['user'] is Map
        ? (business['user']['phone'] ?? '').toString()
        : '';
    return Theme(
      data: ThemeData.light().copyWith(
        colorScheme: const ColorScheme.light(
          primary: exploreTeal,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: exploreInk,
        ),
      ),
      child: Scaffold(
        backgroundColor: widget.color,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 44,
                                    height: 44,
                                    child: IconButton(
                                      tooltip: 'Back to Explore',
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      style: IconButton.styleFrom(
                                        backgroundColor: exploreInk,
                                        foregroundColor: Colors.white,
                                      ),
                                      icon: const Icon(
                                        Icons.chevron_left_rounded,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 7,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: .65,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: Text(
                                          exploreCategory(business)
                                              .toUpperCase(),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: exploreBody(12)
                                              .copyWith(letterSpacing: .5),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(22, 18, 22, 0),
                              child: _DetailTitle(name: exploreName(business)),
                            ),
                            if (address.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  22,
                                  14,
                                  22,
                                  0,
                                ),
                                child: InkWell(
                                  onTap: () => launchUrl(
                                    Uri.parse(
                                      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeQueryComponent(address)}',
                                    ),
                                    mode: LaunchMode.externalApplication,
                                  ),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minHeight: 44,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.location_on_outlined,
                                          size: 16,
                                          color: exploreInk,
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            address,
                                            style: exploreBody(
                                              14,
                                              weight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            if (description.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  22,
                                  6,
                                  22,
                                  0,
                                ),
                                child: Text(
                                  description,
                                  style: exploreBody(
                                    14,
                                    color: exploreInk.withValues(alpha: .8),
                                    weight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'YOUR CARD · $punches / ${explorePunchText(widget.card)}',
                                    style: exploreBody(11)
                                        .copyWith(letterSpacing: .5),
                                  ),
                                  if (required > 0) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: List.generate(
                                        math.min(required, 15),
                                        (index) {
                                          final segments = math.min(
                                            required,
                                            15,
                                          );
                                          final filled =
                                              punches / required >=
                                              (index + 1) / segments;
                                          return Expanded(
                                            child: Container(
                                              height: 14,
                                              margin: EdgeInsets.only(
                                                right: index < segments - 1
                                                    ? 4
                                                    : 0,
                                              ),
                                              decoration: BoxDecoration(
                                                color: exploreInk.withValues(
                                                  alpha: filled ? 1 : .18,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _stat(
                                    explorePunchText(widget.card),
                                    'TOTAL PUNCHES',
                                  ),
                                  _stat(price, 'PER PUNCH'),
                                  _stat(
                                    widget.card == null ? '—' : '1',
                                    'REWARD',
                                  ),
                                ],
                              ),
                            ),
                            if (reward.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  22,
                                  16,
                                  22,
                                  0,
                                ),
                                child: Text(
                                  reward,
                                  style: exploreBody(
                                    14,
                                    weight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            if (widget.card?['validUntil'] != null)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  22,
                                  8,
                                  22,
                                  0,
                                ),
                                child: Text(
                                  'Valid until ${_date(widget.card!['validUntil'])}',
                                  style: exploreBody(12, color: exploreMuted),
                                ),
                              ),
                            if (phone.isNotEmpty ||
                                (business['website'] ?? '')
                                    .toString()
                                    .isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Wrap(
                                  spacing: 8,
                                  children: [
                                    if (phone.isNotEmpty)
                                      TextButton(
                                        onPressed: () =>
                                            launchUrl(Uri.parse('tel:$phone')),
                                        child: Text(
                                          phone,
                                          style: exploreBody(12),
                                        ),
                                      ),
                                    if ((business['website'] ?? '')
                                        .toString()
                                        .isNotEmpty)
                                      TextButton(
                                        onPressed: () => launchUrl(
                                          Uri.parse(
                                            business['website'].toString(),
                                          ),
                                          mode: LaunchMode.externalApplication,
                                        ),
                                        child: Text(
                                          'Website',
                                          style: exploreBody(12),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            const Spacer(),
                            const SizedBox(height: 24),
                            ClipPath(
                              clipper: const ExploreNotchClipper(
                                depth: 26,
                                start: .40,
                                end: .48,
                              ),
                              child: Container(
                                color: Colors.white,
                                padding: const EdgeInsets.fromLTRB(
                                  22,
                                  44,
                                  22,
                                  24,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              explorePunchText(widget.card),
                                              style: exploreDisplay(
                                                120,
                                                height: .8,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'PUNCHES TO REWARD',
                                            style: exploreBody(
                                              11,
                                              color: exploreMuted,
                                            ).copyWith(letterSpacing: .5),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            price,
                                            textAlign: TextAlign.right,
                                            style: exploreDisplay(30),
                                          ),
                                          Text(
                                            'PER PUNCH',
                                            style: exploreBody(
                                              11,
                                              color: exploreMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: _added
                    ? 'Card added to wallet'
                    : 'Join ${exploreName(business)} loyalty card',
                child: Container(
                  color: _added ? exploreTeal : exploreCoral,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.paddingOf(context).bottom,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 68,
                    child: PunchyAsyncButton(
                      label: _added
                          ? 'CARD ADDED'
                          : widget.card == null
                          ? 'NO ACTIVE CARD'
                          : 'JOIN CARD',
                      processingLabel: 'JOINING…',
                      enabled: !_added && widget.card?['id'] != null,
                      onPressed: widget.onJoin,
                      onSuccess: () => setState(() => _added = true),
                      backgroundColor: _added ? exploreTeal : exploreCoral,
                      errorMessage:
                          'Could not add this card. Please try again.',
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        shape: const RoundedRectangleBorder(),
                        disabledBackgroundColor: _added
                            ? exploreTeal
                            : exploreCoral,
                        disabledForegroundColor: Colors.white,
                        textStyle: exploreDisplay(
                          24,
                          color: Colors.white,
                        ).copyWith(letterSpacing: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String value, String label) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: exploreDisplay(28),
        ),
        Text(
          label,
          style: exploreBody(
            10,
            color: exploreInk.withValues(alpha: .7),
          ).copyWith(letterSpacing: .5),
        ),
      ],
    ),
  );
  String _date(dynamic value) {
    final date = DateTime.tryParse(value.toString());
    if (date == null) return value.toString();
    return '${date.day} ${const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][date.month - 1]} ${date.year}';
  }
}

class _DetailTitle extends StatelessWidget {
  const _DetailTitle({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) {
    final words = name.toUpperCase().split(RegExp(r'\s+'));
    TextSpan span(double size) => TextSpan(
      style: exploreDisplay(size, height: .86),
      children: [
        TextSpan(text: words.first),
        if (words.length > 1)
          TextSpan(
            text: ' ${words.skip(1).join(' ')}',
            style: const TextStyle(color: Colors.white),
          ),
      ],
    );
    var size = 72.0;
    while (size > 30) {
      final painter = TextPainter(
        text: span(size),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: MediaQuery.sizeOf(context).width - 44);
      if (painter.height <= 180 && painter.computeLineMetrics().length <= 3) {
        break;
      }
      size -= 2;
    }
    return Text.rich(span(size), maxLines: 3, overflow: TextOverflow.ellipsis);
  }
}
