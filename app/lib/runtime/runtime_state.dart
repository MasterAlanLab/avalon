import 'package:av_core/av_core.dart';
import 'package:flutter/foundation.dart';

import '../services/plan_service.dart';
import 'host_protocol.dart';

/// Where the session is, as the app sees it (RUNTIME_HOST §4).
enum RuntimePhase { stopped, starting, running, reloading, stopping }

/// Why the proxy is not running although it was asked to.
sealed class RuntimeFailure {
  const RuntimeFailure();
}

/// The system's consent (the VPN) was refused.
final class PermissionRefused extends RuntimeFailure {
  const PermissionRefused();
}

/// Nothing to run: no configuration, or one not downloaded yet.
final class NothingToRun extends RuntimeFailure {
  const NothingToRun(this.reason);

  final PlanUnavailable reason;
}

/// The plan could not be compiled.
final class PlanFailed extends RuntimeFailure {
  const PlanFailed(this.error);

  final CompileException error;
}

/// Per-app proxy lets only the listed apps through and none of them is
/// installed: the system would put every app through the tunnel instead
/// (PRODUCT_SPEC §3.11).
final class NoListedAppInstalled extends RuntimeFailure {
  const NoListedAppInstalled();
}

/// The host refused or failed.
final class HostFailed extends RuntimeFailure {
  const HostFailed(this.error);

  final HostError error;
}

@immutable
final class RuntimeState {
  const RuntimeState({
    this.available = true,
    this.phase = RuntimePhase.stopped,
    this.snapshot = const HostSnapshot(),
    this.failure,
    this.coreVersion = '',
    this.speeds = const [],
    this.tags = const {},
    this.activeMixedPort,
    this.activeProxyTun,
    this.pendingTun,
    this.pendingSystemProxy,
  });

  /// False where this platform's host is not built yet.
  final bool available;
  final RuntimePhase phase;

  /// The host's last report.
  final HostSnapshot snapshot;

  /// Set when the last attempt to run failed; cleared by the next.
  final RuntimeFailure? failure;

  /// The core the host runs, once known.
  final String coreVersion;

  /// Download speed of the last seconds, oldest first, in bytes per
  /// second; for the dashboard's chart.
  final List<int> speeds;

  /// What the tags in [snapshot] stand for: the running plan's map from
  /// outbound tags back to members (CONFIG_PIPELINE §7). Empty until the
  /// plan is known (just after adopting a session).
  final Map<String, PlanTag> tags;

  /// From the last accepted plan; null while an adopted session has not
  /// been matched to its compiled plan. Preferences cannot attest it.
  final int? activeMixedPort;

  /// Whether the last accepted plan includes the proxy's TUN inbound.
  /// A Tailnet-only route still has a native TUN, independently of this.
  final bool? activeProxyTun;

  bool? get proxyTunActive {
    final native = snapshot.tunActive;
    if (native != true) return native;
    if (activeProxyTun != null) return activeProxyTun;
    // Match an adopted Tailnet session to its accepted plan before
    // interpreting the shared native tunnel as proxy traffic capture.
    return snapshot.tailnetActive == true ? null : native;
  }

  /// A device switch changed while a session is running. The preference is
  /// shown immediately while the host reloads; the coordinator clears it
  /// after the reload has either been accepted or rejected.
  final bool? pendingTun;
  final bool? pendingSystemProxy;

  /// The proxy carries traffic (a reload interrupts it for a moment).
  bool get connected =>
      phase == RuntimePhase.running || phase == RuntimePhase.reloading;

  /// A Tailnet-only session does not turn the dashboard proxy on.
  bool get proxyConnected => connected && (snapshot.proxyActive ?? true);

  /// Something is under way; the switch waits for it.
  bool get busy =>
      phase == RuntimePhase.starting ||
      phase == RuntimePhase.stopping ||
      phase == RuntimePhase.reloading;

  RuntimeState copyWith({
    RuntimePhase? phase,
    HostSnapshot? snapshot,
    RuntimeFailure? Function()? failure,
    String? coreVersion,
    List<int>? speeds,
    Map<String, PlanTag>? tags,
    int? Function()? activeMixedPort,
    bool? Function()? activeProxyTun,
    bool? Function()? pendingTun,
    bool? Function()? pendingSystemProxy,
  }) => RuntimeState(
    available: available,
    phase: phase ?? this.phase,
    snapshot: snapshot ?? this.snapshot,
    failure: failure == null ? this.failure : failure(),
    coreVersion: coreVersion ?? this.coreVersion,
    speeds: speeds ?? this.speeds,
    tags: tags ?? this.tags,
    activeMixedPort: activeMixedPort == null
        ? this.activeMixedPort
        : activeMixedPort(),
    activeProxyTun: activeProxyTun == null
        ? this.activeProxyTun
        : activeProxyTun(),
    pendingTun: pendingTun == null ? this.pendingTun : pendingTun(),
    pendingSystemProxy: pendingSystemProxy == null
        ? this.pendingSystemProxy
        : pendingSystemProxy(),
  );
}
