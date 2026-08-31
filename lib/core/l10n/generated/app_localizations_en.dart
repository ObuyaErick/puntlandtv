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
}
