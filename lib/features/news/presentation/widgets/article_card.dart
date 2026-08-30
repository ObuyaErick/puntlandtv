import 'package:material_ui/material_ui.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/remote_image.dart';
import '../../domain/entities/article.dart';

/// Formats "DALKA · 22 MIN" — the category overline with a relative time.
///
/// Uses the app's own plural messages rather than `intl`'s relative-time
/// formatting, because `intl` has no Somali data at all.
String categoryOverline(BuildContext context, ArticleSummary article) {
  final l10n = context.l10n;
  final elapsed = DateTime.now().difference(article.publishedAt);
  final relative = elapsed.inMinutes < 60
      ? l10n.minutesAgo(elapsed.inMinutes.clamp(1, 59))
      : l10n.hoursAgo(elapsed.inHours.clamp(1, 99));
  return '${article.categoryName.toUpperCase()} · $relative';
}

/// The standard feed row: 104×78 thumbnail, overline, serif headline.
class ArticleCard extends StatelessWidget {
  const ArticleCard({super.key, required this.article, required this.onTap});

  final ArticleSummary article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.scheme.surface,
      borderRadius: Radii.cardBorder,
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.cardBorder,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: Radii.cardBorder,
            border: Border.all(color: context.colors.outline),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RemoteImage(
                url: article.imageUrl,
                width: 104,
                height: 78,
                borderRadius: Radii.thumbBorder,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryOverline(context, article),
                      style: context.text.overline.copyWith(
                        color: context.colors.accent,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // The article's own language, not the UI's — so Somali
                    // text in an English shell still gets the right font
                    // resolution and screen-reader pronunciation.
                    Localizations.override(
                      context: context,
                      locale: Locale(article.contentLanguage),
                      child: Builder(
                        builder: (context) => Text(
                          article.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.cardTitle.copyWith(
                            color: context.scheme.primary,
                          ),
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

/// The lead story: full-bleed image, LEAD STORY overline, 26px headline,
/// excerpt. One per feed, at the top.
class LeadStoryCard extends StatelessWidget {
  const LeadStoryCard({super.key, required this.article, required this.onTap});

  final ArticleSummary article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Material(
      color: context.scheme.surface,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                RemoteImage(
                  url: article.imageUrl,
                  height: 206,
                  width: double.infinity,
                ),
                Positioned(
                  left: Spacing.cardInternal,
                  top: Spacing.cardInternal,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: context.scheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      l10n.leadStory,
                      style: context.text.overline.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.gutter,
                Spacing.listRhythm,
                Spacing.gutter,
                Spacing.gutter,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryOverline(context, article),
                    style: context.text.overline.copyWith(
                      color: context.colors.accent,
                    ),
                  ),
                  const SizedBox(height: Spacing.chip),
                  Localizations.override(
                    context: context,
                    locale: Locale(article.contentLanguage),
                    child: Builder(
                      builder: (context) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            article.title,
                            style: context.text.headline.copyWith(
                              color: context.scheme.primary,
                            ),
                          ),
                          if (article.excerpt != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              article.excerpt!,
                              style: context.text.body.copyWith(
                                color: context.scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
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
  }
}
