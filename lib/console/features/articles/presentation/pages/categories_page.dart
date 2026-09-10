import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/domain/parity.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/responsive/window_size.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../core/widgets/feedback_views.dart';
import '../../../../app/console_navigation.dart';
import '../../../../core/admin_api/dto/broadcast_dto.dart';
import '../../../../core/localised.dart';
import '../../../../core/widgets/console_page.dart';
import '../../../../core/widgets/console_table.dart';
import '../controllers/article_list_controller.dart';
import '../controllers/category_controller.dart';
import 'category_panel.dart';

/// Taxonomy management.
///
/// Built around one distinction the newsroom has to internalise: the **slug is
/// permanent** — it is baked into deep links and push topics, so changing it
/// breaks every alert already sent — while **display names are per-locale and
/// free to change**. The table shows both, side by side, so nobody has to be
/// told twice.
///
/// Lives inside Articles (`/articles/categories`), reached from the article
/// list, because a category only means anything as the place stories are
/// filed: each count here leads back to those stories.
class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final categories = ref.watch(categoryConfigProvider);

    return ConsolePage(
      title: l10n.categoriesTitle,
      actions: [
        OutlinedButton.icon(
          onPressed: context.openArticles,
          icon: const Icon(Icons.arrow_back_rounded, size: 18),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 40),
            side: BorderSide(color: context.colors.outline),
            foregroundColor: context.scheme.onSurface,
          ),
          label: Text(l10n.backToArticles),
        ),
        FilledButton.icon(
          // Waits for the list: the form checks a new slug against it, and a
          // uniqueness check against nothing would pass every duplicate.
          onPressed: categories.hasValue
              ? () => showCategoryPanel(context)
              : null,
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

    // Four columns need ~700dp before the NAME column is squeezed into
    // something unreadable. Below that each row becomes a card, the same
    // trade the article list makes.
    return WindowSizeScope(
      builder: (context, size) {
        if (!size.isAtLeastExpanded) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              Spacing.gutter,
              Spacing.gutter,
              Spacing.gutter,
              Spacing.emptyState,
            ),
            children: [
              for (final category in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.cardInternal),
                  child: _CategoryCard(category: category, locale: locale),
                ),
              Text(
                l10n.untranslatedHiddenNote,
                style: context.text.meta.copyWith(
                  color: context.scheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.sectionBreak,
            Spacing.gutter,
            Spacing.sectionBreak,
            Spacing.sectionBreak,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              // color: context.scheme.surface,
              // borderRadius: Radii.cardBorder,
              // border: Border.all(color: context.colors.outline),
            ),
            child: Column(
              children: [
                ConsoleTableHeader(columns: columns),
                Expanded(
                  child: ListView(
                    children: [
                      // No `isLast`: the note below follows the rows, and
                      // the divider is what separates them from it.
                      for (final (index, category) in rows.indexed)
                        ConsoleTableRow(
                          columns: columns,
                          onTap: () =>
                              showCategoryPanel(context, category: category),
                          parity: Parity.of(index),
                          cells: [
                            // Monospace-ish weight to signal "identifier,
                            // not prose".
                            Text(
                              category.slug,
                              style: context.text.label.copyWith(
                                color: context.scheme.primary,
                              ),
                            ),
                            _NameCell(category: category, locale: locale),
                            _ArticleCountLink(
                              category: category,
                              label: '${category.articleCount}',
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
        );
      },
    );
  }
}

/// The compact-width presentation of a category.
///
/// Keeps the table's one lesson intact: the permanent slug and the editable
/// name are shown together, the slug visibly an identifier rather than prose.
class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.locale});

  final CategoryConfigDto category;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Material(
      color: context.scheme.surface,
      borderRadius: Radii.cardBorder,
      child: InkWell(
        onTap: () => showCategoryPanel(context, category: category),
        borderRadius: Radii.cardBorder,
        child: Container(
          padding: const EdgeInsets.all(Spacing.listRhythm),
          decoration: BoxDecoration(
            borderRadius: Radii.cardBorder,
            border: Border.all(color: context.colors.outline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _NameCell(category: category, locale: locale),
                  ),
                  const SizedBox(width: Spacing.cardInternal),
                  _VisibilityCell(category: category),
                ],
              ),
              const SizedBox(height: Spacing.chip),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      category.slug,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.label.copyWith(
                        color: context.scheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.cardInternal),
                  // The count carries its own noun here: there is no column
                  // header above a card to say what the number counts.
                  _ArticleCountLink(
                    category: category,
                    label: l10n.categoryArticleCount(category.articleCount),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A category's article count, and the way to those articles.
///
/// The count is the question an editor brings to this screen — what is filed
/// here? — so it answers it: tapping opens the article list narrowed to this
/// category. Its own tap target inside the row, whose tap opens the editor.
/// Zero stays plain text; there is nothing to open.
class _ArticleCountLink extends ConsumerWidget {
  const _ArticleCountLink({required this.category, required this.label});

  final CategoryConfigDto category;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (category.articleCount == 0) {
      return Text(
        label,
        style: context.text.meta.copyWith(
          color: context.scheme.onSurfaceVariant,
        ),
      );
    }

    return Tooltip(
      message: context.l10n.viewCategoryArticles,
      child: Semantics(
        link: true,
        child: InkWell(
          onTap: () {
            ref
                .read(articleFilterProvider.notifier)
                .onlyCategory(category.slug);
            context.openArticles();
          },
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              label,
              style: context.text.meta.copyWith(
                color: context.colors.linkText,
                decoration: TextDecoration.underline,
                decorationColor: context.colors.linkText,
              ),
            ),
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
