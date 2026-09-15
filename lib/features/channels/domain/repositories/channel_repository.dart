import '../entities/channel.dart';

abstract interface class ChannelRepository {
  /// Published channels, in the order the newsroom set.
  Future<List<Channel>> channels();
}
