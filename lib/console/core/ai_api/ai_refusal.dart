import '../../../core/error/failure.dart';
import '../../../core/l10n/l10n.dart';
import 'dto/ai_suggestion_dto.dart';

/// Turns an assistance refusal into a sentence the newsroom can act on.
///
/// Every message this returns names the manual route, or implies it, because
/// every task assistance touches here is one the newsroom was already doing by
/// hand. None of these is a blocker: a failed translation draft leaves an
/// editor exactly where they were before they pressed the button, and the copy
/// has to say so rather than reading like something has gone wrong with the
/// article.
///
/// Follows the per-screen refusal switch used elsewhere in the console — see
/// `channelRefusal` in `channel_panel.dart` — so an unrecognised code still
/// renders the code itself rather than a shrug.
String assistRefusal(AppL10n l10n, Failure failure) => switch (failure.code) {
  AiFailureCode.rateLimited => l10n.aiRateLimited,
  AiFailureCode.inputTooLarge => l10n.aiTooLong,
  AiFailureCode.unsafeContent => l10n.aiDeclined,
  AiFailureCode.disabled ||
  AiFailureCode.unavailable ||
  AiFailureCode.malformedOutput => l10n.aiUnavailable,
  _ => l10n.errorCodeLine(failure.code),
};
