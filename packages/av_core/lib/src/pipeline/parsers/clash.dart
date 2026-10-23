import 'dart:convert';

import '../../domain/content.dart';
import '../../domain/node.dart';
import '../../domain/secret.dart';
import '../import_exception.dart';
import '../rule_sets.dart';
import '../text.dart';
import 'json_object.dart';
import 'limits.dart';
import 'share_link.dart';
import 'uri_list.dart' show defaultTestUrl, insecureTls, linkLines;

/// Skips one node, group or rule with a warning.
final class _Skip implements Exception {
  const _Skip(this.kind, this.subject);

  final WarningKind kind;
  final String subject;
}

/// Proxy options that only tune dialing; ignored silently.
const _dialOptions = {
  'udp', 'tfo', 'mptcp', 'ip-version', 'interface-name', 'routing-mark', //
  'packet-addr', 'xudp', 'packet-encoding', 'global-padding',
  'authenticated-length', 'udp-over-tcp', 'udp-over-tcp-version',
};

const _proxyTypes = {
  'ss', 'vmess', 'vless', 'trojan', 'hysteria2', 'tuic', 'socks5', 'http', //
  'anytls',
};

/// Settings replaced by Avalon's own (D29).
const _ignoredSections = {
  'dns': 'dns',
  'tun': 'tun',
  'hosts': 'hosts',
  'sniffer': 'sniffer',
  'listeners': 'listeners',
  'sub-rules': 'sub-rules',
  'mode': 'mode',
  'port': 'ports',
  'socks-port': 'ports',
  'mixed-port': 'ports',
  'redir-port': 'ports',
  'tproxy-port': 'ports',
};

const _privateCidrs = [
  '10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16', '127.0.0.0/8', //
  '169.254.0.0/16', '100.64.0.0/10', 'fc00::/7', 'fe80::/10', '::1/128',
];

Map<String, Object?> _map(Object? v) =>
    v is Map ? {for (final e in v.entries) '${e.key}': e.value} : const {};

/// HTTP proxy providers whose content must be downloaded, by name, before
/// [parseClash] runs (CONFIG_PIPELINE §2: all in the same refresh).
Map<String, String> clashProviderUrls(Map<String, Object?> doc) {
  final out = <String, String>{};
  for (final e in _map(doc['proxy-providers']).entries) {
    final p = _map(e.value);
    final url = p['url'];
    if (p['type'] == 'http' && url is String && url.isNotEmpty) {
      out[e.key] = url;
    }
  }
  return out;
}

/// Parses a Clash/Mihomo configuration (CONFIG_PIPELINE §4). Keys are
/// `proxy:<name>`, `group:<name>` and `provider:<provider>/<name>`.
/// [providerTexts] holds the downloaded content of every provider named by
/// [clashProviderUrls].
ConfigContent parseClash(
  Map<String, Object?> doc, {
  Map<String, String> providerTexts = const {},
}) {
  final counts = <(WarningKind, String), int>{};
  void warn(WarningKind kind, String subject) =>
      counts[(kind, subject)] = (counts[(kind, subject)] ?? 0) + 1;

  for (final e in _ignoredSections.entries) {
    if (doc.containsKey(e.key)) warn(WarningKind.ignoredSection, e.value);
  }

  final nodes = <NodeDef>[];
  final proxyKeys = <String, String>{}; // name -> key
  final pendingDetours = <int, String>{}; // node index -> dialer-proxy name

  void addProxy(Map<String, Object?> raw, String key, String path) {
    final p = JsonObject(raw, path);
    final type = p.str('type') ?? '';
    final name = p.str('name');
    if (name == null) {
      warn(WarningKind.unreadableEntry, '$path.name');
      return;
    }
    if (!_proxyTypes.contains(type)) {
      warn(WarningKind.unsupportedNodeType, type.isEmpty ? '?' : type);
      return;
    }
    try {
      final (node, dialer) = _proxy(p, type, key, name, warn);
      if (dialer != null) pendingDetours[nodes.length] = dialer;
      nodes.add(node);
    } on _Skip catch (s) {
      warn(s.kind, s.subject);
    } on ImportException catch (e) {
      warn(WarningKind.unreadableEntry, e.field ?? name);
    }
  }

  final proxies = doc['proxies'];
  if (proxies != null && proxies is! List) {
    throw const ImportException(ImportErrorCode.invalidField, field: 'proxies');
  }
  for (final (i, raw) in ((proxies as List?) ?? const []).indexed) {
    final m = _map(raw);
    final name = m['name'];
    final before = nodes.length;
    addProxy(m, 'proxy:$name', 'proxies[$i]');
    if (nodes.length > before) proxyKeys['$name'] = 'proxy:$name';
  }

  // Provider nodes, by provider name.
  final providerNodes = <String, List<String>>{};
  for (final e in _map(doc['proxy-providers']).entries) {
    final name = e.key;
    final p = JsonObject(_map(e.value), 'proxy-providers.$name');
    final type = p.str('type');
    final List<Map<String, Object?>> entries;
    switch (type) {
      case 'http':
        final text = providerTexts[name];
        if (text == null) {
          throw StateError('provider $name was not downloaded');
        }
        entries = _providerEntries(text);
      case 'inline':
        entries = [for (final x in p.list('payload')) _map(x)];
      default:
        warn(WarningKind.unreadableEntry, 'proxy-providers.$name');
        continue;
    }
    final include = _regex(p.str('filter'));
    final exclude = _regex(p.str('exclude-filter'));
    final override = p.object('override');
    // Kept verbatim: spaces in a prefix or suffix are deliberate.
    final prefix = _verbatim(override, 'additional-prefix');
    final suffix = _verbatim(override, 'additional-suffix');
    for (final k in override?.unread ?? const <String>[]) {
      warn(WarningKind.ignoredNodeOption, 'override.$k');
    }
    final keys = <String>[];
    for (final (i, raw) in entries.indexed) {
      final original = '${raw['name'] ?? ''}';
      if (include != null && !include.hasMatch(original)) continue;
      if (exclude != null && exclude.hasMatch(original)) continue;
      final shown = '$prefix$original$suffix';
      final key = 'provider:$name/$original';
      final before = nodes.length;
      addProxy({...raw, 'name': shown}, key, 'proxy-providers.$name[$i]');
      if (nodes.length > before) keys.add(key);
    }
    providerNodes[name] = keys;
  }

  // Groups: names first, so members can refer to any group.
  final rawGroups = doc['proxy-groups'] is List
      ? [for (final g in doc['proxy-groups']! as List) _map(g)]
      : <Map<String, Object?>>[];
  final groupKeys = <String, String>{};
  for (final g in rawGroups) {
    final name = g['name'];
    if (name is String && name.isNotEmpty && g['type'] != 'relay') {
      groupKeys[name] = 'group:$name';
    }
  }

  String? resolve(String name) => switch (name.toUpperCase()) {
    'DIRECT' => ContentKeys.direct,
    'REJECT' || 'REJECT-DROP' => ContentKeys.reject,
    _ => proxyKeys[name] ?? groupKeys[name],
  };

  // dialer-proxy may name a later proxy or a group.
  for (final e in pendingDetours.entries) {
    final target = resolve(e.value);
    if (target == null) {
      warn(WarningKind.droppedMember, e.value);
    } else {
      nodes[e.key] = nodes[e.key].copyWith(detourKey: target);
    }
  }

  final groups = <GroupDef>[];
  for (final (i, raw) in rawGroups.indexed) {
    final g = JsonObject(raw, 'proxy-groups[$i]');
    final name = g.str('name');
    if (name == null) continue;
    try {
      groups.add(_group(g, name, resolve, providerNodes, proxyKeys, warn));
    } on _Skip catch (s) {
      warn(s.kind, s.subject);
    }
  }

  // Rule providers become rule sets, converted after download.
  final ruleSets = <String, RuleSetRef>{};
  final providerSets = <String, String?>{}; // provider -> tag, null if unusable
  for (final e in _map(doc['rule-providers']).entries) {
    final p = JsonObject(_map(e.value), 'rule-providers.${e.key}');
    final url = p.str('url');
    final format = _ruleProviderFormat(p.str('behavior'), p.str('format'));
    if (p.str('type') != 'http' || url == null || format == null) {
      warn(WarningKind.unsupportedRuleSet, e.key);
      providerSets[e.key] = null;
      continue;
    }
    final tag = 'provider-${e.key}';
    ruleSets[tag] = RuleSetRef(tag: tag, url: url, format: format);
    providerSets[e.key] = tag;
  }

  final rules = <RuleDef>[];
  String? finalTarget;
  final rawRules = doc['rules'] is List
      ? doc['rules']! as List
      : const <Object?>[];
  for (final raw in rawRules) {
    if (raw is! String) continue;
    final parts = [for (final s in raw.split(',')) s.trim()];
    final type = parts.first.toUpperCase();
    if (type == 'MATCH' || type == 'FINAL') {
      if (parts.length < 2) continue;
      final target = resolve(parts[1]);
      if (target == null) {
        warn(WarningKind.droppedMember, parts[1]);
      } else {
        finalTarget ??= target;
      }
      continue;
    }
    try {
      final rule = _rule(type, parts, resolve, ruleSets, providerSets);
      rules.add(rule);
    } on _Skip catch (s) {
      warn(s.kind, s.subject);
    }
  }
  if (finalTarget == null) warn(WarningKind.missingFinal, '');

  final insecure = nodes.where((n) => insecureTls(n.params)).length;
  return ConfigContent(
    nodes: nodes,
    groups: groups,
    rules: rules,
    ruleSets: ruleSets.values.toList(),
    finalTarget: finalTarget ?? ContentKeys.direct,
    warnings: [
      for (final e in counts.entries)
        ImportWarning(kind: e.key.$1, subject: e.key.$2, count: e.value),
      if (insecure > 0)
        ImportWarning(kind: WarningKind.insecureTls, count: insecure),
    ],
  );
}

String _verbatim(JsonObject? o, String key) {
  if (o == null) return '';
  o.ignore([key]);
  final v = o.map[key];
  return v is String ? v : '';
}

RegExp? _regex(String? pattern) {
  if (pattern == null) return null;
  try {
    return RegExp(pattern);
  } on FormatException {
    throw ImportException(
      ImportErrorCode.invalidField,
      field: 'filter',
      detail: pattern,
    );
  }
}

/// Provider content: Clash YAML `proxies`, or a (Base64) link list.
List<Map<String, Object?>> _providerEntries(String text) {
  var lines = linkLines(text);
  if (lines == null) {
    try {
      lines = linkLines(utf8.decode(decodeBase64Loose(text)));
    } on FormatException {
      // Not Base64; try YAML below.
    }
  }
  if (lines != null) {
    return [
      for (final l in lines) {'link': l},
    ];
  }
  final doc = decodeYamlMap(text);
  final proxies = doc?['proxies'];
  if (proxies is! List) {
    throw const ImportException(ImportErrorCode.unknownFormat);
  }
  return [for (final p in proxies) _map(p)];
}

(NodeDef, String?) _proxy(
  JsonObject p,
  String type,
  String key,
  String name,
  void Function(WarningKind, String) warn,
) {
  // Provider entries may be share links.
  final link = p.str('link');
  if (link != null) {
    final n = parseShareLink(link);
    return (
      NodeDef(
        key: key,
        name: name.isEmpty || name == 'null' ? (n.name ?? n.server) : name,
        server: n.server,
        port: n.port,
        params: n.params,
      ),
      null,
    );
  }

  p.ignore(['name', 'type']);
  p.ignore(_dialOptions);
  final server = _need(p, 'server');
  final ports = p.str('ports');
  final port = p.integer('port');
  if ((port == null && ports == null) ||
      (port != null && (port < 1 || port > 65535))) {
    throw p.invalid('port');
  }
  final dialer = p.str('dialer-proxy');
  final smux = p.object('smux');
  if (smux != null && smux.flag('enabled')) {
    warn(WarningKind.ignoredNodeOption, 'smux');
  }

  final NodeParams params;
  switch (type) {
    case 'ss':
      final (plugin, opts) = _ssPlugin(p);
      params = NodeParams.shadowsocks(
        method: _need(p, 'cipher'),
        password: Secret(_need(p, 'password')),
        plugin: plugin,
        pluginOpts: opts,
      );
    case 'vmess':
      params = NodeParams.vmess(
        uuid: Secret(_need(p, 'uuid')),
        alterId: p.integer('alterId') ?? 0,
        cipher: p.str('cipher') ?? 'auto',
        transport: _transport(p),
        tls: p.flag('tls') ? _tls(p) : null,
      );
    case 'vless':
      final encryption = p.str('encryption');
      if (encryption != null && encryption != 'none') {
        throw const _Skip(WarningKind.unsupportedNodeOption, 'encryption');
      }
      final tls = p.flag('tls') || p.has('reality-opts') ? _tls(p) : null;
      params = NodeParams.vless(
        uuid: Secret(_need(p, 'uuid')),
        flow: p.str('flow'),
        transport: _transport(p),
        tls: tls,
      );
    case 'trojan':
      if (p.has('reality-opts')) {
        throw const _Skip(WarningKind.unsupportedNodeOption, 'reality-opts');
      }
      params = NodeParams.trojan(
        password: Secret(_need(p, 'password')),
        transport: _transport(p),
        tls: _tls(p),
      );
    case 'hysteria2':
      final obfs = p.str('obfs');
      if (obfs != null && obfs != 'salamander') {
        throw const _Skip(WarningKind.unsupportedNodeOption, 'obfs');
      }
      p.ignore(['hop-interval']);
      params = NodeParams.hysteria2(
        password: Secret(_need(p, 'password')),
        obfsPassword: obfs == null ? null : Secret(_need(p, 'obfs-password')),
        upMbps: _mbps(p, 'up'),
        downMbps: _mbps(p, 'down'),
        serverPorts: [
          for (final r in (ports ?? '').split(RegExp(r'[,/]')))
            if (r.trim().isNotEmpty) r.trim().replaceAll('-', ':'),
        ],
        tls: _tls(p),
      );
    case 'tuic':
      if (p.has('token')) {
        throw const _Skip(WarningKind.unsupportedNodeOption, 'tuic-v4');
      }
      p.ignore([
        'reduce-rtt', 'request-timeout', 'heartbeat-interval', //
        'max-udp-relay-packet-size', 'fast-open', 'max-open-streams',
        'disable-sni',
      ]);
      params = NodeParams.tuic(
        uuid: Secret(_need(p, 'uuid')),
        password: Secret(_need(p, 'password')),
        congestionControl: p.str('congestion-controller') ?? 'bbr',
        udpRelayMode: p.str('udp-relay-mode'),
        tls: _tls(p),
      );
    case 'socks5':
      final pass = p.str('password');
      params = NodeParams.socks5(
        username: p.str('username'),
        password: pass == null ? null : Secret(pass),
        tls: p.flag('tls') ? _tls(p) : null,
      );
    case 'http':
      final pass = p.str('password');
      if (p.has('headers')) {
        p.ignore(['headers']);
        warn(WarningKind.ignoredNodeOption, 'headers');
      }
      params = NodeParams.http(
        username: p.str('username'),
        password: pass == null ? null : Secret(pass),
        tls: p.flag('tls') ? _tls(p) : null,
      );
    default: // anytls
      p.ignore(['idle-session-timeout', 'min-idle-session']);
      params = NodeParams.anytls(
        password: Secret(_need(p, 'password')),
        idleSessionCheckInterval: p.str('idle-session-check-interval'),
        tls: _tls(p),
      );
  }

  for (final k in p.unread) {
    throw _Skip(WarningKind.unsupportedNodeOption, k);
  }
  return (
    NodeDef(
      key: key,
      name: name,
      server: server,
      port: port ?? 0,
      params: params,
    ),
    dialer,
  );
}

String _need(JsonObject o, String key) =>
    o.str(key) ??
    (throw ImportException(
      ImportErrorCode.missingField,
      field: '${o.path}.$key',
    ));

/// Bandwidth such as `50`, `50 Mbps` or `1 Gbps`, in Mbps.
int? _mbps(JsonObject p, String key) {
  final text = p.str(key);
  if (text == null) return null;
  final m = RegExp(
    r'^(\d+(?:\.\d+)?)\s*([kmgt]?)(bps)?$',
    caseSensitive: false,
  ).firstMatch(text);
  if (m == null) throw p.invalid(key);
  final n = double.parse(m.group(1)!);
  final scale = switch (m.group(2)!.toLowerCase()) {
    'k' => 0.001,
    'g' => 1000.0,
    't' => 1000000.0,
    _ => 1.0,
  };
  return (n * scale).round();
}

Tls _tls(JsonObject p) {
  if (p.has('fingerprint')) {
    throw const _Skip(WarningKind.unsupportedNodeOption, 'fingerprint');
  }
  if (p.has('ech-opts')) {
    throw const _Skip(WarningKind.unsupportedNodeOption, 'ech-opts');
  }
  p.ignore(['tls']);
  final reality = p.object('reality-opts');
  return Tls(
    serverName: p.str('servername') ?? p.str('sni'),
    insecure: p.flag('skip-cert-verify'),
    alpn: p.strings('alpn'),
    fingerprint: p.str('client-fingerprint'),
    reality: reality == null
        ? null
        : Reality(
            publicKey: _need(reality, 'public-key'),
            shortId: reality.str('short-id'),
          ),
  );
}

Transport _transport(JsonObject p) {
  final network = p.str('network') ?? 'tcp';
  switch (network) {
    case 'tcp':
      if (p.has('http-opts')) {
        throw const _Skip(WarningKind.unsupportedNodeOption, 'http-opts');
      }
      return const Transport.tcp();
    case 'ws':
      final o = p.object('ws-opts');
      if (o != null && o.flag('v2ray-http-upgrade')) {
        throw const _Skip(WarningKind.unsupportedNodeOption, 'http-upgrade');
      }
      final headers = o?.object('headers');
      final early = o?.integer('max-early-data') ?? 0;
      return Transport.ws(
        path: o?.str('path') ?? '/',
        host: headers?.str('Host') ?? headers?.str('host'),
        maxEarlyData: early,
        earlyDataHeader:
            o?.str('early-data-header-name') ??
            (early > 0 ? 'Sec-WebSocket-Protocol' : null),
      );
    case 'grpc':
      return Transport.grpc(
        serviceName: p.object('grpc-opts')?.str('grpc-service-name') ?? '',
      );
    case 'h2' || 'http':
      final o = p.object(network == 'h2' ? 'h2-opts' : 'http-opts');
      return Transport.http2(
        path: o?.strings('path').firstOrNull ?? '/',
        host: o?.strings('host') ?? const [],
      );
  }
  throw _Skip(WarningKind.unsupportedNodeOption, 'network.$network');
}

/// Clash `obfs`/`v2ray-plugin` options as sing-box plugin settings.
(String?, String?) _ssPlugin(JsonObject p) {
  final plugin = p.str('plugin');
  if (plugin == null) return (null, null);
  final o = p.object('plugin-opts');
  switch (plugin) {
    case 'obfs':
      return (
        'obfs-local',
        [
          'obfs=${o?.str('mode') ?? 'http'}',
          if (o?.str('host') != null) 'obfs-host=${o!.str('host')}',
        ].join(';'),
      );
    case 'v2ray-plugin':
      if (o != null && o.str('mode') != null && o.str('mode') != 'websocket') {
        throw const _Skip(
          WarningKind.unsupportedNodeOption,
          'plugin-opts.mode',
        );
      }
      return (
        'v2ray-plugin',
        [
          'mode=websocket',
          if (o?.flag('tls') ?? false) 'tls',
          if (o?.str('host') != null) 'host=${o!.str('host')}',
          if (o?.str('path') != null) 'path=${o!.str('path')}',
        ].join(';'),
      );
  }
  throw _Skip(WarningKind.unsupportedNodeOption, 'plugin.$plugin');
}

GroupDef _group(
  JsonObject g,
  String name,
  String? Function(String) resolve,
  Map<String, List<String>> providerNodes,
  Map<String, String> proxyKeys,
  void Function(WarningKind, String) warn,
) {
  final type = g.str('type');
  final (GroupType kind, String display) = switch (type) {
    'select' => (GroupType.selector, 'Selector'),
    'url-test' => (GroupType.urltest, 'URLTest'),
    'fallback' => (GroupType.urltest, 'Fallback'),
    'load-balance' => (GroupType.urltest, 'LoadBalance'),
    _ => throw _Skip(WarningKind.unsupportedGroupType, type ?? '?'),
  };
  if (display == 'Fallback' || display == 'LoadBalance') {
    warn(WarningKind.approximatedGroupType, display);
  }

  final members = <String>[];
  void add(String key) {
    if (!members.contains(key)) members.add(key);
  }

  for (final m in g.strings('proxies')) {
    final key = resolve(m);
    if (key == null) {
      warn(WarningKind.droppedMember, m);
    } else {
      add(key);
    }
  }
  final include = _regex(g.str('filter'));
  final exclude = _regex(g.str('exclude-filter'));
  bool keep(String key) {
    final n = key.substring(key.indexOf('/') + 1);
    final shown = key.startsWith('proxy:') ? key.substring(6) : n;
    return (include?.hasMatch(shown) ?? true) &&
        !(exclude?.hasMatch(shown) ?? false);
  }

  final all = g.flag('include-all');
  final providers = [
    ...g.strings('use'),
    if (all || g.flag('include-all-providers')) ...providerNodes.keys,
  ];
  for (final p in providers) {
    final keys = providerNodes[p];
    if (keys == null) {
      warn(WarningKind.droppedMember, p);
      continue;
    }
    keys.where(keep).forEach(add);
  }
  if (all || g.flag('include-all-proxies')) {
    proxyKeys.values.where(keep).forEach(add);
  }

  return GroupDef(
    key: 'group:$name',
    name: name,
    type: kind,
    displayType: display,
    members: members,
    test: kind == GroupType.urltest
        ? GroupTest(
            url: g.str('url') ?? defaultTestUrl,
            intervalSeconds: g.integer('interval') ?? 300,
            toleranceMs: g.integer('tolerance') ?? 50,
          )
        : null,
  );
}

RuleSetFormat? _ruleProviderFormat(String? behavior, String? format) {
  final text = format == 'text';
  if (format != null && format != 'yaml' && format != 'text') return null;
  return switch (behavior) {
    'domain' =>
      text ? RuleSetFormat.clashDomainText : RuleSetFormat.clashDomainYaml,
    'ipcidr' =>
      text ? RuleSetFormat.clashIpcidrText : RuleSetFormat.clashIpcidrYaml,
    'classical' =>
      text
          ? RuleSetFormat.clashClassicalText
          : RuleSetFormat.clashClassicalYaml,
    _ => null,
  };
}

/// Rule types with a sing-box equivalent (CONFIG_PIPELINE §4).
const _ruleTypes = {
  'DOMAIN', 'DOMAIN-SUFFIX', 'DOMAIN-KEYWORD', 'DOMAIN-REGEX', 'IP-CIDR', //
  'IP-CIDR6', 'SRC-IP-CIDR', 'PROCESS-NAME', 'PROCESS-PATH', 'NETWORK',
  'DST-PORT', 'GEOSITE', 'GEOIP', 'RULE-SET',
};

RuleDef _rule(
  String type,
  List<String> parts,
  String? Function(String) resolve,
  Map<String, RuleSetRef> ruleSets,
  Map<String, String?> providerSets,
) {
  if (!_ruleTypes.contains(type) || parts.length < 3) {
    throw _Skip(WarningKind.unsupportedRule, type);
  }
  final payload = parts[1];
  final targetName = parts[2];
  final target =
      resolve(targetName) ??
      (throw _Skip(WarningKind.droppedMember, targetName));
  RuleDef rule(RuleDef Function(RuleDef r) f) => f(RuleDef(target: target));

  switch (type) {
    case 'DOMAIN':
      return rule((r) => r.copyWith(domain: [payload]));
    case 'DOMAIN-SUFFIX':
      return rule((r) => r.copyWith(domainSuffix: [payload]));
    case 'DOMAIN-KEYWORD':
      return rule((r) => r.copyWith(domainKeyword: [payload]));
    case 'DOMAIN-REGEX':
      return rule((r) => r.copyWith(domainRegex: [payload]));
    case 'IP-CIDR' || 'IP-CIDR6':
      return rule((r) => r.copyWith(ipCidr: [payload]));
    case 'SRC-IP-CIDR':
      return rule((r) => r.copyWith(sourceIpCidr: [payload]));
    case 'PROCESS-NAME':
      return rule((r) => r.copyWith(processName: [payload]));
    case 'PROCESS-PATH':
      return rule((r) => r.copyWith(processPath: [payload]));
    case 'NETWORK':
      return rule((r) => r.copyWith(network: [payload.toLowerCase()]));
    case 'DST-PORT':
      final ports = <int>[];
      final ranges = <String>[];
      for (final p in payload.split('/')) {
        final n = int.tryParse(p);
        if (n != null) {
          ports.add(n);
        } else if (RegExp(r'^\d+-\d+$').hasMatch(p)) {
          ranges.add(p.replaceAll('-', ':'));
        } else {
          throw const _Skip(WarningKind.unsupportedRule, 'DST-PORT');
        }
      }
      return rule((r) => r.copyWith(port: ports, portRange: ranges));
    case 'GEOSITE':
      final set = RuleSetCatalog.geosite(payload);
      ruleSets.putIfAbsent(set.tag, () => set);
      return rule((r) => r.copyWith(ruleSet: [set.tag]));
    case 'GEOIP':
      if (const {'lan', 'private'}.contains(payload.toLowerCase())) {
        return rule((r) => r.copyWith(ipCidr: _privateCidrs));
      }
      final set = RuleSetCatalog.geoip(payload);
      ruleSets.putIfAbsent(set.tag, () => set);
      return rule((r) => r.copyWith(ruleSet: [set.tag]));
    case 'RULE-SET':
      if (!providerSets.containsKey(payload)) {
        throw _Skip(WarningKind.droppedMember, payload);
      }
      final tag =
          providerSets[payload] ??
          (throw _Skip(WarningKind.unsupportedRuleSet, payload));
      return rule((r) => r.copyWith(ruleSet: [tag]));
  }
  throw _Skip(WarningKind.unsupportedRule, type);
}
