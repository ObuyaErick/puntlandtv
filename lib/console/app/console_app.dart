import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n/l10n.dart';
import '../../core/l10n/so_material_localizations.dart';
import '../../core/providers/preferences_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_context.dart';
import '../../core/theme/tokens.dart';
import '../../features/settings/domain/entities/app_preferences.dart';
import '../core/providers/console_providers.dart';
import '../features/auth/domain/entities/console_user.dart';
import '../features/articles/presentation/pages/article_list_page.dart';
import '../features/auth/presentation/pages/sign_in_page.dart';
import '../features/administration/presentation/pages/app_config_page.dart';
import '../features/administration/presentation/pages/users_page.dart';
import '../features/media/presentation/pages/media_library_page.dart';
import '../features/programs/presentation/pages/programs_page.dart';
import '../features/operations/presentation/pages/categories_page.dart';
import '../features/operations/presentation/pages/live_control_page.dart';
import '../features/operations/presentation/pages/push_composer_page.dart';
import '../features/operations/presentation/pages/schedule_page.dart';
import '../features/overview/presentation/pages/overview_page.dart';
import 'console_shell.dart';

/// The content console.
///
/// Shares the app's theme and localisation wholesale — same tokens, same
/// delegates, same Somali workaround. It is the same product seen from the
/// other side, not a separate one.
class PuntlandConsoleApp extends ConsumerWidget {
  const PuntlandConsoleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themePref = ref.watch(preferencesProvider).theme;

    return MaterialApp(
      title: 'Puntland TV Console',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: switch (themePref) {
        ThemePreference.system => ThemeMode.system,
        ThemePreference.light => ThemeMode.light,
        ThemePreference.dark => ThemeMode.dark,
      },
      locale: locale,
      supportedLocales: const [Locale('en', 'US'), Locale('so')],
      localizationsDelegates: <LocalizationsDelegate<dynamic>>[
        AppL10n.delegate,
        SoMaterialLocalizations.delegate,
        SoCupertinoLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      home: const ConsoleRoot(),
    );
  }
}

/// The auth guard.
///
/// A single switch on [AuthState] rather than route-level redirects: there are
/// exactly two states the console can be in, and making that visible in one
/// place is worth more than a router that can be configured wrongly.
class ConsoleRoot extends ConsumerStatefulWidget {
  const ConsoleRoot({super.key});

  @override
  ConsumerState<ConsoleRoot> createState() => _ConsoleRootState();
}

class _ConsoleRootState extends ConsumerState<ConsoleRoot> {
  var _route = '/overview';

  @override
  void initState() {
    super.initState();
    // Restore before the first frame so a page reload does not bounce a
    // signed-in editor back to the login form.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).restore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    if (state is! SignedIn) return const SignInPage();

    return ConsoleShell(
      currentRoute: _route,
      onNavigate: (route) => setState(() => _route = route),
      child: _routeBody(_route),
    );
  }
}

/// Every rail destination now resolves to a screen. The placeholder below is
/// kept for an unknown route only — a `switch` that cannot fall through is one
/// nobody notices is unreachable when a destination is added.
Widget _routeBody(String route) => switch (route) {
  '/overview' => const OverviewPage(),
  '/articles' => const ArticleListPage(),
  '/live' => const LiveControlPage(),
  '/schedule' => const SchedulePage(),
  '/push' => const PushComposerPage(),
  '/categories' => const CategoriesPage(),
  '/media' => const MediaLibraryPage(),
  '/programs' => const ProgramsPage(),
  '/users' => const UsersPage(),
  '/config' => const AppConfigPage(),
  _ => _ConsolePlaceholder(route: route),
};

/// Reached only by a route with no screen behind it.
///
/// Deliberately explicit about what is missing rather than rendering an empty
/// pane that looks like a bug.
class _ConsolePlaceholder extends StatelessWidget {
  const _ConsolePlaceholder({required this.route});

  final String route;

  @override
  Widget build(BuildContext context) {
    final destination = consoleDestinations().firstWhere(
      (d) => d.route == route,
      orElse: () => consoleDestinations().first,
    );

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.emptyState),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              destination.icon,
              size: 34,
              color: context.scheme.onSurfaceVariant,
            ),
            const SizedBox(height: Spacing.listRhythm),
            Text(
              destination.label(context.l10n),
              style: context.text.title.copyWith(color: context.scheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
