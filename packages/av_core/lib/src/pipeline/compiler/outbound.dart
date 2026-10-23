import '../../domain/node.dart';
import '../../domain/node_keys.dart';

/// A node the plan cannot express (e.g. SOCKS5 over TLS, unsupported by the
/// core per D84); the node is unavailable rather than silently changed.
final class UnsupportedNode implements Exception {
  const UnsupportedNode(this.reason);

  final String reason;
}

/// sing-box outbound for a node (CONFIG_PIPELINE §6). Secrets stay [Secret]
/// objects in the tree.
Map<String, Object?> nodeOutbound({
  required String tag,
  required String server,
  required int port,
  required NodeParams params,
  String? detour,
}) {
  final out = <String, Object?>{
    'type': _type(params),
    'tag': tag,
    'server': server,
    if (port > 0) 'server_port': port,
  };
  switch (params) {
    case Hysteria2Params(
      :final password,
      :final obfsPassword,
      :final upMbps,
      :final downMbps,
      :final serverPorts,
      :final tls,
    ):
      out.addAll({
        if (serverPorts.isNotEmpty) 'server_ports': serverPorts,
        'up_mbps': ?upMbps,
        'down_mbps': ?downMbps,
        if (obfsPassword != null)
          'obfs': {'type': 'salamander', 'password': obfsPassword},
        'password': password,
        'tls': _tls(tls),
      });
    case TuicParams(
      :final uuid,
      :final password,
      :final congestionControl,
      :final udpRelayMode,
      :final tls,
    ):
      out.addAll({
        'uuid': uuid,
        'password': password,
        'congestion_control': congestionControl,
        'udp_relay_mode': ?udpRelayMode,
        'tls': _tls(tls),
      });
    case VlessParams(:final uuid, :final flow, :final transport, :final tls):
      out.addAll({
        'uuid': uuid,
        'flow': ?flow,
        if (tls != null) 'tls': _tls(tls),
        ...?_transport(transport),
      });
    case VmessParams(
      :final uuid,
      :final alterId,
      :final cipher,
      :final transport,
      :final tls,
    ):
      out.addAll({
        'uuid': uuid,
        'security': cipher,
        'alter_id': alterId,
        if (tls != null) 'tls': _tls(tls),
        ...?_transport(transport),
      });
    case TrojanParams(:final password, :final transport, :final tls):
      out.addAll({
        'password': password,
        'tls': _tls(tls),
        ...?_transport(transport),
      });
    case ShadowsocksParams(
      :final method,
      :final password,
      :final plugin,
      :final pluginOpts,
    ):
      // The core refuses the whole plan over a malformed 2022 key.
      if (!NodeKeys.shadowsocksPassword(method, password.value)) {
        throw const UnsupportedNode('shadowsocks-key');
      }
      out.addAll({
        'method': method,
        'password': password,
        'plugin': ?plugin,
        'plugin_opts': ?pluginOpts,
      });
    case Socks5Params(:final username, :final password, :final tls):
      // sing-box's SOCKS outbound has no TLS (S5 confirms); do not drop it.
      if (tls != null) throw const UnsupportedNode('socks-tls');
      out.addAll({
        'version': '5',
        'username': ?username,
        'password': ?password,
      });
    case AnyTlsParams(
      :final password,
      :final idleSessionCheckInterval,
      :final tls,
    ):
      out.addAll({
        'password': password,
        'idle_session_check_interval': ?idleSessionCheckInterval,
        'tls': _tls(tls),
      });
    case HttpParams(:final username, :final password, :final tls):
      out.addAll({
        'username': ?username,
        'password': ?password,
        if (tls != null) 'tls': _tls(tls),
      });
  }
  if (detour != null) out['detour'] = detour;
  return out;
}

String _type(NodeParams p) => switch (p) {
  Hysteria2Params() => 'hysteria2',
  TuicParams() => 'tuic',
  VlessParams() => 'vless',
  VmessParams() => 'vmess',
  TrojanParams() => 'trojan',
  ShadowsocksParams() => 'shadowsocks',
  Socks5Params() => 'socks',
  AnyTlsParams() => 'anytls',
  HttpParams() => 'http',
};

Map<String, Object?> _tls(Tls t) {
  // The core refuses the whole plan over a malformed Reality key.
  if (t.reality case final r?) {
    if (!NodeKeys.realityPublicKey(r.publicKey)) {
      throw const UnsupportedNode('reality-key');
    }
    if (r.shortId case final id? when !NodeKeys.realityShortId(id)) {
      throw const UnsupportedNode('reality-short-id');
    }
  }
  // Reality needs a uTLS fingerprint.
  final fingerprint = t.fingerprint ?? (t.reality != null ? 'chrome' : null);
  return {
    'enabled': true,
    'server_name': ?t.serverName,
    if (t.insecure) 'insecure': true,
    if (t.alpn.isNotEmpty) 'alpn': t.alpn,
    if (fingerprint != null)
      'utls': {'enabled': true, 'fingerprint': fingerprint},
    if (t.reality case final r?)
      'reality': {
        'enabled': true,
        'public_key': r.publicKey,
        'short_id': ?r.shortId,
      },
  };
}

Map<String, Object?>? _transport(Transport t) => switch (t) {
  TcpTransport() => null,
  WsTransport(
    :final path,
    :final host,
    :final maxEarlyData,
    :final earlyDataHeader,
  ) =>
    {
      'transport': {
        'type': 'ws',
        'path': path,
        if (host != null) 'headers': {'Host': host},
        if (maxEarlyData > 0) 'max_early_data': maxEarlyData,
        'early_data_header_name': ?earlyDataHeader,
      },
    },
  GrpcTransport(:final serviceName) => {
    'transport': {'type': 'grpc', 'service_name': serviceName},
  },
  Http2Transport(:final path, :final host) => {
    'transport': {
      'type': 'http',
      'path': path,
      if (host.isNotEmpty) 'host': host,
    },
  },
};
