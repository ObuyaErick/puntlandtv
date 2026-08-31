/// One language's push payload.
class PushMessageDto {
  const PushMessageDto({this.title = '', this.body = ''});

  factory PushMessageDto.fromJson(Map<String, dynamic> json) => PushMessageDto(
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
  );

  final String title;
  final String body;

  /// Android truncates near here on the lock screen. Not a hard limit — a
  /// longer title still sends, it just gets cut where nobody sees it.
  static const titleTruncatesAt = 65;

  bool get isComplete => title.trim().isNotEmpty && body.trim().isNotEmpty;

  bool get titleWillTruncate => title.length > titleTruncatesAt;

  PushMessageDto copyWith({String? title, String? body}) =>
      PushMessageDto(title: title ?? this.title, body: body ?? this.body);

  Map<String, dynamic> toJson() => {'title': title, 'body': body};
}

/// A push alert being composed.
///
/// The rule this type exists to enforce: **a push cannot go out in one
/// language.** The payload is written before it leaves the server and cannot
/// be translated on the device, so an alert composed only in Somali reaches
/// English-preference readers as Somali, or not at all. Both are failures of
/// the bilingual promise, and neither is visible from the composer unless the
/// model refuses.
class PushDraftDto {
  const PushDraftDto({
    this.messages = const {},
    this.topics = const {'breaking'},
    this.deepLink,
    this.fallback = 'home',
  });

  factory PushDraftDto.fromJson(Map<String, dynamic> json) => PushDraftDto(
    messages: {
      for (final entry in (json['messages'] as Map<String, dynamic>).entries)
        entry.key: PushMessageDto.fromJson(entry.value as Map<String, dynamic>),
    },
    topics: (json['topics'] as List<dynamic>).cast<String>().toSet(),
    deepLink: json['deep_link'] as String?,
    fallback: json['fallback'] as String? ?? 'home',
  );

  final Map<String, PushMessageDto> messages;
  final Set<String> topics;

  /// `pltv://article/4183`. Null sends readers to the fallback surface.
  final String? deepLink;
  final String fallback;

  /// Locales an alert must exist in before it can be sent.
  static const requiredLocales = ['so', 'en'];

  PushMessageDto message(String locale) =>
      messages[locale] ?? const PushMessageDto();

  /// Locales still missing a title or a body.
  List<String> get incompleteLocales => requiredLocales
      .where((locale) => !message(locale).isComplete)
      .toList(growable: false);

  /// The single gate on sending.
  bool get canSend => incompleteLocales.isEmpty;

  /// A value-comparable key for the selected topics.
  ///
  /// `Set` equality in Dart is identity, so a provider keyed on the set itself
  /// never sees two selections as equal and re-fetches on every keystroke.
  String get topicsKey => (topics.toList()..sort()).join(',');

  PushDraftDto copyWith({
    Map<String, PushMessageDto>? messages,
    Set<String>? topics,
    String? deepLink,
  }) => PushDraftDto(
    messages: messages ?? this.messages,
    topics: topics ?? this.topics,
    deepLink: deepLink ?? this.deepLink,
    fallback: fallback,
  );

  PushDraftDto withMessage(String locale, PushMessageDto message) =>
      copyWith(messages: {...messages, locale: message});

  Map<String, dynamic> toJson() => {
    'messages': {
      for (final entry in messages.entries) entry.key: entry.value.toJson(),
    },
    'topics': topics.toList(),
    'deep_link': deepLink,
    'fallback': fallback,
  };
}

/// How many devices an alert would reach, split by language preference.
class PushReachDto {
  const PushReachDto({required this.byLocale});

  factory PushReachDto.fromJson(Map<String, dynamic> json) => PushReachDto(
    byLocale: (json['by_locale'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, v as int),
    ),
  );

  final Map<String, int> byLocale;

  int get total => byLocale.values.fold(0, (sum, count) => sum + count);

  int forLocale(String locale) => byLocale[locale] ?? 0;
}

/// A previously sent alert.
class PushHistoryEntryDto {
  const PushHistoryEntryDto({
    required this.id,
    required this.title,
    required this.sentAt,
    required this.sentBy,
    required this.topic,
    required this.delivered,
    required this.targeted,
  });

  final String id;
  final String title;
  final DateTime sentAt;
  final String sentBy;
  final String topic;
  final int delivered;
  final int targeted;

  double get deliveryRate => targeted == 0 ? 0 : delivered / targeted;
}
