import 'package:flutter/widgets.dart';

import 'media_card.dart';
import '../theme/surface_tokens.dart';

/// Placeholder that mirrors the poster + title + subtitle layout of a real
/// media card. Rendered in a sparse grid while items for that slot are in
/// flight. Not focusable — dpad navigation skips over these.
class SkeletonMediaCard extends StatelessWidget {
  const SkeletonMediaCard({super.key});

  @override
  Widget build(BuildContext context) {
    final surfaces = SurfaceTokens.of(context);
    final textRadius = BorderRadius.all(Radius.circular(surfaces.skeletonTextRadius));
    return Padding(
      padding: const .all(8),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.all(Radius.circular(surfaces.skeletonRadius)),
              child: const SkeletonLoader(child: SizedBox.expand()),
            ),
          ),
          const SizedBox(height: 4),
          SkeletonLoader(
            borderRadius: textRadius,
            child: const SizedBox(height: 13, width: double.infinity),
          ),
          const SizedBox(height: 3),
          FractionallySizedBox(
            alignment: .centerLeft,
            widthFactor: 0.6,
            child: SkeletonLoader(borderRadius: textRadius, child: const SizedBox(height: 11)),
          ),
        ],
      ),
    );
  }
}
