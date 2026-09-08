import 'dart:async';
import 'dart:js_interop';
// `has` and `getProperty`, for the two places this file has to ask about a
// JavaScript value the bindings above do not describe: whether the hls.js
// script actually loaded, and whether an error it reported is fatal.
import 'dart:js_interop_unsafe';
import 'dart:ui_web' as ui_web;

import 'package:material_ui/material_ui.dart';
import 'package:web/web.dart' as web;

import 'video_engine.dart';

/// HLS playback on the web, which `video_player` cannot do.
///
/// On web that plugin renders a plain `<video>` element, and only Safari can
/// play an `.m3u8` from one. Chrome and Firefox need the manifest parsed and
/// the segments fed to the element in JavaScript, which is what hls.js does.
/// Both the reader app and the console ship web builds, so this is the path
/// most of the desktop audience and every console operator takes.
///
/// The element is created once per engine and reused across loads. Flutter web
/// has no way to *un*register a platform view factory, so a factory per load
/// would accumulate one dead entry every time an operator changed channel.
VideoEngine createVideoEngine() => WebHlsVideoEngine();

/// hls.js, loaded from a `<script>` tag in `web/index.html`.
///
/// A minimal binding: enough to attach a manifest to an element and hear about
/// failures. hls.js has a large API and none of the rest of it is needed —
/// quality selection is left to its own adaptive logic, which is the whole
/// reason to use it.
@JS('Hls')
extension type _Hls._(JSObject _) implements JSObject {
  external _Hls();
  external static bool isSupported();
  external void loadSource(String url);
  external void attachMedia(web.HTMLVideoElement media);
  external void on(String event, JSFunction callback);
  external void destroy();
}

/// hls.js's own name for its error event (`Hls.Events.ERROR`).
const _hlsErrorEvent = 'hlsError';

/// Safari and iOS play HLS natively, and doing so is better than hls.js there:
/// it hands off to the platform's own pipeline, which on iOS is the only way
/// to get hardware decoding and AirPlay.
bool _canPlayHlsNatively(web.HTMLVideoElement element) =>
    element.canPlayType('application/vnd.apple.mpegurl').isNotEmpty;

var _viewTypeSeed = 0;

class WebHlsVideoEngine implements VideoEngine {
  WebHlsVideoEngine() {
    _viewType = 'puntland-video-${_viewTypeSeed++}';

    _element = web.HTMLVideoElement()
      // The element fills the platform view and crops or letterboxes itself;
      // `buildSurface` sets which. Doing it in CSS rather than with a Flutter
      // FittedBox keeps the browser's own scaler in the path.
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = 'transparent'
      ..controls = false
      // Without this, iOS Safari takes any playing video fullscreen and the
      // app's own player chrome is never seen.
      ..setAttribute('playsinline', 'true');

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int _) => _element,
    );

    _listen('loadedmetadata', _onMetadata);
    _listen('timeupdate', _onTimeUpdate);
    _listen('playing', _onPlaying);
    _listen('pause', _onPause);
    _listen('waiting', _onWaiting);
    _listen('error', _onError);
  }

  late final String _viewType;
  late final web.HTMLVideoElement _element;

  _Hls? _hls;
  bool _live = false;
  final _listeners = <(String, JSFunction)>[];
  final _states = StreamController<VideoEngineState>.broadcast();
  VideoEngineState _state = const VideoEngineState();

  @override
  VideoEngineState get state => _state;

  @override
  Stream<VideoEngineState> get states => _states.stream;

  void _listen(String type, void Function(web.Event) handler) {
    final callback = handler.toJS;
    _element.addEventListener(type, callback);
    _listeners.add((type, callback));
  }

  void _emit(VideoEngineState next) {
    _state = next;
    if (!_states.isClosed) _states.add(next);
  }

  @override
  Future<void> load(String url, {required bool live, double volume = 1}) async {
    _live = live;
    _detachHls();

    _emit(const VideoEngineState(isBuffering: true));

    // Set before play(), not after: an audible autoplay is refused outright
    // without a user gesture, so a silent preview has to be silent already.
    _element.volume = volume;
    _element.muted = volume == 0;

    if (_canPlayHlsNatively(_element)) {
      _element.src = url;
    } else if (_hlsAvailable && _Hls.isSupported()) {
      final hls = _Hls();
      _hls = hls;
      hls.on(
        _hlsErrorEvent,
        (JSAny _, JSObject data) {
          // hls.js reports recoverable errors too — a single segment timing
          // out, which it retries by itself. Only a fatal one is worth
          // surfacing, because the rest resolve without the viewer noticing.
          if (data['fatal'].isDefinedAndNotNull &&
              (data['fatal'] as JSBoolean).toDart) {
            _emit(_state.copyWith(errorCode: 'PLAYBACK_FAILED'));
          }
        }.toJS,
      );
      hls.loadSource(url);
      hls.attachMedia(_element);
    } else {
      // The script tag is missing or blocked. Falling back to a plain src is
      // hopeless on Chrome, so say so rather than showing a spinner forever.
      _emit(const VideoEngineState(errorCode: 'PLAYBACK_FAILED'));
      return;
    }

    try {
      await _element.play().toDart;
    } catch (_) {
      // Autoplay refused, or the source failed. Either way there is nothing
      // playing and the UI needs to offer the viewer a way to start it.
      _emit(_state.copyWith(isBuffering: false, errorCode: 'PLAYBACK_FAILED'));
    }
  }

  bool get _hlsAvailable => globalContext.has('Hls');

  void _onMetadata(web.Event _) => _emit(
    _state.copyWith(
      isInitialized: _element.videoWidth > 0,
      isBuffering: false,
      size: Size(
        _element.videoWidth.toDouble(),
        _element.videoHeight.toDouble(),
      ),
      clearError: true,
    ),
  );

  void _onTimeUpdate(web.Event _) => _emit(
    _state.copyWith(
      position: Duration(milliseconds: (_element.currentTime * 1000).round()),
      duration: _live ? null : _durationOrNull(),
    ),
  );

  Duration? _durationOrNull() {
    final seconds = _element.duration;
    if (seconds.isNaN || seconds.isInfinite) return null;
    return Duration(milliseconds: (seconds * 1000).round());
  }

  void _onPlaying(web.Event _) => _emit(
    _state.copyWith(
      isPlaying: true,
      isBuffering: false,
      isInitialized: true,
      clearError: true,
    ),
  );

  void _onPause(web.Event _) => _emit(_state.copyWith(isPlaying: false));

  void _onWaiting(web.Event _) => _emit(_state.copyWith(isBuffering: true));

  void _onError(web.Event _) =>
      _emit(_state.copyWith(isBuffering: false, errorCode: 'PLAYBACK_FAILED'));

  @override
  Future<void> play() async {
    try {
      await _element.play().toDart;
    } catch (_) {
      _emit(_state.copyWith(errorCode: 'PLAYBACK_FAILED'));
    }
  }

  @override
  Future<void> pause() async => _element.pause();

  @override
  Future<void> setVolume(double value) async {
    _element.volume = value;
    _element.muted = value == 0;
  }

  @override
  Future<void> seek(Duration to) async {
    if (_live) return;
    _element.currentTime = to.inMilliseconds / 1000;
  }

  @override
  Widget? buildSurface({BoxFit fit = BoxFit.contain}) {
    if (!_state.isInitialized) return null;
    _element.style.objectFit = fit == BoxFit.cover ? 'cover' : 'contain';
    return HtmlElementView(viewType: _viewType);
  }

  @override
  Future<void> dispose() async {
    _detachHls();
    for (final (type, callback) in _listeners) {
      _element.removeEventListener(type, callback);
    }
    _listeners.clear();
    _element.pause();
    _element.removeAttribute('src');
    await _states.close();
  }

  /// Tears down hls.js and clears the element's source.
  ///
  /// `destroy()` alone leaves the element holding the last decoded frame,
  /// which on a channel change shows the previous stream frozen under the new
  /// one's spinner. Removing `src` and calling `load()` is what actually
  /// blanks it.
  void _detachHls() {
    _hls?.destroy();
    _hls = null;
    _element.removeAttribute('src');
    _element.load();
  }
}
