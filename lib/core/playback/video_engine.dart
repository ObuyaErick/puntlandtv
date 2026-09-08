import 'dart:ui' show Size;

import 'package:material_ui/material_ui.dart' show BoxFit, Widget;

/// What a video engine reports about the stream it is playing.
///
/// Deliberately smaller than either plugin's own state class. Everything here
/// is something the UI actually renders; anything the UI does not render stays
/// inside the implementation, so a plugin swap cannot leak a new concept into
/// the widgets.
class VideoEngineState {
  const VideoEngineState({
    this.isInitialized = false,
    this.isPlaying = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.duration,
    this.size,
    this.errorCode,
  });

  /// Whether the engine has enough of the stream to draw a frame. Until this
  /// is true there is nothing to show but a spinner.
  final bool isInitialized;

  final bool isPlaying;
  final bool isBuffering;
  final Duration position;

  /// Null for a live stream, which has no end to seek towards.
  final Duration? duration;

  /// The source's intrinsic pixel size, once known.
  final Size? size;

  final String? errorCode;

  /// The rung the viewer is actually receiving, as `720p`.
  ///
  /// Measured from the stream rather than taken from the API, because with
  /// adaptive HLS the player — not the backend — decides which rendition to
  /// pull, and it changes mid-playback as the connection does.
  String? get qualityLabel {
    final height = size?.height;
    if (height == null || height <= 0) return null;
    return '${height.round()}p';
  }

  VideoEngineState copyWith({
    bool? isInitialized,
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    Size? size,
    String? errorCode,
    bool clearError = false,
  }) => VideoEngineState(
    isInitialized: isInitialized ?? this.isInitialized,
    isPlaying: isPlaying ?? this.isPlaying,
    isBuffering: isBuffering ?? this.isBuffering,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    size: size ?? this.size,
    errorCode: clearError ? null : (errorCode ?? this.errorCode),
  );
}

/// One way of playing a video, behind an interface the widgets can hold.
///
/// Two implementations exist and the platform picks between them at compile
/// time through `video_engine_factory.dart`:
///
///   * `NativeVideoEngine` wraps `video_player` — ExoPlayer on Android,
///     AVPlayer on iOS. Both play HLS natively.
///   * `WebHlsVideoEngine` drives an `HTMLVideoElement` with hls.js, because
///     `video_player` on web is a plain `<video>` tag and Chrome and Firefox
///     cannot play an `.m3u8` without help. Both reader and console ship to
///     web, so this is not an edge case.
///
/// The interface exists so that stays true of exactly two files. The playback
/// controller's own doc comment has promised since the scaffold that swapping
/// the video plugin is a one-file change; before this abstraction, two widgets
/// imported `video_player` directly and it was not.
abstract interface class VideoEngine {
  /// The current state, and a stream of every change to it.
  VideoEngineState get state;
  Stream<VideoEngineState> get states;

  /// Loads [url] and begins playing.
  ///
  /// [live] tells the engine there is no meaningful duration or seekable
  /// range, which is what keeps a live stream from rendering a scrub bar it
  /// cannot honour.
  ///
  /// [volume] is applied before playback starts rather than after, because on
  /// web it decides whether playback is allowed to start at all: browsers
  /// refuse to autoplay audible video without a user gesture, and a preview
  /// that is meant to be silent — the console's monitor — must say so up
  /// front or it simply never plays.
  Future<void> load(String url, {required bool live, double volume = 1});

  Future<void> play();
  Future<void> pause();
  Future<void> setVolume(double value);

  /// Ignored for a live stream.
  Future<void> seek(Duration to);

  /// The video surface, or null before there is a frame to draw.
  ///
  /// The engine owns its own aspect handling — a caller that had to ask for
  /// the intrinsic size and wrap it itself would be a caller that knows which
  /// engine it holds.
  Widget? buildSurface({BoxFit fit = BoxFit.contain});

  Future<void> dispose();
}
