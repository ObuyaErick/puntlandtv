import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../theme/theme_context.dart';
import '../theme/tokens.dart';

/// The Puntland TV mark: three concentric arcs above the PLTV blocks.
///
/// Drawn rather than shipped as an asset so it stays sharp at every density
/// and can invert for dark surfaces. Replace with the official vector once the
/// brand team supplies it — the geometry here is traced from the design canvas
/// and is an approximation of the real mark.
class PltvMark extends StatelessWidget {
  const PltvMark({super.key, this.height = 24, this.onDark = false});

  final double height;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final blockColor = onDark ? Colors.white : BrandPalette.navy;
    final arcWidth = height * 1.45;

    return SizedBox(
      height: height,
      width: arcWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: height * 0.5,
            width: arcWidth,
            child: CustomPaint(
              painter: _ArcsPainter(
                innerColor: onDark ? Colors.white : BrandPalette.navy,
              ),
            ),
          ),
          SizedBox(height: height * 0.1),
          SizedBox(
            height: height * 0.36,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 4; i++) ...[
                  if (i > 0) SizedBox(width: height * 0.07),
                  Container(
                    width: height * 0.24,
                    decoration: BoxDecoration(
                      color: blockColor,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArcsPainter extends CustomPainter {
  const _ArcsPainter({required this.innerColor});

  final Color innerColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Three concentric half-rings, outer to inner: green, blue, navy.
    // The canvas is the *top half* of each ellipse, so the arc rect extends to
    // twice the canvas height and only the upper 180° is drawn.
    final stroke = size.height * 0.26;
    final gap = size.height * 0.07;
    final step = stroke + gap;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final rings = <Color>[BrandPalette.green, BrandPalette.blue, innerColor];

    for (var i = 0; i < rings.length; i++) {
      final inset = stroke / 2 + i * step;
      if (size.width - inset * 2 <= 0) break;

      canvas.drawArc(
        Rect.fromLTRB(
          inset,
          inset,
          size.width - inset,
          size.height * 2 - inset,
        ),
        math.pi,
        math.pi,
        false,
        paint..color = rings[i],
      );
    }
  }

  @override
  bool shouldRepaint(_ArcsPainter old) => old.innerColor != innerColor;
}

/// Mark plus wordmark, as it appears in the app bar.
///
/// The canvas reserves 188×36dp for this lockup and instructs: never scale
/// below it — drop the wordmark before shrinking the mark.
class PltvLockup extends StatelessWidget {
  const PltvLockup({super.key, this.showWordmark = true, this.onDark = false});

  final bool showWordmark;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PltvMark(height: 26, onDark: onDark),
        if (showWordmark) ...[
          const SizedBox(width: 9),
          // Flexible with an ellipsis is the last line of defence: callers are
          // expected to drop the wordmark before it gets this tight, but a
          // clipped wordmark still beats a yellow-and-black overflow stripe.
          Flexible(
            child: Text(
              'PUNTLAND TV',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.wordmark.copyWith(
                color: onDark ? Colors.white : context.scheme.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
