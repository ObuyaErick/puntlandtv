import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/feedback_views.dart';
import '../../../../core/widgets/remote_image.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../domain/entities/program.dart';
import '../controllers/vod_controllers.dart';

/// The catch-up grid. Browse by programme; the MVP has no "popular" sort
/// because the view analytics that would rank it do not exist yet.
class ProgramsPage extends ConsumerWidget {
  const ProgramsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final programs = ref.watch(programsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.programsTitle),
            Text(
              l10n.programsSubtitle,
              style: context.text.meta.copyWith(
                color: context.scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        toolbarHeight: 72,
      ),
      body: programs.when(
        loading: () => const _ProgramsSkeleton(),
        error: (error, _) => ErrorView(
          failure: error is Failure
              ? error
              : const Failure(kind: FailureKind.unknown, code: 'UNKNOWN'),
          onRetry: () => ref.invalidate(programsProvider),
        ),
        data: (items) => GridView.builder(
          padding: const EdgeInsets.all(Spacing.gutter),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: Spacing.listRhythm,
            crossAxisSpacing: Spacing.cardInternal,
            mainAxisExtent: 260,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => _ProgramTile(program: items[index]),
        ),
      ),
    );
  }
}

/// How long the highlight takes to fade in.
///
/// Short enough to feel attached to the pointer. There is no motion token for
/// this yet; when there is one, this should use it.
const _highlightFade = Duration(milliseconds: 120);

class _ProgramTile extends StatefulWidget {
  const _ProgramTile({required this.program});

  final Program program;

  @override
  State<_ProgramTile> createState() => _ProgramTileState();
}

class _ProgramTileState extends State<_ProgramTile> {
  var _hovered = false;
  var _focused = false;
  var _pressed = false;

  /// Hover, keyboard focus and touch all get the same treatment.
  ///
  /// All three have to be here. Clearing the ink colours below removes the focus
  /// ring `InkWell` would have drawn *and* the splash it would have shown on
  /// tap — and most of this audience is on a phone, where there is no hover at
  /// all. A card that gives nothing back when touched reads as a card that did
  /// not register the touch.
  bool get _highlighted => _hovered || _focused || _pressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final program = widget.program;

    return InkWell(
      onTap: () => context.push(Routes.program(program.id)),
      onHover: (hovered) => setState(() => _hovered = hovered),
      onFocusChange: (focused) => setState(() => _focused = focused),
      // Fires on press down and again on release or cancel, which is exactly
      // the window a touch needs feedback for.
      onHighlightChanged: (pressed) => setState(() => _pressed = pressed),
      borderRadius: Radii.cardBorder,
      // The default ink wash is painted by the enclosing `Material`, *behind*
      // this tile — so it lands wherever the tile is transparent, which is
      // everywhere except the artwork. That put a hard-edged grey slab across
      // the title and the cadence line, wider and squarer than the picture it
      // was meant to belong to. The treatment below is drawn on the artwork
      // instead, where the thing being pressed actually is.
      hoverColor: Colors.transparent,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                RemoteImage(
                  url: program.artworkUrl,
                  borderRadius: Radii.cardBorder,
                ),
                // Over the artwork but under the episode chip, which has to
                // stay readable while the card is highlighted.
                IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _highlighted ? 1 : 0,
                    duration: _highlightFade,
                    curve: Curves.easeOut,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: Radii.cardBorder,
                        // Darkened rather than tinted: the artwork is a
                        // photograph, and any colour laid over it clashes with
                        // some picture in the grid.
                        color: Colors.black.withValues(alpha: 0.16),
                        // Drawn as an overlay rather than as a border on the
                        // image's own box, so nothing is inset and the grid
                        // does not shift by two pixels under the pointer.
                        border: Border.all(
                          color: context.colors.accent,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: Spacing.chip,
                  top: Spacing.chip,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: BrandPalette.navy.withValues(alpha: 0.88),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      l10n.episodeCount(program.episodeCount),
                      style: context.text.overline.copyWith(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: Text(
              program.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: context.text.cardTitle.copyWith(
                fontSize: 15,
                color: _highlighted
                    ? context.colors.accent
                    : context.scheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            [program.cadence, program.genre].whereType<String>().join(' · '),
            style: context.text.meta.copyWith(
              color: context.scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgramsSkeleton extends StatelessWidget {
  const _ProgramsSkeleton();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(Spacing.gutter),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: Spacing.listRhythm,
        crossAxisSpacing: Spacing.cardInternal,
        mainAxisExtent: 260,
      ),
      itemCount: 4,
      itemBuilder: (_, _) => const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: SkeletonBox(radius: Radii.card, height: 200)),
          SizedBox(height: Spacing.chip),
          SkeletonBox(height: 14),
          SizedBox(height: 6),
          SkeletonBox(width: 90, height: 11),
        ],
      ),
    );
  }
}
