import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../app/router/route_paths.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/theme_context.dart';
import '../../../../core/theme/tokens.dart';
import '../../../../core/widgets/feedback_views.dart';
import '../../../news/domain/entities/article.dart';
import '../../../news/presentation/widgets/article_card.dart';

/// Saved articles, readable with no connection.
///
/// Bookmarks are device-local — there are no accounts in the MVP — so this
/// screen never shows a network error. If the list is empty it is because
/// nothing was saved, not because something failed.
class SavedPage extends ConsumerStatefulWidget {
  const SavedPage({super.key});

  @override
  ConsumerState<SavedPage> createState() => _SavedPageState();
}

class _SavedPageState extends ConsumerState<SavedPage> {
  late Future<List<ArticleSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(bookmarkRepositoryProvider).saved();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final offline = ref.watch(isOfflineProvider);

    // Re-read whenever the saved set changes anywhere in the app.
    ref.listen(savedSlugsProvider, (_, _) {
      setState(() {
        _future = ref.read(bookmarkRepositoryProvider).saved();
      });
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.savedTitle)),
      body: FutureBuilder<List<ArticleSummary>>(
        future: _future,
        builder: (context, snapshot) {
          final items = snapshot.data ?? const <ArticleSummary>[];

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (items.isEmpty) {
            return EmptyView(
              title: l10n.emptySavedTitle,
              icon: Icons.bookmark_outline_rounded,
              actionLabel: l10n.browseNews,
              onAction: () => context.go(Routes.news),
            );
          }

          return Column(
            children: [
              if (offline)
                OfflineBanner(message: l10n.offlineShowingSaved(items.length)),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(Spacing.gutter),
                  itemCount: items.length + 1,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: Spacing.cardInternal),
                  itemBuilder: (context, index) {
                    if (index == items.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: Spacing.listRhythm),
                        child: Text(
                          l10n.savedRetentionNote,
                          style: context.text.meta.copyWith(
                            color: context.scheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }
                    final article = items[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ArticleCard(
                          article: article,
                          onTap: () =>
                              context.push(Routes.article(article.slug)),
                        ),
                        const SizedBox(height: 6),
                        _OfflineChip(hasImage: article.imageUrl != null),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OfflineChip extends StatelessWidget {
  const _OfflineChip({required this.hasImage});

  final bool hasImage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    // The MVP caches article text but not images, so a saved article is only
    // partly offline-complete. Saying so is better than a user discovering it
    // on a train with no signal.
    if (!hasImage) {
      return Text(
        l10n.textSavedImageOnline,
        style: context.text.meta.copyWith(
          color: context.scheme.onSurfaceVariant,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.colors.accentContainer,
        borderRadius: BorderRadius.circular(Radii.chip),
        border: Border.all(color: context.colors.accentContainerOutline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.offline_pin_outlined,
            size: 13,
            color: context.colors.onAccentContainer,
          ),
          const SizedBox(width: 6),
          Text(
            l10n.availableOffline,
            style: context.text.overline.copyWith(
              fontSize: 11,
              letterSpacing: 0.2,
              color: context.colors.onAccentContainer,
            ),
          ),
        ],
      ),
    );
  }
}
