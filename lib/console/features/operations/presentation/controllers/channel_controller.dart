import 'package:riverpod_annotation/riverpod_annotation.dart';

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

/// Writes against the channel list.
///
/// Each one invalidates the list rather than setting it from the response —
/// the same choice the category actions make, so a screen watching the list
/// gets one fresh read rather than a patched copy. `keepAlive` because nothing
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
    ref.invalidate(channelListProvider);
  }

  /// Changes a channel's settings. Its control room reads the name, the
  /// published flag and what it carries, so that is re-read too.
  Future<void> update(String key, ChannelSettingsDto settings) async {
    await ref.read(adminApiProvider).updateChannel(key, settings);
    ref
      ..invalidate(channelListProvider)
      ..invalidate(broadcastControlProvider(key));
  }

  /// Puts the channels in [keys] order — every key, once.
  Future<void> reorder(List<String> keys) async {
    await ref.read(adminApiProvider).reorderChannels(keys);
    ref.invalidate(channelListProvider);
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
      ..invalidate(broadcastControlProvider(key));
  }

  Future<void> delete(String key) async {
    await ref.read(adminApiProvider).deleteChannel(key);
    ref
      ..invalidate(channelListProvider)
      ..invalidate(broadcastControlProvider(key));
  }
}
