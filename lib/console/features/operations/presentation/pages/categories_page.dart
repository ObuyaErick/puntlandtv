import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../core/widgets/feedback_views.dart';
import '../../../../core/admin_api/dto/broadcast_dto.dart';
import '../../../../core/localised.dart';
import '../../../../core/providers/console_providers.dart';
import '../../../../core/widgets/console_page.dart';
import '../../../../core/widgets/console_table.dart';

final categoryConfigProvider = FutureProvider<List<CategoryConfigDto>>(
  (ref) => ref.watch(adminApiProvider).fetchCategories(),
);

/// Taxonomy management.
///
/// Built around one distinction the newsroom has to internalise: the **slug is
/// permanent** — it is baked into deep links and push topics, so changing it
/// breaks every alert already sent — while **display names are per-locale and
/// free to change**. The table shows both, side by side, so nobody has to be
/// told twice.
class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final categories = ref.watch(categoryConfigProvider);

    return ConsolePage(
      title: l10n.categoriesTitle,
      actions: [
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add_rounded, size: 18),
          label: Text(l10n.newCategory),
        ),
      ],
      notice: ConsoleNotice(message: l10n.slugPermanentNote),
      child: categories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          failure: error is Failure
              ? error
              : const Failure(kind: FailureKind.unknown, code: 'UNKNOWN'),
          onRetry: () => ref.invalidate(categoryConfigProvider),
        ),
        data: (rows) => _CategoryTable(rows: rows),
      ),
    );
  }
}

class _CategoryTable extends StatelessWidget {
  const _CategoryTable({required this.rows});

  final List<CategoryConfigDto> rows;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.languageCode;

    final columns = [
      ConsoleColumn(label: l10n.colSlug, width: 130),
      // One NAME column in the active locale, not one per language: the
      // per-language values belong on the *edit* form, where someone is
      // entering them, not spread across a table nobody reads sideways.
      ConsoleColumn(label: l10n.colName, flex: 3),
      ConsoleColumn(label: l10n.colArticles, width: 90, alignEnd: true),
      ConsoleColumn(label: l10n.colInApp, width: 110),
    ];

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
              ConsoleTableHeader(columns: columns),
              Expanded(
                child: ListView(
                  children: [
                    for (final category in rows)
                      ConsoleTableRow(
                        columns: columns,
                        onTap: () {},
                        cells: [
                          // Monospace-ish weight to signal "identifier, not prose".
                          Text(
                            category.slug,
                            style: context.text.label.copyWith(
                              color: context.scheme.primary,
                            ),
                          ),
                          _NameCell(category: category, locale: locale),
                          Text(
                            '${category.articleCount}',
                            style: context.text.meta.copyWith(
                              color: context.scheme.onSurface,
                            ),
                          ),
                          _VisibilityCell(category: category),
                        ],
                      ),
                    Padding(
                      padding: const EdgeInsets.all(Spacing.gutter),
                      child: Text(
                        l10n.untranslatedHiddenNote,
                        style: context.text.meta.copyWith(
                          color: context.scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
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

class _NameCell extends StatelessWidget {
  const _NameCell({required this.category, required this.locale});

  final CategoryConfigDto category;
  final String locale;

  @override
  Widget build(BuildContext context) {
    // Falls back to another language rather than showing a slug, and says so:
    // the fallback is legitimate data, the missing translation is the note.
    final missing = category.untranslatedLocales;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          category.nameFor(locale),
          style: context.text.body.copyWith(color: context.scheme.onSurface),
        ),
        if (missing.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            missing
                .map(
                  (code) => context.l10n.missingTranslation(
                    context.languageNameOf(code),
                  ),
                )
                .join(' · '),
            style: context.text.meta.copyWith(color: context.scheme.error),
          ),
        ],
      ],
    );
  }
}

/// Which locales' tab bars this category appears in.
class _VisibilityCell extends StatelessWidget {
  const _VisibilityCell({required this.category});

  final CategoryConfigDto category;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      children: [
        for (final locale in const ['so', 'en'])
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: category.isVisibleIn(locale)
                  ? context.colors.accentContainer
                  : context.colors.skeleton,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              locale.toUpperCase(),
              style: context.text.overline.copyWith(
                fontSize: 9.5,
                color: category.isVisibleIn(locale)
                    ? context.colors.onAccentContainer
                    : context.scheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}
