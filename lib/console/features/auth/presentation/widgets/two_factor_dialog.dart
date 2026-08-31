import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/responsive/adaptive_layout.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../core/providers/console_providers.dart';
import '../../domain/entities/console_user.dart';

/// The second-factor step.
///
/// A dialog from medium up and a bottom sheet below, via the shared adaptive
/// presenter — the same rule the app uses for its language picker.
Future<void> showTwoFactorDialog(BuildContext context) {
  return showAdaptiveSheet<void>(
    context: context,
    builder: (context) => const _TwoFactorForm(),
  );
}

class _TwoFactorForm extends ConsumerStatefulWidget {
  const _TwoFactorForm();

  @override
  ConsumerState<_TwoFactorForm> createState() => _TwoFactorFormState();
}

class _TwoFactorFormState extends ConsumerState<_TwoFactorForm> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  var _submitting = false;
  var _secondsRemaining = 24;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _focus.requestFocus();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_secondsRemaining > 0) _secondsRemaining--;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() => _submitting = true);
    await ref.read(authControllerProvider.notifier).verify(_controller.text);
    if (!mounted) return;

    final state = ref.read(authControllerProvider);
    setState(() => _submitting = false);

    // Both outcomes close the dialog: signed in, or locked out and returned
    // to the form. Only a retryable failure keeps it open.
    if (state is SignedIn || state is SignedOut) {
      Navigator.of(context).pop();
      return;
    }
    _controller.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final state = ref.watch(authControllerProvider);
    final pending = state is AwaitingSecondFactor ? state : null;

    return Padding(
      padding: const EdgeInsets.all(Spacing.gutter),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.twoFactorTitle,
            style: context.text.title.copyWith(color: context.scheme.primary),
          ),
          const SizedBox(height: Spacing.chip),
          Text(
            l10n.twoFactorBody,
            style: context.text.body.copyWith(
              color: context.scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.gutter),
          TextField(
            controller: _controller,
            focusNode: _focus,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            onSubmitted: (_) => _verify(),
            style: context.text.display.copyWith(
              letterSpacing: 12,
              color: context.scheme.primary,
            ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: context.scheme.surfaceContainerLow,
              errorText: pending?.errorCode == 'INVALID_CODE'
                  ? l10n.errorInvalidCode
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Radii.button),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Radii.button),
                borderSide: BorderSide(color: context.colors.link, width: 2),
              ),
            ),
          ),
          const SizedBox(height: Spacing.cardInternal),
          Row(
            children: [
              TextButton(
                onPressed: _secondsRemaining == 0
                    ? () => setState(() => _secondsRemaining = 24)
                    : null,
                child: Text(
                  l10n.resendCode(_formatCountdown(_secondsRemaining)),
                ),
              ),
              const Spacer(),
              // Attempts are shown, and they run out. Silently locking someone
              // out on the third try is worse than counting down in front of
              // them.
              Text(
                l10n.attemptCount(
                  (pending?.attemptsUsed ?? 0) + 1,
                  AwaitingSecondFactor.maxAttempts,
                ),
                style: context.text.meta.copyWith(
                  color: context.scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.gutter),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  ref.read(authControllerProvider.notifier).cancel();
                  Navigator.of(context).pop();
                },
                child: Text(l10n.cancel),
              ),
              const SizedBox(width: Spacing.chip),
              FilledButton(
                onPressed: _submitting ? null : _verify,
                child: Text(l10n.actionVerify),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatCountdown(int seconds) =>
      '0:${seconds.toString().padLeft(2, '0')}';
}
