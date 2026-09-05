import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../core/admin_api/dto/media_dto.dart';
import '../../../../core/providers/console_providers.dart';
import '../../../media/presentation/widgets/media_thumbnail.dart';
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
    final assets = await ref.read(adminApiProvider).fetchMedia(
      filter: MediaKindFilter.image,
    );
    if (!mounted) return;

    final chosen = await showDialog<MediaAssetDto>(
      context: context,
      builder: (context) => _PickerDialog(assets: assets),
    );
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
                      _Chip(
                        label: l10n.removeImage,
                        onTap: onRemove!,
                      ),
                      const SizedBox(width: 6),
                    ],
                    _Chip(label: l10n.heroReplace, onTap: onTap),
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

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(4),
    child: Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.chip),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.scheme.primary.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: context.text.overline.copyWith(
          fontSize: 10.5,
          color: context.scheme.onPrimary,
        ),
      ),
    ),
  );
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
        Icon(Icons.error_outline_rounded, size: 16, color: context.scheme.error),
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

/// Picks an image from the library.
///
/// Only images, and each one shows whether it has alt text — choosing an
/// undescribed picture is choosing to be blocked at publish, and the grid is
/// where that is cheapest to know.
class _PickerDialog extends StatelessWidget {
  const _PickerDialog({required this.assets});

  final List<MediaAssetDto> assets;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      title: Text(l10n.chooseHeroImage, style: context.text.title),
      content: SizedBox(
        width: 620,
        height: 420,
        child: assets.isEmpty
            ? Center(
                child: Text(
                  l10n.emptyMedia,
                  style: context.text.body.copyWith(
                    color: context.scheme.onSurfaceVariant,
                  ),
                ),
              )
            : GridView.builder(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: Spacing.cardInternal,
                      crossAxisSpacing: Spacing.cardInternal,
                      childAspectRatio: 4 / 3,
                    ),
                itemCount: assets.length,
                itemBuilder: (context, index) {
                  final asset = assets[index];
                  return Semantics(
                    button: true,
                    label: asset.filename,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(asset),
                      borderRadius: Radii.thumbBorder,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          MediaThumbnail(asset: asset),
                          if (asset.alt.isEmpty)
                            Positioned(
                              left: 6,
                              bottom: 6,
                              child: _Chip(
                                label: l10n.filterNeedsAlt,
                                onTap: () =>
                                    Navigator.of(context).pop(asset),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
}
