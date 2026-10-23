import 'package:av_design/av_design.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_error.dart';
import '../../app/layout.dart';
import '../../app/routes.dart';
import '../../l10n/app_localizations.dart';
import 'dashboard_state.dart';
import 'dashboard_view.dart';
import 'dashboard_view_model.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  /// Without a configuration there is nothing to start: say so and go to
  /// the configurations page (PRODUCT_SPEC §3.1). Where this platform has
  /// no host yet, say that.
  void _power(BuildContext context, WidgetRef ref, DashboardState state) {
    final l = AppLocalizations.of(context);
    HapticFeedback.lightImpact();
    if (state.connected || state.status == ConnectionStatus.connecting) {
      ref.read(dashboardViewModelProvider).togglePower();
      return;
    }
    if (!state.hasConfiguration) {
      showAvToast(context, l.addConfigurationFirst);
      context.go(Routes.configurations);
      return;
    }
    if (state.status == ConnectionStatus.unavailable) {
      showAvNotice(
        context,
        title: l.coreNotConnected,
        message: l.coreNotConnectedNote,
        ok: l.ok,
      );
      return;
    }
    ref.read(dashboardViewModelProvider).togglePower();
  }

  /// A failure is said once, with its detail; the page keeps a line of it.
  void _explain(BuildContext context, DashboardState state) {
    final l = AppLocalizations.of(context);
    final title = dashboardFailureText(l, state.failure);
    if (title == null) return;
    final planError = state.planError;
    final detail = switch (state.failure) {
      ConnectionFailure.permissionRefused => l.runtimePermissionRefusedNote,
      ConnectionFailure.noListedAppInstalled =>
        l.runtimeNoListedAppInstalledNote,
      ConnectionFailure.planFailed when planError != null => compileErrorText(
        l,
        planError,
      ),
      _ => state.failureDetail,
    };
    showAvNotice(context, title: title, message: detail ?? '', ok: l.ok);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardStateProvider);
    final model = ref.read(dashboardViewModelProvider);
    ref.listen(dashboardStateProvider.select((s) => s.failure), (_, failure) {
      if (failure != null) _explain(context, ref.read(dashboardStateProvider));
    });
    return DashboardView(
      state: state,
      platform: AppPlatform.host,
      onPower: () => _power(context, ref, state),
      onMode: model.setMode,
      onTun: model.setTun,
      onSystemProxy: model.setSystemProxy,
      onExit: () => context.go(Routes.proxies),
    );
  }
}
