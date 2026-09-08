import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:material_ui/material_ui.dart' show BoxFit, Widget;

import '../../../../core/playback/video_engine.dart';
import '../../../../core/playback/video_engine_factory.dart';
import '../../domain/entities/playback_source.dart';

/// Everything the UI needs to render any playback surface.
@immutable
class PlaybackState {
  const PlaybackState({
    this.source,
    this.isPlaying = false,
    this.isBuffering = false,
    this.isExpanded = false,
    this.audioOnly = false,
    this.position = Duration.zero,
    this.duration,
    this.qualityLabel,
    this.errorCode,
    this.volume = 1,
  });

  final PlaybackSource? source;
  final bool isPlaying;
  final bool isBuffering;

  /// True when the full-screen player is showing; false when docked as the
  /// mini-player. The same controller and the same platform player back both,
  /// which is why audio never cuts across the transition.
  final bool isExpanded;

  /// User dropped the video track to save data. The stream keeps playing.
  final bool audioOnly;

  final Duration position;
  final Duration? duration;

  /// The rung actually being received, as `720p`, or null before the first
  /// frame.
  ///
  /// Measured from the stream, not read from the API: with adaptive HLS the
  /// player picks the rendition and re-picks it as the connection changes, so
  /// the backend cannot know. Null when there is nothing to report, which is
  /// the case the chrome has to handle by showing nothing rather than a
  /// reassuring guess.
  final String? qualityLabel;

  final String? errorCode;
  final double volume;

  bool get hasSource => source != null;
  bool get isMuted => volume == 0;

  PlaybackState copyWith({
    PlaybackSource? source,
    bool? isPlaying,
    bool? isBuffering,
    bool? isExpanded,
    bool? audioOnly,
    Duration? position,
    Duration? duration,
    String? qualityLabel,
    String? errorCode,
    double? volume,
    bool clearSource = false,
    bool clearError = false,
  }) => PlaybackState(
    source: clearSource ? null : (source ?? this.source),
    isPlaying: isPlaying ?? this.isPlaying,
    isBuffering: isBuffering ?? this.isBuffering,
    isExpanded: isExpanded ?? this.isExpanded,
    audioOnly: audioOnly ?? this.audioOnly,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    qualityLabel: qualityLabel ?? this.qualityLabel,
    errorCode: clearError ? null : (errorCode ?? this.errorCode),
    volume: volume ?? this.volume,
  );
}

/// The single playback authority for the whole app.
///
/// Two rules it exists to enforce:
///
/// 1. **Only one thing plays at a time.** Starting the radio stops the live
///    channel and vice versa — the canvas calls for this explicitly, and it is
///    also what users expect from a broadcaster's app.
/// 2. **Playback outlives the screen that started it.** The controller is
///    app-scoped, so navigating away from the live page docks the player
///    rather than tearing it down. The video surface moves; the stream does
///    not restart.
///
/// The platform players are deliberately behind this class. Swapping the video
/// plugin is a change to `core/playback/` only, because no widget anywhere
/// imports one — this class hands out a built surface rather than a controller,
/// which is what makes that true rather than merely intended.
class PlaybackController extends Notifier<PlaybackState> {
  /// Created once and reused across sources, not per `play()`.
  ///
  /// The web engine registers a platform view factory in its constructor and
  /// Flutter web offers no way to unregister one, so an engine per source
  /// would leak a dead entry on every channel change. `load()` is the thing
  /// that swaps streams.
  VideoEngine? _engine;
  StreamSubscription<VideoEngineState>? _engineSub;

  ja.AudioPlayer? _audio;
  StreamSubscription<dynamic>? _audioSub;

  @override
  PlaybackState build() {
    ref.onDispose(_disposeAll);
    return const PlaybackState();
  }

  /// The video surface for the current source, or null when there is nothing
  /// to draw — audio-only, idle, or still opening the stream.
  ///
  /// [fit] is the caller's choice because the two mounts want different
  /// things: the full player letterboxes, and the mini-player's thumbnail
  /// fills and crops.
  Widget? buildVideoSurface({BoxFit fit = BoxFit.contain}) {
    if (state.audioOnly) return null;
    return _engine?.buildSurface(fit: fit);
  }

  Future<void> play(PlaybackSource source) async {
    if (state.source == source && state.isPlaying) {
      state = state.copyWith(isExpanded: true);
      return;
    }

    await _stopPlatformPlayers();
    state = PlaybackState(
      source: source,
      isBuffering: true,
      isExpanded: !source.isAudioOnly,
      audioOnly: source.isAudioOnly,
    );

    try {
      if (source.isAudioOnly) {
        await _startAudio(source);
      } else {
        await _startVideo(source);
      }
    } catch (e) {
      state = state.copyWith(
        isBuffering: false,
        isPlaying: false,
        errorCode: 'PLAYBACK_FAILED',
      );
    }
  }

  Future<void> _startVideo(PlaybackSource source) async {
    final engine = _engine ??= createVideoEngine();

    // Subscribed before loading, so the first frame's metadata is not missed.
    // Re-subscribed per source because `_stopPlatformPlayers` cancels it — the
    // engine outlives a source, the subscription does not.
    await _engineSub?.cancel();
    _engineSub = engine.states.listen(_onEngineState);

    await engine.load(source.url, live: source.isLive, volume: state.volume);
    _onEngineState(engine.state);
  }

  /// Mirrors the engine's state onto the app's.
  ///
  /// Two things are translated rather than copied. A live source has no
  /// duration, however much the engine thinks it knows — a scrub bar on a
  /// broadcast is a control that cannot be honoured. And an error is passed
  /// through as it arrives: the live page watches for `PLAYBACK_FAILED` on a
  /// live source and re-asks the API whether the channel is still up, which is
  /// how a dropped signal becomes a slate rather than a frozen frame.
  void _onEngineState(VideoEngineState engineState) {
    final isLive = state.source?.isLive ?? false;
    state = state.copyWith(
      isPlaying: engineState.isPlaying,
      isBuffering: engineState.isBuffering,
      position: engineState.position,
      duration: isLive ? null : engineState.duration,
      qualityLabel: engineState.qualityLabel,
      errorCode: engineState.errorCode,
      clearError: engineState.errorCode == null,
    );
  }

  Future<void> _startAudio(PlaybackSource source) async {
    final player = ja.AudioPlayer();
    _audio = player;
    await player.setUrl(source.url);
    await player.setVolume(state.volume);
    unawaited(player.play());

    _audioSub = player.playerStateStream.listen((s) {
      state = state.copyWith(
        isPlaying: s.playing,
        isBuffering:
            s.processingState == ja.ProcessingState.loading ||
            s.processingState == ja.ProcessingState.buffering,
      );
    });

    state = state.copyWith(isBuffering: false, clearError: true);
  }

  Future<void> togglePlayPause() async {
    if (!state.hasSource) return;
    if (state.isPlaying) {
      await _engine?.pause();
      await _audio?.pause();
      state = state.copyWith(isPlaying: false);
    } else {
      await _engine?.play();
      await _audio?.play();
      state = state.copyWith(isPlaying: true);
    }
  }

  Future<void> seek(Duration to) async {
    if (state.source?.isLive ?? true) return;
    await _engine?.seek(to);
    state = state.copyWith(position: to);
  }

  Future<void> setVolume(double value) async {
    await _engine?.setVolume(value);
    await _audio?.setVolume(value);
    state = state.copyWith(volume: value);
  }

  Future<void> toggleMute() => setVolume(state.isMuted ? 1 : 0);

  /// Drops the video track and keeps the audio, for users on metered data.
  ///
  /// Still only stops *rendering* the surface, so the toggle is instant and
  /// saves no bytes. Requesting an audio-only rendition is the change that
  /// would, and it needs a separate manifest — which needs the transcode
  /// ladder, because MediaMTX remuxes rather than transcodes and there is
  /// exactly one rung to ask for. Tracked with the ladder, not before it.
  void toggleAudioOnly() => state = state.copyWith(audioOnly: !state.audioOnly);

  void expand() => state = state.copyWith(isExpanded: true);

  void collapse() => state = state.copyWith(isExpanded: false);

  Future<void> stop() async {
    await _stopPlatformPlayers();
    state = const PlaybackState();
  }

  /// Stops what is playing without discarding the engine.
  ///
  /// The engine is kept: it holds a platform view registration on web that
  /// cannot be undone, and `load()` is what actually swaps streams. Only
  /// `_disposeAll`, at the end of the provider's life, tears it down.
  Future<void> _stopPlatformPlayers() async {
    await _engineSub?.cancel();
    _engineSub = null;
    await _engine?.pause();

    await _audioSub?.cancel();
    _audioSub = null;
    await _audio?.stop();
    await _audio?.dispose();
    _audio = null;
  }

  void _disposeAll() {
    _engineSub?.cancel();
    _engine?.dispose();
    _engine = null;
    _audioSub?.cancel();
    _audio?.dispose();
  }
}

final playbackControllerProvider =
    NotifierProvider<PlaybackController, PlaybackState>(PlaybackController.new);
