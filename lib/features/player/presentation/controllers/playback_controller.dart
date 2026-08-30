import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:video_player/video_player.dart';

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
/// The platform players are deliberately behind this class. Swapping
/// `video_player` for `media_kit` is a change to this file only, because no
/// widget anywhere imports either package.
class PlaybackController extends Notifier<PlaybackState> {
  VideoPlayerController? _video;
  ja.AudioPlayer? _audio;
  StreamSubscription<dynamic>? _audioSub;
  Timer? _ticker;

  @override
  PlaybackState build() {
    ref.onDispose(_disposeAll);
    return const PlaybackState();
  }

  /// Video surface for the current source, or null when audio-only or idle.
  VideoPlayerController? get videoController => state.audioOnly ? null : _video;

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
    final controller = VideoPlayerController.networkUrl(Uri.parse(source.url));
    _video = controller;
    await controller.initialize();
    await controller.setVolume(state.volume);
    await controller.play();

    controller.addListener(_onVideoTick);
    state = state.copyWith(
      isPlaying: true,
      isBuffering: false,
      duration: source.isLive ? null : controller.value.duration,
      clearError: true,
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

  void _onVideoTick() {
    final v = _video?.value;
    if (v == null) return;
    state = state.copyWith(
      isPlaying: v.isPlaying,
      isBuffering: v.isBuffering,
      position: v.position,
      duration: state.source?.isLive ?? false ? null : v.duration,
    );
  }

  Future<void> togglePlayPause() async {
    if (!state.hasSource) return;
    if (state.isPlaying) {
      await _video?.pause();
      await _audio?.pause();
      state = state.copyWith(isPlaying: false);
    } else {
      await _video?.play();
      await _audio?.play();
      state = state.copyWith(isPlaying: true);
    }
  }

  Future<void> seek(Duration to) async {
    if (state.source?.isLive ?? true) return;
    await _video?.seekTo(to);
    state = state.copyWith(position: to);
  }

  Future<void> setVolume(double value) async {
    await _video?.setVolume(value);
    await _audio?.setVolume(value);
    state = state.copyWith(volume: value);
  }

  Future<void> toggleMute() => setVolume(state.isMuted ? 1 : 0);

  /// Drops the video track and keeps the audio, for users on metered data.
  ///
  /// The MVP keeps the same stream running and simply stops rendering the
  /// surface, so the toggle is instant. Requesting an audio-only rendition
  /// from the CDN — the change that would actually save bytes — needs a
  /// separate manifest from the backend and is tracked for Phase 2.
  void toggleAudioOnly() => state = state.copyWith(audioOnly: !state.audioOnly);

  void expand() => state = state.copyWith(isExpanded: true);

  void collapse() => state = state.copyWith(isExpanded: false);

  Future<void> stop() async {
    await _stopPlatformPlayers();
    state = const PlaybackState();
  }

  Future<void> _stopPlatformPlayers() async {
    _ticker?.cancel();
    _ticker = null;

    _video?.removeListener(_onVideoTick);
    await _video?.pause();
    await _video?.dispose();
    _video = null;

    await _audioSub?.cancel();
    _audioSub = null;
    await _audio?.stop();
    await _audio?.dispose();
    _audio = null;
  }

  void _disposeAll() {
    _ticker?.cancel();
    _video?.removeListener(_onVideoTick);
    _video?.dispose();
    _audioSub?.cancel();
    _audio?.dispose();
  }
}

final playbackControllerProvider =
    NotifierProvider<PlaybackController, PlaybackState>(PlaybackController.new);
