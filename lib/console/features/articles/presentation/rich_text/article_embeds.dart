import 'package:flutter_quill/flutter_quill.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';

/// How the body editor renders the things in an article that are not prose.
///
/// **Every embed the document can hold needs a builder here.**
List<EmbedBuilder> articleEmbedBuilders() => const [_ImageEmbedBuilder()];

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
      child: ClipRRect(
        borderRadius: Radii.thumbBorder,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          width: double.infinity,
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : const _EmbedNotice(icon: Icons.image_outlined, busy: true),
          errorBuilder: (context, _, _) => _EmbedNotice(
            icon: Icons.broken_image_outlined,
            message: context.l10n.imageFailedToLoad,
          ),
        ),
      ),
    );
  }
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
