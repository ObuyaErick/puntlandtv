import 'package:material_ui/material_ui.dart';

import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../core/admin_api/dto/channel_dto.dart';

/// Which channel a screen is showing, and the way to another.
///
/// A button naming the channel rather than a bare dropdown arrow: on a screen
/// whose every control acts on one channel, "which channel am I about to take
/// off air" has to be answered by the header before anyone reaches a switch.
class ChannelSwitcher extends StatelessWidget {
  const ChannelSwitcher({
    super.key,
    required this.channels,
    required this.selectedKey,
    required this.onSelected,
    this.onDark = false,
  });

  /// The channels to offer, in list order.
  final List<ChannelDto> channels;
  final String selectedKey;
  final ValueChanged<String> onSelected;

  /// Styled for live control's dark header.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final selected = channels.where((c) => c.key == selectedKey).firstOrNull;
    final foreground = onDark ? Colors.white : context.scheme.onSurface;

    return MenuAnchor(
      menuChildren: [
        for (final channel in channels)
          MenuItemButton(
            key: Key('switch-channel-${channel.key}'),
            onPressed: channel.key == selectedKey
                ? null
                : () => onSelected(channel.key),
            // A tick on the current one rather than hiding it: the menu then
            // reads as the whole list, in order, with "you are here" marked.
            leadingIcon: Icon(
              channel.key == selectedKey
                  ? Icons.check_rounded
                  : Icons.podcasts_outlined,
              size: 16,
            ),
            child: Text(channel.name),
          ),
      ],
      builder: (context, controller, _) => Tooltip(
        message: context.l10n.switchChannel,
        child: OutlinedButton.icon(
          key: const Key('channel-switcher'),
          onPressed: channels.length < 2
              ? null
              : () =>
                    controller.isOpen ? controller.close() : controller.open(),
          icon: const Icon(Icons.unfold_more_rounded, size: 16),
          iconAlignment: IconAlignment.end,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 36),
            foregroundColor: foreground,
            disabledForegroundColor: foreground,
            side: BorderSide(
              color: onDark ? DarkTokens.outlineStrong : context.colors.outline,
            ),
          ),
          label: ConstrainedBox(
            // A long name gives way before the header's other actions do.
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              selected?.name ?? selectedKey,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
