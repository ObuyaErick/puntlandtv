import '../entities/channel.dart';

abstract interface class ChannelRepository {
  /// Published channels, in the order the newsroom set.
  Future<List<Channel>> channels();

  /// The same list, kept current — a channel going on air, being renamed,
  /// reordered or removed all reach the list without the reader reopening it.
  Stream<List<Channel>> watch();
}
