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

  @override
  String get selectArticleTitle => 'Dooro war aad akhrido';

  @override
  String get selectArticleBody =>
      'Ka dooro cinwaan liiska, halkanna ayuu ka furmayaa.';

  @override
  String get statusDraft => 'QABYO';

  @override
  String get statusInReview => 'DIB U EEGIS';

  @override
  String get statusScheduled => 'LA JADWALEEYAY';

  @override
  String get statusPublished => 'LA DAABACAY';

  @override
  String get statusFailed => 'WAA FASHILMAY';

  @override
  String get statusTranscoding => 'WAA LA BEDDELAYAA';

  @override
  String get consoleTitle => 'Xarunta maamulka';

  @override
  String get consoleSubtitle =>
      'Qalabka qolka wararka iyo hawlgallada ee abka Puntland TV — maqaallada, barnaamijyada, baahinta tooska ah iyo digniinaha.';

  @override
  String get consoleInternalNotice =>
      'Nidaam gudaha ah. Gelitaanka waa la diiwaangeliyaa.';

  @override
  String get navOverview => 'Guudmar';

  @override
  String get navArticles => 'Maqaallada';

  @override
  String get navProgramsConsole => 'Barnaamijyada';

  @override
  String get navLiveControl => 'Maamulka tooska';

  @override
  String get navSchedule => 'Jadwalka';

  @override
  String get navPush => 'Digniinaha';

  @override
  String get navMedia => 'Warbaahinta';

  @override
  String get navCategories => 'Qaybaha';

  @override
  String get navUsers => 'Isticmaalayaasha';

  @override
  String get navAppConfig => 'Goobaha abka';

  @override
  String get roleJournalist => 'WERIYE';

  @override
  String get roleEditor => 'TIFAFTIRE';

  @override
  String get roleOperations => 'HAWLGALLO';

  @override
  String get roleAdmin => 'MAAMULE';

  @override
  String get signInTitle => 'Gal';

  @override
  String get signInSubtitle => 'Isticmaal akoonkaaga shaqaalaha PLTV.';

  @override
  String get fieldEmail => 'Iimayl';

  @override
  String get fieldPassword => 'Furaha sirta ah';

  @override
  String get actionContinue => 'Sii wad';

  @override
  String get forgotPassword => 'Ma illowday furaha?';

  @override
  String get signOut => 'Ka bax';

  @override
  String get twoFactorTitle => 'Xaqiijinta labaad';

  @override
  String get twoFactorBody =>
      'Geli koodhka 6-god ee ka yimid abka xaqiijinta ee taleefankaaga.';

  @override
  String resendCode(String seconds) {
    return 'Dib u dir koodhka ($seconds)';
  }

  @override
  String attemptCount(int used, int total) {
    return 'Isku day $used / $total';
  }

  @override
  String get actionVerify => 'Xaqiiji';

  @override
  String get errorInvalidCredentials =>
      'Iimaylka ama furaha sirta ah lama aqoonsan.';

  @override
  String get errorPasswordRequired => 'Geli furahaaga sirta ah.';

  @override
  String get errorInvalidCode => 'Koodhkaas sax ma aha.';

  @override
  String get errorLockedOut => 'Isku dayo badan. Dib u bilow.';

  @override
  String get articlesTitle => 'Maqaallada';

  @override
  String get myArticlesTitle => 'Maqaalladayda';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count shay',
      one: '$count shay',
    );
    return '$_temp0';
  }

  @override
  String get newArticle => 'Maqaal cusub';

  @override
  String get newDraft => 'Qabyo cusub';

  @override
  String get journalistNotice =>
      'Waad qori kartaa oo u gudbin kartaa dib u eegis. Daabacaadda, jadwalaynta iyo digniinaha waa hawlaha tifaftiraha.';

  @override
  String get filterAllArticles => 'Dhammaan';

  @override
  String get filterMine => 'Kayga';

  @override
  String get colHeadline => 'CINWAANKA';

  @override
  String get colCategory => 'QAYBTA';

  @override
  String get colLocale => 'LUQADDA';

  @override
  String get colAuthor => 'QORAAGA';

  @override
  String get colUpdated => 'LA CUSBOONEYSIIYAY';

  @override
  String get colStatus => 'XAALADDA';

  @override
  String get noEnglishTranslation => 'Turjumaad Ingiriisi ah ma jirto';

  @override
  String get translationBehind => 'Ingiriisku wuu ka daahay';

  @override
  String get heroSet => 'sawir la dhigay';

  @override
  String selectedCount(int count) {
    return '$count la doortay';
  }

  @override
  String get bulkPublish => 'Daabac';

  @override
  String get bulkUnpublish => 'Ka saar daabacaadda';

  @override
  String get deselectAll => 'Ka saar doorashada';

  @override
  String get emptyArticles => 'Weli maqaallo ma jiraan';

  @override
  String get emptyArticlesBody =>
      'Maqaallada aad abuurto halkan ayay ka muuqan doonaan. Isticmaal Maqaal cusub si aad u bilowdo.';

  @override
  String get overviewTitle => 'Guudmar';

  @override
  String get onAirNow => 'HADDA WAA BAAHINAYAA';

  @override
  String get publishedToday => 'MAANTA LA DAABACAY';

  @override
  String get awaitingReview => 'SUGAYA DIB U EEGIS';

  @override
  String get failedIngests => 'SOO GELIN FASHILMAY';

  @override
  String breakingFlagged(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count deg deg ah',
      one: '$count deg deg ah',
    );
    return '$_temp0';
  }

  @override
  String concurrentViewers(String count) {
    return '$count isku mar';
  }

  @override
  String get allRenditionsHealthy => 'dhammaan waa fiican yihiin';

  @override
  String get renditionsDegraded => 'waa liitaa';

  @override
  String get radioOnAir => 'Raadiyaha: waa baahinayaa';

  @override
  String get radioOffAir => 'Raadiyaha: ma baahinayo';

  @override
  String get openLiveControl => 'Fur maamulka tooska';

  @override
  String get reviewFailures => 'Eeg fashilkooda';

  @override
  String editorHeadline(String locale) {
    return 'CINWAANKA · $locale';
  }

  @override
  String editorExcerpt(String locale) {
    return 'SOO KOOBID · $locale';
  }

  @override
  String editorBody(String locale) {
    return 'QORAALKA · $locale';
  }

  @override
  String get headlineHint => 'Isku day inuu ka yar yahay 90 xaraf';

  @override
  String charCount(int used, int limit) {
    return '$used / $limit';
  }

  @override
  String wordCountAndRead(int words, int minutes) {
    return '$words eray · $minutes daq. akhris';
  }

  @override
  String get sectionTranslation => 'TURJUMAADDA';

  @override
  String get sectionHeroImage => 'SAWIRKA WEYN';

  @override
  String get sectionPublishing => 'DAABACAADDA';

  @override
  String translationSource(String language) {
    return '$language — isha';
  }

  @override
  String translationLinked(String language) {
    return '$language — ku xiran';
  }

  @override
  String get translationCurrent => 'Waa cusub yahay';

  @override
  String translationBehindBy(int count) {
    return 'WUXUU KA DAAHAY $count WAX-KA-BEDDEL';
  }

  @override
  String get translationStaleNote =>
      'Daabacaadda nuqulka isha ah waxay turjumaadda ku calaamadinaysaa mid duugoobay abka gudihiisa, halkii la qarin lahaa. Calaamadda waxaad ka saartaa adigoo turjumaadda dib u xaqiijiya.';

  @override
  String get reconfirmTranslation => 'Dib u xaqiiji turjumaadda';

  @override
  String get openSideBySide => 'Fur labada dhinac';

  @override
  String get altTextRequired =>
      'Qoraalka sawirka waa loo baahan yahay ka hor daabacaadda.';

  @override
  String get fieldCategory => 'Qaybta';

  @override
  String get fieldReadTime => 'Waqtiga akhriska';

  @override
  String get fieldSchedule => 'Jadwalka';

  @override
  String get fieldBreaking => 'War deg deg ah';

  @override
  String get breakingHint =>
      'Waxay ku darsataa calaamadda cas abka. Digniinta gooni ayaa loo diraa.';

  @override
  String autoReadTime(int minutes) {
    return 'Toos · $minutes daq.';
  }

  @override
  String get saveDraft => 'Kaydi qabyada';

  @override
  String get publishNow => 'Hadda daabac';

  @override
  String savedAt(String time) {
    return 'La kaydiyay $time · kaydinta toosa waa shidan';
  }

  @override
  String get pushTitle => 'Qoraaga digniinaha';

  @override
  String pushIrreversible(String count) {
    return 'LAMA CELIN KARO · $count QALAB';
  }

  @override
  String messageInLocale(String language) {
    return 'FARRIINTA · $language';
  }

  @override
  String get required => 'WAA LOO BAAHAN YAHAY';

  @override
  String get complete => 'Waa dhammaystiran';

  @override
  String get bodyMissing => 'Qoraalka waa maqan';

  @override
  String get fieldTitle => 'Cinwaanka';

  @override
  String get fieldBody => 'Qoraalka';

  @override
  String truncationHint(int count) {
    return 'Android wuxuu gooyaa ku dhawaad $count xaraf shaashadda qufulka';
  }

  @override
  String get bodyRequiredHint =>
      'Waa loo baahan yahay — digniinaha lagama turjumi karo qalabka';

  @override
  String get copySomaliBody => 'Koobi qoraalka Soomaaliga si aad uga bilowdo';

  @override
  String get sectionTarget => 'BARTILMAAMEEDKA IYO MAWDUUCYADA';

  @override
  String get fieldDeepLink => 'Xiriirka toosa';

  @override
  String estimatedReach(String total) {
    return 'Gaadhista la filayo $total qalab';
  }

  @override
  String get lockScreenPreview => 'Muuqaalka shaashadda qufulka';

  @override
  String get previewIncomplete => 'MA DHAMMAYSTIRNA';

  @override
  String get sendBlocked =>
      'Dirista waa la joojiyay ilaa labada luqadood dhammaystiraan';

  @override
  String get reviewAndSend => 'Eeg oo dir';

  @override
  String get saveAsDraft => 'Kaydi qabyo ahaan';

  @override
  String get sendHistory => 'TAARIIKHDA DIRISTA';

  @override
  String confirmSendTitle(String count) {
    return 'Ma u dirayaa $count qalab?';
  }

  @override
  String get confirmSendBody =>
      'Tan lama celin karo. Labada luqadood isku mar ayaa la gaadhsiinayaa.';

  @override
  String typeToConfirm(String word) {
    return 'Ku qor $word si aad u xaqiijiso';
  }

  @override
  String get confirmWord => 'DIR';

  @override
  String sentAsAudit(String name) {
    return 'Waxaa diray $name · waxaa lagu duubay diiwaanka hawlaha';
  }

  @override
  String get sendNow => 'Hadda dir';

  @override
  String pushSent(String count) {
    return 'Digniinta waxaa loo diray $count qalab';
  }

  @override
  String get liveControlTitle => 'Maamulka tooska';

  @override
  String get tvOnAir => 'TV WAA BAAHINAYAA';

  @override
  String get tvOffAir => 'TV MA BAAHINAYO';

  @override
  String get sectionTvChannel => 'KANAALKA TV';

  @override
  String get sectionRadio => 'RAADIYAHA';

  @override
  String get sectionRenditions => 'TAYADA';

  @override
  String get sectionSlate => 'FARRIINTA MARKA LA JOOJIYO';

  @override
  String get onAir => 'Waa baahinayaa';

  @override
  String get switchingOffShowsSlate => 'Joojintu waxay tusaysaa farriinta';

  @override
  String uptimeAndViewers(String uptime, String viewers) {
    return 'Muddada $uptime · $viewers isku mar';
  }

  @override
  String radioStatusLine(int bitrate, String listeners) {
    return '$bitrate kbps AAC · $listeners dhegeyste';
  }

  @override
  String protectedRungNote(String rung) {
    return '$rung waa tayada ay dadka badankoodu helaan — lama demin karo';
  }

  @override
  String get colRung => 'TAYADA';

  @override
  String get colBitrate => 'XAWLIGA';

  @override
  String get colHealth => 'CAAFIMAADKA';

  @override
  String get colEnabled => 'SHIDAN';

  @override
  String get healthy => 'Waa fiican';

  @override
  String get degraded => 'Waa liitaa';

  @override
  String get keyRung => 'MUHIIM';

  @override
  String get slateBothRequired =>
      'Labada luqadood waa loo baahan yahay ka hor inta aan kanaalka la joojin.';

  @override
  String get slatePreview => 'MUUQAALKA FARRIINTA';

  @override
  String get categoriesTitle => 'Qaybaha';

  @override
  String get newCategory => 'Qayb cusub';

  @override
  String get slugPermanentNote =>
      'Slug-ga waa mid joogto ah — wuxuu ku dhex jiraa xiriirada abka iyo mawduucyada digniinaha. Magacyada bandhigga ah waa mid luqad kasta oo waqti kasta la beddeli karo.';

  @override
  String get untranslatedHiddenNote =>
      'Qayb aan magac ku lahayn luqad waxaa laga qariyaa liiska luqaddaas, halkii aan la tusi lahayn mid aan la turjumin.';

  @override
  String get colSlug => 'SLUG';

  @override
  String get colArticles => 'MAQAALLO';

  @override
  String get colInApp => 'ABKA GUDIHIISA';

  @override
  String get notTranslated => 'Lama turjumin';

  @override
  String get scheduleTitle => 'Jadwalka';

  @override
  String gapsAndOverlaps(int gaps, int overlaps) {
    return '$gaps bannaan · $overlaps isku dhac';
  }

  @override
  String get publishDay => 'Daabac maalinta';

  @override
  String get autoResolveOverlap => 'Si toos ah u xalli isku dhaca';

  @override
  String gapLabel(String from, String to) {
    return 'BANNAAN $from – $to · waxaa buuxinaya farriin sii socoto';
  }

  @override
  String overlapLabel(int minutes) {
    return 'ISKU DHAC · wuxuu ku dhacayaa $minutes daq.';
  }

  @override
  String dayTotal(int hours, int minutes) {
    return 'Wadarta maalinta ${hours}s ${minutes}d ayaa la qorsheeyay';
  }

  @override
  String get publishBlockedByOverlap =>
      'Xalli isku dhaca ka hor inta aanad daabicin maalinta.';

  @override
  String get colName => 'MAGACA';

  @override
  String get collapseSidebar => 'Yaree liiska dhinaca';

  @override
  String get expandSidebar => 'Ballaari liiska dhinaca';

  @override
  String get clearFilters => 'Nadiifi shaandhaynta';

  @override
  String filterCategory(String value) {
    return 'Qaybta: $value';
  }

  @override
  String filterLocale(String value) {
    return 'Luqadda: $value';
  }

  @override
  String filterAuthor(String value) {
    return 'Qoraaga: $value';
  }

  @override
  String get filterAnyone => 'Qof kasta';

  @override
  String get bulkSchedule => 'Jadwalee…';

  @override
  String get bulkChangeCategory => 'Beddel qaybta';

  @override
  String rowsRange(int from, int to, int total) {
    return 'Safafka $from–$to ee $total';
  }

  @override
  String perPage(int count) {
    return '$count bog kasta';
  }

  @override
  String get rowActions => 'Hawlaha safka';

  @override
  String get languageNameSomali => 'Soomaali';

  @override
  String get languageNameEnglish => 'Ingiriisi';

  @override
  String missingTranslation(String language) {
    return 'Turjumaad $language ah ma jirto';
  }

  @override
  String translationBehindIn(String language) {
    return '$language wuu ka daahay';
  }

  @override
  String get consoleLanguage => 'Luqadda xarunta';

  @override
  String get tagline => 'Codka Dawladda Puntland, Soomaaliya';

  @override
  String get newAlert => 'Digniin cusub';

  @override
  String get todaysQueue => 'Safka daabacaadda maanta';

  @override
  String get openArticles => 'Fur maqaallada';

  @override
  String get recentPushes => 'Digniinihii ugu dambeeyay';

  @override
  String deliveredOf(String delivered, String targeted) {
    return 'La gaadhsiiyay $delivered / $targeted';
  }

  @override
  String get colTime => 'WAQTIGA';

  @override
  String liveFor(String duration) {
    return 'TOOS $duration';
  }

  @override
  String get queueEmpty => 'Waxba maanta looma jadwalayn';

  @override
  String get justNow => 'hadda';

  @override
  String get colUrl => 'URL';
}
