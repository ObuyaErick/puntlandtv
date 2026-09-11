import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/admin_api/dto/broadcast_dto.dart';
import '../../../../core/providers/console_providers.dart';

/// One channel's state, as its control room governs it, by channel key.
///
/// Its own file because two screens read it: live control, and the overview's
/// on-air card, which plays the same preview.
final broadcastControlProvider =
    FutureProvider.family<BroadcastControlDto, String>(
      (ref, channelKey) =>
          ref.watch(adminApiProvider).fetchBroadcastControl(channelKey),
    );
