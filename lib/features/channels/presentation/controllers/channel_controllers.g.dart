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

/// The list, kept current while it is on screen.
///
/// The badges are the reason to open this screen — which channel is live now —
/// and they now move on their own: `channels.changed` for the list itself, and
/// the same fallback poll behind it that the live page has. See
/// `ChannelRepositoryImpl.watch`.

@ProviderFor(channelListWatch)
final channelListWatchProvider = ChannelListWatchProvider._();

/// The list, kept current while it is on screen.
///
/// The badges are the reason to open this screen — which channel is live now —
/// and they now move on their own: `channels.changed` for the list itself, and
/// the same fallback poll behind it that the live page has. See
/// `ChannelRepositoryImpl.watch`.

final class ChannelListWatchProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Channel>>,
          List<Channel>,
          Stream<List<Channel>>
        >
    with $FutureModifier<List<Channel>>, $StreamProvider<List<Channel>> {
  /// The list, kept current while it is on screen.
  ///
  /// The badges are the reason to open this screen — which channel is live now —
  /// and they now move on their own: `channels.changed` for the list itself, and
  /// the same fallback poll behind it that the live page has. See
  /// `ChannelRepositoryImpl.watch`.
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

String _$channelListWatchHash() => r'9be45f72aeeb225f5fcbda301d21db19e8630148';
