import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/playback/video_engine.dart';
import '../../../../../core/playback/video_engine_factory.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';

/// The stream preview: the actual channel, optionally with its LIVE flag
/// pinned to the corner.
///
/// This was a static box with a `videocam` glyph in it — a picture of a
/// preview. An operator's first question about a live channel is "what is
/// going out", and the screens built to answer it could not.
///
/// Plays the same URL a reader gets, so it fails the same way a reader's
/// player fails. Muted, because the alternative is a newsroom where every open
/// tab is talking, and because a browser refuses to autoplay audible video
/// without a gesture anyway.
///
/// Fills whatever it is given: live control and the overview size it
/// differently, and each already knows the box it has.
class StreamPreview extends StatefulWidget {
  const StreamPreview({
    super.key,
    required this.isLive,
    this.streamUrl,
    this.showLiveFlag = true,
  });

  final bool isLive;

  /// The playlist to show. Null, or off air, renders the placeholder.
  final String? streamUrl;

  /// Off where the surrounding card already says LIVE, so the preview does not
  /// say it a second time a few pixels away.
  final bool showLiveFlag;

  @override
  State<StreamPreview> createState() => _StreamPreviewState();
}

class _StreamPreviewState extends State<StreamPreview> {
  VideoEngine? _engine;
  StreamSubscription<VideoEngineState>? _sub;
  String? _loadedUrl;

  bool get _shouldPlay =>
      widget.isLive && (widget.streamUrl?.isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(StreamPreview old) {
    super.didUpdateWidget(old);
    _sync();
  }

  /// Starts, stops, or re-points the preview to match the channel.
  ///
  /// Guarded on the URL so a rebuild that re-reads the same channel — a
  /// refresh, a save elsewhere on the screen — does not restart playback.
  void _sync() {
    if (!_shouldPlay) {
      if (_loadedUrl != null) {
        _sub?.cancel();
        _sub = null;
        _engine?.dispose();
        _engine = null;
        _loadedUrl = null;
      }
      return;
    }
    if (_loadedUrl == widget.streamUrl) return;

    _loadedUrl = widget.streamUrl;
    final engine = _engine ??= createVideoEngine();

    // Replaced, not stacked: the engine outlives a URL, so re-listening
    // without cancelling would leave one live subscription per channel change,
    // each calling setState on every frame.
    _sub?.cancel();
    _sub = engine.states.listen((_) {
      if (mounted) setState(() {});
    });
    // Volume zero, and stated at load time rather than after: an audible
    // autoplay is refused outright without a user gesture, so a preview that
    // asks to be silent afterwards never starts at all.
    engine.load(widget.streamUrl!, live: true, volume: 0);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _engine?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surface = _engine?.buildSurface(fit: BoxFit.cover);

    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Radii.button),
            child: ColoredBox(
              color: const Color(0xFF04101F),
              child:
                  surface ??
                  Center(
                    child: Icon(
                      widget.isLive
                          ? Icons.hourglass_empty_rounded
                          : Icons.videocam_off_outlined,
                      size: 26,
                      color: DarkTokens.onSurfaceVariant,
                    ),
                  ),
            ),
          ),
        ),
        if (widget.isLive && widget.showLiveFlag)
          Positioned(
            left: 8,
            top: 8,
            child: Container(
              height: 22,
              padding: const EdgeInsets.symmetric(horizontal: 7),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: LightTokens.accent,
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                context.l10n.live,
                style: context.text.overline.copyWith(
                  fontSize: 9.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
