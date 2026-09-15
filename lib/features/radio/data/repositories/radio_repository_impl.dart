import '../../../../core/api/puntland_api.dart';
import '../../domain/entities/radio_station.dart';
import '../../domain/repositories/radio_repository.dart';

class RadioRepositoryImpl implements RadioRepository {
  const RadioRepositoryImpl(this._api);

  final PuntlandApi _api;

  @override
  Future<RadioStation> station(String key) async {
    final dto = await _api.fetchRadioStatus(key);
    return RadioStation(
      key: dto.channelKey,
      isOnAir: dto.isOnAir,
      streamUrl: dto.streamUrl,
      name: dto.stationName,
      nowPlaying: dto.nowPlaying,
      frequencyLabel: dto.frequencyLabel,
    );
  }
}
