import 'package:flutter_test/flutter_test.dart';
import 'package:puntland/console/core/providers/console_providers.dart';
import 'package:puntland/console/core/admin_api/fixture_admin_api.dart';
import 'package:puntland/console/features/auth/domain/entities/console_user.dart';
import 'package:puntland/core/providers/preferences_providers.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ProviderContainer> container() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('valid credentials do not sign you in on their own', () async {
    final c = await container();

    await c
        .read(authControllerProvider.notifier)
        .signIn(email: 'a.yuusuf@pltv.so', password: 'anything');

    expect(
      c.read(authControllerProvider),
      isA<AwaitingSecondFactor>(),
      reason:
          'the console can publish to every phone and take the channel '
          'off air — a password alone is not the bar',
    );
  });

  test('an unknown email fails the same way a bad password does', () async {
    final c = await container();

    await c
        .read(authControllerProvider.notifier)
        .signIn(email: 'nobody@pltv.so', password: 'anything');

    final state = c.read(authControllerProvider);
    expect(state, isA<SignedOut>());
    expect(
      (state as SignedOut).errorCode,
      'INVALID_CREDENTIALS',
      reason: 'saying which half was wrong is free reconnaissance',
    );
  });

  test('the right code signs you in with the right role', () async {
    final c = await container();
    final auth = c.read(authControllerProvider.notifier);

    await auth.signIn(email: 'f.xasan@pltv.so', password: 'x');
    await auth.verify(FixtureAdminApi.validSecondFactorCode);

    final state = c.read(authControllerProvider);
    expect(state, isA<SignedIn>());
    expect((state as SignedIn).user.role, ConsoleRole.journalist);
    expect(c.read(canProvider(Capability.publishArticles)), isFalse);
  });

  test('a wrong code burns an attempt and keeps you on the step', () async {
    final c = await container();
    final auth = c.read(authControllerProvider.notifier);

    await auth.signIn(email: 'a.yuusuf@pltv.so', password: 'x');
    await auth.verify('000');

    final state = c.read(authControllerProvider);
    expect(state, isA<AwaitingSecondFactor>());
    expect((state as AwaitingSecondFactor).attemptsUsed, 1);
    expect(state.errorCode, 'INVALID_CODE');
  });

  test('three wrong codes lock out and return to the form', () async {
    final c = await container();
    final auth = c.read(authControllerProvider.notifier);

    await auth.signIn(email: 'a.yuusuf@pltv.so', password: 'x');
    await auth.verify('000');
    await auth.verify('111');
    await auth.verify('222');

    final state = c.read(authControllerProvider);
    expect(state, isA<SignedOut>());
    expect((state as SignedOut).errorCode, 'LOCKED_OUT');
  });

  test('a session survives a restart, and sign-out clears it', () async {
    final c = await container();
    final auth = c.read(authControllerProvider.notifier);

    await auth.signIn(email: 'a.yuusuf@pltv.so', password: 'x');
    await auth.verify(FixtureAdminApi.validSecondFactorCode);

    // A fresh container over the same preferences stands in for a page reload.
    final restored = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
      ],
    );
    addTearDown(restored.dispose);
    await restored.read(authControllerProvider.notifier).restore();
    expect(restored.read(authControllerProvider), isA<SignedIn>());

    await restored.read(authControllerProvider.notifier).signOut();
    final after = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
      ],
    );
    addTearDown(after.dispose);
    await after.read(authControllerProvider.notifier).restore();
    expect(after.read(authControllerProvider), isA<SignedOut>());
  });
}
