import 'package:material_ui/material_ui.dart';

import '../../../../../core/l10n/app_date_format.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../core/admin_api/dto/admin_article_dto.dart';
import '../../../../core/localised.dart';
import '../../../../core/widgets/status_badge.dart';

/// The compact-width presentation of an article row.
///
/// Same information as the table, arranged so it survives 390dp: status and
/// time on one line, headline below, metadata last.
class ArticleRowCard extends StatelessWidget {
  const ArticleRowCard({
    super.key,
    required this.article,
    required this.categoryName,
    this.showAuthor = true,
    this.onTap,
  });

  final AdminArticleDto article;

  /// Already resolved to the active locale by the caller.
  final String categoryName;

  final bool showAuthor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.languageCode;
    final shown = article.translationFor(locale);

    return Material(
      color: context.scheme.surface,
      borderRadius: Radii.cardBorder,
      child: InkWell(
        onTap: onTap,
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
                children: [
                  StatusBadge.forArticle(article.status),
                  if (article.isBreaking) ...[
                    const SizedBox(width: Spacing.chip),
                    const StatusBadge(kind: BadgeKind.breaking),
                  ],
                  const Spacer(),
                  Text(
                    AppDateFormat.time(article.updatedAt, context.languageCode),
                    style: context.text.meta.copyWith(
                      color: context.scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Spacing.cardInternal),
              Text(
                shown?.title ?? '',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: context.text.cardTitle.copyWith(
                  color: context.scheme.primary,
                ),
              ),
              const SizedBox(height: Spacing.chip),
              Row(
                children: [
                  // No locale chips: which languages a row exists in is a
                  // technical field. A missing translation is said in words,
                  // because that is the part an editor can act on.
                  Expanded(
                    child: Text(
                      [
                        categoryName,
                        if (showAuthor) article.authorName,
                        for (final missing in article.missingLocales(const [
                          'so',
                          'en',
                        ]))
                          l10n.missingTranslation(
                            context.languageNameOf(missing),
                          ),
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.meta.copyWith(
                        color: context.scheme.onSurfaceVariant,
                      ),
                    ),
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
