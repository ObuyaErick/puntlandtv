// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_controllers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// One live channel's status and schedule, by key.
///
/// Kept alive so returning to a channel does not re-request the manifest. Not
/// polled by itself either — see [liveChannelWatch], which is what adds a
/// timer, and only while there is somebody to notice.

@ProviderFor(liveChannel)
final liveChannelProvider = LiveChannelFamily._();

/// One live channel's status and schedule, by key.
///
/// Kept alive so returning to a channel does not re-request the manifest. Not
/// polled by itself either — see [liveChannelWatch], which is what adds a
/// timer, and only while there is somebody to notice.

final class LiveChannelProvider
    extends
        $FunctionalProvider<
          AsyncValue<LiveChannel>,
          LiveChannel,
          FutureOr<LiveChannel>
        >
    with $FutureModifier<LiveChannel>, $FutureProvider<LiveChannel> {
  /// One live channel's status and schedule, by key.
  ///
  /// Kept alive so returning to a channel does not re-request the manifest. Not
  /// polled by itself either — see [liveChannelWatch], which is what adds a
  /// timer, and only while there is somebody to notice.
  LiveChannelProvider._({
    required LiveChannelFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'liveChannelProvider',
         isAutoDispose: false,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$liveChannelHash();

  @override
  String toString() {
    return r'liveChannelProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<LiveChannel> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<LiveChannel> create(Ref ref) {
    final argument = this.argument as String;
    return liveChannel(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LiveChannelProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$liveChannelHash() => r'8196e5c375f1720f9b1d82e11e102a5ca36882d4';

/// One live channel's status and schedule, by key.
///
/// Kept alive so returning to a channel does not re-request the manifest. Not
/// polled by itself either — see [liveChannelWatch], which is what adds a
/// timer, and only while there is somebody to notice.

final class LiveChannelFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<LiveChannel>, String> {
  LiveChannelFamily._()
    : super(
        retry: null,
        name: r'liveChannelProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: false,
      );

  /// One live channel's status and schedule, by key.
  ///
  /// Kept alive so returning to a channel does not re-request the manifest. Not
  /// polled by itself either — see [liveChannelWatch], which is what adds a
  /// timer, and only while there is somebody to notice.

  LiveChannelProvider call(String key) =>
      LiveChannelProvider._(argument: key, from: this);

  @override
  String toString() => r'liveChannelProvider';
}

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
///
/// One timer per channel on screen, which in practice is one: the page for a
/// channel is the only thing that watches it.

@ProviderFor(liveChannelWatch)
final liveChannelWatchProvider = LiveChannelWatchFamily._();

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
///
/// One timer per channel on screen, which in practice is one: the page for a
/// channel is the only thing that watches it.

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
  ///
  /// One timer per channel on screen, which in practice is one: the page for a
  /// channel is the only thing that watches it.
  LiveChannelWatchProvider._({
    required LiveChannelWatchFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'liveChannelWatchProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$liveChannelWatchHash();

  @override
  String toString() {
    return r'liveChannelWatchProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<LiveChannel> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<LiveChannel> create(Ref ref) {
    final argument = this.argument as String;
    return liveChannelWatch(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is LiveChannelWatchProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$liveChannelWatchHash() => r'6bc25587938110224b76296370aa2fc4fb04cc0d';

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
///
/// One timer per channel on screen, which in practice is one: the page for a
/// channel is the only thing that watches it.

final class LiveChannelWatchFamily extends $Family
    with $FunctionalFamilyOverride<Stream<LiveChannel>, String> {
  LiveChannelWatchFamily._()
    : super(
        retry: null,
        name: r'liveChannelWatchProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

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
  ///
  /// One timer per channel on screen, which in practice is one: the page for a
  /// channel is the only thing that watches it.

  LiveChannelWatchProvider call(String key) =>
      LiveChannelWatchProvider._(argument: key, from: this);

  @override
  String toString() => r'liveChannelWatchProvider';
}
