import '../../../../core/api/puntland_api.dart';
import '../../domain/entities/radio_station.dart';
import '../../domain/repositories/radio_repository.dart';

class RadioRepositoryImpl implements RadioRepository {
  const RadioRepositoryImpl(this._api);

  final PuntlandApi _api;

  @override
  Future<RadioStation> station() async {
    final dto = await _api.fetchRadioStatus();
    return RadioStation(
      streamUrl: dto.streamUrl,
      name: dto.stationName,
      nowPlaying: dto.nowPlaying,
      frequencyLabel: dto.frequencyLabel,
    );
  }
}
