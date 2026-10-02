import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Lightweight reusable placeholder blocks for data-driven Punchy screens.
class PunchySkeleton extends StatefulWidget {
  const PunchySkeleton({super.key, this.rows = 3, this.card = true});

  final int rows;
  final bool card;

  @override
  State<PunchySkeleton> createState() => _PunchySkeletonState();
}

class _PunchySkeletonState extends State<PunchySkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Widget _block(double width, double height, {double radius = 8}) =>
      AnimatedBuilder(
        animation: _pulse,
        builder: (context, child) =>
            Opacity(opacity: 0.55 + _pulse.value * 0.35, child: child),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.line,
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => ListView.separated(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
    itemCount: widget.rows,
    separatorBuilder: (_, _) => const SizedBox(height: 14),
    itemBuilder: (context, index) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _block(46, 46, radius: 14),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _block(150, 14),
                    const SizedBox(height: 8),
                    _block(95, 10),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (widget.card) ...[
            _block(double.infinity, 76, radius: 14),
            const SizedBox(height: 12),
          ],
          _block(double.infinity, 38, radius: 12),
        ],
      ),
    ),
  );
}
