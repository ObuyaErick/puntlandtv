// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Somali (`so`).
class AppL10nSo extends AppL10n {
  AppL10nSo([String locale = 'so']) : super(locale);

  @override
  String get appName => 'Puntland TV';

  @override
  String get navHome => 'Guriga';

  @override
  String get navLive => 'Tooska';

  @override
  String get navPrograms => 'Barnaamij';

  @override
  String get navRadio => 'Raadiyo';

  @override
  String get navSaved => 'Kaydka';

  @override
  String get live => 'TOOS';

  @override
  String get liveNow => 'TOOS AH';

  @override
  String get watchLive => 'Daawo tooska ah';

  @override
  String get leadStory => 'WARKA WEYN';

  @override
  String get refreshing => 'La cusbooneysiinayo…';

  @override
  String minutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count DAQIIQO KA HOR',
      one: '$count DAQIIQO KA HOR',
    );
    return '$_temp0';
  }

  @override
  String hoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count SAAC',
      one: '$count SAAC',
    );
    return '$_temp0';
  }

  @override
  String get relatedStories => 'WARARKA LA XIRIIRA';

  @override
  String moreFrom(String category) {
    return 'Wararka kale ee $category';
  }

  @override
  String get share => 'Wadaag';

  @override
  String get save => 'Kaydi';

  @override
  String get saved => 'La kaydiyay';

  @override
  String minRead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count daq. akhris',
      one: '$count daq. akhris',
    );
    return '$_temp0';
  }

  @override
  String get nowPlaying => 'HADDA LA SII DAAYO';

  @override
  String get upNextToday => 'BARNAAMIJYADA SOO SOCDA';

  @override
  String get audioOnly => 'Cod keliya';

  @override
  String get schedule => 'Jadwalka';

  @override
  String get seeSchedule => 'Fiiri jadwalka';

  @override
  String get streamOfflineTitle => 'Baahinta ma socoto hadda';

  @override
  String streamOfflineBody(String time) {
    return 'Baahintu waxay dib u bilaabaneysaa $time';
  }

  @override
  String get buffering => 'La soo dejinayo';

  @override
  String get slowConnectionQualityReduced =>
      'Xiriirka waa gaabis — tayada waa la yareeyay';

  @override
  String get programsTitle => 'Barnaamijyada';

  @override
  String get programsSubtitle => 'Daawo goorta aad rabto';

  @override
  String get filterAll => 'Dhammaan';

  @override
  String get playLatest => 'Daawo kii ugu dambeeyay';

  @override
  String get episodes => 'QAYBAHA';

  @override
  String episodeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count QAYB',
      one: '$count QAYB',
    );
    return '$_temp0';
  }

  @override
  String get sortNewest => 'Kuwa cusub';

  @override
  String get downloaded => 'La soo dejiyay';

  @override
  String minutesLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count daq. ayaa hadhay',
      one: '$count daq. ayaa hadhay',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count daq.',
      one: '$count daq.',
    );
    return '$_temp0';
  }

  @override
  String get radioTitle => 'Raadiyo Puntland';

  @override
  String get radioBackgroundNote =>
      'Codku wuu socon doonaa xitaa marka app-ka la xiro — 48 kbps oo ku habboon 3G.';

  @override
  String get savedTitle => 'Kaydka';

  @override
  String get tabArticles => 'Maqaallada';

  @override
  String get tabEpisodes => 'Barnaamijyada';

  @override
  String get availableOffline => 'Offline diyaar';

  @override
  String get noImage => 'SAWIR MA JIRO';

  @override
  String get textSavedImageOnline =>
      'Qoraalka waa la kaydiyay · sawirka wuxuu soo bixi doonaa marka aad online noqoto';

  @override
  String get savedRetentionNote =>
      'Maqaallada la kaydiyay qoraalkooda iyo sawirradooda waxay sii jiraan 30 maalmood. Barnaamijyada waxaa lagu soo dejiyaa Wi-Fi keliya.';

  @override
  String offlineShowingSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Xiriir ma jiro — waxaa lagu tusayaa $count shay oo aad kaydsatay',
      one: 'Xiriir ma jiro — waxaa lagu tusayaa $count shay oo aad kaydsatay',
    );
    return '$_temp0';
  }

  @override
  String get emptySavedTitle => 'Weli wax kayd ah ma jiro';

  @override
  String get browseNews => 'Fiiri wararka';

  @override
  String get settingsTitle => 'Goobaha';

  @override
  String get sectionGeneral => 'GUUD';

  @override
  String get sectionDataPlayback => 'XOGTA IYO DAAWASHADA';

  @override
  String get sectionAbout => 'KU SAABSAN';

  @override
  String get settingLanguage => 'Luqadda';

  @override
  String get settingTheme => 'Muuqaalka';

  @override
  String get settingTextSize => 'Cabbirka qoraalka';

  @override
  String get settingDataSaver => 'Badbaadinta xogta';

  @override
  String get settingDataSaverSub =>
      'Yaree tayada muuqaalka marka la isticmaalayo xogta taleefanka';

  @override
  String get settingWifiOnlyDownloads => 'Kaliya Wi-Fi ku soo dejiso';

  @override
  String get settingBreakingAlerts => 'Digniinaha warka deg degga ah';

  @override
  String get followSystem => 'Habka nidaamka';

  @override
  String followSystemWithScale(String percent) {
    return 'Habka nidaamka ($percent)';
  }

  @override
  String get themeLight => 'Iftiin';

  @override
  String get themeDark => 'Mugdi';

  @override
  String versionLine(String version) {
    return 'Puntland TV · v$version';
  }

  @override
  String get languageSheetTitle => 'Luqadda · Language';

  @override
  String get languageSystemDefault => 'Habka nidaamka';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSomali => 'Soomaali';

  @override
  String get languageEnglishSub => 'en-US';

  @override
  String get languageSomaliSub => 'so · Far Laatiin, LTR';

  @override
  String get languageSwitchNote =>
      'Isbeddelka luqadda wuu dhaqan galaa isla markiiba — dib u furid uma baahna.';

  @override
  String get cancel => 'Jooji';

  @override
  String get choose => 'Dooro';

  @override
  String get retry => 'Isku day mar kale';

  @override
  String get feedErrorTitle => 'Wararka lama soo dejin karo';

  @override
  String get openSaved => 'Fur kaydka';

  @override
  String errorCodeLine(String code) {
    return 'Cilad: $code';
  }

  @override
  String get emptyCategoryTitle => 'Weli waxba halkan ma jiraan';

  @override
  String get emptyCategoryBody =>
      'Wararka cusub ee qaybtan waxay soo bixi doonaan isla markii qolka wararku daabaco.';

  @override
  String get offlineBanner => 'Xiriir ma jiro — habka offline';

  @override
  String get backOnlineBanner =>
      'Xiriirku wuu soo laabtay — waa la cusbooneysiiyay';

  @override
  String get breaking => 'DEG DEG';

  @override
  String get tapToReadFullReport => 'Taabo si aad u akhrido warbixinta buuxda.';

  @override
  String get a11yPlay => 'Daawo';

  @override
  String get a11yPause => 'Jooji';

  @override
  String get a11yExpandPlayer => 'Ballaari daawadaha';

  @override
  String get a11yCollapsePlayer => 'Yaree daawadaha';

  @override
  String get a11yClosePlayer => 'Jooji oo xir daawadaha';

  @override
  String get a11yMute => 'Aamusi';

  @override
  String get a11yFullscreen => 'Shaashad buuxda';

  @override
  String get a11yBookmarkAdd => 'Kaydi maqaalka';

  @override
  String get a11yBookmarkRemove => 'Ka saar kaydka';

  @override
  String get textSizeSheetBody =>
      'Cabbirka qoraalku wuxuu raacaa goobaha muuqaalka ee taleefankaaga. Ka beddel goobaha helitaanka ee taleefanka, app-kuna wuu raaci doonaa.';
}
