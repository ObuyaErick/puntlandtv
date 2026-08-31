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

  /// Article status badge. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'DRAFT'**
  String get statusDraft;

  /// Article status badge. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'IN REVIEW'**
  String get statusInReview;

  /// Article status badge. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'SCHEDULED'**
  String get statusScheduled;

  /// Article status badge. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'PUBLISHED'**
  String get statusPublished;

  /// Status badge for a failed ingest or publish. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'FAILED'**
  String get statusFailed;

  /// Status badge while an episode encodes. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'TRANSCODING'**
  String get statusTranscoding;

  /// Name of the internal console.
  ///
  /// In en, this message translates to:
  /// **'Content console'**
  String get consoleTitle;

  /// Sign-in page description of the console.
  ///
  /// In en, this message translates to:
  /// **'Newsroom and operations tooling for the Puntland TV app — articles, programmes, live streams and alerts.'**
  String get consoleSubtitle;

  /// Footer notice on the console sign-in page.
  ///
  /// In en, this message translates to:
  /// **'Internal system. Access is logged.'**
  String get consoleInternalNotice;

  /// Console navigation: dashboard.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get navOverview;

  /// Console navigation: article list.
  ///
  /// In en, this message translates to:
  /// **'Articles'**
  String get navArticles;

  /// Console navigation: programmes and episodes.
  ///
  /// In en, this message translates to:
  /// **'Programs'**
  String get navProgramsConsole;

  /// Console navigation: broadcast control.
  ///
  /// In en, this message translates to:
  /// **'Live control'**
  String get navLiveControl;

  /// Console navigation: EPG builder.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get navSchedule;

  /// Console navigation: push composer.
  ///
  /// In en, this message translates to:
  /// **'Push'**
  String get navPush;

  /// Console navigation: media library.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get navMedia;

  /// Console navigation: taxonomy.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get navCategories;

  /// Console navigation: staff accounts.
  ///
  /// In en, this message translates to:
  /// **'Users & roles'**
  String get navUsers;

  /// Console navigation: flags and build settings.
  ///
  /// In en, this message translates to:
  /// **'App config'**
  String get navAppConfig;

  /// Staff role. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'JOURNALIST'**
  String get roleJournalist;

  /// Staff role. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'EDITOR'**
  String get roleEditor;

  /// Staff role. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'OPERATIONS'**
  String get roleOperations;

  /// Staff role. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'ADMIN'**
  String get roleAdmin;

  /// Heading of the sign-in card.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// Subtitle of the sign-in card.
  ///
  /// In en, this message translates to:
  /// **'Use your PLTV staff account.'**
  String get signInSubtitle;

  /// Email field label.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get fieldEmail;

  /// Password field label.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get fieldPassword;

  /// Submits the sign-in form.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// Link to password recovery.
  ///
  /// In en, this message translates to:
  /// **'Forgot password'**
  String get forgotPassword;

  /// Ends the console session.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// Heading of the two-factor step.
  ///
  /// In en, this message translates to:
  /// **'Second verification'**
  String get twoFactorTitle;

  /// Instruction for the two-factor step.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code from the authenticator app on your phone.'**
  String get twoFactorBody;

  /// Resend action with its cooldown timer.
  ///
  /// In en, this message translates to:
  /// **'Resend code ({seconds})'**
  String resendCode(String seconds);

  /// How many verification attempts have been used.
  ///
  /// In en, this message translates to:
  /// **'Attempt {used} / {total}'**
  String attemptCount(int used, int total);

  /// Submits the verification code.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get actionVerify;

  /// Sign-in failure. Deliberately does not say which half was wrong.
  ///
  /// In en, this message translates to:
  /// **'That email or password was not recognised.'**
  String get errorInvalidCredentials;

  /// Validation message for an empty password.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get errorPasswordRequired;

  /// Two-factor failure.
  ///
  /// In en, this message translates to:
  /// **'That code is not correct.'**
  String get errorInvalidCode;

  /// Shown after the final failed verification attempt.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Start again.'**
  String get errorLockedOut;

  /// Console article list heading for editors.
  ///
  /// In en, this message translates to:
  /// **'Articles'**
  String get articlesTitle;

  /// Console article list heading for journalists.
  ///
  /// In en, this message translates to:
  /// **'My articles'**
  String get myArticlesTitle;

  /// Row count under a list heading.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} item} other{{count} items}}'**
  String itemCount(int count);

  /// Creates an article.
  ///
  /// In en, this message translates to:
  /// **'New article'**
  String get newArticle;

  /// Creates an article, journalist wording.
  ///
  /// In en, this message translates to:
  /// **'New draft'**
  String get newDraft;

  /// Explains the journalist role limits on the article list.
  ///
  /// In en, this message translates to:
  /// **'You can draft and submit for review. Publishing, scheduling and push are Editor actions.'**
  String get journalistNotice;

  /// Filter chip: every article.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAllArticles;

  /// Filter chip: the signed-in journalist own articles.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get filterMine;

  /// Table column. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'HEADLINE'**
  String get colHeadline;

  /// Table column. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'CATEGORY'**
  String get colCategory;

  /// Table column. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'LOCALE'**
  String get colLocale;

  /// Table column. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'AUTHOR'**
  String get colAuthor;

  /// Table column. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'UPDATED'**
  String get colUpdated;

  /// Table column. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'STATUS'**
  String get colStatus;

  /// Sub-label on a row that exists only in Somali.
  ///
  /// In en, this message translates to:
  /// **'No English translation'**
  String get noEnglishTranslation;

  /// Sub-label on a row whose translation is older than the source.
  ///
  /// In en, this message translates to:
  /// **'English is behind'**
  String get translationBehind;

  /// Sub-label fragment meaning the article has an image.
  ///
  /// In en, this message translates to:
  /// **'hero set'**
  String get heroSet;

  /// Bulk action bar count.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// Bulk action.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get bulkPublish;

  /// Bulk action.
  ///
  /// In en, this message translates to:
  /// **'Unpublish'**
  String get bulkUnpublish;

  /// Clears the bulk selection.
  ///
  /// In en, this message translates to:
  /// **'Deselect all'**
  String get deselectAll;

  /// Empty state for the article list.
  ///
  /// In en, this message translates to:
  /// **'No articles here yet'**
  String get emptyArticles;

  /// Empty state body.
  ///
  /// In en, this message translates to:
  /// **'Articles you create appear here. Use New article to start one.'**
  String get emptyArticlesBody;

  /// Console dashboard heading.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overviewTitle;

  /// Overview panel heading. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'ON AIR NOW'**
  String get onAirNow;

  /// Overview stat heading. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'PUBLISHED TODAY'**
  String get publishedToday;

  /// Overview stat heading. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'AWAITING REVIEW'**
  String get awaitingReview;

  /// Overview stat heading. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'FAILED INGESTS'**
  String get failedIngests;

  /// Sub-label under the awaiting-review count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} breaking-flagged} other{{count} breaking-flagged}}'**
  String breakingFlagged(int count);

  /// Live viewer count on the overview. The number is formatted by AppNumberFormat before it gets here — intl has no Somali number data.
  ///
  /// In en, this message translates to:
  /// **'{count} concurrent'**
  String concurrentViewers(String count);

  /// Sub-label when every stream rendition is up.
  ///
  /// In en, this message translates to:
  /// **'all healthy'**
  String get allRenditionsHealthy;

  /// Sub-label when a stream rendition is down.
  ///
  /// In en, this message translates to:
  /// **'degraded'**
  String get renditionsDegraded;

  /// Radio status on the overview.
  ///
  /// In en, this message translates to:
  /// **'Radio: on air'**
  String get radioOnAir;

  /// Radio status on the overview.
  ///
  /// In en, this message translates to:
  /// **'Radio: off air'**
  String get radioOffAir;

  /// Action on the on-air panel.
  ///
  /// In en, this message translates to:
  /// **'Open live control'**
  String get openLiveControl;

  /// Action on the failed-ingests tile.
  ///
  /// In en, this message translates to:
  /// **'Review failures'**
  String get reviewFailures;

  /// Editor field label with the language code. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'HEADLINE · {locale}'**
  String editorHeadline(String locale);

  /// Editor field label with the language code. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'EXCERPT · {locale}'**
  String editorExcerpt(String locale);

  /// Editor field label with the language code. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'BODY · {locale}'**
  String editorBody(String locale);

  /// Guidance under the headline field.
  ///
  /// In en, this message translates to:
  /// **'Aim for under 90 characters'**
  String get headlineHint;

  /// Character counter.
  ///
  /// In en, this message translates to:
  /// **'{used} / {limit}'**
  String charCount(int used, int limit);

  /// Body editor footer.
  ///
  /// In en, this message translates to:
  /// **'{words} words · {minutes} min read'**
  String wordCountAndRead(int words, int minutes);

  /// Editor side panel section. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'TRANSLATION'**
  String get sectionTranslation;

  /// Editor side panel section. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'HERO IMAGE'**
  String get sectionHeroImage;

  /// Editor side panel section. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'PUBLISHING'**
  String get sectionPublishing;

  /// Row label for the language an article was written in.
  ///
  /// In en, this message translates to:
  /// **'{language} — source'**
  String translationSource(String language);

  /// Row label for a translation of the source.
  ///
  /// In en, this message translates to:
  /// **'{language} — linked'**
  String translationLinked(String language);

  /// Badge on an up-to-date translation.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get translationCurrent;

  /// Badge on a stale translation. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'BEHIND BY {count} EDITS'**
  String translationBehindBy(int count);

  /// Explains what staleness does, in the editor.
  ///
  /// In en, this message translates to:
  /// **'Publishing the source version marks the translation stale in the app rather than hiding it. Clear the flag by re-confirming the translation.'**
  String get translationStaleNote;

  /// Clears the stale flag.
  ///
  /// In en, this message translates to:
  /// **'Re-confirm translation'**
  String get reconfirmTranslation;

  /// Opens both languages together.
  ///
  /// In en, this message translates to:
  /// **'Open side-by-side'**
  String get openSideBySide;

  /// Validation note on the hero image.
  ///
  /// In en, this message translates to:
  /// **'Alt text is required before publishing.'**
  String get altTextRequired;

  /// Editor field.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get fieldCategory;

  /// Editor field.
  ///
  /// In en, this message translates to:
  /// **'Read time'**
  String get fieldReadTime;

  /// Editor field.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get fieldSchedule;

  /// Editor toggle.
  ///
  /// In en, this message translates to:
  /// **'Breaking news'**
  String get fieldBreaking;

  /// Explains what the breaking toggle does — and does not — do.
  ///
  /// In en, this message translates to:
  /// **'Adds the red flag in the app. Push is sent separately.'**
  String get breakingHint;

  /// Automatically computed read time.
  ///
  /// In en, this message translates to:
  /// **'Auto · {minutes} min'**
  String autoReadTime(int minutes);

  /// Editor action.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get saveDraft;

  /// Editor action.
  ///
  /// In en, this message translates to:
  /// **'Publish now'**
  String get publishNow;

  /// Editor header status.
  ///
  /// In en, this message translates to:
  /// **'Saved {time} · autosave on'**
  String savedAt(String time);

  /// Console screen heading.
  ///
  /// In en, this message translates to:
  /// **'Push composer'**
  String get pushTitle;

  /// Warning badge on the push composer. Uppercase. Pre-formatted.
  ///
  /// In en, this message translates to:
  /// **'IRREVERSIBLE · {count} DEVICES'**
  String pushIrreversible(String count);

  /// Push composer section per language. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'MESSAGE · {language}'**
  String messageInLocale(String language);

  /// Badge on a mandatory section. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'REQUIRED'**
  String get required;

  /// Badge on a finished section.
  ///
  /// In en, this message translates to:
  /// **'Complete'**
  String get complete;

  /// Badge on an unfinished push message.
  ///
  /// In en, this message translates to:
  /// **'Body missing'**
  String get bodyMissing;

  /// Push message field.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get fieldTitle;

  /// Push message field.
  ///
  /// In en, this message translates to:
  /// **'Body'**
  String get fieldBody;

  /// Guidance under the push title field.
  ///
  /// In en, this message translates to:
  /// **'Android truncates near {count} characters on the lock screen'**
  String truncationHint(int count);

  /// Explains why every locale needs its own body.
  ///
  /// In en, this message translates to:
  /// **'Required — push payloads cannot be translated on the device'**
  String get bodyRequiredHint;

  /// Convenience action in the push composer.
  ///
  /// In en, this message translates to:
  /// **'Copy Somali body as a starting point'**
  String get copySomaliBody;

  /// Push composer section. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'TARGET & TOPICS'**
  String get sectionTarget;

  /// Push composer field.
  ///
  /// In en, this message translates to:
  /// **'Deep link'**
  String get fieldDeepLink;

  /// Reach line in the push composer. Pre-formatted.
  ///
  /// In en, this message translates to:
  /// **'Estimated reach {total} devices'**
  String estimatedReach(String total);

  /// Preview section heading.
  ///
  /// In en, this message translates to:
  /// **'Lock-screen preview'**
  String get lockScreenPreview;

  /// Badge on a preview whose payload is unfinished. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'INCOMPLETE'**
  String get previewIncomplete;

  /// Explains why the send button is disabled.
  ///
  /// In en, this message translates to:
  /// **'Send is blocked until both locales are complete'**
  String get sendBlocked;

  /// Opens the send confirmation.
  ///
  /// In en, this message translates to:
  /// **'Review & send'**
  String get reviewAndSend;

  /// Saves a push without sending.
  ///
  /// In en, this message translates to:
  /// **'Save as draft'**
  String get saveAsDraft;

  /// Push composer section. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'SEND HISTORY'**
  String get sendHistory;

  /// Send confirmation heading. Pre-formatted.
  ///
  /// In en, this message translates to:
  /// **'Send to {count} devices?'**
  String confirmSendTitle(String count);

  /// Send confirmation warning.
  ///
  /// In en, this message translates to:
  /// **'This cannot be recalled. Both language payloads will be delivered simultaneously.'**
  String get confirmSendBody;

  /// Instruction for the type-to-confirm field.
  ///
  /// In en, this message translates to:
  /// **'Type {word} to confirm'**
  String typeToConfirm(String word);

  /// The word a user types to confirm sending. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'SEND'**
  String get confirmWord;

  /// Attribution note on the send confirmation.
  ///
  /// In en, this message translates to:
  /// **'Sent as {name} · recorded in the audit log'**
  String sentAsAudit(String name);

  /// Confirms sending.
  ///
  /// In en, this message translates to:
  /// **'Send now'**
  String get sendNow;

  /// Toast after a successful send. Pre-formatted.
  ///
  /// In en, this message translates to:
  /// **'Alert sent to {count} devices'**
  String pushSent(String count);

  /// Console screen heading.
  ///
  /// In en, this message translates to:
  /// **'Live control'**
  String get liveControlTitle;

  /// Badge when the channel is transmitting. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'TV ON AIR'**
  String get tvOnAir;

  /// Badge when the channel is down. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'TV OFF AIR'**
  String get tvOffAir;

  /// Live control section. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'TV CHANNEL'**
  String get sectionTvChannel;

  /// Live control section. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'RADIO'**
  String get sectionRadio;

  /// Live control section. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'RENDITIONS'**
  String get sectionRenditions;

  /// Live control section. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'OFF-AIR SLATE MESSAGE'**
  String get sectionSlate;

  /// Toggle label for transmitting.
  ///
  /// In en, this message translates to:
  /// **'On air'**
  String get onAir;

  /// Explains what the on-air toggle does.
  ///
  /// In en, this message translates to:
  /// **'Switching off shows the slate'**
  String get switchingOffShowsSlate;

  /// Channel status line. Counts arrive pre-formatted.
  ///
  /// In en, this message translates to:
  /// **'Uptime {uptime} · {viewers} concurrent'**
  String uptimeAndViewers(String uptime, String viewers);

  /// Radio status line. Listener count arrives pre-formatted.
  ///
  /// In en, this message translates to:
  /// **'{bitrate} kbps AAC · {listeners} listeners'**
  String radioStatusLine(int bitrate, String listeners);

  /// Explains why one rendition is locked on.
  ///
  /// In en, this message translates to:
  /// **'{rung} is the rung most of the audience receives — it cannot be disabled'**
  String protectedRungNote(String rung);

  /// Renditions table column. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'RUNG'**
  String get colRung;

  /// Renditions table column. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'BITRATE'**
  String get colBitrate;

  /// Renditions table column. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'HEALTH'**
  String get colHealth;

  /// Renditions table column. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'ENABLED'**
  String get colEnabled;

  /// Rendition health value.
  ///
  /// In en, this message translates to:
  /// **'Healthy'**
  String get healthy;

  /// Rendition health value.
  ///
  /// In en, this message translates to:
  /// **'Degraded'**
  String get degraded;

  /// Badge on the protected rendition. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'KEY'**
  String get keyRung;

  /// Explains the off-air gate.
  ///
  /// In en, this message translates to:
  /// **'Both locales are required before the channel can be taken off air.'**
  String get slateBothRequired;

  /// Heading above the rendered slate. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'SLATE PREVIEW'**
  String get slatePreview;

  /// Console screen heading.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTitle;

  /// Creates a category.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get newCategory;

  /// Explains the slug versus name distinction.
  ///
  /// In en, this message translates to:
  /// **'The slug is permanent — it is baked into app deep links and push topics. Display names are per-locale and safe to change at any time.'**
  String get slugPermanentNote;

  /// Explains what an untranslated category does.
  ///
  /// In en, this message translates to:
  /// **'A category with no name in a locale is hidden from that locale\'s tab bar rather than shown untranslated.'**
  String get untranslatedHiddenNote;

  /// Categories column. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'SLUG'**
  String get colSlug;

  /// Categories column. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'ARTICLES'**
  String get colArticles;

  /// Categories column showing which locales display it. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'IN APP'**
  String get colInApp;

  /// Value in a category name column with no translation.
  ///
  /// In en, this message translates to:
  /// **'Not translated'**
  String get notTranslated;

  /// Console screen heading.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get scheduleTitle;

  /// Schedule issue summary.
  ///
  /// In en, this message translates to:
  /// **'{gaps} gap · {overlaps} overlap'**
  String gapsAndOverlaps(int gaps, int overlaps);

  /// Publishes the day schedule.
  ///
  /// In en, this message translates to:
  /// **'Publish day'**
  String get publishDay;

  /// Pushes colliding slots later.
  ///
  /// In en, this message translates to:
  /// **'Auto-resolve overlap'**
  String get autoResolveOverlap;

  /// Marker on a schedule gap.
  ///
  /// In en, this message translates to:
  /// **'GAP {from} – {to} · fills with continuity slate'**
  String gapLabel(String from, String to);

  /// Marker on a schedule overlap.
  ///
  /// In en, this message translates to:
  /// **'OVERLAP · collides by {minutes} min'**
  String overlapLabel(int minutes);

  /// Schedule footer.
  ///
  /// In en, this message translates to:
  /// **'Day total {hours}h {minutes}m programmed'**
  String dayTotal(int hours, int minutes);

  /// Explains why publishing is blocked.
  ///
  /// In en, this message translates to:
  /// **'Resolve the overlap before publishing the day.'**
  String get publishBlockedByOverlap;

  /// Categories table column for the display name. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'NAME'**
  String get colName;

  /// Tooltip on the rail collapse control.
  ///
  /// In en, this message translates to:
  /// **'Collapse sidebar'**
  String get collapseSidebar;

  /// Tooltip on the rail expand control.
  ///
  /// In en, this message translates to:
  /// **'Expand sidebar'**
  String get expandSidebar;

  /// Resets every article list filter.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get clearFilters;

  /// Category filter button label.
  ///
  /// In en, this message translates to:
  /// **'Category: {value}'**
  String filterCategory(String value);

  /// Locale filter button label.
  ///
  /// In en, this message translates to:
  /// **'Locale: {value}'**
  String filterLocale(String value);

  /// Author filter button label.
  ///
  /// In en, this message translates to:
  /// **'Author: {value}'**
  String filterAuthor(String value);

  /// Author filter value meaning no author filter.
  ///
  /// In en, this message translates to:
  /// **'Anyone'**
  String get filterAnyone;

  /// Bulk action opening the scheduling dialog.
  ///
  /// In en, this message translates to:
  /// **'Schedule…'**
  String get bulkSchedule;

  /// Bulk action.
  ///
  /// In en, this message translates to:
  /// **'Change category'**
  String get bulkChangeCategory;

  /// Pagination summary.
  ///
  /// In en, this message translates to:
  /// **'Rows {from}–{to} of {total}'**
  String rowsRange(int from, int to, int total);

  /// Page size selector.
  ///
  /// In en, this message translates to:
  /// **'{count} per page'**
  String perPage(int count);

  /// Tooltip on the per-row overflow button.
  ///
  /// In en, this message translates to:
  /// **'Row actions'**
  String get rowActions;

  /// Name of the Somali language, in the active UI language. Distinct from the picker, which uses endonyms.
  ///
  /// In en, this message translates to:
  /// **'Somali'**
  String get languageNameSomali;

  /// Name of the English language, in the active UI language.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageNameEnglish;

  /// Sub-label on an article missing a required translation.
  ///
  /// In en, this message translates to:
  /// **'No {language} translation'**
  String missingTranslation(String language);

  /// Sub-label on an article whose translation is older than the source.
  ///
  /// In en, this message translates to:
  /// **'{language} is behind'**
  String translationBehindIn(String language);

  /// Tooltip on the console language switch.
  ///
  /// In en, this message translates to:
  /// **'Console language'**
  String get consoleLanguage;

  /// Institutional tagline under the wordmark. A descriptive phrase, so it is translated — unlike the name "Puntland TV", which is a proper noun. Confirm the English wording with the broadcaster.
  ///
  /// In en, this message translates to:
  /// **'The Voice of the Puntland Government, Somalia'**
  String get tagline;

  /// Overview action that opens the push composer.
  ///
  /// In en, this message translates to:
  /// **'New alert'**
  String get newAlert;

  /// Overview panel heading.
  ///
  /// In en, this message translates to:
  /// **'Today\'s publishing queue'**
  String get todaysQueue;

  /// Link from the queue panel to the article list.
  ///
  /// In en, this message translates to:
  /// **'Open articles'**
  String get openArticles;

  /// Overview panel heading.
  ///
  /// In en, this message translates to:
  /// **'Recent pushes'**
  String get recentPushes;

  /// Delivery result on a sent alert. Both numbers arrive pre-formatted.
  ///
  /// In en, this message translates to:
  /// **'Delivered {delivered} / {targeted}'**
  String deliveredOf(String delivered, String targeted);

  /// Queue table column. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'TIME'**
  String get colTime;

  /// On-air pill showing how long the channel has been up. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'LIVE {duration}'**
  String liveFor(String duration);

  /// Empty state for the publishing queue.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled for today'**
  String get queueEmpty;

  /// Relative time for something that has just happened.
  ///
  /// In en, this message translates to:
  /// **'now'**
  String get justNow;

  /// Renditions table column for the manifest URL. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get colUrl;
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
