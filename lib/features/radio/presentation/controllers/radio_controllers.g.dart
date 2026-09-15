// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'radio_controllers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// One channel's radio station, by key.

@ProviderFor(radioStation)
final radioStationProvider = RadioStationFamily._();

/// One channel's radio station, by key.

final class RadioStationProvider
    extends
        $FunctionalProvider<
          AsyncValue<RadioStation>,
          RadioStation,
          FutureOr<RadioStation>
        >
    with $FutureModifier<RadioStation>, $FutureProvider<RadioStation> {
  /// One channel's radio station, by key.
  RadioStationProvider._({
    required RadioStationFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'radioStationProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$radioStationHash();

  @override
  String toString() {
    return r'radioStationProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<RadioStation> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RadioStation> create(Ref ref) {
    final argument = this.argument as String;
    return radioStation(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RadioStationProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$radioStationHash() => r'c3ed5d89f85d63b88dd3d957740a01a7472439fb';

/// One channel's radio station, by key.

final class RadioStationFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<RadioStation>, String> {
  RadioStationFamily._()
    : super(
        retry: null,
        name: r'radioStationProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// One channel's radio station, by key.

  RadioStationProvider call(String key) =>
      RadioStationProvider._(argument: key, from: this);

  @override
  String toString() => r'radioStationProvider';
}
