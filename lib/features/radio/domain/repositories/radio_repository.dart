import '../entities/radio_station.dart';

abstract interface class RadioRepository {
  Future<RadioStation> station(String key);

  /// The station, kept current.
  ///
  /// Radio had no refresh of any kind before this: a single future, no timer
  /// and no playback-failure listener, so a station going off air left the
  /// listener on a dead stream indefinitely.
  Stream<RadioStation> watch(String key);
}
