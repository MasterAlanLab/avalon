import 'package:flutter/foundation.dart';

@immutable
final class HostTailnetPeer {
  const HostTailnetPeer({
    required this.id,
    required this.name,
    required this.os,
    required this.ips,
    required this.online,
    required this.exitCapable,
  });

  factory HostTailnetPeer.fromJson(Map<String, Object?> json) =>
      HostTailnetPeer(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        os: json['os'] as String? ?? '',
        ips: List.unmodifiable(
          (json['ips'] as List? ?? const []).cast<String>(),
        ),
        online: json['online'] == true,
        exitCapable: json['exitCapable'] == true,
      );
  final String id, name, os;
  final List<String> ips;
  final bool online, exitCapable;
}

@immutable
final class HostTailnetStatus {
  const HostTailnetStatus({
    this.state = 'disabled',
    this.tailnet = '',
    this.loginUrl,
    this.self,
    this.peers = const [],
  });

  factory HostTailnetStatus.fromJson(Map<String, Object?> json) =>
      HostTailnetStatus(
        state: json['state'] as String? ?? 'disabled',
        tailnet: json['tailnet'] as String? ?? '',
        loginUrl: json['loginUrl'] as String?,
        self: json['self'] is Map
            ? HostTailnetPeer.fromJson(
                (json['self'] as Map).cast<String, Object?>(),
              )
            : null,
        peers: List.unmodifiable([
          for (final item in json['peers'] as List? ?? const [])
            HostTailnetPeer.fromJson((item as Map).cast<String, Object?>()),
        ]),
      );
  final String state, tailnet;
  final String? loginUrl;
  final HostTailnetPeer? self;
  final List<HostTailnetPeer> peers;
  bool get connected => state == 'Running';
  bool get needsLogin => state == 'NeedsLogin' || state == 'NoState';
}

/// What the host answers, as the Core Bridge defines it (RUNTIME_HOST §2,
/// §6). These mirror `core/bridge/protocol.go`; unknown fields are ignored
/// so that a newer host can add some (RUNTIME_HOST §3.1).

/// Version of the messages this app speaks.
const hostProtocolVersion = 1;

enum HostState {
  stopped,
  starting,
  running,
  reloading,
  stopping,
  failed;

  static HostState parse(Object? name) => values.firstWhere(
    (state) => state.name == name,
    orElse: () => HostState.stopped,
  );
}

/// Why a command failed. The first seven are the bridge's codes; the last
/// is the app's own, for a host that did not answer at all.
enum HostErrorCode {
  planInvalid('PLAN_INVALID'),
  portInUse('PORT_IN_USE'),
  permissionDenied('PERMISSION_DENIED'),
  sessionMismatch('SESSION_MISMATCH'),
  coreFailed('CORE_FAILED'),
  timeout('TIMEOUT'),
  unsupported('UNSUPPORTED'),
  unreachable('HOST_UNREACHABLE');

  const HostErrorCode(this.wire);

  final String wire;

  static HostErrorCode parse(Object? wire) => values.firstWhere(
    (code) => code.wire == wire,
    orElse: () => HostErrorCode.coreFailed,
  );
}

@immutable
final class HostError {
  const HostError(this.code, this.message, {this.detail});

  factory HostError.fromJson(Map<String, Object?> json) => HostError(
    HostErrorCode.parse(json['code']),
    json['message'] as String? ?? '',
    detail: json['detail'] as String?,
  );

  final HostErrorCode code;

  /// The core's own words (English). Shown as a detail, never alone.
  final String message;
  final String? detail;

  @override
  String toString() => 'HostError(${code.wire}: $message)';
}

final class HostException implements Exception {
  const HostException(this.error);

  final HostError error;

  @override
  String toString() => 'HostException(${error.code.wire}: ${error.message})';
}

@immutable
final class HostCapabilities {
  const HostCapabilities({
    required this.protocolVersion,
    required this.coreVersion,
    required this.platform,
    this.publicNetworkVersion = 0,
  });

  factory HostCapabilities.fromJson(Map<String, Object?> json) =>
      HostCapabilities(
        protocolVersion: (json['protocolVersion'] as num?)?.toInt() ?? 0,
        coreVersion: json['coreVersion'] as String? ?? '',
        platform: json['platform'] as String? ?? '',
        publicNetworkVersion:
            (json['publicNetworkVersion'] as num?)?.toInt() ?? 0,
      );

  final int protocolVersion;
  final String coreVersion;
  final String platform;
  final int publicNetworkVersion;
}

/// A started or reloaded session.
@immutable
final class HostSession {
  const HostSession(this.sessionId, {this.restarted = false});

  factory HostSession.fromJson(Map<String, Object?> json) => HostSession(
    json['sessionId'] as String? ?? '',
    restarted: json['method'] == 'restart',
  );

  final String sessionId;

  /// The reload stopped the core and started it again: connections were
  /// dropped (always so with sing-box 1.14, D82).
  final bool restarted;
}

/// The observable state of the host (RUNTIME_HOST §6).
@immutable
final class HostSnapshot {
  const HostSnapshot({
    this.sessionId = '',
    this.revision = 0,
    this.state = HostState.stopped,
    this.proxyActive,
    this.tailnetActive,
    this.tunActive,
    this.systemProxyActive,
    this.clashApiListen,
    this.startedAt,
    this.planHash = '',
    this.mode = '',
    this.selections = const {},
    this.upBps = 0,
    this.downBps = 0,
    this.upTotal = 0,
    this.downTotal = 0,
    this.todayUp = 0,
    this.todayDown = 0,
    this.error,
  });

  factory HostSnapshot.fromJson(Map<String, Object?> json) {
    int number(String key) => (json[key] as num?)?.toInt() ?? 0;
    final error = json['error'];
    return HostSnapshot(
      sessionId: json['sessionId'] as String? ?? '',
      revision: number('revision'),
      state: HostState.parse(json['state']),
      proxyActive: json['proxyActive'] as bool?,
      tailnetActive: json['tailnetActive'] as bool?,
      tunActive: json['tunActive'] as bool?,
      systemProxyActive: json['systemProxyActive'] as bool?,
      clashApiListen: json['clashApiListen'] as String?,
      startedAt: number('startedAt') == 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(number('startedAt')),
      planHash: json['planHash'] as String? ?? '',
      mode: json['mode'] as String? ?? '',
      selections: {
        for (final entry in (json['selections'] as Map? ?? const {}).entries)
          entry.key as String: entry.value as String,
      },
      upBps: number('upBps'),
      downBps: number('downBps'),
      upTotal: number('upTotal'),
      downTotal: number('downTotal'),
      todayUp: number('todayUp'),
      todayDown: number('todayDown'),
      error: error is Map ? HostError.fromJson(error.cast()) : null,
    );
  }

  final String sessionId;

  /// Grows with every snapshot of a host; an older one is dropped.
  final int revision;
  final HostState state;

  /// Facts of the accepted session, not the device's saved preferences.
  /// Null means an older host does not report this field.
  final bool? proxyActive;
  final bool? tailnetActive;
  final bool? tunActive;
  final bool? systemProxyActive;

  /// Accepted controller address without its secret. Empty when off;
  /// null when an older host does not report it.
  final String? clashApiListen;

  /// When the session started running; null unless running.
  final DateTime? startedAt;

  /// Only while running.
  final String planHash;

  /// As the core spells it: compare ignoring case (RUNTIME_HOST §5).
  final String mode;

  /// What each group uses now, by tag.
  final Map<String, String> selections;
  final int upBps;
  final int downBps;

  /// Since the session started.
  final int upTotal;
  final int downTotal;

  /// Since local midnight, across sessions.
  final int todayUp;
  final int todayDown;
  final HostError? error;
}

/// What a download through an outbound got (RUNTIME_HOST §2 `fetch`).
@immutable
final class HostFetch {
  const HostFetch({required this.status, this.size = 0, this.body});

  factory HostFetch.fromJson(Map<String, Object?> json) => HostFetch(
    status: (json['status'] as num?)?.toInt() ?? 0,
    size: (json['size'] as num?)?.toInt() ?? 0,
    body: json['body'] as String?,
  );

  final int status;
  final int size;

  /// The body, when it was not written to a file.
  final String? body;
}

/// How long an outbound took to answer a latency test, or why it did not.
@immutable
final class HostLatency {
  const HostLatency({this.delayMs, this.error});

  factory HostLatency.fromJson(Map<String, Object?> json) => HostLatency(
    delayMs: (json['delayMs'] as num?)?.toInt(),
    error: json['error'] as String?,
  );

  /// Null when the test failed.
  final int? delayMs;

  /// `timeout`, or what the core said.
  final String? error;

  bool get timedOut => error == 'timeout';
}

@immutable
final class HostLogEntry {
  const HostLogEntry(this.seq, this.level, this.message, {this.time});

  final int seq;

  /// `trace`, `debug`, `info`, `warn`, `error`, `fatal` or `panic`.
  final String level;
  final String message;

  /// When the host received the line.
  final DateTime? time;
}

/// One active connection of the running session (PRODUCT_SPEC §3.8).
@immutable
final class HostConnection {
  const HostConnection({
    required this.id,
    required this.host,
    this.network = '',
    this.process = '',
    this.rule = '',
    this.chain = const [],
    this.upload = 0,
    this.download = 0,
    this.createdAt,
  });

  factory HostConnection.fromJson(Map<String, Object?> json) {
    final created = (json['createdAt'] as num?)?.toInt() ?? 0;
    return HostConnection(
      id: json['id'] as String? ?? '',
      host: json['host'] as String? ?? '',
      network: json['network'] as String? ?? '',
      process: json['process'] as String? ?? '',
      rule: json['rule'] as String? ?? '',
      chain: [...(json['chain'] as List? ?? const []).cast<String>()],
      upload: (json['upload'] as num?)?.toInt() ?? 0,
      download: (json['download'] as num?)?.toInt() ?? 0,
      createdAt: created == 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(created),
    );
  }

  final String id;

  /// Domain or address, with port.
  final String host;
  final String network;

  /// Android package or program file name; empty when unknown.
  final String process;

  /// The rule as the core writes it; empty for the final target.
  final String rule;

  /// Outbound tags from the rule's target through groups to the exit.
  final List<String> chain;
  final int upload;
  final int download;
  final DateTime? createdAt;
}

@immutable
final class HostLogPage {
  const HostLogPage({
    this.entries = const [],
    this.nextSeq = 0,
    this.dropped = 0,
  });

  factory HostLogPage.fromJson(Map<String, Object?> json) => HostLogPage(
    entries: [
      for (final entry
          in (json['entries'] as List? ?? const [])
              .cast<Map<String, Object?>>())
        HostLogEntry(
          (entry['seq'] as num).toInt(),
          entry['level'] as String? ?? '',
          entry['message'] as String? ?? '',
          time: (entry['time'] as num?) == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(
                  (entry['time']! as num).toInt(),
                ),
        ),
    ],
    nextSeq: (json['nextSeq'] as num?)?.toInt() ?? 0,
    dropped: (json['dropped'] as num?)?.toInt() ?? 0,
  );

  final List<HostLogEntry> entries;

  /// Pass as `afterSeq` to read on.
  final int nextSeq;

  /// Lines that fell out of the host's buffer before they were read.
  final int dropped;
}
