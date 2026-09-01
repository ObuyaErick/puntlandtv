import 'package:flutter_test/flutter_test.dart';
import 'package:puntland/console/core/admin_api/dto/admin_program_dto.dart';
import 'package:puntland/console/core/admin_api/dto/media_dto.dart';
import 'package:puntland/console/core/admin_api/fixture_admin_api.dart';
import 'package:puntland/core/error/failure.dart';

MediaAssetDto _video({
  String id = 'm-v',
  MediaProcessingState processing = MediaProcessingState.ready,
}) => MediaAssetDto(
  id: id,
  kind: MediaKind.video,
  filename: '$id.mp4',
  url: 'https://cdn.pltv.so/media/$id.m3u8',
  byteSize: 1024,
  uploadedAt: DateTime(2026, 8, 30),
  uploadedBy: 'M. Cali',
  processing: processing,
);

AdminEpisodeDto _episode({
  Map<String, String> titles = const {'so': 'Qayb', 'en': 'Episode'},
  MediaAssetDto? source,
  EpisodeStatus status = EpisodeStatus.draft,
}) => AdminEpisodeDto(
  id: 'ep-1',
  programId: 'p-1',
  titles: titles,
  number: 1,
  status: status,
  duration: const Duration(minutes: 30),
  source: source,
);

void main() {
  group('an untitled locale hides a programme from that shelf', () {
    test('a programme titled in both languages is on both shelves', () {
      final program = AdminProgramDto(
        id: 'p',
        titles: const {'so': 'Dood Furan', 'en': 'Open Debate'},
        cadence: ProgramCadence.weekly,
        genre: ProgramGenre.debate,
        episodeCount: 3,
        updatedAt: DateTime(2026, 8, 30),
        isPublished: true,
      );

      expect(program.untitledLocales, isEmpty);
      expect(program.isVisibleIn('so'), isTrue);
      expect(program.isVisibleIn('en'), isTrue);
      expect(program.isPartiallyVisible, isFalse);
    });

    test('a Somali-only title hides it from the English shelf', () {
      final program = AdminProgramDto(
        id: 'p',
        titles: const {'so': 'Barnaamijka Caruurta'},
        cadence: ProgramCadence.weekly,
        genre: ProgramGenre.kids,
        episodeCount: 9,
        updatedAt: DateTime(2026, 8, 30),
        isPublished: true,
      );

      expect(program.untitledLocales, ['en']);
      expect(program.isVisibleIn('so'), isTrue);
      expect(
        program.isVisibleIn('en'),
        isFalse,
        reason: 'it is hidden from that shelf, not shown in the other language',
      );
      expect(program.isPartiallyVisible, isTrue);
    });

    test('an unpublished programme is on no shelf at all', () {
      final program = AdminProgramDto(
        id: 'p',
        titles: const {'so': 'Ciyaaraha'},
        cadence: ProgramCadence.weekly,
        genre: ProgramGenre.sport,
        episodeCount: 0,
        updatedAt: DateTime(2026, 8, 30),
      );

      expect(
        program.isPartiallyVisible,
        isFalse,
        reason:
            'a draft nobody has finished is not the state that needs '
            'attention; calling it "hidden" is noise',
      );
    });

    test('the display title falls back rather than showing the slug', () {
      final program = AdminProgramDto(
        id: 'barnaamijka-caruurta',
        titles: const {'so': 'Barnaamijka Caruurta'},
        cadence: ProgramCadence.weekly,
        genre: ProgramGenre.kids,
        episodeCount: 9,
        updatedAt: DateTime(2026, 8, 30),
      );

      expect(program.titleFor('en'), 'Barnaamijka Caruurta');
      expect(program.untitledLocales, ['en']);
    });
  });

  group('an episode cannot publish on a source that is not playable', () {
    test('a ready source and both titles clears every blocker', () {
      final episode = _episode(source: _video());

      expect(episode.blockers, isEmpty);
      expect(episode.canPublish, isTrue);
    });

    test('no source attached is its own blocker', () {
      final episode = _episode();

      expect(episode.blockers, [EpisodeBlocker.noSource]);
      expect(episode.hasNoSource, isTrue);
      expect(episode.canPublish, isFalse);
    });

    test('a transcoding source blocks publishing', () {
      final episode = _episode(
        source: _video(processing: MediaProcessingState.processing),
      );

      expect(episode.blockers, [EpisodeBlocker.sourceProcessing]);
      expect(
        episode.canPublish,
        isFalse,
        reason: 'publishing at 62% ships a shelf entry that opens to an error',
      );
    });

    test(
      'a failed transcode blocks publishing, distinctly from an unfinished one',
      () {
        final episode = _episode(
          source: _video(processing: MediaProcessingState.failed),
        );

        expect(
          episode.blockers,
          [EpisodeBlocker.sourceFailed],
          reason:
              'a failure needs a retry and an unfinished ingest needs time — '
              'collapsing them sends whoever reads it to the wrong place',
        );
      },
    );

    test('a missing locale title blocks publishing', () {
      final episode = _episode(
        titles: const {'so': 'Dood ku saabsan waxbarashada'},
        source: _video(),
      );

      expect(episode.blockers, [EpisodeBlocker.untitled]);
      expect(episode.untitledLocales, ['en']);
    });

    test('blockers accumulate rather than reporting only the first', () {
      final episode = _episode(
        titles: const {'so': 'Dood'},
        source: _video(processing: MediaProcessingState.failed),
      );

      expect(episode.blockers, [
        EpisodeBlocker.sourceFailed,
        EpisodeBlocker.untitled,
      ]);
    });

    test('the API refuses a blocked publish, not just the UI', () async {
      final api = FixtureAdminApi(latency: Duration.zero);

      await expectLater(
        api.setEpisodeStatus(id: 'ep-df-18', status: EpisodeStatus.published),
        throwsA(
          isA<Failure>().having(
            (f) => f.code,
            'code',
            ProgramFailureCode.episodeBlocked,
          ),
        ),
      );
    });

    test('an unblocked episode publishes', () async {
      final api = FixtureAdminApi(latency: Duration.zero);

      final published = await api.setEpisodeStatus(
        id: 'ep-sd-24',
        status: EpisodeStatus.published,
      );

      expect(published.status, EpisodeStatus.published);
      expect(published.airedAt, isNotNull);
    });
  });

  group('an episode source is the media library asset', () {
    test('the seeded episodes point at the seeded media assets', () async {
      final api = FixtureAdminApi(latency: Duration.zero);
      final episodes = await api.fetchEpisodes('dood-furan');

      final failed = episodes.firstWhere((e) => e.number == 17);
      final processing = episodes.firstWhere((e) => e.number == 18);

      expect(failed.source?.id, 'm-dood-17');
      expect(processing.source?.id, 'm-dood-18');
    });

    test(
      'retrying the transcode in the library changes what the episode says',
      () async {
        final api = FixtureAdminApi(latency: Duration.zero);

        final before = (await api.fetchEpisodes('dood-furan'))
            .firstWhere((e) => e.number == 17);
        expect(before.blockers, contains(EpisodeBlocker.sourceFailed));

        await api.retryMediaIngest('m-dood-17');

        final after = (await api.fetchEpisodes('dood-furan'))
            .firstWhere((e) => e.number == 17);
        expect(
          after.blockers,
          contains(EpisodeBlocker.sourceProcessing),
          reason:
              'one asset, one truth about whether it is ready — the episode '
              'must not hold a stale copy',
        );
        expect(after.blockers, isNot(contains(EpisodeBlocker.sourceFailed)));
      },
    );

    test('a save cannot forge the source the pipeline owns', () async {
      final api = FixtureAdminApi(latency: Duration.zero);
      final stored = (await api.fetchEpisodes('dood-furan'))
          .firstWhere((e) => e.number == 18);

      final forged = AdminEpisodeDto(
        id: stored.id,
        programId: stored.programId,
        titles: const {'so': 'Cusub', 'en': 'New'},
        number: stored.number,
        status: stored.status,
        duration: stored.duration,
        source: _video(),
      );

      final saved = await api.saveEpisode(forged);

      expect(saved.titles['en'], 'New');
      expect(
        saved.source?.id,
        'm-dood-18',
        reason: 'the form may edit titles, never the ingest state',
      );
      expect(saved.canPublish, isFalse);
    });
  });

  test('episodes come back newest first', () async {
    final api = FixtureAdminApi(latency: Duration.zero);
    final episodes = await api.fetchEpisodes('dood-furan');

    expect(episodes.map((e) => e.number), [18, 17, 16]);
  });

  test('a programme round-trips through JSON', () {
    final program = AdminProgramDto(
      id: 'dood-furan',
      titles: const {'so': 'Dood Furan', 'en': 'Open Debate'},
      cadence: ProgramCadence.weekly,
      genre: ProgramGenre.debate,
      episodeCount: 18,
      updatedAt: DateTime(2026, 8, 30, 12),
      isPublished: true,
    );

    final restored = AdminProgramDto.fromJson(program.toJson());

    expect(restored.titles, program.titles);
    expect(restored.cadence, ProgramCadence.weekly);
    expect(restored.genre, ProgramGenre.debate);
    expect(restored.isPublished, isTrue);
  });

  test('an episode round-trips through JSON, source and all', () {
    final episode = _episode(
      source: _video(processing: MediaProcessingState.processing),
    );

    final restored = AdminEpisodeDto.fromJson(episode.toJson());

    expect(restored.source?.processing, MediaProcessingState.processing);
    expect(restored.blockers, [EpisodeBlocker.sourceProcessing]);
  });
}
