import '../../../../core/api/dto/live_dto.dart';
import '../../../../core/api/puntland_api.dart';
import '../../domain/entities/live_channel.dart';
import '../../domain/repositories/live_repository.dart';

class LiveRepositoryImpl implements LiveRepository {
  const LiveRepositoryImpl(this._api);

  final PuntlandApi _api;

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
