// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_controllers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The live channel's status and schedule.
///
/// Kept alive so returning to the Live tab does not re-request the manifest.
/// Not polled by itself either — see [liveChannelWatch], which is what adds a
/// timer, and only while there is somebody to notice.

@ProviderFor(liveChannel)
final liveChannelProvider = LiveChannelProvider._();

/// The live channel's status and schedule.
///
/// Kept alive so returning to the Live tab does not re-request the manifest.
/// Not polled by itself either — see [liveChannelWatch], which is what adds a
/// timer, and only while there is somebody to notice.

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
  /// Kept alive so returning to the Live tab does not re-request the manifest.
  /// Not polled by itself either — see [liveChannelWatch], which is what adds a
  /// timer, and only while there is somebody to notice.
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

/// Re-checks the channel while it is being watched.
///
/// This file used to carry a comment saying the channel was deliberately not
/// polled: the app had no way to know when the broadcaster went off air, and
/// the answer was the backend's `is_live` flag on the next natural fetch
/// rather than a timer burning data all day. That was right while `tv_on_air`
/// was a switch a person flipped, because a person was always there when it
/// changed.
///
/// It is wrong now. The channel also goes down when the studio's encoder
/// drops, which happens at 03:00 with nobody watching the console, and the API
/// answers the drop within three seconds. Without a re-check the app keeps
/// playing a manifest whose segments have stopped existing — a frozen frame,
/// or a spinner, with no way back to the slate short of the viewer closing the
/// app.
///
/// Watch it, and the timer runs. Stop watching, and Riverpod disposes this
/// provider and the timer with it. That is the narrowest form of the fix: no
/// background polling, nothing running while the app is in the news tab, and
/// one request every thirty seconds for as long as a video is on screen.
///
/// Playback failures are the other half and do not go through here — the live
/// page refreshes immediately on `PLAYBACK_FAILED`, because a viewer whose
/// stream just died should not wait out a timer to find out why.

@ProviderFor(liveChannelWatch)
final liveChannelWatchProvider = LiveChannelWatchProvider._();

/// Re-checks the channel while it is being watched.
///
/// This file used to carry a comment saying the channel was deliberately not
/// polled: the app had no way to know when the broadcaster went off air, and
/// the answer was the backend's `is_live` flag on the next natural fetch
/// rather than a timer burning data all day. That was right while `tv_on_air`
/// was a switch a person flipped, because a person was always there when it
/// changed.
///
/// It is wrong now. The channel also goes down when the studio's encoder
/// drops, which happens at 03:00 with nobody watching the console, and the API
/// answers the drop within three seconds. Without a re-check the app keeps
/// playing a manifest whose segments have stopped existing — a frozen frame,
/// or a spinner, with no way back to the slate short of the viewer closing the
/// app.
///
/// Watch it, and the timer runs. Stop watching, and Riverpod disposes this
/// provider and the timer with it. That is the narrowest form of the fix: no
/// background polling, nothing running while the app is in the news tab, and
/// one request every thirty seconds for as long as a video is on screen.
///
/// Playback failures are the other half and do not go through here — the live
/// page refreshes immediately on `PLAYBACK_FAILED`, because a viewer whose
/// stream just died should not wait out a timer to find out why.

final class LiveChannelWatchProvider
    extends
        $FunctionalProvider<
          AsyncValue<LiveChannel>,
          LiveChannel,
          Stream<LiveChannel>
        >
    with $FutureModifier<LiveChannel>, $StreamProvider<LiveChannel> {
  /// Re-checks the channel while it is being watched.
  ///
  /// This file used to carry a comment saying the channel was deliberately not
  /// polled: the app had no way to know when the broadcaster went off air, and
  /// the answer was the backend's `is_live` flag on the next natural fetch
  /// rather than a timer burning data all day. That was right while `tv_on_air`
  /// was a switch a person flipped, because a person was always there when it
  /// changed.
  ///
  /// It is wrong now. The channel also goes down when the studio's encoder
  /// drops, which happens at 03:00 with nobody watching the console, and the API
  /// answers the drop within three seconds. Without a re-check the app keeps
  /// playing a manifest whose segments have stopped existing — a frozen frame,
  /// or a spinner, with no way back to the slate short of the viewer closing the
  /// app.
  ///
  /// Watch it, and the timer runs. Stop watching, and Riverpod disposes this
  /// provider and the timer with it. That is the narrowest form of the fix: no
  /// background polling, nothing running while the app is in the news tab, and
  /// one request every thirty seconds for as long as a video is on screen.
  ///
  /// Playback failures are the other half and do not go through here — the live
  /// page refreshes immediately on `PLAYBACK_FAILED`, because a viewer whose
  /// stream just died should not wait out a timer to find out why.
  LiveChannelWatchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'liveChannelWatchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$liveChannelWatchHash();

  @$internal
  @override
  $StreamProviderElement<LiveChannel> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<LiveChannel> create(Ref ref) {
    return liveChannelWatch(ref);
  }
}

String _$liveChannelWatchHash() => r'9c642d93b5a0341ed904e7bb29132da5a2ec0a84';
