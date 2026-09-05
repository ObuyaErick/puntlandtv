import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'console_routes.dart';

/// Every navigation the console can perform, named.
///
/// The one file allowed to call `go`/`push`. Screens say what they mean —
/// `context.openProgram(id)` — and never assemble a path or pick a navigation
/// verb themselves, so changing how a destination is reached (a path that gains
/// a segment, a screen that becomes a push rather than a replace) is a change
/// here and nowhere else. It also keeps `go_router` out of the widget layer,
/// which is what makes those widgets testable without a router in the tree.
extension ConsoleNavigation on BuildContext {
  /// The landing page. Also where the router sends anyone who asks for a
  /// destination their role cannot open.
  void openOverview() => go(ConsoleRoutes.overview);

  /// The programme list.
  void openPrograms() => go(ConsoleRoutes.programs);

  /// One programme's episodes.
  void openProgram(String id) => go(ConsoleRoutes.program(id));
}
