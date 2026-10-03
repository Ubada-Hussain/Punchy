import 'package:flutter/material.dart';

import 'explore_style.dart';

class ExploreHeader extends StatelessWidget {
  const ExploreHeader({
    super.key,
    required this.onSearch,
    required this.onRefresh,
    required this.onProfile,
    required this.loading,
  });
  final VoidCallback onSearch, onRefresh, onProfile;
  final bool loading;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 22),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DISCOVER',
                  style: exploreDisplay(
                    64,
                    height: .86,
                  ).copyWith(letterSpacing: .5),
                ),
                Text(
                  'REWARDS',
                  style: exploreDisplay(
                    64,
                    color: exploreMuted.withValues(alpha: .55),
                    height: .86,
                  ).copyWith(letterSpacing: .5),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ExploreIconButton(
              icon: Icons.search_rounded,
              label: 'Search businesses',
              onTap: onSearch,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ExploreIconButton(
                  icon: Icons.refresh_rounded,
                  label: 'Refresh Explore',
                  onTap: loading ? null : onRefresh,
                ),
                const SizedBox(width: 6),
                ExploreIconButton(
                  icon: Icons.person_outline_rounded,
                  label: 'Open profile',
                  onTap: onProfile,
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

class ExploreIconButton extends StatelessWidget {
  const ExploreIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 44,
    height: 44,
    child: IconButton(
      tooltip: label,
      onPressed: onTap,
      icon: Icon(icon, size: 21),
      style: IconButton.styleFrom(
        foregroundColor: exploreInk,
        backgroundColor: Colors.white,
        side: const BorderSide(color: exploreLine),
        padding: EdgeInsets.zero,
      ),
    ),
  );
}
