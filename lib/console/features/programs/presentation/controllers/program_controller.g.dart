// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'program_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Which programme's episodes are open, or null for the programme list.
///
/// The episodes of one show are a different screen from the list of shows, but
/// not a different *destination* — the rail has one Programmes entry, and
/// adding a second for "episodes of the thing you last clicked" would be a
/// navigation item that means nothing until you have already navigated.

@ProviderFor(OpenProgram)
final openProgramProvider = OpenProgramProvider._();

/// Which programme's episodes are open, or null for the programme list.
///
/// The episodes of one show are a different screen from the list of shows, but
/// not a different *destination* — the rail has one Programmes entry, and
/// adding a second for "episodes of the thing you last clicked" would be a
/// navigation item that means nothing until you have already navigated.
final class OpenProgramProvider
    extends $NotifierProvider<OpenProgram, String?> {
  /// Which programme's episodes are open, or null for the programme list.
  ///
  /// The episodes of one show are a different screen from the list of shows, but
  /// not a different *destination* — the rail has one Programmes entry, and
  /// adding a second for "episodes of the thing you last clicked" would be a
  /// navigation item that means nothing until you have already navigated.
  OpenProgramProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'openProgramProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$openProgramHash();

  @$internal
  @override
  OpenProgram create() => OpenProgram();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$openProgramHash() => r'5dbf25caa2bc1f8a8efc4b8dd4f016f2a929214b';

/// Which programme's episodes are open, or null for the programme list.
///
/// The episodes of one show are a different screen from the list of shows, but
/// not a different *destination* — the rail has one Programmes entry, and
/// adding a second for "episodes of the thing you last clicked" would be a
/// navigation item that means nothing until you have already navigated.

abstract class _$OpenProgram extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(programList)
final programListProvider = ProgramListProvider._();

final class ProgramListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AdminProgramDto>>,
          List<AdminProgramDto>,
          FutureOr<List<AdminProgramDto>>
        >
    with
        $FutureModifier<List<AdminProgramDto>>,
        $FutureProvider<List<AdminProgramDto>> {
  ProgramListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'programListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$programListHash();

  @$internal
  @override
  $FutureProviderElement<List<AdminProgramDto>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AdminProgramDto>> create(Ref ref) {
    return programList(ref);
  }
}

String _$programListHash() => r'a637ab701577b2141764f67d25d3cb01441ed86b';

@ProviderFor(episodeList)
final episodeListProvider = EpisodeListFamily._();

final class EpisodeListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AdminEpisodeDto>>,
          List<AdminEpisodeDto>,
          FutureOr<List<AdminEpisodeDto>>
        >
    with
        $FutureModifier<List<AdminEpisodeDto>>,
        $FutureProvider<List<AdminEpisodeDto>> {
  EpisodeListProvider._({
    required EpisodeListFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'episodeListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$episodeListHash();

  @override
  String toString() {
    return r'episodeListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<AdminEpisodeDto>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AdminEpisodeDto>> create(Ref ref) {
    final argument = this.argument as String;
    return episodeList(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EpisodeListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$episodeListHash() => r'bb162013f9aa11523546749973aa5f3024873cf3';

final class EpisodeListFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<AdminEpisodeDto>>, String> {
  EpisodeListFamily._()
    : super(
        retry: null,
        name: r'episodeListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EpisodeListProvider call(String programId) =>
      EpisodeListProvider._(argument: programId, from: this);

  @override
  String toString() => r'episodeListProvider';
}

/// Writes against programmes and episodes.
///
/// `keepAlive` for the same reason the media library's actions provider needs
/// it: nothing watches an actions provider, so under auto-dispose the notifier
/// is disposed before the awaited write returns and the invalidation that
/// follows throws on a dead `Ref`.

@ProviderFor(ProgramActions)
final programActionsProvider = ProgramActionsProvider._();

/// Writes against programmes and episodes.
///
/// `keepAlive` for the same reason the media library's actions provider needs
/// it: nothing watches an actions provider, so under auto-dispose the notifier
/// is disposed before the awaited write returns and the invalidation that
/// follows throws on a dead `Ref`.
final class ProgramActionsProvider
    extends $NotifierProvider<ProgramActions, void> {
  /// Writes against programmes and episodes.
  ///
  /// `keepAlive` for the same reason the media library's actions provider needs
  /// it: nothing watches an actions provider, so under auto-dispose the notifier
  /// is disposed before the awaited write returns and the invalidation that
  /// follows throws on a dead `Ref`.
  ProgramActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'programActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$programActionsHash();

  @$internal
  @override
  ProgramActions create() => ProgramActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$programActionsHash() => r'aff4b4d231f866e58d47878368956bb82db1c1aa';

/// Writes against programmes and episodes.
///
/// `keepAlive` for the same reason the media library's actions provider needs
/// it: nothing watches an actions provider, so under auto-dispose the notifier
/// is disposed before the awaited write returns and the invalidation that
/// follows throws on a dead `Ref`.

abstract class _$ProgramActions extends $Notifier<void> {
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
