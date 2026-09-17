import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../domain/entities/channel.dart';

part 'channel_controllers.g.dart';

/// Every published channel, in the newsroom's order.
///
/// Kept alive, and shared by both tabs: Live TV and Radio are two filters over
/// this one list, so switching between them costs no request.
@Riverpod(keepAlive: true)
Future<List<Channel>> channelList(Ref ref) {
  return ref.watch(channelRepositoryProvider).channels();
}

/// The list, kept current while it is on screen.
///
/// The badges are the reason to open this screen — which channel is live now —
/// and they now move on their own: `channels.changed` for the list itself, and
/// the same fallback poll behind it that the live page has. See
/// `ChannelRepositoryImpl.watch`.
@riverpod
Stream<List<Channel>> channelListWatch(Ref ref) {
  return ref.watch(channelRepositoryProvider).watch();
}
