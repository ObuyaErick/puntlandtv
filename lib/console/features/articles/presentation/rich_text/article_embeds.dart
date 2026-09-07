import 'dart:typed_data';

import 'package:flutter_quill/flutter_quill.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';

/// How the body editor renders the things in an article that are not prose.
///
/// **Every embed the document can hold needs a builder here.**
List<EmbedBuilder> articleEmbedBuilders() => const [
  _ImageEmbedBuilder(),
  _PendingImageEmbedBuilder(),
];

/// The spot a pasted image will occupy until its upload finishes.
///
/// A real embed rather than a grey box drawn over the document, because it has
/// to be *findable* when the upload returns: by then the caret has moved, more
/// text may have been typed, and the offset the paste started at means nothing.
///
/// It is deliberately outside [kArticleTags], so a body saved while an upload
/// is still running writes it out as nothing at all rather than as markup a
/// reader would have to render. The editor suppresses that save anyway — this
/// is the second lock on the same door.

/// The catch-all, passed as `unknownEmbedBuilder`.
///
/// Reachable by paste, by a document written by a future version of this
/// console, or by a body whose HTML carried something [kArticleTags] does not
/// model. It renders a placeholder the journalist can select and delete.
const EmbedBuilder unsupportedArticleEmbed = _UnsupportedEmbedBuilder();

/// A block image in the body.
class _ImageEmbedBuilder extends EmbedBuilder {
  const _ImageEmbedBuilder();

  @override
  String get key => BlockEmbed.imageType;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final url = embedContext.node.value.data;
    if (url is! String || url.isEmpty) {
      return const _EmbedNotice(icon: Icons.broken_image_outlined);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.cardInternal),
      child: ClipRRect(borderRadius: Radii.thumbBorder, child: _picture(url)),
    );
  }

  /// The picture itself, fetched or carried.
  ///
  /// **A body image can be a `data:` URL, and `Image.network` cannot open
  /// one.** On the VM — which is where `flutter test` runs — `NetworkImage`
  /// goes through `HttpClient`, and `data:` is not a scheme it resolves; the
  /// test harness's stub answers `400` to everything anyway. So an image the
  /// operator can plainly see in a browser would be a broken box in every test
  /// that looks at one, and on any desktop build.
  Widget _picture(String url) {
    Widget broken(BuildContext context) => _EmbedNotice(
      icon: Icons.broken_image_outlined,
      message: context.l10n.imageFailedToLoad,
    );

    if (url.startsWith('data:')) {
      final bytes = _inlineBytes(url);
      if (bytes == null) {
        return Builder(builder: broken);
      }
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, _, _) => broken(context),
      );
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const _EmbedNotice(icon: Icons.image_outlined, busy: true),
      errorBuilder: (context, _, _) => broken(context),
    );
  }
}

/// Bytes behind `data:` embeds, keyed by the URL they were parsed from.
///
/// `MemoryImage` keys its entry in Flutter's image cache by **list identity**,
/// so decoding the URI afresh on each build hands the framework a new key
/// every frame and re-decodes the picture — for every pasted image, on every
/// keystroke, while someone is typing. Bounded, because a cache that only
/// grows is a leak with a tidy name and a body can hold a lot of screenshots.
final _inlineImages = <String, Uint8List>{};

const _inlineImageLimit = 12;

Uint8List? _inlineBytes(String url) {
  final cached = _inlineImages[url];
  if (cached != null) return cached;

  try {
    final bytes = UriData.parse(url).contentAsBytes();
    if (_inlineImages.length >= _inlineImageLimit) {
      _inlineImages.remove(_inlineImages.keys.first);
    }
    return _inlineImages[url] = bytes;
  } catch (_) {
    // A malformed data URL is a broken image, not a crash mid-render.
    return null;
  }
}

/// Drops everything [_inlineBytes] is holding.
///
/// For tests, which must not let one case's bytes decide another's outcome.
@visibleForTesting
void clearInlineImageCache() => _inlineImages.clear();

class PendingImageEmbed extends BlockEmbed {
  const PendingImageEmbed(String token) : super(embedType, token);

  static const embedType = 'pendingImage';
}

class _PendingImageEmbedBuilder extends EmbedBuilder {
  const _PendingImageEmbedBuilder();

  @override
  String get key => PendingImageEmbed.embedType;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) =>
      const _EmbedNotice(icon: Icons.image_outlined, busy: true);
}

class _UnsupportedEmbedBuilder extends EmbedBuilder {
  const _UnsupportedEmbedBuilder();

  /// Never matched by type — this is the fallback, reached only when nothing
  /// in [articleEmbedBuilders] claimed the node.
  @override
  String get key => '__unsupported__';

  @override
  Widget build(BuildContext context, EmbedContext embedContext) => _EmbedNotice(
    icon: Icons.help_outline_rounded,
    message: context.l10n.unsupportedEmbed(embedContext.node.value.type),
  );
}

/// The placeholder an embed falls back to: visible, selectable, deletable.
class _EmbedNotice extends StatelessWidget {
  const _EmbedNotice({required this.icon, this.message, this.busy = false});

  final IconData icon;
  final String? message;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      margin: const EdgeInsets.symmetric(vertical: Spacing.cardInternal),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.colors.imagePlaceholder,
        borderRadius: Radii.thumbBorder,
        border: Border.all(color: context.colors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (busy)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(icon, size: 20, color: context.scheme.onSurfaceVariant),
          if (message != null) ...[
            const SizedBox(width: Spacing.chip),
            Flexible(
              child: Text(
                message!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.text.meta.copyWith(
                  color: context.scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
