import 'package:cached_network_image/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/theme_context.dart';

/// Network image with the design's placeholder treatment.
///
/// Every image in this app is optional. On the target connections a hero image
/// often arrives after the text, or not at all, so the placeholder is a
/// designed state rather than a gap — it holds the exact layout the image will
/// occupy, which is what stops the feed from reflowing as pictures land.
class RemoteImage extends StatelessWidget {
  const RemoteImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  final String? url;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.zero;

    Widget placeholder({bool failed = false}) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.imagePlaceholder,
        borderRadius: radius,
      ),
      child: Center(
        child: Icon(
          failed ? Icons.image_not_supported_outlined : Icons.image_outlined,
          size: 22,
          color: context.colors.onPlayerSurfaceVariant,
        ),
      ),
    );

    if (url == null || url!.isEmpty) return placeholder();

    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: url!,
        width: width,
        height: height,
        fit: fit,
        // No cross-fade: it costs a frame on every card in a fast scroll and
        // reads as jitter rather than polish on a low-end device.
        fadeInDuration: Duration.zero,
        placeholder: (_, _) => placeholder(),
        errorWidget: (_, _, _) => placeholder(failed: true),
      ),
    );
  }
}
