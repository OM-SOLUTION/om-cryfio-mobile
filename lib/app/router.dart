import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:om_cryfio/app/app_shell.dart';
import 'package:om_cryfio/app/dev_tools.dart';
import 'package:om_cryfio/features/files/presentation/file_browser_screen.dart';
import 'package:om_cryfio/features/notifications/presentation/notifications_screen.dart';
import 'package:om_cryfio/features/settings/presentation/settings_screen.dart';
import 'package:om_cryfio/features/sharing/presentation/shared_screen.dart';

abstract final class AppRoutes {
  static const files = '/files';
  static const shared = '/shared';
  static const notifications = '/notifications';
  static const settings = '/settings';
}

/// There is no sign-in yet, so the app starts straight on the Files tab.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.files,
    routes: [
      // Each tab keeps its own navigation stack and scroll position.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.files,
                builder: (context, state) => const FileBrowserScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.shared,
                builder: (context, state) => const SharedScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.notifications,
                builder: (context, state) => const NotificationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      ...devRoutes(),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
