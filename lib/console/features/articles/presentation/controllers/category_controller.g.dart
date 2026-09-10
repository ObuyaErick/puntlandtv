// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'category_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The taxonomy, as the console sees it: every locale's name, plus counts.
///
/// `keepAlive` because the article list and the publishing panel `read` it for
/// their category pickers without watching it, and an auto-disposed provider
/// would hand them an empty list every time.

@ProviderFor(categoryConfig)
final categoryConfigProvider = CategoryConfigProvider._();

/// The taxonomy, as the console sees it: every locale's name, plus counts.
///
/// `keepAlive` because the article list and the publishing panel `read` it for
/// their category pickers without watching it, and an auto-disposed provider
/// would hand them an empty list every time.

final class CategoryConfigProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CategoryConfigDto>>,
          List<CategoryConfigDto>,
          FutureOr<List<CategoryConfigDto>>
        >
    with
        $FutureModifier<List<CategoryConfigDto>>,
        $FutureProvider<List<CategoryConfigDto>> {
  /// The taxonomy, as the console sees it: every locale's name, plus counts.
  ///
  /// `keepAlive` because the article list and the publishing panel `read` it for
  /// their category pickers without watching it, and an auto-disposed provider
  /// would hand them an empty list every time.
  CategoryConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryConfigHash();

  @$internal
  @override
  $FutureProviderElement<List<CategoryConfigDto>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CategoryConfigDto>> create(Ref ref) {
    return categoryConfig(ref);
  }
}

String _$categoryConfigHash() => r'0748fefc7081897c8993c0375a088aad20dacd64';

/// Writes against the taxonomy.
///
/// Create and rename go through the whole-list save, because `order` is a
/// property of the collection rather than of one row; delete is its own call,
/// because the save never deletes. `keepAlive` for the same reason as the
/// other actions providers: nothing watches it, so under auto-dispose the
/// notifier would be gone before the awaited write returned.

@ProviderFor(CategoryActions)
final categoryActionsProvider = CategoryActionsProvider._();

/// Writes against the taxonomy.
///
/// Create and rename go through the whole-list save, because `order` is a
/// property of the collection rather than of one row; delete is its own call,
/// because the save never deletes. `keepAlive` for the same reason as the
/// other actions providers: nothing watches it, so under auto-dispose the
/// notifier would be gone before the awaited write returned.
final class CategoryActionsProvider
    extends $NotifierProvider<CategoryActions, void> {
  /// Writes against the taxonomy.
  ///
  /// Create and rename go through the whole-list save, because `order` is a
  /// property of the collection rather than of one row; delete is its own call,
  /// because the save never deletes. `keepAlive` for the same reason as the
  /// other actions providers: nothing watches it, so under auto-dispose the
  /// notifier would be gone before the awaited write returned.
  CategoryActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'categoryActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$categoryActionsHash();

  @$internal
  @override
  CategoryActions create() => CategoryActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$categoryActionsHash() => r'e33e637b3d4eb9b75904708deadd41c7c1d0e823';

/// Writes against the taxonomy.
///
/// Create and rename go through the whole-list save, because `order` is a
/// property of the collection rather than of one row; delete is its own call,
/// because the save never deletes. `keepAlive` for the same reason as the
/// other actions providers: nothing watches it, so under auto-dispose the
/// notifier would be gone before the awaited write returned.

abstract class _$CategoryActions extends $Notifier<void> {
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
