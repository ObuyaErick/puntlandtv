import 'package:material_ui/material_ui.dart';

import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/responsive/adaptive_layout.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../core/admin_api/dto/media_dto.dart';
import '../../../../core/widgets/status_badge.dart';
import '../media_format.dart';
import 'media_thumbnail.dart';

/// One asset in the library grid.
///
/// The sub-line under the filename is the tile's real content. It says the one
/// thing an editor can act on, in priority order: a failed ingest first, then
/// missing alt text, then — when there is nothing wrong — the size and kind.
/// A tile that reports "2.1 MB · Image" while the file cannot legally publish
/// is a tile that taught someone the wrong thing.
class MediaGridTile extends StatelessWidget {
  const MediaGridTile({
    super.key,
    required this.asset,
    required this.onTap,
    this.selected = false,
    this.onToggleSelected,
  });

  final MediaAssetDto asset;
  final VoidCallback onTap;
  final bool selected;
  final VoidCallback? onToggleSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Semantics(
      button: true,
      selected: selected,
      label: l10n.mediaGridLabel(
        asset.filename,
        MediaFormat.kind(l10n, asset.kind),
      ),
      child: ExcludeSemantics(
        child: PointerAffordance(
          onTap: onTap,
          selected: selected,
          borderRadius: Radii.cardBorder,
          child: Container(
            decoration: BoxDecoration(
              color: context.scheme.surface,
              borderRadius: Radii.cardBorder,
              border: Border.all(
                color: selected
                    ? context.scheme.primary
                    : context.colors.outline,
                width: selected ? 2 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Expanded rather than a fixed ratio: the caption underneath
                // is prose, and prose changes height with the language and the
                // reader's text scale. The picture takes what is left, which
                // is the only arrangement that cannot overflow.
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(child: MediaThumbnail(asset: asset)),
                      if (onToggleSelected != null)
                        Positioned(
                          top: 4,
                          left: 4,
                          child: _SelectionBox(
                            selected: selected,
                            onChanged: onToggleSelected!,
                          ),
                        ),
                      if (asset.duration != null)
                        Positioned(
                          right: 6,
                          bottom: 6,
                          child: _DurationPill(duration: asset.duration!),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(Spacing.cardInternal),
                  child: _Caption(asset: asset),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption({required this.asset});

  final MediaAssetDto asset;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final missing = asset.missingAltLocales;

    // Priority order, worst first. Only one line fits, so it has to be the
    // one that changes what someone does next.
    final (detail, isProblem) = asset.hasFailed
        ? (l10n.transcodeFailedTitle, true)
        : !asset.isReady
        ? (
            l10n.transcodingProgress(
              (asset.transcodeProgress * 100).round().toString(),
            ),
            true,
          )
        : missing.isNotEmpty
        ? (l10n.altMissingInCount(missing.length), true)
        : (
            '${MediaFormat.kind(l10n, asset.kind)} · '
                '${MediaFormat.bytes(l10n, asset.byteSize, context.languageCode)}',
            false,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                asset.filename,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.body.copyWith(
                  fontWeight: FontWeight.w500,
                  color: context.scheme.primary,
                ),
              ),
            ),
            // A used asset is one somebody else's page depends on. The count
            // is here rather than in the panel alone because it is what makes
            // a delete refusal predictable instead of surprising.
            if (asset.isInUse) ...[
              const SizedBox(width: Spacing.chip),
              _UsagePill(count: asset.usageCount),
            ],
          ],
        ),
        const SizedBox(height: 3),
        // The badge is dropped on a narrow tile rather than shrunk. It is not
        // load-bearing here: the line beside it already says "Ingest failed"
        // or "Transcoding · 62%" in words, so the status survives the cut —
        // which is the test the project's no-colour-only rule actually sets.
        LayoutBuilder(
          builder: (context, constraints) {
            final showBadge =
                constraints.maxWidth >= _badgeNeeds && !asset.isReady;

            return Row(
              children: [
                if (showBadge) ...[
                  StatusBadge(
                    kind: asset.hasFailed
                        ? BadgeKind.failed
                        : BadgeKind.transcoding,
                  ),
                  const SizedBox(width: Spacing.chip),
                ],
                Expanded(
                  child: Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.meta.copyWith(
                      color: isProblem
                          ? context.scheme.error
                          : context.scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Below this the badge and the sentence beside it cannot share a line.
  static const _badgeNeeds = 210.0;
}

class _SelectionBox extends StatelessWidget {
  const _SelectionBox({required this.selected, required this.onChanged});

  final bool selected;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.scheme.surface.withValues(alpha: 0.92),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      child: SizedBox(
        width: 32,
        height: 32,
        child: Checkbox(
          value: selected,
          onChanged: (_) => onChanged(),
          visualDensity: VisualDensity.compact,
        ),
      ),
    );
  }
}

class _DurationPill extends StatelessWidget {
  const _DurationPill({required this.duration});

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        MediaFormat.duration(duration),
        style: context.text.overline.copyWith(
          fontSize: 10,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _UsagePill extends StatelessWidget {
  const _UsagePill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: context.colors.skeleton,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.link_rounded,
            size: 11,
            color: context.scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 3),
          Text(
            '$count',
            style: context.text.overline.copyWith(
              fontSize: 10,
              color: context.scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
