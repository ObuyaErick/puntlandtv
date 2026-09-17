import '../../../../core/api/dto/live_dto.dart';
import '../../../../core/api/puntland_api.dart';
import '../../../../core/realtime/realtime_client.dart';
import '../../../../core/realtime/realtime_event.dart';
import '../../../../core/realtime/realtime_watch.dart';
import '../../domain/entities/live_channel.dart';
import '../../domain/repositories/live_repository.dart';

class LiveRepositoryImpl implements LiveRepository {
  const LiveRepositoryImpl(this._api, this._realtime, {this.onDispose});

  final PuntlandApi _api;
  final RealtimeClient _realtime;

  /// The owning provider's `onDispose`. See [watchRealtime] — a fallback poll
  /// has to stop when the provider goes, not when a future resolves.
  final void Function(void Function())? onDispose;

  @override
  Future<LiveChannel> channel(String key) async {
    final dto = await _api.fetchLiveStatus(key);
    return LiveChannel(
      key: dto.channelKey,
      name: dto.channelName,
      isLive: dto.isLive,
      streamUrl: dto.streamUrl,
      offlineMessage: dto.offlineMessage,
      resumesAt: dto.resumesAt,
      nowPlaying: dto.nowPlaying?.toEntity(),
      upNext: dto.upNext.map((e) => e.toEntity()).toList(growable: false),
    );
  }

  @override
  Stream<LiveChannel> watch(String key) => watchRealtime<LiveChannel>(
    client: _realtime,
    topic: RealtimeTopic.channel(key),
    fetch: () => channel(key),
    apply: _applyLiveChanged,
    onDispose: onDispose,
  );
}

/// Folds a `live.changed` event into the channel on screen.
///
/// Going **on air** is applied inline: the event carries `stream_url`, so the
/// player starts on the next frame with no round trip — which is the entire
/// point of the phase.
///
/// Going **off air** returns null, which asks for a refetch. What replaces the
/// video is a localised slate and a schedule, and one event is fanned out to
/// every viewer in both languages at once, so it cannot carry them. The server
/// says as much with `refetch: true`; this honours the flag rather than
/// second-guessing it, so a later event that *can* be applied inline needs no
/// change here.
LiveChannel? _applyLiveChanged(LiveChannel current, RealtimeEvent event) {
  if (event.name != RealtimeEventName.liveChanged) return null;
  if (event.boolean('refetch', orElse: true)) return null;

  return current.copyWith(
    isLive: event.boolean('is_live'),
    streamUrl: event.string('stream_url'),
  );
}

extension on ScheduleEntryDto {
  ScheduleEntry toEntity() => ScheduleEntry(
    title: title,
    startsAt: startsAt,
    endsAt: endsAt,
    subtitle: subtitle,
    genre: genre,
  );
}
