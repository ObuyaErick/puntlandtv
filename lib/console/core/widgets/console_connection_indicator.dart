import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/realtime/realtime_event.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/theme/tokens.dart';
import '../providers/console_providers.dart';

/// Tells the operator when the console has stopped updating itself.
///
/// **Only when it has.** There is deliberately no "connected" state to render:
/// a permanent green dot is chrome nobody reads after the first week, and the
/// thing worth interrupting someone about is the screen having quietly gone
/// stale — which, before the realtime layer, was every screen all the time and
/// nobody was told.
///
/// [RealtimeStatus.idle] is also silent, and that is not an oversight. Idle
/// means no socket is wanted: the console is running on fixtures, or nothing
/// on screen subscribes to anything. Reporting that as a fault would put a
/// warning on every screen of a demo build.
class ConsoleConnectionIndicator extends ConsumerWidget {
  const ConsoleConnectionIndicator({super.key, this.onDark = false});

  /// Matches the dark ground live control uses.
  final bool onDark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref
        .watch(consoleRealtimeStatusProvider)
        .maybeWhen(data: (value) => value, orElse: () => RealtimeStatus.idle);

    if (status != RealtimeStatus.connecting) return const SizedBox.shrink();

    final l10n = context.l10n;
    final colour = onDark
        ? DarkTokens.onSurfaceVariant
        : context.scheme.onSurfaceVariant;

    return Tooltip(
      message: l10n.realtimeReconnectingHint,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: colour),
          ),
          const SizedBox(width: Spacing.chip),
          Text(
            l10n.realtimeReconnecting,
            style: context.text.meta.copyWith(color: colour),
          ),
        ],
      ),
    );
  }
}
