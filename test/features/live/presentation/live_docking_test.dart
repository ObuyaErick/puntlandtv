import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/core/providers/repository_providers.dart';
import 'package:puntland/features/live/presentation/pages/live_page.dart';
import 'package:puntland/features/player/domain/entities/playback_source.dart';
import 'package:puntland/features/player/presentation/controllers/playback_controller.dart';

import '../../../helpers/fake_repositories.dart';
import '../../../helpers/pump_app.dart';

/// Leaving the live page docks the player.
///
/// The interesting half is *when* the write happens. The page is removed while
/// the router is rebuilding the tree, so `deactivate` runs inside the build
/// phase — and a provider written there throws "Tried to modify a provider
/// while the widget tree was building", which reached the viewer as a red
/// screen over the channel list they had just navigated to.
class _StubPlayback extends PlaybackController {
  @override
  PlaybackState build() => const PlaybackState(
    source: PlaybackSource(
      id: 'live:main',
      url: 'https://example.test/main.m3u8',
      kind: PlaybackKind.liveTv,
      title: 'Main',
    ),
    isPlaying: true,
    isExpanded: true,
  );
}

void main() {
  testWidgets('leaving the page docks the player without writing mid-build', (
    tester,
  ) async {
    final showLive = ValueNotifier(true);
    addTearDown(showLive.dispose);

    late PlaybackState state;

    await pumpApp(
      tester,
      Consumer(
        builder: (context, ref, _) {
          state = ref.watch(playbackControllerProvider);
          return ValueListenableBuilder<bool>(
            valueListenable: showLive,
            builder: (context, live, _) => live
                ? const LivePage(channelKey: 'main')
                : const SizedBox.shrink(),
          );
        },
      ),
      overrides: [
        liveRepositoryProvider.overrideWithValue(const FakeLiveRepository()),
        playbackControllerProvider.overrideWith(_StubPlayback.new),
      ],
    );
    await tester.pump();
    expect(state.isExpanded, isTrue);

    // Navigating away: the page leaves the tree during a rebuild.
    showLive.value = false;
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pump();
    expect(state.isExpanded, isFalse, reason: 'player should be docked');
    expect(state.hasSource, isTrue, reason: 'docked, not stopped');
  });
}
