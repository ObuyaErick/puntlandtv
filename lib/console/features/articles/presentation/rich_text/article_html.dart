/// The one place article body markup is converted, in either direction.
///
/// **`bodyHtml` is the stored form, and the editor's document is derived.**
/// The reader app renders the body with `flutter_widget_from_html_core` and the
/// backend column is HTML; a Delta stored alongside it would be a second
/// source of truth for the same prose, and the two would disagree the first
/// time anything but this editor touched a story. So the Delta lives for
/// exactly as long as the editor is open.
///
/// The cost of that choice is that every save is a round trip, and a round
/// trip is lossy in the direction of whatever the converters do not model.
/// [kArticleTags] is the answer: a small, closed vocabulary that survives the
/// trip unchanged, chosen from what the reader actually renders. Anything
/// outside it is not "unsupported" in some future sense — it is markup this
/// product has decided an article does not contain.
///
/// **Why the HTML→Delta direction is hand-written.** It was
/// `flutter_quill_delta_from_html` first. That package renders
/// `<p>One.</p><p>Two.</p>` as the single line `One.Two.` — it drops the
/// paragraph break, silently, on the one shape every article has. Its
/// `shouldInsertANewLine` hook restores the break and then leaves a trailing
/// empty paragraph behind, which the next save parses and re-emits, so a story
/// grows a blank line every time it is opened. Neither failure is visible in
/// the editor; both reach the reader. Against a vocabulary this small the
/// parser below is the cheaper thing to be sure of. The Delta→HTML direction
/// is still `vsc_quill_delta_to_html`, which is exact once told not to merge
/// paragraphs.
library;

import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

/// The markup an article body may contain.
///
/// Deliberately short, and deliberately missing `<h1>`: the headline is the
/// page's one first-level heading, and a body that declares another leaves a
/// screen-reader user with two documents in one. The toolbar offers H2 and H3
/// for the same reason.
const kArticleTags = <String>{
  'p',
  'strong',
  'em',
  'h2',
  'h3',
  'ul',
  'ol',
  'li',
  'a',
  'img',
  'blockquote',
  'br',
};

/// Parses stored [html] into a document the editor can open.
///
/// A null or blank body is a new story, not a failure — it opens as one empty
/// paragraph rather than as an editor with no line to type on.
Document articleHtmlToDocument(String? html) {
  final source = html?.trim() ?? '';
  if (source.isEmpty) return Document();

  try {
    return Document.fromDelta(articleHtmlToDelta(source));
  } catch (_) {
    // Markup this editor cannot parse must not cost the journalist their
    // story. Falling back to the text keeps every word and loses only the
    // formatting — recoverable by hand, which an empty editor is not.
    final text = _plainText(source);
    return Document()..insert(0, text.isEmpty ? '' : text);
  }
}

/// Serialises the editor's [document] to the stored form.
///
/// Returns an empty string for an empty document rather than the `<p><br></p>`
/// the converter emits for one. That string is not nothing: it is a body, and
/// it would defeat every "has this article been written yet" check between
/// here and the app.
String documentToArticleHtml(Document document) {
  if (isArticleDocumentEmpty(document)) return '';

  final html = QuillDeltaToHtmlConverter(
    document.toDelta().toJson().cast<Map<String, dynamic>>(),
    ConverterOptions(
      // One `<p>` per paragraph. The converter's default folds consecutive
      // paragraph lines into a single element, which reads as `…xilliga.Dadka
      // deggan…` — two sentences run together with no space, in published copy.
      multiLineParagraph: false,
      converterOptions: OpConverterOptions(
        // Semantic tags, not `<span style>`: the reader app styles the body
        // from its own theme, and inline styles authored in the console would
        // be a second, unthemed opinion that ignores dark mode.
        inlineStylesFlag: false,
        // No `target="_blank"`. The body is rendered inside the app, where
        // there is no second tab for a link to open in — the attribute would
        // be stored on every link forever to describe a browser nobody uses.
        linkTarget: '',
      ),
    ),
  ).convert();

  return html.trim();
}

/// True when [document] holds no prose.
///
/// Quill's empty document is a single newline, so `length` is 1 rather than 0
/// — the check every caller gets wrong once.
bool isArticleDocumentEmpty(Document document) =>
    document.toPlainText().trim().isEmpty;

/// Words in [html], for a body that is stored but not open in an editor.
int articleHtmlWordCount(String? html) => _countWords(_plainText(html ?? ''));

/// Words in an open [document].
int articleDocumentWordCount(Document document) =>
    _countWords(document.toPlainText());

/// Roughly 200 words a minute, floor of one — the same rate the reader app
/// shows, so the console never promises a different number than the story does.
int articleReadingMinutes(int words) => (words / 200).ceil().clamp(1, 99);

int _countWords(String text) =>
    text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

String _plainText(String html) =>
    _lines(html_parser.parseFragment(html).nodes).map((l) => l.text).join('\n');

// ---- HTML → Delta ----

/// Parses [html] into a Quill delta over [kArticleTags].
///
/// Exposed for the round-trip test, which is the only thing that should care
/// about the delta as such — everywhere else wants a [Document].
Delta articleHtmlToDelta(String html) {
  final delta = Delta();

  for (final line in _lines(html_parser.parseFragment(html).nodes)) {
    for (final run in line.runs) {
      delta.insert(run.data, run.attributes.isEmpty ? null : run.attributes);
    }
    // Quill carries a line's block style on the newline that *ends* it, not on
    // its text. A heading is a `\n` wearing `{header: 2}`.
    delta.insert('\n', line.block.isEmpty ? null : line.block);
  }

  // Quill asserts on a document that does not end in a newline, and an empty
  // one is a single newline rather than nothing at all.
  if (delta.isEmpty) delta.insert('\n');
  return delta;
}

/// One line of the document: its inline runs, plus the block style that ends it.
class _Line {
  _Line(this.block);

  final Map<String, dynamic> block;
  final List<_Run> runs = [];

  String get text => runs.map((r) => r.data is String ? r.data as String : '').join();

  bool get isBlank => runs.isEmpty;
}

class _Run {
  const _Run(this.data, this.attributes);

  /// A `String` for text, or `{'image': url}` for an embed.
  final Object data;
  final Map<String, dynamic> attributes;
}

/// Walks block-level [nodes] into lines.
List<_Line> _lines(List<dom.Node> nodes) {
  final lines = <_Line>[];
  _walkBlocks(nodes, const {}, lines);
  return lines;
}

void _walkBlocks(
  List<dom.Node> nodes,
  Map<String, dynamic> inherited,
  List<_Line> out,
) {
  for (final node in nodes) {
    if (node is dom.Text) {
      // Whitespace between block elements is formatting in the source file,
      // not content — `</p>\n  <p>` must not become a blank paragraph.
      final text = _collapse(node.text);
      if (text.trim().isEmpty) continue;
      out.add(_Line({...inherited})..runs.addAll(_inline([node], const {})));
      continue;
    }
    if (node is! dom.Element) continue;

    switch (node.localName) {
      case 'p':
        out.add(_line(node, inherited));
      case 'h2':
        out.add(_line(node, {...inherited, 'header': 2}));
      case 'h3':
        out.add(_line(node, {...inherited, 'header': 3}));
      case 'blockquote':
        // A blockquote may hold paragraphs or bare text. Recursing carries the
        // quote onto whatever lines are inside it, so both shapes land as
        // quoted lines rather than one of them silently losing the quote.
        _descend(node, {...inherited, 'blockquote': true}, out);
      case 'ul':
        _items(node, inherited, 'bullet', out);
      case 'ol':
        _items(node, inherited, 'ordered', out);
      case 'li':
        // Only reachable from malformed markup; treat as its own line.
        out.add(_line(node, inherited));
      case 'img':
        final src = node.attributes['src'];
        if (src != null && src.isNotEmpty) {
          out.add(_Line({...inherited})..runs.add(_Run({'image': src}, const {})));
        }
      case 'br':
        out.add(_Line({...inherited}));
      default:
        // An unknown tag is a container until proven otherwise: `<div>` and
        // `<section>` wrap paragraphs, and treating them as one line would
        // weld every paragraph inside them together.
        if (node.nodes.any(_isBlock)) {
          _walkBlocks(node.nodes, inherited, out);
        } else {
          out.add(_line(node, inherited));
        }
    }
  }
}

/// Recurses into [element], keeping [block] on every line it produces.
void _descend(
  dom.Element element,
  Map<String, dynamic> block,
  List<_Line> out,
) {
  if (element.nodes.any(_isBlock)) {
    _walkBlocks(element.nodes, block, out);
  } else {
    out.add(_line(element, block));
  }
}

void _items(
  dom.Element list,
  Map<String, dynamic> inherited,
  String kind,
  List<_Line> out,
) {
  for (final item in list.children.where((c) => c.localName == 'li')) {
    _descend(item, {...inherited, 'list': kind}, out);
  }
}

_Line _line(dom.Element element, Map<String, dynamic> block) =>
    _Line(block)..runs.addAll(_inline(element.nodes, const {}));

bool _isBlock(dom.Node node) =>
    node is dom.Element &&
    const {'p', 'h2', 'h3', 'ul', 'ol', 'li', 'blockquote', 'div'}
        .contains(node.localName);

/// Flattens inline [nodes] into styled runs.
List<_Run> _inline(List<dom.Node> nodes, Map<String, dynamic> attributes) {
  final runs = <_Run>[];

  for (final node in nodes) {
    if (node is dom.Text) {
      final text = _collapse(node.text);
      if (text.isEmpty) continue;
      runs.add(_Run(text, attributes));
      continue;
    }
    if (node is! dom.Element) continue;

    switch (node.localName) {
      case 'strong' || 'b':
        runs.addAll(_inline(node.nodes, {...attributes, 'bold': true}));
      case 'em' || 'i':
        runs.addAll(_inline(node.nodes, {...attributes, 'italic': true}));
      case 'a':
        final href = node.attributes['href'];
        runs.addAll(
          _inline(node.nodes, {
            ...attributes,
            if (href != null && href.isNotEmpty) 'link': href,
          }),
        );
      case 'img':
        final src = node.attributes['src'];
        if (src != null && src.isNotEmpty) {
          runs.add(_Run({'image': src}, const {}));
        }
      case 'br':
        runs.add(_Run('\n', const {}));
      default:
        runs.addAll(_inline(node.nodes, attributes));
    }
  }

  return runs;
}

/// HTML collapses runs of whitespace to one space; a body stored with newlines
/// for readability must not gain them back as content.
String _collapse(String text) => text.replaceAll(RegExp(r'\s+'), ' ');
