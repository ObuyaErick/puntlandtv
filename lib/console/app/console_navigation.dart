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

  /// The article list.
  void openArticles() => go(ConsoleRoutes.articles);

  /// One article, in the editor.
  ///
  /// `push`, not `go`: the editor is opened *from* the list and the back
  /// button has to return to it with its filter and scroll position intact.
  /// `go` would rebuild the branch and drop both.
  void openArticle(String id) => push<void>(ConsoleRoutes.article(id));

  /// One programme's episodes.
  void openProgram(String id) => go(ConsoleRoutes.program(id));
}
