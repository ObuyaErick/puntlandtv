import 'package:material_ui/material_ui.dart';

import 'generated/app_localizations.dart';

export 'generated/app_localizations.dart';

/// `context.l10n.watchLive` instead of `AppL10n.of(context).watchLive`.
extension L10nX on BuildContext {
  AppL10n get l10n => AppL10n.of(this);

  /// The active UI language code — needed wherever formatting must branch on
  /// it (dates, in particular, because `intl` has no Somali data).
  String get languageCode => Localizations.localeOf(this).languageCode;
}
