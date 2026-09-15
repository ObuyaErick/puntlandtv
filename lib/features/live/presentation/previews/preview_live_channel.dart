import 'package:puntland/features/live/domain/entities/live_channel.dart';

final _previewNow = DateTime(2026, 9, 12, 18);

final previewChannel = LiveChannel(
  key: 'somali-tv',
  name: 'Somali TV',
  isLive: true,
  streamUrl: 'http://localhost:8888/main/index.m3u8',
  nowPlaying: ScheduleEntry(
    title: 'News at 6',
    subtitle: 'The latest headlines from around the world.',
    startsAt: _previewNow,
    endsAt: _previewNow.add(const Duration(minutes: 30)),
    genre: 'News',
  ),
  upNext: [
    ScheduleEntry(
      title: 'Sports Highlights',
      startsAt: _previewNow.add(const Duration(minutes: 30)),
      endsAt: _previewNow.add(const Duration(minutes: 60)),
      genre: 'Sports',
    ),
    ScheduleEntry(
      title: 'Evening Drama',
      startsAt: _previewNow.add(const Duration(minutes: 60)),
      endsAt: _previewNow.add(const Duration(minutes: 90)),
      genre: 'Drama',
    ),
  ],
);
