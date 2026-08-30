// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'radio_controllers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(radioStation)
final radioStationProvider = RadioStationProvider._();

final class RadioStationProvider
    extends
        $FunctionalProvider<
          AsyncValue<RadioStation>,
          RadioStation,
          FutureOr<RadioStation>
        >
    with $FutureModifier<RadioStation>, $FutureProvider<RadioStation> {
  RadioStationProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'radioStationProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$radioStationHash();

  @$internal
  @override
  $FutureProviderElement<RadioStation> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RadioStation> create(Ref ref) {
    return radioStation(ref);
  }
}

String _$radioStationHash() => r'7394c1c1b0ab04de5edcd834bc0adb26622eddd1';
