import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/responsive/window_size.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../core/widgets/feedback_views.dart';
import '../../../../core/admin_api/dto/admin_program_dto.dart';
import '../../../../core/localised.dart';
import '../../../../core/widgets/console_page.dart';
import '../../../../core/widgets/console_table.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../media/presentation/media_format.dart';
import '../controllers/program_controller.dart';
import '../widgets/shelf_pills.dart';
import 'episode_list_page.dart';

/// The VOD library: programmes, and one programme's episodes.
///
/// One destination holding two views rather than two rail entries. The rail has
/// a Programmes entry; an "Episodes" entry beside it would mean nothing until
/// you had already picked a show, and would sit there empty the rest of the
/// time.
///
/// The rule this screen carries is the same one the categories table carries,
/// applied to shelves instead of tab bars: **an untitled locale hides the
/// programme from that locale's audience.** It does not fall back to the other
/// language. Putting a Somali-only title on an English shelf would show the
/// majority-language audience's content to people who cannot read it and count
/// that as coverage.
class ProgramsPage extends ConsumerWidget {
  const ProgramsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openId = ref.watch(openProgramProvider);
    if (openId != null) return EpisodeListPage(programId: openId);

    final l10n = context.l10n;
    final programs = ref.watch(programListProvider);

    return ConsolePage(
      title: l10n.programsConsoleTitle,
      subtitle: programs.value == null
          ? null
          : l10n.itemCount(programs.value!.length),
      actions: [
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(l10n.newProgram),
        ),
      ],
      notice: ConsoleNotice(message: l10n.programsNotice),
      child: programs.when(
        loading: () => const _ProgramSkeleton(),
        error: (error, _) => ErrorView(
          failure: error is Failure
              ? error
              : const Failure(kind: FailureKind.unknown, code: 'UNKNOWN'),
          onRetry: () => ref.invalidate(programListProvider),
        ),
        data: (rows) => rows.isEmpty
            ? EmptyView(
                title: l10n.emptyPrograms,
                body: l10n.emptyProgramsBody,
                icon: Icons.video_library_outlined,
              )
            : _ProgramTable(rows: rows),
      ),
    );
  }
}

class _ProgramTable extends ConsumerWidget {
  const _ProgramTable({required this.rows});

  final List<AdminProgramDto> rows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final locale = context.languageCode;

    final columns = <ConsoleColumn>[
      ConsoleColumn(label: l10n.colProgram, flex: 4),
      ConsoleColumn(label: l10n.colGenre, width: 110),
      ConsoleColumn(label: l10n.colCadence, width: 110),
      ConsoleColumn(label: l10n.colEpisodes, width: 90, alignEnd: true),
      ConsoleColumn(label: l10n.colShelf, width: 96),
    ];

    return WindowSizeScope(
      builder: (context, size) {
        final asTable = size.isAtLeastExpanded;

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.sectionBreak,
            Spacing.gutter,
            Spacing.sectionBreak,
            Spacing.sectionBreak,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.scheme.surface,
              borderRadius: Radii.cardBorder,
              border: Border.all(color: context.colors.outline),
            ),
            child: ClipRRect(
              borderRadius: Radii.cardBorder,
              child: Column(
                children: [
                  if (asTable) ConsoleTableHeader(columns: columns),
                  Expanded(
                    child: ListView.builder(
                      itemCount: rows.length,
                      itemBuilder: (context, index) {
                        final program = rows[index];
                        void open() => ref
                            .read(openProgramProvider.notifier)
                            .open(program.id);

                        if (!asTable) {
                          return _ProgramCard(
                            program: program,
                            locale: locale,
                            onTap: open,
                          );
                        }

                        return ConsoleTableRow(
                          columns: columns,
                          onTap: open,
                          cells: [
                            _ProgramCell(program: program, locale: locale),
                            Text(
                              ConsoleLabels.genre(l10n, program.genre),
                              style: context.text.meta.copyWith(
                                color: context.scheme.onSurface,
                              ),
                            ),
                            Text(
                              ConsoleLabels.cadence(l10n, program.cadence),
                              style: context.text.meta.copyWith(
                                color: context.scheme.onSurface,
                              ),
                            ),
                            Text(
                              '${program.episodeCount}',
                              style: context.text.meta.copyWith(
                                color: context.scheme.onSurface,
                              ),
                            ),
                            ShelfPills(program: program),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Artwork, title, and the one line that says whether anyone can see this.
class _ProgramCell extends StatelessWidget {
  const _ProgramCell({required this.program, required this.locale});

  final AdminProgramDto program;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final untitled = program.untitledLocales;

    // Priority order. A programme live on one shelf and missing from the other
    // is the state someone has to fix; a draft that is missing both is just
    // unfinished, and saying "hidden" about it would be noise.
    //
    // With nothing wrong, the line carries the id — the slug the app's deep
    // links are built on, and the one field here that no column repeats. Genre
    // sat here first and printed the same word twice in every row.
    final (detail, isProblem) = program.isPartiallyVisible
        ? (l10n.hiddenFromShelf(context.languageNameOf(untitled.first)), true)
        : (program.id, false);

    return Row(
      children: [
        _Artwork(url: program.artworkUrl),
        const SizedBox(width: Spacing.cardInternal),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                program.titleFor(locale),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.body.copyWith(
                  fontWeight: FontWeight.w500,
                  color: context.scheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.meta.copyWith(
                  color: isProblem
                      ? context.scheme.error
                      : context.scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (!program.isPublished) ...[
          const SizedBox(width: Spacing.chip),
          const StatusBadge(kind: BadgeKind.draft),
        ],
      ],
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.url, this.size = 40});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: context.colors.imagePlaceholder,
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? Icon(
              Icons.video_library_outlined,
              size: size * 0.45,
              color: context.scheme.onSurfaceVariant,
            )
          : Image.network(
              url!,
              fit: BoxFit.cover,
              errorBuilder: (context, _, _) => Icon(
                Icons.video_library_outlined,
                size: size * 0.45,
                color: context.scheme.onSurfaceVariant,
              ),
            ),
    );
  }
}

/// The compact presentation: the same information, stacked.
class _ProgramCard extends StatelessWidget {
  const _ProgramCard({
    required this.program,
    required this.locale,
    required this.onTap,
  });

  final AdminProgramDto program;
  final String locale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Spacing.listRhythm),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: context.colors.outlineSubtle),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProgramCell(program: program, locale: locale),
            const SizedBox(height: Spacing.cardInternal),
            Row(
              children: [
                ShelfPills(program: program),
                const Spacer(),
                Text(
                  '${ConsoleLabels.cadence(l10n, program.cadence)} · '
                  '${program.episodeCount}',
                  style: context.text.meta.copyWith(
                    color: context.scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgramSkeleton extends StatelessWidget {
  const _ProgramSkeleton();

  @override
  Widget build(BuildContext context) {
    final columns = [
      ConsoleColumn(label: context.l10n.colProgram, flex: 4),
      const ConsoleColumn(label: '', width: 110),
      const ConsoleColumn(label: '', width: 96),
    ];

    return ListView(
      children: [
        for (var i = 0; i < 6; i++) ConsoleTableRowSkeleton(columns: columns),
      ],
    );
  }
}

/// Shared by the programme and episode screens.
class ProgramArtwork extends StatelessWidget {
  const ProgramArtwork({super.key, required this.url, this.size = 40});

  final String? url;
  final double size;

  @override
  Widget build(BuildContext context) => _Artwork(url: url, size: size);
}

/// Episode running time, in the form every player uses.
String episodeDurationLabel(Duration value) => MediaFormat.duration(value);
