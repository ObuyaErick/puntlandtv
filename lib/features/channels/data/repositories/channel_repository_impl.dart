import '../../../../core/api/puntland_api.dart';
import '../../domain/entities/channel.dart';
import '../../domain/repositories/channel_repository.dart';

class ChannelRepositoryImpl implements ChannelRepository {
  const ChannelRepositoryImpl(this._api);

  final PuntlandApi _api;

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
}
