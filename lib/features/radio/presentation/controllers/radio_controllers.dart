import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../domain/entities/radio_station.dart';

part 'radio_controllers.g.dart';

/// One channel's radio station, by key.
@Riverpod(keepAlive: true)
Future<RadioStation> radioStation(Ref ref, String key) {
  return ref.watch(radioRepositoryProvider).station(key);
}
