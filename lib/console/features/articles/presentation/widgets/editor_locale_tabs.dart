import 'package:material_ui/material_ui.dart';

import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../core/localised.dart';
import '../controllers/article_editor_controller.dart';

/// The language strip: which version you are editing, and how it stands.
///
/// Tabs rather than a picker, and each one carries its own state — `SOURCE` on
/// the language the story was written in, `BEHIND` on one that has fallen back.
/// The badge is the point: an editor opening a story has to be able to see
/// that the English is stale without first selecting it and reading a date.
class EditorLocaleTabs extends StatelessWidget {
  const EditorLocaleTabs({super.key, required this.editor});

  final ArticleEditor editor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stale = editor.staleLocales;
    final counterpart = editor.counterpartLocale;

    return Container(
      decoration: BoxDecoration(
        color: context.scheme.surface,
        border: Border(bottom: BorderSide(color: context.colors.outline)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sectionBreak),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final locale in editor.locales)
                    _Tab(
                      label: context.languageNameOf(locale),
                      selected: locale == editor.locale,
                      isSource: locale == editor.article.sourceLocale,
                      isStale: stale.contains(locale),
                      onTap: () => editor.selectLocale(locale),
                    ),
                  // Adding the missing language is on the strip that shows
                  // which languages exist, because that is where its absence
                  // is visible.
                  for (final locale in const ['so', 'en'])
                    if (!editor.locales.contains(locale))
                      Padding(
                        padding: const EdgeInsets.only(
                          left: Spacing.chip,
                          bottom: Spacing.cardInternal,
                        ),
                        child: TextButton.icon(
                          onPressed: () => editor.addLocale(locale),
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: Text(
                            l10n.addTranslation(context.languageNameOf(locale)),
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
          if (counterpart != null)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.cardInternal),
              child: OutlinedButton.icon(
                onPressed: editor.toggleSideBySide,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 34),
                  side: BorderSide(
                    color: editor.sideBySide
                        ? context.colors.link
                        : context.colors.outline,
                  ),
                  foregroundColor: context.scheme.primary,
                ),
                icon: const Icon(Icons.splitscreen_rounded, size: 15),
                label: Text(
                  editor.sideBySide ? l10n.exitSideBySide : l10n.sideBySide,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.isSource,
    required this.isStale,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool isSource;
  final bool isStale;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 13),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? context.scheme.primary : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: context.text.label.copyWith(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? context.scheme.primary
                      : context.scheme.onSurfaceVariant,
                ),
              ),
              if (isSource) ...[
                const SizedBox(width: 9),
                _Pill(
                  label: l10n.badgeSource,
                  background: context.scheme.primary,
                  foreground: context.scheme.onPrimary,
                ),
              ],
              if (isStale) ...[
                const SizedBox(width: 9),
                _Pill(
                  label: l10n.badgeBehind,
                  background: context.scheme.errorContainer,
                  foreground: context.scheme.error,
                  border: context.colors.errorContainerOutline,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
    this.border,
  });

  final String label;
  final Color background;
  final Color foreground;
  final Color? border;

  @override
  Widget build(BuildContext context) => Container(
    height: 19,
    padding: const EdgeInsets.symmetric(horizontal: 6),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(3),
      border: border == null ? null : Border.all(color: border!),
    ),
    child: Text(
      label,
      style: context.text.overline.copyWith(fontSize: 9.5, color: foreground),
    ),
  );
}
