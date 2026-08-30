import 'package:material_ui/material_ui.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.dart';

/// A flat placeholder block.
///
/// Deliberately not animated. The canvas specifies "NO SHIMMER — CHEAP TO
/// PAINT": a shimmer gradient on every card in a scrolling feed is a real
/// per-frame cost on the low-end devices that make up most of this audience,
/// and it buys nothing a static block does not.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height = 13, this.radius = 4});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.skeleton,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// The article-card skeleton from the canvas: thumbnail, overline, three text
/// lines with the last one short.
class ArticleCardSkeleton extends StatelessWidget {
  const ArticleCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.scheme.surface,
        borderRadius: Radii.cardBorder,
        border: Border.all(color: context.colors.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonBox(width: 104, height: 78, radius: Radii.thumbnail),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(width: 86, height: 9),
                  const SizedBox(height: 9),
                  const SkeletonBox(height: 13),
                  const SizedBox(height: 9),
                  const SkeletonBox(height: 13),
                  const SizedBox(height: 9),
                  FractionallySizedBox(
                    widthFactor: 0.58,
                    child: const SkeletonBox(height: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Feed first-load state: a lead-story block followed by card skeletons.
class FeedSkeleton extends StatelessWidget {
  const FeedSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Spacing.gutter,
        Spacing.listRhythm,
        Spacing.gutter,
        Spacing.emptyState,
      ),
      children: [
        const SkeletonBox(height: 206, radius: Radii.card),
        const SizedBox(height: Spacing.listRhythm),
        const SkeletonBox(width: 110, height: 10),
        const SizedBox(height: Spacing.cardInternal),
        const SkeletonBox(height: 20),
        const SizedBox(height: 10),
        FractionallySizedBox(
          widthFactor: 0.7,
          child: const SkeletonBox(height: 20),
        ),
        const SizedBox(height: Spacing.sectionBreak),
        for (var i = 0; i < 4; i++) ...[
          const ArticleCardSkeleton(),
          const SizedBox(height: Spacing.cardInternal),
        ],
      ],
    );
  }
}
