/// One event, as it arrived from the API.
///
/// Pure Dart, and deliberately untyped in its [data]: the repositories that
/// consume an event already know which topic they subscribed to and therefore
/// what shape to read, and a sealed hierarchy of payload classes here would be
/// a second copy of `src/realtime/realtime.events.ts` to keep in step with the
/// first. The typing that matters — that a name and its payload agree — is
/// enforced on the emitting side, where the emitters are.
class RealtimeEvent {
  const RealtimeEvent({
    required this.topic,
    required this.name,
    required this.data,
    required this.at,
  });

  /// Reads the server's `type: "event"` frame.
  ///
  /// Returns null for any frame that is not an event or is missing the fields
  /// an event must have. A client one deploy behind the API will meet frames
  /// it has no use for, and that is not an error — it is the normal state of
  /// a mobile fleet during a rollout.
  static RealtimeEvent? tryParse(Map<String, dynamic> frame) {
    if (frame['type'] != 'event') return null;

    final topic = frame['topic'];
    final name = frame['event'];
    if (topic is! String || name is! String) return null;

    final data = frame['data'];
    return RealtimeEvent(
      topic: topic,
      name: name,
      data: data is Map<String, dynamic> ? data : const {},
      at: DateTime.tryParse(frame['at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  final String topic;

  /// The event name, e.g. `live.changed`. See [RealtimeEventName].
  final String name;

  /// The payload, `snake_case` exactly as the API sends it.
  final Map<String, dynamic> data;

  /// When the API raised it, not when this client read it — so a burst that
  /// arrives together after a reconnect is still orderable.
  final DateTime at;

  /// Reads [key] as a bool, defaulting rather than throwing: a payload field
  /// this build has never heard of is a rollout, not a bug.
  bool boolean(String key, {bool orElse = false}) {
    final value = data[key];
    return value is bool ? value : orElse;
  }

  /// Reads [key] as a string, or null.
  String? string(String key) {
    final value = data[key];
    return value is String ? value : null;
  }

  /// Reads [key] as an int, or null.
  int? integer(String key) {
    final value = data[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }

  @override
  String toString() => 'RealtimeEvent($topic · $name)';
}

/// The event names the API can send. Mirrors `RealtimeEvent` in
/// `src/realtime/realtime.events.ts`; a name here that does not exist there is
/// simply one nothing will ever emit.
abstract final class RealtimeEventName {
  static const channelsChanged = 'channels.changed';
  static const liveChanged = 'live.changed';
  static const radioChanged = 'radio.changed';
  static const articlePublished = 'article.published';
  static const articleUnpublished = 'article.unpublished';
  static const articleChanged = 'article.changed';
  static const articleEditing = 'article.editing';
  static const controlChanged = 'control.changed';
  static const viewersChanged = 'viewers.changed';
  static const mediaProgress = 'media.progress';
  static const mediaReady = 'media.ready';
  static const mediaFailed = 'media.failed';
}

/// The topics a client may subscribe to.
///
/// Built here rather than spelled at each call site, because the API parses
/// these strictly — an unparsed topic is refused rather than ignored — and a
/// typo would be a screen that silently never updates.
abstract final class RealtimeTopic {
  /// The published channel list.
  static const channels = 'channels';

  /// The public feed.
  static const news = 'news';

  /// Media ingest progress. Requires `manageLibrary`.
  static const adminMedia = 'admin:media';

  /// Newsroom presence. Requires any signed-in member of staff.
  static const adminNewsroom = 'admin:newsroom';

  /// One channel, as a reader sees it.
  static String channel(String key) => 'channel:$key';

  /// One channel's control room. Requires `manageBroadcast`.
  static String adminChannel(String key) => 'admin:channel:$key';
}

/// Where the connection stands.
///
/// The console shows this directly; the reader uses it to decide whether its
/// fallback poll should run at the fast cadence or the slow one.
enum RealtimeStatus {
  /// No socket, and none being attempted — the app is backgrounded, the device
  /// is offline, or there is no backend configured at all.
  idle,

  /// Connecting, or waiting out a backoff delay before trying again.
  connecting,

  /// Connected, with every held topic resubscribed.
  connected,
}
