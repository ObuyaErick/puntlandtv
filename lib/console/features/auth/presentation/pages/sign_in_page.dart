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
import '../widgets/forgot_password_dialog.dart';
import '../widgets/two_factor_dialog.dart';

/// Console sign-in.
///
/// Two panes from medium up — brand on the left, form on the right. Below that
/// it is a phone screen of its own rather than the two panes stacked, so the
/// console is usable when a duty editor needs it at 23:00: see [_CompactLayout].
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
            Widget form({required bool compact}) => _SignInCard(
              email: _email,
              password: _password,
              errorCode: errorCode,
              submitting: _submitting,
              onSubmit: _submit,
              compact: compact,
            );

            if (!size.isAtLeastMedium) {
              return _CompactLayout(form: form(compact: true));
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
                      SizedBox(width: 400, child: form(compact: false)),
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

/// The portrait phone screen.
///
/// Brand and language sit in a top bar, the form follows with no card around
/// it — a bordered card inside a 20dp gutter spends a sixth of a 390dp screen
/// on frame — and the access notice holds the bottom edge. The console's
/// marketing paragraph is left to the wide layout: the people signing in here
/// already know what the console is, and on a phone it pushed Continue towards
/// the fold.
///
/// It scrolls rather than overflows, so a short screen or an open keyboard
/// still reaches the button; the notice only rides the bottom while there is
/// room for it to.
class _CompactLayout extends StatelessWidget {
  const _CompactLayout({required this.form});

  final Widget form;

  @override
  Widget build(BuildContext context) {
    // The lockup must never scale below its reserved size, so a screen too
    // narrow for it beside the toggle (320dp, say) keeps the mark and drops
    // the wordmark. Read from the window rather than a LayoutBuilder, which
    // cannot answer the intrinsic sizing SliverFillRemaining asks of it.
    final rowWidth =
        MediaQuery.sizeOf(context).width -
        MediaQuery.paddingOf(context).horizontal -
        2 * Spacing.gutter;
    final showWordmark =
        rowWidth >=
        kLogoLockupSize.width + _LocaleToggle.compactWidth + Spacing.chip;

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.gutter,
              Spacing.listRhythm,
              Spacing.gutter,
              Spacing.gutter,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    PltvLockup(showWordmark: showWordmark),
                    const Spacer(),
                    // Top of the screen, not inside the form: a Somali-first
                    // user has to find it before reading anything else.
                    const _LocaleToggle(compact: true),
                  ],
                ),
                const SizedBox(height: Spacing.emptyState),
                form,
                const Spacer(),
                const SizedBox(height: Spacing.sectionBreak),
                const _InternalNotice(),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

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
        const SizedBox(height: Spacing.sectionBreak),
        Text(
          l10n.consoleTitle,
          style: context.text.display.copyWith(color: context.scheme.primary),
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

/// "Internal system. Access is logged." at the foot of the phone layout.
class _InternalNotice extends StatelessWidget {
  const _InternalNotice();

  @override
  Widget build(BuildContext context) {
    final color = context.scheme.onSurfaceVariant;

    return Row(
      children: [
        Icon(Icons.lock_outline_rounded, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${context.l10n.consoleInternalNotice} v1.0.0',
            style: context.text.meta.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _SignInCard extends ConsumerStatefulWidget {
  const _SignInCard({
    required this.email,
    required this.password,
    required this.errorCode,
    required this.submitting,
    required this.onSubmit,
    required this.compact,
  });

  final TextEditingController email;
  final TextEditingController password;
  final String? errorCode;
  final bool submitting;
  final VoidCallback onSubmit;

  /// Unframed, with the page heading and no locale toggle — the phone layout
  /// puts that in its top bar.
  final bool compact;

  @override
  ConsumerState<_SignInCard> createState() => _SignInCardState();
}

class _SignInCardState extends ConsumerState<_SignInCard> {
  /// Masked until asked otherwise. Someone signing in from the newsroom floor
  /// has people behind them; revealing is the deliberate act, not the default.
  var _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final email = widget.email;
    final password = widget.password;
    final errorCode = widget.errorCode;
    final submitting = widget.submitting;
    final onSubmit = widget.onSubmit;
    final compact = widget.compact;

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

    final header = compact
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.consoleTitle.toUpperCase(),
                style: context.text.overline.copyWith(
                  color: context.colors.accent,
                ),
              ),
              const SizedBox(height: Spacing.chip),
              Semantics(
                header: true,
                child: Text(
                  l10n.signInTitle,
                  style: context.text.headline.copyWith(
                    color: context.scheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: Spacing.iconToLabel),
              Text(
                l10n.signInSubtitle,
                style: context.text.body.copyWith(
                  color: context.scheme.onSurfaceVariant,
                ),
              ),
            ],
          )
        : Row(
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
          );

    final fields = AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          header,
          SizedBox(height: compact ? Spacing.sectionBreak : Spacing.gutter),
          ConsoleTextField(
            label: l10n.fieldEmail,
            controller: email,
            // Not on a phone: the keyboard would open over the screen before
            // anyone has seen it, language switch included.
            autofocus: !compact,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            hintText: 'a.yuusuf@pltv.so',
            errorText: message,
          ),
          const SizedBox(height: Spacing.listRhythm),
          ConsoleTextField(
            label: l10n.fieldPassword,
            controller: password,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => onSubmit(),
            suffixIcon: IconButton(
              // Tooltip and semantics both name the *result* of pressing, which
              // is what a screen reader user needs to hear.
              tooltip: _obscurePassword ? l10n.showPassword : l10n.hidePassword,
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: context.scheme.onSurfaceVariant,
              ),
            ),
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
          TextButton(
            // The address travels with them: someone who has just failed to
            // sign in has already typed it once.
            onPressed: () => showForgotPasswordDialog(
              context,
              email: email.text.trim().isEmpty ? null : email.text.trim(),
            ),
            child: Text(l10n.forgotPassword),
          ),
        ],
      ),
    );

    if (compact) return fields;

    return Container(
      padding: const EdgeInsets.all(Spacing.sectionBreak),
      decoration: BoxDecoration(
        color: context.scheme.surface,
        borderRadius: Radii.cardBorder,
        border: Border.all(color: context.colors.outline),
      ),
      child: fields,
    );
  }
}

/// EN / SO switch on the sign-in screen.
///
/// It has to be here rather than only in settings: a Somali-first user must be
/// able to read the login form before they have an account session to store a
/// preference against.
class _LocaleToggle extends ConsumerWidget {
  const _LocaleToggle({this.compact = false});

  /// Touch-sized segments. The desktop size is a pointer target and falls
  /// under the 48dp minimum on a phone.
  final bool compact;

  /// Two touch segments inside 2dp of padding and a 1dp border.
  static const compactWidth = 2 * kMinTapTarget + 6;

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
            width: compact ? kMinTapTarget : 34,
            height: compact ? kMinTapTarget : 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? context.scheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: context.text.overline.copyWith(
                fontSize: compact ? 12 : 10,
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
