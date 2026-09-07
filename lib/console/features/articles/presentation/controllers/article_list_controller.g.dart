// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article_list_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The active filters.
///
/// Each setter builds the whole value rather than going through a `copyWith`:
/// every narrowing field is nullable and null is meaningful, so a copyWith
/// could not tell "leave this alone" from "clear this".

@ProviderFor(ArticleFilter)
final articleFilterProvider = ArticleFilterProvider._();

/// The active filters.
///
/// Each setter builds the whole value rather than going through a `copyWith`:
/// every narrowing field is nullable and null is meaningful, so a copyWith
/// could not tell "leave this alone" from "clear this".
final class ArticleFilterProvider
    extends $NotifierProvider<ArticleFilter, ArticleQuery> {
  /// The active filters.
  ///
  /// Each setter builds the whole value rather than going through a `copyWith`:
  /// every narrowing field is nullable and null is meaningful, so a copyWith
  /// could not tell "leave this alone" from "clear this".
  ArticleFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'articleFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$articleFilterHash();

  @$internal
  @override
  ArticleFilter create() => ArticleFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ArticleQuery value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ArticleQuery>(value),
    );
  }
}

String _$articleFilterHash() => r'61d1b8ee56d7ff8fe0e0f33b8c78f766e823b9e8';

/// The active filters.
///
/// Each setter builds the whole value rather than going through a `copyWith`:
/// every narrowing field is nullable and null is meaningful, so a copyWith
/// could not tell "leave this alone" from "clear this".

abstract class _$ArticleFilter extends $Notifier<ArticleQuery> {
  ArticleQuery build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ArticleQuery, ArticleQuery>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ArticleQuery, ArticleQuery>,
              ArticleQuery,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Staff as bylines, for the author filter.

@ProviderFor(articleAuthors)
final articleAuthorsProvider = ArticleAuthorsProvider._();

/// Staff as bylines, for the author filter.

final class ArticleAuthorsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ConsoleUser>>,
          List<ConsoleUser>,
          FutureOr<List<ConsoleUser>>
        >
    with
        $FutureModifier<List<ConsoleUser>>,
        $FutureProvider<List<ConsoleUser>> {
  /// Staff as bylines, for the author filter.
  ArticleAuthorsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'articleAuthorsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$articleAuthorsHash();

  @$internal
  @override
  $FutureProviderElement<List<ConsoleUser>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ConsoleUser>> create(Ref ref) {
    return articleAuthors(ref);
  }
}

String _$articleAuthorsHash() => r'214fb45a2b7f50877fb5a562cbbb671848d6a0c2';

/// Rows currently ticked, for the bulk action bar.

@ProviderFor(ArticleSelection)
final articleSelectionProvider = ArticleSelectionProvider._();

/// Rows currently ticked, for the bulk action bar.
final class ArticleSelectionProvider
    extends $NotifierProvider<ArticleSelection, Set<String>> {
  /// Rows currently ticked, for the bulk action bar.
  ArticleSelectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'articleSelectionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$articleSelectionHash();

  @$internal
  @override
  ArticleSelection create() => ArticleSelection();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$articleSelectionHash() => r'5679553b1b0dbbb8e03293f938c71958fba68e88';

/// Rows currently ticked, for the bulk action bar.

abstract class _$ArticleSelection extends $Notifier<Set<String>> {
  Set<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Set<String>, Set<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Set<String>, Set<String>>,
              Set<String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The article list, scoped to what the signed-in user may see.
///
/// A Journalist cannot publish, so showing them everyone's queue would be
/// noise they cannot act on — the list is scoped to their own work at the
/// source rather than filtered in the widget.

@ProviderFor(articleList)
final articleListProvider = ArticleListProvider._();

/// The article list, scoped to what the signed-in user may see.
///
/// A Journalist cannot publish, so showing them everyone's queue would be
/// noise they cannot act on — the list is scoped to their own work at the
/// source rather than filtered in the widget.

final class ArticleListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AdminArticleDto>>,
          List<AdminArticleDto>,
          FutureOr<List<AdminArticleDto>>
        >
    with
        $FutureModifier<List<AdminArticleDto>>,
        $FutureProvider<List<AdminArticleDto>> {
  /// The article list, scoped to what the signed-in user may see.
  ///
  /// A Journalist cannot publish, so showing them everyone's queue would be
  /// noise they cannot act on — the list is scoped to their own work at the
  /// source rather than filtered in the widget.
  ArticleListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'articleListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$articleListHash();

  @$internal
  @override
  $FutureProviderElement<List<AdminArticleDto>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AdminArticleDto>> create(Ref ref) {
    return articleList(ref);
  }
}

String _$articleListHash() => r'97e0a5d43e21fcc984f96c59f23ff4be51746d54';

/// Counts for the filter chips, independent of the active filter — the chips
/// have to keep showing the other totals while one is selected.

@ProviderFor(articleCounts)
final articleCountsProvider = ArticleCountsProvider._();

/// Counts for the filter chips, independent of the active filter — the chips
/// have to keep showing the other totals while one is selected.

final class ArticleCountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<ArticleCounts>,
          ArticleCounts,
          FutureOr<ArticleCounts>
        >
    with $FutureModifier<ArticleCounts>, $FutureProvider<ArticleCounts> {
  /// Counts for the filter chips, independent of the active filter — the chips
  /// have to keep showing the other totals while one is selected.
  ArticleCountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'articleCountsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$articleCountsHash();

  @$internal
  @override
  $FutureProviderElement<ArticleCounts> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ArticleCounts> create(Ref ref) {
    return articleCounts(ref);
  }
}

String _$articleCountsHash() => r'7fc84a3010c19d12362d98185e824c07f8d861ea';

/// Bulk and single-row actions.
///
/// `keepAlive` for the same reason the media library's actions provider needs
/// it: nothing watches an actions provider, so under auto-dispose the notifier is disposed before the
/// awaited write returns and the invalidation that follows throws on a dead
/// `Ref` — leaving the list showing the state the article was in before the
/// publish it just performed.

@ProviderFor(ArticleActions)
final articleActionsProvider = ArticleActionsProvider._();

/// Bulk and single-row actions.
///
/// `keepAlive` for the same reason the media library's actions provider needs
/// it: nothing watches an actions provider, so under auto-dispose the notifier is disposed before the
/// awaited write returns and the invalidation that follows throws on a dead
/// `Ref` — leaving the list showing the state the article was in before the
/// publish it just performed.
final class ArticleActionsProvider
    extends $NotifierProvider<ArticleActions, void> {
  /// Bulk and single-row actions.
  ///
  /// `keepAlive` for the same reason the media library's actions provider needs
  /// it: nothing watches an actions provider, so under auto-dispose the notifier is disposed before the
  /// awaited write returns and the invalidation that follows throws on a dead
  /// `Ref` — leaving the list showing the state the article was in before the
  /// publish it just performed.
  ArticleActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'articleActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$articleActionsHash();

  @$internal
  @override
  ArticleActions create() => ArticleActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$articleActionsHash() => r'cd087d115fb6c2a0a3122d6ce61768bb5d927468';

/// Bulk and single-row actions.
///
/// `keepAlive` for the same reason the media library's actions provider needs
/// it: nothing watches an actions provider, so under auto-dispose the notifier is disposed before the
/// awaited write returns and the invalidation that follows throws on a dead
/// `Ref` — leaving the list showing the state the article was in before the
/// publish it just performed.

abstract class _$ArticleActions extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
