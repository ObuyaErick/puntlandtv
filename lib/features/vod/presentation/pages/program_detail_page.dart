import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/app_date_format.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/feedback_views.dart';
import '../../../../core/widgets/remote_image.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../player/domain/entities/playback_source.dart';
import '../../../player/presentation/controllers/playback_controller.dart';
import '../../domain/entities/program.dart';
import '../controllers/vod_controllers.dart';

class ProgramDetailPage extends ConsumerWidget {
  const ProgramDetailPage({super.key, required this.programId});

  final String programId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final program = ref.watch(programProvider(programId));
    final episodes = ref.watch(episodesProvider(programId));

    return Scaffold(
      appBar: AppBar(title: Text(program.value?.title ?? '')),
      body: episodes.when(
        loading: () => const _EpisodesSkeleton(),
        error: (error, _) => ErrorView(
          failure: error is Failure
              ? error
              : const Failure(kind: FailureKind.unknown, code: 'UNKNOWN'),
          onRetry: () => ref.invalidate(episodesProvider(programId)),
        ),
        data: (page) => ListView(
          padding: const EdgeInsets.only(bottom: Spacing.emptyState),
          children: [
            if (program.value != null) _Header(program: program.value!),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.gutter,
                Spacing.sectionBreak,
                Spacing.gutter,
                Spacing.cardInternal,
              ),
              child: Row(
                children: [
                  Text(
                    l10n.episodes,
                    style: context.text.overline.copyWith(
                      color: context.scheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    l10n.sortNewest,
                    style: context.text.label.copyWith(
                      color: context.colors.linkText,
                    ),
                  ),
                ],
              ),
            ),
            for (final episode in page.items)
              _EpisodeRow(episode: episode, programTitle: program.value?.title),
          ],
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header({required this.program});

  final Program program;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final episodes = ref.watch(episodesProvider(program.id)).value;

    return Padding(
      padding: const EdgeInsets.all(Spacing.gutter),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RemoteImage(
            url: program.artworkUrl,
            width: 110,
            height: 110,
            borderRadius: Radii.cardBorder,
          ),
          const SizedBox(width: Spacing.listRhythm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  [
                    program.cadence,
                    program.genre,
                    l10n.episodeCount(program.episodeCount),
                  ].whereType<String>().join(' · ').toUpperCase(),
                  style: context.text.overline.copyWith(
                    color: context.colors.accent,
                  ),
                ),
                const SizedBox(height: Spacing.chip),
                Text(
                  program.title,
                  style: context.text.title.copyWith(
                    color: context.scheme.primary,
                  ),
                ),
                const SizedBox(height: Spacing.listRhythm),
                FilledButton.icon(
                  onPressed: episodes == null || episodes.items.isEmpty
                      ? null
                      : () => _play(ref, episodes.items.first, program.title),
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: Text(l10n.playLatest),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _play(WidgetRef ref, dynamic episode, String? programTitle) {
  ref
      .read(playbackControllerProvider.notifier)
      .play(
        PlaybackSource(
          id: episode.id as String,
          url: episode.playbackUrl as String,
          kind: PlaybackKind.vod,
          title: episode.title as String,
          subtitle: programTitle,
          artworkUrl: episode.thumbnailUrl as String?,
        ),
      );
}

class _EpisodeRow extends ConsumerWidget {
  const _EpisodeRow({required this.episode, this.programTitle});

  final Episode episode;
  final String? programTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return InkWell(
      onTap: () => _play(ref, episode, programTitle),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.gutter,
          vertical: Spacing.cardInternal,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                RemoteImage(
                  url: episode.thumbnailUrl,
                  width: 116,
                  height: 70,
                  borderRadius: Radii.thumbBorder,
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: BrandPalette.navy.withValues(alpha: 0.72),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(width: Spacing.listRhythm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${AppDateFormat.dayMonth(episode.airedAt, context.languageCode)}'
                    ' · ${episode.title}',
                    style: context.text.body.copyWith(
                      color: context.scheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.durationMinutes(episode.duration.inMinutes),
                    style: context.text.meta.copyWith(
                      color: context.scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EpisodesSkeleton extends StatelessWidget {
  const _EpisodesSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(Spacing.gutter),
      children: [
        Row(
          children: [
            const SkeletonBox(width: 110, height: 110, radius: Radii.card),
            const SizedBox(width: Spacing.listRhythm),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 120, height: 10),
                  SizedBox(height: Spacing.chip),
                  SkeletonBox(height: 20),
                  SizedBox(height: Spacing.listRhythm),
                  SkeletonBox(width: 130, height: kMinTapTarget, radius: 8),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.sectionBreak),
        for (var i = 0; i < 4; i++) ...[
          Row(
            children: [
              const SkeletonBox(
                width: 116,
                height: 70,
                radius: Radii.thumbnail,
              ),
              const SizedBox(width: Spacing.listRhythm),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 15),
                    SizedBox(height: 8),
                    SkeletonBox(width: 70, height: 11),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.gutter),
        ],
      ],
    );
  }
}
