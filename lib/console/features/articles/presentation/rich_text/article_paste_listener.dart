/// The browser's paste event, which on the web is the only one there is.
///
/// **`Ctrl+V` never reaches flutter_quill in a browser.** Flutter maps every
/// clipboard shortcut to `DoNothingAndStopPropagationTextIntent` when
/// `kIsWeb` — see `_webDisablingTextShortcuts` in
/// `default_text_editing_shortcuts.dart` — so `PasteTextIntent` is never
/// dispatched, `QuillController.clipboardPaste` never runs, and every hook it
/// offers is unreachable. The browser hands the paste to Flutter's hidden
/// input instead and the engine delivers it as an editing-value update, which
/// is exactly why markdown has always arrived in a story as literal
/// `## Heading`. This console is a web app, so that is not an edge case: it is
/// the only case.
///
/// Listening to the DOM event is better than fighting the shortcut map anyway.
/// `event.clipboardData` needs no permission prompt and works in Firefox and
/// Safari, where `navigator.clipboard.read()` does not.
///
/// Off the web this is a no-op — flutter_quill's `onClipboardPaste` fires
/// there, and the handler is wired into it.
library;

export 'article_paste_listener_stub.dart'
    if (dart.library.js_interop) 'article_paste_listener_web.dart';
