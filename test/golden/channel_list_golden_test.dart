@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/core/providers/repository_providers.dart';
import 'package:puntland/features/channels/domain/entities/channel.dart';
import 'package:puntland/features/channels/presentation/pages/channel_list_page.dart';

import '../helpers/fake_repositories.dart';
import '../helpers/golden.dart';

/// The channel list as a list of rows on a phone and as tiles once there is
/// room for two columns, on both tabs and in both locales.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadAppFonts);

  Future<void> pumpList(
    WidgetTester tester, {
    required ChannelMedium medium,
    required double width,
    required double height,
    Locale locale = const Locale('en', 'US'),
    double textScale = 1,
  }) => pumpGolden(
    tester,
    ChannelListPage(medium: medium),
    width: width,
    height: height,
    locale: locale,
    textScale: textScale,
    overrides: [
      channelRepositoryProvider.overrideWithValue(
        const FakeChannelRepository(),
      ),
    ],
  );

  const cases = <(String, ChannelMedium, double, double, Locale)>[
    ('tv_compact_390', ChannelMedium.tv, 390, 844, Locale('en', 'US')),
    ('tv_medium_768', ChannelMedium.tv, 768, 1024, Locale('en', 'US')),
    ('radio_compact_390', ChannelMedium.radio, 390, 844, Locale('en', 'US')),
    ('tv_compact_so', ChannelMedium.tv, 390, 844, Locale('so')),
    ('radio_medium_so', ChannelMedium.radio, 768, 1024, Locale('so')),
  ];

  for (final (name, medium, width, height, locale) in cases) {
    testWidgets('channel list · $name', (tester) async {
      await pumpList(
        tester,
        medium: medium,
        width: width,
        height: height,
        locale: locale,
      );
      await expectLater(
        find.byType(ChannelListPage),
        matchesGoldenFile('../goldens/channel_list_$name.png'),
      );
    });
  }

  testWidgets('channel list · 320dp · so · 130% text', (tester) async {
    await pumpList(
      tester,
      medium: ChannelMedium.tv,
      width: 320,
      height: 568,
      locale: const Locale('so'),
      textScale: 1.3,
    );
    await expectLater(
      find.byType(ChannelListPage),
      matchesGoldenFile('../goldens/channel_list_so_130.png'),
    );
  });
}
