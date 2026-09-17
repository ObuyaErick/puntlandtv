import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../domain/entities/live_channel.dart';

part 'live_controllers.g.dart';

/// One live channel's status and schedule, by key.
///
/// Kept alive so returning to a channel does not re-request the manifest.
/// A one-shot read: [liveChannelWatch] is what stays current.
@Riverpod(keepAlive: true)
Future<LiveChannel> liveChannel(Ref ref, String key) {
  return ref.watch(liveRepositoryProvider).channel(key);
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
@riverpod
Stream<LiveChannel> liveChannelWatch(Ref ref, String key) {
  return ref.watch(liveRepositoryProvider).watch(key);
}
