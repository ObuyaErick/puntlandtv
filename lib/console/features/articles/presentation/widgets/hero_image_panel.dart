import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../media/presentation/widgets/media_picker_dialog.dart';
import '../controllers/article_editor_controller.dart';

/// The hero image card: the picture, its caption, and the rule that gates
/// publishing on it being described.
///
/// The image is attached **by asset id**, never by URL. That is what makes the
/// media library's "in use" refusal answerable — a published article can lose
/// its hero image to a tidy-up otherwise, and nobody finds out until a reader
/// does.
class HeroImagePanel extends ConsumerStatefulWidget {
  const HeroImagePanel({
    super.key,
    required this.editor,
    required this.onChanged,
  });

  final ArticleEditor editor;

  /// Null detaches the current image.
  final ValueChanged<String?> onChanged;

  @override
  ConsumerState<HeroImagePanel> createState() => _HeroImagePanelState();
}

class _HeroImagePanelState extends ConsumerState<HeroImagePanel> {
  late final _caption = TextEditingController(
    text: widget.editor.draft.caption,
  );
  String _captionLocale = '';

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final article = widget.editor.article;
    final locale = widget.editor.locale;

    // The caption is translated like everything else, so switching language
    // has to re-hydrate the field rather than leave the Somali text sitting
    // under an `EN` label.
    if (_captionLocale != locale) {
      _captionLocale = locale;
      _caption.text = widget.editor.draft.caption;
    }

    final hasImage = article.imageId != null;
    final altMissing = hasImage && article.imageAlt == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.sectionHeroImage,
          style: context.text.overline.copyWith(
            color: context.scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.listRhythm - 2),
        _Frame(
          imageUrl: article.imageUrl,
          onTap: _pick,
          onRemove: hasImage ? () => widget.onChanged(null) : null,
        ),
        const SizedBox(height: Spacing.listRhythm - 2),
        Text(
          l10n.editorCaption(locale.toUpperCase()),
          style: context.text.label.copyWith(color: context.scheme.onSurface),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _caption,
          onChanged: widget.editor.setCaption,
          minLines: 2,
          maxLines: 3,
          style: context.text.body.copyWith(color: context.scheme.onSurface),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: context.scheme.surface,
            hintText: l10n.captionHint,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: Radii.cardBorder,
              borderSide: BorderSide(color: context.colors.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: Radii.cardBorder,
              borderSide: BorderSide(color: context.colors.link, width: 2),
            ),
          ),
        ),
        if (altMissing) ...[
          const SizedBox(height: Spacing.listRhythm - 2),
          _AltWarning(),
        ],
      ],
    );
  }

  Future<void> _pick() async {
    final chosen = await pickMediaImage(context, ref);
    if (chosen != null) widget.onChanged(chosen.id);
  }
}

/// The 16:9 frame, with `Replace` over it per the canvas.
class _Frame extends StatelessWidget {
  const _Frame({
    required this.imageUrl,
    required this.onTap,
    required this.onRemove,
  });

  final String? imageUrl;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Semantics(
      button: true,
      label: imageUrl == null ? l10n.chooseHeroImage : l10n.replaceHeroImage,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.cardBorder,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: context.colors.imagePlaceholder,
                  borderRadius: Radii.cardBorder,
                ),
                child: imageUrl == null
                    ? Icon(
                        Icons.image_outlined,
                        size: 24,
                        color: context.scheme.onSurfaceVariant,
                      )
                    : ClipRRect(
                        borderRadius: Radii.cardBorder,
                        child: Image.network(imageUrl!, fit: BoxFit.cover),
                      ),
              ),
              Positioned(
                right: Spacing.chip,
                bottom: Spacing.chip,
                child: Row(
                  children: [
                    if (onRemove != null) ...[
                      MediaOverlayChip(
                        label: l10n.removeImage,
                        onTap: onRemove!,
                      ),
                      const SizedBox(width: 6),
                    ],
                    MediaOverlayChip(label: l10n.heroReplace, onTap: onTap),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AltWarning extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
    decoration: BoxDecoration(
      color: context.scheme.errorContainer,
      borderRadius: Radii.cardBorder,
      border: Border.all(color: context.colors.errorContainerOutline),
    ),
    child: Row(
      children: [
        Icon(
          Icons.error_outline_rounded,
          size: 16,
          color: context.scheme.error,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            context.l10n.altTextRequired,
            style: context.text.meta.copyWith(color: context.scheme.error),
          ),
        ),
      ],
    ),
  );
}
