import 'package:material_ui/material_ui.dart';

import '../../../../../core/l10n/l10n.dart';
import '../../../../../core/theme/theme_context.dart';
import '../../../../../core/theme/tokens.dart';
import '../../../../core/admin_api/dto/media_dto.dart';

/// The upload affordance at the head of the library.
///
/// A visible zone rather than a hidden drag target: a drop area nobody can see
/// is a feature only the person who built it knows about. The button beside it
/// is not a fallback — it is the path a keyboard user takes, and dropping is
/// the shortcut.
///
/// There is no file picker behind this in the MVP. It stands in for one and
/// registers a fixture asset, which is enough to demonstrate the state that
/// matters: an image lands **undescribed**, and the library says so
/// immediately rather than letting it sit in the grid looking finished.
class UploadDropZone extends StatefulWidget {
  const UploadDropZone({super.key, required this.onUpload, this.busy = false});

  /// Called with what the picker would have returned.
  final void Function({
    required String filename,
    required MediaKind kind,
    required int byteSize,
  })
  onUpload;

  final bool busy;

  @override
  State<UploadDropZone> createState() => _UploadDropZoneState();
}

class _UploadDropZoneState extends State<UploadDropZone> {
  var _hovered = false;

  /// Cycles so repeated presses do not collide on one filename, and so the
  /// video path — the one with a transcode state — is reachable without a
  /// second control.
  var _next = 0;

  static const _samples = <(String, MediaKind, int)>[
    ('sawir-cusub-01.jpg', MediaKind.image, 1420 * 1024),
    ('sawir-cusub-02.jpg', MediaKind.image, 2760 * 1024),
    ('barnaamij-cusub.mp4', MediaKind.video, 1240 * 1024 * 1024),
  ];

  void _upload() {
    final (filename, kind, byteSize) = _samples[_next % _samples.length];
    setState(() => _next++);
    widget.onUpload(filename: filename, kind: kind, byteSize: byteSize);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    final icon = Icon(
      Icons.cloud_upload_outlined,
      size: 22,
      color: context.scheme.onSurfaceVariant,
    );

    final button = OutlinedButton(
      onPressed: widget.busy ? null : _upload,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 40),
        side: BorderSide(color: context.colors.outline),
        foregroundColor: context.scheme.onSurface,
      ),
      child: Text(l10n.chooseFiles),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: DottedBorderBox(
        active: _hovered,
        // Measured against the zone's own width, not the window's — per the
        // project's breakpoint rule. Squeezing the label between an icon and a
        // button on a 390dp screen wraps it to nine lines and the zone eats
        // the whole viewport, which is exactly what it did before this.
        child: LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < _rowMinWidth;

            final labels = Column(
              crossAxisAlignment: stacked
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.dropToUpload,
                  textAlign: stacked ? TextAlign.center : TextAlign.start,
                  style: context.text.body.copyWith(
                    color: context.scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.uploadFormats,
                  textAlign: stacked ? TextAlign.center : TextAlign.start,
                  style: context.text.meta.copyWith(
                    color: context.scheme.onSurfaceVariant,
                  ),
                ),
              ],
            );

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.gutter,
                vertical: Spacing.listRhythm,
              ),
              child: stacked
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        icon,
                        const SizedBox(height: Spacing.cardInternal),
                        labels,
                        const SizedBox(height: Spacing.listRhythm),
                        button,
                      ],
                    )
                  : Row(
                      children: [
                        icon,
                        const SizedBox(width: Spacing.listRhythm),
                        Expanded(child: labels),
                        const SizedBox(width: Spacing.listRhythm),
                        button,
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }

  /// Below this the icon, the label, and the button cannot share a line
  /// without the label being crushed into a column of single words.
  static const _rowMinWidth = 520.0;
}

/// A dashed rectangle, painted rather than assembled from widgets.
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.child, this.active = false});

  final Widget child;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(
        color: active ? context.colors.link : context.colors.outline,
        radius: Radii.card,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: active
              ? context.colors.link.withValues(alpha: 0.04)
              : Colors.transparent,
          borderRadius: Radii.cardBorder,
        ),
        child: child,
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  const _DashedRectPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );

    const dash = 6.0;
    const gap = 4.0;

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter old) =>
      old.color != color || old.radius != radius;
}
