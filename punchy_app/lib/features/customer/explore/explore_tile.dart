import 'dart:async';

import 'package:flutter/material.dart';

import 'explore_clipper.dart';
import 'explore_style.dart';

// Leave room above the next tile's 24px overlap for both caption lines.
const exploreTileHeight = 192.0;
const exploreTileStep = exploreTileHeight - 24;

class ExploreTile extends StatelessWidget {
  const ExploreTile({
    super.key,
    required this.business,
    required this.color,
    required this.added,
    required this.onTap,
  });
  final Map<String, dynamic> business;
  final Color color;
  final bool added;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label:
        '${exploreName(business)}, ${exploreCategory(business)}, ${explorePunchText(exploreCard(business))} punches, opens details${added ? ', card added' : ''}',
    child: ClipPath(
      clipper: const ExploreNotchClipper(),
      child: Material(
        color: color,
        child: InkWell(
          onTap: onTap,
          child: ExploreTileContent(business: business, added: added),
        ),
      ),
    ),
  );
}

class ExploreTileContent extends StatelessWidget {
  const ExploreTileContent({
    super.key,
    required this.business,
    required this.added,
  });
  final Map<String, dynamic> business;
  final bool added;
  @override
  Widget build(BuildContext context) {
    final card = exploreCard(business);
    final logo = (business['logo'] ?? '').toString();
    final price = explorePrice(business, card);
    final initials = Center(
      child: Text(
        exploreInitials(business),
        style: exploreDisplay(14, color: Colors.white, weight: FontWeight.w800),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 44, 22, 32),
      child: Column(
        children: [
          Row(
            children: [
              ClipOval(
                child: Container(
                  width: 34,
                  height: 34,
                  color: exploreInk,
                  child: logo.isEmpty
                      ? initials
                      : Image.network(
                          logo,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => initials,
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  exploreCategory(business).toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: exploreBody(12).copyWith(letterSpacing: .4),
                ),
              ),
              if (added)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: exploreInk,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'ADDED',
                    style: exploreBody(11, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      explorePunchText(card),
                      style: exploreDisplay(52, height: .85),
                    ),
                    const SizedBox(height: 3),
                    _caption('PUNCHES'),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        exploreName(business).toUpperCase(),
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: exploreDisplay(26, height: .95),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        price == 'Not set'
                            ? 'PER PUNCH NOT SET'
                            : '$price / PUNCH',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: exploreBody(
                          11,
                          color: exploreInk.withValues(alpha: .7),
                        ).copyWith(letterSpacing: .5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _caption(String text) => Text(
    text,
    style: exploreBody(
      11,
      color: exploreInk.withValues(alpha: .7),
    ).copyWith(letterSpacing: .5),
  );
}

class ExploreTileEntry extends StatefulWidget {
  const ExploreTileEntry({super.key, required this.index, required this.child});
  final int index;
  final Widget child;
  @override
  State<ExploreTileEntry> createState() => _ExploreTileEntryState();
}

class _ExploreTileEntryState extends State<ExploreTileEntry>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );
  Timer? _timer;
  bool _started = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else {
      _timer = Timer(
        Duration(milliseconds: widget.index * 70),
        _controller.forward,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    child: widget.child,
    builder: (_, child) {
      final t = exploreCurve.transform(_controller.value);
      return Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 40 * (1 - t)),
          child: child,
        ),
      );
    },
  );
}

class ExploreSkeletonTiles extends StatelessWidget {
  const ExploreSkeletonTiles({super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: exploreTileStep * 2 + exploreTileHeight,
    child: Stack(
      children: [
        for (var i = 0; i < 3; i++)
          Positioned(
            top: i * exploreTileStep,
            left: 0,
            right: 0,
            height: exploreTileHeight,
            child: ClipPath(
              clipper: const ExploreNotchClipper(),
              child: Container(
                color: exploreTrack,
                padding: const EdgeInsets.fromLTRB(22, 44, 22, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _block(34, 34, radius: 30),
                        const SizedBox(width: 10),
                        _block(110, 12),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [_block(42, 48), _block(150, 38)],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
  Widget _block(double width, double height, {double radius = 6}) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: exploreLine,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

class ExploreEmptyState extends StatelessWidget {
  const ExploreEmptyState({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
    child: Text(
      'No cards here yet. Try another category.',
      textAlign: TextAlign.center,
      style: exploreBody(14, color: exploreMuted, weight: FontWeight.w600),
    ),
  );
}
