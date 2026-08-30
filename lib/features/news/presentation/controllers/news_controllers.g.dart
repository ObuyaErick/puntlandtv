// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news_controllers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The category tabs. Cached for the session — categories change on the scale
/// of months, and re-fetching them on every tab switch wastes a request on a
/// metered connection.

@ProviderFor(categories)
final categoriesProvider = CategoriesProvider._();

/// The category tabs. Cached for the session — categories change on the scale
/// of months, and re-fetching them on every tab switch wastes a request on a
/// metered connection.

final class CategoriesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<NewsCategory>>,
          List<NewsCategory>,
          FutureOr<List<NewsCategory>>
        >
    with
        $FutureModifier<List<NewsCategory>>,
        $FutureProvider<List<NewsCategory>> {
  /// The category tabs. Cached for the session — categories change on the scale
  /// of months, and re-fetching them on every tab switch wastes a request on a
  /// metered connection.
  CategoriesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoriesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoriesHash();

  @$internal
  @override
  $FutureProviderElement<List<NewsCategory>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<NewsCategory>> create(Ref ref) {
    return categories(ref);
  }
}

String _$categoriesHash() => r'4f3378d48676ea72ccf5e54d976f56c6285fce18';

/// Which tab is selected. Held above the feed so switching tabs does not
/// rebuild the controller for the tab you left.

@ProviderFor(SelectedCategory)
final selectedCategoryProvider = SelectedCategoryProvider._();

/// Which tab is selected. Held above the feed so switching tabs does not
/// rebuild the controller for the tab you left.
final class SelectedCategoryProvider
    extends $NotifierProvider<SelectedCategory, String> {
  /// Which tab is selected. Held above the feed so switching tabs does not
  /// rebuild the controller for the tab you left.
  SelectedCategoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedCategoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedCategoryHash();

  @$internal
  @override
  SelectedCategory create() => SelectedCategory();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$selectedCategoryHash() => r'3a1a2a91e3b8533cbefca8b758d302dfd7aae0f9';

/// Which tab is selected. Held above the feed so switching tabs does not
/// rebuild the controller for the tab you left.

abstract class _$SelectedCategory extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// One category's feed, with cursor pagination.
///
/// Note what this class does *not* contain: no HTTP, no JSON, no status codes.
/// It asks a `NewsRepository` for a [Page] and holds the result — it would work
/// unchanged against a local database.

@ProviderFor(Feed)
final feedProvider = FeedFamily._();

/// One category's feed, with cursor pagination.
///
/// Note what this class does *not* contain: no HTTP, no JSON, no status codes.
/// It asks a `NewsRepository` for a [Page] and holds the result — it would work
/// unchanged against a local database.
final class FeedProvider extends $AsyncNotifierProvider<Feed, FeedState> {
  /// One category's feed, with cursor pagination.
  ///
  /// Note what this class does *not* contain: no HTTP, no JSON, no status codes.
  /// It asks a `NewsRepository` for a [Page] and holds the result — it would work
  /// unchanged against a local database.
  FeedProvider._({
    required FeedFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'feedProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$feedHash();

  @override
  String toString() {
    return r'feedProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  Feed create() => Feed();

  @override
  bool operator ==(Object other) {
    return other is FeedProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$feedHash() => r'8225f3eefe1e9f8273302edc4732c8afddec37cd';

/// One category's feed, with cursor pagination.
///
/// Note what this class does *not* contain: no HTTP, no JSON, no status codes.
/// It asks a `NewsRepository` for a [Page] and holds the result — it would work
/// unchanged against a local database.

final class FeedFamily extends $Family
    with
        $ClassFamilyOverride<
          Feed,
          AsyncValue<FeedState>,
          FeedState,
          FutureOr<FeedState>,
          String
        > {
  FeedFamily._()
    : super(
        retry: null,
        name: r'feedProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One category's feed, with cursor pagination.
  ///
  /// Note what this class does *not* contain: no HTTP, no JSON, no status codes.
  /// It asks a `NewsRepository` for a [Page] and holds the result — it would work
  /// unchanged against a local database.

  FeedProvider call(String categorySlug) =>
      FeedProvider._(argument: categorySlug, from: this);

  @override
  String toString() => r'feedProvider';
}

/// One category's feed, with cursor pagination.
///
/// Note what this class does *not* contain: no HTTP, no JSON, no status codes.
/// It asks a `NewsRepository` for a [Page] and holds the result — it would work
/// unchanged against a local database.

abstract class _$Feed extends $AsyncNotifier<FeedState> {
  late final _$args = ref.$arg as String;
  String get categorySlug => _$args;

  FutureOr<FeedState> build(String categorySlug);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<FeedState>, FeedState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<FeedState>, FeedState>,
              AsyncValue<FeedState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// A single article, falling back to the bookmarked copy when the network
/// fails — which is what makes "save for offline" work at the point of use
/// rather than only on the saved list.

@ProviderFor(articleDetail)
final articleDetailProvider = ArticleDetailFamily._();

/// A single article, falling back to the bookmarked copy when the network
/// fails — which is what makes "save for offline" work at the point of use
/// rather than only on the saved list.

final class ArticleDetailProvider
    extends $FunctionalProvider<AsyncValue<Article>, Article, FutureOr<Article>>
    with $FutureModifier<Article>, $FutureProvider<Article> {
  /// A single article, falling back to the bookmarked copy when the network
  /// fails — which is what makes "save for offline" work at the point of use
  /// rather than only on the saved list.
  ArticleDetailProvider._({
    required ArticleDetailFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'articleDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$articleDetailHash();

  @override
  String toString() {
    return r'articleDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Article> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Article> create(Ref ref) {
    final argument = this.argument as String;
    return articleDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ArticleDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$articleDetailHash() => r'c88f9bba66451c1caec72b9e15ad26b7cdf9233e';

/// A single article, falling back to the bookmarked copy when the network
/// fails — which is what makes "save for offline" work at the point of use
/// rather than only on the saved list.

final class ArticleDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Article>, String> {
  ArticleDetailFamily._()
    : super(
        retry: null,
        name: r'articleDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// A single article, falling back to the bookmarked copy when the network
  /// fails — which is what makes "save for offline" work at the point of use
  /// rather than only on the saved list.

  ArticleDetailProvider call(String slug) =>
      ArticleDetailProvider._(argument: slug, from: this);

  @override
  String toString() => r'articleDetailProvider';
}

@ProviderFor(relatedArticles)
final relatedArticlesProvider = RelatedArticlesFamily._();

final class RelatedArticlesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ArticleSummary>>,
          List<ArticleSummary>,
          FutureOr<List<ArticleSummary>>
        >
    with
        $FutureModifier<List<ArticleSummary>>,
        $FutureProvider<List<ArticleSummary>> {
  RelatedArticlesProvider._({
    required RelatedArticlesFamily super.from,
    required List<String> super.argument,
  }) : super(
         retry: null,
         name: r'relatedArticlesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$relatedArticlesHash();

  @override
  String toString() {
    return r'relatedArticlesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ArticleSummary>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ArticleSummary>> create(Ref ref) {
    final argument = this.argument as List<String>;
    return relatedArticles(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RelatedArticlesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$relatedArticlesHash() => r'29b8f912848390a57138f020e413a83d76ab3d90';

final class RelatedArticlesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<ArticleSummary>>,
          List<String>
        > {
  RelatedArticlesFamily._()
    : super(
        retry: null,
        name: r'relatedArticlesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  RelatedArticlesProvider call(List<String> slugs) =>
      RelatedArticlesProvider._(argument: slugs, from: this);

  @override
  String toString() => r'relatedArticlesProvider';
}
