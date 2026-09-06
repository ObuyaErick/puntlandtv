/// Turns a decided paste into a change in the document.
///
/// [ArticlePasteAction] says *what* a paste is; this says what happens to a
/// live editor because of it. The split is deliberate: everything here is
/// about a document, a network call and the time between them, and none of it
/// can be reasoned about by reading the clipboard.
///
/// **The upload is the hard part, and the reason is the gap.** Registering a
/// pasted screenshot with the media library is a round trip. In that time the
/// journalist can type, move the caret, switch to the other language, or close
/// the editor — and the editor closing disposes the [QuillController] this
/// holds. Every guard below exists because one of those makes an unguarded
/// insert land in the wrong place, throw after disposal, or save a placeholder
/// into a published story.
library;

// flutter_quill marks its whole clipboard surface experimental, and this file
// is the one place that touches it. `internal.dart` carries the same warning
// with more teeth — it may change in a minor version — which is why
// `pubspec.yaml` pins the package to the 11.5 line rather than a caret range.
// The alternative was a direct dependency on `quill_native_bridge`, a package
// that describes itself as internal to flutter_quill; this at least reads from
// the same clipboard instance flutter_quill's own paste paths do, so a fake
// installed in a test is a fake for both.
// ignore_for_file: experimental_member_use

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart' show Clipboard, TextSelection;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/internal.dart' show ClipboardServiceProvider;
import 'package:flutter_quill/quill_delta.dart';

import '../../../../core/admin_api/dto/media_dto.dart';
import '../../../../core/admin_api/puntland_admin_api.dart';
import 'article_embeds.dart';
import 'article_paste.dart';

/// What happened, for the editor chrome to say out loud.
enum ArticlePasteResult {
  /// Plain text was read as markdown. The only case where the editor guessed,
  /// so the only one that has to offer a way back.
  reformatted,

  /// An image was uploaded and inserted. It has no alt text yet.
  imageAdded,

  imageTooLarge,

  /// Bytes in a format this product does not accept as an image.
  imageRejected,

  uploadFailed,
}

/// One thing the operator should be told about a paste.
class ArticlePasteOutcome {
  const ArticlePasteOutcome(this.result, {this.assetId});

  final ArticlePasteResult result;

  /// The media asset a pasted image landed as, so the toast can offer to open
  /// it. An undescribed image is the library's one actionable state, and the
  /// moment it is created is the cheapest moment to fix it.
  final String? assetId;
}

/// A pasted image larger than this is refused before it is uploaded.
///
/// A 4K screenshot is comfortably 8MB of PNG, and a body is not the place for
/// one — the reader downloads it over a metered connection.
const kMaxPastedImageBytes = 8 * 1024 * 1024;

/// Applies pastes to one locale's body.
///
/// One per [ArticleDraft], living as long as its controller does.
class ArticlePasteHandler {
  ArticlePasteHandler({required this.api, required this.onOutcome});

  final PuntlandAdminApi api;
  final void Function(ArticlePasteOutcome outcome) onOutcome;

  QuillController? _controller;
  var _uploads = 0;
  var _tokens = 0;

  /// True while a pasted image is on its way to the library.
  ///
  /// The editor autosaves two seconds after the last edit, and inserting the
  /// placeholder *is* an edit. A save landing before the upload does would
  /// write a body whose image is a custom embed the HTML converter renders as
  /// nothing — the picture silently missing from a stored story. Autosave
  /// waits instead.
  bool get isUploading => _uploads > 0;

  /// Binds the controller this handles pastes for.
  ///
  /// Separate from the constructor because the controller's own config has to
  /// carry [clipboardConfig], and a controller cannot be handed a config that
  /// refers to itself.
  void attach(QuillController controller) => _controller = controller;

  /// Drops the controller, after the draft that owned it is disposed.
  ///
  /// [QuillController] exposes no way to ask whether it has been disposed, and
  /// notifying a disposed one throws. This is that missing question.
  void detach() => _controller = null;

  /// flutter_quill's paste configuration for the bound controller.
  QuillClipboardConfig get clipboardConfig => QuillClipboardConfig(
    // flutter_quill's own rich paste is `DeltaX.fromHtml`, which is
    // `flutter_quill_delta_from_html` — the converter `article_html.dart` was
    // written to replace, because it renders two paragraphs as one. Left on,
    // it runs before anything here can and welds them together.
    enableExternalRichPaste: false,
    onClipboardPaste: _pasteFromSystemClipboard,
  );

  /// Takes a paste. Returns false when the ordinary paste should run instead.
  Future<bool> handle({
    String? html,
    String? plainText,
    Uint8List? imageBytes,
  }) async {
    final controller = _controller;
    if (controller == null || !_canEdit(controller)) return false;

    // An image copied from *inside* this editor belongs to flutter_quill: it
    // is holding the URL and its style, and it cleared the clipboard text to
    // say so. The system clipboard may still be carrying an unrelated
    // screenshot from an hour ago, and re-uploading that would be a
    // bewildering thing to watch happen.
    if (controller.copiedImageUrl != null) return false;

    final action = decidePaste(
      html: html,
      plainText: plainText,
      imageBytes: imageBytes,
    );

    switch (action) {
      case PasteNotHandled():
        return false;
      case InsertPastedDelta(:final delta, :final wasReformatted):
        _compose(controller, delta);
        if (wasReformatted) {
          onOutcome(const ArticlePasteOutcome(ArticlePasteResult.reformatted));
        }
        return true;
      case UploadPastedImage(:final bytes):
        await _upload(controller, bytes);
        return true;
    }
  }

  /// Takes a paste whose default the caller has already cancelled.
  ///
  /// The browser gives a `paste` listener no second chance: `preventDefault`
  /// has to be called before anything is known about the clipboard's contents,
  /// so by the time [handle] declines, the ordinary paste is already gone and
  /// this has to stand in for it.
  ///
  /// The stand-in is plain text, which is what a web paste has always been
  /// here — `Ctrl+V` on the web never reached flutter_quill's clipboard code
  /// at all, so nothing is lost that used to work.
  Future<void> handleExclusively({
    String? html,
    String? plainText,
    Uint8List? imageBytes,
  }) async {
    if (await handle(
      html: html,
      plainText: plainText,
      imageBytes: imageBytes,
    )) {
      return;
    }

    final controller = _controller;
    final text = plainText ?? '';
    if (controller == null || text.isEmpty || !_canEdit(controller)) return;

    final selection = controller.selection;
    controller.replaceText(
      selection.start,
      selection.end - selection.start,
      text,
      TextSelection.collapsed(offset: selection.start + text.length),
    );
  }

  /// The desktop route: flutter_quill asks, and this reads the clipboard.
  ///
  /// Also the web's context-menu route, which does reach this — only the
  /// keyboard shortcut is intercepted before flutter_quill sees it.
  Future<bool> _pasteFromSystemClipboard() async {
    final clipboard = ClipboardServiceProvider.instance;
    final html = await _read(clipboard.getHtmlText);
    final image = await _read(clipboard.getImageFile);
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    return handle(html: html, plainText: text, imageBytes: image);
  }

  /// Reads one clipboard flavour, or nothing.
  ///
  /// Checking `isSupported` is not enough: on the web it only asks whether
  /// `navigator.clipboard` exists, so Firefox — which has the object but not
  /// `read()` — answers yes and then throws. An uncaught error there kills the
  /// whole paste with no message. A flavour that cannot be read is a flavour
  /// this paste does not use.
  Future<T?> _read<T>(Future<T?> Function() flavour) async {
    try {
      return await flavour();
    } catch (_) {
      return null;
    }
  }

  bool _canEdit(QuillController controller) =>
      !controller.readOnly && controller.selection.isValid;

  void _compose(QuillController controller, Delta delta) {
    final start = controller.selection.start;
    final length = controller.selection.end - start;

    _startHistoryEntry(controller);
    // The selection is set afterwards rather than passed in: `replaceText`
    // works out where the caret went with `getPositionDelta`, which measures
    // the inserted data — and a `Delta` measures as one character however much
    // prose it carries, leaving the caret at the front of a pasted article.
    controller.replaceText(start, length, delta, null);
    controller.updateSelection(
      TextSelection.collapsed(offset: start + _insertedLength(delta)),
      ChangeSource.local,
    );
  }

  Future<void> _upload(QuillController controller, Uint8List bytes) async {
    final format = ImageFormat.of(bytes);
    if (format == null) {
      onOutcome(const ArticlePasteOutcome(ArticlePasteResult.imageRejected));
      return;
    }
    if (bytes.length > kMaxPastedImageBytes) {
      onOutcome(const ArticlePasteOutcome(ArticlePasteResult.imageTooLarge));
      return;
    }

    // The placeholder is what makes the round trip safe. It holds the spot the
    // caret was in, so the image lands where it was pasted even if the caret
    // has moved on; it makes two quick pastes independent of each other; and
    // it tells the journalist something is happening.
    final token = 'paste-${_tokens++}';
    final document = controller.document;

    final start = controller.selection.start;
    _startHistoryEntry(controller);
    controller.replaceText(
      start,
      controller.selection.end - start,
      PendingImageEmbed(token),
      TextSelection.collapsed(offset: start + 1),
    );

    _uploads++;
    try {
      final asset = await api.uploadMedia(
        filename: _pastedFilename(format),
        kind: MediaKind.image,
        byteSize: bytes.length,
        bytes: bytes,
      );
      if (!_stillEditing(document)) return;
      if (!_replacePlaceholder(token, BlockEmbed.image(asset.url))) return;
      onOutcome(
        ArticlePasteOutcome(ArticlePasteResult.imageAdded, assetId: asset.id),
      );
    } catch (_) {
      // The draft must not keep a change the upload did not earn — the same
      // rule the autosave path follows when a write fails.
      if (_stillEditing(document)) {
        _replacePlaceholder(token, null);
        onOutcome(const ArticlePasteOutcome(ArticlePasteResult.uploadFailed));
      }
    } finally {
      _uploads--;
    }
  }

  /// Whether the controller this started on is still the one on screen.
  ///
  /// Two ways it is not: the draft was disposed while the upload was in
  /// flight, or the document was swapped underneath the controller. Composing
  /// into either is an exception in debug and a lost edit in release.
  bool _stillEditing(Document document) {
    final controller = _controller;
    return controller != null && identical(controller.document, document);
  }

  /// Swaps the placeholder for [replacement], or removes it when null.
  ///
  /// False when the placeholder is gone — undone, or deleted by hand while the
  /// upload was running. Both are the journalist saying they did not want it,
  /// and putting the image back would be arguing.
  bool _replacePlaceholder(String token, Embeddable? replacement) {
    final controller = _controller;
    if (controller == null) return false;

    final offset = _placeholderOffset(controller.document, token);
    if (offset == null) return false;

    _startHistoryEntry(controller);
    controller.replaceText(
      offset,
      1,
      replacement ?? '',
      TextSelection.collapsed(
        offset: replacement == null ? offset : offset + 1,
      ),
    );
    return true;
  }

  /// Makes the next change its own undo step.
  ///
  /// `History.record` folds changes made within 400ms of each other into one
  /// entry. Without this, a paste typed quickly after a word takes that word
  /// with it when undone — and undo is the entire answer to a markdown guess
  /// that came out wrong.
  void _startHistoryEntry(QuillController controller) =>
      controller.document.history.lastRecorded = 0;
}

/// Where [token]'s placeholder is, or null if it is no longer in [document].
int? _placeholderOffset(Document document, String token) {
  var offset = 0;
  for (final op in document.toDelta().toList()) {
    if (!op.isInsert) continue;
    final data = op.data;
    if (data is String) {
      offset += data.length;
      continue;
    }
    if (data is Map && data[PendingImageEmbed.embedType] == token) {
      return offset;
    }
    offset += 1;
  }
  return null;
}

int _insertedLength(Delta delta) {
  var length = 0;
  for (final op in delta.toList()) {
    if (!op.isInsert) continue;
    final data = op.data;
    length += data is String ? data.length : 1;
  }
  return length;
}

/// A name for a file that arrived without one.
///
/// The media grid is a list of names people read, so it says what it is and
/// when it landed. Somali, like the rest of the library's fixtures.
String _pastedFilename(ImageFormat format) {
  final now = DateTime.now();
  String pad(int value, [int width = 2]) =>
      value.toString().padLeft(width, '0');
  final stamp =
      '${now.year}${pad(now.month)}${pad(now.day)}'
      '-${pad(now.hour)}${pad(now.minute)}${pad(now.second)}'
      '${pad(now.millisecond, 3)}';
  return 'sawir-$stamp.${format.extension}';
}
