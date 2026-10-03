import 'package:flutter/material.dart';

import 'explore_style.dart';

class ExploreFilters extends StatelessWidget {
  const ExploreFilters({
    super.key,
    required this.scope,
    required this.category,
    required this.categories,
    required this.onScope,
    required this.onCategory,
  });
  final String scope, category;
  final List<String> categories;
  final ValueChanged<String> onScope, onCategory;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Container(
        margin: const EdgeInsets.fromLTRB(22, 16, 22, 0),
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: exploreTrack,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            for (final entry in const {
              'city': 'In Your City',
              'country': 'In Your Country',
            }.entries)
              Expanded(
                child: Semantics(
                  selected: scope == entry.key,
                  button: true,
                  child: InkWell(
                    onTap: () => onScope(entry.key),
                    borderRadius: BorderRadius.circular(22),
                    child: Center(
                      child: Container(
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: scope == entry.key
                              ? exploreInk
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          entry.value,
                          style: exploreBody(
                            13,
                            color: scope == entry.key
                                ? Colors.white
                                : exploreMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      SizedBox(
        height: 46,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          itemCount: categories.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final selected = categories[i] == category;
            return Semantics(
              selected: selected,
              button: true,
              child: Center(
                child: SizedBox(
                  height: 44,
                  child: InkWell(
                    onTap: () => onCategory(categories[i]),
                    borderRadius: BorderRadius.circular(22),
                    child: Center(
                      child: Container(
                        height: 38,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        decoration: BoxDecoration(
                          color: selected ? exploreTeal : Colors.white,
                          borderRadius: BorderRadius.circular(19),
                          border: Border.all(
                            color: selected ? exploreTeal : exploreLine,
                          ),
                        ),
                        child: Text(
                          categories[i],
                          style: exploreBody(
                            13,
                            color: selected ? Colors.white : exploreInk,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ],
  );
}
