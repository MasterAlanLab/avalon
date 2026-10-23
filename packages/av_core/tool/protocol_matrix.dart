// Writes what core/check_protocols.sh needs to try every protocol against
// a real sing-box server (spike S5): one definition per case gives both the
// server's inbound and the node as Avalon stores it; the client plan is
// what Avalon's compiler makes of those nodes.
//
//   dart run tool/protocol_matrix.dart OUT_DIR MIXED_PORT BASE_PORT \
//       REALITY_PRIVATE REALITY_PUBLIC
//
// OUT_DIR gets server.json (mounted in the container at /etc/s5),
// plan.json and cases.json. It must already hold geosite-cn.srs.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:av_core/av_core.dart';

const _host = 's5.avalon.test';
const _uuid = '11111111-1111-4111-8111-111111111111';
const _password = 'avalon-s5-password';
const _key2022 =
    'MTIzNDU2Nzg5MGFiY2RlZg=='; // 16 bytes for 2022-blake3-aes-128-gcm

final class _Case {
  _Case(
    this.name,
    this.params,
    this.inbound, {
    this.udp = false,
    this.relaysUdp = true,
    this.detour,
    this.hopPorts = 0,
  });

  final String name;
  final NodeParams params;

  /// The server side, without tag and listen fields.
  final Map<String, Object?> inbound;

  /// Carried over QUIC: the port is published as UDP.
  final bool udp;

  /// Whether the protocol relays UDP (an HTTP proxy cannot): the test then
  /// sends a datagram through it too.
  final bool relaysUdp;

  /// Name of the case whose node this one dials through (a chain, as
  /// Clash's `dialer-proxy` makes it).
  final String? detour;

  /// Port hopping: the server listens on this many more ports and the
  /// node knows only that range (`server_ports`). Real servers forward the
  /// range to one port (DNAT); Docker cannot map several host ports to one
  /// container port for UDP, so each port has an inbound of its own. What
  /// is tried is dialing by the range, not a hop mid-connection (every 30
  /// seconds by default).
  final int hopPorts;
}

void main(List<String> args) {
  final out = args[0];
  final mixedPort = int.parse(args[1]);
  final basePort = int.parse(args[2]);
  final realityPrivate = args[3];
  final realityPublic = args[4];

  const serverTls = {
    'enabled': true,
    'server_name': _host,
    'certificate_path': '/etc/s5/cert.pem',
    'key_path': '/etc/s5/key.pem',
  };
  // The server's certificate is self-signed for this run.
  const tls = Tls(serverName: _host, insecure: true);
  const secret = Secret(_password);
  const uuid = Secret(_uuid);
  final users = [
    {'uuid': _uuid},
  ];
  const ws = Transport.ws(path: '/ws');
  const grpc = Transport.grpc(serviceName: 'avalon');
  const h2 = Transport.http2(path: '/h2', host: [_host]);
  const wsServer = {'type': 'ws', 'path': '/ws'};
  const grpcServer = {'type': 'grpc', 'service_name': 'avalon'};
  const h2Server = {
    'type': 'http',
    'path': '/h2',
    'host': [_host],
  };

  // Reality borrows the handshake of a TLS 1.3 server: the plain VLESS
  // inbound below, on the port given to «vless tcp tls».
  late final int handshakePort;

  final cases = <_Case>[
    _Case(
      'shadowsocks aes-256-gcm',
      const NodeParams.shadowsocks(method: 'aes-256-gcm', password: secret),
      {'type': 'shadowsocks', 'method': 'aes-256-gcm', 'password': _password},
    ),
    _Case(
      'shadowsocks 2022-blake3-aes-128-gcm',
      const NodeParams.shadowsocks(
        method: '2022-blake3-aes-128-gcm',
        password: Secret(_key2022),
      ),
      {
        'type': 'shadowsocks',
        'method': '2022-blake3-aes-128-gcm',
        'password': _key2022,
      },
    ),
    _Case('vmess tcp', const NodeParams.vmess(uuid: uuid), {
      'type': 'vmess',
      'users': users,
    }),
    _Case('vmess ws', const NodeParams.vmess(uuid: uuid, transport: ws), {
      'type': 'vmess',
      'users': users,
      'transport': wsServer,
    }),
    _Case(
      'vmess ws tls',
      const NodeParams.vmess(uuid: uuid, transport: ws, tls: tls),
      {
        'type': 'vmess',
        'users': users,
        'transport': wsServer,
        'tls': serverTls,
      },
    ),
    _Case(
      'vmess grpc tls',
      const NodeParams.vmess(uuid: uuid, transport: grpc, tls: tls),
      {
        'type': 'vmess',
        'users': users,
        'transport': grpcServer,
        'tls': serverTls,
      },
    ),
    _Case(
      'vmess http2 tls',
      const NodeParams.vmess(uuid: uuid, transport: h2, tls: tls),
      {
        'type': 'vmess',
        'users': users,
        'transport': h2Server,
        'tls': serverTls,
      },
    ),
    _Case('vless tcp tls', const NodeParams.vless(uuid: uuid, tls: tls), {
      'type': 'vless',
      'users': users,
      'tls': serverTls,
    }),
    _Case(
      'vless tcp tls vision',
      const NodeParams.vless(uuid: uuid, flow: 'xtls-rprx-vision', tls: tls),
      {
        'type': 'vless',
        'users': [
          {'uuid': _uuid, 'flow': 'xtls-rprx-vision'},
        ],
        'tls': serverTls,
      },
    ),
    _Case(
      'vless tcp reality vision',
      NodeParams.vless(
        uuid: uuid,
        flow: 'xtls-rprx-vision',
        tls: Tls(
          serverName: _host,
          fingerprint: 'chrome',
          reality: Reality(publicKey: realityPublic, shortId: '0a1b'),
        ),
      ),
      {
        'type': 'vless',
        'users': [
          {'uuid': _uuid, 'flow': 'xtls-rprx-vision'},
        ],
        'tls': {
          'enabled': true,
          'server_name': _host,
          'reality': {
            'enabled': true,
            'handshake': {'server': '127.0.0.1', 'server_port': 0},
            'private_key': realityPrivate,
            'short_id': ['0a1b'],
          },
        },
      },
    ),
    _Case(
      'vless ws tls',
      const NodeParams.vless(uuid: uuid, transport: ws, tls: tls),
      {
        'type': 'vless',
        'users': users,
        'transport': wsServer,
        'tls': serverTls,
      },
    ),
    _Case(
      'vless grpc tls',
      const NodeParams.vless(uuid: uuid, transport: grpc, tls: tls),
      {
        'type': 'vless',
        'users': users,
        'transport': grpcServer,
        'tls': serverTls,
      },
    ),
    _Case(
      'vless http2 tls',
      const NodeParams.vless(uuid: uuid, transport: h2, tls: tls),
      {
        'type': 'vless',
        'users': users,
        'transport': h2Server,
        'tls': serverTls,
      },
    ),
    _Case(
      'trojan tcp tls',
      const NodeParams.trojan(password: secret, tls: tls),
      {
        'type': 'trojan',
        'users': [
          {'password': _password},
        ],
        'tls': serverTls,
      },
    ),
    _Case(
      'trojan ws tls',
      const NodeParams.trojan(password: secret, transport: ws, tls: tls),
      {
        'type': 'trojan',
        'users': [
          {'password': _password},
        ],
        'transport': wsServer,
        'tls': serverTls,
      },
    ),
    _Case(
      'trojan grpc tls',
      const NodeParams.trojan(password: secret, transport: grpc, tls: tls),
      {
        'type': 'trojan',
        'users': [
          {'password': _password},
        ],
        'transport': grpcServer,
        'tls': serverTls,
      },
    ),
    _Case('hysteria2', const NodeParams.hysteria2(password: secret, tls: tls), {
      'type': 'hysteria2',
      'users': [
        {'password': _password},
      ],
      'tls': serverTls,
    }, udp: true),
    _Case(
      'hysteria2 obfs',
      const NodeParams.hysteria2(
        password: secret,
        obfsPassword: Secret('avalon-s5-obfs'),
        tls: tls,
      ),
      {
        'type': 'hysteria2',
        'users': [
          {'password': _password},
        ],
        'obfs': {'type': 'salamander', 'password': 'avalon-s5-obfs'},
        'tls': serverTls,
      },
      udp: true,
    ),
    _Case(
      'tuic',
      const NodeParams.tuic(
        uuid: uuid,
        password: secret,
        tls: Tls(serverName: _host, insecure: true, alpn: ['h3']),
      ),
      {
        'type': 'tuic',
        'users': [
          {'uuid': _uuid, 'password': _password},
        ],
        'congestion_control': 'bbr',
        'tls': {
          ...serverTls,
          'alpn': ['h3'],
        },
      },
      udp: true,
    ),
    _Case('anytls', const NodeParams.anytls(password: secret, tls: tls), {
      'type': 'anytls',
      'users': [
        {'password': _password},
      ],
      'tls': serverTls,
    }),
    // SOCKS5 relays UDP on a port the server picks as it answers, which
    // Docker does not publish: only TCP is tried here.
    _Case('socks5', const NodeParams.socks5(), {
      'type': 'socks',
    }, relaysUdp: false),
    _Case(
      'socks5 with a password',
      const NodeParams.socks5(username: 'avalon', password: secret),
      {
        'type': 'socks',
        'users': [
          {'username': 'avalon', 'password': _password},
        ],
      },
      relaysUdp: false,
    ),
    _Case(
      'http with a password',
      const NodeParams.http(username: 'avalon', password: secret),
      {
        'type': 'http',
        'users': [
          {'username': 'avalon', 'password': _password},
        ],
      },
      relaysUdp: false,
    ),
    _Case(
      'http tls',
      const NodeParams.http(username: 'avalon', password: secret, tls: tls),
      {
        'type': 'http',
        'users': [
          {'username': 'avalon', 'password': _password},
        ],
        'tls': serverTls,
      },
      relaysUdp: false,
    ),
    // WebSocket early data: the first bytes ride in the upgrade request.
    _Case(
      'vmess ws early data',
      const NodeParams.vmess(
        uuid: uuid,
        transport: Transport.ws(
          path: '/ws',
          maxEarlyData: 2048,
          earlyDataHeader: 'Sec-WebSocket-Protocol',
        ),
      ),
      {
        'type': 'vmess',
        'users': users,
        'transport': {
          ...wsServer,
          'max_early_data': 2048,
          'early_data_header_name': 'Sec-WebSocket-Protocol',
        },
      },
    ),
    // Port hopping: the node knows only the published range.
    _Case(
      'hysteria2 port hopping',
      const NodeParams.hysteria2(password: secret, tls: tls),
      {
        'type': 'hysteria2',
        'users': [
          {'password': _password},
        ],
        'tls': serverTls,
      },
      udp: true,
      hopPorts: 3,
    ),
    // Chains: each through the Shadowsocks node, to an inbound of its own.
    _Case(
      'trojan ws tls via shadowsocks',
      const NodeParams.trojan(password: secret, transport: ws, tls: tls),
      {
        'type': 'trojan',
        'users': [
          {'password': _password},
        ],
        'transport': wsServer,
        'tls': serverTls,
      },
      detour: 'shadowsocks aes-256-gcm',
    ),
    _Case(
      'vless reality vision via shadowsocks',
      NodeParams.vless(
        uuid: uuid,
        flow: 'xtls-rprx-vision',
        tls: Tls(
          serverName: _host,
          fingerprint: 'chrome',
          reality: Reality(publicKey: realityPublic, shortId: '0a1b'),
        ),
      ),
      {
        'type': 'vless',
        'users': [
          {'uuid': _uuid, 'flow': 'xtls-rprx-vision'},
        ],
        'tls': {
          'enabled': true,
          'server_name': _host,
          'reality': {
            'enabled': true,
            'handshake': {'server': '127.0.0.1', 'server_port': 0},
            'private_key': realityPrivate,
            'short_id': ['0a1b'],
          },
        },
      },
      detour: 'shadowsocks aes-256-gcm',
    ),
    _Case(
      'hysteria2 via shadowsocks',
      const NodeParams.hysteria2(password: secret, tls: tls),
      {
        'type': 'hysteria2',
        'users': [
          {'password': _password},
        ],
        'tls': serverTls,
      },
      udp: true,
      detour: 'shadowsocks aes-256-gcm',
    ),
  ];
  handshakePort = basePort + cases.indexWhere((c) => c.name == 'vless tcp tls');
  // Host ports for hopping, after the cases' own.
  var nextHop = basePort + cases.length;
  final hops = <int, List<int>>{
    for (final (i, c) in cases.indexed)
      if (c.hopPorts > 0) i: [for (var k = 0; k < c.hopPorts; k++) nextHop++],
  };

  final inbounds = <Map<String, Object?>>[];
  final nodes = <NodeDef>[];
  for (final (i, c) in cases.indexed) {
    final port = basePort + i;
    final inbound = {
      ...c.inbound,
      'tag': 'in-$i',
      'listen': '::',
      'listen_port': port,
    };
    final reality = (inbound['tls'] as Map?)?['reality'] as Map?;
    if (reality != null) {
      inbound['tls'] = {
        ...inbound['tls']! as Map,
        'reality': {
          ...reality,
          'handshake': {'server': '127.0.0.1', 'server_port': handshakePort},
        },
      };
    }
    inbounds.add(inbound);
    for (final (k, hop) in (hops[i] ?? const <int>[]).indexed) {
      inbounds.add({...inbound, 'tag': 'in-$i-h$k', 'listen_port': hop});
    }
    final hopping = hops[i];
    var params = c.params;
    if (hopping != null && params is Hysteria2Params) {
      params = params.copyWith(
        serverPorts: ['${hopping.first}:${hopping.last}'],
      );
    }
    final detour = c.detour;
    nodes.add(
      NodeDef(
        key: 'node-$i',
        name: c.name,
        server: '127.0.0.1',
        // Hopping: only the range is known.
        port: hopping == null ? port : 0,
        params: params,
        detourKey: detour == null
            ? null
            : 'node-${cases.indexWhere((d) => d.name == detour)}',
      ),
    );
  }
  // What check_protocols.sh publishes besides the cases' own ports.
  File('$out/hop_ports.txt').writeAsStringSync(
    [
      for (final ports in hops.values)
        for (final p in ports) '$p:$p',
    ].join('\n'),
  );

  File('$out/server.json').writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'log': {'level': 'info'},
      'inbounds': inbounds,
      'outbounds': [
        {'type': 'direct', 'tag': 'direct'},
      ],
    }),
  );

  final content = ConfigContent(
    nodes: nodes,
    groups: [
      GroupDef(
        key: 'group',
        name: 'matrix',
        type: GroupType.selector,
        displayType: 'Selector',
        members: [for (final n in nodes) n.key],
      ),
    ],
    finalTarget: 'group',
  );
  final plan = compile(
    CompileInput(
      source: ImportedSource(id: 's5', content: content),
      settings: DeviceSettings(
        tunEnabled: false,
        mixedPort: mixedPort,
        bypassLan: false,
        clashApi: false,
        logLevel: LogLevel.info,
      ),
      host: HostInfo(
        platform: HostPlatform.macos,
        stateDir: out,
        deviceName: 's5',
      ),
      hashKey: Uint8List.fromList(List.filled(32, 5)),
      // No downloads during the run: the DNS rule's set, empty.
      ruleSetCache: {'geosite-cn': '$out/geosite-cn.srs'},
    ),
  );
  File('$out/plan.json').writeAsStringSync(jsonEncode(plan.toJson()));

  String tagOf(MemberRef ref) =>
      plan.tags.entries.firstWhere((e) => e.value.ref == ref).key;
  File('$out/cases.json').writeAsStringSync(
    jsonEncode({
      'group': tagOf(
        const MemberRef.source(configurationId: 's5', key: 'group'),
      ),
      'mixedPort': mixedPort,
      'cases': [
        for (final (i, c) in cases.indexed)
          {
            'name': c.name,
            'tag': tagOf(
              MemberRef.source(configurationId: 's5', key: 'node-$i'),
            ),
            'port': basePort + i,
            'udp': c.udp,
            'relaysUdp': c.relaysUdp,
          },
      ],
    }),
  );
  stdout.writeln('${cases.length} cases');
}
