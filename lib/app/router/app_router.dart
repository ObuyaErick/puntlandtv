import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/news/presentation/pages/article_page.dart';
import '../../features/news/presentation/pages/news_feed_page.dart';
import '../../features/bookmarks/presentation/pages/saved_page.dart';
import '../../features/live/presentation/pages/live_page.dart';
import '../../features/radio/presentation/pages/radio_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/vod/presentation/pages/program_detail_page.dart';
import '../../features/vod/presentation/pages/programs_page.dart';
import '../shell/app_shell.dart';
import 'route_paths.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.news,
    routes: [
      // One branch per tab. `StatefulShellRoute` keeps each branch's navigator
      // alive, so scroll position and loaded pages survive tab switches — and
      // the shell itself hosts the mini-player, which is why playback survives
      // navigation too.
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.news,
                builder: (_, _) => const NewsFeedPage(),
                routes: [
                  GoRoute(
                    path: Routes.articlePattern,
                    builder: (_, state) =>
                        ArticlePage(slug: state.pathParameters['slug']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: Routes.live, builder: (_, _) => const LivePage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.programs,
                builder: (_, _) => const ProgramsPage(),
                routes: [
                  GoRoute(
                    path: Routes.programPattern,
                    builder: (_, state) => ProgramDetailPage(
                      programId: state.pathParameters['id']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: Routes.radio, builder: (_, _) => const RadioPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: Routes.saved, builder: (_, _) => const SavedPage()),
            ],
          ),
        ],
      ),

      // Settings sits above the shell: it is a destination, not a tab, and it
      // should cover the mini-player rather than dock beside it.
      GoRoute(
        path: Routes.settings,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const SettingsPage(),
      ),
    ],
    navigatorKey: _rootKey,
  );
});

final _rootKey = GlobalKey<NavigatorState>();
