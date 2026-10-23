import 'dart:convert';

import '../../domain/node.dart';
import '../../domain/secret.dart';
import '../import_exception.dart';
import '../text.dart';

/// A node read from a share link. It has no key yet, and [name] is null when
/// the link carries none (the caller falls back to the server address).
final class LinkNode {
  const LinkNode({
    this.name,
    required this.server,
    required this.port,
    required this.params,
  });

  final String? name;
  final String server;
  final int port;
  final NodeParams params;
}

/// Parses one share link (CONFIG_PIPELINE §4).
///
/// Unknown parameters and values Avalon cannot express raise
/// [ImportException] naming the parameter; nothing is guessed or dropped.
/// Parameters that only restate defaults (`encryption=none`,
/// `headerType=none`, AnyTLS/VLESS `udp=true`) or tune the client UI (`spx`)
/// are accepted.
LinkNode parseShareLink(String input) {
  final link = input.trim();
  final sep = link.indexOf('://');
  if (sep <= 0) {
    throw const ImportException(ImportErrorCode.unsupportedScheme);
  }
  final scheme = link.substring(0, sep).toLowerCase();
  return switch (scheme) {
    'vless' => _vless(_uri(link)),
    'vmess' => _vmess(link.substring(sep + 3)),
    'trojan' => _trojan(_uri(link)),
    'ss' => _shadowsocks(link.substring(sep + 3)),
    'hysteria2' || 'hy2' => _hysteria2(_uri(link)),
    'tuic' => _tuic(_uri(link)),
    'socks' || 'socks5' => _socks(_uri(link)),
    'http' || 'https' => _http(_uri(link), tls: scheme == 'https'),
    'anytls' => _anytls(_uri(link)),
    _ => throw ImportException(
      ImportErrorCode.unsupportedScheme,
      detail: scheme,
    ),
  };
}

Uri _uri(String link) {
  try {
    return Uri.parse(link);
  } on FormatException {
    throw const ImportException(ImportErrorCode.malformed);
  }
}

/// Query parameters with percent-decoding only, checked against [known].
/// [enabledDefaults] accepts only flags that restate an enabled capability.
final class _Query {
  _Query(Uri uri, Set<String> known, {Set<String> enabledDefaults = const {}}) {
    if (uri.query.isEmpty) return;
    for (final part in uri.query.split('&')) {
      if (part.isEmpty) continue;
      final eq = part.indexOf('=');
      final key = percentDecode(eq < 0 ? part : part.substring(0, eq));
      if (!known.contains(key)) {
        throw ImportException(ImportErrorCode.unknownParameter, field: key);
      }
      final value = eq < 0 ? '' : percentDecode(part.substring(eq + 1));
      // Validate every occurrence before assigning it: a later true flag
      // must not silently overwrite a request to disable the capability.
      if (enabledDefaults.contains(key) &&
          !_trueFlags.contains(value.toLowerCase())) {
        throw ImportException(ImportErrorCode.unsupportedValue, field: key);
      }
      _values[key] = value;
    }
  }

  final _values = <String, String>{};
  static const _trueFlags = {'1', 'true', 'yes'};

  String? operator [](String key) {
    final v = _values[key];
    return v == null || v.isEmpty ? null : v;
  }

  bool flag(String key) => _trueFlags.contains(_values[key]?.toLowerCase());

  List<String> list(String key) => [
    for (final s in (this[key] ?? '').split(','))
      if (s.trim().isNotEmpty) s.trim(),
  ];
}

String? _name(Uri uri) {
  final n = percentDecode(uri.fragment).trim();
  return n.isEmpty ? null : n;
}

String _server(Uri uri) {
  if (uri.host.isEmpty) {
    throw const ImportException(ImportErrorCode.missingField, field: 'server');
  }
  return uri.host;
}

int _port(Uri uri) {
  // `Uri` drops a scheme's default port (https://h:443), but `port` still
  // reports it; custom schemes without a port report 0.
  if (uri.port == 0) {
    throw const ImportException(ImportErrorCode.missingField, field: 'port');
  }
  if (uri.port < 1 || uri.port > 65535) {
    throw const ImportException(ImportErrorCode.invalidField, field: 'port');
  }
  return uri.port;
}

String _required(String? value, String field) {
  if (value == null || value.isEmpty) {
    throw ImportException(ImportErrorCode.missingField, field: field);
  }
  return value;
}

String _userInfo(Uri uri) => percentDecode(uri.userInfo);

Tls _tls(_Query q) => Tls(
  serverName: q['sni'] ?? q['peer'],
  insecure: q.flag('allowInsecure') || q.flag('insecure'),
  alpn: q.list('alpn'),
  fingerprint: q['fp'],
);

const _transportKeys = {'type', 'path', 'host', 'serviceName', 'headerType'};
const _tlsKeys = {'sni', 'alpn', 'fp', 'allowInsecure', 'insecure'};

Transport _transport({
  required String type,
  String? path,
  String? host,
  String? serviceName,
  String? headerType,
}) {
  if (headerType != null && headerType != 'none') {
    throw ImportException(
      ImportErrorCode.unsupportedValue,
      field: 'headerType',
      detail: headerType,
    );
  }
  switch (type) {
    case 'tcp':
      return const Transport.tcp();
    case 'ws':
      // `/path?ed=2048` asks for early data in the WebSocket protocol header.
      var p = path ?? '/';
      var earlyData = 0;
      final ed = RegExp(r'[?&]ed=(\d+)').firstMatch(p);
      if (ed != null) {
        earlyData = int.parse(ed.group(1)!);
        p = p.substring(0, ed.start);
        if (p.isEmpty) p = '/';
      }
      return Transport.ws(
        path: p,
        host: host,
        maxEarlyData: earlyData,
        earlyDataHeader: earlyData > 0 ? 'Sec-WebSocket-Protocol' : null,
      );
    case 'grpc':
      return Transport.grpc(serviceName: serviceName ?? '');
    case 'http' || 'h2':
      return Transport.http2(
        path: path ?? '/',
        host: [
          for (final h in (host ?? '').split(','))
            if (h.trim().isNotEmpty) h.trim(),
        ],
      );
  }
  throw ImportException(
    ImportErrorCode.unsupportedValue,
    field: 'type',
    detail: type,
  );
}

Transport _queryTransport(_Query q) => _transport(
  type: q['type'] ?? 'tcp',
  path: q['path'],
  host: q['host'],
  serviceName: q['serviceName'],
  headerType: q['headerType'],
);

void _grpcMode(_Query q) {
  final mode = q['mode'];
  if (mode != null && mode != 'gun') {
    throw ImportException(
      ImportErrorCode.unsupportedValue,
      field: 'mode',
      detail: mode,
    );
  }
}

// vless://uuid@host:port?type=&security=&sni=&pbk=&sid=&flow=&path=&host=
//   &serviceName=#name
LinkNode _vless(Uri uri) {
  final q = _Query(
    uri,
    {
      ..._transportKeys,
      ..._tlsKeys,
      'security',
      'pbk',
      'sid',
      'flow',
      'encryption',
      'spx',
      'mode',
      'udp',
    },
    enabledDefaults: const {'udp'},
  );
  final encryption = q['encryption'];
  if (encryption != null && encryption != 'none') {
    throw ImportException(
      ImportErrorCode.unsupportedValue,
      field: 'encryption',
      detail: encryption,
    );
  }
  _grpcMode(q);
  final security = q['security'] ?? 'none';
  final Tls? tls = switch (security) {
    'none' => null,
    'tls' => _tls(q),
    'reality' => _tls(q).copyWith(
      reality: Reality(
        publicKey: _required(q['pbk'], 'pbk'),
        shortId: q['sid'],
      ),
    ),
    _ => throw ImportException(
      ImportErrorCode.unsupportedValue,
      field: 'security',
      detail: security,
    ),
  };
  return LinkNode(
    name: _name(uri),
    server: _server(uri),
    port: _port(uri),
    params: NodeParams.vless(
      uuid: Secret(_required(_userInfo(uri), 'uuid')),
      flow: q['flow'],
      transport: _queryTransport(q),
      tls: tls,
    ),
  );
}

// vmess://Base64(JSON), the v2 share format.
LinkNode _vmess(String body) {
  final Map<String, dynamic> j;
  try {
    j =
        jsonDecode(utf8.decode(decodeBase64Loose(body)))
            as Map<String, dynamic>;
  } on Object {
    throw const ImportException(ImportErrorCode.malformed);
  }
  const known = {
    'v', 'ps', 'add', 'port', 'id', 'aid', 'scy', 'net', 'type', //
    'host', 'path', 'tls', 'sni', 'alpn', 'fp', 'allowInsecure',
  };
  for (final k in j.keys) {
    if (!known.contains(k)) {
      throw ImportException(ImportErrorCode.unknownParameter, field: k);
    }
  }
  String? str(String k) {
    final v = j[k];
    final s = v == null ? '' : '$v'.trim();
    return s.isEmpty ? null : s;
  }

  final port = int.tryParse(_required(str('port'), 'port'));
  if (port == null || port < 1 || port > 65535) {
    throw const ImportException(ImportErrorCode.invalidField, field: 'port');
  }
  final net = str('net') ?? 'tcp';
  final aid = int.tryParse(str('aid') ?? '0');
  if (aid == null) {
    throw const ImportException(ImportErrorCode.invalidField, field: 'aid');
  }
  final tlsMode = str('tls');
  if (tlsMode != null && tlsMode != 'tls' && tlsMode != 'none') {
    throw ImportException(
      ImportErrorCode.unsupportedValue,
      field: 'tls',
      detail: tlsMode,
    );
  }
  return LinkNode(
    name: str('ps'),
    server: _required(str('add'), 'server'),
    port: port,
    params: NodeParams.vmess(
      uuid: Secret(_required(str('id'), 'uuid')),
      alterId: aid,
      cipher: str('scy') ?? 'auto',
      transport: _transport(
        type: net,
        path: str('path'),
        host: str('host'),
        // The v2 format puts the gRPC service name in `path`.
        serviceName: str('path'),
        headerType: str('type'),
      ),
      tls: tlsMode == 'tls'
          ? Tls(
              serverName: str('sni'),
              alpn: [
                for (final a in (str('alpn') ?? '').split(','))
                  if (a.trim().isNotEmpty) a.trim(),
              ],
              fingerprint: str('fp'),
              insecure: const {'1', 'true'}.contains(str('allowInsecure')),
            )
          : null,
    ),
  );
}

// trojan://password@host:port?sni=&type=&path=&host=&serviceName=#name
LinkNode _trojan(Uri uri) {
  final q = _Query(uri, {
    ..._transportKeys,
    ..._tlsKeys,
    'security',
    'peer',
    'mode',
  });
  final security = q['security'];
  if (security != null && security != 'tls') {
    throw ImportException(
      ImportErrorCode.unsupportedValue,
      field: 'security',
      detail: security,
    );
  }
  _grpcMode(q);
  return LinkNode(
    name: _name(uri),
    server: _server(uri),
    port: _port(uri),
    params: NodeParams.trojan(
      password: Secret(_required(_userInfo(uri), 'password')),
      transport: _queryTransport(q),
      tls: _tls(q),
    ),
  );
}

// ss://Base64(method:password)@host:port[/?plugin=…]#name (SIP002),
// ss://method:password@host:port (percent-encoded, common for 2022 ciphers)
// or ss://Base64(method:password@host:port)#name (legacy).
LinkNode _shadowsocks(String body) {
  String? name;
  final hash = body.indexOf('#');
  if (hash >= 0) {
    final n = percentDecode(body.substring(hash + 1)).trim();
    name = n.isEmpty ? null : n;
    body = body.substring(0, hash);
  }

  String credentials;
  Uri uri;
  if (body.contains('@')) {
    uri = _uri('ss://$body');
    final info = percentDecode(uri.userInfo);
    if (info.contains(':')) {
      credentials = info;
    } else {
      try {
        credentials = utf8.decode(decodeBase64Loose(uri.userInfo));
      } on FormatException {
        throw const ImportException(
          ImportErrorCode.malformed,
          field: 'userinfo',
        );
      }
    }
  } else {
    final String decoded;
    try {
      decoded = utf8.decode(decodeBase64Loose(body));
    } on FormatException {
      throw const ImportException(ImportErrorCode.malformed);
    }
    final at = decoded.lastIndexOf('@');
    if (at < 0) throw const ImportException(ImportErrorCode.malformed);
    credentials = decoded.substring(0, at);
    uri = _uri('ss://x@${decoded.substring(at + 1)}');
  }

  final q = _Query(uri, {'plugin'});
  final colon = credentials.indexOf(':');
  if (colon <= 0) {
    throw const ImportException(ImportErrorCode.missingField, field: 'method');
  }
  final plugin = q['plugin'];
  final semi = plugin?.indexOf(';') ?? -1;
  return LinkNode(
    name: name,
    server: _server(uri),
    port: _port(uri),
    params: NodeParams.shadowsocks(
      method: credentials.substring(0, colon),
      password: Secret(_required(credentials.substring(colon + 1), 'password')),
      plugin: semi < 0 ? plugin : plugin!.substring(0, semi),
      pluginOpts: semi < 0 ? null : plugin!.substring(semi + 1),
    ),
  );
}

// hysteria2://auth@host:port?obfs=salamander&obfs-password=&sni=#name
LinkNode _hysteria2(Uri uri) {
  final q = _Query(uri, {
    'obfs',
    'obfs-password',
    'sni',
    'insecure',
    'alpn',
    'mport',
  });
  final obfs = q['obfs'];
  if (obfs != null && obfs != 'salamander') {
    throw ImportException(
      ImportErrorCode.unsupportedValue,
      field: 'obfs',
      detail: obfs,
    );
  }
  return LinkNode(
    name: _name(uri),
    server: _server(uri),
    port: _port(uri),
    params: NodeParams.hysteria2(
      password: Secret(_required(_userInfo(uri), 'password')),
      obfsPassword: obfs == null
          ? null
          : Secret(_required(q['obfs-password'], 'obfs-password')),
      serverPorts: [for (final r in q.list('mport')) r.replaceAll('-', ':')],
      tls: Tls(
        serverName: q['sni'],
        insecure: q.flag('insecure'),
        alpn: q.list('alpn'),
      ),
    ),
  );
}

// tuic://uuid:password@host:port?congestion_control=&sni=#name
LinkNode _tuic(Uri uri) {
  final q = _Query(uri, {
    'congestion_control',
    'sni',
    'alpn',
    'udp_relay_mode',
    'allow_insecure',
    'allowInsecure',
    'insecure',
  });
  final info = _userInfo(uri);
  final colon = info.indexOf(':');
  return LinkNode(
    name: _name(uri),
    server: _server(uri),
    port: _port(uri),
    params: NodeParams.tuic(
      uuid: Secret(
        _required(colon < 0 ? info : info.substring(0, colon), 'uuid'),
      ),
      password: Secret(
        _required(colon < 0 ? null : info.substring(colon + 1), 'password'),
      ),
      congestionControl: q['congestion_control'] ?? 'bbr',
      udpRelayMode: q['udp_relay_mode'],
      tls: Tls(
        serverName: q['sni'],
        insecure:
            q.flag('allow_insecure') ||
            q.flag('allowInsecure') ||
            q.flag('insecure'),
        alpn: q.list('alpn'),
      ),
    ),
  );
}

/// `user:pass`, or the same Base64-encoded as some clients write it.
(String?, Secret?) _credentials(Uri uri) {
  if (uri.userInfo.isEmpty) return (null, null);
  var info = _userInfo(uri);
  if (!info.contains(':')) {
    try {
      final decoded = utf8.decode(decodeBase64Loose(uri.userInfo));
      if (decoded.contains(':')) info = decoded;
    } on FormatException {
      // Plain user name without a password.
    }
  }
  final colon = info.indexOf(':');
  if (colon < 0) return (info, null);
  final pass = info.substring(colon + 1);
  return (
    colon == 0 ? null : info.substring(0, colon),
    pass.isEmpty ? null : Secret(pass),
  );
}

// socks5://user:pass@host:port#name
LinkNode _socks(Uri uri) {
  _Query(uri, const {});
  final (user, pass) = _credentials(uri);
  return LinkNode(
    name: _name(uri),
    server: _server(uri),
    port: _port(uri),
    params: NodeParams.socks5(username: user, password: pass),
  );
}

// http(s)://user:pass@host:port#name; https means TLS.
LinkNode _http(Uri uri, {required bool tls}) {
  final q = _Query(uri, const {'sni'});
  final (user, pass) = _credentials(uri);
  return LinkNode(
    name: _name(uri),
    server: _server(uri),
    port: _port(uri),
    params: NodeParams.http(
      username: user,
      password: pass,
      tls: tls ? Tls(serverName: q['sni']) : null,
    ),
  );
}

// anytls://password@host:port?sni=&insecure=1&udp=true#name
LinkNode _anytls(Uri uri) {
  final q = _Query(uri, {..._tlsKeys, 'udp'}, enabledDefaults: const {'udp'});
  return LinkNode(
    name: _name(uri),
    server: _server(uri),
    port: _port(uri),
    params: NodeParams.anytls(
      password: Secret(_required(_userInfo(uri), 'password')),
      tls: _tls(q),
    ),
  );
}
