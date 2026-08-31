import 'package:puntland/features/live/domain/entities/live_channel.dart';
import 'package:puntland/features/live/domain/repositories/live_repository.dart';

/// A channel that is on air, with a fixed schedule.
///
/// Times are absolute rather than relative to now: the live page renders them
/// as wall-clock labels, not elapsed time, so a fixed schedule is stable in
/// goldens where a relative one would not be.
class FakeLiveRepository implements LiveRepository {
  const FakeLiveRepository({this.isLive = true});

  final bool isLive;

  @override
  Future<LiveChannel> channel() async {
    final base = DateTime(2026, 8, 31, 21);
    return LiveChannel(
      isLive: isLive,
      streamUrl: isLive ? 'https://example.invalid/live.m3u8' : null,
      offlineMessage: isLive
          ? null
          : 'Baahintu waxay dib u bilaabaneysaa 18:00',
      nowPlaying: ScheduleEntry(
        title: 'Warbaahinta Fiidka — Evening News',
        startsAt: base,
        endsAt: base.add(const Duration(hours: 1)),
        subtitle:
            'The main evening bulletin from the PLTV newsroom in Garowe, '
            'with regional and international reports.',
        genre: 'News',
      ),
      upNext: [
        ScheduleEntry(
          title: 'Dood Furan — Open Debate',
          startsAt: base.add(const Duration(hours: 1)),
          endsAt: base.add(const Duration(hours: 2)),
          genre: 'Current affairs',
        ),
        ScheduleEntry(
          title: 'Wararka Habeenkii — Late News',
          startsAt: base.add(const Duration(hours: 2)),
          endsAt: base.add(const Duration(hours: 2, minutes: 30)),
          genre: 'News',
        ),
      ],
    );
  }
}
