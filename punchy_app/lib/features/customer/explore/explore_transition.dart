import 'package:flutter/material.dart';

import 'explore_clipper.dart';
import 'explore_style.dart';
import 'explore_tile.dart';

class ExploreDetailRoute extends PageRouteBuilder<void> {
  ExploreDetailRoute({
    required Rect Function() sourceRect,
    required Color color,
    required Map<String, dynamic> business,
    required bool Function() added,
    required Widget detail,
    required bool reducedMotion,
  }) : super(
         opaque: false,
         transitionDuration: Duration(milliseconds: reducedMotion ? 200 : 550),
         reverseTransitionDuration: Duration(
           milliseconds: reducedMotion ? 200 : 550,
         ),
         pageBuilder: (_, _, _) => detail,
         transitionsBuilder: (context, animation, secondaryAnimation, child) =>
             AnimatedBuilder(
               animation: animation,
               child: child,
               builder: (context, child) {
                 final size = MediaQuery.sizeOf(context);
                 final t = reducedMotion
                     ? animation.value
                     : exploreCurve.transform(animation.value);
                 final rect = reducedMotion
                     ? Offset.zero & size
                     : Rect.lerp(sourceRect(), Offset.zero & size, t)!;
                 final fade = reducedMotion
                     ? t
                     : const Interval(
                         150 / 550,
                         450 / 550,
                       ).transform(animation.value);
                 if (reducedMotion) {
                   return FadeTransition(opacity: animation, child: child);
                 }
                 return Stack(
                   children: [
                     Positioned.fromRect(
                       rect: rect,
                       child: ClipPath(
                         clipper: ExploreNotchClipper(
                           depth: reducedMotion ? 0 : 24 * (1 - t),
                         ),
                         child: ColoredBox(
                           color: color,
                           child: Stack(
                             children: [
                               if (!reducedMotion && t < 1)
                                 Positioned.fill(
                                   child: Opacity(
                                     opacity: 1 - t,
                                     child: OverflowBox(
                                       alignment: Alignment.topLeft,
                                       minWidth: size.width,
                                       maxWidth: size.width,
                                       minHeight: exploreTileHeight,
                                       maxHeight: exploreTileHeight,
                                       child: ExploreTileContent(
                                         business: business,
                                         added: added(),
                                       ),
                                     ),
                                   ),
                                 ),
                               Positioned.fill(
                                 child: OverflowBox(
                                   alignment: Alignment.topLeft,
                                   minWidth: size.width,
                                   maxWidth: size.width,
                                   minHeight: size.height,
                                   maxHeight: size.height,
                                   child: Opacity(
                                     opacity: fade,
                                     child: SizedBox(
                                       width: size.width,
                                       height: size.height,
                                       child: child,
                                     ),
                                   ),
                                 ),
                               ),
                             ],
                           ),
                         ),
                       ),
                     ),
                   ],
                 );
               },
             ),
       );
}
