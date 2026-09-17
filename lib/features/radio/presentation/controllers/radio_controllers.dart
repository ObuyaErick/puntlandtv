import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../domain/entities/radio_station.dart';

part 'radio_controllers.g.dart';

/// One channel's radio station, by key.
@Riverpod(keepAlive: true)
Future<RadioStation> radioStation(Ref ref, String key) {
  return ref.watch(radioRepositoryProvider).station(key);
}

/// The station, kept current while somebody is listening.
///
/// Radio had nothing like this. There was one future provider, no timer and no
/// `PLAYBACK_FAILED` listener, so a station going off air left the listener on
/// a dead stream indefinitely — the television side had grown three separate
/// answers to that problem and radio had none of them.
@riverpod
Stream<RadioStation> radioStationWatch(Ref ref, String key) {
  return ref.watch(radioRepositoryProvider).watch(key);
}
