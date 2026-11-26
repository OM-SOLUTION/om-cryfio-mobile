import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Where developer-only tools plug into the app. In the repository this does
/// nothing. A developer can keep a private copy of this file (marked with
/// `git update-index --skip-worktree lib/app/dev_tools.dart` so git never
/// commits it) that adds, for example, a component gallery.

/// Extra routes, added after the app's own.
List<RouteBase> devRoutes() => const [];

/// Extra rows at the end of the Settings list, such as a "Developer" section.
List<Widget> devSettingsTiles(BuildContext context) => const [];
