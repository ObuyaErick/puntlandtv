import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n/l10n.dart';
import '../../core/theme/theme_context.dart';
import '../../core/theme/tokens.dart';
import '../core/providers/console_providers.dart';
import '../features/administration/presentation/pages/app_config_page.dart';
import '../features/administration/presentation/pages/users_page.dart';
import '../features/articles/presentation/pages/article_list_page.dart';
import '../features/auth/domain/entities/console_user.dart';
import '../features/auth/presentation/pages/sign_in_page.dart';
import '../features/media/presentation/pages/media_library_page.dart';
import '../features/operations/presentation/pages/categories_page.dart';
import '../features/operations/presentation/pages/live_control_page.dart';
import '../features/operations/presentation/pages/push_composer_page.dart';
import '../features/operations/presentation/pages/schedule_page.dart';
import '../features/overview/presentation/pages/overview_page.dart';
import '../features/programs/presentation/pages/episode_list_page.dart';
import '../features/programs/presentation/pages/programs_page.dart';
import 'console_navigation.dart';
import 'console_routes.dart';
import 'console_shell.dart';

/// The console's router.
///
/// Same shape as the app's: a `StatefulShellRoute.indexedStack` with one branch
/// per destination, so each section keeps its own navigator — the episode list
/// you were reading is still there when you come back from the media library —
/// and everything the console can show has a URL. That last part is not a
/// nicety on a tool that runs in a browser: "the programme I mean is
/// /programs/dood-furan" is how one editor hands a screen to another.
///
/// The guard that used to be a `switch` on [AuthState] in the root widget is
/// the [redirect] below. It answers two questions rather than one — signed in,
/// *and* allowed here — because a rail that hides a destination is presentation
/// only: typing `/users` into the address bar bypassed it.
final consoleRouterProvider = Provider<GoRouter>((ref) {
  assert(
    ConsoleRoutes.branches.length == consoleDestinations().length &&
        ConsoleRoutes.branches.indexed.every(
          (entry) => consoleDestinations()[entry.$1].route == entry.$2,
        ),
    'the rail and the shell branches must list the same destinations in the '
    'same order — they are matched by index',
  );

  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: ConsoleRoutes.overview,
    // Re-runs the redirect when somebody signs in, signs out, or has their
    // session restored. Without it the router would keep serving the sign-in
    // page to a user who has just authenticated.
    refreshListenable: refresh,
    redirect: (context, state) => _guard(ref, state),
    errorBuilder: (context, state) => _UnknownRoute(location: state.uri.path),
    routes: [
      // Above the shell: there is no rail to sign in to yet.
      GoRoute(
        path: ConsoleRoutes.signIn,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const SignInPage(),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => ConsoleShell(
          currentRoute: ConsoleRoutes.branches[shell.currentIndex],
          onNavigate: (route) => _goBranch(shell, route),
          child: shell,
        ),
        branches: [
          _branch(ConsoleRoutes.overview, const OverviewPage()),
          _branch(ConsoleRoutes.articles, const ArticleListPage()),
          _branch(
            ConsoleRoutes.programs,
            const ProgramsPage(),
            routes: [
              // One programme's episodes is a screen, not a destination — it
              // hangs off Programmes rather than earning a rail entry that
              // would mean nothing until you had already picked a show.
              GoRoute(
                path: ConsoleRoutes.programPattern,
                builder: (_, state) =>
                    EpisodeListPage(programId: state.pathParameters['id']!),
              ),
            ],
          ),
          _branch(ConsoleRoutes.live, const LiveControlPage()),
          _branch(ConsoleRoutes.schedule, const SchedulePage()),
          _branch(ConsoleRoutes.push, const PushComposerPage()),
          _branch(ConsoleRoutes.media, const MediaLibraryPage()),
          _branch(ConsoleRoutes.categories, const CategoriesPage()),
          _branch(ConsoleRoutes.users, const UsersPage()),
          _branch(ConsoleRoutes.config, const AppConfigPage()),
        ],
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});

StatefulShellBranch _branch(
  String path,
  Widget page, {
  List<RouteBase> routes = const [],
}) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: (_, _) => page, routes: routes)],
);

void _goBranch(StatefulNavigationShell shell, String route) {
  final index = ConsoleRoutes.branchOf(route);
  if (index < 0) return;

  // Tapping the destination you are already on pops it to its root — the
  // fastest way out of a programme's episodes, and the same behaviour the app's
  // tab bar has.
  shell.goBranch(index, initialLocation: index == shell.currentIndex);
}

/// Signed in, and allowed to be here.
String? _guard(Ref ref, GoRouterState state) {
  // [AuthState] itself rather than the `currentUserProvider` derived from it.
  // A sign-out re-runs this guard from inside the notification that announced
  // it, and a derived provider read at that moment still holds the value it
  // computed before — which is the signed-in user we are here to stop serving.
  final auth = ref.read(authControllerProvider);
  final user = auth is SignedIn ? auth.user : null;
  final location = state.matchedLocation;
  final atSignIn = location == ConsoleRoutes.signIn;

  if (user == null) return atSignIn ? null : ConsoleRoutes.signIn;
  if (atSignIn) return ConsoleRoutes.overview;

  // The capability the destination declares for the rail is the one the router
  // enforces, so the two cannot drift apart.
  final index = ConsoleRoutes.branchOf(location);
  if (index < 0) return null;

  final required = consoleDestinations()[index].requires;
  if (required != null && !user.can(required)) return ConsoleRoutes.overview;

  return null;
}

/// Bridges the auth state into something [GoRouter] can listen to.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
  }
}

/// A URL that matches nothing.
///
/// Deliberately says which one rather than bouncing to the overview: a stale
/// link in somebody's notes is worth seeing as broken.
class _UnknownRoute extends StatelessWidget {
  const _UnknownRoute({required this.location});

  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.emptyState),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.link_off_rounded,
                size: 34,
                color: context.scheme.onSurfaceVariant,
              ),
              const SizedBox(height: Spacing.listRhythm),
              Text(
                location,
                style: context.text.title.copyWith(
                  color: context.scheme.primary,
                ),
              ),
              const SizedBox(height: Spacing.listRhythm),
              FilledButton(
                onPressed: context.openOverview,
                child: Text(context.l10n.navOverview),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final _rootKey = GlobalKey<NavigatorState>();
