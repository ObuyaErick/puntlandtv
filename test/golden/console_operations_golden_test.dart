@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/console/core/admin_api/fixture_admin_api.dart';
import 'package:puntland/console/core/providers/console_providers.dart';
import 'package:puntland/console/features/auth/domain/entities/console_user.dart';
import 'package:puntland/console/core/admin_api/dto/push_dto.dart';
import 'package:puntland/console/features/operations/presentation/controllers/push_controller.dart';
import 'package:puntland/console/features/operations/presentation/pages/categories_page.dart';
import 'package:puntland/console/features/operations/presentation/pages/live_control_page.dart';
import 'package:puntland/console/features/operations/presentation/pages/push_composer_page.dart';
import 'package:puntland/console/features/operations/presentation/pages/schedule_page.dart';
import 'package:puntland/core/providers/preferences_providers.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/golden.dart';

class _SignedInAs extends AuthController {
  _SignedInAs(this.role);

  final ConsoleRole role;

  @override
  AuthState build() => SignedIn(
    ConsoleUser(
      id: 'u-${role.name}',
      name: 'A. Yuusuf',
      email: 'a@pltv.so',
      role: role,
    ),
  );
}

/// A draft with the Somali half written and the English half missing — the
/// state the composer exists to refuse.
class _HalfWrittenDraft extends PushDraft {
  @override
  PushDraftDto build() => const PushDraftDto(
    messages: {
      'so': PushMessageDto(
        title: 'Warar deg deg: dayactirka wadada weyn oo dhammaaday',
        body: 'Taabo si aad u akhrido warbixinta buuxda.',
      ),
      'en': PushMessageDto(title: 'Breaking: main highway repairs completed'),
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadAppFonts);

  Future<List<Override>> baseOverrides({
    ConsoleRole role = ConsoleRole.operations,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authControllerProvider.overrideWith(() => _SignedInAs(role)),
      consoleClockProvider.overrideWithValue(
        () => DateTime(2026, 8, 30, 21, 4),
      ),
      adminApiProvider.overrideWithValue(
        FixtureAdminApi(
          latency: Duration.zero,
          now: DateTime(2026, 8, 30, 21, 12),
        ),
      ),
    ];
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(Duration.zero);
    await tester.pump();
  }

  testWidgets('console · push composer · half written', (tester) async {
    await pumpGolden(
      tester,
      const Scaffold(body: PushComposerPage()),
      width: 1440,
      height: 1000,
      overrides: [
        ...await baseOverrides(role: ConsoleRole.editor),
        pushDraftProvider.overrideWith(_HalfWrittenDraft.new),
      ],
    );
    await settle(tester);
    await expectLater(
      find.byType(PushComposerPage),
      matchesGoldenFile('../goldens/console_push_half_written.png'),
    );
  });

  testWidgets('console · live control', (tester) async {
    await pumpGolden(
      tester,
      const Scaffold(body: LiveControlPage()),
      width: 1200,
      height: 1100,
      overrides: await baseOverrides(),
    );
    await settle(tester);
    await expectLater(
      find.byType(LiveControlPage),
      matchesGoldenFile('../goldens/console_live_control.png'),
    );
  });

  testWidgets('console · schedule with gap and overlap', (tester) async {
    await pumpGolden(
      tester,
      const Scaffold(body: SchedulePage()),
      width: 1200,
      height: 900,
      overrides: await baseOverrides(),
    );
    await settle(tester);
    await expectLater(
      find.byType(SchedulePage),
      matchesGoldenFile('../goldens/console_schedule.png'),
    );
  });

  testWidgets('console · categories', (tester) async {
    await pumpGolden(
      tester,
      const Scaffold(body: CategoriesPage()),
      width: 1200,
      height: 700,
      overrides: await baseOverrides(role: ConsoleRole.admin),
    );
    await settle(tester);
    await expectLater(
      find.byType(CategoriesPage),
      matchesGoldenFile('../goldens/console_categories.png'),
    );
  });
}
