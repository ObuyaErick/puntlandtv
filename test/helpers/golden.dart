import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/core/l10n/l10n.dart';
import 'package:puntland/core/l10n/so_material_localizations.dart';
import 'package:puntland/core/theme/app_theme.dart';
import 'package:riverpod/misc.dart' show Override;

/// Shared harness for golden renders.
///
/// Run `flutter test --update-goldens test/golden` to regenerate.
///
/// The real bundled fonts are loaded first. Without that, goldens render in
/// the test fallback font and tell you nothing about typography or about the
/// line lengths that drive Somali overflow — and every icon becomes an empty
/// box, which looks like a passing test and is not one.
Future<void> loadAppFonts() async {
  for (final family in {
    'IBMPlexSans': [
      'IBMPlexSans-Regular',
      'IBMPlexSans-Medium',
      'IBMPlexSans-SemiBold',
      'IBMPlexSans-Bold',
    ],
    'SourceSerif4': [
      'SourceSerif4-Regular',
      'SourceSerif4-Semibold',
      'SourceSerif4-Bold',
    ],
  }.entries) {
    final loader = FontLoader(family.key);
    for (final file in family.value) {
      final bytes = File('assets/fonts/$file.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }

  // Icons come from the SDK cache, not the project. Without this every icon
  // renders as an empty box and the goldens silently stop telling you whether
  // the icon set is right.
  final iconFontPath = _materialIconFontPath();
  if (iconFontPath == null) {
    fail(
      'MaterialIcons-Regular.otf not found under the Flutter SDK. Goldens '
      'would render every icon as an empty box, which looks like a passing '
      'test and is not one.',
    );
  }
  final iconLoader = FontLoader('MaterialIcons')
    ..addFont(
      Future.value(ByteData.sublistView(File(iconFontPath).readAsBytesSync())),
    );
  await iconLoader.load();
}

/// Resolves the SDK root by walking up from the running Dart executable until
/// the material-fonts directory appears.
///
/// Counting `.parent` calls is fragile — it depends on the SDK's internal
/// layout and silently yields the wrong path (and boxes instead of icons)
/// when that shifts. Searching for the thing we actually want does not.
String? _materialIconFontPath() {
  var dir = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 8; i++) {
    final candidate = File(
      '${dir.path}/bin/cache/artifacts/material_fonts/'
      'MaterialIcons-Regular.otf',
    );
    if (candidate.existsSync()) return candidate.path;
    if (dir.parent.path == dir.path) break;
    dir = dir.parent;
  }
  return null;
}

/// Pumps [child] with the app's real theme and localisation wiring.
///
/// [width] defaults to 390dp, but pass the width you actually care about:
/// anything inside an `AspectRatio` derives its height from the device width,
/// so a layout that fits at 390 can overflow at 360 — the most common Android
/// width — and a golden suite pinned to one width will not tell you.
Future<void> pumpGolden(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en', 'US'),
  ThemeData? theme,
  double textScale = 1,
  double width = 390,
  double height = 844,
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = Size(width * 3, height * 3);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: locale,
        theme: theme ?? AppTheme.light(),
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
        home: child,
      ),
    ),
  );
  await tester.pumpAndSettle();
}
