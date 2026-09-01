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
  /// **'Journalist'**
  String get roleJournalist;

  /// Staff role. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'Editor'**
  String get roleEditor;

  /// Staff role. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get roleOperations;

  /// Staff role. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
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

  /// Sign-in failure for an account that cannot complete the second step. Not a wrong password, so it must not read like one.
  ///
  /// In en, this message translates to:
  /// **'This account has no second factor set up. Ask an administrator.'**
  String get errorTwoFactorNotEnrolled;

  /// Fallback for any sign-in failure without a message of its own — a lost connection, a server error. Shown so the form never fails silently.
  ///
  /// In en, this message translates to:
  /// **'Sign-in did not go through. Try again.'**
  String get errorSignInFailed;

  /// Heading of the forgotten-password dialog, first step.
  ///
  /// In en, this message translates to:
  /// **'Reset your password'**
  String get resetTitle;

  /// First step of the reset flow.
  ///
  /// In en, this message translates to:
  /// **'Enter your work address. We will send a six-digit code.'**
  String get resetBody;

  /// Heading of the forgotten-password dialog, second step.
  ///
  /// In en, this message translates to:
  /// **'Enter the code'**
  String get resetSentTitle;

  /// Confirmation after requesting a code. Conditional on purpose: the backend answers the same way for an unknown address, and this sentence must not claim more than it knows.
  ///
  /// In en, this message translates to:
  /// **'If {email} belongs to a console account, a six-digit code is on its way. It expires in 15 minutes.'**
  String resetSentBody(String email);

  /// Label for the six-digit code field.
  ///
  /// In en, this message translates to:
  /// **'Reset code'**
  String get resetCodeLabel;

  /// Label for the new password field.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get resetNewPassword;

  /// Label for the repeated password field.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get resetConfirmPassword;

  /// Password length requirement, shown before it is broken rather than after.
  ///
  /// In en, this message translates to:
  /// **'At least {count} characters.'**
  String resetPasswordRule(int count);

  /// Submits the new password.
  ///
  /// In en, this message translates to:
  /// **'Set password'**
  String get resetAction;

  /// Requests a reset code.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get resetSendAction;

  /// Heading after a completed reset.
  ///
  /// In en, this message translates to:
  /// **'Password changed'**
  String get resetDoneTitle;

  /// Shown after a completed reset. Says the sessions ended because someone resetting a password they think was stolen needs to know that happened.
  ///
  /// In en, this message translates to:
  /// **'Sign in with your new password. Any other session you had open has been signed out.'**
  String get resetDoneBody;

  /// Shown only when the backend echoes the code, which it does outside production because no email or SMS gateway is wired up yet.
  ///
  /// In en, this message translates to:
  /// **'Development build: your code is {code}'**
  String resetDevCode(String code);

  /// Validation message for an empty address on the reset form.
  ///
  /// In en, this message translates to:
  /// **'Enter your work email address.'**
  String get errorEmailRequired;

  /// Validation message for an incomplete reset code.
  ///
  /// In en, this message translates to:
  /// **'Enter the six-digit code.'**
  String get errorResetCodeRequired;

  /// A wrong reset code, with attempts still remaining.
  ///
  /// In en, this message translates to:
  /// **'That code is not correct.'**
  String get errorResetCodeInvalid;

  /// Covers an expired code, a spent one, and one that was never issued — the backend does not distinguish them, so neither does this.
  ///
  /// In en, this message translates to:
  /// **'That code can no longer be used. Request a new one.'**
  String get errorResetExpired;

  /// Shown when the new password is below the length floor.
  ///
  /// In en, this message translates to:
  /// **'Passwords must be at least {count} characters.'**
  String errorPasswordTooShort(int count);

  /// Shown when the confirmation does not match.
  ///
  /// In en, this message translates to:
  /// **'Those passwords do not match.'**
  String get errorPasswordMismatch;

  /// Fallback for any reset failure without a message of its own, so the dialog never fails silently.
  ///
  /// In en, this message translates to:
  /// **'That did not go through. Try again.'**
  String get errorResetFailed;

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

  /// Console media library page title.
  ///
  /// In en, this message translates to:
  /// **'Media library'**
  String get mediaTitle;

  /// Primary action on the media library: add files.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get uploadMedia;

  /// Notice strip on the media library explaining the per-locale alt text rule.
  ///
  /// In en, this message translates to:
  /// **'Alt text is required in both languages. An image described in only one reaches the other language\'s readers undescribed.'**
  String get mediaAltNotice;

  /// Media library filter chip: every asset.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAllMedia;

  /// Media library filter chip.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get filterImages;

  /// Media library filter chip.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get filterVideo;

  /// Media library filter chip.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get filterAudio;

  /// Media library filter chip for images missing alt text in at least one language. The only filter naming a problem rather than a type.
  ///
  /// In en, this message translates to:
  /// **'Needs alt text'**
  String get filterNeedsAlt;

  /// Placeholder in the media library search box.
  ///
  /// In en, this message translates to:
  /// **'Search filename, alt text, or credit'**
  String get searchMedia;

  /// Media library empty state title.
  ///
  /// In en, this message translates to:
  /// **'Nothing in the library yet'**
  String get emptyMedia;

  /// Media library empty state body.
  ///
  /// In en, this message translates to:
  /// **'Upload an image, a programme, or an audio bed to get started.'**
  String get emptyMediaBody;

  /// Media library empty state when a filter or search excludes everything.
  ///
  /// In en, this message translates to:
  /// **'No files match this filter'**
  String get emptyMediaFiltered;

  /// Title of the media detail side panel.
  ///
  /// In en, this message translates to:
  /// **'Asset'**
  String get mediaAssetTitle;

  /// Section heading in the media detail panel. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'ALT TEXT'**
  String get sectionAltText;

  /// Section heading in the media detail panel. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'FILE'**
  String get sectionFileDetails;

  /// Section heading in the media detail panel listing the articles an asset appears in. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'USED IN'**
  String get sectionUsage;

  /// Label on one language's alt text field.
  ///
  /// In en, this message translates to:
  /// **'Alt text ({language})'**
  String altTextFor(String language);

  /// Helper text under the alt text fields.
  ///
  /// In en, this message translates to:
  /// **'Describe what is in the picture, not that it is a picture.'**
  String get altTextHint;

  /// Warning on an asset tile counting the languages with no alt text.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Missing alt text in {count} language} other{Missing alt text in {count} languages}}'**
  String altMissingInCount(int count);

  /// Confirmation on an asset whose alt text is complete.
  ///
  /// In en, this message translates to:
  /// **'Described in both languages'**
  String get altComplete;

  /// Photographer or agency attribution field. Not translated — it is a proper noun.
  ///
  /// In en, this message translates to:
  /// **'Credit'**
  String get fieldCredit;

  /// Helper text explaining why the credit field has no per-language variant.
  ///
  /// In en, this message translates to:
  /// **'A name, so it stays the same in both languages.'**
  String get creditNotTranslated;

  /// Media detail row label.
  ///
  /// In en, this message translates to:
  /// **'Filename'**
  String get fieldFilename;

  /// Media detail row label for an image's pixel size.
  ///
  /// In en, this message translates to:
  /// **'Dimensions'**
  String get fieldDimensions;

  /// Media detail row label.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get fieldFileSize;

  /// Media detail row label for video and audio length.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get fieldDuration;

  /// Media detail row label.
  ///
  /// In en, this message translates to:
  /// **'Uploaded'**
  String get fieldUploaded;

  /// File size in megabytes. The number arrives pre-formatted for the locale.
  ///
  /// In en, this message translates to:
  /// **'{value} MB'**
  String megabytes(String value);

  /// File size in kilobytes. The number arrives pre-formatted for the locale.
  ///
  /// In en, this message translates to:
  /// **'{value} kB'**
  String kilobytes(String value);

  /// Who uploaded an asset and when.
  ///
  /// In en, this message translates to:
  /// **'{name} · {date}'**
  String uploadedByOn(String name, String date);

  /// Progress label on a video still being ingested.
  ///
  /// In en, this message translates to:
  /// **'Transcoding · {percent}%'**
  String transcodingProgress(String percent);

  /// Explains why a processing video cannot be used yet.
  ///
  /// In en, this message translates to:
  /// **'Not attachable until transcoding finishes.'**
  String get transcodeNotAttachable;

  /// Heading on a failed transcode in the media detail panel.
  ///
  /// In en, this message translates to:
  /// **'Ingest failed'**
  String get transcodeFailedTitle;

  /// Action that re-queues a failed transcode.
  ///
  /// In en, this message translates to:
  /// **'Retry ingest'**
  String get retryIngest;

  /// Toast after re-queuing a failed transcode.
  ///
  /// In en, this message translates to:
  /// **'Retry queued.'**
  String get retryQueued;

  /// How many articles an asset appears in.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, zero{Not used yet} one{Used in {count} article} other{Used in {count} articles}}'**
  String usedInCount(int count);

  /// Sub-label warning that some uses of an asset are already live.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} of them is published} other{{count} of them are published}}'**
  String usedInPublishedCount(int count);

  /// Action that removes an asset from the library.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAsset;

  /// Why the delete action is disabled on an asset an article points at.
  ///
  /// In en, this message translates to:
  /// **'In use — detach it from every article before deleting.'**
  String get deleteBlockedInUse;

  /// Confirmation dialog title for deleting an asset.
  ///
  /// In en, this message translates to:
  /// **'Delete this file?'**
  String get deleteAssetTitle;

  /// Confirmation dialog body for deleting an unused asset.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone. Nothing points at it, so no article changes.'**
  String get deleteAssetBody;

  /// Toast after deleting one asset.
  ///
  /// In en, this message translates to:
  /// **'Deleted {filename}'**
  String assetDeleted(String filename);

  /// Toast after a bulk delete.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} file deleted} other{{count} files deleted}}'**
  String assetsDeleted(int count);

  /// Toast reporting the part of a bulk delete the library refused.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} file kept — it is still in use} other{{count} files kept — they are still in use}}'**
  String deleteRefusedCount(int count);

  /// Toast after saving an asset's metadata.
  ///
  /// In en, this message translates to:
  /// **'Alt text saved.'**
  String get altTextSaved;

  /// Toast while a file is being registered.
  ///
  /// In en, this message translates to:
  /// **'Uploading {filename}…'**
  String uploadPending(String filename);

  /// Toast after uploading an image, which lands undescribed.
  ///
  /// In en, this message translates to:
  /// **'Uploaded. Add alt text in both languages before it can publish.'**
  String get uploadedNeedsAlt;

  /// Toast after uploading a video.
  ///
  /// In en, this message translates to:
  /// **'Uploaded. Transcoding has started.'**
  String get uploadedProcessing;

  /// Label inside the media library's upload drop zone.
  ///
  /// In en, this message translates to:
  /// **'Drop files here, or choose from your computer'**
  String get dropToUpload;

  /// Button inside the upload drop zone.
  ///
  /// In en, this message translates to:
  /// **'Choose files'**
  String get chooseFiles;

  /// Accepted formats under the upload drop zone.
  ///
  /// In en, this message translates to:
  /// **'JPEG, PNG, MP4, or M4A — up to 2 GB'**
  String get uploadFormats;

  /// Asset kind label.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get mediaKindImage;

  /// Asset kind label.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get mediaKindVideo;

  /// Asset kind label.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get mediaKindAudio;

  /// Screen reader label for an asset tile in the grid.
  ///
  /// In en, this message translates to:
  /// **'{filename}, {kind}'**
  String mediaGridLabel(String filename, String kind);

  /// Link from an asset's usage list to the article using it.
  ///
  /// In en, this message translates to:
  /// **'Open article'**
  String get openArticle;

  /// Console programmes page title. Distinct from programsTitle, which is the reader app's VOD screen.
  ///
  /// In en, this message translates to:
  /// **'Programmes'**
  String get programsConsoleTitle;

  /// Primary action on the programmes page.
  ///
  /// In en, this message translates to:
  /// **'New programme'**
  String get newProgram;

  /// Notice on the programmes page explaining the per-locale visibility rule.
  ///
  /// In en, this message translates to:
  /// **'A programme with no title in a language is hidden from that language\'s shelf. It is not shown in the other language.'**
  String get programsNotice;

  /// Programmes table column. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'PROGRAMME'**
  String get colProgram;

  /// Programmes table column for how often a show airs. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'CADENCE'**
  String get colCadence;

  /// Programmes table column. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'GENRE'**
  String get colGenre;

  /// Programmes table column. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'EPISODES'**
  String get colEpisodes;

  /// Programmes table column showing which locales a programme appears in. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'ON SHELF'**
  String get colShelf;

  /// Programme cadence.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get cadenceDaily;

  /// Programme cadence.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get cadenceWeekly;

  /// Programme cadence.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get cadenceMonthly;

  /// Programme cadence for specials with no fixed slot.
  ///
  /// In en, this message translates to:
  /// **'Occasional'**
  String get cadenceOccasional;

  /// Programme genre.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get genreNews;

  /// Programme genre.
  ///
  /// In en, this message translates to:
  /// **'Debate'**
  String get genreDebate;

  /// Programme genre.
  ///
  /// In en, this message translates to:
  /// **'Culture'**
  String get genreCulture;

  /// Programme genre.
  ///
  /// In en, this message translates to:
  /// **'Children'**
  String get genreKids;

  /// Programme genre.
  ///
  /// In en, this message translates to:
  /// **'Sport'**
  String get genreSport;

  /// Programme genre.
  ///
  /// In en, this message translates to:
  /// **'Religion'**
  String get genreReligion;

  /// Programmes page empty state.
  ///
  /// In en, this message translates to:
  /// **'No programmes yet'**
  String get emptyPrograms;

  /// Programmes page empty state body.
  ///
  /// In en, this message translates to:
  /// **'A programme groups episodes into a shelf in the app.'**
  String get emptyProgramsBody;

  /// Sub-label on a programme with no title in one language.
  ///
  /// In en, this message translates to:
  /// **'Hidden from the {language} shelf'**
  String hiddenFromShelf(String language);

  /// Title of the episode list for one programme.
  ///
  /// In en, this message translates to:
  /// **'Episodes · {program}'**
  String episodesOf(String program);

  /// Returns from one programme's episodes to the programme list.
  ///
  /// In en, this message translates to:
  /// **'All programmes'**
  String get backToPrograms;

  /// Episodes table column. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'EPISODE'**
  String get colEpisode;

  /// Episodes table column for the attached video file. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'SOURCE'**
  String get colSource;

  /// Episodes table column. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'AIRED'**
  String get colAired;

  /// Short episode label.
  ///
  /// In en, this message translates to:
  /// **'Ep. {number}'**
  String episodeNumber(int number);

  /// Episode list empty state.
  ///
  /// In en, this message translates to:
  /// **'No episodes in this programme'**
  String get emptyEpisodes;

  /// Episode list empty state body.
  ///
  /// In en, this message translates to:
  /// **'Upload the video to the media library first, then attach it here.'**
  String get emptyEpisodesBody;

  /// Why an episode cannot be published: nothing to play.
  ///
  /// In en, this message translates to:
  /// **'No video attached'**
  String get blockerNoSource;

  /// Why an episode cannot be published: the ingest failed.
  ///
  /// In en, this message translates to:
  /// **'Transcode failed — retry it in the media library'**
  String get blockerSourceFailed;

  /// Why an episode cannot be published: the ingest is unfinished.
  ///
  /// In en, this message translates to:
  /// **'Still transcoding'**
  String get blockerSourceProcessing;

  /// Why an episode cannot be published: a missing locale title.
  ///
  /// In en, this message translates to:
  /// **'No title in {language}'**
  String blockerUntitled(String language);

  /// Action that puts an episode in the app.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publishEpisode;

  /// Action that removes an episode from the app.
  ///
  /// In en, this message translates to:
  /// **'Unpublish'**
  String get unpublishEpisode;

  /// Tooltip on a disabled episode publish button.
  ///
  /// In en, this message translates to:
  /// **'Fix what is blocking this episode before publishing it.'**
  String get episodePublishBlocked;

  /// Toast after publishing an episode.
  ///
  /// In en, this message translates to:
  /// **'Episode published.'**
  String get episodePublished;

  /// Toast after unpublishing an episode.
  ///
  /// In en, this message translates to:
  /// **'Episode removed from the app.'**
  String get episodeUnpublished;

  /// Summary strip above an episode list.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} episode cannot be published yet} other{{count} episodes cannot be published yet}}'**
  String blockedEpisodeCount(int count);

  /// Console administration page title.
  ///
  /// In en, this message translates to:
  /// **'Users and roles'**
  String get usersTitle;

  /// Primary action on the users page.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get inviteUser;

  /// Notice on the users page.
  ///
  /// In en, this message translates to:
  /// **'A role is a set of capabilities, not a label. Changing someone\'s role changes what they can do everywhere in the console at once.'**
  String get usersNotice;

  /// Users table column. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'PERSON'**
  String get colPerson;

  /// Users table column. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'ROLE'**
  String get colRole;

  /// Users table column. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'LAST ACTIVE'**
  String get colLastActive;

  /// Staff account status.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// Staff account status: invited but never signed in.
  ///
  /// In en, this message translates to:
  /// **'Invited'**
  String get statusInvited;

  /// Staff account status: kept, but cannot sign in.
  ///
  /// In en, this message translates to:
  /// **'Suspended'**
  String get statusSuspended;

  /// Last-active value for an account that has never been used.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get neverSignedIn;

  /// Warning on an account that cannot complete a sign-in.
  ///
  /// In en, this message translates to:
  /// **'No second factor'**
  String get noSecondFactor;

  /// Summary strip on the users page. Counts only active admins.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} admin can sign in} other{{count} admins can sign in}}'**
  String adminSeatCount(int count);

  /// Summary strip on the users page.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} account has no second factor} other{{count} accounts have no second factor}}'**
  String twoFactorGapCount(int count);

  /// Title of the staff detail side panel.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get memberTitle;

  /// Section heading in the staff panel. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'ROLE'**
  String get sectionRole;

  /// Section heading above the capability list. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'WHAT THIS ROLE CAN DO'**
  String get sectionCapabilities;

  /// Section heading in the staff panel. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNT'**
  String get sectionAccount;

  /// Explains why the capability list is read-only.
  ///
  /// In en, this message translates to:
  /// **'Capabilities come from the role, never from the person. There is no per-user grant to audit.'**
  String get capabilityDerivedNote;

  /// Capability description.
  ///
  /// In en, this message translates to:
  /// **'Write and edit own drafts'**
  String get capWriteOwnArticles;

  /// Capability description.
  ///
  /// In en, this message translates to:
  /// **'Edit anyone\'s article, and publish'**
  String get capPublishArticles;

  /// Capability description.
  ///
  /// In en, this message translates to:
  /// **'Send push alerts'**
  String get capSendPush;

  /// Capability description.
  ///
  /// In en, this message translates to:
  /// **'Streams, schedule, and the on-air toggle'**
  String get capManageBroadcast;

  /// Capability description.
  ///
  /// In en, this message translates to:
  /// **'Programmes, episodes, and the media library'**
  String get capManageLibrary;

  /// Capability description.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get capManageTaxonomy;

  /// Capability description.
  ///
  /// In en, this message translates to:
  /// **'Staff accounts and roles'**
  String get capManageUsers;

  /// Capability description.
  ///
  /// In en, this message translates to:
  /// **'Feature flags, minimum build, locales'**
  String get capManageConfig;

  /// Capability description.
  ///
  /// In en, this message translates to:
  /// **'Read the audit trail'**
  String get capViewAuditLog;

  /// Action that stops an account signing in.
  ///
  /// In en, this message translates to:
  /// **'Suspend'**
  String get suspendAccount;

  /// Action that restores a suspended account.
  ///
  /// In en, this message translates to:
  /// **'Reinstate'**
  String get reinstateAccount;

  /// Explains why suspension exists instead of deletion.
  ///
  /// In en, this message translates to:
  /// **'Suspending keeps the account and its bylines. Deleting it would rewrite the author on every article they filed.'**
  String get suspendKeepsBylinesNote;

  /// Why a role or status change on your own account is refused.
  ///
  /// In en, this message translates to:
  /// **'You cannot revoke your own access — another admin would have to let you back in.'**
  String get refusalSelf;

  /// Why demoting or suspending the last admin is refused.
  ///
  /// In en, this message translates to:
  /// **'This is the only admin who can sign in. Promote someone else first.'**
  String get refusalLastAdmin;

  /// Toast after a role change.
  ///
  /// In en, this message translates to:
  /// **'{name} is now {role}.'**
  String roleChanged(String name, String role);

  /// Toast after suspending an account.
  ///
  /// In en, this message translates to:
  /// **'{name} can no longer sign in.'**
  String accountSuspended(String name);

  /// Toast after reinstating an account.
  ///
  /// In en, this message translates to:
  /// **'{name} can sign in again.'**
  String accountReinstated(String name);

  /// Console app config page title.
  ///
  /// In en, this message translates to:
  /// **'App configuration'**
  String get configTitle;

  /// Notice on the app config page.
  ///
  /// In en, this message translates to:
  /// **'The app reads this at startup. A change reaches a reader the next time they open it, not immediately.'**
  String get configNotice;

  /// App config section heading. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'MINIMUM SUPPORTED BUILD'**
  String get sectionUpdateFloor;

  /// App config section heading. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'LANGUAGES'**
  String get sectionLocales;

  /// App config section heading. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'FEATURE FLAGS'**
  String get sectionFlags;

  /// App config section heading. Uppercase.
  ///
  /// In en, this message translates to:
  /// **'READER DEFAULTS'**
  String get sectionReaderDefaults;

  /// Label on the minimum supported build field.
  ///
  /// In en, this message translates to:
  /// **'Builds below this must update'**
  String get fieldMinimumBuild;

  /// Reference value beside the minimum build field.
  ///
  /// In en, this message translates to:
  /// **'Highest released build: {build}'**
  String releasedBuildIs(String build);

  /// Error under the minimum build field when it exceeds the released build.
  ///
  /// In en, this message translates to:
  /// **'No released build satisfies this floor. Every reader would be told to update with nothing to update to, and only a store release could undo it.'**
  String get floorLocksEveryoneOut;

  /// Confirmation under a valid minimum build field.
  ///
  /// In en, this message translates to:
  /// **'Readers on build {build} or later are unaffected.'**
  String floorSafe(String build);

  /// How much content disabling a language would remove.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, zero{Nothing exists only in this language} one{{count} published article exists only in this language} other{{count} published articles exist only in this language}}'**
  String localeStrandsArticles(int count);

  /// Why the final enabled locale's switch is disabled.
  ///
  /// In en, this message translates to:
  /// **'The last language cannot be switched off.'**
  String get lastLocaleCannotBeDisabled;

  /// Explains the consequence of disabling a locale.
  ///
  /// In en, this message translates to:
  /// **'Switching a language off removes the stories written only in it. They do not fall back to the other language.'**
  String get disablingRemovesContent;

  /// App config toggle label.
  ///
  /// In en, this message translates to:
  /// **'Data saver on by default'**
  String get fieldDataSaver;

  /// Helper text under the data saver toggle.
  ///
  /// In en, this message translates to:
  /// **'Most of the audience is on metered mobile data.'**
  String get dataSaverHint;

  /// Notice above the feature flag list.
  ///
  /// In en, this message translates to:
  /// **'A flag key is baked into released builds. Renaming one switches the feature off for everyone already installed.'**
  String get flagKeyPermanentNote;

  /// Toast after saving app config.
  ///
  /// In en, this message translates to:
  /// **'Configuration saved.'**
  String get configSaved;

  /// Provenance line on the app config page.
  ///
  /// In en, this message translates to:
  /// **'Last changed {date} by {name}'**
  String configLastChanged(String date, String name);

  /// Tooltip on the disabled app config save button.
  ///
  /// In en, this message translates to:
  /// **'Fix the minimum build before saving.'**
  String get saveBlockedByFloor;

  /// Abandons unsaved app config edits.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardChanges;

  /// Marker shown while the app config form differs from what is stored.
  ///
  /// In en, this message translates to:
  /// **'Unsaved changes'**
  String get unsavedChanges;
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
