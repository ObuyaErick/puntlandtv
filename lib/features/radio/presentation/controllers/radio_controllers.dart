import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../domain/entities/radio_station.dart';

part 'radio_controllers.g.dart';

@Riverpod(keepAlive: true)
Future<RadioStation> radioStation(Ref ref) {
  return ref.watch(radioRepositoryProvider).station();
}
