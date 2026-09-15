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

  /// One channel's player. [live] and [radio] are the channel lists.
  static String liveChannel(String key) => '$live/$key';
  static String radioChannel(String key) => '$radio/$key';

  /// Path pattern fragments used when registering the routes.
  static const articlePattern = 'article/:slug';
  static const programPattern = ':id';

  /// Shared by the Live TV and Radio branches: in both, the child of the list
  /// is one channel, named by its permanent key.
  static const channelPattern = ':channelKey';
}
