import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/app/router/route_paths.dart';
import 'package:puntland/core/l10n/l10n.dart';
import 'package:puntland/core/l10n/so_material_localizations.dart';
import 'package:puntland/core/providers/repository_providers.dart';
import 'package:puntland/core/theme/app_theme.dart';
import 'package:puntland/features/channels/domain/entities/channel.dart';
import 'package:puntland/features/channels/presentation/pages/channel_list_page.dart';

import '../../../helpers/fake_repositories.dart';

/// The Live TV and Radio tabs' first screen: one list, filtered by medium,
/// where a tap is a navigation to the channel's player.
void main() {
  late GoRouter router;

  /// Both lists with their player routes registered as `app_router.dart`
  /// registers them, minus the shell. The players are stand-ins: what is under
  /// test is where a tap goes, not what the player draws.
  Future<void> pump(
    WidgetTester tester, {
    String location = Routes.live,
    Size size = const Size(390, 844),
    Locale locale = const Locale('en', 'US'),
    double textScale = 1,
    List<Channel> channels = FakeChannelRepository.defaultChannels,
  }) async {
    tester.view.physicalSize = Size(size.width * 3, size.height * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    router = GoRouter(
      initialLocation: location,
      routes: [
        GoRoute(
          path: Routes.live,
          builder: (_, _) => const ChannelListPage(medium: ChannelMedium.tv),
          routes: [
            GoRoute(
              path: Routes.channelPattern,
              builder: (_, state) =>
                  Text('tv player ${state.pathParameters['channelKey']}'),
            ),
          ],
        ),
        GoRoute(
          path: Routes.radio,
          builder: (_, _) => const ChannelListPage(medium: ChannelMedium.radio),
          routes: [
            GoRoute(
              path: Routes.channelPattern,
              builder: (_, state) =>
                  Text('radio player ${state.pathParameters['channelKey']}'),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          channelRepositoryProvider.overrideWithValue(
            FakeChannelRepository(channelList: channels),
          ),
        ],
        child: MaterialApp.router(
          locale: locale,
          theme: AppTheme.light(),
          supportedLocales: const [Locale('en', 'US'), Locale('so')],
          localizationsDelegates: <LocalizationsDelegate<dynamic>>[
            AppL10n.delegate,
            SoMaterialLocalizations.delegate,
            SoCupertinoLocalizations.delegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(Duration.zero);
    await tester.pump();
  }

  group('filter by medium', () {
    testWidgets('Live TV lists television channels only', (tester) async {
      await pump(tester);

      expect(find.text('Puntland TV'), findsOneWidget);
      expect(find.text('PLTV 2'), findsOneWidget);
      expect(
        find.text('Radio Garowe'),
        findsNothing,
        reason: 'a radio-only station has no television to open',
      );
    });

    testWidgets('Radio lists radio stations only', (tester) async {
      await pump(tester, location: Routes.radio);

      expect(find.text('Puntland TV'), findsOneWidget);
      expect(find.text('Radio Garowe'), findsOneWidget);
      expect(find.text('PLTV 2'), findsNothing);
    });

    testWidgets('Radio shows the schedule only for a radio-only station', (
      tester,
    ) async {
      await pump(tester, location: Routes.radio);

      expect(find.text('Morning Requests'), findsOneWidget);
      expect(
        find.text('Warbaahinta Fiidka — Evening News'),
        findsNothing,
        reason:
            "the list's programme is television's, which is not what a "
            "shared channel's radio is playing",
      );
    });

    testWidgets('each card says whether its medium is on air', (tester) async {
      await pump(tester);

      // Puntland TV is live; PLTV 2 is not.
      expect(find.text('LIVE'), findsOneWidget);
      expect(find.text('OFF AIR'), findsOneWidget);
    });
  });

  group('navigation', () {
    testWidgets('tapping a TV channel opens /live/<key>', (tester) async {
      await pump(tester);

      await tester.tap(find.text('PLTV 2'));
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        Routes.liveChannel('pltv2'),
      );
      expect(find.text('tv player pltv2'), findsOneWidget);
    });

    testWidgets('tapping a station opens /radio/<key>', (tester) async {
      await pump(tester, location: Routes.radio);

      await tester.tap(find.text('Radio Garowe'));
      await tester.pumpAndSettle();

      expect(
        router.routerDelegate.currentConfiguration.uri.path,
        Routes.radioChannel('radio-garowe'),
      );
      expect(find.text('radio player radio-garowe'), findsOneWidget);
    });
  });

  testWidgets('a medium with no channels is an empty state, not a blank', (
    tester,
  ) async {
    await pump(
      tester,
      location: Routes.radio,
      channels: const [
        Channel(key: 'pltv2', name: 'PLTV 2', hasTv: true, hasRadio: false),
      ],
    );

    expect(find.text('No channels right now'), findsOneWidget);
    expect(find.text('PLTV 2'), findsNothing);
  });

  testWidgets('no overflow as a list or a grid, in either locale', (
    tester,
  ) async {
    const sizes = [Size(320, 568), Size(390, 844), Size(768, 1024)];

    for (final location in [Routes.live, Routes.radio]) {
      for (final size in sizes) {
        for (final locale in const [Locale('en', 'US'), Locale('so')]) {
          for (final scale in [1.0, 1.3]) {
            await pump(
              tester,
              location: location,
              size: size,
              locale: locale,
              textScale: scale,
            );
            expect(
              tester.takeException(),
              isNull,
              reason:
                  'overflow on $location at ${size.width}×${size.height} '
                  '· ${locale.languageCode} @ $scale',
            );
          }
        }
      }
    }
  });
}
