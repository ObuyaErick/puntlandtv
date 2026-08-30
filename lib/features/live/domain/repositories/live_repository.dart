import '../entities/live_channel.dart';

abstract interface class LiveRepository {
  Future<LiveChannel> channel();
}
