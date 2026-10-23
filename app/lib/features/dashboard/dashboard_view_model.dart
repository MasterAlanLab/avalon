import 'package:av_core/av_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/desktop_proxy_controller.dart';
import '../../app/providers.dart';
import '../../app/selected_configuration.dart';
import '../../runtime/actual_selections.dart';
import '../../runtime/exit_ip_probe.dart';
import '../../runtime/host_protocol.dart';
import '../../runtime/latency.dart';
import '../../runtime/runtime_coordinator.dart';
import '../../runtime/runtime_state.dart';
import '../../services/plan_service.dart';
import 'dashboard_state.dart';

/// The page: what is selected and set, with the connection folded in.
final dashboardStateProvider = Provider.autoDispose<DashboardState>((ref) {
  final runtime = ref.watch(runtimeProvider);
  final desktopProxy = ref.watch(desktopProxyProvider);
  final page = ref.watch(_selectionStateProvider);
  final snapshot = runtime.snapshot;
  final started = snapshot.startedAt;
  final (failure, detail, planError) = _failure(runtime.failure);
  final exitIp = ref.watch(exitIpProvider);
  return page.withConnection(
    // Disconnected switches configure the next start; while connected
    // they reflect the host, including a rejected settings change that
    // leaves the old session carrying traffic.
    tunEnabled: runtime.proxyConnected
        ? runtime.pendingTun ?? runtime.proxyTunActive ?? false
        : null,
    systemProxy: runtime.proxyConnected
        ? (desktopProxy.managed
              ? desktopProxy.active
              : runtime.pendingSystemProxy ??
                    snapshot.systemProxyActive ??
                    false)
        : null,
    tunKnown:
        !runtime.proxyConnected ||
        runtime.pendingTun != null ||
        runtime.proxyTunActive != null,
    systemProxyKnown:
        !runtime.proxyConnected ||
        (desktopProxy.managed
            ? desktopProxy.known
            : runtime.pendingSystemProxy != null ||
                  snapshot.systemProxyActive != null),
    status: !runtime.available
        ? ConnectionStatus.unavailable
        : switch (runtime.phase) {
            RuntimePhase.stopped => ConnectionStatus.disconnected,
            RuntimePhase.starting => ConnectionStatus.connecting,
            RuntimePhase.running =>
              runtime.proxyConnected
                  ? ConnectionStatus.connected
                  : ConnectionStatus.disconnected,
            RuntimePhase.reloading =>
              runtime.proxyConnected
                  ? ConnectionStatus.reconnecting
                  : ConnectionStatus.disconnected,
            RuntimePhase.stopping => ConnectionStatus.disconnecting,
          },
    connectedFor: runtime.proxyConnected && started != null
        ? DateTime.now().difference(started)
        : null,
    upBps: runtime.proxyConnected ? snapshot.upBps : 0,
    downBps: runtime.proxyConnected ? snapshot.downBps : 0,
    speeds: runtime.speeds,
    todayUp: runtime.available ? snapshot.todayUp : null,
    todayDown: runtime.available ? snapshot.todayDown : null,
    coreVersion: runtime.coreVersion,
    failure:
        failure ?? (desktopProxy.failed ? ConnectionFailure.systemProxy : null),
    failureDetail: detail,
    planError: planError,
    exitAddress: exitIp?.ip,
    exitLocation: exitIp?.location,
  );
});

(ConnectionFailure?, String?, CompileException?) _failure(
  RuntimeFailure? failure,
) => switch (failure) {
  null => (null, null, null),
  PermissionRefused() => (ConnectionFailure.permissionRefused, null, null),
  NoListedAppInstalled() => (
    ConnectionFailure.noListedAppInstalled,
    null,
    null,
  ),
  NothingToRun(:final reason) => (
    reason == PlanUnavailable.notDownloaded
        ? ConnectionFailure.notDownloaded
        : ConnectionFailure.nothingSelected,
    null,
    null,
  ),
  PlanFailed(:final error) => (ConnectionFailure.planFailed, null, error),
  HostFailed(:final error) => (
    switch (error.code) {
      HostErrorCode.unreachable => ConnectionFailure.hostUnreachable,
      HostErrorCode.portInUse => ConnectionFailure.portInUse,
      HostErrorCode.planInvalid => ConnectionFailure.planRefused,
      HostErrorCode.permissionDenied => ConnectionFailure.permissionRefused,
      HostErrorCode.timeout => ConnectionFailure.timeout,
      _ => ConnectionFailure.coreFailed,
    },
    error.message,
    null,
  ),
};

/// What is selected and how it is set, without the connection.
final _selectionStateProvider = Provider.autoDispose<DashboardState>((ref) {
  final settings = ref.watch(deviceSettingsProvider).value;
  if (settings == null) return const DashboardState(loading: true);
  final base = DashboardState(
    mode: settings.mode,
    tunEnabled: settings.tunEnabled,
    systemProxy: settings.systemProxy,
  );
  switch (ref.watch(selectedConfigurationProvider)) {
    case SelectionLoading():
      return const DashboardState(loading: true);
    case NothingSelected():
      return DashboardState(
        hasConfiguration: false,
        mode: base.mode,
        tunEnabled: base.tunEnabled,
        systemProxy: base.systemProxy,
      );
    case NotDownloaded() || SelectionFailed():
      return base;
    case SelectionReady(
      :final configuration,
      :final catalog,
      :final selections,
    ):
      // While connected, what the host actually uses: through groups that
      // pick by latency down to the node itself.
      final actual = ref.watch(actualSelectionsProvider);
      final primary = MemberRef.source(
        configurationId: configuration.id,
        key: catalog.primaryKey,
      );
      final exit = actual.of(primary) == null
          ? catalog.exit(selections)
          : actual.resolve(primary);
      final latency = exit == null
          ? null
          : ref.watch(
              latencyProvider.select((all) => all[(configuration.id, exit)]),
            );
      return DashboardState(
        mode: base.mode,
        tunEnabled: base.tunEnabled,
        systemProxy: base.systemProxy,
        exit: exit == null
            ? null
            : _describe(catalog, exit).withLatency(latency),
      );
  }
});

DashboardExit _describe(MemberCatalog catalog, MemberRef ref) {
  final name = catalog.name(ref);
  final unavailable = catalog.unavailable(ref) != null;
  return switch (ref) {
    SourceMember(:final key) when catalog.content.group(key) != null =>
      DashboardExit(
        name: name,
        kind: ExitKind.group,
        groupType: catalog.content.group(key)!.displayType,
      ),
    SourceMember() || SelfNodeRef() => DashboardExit(
      name: name,
      kind: ExitKind.node,
      protocol: catalog.paramsOf(ref)?.protocol,
      unavailable: unavailable,
    ),
    ChainRef(:final id) => DashboardExit(
      name: name,
      kind: ExitKind.chain,
      hops: catalog.chain(id)?.hops.length ?? 0,
      unavailable: unavailable,
    ),
    TailnetExitRef() => DashboardExit(
      name: name,
      kind: ExitKind.tailnet,
      unavailable: unavailable,
    ),
    BuiltinRef(:final builtin) => DashboardExit(
      name: name,
      kind: builtin == Builtin.direct ? ExitKind.direct : ExitKind.reject,
    ),
  };
}

/// Commands of the dashboard. Not auto-disposed: the page reads it while
/// building and calls it when a control is used.
final dashboardViewModelProvider = Provider<DashboardViewModel>(
  DashboardViewModel.new,
);

final class DashboardViewModel {
  DashboardViewModel(this._ref);

  final Ref _ref;

  Future<void> setMode(OutboundMode mode) =>
      _ref.read(outboundModeProvider.notifier).set(mode);

  Future<void> setTun(bool on) =>
      _ref.read(runtimeProvider.notifier).setTunPreference(on);

  Future<void> setSystemProxy(bool on) async {
    await _ref.read(runtimeProvider.notifier).setSystemProxyPreference(on);
    await _ref.read(desktopProxyProvider.notifier).reconcile(force: true);
  }

  /// The power button: start the proxy, or stop it.
  Future<void> togglePower() => _ref.read(runtimeProvider.notifier).toggle();
}
