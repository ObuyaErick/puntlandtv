import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:video_player/video_player.dart';

import 'video_engine.dart';

/// The only place in the app that names `video_player`.
///
/// ExoPlayer on Android and AVPlayer on iOS, both of which play HLS natively —
/// which is why the mobile side needs nothing beyond the plugin, and why the
/// web side needs hls.js.
VideoEngine createVideoEngine() => NativeVideoEngine();

class NativeVideoEngine implements VideoEngine {
  VideoPlayerController? _controller;
  final _states = StreamController<VideoEngineState>.broadcast();
  VideoEngineState _state = const VideoEngineState();
  bool _live = false;

  @override
  VideoEngineState get state => _state;

  @override
  Stream<VideoEngineState> get states => _states.stream;

  void _emit(VideoEngineState next) {
    _state = next;
    if (!_states.isClosed) _states.add(next);
  }

  @override
  Future<void> load(String url, {required bool live, double volume = 1}) async {
    _live = live;
    await _teardown();

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    _controller = controller;
    controller.addListener(_onTick);

    try {
      await controller.initialize();
      await controller.setVolume(volume);
      await controller.play();
    } catch (_) {
      // Rethrowing would make every caller handle a plugin exception. The
      // state carries the failure instead, which is the same channel a
      // mid-playback error arrives on — so the UI has one path, not two.
      _emit(const VideoEngineState(errorCode: 'PLAYBACK_FAILED'));
      return;
    }

    _onTick();
  }

  void _onTick() {
    final value = _controller?.value;
    if (value == null) return;

    // The plugin surfaces a mid-playback failure on the value rather than by
    // throwing — a segment that 404s when the encoder drops arrives here.
    if (value.hasError) {
      _emit(_state.copyWith(errorCode: 'PLAYBACK_FAILED', isPlaying: false));
      return;
    }

    _emit(
      VideoEngineState(
        isInitialized: value.isInitialized,
        isPlaying: value.isPlaying,
        isBuffering: value.isBuffering,
        position: value.position,
        duration: _live ? null : value.duration,
        size: value.isInitialized ? value.size : null,
      ),
    );
  }

  @override
  Future<void> play() async => _controller?.play();

  @override
  Future<void> pause() async => _controller?.pause();

  @override
  Future<void> setVolume(double value) async => _controller?.setVolume(value);

  @override
  Future<void> seek(Duration to) async {
    if (_live) return;
    await _controller?.seekTo(to);
  }

  @override
  Widget? buildSurface({BoxFit fit = BoxFit.contain}) {
    final controller = _controller;
    final value = controller?.value;
    if (controller == null || value == null || !value.isInitialized) {
      return null;
    }

    // FittedBox around the intrinsic size rather than an AspectRatio, which is
    // what the two call sites did by hand before this engine existed: it lets
    // the caller choose contain (the full player letterboxes) or cover (the
    // mini-player's 96dp thumbnail fills and crops).
    return FittedBox(
      fit: fit,
      clipBehavior: fit == BoxFit.cover ? Clip.hardEdge : Clip.none,
      child: SizedBox(
        width: value.size.width,
        height: value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    await _teardown();
    await _states.close();
  }

  Future<void> _teardown() async {
    final controller = _controller;
    _controller = null;
    if (controller == null) return;
    controller.removeListener(_onTick);
    await controller.pause();
    await controller.dispose();
  }
}
