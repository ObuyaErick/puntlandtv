// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article_list_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Which filter chip is active.

@ProviderFor(ArticleFilter)
final articleFilterProvider = ArticleFilterProvider._();

/// Which filter chip is active.
final class ArticleFilterProvider
    extends $NotifierProvider<ArticleFilter, ArticleStatusFilter> {
  /// Which filter chip is active.
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
  Override overrideWithValue(ArticleStatusFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ArticleStatusFilter>(value),
    );
  }
}

String _$articleFilterHash() => r'f9e797c75551c94e9093f0935831830cfad0be86';

/// Which filter chip is active.

abstract class _$ArticleFilter extends $Notifier<ArticleStatusFilter> {
  ArticleStatusFilter build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ArticleStatusFilter, ArticleStatusFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ArticleStatusFilter, ArticleStatusFilter>,
              ArticleStatusFilter,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

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

String _$articleListHash() => r'2dab8660ac12cf7412c4e4bb46ba4912f25b9608';

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

String _$articleCountsHash() => r'35f3c1bfaffe1386d5372c3955739c1a7a42d293';

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

String _$articleActionsHash() => r'f162ad3e7eb4444041f493a238f6bd00231cbc6b';

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
