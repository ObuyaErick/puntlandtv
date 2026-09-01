// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_library_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Which filter chip is active.

@ProviderFor(MediaFilter)
final mediaFilterProvider = MediaFilterProvider._();

/// Which filter chip is active.
final class MediaFilterProvider
    extends $NotifierProvider<MediaFilter, MediaKindFilter> {
  /// Which filter chip is active.
  MediaFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mediaFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaFilterHash();

  @$internal
  @override
  MediaFilter create() => MediaFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MediaKindFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MediaKindFilter>(value),
    );
  }
}

String _$mediaFilterHash() => r'642b2144e987c4d7c65fcb9ea5661efd73a3c194';

/// Which filter chip is active.

abstract class _$MediaFilter extends $Notifier<MediaKindFilter> {
  MediaKindFilter build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MediaKindFilter, MediaKindFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MediaKindFilter, MediaKindFilter>,
              MediaKindFilter,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The search box's contents.
///
/// Separate from [MediaFilter] because the two compose: "videos matching
/// 'dood'" is a normal thing to ask, and folding search into the filter enum
/// would make it impossible to express.
///
/// Named `MediaSearch` rather than the obvious `MediaQuery` — that name is
/// taken by a Flutter widget every screen in this codebase uses.

@ProviderFor(MediaSearch)
final mediaSearchProvider = MediaSearchProvider._();

/// The search box's contents.
///
/// Separate from [MediaFilter] because the two compose: "videos matching
/// 'dood'" is a normal thing to ask, and folding search into the filter enum
/// would make it impossible to express.
///
/// Named `MediaSearch` rather than the obvious `MediaQuery` — that name is
/// taken by a Flutter widget every screen in this codebase uses.
final class MediaSearchProvider extends $NotifierProvider<MediaSearch, String> {
  /// The search box's contents.
  ///
  /// Separate from [MediaFilter] because the two compose: "videos matching
  /// 'dood'" is a normal thing to ask, and folding search into the filter enum
  /// would make it impossible to express.
  ///
  /// Named `MediaSearch` rather than the obvious `MediaQuery` — that name is
  /// taken by a Flutter widget every screen in this codebase uses.
  MediaSearchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mediaSearchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaSearchHash();

  @$internal
  @override
  MediaSearch create() => MediaSearch();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$mediaSearchHash() => r'7c3a31abffb1d100e56778a4b501ab218cac6b73';

/// The search box's contents.
///
/// Separate from [MediaFilter] because the two compose: "videos matching
/// 'dood'" is a normal thing to ask, and folding search into the filter enum
/// would make it impossible to express.
///
/// Named `MediaSearch` rather than the obvious `MediaQuery` — that name is
/// taken by a Flutter widget every screen in this codebase uses.

abstract class _$MediaSearch extends $Notifier<String> {
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

/// Assets ticked for a bulk action.

@ProviderFor(MediaSelection)
final mediaSelectionProvider = MediaSelectionProvider._();

/// Assets ticked for a bulk action.
final class MediaSelectionProvider
    extends $NotifierProvider<MediaSelection, Set<String>> {
  /// Assets ticked for a bulk action.
  MediaSelectionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mediaSelectionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaSelectionHash();

  @$internal
  @override
  MediaSelection create() => MediaSelection();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Set<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Set<String>>(value),
    );
  }
}

String _$mediaSelectionHash() => r'dfc44e1a18409f405e091cf075e26a900f8b722e';

/// Assets ticked for a bulk action.

abstract class _$MediaSelection extends $Notifier<Set<String>> {
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

/// The grid's contents.

@ProviderFor(mediaLibrary)
final mediaLibraryProvider = MediaLibraryProvider._();

/// The grid's contents.

final class MediaLibraryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MediaAssetDto>>,
          List<MediaAssetDto>,
          FutureOr<List<MediaAssetDto>>
        >
    with
        $FutureModifier<List<MediaAssetDto>>,
        $FutureProvider<List<MediaAssetDto>> {
  /// The grid's contents.
  MediaLibraryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mediaLibraryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaLibraryHash();

  @$internal
  @override
  $FutureProviderElement<List<MediaAssetDto>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MediaAssetDto>> create(Ref ref) {
    return mediaLibrary(ref);
  }
}

String _$mediaLibraryHash() => r'73b725aaa49f3052d5c7626c6a7e5eeca201f84e';

/// Counts for the filter chips, independent of the active filter.
///
/// Fetches the unfiltered library rather than counting the filtered view — a
/// chip that reads 0 because its own filter is not selected is worse than no
/// count at all. The search box *does* narrow the counts, because a search is
/// the user asking about a subset.

@ProviderFor(mediaCounts)
final mediaCountsProvider = MediaCountsProvider._();

/// Counts for the filter chips, independent of the active filter.
///
/// Fetches the unfiltered library rather than counting the filtered view — a
/// chip that reads 0 because its own filter is not selected is worse than no
/// count at all. The search box *does* narrow the counts, because a search is
/// the user asking about a subset.

final class MediaCountsProvider
    extends
        $FunctionalProvider<
          AsyncValue<MediaCounts>,
          MediaCounts,
          FutureOr<MediaCounts>
        >
    with $FutureModifier<MediaCounts>, $FutureProvider<MediaCounts> {
  /// Counts for the filter chips, independent of the active filter.
  ///
  /// Fetches the unfiltered library rather than counting the filtered view — a
  /// chip that reads 0 because its own filter is not selected is worse than no
  /// count at all. The search box *does* narrow the counts, because a search is
  /// the user asking about a subset.
  MediaCountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mediaCountsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaCountsHash();

  @$internal
  @override
  $FutureProviderElement<MediaCounts> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MediaCounts> create(Ref ref) {
    return mediaCounts(ref);
  }
}

String _$mediaCountsHash() => r'80fe0050dd732ee5e5715c53130a83aaa073b4a6';

/// One asset, live. The detail panel watches this rather than holding the row
/// it was opened with, so a save is reflected without closing the panel.

@ProviderFor(mediaAsset)
final mediaAssetProvider = MediaAssetFamily._();

/// One asset, live. The detail panel watches this rather than holding the row
/// it was opened with, so a save is reflected without closing the panel.

final class MediaAssetProvider
    extends
        $FunctionalProvider<
          AsyncValue<MediaAssetDto>,
          MediaAssetDto,
          FutureOr<MediaAssetDto>
        >
    with $FutureModifier<MediaAssetDto>, $FutureProvider<MediaAssetDto> {
  /// One asset, live. The detail panel watches this rather than holding the row
  /// it was opened with, so a save is reflected without closing the panel.
  MediaAssetProvider._({
    required MediaAssetFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'mediaAssetProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$mediaAssetHash();

  @override
  String toString() {
    return r'mediaAssetProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<MediaAssetDto> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MediaAssetDto> create(Ref ref) {
    final argument = this.argument as String;
    return mediaAsset(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MediaAssetProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$mediaAssetHash() => r'629d7cea1679f1cb7dd616537ecf049bdab515e5';

/// One asset, live. The detail panel watches this rather than holding the row
/// it was opened with, so a save is reflected without closing the panel.

final class MediaAssetFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<MediaAssetDto>, String> {
  MediaAssetFamily._()
    : super(
        retry: null,
        name: r'mediaAssetProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One asset, live. The detail panel watches this rather than holding the row
  /// it was opened with, so a save is reflected without closing the panel.

  MediaAssetProvider call(String id) =>
      MediaAssetProvider._(argument: id, from: this);

  @override
  String toString() => r'mediaAssetProvider';
}

/// Writes against the library.
///
/// Every method invalidates the list *and* the counts: the "needs alt text"
/// chip is derived from the same rule the rows are, and letting the two drift
/// is how a newsroom stops trusting the number.
///
/// `keepAlive` is load-bearing rather than an optimisation. Nothing *watches*
/// an actions provider — a caller reads it, calls a method, and lets go — so
/// under auto-dispose the notifier is gone before the await returns and the
/// invalidation that follows throws on a disposed `Ref`. The visible symptom
/// is worse than the exception: the write lands and the grid never refreshes,
/// so the screen shows stale alt-text state for a file that has just been
/// described. Guarding on `ref.mounted` would swap the throw for exactly that
/// silence, which is why this is keep-alive instead.

@ProviderFor(MediaActions)
final mediaActionsProvider = MediaActionsProvider._();

/// Writes against the library.
///
/// Every method invalidates the list *and* the counts: the "needs alt text"
/// chip is derived from the same rule the rows are, and letting the two drift
/// is how a newsroom stops trusting the number.
///
/// `keepAlive` is load-bearing rather than an optimisation. Nothing *watches*
/// an actions provider — a caller reads it, calls a method, and lets go — so
/// under auto-dispose the notifier is gone before the await returns and the
/// invalidation that follows throws on a disposed `Ref`. The visible symptom
/// is worse than the exception: the write lands and the grid never refreshes,
/// so the screen shows stale alt-text state for a file that has just been
/// described. Guarding on `ref.mounted` would swap the throw for exactly that
/// silence, which is why this is keep-alive instead.
final class MediaActionsProvider extends $NotifierProvider<MediaActions, void> {
  /// Writes against the library.
  ///
  /// Every method invalidates the list *and* the counts: the "needs alt text"
  /// chip is derived from the same rule the rows are, and letting the two drift
  /// is how a newsroom stops trusting the number.
  ///
  /// `keepAlive` is load-bearing rather than an optimisation. Nothing *watches*
  /// an actions provider — a caller reads it, calls a method, and lets go — so
  /// under auto-dispose the notifier is gone before the await returns and the
  /// invalidation that follows throws on a disposed `Ref`. The visible symptom
  /// is worse than the exception: the write lands and the grid never refreshes,
  /// so the screen shows stale alt-text state for a file that has just been
  /// described. Guarding on `ref.mounted` would swap the throw for exactly that
  /// silence, which is why this is keep-alive instead.
  MediaActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mediaActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mediaActionsHash();

  @$internal
  @override
  MediaActions create() => MediaActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$mediaActionsHash() => r'4e64e8ceab29a9e47837169828b1e9e03c17917e';

/// Writes against the library.
///
/// Every method invalidates the list *and* the counts: the "needs alt text"
/// chip is derived from the same rule the rows are, and letting the two drift
/// is how a newsroom stops trusting the number.
///
/// `keepAlive` is load-bearing rather than an optimisation. Nothing *watches*
/// an actions provider — a caller reads it, calls a method, and lets go — so
/// under auto-dispose the notifier is gone before the await returns and the
/// invalidation that follows throws on a disposed `Ref`. The visible symptom
/// is worse than the exception: the write lands and the grid never refreshes,
/// so the screen shows stale alt-text state for a file that has just been
/// described. Guarding on `ref.mounted` would swap the throw for exactly that
/// silence, which is why this is keep-alive instead.

abstract class _$MediaActions extends $Notifier<void> {
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
