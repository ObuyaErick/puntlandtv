import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../../core/realtime/realtime_event.dart';
import '../../../../../core/realtime/realtime_watch.dart';
import '../../../../core/admin_api/dto/channel_dto.dart';
import '../../../../core/providers/console_providers.dart';
import 'broadcast_control_provider.dart';

part 'channel_controller.g.dart';

/// Every channel, published or not, in the order readers see them.
///
/// Auto-disposed rather than kept alive, unlike the category list: a channel's
/// on-air state moves on its own — an encoder connects, the signal drops — so
/// a screen that comes back to the list should read it again rather than show
/// what it looked like the last time anyone looked.
@riverpod
Future<List<ChannelDto>> channelList(Ref ref) =>
    ref.watch(adminApiProvider).fetchChannels();

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
@riverpod
Stream<List<ChannelDto>> channelListWatch(Ref ref) {
  return watchRealtime<List<ChannelDto>>(
    client: ref.watch(consoleRealtimeClientProvider),
    topic: RealtimeTopic.channels,
    fetch: () => ref.read(adminApiProvider).fetchChannels(),
    apply: (_, _) => null,
    onDispose: ref.onDispose,
  );
}

/// Writes against the channel list.
///
/// Each one invalidates the list rather than setting it from the response —
/// the same choice the category actions make, so a screen watching the list
/// gets one fresh read rather than a patched copy. Both list providers, because
/// the table watches the realtime one and live control's switcher reads the
/// plain one: an operator who just pressed save should see the result at the
/// speed of the response, not at the speed of a round trip through Redis. `keepAlive` because nothing
/// watches it: under auto-dispose the notifier would be gone before the
/// awaited write returned.
@Riverpod(keepAlive: true)
class ChannelActions extends _$ChannelActions {
  @override
  void build() {}

  Future<void> create({
    required String key,
    required ChannelSettingsDto settings,
  }) async {
    await ref
        .read(adminApiProvider)
        .createChannel(key: key, settings: settings);
    ref
      ..invalidate(channelListProvider)
      ..invalidate(channelListWatchProvider);
  }

  /// Changes a channel's settings. Its control room reads the name, the
  /// published flag and what it carries, so that is re-read too.
  Future<void> update(String key, ChannelSettingsDto settings) async {
    await ref.read(adminApiProvider).updateChannel(key, settings);
    ref
      ..invalidate(channelListProvider)
      ..invalidate(channelListWatchProvider)
      ..invalidate(broadcastControlWatchProvider(key));
  }

  /// Puts the channels in [keys] order — every key, once.
  Future<void> reorder(List<String> keys) async {
    await ref.read(adminApiProvider).reorderChannels(keys);
    ref
      ..invalidate(channelListProvider)
      ..invalidate(channelListWatchProvider);
  }

  /// Switches a channel's TV off air, from the channel list.
  ///
  /// Through the same broadcast write the control room uses, so the same
  /// slate gate applies: a channel whose off-air message is not written in
  /// every language is refused rather than taken down to a dead player.
  Future<void> takeOffAir(String key) async {
    final api = ref.read(adminApiProvider);
    final control = await api.fetchBroadcastControl(key);
    await api.saveBroadcastControl(key, control.copyWith(tvOnAir: false));
    ref
      ..invalidate(channelListProvider)
      ..invalidate(channelListWatchProvider)
      ..invalidate(broadcastControlWatchProvider(key));
  }

  Future<void> delete(String key) async {
    await ref.read(adminApiProvider).deleteChannel(key);
    ref
      ..invalidate(channelListProvider)
      ..invalidate(channelListWatchProvider)
      ..invalidate(broadcastControlWatchProvider(key));
  }
}
