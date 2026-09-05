/// Every console route, in one place — the console's counterpart to
/// `app/router/route_paths.dart`.
///
/// The order of [branches] is load-bearing: it is the order of the rail's
/// destinations *and* the order of the router's shell branches, and the two
/// are matched by index. A destination added to one list and not the other is
/// caught by the assertion in `console_router.dart` rather than by an operator
/// landing on the wrong screen.
abstract final class ConsoleRoutes {
  static const signIn = '/sign-in';

  static const overview = '/overview';
  static const articles = '/articles';
  static const programs = '/programs';
  static const live = '/live';
  static const schedule = '/schedule';
  static const push = '/push';
  static const media = '/media';
  static const categories = '/categories';
  static const users = '/users';
  static const config = '/config';

  /// One entry per shell branch, in branch order.
  static const branches = <String>[
    overview,
    articles,
    programs,
    live,
    schedule,
    push,
    media,
    categories,
    users,
    config,
  ];

  /// One programme's episodes.
  static String program(String id) => '$programs/$id';

  /// Path pattern fragment used when registering the route.
  static const programPattern = ':id';

  /// The branch a location belongs to, or -1 for a location outside the shell.
  ///
  /// Matches on the whole first segment rather than `startsWith`, so a future
  /// `/media-library` cannot be mistaken for a child of `/media`.
  static int branchOf(String location) =>
      branches.indexWhere((r) => location == r || location.startsWith('$r/'));
}
