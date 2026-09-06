import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'article_paste.dart';

/// Catches the browser's `paste` event for one body editor.
///
/// Registered on `document` in the **capture** phase, so it runs before the
/// event reaches Flutter's hidden input and before that input's default action
/// puts the plain text in the document.
class ArticlePasteListener {
  ArticlePasteListener({required this.isFocused, required this.onPaste});

  /// Whether this editor is the one the paste is meant for.
  ///
  /// Every body editor on screen — one per language tab — installs a listener,
  /// and they all see every paste. The focused one takes it.
  final bool Function() isFocused;

  final ArticlePasteSink onPaste;

  web.EventListener? _listener;

  void attach() {
    if (_listener != null) return;
    final listener = _onPaste.toJS;
    _listener = listener;
    web.document.addEventListener('paste', listener, true.toJS);
  }

  void detach() {
    final listener = _listener;
    if (listener == null) return;
    web.document.removeEventListener('paste', listener, true.toJS);
    _listener = null;
  }

  void _onPaste(web.Event event) {
    if (!isFocused()) return;

    final data = (event as web.ClipboardEvent).clipboardData;
    if (data == null) return;

    final html = data.getData('text/html');
    final text = data.getData('text/plain');
    final file = _firstImage(data);
    if (html.isEmpty && text.isEmpty && file == null) return;

    // Synchronous, and before anything is awaited: once this handler returns,
    // the browser performs the default paste, and a `preventDefault` decided
    // after an `await` arrives too late to stop it. Cancelling first means the
    // paste is now ours whatever it turns out to hold — which is why the sink
    // is `handleExclusively` and not `handle`.
    event.preventDefault();
    event.stopPropagation();

    unawaited(_deliver(html: html, text: text, file: file));
  }

  Future<void> _deliver({
    required String html,
    required String text,
    required web.File? file,
  }) async {
    await onPaste(
      html: html.isEmpty ? null : html,
      plainText: text.isEmpty ? null : text,
      imageBytes: file == null ? null : await _bytesOf(file),
    );
  }

  /// The first image on the clipboard, if there is one.
  ///
  /// A screenshot arrives as a file item with no name. Copying an image in a
  /// browser puts one here *and* an `<img src>` in the HTML; taking the bytes
  /// is what puts the picture in the media library instead of hotlinking
  /// somebody else's server from a published story.
  web.File? _firstImage(web.DataTransfer data) {
    final items = data.items;
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.kind != 'file') continue;
      if (!item.type.startsWith('image/')) continue;
      final file = item.getAsFile();
      if (file != null) return file;
    }
    return null;
  }

  Future<Uint8List?> _bytesOf(web.File file) async {
    try {
      final buffer = await file.arrayBuffer().toDart;
      return buffer.toDart.asUint8List();
    } catch (_) {
      // An unreadable blob is an image this paste does not have.
      return null;
    }
  }
}
