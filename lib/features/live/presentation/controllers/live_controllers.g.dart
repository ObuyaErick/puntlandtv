// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_controllers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The live channel's status and schedule.
///
/// Kept alive so returning to the Live tab does not re-request the manifest,
/// but deliberately *not* polled: the app has no way to know when the
/// broadcaster goes off air, and the plan's answer is the backend's
/// `is_live` flag on the next natural fetch rather than a background poll that
/// burns data all day.

@ProviderFor(liveChannel)
final liveChannelProvider = LiveChannelProvider._();

/// The live channel's status and schedule.
///
/// Kept alive so returning to the Live tab does not re-request the manifest,
/// but deliberately *not* polled: the app has no way to know when the
/// broadcaster goes off air, and the plan's answer is the backend's
/// `is_live` flag on the next natural fetch rather than a background poll that
/// burns data all day.

final class LiveChannelProvider
    extends
        $FunctionalProvider<
          AsyncValue<LiveChannel>,
          LiveChannel,
          FutureOr<LiveChannel>
        >
    with $FutureModifier<LiveChannel>, $FutureProvider<LiveChannel> {
  /// The live channel's status and schedule.
  ///
  /// Kept alive so returning to the Live tab does not re-request the manifest,
  /// but deliberately *not* polled: the app has no way to know when the
  /// broadcaster goes off air, and the plan's answer is the backend's
  /// `is_live` flag on the next natural fetch rather than a background poll that
  /// burns data all day.
  LiveChannelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'liveChannelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$liveChannelHash();

  @$internal
  @override
  $FutureProviderElement<LiveChannel> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LiveChannel> create(Ref ref) {
    return liveChannel(ref);
  }
}

String _$liveChannelHash() => r'f645ce6fa54f091af51411c6c6446297a6a9c302';
