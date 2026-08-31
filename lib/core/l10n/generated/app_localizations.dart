import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_so.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppL10n
/// returned by `AppL10n.of(context)`.
///
/// Applications need to include `AppL10n.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppL10n.localizationsDelegates,
///   supportedLocales: AppL10n.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppL10n.supportedLocales
/// property.
abstract class AppL10n {
  AppL10n(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppL10n of(BuildContext context) {
    return Localizations.of<AppL10n>(context, AppL10n)!;
  }

  static const LocalizationsDelegate<AppL10n> delegate = _AppL10nDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('so'),
  ];

  /// App name. Brand — never translated.
  ///
  /// In en, this message translates to:
  /// **'Puntland TV'**
  String get appName;

  /// Bottom navigation: news feed tab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// Bottom navigation: live television tab.
  ///
  /// In en, this message translates to:
  /// **'Live TV'**
  String get navLive;

  /// Bottom navigation: video-on-demand tab.
  ///
  /// In en, this message translates to:
  /// **'Programs'**
  String get navPrograms;

  /// Bottom navigation: live radio tab.
  ///
  /// In en, this message translates to:
  /// **'Radio'**
  String get navRadio;

  /// Bottom navigation: bookmarks tab.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get navSaved;

  /// Short live badge shown on the player. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'LIVE'**
  String get live;

  /// Live badge in the app bar and on buttons. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'LIVE NOW'**
  String get liveNow;

  /// Primary button opening the live stream.
  ///
  /// In en, this message translates to:
  /// **'Watch live'**
  String get watchLive;

  /// Overline above the top story on the feed. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'LEAD STORY'**
  String get leadStory;

  /// Pull-to-refresh indicator label.
  ///
  /// In en, this message translates to:
  /// **'Refreshing…'**
  String get refreshing;

  /// Relative timestamp in a card overline. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} MIN AGO} other{{count} MIN AGO}}'**
  String minutesAgo(int count);

  /// Relative timestamp in hours, card overline. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} H} other{{count} H}}'**
  String hoursAgo(int count);

  /// Section heading below an article. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'RELATED STORIES'**
  String get relatedStories;

  /// Link to a category from an article footer.
  ///
  /// In en, this message translates to:
  /// **'More from {category}'**
  String moreFrom(String category);

  /// Opens the OS share sheet.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Bookmark this article.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// State of the bookmark control once saved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get saved;

  /// Estimated reading time in an article byline.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} min read} other{{count} min read}}'**
  String minRead(int count);

  /// Label above the current programme on the live screen. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'NOW PLAYING'**
  String get nowPlaying;

  /// Heading for the rest of today's schedule. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'UP NEXT TODAY'**
  String get upNextToday;

  /// Toggle dropping the video track to save data.
  ///
  /// In en, this message translates to:
  /// **'Audio only'**
  String get audioOnly;

  /// Opens the programme schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get schedule;

  /// Action on the stream-offline slate.
  ///
  /// In en, this message translates to:
  /// **'See schedule'**
  String get seeSchedule;

  /// Shown when the broadcaster is not transmitting.
  ///
  /// In en, this message translates to:
  /// **'The stream is offline'**
  String get streamOfflineTitle;

  /// When transmission returns.
  ///
  /// In en, this message translates to:
  /// **'Broadcast resumes at {time}'**
  String streamOfflineBody(String time);

  /// Player is rebuffering.
  ///
  /// In en, this message translates to:
  /// **'Buffering'**
  String get buffering;

  /// Shown when the player drops to the lowest rendition.
  ///
  /// In en, this message translates to:
  /// **'Slow connection — quality reduced'**
  String get slowConnectionQualityReduced;

  /// Title of the video-on-demand screen.
  ///
  /// In en, this message translates to:
  /// **'Programs'**
  String get programsTitle;

  /// Subtitle under the programmes heading.
  ///
  /// In en, this message translates to:
  /// **'Watch anytime'**
  String get programsSubtitle;

  /// Filter chip showing every programme.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// Plays the most recent episode of a programme.
  ///
  /// In en, this message translates to:
  /// **'Play latest'**
  String get playLatest;

  /// Section heading above an episode list. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'EPISODES'**
  String get episodes;

  /// Episode count badge on programme artwork. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} EP} other{{count} EPS}}'**
  String episodeCount(int count);

  /// Episode sort order.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get sortNewest;

  /// Badge on an episode available offline.
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get downloaded;

  /// Remaining time on a partly watched episode.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} min left} other{{count} min left}}'**
  String minutesLeft(int count);

  /// Episode or programme duration.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} min} other{{count} min}}'**
  String durationMinutes(int count);

  /// Name of the radio service.
  ///
  /// In en, this message translates to:
  /// **'Radio Puntland'**
  String get radioTitle;

  /// Explains background playback and the low bitrate.
  ///
  /// In en, this message translates to:
  /// **'Audio keeps playing when the app is closed — 48 kbps, tuned for 3G.'**
  String get radioBackgroundNote;

  /// Title of the bookmarks screen.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedTitle;

  /// Bookmarks tab for saved articles.
  ///
  /// In en, this message translates to:
  /// **'Articles'**
  String get tabArticles;

  /// Bookmarks tab for downloaded episodes.
  ///
  /// In en, this message translates to:
  /// **'Episodes'**
  String get tabEpisodes;

  /// Chip on a fully cached article.
  ///
  /// In en, this message translates to:
  /// **'Available offline'**
  String get availableOffline;

  /// Placeholder where an image could not be cached. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'NO IMAGE'**
  String get noImage;

  /// Explains a partly cached saved article.
  ///
  /// In en, this message translates to:
  /// **'Text saved · image will load online'**
  String get textSavedImageOnline;

  /// Footer note on the bookmarks screen.
  ///
  /// In en, this message translates to:
  /// **'Saved articles keep their text and images for 30 days. Episodes download only over Wi-Fi.'**
  String get savedRetentionNote;

  /// Offline banner on the bookmarks screen.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{No connection — showing your {count} saved item} other{No connection — showing your {count} saved items}}'**
  String offlineShowingSaved(int count);

  /// Empty state on the bookmarks screen.
  ///
  /// In en, this message translates to:
  /// **'Nothing saved yet'**
  String get emptySavedTitle;

  /// Action from the empty bookmarks state.
  ///
  /// In en, this message translates to:
  /// **'Browse news'**
  String get browseNews;

  /// Title of the settings screen.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Settings section heading. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'GENERAL'**
  String get sectionGeneral;

  /// Settings section heading. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'DATA & PLAYBACK'**
  String get sectionDataPlayback;

  /// Settings section heading. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'ABOUT'**
  String get sectionAbout;

  /// Opens the language picker.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingLanguage;

  /// Opens the theme picker.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingTheme;

  /// Text scale setting, follows the OS.
  ///
  /// In en, this message translates to:
  /// **'Text size'**
  String get settingTextSize;

  /// Toggle reducing video quality on mobile data.
  ///
  /// In en, this message translates to:
  /// **'Data saver'**
  String get settingDataSaver;

  /// Subtitle for the data saver toggle.
  ///
  /// In en, this message translates to:
  /// **'Lower video quality on mobile data'**
  String get settingDataSaverSub;

  /// Toggle restricting downloads to Wi-Fi.
  ///
  /// In en, this message translates to:
  /// **'Download over Wi-Fi only'**
  String get settingWifiOnlyDownloads;

  /// Toggle for breaking-news push notifications.
  ///
  /// In en, this message translates to:
  /// **'Breaking news alerts'**
  String get settingBreakingAlerts;

  /// Value meaning the OS setting is used.
  ///
  /// In en, this message translates to:
  /// **'Follow system'**
  String get followSystem;

  /// Text size value showing the OS scale.
  ///
  /// In en, this message translates to:
  /// **'Follow system ({percent})'**
  String followSystemWithScale(String percent);

  /// Light theme option.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Dark theme option.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Version line at the foot of settings.
  ///
  /// In en, this message translates to:
  /// **'Puntland TV · v{version}'**
  String versionLine(String version);

  /// Title of the language picker sheet. Shown in both languages deliberately, so it is readable whichever locale is active.
  ///
  /// In en, this message translates to:
  /// **'Language · Luqadda'**
  String get languageSheetTitle;

  /// Use the device language.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystemDefault;

  /// English option. Always in English — an endonym.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Somali option. Always in Somali — an endonym.
  ///
  /// In en, this message translates to:
  /// **'Soomaali'**
  String get languageSomali;

  /// Locale code under the English option.
  ///
  /// In en, this message translates to:
  /// **'en-US'**
  String get languageEnglishSub;

  /// Locale detail under the Somali option.
  ///
  /// In en, this message translates to:
  /// **'so · Latin script, LTR'**
  String get languageSomaliSub;

  /// Reassurance in the language sheet.
  ///
  /// In en, this message translates to:
  /// **'The language changes immediately — no restart needed.'**
  String get languageSwitchNote;

  /// Dismisses a sheet or dialog.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Confirms a selection in a sheet.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choose;

  /// Retries a failed request.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// Error state on the feed.
  ///
  /// In en, this message translates to:
  /// **'News could not be loaded'**
  String get feedErrorTitle;

  /// Fallback action from an error state — read bookmarks instead.
  ///
  /// In en, this message translates to:
  /// **'Open saved'**
  String get openSaved;

  /// Technical error code, shown small under an error message.
  ///
  /// In en, this message translates to:
  /// **'Error: {code}'**
  String errorCodeLine(String code);

  /// Empty state for a category with no articles.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get emptyCategoryTitle;

  /// Body of the empty category state.
  ///
  /// In en, this message translates to:
  /// **'New stories in this category will appear as soon as the newsroom publishes them.'**
  String get emptyCategoryBody;

  /// Banner shown while the device is offline.
  ///
  /// In en, this message translates to:
  /// **'No connection — offline mode'**
  String get offlineBanner;

  /// Banner shown briefly when connectivity returns.
  ///
  /// In en, this message translates to:
  /// **'Back online — refreshed'**
  String get backOnlineBanner;

  /// Badge on a breaking-news item. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'BREAKING'**
  String get breaking;

  /// Body of a breaking-news push notification.
  ///
  /// In en, this message translates to:
  /// **'Tap to read the full report'**
  String get tapToReadFullReport;

  /// Screen-reader label for the play control.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get a11yPlay;

  /// Screen-reader label for the pause control.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get a11yPause;

  /// Screen-reader label for the mini-player tap target.
  ///
  /// In en, this message translates to:
  /// **'Expand player'**
  String get a11yExpandPlayer;

  /// Screen-reader label for collapsing the full player.
  ///
  /// In en, this message translates to:
  /// **'Collapse player'**
  String get a11yCollapsePlayer;

  /// Screen-reader label for the mini-player close button.
  ///
  /// In en, this message translates to:
  /// **'Stop and close player'**
  String get a11yClosePlayer;

  /// Screen-reader label for the mute control.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get a11yMute;

  /// Screen-reader label for the fullscreen control.
  ///
  /// In en, this message translates to:
  /// **'Full screen'**
  String get a11yFullscreen;

  /// Screen-reader label for the bookmark control.
  ///
  /// In en, this message translates to:
  /// **'Save article'**
  String get a11yBookmarkAdd;

  /// Screen-reader label when already bookmarked.
  ///
  /// In en, this message translates to:
  /// **'Remove from saved'**
  String get a11yBookmarkRemove;

  /// Explains that text size follows the OS setting.
  ///
  /// In en, this message translates to:
  /// **'Text size follows your device\'s display settings. Change it in your phone\'s accessibility settings and the app will follow.'**
  String get textSizeSheetBody;

  /// Empty detail pane on wide windows, before anything is chosen.
  ///
  /// In en, this message translates to:
  /// **'Select a story to read'**
  String get selectArticleTitle;

  /// Body of the empty detail pane.
  ///
  /// In en, this message translates to:
  /// **'Choose a headline from the list and it opens here.'**
  String get selectArticleBody;
}

class _AppL10nDelegate extends LocalizationsDelegate<AppL10n> {
  const _AppL10nDelegate();

  @override
  Future<AppL10n> load(Locale locale) {
    return SynchronousFuture<AppL10n>(lookupAppL10n(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'so'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppL10nDelegate old) => false;
}

AppL10n lookupAppL10n(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppL10nEn();
    case 'so':
      return AppL10nSo();
  }

  throw FlutterError(
    'AppL10n.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
