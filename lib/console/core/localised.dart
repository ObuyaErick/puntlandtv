import 'package:material_ui/material_ui.dart';

import '../../core/l10n/l10n.dart';

/// Names of the languages the product supports, in the *active* UI language.
///
/// Distinct from the language picker, which deliberately uses endonyms so a
/// reader can find their own language without being able to read the rest of
/// the UI. Everywhere else — "No English translation", "Somali is behind" —
/// the language name is ordinary prose and follows the active locale like any
/// other word.
String languageName(AppL10n l10n, String code) => switch (code) {
  'so' => l10n.languageNameSomali,
  'en' => l10n.languageNameEnglish,
  _ => code.toUpperCase(),
};

extension LocalisedContext on BuildContext {
  /// The name of [code] in the active UI language.
  String languageNameOf(String code) => languageName(l10n, code);
}
