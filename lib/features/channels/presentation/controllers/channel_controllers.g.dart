// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_controllers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every published channel, in the newsroom's order.
///
/// Kept alive, and shared by both tabs: Live TV and Radio are two filters over
/// this one list, so switching between them costs no request.

@ProviderFor(channelList)
final channelListProvider = ChannelListProvider._();

/// Every published channel, in the newsroom's order.
///
/// Kept alive, and shared by both tabs: Live TV and Radio are two filters over
/// this one list, so switching between them costs no request.

final class ChannelListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Channel>>,
          List<Channel>,
          FutureOr<List<Channel>>
        >
    with $FutureModifier<List<Channel>>, $FutureProvider<List<Channel>> {
  /// Every published channel, in the newsroom's order.
  ///
  /// Kept alive, and shared by both tabs: Live TV and Radio are two filters over
  /// this one list, so switching between them costs no request.
  ChannelListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'channelListProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$channelListHash();

  @$internal
  @override
  $FutureProviderElement<List<Channel>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Channel>> create(Ref ref) {
    return channelList(ref);
  }
}

String _$channelListHash() => r'c5e94412ab1e0d9432e7fa50a0f321d6224ecde3';

/// Re-checks the list while it is on screen.
///
/// The list's badges are the reason to open it — which channel is live now —
/// and a channel's encoder can drop or return at any moment with nobody in
/// the console. This is `liveChannelWatch`'s pattern for the same reason: a
/// timer only while somebody is looking, disposed with the screen, at the same
/// [liveRefreshInterval].

@ProviderFor(channelListWatch)
final channelListWatchProvider = ChannelListWatchProvider._();

/// Re-checks the list while it is on screen.
///
/// The list's badges are the reason to open it — which channel is live now —
/// and a channel's encoder can drop or return at any moment with nobody in
/// the console. This is `liveChannelWatch`'s pattern for the same reason: a
/// timer only while somebody is looking, disposed with the screen, at the same
/// [liveRefreshInterval].

final class ChannelListWatchProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Channel>>,
          List<Channel>,
          Stream<List<Channel>>
        >
    with $FutureModifier<List<Channel>>, $StreamProvider<List<Channel>> {
  /// Re-checks the list while it is on screen.
  ///
  /// The list's badges are the reason to open it — which channel is live now —
  /// and a channel's encoder can drop or return at any moment with nobody in
  /// the console. This is `liveChannelWatch`'s pattern for the same reason: a
  /// timer only while somebody is looking, disposed with the screen, at the same
  /// [liveRefreshInterval].
  ChannelListWatchProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'channelListWatchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$channelListWatchHash();

  @$internal
  @override
  $StreamProviderElement<List<Channel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<Channel>> create(Ref ref) {
    return channelListWatch(ref);
  }
}

String _$channelListWatchHash() => r'e36486b95d88159eb9b3f503a927f9b80183358e';
