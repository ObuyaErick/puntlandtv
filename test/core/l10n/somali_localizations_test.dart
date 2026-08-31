import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:puntland/core/l10n/app_date_format.dart';
import 'package:puntland/core/l10n/app_number_format.dart';
import 'package:puntland/core/l10n/l10n.dart';
import 'package:puntland/core/theme/tokens.dart';
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

  group('AppNumberFormat', () {
    // The same gap as dates: `intl` has no Somali number data, so grouping
    // has to be done by hand rather than by asking `NumberFormat` for a
    // locale it does not have.
    test('groups thousands in Somali without intl', () {
      expect(AppNumberFormat.decimal(38410, 'so'), '38,410');
      expect(AppNumberFormat.decimal(4182, 'so'), '4,182');
      expect(AppNumberFormat.decimal(999, 'so'), '999');
      expect(AppNumberFormat.decimal(1000000, 'so'), '1,000,000');
    });

    test('delegates to intl for English', () {
      expect(AppNumberFormat.decimal(38410, 'en'), '38,410');
    });

    test('handles zero and negatives', () {
      expect(AppNumberFormat.decimal(0, 'so'), '0');
      expect(AppNumberFormat.decimal(-1500, 'so'), '-1,500');
    });
  });

  group('brand strings', () {
    // The name is a proper noun and stays put; the tagline is a descriptive
    // phrase and follows the active locale. Getting this backwards — because
    // the design canvas happens to be drawn in Somali — leaves an English UI
    // with a Somali line under the logo.
    testWidgets('the tagline follows the active locale', (tester) async {
      final taglines = <String, String>{};

      for (final locale in [const Locale('en', 'US'), const Locale('so')]) {
        await pumpApp(
          tester,
          Builder(
            builder: (context) {
              taglines[locale.languageCode] = context.l10n.tagline;
              return const SizedBox();
            },
          ),
          locale: locale,
        );
      }

      expect(taglines['en'], 'The Voice of the Puntland Government, Somalia');
      expect(taglines['so'], 'Codka Dawladda Puntland, Soomaaliya');
      expect(taglines['en'], isNot(taglines['so']));
    });

    test('the brand name is the same in every locale', () {
      expect(BrandLockup.name, 'Puntland TV');
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
