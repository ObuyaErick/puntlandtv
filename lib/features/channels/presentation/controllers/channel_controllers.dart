import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../live/presentation/controllers/live_controllers.dart';
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

/// Re-checks the list while it is on screen.
///
/// The list's badges are the reason to open it — which channel is live now —
/// and a channel's encoder can drop or return at any moment with nobody in
/// the console. This is `liveChannelWatch`'s pattern for the same reason: a
/// timer only while somebody is looking, disposed with the screen, at the same
/// [liveRefreshInterval].
@riverpod
Stream<List<Channel>> channelListWatch(Ref ref) {
  final controller = StreamController<List<Channel>>();

  Future<void> emit() async {
    try {
      final channels = await ref.read(channelListProvider.future);
      if (!controller.isClosed) controller.add(channels);
    } catch (error, stack) {
      if (!controller.isClosed) controller.addError(error, stack);
    }
  }

  unawaited(emit());

  final timer = Timer.periodic(liveRefreshInterval, (_) {
    ref.invalidate(channelListProvider);
    unawaited(emit());
  });

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
}
