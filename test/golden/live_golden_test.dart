@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/core/providers/repository_providers.dart';
import 'package:puntland/core/theme/tokens.dart';
import 'package:puntland/features/live/domain/entities/live_channel.dart';
import 'package:puntland/features/live/domain/repositories/live_repository.dart';
import 'package:puntland/features/live/presentation/pages/live_page.dart';
import 'package:puntland/features/live/presentation/widgets/player_controls.dart';
import 'package:puntland/features/player/presentation/controllers/playback_controller.dart';

import '../helpers/golden.dart';

/// A channel that is on air but whose stream never initialises, which is the
/// state the controls render over.
class _FakeLiveRepository implements LiveRepository {
  const _FakeLiveRepository({this.isLive = true});

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
        subtitle: 'Evening News',
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadAppFonts);

  // 360dp is where the controls overflowed by 12px: the player sits in a 16:9
  // box, so its height falls out of the device width. Goldens at the narrowest
  // supported width, the most common Android width, and the design width —
  // the last of which is the only one the original layout actually fitted.
  //
  // These render `PlayerControls` directly rather than through `LivePage`,
  // because the page shows a "Watch live" button until playback starts and the
  // controls would never appear.
  for (final width in <double>[320, 360, 390]) {
    testWidgets('player controls · ${width.toInt()}dp', (tester) async {
      await pumpGolden(
        tester,
        Scaffold(
          backgroundColor: DarkTokens.background,
          body: Column(
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ColoredBox(
                  color: DarkTokens.surfaceRaised,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: PlayerControls(
                          state: const PlaybackState(isPlaying: true),
                          onPlayPause: () {},
                          onMute: () {},
                          onFullscreen: () {},
                          onCollapse: () {},
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        width: width,
        overrides: [
          liveRepositoryProvider.overrideWithValue(const _FakeLiveRepository()),
        ],
      );
      await expectLater(
        find.byType(PlayerControls),
        matchesGoldenFile('../goldens/player_controls_${width.toInt()}.png'),
      );
    });
  }

  testWidgets('live · off air slate · so', (tester) async {
    await pumpGolden(
      tester,
      const LivePage(),
      locale: const Locale('so'),
      overrides: [
        liveRepositoryProvider.overrideWithValue(
          const _FakeLiveRepository(isLive: false),
        ),
      ],
    );
    await expectLater(
      find.byType(LivePage),
      matchesGoldenFile('../goldens/live_offline_so.png'),
    );
  });
}
