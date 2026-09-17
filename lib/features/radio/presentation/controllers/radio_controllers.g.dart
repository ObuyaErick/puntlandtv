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

/// The station, kept current while somebody is listening.
///
/// Radio had nothing like this. There was one future provider, no timer and no
/// `PLAYBACK_FAILED` listener, so a station going off air left the listener on
/// a dead stream indefinitely — the television side had grown three separate
/// answers to that problem and radio had none of them.

@ProviderFor(radioStationWatch)
final radioStationWatchProvider = RadioStationWatchFamily._();

/// The station, kept current while somebody is listening.
///
/// Radio had nothing like this. There was one future provider, no timer and no
/// `PLAYBACK_FAILED` listener, so a station going off air left the listener on
/// a dead stream indefinitely — the television side had grown three separate
/// answers to that problem and radio had none of them.

final class RadioStationWatchProvider
    extends
        $FunctionalProvider<
          AsyncValue<RadioStation>,
          RadioStation,
          Stream<RadioStation>
        >
    with $FutureModifier<RadioStation>, $StreamProvider<RadioStation> {
  /// The station, kept current while somebody is listening.
  ///
  /// Radio had nothing like this. There was one future provider, no timer and no
  /// `PLAYBACK_FAILED` listener, so a station going off air left the listener on
  /// a dead stream indefinitely — the television side had grown three separate
  /// answers to that problem and radio had none of them.
  RadioStationWatchProvider._({
    required RadioStationWatchFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'radioStationWatchProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$radioStationWatchHash();

  @override
  String toString() {
    return r'radioStationWatchProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<RadioStation> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<RadioStation> create(Ref ref) {
    final argument = this.argument as String;
    return radioStationWatch(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is RadioStationWatchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$radioStationWatchHash() => r'9f6352e738156468a29e06c4ff179011b6783d3e';

/// The station, kept current while somebody is listening.
///
/// Radio had nothing like this. There was one future provider, no timer and no
/// `PLAYBACK_FAILED` listener, so a station going off air left the listener on
/// a dead stream indefinitely — the television side had grown three separate
/// answers to that problem and radio had none of them.

final class RadioStationWatchFamily extends $Family
    with $FunctionalFamilyOverride<Stream<RadioStation>, String> {
  RadioStationWatchFamily._()
    : super(
        retry: null,
        name: r'radioStationWatchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The station, kept current while somebody is listening.
  ///
  /// Radio had nothing like this. There was one future provider, no timer and no
  /// `PLAYBACK_FAILED` listener, so a station going off air left the listener on
  /// a dead stream indefinitely — the television side had grown three separate
  /// answers to that problem and radio had none of them.

  RadioStationWatchProvider call(String key) =>
      RadioStationWatchProvider._(argument: key, from: this);

  @override
  String toString() => r'radioStationWatchProvider';
}
