import 'package:av_core/av_core.dart';

import '../../runtime/latency.dart';

enum ExitKind { node, chain, group, direct, reject, tailnet }

/// What the main exit is (PRODUCT_SPEC §3.1 «当前节点»).
final class DashboardExit {
  const DashboardExit({
    required this.name,
    required this.kind,
    this.protocol,
    this.groupType,
    this.hops = 0,
    this.unavailable = false,
    this.latency,
  });

  final String name;
  final ExitKind kind;
  final Protocol? protocol;

  /// [ExitKind.group]: a group that picks by latency, as imported.
  final String? groupType;
  final int hops;
  final bool unavailable;

  /// Its last latency test; null when never tested.
  final Latency? latency;

  DashboardExit withLatency(Latency? latency) => DashboardExit(
    name: name,
    kind: kind,
    protocol: protocol,
    groupType: groupType,
    hops: hops,
    unavailable: unavailable,
    latency: latency,
  );
}

/// Where the connection is (PRODUCT_SPEC §3.1).
enum ConnectionStatus {
  /// This platform's host is not built yet.
  unavailable,
  disconnected,
  connecting,
  connected,

  /// A reload restarts the core; connections drop for a moment (D82).
  reconnecting,
  disconnecting,
}

/// Why the proxy is not running; the view puts it into words.
enum ConnectionFailure {
  permissionRefused,
  noListedAppInstalled,
  nothingSelected,
  notDownloaded,
  planFailed,
  hostUnreachable,
  portInUse,
  planRefused,
  coreFailed,
  timeout,
  systemProxy,
}

final class DashboardState {
  const DashboardState({
    this.loading = false,
    this.hasConfiguration = true,
    this.mode = OutboundMode.rule,
    this.exit,
    this.tunEnabled = true,
    this.systemProxy = false,
    this.tunKnown = true,
    this.systemProxyKnown = true,
    this.status = ConnectionStatus.unavailable,
    this.connectedFor,
    this.upBps = 0,
    this.downBps = 0,
    this.speeds = const [],
    this.todayUp,
    this.todayDown,
    this.coreVersion = '',
    this.failure,
    this.failureDetail,
    this.planError,
    this.exitAddress,
    this.exitLocation,
  });

  final bool loading;
  final bool hasConfiguration;
  final OutboundMode mode;

  /// Null when the configuration has nothing usable (or none is chosen).
  final DashboardExit? exit;
  final bool tunEnabled;
  final bool systemProxy;
  final bool tunKnown;
  final bool systemProxyKnown;

  /// The same page with the connection's side filled in.
  DashboardState withConnection({
    required ConnectionStatus status,
    bool? tunEnabled,
    bool? systemProxy,
    bool tunKnown = true,
    bool systemProxyKnown = true,
    Duration? connectedFor,
    int upBps = 0,
    int downBps = 0,
    List<int> speeds = const [],
    int? todayUp,
    int? todayDown,
    String coreVersion = '',
    ConnectionFailure? failure,
    String? failureDetail,
    CompileException? planError,
    String? exitAddress,
    String? exitLocation,
  }) => DashboardState(
    loading: loading,
    hasConfiguration: hasConfiguration,
    mode: mode,
    exit: exit,
    tunEnabled: tunEnabled ?? this.tunEnabled,
    systemProxy: systemProxy ?? this.systemProxy,
    tunKnown: tunKnown,
    systemProxyKnown: systemProxyKnown,
    status: status,
    connectedFor: connectedFor,
    upBps: upBps,
    downBps: downBps,
    speeds: speeds,
    todayUp: todayUp,
    todayDown: todayDown,
    coreVersion: coreVersion,
    failure: failure,
    failureDetail: failureDetail,
    planError: planError,
    exitAddress: exitAddress,
    exitLocation: exitLocation,
  );

  final ConnectionStatus status;

  /// Since the session started; null unless connected.
  final Duration? connectedFor;

  /// Bytes per second now.
  final int upBps;
  final int downBps;

  /// Download speed of the last seconds, oldest first.
  final List<int> speeds;

  /// Traffic since local midnight; null while unknown (shown as «—»).
  final int? todayUp;
  final int? todayDown;

  /// The core's version once the host has said it.
  final String coreVersion;
  final ConnectionFailure? failure;

  /// What the core said, to go with [failure].
  final String? failureDetail;

  /// The compiler's error when [failure] is `planFailed`.
  final CompileException? planError;

  /// The exit IP and where it is (CONFIG_PIPELINE §9); null while unknown
  /// (shown as «—»).
  final String? exitAddress;
  final String? exitLocation;

  /// Traffic is carried (a reconnect interrupts it for a moment).
  bool get connected =>
      status == ConnectionStatus.connected ||
      status == ConnectionStatus.reconnecting;
}
