import '../domain/node.dart';
import '../domain/node_keys.dart';
import '../domain/secret.dart';
import '../domain/user_content.dart';
import 'parsers/share_link.dart';

/// Every text field the node form can show (PRODUCT_SPEC §3.6).
enum NodeField {
  name,
  server,
  port,
  uuid,
  password,
  obfsPassword,
  username,
  upMbps,
  downMbps,
  congestion,
  flow,
  alterId,
  method,
  idleCheck,
  wsPath,
  wsHost,
  grpcService,
  h2Path,
  sni,
  publicKey,
  shortId,
}

enum TransportKind { tcp, ws, grpc, http2 }

enum NodeSecurity { none, tls, reality }

enum NodeDraftError {
  /// A required field is empty.
  required,

  /// The value cannot be read (not a port, not a UUID…).
  invalid,

  /// A readable value Avalon cannot run.
  unsupported,
}

/// The first problem that keeps a draft from being saved.
final class NodeDraftException implements Exception {
  const NodeDraftException(this.field, this.error);

  final NodeField field;
  final NodeDraftError error;

  @override
  String toString() => 'NodeDraftException(${field.name}, ${error.name})';
}

/// What the node form holds: the texts as typed plus the three choices.
/// Which fields show, what they suggest and how they become a node all
/// follow from it, so the form itself only draws.
final class NodeDraft {
  const NodeDraft({
    this.protocol = Protocol.vless,
    this.transport = TransportKind.tcp,
    this.security = NodeSecurity.reality,
    this.values = const {NodeField.port: '443'},
  }) : _sourceTls = null;

  const NodeDraft._(
    this._sourceTls, {
    required this.protocol,
    required this.transport,
    required this.security,
    required this.values,
  });

  /// Fills the form from a parsed share link (nothing is saved).
  factory NodeDraft.fromLink(LinkNode link) => NodeDraft.fromNode(
    name: link.name ?? '',
    server: link.server,
    port: link.port,
    params: link.params,
  );

  /// Fills the form from a node. With [withSecrets] false (editing) the
  /// secret fields stay empty, which [build] reads as «unchanged».
  factory NodeDraft.fromNode({
    required String name,
    required String server,
    required int port,
    required NodeParams params,
    bool withSecrets = true,
  }) {
    final v = <NodeField, String>{
      NodeField.name: name,
      NodeField.server: server,
      NodeField.port: port > 0 ? '$port' : '',
    };
    void put(NodeField f, Object? value) {
      final text = switch (value) {
        null => '',
        Secret(:final value) => withSecrets ? value : '',
        _ => '$value',
      };
      if (text.isNotEmpty) v[f] = text;
    }

    var transport = TransportKind.tcp;
    var security = NodeSecurity.none;
    Tls? sourceTls;
    void readTransport(Transport t) {
      switch (t) {
        case TcpTransport():
          transport = TransportKind.tcp;
        case WsTransport(:final path, :final host):
          transport = TransportKind.ws;
          put(NodeField.wsPath, path);
          put(NodeField.wsHost, host);
        case GrpcTransport(:final serviceName):
          transport = TransportKind.grpc;
          put(NodeField.grpcService, serviceName);
        case Http2Transport(:final path):
          transport = TransportKind.http2;
          put(NodeField.h2Path, path);
      }
    }

    void readTls(Tls? tls) {
      if (tls == null) return;
      sourceTls = tls;
      security = tls.reality == null ? NodeSecurity.tls : NodeSecurity.reality;
      put(NodeField.sni, tls.serverName);
      put(NodeField.publicKey, tls.reality?.publicKey);
      put(NodeField.shortId, tls.reality?.shortId);
    }

    switch (params) {
      case Hysteria2Params():
        put(NodeField.password, params.password);
        put(NodeField.obfsPassword, params.obfsPassword);
        put(NodeField.upMbps, params.upMbps);
        put(NodeField.downMbps, params.downMbps);
        readTls(params.tls);
      case TuicParams():
        put(NodeField.uuid, params.uuid);
        put(NodeField.password, params.password);
        put(NodeField.congestion, params.congestionControl);
        readTls(params.tls);
      case VlessParams():
        put(NodeField.uuid, params.uuid);
        put(NodeField.flow, params.flow);
        readTransport(params.transport);
        readTls(params.tls);
      case VmessParams():
        put(NodeField.uuid, params.uuid);
        put(NodeField.alterId, params.alterId);
        readTransport(params.transport);
        readTls(params.tls);
      case TrojanParams():
        put(NodeField.password, params.password);
        readTransport(params.transport);
        readTls(params.tls);
      case ShadowsocksParams():
        put(NodeField.method, params.method);
        put(NodeField.password, params.password);
      case Socks5Params():
        put(NodeField.username, params.username);
        put(NodeField.password, params.password);
        readTls(params.tls);
      case AnyTlsParams():
        put(NodeField.password, params.password);
        put(NodeField.idleCheck, params.idleSessionCheckInterval);
        readTls(params.tls);
      case HttpParams():
        put(NodeField.username, params.username);
        put(NodeField.password, params.password);
        readTls(params.tls);
    }
    return NodeDraft._(
      (protocol: params.protocol, tls: sourceTls),
      protocol: params.protocol,
      transport: transport,
      security: security,
      values: v,
    );
  }

  final Protocol protocol;
  final TransportKind transport;

  /// The user's choice. It is kept while another protocol cannot offer it
  /// and comes back when one can; see [effectiveSecurity].
  final NodeSecurity security;
  final Map<NodeField, String> values;

  /// Imported options the form does not show, retained for their protocol.
  /// Visible SNI and Reality fields always come from the current draft.
  final ({Protocol protocol, Tls? tls})? _sourceTls;

  String operator [](NodeField field) => values[field] ?? '';

  String _text(NodeField field) => this[field].trim();

  NodeDraft set(NodeField field, String value) => NodeDraft._(
    _sourceTls,
    protocol: protocol,
    transport: transport,
    security: security,
    values: {...values, field: value},
  );

  NodeDraft copyWith({
    Protocol? protocol,
    TransportKind? transport,
    NodeSecurity? security,
  }) => NodeDraft._(
    _sourceTls,
    protocol: protocol ?? this.protocol,
    transport: transport ?? this.transport,
    security: security ?? this.security,
    values: values,
  );

  // ----------------------------------------------------------- what shows

  static const _server = <Protocol, List<NodeField>>{
    Protocol.hysteria2: [
      NodeField.server,
      NodeField.port,
      NodeField.password,
      NodeField.obfsPassword,
      NodeField.upMbps,
      NodeField.downMbps,
    ],
    Protocol.tuic: [
      NodeField.server,
      NodeField.port,
      NodeField.uuid,
      NodeField.password,
      NodeField.congestion,
    ],
    Protocol.vless: [
      NodeField.server,
      NodeField.port,
      NodeField.uuid,
      NodeField.flow,
    ],
    Protocol.vmess: [
      NodeField.server,
      NodeField.port,
      NodeField.uuid,
      NodeField.alterId,
    ],
    Protocol.trojan: [NodeField.server, NodeField.port, NodeField.password],
    Protocol.shadowsocks: [
      NodeField.server,
      NodeField.port,
      NodeField.method,
      NodeField.password,
    ],
    Protocol.socks5: [
      NodeField.server,
      NodeField.port,
      NodeField.username,
      NodeField.password,
    ],
    Protocol.anytls: [
      NodeField.server,
      NodeField.port,
      NodeField.password,
      NodeField.idleCheck,
    ],
    Protocol.http: [
      NodeField.server,
      NodeField.port,
      NodeField.username,
      NodeField.password,
    ],
  };

  static const _alwaysTls = {
    Protocol.trojan,
    Protocol.hysteria2,
    Protocol.tuic,
    Protocol.anytls,
  };

  /// The «服务器» group, after the name.
  List<NodeField> get serverFields => _server[protocol]!;

  /// VLESS, VMess and Trojan choose a transport.
  bool get hasTransport =>
      protocol == Protocol.vless ||
      protocol == Protocol.vmess ||
      protocol == Protocol.trojan;

  /// The «传输层安全» segment; empty when the protocol has no choice.
  List<NodeSecurity> get securityOptions => switch (protocol) {
    Protocol.vless => NodeSecurity.values,
    Protocol.vmess ||
    Protocol.http => const [NodeSecurity.none, NodeSecurity.tls],
    _ => const [],
  };

  /// The segment's selection: the user's choice, or TLS while the protocol
  /// cannot offer it. Null without a segment.
  NodeSecurity? get effectiveSecurity {
    final options = securityOptions;
    if (options.isEmpty) return null;
    return options.contains(security) ? security : NodeSecurity.tls;
  }

  /// Fields under the segments: the transport's, then the TLS ones.
  List<NodeField> get extraFields {
    final sec = effectiveSecurity;
    return [
      if (hasTransport)
        ...switch (transport) {
          TransportKind.tcp => const <NodeField>[],
          TransportKind.ws => const [NodeField.wsPath, NodeField.wsHost],
          TransportKind.grpc => const [NodeField.grpcService],
          TransportKind.http2 => const [NodeField.h2Path],
        },
      if (sec == NodeSecurity.reality) ...[
        NodeField.sni,
        NodeField.publicKey,
        NodeField.shortId,
      ] else if (sec == NodeSecurity.tls || _alwaysTls.contains(protocol))
        NodeField.sni,
    ];
  }

  /// Whether [field] must be filled for the current choices.
  bool isRequired(NodeField field) => switch (field) {
    NodeField.server || NodeField.port => true,
    NodeField.uuid || NodeField.method => true,
    NodeField.password =>
      protocol != Protocol.socks5 && protocol != Protocol.http,
    NodeField.publicKey => true,
    NodeField.sni => effectiveSecurity == NodeSecurity.reality,
    _ => false,
  };

  /// A sample value to show while [field] is empty; null where the form
  /// says «必填» or «可选» instead (see [isRequired]).
  String? sample(NodeField field) => switch (field) {
    NodeField.server =>
      protocol == Protocol.socks5 ? '127.0.0.1' : 'example.com',
    NodeField.port => switch (protocol) {
      Protocol.shadowsocks => '8388',
      Protocol.socks5 => '1080',
      Protocol.http => '8080',
      _ => '443',
    },
    NodeField.upMbps => '50',
    NodeField.downMbps => '200',
    NodeField.congestion => 'bbr',
    NodeField.flow => 'xtls-rprx-vision',
    NodeField.alterId => '0',
    NodeField.method => '2022-blake3-aes-128-gcm',
    NodeField.idleCheck => '30s',
    NodeField.wsPath => '/ws',
    NodeField.grpcService => 'grpc',
    NodeField.h2Path => '/',
    NodeField.sni =>
      effectiveSecurity == NodeSecurity.reality
          ? 'www.apple.com'
          : 'example.com',
    NodeField.publicKey => 'Public Key',
    _ => null,
  };

  /// Secrets are stored encrypted and never shown again once saved.
  static bool isSecret(NodeField field) =>
      field == NodeField.uuid ||
      field == NodeField.password ||
      field == NodeField.obfsPassword;

  // ------------------------------------------------------------ to a node

  static final _host = RegExp(r'^[A-Za-z0-9._\-:\[\]]+$');
  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  static final _duration = RegExp(r'^\d+(ms|s|m|h)$');

  /// Methods sing-box accepts for Shadowsocks.
  static const shadowsocksMethods = {
    '2022-blake3-aes-128-gcm',
    '2022-blake3-aes-256-gcm',
    '2022-blake3-chacha20-poly1305',
    'none',
    'aes-128-gcm',
    'aes-192-gcm',
    'aes-256-gcm',
    'chacha20-ietf-poly1305',
    'xchacha20-ietf-poly1305',
    'aes-128-ctr',
    'aes-192-ctr',
    'aes-256-ctr',
    'aes-128-cfb',
    'aes-192-cfb',
    'aes-256-cfb',
    'rc4-md5',
    'chacha20-ietf',
    'xchacha20',
  };

  Never _fail(NodeField field, NodeDraftError error) =>
      throw NodeDraftException(field, error);

  String _need(NodeField field) {
    final text = _text(field);
    if (text.isEmpty) _fail(field, NodeDraftError.required);
    return text;
  }

  String? _optional(NodeField field) {
    final text = _text(field);
    return text.isEmpty ? null : text;
  }

  /// A secret as typed; when empty, the saved one ([kept]) if there is.
  Secret? _secret(NodeField field, Secret? kept, {required bool required}) {
    final text = _text(field);
    if (text.isNotEmpty) return Secret(text);
    if (kept != null) return kept;
    if (required) _fail(field, NodeDraftError.required);
    return null;
  }

  int? _number(NodeField field, {int min = 0}) {
    final text = _text(field);
    if (text.isEmpty) return null;
    final n = int.tryParse(text);
    if (n == null || n < min) _fail(field, NodeDraftError.invalid);
    return n;
  }

  Tls? _tls({Tls? kept}) {
    final source = _sourceTls;
    final base = source?.protocol == protocol
        ? source!.tls ?? const Tls()
        : kept ?? const Tls();
    final sec = effectiveSecurity;
    if (sec == NodeSecurity.reality) {
      final serverName = _need(NodeField.sni);
      final publicKey = _need(NodeField.publicKey);
      if (!NodeKeys.realityPublicKey(publicKey)) {
        _fail(NodeField.publicKey, NodeDraftError.invalid);
      }
      final shortId = _optional(NodeField.shortId);
      if (shortId != null && !NodeKeys.realityShortId(shortId)) {
        _fail(NodeField.shortId, NodeDraftError.invalid);
      }
      return base.copyWith(
        serverName: serverName,
        reality: Reality(publicKey: publicKey, shortId: shortId),
      );
    }
    if (sec == NodeSecurity.tls || _alwaysTls.contains(protocol)) {
      return base.copyWith(serverName: _optional(NodeField.sni), reality: null);
    }
    return null;
  }

  Transport _transport() => switch (transport) {
    TransportKind.tcp => const Transport.tcp(),
    TransportKind.ws => Transport.ws(
      path: _optional(NodeField.wsPath) ?? '/',
      host: _optional(NodeField.wsHost),
    ),
    TransportKind.grpc => Transport.grpc(
      serviceName: _optional(NodeField.grpcService) ?? '',
    ),
    TransportKind.http2 => Transport.http2(
      path: _optional(NodeField.h2Path) ?? '/',
    ),
  };

  /// Validates the draft and turns it into a node (id empty; the
  /// repository assigns one). The name falls back to the server address.
  /// When editing, [existing] supplies the secrets left empty and the id.
  /// Throws [NodeDraftException] for the first problem, in form order.
  SelfNode build({SelfNode? existing}) {
    final server = _need(NodeField.server);
    if (!_host.hasMatch(server)) {
      _fail(NodeField.server, NodeDraftError.invalid);
    }
    final portText = _need(NodeField.port);
    final port = int.tryParse(portText);
    if (port == null || port < 1 || port > 65535) {
      _fail(NodeField.port, NodeDraftError.invalid);
    }
    // Secrets carry over only within the same protocol.
    final old = existing?.params.protocol == protocol ? existing!.params : null;

    Secret uuid(Secret? kept) {
      final s = _secret(NodeField.uuid, kept, required: true)!;
      if (!_uuid.hasMatch(s.value)) {
        _fail(NodeField.uuid, NodeDraftError.invalid);
      }
      return s;
    }

    final NodeParams params;
    switch (protocol) {
      case Protocol.hysteria2:
        final o = old as Hysteria2Params?;
        params = NodeParams.hysteria2(
          password: _secret(NodeField.password, o?.password, required: true)!,
          obfsPassword: _secret(
            NodeField.obfsPassword,
            o?.obfsPassword,
            required: false,
          ),
          upMbps: _number(NodeField.upMbps, min: 1),
          downMbps: _number(NodeField.downMbps, min: 1),
          serverPorts: o?.serverPorts ?? const [],
          tls: _tls(kept: o?.tls)!,
        );
      case Protocol.tuic:
        final o = old as TuicParams?;
        final congestion = _optional(NodeField.congestion) ?? 'bbr';
        if (!const {'bbr', 'cubic', 'new_reno'}.contains(congestion)) {
          _fail(NodeField.congestion, NodeDraftError.unsupported);
        }
        params = NodeParams.tuic(
          uuid: uuid(o?.uuid),
          password: _secret(NodeField.password, o?.password, required: true)!,
          congestionControl: congestion,
          udpRelayMode: o?.udpRelayMode,
          tls: _tls(kept: o?.tls)!,
        );
      case Protocol.vless:
        final o = old as VlessParams?;
        final flow = _optional(NodeField.flow);
        if (flow != null && flow != 'xtls-rprx-vision') {
          _fail(NodeField.flow, NodeDraftError.unsupported);
        }
        params = NodeParams.vless(
          uuid: uuid(o?.uuid),
          flow: flow,
          transport: _transport(),
          tls: _tls(kept: o?.tls),
        );
      case Protocol.vmess:
        final o = old as VmessParams?;
        params = NodeParams.vmess(
          uuid: uuid(o?.uuid),
          alterId: _number(NodeField.alterId) ?? 0,
          cipher: o?.cipher ?? 'auto',
          transport: _transport(),
          tls: _tls(kept: o?.tls),
        );
      case Protocol.trojan:
        final o = old as TrojanParams?;
        params = NodeParams.trojan(
          password: _secret(NodeField.password, o?.password, required: true)!,
          transport: _transport(),
          tls: _tls(kept: o?.tls)!,
        );
      case Protocol.shadowsocks:
        final o = old as ShadowsocksParams?;
        final method = _need(NodeField.method);
        if (!shadowsocksMethods.contains(method)) {
          _fail(NodeField.method, NodeDraftError.unsupported);
        }
        final password = _secret(
          NodeField.password,
          o?.password,
          required: true,
        )!;
        if (!NodeKeys.shadowsocksPassword(method, password.value)) {
          _fail(NodeField.password, NodeDraftError.invalid);
        }
        params = NodeParams.shadowsocks(
          method: method,
          password: password,
          plugin: o?.plugin,
          pluginOpts: o?.pluginOpts,
        );
      case Protocol.socks5:
        final o = old as Socks5Params?;
        params = NodeParams.socks5(
          username: _optional(NodeField.username),
          password: _secret(NodeField.password, o?.password, required: false),
          tls: _tls(kept: o?.tls),
        );
      case Protocol.anytls:
        final o = old as AnyTlsParams?;
        final idle = _optional(NodeField.idleCheck);
        if (idle != null && !_duration.hasMatch(idle)) {
          _fail(NodeField.idleCheck, NodeDraftError.invalid);
        }
        params = NodeParams.anytls(
          password: _secret(NodeField.password, o?.password, required: true)!,
          idleSessionCheckInterval: idle,
          tls: _tls(kept: o?.tls)!,
        );
      case Protocol.http:
        final o = old as HttpParams?;
        params = NodeParams.http(
          username: _optional(NodeField.username),
          password: _secret(NodeField.password, o?.password, required: false),
          tls: _tls(kept: o?.tls),
        );
    }
    final name = _text(NodeField.name);
    return SelfNode(
      id: existing?.id ?? '',
      name: name.isEmpty ? server : name,
      server: server,
      port: port,
      params: params,
    );
  }
}
