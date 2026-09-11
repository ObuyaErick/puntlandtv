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

String _$channelActionsHash() => r'7214c35aaaa48d785968b84e8e6c50b6e1018099';

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
