// The one file in the console that imports the SDK's Material library.
//
// **Why it exists.** Flutter 3.47 moved Material out of the SDK: this product
// draws its UI from `package:material_ui`, and `package:flutter/material.dart`
// is a *separate copy* of the same library. Two copies means two unrelated
// `Theme`s, two `MaterialLocalizations`, two `ThemeData` types — an inherited
// widget published by one is invisible to the other.
//
// `flutter_quill` has not made that move. Every widget it builds looks up the
// SDK's inherited widgets, and finds nothing in a tree assembled from
// `material_ui`. The failures are not symmetrical, which is what makes this
// worth a file of its own rather than a comment:
//
//   * `Theme.of` and `TextSelectionTheme.of` **fall back silently**. The editor
//     renders, in `ThemeData.fallback()` colours — a blue cursor and a purple
//     selection in a navy console, with nothing logged.
//   * `MaterialLocalizations.of` **throws**, but only when the selection
//     toolbar is first shown. Cut/Copy/Paste is a right-click away from a red
//     screen, and no amount of exercising the editor by typing finds it.
//
// So the bridge republishes, in the SDK's vocabulary, the three things Quill
// reads: a theme carrying the console's real colours, a `Material` host for
// the ink-based widgets inside the editor, and Material localisations for the
// selection toolbar. Everything above and below this widget stays
// `material_ui`.
library;

import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/material.dart' as sdk;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:material_ui/material_ui.dart';

/// Wraps [child] — a `flutter_quill` subtree — in the SDK-Material context it
/// looks for.
///
/// Translates rather than guesses: the cursor and selection colours are the
/// console's own, read from the ambient `material_ui` theme, so the editor
/// matches the screen it sits on instead of Flutter's defaults.
class QuillMaterialBridge extends StatelessWidget {
  const QuillMaterialBridge({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return sdk.Theme(
      data: sdk.ThemeData(
        brightness: scheme.brightness,
        colorScheme: sdk.ColorScheme(
          brightness: scheme.brightness,
          primary: scheme.primary,
          onPrimary: scheme.onPrimary,
          secondary: scheme.secondary,
          onSecondary: scheme.onSecondary,
          error: scheme.error,
          onError: scheme.onError,
          surface: scheme.surface,
          onSurface: scheme.onSurface,
        ),
        textSelectionTheme: sdk.TextSelectionThemeData(
          cursorColor: scheme.primary,
          selectionColor: scheme.primary.withValues(alpha: 0.24),
          selectionHandleColor: scheme.primary,
        ),
      ),
      // `Localizations.override`, which **merges**: it takes the delegates
      // already in scope and prepends these. A bare `Localizations` replaces
      // them instead, and that is not a subtlety — it silently took `AppL10n`
      // away from every widget inside the editor, so the first embed builder to
      // ask `context.l10n` for a string got a null-check failure where an image
      // should have been.
      //
      // Both delegates are wrapped rather than used as shipped, and for the
      // same reason: each one answers `isSupported` from a fixed locale list
      // that does not include Somali, and a delegate that declines is a
      // delegate that is dropped from the scope entirely. The widget then
      // throws for want of something the app plainly configured. It is the
      // majority publishing language that breaks, so an English-only test says
      // everything is fine.
      child: Localizations.override(
        context: context,
        delegates: [
          _ForwardedMaterialLocalizations.delegate(
            MaterialLocalizations.of(context),
          ),
          const _QuillLocalizationsWithFallback(),
        ],
        // Transparent, and `type: transparency` so it paints nothing of its
        // own: the field's own border and fill are drawn by the console, and a
        // second surface underneath them washes the ground out by a shade.
        child: sdk.Material(
          type: sdk.MaterialType.transparency,
          child: child,
        ),
      ),
    );
  }
}


/// `flutter_quill`'s own strings, with English standing in where it has none.
///
/// The package ships translations for a fixed list of locales, and **Somali is
/// not on it** — the same gap `SoMaterialLocalizations` exists to fill for the
/// framework. Used as shipped, `FlutterQuillLocalizations.delegate` declines
/// `so`, is dropped from the scope, and every `QuillSimpleToolbar` button
/// throws `MissingFlutterQuillLocalizationException` while asking for its
/// tooltip. The console is unusable in the language most of this newsroom
/// writes in, and passes every test written in English.
///
/// So: supported everywhere, falling back to the package's English.
///
/// **That fallback is a visible shortfall, not a fix.** A Somali editor gets
/// English tooltips on any `flutter_quill`-supplied toolbar. The console's own
/// [ArticleBodyToolbar] does not have this problem and is not merely a
/// styling choice for that reason: its labels come from this product's ARB
/// files, where Somali is at full parity and gated in CI.
class _QuillLocalizationsWithFallback
    extends LocalizationsDelegate<FlutterQuillLocalizations> {
  const _QuillLocalizationsWithFallback();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<FlutterQuillLocalizations> load(Locale locale) {
    // Delegating rather than naming a concrete class: the package exports the
    // delegate but not its per-locale implementations, and this keeps the
    // English copy the package's to change.
    final resolved = FlutterQuillLocalizations.delegate.isSupported(locale)
        ? locale
        : const Locale('en');
    return FlutterQuillLocalizations.delegate.load(resolved);
  }

  /// The wrapped delegate is stateless and the fallback never changes, so the
  /// resources only need loading once per locale.
  @override
  bool shouldReload(_QuillLocalizationsWithFallback old) => false;
}

/// The SDK's `MaterialLocalizations`, answered from the app's own.
///
/// The app already translates the clipboard menu — `SoMaterialLocalizations`
/// in `core/l10n` supplies the Somali the framework does not ship. Those
/// strings are typed against `material_ui`, so Quill's selection toolbar
/// cannot see them. Rather than translate the same eight words twice and let
/// the two copies drift, this forwards them across the library boundary.
///
/// Everything not listed inherits `sdk.DefaultMaterialLocalizations`, which is
/// English — the same deliberate, visible shortfall `SoMaterialLocalizations`
/// documents, and for the same reason: these are the strings this product
/// actually surfaces, and a wall of forwarded getters for widgets Quill never
/// builds would hide which ones those are.
class _ForwardedMaterialLocalizations extends sdk.DefaultMaterialLocalizations {
  const _ForwardedMaterialLocalizations(this._source);

  /// The app's own localisations, from `package:material_ui`.
  final MaterialLocalizations _source;

  static sdk.LocalizationsDelegate<sdk.MaterialLocalizations> delegate(
    MaterialLocalizations source,
  ) => _ForwardedDelegate(source);

  // The text-selection toolbar, which is the whole of what Quill shows.
  @override
  String get cutButtonLabel => _source.cutButtonLabel;
  @override
  String get copyButtonLabel => _source.copyButtonLabel;
  @override
  String get pasteButtonLabel => _source.pasteButtonLabel;
  @override
  String get selectAllButtonLabel => _source.selectAllButtonLabel;
  @override
  String get lookUpButtonLabel => _source.lookUpButtonLabel;
  @override
  String get searchWebButtonLabel => _source.searchWebButtonLabel;
  @override
  String get shareButtonLabel => _source.shareButtonLabel;
  @override
  String get scanTextButtonLabel => _source.scanTextButtonLabel;
}

class _ForwardedDelegate
    extends sdk.LocalizationsDelegate<sdk.MaterialLocalizations> {
  const _ForwardedDelegate(this.source);

  final MaterialLocalizations source;

  /// Every locale. The app upstream has already decided which locales it
  /// supports and resolved [source] accordingly; declining here would only
  /// leave the scope empty.
  @override
  bool isSupported(Locale locale) => true;

  @override
  SynchronousFuture<sdk.MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture(_ForwardedMaterialLocalizations(source));

  /// Reloads when the app's own localisations change — which is what a
  /// language switch looks like from in here.
  @override
  bool shouldReload(_ForwardedDelegate old) => old.source != source;
}
