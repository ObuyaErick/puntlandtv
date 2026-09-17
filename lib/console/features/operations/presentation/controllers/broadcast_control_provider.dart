import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/realtime/realtime_event.dart';
import '../../../../../core/realtime/realtime_watch.dart';
import '../../../../core/admin_api/dto/broadcast_dto.dart';
import '../../../../core/providers/console_providers.dart';

/// One channel's state, as its control room governs it, by channel key, kept
/// current from `admin:channel:<key>`.
///
/// Its own file because two screens read it: live control, and the overview's
/// on-air card, which plays the same preview.
///
/// This replaced a plain `FutureProvider.family` that fetched once. It is the
/// documented fix for the staleness `live_control_page.dart`
/// complains about out loud: the screen fetched once and then only re-read
/// after a write of its own, so the encoder reconnecting, another operator
/// pulling a rung, or the signal dropping sat stale until somebody navigated
/// away and back.
///
/// Always a refetch rather than an inline apply. `BroadcastControlDto` is the
/// whole control room — rungs, health, bitrates, uptime, slates in both
/// languages — and an event that tried to carry it would be a second, weaker
/// copy of the endpoint. The event's job here is only to say *when*.
///
/// The manual refresh button stays. It is still the right escape hatch when an
/// operator wants to know the reading is current rather than trust that it is,
/// and it is the only thing that works when the socket is down.
final broadcastControlWatchProvider =
    StreamProvider.family<BroadcastControlDto, String>((ref, channelKey) {
      return watchRealtime<BroadcastControlDto>(
        client: ref.watch(consoleRealtimeClientProvider),
        topic: RealtimeTopic.adminChannel(channelKey),
        fetch: () =>
            ref.read(adminApiProvider).fetchBroadcastControl(channelKey),
        apply: (_, _) => null,
        onDispose: ref.onDispose,
      );
    });
