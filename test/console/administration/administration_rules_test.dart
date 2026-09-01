import 'package:flutter_test/flutter_test.dart';
import 'package:puntland/console/core/admin_api/dto/console_config_dto.dart';
import 'package:puntland/console/core/admin_api/dto/staff_dto.dart';
import 'package:puntland/console/core/admin_api/fixture_admin_api.dart';
import 'package:puntland/console/features/auth/domain/entities/console_user.dart';
import 'package:puntland/core/error/failure.dart';

StaffMemberDto _member({
  required String id,
  required ConsoleRole role,
  StaffStatus status = StaffStatus.active,
  bool twoFactor = true,
}) => StaffMemberDto(
  id: id,
  name: id,
  email: '$id@pltv.so',
  role: role,
  status: status,
  createdAt: DateTime(2026, 1, 1),
  twoFactorEnrolled: twoFactor,
);

void main() {
  group('you cannot revoke your own access', () {
    final directory = StaffDirectoryDto(
      members: [
        _member(id: 'me', role: ConsoleRole.admin),
        _member(id: 'other', role: ConsoleRole.admin),
      ],
    );

    test('demoting yourself out of admin is refused', () {
      expect(
        directory.refusalForRoleChange(
          id: 'me',
          role: ConsoleRole.editor,
          actingUserId: 'me',
        ),
        StaffRefusal.self,
      );
    });

    test('suspending yourself is refused', () {
      expect(
        directory.refusalForSuspension(id: 'me', actingUserId: 'me'),
        StaffRefusal.self,
      );
    });

    test('demoting a different admin is allowed while another remains', () {
      expect(
        directory.refusalForRoleChange(
          id: 'other',
          role: ConsoleRole.editor,
          actingUserId: 'me',
        ),
        isNull,
      );
    });

    test('being promoted is never refused, including your own account', () {
      final mixed = StaffDirectoryDto(
        members: [
          _member(id: 'me', role: ConsoleRole.editor),
          _member(id: 'admin', role: ConsoleRole.admin),
        ],
      );

      expect(
        mixed.refusalForRoleChange(
          id: 'me',
          role: ConsoleRole.admin,
          actingUserId: 'me',
        ),
        isNull,
        reason: 'gaining access cannot lock anyone out',
      );
    });

    test('a no-op role change is not refused', () {
      expect(
        directory.refusalForRoleChange(
          id: 'me',
          role: ConsoleRole.admin,
          actingUserId: 'me',
        ),
        isNull,
      );
    });
  });

  group('the last admin who can sign in is protected', () {
    final soleAdmin = StaffDirectoryDto(
      members: [
        _member(id: 'admin', role: ConsoleRole.admin),
        _member(id: 'editor', role: ConsoleRole.editor),
      ],
    );

    test('demoting the only admin is refused', () {
      expect(soleAdmin.isLastAdmin('admin'), isTrue);
      expect(
        soleAdmin.refusalForRoleChange(
          id: 'admin',
          role: ConsoleRole.editor,
          actingUserId: 'someone-else',
        ),
        StaffRefusal.lastAdmin,
      );
    });

    test('suspending the only admin is refused', () {
      expect(
        soleAdmin.refusalForSuspension(
          id: 'admin',
          actingUserId: 'someone-else',
        ),
        StaffRefusal.lastAdmin,
      );
    });

    test('an invited admin is not a way back in', () {
      final withInvite = StaffDirectoryDto(
        members: [
          _member(id: 'admin', role: ConsoleRole.admin),
          _member(
            id: 'pending',
            role: ConsoleRole.admin,
            status: StaffStatus.invited,
          ),
        ],
      );

      expect(
        withInvite.effectiveAdminCount,
        1,
        reason: 'an account that has never signed in cannot rescue anyone',
      );
      expect(withInvite.isLastAdmin('admin'), isTrue);
    });

    test('a suspended admin is not a way back in either', () {
      final withSuspended = StaffDirectoryDto(
        members: [
          _member(id: 'admin', role: ConsoleRole.admin),
          _member(
            id: 'former',
            role: ConsoleRole.admin,
            status: StaffStatus.suspended,
          ),
        ],
      );

      expect(withSuspended.effectiveAdminCount, 1);
      expect(withSuspended.isLastAdmin('admin'), isTrue);
    });

    test('two active admins make either one demotable', () {
      final two = StaffDirectoryDto(
        members: [
          _member(id: 'a', role: ConsoleRole.admin),
          _member(id: 'b', role: ConsoleRole.admin),
        ],
      );

      expect(two.isLastAdmin('a'), isFalse);
      expect(two.isLastAdmin('b'), isFalse);
    });

    test('reinstating is never refused', () {
      final directory = StaffDirectoryDto(
        members: [
          _member(
            id: 'former',
            role: ConsoleRole.editor,
            status: StaffStatus.suspended,
          ),
        ],
      );

      expect(directory.canReinstate('former'), isTrue);
    });

    test('the API refuses the last-admin demotion, not just the UI', () async {
      final api = FixtureAdminApi(latency: Duration.zero);

      // The seeded directory has one active admin and one invited one.
      final directory = await api.fetchStaffDirectory();
      expect(directory.effectiveAdminCount, 1);

      await expectLater(
        api.setStaffRole(id: 'u-admin', role: ConsoleRole.editor),
        throwsA(
          isA<Failure>().having(
            (f) => f.code,
            'code',
            StaffFailureCode.lastAdmin,
          ),
        ),
      );
    });

    test('the API refuses the last-admin suspension too', () async {
      final api = FixtureAdminApi(latency: Duration.zero);

      await expectLater(
        api.setStaffStatus(id: 'u-admin', status: StaffStatus.suspended),
        throwsA(
          isA<Failure>().having(
            (f) => f.code,
            'code',
            StaffFailureCode.lastAdmin,
          ),
        ),
      );
    });

    test('promoting a second admin unblocks the first demotion', () async {
      final api = FixtureAdminApi(latency: Duration.zero);

      await api.setStaffRole(id: 'u-editor', role: ConsoleRole.admin);
      final demoted = await api.setStaffRole(
        id: 'u-admin',
        role: ConsoleRole.editor,
      );

      expect(demoted.role, ConsoleRole.editor);
    });
  });

  group('capabilities come from the role, never the person', () {
    test('a member exposes its role capabilities unchanged', () {
      final member = _member(id: 'x', role: ConsoleRole.operations);

      expect(member.capabilities, ConsoleRole.operations.capabilities);
      expect(member.capabilities, contains(Capability.manageBroadcast));
      expect(
        member.capabilities,
        isNot(contains(Capability.publishArticles)),
        reason:
            'the absent capabilities are what answer "will this change take '
            'something away"',
      );
    });

    test(
      'a suspended admin still holds admin capabilities but cannot sign in',
      () {
        final member = _member(
          id: 'x',
          role: ConsoleRole.admin,
          status: StaffStatus.suspended,
        );

        expect(member.capabilities, ConsoleRole.admin.capabilities);
        expect(member.canSignIn, isFalse);
        expect(member.isEffectiveAdmin, isFalse);
      },
    );
  });

  group('a minimum build above the released one locks everyone out', () {
    ConsoleConfigDto config({
      required int floor,
      int released = 118,
    }) => ConsoleConfigDto(
      minimumSupportedBuild: floor,
      currentReleasedBuild: released,
      locales: const [
        LocaleOptionDto(code: 'so', enabled: true, articlesOnlyInThisLocale: 2),
        LocaleOptionDto(code: 'en', enabled: true, articlesOnlyInThisLocale: 0),
      ],
      flags: const [],
    );

    test('a floor below the release is safe', () {
      final value = config(floor: 104);

      expect(value.isFloorValid, isTrue);
      expect(value.locksEveryoneOut, isFalse);
      expect(value.floorOvershoot, 0);
      expect(value.canSave, isTrue);
    });

    test('a floor equal to the release is safe', () {
      expect(config(floor: 118).isFloorValid, isTrue);
    });

    test('one build above the release locks everyone out', () {
      final value = config(floor: 119);

      expect(
        value.locksEveryoneOut,
        isTrue,
        reason:
            'every reader is told to update with nothing to update to, and '
            'only a store release undoes it',
      );
      expect(value.floorOvershoot, 1);
      expect(value.canSave, isFalse);
    });

    test('the API refuses it, not just the UI', () async {
      final api = FixtureAdminApi(latency: Duration.zero);
      final stored = await api.fetchConsoleConfig();

      await expectLater(
        api.saveConsoleConfig(
          stored.copyWith(
            minimumSupportedBuild: stored.currentReleasedBuild + 1,
          ),
        ),
        throwsA(
          isA<Failure>().having(
            (f) => f.code,
            'code',
            ConfigFailureCode.floorAboveRelease,
          ),
        ),
      );
    });

    test('the released build is not the client\'s to move', () async {
      final api = FixtureAdminApi(latency: Duration.zero);
      final stored = await api.fetchConsoleConfig();

      final saved = await api.saveConsoleConfig(
        ConsoleConfigDto(
          minimumSupportedBuild: 110,
          currentReleasedBuild: 9999,
          locales: stored.locales,
          flags: stored.flags,
        ),
      );

      expect(saved.currentReleasedBuild, stored.currentReleasedBuild);
      expect(saved.minimumSupportedBuild, 110);
    });
  });

  group('disabling a language removes content, not labels', () {
    test('the stranded count is what the switch has to say', () async {
      final api = FixtureAdminApi(latency: Duration.zero);
      final config = await api.fetchConsoleConfig();

      // The article fixtures include published Somali-only stories.
      expect(config.articlesStrandedBy('so'), greaterThan(0));
      expect(config.locale('so')?.enabled, isTrue);
    });

    test('the last enabled language cannot be switched off', () async {
      final api = FixtureAdminApi(latency: Duration.zero);
      final config = await api.fetchConsoleConfig();

      final somaliOnly = config.withLocaleEnabled('en', false);

      expect(somaliOnly.canDisableLocale('en'), isFalse);
      expect(
        somaliOnly.canDisableLocale('so'),
        isFalse,
        reason: 'an app with no languages has no content in any of them',
      );
      expect(somaliOnly.enabledLocales, hasLength(1));
      expect(somaliOnly.canSave, isTrue);
    });

    test('a save with no languages is refused at the API', () async {
      final api = FixtureAdminApi(latency: Duration.zero);
      final config = await api.fetchConsoleConfig();

      final none = config
          .withLocaleEnabled('so', false)
          .withLocaleEnabled('en', false);

      expect(none.canSave, isFalse);
      await expectLater(
        api.saveConsoleConfig(none),
        throwsA(
          isA<Failure>().having(
            (f) => f.code,
            'code',
            ConfigFailureCode.noLocales,
          ),
        ),
      );
    });
  });

  group('feature flags', () {
    test('a flag toggles by key and leaves the others alone', () async {
      final api = FixtureAdminApi(latency: Duration.zero);
      final config = await api.fetchConsoleConfig();

      final flipped = config.withFlag('vod_downloads', true);

      expect(
        flipped.flags.firstWhere((f) => f.key == 'vod_downloads').enabled,
        isTrue,
      );
      expect(
        flipped.flags.firstWhere((f) => f.key == 'radio_tab').enabled,
        config.flags.firstWhere((f) => f.key == 'radio_tab').enabled,
      );
    });

    test('a save persists and stamps who changed it', () async {
      final api = FixtureAdminApi(latency: Duration.zero);
      final config = await api.fetchConsoleConfig();

      await api.saveConsoleConfig(config.withFlag('vod_downloads', true));
      final reread = await api.fetchConsoleConfig();

      expect(
        reread.flags.firstWhere((f) => f.key == 'vod_downloads').enabled,
        isTrue,
      );
      expect(reread.updatedBy, isNotNull);
    });
  });

  test('the config round-trips through JSON', () async {
    final api = FixtureAdminApi(latency: Duration.zero);
    final config = await api.fetchConsoleConfig();

    final restored = ConsoleConfigDto.fromJson(config.toJson());

    expect(restored.minimumSupportedBuild, config.minimumSupportedBuild);
    expect(restored.flags, hasLength(config.flags.length));
    expect(restored.enabledLocales, hasLength(config.enabledLocales.length));
    expect(restored.isFloorValid, isTrue);
  });

  test('the staff directory round-trips through JSON', () async {
    final api = FixtureAdminApi(latency: Duration.zero);
    final directory = await api.fetchStaffDirectory();

    final restored = StaffDirectoryDto.fromJson(directory.toJson());

    expect(restored.members, hasLength(directory.members.length));
    expect(restored.effectiveAdminCount, directory.effectiveAdminCount);
    expect(restored.accountsWithoutTwoFactor, greaterThan(0));
  });
}
