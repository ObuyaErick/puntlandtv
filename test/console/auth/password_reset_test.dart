import 'package:flutter_test/flutter_test.dart';
import 'package:puntland/console/core/admin_api/fixture_admin_api.dart';
import 'package:puntland/core/error/failure.dart';
import 'package:puntland/console/core/providers/console_providers.dart';
import 'package:puntland/console/features/auth/domain/entities/console_user.dart';
import 'package:puntland/core/providers/preferences_providers.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The forgotten-password flow, as the console runs it.
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

  test('an unknown address is answered exactly like a real one', () async {
    final c = await container();
    final reset = c.read(passwordResetControllerProvider.notifier);

    await reset.request('a.yuusuf@pltv.so');
    final known = c.read(passwordResetControllerProvider);

    reset.reset();
    await reset.request('nobody@pltv.so');
    final unknown = c.read(passwordResetControllerProvider);

    // Both move to the same step. A reset form that stopped at the first one
    // would tell anyone who asked which addresses have console accounts.
    expect(known, isA<ResetCodeSent>());
    expect(
      unknown,
      isA<ResetCodeSent>(),
      reason: 'a reset form must not be an account-enumeration oracle',
    );
  });

  test('an empty address is caught without asking the backend', () async {
    final c = await container();

    await c.read(passwordResetControllerProvider.notifier).request('  ');

    final state = c.read(passwordResetControllerProvider);
    expect(state, isA<ResetIdle>());
    expect((state as ResetIdle).errorCode, 'EMAIL_REQUIRED');
  });

  test('the right code sets the password', () async {
    final c = await container();
    final reset = c.read(passwordResetControllerProvider.notifier);

    await reset.request('a.yuusuf@pltv.so');
    await reset.submit(
      code: FixtureAdminApi.validResetCode,
      password: 'a-long-enough-passphrase',
    );

    expect(c.read(passwordResetControllerProvider), isA<ResetComplete>());
  });

  test('completing a reset does not sign anybody in', () async {
    final c = await container();
    final reset = c.read(passwordResetControllerProvider.notifier);

    await reset.request('a.yuusuf@pltv.so');
    await reset.submit(
      code: FixtureAdminApi.validResetCode,
      password: 'a-long-enough-passphrase',
    );

    // "I forgot my password" is exactly the story an attacker tells. The
    // operator goes back to the form and passes the second factor like anyone
    // else.
    expect(c.read(authControllerProvider), isA<SignedOut>());
    expect(c.read(currentUserProvider), isNull);
  });

  test('a short password is refused before a round trip', () async {
    final c = await container();
    final reset = c.read(passwordResetControllerProvider.notifier);

    await reset.request('a.yuusuf@pltv.so');
    await reset.submit(code: FixtureAdminApi.validResetCode, password: 'short');

    final state = c.read(passwordResetControllerProvider);
    expect(state, isA<ResetCodeSent>());
    expect((state as ResetCodeSent).errorCode, 'PASSWORD_TOO_SHORT');
  });

  test('a wrong code burns an attempt and keeps the step open', () async {
    final c = await container();
    final reset = c.read(passwordResetControllerProvider.notifier);

    await reset.request('a.yuusuf@pltv.so');
    await reset.submit(code: '000000', password: 'a-long-enough-passphrase');

    final state = c.read(passwordResetControllerProvider);
    expect(state, isA<ResetCodeSent>());
    expect((state as ResetCodeSent).attemptsUsed, 1);
    expect(state.errorCode, 'RESET_CODE_INVALID');
    expect(state.attemptsRemaining, 4);
  });

  test('five wrong codes send the operator back to the start', () async {
    final c = await container();
    final reset = c.read(passwordResetControllerProvider.notifier);

    await reset.request('a.yuusuf@pltv.so');
    for (var attempt = 0; attempt < ResetCodeSent.maxAttempts; attempt++) {
      await reset.submit(code: '000000', password: 'a-long-enough-passphrase');
    }

    final state = c.read(passwordResetControllerProvider);
    expect(state, isA<ResetIdle>());
    expect((state as ResetIdle).errorCode, 'RESET_EXPIRED');
  });

  test('a code is single-use', () async {
    // Driven against the API directly: the controller refuses to submit twice
    // because the state has moved on, which would make a replay look prevented
    // when it was only unreachable.
    final api = FixtureAdminApi(latency: Duration.zero);

    await api.requestPasswordReset(email: 'a.yuusuf@pltv.so');
    await api.resetPassword(
      email: 'a.yuusuf@pltv.so',
      code: FixtureAdminApi.validResetCode,
      password: 'a-long-enough-passphrase',
    );

    await expectLater(
      api.resetPassword(
        email: 'a.yuusuf@pltv.so',
        code: FixtureAdminApi.validResetCode,
        password: 'another-long-passphrase',
      ),
      throwsA(
        isA<Failure>().having((f) => f.code, 'code', 'RESET_EXPIRED'),
      ),
      reason: 'a spent code must not set a second password',
    );
  });

  test('a code nobody asked for is refused', () async {
    final api = FixtureAdminApi(latency: Duration.zero);

    await expectLater(
      api.resetPassword(
        email: 'a.yuusuf@pltv.so',
        code: FixtureAdminApi.validResetCode,
        password: 'a-long-enough-passphrase',
      ),
      throwsA(
        isA<Failure>().having((f) => f.code, 'code', 'RESET_EXPIRED'),
      ),
    );
  });

  test('a reset in flight disables the buttons', () async {
    final c = await container();
    final reset = c.read(passwordResetControllerProvider.notifier);

    final pending = reset.request('a.yuusuf@pltv.so');
    // The fixture answers after a delay, so the intermediate state is real.
    final midFlight = c.read(passwordResetControllerProvider);
    expect((midFlight as ResetIdle).submitting, isTrue);
    await pending;
    expect(c.read(passwordResetControllerProvider), isA<ResetCodeSent>());
  });
}
