import 'package:material_ui/material_ui.dart';

import '../../../../../core/l10n/app_date_format.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../core/localised.dart';
import '../../../../core/admin_api/dto/admin_article_dto.dart';

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
    required this.article,
    required this.onReconfirm,
    required this.onOpenSideBySide,
  });

  final AdminArticleDto article;
  final ValueChanged<String> onReconfirm;
  final ValueChanged<String> onOpenSideBySide;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final stale = article.staleLocales;
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: context.scheme.errorContainer,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: context.colors.errorContainerOutline,
                  ),
                ),
                child: Text(
                  l10n.translationBehindBy(stale.length),
                  style: context.text.overline.copyWith(
                    fontSize: 9.5,
                    color: context.scheme.error,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: Spacing.cardInternal),
        for (final locale in article.locales)
          _TranslationRow(
            locale: locale,
            languageName: context.languageNameOf(locale),
            isSource: locale == article.sourceLocale,
            isStale: stale.contains(locale),
            translation: article.translations[locale]!,
            sourceUpdatedAt: source?.updatedAt,
            onReconfirm: () => onReconfirm(locale),
            onOpen: () => onOpenSideBySide(locale),
          ),
        if (stale.isNotEmpty) ...[
          const SizedBox(height: Spacing.cardInternal),
          Text(
            l10n.translationStaleNote,
            style: context.text.meta.copyWith(
              color: context.scheme.onSurfaceVariant,
            ),
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
    required this.translation,
    required this.sourceUpdatedAt,
    required this.onReconfirm,
    required this.onOpen,
  });

  final String locale;
  final String languageName;
  final bool isSource;
  final bool isStale;
  final ArticleTranslationDto translation;
  final DateTime? sourceUpdatedAt;
  final VoidCallback onReconfirm;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Container(
      margin: const EdgeInsets.only(bottom: Spacing.chip),
      padding: const EdgeInsets.all(Spacing.cardInternal),
      decoration: BoxDecoration(
        color: isStale ? context.scheme.errorContainer : null,
        borderRadius: Radii.cardBorder,
        border: Border.all(
          color: isStale
              ? context.colors.errorContainerOutline
              : context.colors.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: context.colors.skeleton,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  locale.toUpperCase(),
                  style: context.text.overline.copyWith(
                    fontSize: 9.5,
                    color: context.scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: Spacing.chip),
              Expanded(
                child: Text(
                  isSource
                      ? l10n.translationSource(languageName)
                      : l10n.translationLinked(languageName),
                  style: context.text.label.copyWith(
                    color: context.scheme.primary,
                  ),
                ),
              ),
              if (!isStale)
                Text(
                  l10n.translationCurrent,
                  style: context.text.meta.copyWith(
                    color: context.colors.accent,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${AppDateFormat.byline(translation.updatedAt, context.languageCode)}'
            '${translation.updatedBy != null ? ' · ${translation.updatedBy}' : ''}',
            style: context.text.meta.copyWith(
              color: context.scheme.onSurfaceVariant,
            ),
          ),
          if (isStale) ...[
            const SizedBox(height: Spacing.chip),
            Wrap(
              spacing: Spacing.chip,
              children: [
                OutlinedButton(
                  onPressed: onReconfirm,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                  ),
                  child: Text(l10n.reconfirmTranslation),
                ),
                TextButton(
                  onPressed: onOpen,
                  style: TextButton.styleFrom(minimumSize: const Size(0, 36)),
                  child: Text(l10n.openSideBySide),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
