import 'package:material_ui/material_ui.dart';

import '../../../../../core/l10n/app_date_format.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../core/localised.dart';
import '../controllers/article_editor_controller.dart';

/// The translation-linking model, made visible.
///
/// The rule it exists to explain: publishing the source language marks a
/// lagging translation **stale in the app rather than hiding it**. Hiding
/// would leave a reader with nothing, which is worse than slightly
/// out-of-date copy — but an editor has to know that is what happens, or they
/// will assume the old text quietly disappeared.
class TranslationPanel extends StatelessWidget {
  const TranslationPanel({
    super.key,
    required this.editor,
    required this.onReconfirm,
    required this.onOpenSideBySide,
  });

  final ArticleEditor editor;
  final ValueChanged<String> onReconfirm;
  final ValueChanged<String> onOpenSideBySide;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final article = editor.article;
    final stale = editor.staleLocales;
    final source = article.translations[article.sourceLocale];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.sectionTranslation,
              style: context.text.overline.copyWith(
                color: context.scheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            if (stale.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: context.scheme.errorContainer,
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(
                    color: context.colors.errorContainerOutline,
                  ),
                ),
                child: Text(
                  l10n.translationLocaleBehind(
                    context.languageNameOf(stale.first).toUpperCase(),
                  ),
                  style: context.text.overline.copyWith(
                    fontSize: 10,
                    color: context.scheme.error,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: Spacing.listRhythm - 2),
        for (final locale in editor.locales)
          _TranslationRow(
            locale: locale,
            languageName: context.languageNameOf(locale),
            isSource: locale == article.sourceLocale,
            isStale: stale.contains(locale),
            updatedAt: article.translations[locale]?.updatedAt,
            updatedBy: article.translations[locale]?.updatedBy,
            sourceUpdatedAt: source?.updatedAt,
            onOpen: () => onOpenSideBySide(locale),
          ),
        if (stale.isNotEmpty) ...[
          const SizedBox(height: Spacing.cardInternal),
          Container(
            padding: const EdgeInsets.all(Spacing.cardInternal),
            decoration: BoxDecoration(
              color: context.scheme.errorContainer,
              borderRadius: Radii.cardBorder,
              border: Border.all(color: context.colors.errorContainerOutline),
            ),
            child: Text(
              l10n.translationStaleNote,
              style: context.text.meta.copyWith(
                color: context.scheme.error,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: Spacing.cardInternal),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => onOpenSideBySide(stale.first),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    side: BorderSide(color: context.colors.outline, width: 1.5),
                    foregroundColor: context.scheme.primary,
                  ),
                  child: Text(
                    l10n.openLocaleSideBySide(
                      context.languageNameOf(stale.first),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              // Clearing the flag is the destructive-looking half of the pair,
              // so it is the icon rather than the wide button: re-confirming a
              // translation nobody has re-read is exactly the mistake this
              // panel exists to make harder.
              Tooltip(
                message: l10n.reconfirmTranslation,
                child: OutlinedButton(
                  onPressed: () => onReconfirm(stale.first),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    padding: EdgeInsets.zero,
                    side: BorderSide(color: context.colors.outline, width: 1.5),
                    foregroundColor: context.scheme.error,
                  ),
                  child: Semantics(
                    label: l10n.reconfirmTranslation,
                    child: const Icon(Icons.close_rounded, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _TranslationRow extends StatelessWidget {
  const _TranslationRow({
    required this.locale,
    required this.languageName,
    required this.isSource,
    required this.isStale,
    required this.updatedAt,
    required this.updatedBy,
    required this.sourceUpdatedAt,
    required this.onOpen,
  });

  final String locale;
  final String languageName;
  final bool isSource;
  final bool isStale;
  final DateTime? updatedAt;
  final String? updatedBy;
  final DateTime? sourceUpdatedAt;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: isStale
            ? context.scheme.surface
            : context.scheme.surfaceContainerLow,
        borderRadius: Radii.cardBorder,
        border: Border.all(
          color: isStale
              ? context.colors.errorContainerOutline
              : context.colors.outline,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSource
                  ? context.scheme.primary
                  : context.scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(6),
              border: isSource
                  ? null
                  : Border.all(color: context.colors.outline),
            ),
            child: Text(
              locale.toUpperCase(),
              style: context.text.overline.copyWith(
                fontSize: 10.5,
                color: isSource
                    ? context.scheme.onPrimary
                    : context.scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isSource
                      ? l10n.translationSource(languageName)
                      : l10n.translationLinked(languageName),
                  style: context.text.label.copyWith(
                    color: context.scheme.primary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  // A stale row says *since when*, because that is the
                  // question an editor actually has: how far behind is it.
                  isStale && sourceUpdatedAt != null
                      ? l10n.changedSince(
                          AppDateFormat.time(
                            updatedAt ?? sourceUpdatedAt!,
                            context.languageCode,
                          ),
                        )
                      : _updatedLine(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.meta.copyWith(
                    color: isStale
                        ? context.scheme.error
                        : context.scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: Spacing.chip),
          if (isStale)
            TextButton(
              onPressed: onOpen,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                foregroundColor: context.colors.link,
              ),
              child: Text(l10n.reviewTranslation),
            )
          else
            Text(
              l10n.translationCurrent,
              style: context.text.meta.copyWith(color: context.colors.accent),
            ),
        ],
      ),
    );
  }

  String _updatedLine(BuildContext context) {
    if (updatedAt == null) return context.l10n.notYetWritten;
    final time = AppDateFormat.time(updatedAt!, context.languageCode);
    return updatedBy == null
        ? context.l10n.updatedAtTime(time)
        : context.l10n.updatedAtTimeBy(time, updatedBy!);
  }
}
