// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vod_controllers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(programs)
final programsProvider = ProgramsProvider._();

final class ProgramsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Program>>,
          List<Program>,
          FutureOr<List<Program>>
        >
    with $FutureModifier<List<Program>>, $FutureProvider<List<Program>> {
  ProgramsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'programsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$programsHash();

  @$internal
  @override
  $FutureProviderElement<List<Program>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Program>> create(Ref ref) {
    return programs(ref);
  }
}

String _$programsHash() => r'c7c52ba6bc044f87bd0f87b59cd7b2732a35fd19';

@ProviderFor(episodes)
final episodesProvider = EpisodesFamily._();

final class EpisodesProvider
    extends
        $FunctionalProvider<
          AsyncValue<Page<Episode>>,
          Page<Episode>,
          FutureOr<Page<Episode>>
        >
    with $FutureModifier<Page<Episode>>, $FutureProvider<Page<Episode>> {
  EpisodesProvider._({
    required EpisodesFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'episodesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$episodesHash();

  @override
  String toString() {
    return r'episodesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Page<Episode>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Page<Episode>> create(Ref ref) {
    final argument = this.argument as String?;
    return episodes(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EpisodesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$episodesHash() => r'cb8d33c75dbfad92e33c7433a4a0ea921fbfd54b';

final class EpisodesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Page<Episode>>, String?> {
  EpisodesFamily._()
    : super(
        retry: null,
        name: r'episodesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  EpisodesProvider call(String? programId) =>
      EpisodesProvider._(argument: programId, from: this);

  @override
  String toString() => r'episodesProvider';
}

@ProviderFor(program)
final programProvider = ProgramFamily._();

final class ProgramProvider
    extends
        $FunctionalProvider<AsyncValue<Program?>, Program?, FutureOr<Program?>>
    with $FutureModifier<Program?>, $FutureProvider<Program?> {
  ProgramProvider._({
    required ProgramFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'programProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$programHash();

  @override
  String toString() {
    return r'programProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Program?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Program?> create(Ref ref) {
    final argument = this.argument as String;
    return program(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ProgramProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$programHash() => r'b302b9f45a04ee6eb8619434823804bb2859cd1b';

final class ProgramFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Program?>, String> {
  ProgramFamily._()
    : super(
        retry: null,
        name: r'programProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ProgramProvider call(String id) =>
      ProgramProvider._(argument: id, from: this);

  @override
  String toString() => r'programProvider';
}
