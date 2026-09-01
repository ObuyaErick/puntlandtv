import 'package:material_ui/material_ui.dart';

import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../core/admin_api/dto/media_dto.dart';

/// The picture side of an asset, in whatever state it is actually in.
///
/// A thumbnail is the only part of this screen an operator looks at before
/// reading anything, so it carries the ingest state rather than leaving it to
/// a badge elsewhere in the card: a video mid-transcode shows its progress
/// over the poster, and a failed one shows that it failed. A tile that looks
/// finished but is not is the single most expensive thing this screen could
/// do.
class MediaThumbnail extends StatelessWidget {
  const MediaThumbnail({
    super.key,
    required this.asset,
    this.aspectRatio,
    this.iconSize = 26,
  });

  final MediaAssetDto asset;

  /// Null fills whatever box the parent gives it.
  ///
  /// The grid tile needs that: its caption is prose, so its height depends on
  /// the language and the reader's text scale, and a thumbnail that insists on
  /// 4:3 inside a fixed-height cell overflows the moment either changes.
  final double? aspectRatio;

  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final content = DecoratedBox(
      decoration: BoxDecoration(color: context.colors.imagePlaceholder),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _Surface(asset: asset, iconSize: iconSize),
          if (!asset.isReady) _IngestOverlay(asset: asset),
        ],
      ),
    );

    return aspectRatio == null
        ? content
        : AspectRatio(aspectRatio: aspectRatio!, child: content);
  }
}

/// The image itself, or the placeholder that stands in for one.
class _Surface extends StatelessWidget {
  const _Surface({required this.asset, required this.iconSize});

  final MediaAssetDto asset;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final source =
        asset.thumbnailUrl ??
        (asset.kind == MediaKind.image ? asset.url : null);

    if (source != null) {
      return Image.network(
        source,
        fit: BoxFit.cover,
        // The fixture CDN does not resolve, and a stack of red error boxes is
        // a worse answer than the placeholder the asset would have had anyway.
        errorBuilder: (context, _, _) =>
            _KindPlaceholder(kind: asset.kind, size: iconSize),
      );
    }

    return _KindPlaceholder(kind: asset.kind, size: iconSize);
  }
}

class _KindPlaceholder extends StatelessWidget {
  const _KindPlaceholder({required this.kind, required this.size});

  final MediaKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        switch (kind) {
          MediaKind.image => Icons.image_outlined,
          MediaKind.video => Icons.movie_outlined,
          MediaKind.audio => Icons.graphic_eq_rounded,
        },
        size: size,
        color: context.scheme.onSurfaceVariant,
      ),
    );
  }
}

/// Progress or failure, painted over the poster.
class _IngestOverlay extends StatelessWidget {
  const _IngestOverlay({required this.asset});

  final MediaAssetDto asset;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final failed = asset.hasFailed;

    return Container(
      color: Colors.black.withValues(alpha: 0.55),
      padding: const EdgeInsets.all(Spacing.cardInternal),
      // A thumbnail in a five-column grid is barely 80dp tall, and the full
      // overlay does not fit in it. It sheds parts in order of what a glance
      // needs least: the bar first — the percentage says the same thing in
      // less space — then the words, leaving the icon, which is the one part
      // that still means "this is not finished".
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showBar = !failed && constraints.maxHeight >= _barNeeds;
          final showLabel = constraints.maxHeight >= _labelNeeds;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                failed ? Icons.error_outline_rounded : Icons.sync_rounded,
                size: 20,
                color: failed ? context.scheme.error : Colors.white,
              ),
              if (showLabel) ...[
                const SizedBox(height: Spacing.chip),
                Text(
                  failed
                      ? l10n.transcodeFailedTitle
                      // The percentage is the whole point of the overlay:
                      // "working" with no number is indistinguishable from
                      // "stuck".
                      : l10n.transcodingProgress(
                          (asset.transcodeProgress * 100).round().toString(),
                        ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.overline.copyWith(
                    fontSize: 10,
                    color: failed ? context.scheme.error : Colors.white,
                  ),
                ),
              ],
              if (showBar) ...[
                const SizedBox(height: Spacing.chip),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: asset.transcodeProgress,
                    minHeight: 4,
                    backgroundColor: Colors.white24,
                    valueColor: AlwaysStoppedAnimation(context.colors.accent),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  /// Heights below which the overlay drops its bar, then its words.
  static const _barNeeds = 108.0;
  static const _labelNeeds = 64.0;
}
