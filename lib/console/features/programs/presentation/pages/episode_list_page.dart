import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/l10n/app_date_format.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/responsive/window_size.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../core/widgets/feedback_views.dart';
import '../../../../app/console_navigation.dart';
import '../../../../core/admin_api/dto/admin_program_dto.dart';
import '../../../../core/widgets/console_page.dart';
import '../../../../core/widgets/console_table.dart';
import '../../../../core/widgets/console_toast.dart';
import '../../../../core/widgets/status_badge.dart';
import '../controllers/program_controller.dart';
import '../widgets/episode_blocker_list.dart';
import 'programs_page.dart';

/// One programme's episodes.
///
/// The rule this screen carries: **an episode cannot be published on a source
/// that is not playable yet.** Publishing an episode whose transcode sits at
/// 62% ships a shelf entry that opens to an error, and the audience finds out
/// before the newsroom does. The source is the media library's asset, carried
/// whole rather than by id, so there is one asset and one truth about whether
/// it is ready — retrying a failed transcode in the library changes what this
/// screen says about the episode.
class EpisodeListPage extends ConsumerWidget {
  const EpisodeListPage({super.key, required this.programId});

  final String programId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = context.languageCode;
    final program = ref
        .watch(programListProvider)
        .value
        ?.where((p) => p.id == programId)
        .firstOrNull;
    final episodes = ref.watch(episodeListProvider(programId));

    final blocked =
        episodes.value?.where((e) => !e.canPublish && !e.isPublished).length ??
        0;

    return ConsolePage(
      title: l10n.episodesOf(program?.titleFor(locale) ?? programId),
      subtitle: episodes.value == null
          ? null
          : l10n.itemCount(episodes.value!.length),
      actions: [
        OutlinedButton.icon(
          onPressed: context.openPrograms,
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 40),
            side: BorderSide(color: context.colors.outline),
            foregroundColor: context.scheme.onSurface,
          ),
          label: Text(l10n.backToPrograms),
        ),
      ],
      // Counted at the top rather than left to be discovered row by row: an
      // editor opening a programme wants to know whether anything is stuck
      // before they start reading.
      notice: blocked == 0
          ? null
          : ConsoleNotice(
              message: l10n.blockedEpisodeCount(blocked),
              icon: Icons.block_rounded,
              warning: true,
            ),
      child: episodes.when(
        loading: () => const _EpisodeSkeleton(),
        error: (error, _) => ErrorView(
          failure: error is Failure
              ? error
              : const Failure(kind: FailureKind.unknown, code: 'UNKNOWN'),
          onRetry: () => ref.invalidate(episodeListProvider(programId)),
        ),
        data: (rows) => rows.isEmpty
            ? EmptyView(
                title: l10n.emptyEpisodes,
                body: l10n.emptyEpisodesBody,
                icon: Icons.movie_outlined,
              )
            : _EpisodeTable(rows: rows, locale: locale),
      ),
    );
  }
}

class _EpisodeTable extends ConsumerWidget {
  const _EpisodeTable({required this.rows, required this.locale});

  final List<AdminEpisodeDto> rows;
  final String locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    final columns = <ConsoleColumn>[
      ConsoleColumn(label: l10n.colEpisode, flex: 4),
      ConsoleColumn(label: l10n.colSource, flex: 3),
      ConsoleColumn(label: l10n.colAired, width: 132),
      ConsoleColumn(label: l10n.colStatus, width: 104),
      const ConsoleColumn(label: '', width: 116),
    ];

    return WindowSizeScope(
      builder: (context, size) {
        final asTable = size.isAtLeastExpanded;

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.sectionBreak,
            Spacing.gutter,
            Spacing.sectionBreak,
            Spacing.sectionBreak,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.scheme.surface,
              borderRadius: Radii.cardBorder,
              border: Border.all(color: context.colors.outline),
            ),
            child: ClipRRect(
              borderRadius: Radii.cardBorder,
              child: Column(
                children: [
                  if (asTable) ConsoleTableHeader(columns: columns),
                  Expanded(
                    child: ListView.builder(
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final episode = rows[index];

                        if (!asTable) {
                          return _EpisodeCard(episode: episode, locale: locale);
                        }

                        return ConsoleTableRow(
                          columns: columns,
                          cells: [
                            _EpisodeCell(episode: episode, locale: locale),
                            _SourceCell(episode: episode),
                            Text(
                              _airedLabel(context, episode),
                              style: context.text.meta.copyWith(
                                color: context.scheme.onSurfaceVariant,
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _StatusCell(episode: episode),
                            ),
                            _PublishButton(episode: episode),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

String _airedLabel(BuildContext context, AdminEpisodeDto episode) {
  final code = context.languageCode;
  final when = episode.airedAt ?? episode.scheduledFor;
  return when == null ? '—' : AppDateFormat.byline(when, code);
}

class _EpisodeCell extends StatelessWidget {
  const _EpisodeCell({required this.episode, required this.locale});

  final AdminEpisodeDto episode;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Text(
              l10n.episodeNumber(episode.number),
              style: context.text.overline.copyWith(
                fontSize: 10,
                color: context.scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: Spacing.chip),
            Flexible(
              child: Text(
                episode.titleFor(locale),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.body.copyWith(
                  fontWeight: FontWeight.w500,
                  color: context.scheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        // The blockers, or the running time when there are none. The line says
        // the most actionable thing available, never both.
        if (episode.blockers.isEmpty)
          Text(
            episodeDurationLabel(episode.duration),
            style: context.text.meta.copyWith(
              color: context.scheme.onSurfaceVariant,
            ),
          )
        else
          EpisodeBlockerList(episode: episode, dense: true),
      ],
    );
  }
}

/// The attached media asset, named, with its ingest state.
class _SourceCell extends StatelessWidget {
  const _SourceCell({required this.episode});

  final AdminEpisodeDto episode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final source = episode.source;

    if (source == null) {
      return Text(
        l10n.blockerNoSource,
        style: context.text.meta.copyWith(color: context.scheme.error),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          source.filename,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.meta.copyWith(color: context.scheme.onSurface),
        ),
        if (!source.isReady) ...[
          const SizedBox(height: 3),
          StatusBadge(
            kind: source.hasFailed ? BadgeKind.failed : BadgeKind.transcoding,
          ),
        ],
      ],
    );
  }
}

class _StatusCell extends StatelessWidget {
  const _StatusCell({required this.episode});

  final AdminEpisodeDto episode;

  @override
  Widget build(BuildContext context) => StatusBadge(
    kind: switch (episode.status) {
      EpisodeStatus.draft => BadgeKind.draft,
      EpisodeStatus.scheduled => BadgeKind.scheduled,
      EpisodeStatus.published => BadgeKind.published,
    },
  );
}

/// Publish, or a disabled button that says why not.
///
/// Disabled rather than absent: "why can I not publish this" is a question the
/// row has to answer, and a missing button answers nothing. The reasons are
/// already spelled out under the title, so the tooltip points at them rather
/// than repeating one of them and implying it is the only one.
class _PublishButton extends ConsumerWidget {
  const _PublishButton({required this.episode});

  final AdminEpisodeDto episode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    Future<void> apply(EpisodeStatus status) async {
      await ref
          .read(programActionsProvider.notifier)
          .setEpisodeStatus(episode: episode, status: status);
      if (!context.mounted) return;
      showConsoleToast(
        context,
        message: status == EpisodeStatus.published
            ? l10n.episodePublished
            : l10n.episodeUnpublished,
        kind: ToastKind.success,
      );
    }

    if (episode.isPublished) {
      return TextButton(
        onPressed: () => apply(EpisodeStatus.draft),
        child: Text(l10n.unpublishEpisode),
      );
    }

    return Tooltip(
      message: episode.canPublish ? '' : l10n.episodePublishBlocked,
      child: OutlinedButton(
        onPressed: episode.canPublish
            ? () => apply(EpisodeStatus.published)
            : null,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 36),
          side: BorderSide(color: context.colors.outline),
          foregroundColor: context.scheme.onSurface,
        ),
        child: Text(l10n.publishEpisode),
      ),
    );
  }
}

class _EpisodeCard extends ConsumerWidget {
  const _EpisodeCard({required this.episode, required this.locale});

  final AdminEpisodeDto episode;
  final String locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(Spacing.listRhythm),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.colors.outlineSubtle)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _EpisodeCell(episode: episode, locale: locale),
          const SizedBox(height: Spacing.cardInternal),
          _SourceCell(episode: episode),
          const SizedBox(height: Spacing.cardInternal),
          Row(
            children: [
              _StatusCell(episode: episode),
              const Spacer(),
              _PublishButton(episode: episode),
            ],
          ),
        ],
      ),
    );
  }
}

class _EpisodeSkeleton extends StatelessWidget {
  const _EpisodeSkeleton();

  @override
  Widget build(BuildContext context) {
    final columns = [
      ConsoleColumn(label: context.l10n.colEpisode, flex: 4),
      const ConsoleColumn(label: '', width: 132),
      const ConsoleColumn(label: '', width: 104),
    ];

    return ListView(
      children: [
        for (var i = 0; i < 6; i++) ConsoleTableRowSkeleton(columns: columns),
      ],
    );
  }
}
