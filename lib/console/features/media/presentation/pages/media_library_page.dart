import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/responsive/window_size.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../core/widgets/feedback_views.dart';
import '../../../../core/admin_api/dto/media_dto.dart';
import '../../../../core/widgets/console_page.dart';
import '../../../../core/widgets/console_toast.dart';
import '../controllers/media_library_controller.dart';
import '../widgets/media_grid_tile.dart';
import '../widgets/upload_drop_zone.dart';
import 'media_detail_panel.dart';

/// The media library.
///
/// A grid rather than a table, because the first question anyone asks of a
/// file listing is "which picture is that" and no column answers it. The
/// columns a table would have carried — size, kind, ingest state, usage —
/// survive as one line under each thumbnail, chosen by which of them the
/// person can act on.
///
/// The rule the library carries beyond the article editor's publish gate is
/// **alt text in every locale**. The editor gates on a description existing;
/// that is presence, not completeness, and an image described only in Somali
/// reaches an English reader's screen reader as Somali or as nothing. That
/// completeness is authored here, and the "needs alt text" chip is the only
/// filter on this screen that names a problem rather than a file type.
class MediaLibraryPage extends ConsumerWidget {
  const MediaLibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final assets = ref.watch(mediaLibraryProvider);
    final counts = ref.watch(mediaCountsProvider).value;

    return ConsolePage(
      title: l10n.mediaTitle,
      subtitle: assets.value == null
          ? null
          : l10n.itemCount(assets.value!.length),
      actions: [
        FilledButton.icon(
          onPressed: () => _upload(context, ref),
          icon: const Icon(Icons.upload_rounded, size: 18),
          label: Text(l10n.uploadMedia),
        ),
      ],
      // The rule, stated once at the top rather than only on the tiles that
      // break it — someone has to know it before they upload, not after.
      notice: ConsoleNotice(message: l10n.mediaAltNotice),
      filters: const _FilterRow(),
      child: assets.when(
        loading: () => const _GridSkeleton(),
        error: (error, _) => ErrorView(
          failure: error is Failure
              ? error
              : const Failure(kind: FailureKind.unknown, code: 'UNKNOWN'),
          onRetry: () => ref.invalidate(mediaLibraryProvider),
        ),
        data: (rows) => _LibraryBody(rows: rows, counts: counts),
      ),
    );
  }
}

/// Registers an upload and opens it.
///
/// Opening the panel is the point rather than a convenience: an image lands
/// with no alt text, and the panel is where that gets fixed. Dropping the
/// operator back on the grid would leave an undescribed file looking finished.
Future<void> _upload(BuildContext context, WidgetRef ref) async {
  await _uploadWith(
    context,
    ref,
    filename: 'sawir-cusub.jpg',
    kind: MediaKind.image,
    byteSize: 1420 * 1024,
  );
}

Future<void> _uploadWith(
  BuildContext context,
  WidgetRef ref, {
  required String filename,
  required MediaKind kind,
  required int byteSize,
}) async {
  final l10n = context.l10n;
  showConsoleToast(context, message: l10n.uploadPending(filename));

  final asset = await ref
      .read(mediaActionsProvider.notifier)
      .upload(filename: filename, kind: kind, byteSize: byteSize);

  if (!context.mounted) return;

  showConsoleToast(
    context,
    message: asset.blocksPublishing
        ? l10n.uploadedNeedsAlt
        : l10n.uploadedProcessing,
    kind: asset.blocksPublishing ? ToastKind.error : ToastKind.success,
  );

  // Only an image opens straight into the panel. A video has nothing to fill
  // in yet — it is transcoding, and the useful next action is to leave it
  // alone.
  if (asset.kind == MediaKind.image) {
    await showMediaAsset(context, id: asset.id);
  }
}

class _FilterRow extends ConsumerWidget {
  const _FilterRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selected = ref.watch(mediaFilterProvider);
    final counts = ref.watch(mediaCountsProvider).value;
    final controller = ref.read(mediaFilterProvider.notifier);

    final chips = <(MediaKindFilter, String)>[
      (MediaKindFilter.all, l10n.filterAllMedia),
      (MediaKindFilter.image, l10n.filterImages),
      (MediaKindFilter.video, l10n.filterVideo),
      (MediaKindFilter.audio, l10n.filterAudio),
    ];

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: context.scheme.surface,
        border: Border(bottom: BorderSide(color: context.colors.outline)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.sectionBreak),
        children: [
          for (final (filter, label) in chips) ...[
            Center(
              child: ConsoleFilterChip(
                label: label,
                count: counts?.forFilter(filter) ?? 0,
                selected: selected == filter,
                onTap: () => controller.select(filter),
              ),
            ),
            const SizedBox(width: Spacing.chip),
          ],
          // A rule before the one chip that filters on a *problem* rather than
          // a type. Running it in with the kind chips reads as a fifth file
          // format.
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.chip,
              vertical: Spacing.listRhythm,
            ),
            child: VerticalDivider(width: 1, color: context.colors.outline),
          ),
          Center(
            child: ConsoleFilterChip(
              label: l10n.filterNeedsAlt,
              count: counts?.needsAlt ?? 0,
              selected: selected == MediaKindFilter.needsAlt,
              onTap: () => controller.select(MediaKindFilter.needsAlt),
            ),
          ),
          const SizedBox(width: Spacing.listRhythm),
          const Center(child: _SearchBox()),
        ],
      ),
    );
  }
}

class _SearchBox extends ConsumerStatefulWidget {
  const _SearchBox();

  @override
  ConsumerState<_SearchBox> createState() => _SearchBoxState();
}

class _SearchBoxState extends ConsumerState<_SearchBox> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return SizedBox(
      width: 300,
      height: 40,
      child: TextField(
        controller: _controller,
        onChanged: ref.read(mediaSearchProvider.notifier).update,
        style: context.text.body.copyWith(color: context.scheme.primary),
        decoration: InputDecoration(
          hintText: l10n.searchMedia,
          isDense: true,
          filled: true,
          fillColor: context.scheme.surface,
          prefixIcon: Icon(
            Icons.search_rounded,
            size: 18,
            color: context.scheme.onSurfaceVariant,
          ),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _controller.clear();
                    ref.read(mediaSearchProvider.notifier).clear();
                  },
                  tooltip: l10n.clearFilters,
                  icon: const Icon(Icons.close_rounded, size: 16),
                ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Radii.button),
            borderSide: BorderSide(color: context.colors.outline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Radii.button),
            borderSide: BorderSide(color: context.colors.link, width: 2),
          ),
        ),
      ),
    );
  }
}

class _LibraryBody extends ConsumerWidget {
  const _LibraryBody({required this.rows, required this.counts});

  final List<MediaAssetDto> rows;
  final MediaCounts? counts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final selection = ref.watch(mediaSelectionProvider);
    final filtered =
        ref.watch(mediaFilterProvider) != MediaKindFilter.all ||
        ref.watch(mediaSearchProvider).isNotEmpty;

    if (rows.isEmpty) {
      return EmptyView(
        title: filtered ? l10n.emptyMediaFiltered : l10n.emptyMedia,
        body: filtered ? null : l10n.emptyMediaBody,
        icon: Icons.perm_media_outlined,
        actionLabel: filtered ? l10n.clearFilters : null,
        onAction: filtered
            ? () {
                ref
                    .read(mediaFilterProvider.notifier)
                    .select(MediaKindFilter.all);
                ref.read(mediaSearchProvider.notifier).clear();
              }
            : null,
      );
    }

    return WindowSizeScope(
      builder: (context, size) {
        // Tile width is capped rather than the column count being fixed: a
        // thumbnail stretched to 500dp on an ultrawide tells you no more than
        // one at 260dp, and four rows of nothing is worse than eight of
        // something.
        final columns = switch (size) {
          final s when s.isAtLeastLarge => 5,
          final s when s.isAtLeastExpanded => 4,
          final s when s.isAtLeastMedium => 3,
          _ => 2,
        };

        return Column(
          children: [
            if (selection.isNotEmpty)
              _MediaBulkBar(selection: selection, assets: rows),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      Spacing.sectionBreak,
                      Spacing.gutter,
                      Spacing.sectionBreak,
                      Spacing.listRhythm,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: UploadDropZone(
                        onUpload:
                            ({
                              required filename,
                              required kind,
                              required byteSize,
                            }) => _uploadWith(
                              context,
                              ref,
                              filename: filename,
                              kind: kind,
                              byteSize: byteSize,
                            ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      Spacing.sectionBreak,
                      0,
                      Spacing.sectionBreak,
                      Spacing.emptyState,
                    ),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: Spacing.listRhythm,
                        crossAxisSpacing: Spacing.listRhythm,
                        // 4:3 thumbnail plus a two-line caption. Fixed
                        // rather than intrinsic: a grid whose rows change
                        // height as images load jumps under the pointer.
                        childAspectRatio: 4 / 3.9,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final asset = rows[index];
                        return MediaGridTile(
                          asset: asset,
                          selected: selection.contains(asset.id),
                          onToggleSelected: () => ref
                              .read(mediaSelectionProvider.notifier)
                              .toggle(asset.id),
                          onTap: () => showMediaAsset(context, id: asset.id),
                        );
                      }, childCount: rows.length),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The bulk bar, which here has exactly one action.
///
/// Delete is the only thing that makes sense across a mixed selection — alt
/// text is per-image prose, and there is no bulk form for writing it. Offering
/// one would produce four pictures sharing a description, which is worse than
/// none.
class _MediaBulkBar extends ConsumerWidget {
  const _MediaBulkBar({required this.selection, required this.assets});

  final Set<String> selection;
  final List<MediaAssetDto> assets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    // Counted here so the bar can warn *before* the click rather than
    // reporting a partial delete afterwards.
    final blocked = assets
        .where((a) => selection.contains(a.id) && !a.canDelete)
        .length;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        Spacing.sectionBreak,
        Spacing.cardInternal,
        Spacing.sectionBreak,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.listRhythm,
        vertical: Spacing.cardInternal,
      ),
      decoration: BoxDecoration(
        color: context.scheme.primary,
        borderRadius: Radii.cardBorder,
      ),
      child: Row(
        children: [
          Text(
            l10n.selectedCount(selection.length),
            style: context.text.label.copyWith(color: Colors.white),
          ),
          if (blocked > 0) ...[
            const SizedBox(width: Spacing.listRhythm),
            Flexible(
              child: Text(
                l10n.deleteRefusedCount(blocked),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.meta.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
          const Spacer(),
          TextButton(
            onPressed: () async {
              final ids = selection.toList();
              final refused = await ref
                  .read(mediaActionsProvider.notifier)
                  .delete(ids);
              if (!context.mounted) return;
              showConsoleToast(
                context,
                message: refused.isEmpty
                    ? l10n.assetsDeleted(ids.length)
                    : l10n.deleteRefusedCount(refused.length),
                kind: refused.isEmpty ? ToastKind.success : ToastKind.error,
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: Text(l10n.deleteAsset),
          ),
          const SizedBox(width: Spacing.chip),
          TextButton(
            onPressed: ref.read(mediaSelectionProvider.notifier).clear,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withValues(alpha: 0.8),
            ),
            child: Text(l10n.deselectAll),
          ),
        ],
      ),
    );
  }
}

class _GridSkeleton extends StatelessWidget {
  const _GridSkeleton();

  @override
  Widget build(BuildContext context) {
    return WindowSizeScope(
      builder: (context, size) {
        final columns = switch (size) {
          final s when s.isAtLeastLarge => 5,
          final s when s.isAtLeastExpanded => 4,
          final s when s.isAtLeastMedium => 3,
          _ => 2,
        };

        return GridView.builder(
          padding: const EdgeInsets.all(Spacing.sectionBreak),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: Spacing.listRhythm,
            crossAxisSpacing: Spacing.listRhythm,
            childAspectRatio: 4 / 3.9,
          ),
          itemCount: columns * 2,
          itemBuilder: (context, index) => DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.skeleton,
              borderRadius: Radii.cardBorder,
            ),
          ),
        );
      },
    );
  }
}
