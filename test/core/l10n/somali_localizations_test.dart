import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/core/l10n/app_date_format.dart';
import 'package:puntland/core/l10n/l10n.dart';
import 'package:puntland/core/l10n/so_material_localizations.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('Somali localisation gap', () {
    // Flutter bundles Material translations for 116 locales and Somali is not
    // among them. These tests pin the workaround: if someone removes our
    // delegate, or a future SDK adds real Somali support and makes it
    // redundant, this is where that shows up — rather than in a Somali user's
    // dialog rendering in English.
    test('flutter_localizations still does not support Somali', () {
      expect(
        GlobalMaterialLocalizations.delegate.isSupported(const Locale('so')),
        isFalse,
        reason:
            'If this now passes, the SDK has added Somali — re-evaluate '
            'whether SoMaterialLocalizations is still needed.',
      );
    });

    test('our delegate supports Somali and nothing else', () {
      expect(
        SoMaterialLocalizations.delegate.isSupported(const Locale('so')),
        isTrue,
      );
      expect(
        SoMaterialLocalizations.delegate.isSupported(const Locale('en')),
        isFalse,
      );
    });

    testWidgets('framework strings resolve to Somali, not English', (
      tester,
    ) async {
      late MaterialLocalizations material;

      await pumpApp(
        tester,
        Builder(
          builder: (context) {
            material = MaterialLocalizations.of(context);
            return const SizedBox();
          },
        ),
        locale: const Locale('so'),
      );

      expect(material.cancelButtonLabel, 'Jooji');
      expect(material.okButtonLabel, 'Haa');
      expect(material.backButtonTooltip, isNot('Back'));
    });

    testWidgets('app strings resolve in both locales', (tester) async {
      for (final (locale, expected) in [
        (const Locale('en', 'US'), 'Watch live'),
        (const Locale('so'), 'Daawo tooska ah'),
      ]) {
        late AppL10n l10n;
        await pumpApp(
          tester,
          Builder(
            builder: (context) {
              l10n = context.l10n;
              return const SizedBox();
            },
          ),
          locale: locale,
        );
        expect(l10n.watchLive, expected);
      }
    });
  });

  group('AppDateFormat', () {
    final date = DateTime(2026, 8, 30, 8, 12);

    test('formats Somali dates without intl, which has no Somali data', () {
      expect(AppDateFormat.byline(date, 'so'), '30 Ogosto 2026, 08:12');
      expect(AppDateFormat.dayMonth(date, 'so'), '30 Ogo');
      // 30 Aug 2026 is a Sunday.
      expect(AppDateFormat.weekdayDayMonth(date, 'so'), 'Axad, 30 Ogosto');
    });

    test('delegates to intl for English', () {
      expect(AppDateFormat.byline(date, 'en'), '30 Aug 2026, 08:12');
    });
  });
}
