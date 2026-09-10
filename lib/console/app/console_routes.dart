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
    users,
    config,
  ];

  /// One programme's episodes.
  static String program(String id) => '$programs/$id';

  /// One article, open in the editor.
  ///
  /// A URL rather than a modal, because "the story I mean is
  /// /articles/a-rains" is how one editor hands work to another — and because
  /// a reload in the middle of writing has to come back to the same story.
  static String article(String id) => '$articles/$id';

  /// The taxonomy articles are filed under.
  ///
  /// A screen inside Articles rather than a branch of its own: categories
  /// exist to organise stories, and managing them is a step in the newsroom's
  /// flow — "this needs a section we do not have yet" — not a separate
  /// destination. Keeping it in the branch keeps the rail on Articles while it
  /// is open.
  static const categories = '$articles/$categoriesPattern';

  /// Path pattern fragments used when registering the child routes.
  static const programPattern = ':id';
  static const articlePattern = ':id';

  /// A literal segment, so it has to be registered ahead of [articlePattern] —
  /// the router matches in order, and `:id` would otherwise take it as an
  /// article called "categories".
  static const categoriesPattern = 'categories';

  /// The branch a location belongs to, or -1 for a location outside the shell.
  ///
  /// Matches on the whole first segment rather than `startsWith`, so a future
  /// `/media-library` cannot be mistaken for a child of `/media`.
  static int branchOf(String location) =>
      branches.indexWhere((r) => location == r || location.startsWith('$r/'));
}
