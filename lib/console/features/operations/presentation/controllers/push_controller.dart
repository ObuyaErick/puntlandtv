import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/admin_api/dto/push_dto.dart';
import '../../../../core/providers/console_providers.dart';

part 'push_controller.g.dart';

/// The alert being composed.
@riverpod
class PushDraft extends _$PushDraft {
  @override
  PushDraftDto build() => const PushDraftDto(
    messages: {'so': PushMessageDto(), 'en': PushMessageDto()},
  );

  void setTitle(String locale, String title) => state = state.withMessage(
    locale,
    state.message(locale).copyWith(title: title),
  );

  void setBody(String locale, String body) => state = state.withMessage(
    locale,
    state.message(locale).copyWith(body: body),
  );

  void toggleTopic(String topic) => state = state.copyWith(
    topics: state.topics.contains(topic)
        ? ({...state.topics}..remove(topic))
        : {...state.topics, topic},
  );

  void setDeepLink(String value) =>
      state = state.copyWith(deepLink: value.isEmpty ? null : value);

  /// Seeds one locale's body from another's, as a starting point for
  /// translation. Explicitly a copy, not a machine translation — the editor
  /// still has to write it.
  void copyBodyFrom({required String from, required String to}) =>
      setBody(to, state.message(from).body);

  void reset() => state = build();
}

/// Reach depends only on the selected topics, not on the message text.
///
/// Keyed on [PushDraftDto.topicsKey] rather than watching the whole draft:
/// watching the draft re-fetched on every keystroke, because a new draft
/// object never compares equal to the old one and the provider churned
/// continuously.
@riverpod
Future<PushReachDto> pushReach(Ref ref, String topicsKey) {
  final topics = topicsKey.isEmpty ? <String>{} : topicsKey.split(',').toSet();
  return ref.watch(adminApiProvider).fetchPushReach(topics);
}

@riverpod
Future<List<PushHistoryEntryDto>> pushHistory(Ref ref) =>
    ref.watch(adminApiProvider).fetchPushHistory();

@riverpod
class PushSender extends _$PushSender {
  @override
  bool build() => false;

  /// Sends and clears the composer. Returns the number of devices reached.
  Future<int> send() async {
    final draft = ref.read(pushDraftProvider);
    state = true;
    try {
      await ref.read(adminApiProvider).sendPush(draft);
      final reach = await ref.read(pushReachProvider(draft.topicsKey).future);
      ref
        ..invalidate(pushHistoryProvider)
        ..read(pushDraftProvider.notifier).reset();
      return reach.total;
    } finally {
      state = false;
    }
  }
}
