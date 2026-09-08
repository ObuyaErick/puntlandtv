/// Picks the video engine at compile time.
///
/// (A `library` directive follows because this file is only a doc comment and
/// a conditional export, and the analyser needs the comment anchored to
/// something.)
///
/// Native is the default and web is the exception, which is the right way
/// round: the mobile apps are the product, and the web builds exist so the
/// console has somewhere to run and so a reader on a desktop is not turned
/// away. `dart.library.js_interop` is only true on web.
///
/// The consequence of doing this here rather than with a `kIsWeb` branch is
/// that neither implementation's imports reach the other platform — a mobile
/// build never sees `dart:ui_web`, and a web build never links ExoPlayer.
library;

export 'native_video_engine.dart'
    if (dart.library.js_interop) 'web_hls_video_engine.dart';
