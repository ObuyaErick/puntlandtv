// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'administration_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(staffDirectory)
final staffDirectoryProvider = StaffDirectoryProvider._();

final class StaffDirectoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<StaffDirectoryDto>,
          StaffDirectoryDto,
          FutureOr<StaffDirectoryDto>
        >
    with
        $FutureModifier<StaffDirectoryDto>,
        $FutureProvider<StaffDirectoryDto> {
  StaffDirectoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'staffDirectoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$staffDirectoryHash();

  @$internal
  @override
  $FutureProviderElement<StaffDirectoryDto> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<StaffDirectoryDto> create(Ref ref) {
    return staffDirectory(ref);
  }
}

String _$staffDirectoryHash() => r'cd470630c154ba69742e0a363815e3ff803a1ed7';

/// Writes against staff accounts.

@ProviderFor(StaffActions)
final staffActionsProvider = StaffActionsProvider._();

/// Writes against staff accounts.
final class StaffActionsProvider extends $NotifierProvider<StaffActions, void> {
  /// Writes against staff accounts.
  StaffActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'staffActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$staffActionsHash();

  @$internal
  @override
  StaffActions create() => StaffActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$staffActionsHash() => r'a9338689e57726256f18944b8760a352d75ca3d2';

/// Writes against staff accounts.

abstract class _$StaffActions extends $Notifier<void> {
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

@ProviderFor(storedConfig)
final storedConfigProvider = StoredConfigProvider._();

final class StoredConfigProvider
    extends
        $FunctionalProvider<
          AsyncValue<ConsoleConfigDto>,
          ConsoleConfigDto,
          FutureOr<ConsoleConfigDto>
        >
    with $FutureModifier<ConsoleConfigDto>, $FutureProvider<ConsoleConfigDto> {
  StoredConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storedConfigProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storedConfigHash();

  @$internal
  @override
  $FutureProviderElement<ConsoleConfigDto> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ConsoleConfigDto> create(Ref ref) {
    return storedConfig(ref);
  }
}

String _$storedConfigHash() => r'b734b834d2b88b6bf12dd007be3399d71bc2fdda';

/// The config as it stands in the form, which is not what is stored.
///
/// App configuration is edited as a whole and saved once, unlike the article
/// list where every action is its own write. Two of these fields can take the
/// product down for every reader, so a switch that applies the instant it is
/// flipped is the wrong shape: there has to be a moment where the form is
/// wrong, the screen says why, and nothing has happened yet.
///
/// Null until the stored config has loaded — the draft is a copy of something,
/// and inventing a default would let the form save a floor nobody chose.

@ProviderFor(ConfigDraft)
final configDraftProvider = ConfigDraftProvider._();

/// The config as it stands in the form, which is not what is stored.
///
/// App configuration is edited as a whole and saved once, unlike the article
/// list where every action is its own write. Two of these fields can take the
/// product down for every reader, so a switch that applies the instant it is
/// flipped is the wrong shape: there has to be a moment where the form is
/// wrong, the screen says why, and nothing has happened yet.
///
/// Null until the stored config has loaded — the draft is a copy of something,
/// and inventing a default would let the form save a floor nobody chose.
final class ConfigDraftProvider
    extends $NotifierProvider<ConfigDraft, ConsoleConfigDto?> {
  /// The config as it stands in the form, which is not what is stored.
  ///
  /// App configuration is edited as a whole and saved once, unlike the article
  /// list where every action is its own write. Two of these fields can take the
  /// product down for every reader, so a switch that applies the instant it is
  /// flipped is the wrong shape: there has to be a moment where the form is
  /// wrong, the screen says why, and nothing has happened yet.
  ///
  /// Null until the stored config has loaded — the draft is a copy of something,
  /// and inventing a default would let the form save a floor nobody chose.
  ConfigDraftProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'configDraftProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$configDraftHash();

  @$internal
  @override
  ConfigDraft create() => ConfigDraft();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConsoleConfigDto? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConsoleConfigDto?>(value),
    );
  }
}

String _$configDraftHash() => r'930599616ab1d2d7b08d04d403a4e9d55505691c';

/// The config as it stands in the form, which is not what is stored.
///
/// App configuration is edited as a whole and saved once, unlike the article
/// list where every action is its own write. Two of these fields can take the
/// product down for every reader, so a switch that applies the instant it is
/// flipped is the wrong shape: there has to be a moment where the form is
/// wrong, the screen says why, and nothing has happened yet.
///
/// Null until the stored config has loaded — the draft is a copy of something,
/// and inventing a default would let the form save a floor nobody chose.

abstract class _$ConfigDraft extends $Notifier<ConsoleConfigDto?> {
  ConsoleConfigDto? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ConsoleConfigDto?, ConsoleConfigDto?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ConsoleConfigDto?, ConsoleConfigDto?>,
              ConsoleConfigDto?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Whether the form differs from what is stored.
///
/// Compared field by field rather than by identity: the draft is a new object
/// after every keystroke, so an identity check would report unsaved changes
/// forever once anyone touched the form and then undid it.

@ProviderFor(configIsDirty)
final configIsDirtyProvider = ConfigIsDirtyProvider._();

/// Whether the form differs from what is stored.
///
/// Compared field by field rather than by identity: the draft is a new object
/// after every keystroke, so an identity check would report unsaved changes
/// forever once anyone touched the form and then undid it.

final class ConfigIsDirtyProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether the form differs from what is stored.
  ///
  /// Compared field by field rather than by identity: the draft is a new object
  /// after every keystroke, so an identity check would report unsaved changes
  /// forever once anyone touched the form and then undid it.
  ConfigIsDirtyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'configIsDirtyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$configIsDirtyHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return configIsDirty(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$configIsDirtyHash() => r'c0bb64d58d83e26bc31c332412d05e04a55cd0ee';

@ProviderFor(ConfigActions)
final configActionsProvider = ConfigActionsProvider._();

final class ConfigActionsProvider
    extends $NotifierProvider<ConfigActions, void> {
  ConfigActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'configActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$configActionsHash();

  @$internal
  @override
  ConfigActions create() => ConfigActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$configActionsHash() => r'3c5e45bb9a2c48817dc66be20b7d48c9532105bb';

abstract class _$ConfigActions extends $Notifier<void> {
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
