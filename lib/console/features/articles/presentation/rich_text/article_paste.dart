/// What a paste becomes, decided before anything touches the document.
///
/// **Every rule here is a pure function of what was on the clipboard.** The
/// two things that read the clipboard — a browser `paste` event on the web, and
/// flutter_quill's `onClipboardPaste` everywhere else — differ in almost every
/// respect, and neither can be exercised by `flutter test`. Keeping the
/// decision separate from the reading means the interesting half is a table of
/// inputs and expected outputs, testable on the VM with no browser, no
/// clipboard permission and no widget binding.
///
/// **Why the editor takes paste over at all.** flutter_quill will do rich
/// paste itself, and both of its routes are dead ends here. Its HTML route
/// goes through `DeltaX.fromHtml`, which is `flutter_quill_delta_from_html` —
/// the package `article_html.dart` documents as rendering
/// `<p>One.</p><p>Two.</p>` as `One.Two.`, and the reason this product parses
/// HTML by hand. Its markdown route reads a `.md` **file** off the clipboard
/// and nothing else, which no one has ever put there; on the web the file
/// bridge reports itself unsupported, so it is dead code. Pasting markdown
/// *text* — copied out of a chat answer, a README, a notes app — was never
/// handled by anything, which is why it arrives in a story as literal
/// `## Heading`.
library;

import 'dart:typed_data';

import 'package:flutter_quill/quill_delta.dart';
import 'package:markdown/markdown.dart' as md;

import 'article_html.dart';

/// Receives what was on the clipboard. Returns true when this editor took it.
///
/// The shape both clipboard routes speak, so neither the browser listener nor
/// flutter_quill's hook knows anything about documents, uploads or drafts.
typedef ArticlePasteSink = Future<bool> Function({
  String? html,
  String? plainText,
  Uint8List? imageBytes,
});

/// What the editor should do with a paste.
sealed class ArticlePasteAction {
  const ArticlePasteAction();
}

/// Compose [delta] at the caret.
final class InsertPastedDelta extends ArticlePasteAction {
  const InsertPastedDelta(this.delta, {required this.wasReformatted});

  final Delta delta;

  /// True when the source was plain text that [looksLikeMarkdown] chose to
  /// read as markup.
  ///
  /// The one case where the editor guessed rather than read, so the one case
  /// that has to offer a way back. The toast carries an undo.
  final bool wasReformatted;
}

/// Upload [bytes] to the media library and insert the image it returns.
final class UploadPastedImage extends ArticlePasteAction {
  const UploadPastedImage(this.bytes);

  final Uint8List bytes;
}

/// Nothing here this editor improves on. Let the ordinary paste run.
final class PasteNotHandled extends ArticlePasteAction {
  const PasteNotHandled();
}

/// Decides what the clipboard's contents should become.
///
/// The order is the whole design:
///
/// 1. **Image bytes first.** A browser's "copy image" puts *both* the bytes and
///    an `<img src>` on the clipboard. Taking the HTML would hotlink someone
///    else's server from a published story; taking the bytes puts the picture
///    in the media library, where the alt-text rule and the in-use delete
///    refusal can reach it.
/// 2. **HTML next.** Every rich source — browser, Word, Google Docs, Notion —
///    puts `text/html` on the clipboard, so this branch catches all of them and
///    the guesswork below never sees them.
/// 3. **Markdown-looking plain text last**, and only when it is unambiguous.
/// 4. **Otherwise nothing**, and the ordinary paste runs. That matters for
///    copying *within* the editor: Flutter puts only plain text on the system
///    clipboard, so an internal copy reaches step 3 as prose, declines, and
///    falls through to flutter_quill's own path — which restores the styles and
///    embeds from the delta it kept.
ArticlePasteAction decidePaste({
  String? html,
  String? plainText,
  Uint8List? imageBytes,
}) {
  if (imageBytes != null && imageBytes.isNotEmpty) {
    return UploadPastedImage(imageBytes);
  }

  final markup = html?.trim() ?? '';
  if (markup.isNotEmpty && markup.length <= _maxHtmlBytes) {
    final delta = articlePasteDelta(markup);
    if (_carriesContent(delta)) {
      return InsertPastedDelta(delta, wasReformatted: false);
    }
  }

  final text = plainText ?? '';
  if (text.isNotEmpty && looksLikeMarkdown(text)) {
    final delta = markdownToArticleDelta(text);
    if (_carriesContent(delta)) {
      return InsertPastedDelta(delta, wasReformatted: true);
    }
  }

  return const PasteNotHandled();
}

/// Converts markdown [source] to a delta over [kArticleTags].
///
/// Via HTML rather than direct to a delta, so the closed vocabulary, the tag
/// normalisation and the caret shaping in `article_html.dart` all apply
/// unchanged — one parser to be sure of instead of two.
///
/// GitHub-flavoured markdown passes raw HTML through, which means markup typed
/// into a markdown document lands in the same parser as markup pasted from a
/// browser and is subject to the same rules: `<strong>` is bold, `<script>` is
/// dropped, `<h1>` becomes an H2. One vocabulary regardless of how the text
/// arrived, rather than a second set of decisions for this route.
Delta markdownToArticleDelta(String source) => articlePasteDelta(
  md.markdownToHtml(source, extensionSet: md.ExtensionSet.gitHubFlavored),
);

/// Whether plain [text] should be read as markdown.
///
/// **The cost of a false positive is not a stray bold run.** Markdown folds a
/// soft line break into a space, so text wrongly read as markdown comes back
/// with its lines *merged* — two sentences run together in published copy,
/// which is the same failure `documentToArticleHtml` sets `multiLineParagraph`
/// to avoid. That is why the thresholds below are deliberately reluctant:
///
/// - A heading, a quote or a fence is decisive on its own. `#{1,6}` must be
///   followed by whitespace, or `#Puntland` in a social post becomes an H2.
/// - A list marker is **not** decisive on its own. A single line opening with
///   `- ` is far more often dialogue attribution or a dash than a list, so two
///   consecutive item lines are required — a real list has a second item.
/// - Inline markers are the weakest signal and need two of them. One
///   `**word**` in a paragraph is as likely to be someone's asterisks.
///
/// Anything larger than [_maxMarkdownScan] declines outright: a pasted log or
/// a database dump is not an article, and scanning it is wasted work on the
/// keystroke path.
bool looksLikeMarkdown(String text) {
  if (text.length > _maxMarkdownScan) return false;

  final lines = text.split('\n');

  var previousBullet = false;
  var previousOrdered = false;

  for (final line in lines) {
    if (_heading.hasMatch(line) ||
        _blockQuote.hasMatch(line) ||
        _fence.hasMatch(line)) {
      return true;
    }

    final bullet = _bullet.hasMatch(line);
    if (bullet && previousBullet) return true;

    final ordered = _ordered.hasMatch(line);
    if (ordered && previousOrdered) return true;

    previousBullet = bullet;
    previousOrdered = ordered;
  }

  var inline = 0;
  for (final pattern in _inlineMarkers) {
    inline += pattern.allMatches(text).length;
    if (inline >= 2) return true;
  }
  return false;
}

/// True when [delta] holds something other than the newline Quill requires.
bool _carriesContent(Delta delta) {
  for (final op in delta.toList()) {
    if (!op.isInsert) continue;
    final data = op.data;
    if (data is! String) return true;
    if (data.trim().isNotEmpty) return true;
  }
  return false;
}

/// Word and Google Docs put a stylesheet on the clipboard along with the
/// prose, so rich HTML is routinely tens of kilobytes. Past this it is not a
/// paste anyone meant to make.
const _maxHtmlBytes = 2 * 1024 * 1024;

const _maxMarkdownScan = 100 * 1024;

final _heading = RegExp(r'^ {0,3}#{1,6}\s+\S');
final _blockQuote = RegExp(r'^ {0,3}>\s');
final _fence = RegExp(r'^ {0,3}(```|~~~)');
final _bullet = RegExp(r'^ {0,3}[-*+]\s+\S');
final _ordered = RegExp(r'^ {0,3}\d{1,9}[.)]\s+\S');

final _inlineMarkers = <RegExp>[
  RegExp(r'\*\*[^*\n]+\*\*'),
  RegExp(r'!\[[^\]\n]*\]\([^)\s]+\)'),
  RegExp(r'(?<!!)\[[^\]\n]+\]\((?:https?:|/|#)[^)\s]*\)'),
];
