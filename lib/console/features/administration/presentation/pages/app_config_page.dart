import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../../core/error/failure.dart';
import '../../../../../core/l10n/app_date_format.dart';
import '../../../../../core/l10n/app_number_format.dart';
import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/responsive/window_size.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../../core/widgets/feedback_views.dart';
import '../../../../core/admin_api/dto/console_config_dto.dart';
import '../../../../core/localised.dart';
import '../../../../core/widgets/console_fields.dart';
import '../../../../core/widgets/console_page.dart';
import '../../../../core/widgets/console_toast.dart';
import '../controllers/administration_controller.dart';

/// What `GET /v1/config` serves, from the writing side.
///
/// Edited as a draft and saved once, unlike every other console screen where an
/// action is its own write. Two fields here can take the product down for every
/// reader at the moment they are changed, so there has to be a state where the
/// form is wrong, the screen says why, and nothing has happened yet:
///
/// 1. **A minimum build above the highest released one locks everyone out.**
///    Every reader is told to update, with nothing to update to, and only a
///    store release undoes it — days, not minutes.
/// 2. **Disabling a language removes content, not labels.** An article written
///    only in Somali has nowhere to go when Somali is off; it does not fall
///    back, it disappears. The switch says how many.
class AppConfigPage extends ConsumerWidget {
  const AppConfigPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final stored = ref.watch(storedConfigProvider);
    final draft = ref.watch(configDraftProvider);
    final dirty = ref.watch(configIsDirtyProvider);

    return ConsolePage(
      title: l10n.configTitle,
      subtitle: dirty ? l10n.unsavedChanges : _provenance(context, draft),
      actions: [
        if (dirty)
          TextButton(
            onPressed: ref.read(configDraftProvider.notifier).discard,
            child: Text(l10n.discardChanges),
          ),
        Tooltip(
          message: draft?.canSave ?? true ? '' : l10n.saveBlockedByFloor,
          child: FilledButton(
            onPressed: dirty && (draft?.canSave ?? false)
                ? () => _save(context, ref)
                : null,
            child: Text(l10n.save),
          ),
        ),
      ],
      notice: ConsoleNotice(message: l10n.configNotice),
      child: stored.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          failure: error is Failure
              ? error
              : const Failure(kind: FailureKind.unknown, code: 'UNKNOWN'),
          onRetry: () => ref.invalidate(storedConfigProvider),
        ),
        data: (_) => draft == null
            ? const SizedBox.shrink()
            : _ConfigForm(config: draft),
      ),
    );
  }

  String? _provenance(BuildContext context, ConsoleConfigDto? config) {
    if (config?.updatedAt == null || config?.updatedBy == null) return null;
    return context.l10n.configLastChanged(
      AppDateFormat.byline(config!.updatedAt!, context.languageCode),
      config.updatedBy!,
    );
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    await ref.read(configActionsProvider.notifier).save();
    if (!context.mounted) return;
    showConsoleToast(
      context,
      message: l10n.configSaved,
      kind: ToastKind.success,
    );
  }
}

class _ConfigForm extends StatelessWidget {
  const _ConfigForm({required this.config});

  final ConsoleConfigDto config;

  @override
  Widget build(BuildContext context) {
    return WindowSizeScope(
      builder: (context, size) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Spacing.sectionBreak,
            Spacing.gutter,
            Spacing.sectionBreak,
            Spacing.emptyState,
          ),
          child: Center(
            child: ConstrainedBox(
              // The form is prose and single-column controls; letting it run to
              // 1400dp puts a switch a screen's width away from its label.
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Section(
                    title: context.l10n.sectionUpdateFloor,
                    child: _UpdateFloor(config: config),
                  ),
                  _Section(
                    title: context.l10n.sectionLocales,
                    child: _Locales(config: config),
                  ),
                  _Section(
                    title: context.l10n.sectionFlags,
                    child: _Flags(config: config),
                  ),
                  _Section(
                    title: context.l10n.sectionReaderDefaults,
                    child: _ReaderDefaults(config: config),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sectionBreak),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: context.text.overline.copyWith(
              color: context.scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.cardInternal),
          Container(
            padding: const EdgeInsets.all(Spacing.listRhythm),
            decoration: BoxDecoration(
              color: context.scheme.surface,
              borderRadius: Radii.cardBorder,
              border: Border.all(color: context.colors.outline),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// The force-update floor, with the released build beside it.
///
/// The reference number is on screen rather than in a tooltip because the field
/// is meaningless without it: 118 is safe and 119 is a catastrophe, and nothing
/// about the digits says which.
class _UpdateFloor extends ConsumerStatefulWidget {
  const _UpdateFloor({required this.config});

  final ConsoleConfigDto config;

  @override
  ConsumerState<_UpdateFloor> createState() => _UpdateFloorState();
}

class _UpdateFloorState extends ConsumerState<_UpdateFloor> {
  late final _controller = TextEditingController(
    text: '${widget.config.minimumSupportedBuild}',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_UpdateFloor old) {
    super.didUpdateWidget(old);
    // Re-seeds when the draft is discarded, but not while the user is typing —
    // an unparseable field is a state they are mid-way through, not one to
    // overwrite.
    final stored = '${widget.config.minimumSupportedBuild}';
    if (int.tryParse(_controller.text) != widget.config.minimumSupportedBuild) {
      if (int.tryParse(_controller.text) == null) return;
      _controller.text = stored;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final config = widget.config;
    final code = context.languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConsoleTextField(
          label: l10n.fieldMinimumBuild,
          controller: _controller,
          keyboardType: TextInputType.number,
          errorText: config.locksEveryoneOut
              ? l10n.floorLocksEveryoneOut
              : null,
          onChanged: (value) {
            final parsed = int.tryParse(value.trim());
            if (parsed != null) {
              ref.read(configDraftProvider.notifier).setMinimumBuild(parsed);
            }
          },
        ),
        const SizedBox(height: Spacing.cardInternal),
        Row(
          children: [
            Icon(
              config.locksEveryoneOut
                  ? Icons.dangerous_outlined
                  : Icons.check_circle_outline_rounded,
              size: 16,
              color: config.locksEveryoneOut
                  ? context.scheme.error
                  : context.colors.onAccentContainer,
            ),
            const SizedBox(width: Spacing.chip),
            Expanded(
              child: Text(
                config.locksEveryoneOut
                    ? l10n.releasedBuildIs(
                        AppNumberFormat.decimal(
                          config.currentReleasedBuild,
                          code,
                        ),
                      )
                    : l10n.floorSafe(
                        AppNumberFormat.decimal(
                          config.minimumSupportedBuild,
                          code,
                        ),
                      ),
                style: context.text.meta.copyWith(
                  color: config.locksEveryoneOut
                      ? context.scheme.error
                      : context.scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        if (!config.locksEveryoneOut) ...[
          const SizedBox(height: 4),
          Text(
            l10n.releasedBuildIs(
              AppNumberFormat.decimal(config.currentReleasedBuild, code),
            ),
            style: context.text.meta.copyWith(
              color: context.scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// One switch per language, each carrying the cost of turning it off.
class _Locales extends ConsumerWidget {
  const _Locales({required this.config});

  final ConsoleConfigDto config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final option in config.locales) ...[
          _LocaleRow(config: config, option: option),
          if (option != config.locales.last)
            Divider(
              height: Spacing.listRhythm,
              color: context.colors.outlineSubtle,
            ),
        ],
        const SizedBox(height: Spacing.cardInternal),
        Text(
          l10n.disablingRemovesContent,
          style: context.text.meta.copyWith(
            color: context.scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _LocaleRow extends ConsumerWidget {
  const _LocaleRow({required this.config, required this.option});

  final ConsoleConfigDto config;
  final LocaleOptionDto option;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final isLast = option.enabled && !config.canDisableLocale(option.code);
    final stranded = option.articlesOnlyInThisLocale;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.languageNameOf(option.code),
                style: context.text.body.copyWith(
                  color: context.scheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isLast
                    ? l10n.lastLocaleCannotBeDisabled
                    : l10n.localeStrandsArticles(stranded),
                style: context.text.meta.copyWith(
                  // Amber, not red: the content is not lost, it stops being
                  // reachable. Colouring it as an error would put it in the
                  // same class as the build floor, which is a genuine
                  // catastrophe.
                  color: isLast
                      ? context.scheme.onSurfaceVariant
                      : stranded > 0 && option.enabled
                      ? const Color(0xFF8A5A00)
                      : context.scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          key: Key('locale-${option.code}'),
          value: option.enabled,
          onChanged: isLast
              ? null
              : (value) => ref
                    .read(configDraftProvider.notifier)
                    .setLocaleEnabled(option.code, value),
        ),
      ],
    );
  }
}

class _Flags extends ConsumerWidget {
  const _Flags({required this.config});

  final ConsoleConfigDto config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.flagKeyPermanentNote,
          style: context.text.meta.copyWith(
            color: context.scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.listRhythm),
        for (final flag in config.flags) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // The key verbatim, in the weight the categories table uses
                    // for a slug: this is an identifier a released build looks
                    // for, not a name.
                    Text(
                      flag.key,
                      style: context.text.label.copyWith(
                        color: context.scheme.primary,
                      ),
                    ),
                    if (flag.description != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        flag.description!,
                        style: context.text.meta.copyWith(
                          color: context.scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Switch.adaptive(
                key: Key('flag-${flag.key}'),
                value: flag.enabled,
                onChanged: (value) => ref
                    .read(configDraftProvider.notifier)
                    .setFlag(flag.key, value),
              ),
            ],
          ),
          if (flag != config.flags.last)
            Divider(
              height: Spacing.listRhythm,
              color: context.colors.outlineSubtle,
            ),
        ],
      ],
    );
  }
}

class _ReaderDefaults extends ConsumerWidget {
  const _ReaderDefaults({required this.config});

  final ConsoleConfigDto config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    // A Row rather than a SwitchListTile: every section on this page sits in a
    // coloured card, and a ListTile paints its background and ink on the
    // nearest Material — so its splash lands behind the card and is never
    // seen. The same shape as the locale and flag rows above, which is also
    // why they are Rows.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.fieldDataSaver,
                style: context.text.body.copyWith(
                  color: context.scheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l10n.dataSaverHint,
                style: context.text.meta.copyWith(
                  color: context.scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          key: const Key('data-saver-default'),
          value: config.dataSaverDefault,
          onChanged: ref.read(configDraftProvider.notifier).setDataSaverDefault,
        ),
      ],
    );
  }
}
