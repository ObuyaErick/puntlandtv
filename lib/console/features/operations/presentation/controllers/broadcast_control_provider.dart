import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/admin_api/dto/broadcast_dto.dart';
import '../../../../core/providers/console_providers.dart';

/// The channel's state, as live control governs it.
///
/// Its own file because two screens read it: live control, and the overview's
/// on-air card, which plays the same preview.
final broadcastControlProvider = FutureProvider<BroadcastControlDto>(
  (ref) => ref.watch(adminApiProvider).fetchBroadcastControl(),
);
