import 'package:av_design/av_design.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/about/about_screen.dart';
import '../features/about/licenses_screen.dart';
import '../features/add/add_screen.dart';
import '../features/cloud/cloud_screen.dart';
import '../features/configurations/configurations_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/diagnostics/connections_screen.dart';
import '../features/diagnostics/logs_screen.dart';
import '../features/generated/generated_screen.dart';
import '../features/override/override_screen.dart';
import '../features/proxies/proxies_screen.dart';
import '../features/rules/rules_screen.dart';
import '../features/settings/advanced_settings_screen.dart';
import '../features/settings/apps_screen.dart';
import '../features/settings/basic_settings_screen.dart';
import '../features/tailscale/tailscale_screen.dart';
import '../features/tools/tools_frame.dart';
import '../features/tools/tools_screen.dart';
import 'layout.dart';
import 'routes.dart';
import 'shell/app_shell.dart';

/// One route table for phones and desktop: four branches
/// with their own navigators; forms open above the shell.
GoRouter buildRouter({
  String initialLocation = Routes.dashboard,
  bool cloudEnabled = false,
}) {
  final root = GlobalKey<NavigatorState>(debugLabel: 'root');

  StatefulShellBranch branch(
    String path,
    Widget screen, {
    List<RouteBase> routes = const [],
  }) => StatefulShellBranch(
    routes: [
      GoRoute(
        path: path,
        pageBuilder: (context, state) =>
            AvPage<void>(key: state.pageKey, child: screen),
        routes: routes,
      ),
    ],
  );

  // A sheet on phones, a dialog on wide windows. [build] gets the sheet's
  // scroll controller (null in a dialog).
  Page<T> modal<T>(
    BuildContext context,
    GoRouterState state,
    Widget Function(ScrollController? scroll) build,
  ) => isWideLayout(context)
      ? AvDialogPage<T>(key: state.pageKey, child: build(null))
      : AvSheetPage<T>(
          key: state.pageKey,
          builder: (context, controller) => build(controller),
        );

  Page<AddResult> form(
    BuildContext context,
    GoRouterState state,
    EditTarget? edit,
  ) => modal<AddResult>(
    context,
    state,
    (scroll) => AddScreen(edit: edit, scrollController: scroll),
  );

  // Tools pages push on phones and swap in place in the desktop pane.
  Page<void> toolPage(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) => isWideLayout(context)
      ? AvSwapPage<void>(key: state.pageKey, child: child)
      : AvPage<void>(key: state.pageKey, child: child);

  return GoRouter(
    navigatorKey: root,
    initialLocation: initialLocation,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(shell: shell),
        branches: [
          branch(Routes.dashboard, const DashboardScreen()),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.proxies,
                pageBuilder: (context, state) => AvPage<void>(
                  key: state.pageKey,
                  child: ProxiesScreen(
                    group: state.uri.queryParameters[Routes.proxiesGroup],
                  ),
                ),
              ),
            ],
          ),
          branch(Routes.configurations, const ConfigurationsScreen()),
          StatefulShellBranch(
            routes: [
              // On desktop the frame adds the list of tools on the left.
              ShellRoute(
                builder: (context, state, child) => ToolsFrame(
                  location: state.uri.path,
                  cloudEnabled: cloudEnabled,
                  child: child,
                ),
                routes: [
                  GoRoute(
                    path: Routes.tools,
                    pageBuilder: (context, state) => toolPage(
                      context,
                      state,
                      // The bare tab: the list on phones, the first tool
                      // beside the list on desktop.
                      isWideLayout(context)
                          ? const BasicSettingsScreen()
                          : ToolsScreen(cloudEnabled: cloudEnabled),
                    ),
                    routes: [
                      for (final tool in Tool.values)
                        if (tool != Tool.cloud || cloudEnabled)
                          GoRoute(
                            path: tool.name,
                            routes: [
                              if (tool == Tool.about)
                                GoRoute(
                                  path: 'licenses',
                                  pageBuilder: (context, state) => toolPage(
                                    context,
                                    state,
                                    const LicensesScreen(),
                                  ),
                                  routes: [
                                    GoRoute(
                                      path: ':package',
                                      pageBuilder: (context, state) => toolPage(
                                        context,
                                        state,
                                        LicenseScreen(
                                          package:
                                              state.pathParameters['package']!,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                            pageBuilder: (context, state) => toolPage(
                              context,
                              state,
                              switch (tool) {
                                Tool.basic => const BasicSettingsScreen(),
                                Tool.advanced => const AdvancedSettingsScreen(),
                                Tool.about => const AboutScreen(),
                                Tool.apps => const AppsScreen(),
                                Tool.geo => const RulesScreen(),
                                Tool.connections => const ConnectionsScreen(),
                                Tool.logs => const LogsScreen(),
                                Tool.tailscale => const TailscaleScreen(),
                                Tool.cloud => const CloudScreen(),
                              },
                            ),
                          ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      // Forms open above the shell, whatever page asked for them.
      GoRoute(
        path: Routes.add,
        pageBuilder: (context, state) => form(context, state, null),
      ),
      GoRoute(
        path: '/edit/:kind/:id',
        pageBuilder: (context, state) => form(
          context,
          state,
          EditTarget(
            EditKind.values.byName(state.pathParameters['kind']!),
            state.pathParameters['id']!,
          ),
        ),
      ),
      GoRoute(
        path: Routes.override,
        pageBuilder: (context, state) => modal<void>(
          context,
          state,
          (scroll) => OverrideScreen(scrollController: scroll),
        ),
      ),
      GoRoute(
        path: Routes.generated,
        pageBuilder: (context, state) => modal<void>(
          context,
          state,
          (scroll) => GeneratedScreen(scrollController: scroll),
        ),
      ),
    ],
  );
}
