import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/providers/preferences_providers.dart';
import '../../../../../core/responsive/window_size.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../core/widgets/pltv_logo.dart';
import '../../../../../features/settings/domain/entities/app_preferences.dart';
import '../../../../core/providers/console_providers.dart';
import '../../../../core/widgets/console_fields.dart';
import '../../domain/entities/console_user.dart';
import '../widgets/two_factor_dialog.dart';

/// Console sign-in.
///
/// Two panes from medium up — brand on the left, form on the right — and a
/// single stacked column below that, so the console is usable on a phone when
/// a duty editor needs it at 23:00.
class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _submitting = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    await ref
        .read(authControllerProvider.notifier)
        .signIn(email: _email.text, password: _password.text);
    if (!mounted) return;
    setState(() => _submitting = false);

    if (ref.read(authControllerProvider) is AwaitingSecondFactor) {
      await showTwoFactorDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    final errorCode = state is SignedOut ? state.errorCode : null;

    return Scaffold(
      backgroundColor: context.scheme.surfaceContainerLow,
      body: SafeArea(
        child: WindowSizeScope(
          builder: (context, size) {
            final form = _SignInCard(
              email: _email,
              password: _password,
              errorCode: errorCode,
              submitting: _submitting,
              onSubmit: _submit,
            );

            if (!size.isAtLeastMedium) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(Spacing.gutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _BrandPanel(compact: true),
                    const SizedBox(height: Spacing.sectionBreak),
                    form,
                  ],
                ),
              );
            }

            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.emptyState),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Expanded(child: _BrandPanel()),
                      const SizedBox(width: Spacing.emptyState),
                      SizedBox(width: 400, child: form),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const PltvLockup(),
        const SizedBox(height: 6),
        Text(
          l10n.tagline,
          style: context.text.meta.copyWith(
            color: context.scheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: compact ? Spacing.gutter : Spacing.sectionBreak),
        Text(
          l10n.consoleTitle,
          style: (compact ? context.text.headline : context.text.display)
              .copyWith(color: context.scheme.primary),
        ),
        const SizedBox(height: Spacing.cardInternal),
        Text(
          l10n.consoleSubtitle,
          style: context.text.body.copyWith(
            color: context.scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.sectionBreak),
        Text(
          '${l10n.consoleInternalNotice} v1.0.0',
          style: context.text.meta.copyWith(
            color: context.scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SignInCard extends ConsumerWidget {
  const _SignInCard({
    required this.email,
    required this.password,
    required this.errorCode,
    required this.submitting,
    required this.onSubmit,
  });

  final TextEditingController email;
  final TextEditingController password;
  final String? errorCode;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    // A real backend can refuse for reasons the fixtures never produced — an
    // account with no second factor, a lost connection, a 500. The fallback is
    // not decorative: without it those all render as an empty box, and a form
    // that fails silently reads as a form that is broken.
    final message = switch (errorCode) {
      null => null,
      'INVALID_CREDENTIALS' => l10n.errorInvalidCredentials,
      'PASSWORD_REQUIRED' => l10n.errorPasswordRequired,
      'LOCKED_OUT' => l10n.errorLockedOut,
      'TWO_FACTOR_NOT_ENROLLED' => l10n.errorTwoFactorNotEnrolled,
      _ => l10n.errorSignInFailed,
    };

    return Container(
      padding: const EdgeInsets.all(Spacing.sectionBreak),
      decoration: BoxDecoration(
        color: context.scheme.surface,
        borderRadius: Radii.cardBorder,
        border: Border.all(color: context.colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.signInTitle,
                      style: context.text.title.copyWith(
                        color: context.scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.signInSubtitle,
                      style: context.text.meta.copyWith(
                        color: context.scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const _LocaleToggle(),
            ],
          ),
          const SizedBox(height: Spacing.gutter),
          ConsoleTextField(
            label: l10n.fieldEmail,
            controller: email,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            hintText: 'a.yuusuf@pltv.so',
            errorText: message,
          ),
          const SizedBox(height: Spacing.listRhythm),
          ConsoleTextField(
            label: l10n.fieldPassword,
            controller: password,
            obscureText: true,
            onSubmitted: (_) => onSubmit(),
          ),
          const SizedBox(height: Spacing.gutter),
          FilledButton(
            onPressed: submitting ? null : onSubmit,
            child: submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(l10n.actionContinue),
          ),
          const SizedBox(height: Spacing.chip),
          TextButton(onPressed: () {}, child: Text(l10n.forgotPassword)),
        ],
      ),
    );
  }
}

/// EN / SO switch on the sign-in screen.
///
/// It has to be here rather than only in settings: a Somali-first user must be
/// able to read the login form before they have an account session to store a
/// preference against.
class _LocaleToggle extends ConsumerWidget {
  const _LocaleToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(preferencesProvider).locale;
    final controller = ref.read(preferencesProvider.notifier);

    Widget option(String label, LocalePreference value) {
      final selected = current == value;
      return Semantics(
        selected: selected,
        button: true,
        child: InkWell(
          onTap: () => controller.setLocale(value),
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 34,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? context.scheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: context.text.overline.copyWith(
                fontSize: 10,
                color: selected
                    ? Colors.white
                    : context.scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: context.colors.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          option('EN', LocalePreference.english),
          option('SO', LocalePreference.somali),
        ],
      ),
    );
  }
}
