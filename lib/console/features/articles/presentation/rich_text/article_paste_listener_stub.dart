import 'article_paste.dart';

/// Does nothing off the web, where flutter_quill's own paste hook fires.
///
/// See `article_paste_listener.dart` for why the web needs its own route.
class ArticlePasteListener {
  ArticlePasteListener({required this.isFocused, required this.onPaste});

  final bool Function() isFocused;
  final ArticlePasteSink onPaste;

  void attach() {}

  void detach() {}
}
