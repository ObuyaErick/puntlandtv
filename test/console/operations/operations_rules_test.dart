import 'package:flutter_test/flutter_test.dart';
import 'package:puntland/console/core/admin_api/dto/broadcast_dto.dart';
import 'package:puntland/console/core/admin_api/fixture_admin_api.dart';
import 'package:puntland/console/core/admin_api/dto/push_dto.dart';
import 'package:puntland/console/core/admin_api/dto/schedule_dto.dart';

/// The four operations rules that protect the audience from a mistake made in
/// this console.
void main() {
  group('push must be bilingual', () {
    const somali = PushMessageDto(
      title: 'Warar deg deg: dayactirka wadada weyn oo dhammaaday',
      body: 'Taabo si aad u akhrido warbixinta buuxda.',
    );
    const english = PushMessageDto(
      title: 'Breaking: main highway repairs completed',
      body: 'Tap to read the full report.',
    );

    test('a Somali-only alert cannot be sent', () {
      const draft = PushDraftDto(messages: {'so': somali});

      expect(draft.canSend, isFalse);
      expect(
        draft.incompleteLocales,
        ['en'],
        reason:
            'a push payload is written before it leaves the server and '
            'cannot be translated on the device',
      );
    });

    test('a title without a body does not count as complete', () {
      const draft = PushDraftDto(
        messages: {
          'so': somali,
          'en': PushMessageDto(title: 'Breaking: repairs completed'),
        },
      );

      expect(draft.canSend, isFalse);
      expect(draft.incompleteLocales, ['en']);
    });

    test('whitespace is not content', () {
      const draft = PushDraftDto(
        messages: {
          'so': somali,
          'en': PushMessageDto(title: '   ', body: '\n'),
        },
      );

      expect(draft.canSend, isFalse);
    });

    test('both locales complete unlocks sending', () {
      const draft = PushDraftDto(messages: {'so': somali, 'en': english});

      expect(draft.canSend, isTrue);
      expect(draft.incompleteLocales, isEmpty);
    });

    test('warns where Android truncates, without blocking', () {
      const long = PushMessageDto(
        title:
            'Warar deg deg oo ku saabsan dayactirka wadada weyn ee isku '
            'xirta magaalooyinka waaweyn ee gobolka',
        body: 'x',
      );

      expect(long.titleWillTruncate, isTrue);
      expect(
        long.isComplete,
        isTrue,
        reason: 'truncation is a warning — a long title still sends',
      );
      expect(somali.titleWillTruncate, isFalse);
    });

    // The UI blocks this too, but a boundary that trusts the UI to have
    // checked is not a boundary. Asserted here as a plain unit test: an async
    // `throwsA` inside a widget test never resolves under the fake clock.
    test('the API refuses an incomplete draft', () async {
      final api = FixtureAdminApi(latency: Duration.zero);

      await expectLater(
        api.sendPush(const PushDraftDto(messages: {'so': somali})),
        throwsA(
          isA<Object>().having(
            (e) => e.toString(),
            'code',
            contains('PUSH_INCOMPLETE_LOCALES'),
          ),
        ),
      );
    });

    test('the API accepts a complete draft', () async {
      final api = FixtureAdminApi(latency: Duration.zero);

      final entry = await api.sendPush(
        const PushDraftDto(messages: {'so': somali, 'en': english}),
      );

      expect(entry.title, somali.title);
      expect(entry.delivered, entry.targeted);
    });

    test('reach splits by language preference', () {
      const reach = PushReachDto(byLocale: {'so': 26411, 'en': 12491});

      expect(reach.total, 38902);
      expect(reach.forLocale('so'), 26411);
      expect(reach.forLocale('ar'), 0);
    });
  });

  group('schedule gap and overlap detection', () {
    final day = DateTime(2026, 8, 30);

    ScheduleSlotDto slot(String id, int hour, int minute, int minutes) =>
        ScheduleSlotDto(
          id: id,
          title: id,
          startsAt: DateTime(day.year, day.month, day.day, hour, minute),
          duration: Duration(minutes: minutes),
        );

    test('a clean day has no issues', () {
      final schedule = DayScheduleDto(
        day: day,
        slots: [slot('a', 18, 0, 60), slot('b', 19, 0, 60)],
      );

      expect(schedule.issues, isEmpty);
      expect(schedule.isPublishable, isTrue);
    });

    test('finds a gap and measures it', () {
      final schedule = DayScheduleDto(
        day: day,
        slots: [slot('a', 18, 0, 30), slot('b', 19, 0, 60)],
      );

      expect(schedule.gaps, hasLength(1));
      expect(schedule.gaps.single.length, const Duration(minutes: 30));
      expect(schedule.gaps.single.slotIds, ['a', 'b']);
    });

    test('finds an overlap and measures the collision', () {
      final schedule = DayScheduleDto(
        day: day,
        slots: [slot('a', 22, 0, 60), slot('b', 22, 30, 30)],
      );

      expect(schedule.overlaps, hasLength(1));
      expect(schedule.overlaps.single.length, const Duration(minutes: 30));
      expect(
        schedule.isPublishable,
        isFalse,
        reason: 'an overlap means something gets cut and nobody chose what',
      );
    });

    test('detects issues regardless of the order slots arrive in', () {
      final schedule = DayScheduleDto(
        day: day,
        slots: [slot('late', 22, 30, 30), slot('early', 22, 0, 60)],
      );

      expect(schedule.overlaps, hasLength(1));
    });

    test('resolving an overlap moves the later start, never shortens', () {
      final schedule = DayScheduleDto(
        day: day,
        slots: [slot('a', 22, 0, 60), slot('b', 22, 30, 30)],
      );

      final resolved = schedule.resolveOverlaps();

      expect(resolved.overlaps, isEmpty);
      expect(resolved.ordered.last.startsAt.hour, 23);
      expect(
        resolved.programmedTime,
        schedule.programmedTime,
        reason:
            'a tool that silently truncates content is one nobody trusts '
            'twice',
      );
    });
  });

  group('broadcast control', () {
    BroadcastControlDto control({
      Map<String, SlateMessageDto> slate = const {},
    }) => BroadcastControlDto(
      tvOnAir: true,
      radioOnAir: true,
      channelName: 'Puntland TV — main',
      uptime: const Duration(hours: 2, minutes: 4),
      concurrentViewers: 4182,
      radioListeners: 1904,
      renditions: const [
        RenditionConfigDto(
          rung: '1080p',
          url: 'https://cdn.pltv.so/live/1080/index.m3u8',
          bitrateKbps: 4500,
          healthy: true,
          enabled: true,
        ),
        RenditionConfigDto(
          rung: '240p',
          url: 'https://cdn.pltv.so/live/240/index.m3u8',
          bitrateKbps: 420,
          healthy: true,
          enabled: true,
        ),
      ],
      slate: slate,
    );

    test('cannot go off air without a slate in both languages', () {
      final onlySomali = control(
        slate: const {
          'so': SlateMessageDto(
            title: 'Baahinta ma socoto hadda',
            detail: 'Waxaan dib u bilaabeynaa 18:00',
          ),
        },
      );

      expect(onlySomali.canGoOffAir, isFalse);
      expect(onlySomali.incompleteSlateLocales, ['en']);
    });

    test('a complete slate in both languages unlocks the toggle', () {
      final both = control(
        slate: const {
          'so': SlateMessageDto(title: 'A', detail: 'B'),
          'en': SlateMessageDto(title: 'C', detail: 'D'),
        },
      );

      expect(both.canGoOffAir, isTrue);
    });

    test('the 240p rung cannot be disabled', () {
      final after = control().setRenditionEnabled('240p', enabled: false);

      expect(
        after.renditions.firstWhere((r) => r.rung == '240p').enabled,
        isTrue,
        reason:
            'disabling it does not break the stream — it silently makes '
            'it unwatchable for everyone on a slow connection',
      );
    });

    test('other rungs can be disabled and re-enabled', () {
      final off = control().setRenditionEnabled('1080p', enabled: false);
      expect(off.renditions.first.enabled, isFalse);

      final on = off.setRenditionEnabled('1080p', enabled: true);
      expect(on.renditions.first.enabled, isTrue);
    });
  });

  group('categories', () {
    const category = CategoryConfigDto(
      slug: 'education',
      names: {'so': 'Waxbarasho'},
      articleCount: 17,
      order: 5,
    );

    test('an untranslated category is hidden from that locale', () {
      expect(category.isVisibleIn('so'), isTrue);
      expect(
        category.isVisibleIn('en'),
        isFalse,
        reason:
            'a Somali name in an English tab bar reads as a bug to the '
            'reader and an oversight to the newsroom',
      );
      expect(category.untranslatedLocales, ['en']);
    });

    test('the slug survives a rename', () {
      final renamed = category.copyWith(
        names: {'so': 'Waxbarashada', 'en': 'Education'},
      );

      expect(renamed.slug, 'education');
      expect(renamed.untranslatedLocales, isEmpty);
    });
  });
}
