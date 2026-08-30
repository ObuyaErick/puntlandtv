import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/l10n/app_date_format.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/feedback_views.dart';
import '../../../../core/widgets/remote_image.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../domain/entities/article.dart';
import '../controllers/news_controllers.dart';
import '../widgets/article_card.dart';

class ArticlePage extends ConsumerWidget {
  const ArticlePage({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final article = ref.watch(articleDetailProvider(slug));

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        actions: [
          _SaveAction(slug: slug),
          const SizedBox(width: Spacing.chip),
        ],
      ),
      body: article.when(
        loading: () => const _ArticleSkeleton(),
        error: (error, _) => ErrorView(
          failure: error is Failure
              ? error
              : const Failure(kind: FailureKind.unknown, code: 'UNKNOWN'),
          onRetry: () => ref.invalidate(articleDetailProvider(slug)),
        ),
        data: (data) => _ArticleBody(article: data),
      ),
    );
  }
}

class _ArticleBody extends ConsumerWidget {
  const _ArticleBody({required this.article});

  final Article article;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final summary = article.summary;

    return ListView(
      padding: const EdgeInsets.only(bottom: Spacing.emptyState),
      children: [
        if (summary.imageUrl != null) ...[
          RemoteImage(
            url: summary.imageUrl,
            height: 220,
            width: double.infinity,
          ),
          if (article.imageCaption != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.gutter,
                Spacing.chip,
                Spacing.gutter,
                0,
              ),
              child: Text(
                article.imageCaption!,
                style: context.text.meta.copyWith(
                  color: context.scheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.gutter,
            Spacing.gutter,
            Spacing.gutter,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${summary.categoryName.toUpperCase()} · '
                        '${summary.excerpt != null ? '' : ''}'
                        '${l10n.minRead(summary.readingMinutes ?? 3)}'
                    .toUpperCase(),
                style: context.text.overline.copyWith(
                  color: context.colors.accent,
                ),
              ),
              const SizedBox(height: Spacing.cardInternal),

              // The article renders in its own language, whatever the UI is
              // set to. A Somali story in an English shell must still get
              // Somali font resolution and screen-reader pronunciation.
              Localizations.override(
                context: context,
                locale: Locale(summary.contentLanguage),
                child: Builder(
                  builder: (context) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        summary.title,
                        style: context.text.headline.copyWith(
                          color: context.scheme.primary,
                        ),
                      ),
                      if (summary.excerpt != null) ...[
                        const SizedBox(height: Spacing.cardInternal),
                        Text(
                          summary.excerpt!,
                          style: context.text.bodyLarge.copyWith(
                            color: context.scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: Spacing.listRhythm),
              Row(
                children: [
                  if (article.author != null) ...[
                    Text(
                      article.author!,
                      style: context.text.label.copyWith(
                        color: context.scheme.primary,
                      ),
                    ),
                    const SizedBox(width: Spacing.chip),
                  ],
                  Expanded(
                    child: Text(
                      AppDateFormat.byline(
                        summary.publishedAt,
                        context.languageCode,
                      ),
                      style: context.text.meta.copyWith(
                        color: context.scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: Spacing.sectionBreak * 2),

              // The CMS is responsible for sanitising this. The app renders
              // what it is given and does not police it — see the API contract
              // in docs/puntland_tv_mvp_plan.md §6.
              HtmlWidget(
                article.bodyHtml,
                textStyle: context.text.bodyLarge.copyWith(
                  color: context.scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        if (article.relatedSlugs.isNotEmpty)
          _Related(slugs: article.relatedSlugs, category: summary.categoryName),
      ],
    );
  }
}

class _Related extends ConsumerWidget {
  const _Related({required this.slugs, required this.category});

  final List<String> slugs;
  final String category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final related = ref.watch(relatedArticlesProvider(slugs));

    return related.maybeWhen(
      orElse: () => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.gutter,
            Spacing.sectionBreak * 1.5,
            Spacing.gutter,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.relatedStories,
                style: context.text.overline.copyWith(
                  color: context.scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Spacing.listRhythm),
              for (final article in items) ...[
                ArticleCard(
                  article: article,
                  onTap: () => context.push(Routes.article(article.slug)),
                ),
                const SizedBox(height: Spacing.cardInternal),
              ],
              const SizedBox(height: Spacing.chip),
              TextButton(
                onPressed: () {},
                child: Text(l10n.moreFrom(category)),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Bookmark toggle. Saves the full body so the article is readable offline —
/// saving only the summary would make the feature a lie.
class _SaveAction extends ConsumerWidget {
  const _SaveAction({required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final saved =
        ref.watch(savedSlugsProvider).value ??
        ref.read(bookmarkRepositoryProvider).savedSlugs;
    final isSaved = saved.contains(slug);
    final article = ref.watch(articleDetailProvider(slug)).value;

    return IconButton(
      tooltip: isSaved ? l10n.a11yBookmarkRemove : l10n.a11yBookmarkAdd,
      constraints: const BoxConstraints.tightFor(
        width: kMinTapTarget,
        height: kMinTapTarget,
      ),
      onPressed: article == null
          ? null
          : () {
              final repo = ref.read(bookmarkRepositoryProvider);
              if (isSaved) {
                repo.remove(slug);
              } else {
                repo.save(article);
              }
            },
      icon: Icon(
        isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
        color: isSaved ? context.colors.accent : context.scheme.primary,
      ),
    );
  }
}

class _ArticleSkeleton extends StatelessWidget {
  const _ArticleSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(Spacing.gutter),
      children: const [
        SkeletonBox(height: 220, radius: Radii.card),
        SizedBox(height: Spacing.gutter),
        SkeletonBox(width: 140, height: 10),
        SizedBox(height: Spacing.listRhythm),
        SkeletonBox(height: 26),
        SizedBox(height: 10),
        SkeletonBox(height: 26),
        SizedBox(height: Spacing.sectionBreak),
        SkeletonBox(height: 15),
        SizedBox(height: 10),
        SkeletonBox(height: 15),
        SizedBox(height: 10),
        SkeletonBox(height: 15),
      ],
    );
  }
}
