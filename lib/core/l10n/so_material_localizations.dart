import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'app_date_format.dart';

/// Somali localizations for the *framework's* own strings.
///
/// Why this file exists: Flutter 3.47 bundles Material/Cupertino translations
/// for 116 locales and **Somali is not one of them**. Without this delegate the
/// app still runs, which is the trap — `MaterialApp` silently falls back to
/// [DefaultMaterialLocalizations], so a user reading a Somali UI hits English
/// on every dialog button, the back-button tooltip, the text-selection menu and
/// the pull-to-refresh announcement. Nothing logs, nothing crashes.
///
/// We override only the strings this app actually surfaces. Anything not
/// overridden inherits the English default, which is a deliberate, visible
/// shortfall rather than a hidden one — add to it as new framework widgets are
/// adopted.
class SoMaterialLocalizations extends DefaultMaterialLocalizations {
  const SoMaterialLocalizations();

  @override
  String get okButtonLabel => 'Haa';
  @override
  String get cancelButtonLabel => 'Jooji';
  @override
  String get closeButtonLabel => 'Xir';
  @override
  String get continueButtonLabel => 'Sii wad';
  @override
  String get backButtonTooltip => 'Dib u noqo';
  @override
  String get closeButtonTooltip => 'Xir';
  @override
  String get deleteButtonTooltip => 'Tirtir';
  @override
  String get moreButtonTooltip => 'Wax dheeraad ah';
  @override
  String get showMenuTooltip => 'Muuji liiska';
  @override
  String get modalBarrierDismissLabel => 'Iska tuur';
  @override
  String get drawerLabel => 'Liiska sooca';
  @override
  String get popupMenuLabel => 'Liiska soo baxa';
  @override
  String get bottomSheetLabel => 'Bogga hoose';
  @override
  String get dialogLabel => 'Sanduuqa wada hadalka';
  @override
  String get alertDialogLabel => 'Digniin';
  @override
  String get searchFieldLabel => 'Raadi';
  @override
  String get refreshIndicatorSemanticLabel => 'La cusbooneysiinayo';

  @override
  String get copyButtonLabel => 'Koobi';
  @override
  String get cutButtonLabel => 'Goo';
  @override
  String get pasteButtonLabel => 'Dhaji';
  @override
  String get selectAllButtonLabel => 'Dhammaan dooro';
  @override
  String get shareButtonLabel => 'Wadaag';
  @override
  String get lookUpButtonLabel => 'Raadi';
  @override
  String get searchWebButtonLabel => 'Internetka ka raadi';

  @override
  String get viewLicensesButtonLabel => 'Fiiri shatiyada';
  @override
  String get licensesPageTitle => 'Shatiyada';

  @override
  String get firstPageTooltip => 'Boggii ugu horreeyay';
  @override
  String get lastPageTooltip => 'Boggii ugu dambeeyay';
  @override
  String get nextPageTooltip => 'Bogga xiga';
  @override
  String get previousPageTooltip => 'Bogga hore';

  @override
  String get nextMonthTooltip => 'Bisha xigta';
  @override
  String get previousMonthTooltip => 'Bishii hore';

  @override
  String tabLabel({required int tabIndex, required int tabCount}) =>
      'Tab $tabIndex ka mid $tabCount';

  // The framework asks for date/month names in pickers and semantics. intl has
  // no Somali data either, so these come from our own table.
  @override
  String formatMonthYear(DateTime date) => AppDateFormat.somaliMonthYear(date);

  @override
  String formatMediumDate(DateTime date) =>
      AppDateFormat.somaliMediumDate(date);

  @override
  String formatFullDate(DateTime date) => AppDateFormat.somaliFullDate(date);

  @override
  List<String> get narrowWeekdays => SomaliCalendar.narrowWeekdays;

  /// Somali weeks start on Saturday in common usage; the framework indexes
  /// [narrowWeekdays] from Sunday, so this stays 0 and the table above is
  /// ordered Sunday-first to match.
  @override
  int get firstDayOfWeekIndex => 6;

  static const LocalizationsDelegate<MaterialLocalizations> delegate =
      _SoMaterialLocalizationsDelegate();
}

class _SoMaterialLocalizationsDelegate
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _SoMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'so';

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture<MaterialLocalizations>(const SoMaterialLocalizations());

  @override
  bool shouldReload(_SoMaterialLocalizationsDelegate old) => false;

  @override
  String toString() => 'SoMaterialLocalizations.delegate(so)';
}

/// Cupertino equivalent. Reached on iOS for text selection and any adaptive
/// widget, so it needs the same treatment.
class SoCupertinoLocalizations extends DefaultCupertinoLocalizations {
  const SoCupertinoLocalizations();

  @override
  String get copyButtonLabel => 'Koobi';
  @override
  String get cutButtonLabel => 'Goo';
  @override
  String get pasteButtonLabel => 'Dhaji';
  @override
  String get selectAllButtonLabel => 'Dhammaan dooro';
  @override
  String get shareButtonLabel => 'Wadaag';
  @override
  String get lookUpButtonLabel => 'Raadi';
  @override
  String get searchWebButtonLabel => 'Internetka ka raadi';
  @override
  String get modalBarrierDismissLabel => 'Iska tuur';
  @override
  String get searchTextFieldPlaceholderLabel => 'Raadi';
  @override
  String get alertDialogLabel => 'Digniin';

  static const LocalizationsDelegate<CupertinoLocalizations> delegate =
      _SoCupertinoLocalizationsDelegate();
}

class _SoCupertinoLocalizationsDelegate
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _SoCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'so';

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      SynchronousFuture<CupertinoLocalizations>(
        const SoCupertinoLocalizations(),
      );

  @override
  bool shouldReload(_SoCupertinoLocalizationsDelegate old) => false;
}
