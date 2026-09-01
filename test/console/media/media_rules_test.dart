import 'package:flutter_test/flutter_test.dart';
import 'package:puntland/console/core/admin_api/dto/media_dto.dart';
import 'package:puntland/console/core/admin_api/fixture_admin_api.dart';
import 'package:puntland/core/error/failure.dart';

MediaAssetDto _image({
  String id = 'm-test',
  String? so,
  String? en,
  List<MediaUsageDto> usedIn = const [],
}) => MediaAssetDto(
  id: id,
  kind: MediaKind.image,
  filename: 'test.jpg',
  url: 'https://cdn.pltv.so/media/$id.jpg',
  byteSize: 1024 * 1024,
  uploadedAt: DateTime(2026, 8, 30, 21),
  uploadedBy: 'A. Yuusuf',
  alt: {'so': ?so, 'en': ?en},
  usedIn: usedIn,
);

/// The three rules the media library carries that no other screen can.
void main() {
  group('alt text is required in every locale, not once', () {
    test('an undescribed image is missing both languages', () {
      final asset = _image();

      expect(asset.missingAltLocales, ['so', 'en']);
      expect(asset.blocksPublishing, isTrue);
    });

    test('a Somali-only description does not satisfy the rule', () {
      final asset = _image(so: 'Ardayda dugsiga sare oo fasalka gudaha ah');

      expect(
        asset.missingAltLocales,
        ['en'],
        reason:
            'an image described only in Somali reaches an English reader as '
            'Somali or as nothing — the editor gate sees an alt string and '
            'lets it publish',
      );
      expect(asset.blocksPublishing, isTrue);
    });

    test('whitespace is not a description', () {
      final asset = _image(so: 'Wadada weyn', en: '   \n ');

      expect(asset.missingAltLocales, ['en']);
    });

    test('both languages complete clears the block', () {
      final asset = _image(
        so: 'Wadada weyn ee Boosaaso',
        en: 'The Bosaso highway',
      );

      expect(asset.missingAltLocales, isEmpty);
      expect(asset.blocksPublishing, isFalse);
    });

    test('clearing a field removes the key rather than storing an empty', () {
      final asset = _image(
        so: 'Wadada weyn',
        en: 'The highway',
      ).withAlt('en', '');

      expect(asset.alt.containsKey('en'), isFalse);
      expect(asset.missingAltLocales, ['en']);
    });

    test('video and audio are never blocked on alt text', () {
      final video = MediaAssetDto(
        id: 'm-v',
        kind: MediaKind.video,
        filename: 'ep.mp4',
        url: 'https://cdn.pltv.so/media/m-v.m3u8',
        byteSize: 1024,
        uploadedAt: DateTime(2026, 8, 30),
        uploadedBy: 'M. Cali',
      );

      expect(
        video.missingAltLocales,
        isEmpty,
        reason:
            'alt text describes a still image; the equivalent for video is a '
            'caption track, which is a different rule at a different point',
      );
      expect(video.blocksPublishing, isFalse);
    });

    test('a fallback description is shown but does not clear the gap', () {
      final asset = _image(so: 'Wadada weyn');

      expect(asset.altFor('en'), 'Wadada weyn');
      expect(
        asset.missingAltLocales,
        ['en'],
        reason:
            'a fallback is better than an empty announcement, but it is not '
            'the translation',
      );
    });
  });

  group('an asset in use cannot be deleted', () {
    test('an unused asset can be deleted', () {
      expect(_image().canDelete, isTrue);
    });

    test('one article pointing at it is enough to block deletion', () {
      final asset = _image(
        usedIn: const [
          MediaUsageDto(
            articleId: 'a-road',
            title: 'Wadada',
            isPublished: false,
          ),
        ],
      );

      expect(asset.canDelete, isFalse);
      expect(asset.usageCount, 1);
      expect(asset.publishedUsageCount, 0);
    });

    test('published uses are counted separately', () {
      final asset = _image(
        usedIn: const [
          MediaUsageDto(articleId: 'a-1', title: 'One', isPublished: true),
          MediaUsageDto(articleId: 'a-2', title: 'Two', isPublished: false),
        ],
      );

      expect(asset.usageCount, 2);
      expect(
        asset.publishedUsageCount,
        1,
        reason:
            'deleting behind a published use breaks a page a reader can '
            'already open',
      );
    });

    test('the API refuses the delete, not just the UI', () async {
      final api = FixtureAdminApi(latency: Duration.zero);

      // Seeded in use by the published schools article.
      await expectLater(
        api.deleteMediaAsset('m-school'),
        throwsA(
          isA<Failure>().having((f) => f.code, 'code', MediaFailureCode.inUse),
        ),
      );

      expect(await api.fetchMediaAsset('m-school'), isNotNull);
    });

    test('an unused asset really is removed', () async {
      final api = FixtureAdminApi(latency: Duration.zero);

      await api.deleteMediaAsset('m-livestock');

      final ids = (await api.fetchMedia()).map((a) => a.id);
      expect(ids, isNot(contains('m-livestock')));
    });
  });

  group('an asset that has not finished ingesting is not attachable', () {
    test('a transcoding video cannot be attached', () async {
      final api = FixtureAdminApi(latency: Duration.zero);
      final asset = await api.fetchMediaAsset('m-dood-18');

      expect(asset.processing, MediaProcessingState.processing);
      expect(asset.canAttach, isFalse);
    });

    test('a failed ingest cannot be attached and says why', () async {
      final api = FixtureAdminApi(latency: Duration.zero);
      final asset = await api.fetchMediaAsset('m-dood-17');

      expect(asset.hasFailed, isTrue);
      expect(asset.canAttach, isFalse);
      expect(asset.failureReason, isNotNull);
    });

    test('a retry re-queues rather than reporting success', () async {
      final api = FixtureAdminApi(latency: Duration.zero);

      final retried = await api.retryMediaIngest('m-dood-17');

      expect(
        retried.processing,
        MediaProcessingState.processing,
        reason:
            'showing "ready" here would be the console lying about the '
            'pipeline',
      );
      expect(retried.transcodeProgress, 0);
    });
  });

  group('upload', () {
    test('an uploaded image lands undescribed', () async {
      final api = FixtureAdminApi(latency: Duration.zero);

      final asset = await api.uploadMedia(
        filename: 'sawir.jpg',
        kind: MediaKind.image,
        byteSize: 1024,
      );

      expect(asset.isReady, isTrue);
      expect(
        asset.blocksPublishing,
        isTrue,
        reason:
            'an undescribed image must not sit in the grid looking finished',
      );
    });

    test('an uploaded video lands mid-ingest', () async {
      final api = FixtureAdminApi(latency: Duration.zero);

      final asset = await api.uploadMedia(
        filename: 'barnaamij.mp4',
        kind: MediaKind.video,
        byteSize: 1024,
      );

      expect(asset.processing, MediaProcessingState.processing);
      expect(asset.canAttach, isFalse);
    });

    test('a save cannot forge the fields the pipeline owns', () async {
      final api = FixtureAdminApi(latency: Duration.zero);
      final stored = await api.fetchMediaAsset('m-school');

      // A forged usage list would turn the delete rule into a suggestion.
      final forged = MediaAssetDto(
        id: stored.id,
        kind: stored.kind,
        filename: stored.filename,
        url: stored.url,
        byteSize: 1,
        uploadedAt: stored.uploadedAt,
        uploadedBy: stored.uploadedBy,
        alt: const {'so': 'Ardayda', 'en': 'Students'},
      );

      final saved = await api.saveMediaAsset(forged);

      expect(saved.alt['en'], 'Students');
      expect(saved.byteSize, stored.byteSize);
      expect(saved.usedIn, hasLength(stored.usedIn.length));
      expect(saved.canDelete, isFalse);
    });
  });

  group('filters and counts', () {
    test('needsAlt narrows to images the rule blocks', () async {
      final api = FixtureAdminApi(latency: Duration.zero);

      final rows = await api.fetchMedia(filter: MediaKindFilter.needsAlt);

      expect(rows, isNotEmpty);
      expect(rows.every((a) => a.blocksPublishing), isTrue);
      expect(
        rows.map((a) => a.id),
        containsAll(['m-school', 'm-livestock']),
        reason: 'one described in Somali only, one not described at all',
      );
    });

    test('kind filters narrow to that kind', () async {
      final api = FixtureAdminApi(latency: Duration.zero);

      final videos = await api.fetchMedia(filter: MediaKindFilter.video);

      expect(videos, isNotEmpty);
      expect(videos.every((a) => a.kind == MediaKind.video), isTrue);
    });

    test('search matches filename, alt text, and credit', () async {
      final api = FixtureAdminApi(latency: Duration.zero);

      expect(await api.fetchMedia(query: 'dood-furan'), hasLength(2));
      expect(
        (await api.fetchMedia(query: 'Reuters')).single.id,
        'm-rain',
        reason: 'a credit is a thing people search by',
      );
      expect((await api.fetchMedia(query: 'Bosaso')).single.id, 'm-highway');
    });

    test('counts cover every chip from one pass', () async {
      final api = FixtureAdminApi(latency: Duration.zero);
      final counts = MediaCounts.from(await api.fetchMedia());

      expect(counts.all, counts.images + counts.videos + counts.audio);
      expect(counts.forFilter(MediaKindFilter.all), counts.all);
      expect(counts.needsAlt, greaterThan(0));
      expect(
        counts.needsAlt,
        lessThanOrEqualTo(counts.images),
        reason: 'only images can be missing alt text',
      );
    });
  });

  test('an asset round-trips through JSON', () {
    final asset = _image(
      so: 'Wadada weyn',
      en: 'The highway',
      usedIn: const [
        MediaUsageDto(articleId: 'a-1', title: 'One', isPublished: true),
      ],
    );

    final restored = MediaAssetDto.fromJson(asset.toJson());

    expect(restored.alt, asset.alt);
    expect(restored.missingAltLocales, isEmpty);
    expect(restored.usedIn.single.isPublished, isTrue);
    expect(restored.canDelete, isFalse);
  });
}
