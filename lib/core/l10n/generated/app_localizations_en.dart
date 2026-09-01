// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppL10nEn extends AppL10n {
  AppL10nEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Puntland TV';

  @override
  String get navHome => 'Home';

  @override
  String get navLive => 'Live TV';

  @override
  String get navPrograms => 'Programs';

  @override
  String get navRadio => 'Radio';

  @override
  String get navSaved => 'Saved';

  @override
  String get live => 'LIVE';

  @override
  String get liveNow => 'LIVE NOW';

  @override
  String get watchLive => 'Watch live';

  @override
  String get leadStory => 'LEAD STORY';

  @override
  String get refreshing => 'Refreshing…';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count MIN AGO',
      one: '$count MIN AGO',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count H',
      one: '$count H',
    );
    return '$_temp0';
  }

  @override
  String get relatedStories => 'RELATED STORIES';

  @override
  String moreFrom(String category) {
    return 'More from $category';
  }

  @override
  String get share => 'Share';

  @override
  String get save => 'Save';

  @override
  String get saved => 'Saved';

  @override
  String minRead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min read',
      one: '$count min read',
    );
    return '$_temp0';
  }

  @override
  String get nowPlaying => 'NOW PLAYING';

  @override
  String get upNextToday => 'UP NEXT TODAY';

  @override
  String get audioOnly => 'Audio only';

  @override
  String get schedule => 'Schedule';

  @override
  String get seeSchedule => 'See schedule';

  @override
  String get streamOfflineTitle => 'The stream is offline';

  @override
  String streamOfflineBody(String time) {
    return 'Broadcast resumes at $time';
  }

  @override
  String get buffering => 'Buffering';

  @override
  String get slowConnectionQualityReduced =>
      'Slow connection — quality reduced';

  @override
  String get programsTitle => 'Programs';

  @override
  String get programsSubtitle => 'Watch anytime';

  @override
  String get filterAll => 'All';

  @override
  String get playLatest => 'Play latest';

  @override
  String get episodes => 'EPISODES';

  @override
  String episodeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count EPS',
      one: '$count EP',
    );
    return '$_temp0';
  }

  @override
  String get sortNewest => 'Newest';

  @override
  String get downloaded => 'Downloaded';

  @override
  String minutesLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min left',
      one: '$count min left',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min',
      one: '$count min',
    );
    return '$_temp0';
  }

  @override
  String get radioTitle => 'Radio Puntland';

  @override
  String get radioBackgroundNote =>
      'Audio keeps playing when the app is closed — 48 kbps, tuned for 3G.';

  @override
  String get savedTitle => 'Saved';

  @override
  String get tabArticles => 'Articles';

  @override
  String get tabEpisodes => 'Episodes';

  @override
  String get availableOffline => 'Available offline';

  @override
  String get noImage => 'NO IMAGE';

  @override
  String get textSavedImageOnline => 'Text saved · image will load online';

  @override
  String get savedRetentionNote =>
      'Saved articles keep their text and images for 30 days. Episodes download only over Wi-Fi.';

  @override
  String offlineShowingSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'No connection — showing your $count saved items',
      one: 'No connection — showing your $count saved item',
    );
    return '$_temp0';
  }

  @override
  String get emptySavedTitle => 'Nothing saved yet';

  @override
  String get browseNews => 'Browse news';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionGeneral => 'GENERAL';

  @override
  String get sectionDataPlayback => 'DATA & PLAYBACK';

  @override
  String get sectionAbout => 'ABOUT';

  @override
  String get settingLanguage => 'Language';

  @override
  String get settingTheme => 'Theme';

  @override
  String get settingTextSize => 'Text size';

  @override
  String get settingDataSaver => 'Data saver';

  @override
  String get settingDataSaverSub => 'Lower video quality on mobile data';

  @override
  String get settingWifiOnlyDownloads => 'Download over Wi-Fi only';

  @override
  String get settingBreakingAlerts => 'Breaking news alerts';

  @override
  String get followSystem => 'Follow system';

  @override
  String followSystemWithScale(String percent) {
    return 'Follow system ($percent)';
  }

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String versionLine(String version) {
    return 'Puntland TV · v$version';
  }

  @override
  String get languageSheetTitle => 'Language · Luqadda';

  @override
  String get languageSystemDefault => 'System default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSomali => 'Soomaali';

  @override
  String get languageEnglishSub => 'en-US';

  @override
  String get languageSomaliSub => 'so · Latin script, LTR';

  @override
  String get languageSwitchNote =>
      'The language changes immediately — no restart needed.';

  @override
  String get cancel => 'Cancel';

  @override
  String get choose => 'Choose';

  @override
  String get retry => 'Try again';

  @override
  String get feedErrorTitle => 'News could not be loaded';

  @override
  String get openSaved => 'Open saved';

  @override
  String errorCodeLine(String code) {
    return 'Error: $code';
  }

  @override
  String get emptyCategoryTitle => 'Nothing here yet';

  @override
  String get emptyCategoryBody =>
      'New stories in this category will appear as soon as the newsroom publishes them.';

  @override
  String get offlineBanner => 'No connection — offline mode';

  @override
  String get backOnlineBanner => 'Back online — refreshed';

  @override
  String get breaking => 'BREAKING';

  @override
  String get tapToReadFullReport => 'Tap to read the full report';

  @override
  String get a11yPlay => 'Play';

  @override
  String get a11yPause => 'Pause';

  @override
  String get a11yExpandPlayer => 'Expand player';

  @override
  String get a11yCollapsePlayer => 'Collapse player';

  @override
  String get a11yClosePlayer => 'Stop and close player';

  @override
  String get a11yMute => 'Mute';

  @override
  String get a11yFullscreen => 'Full screen';

  @override
  String get a11yBookmarkAdd => 'Save article';

  @override
  String get a11yBookmarkRemove => 'Remove from saved';

  @override
  String get textSizeSheetBody =>
      'Text size follows your device\'s display settings. Change it in your phone\'s accessibility settings and the app will follow.';

  @override
  String get selectArticleTitle => 'Select a story to read';

  @override
  String get selectArticleBody =>
      'Choose a headline from the list and it opens here.';

  @override
  String get statusDraft => 'DRAFT';

  @override
  String get statusInReview => 'IN REVIEW';

  @override
  String get statusScheduled => 'SCHEDULED';

  @override
  String get statusPublished => 'PUBLISHED';

  @override
  String get statusFailed => 'FAILED';

  @override
  String get statusTranscoding => 'TRANSCODING';

  @override
  String get consoleTitle => 'Content console';

  @override
  String get consoleSubtitle =>
      'Newsroom and operations tooling for the Puntland TV app — articles, programmes, live streams and alerts.';

  @override
  String get consoleInternalNotice => 'Internal system. Access is logged.';

  @override
  String get navOverview => 'Overview';

  @override
  String get navArticles => 'Articles';

  @override
  String get navProgramsConsole => 'Programs';

  @override
  String get navLiveControl => 'Live control';

  @override
  String get navSchedule => 'Schedule';

  @override
  String get navPush => 'Push';

  @override
  String get navMedia => 'Media';

  @override
  String get navCategories => 'Categories';

  @override
  String get navUsers => 'Users & roles';

  @override
  String get navAppConfig => 'App config';

  @override
  String get roleJournalist => 'Journalist';

  @override
  String get roleEditor => 'Editor';

  @override
  String get roleOperations => 'Operations';

  @override
  String get roleAdmin => 'Admin';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signInSubtitle => 'Use your PLTV staff account.';

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldPassword => 'Password';

  @override
  String get actionContinue => 'Continue';

  @override
  String get forgotPassword => 'Forgot password';

  @override
  String get signOut => 'Sign out';

  @override
  String get twoFactorTitle => 'Second verification';

  @override
  String get twoFactorBody =>
      'Enter the 6-digit code from the authenticator app on your phone.';

  @override
  String resendCode(String seconds) {
    return 'Resend code ($seconds)';
  }

  @override
  String attemptCount(int used, int total) {
    return 'Attempt $used / $total';
  }

  @override
  String get actionVerify => 'Verify';

  @override
  String get errorInvalidCredentials =>
      'That email or password was not recognised.';

  @override
  String get errorPasswordRequired => 'Enter your password.';

  @override
  String get errorInvalidCode => 'That code is not correct.';

  @override
  String get errorLockedOut => 'Too many attempts. Start again.';

  @override
  String get errorTwoFactorNotEnrolled =>
      'This account has no second factor set up. Ask an administrator.';

  @override
  String get errorSignInFailed => 'Sign-in did not go through. Try again.';

  @override
  String get resetTitle => 'Reset your password';

  @override
  String get resetBody =>
      'Enter your work address. We will send a six-digit code.';

  @override
  String get resetSentTitle => 'Enter the code';

  @override
  String resetSentBody(String email) {
    return 'If $email belongs to a console account, a six-digit code is on its way. It expires in 15 minutes.';
  }

  @override
  String get resetCodeLabel => 'Reset code';

  @override
  String get resetNewPassword => 'New password';

  @override
  String get resetConfirmPassword => 'Confirm new password';

  @override
  String resetPasswordRule(int count) {
    return 'At least $count characters.';
  }

  @override
  String get resetAction => 'Set password';

  @override
  String get resetSendAction => 'Send code';

  @override
  String get resetDoneTitle => 'Password changed';

  @override
  String get resetDoneBody =>
      'Sign in with your new password. Any other session you had open has been signed out.';

  @override
  String resetDevCode(String code) {
    return 'Development build: your code is $code';
  }

  @override
  String get errorEmailRequired => 'Enter your work email address.';

  @override
  String get errorResetCodeRequired => 'Enter the six-digit code.';

  @override
  String get errorResetCodeInvalid => 'That code is not correct.';

  @override
  String get errorResetExpired =>
      'That code can no longer be used. Request a new one.';

  @override
  String errorPasswordTooShort(int count) {
    return 'Passwords must be at least $count characters.';
  }

  @override
  String get errorPasswordMismatch => 'Those passwords do not match.';

  @override
  String get errorResetFailed => 'That did not go through. Try again.';

  @override
  String get articlesTitle => 'Articles';

  @override
  String get myArticlesTitle => 'My articles';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '$count item',
    );
    return '$_temp0';
  }

  @override
  String get newArticle => 'New article';

  @override
  String get newDraft => 'New draft';

  @override
  String get journalistNotice =>
      'You can draft and submit for review. Publishing, scheduling and push are Editor actions.';

  @override
  String get filterAllArticles => 'All';

  @override
  String get filterMine => 'Mine';

  @override
  String get colHeadline => 'HEADLINE';

  @override
  String get colCategory => 'CATEGORY';

  @override
  String get colLocale => 'LOCALE';

  @override
  String get colAuthor => 'AUTHOR';

  @override
  String get colUpdated => 'UPDATED';

  @override
  String get colStatus => 'STATUS';

  @override
  String get noEnglishTranslation => 'No English translation';

  @override
  String get translationBehind => 'English is behind';

  @override
  String get heroSet => 'hero set';

  @override
  String selectedCount(int count) {
    return '$count selected';
  }

  @override
  String get bulkPublish => 'Publish';

  @override
  String get bulkUnpublish => 'Unpublish';

  @override
  String get deselectAll => 'Deselect all';

  @override
  String get emptyArticles => 'No articles here yet';

  @override
  String get emptyArticlesBody =>
      'Articles you create appear here. Use New article to start one.';

  @override
  String get overviewTitle => 'Overview';

  @override
  String get onAirNow => 'ON AIR NOW';

  @override
  String get publishedToday => 'PUBLISHED TODAY';

  @override
  String get awaitingReview => 'AWAITING REVIEW';

  @override
  String get failedIngests => 'FAILED INGESTS';

  @override
  String breakingFlagged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count breaking-flagged',
      one: '$count breaking-flagged',
    );
    return '$_temp0';
  }

  @override
  String concurrentViewers(String count) {
    return '$count concurrent';
  }

  @override
  String get allRenditionsHealthy => 'all healthy';

  @override
  String get renditionsDegraded => 'degraded';

  @override
  String get radioOnAir => 'Radio: on air';

  @override
  String get radioOffAir => 'Radio: off air';

  @override
  String get openLiveControl => 'Open live control';

  @override
  String get reviewFailures => 'Review failures';

  @override
  String editorHeadline(String locale) {
    return 'HEADLINE · $locale';
  }

  @override
  String editorExcerpt(String locale) {
    return 'EXCERPT · $locale';
  }

  @override
  String editorBody(String locale) {
    return 'BODY · $locale';
  }

  @override
  String get headlineHint => 'Aim for under 90 characters';

  @override
  String charCount(int used, int limit) {
    return '$used / $limit';
  }

  @override
  String wordCountAndRead(int words, int minutes) {
    return '$words words · $minutes min read';
  }

  @override
  String get sectionTranslation => 'TRANSLATION';

  @override
  String get sectionHeroImage => 'HERO IMAGE';

  @override
  String get sectionPublishing => 'PUBLISHING';

  @override
  String translationSource(String language) {
    return '$language — source';
  }

  @override
  String translationLinked(String language) {
    return '$language — linked';
  }

  @override
  String get translationCurrent => 'Current';

  @override
  String translationBehindBy(int count) {
    return 'BEHIND BY $count EDITS';
  }

  @override
  String get translationStaleNote =>
      'Publishing the source version marks the translation stale in the app rather than hiding it. Clear the flag by re-confirming the translation.';

  @override
  String get reconfirmTranslation => 'Re-confirm translation';

  @override
  String get openSideBySide => 'Open side-by-side';

  @override
  String get altTextRequired => 'Alt text is required before publishing.';

  @override
  String get fieldCategory => 'Category';

  @override
  String get fieldReadTime => 'Read time';

  @override
  String get fieldSchedule => 'Schedule';

  @override
  String get fieldBreaking => 'Breaking news';

  @override
  String get breakingHint =>
      'Adds the red flag in the app. Push is sent separately.';

  @override
  String autoReadTime(int minutes) {
    return 'Auto · $minutes min';
  }

  @override
  String get saveDraft => 'Save draft';

  @override
  String get publishNow => 'Publish now';

  @override
  String savedAt(String time) {
    return 'Saved $time · autosave on';
  }

  @override
  String get pushTitle => 'Push composer';

  @override
  String pushIrreversible(String count) {
    return 'IRREVERSIBLE · $count DEVICES';
  }

  @override
  String messageInLocale(String language) {
    return 'MESSAGE · $language';
  }

  @override
  String get required => 'REQUIRED';

  @override
  String get complete => 'Complete';

  @override
  String get bodyMissing => 'Body missing';

  @override
  String get fieldTitle => 'Title';

  @override
  String get fieldBody => 'Body';

  @override
  String truncationHint(int count) {
    return 'Android truncates near $count characters on the lock screen';
  }

  @override
  String get bodyRequiredHint =>
      'Required — push payloads cannot be translated on the device';

  @override
  String get copySomaliBody => 'Copy Somali body as a starting point';

  @override
  String get sectionTarget => 'TARGET & TOPICS';

  @override
  String get fieldDeepLink => 'Deep link';

  @override
  String estimatedReach(String total) {
    return 'Estimated reach $total devices';
  }

  @override
  String get lockScreenPreview => 'Lock-screen preview';

  @override
  String get previewIncomplete => 'INCOMPLETE';

  @override
  String get sendBlocked => 'Send is blocked until both locales are complete';

  @override
  String get reviewAndSend => 'Review & send';

  @override
  String get saveAsDraft => 'Save as draft';

  @override
  String get sendHistory => 'SEND HISTORY';

  @override
  String confirmSendTitle(String count) {
    return 'Send to $count devices?';
  }

  @override
  String get confirmSendBody =>
      'This cannot be recalled. Both language payloads will be delivered simultaneously.';

  @override
  String typeToConfirm(String word) {
    return 'Type $word to confirm';
  }

  @override
  String get confirmWord => 'SEND';

  @override
  String sentAsAudit(String name) {
    return 'Sent as $name · recorded in the audit log';
  }

  @override
  String get sendNow => 'Send now';

  @override
  String pushSent(String count) {
    return 'Alert sent to $count devices';
  }

  @override
  String get liveControlTitle => 'Live control';

  @override
  String get tvOnAir => 'TV ON AIR';

  @override
  String get tvOffAir => 'TV OFF AIR';

  @override
  String get sectionTvChannel => 'TV CHANNEL';

  @override
  String get sectionRadio => 'RADIO';

  @override
  String get sectionRenditions => 'RENDITIONS';

  @override
  String get sectionSlate => 'OFF-AIR SLATE MESSAGE';

  @override
  String get onAir => 'On air';

  @override
  String get switchingOffShowsSlate => 'Switching off shows the slate';

  @override
  String uptimeAndViewers(String uptime, String viewers) {
    return 'Uptime $uptime · $viewers concurrent';
  }

  @override
  String radioStatusLine(int bitrate, String listeners) {
    return '$bitrate kbps AAC · $listeners listeners';
  }

  @override
  String protectedRungNote(String rung) {
    return '$rung is the rung most of the audience receives — it cannot be disabled';
  }

  @override
  String get colRung => 'RUNG';

  @override
  String get colBitrate => 'BITRATE';

  @override
  String get colHealth => 'HEALTH';

  @override
  String get colEnabled => 'ENABLED';

  @override
  String get healthy => 'Healthy';

  @override
  String get degraded => 'Degraded';

  @override
  String get keyRung => 'KEY';

  @override
  String get slateBothRequired =>
      'Both locales are required before the channel can be taken off air.';

  @override
  String get slatePreview => 'SLATE PREVIEW';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get newCategory => 'New category';

  @override
  String get slugPermanentNote =>
      'The slug is permanent — it is baked into app deep links and push topics. Display names are per-locale and safe to change at any time.';

  @override
  String get untranslatedHiddenNote =>
      'A category with no name in a locale is hidden from that locale\'s tab bar rather than shown untranslated.';

  @override
  String get colSlug => 'SLUG';

  @override
  String get colArticles => 'ARTICLES';

  @override
  String get colInApp => 'IN APP';

  @override
  String get notTranslated => 'Not translated';

  @override
  String get scheduleTitle => 'Schedule';

  @override
  String gapsAndOverlaps(int gaps, int overlaps) {
    return '$gaps gap · $overlaps overlap';
  }

  @override
  String get publishDay => 'Publish day';

  @override
  String get autoResolveOverlap => 'Auto-resolve overlap';

  @override
  String gapLabel(String from, String to) {
    return 'GAP $from – $to · fills with continuity slate';
  }

  @override
  String overlapLabel(int minutes) {
    return 'OVERLAP · collides by $minutes min';
  }

  @override
  String dayTotal(int hours, int minutes) {
    return 'Day total ${hours}h ${minutes}m programmed';
  }

  @override
  String get publishBlockedByOverlap =>
      'Resolve the overlap before publishing the day.';

  @override
  String get colName => 'NAME';

  @override
  String get collapseSidebar => 'Collapse sidebar';

  @override
  String get expandSidebar => 'Expand sidebar';

  @override
  String get clearFilters => 'Clear filters';

  @override
  String filterCategory(String value) {
    return 'Category: $value';
  }

  @override
  String filterLocale(String value) {
    return 'Locale: $value';
  }

  @override
  String filterAuthor(String value) {
    return 'Author: $value';
  }

  @override
  String get filterAnyone => 'Anyone';

  @override
  String get bulkSchedule => 'Schedule…';

  @override
  String get bulkChangeCategory => 'Change category';

  @override
  String rowsRange(int from, int to, int total) {
    return 'Rows $from–$to of $total';
  }

  @override
  String perPage(int count) {
    return '$count per page';
  }

  @override
  String get rowActions => 'Row actions';

  @override
  String get languageNameSomali => 'Somali';

  @override
  String get languageNameEnglish => 'English';

  @override
  String missingTranslation(String language) {
    return 'No $language translation';
  }

  @override
  String translationBehindIn(String language) {
    return '$language is behind';
  }

  @override
  String get consoleLanguage => 'Console language';

  @override
  String get tagline => 'The Voice of the Puntland Government, Somalia';

  @override
  String get newAlert => 'New alert';

  @override
  String get todaysQueue => 'Today\'s publishing queue';

  @override
  String get openArticles => 'Open articles';

  @override
  String get recentPushes => 'Recent pushes';

  @override
  String deliveredOf(String delivered, String targeted) {
    return 'Delivered $delivered / $targeted';
  }

  @override
  String get colTime => 'TIME';

  @override
  String liveFor(String duration) {
    return 'LIVE $duration';
  }

  @override
  String get queueEmpty => 'Nothing scheduled for today';

  @override
  String get justNow => 'now';

  @override
  String get colUrl => 'URL';

  @override
  String get mediaTitle => 'Media library';

  @override
  String get uploadMedia => 'Upload';

  @override
  String get mediaAltNotice =>
      'Alt text is required in both languages. An image described in only one reaches the other language\'s readers undescribed.';

  @override
  String get filterAllMedia => 'All';

  @override
  String get filterImages => 'Images';

  @override
  String get filterVideo => 'Video';

  @override
  String get filterAudio => 'Audio';

  @override
  String get filterNeedsAlt => 'Needs alt text';

  @override
  String get searchMedia => 'Search filename, alt text, or credit';

  @override
  String get emptyMedia => 'Nothing in the library yet';

  @override
  String get emptyMediaBody =>
      'Upload an image, a programme, or an audio bed to get started.';

  @override
  String get emptyMediaFiltered => 'No files match this filter';

  @override
  String get mediaAssetTitle => 'Asset';

  @override
  String get sectionAltText => 'ALT TEXT';

  @override
  String get sectionFileDetails => 'FILE';

  @override
  String get sectionUsage => 'USED IN';

  @override
  String altTextFor(String language) {
    return 'Alt text ($language)';
  }

  @override
  String get altTextHint =>
      'Describe what is in the picture, not that it is a picture.';

  @override
  String altMissingInCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Missing alt text in $count languages',
      one: 'Missing alt text in $count language',
    );
    return '$_temp0';
  }

  @override
  String get altComplete => 'Described in both languages';

  @override
  String get fieldCredit => 'Credit';

  @override
  String get creditNotTranslated =>
      'A name, so it stays the same in both languages.';

  @override
  String get fieldFilename => 'Filename';

  @override
  String get fieldDimensions => 'Dimensions';

  @override
  String get fieldFileSize => 'Size';

  @override
  String get fieldDuration => 'Duration';

  @override
  String get fieldUploaded => 'Uploaded';

  @override
  String megabytes(String value) {
    return '$value MB';
  }

  @override
  String kilobytes(String value) {
    return '$value kB';
  }

  @override
  String uploadedByOn(String name, String date) {
    return '$name · $date';
  }

  @override
  String transcodingProgress(String percent) {
    return 'Transcoding · $percent%';
  }

  @override
  String get transcodeNotAttachable =>
      'Not attachable until transcoding finishes.';

  @override
  String get transcodeFailedTitle => 'Ingest failed';

  @override
  String get retryIngest => 'Retry ingest';

  @override
  String get retryQueued => 'Retry queued.';

  @override
  String usedInCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Used in $count articles',
      one: 'Used in $count article',
      zero: 'Not used yet',
    );
    return '$_temp0';
  }

  @override
  String usedInPublishedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count of them are published',
      one: '$count of them is published',
    );
    return '$_temp0';
  }

  @override
  String get deleteAsset => 'Delete';

  @override
  String get deleteBlockedInUse =>
      'In use — detach it from every article before deleting.';

  @override
  String get deleteAssetTitle => 'Delete this file?';

  @override
  String get deleteAssetBody =>
      'This cannot be undone. Nothing points at it, so no article changes.';

  @override
  String assetDeleted(String filename) {
    return 'Deleted $filename';
  }

  @override
  String assetsDeleted(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files deleted',
      one: '$count file deleted',
    );
    return '$_temp0';
  }

  @override
  String deleteRefusedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files kept — they are still in use',
      one: '$count file kept — it is still in use',
    );
    return '$_temp0';
  }

  @override
  String get altTextSaved => 'Alt text saved.';

  @override
  String uploadPending(String filename) {
    return 'Uploading $filename…';
  }

  @override
  String get uploadedNeedsAlt =>
      'Uploaded. Add alt text in both languages before it can publish.';

  @override
  String get uploadedProcessing => 'Uploaded. Transcoding has started.';

  @override
  String get dropToUpload => 'Drop files here, or choose from your computer';

  @override
  String get chooseFiles => 'Choose files';

  @override
  String get uploadFormats => 'JPEG, PNG, MP4, or M4A — up to 2 GB';

  @override
  String get mediaKindImage => 'Image';

  @override
  String get mediaKindVideo => 'Video';

  @override
  String get mediaKindAudio => 'Audio';

  @override
  String mediaGridLabel(String filename, String kind) {
    return '$filename, $kind';
  }

  @override
  String get openArticle => 'Open article';

  @override
  String get programsConsoleTitle => 'Programmes';

  @override
  String get newProgram => 'New programme';

  @override
  String get programsNotice =>
      'A programme with no title in a language is hidden from that language\'s shelf. It is not shown in the other language.';

  @override
  String get colProgram => 'PROGRAMME';

  @override
  String get colCadence => 'CADENCE';

  @override
  String get colGenre => 'GENRE';

  @override
  String get colEpisodes => 'EPISODES';

  @override
  String get colShelf => 'ON SHELF';

  @override
  String get cadenceDaily => 'Daily';

  @override
  String get cadenceWeekly => 'Weekly';

  @override
  String get cadenceMonthly => 'Monthly';

  @override
  String get cadenceOccasional => 'Occasional';

  @override
  String get genreNews => 'News';

  @override
  String get genreDebate => 'Debate';

  @override
  String get genreCulture => 'Culture';

  @override
  String get genreKids => 'Children';

  @override
  String get genreSport => 'Sport';

  @override
  String get genreReligion => 'Religion';

  @override
  String get emptyPrograms => 'No programmes yet';

  @override
  String get emptyProgramsBody =>
      'A programme groups episodes into a shelf in the app.';

  @override
  String hiddenFromShelf(String language) {
    return 'Hidden from the $language shelf';
  }

  @override
  String episodesOf(String program) {
    return 'Episodes · $program';
  }

  @override
  String get backToPrograms => 'All programmes';

  @override
  String get colEpisode => 'EPISODE';

  @override
  String get colSource => 'SOURCE';

  @override
  String get colAired => 'AIRED';

  @override
  String episodeNumber(int number) {
    return 'Ep. $number';
  }

  @override
  String get emptyEpisodes => 'No episodes in this programme';

  @override
  String get emptyEpisodesBody =>
      'Upload the video to the media library first, then attach it here.';

  @override
  String get blockerNoSource => 'No video attached';

  @override
  String get blockerSourceFailed =>
      'Transcode failed — retry it in the media library';

  @override
  String get blockerSourceProcessing => 'Still transcoding';

  @override
  String blockerUntitled(String language) {
    return 'No title in $language';
  }

  @override
  String get publishEpisode => 'Publish';

  @override
  String get unpublishEpisode => 'Unpublish';

  @override
  String get episodePublishBlocked =>
      'Fix what is blocking this episode before publishing it.';

  @override
  String get episodePublished => 'Episode published.';

  @override
  String get episodeUnpublished => 'Episode removed from the app.';

  @override
  String blockedEpisodeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count episodes cannot be published yet',
      one: '$count episode cannot be published yet',
    );
    return '$_temp0';
  }

  @override
  String get usersTitle => 'Users and roles';

  @override
  String get inviteUser => 'Invite';

  @override
  String get usersNotice =>
      'A role is a set of capabilities, not a label. Changing someone\'s role changes what they can do everywhere in the console at once.';

  @override
  String get colPerson => 'PERSON';

  @override
  String get colRole => 'ROLE';

  @override
  String get colLastActive => 'LAST ACTIVE';

  @override
  String get statusActive => 'Active';

  @override
  String get statusInvited => 'Invited';

  @override
  String get statusSuspended => 'Suspended';

  @override
  String get neverSignedIn => 'Never';

  @override
  String get noSecondFactor => 'No second factor';

  @override
  String adminSeatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count admins can sign in',
      one: '$count admin can sign in',
    );
    return '$_temp0';
  }

  @override
  String twoFactorGapCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count accounts have no second factor',
      one: '$count account has no second factor',
    );
    return '$_temp0';
  }

  @override
  String get memberTitle => 'Account';

  @override
  String get sectionRole => 'ROLE';

  @override
  String get sectionCapabilities => 'WHAT THIS ROLE CAN DO';

  @override
  String get sectionAccount => 'ACCOUNT';

  @override
  String get capabilityDerivedNote =>
      'Capabilities come from the role, never from the person. There is no per-user grant to audit.';

  @override
  String get capWriteOwnArticles => 'Write and edit own drafts';

  @override
  String get capPublishArticles => 'Edit anyone\'s article, and publish';

  @override
  String get capSendPush => 'Send push alerts';

  @override
  String get capManageBroadcast => 'Streams, schedule, and the on-air toggle';

  @override
  String get capManageLibrary => 'Programmes, episodes, and the media library';

  @override
  String get capManageTaxonomy => 'Categories';

  @override
  String get capManageUsers => 'Staff accounts and roles';

  @override
  String get capManageConfig => 'Feature flags, minimum build, locales';

  @override
  String get capViewAuditLog => 'Read the audit trail';

  @override
  String get suspendAccount => 'Suspend';

  @override
  String get reinstateAccount => 'Reinstate';

  @override
  String get suspendKeepsBylinesNote =>
      'Suspending keeps the account and its bylines. Deleting it would rewrite the author on every article they filed.';

  @override
  String get refusalSelf =>
      'You cannot revoke your own access — another admin would have to let you back in.';

  @override
  String get refusalLastAdmin =>
      'This is the only admin who can sign in. Promote someone else first.';

  @override
  String roleChanged(String name, String role) {
    return '$name is now $role.';
  }

  @override
  String accountSuspended(String name) {
    return '$name can no longer sign in.';
  }

  @override
  String accountReinstated(String name) {
    return '$name can sign in again.';
  }

  @override
  String get configTitle => 'App configuration';

  @override
  String get configNotice =>
      'The app reads this at startup. A change reaches a reader the next time they open it, not immediately.';

  @override
  String get sectionUpdateFloor => 'MINIMUM SUPPORTED BUILD';

  @override
  String get sectionLocales => 'LANGUAGES';

  @override
  String get sectionFlags => 'FEATURE FLAGS';

  @override
  String get sectionReaderDefaults => 'READER DEFAULTS';

  @override
  String get fieldMinimumBuild => 'Builds below this must update';

  @override
  String releasedBuildIs(String build) {
    return 'Highest released build: $build';
  }

  @override
  String get floorLocksEveryoneOut =>
      'No released build satisfies this floor. Every reader would be told to update with nothing to update to, and only a store release could undo it.';

  @override
  String floorSafe(String build) {
    return 'Readers on build $build or later are unaffected.';
  }

  @override
  String localeStrandsArticles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count published articles exist only in this language',
      one: '$count published article exists only in this language',
      zero: 'Nothing exists only in this language',
    );
    return '$_temp0';
  }

  @override
  String get lastLocaleCannotBeDisabled =>
      'The last language cannot be switched off.';

  @override
  String get disablingRemovesContent =>
      'Switching a language off removes the stories written only in it. They do not fall back to the other language.';

  @override
  String get fieldDataSaver => 'Data saver on by default';

  @override
  String get dataSaverHint => 'Most of the audience is on metered mobile data.';

  @override
  String get flagKeyPermanentNote =>
      'A flag key is baked into released builds. Renaming one switches the feature off for everyone already installed.';

  @override
  String get configSaved => 'Configuration saved.';

  @override
  String configLastChanged(String date, String name) {
    return 'Last changed $date by $name';
  }

  @override
  String get saveBlockedByFloor => 'Fix the minimum build before saving.';

  @override
  String get discardChanges => 'Discard';

  @override
  String get unsavedChanges => 'Unsaved changes';
}
