import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart' show TextSelection;
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:puntland/console/core/admin_api/dto/media_dto.dart';
import 'package:puntland/console/core/admin_api/fixture_admin_api.dart';
import 'package:puntland/console/features/articles/presentation/rich_text/article_embeds.dart';
import 'package:puntland/console/features/articles/presentation/rich_text/article_html.dart';
import 'package:puntland/console/features/articles/presentation/rich_text/article_paste_handler.dart';

/// What a paste does to a live document, and what it must not do to one that
/// has moved on underneath it.
///
/// An image upload is a round trip, and in that time the journalist can type,
/// move the caret, switch language or close the editor. Every case here is one
/// of those: without the guards, an unguarded insert lands in the middle of a
/// word, throws after the controller is disposed, or saves a placeholder into
/// a story readers can open.
void main() {
  late FixtureAdminApi api;
  late List<ArticlePasteOutcome> outcomes;

  setUp(() {
    api = FixtureAdminApi(latency: Duration.zero);
    outcomes = [];
  });

  /// A handler over a document holding [bodyHtml], with the caret at [offset].
  (ArticlePasteHandler, QuillController) open({
    String bodyHtml = '',
    int offset = 0,
  }) {
    final handler = ArticlePasteHandler(api: api, onOutcome: outcomes.add);
    final controller = QuillController(
      document: articleHtmlToDocument(bodyHtml),
      selection: TextSelection.collapsed(offset: offset),
    );
    handler.attach(controller);
    addTearDown(controller.dispose);
    return (handler, controller);
  }

  group('markdown', () {
    test('becomes formatting, and says it guessed', () async {
      final (handler, controller) = open();

      expect(
        await handler.handle(plainText: '## Digniin\n\n- Kow\n- Labo\n'),
        isTrue,
      );

      final ops = controller.document
          .toDelta()
          .toJson()
          .cast<Map<String, dynamic>>();
      expect(
        ops,
        contains(
          equals({
            'insert': '\n',
            'attributes': {'header': 2},
          }),
        ),
      );
      expect(
        ops.where((op) => op['attributes']?['list'] == 'bullet'),
        hasLength(2),
      );
      expect(
        outcomes.single.result,
        ArticlePasteResult.reformatted,
        reason:
            'the one place this editor guesses is the one place it has to '
            'offer a way back',
      );
    });

    test('pasting mid-paragraph does not leave a blank line behind', () async {
      final (handler, controller) = open(
        bodyHtml: '<p>Roobab .</p>',
        offset: 7,
      );

      await handler.handle(plainText: '**culus** iyo [xoog](https://pltv.so)');

      expect(controller.document.toPlainText(), 'Roobab culus iyo xoog.\n');
    });

    test('is its own undo step', () async {
      final (handler, controller) = open(bodyHtml: '<p>Roobab</p>', offset: 6);
      // The keystroke a fast paste would otherwise be merged with.
      controller.replaceText(
        6,
        0,
        '!',
        const TextSelection.collapsed(offset: 7),
      );

      await handler.handle(plainText: '# Digniin\n');
      controller.undo();

      expect(controller.document.toPlainText(), 'Roobab!\n');
    });
  });

  group('prose', () {
    test('is declined, so the ordinary paste runs', () async {
      final (handler, controller) = open();

      expect(
        await handler.handle(plainText: 'Roobab culus ayaa da\'ay Nugaal.'),
        isFalse,
      );
      expect(controller.document.toPlainText().trim(), isEmpty);
      expect(outcomes, isEmpty);
    });

    test(
      'but is inserted when the caller already cancelled the default',
      () async {
        // The web listener has to call `preventDefault` before it knows what is
        // on the clipboard, so a declined paste still has to happen.
        final (handler, controller) = open();

        await handler.handleExclusively(plainText: 'Roobab culus.');

        expect(controller.document.toPlainText(), 'Roobab culus.\n');
      },
    );
  });

  group('read-only', () {
    test('takes nothing', () async {
      final (handler, controller) = open();
      controller.readOnly = true;

      expect(await handler.handle(plainText: '# Digniin\n'), isFalse);
      expect(controller.document.toPlainText().trim(), isEmpty);
    });
  });

  group('image', () {
    test('uploads and lands as an embed the library owns', () async {
      final (handler, controller) = open();

      await handler.handle(imageBytes: _png);

      expect(_embeds(controller), hasLength(1));
      expect(
        _embeds(controller).single,
        isNot(contains(PendingImageEmbed.embedType)),
      );
      expect(outcomes.single.result, ArticlePasteResult.imageAdded);

      final asset = await api.fetchMediaAsset(outcomes.single.assetId!);
      expect(asset.kind, MediaKind.image);
      expect(
        asset.blocksPublishing,
        isTrue,
        reason: 'a pasted image is as undescribed as an uploaded one',
      );
    });

    test('bytes that are not an image are refused before any upload', () async {
      final (handler, controller) = open();

      await handler.handle(imageBytes: Uint8List.fromList([1, 2, 3, 4]));

      expect(outcomes.single.result, ArticlePasteResult.imageRejected);
      expect(controller.document.toPlainText().trim(), isEmpty);
      expect(
        await api.fetchMedia(),
        isNot(
          contains(
            isA<MediaAssetDto>().having((a) => a.byteSize, 'byteSize', 4),
          ),
        ),
      );
    });

    test('an image past the limit is refused before any upload', () async {
      final (handler, controller) = open();

      final huge = Uint8List(kMaxPastedImageBytes + 1)
        ..setRange(0, _png.length, _png);
      await handler.handle(imageBytes: huge);

      expect(outcomes.single.result, ArticlePasteResult.imageTooLarge);
      expect(controller.document.toPlainText().trim(), isEmpty);
    });

    test(
      'two quick pastes land in caret order, not completion order',
      () async {
        final slow = _SlowApi();
        final handler = ArticlePasteHandler(api: slow, onOutcome: outcomes.add);
        final controller = QuillController.basic();
        handler.attach(controller);
        addTearDown(controller.dispose);

        final first = handler.handle(imageBytes: _png);
        final second = handler.handle(imageBytes: _jpeg);

        // Finished out of order on purpose: the placeholders are what keep each
        // image in the spot it was pasted into.
        slow.finish(1, 'https://cdn.pltv.so/second.jpg');
        slow.finish(0, 'https://cdn.pltv.so/first.png');
        await Future.wait([first, second]);

        expect(_embeds(controller), [
          'https://cdn.pltv.so/first.png',
          'https://cdn.pltv.so/second.jpg',
        ]);
      },
    );
  });

  group('the gap between pasting and uploading', () {
    test('a failed upload leaves the document exactly as it was', () async {
      final failing = _FailingApi();
      final handler = ArticlePasteHandler(
        api: failing,
        onOutcome: outcomes.add,
      );
      final controller = QuillController(
        document: articleHtmlToDocument('<p>Roobab culus.</p>'),
        selection: const TextSelection.collapsed(offset: 6),
      );
      handler.attach(controller);
      addTearDown(controller.dispose);

      final before = documentToArticleHtml(controller.document);
      await handler.handle(imageBytes: _png);

      expect(documentToArticleHtml(controller.document), before);
      expect(_embeds(controller), isEmpty);
      expect(outcomes.single.result, ArticlePasteResult.uploadFailed);
    });

    test('the editor closing mid-upload throws nothing', () async {
      final slow = _SlowApi();
      final handler = ArticlePasteHandler(api: slow, onOutcome: outcomes.add);
      final controller = QuillController.basic();
      handler.attach(controller);

      final paste = handler.handle(imageBytes: _png);

      // What `ArticleDraft.dispose` does, in the order it does it.
      handler.detach();
      controller.dispose();

      slow.finish(0, 'https://cdn.pltv.so/late.png');
      await expectLater(paste, completes);
      expect(outcomes, isEmpty);
    });

    test('a placeholder deleted by hand is not put back', () async {
      final slow = _SlowApi();
      final handler = ArticlePasteHandler(api: slow, onOutcome: outcomes.add);
      final controller = QuillController.basic();
      handler.attach(controller);
      addTearDown(controller.dispose);

      final paste = handler.handle(imageBytes: _png);
      expect(_pendingCount(controller), 1);

      // The journalist changed their mind while it was uploading.
      controller.undo();
      expect(_pendingCount(controller), 0);

      slow.finish(0, 'https://cdn.pltv.so/unwanted.png');
      await paste;

      expect(_embeds(controller), isEmpty);
      expect(outcomes, isEmpty);
    });

    test('reports itself as uploading, so autosave can wait', () async {
      final slow = _SlowApi();
      final handler = ArticlePasteHandler(api: slow, onOutcome: outcomes.add);
      final controller = QuillController.basic();
      handler.attach(controller);
      addTearDown(controller.dispose);

      expect(handler.isUploading, isFalse);
      final paste = handler.handle(imageBytes: _png);
      expect(handler.isUploading, isTrue);

      slow.finish(0, 'https://cdn.pltv.so/done.png');
      await paste;
      expect(handler.isUploading, isFalse);
    });
  });
}

/// Image URLs in the body, in document order.
List<String> _embeds(QuillController controller) => controller.document
    .toDelta()
    .toList()
    .where((op) => op.data is Map)
    .map((op) => (op.data as Map)[BlockEmbed.imageType])
    .whereType<String>()
    .toList();

int _pendingCount(QuillController controller) => controller.document
    .toDelta()
    .toList()
    .where(
      (op) =>
          op.data is Map &&
          (op.data as Map).containsKey(PendingImageEmbed.embedType),
    )
    .length;

/// An upload that never returns until the test says so.
class _SlowApi extends FixtureAdminApi {
  _SlowApi() : super(latency: Duration.zero);

  final _pending = <Completer<String>>[];

  void finish(int index, String url) => _pending[index].complete(url);

  @override
  Future<MediaAssetDto> uploadMedia({
    required String filename,
    required MediaKind kind,
    required int byteSize,
    Uint8List? bytes,
  }) async {
    final completer = Completer<String>();
    _pending.add(completer);
    final url = await completer.future;
    return MediaAssetDto(
      id: 'm-${_pending.indexOf(completer)}',
      kind: kind,
      filename: filename,
      url: url,
      byteSize: byteSize,
      uploadedAt: DateTime(2026),
      uploadedBy: 'A. Yuusuf',
    );
  }
}

class _FailingApi extends FixtureAdminApi {
  _FailingApi() : super(latency: Duration.zero);

  @override
  Future<MediaAssetDto> uploadMedia({
    required String filename,
    required MediaKind kind,
    required int byteSize,
    Uint8List? bytes,
  }) async => throw StateError('the network is not there');
}

/// A real 1×1 PNG and JPEG, so the format sniffer has something to read.
final _png = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  ),
);

final _jpeg = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A]);
