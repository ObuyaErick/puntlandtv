import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../domain/entities/live_channel.dart';

part 'live_controllers.g.dart';

/// The live channel's status and schedule.
///
/// Kept alive so returning to the Live tab does not re-request the manifest,
/// but deliberately *not* polled: the app has no way to know when the
/// broadcaster goes off air, and the plan's answer is the backend's
/// `is_live` flag on the next natural fetch rather than a background poll that
/// burns data all day.
@Riverpod(keepAlive: true)
Future<LiveChannel> liveChannel(Ref ref) {
  return ref.watch(liveRepositoryProvider).channel();
}
