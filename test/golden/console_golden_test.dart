@Tags(['golden'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/console/app/console_shell.dart';
import 'package:puntland/console/core/providers/console_providers.dart';
import 'package:puntland/console/core/widgets/status_badge.dart';
import 'package:puntland/console/features/auth/domain/entities/console_user.dart';
import 'package:puntland/console/features/auth/presentation/pages/sign_in_page.dart';
import 'package:puntland/core/providers/preferences_providers.dart';
import 'package:puntland/core/theme/theme_context.dart';
import 'package:puntland/core/theme/tokens.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/golden.dart';

/// Console foundation: the sign-in screen at both widths, the rail as each
/// role sees it, and the status badge set.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(loadAppFonts);

  Future<List<Override>> baseOverrides() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    return [sharedPreferencesProvider.overrideWithValue(prefs)];
  }

  group('sign in', () {
    for (final (name, width, height) in <(String, double, double)>[
      ('desktop_1280', 1280, 800),
      ('compact_390', 390, 844),
    ]) {
      testWidgets('console · sign in · $name', (tester) async {
        await pumpGolden(
          tester,
          const SignInPage(),
          width: width,
          height: height,
          overrides: await baseOverrides(),
        );
        await expectLater(
          find.byType(SignInPage),
          matchesGoldenFile('../goldens/console_signin_$name.png'),
        );
      });
    }
  });

  group('shell by role', () {
    // The rail is capability-gated, so each role sees a different set of
    // destinations. These frames are how that stays honest.
    //
    // The signed-in state is injected rather than driven through the sign-in
    // flow. That flow is deliberately asynchronous, and a widget test's fake
    // clock never advances the real `Future.delayed` inside it — driving it
    // here hangs `pumpAndSettle` rather than failing. `auth_flow_test.dart`
    // covers the flow itself.
    for (final role in ConsoleRole.values) {
      testWidgets('console · rail · ${role.name}', (tester) async {
        await pumpGolden(
          tester,
          Builder(
            builder: (context) => ConsoleShell(
              currentRoute: '/overview',
              onNavigate: (_) {},
              articleBadge: 12,
              child: ColoredBox(
                color: context.scheme.surfaceContainerLow,
                child: const SizedBox.expand(),
              ),
            ),
          ),
          width: 1280,
          height: 800,
          overrides: [
            ...await baseOverrides(),
            authControllerProvider.overrideWith(() => _SignedInAuth(role)),
          ],
        );

        await expectLater(
          find.byType(ConsoleShell),
          matchesGoldenFile('../goldens/console_rail_${role.name}.png'),
        );
      });
    }
  });

  testWidgets('console · status badges', (tester) async {
    await pumpGolden(
      tester,
      Builder(
        builder: (context) => ColoredBox(
          color: context.scheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(Spacing.gutter),
            child: Wrap(
              spacing: Spacing.chip,
              runSpacing: Spacing.chip,
              children: [
                for (final kind in BadgeKind.values) StatusBadge(kind: kind),
              ],
            ),
          ),
        ),
      ),
      width: 520,
      height: 140,
      overrides: await baseOverrides(),
    );
    await expectLater(
      find.byType(Wrap),
      matchesGoldenFile('../goldens/console_status_badges.png'),
    );
  });
}

/// Starts already signed in as [role].
class _SignedInAuth extends AuthController {
  _SignedInAuth(this.role);

  final ConsoleRole role;

  @override
  AuthState build() => SignedIn(
    ConsoleUser(
      id: 'u-${role.name}',
      name: switch (role) {
        ConsoleRole.journalist => 'F. Xasan',
        ConsoleRole.editor => 'A. Yuusuf',
        ConsoleRole.operations => 'M. Cali',
        ConsoleRole.admin => 'S. Warsame',
      },
      email: '${role.name}@pltv.so',
      role: role,
    ),
  );
}
