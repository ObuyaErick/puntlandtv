import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../core/admin_api/dto/media_dto.dart';
import '../../../../core/providers/console_providers.dart';
import 'media_thumbnail.dart';

/// Picks an image out of the library.
///
/// Shared by the hero image card and the body editor's image control, because
/// both are answering the same question and an operator who learns one grid
/// should not have to learn a second. Only images, and each tile says whether
/// it has alt text — choosing an undescribed picture is choosing to be blocked
/// at publish, and the grid is where that is cheapest to know.
Future<MediaAssetDto?> pickMediaImage(
  BuildContext context,
  WidgetRef ref,
) async {
  final assets = await ref
      .read(adminApiProvider)
      .fetchMedia(filter: MediaKindFilter.image);
  if (!context.mounted) return null;

  return showDialog<MediaAssetDto>(
    context: context,
    builder: (context) => MediaPickerDialog(assets: assets),
  );
}

/// The grid itself, separated from [pickMediaImage] so a test can pump it
/// without a network round trip.
class MediaPickerDialog extends StatelessWidget {
  const MediaPickerDialog({super.key, required this.assets});

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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                              child: MediaOverlayChip(
                                label: l10n.filterNeedsAlt,
                                onTap: () => Navigator.of(context).pop(asset),
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

/// A small label sitting on top of a picture.
class MediaOverlayChip extends StatelessWidget {
  const MediaOverlayChip({super.key, required this.label, required this.onTap});

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
