// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Every channel, published or not, in the order readers see them.
///
/// Auto-disposed rather than kept alive, unlike the category list: a channel's
/// on-air state moves on its own — an encoder connects, the signal drops — so
/// a screen that comes back to the list should read it again rather than show
/// what it looked like the last time anyone looked.

@ProviderFor(channelList)
final channelListProvider = ChannelListProvider._();

/// Every channel, published or not, in the order readers see them.
///
/// Auto-disposed rather than kept alive, unlike the category list: a channel's
/// on-air state moves on its own — an encoder connects, the signal drops — so
/// a screen that comes back to the list should read it again rather than show
/// what it looked like the last time anyone looked.

final class ChannelListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ChannelDto>>,
          List<ChannelDto>,
          FutureOr<List<ChannelDto>>
        >
    with $FutureModifier<List<ChannelDto>>, $FutureProvider<List<ChannelDto>> {
  /// Every channel, published or not, in the order readers see them.
  ///
  /// Auto-disposed rather than kept alive, unlike the category list: a channel's
  /// on-air state moves on its own — an encoder connects, the signal drops — so
  /// a screen that comes back to the list should read it again rather than show
  /// what it looked like the last time anyone looked.
  ChannelListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'channelListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$channelListHash();

  @$internal
  @override
  $FutureProviderElement<List<ChannelDto>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ChannelDto>> create(Ref ref) {
    return channelList(ref);
  }
}

String _$channelListHash() => r'a415065e661c426b467c46b78869e4d0c34f98df';

/// The same list, kept current from the `channels` topic.
///
/// The table's on-air column is the reason the operations team leaves this
/// screen open, and it used to be a snapshot of whenever they opened it. Now a
/// channel created, renamed, reordered or removed anywhere — by another
/// operator, or by a signal arriving — reaches the table on its own.
///
/// The writes above still invalidate [channelListProvider] directly. They are
/// not waiting to be told about their own change: an operator who just pressed
/// save should see the result at the speed of the response, not at the speed
/// of a round trip through Redis.

@ProviderFor(channelListWatch)
final channelListWatchProvider = ChannelListWatchProvider._();

/// The same list, kept current from the `channels` topic.
///
/// The table's on-air column is the reason the operations team leaves this
/// screen open, and it used to be a snapshot of whenever they opened it. Now a
/// channel created, renamed, reordered or removed anywhere — by another
/// operator, or by a signal arriving — reaches the table on its own.
///
/// The writes above still invalidate [channelListProvider] directly. They are
/// not waiting to be told about their own change: an operator who just pressed
/// save should see the result at the speed of the response, not at the speed
/// of a round trip through Redis.

final class ChannelListWatchProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ChannelDto>>,
          List<ChannelDto>,
          Stream<List<ChannelDto>>
        >
    with $FutureModifier<List<ChannelDto>>, $StreamProvider<List<ChannelDto>> {
  /// The same list, kept current from the `channels` topic.
  ///
  /// The table's on-air column is the reason the operations team leaves this
  /// screen open, and it used to be a snapshot of whenever they opened it. Now a
  /// channel created, renamed, reordered or removed anywhere — by another
  /// operator, or by a signal arriving — reaches the table on its own.
  ///
  /// The writes above still invalidate [channelListProvider] directly. They are
  /// not waiting to be told about their own change: an operator who just pressed
  /// save should see the result at the speed of the response, not at the speed
  /// of a round trip through Redis.
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
  $StreamProviderElement<List<ChannelDto>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ChannelDto>> create(Ref ref) {
    return channelListWatch(ref);
  }
}

String _$channelListWatchHash() => r'3dac5f1853d34add247570fc2cee4f1d76eee886';

/// Writes against the channel list.
///
/// Each one invalidates the list rather than setting it from the response —
/// the same choice the category actions make, so a screen watching the list
/// gets one fresh read rather than a patched copy. `keepAlive` because nothing
/// watches it: under auto-dispose the notifier would be gone before the
/// awaited write returned.

@ProviderFor(ChannelActions)
final channelActionsProvider = ChannelActionsProvider._();

/// Writes against the channel list.
///
/// Each one invalidates the list rather than setting it from the response —
/// the same choice the category actions make, so a screen watching the list
/// gets one fresh read rather than a patched copy. `keepAlive` because nothing
/// watches it: under auto-dispose the notifier would be gone before the
/// awaited write returned.
final class ChannelActionsProvider
    extends $NotifierProvider<ChannelActions, void> {
  /// Writes against the channel list.
  ///
  /// Each one invalidates the list rather than setting it from the response —
  /// the same choice the category actions make, so a screen watching the list
  /// gets one fresh read rather than a patched copy. `keepAlive` because nothing
  /// watches it: under auto-dispose the notifier would be gone before the
  /// awaited write returned.
  ChannelActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'channelActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$channelActionsHash();

  @$internal
  @override
  ChannelActions create() => ChannelActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$channelActionsHash() => r'07f9fe4beddd4c7c130517751bef5bab226d7204';

/// Writes against the channel list.
///
/// Each one invalidates the list rather than setting it from the response —
/// the same choice the category actions make, so a screen watching the list
/// gets one fresh read rather than a patched copy. `keepAlive` because nothing
/// watches it: under auto-dispose the notifier would be gone before the
/// awaited write returned.

abstract class _$ChannelActions extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
