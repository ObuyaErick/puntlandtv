import 'package:flutter_test/flutter_test.dart';
import 'package:puntland/console/features/auth/domain/entities/console_user.dart';

void main() {
  ConsoleUser userWith(ConsoleRole role) =>
      ConsoleUser(id: 'u-1', name: 'A. Yuusuf', email: 'a@pltv.so', role: role);

  group('role capabilities', () {
    test('a journalist may draft but not publish or send push', () {
      final user = userWith(ConsoleRole.journalist);

      expect(user.can(Capability.writeOwnArticles), isTrue);
      expect(user.can(Capability.publishArticles), isFalse);
      expect(
        user.can(Capability.sendPush),
        isFalse,
        reason:
            'a push reaches every phone in the region; it is an '
            'editor-and-above action',
      );
    });

    test('an editor may publish and send push but not run the broadcast', () {
      final user = userWith(ConsoleRole.editor);

      expect(user.can(Capability.publishArticles), isTrue);
      expect(user.can(Capability.sendPush), isTrue);
      expect(user.can(Capability.manageBroadcast), isFalse);
      expect(user.can(Capability.manageUsers), isFalse);
    });

    test('operations runs the broadcast but does not publish articles', () {
      final user = userWith(ConsoleRole.operations);

      expect(user.can(Capability.manageBroadcast), isTrue);
      expect(user.can(Capability.publishArticles), isFalse);
    });

    test('admin holds every capability', () {
      final user = userWith(ConsoleRole.admin);

      for (final capability in Capability.values) {
        expect(
          user.can(capability),
          isTrue,
          reason:
              'admin is the union of all capabilities, not a bypass — '
              '${capability.name} is missing from the set',
        );
      }
    });

    test('every capability is held by at least one role', () {
      final covered = {
        for (final role in ConsoleRole.values) ...role.capabilities,
      };

      expect(
        Capability.values.toSet().difference(covered),
        isEmpty,
        reason:
            'a capability no role can exercise is dead code or a missing '
            'role assignment',
      );
    });
  });

  group('initials', () {
    test('takes the first two name parts', () {
      expect(userWith(ConsoleRole.editor).initials, 'AY');
    });

    test('handles a single-word name', () {
      const user = ConsoleUser(
        id: 'u',
        name: 'Warsame',
        email: 'w@pltv.so',
        role: ConsoleRole.admin,
      );
      expect(user.initials, 'W');
    });
  });

  group('second factor attempts', () {
    test('counts down and locks out', () {
      const first = AwaitingSecondFactor(email: 'a@pltv.so');
      expect(first.attemptsRemaining, 3);
      expect(first.isLockedOut, isFalse);

      const last = AwaitingSecondFactor(email: 'a@pltv.so', attemptsUsed: 3);
      expect(last.attemptsRemaining, 0);
      expect(last.isLockedOut, isTrue);
    });
  });
}
