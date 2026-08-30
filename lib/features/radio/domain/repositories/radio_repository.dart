import '../entities/radio_station.dart';

abstract interface class RadioRepository {
  Future<RadioStation> station();
}
