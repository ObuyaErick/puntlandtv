import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../domain/entities/live_channel.dart';

part 'live_controllers.g.dart';

/// How often the channel is re-checked while someone is actually watching.
///
/// Thirty seconds against a payload of a few hundred bytes. The thing being
/// waited for is a signal drop, and the cost of noticing one late is a viewer
/// staring at a frozen frame — so this is deliberately shorter than the
/// backend's own three-second ingest poll is long.
const liveRefreshInterval = Duration(seconds: 30);

/// The live channel's status and schedule.
///
/// Kept alive so returning to the Live tab does not re-request the manifest.
/// Not polled by itself either — see [liveChannelWatch], which is what adds a
/// timer, and only while there is somebody to notice.
@Riverpod(keepAlive: true)
Future<LiveChannel> liveChannel(Ref ref) {
  return ref.watch(liveRepositoryProvider).channel();
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
@riverpod
Stream<LiveChannel> liveChannelWatch(Ref ref) {
  final controller = StreamController<LiveChannel>();

  Future<void> emit() async {
    try {
      controller.add(await ref.read(liveChannelProvider.future));
    } catch (error, stack) {
      // Surfaced rather than swallowed, but not fatal to the stream: a failed
      // re-check on a bad connection must not tear down a player that is
      // still happily playing buffered segments.
      controller.addError(error, stack);
    }
  }

  unawaited(emit());

  final timer = Timer.periodic(liveRefreshInterval, (_) {
    ref.invalidate(liveChannelProvider);
    unawaited(emit());
  });

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
}
