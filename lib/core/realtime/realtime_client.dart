import 'realtime_event.dart';

/// The app's realtime surface, as an interface.
///
/// The same seam as [PuntlandApi], for the same reason: the app must keep
/// running end to end with no backend, so everything above this line is
/// written against the interface and cannot tell which implementation it got.
/// Two ship — [WebSocketRealtimeClient] against the real gateway, and
/// [FixtureRealtimeClient], which emits nothing.
///
/// "Emits nothing" is the honest fixture. A realtime client with no server is
/// a client that never delivers an event, and every screen above here already
/// has to work in exactly that case — because that is also what a viewer on a
/// train in a tunnel has.
abstract interface class RealtimeClient {
  /// Events on [topic], for as long as the returned stream is listened to.
  ///
  /// Subscription is **refcounted**: the first listener on a topic sends a
  /// `subscribe` frame, the last one to go away sends `unsubscribe`. That is
  /// what makes it safe for a screen to open and close the same topic
  /// repeatedly — which is what a list of channels does as the user scrolls —
  /// and what lets a retry simply re-listen rather than tear down a socket.
  ///
  /// The stream does not close when the connection drops. A drop is a gap, not
  /// an ending: the client reconnects underneath and resubscribes, and the
  /// consumer keeps its subscription across it. Watch [status] to know whether
  /// events are currently flowing.
  Stream<RealtimeEvent> subscribe(String topic);

  /// Where the connection stands, starting with its current value.
  Stream<RealtimeStatus> get status;

  /// Whether there is a server behind this client at all.
  ///
  /// False for [FixtureRealtimeClient], and it is load-bearing rather than
  /// informational: the fallback poll behind every `watch` exists to catch
  /// what a *socket* missed, so with no backend it would be a periodic timer
  /// re-reading bundled JSON forever. That is wasted work in a demo build and
  /// an outright failure in a widget test, where a pending periodic timer at
  /// the end of a test body fails the test.
  bool get isConnectable;

  /// The most recent status, for a caller that needs an answer now rather than
  /// a stream — a fallback poll choosing its interval, for instance.
  RealtimeStatus get currentStatus;

  /// Closes the socket and stops reconnecting. Called when the app is
  /// backgrounded, and on dispose.
  void close();

  /// Reopens after a [close], if there is anything still subscribed.
  void reopen();

  /// Closes for good. The client is not usable afterwards.
  void dispose();
}
