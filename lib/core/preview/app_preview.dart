import 'package:flutter/widget_previews.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/l10n.dart';
import '../l10n/so_material_localizations.dart';
import '../theme/app_theme.dart';

/// `@Preview` with the app's scaffolding already applied.
///
/// A preview does not run `main()`, so a bare `@Preview` has no
/// `ProviderScope`, no `AppL10n`, no `AppColors`/`AppTypography` extensions and
/// — because `GlobalMaterialLocalizations` is what loads `intl`'s date symbols —
/// every `AppDateFormat` call throws `LocaleDataException`. Use this instead:
///
/// ```dart
/// @AppPreview(size: PreviewSize.phone, name: 'NowPlayingPanel')
/// @AppPreview.somali(size: PreviewSize.phone, name: 'NowPlayingPanel (so)')
/// Widget previewNowPlayingPanel() => ...;
/// ```
final class AppPreview extends Preview {
  const AppPreview({
    super.group,
    super.name,
    super.size,
    super.textScaleFactor,
    super.brightness,
  }) : super(wrapper: englishPreviewWrapper);

  const AppPreview.somali({
    super.group,
    super.name,
    super.size,
    super.textScaleFactor,
    super.brightness,
  }) : super(wrapper: somaliPreviewWrapper);
}

/// Wrappers passed to an annotation must be public top-level functions.
Widget englishPreviewWrapper(Widget child) =>
    _PreviewApp(locale: const Locale('en', 'US'), child: child);

Widget somaliPreviewWrapper(Widget child) =>
    _PreviewApp(locale: const Locale('so'), child: child);

/// Mirrors `app/app.dart` and `test/helpers/pump_app.dart` — same delegates,
/// same order, since Somali rides on our own delegates ahead of the global
/// ones.
class _PreviewApp extends StatelessWidget {
  const _PreviewApp({required this.locale, required this.child});

  final Locale locale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        locale: locale,
        supportedLocales: const [Locale('en', 'US'), Locale('so')],
        localizationsDelegates: <LocalizationsDelegate<dynamic>>[
          AppL10n.delegate,
          SoMaterialLocalizations.delegate,
          SoCupertinoLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        home: Scaffold(body: child),
      ),
    );
  }
}
