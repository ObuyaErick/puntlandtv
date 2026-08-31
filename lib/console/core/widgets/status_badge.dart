import 'package:material_ui/material_ui.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/theme_context.dart';
import '../../../core/theme/tokens.dart';
import '../admin_api/dto/admin_article_dto.dart';

/// Every state a row can be in.
///
/// Status is never colour-only: each badge carries its word, and the two green
/// states differ in fill weight as well as hue — so they stay distinguishable
/// in greyscale and to a colour-blind reader.
enum BadgeKind {
  draft,
  inReview,
  scheduled,
  published,
  live,
  failed,
  breaking,
  transcoding,
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.kind});

  StatusBadge.forArticle(ArticleStatus status, {super.key})
    : kind = switch (status) {
        ArticleStatus.draft => BadgeKind.draft,
        ArticleStatus.inReview => BadgeKind.inReview,
        ArticleStatus.scheduled => BadgeKind.scheduled,
        ArticleStatus.published => BadgeKind.published,
        ArticleStatus.failed => BadgeKind.failed,
      };

  final BadgeKind kind;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = context.scheme;
    final colors = context.colors;

    final (background, foreground, border, label) = switch (kind) {
      BadgeKind.draft => (
        colors.skeleton,
        scheme.onSurfaceVariant,
        colors.outline,
        l10n.statusDraft,
      ),
      BadgeKind.inReview => (
        const Color(0xFFFFF4E0),
        const Color(0xFF8A5A00),
        const Color(0xFFF0DCB4),
        l10n.statusInReview,
      ),
      BadgeKind.scheduled => (
        const Color(0xFFE8F1FA),
        colors.linkText,
        const Color(0xFFC8DDF0),
        l10n.statusScheduled,
      ),
      // Published is the lighter green; live is the solid one. Weight, not
      // just hue, separates them.
      BadgeKind.published => (
        colors.accentContainer,
        colors.onAccentContainer,
        colors.accentContainerOutline,
        l10n.statusPublished,
      ),
      BadgeKind.live => (
        LightTokens.accent,
        Colors.white,
        LightTokens.accent,
        l10n.live,
      ),
      BadgeKind.failed => (
        scheme.errorContainer,
        scheme.error,
        colors.errorContainerOutline,
        l10n.statusFailed,
      ),
      BadgeKind.breaking => (
        LightTokens.error,
        Colors.white,
        LightTokens.error,
        l10n.breaking,
      ),
      BadgeKind.transcoding => (
        const Color(0xFFEDE9F7),
        const Color(0xFF57429B),
        const Color(0xFFD7CEEE),
        l10n.statusTranscoding,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: context.text.overline.copyWith(fontSize: 10, color: foreground),
      ),
    );
  }
}
