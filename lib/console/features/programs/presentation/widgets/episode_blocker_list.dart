import 'package:material_ui/material_ui.dart';

import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../core/admin_api/dto/admin_program_dto.dart';
import '../../../../core/localised.dart';

/// Everything standing between an episode and the app.
///
/// A list, not a single "cannot publish" message. The three blockers need
/// different people: a missing video needs an upload, a failed transcode needs
/// a retry in the media library, an unfinished one needs nothing but time. A
/// screen that collapses them into one refusal sends whoever reads it to the
/// wrong place.
class EpisodeBlockerList extends StatelessWidget {
  const EpisodeBlockerList({
    super.key,
    required this.episode,
    this.dense = false,
  });

  final AdminEpisodeDto episode;

  /// One line, for a table cell. The full list is for the panel.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final blockers = episode.blockers;
    if (blockers.isEmpty) return const SizedBox.shrink();

    if (dense) {
      return Text(
        _label(context, blockers.first),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.text.meta.copyWith(color: context.scheme.error),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final blocker in blockers)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.chip),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  switch (blocker) {
                    EpisodeBlocker.noSource => Icons.videocam_off_outlined,
                    EpisodeBlocker.sourceFailed => Icons.error_outline_rounded,
                    EpisodeBlocker.sourceProcessing => Icons.sync_rounded,
                    EpisodeBlocker.untitled => Icons.translate_rounded,
                  },
                  size: 16,
                  // Only a failure is red. A transcode in progress is not
                  // something anyone did wrong, and colouring it as an error
                  // teaches people to ignore the colour.
                  color: blocker == EpisodeBlocker.sourceProcessing
                      ? context.scheme.onSurfaceVariant
                      : context.scheme.error,
                ),
                const SizedBox(width: Spacing.chip),
                Expanded(
                  child: Text(
                    _label(context, blocker),
                    style: context.text.meta.copyWith(
                      color: blocker == EpisodeBlocker.sourceProcessing
                          ? context.scheme.onSurface
                          : context.scheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  String _label(BuildContext context, EpisodeBlocker blocker) {
    final l10n = context.l10n;
    return switch (blocker) {
      EpisodeBlocker.noSource => l10n.blockerNoSource,
      EpisodeBlocker.sourceFailed => l10n.blockerSourceFailed,
      EpisodeBlocker.sourceProcessing => l10n.blockerSourceProcessing,
      EpisodeBlocker.untitled => l10n.blockerUntitled(
        context.languageNameOf(episode.untitledLocales.first),
      ),
    };
  }
}
