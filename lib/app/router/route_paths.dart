/// Every route in the app, in one place.
///
/// Named constants rather than string literals at call sites: push
/// notification deep-links are built from these, and a typo in a deep-link is
/// a bug that only shows up in production.
abstract final class Routes {
  static const news = '/news';
  static const live = '/live';
  static const programs = '/programs';
  static const radio = '/radio';
  static const saved = '/saved';
  static const settings = '/settings';

  static String article(String slug) => '$news/article/$slug';
  static String program(String id) => '$programs/$id';

  /// Path pattern fragments used when registering the routes.
  static const articlePattern = 'article/:slug';
  static const programPattern = ':id';
}
