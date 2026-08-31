// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The alert being composed.

@ProviderFor(PushDraft)
final pushDraftProvider = PushDraftProvider._();

/// The alert being composed.
final class PushDraftProvider
    extends $NotifierProvider<PushDraft, PushDraftDto> {
  /// The alert being composed.
  PushDraftProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushDraftProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushDraftHash();

  @$internal
  @override
  PushDraft create() => PushDraft();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PushDraftDto value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PushDraftDto>(value),
    );
  }
}

String _$pushDraftHash() => r'0ea7f435a0d2fab8553de0e6727089fa46e8eebe';

/// The alert being composed.

abstract class _$PushDraft extends $Notifier<PushDraftDto> {
  PushDraftDto build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PushDraftDto, PushDraftDto>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PushDraftDto, PushDraftDto>,
              PushDraftDto,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Reach depends only on the selected topics, not on the message text.
///
/// Keyed on [PushDraftDto.topicsKey] rather than watching the whole draft:
/// watching the draft re-fetched on every keystroke, because a new draft
/// object never compares equal to the old one and the provider churned
/// continuously.

@ProviderFor(pushReach)
final pushReachProvider = PushReachFamily._();

/// Reach depends only on the selected topics, not on the message text.
///
/// Keyed on [PushDraftDto.topicsKey] rather than watching the whole draft:
/// watching the draft re-fetched on every keystroke, because a new draft
/// object never compares equal to the old one and the provider churned
/// continuously.

final class PushReachProvider
    extends
        $FunctionalProvider<
          AsyncValue<PushReachDto>,
          PushReachDto,
          FutureOr<PushReachDto>
        >
    with $FutureModifier<PushReachDto>, $FutureProvider<PushReachDto> {
  /// Reach depends only on the selected topics, not on the message text.
  ///
  /// Keyed on [PushDraftDto.topicsKey] rather than watching the whole draft:
  /// watching the draft re-fetched on every keystroke, because a new draft
  /// object never compares equal to the old one and the provider churned
  /// continuously.
  PushReachProvider._({
    required PushReachFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'pushReachProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pushReachHash();

  @override
  String toString() {
    return r'pushReachProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PushReachDto> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PushReachDto> create(Ref ref) {
    final argument = this.argument as String;
    return pushReach(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PushReachProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pushReachHash() => r'5742e47916706620dfdb7aea98ed26a0b31fe504';

/// Reach depends only on the selected topics, not on the message text.
///
/// Keyed on [PushDraftDto.topicsKey] rather than watching the whole draft:
/// watching the draft re-fetched on every keystroke, because a new draft
/// object never compares equal to the old one and the provider churned
/// continuously.

final class PushReachFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PushReachDto>, String> {
  PushReachFamily._()
    : super(
        retry: null,
        name: r'pushReachProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Reach depends only on the selected topics, not on the message text.
  ///
  /// Keyed on [PushDraftDto.topicsKey] rather than watching the whole draft:
  /// watching the draft re-fetched on every keystroke, because a new draft
  /// object never compares equal to the old one and the provider churned
  /// continuously.

  PushReachProvider call(String topicsKey) =>
      PushReachProvider._(argument: topicsKey, from: this);

  @override
  String toString() => r'pushReachProvider';
}

@ProviderFor(pushHistory)
final pushHistoryProvider = PushHistoryProvider._();

final class PushHistoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PushHistoryEntryDto>>,
          List<PushHistoryEntryDto>,
          FutureOr<List<PushHistoryEntryDto>>
        >
    with
        $FutureModifier<List<PushHistoryEntryDto>>,
        $FutureProvider<List<PushHistoryEntryDto>> {
  PushHistoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushHistoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushHistoryHash();

  @$internal
  @override
  $FutureProviderElement<List<PushHistoryEntryDto>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PushHistoryEntryDto>> create(Ref ref) {
    return pushHistory(ref);
  }
}

String _$pushHistoryHash() => r'bab4ea5e9220f717eebe7d664c982582fd79b59e';

@ProviderFor(PushSender)
final pushSenderProvider = PushSenderProvider._();

final class PushSenderProvider extends $NotifierProvider<PushSender, bool> {
  PushSenderProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushSenderProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushSenderHash();

  @$internal
  @override
  PushSender create() => PushSender();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$pushSenderHash() => r'64a5a648f21cc4964ac90cbc0b43d33d6bf364f2';

abstract class _$PushSender extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<bool, bool>,
              bool,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
