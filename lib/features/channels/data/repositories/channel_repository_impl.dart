import '../../../../core/api/puntland_api.dart';
import '../../../../core/realtime/realtime_client.dart';
import '../../../../core/realtime/realtime_event.dart';
import '../../../../core/realtime/realtime_watch.dart';
import '../../domain/entities/channel.dart';
import '../../domain/repositories/channel_repository.dart';

class ChannelRepositoryImpl implements ChannelRepository {
  const ChannelRepositoryImpl(this._api, this._realtime, {this.onDispose});

  final PuntlandApi _api;
  final RealtimeClient _realtime;

  /// See [LiveRepositoryImpl.onDispose].
  final void Function(void Function())? onDispose;

  @override
  Future<List<Channel>> channels() async {
    final rows = await _api.fetchChannels();
    return rows
        .map(
          (dto) => Channel(
            key: dto.key,
            name: dto.name,
            hasTv: dto.hasTv,
            hasRadio: dto.hasRadio,
            isLive: dto.isLive,
            radioOnAir: dto.radioOnAir,
            nowPlayingTitle: dto.nowPlayingTitle,
          ),
        )
        .toList(growable: false);
  }

  @override
  Stream<List<Channel>> watch() => watchRealtime<List<Channel>>(
    client: _realtime,
    topic: RealtimeTopic.channels,
    fetch: channels,
    // Always a refetch. What changed could be a rename, a reorder, a new
    // channel or a deleted one, in either language — and the list endpoint
    // answers all of that in one request, so describing the change in the
    // payload would be a second, weaker copy of it.
    apply: (_, _) => null,
    onDispose: onDispose,
  );
}
