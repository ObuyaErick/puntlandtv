// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_controllers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// One live channel's status and schedule, by key.
///
/// Kept alive so returning to a channel does not re-request the manifest.
/// A one-shot read: [liveChannelWatch] is what stays current.

@ProviderFor(liveChannel)
final liveChannelProvider = LiveChannelFamily._();

/// One live channel's status and schedule, by key.
///
/// Kept alive so returning to a channel does not re-request the manifest.
/// A one-shot read: [liveChannelWatch] is what stays current.

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
  /// Kept alive so returning to a channel does not re-request the manifest.
  /// A one-shot read: [liveChannelWatch] is what stays current.
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
/// Kept alive so returning to a channel does not re-request the manifest.
/// A one-shot read: [liveChannelWatch] is what stays current.

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
  /// Kept alive so returning to a channel does not re-request the manifest.
  /// A one-shot read: [liveChannelWatch] is what stays current.

  LiveChannelProvider call(String key) =>
      LiveChannelProvider._(argument: key, from: this);

  @override
  String toString() => r'liveChannelProvider';
}

/// The channel, kept current for as long as somebody is watching it.
///
/// This used to own a thirty-second timer, and the comment here used to
/// explain why a timer was the least-bad answer: the app had no way to be
/// *told* that the broadcaster had gone off air, so it asked. The cost was a
/// viewer learning the channel went on air up to thirty-three seconds late —
/// thirty for this timer, three more for the backend's ingest poll.
///
/// It now subscribes to `channel:<key>` and hears about it in about a second.
/// The timer did not disappear, it moved and slowed down: the repository keeps
/// a fallback poll behind the socket, at the old cadence while disconnected
/// and every five minutes while connected, so a missed frame costs latency
/// rather than correctness.
///
/// The mechanism lives in the data layer, where the layer rules already allow
/// it — see `LiveRepositoryImpl.watch`. What is left here is the seam the
/// pages were already written against, unchanged: this was a `Stream<T>`
/// provider before and still is, so no page code moved for any of this.
///
/// Playback failures are the other half and do not go through here — the live
/// page still refreshes immediately on `PLAYBACK_FAILED`, because a segment
/// 404 is noticed by the player before any server event arrives.

@ProviderFor(liveChannelWatch)
final liveChannelWatchProvider = LiveChannelWatchFamily._();

/// The channel, kept current for as long as somebody is watching it.
///
/// This used to own a thirty-second timer, and the comment here used to
/// explain why a timer was the least-bad answer: the app had no way to be
/// *told* that the broadcaster had gone off air, so it asked. The cost was a
/// viewer learning the channel went on air up to thirty-three seconds late —
/// thirty for this timer, three more for the backend's ingest poll.
///
/// It now subscribes to `channel:<key>` and hears about it in about a second.
/// The timer did not disappear, it moved and slowed down: the repository keeps
/// a fallback poll behind the socket, at the old cadence while disconnected
/// and every five minutes while connected, so a missed frame costs latency
/// rather than correctness.
///
/// The mechanism lives in the data layer, where the layer rules already allow
/// it — see `LiveRepositoryImpl.watch`. What is left here is the seam the
/// pages were already written against, unchanged: this was a `Stream<T>`
/// provider before and still is, so no page code moved for any of this.
///
/// Playback failures are the other half and do not go through here — the live
/// page still refreshes immediately on `PLAYBACK_FAILED`, because a segment
/// 404 is noticed by the player before any server event arrives.

final class LiveChannelWatchProvider
    extends
        $FunctionalProvider<
          AsyncValue<LiveChannel>,
          LiveChannel,
          Stream<LiveChannel>
        >
    with $FutureModifier<LiveChannel>, $StreamProvider<LiveChannel> {
  /// The channel, kept current for as long as somebody is watching it.
  ///
  /// This used to own a thirty-second timer, and the comment here used to
  /// explain why a timer was the least-bad answer: the app had no way to be
  /// *told* that the broadcaster had gone off air, so it asked. The cost was a
  /// viewer learning the channel went on air up to thirty-three seconds late —
  /// thirty for this timer, three more for the backend's ingest poll.
  ///
  /// It now subscribes to `channel:<key>` and hears about it in about a second.
  /// The timer did not disappear, it moved and slowed down: the repository keeps
  /// a fallback poll behind the socket, at the old cadence while disconnected
  /// and every five minutes while connected, so a missed frame costs latency
  /// rather than correctness.
  ///
  /// The mechanism lives in the data layer, where the layer rules already allow
  /// it — see `LiveRepositoryImpl.watch`. What is left here is the seam the
  /// pages were already written against, unchanged: this was a `Stream<T>`
  /// provider before and still is, so no page code moved for any of this.
  ///
  /// Playback failures are the other half and do not go through here — the live
  /// page still refreshes immediately on `PLAYBACK_FAILED`, because a segment
  /// 404 is noticed by the player before any server event arrives.
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

String _$liveChannelWatchHash() => r'ce8d8421b3856a02e18175ebbbaa6f484e2f8f97';

/// The channel, kept current for as long as somebody is watching it.
///
/// This used to own a thirty-second timer, and the comment here used to
/// explain why a timer was the least-bad answer: the app had no way to be
/// *told* that the broadcaster had gone off air, so it asked. The cost was a
/// viewer learning the channel went on air up to thirty-three seconds late —
/// thirty for this timer, three more for the backend's ingest poll.
///
/// It now subscribes to `channel:<key>` and hears about it in about a second.
/// The timer did not disappear, it moved and slowed down: the repository keeps
/// a fallback poll behind the socket, at the old cadence while disconnected
/// and every five minutes while connected, so a missed frame costs latency
/// rather than correctness.
///
/// The mechanism lives in the data layer, where the layer rules already allow
/// it — see `LiveRepositoryImpl.watch`. What is left here is the seam the
/// pages were already written against, unchanged: this was a `Stream<T>`
/// provider before and still is, so no page code moved for any of this.
///
/// Playback failures are the other half and do not go through here — the live
/// page still refreshes immediately on `PLAYBACK_FAILED`, because a segment
/// 404 is noticed by the player before any server event arrives.

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

  /// The channel, kept current for as long as somebody is watching it.
  ///
  /// This used to own a thirty-second timer, and the comment here used to
  /// explain why a timer was the least-bad answer: the app had no way to be
  /// *told* that the broadcaster had gone off air, so it asked. The cost was a
  /// viewer learning the channel went on air up to thirty-three seconds late —
  /// thirty for this timer, three more for the backend's ingest poll.
  ///
  /// It now subscribes to `channel:<key>` and hears about it in about a second.
  /// The timer did not disappear, it moved and slowed down: the repository keeps
  /// a fallback poll behind the socket, at the old cadence while disconnected
  /// and every five minutes while connected, so a missed frame costs latency
  /// rather than correctness.
  ///
  /// The mechanism lives in the data layer, where the layer rules already allow
  /// it — see `LiveRepositoryImpl.watch`. What is left here is the seam the
  /// pages were already written against, unchanged: this was a `Stream<T>`
  /// provider before and still is, so no page code moved for any of this.
  ///
  /// Playback failures are the other half and do not go through here — the live
  /// page still refreshes immediately on `PLAYBACK_FAILED`, because a segment
  /// 404 is noticed by the player before any server event arrives.

  LiveChannelWatchProvider call(String key) =>
      LiveChannelWatchProvider._(argument: key, from: this);

  @override
  String toString() => r'liveChannelWatchProvider';
}
