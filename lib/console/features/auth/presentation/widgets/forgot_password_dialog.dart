import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/responsive/adaptive_layout.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../core/providers/console_providers.dart';
import '../../../../core/widgets/console_fields.dart';
import '../../data/console_auth_repository.dart';
import '../../domain/entities/console_user.dart';
import 'pin_field.dart';

/// The forgotten-password flow.
///
/// A dialog from medium up and a bottom sheet below, through the same adaptive
/// presenter the second-factor step uses.
///
/// Three steps in one surface rather than three routes: the operator is here
/// because they cannot get in, and sending them somewhere else — then back —
/// loses the address they already typed.
Future<void> showForgotPasswordDialog(BuildContext context, {String? email}) {
  return showAdaptiveSheet<void>(
    context: context,
    builder: (context) => ForgotPasswordForm(initialEmail: email),
  );
}

/// Public so it can be rendered directly in goldens and widget tests; the
/// dialog is the normal way in.
class ForgotPasswordForm extends ConsumerStatefulWidget {
  const ForgotPasswordForm({super.key, this.initialEmail});

  /// Carried over from the sign-in form. Someone who just failed to sign in has
  /// already typed their address once.
  final String? initialEmail;

  @override
  ConsumerState<ForgotPasswordForm> createState() => ForgotPasswordFormState();
}

class ForgotPasswordFormState extends ConsumerState<ForgotPasswordForm> {
  late final _email = TextEditingController(text: widget.initialEmail ?? '');
  final _code = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  /// Checked here rather than at the boundary: the backend has no idea what the
  /// operator typed twice, and cannot answer this.
  String? _mismatch;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _request() async {
    await ref.read(passwordResetControllerProvider.notifier).request(_email.text);
  }

  Future<void> _submit() async {
    if (_password.text != _confirm.text) {
      setState(() => _mismatch = 'PASSWORD_MISMATCH');
      return;
    }
    setState(() => _mismatch = null);

    await ref
        .read(passwordResetControllerProvider.notifier)
        .submit(code: _code.text, password: _password.text);

    if (!mounted) return;
    // A wrong code keeps the step open; the code is cleared because retyping it
    // is the point of staying.
    if (ref.read(passwordResetControllerProvider) is ResetCodeSent) {
      _code.clear();
    }
  }

  void _close() {
    ref.read(passwordResetControllerProvider.notifier).reset();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(passwordResetControllerProvider);

    return Padding(
      padding: const EdgeInsets.all(Spacing.gutter),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: switch (state) {
          ResetIdle() => _askForAddress(state),
          ResetCodeSent() => _askForCodeAndPassword(state),
          ResetComplete() => _done(state),
        },
      ),
    );
  }

  List<Widget> _askForAddress(ResetIdle state) {
    final l10n = context.l10n;

    return [
      _Header(
        icon: Icons.lock_reset_rounded,
        title: l10n.resetTitle,
        body: l10n.resetBody,
      ),
      const SizedBox(height: Spacing.gutter),
      ConsoleTextField(
        label: l10n.fieldEmail,
        controller: _email,
        autofocus: true,
        keyboardType: TextInputType.emailAddress,
        hintText: 'a.yuusuf@pltv.so',
        errorText: _messageFor(state.errorCode),
        onSubmitted: (_) => _request(),
      ),
      const SizedBox(height: Spacing.gutter),
      _Actions(
        submitting: state.submitting,
        confirmLabel: l10n.resetSendAction,
        onCancel: _close,
        onConfirm: _request,
      ),
    ];
  }

  List<Widget> _askForCodeAndPassword(ResetCodeSent state) {
    final l10n = context.l10n;
    final codeError =
        state.errorCode == 'RESET_CODE_INVALID' ||
        state.errorCode == 'RESET_CODE_REQUIRED';

    return [
      _Header(
        icon: Icons.mark_email_read_outlined,
        title: l10n.resetSentTitle,
        body: l10n.resetSentBody(state.email),
      ),
      if (state.devCode != null) ...[
        const SizedBox(height: Spacing.chip),
        _DevCodeNote(code: state.devCode!),
      ],
      const SizedBox(height: Spacing.gutter),
      PinField(controller: _code, hasError: codeError),
      if (codeError) ...[
        const SizedBox(height: Spacing.chip),
        _ErrorLine(message: _messageFor(state.errorCode)!),
        const SizedBox(height: Spacing.chip),
        // Attempts are shown, and they run out. Silently sending someone back
        // to the first step on the fifth try is worse than counting in front
        // of them.
        Text(
          l10n.attemptCount(state.attemptsUsed + 1, ResetCodeSent.maxAttempts),
          style: context.text.meta.copyWith(
            color: context.scheme.onSurfaceVariant,
          ),
        ),
      ],
      const SizedBox(height: Spacing.listRhythm),
      ConsoleTextField(
        label: l10n.resetNewPassword,
        controller: _password,
        obscureText: true,
        errorText: _mismatch == null
            ? _messageFor(
                state.errorCode == 'PASSWORD_TOO_SHORT'
                    ? state.errorCode
                    : null,
              )
            : null,
      ),
      const SizedBox(height: 4),
      Text(
        l10n.resetPasswordRule(ConsoleAuthRepository.minimumPasswordLength),
        style: context.text.meta.copyWith(
          color: context.scheme.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: Spacing.listRhythm),
      ConsoleTextField(
        label: l10n.resetConfirmPassword,
        controller: _confirm,
        obscureText: true,
        errorText: _messageFor(_mismatch),
        onSubmitted: (_) => _submit(),
      ),
      const SizedBox(height: Spacing.gutter),
      _Actions(
        submitting: state.submitting,
        confirmLabel: l10n.resetAction,
        onCancel: _close,
        onConfirm: _submit,
      ),
    ];
  }

  List<Widget> _done(ResetComplete state) {
    final l10n = context.l10n;

    return [
      _Header(
        icon: Icons.check_circle_outline_rounded,
        title: l10n.resetDoneTitle,
        body: l10n.resetDoneBody,
      ),
      const SizedBox(height: Spacing.gutter),
      FilledButton(onPressed: _close, child: Text(l10n.actionContinue)),
    ];
  }

  /// One place mapping refusal codes to sentences.
  ///
  /// The fallback is not decorative: a lost connection or a 500 arrives with a
  /// code this switch has never seen, and a dialog that renders nothing for it
  /// reads as a dialog whose button is broken.
  String? _messageFor(String? code) {
    final l10n = context.l10n;
    return switch (code) {
      null => null,
      'EMAIL_REQUIRED' => l10n.errorEmailRequired,
      'RESET_CODE_REQUIRED' => l10n.errorResetCodeRequired,
      'RESET_CODE_INVALID' => l10n.errorResetCodeInvalid,
      'RESET_EXPIRED' => l10n.errorResetExpired,
      'PASSWORD_TOO_SHORT' || 'VALIDATION_FAILED' => l10n.errorPasswordTooShort(
        ConsoleAuthRepository.minimumPasswordLength,
      ),
      'PASSWORD_MISMATCH' => l10n.errorPasswordMismatch,
      _ => l10n.errorResetFailed,
    };
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.colors.accentContainer,
                borderRadius: BorderRadius.circular(Radii.button),
              ),
              child: Icon(
                icon,
                size: 19,
                color: context.colors.onAccentContainer,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                title,
                style: context.text.title.copyWith(
                  color: context.scheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.chip),
        Text(
          body,
          style: context.text.body.copyWith(
            color: context.scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// The code, in the build that has no gateway to send it through.
///
/// Visibly marked as a development affordance rather than dressed up as part of
/// the product: it appears only when the backend echoed the code, which it does
/// outside production only.
class _DevCodeNote extends StatelessWidget {
  const _DevCodeNote({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.cardInternal,
        vertical: Spacing.chip,
      ),
      decoration: BoxDecoration(
        color: context.scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Radii.button),
        border: Border.all(color: context.colors.outlineSubtle),
      ),
      child: Row(
        children: [
          Icon(
            Icons.construction_rounded,
            size: 15,
            color: context.scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.resetDevCode(code),
              style: context.text.meta.copyWith(
                color: context.scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Text(
    message,
    style: context.text.meta.copyWith(color: context.scheme.error),
  );
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.submitting,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
  });

  final bool submitting;
  final String confirmLabel;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Divider(height: Spacing.gutter, color: context.colors.outlineSubtle),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: submitting ? null : onCancel,
                child: Text(context.l10n.cancel),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: submitting ? null : onConfirm,
                child: submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(confirmLabel),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
