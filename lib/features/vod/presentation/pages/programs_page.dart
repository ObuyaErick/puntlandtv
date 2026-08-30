import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/feedback_views.dart';
import '../../../../core/widgets/remote_image.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../domain/entities/program.dart';
import '../controllers/vod_controllers.dart';

/// The catch-up grid. Browse by programme; the MVP has no "popular" sort
/// because the view analytics that would rank it do not exist yet.
class ProgramsPage extends ConsumerWidget {
  const ProgramsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final programs = ref.watch(programsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.programsTitle),
            Text(
              l10n.programsSubtitle,
              style: context.text.meta.copyWith(
                color: context.scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        toolbarHeight: 72,
      ),
      body: programs.when(
        loading: () => const _ProgramsSkeleton(),
        error: (error, _) => ErrorView(
          failure: error is Failure
              ? error
              : const Failure(kind: FailureKind.unknown, code: 'UNKNOWN'),
          onRetry: () => ref.invalidate(programsProvider),
        ),
        data: (items) => GridView.builder(
          padding: const EdgeInsets.all(Spacing.gutter),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: Spacing.listRhythm,
            crossAxisSpacing: Spacing.cardInternal,
            mainAxisExtent: 260,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => _ProgramTile(program: items[index]),
        ),
      ),
    );
  }
}

class _ProgramTile extends StatelessWidget {
  const _ProgramTile({required this.program});

  final Program program;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return InkWell(
      onTap: () => context.push(Routes.program(program.id)),
      borderRadius: Radii.cardBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: RemoteImage(
                    url: program.artworkUrl,
                    borderRadius: Radii.cardBorder,
                  ),
                ),
                Positioned(
                  left: Spacing.chip,
                  top: Spacing.chip,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: BrandPalette.navy.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      l10n.episodeCount(program.episodeCount),
                      style: context.text.overline.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: Text(
              program.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.cardTitle.copyWith(
                fontSize: 15,
                color: context.scheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            [program.cadence, program.genre].whereType<String>().join(' · '),
            style: context.text.meta.copyWith(
              color: context.scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgramsSkeleton extends StatelessWidget {
  const _ProgramsSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(Spacing.gutter),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: Spacing.listRhythm,
        crossAxisSpacing: Spacing.cardInternal,
        mainAxisExtent: 260,
      ),
      itemCount: 4,
      itemBuilder: (_, _) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: SkeletonBox(radius: Radii.card, height: 200)),
          SizedBox(height: Spacing.chip),
          SkeletonBox(height: 14),
          SizedBox(height: 6),
          SkeletonBox(width: 90, height: 11),
        ],
      ),
    );
  }
}
