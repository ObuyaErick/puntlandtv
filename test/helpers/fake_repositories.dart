import 'package:puntland/core/error/failure.dart';
import 'package:puntland/features/channels/domain/entities/channel.dart';
import 'package:puntland/features/channels/domain/repositories/channel_repository.dart';
import 'package:puntland/features/live/domain/entities/live_channel.dart';
import 'package:puntland/features/live/domain/repositories/live_repository.dart';
import 'package:puntland/features/radio/domain/entities/radio_station.dart';
import 'package:puntland/features/radio/domain/repositories/radio_repository.dart';

/// A channel that is on air, with a fixed schedule.
///
/// Times are absolute rather than relative to now: the live page renders them
/// as wall-clock labels, not elapsed time, so a fixed schedule is stable in
/// goldens where a relative one would not be.
class FakeLiveRepository implements LiveRepository {
  const FakeLiveRepository({this.isLive = true});

  final bool isLive;

  @override
  Future<LiveChannel> channel(String key) async {
    final base = DateTime(2026, 8, 31, 21);
    return LiveChannel(
      key: key,
      name: key == 'main' ? 'Puntland TV' : key.toUpperCase(),
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

/// The channel list the fixtures describe: a TV+radio channel that is live, a
/// TV channel off air, and a radio-only station on air.
class FakeChannelRepository implements ChannelRepository {
  const FakeChannelRepository({this.channelList = defaultChannels});

  final List<Channel> channelList;

  static const defaultChannels = [
    Channel(
      key: 'main',
      name: 'Puntland TV',
      hasTv: true,
      hasRadio: true,
      isLive: true,
      radioOnAir: true,
      nowPlayingTitle: 'Warbaahinta Fiidka — Evening News',
    ),
    Channel(key: 'pltv2', name: 'PLTV 2', hasTv: true, hasRadio: false),
    Channel(
      key: 'radio-garowe',
      name: 'Radio Garowe',
      hasTv: false,
      hasRadio: true,
      radioOnAir: true,
      nowPlayingTitle: 'Morning Requests',
    ),
  ];

  @override
  Future<List<Channel>> channels() async => channelList;
}

/// Radio for any key, on or off air. An unknown key is the API's not-found.
class FakeRadioRepository implements RadioRepository {
  const FakeRadioRepository({this.isOnAir = true, this.known = const {'main'}});

  final bool isOnAir;
  final Set<String> known;

  @override
  Future<RadioStation> station(String key) async {
    if (!known.contains(key)) {
      throw const Failure(
        kind: FailureKind.notFound,
        code: 'CHANNEL_NOT_FOUND',
      );
    }
    return RadioStation(
      key: key,
      isOnAir: isOnAir,
      streamUrl: 'https://example.invalid/$key.aac',
      name: 'Radio Puntland',
      nowPlaying: 'Midday Programme',
      frequencyLabel: 'Radio Puntland · 88.5 FM · Garowe',
    );
  }
}
