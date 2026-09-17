import '../../../../core/api/puntland_api.dart';
import '../../../../core/realtime/realtime_client.dart';
import '../../../../core/realtime/realtime_event.dart';
import '../../../../core/realtime/realtime_watch.dart';
import '../../domain/entities/radio_station.dart';
import '../../domain/repositories/radio_repository.dart';

class RadioRepositoryImpl implements RadioRepository {
  const RadioRepositoryImpl(this._api, this._realtime, {this.onDispose});

  final PuntlandApi _api;
  final RealtimeClient _realtime;

  /// See [LiveRepositoryImpl.onDispose].
  final void Function(void Function())? onDispose;

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

  @override
  Stream<RadioStation> watch(String key) => watchRealtime<RadioStation>(
    client: _realtime,
    // The same topic the television status arrives on — one channel, one
    // subscription, whichever of its two feeds the listener is on.
    topic: RealtimeTopic.channel(key),
    fetch: () => station(key),
    apply: _applyRadioChanged,
    onDispose: onDispose,
  );
}

/// Folds a `radio.changed` event into the station on screen.
///
/// Coming on air carries the stream URL, so a listener who was staring at an
/// off-air station starts playing without asking. Going off air refetches,
/// because the station name and frequency label are localised chrome.
RadioStation? _applyRadioChanged(RadioStation current, RealtimeEvent event) {
  if (event.name != RealtimeEventName.radioChanged) return null;
  if (event.boolean('refetch', orElse: true)) return null;

  return current.copyWith(
    isOnAir: event.boolean('is_live'),
    streamUrl: event.string('stream_url'),
  );
}
