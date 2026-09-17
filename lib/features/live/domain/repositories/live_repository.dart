import '../entities/live_channel.dart';

abstract interface class LiveRepository {
  Future<LiveChannel> channel(String key);

  /// The channel's status, kept current.
  ///
  /// A stream rather than a future because "is this channel on air" is not a
  /// question with one answer — it changes while the viewer is watching, and
  /// the whole point of the realtime layer is that they find out in about a
  /// second rather than up to thirty-three.
  ///
  /// The stream does not end when the connection drops and does not error on a
  /// failed re-check: the player is still showing something valid, and tearing
  /// it down would turn a blip into a black screen.
  Stream<LiveChannel> watch(String key);
}
