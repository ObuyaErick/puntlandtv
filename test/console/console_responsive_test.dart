import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/console/core/admin_api/fixture_admin_api.dart';
import 'package:puntland/console/core/providers/console_providers.dart';
import 'package:puntland/console/features/administration/presentation/pages/app_config_page.dart';
import 'package:puntland/console/features/administration/presentation/pages/users_page.dart';
import 'package:puntland/console/features/articles/presentation/pages/article_list_page.dart';
import 'package:puntland/console/features/auth/domain/entities/console_user.dart';
import 'package:puntland/console/features/media/presentation/pages/media_library_page.dart';
import 'package:puntland/console/features/operations/presentation/pages/categories_page.dart';
import 'package:puntland/console/features/operations/presentation/pages/live_control_page.dart';
import 'package:puntland/console/features/operations/presentation/pages/push_composer_page.dart';
import 'package:puntland/console/features/operations/presentation/pages/schedule_page.dart';
import 'package:puntland/console/features/overview/presentation/pages/overview_page.dart';
import 'package:puntland/console/features/programs/presentation/pages/programs_page.dart';
import 'package:puntland/core/l10n/l10n.dart';
import 'package:puntland/core/l10n/so_material_localizations.dart';
import 'package:puntland/core/providers/preferences_providers.dart';
import 'package:puntland/core/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SignedInAs extends AuthController {
  _SignedInAs(this.role);

  final ConsoleRole role;

  @override
  AuthState build() => SignedIn(
    ConsoleUser(id: 'u', name: 'A. Yuusuf', email: 'a@pltv.so', role: role),
  );
}

/// Every console screen, at every width the console is used at, in both
/// languages.
///
/// A duty editor opens this on a phone at 23:00; a 360dp portrait window is a
/// supported size, not a degraded one. The screens are pumped into a very tall
/// viewport on purpose — a lazy list only lays out what is on screen, so a
/// section that overflows below the fold passes a naive pump and fails for the
/// person who scrolls to it.
///
/// Somali is not decoration either: it is the longer language, and three of
/// the overflows this test was written to catch only appeared in `so`.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('so');
    await initializeDateFormatting('en_US');
  });

  final screens = <String, Widget Function()>{
    'overview': OverviewPage.new,
    'articles': ArticleListPage.new,
    'media': MediaLibraryPage.new,
    'programs': ProgramsPage.new,
    'schedule': SchedulePage.new,
    'live control': LiveControlPage.new,
    'categories': CategoriesPage.new,
    'push': PushComposerPage.new,
    'users': UsersPage.new,
    'app config': AppConfigPage.new,
  };

  // 320 is the narrowest phone still in the field; the rest walk each side of
  // the medium (600) and expanded (840) breakpoints, where a screen swaps
  // between its card and table layouts.
  const widths = [
    320.0,
    360.0,
    412.0,
    600.0,
    768.0,
    840.0,
    900.0,
    1024.0,
    1280.0,
    1440.0,
  ];

  for (final locale in const [Locale('en', 'US'), Locale('so')]) {
    for (final width in widths) {
      for (final entry in screens.entries) {
        testWidgets(
          '${entry.key} lays out at ${width.toInt()}dp in ${locale.languageCode}',
          (tester) async {
            final errors = <FlutterErrorDetails>[];
            final prior = FlutterError.onError;
            FlutterError.onError = errors.add;
            addTearDown(() => FlutterError.onError = prior);

            SharedPreferences.setMockInitialValues({});
            final prefs = await SharedPreferences.getInstance();
            tester.view.physicalSize = Size(width * 3, 3000 * 3);
            tester.view.devicePixelRatio = 3;
            addTearDown(tester.view.reset);

            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  sharedPreferencesProvider.overrideWithValue(prefs),
                  authControllerProvider.overrideWith(
                    () => _SignedInAs(ConsoleRole.admin),
                  ),
                  adminApiProvider.overrideWithValue(
                    FixtureAdminApi(
                      latency: Duration.zero,
                      now: DateTime(2026, 8, 30, 21, 12),
                    ),
                  ),
                ],
                child: MaterialApp(
                  locale: locale,
                  theme: AppTheme.light(),
                  supportedLocales: const [Locale('en', 'US'), Locale('so')],
                  localizationsDelegates: <LocalizationsDelegate<dynamic>>[
                    AppL10n.delegate,
                    SoMaterialLocalizations.delegate,
                    SoCupertinoLocalizations.delegate,
                    ...GlobalMaterialLocalizations.delegates,
                  ],
                  home: Scaffold(body: entry.value()),
                ),
              ),
            );
            for (var i = 0; i < 4; i++) {
              await tester.pump(Duration.zero);
            }

            expect(
              errors
                  .map((e) => e.exceptionAsString().split('\n').first)
                  .toSet(),
              isEmpty,
              reason: errors.map((e) => e.toString()).join('\n---\n'),
            );
          },
        );
      }
    }
  }
}
