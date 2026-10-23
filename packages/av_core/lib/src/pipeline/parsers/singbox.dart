import '../../domain/content.dart';
import '../../domain/node.dart';
import '../../domain/secret.dart';
import '../import_exception.dart';
import 'json_object.dart';
import 'uri_list.dart' show defaultTestUrl, insecureTls;

/// Skips one node or rule with a warning.
final class _Skip implements Exception {
  const _Skip(this.kind, this.subject);

  final WarningKind kind;
  final String subject;
}

/// Outbound options that only tune dialing; ignored silently.
const _dialOptions = {
  'bind_interface', 'inet4_bind_address', 'inet6_bind_address', //
  'routing_mark', 'reuse_addr', 'netns', 'connect_timeout',
  'tcp_fast_open', 'tcp_multi_path', 'udp_fragment', 'domain_strategy',
  'domain_resolver', 'fallback_delay', 'network_strategy', 'network_type',
  'fallback_network_type', 'network',
};

/// Options kept out of the plan, with a notice (the node still works).
const _noticedOptions = {'multiplex', 'udp_over_tcp', 'packet_encoding'};

const _nodeTypes = {
  'shadowsocks', 'vmess', 'vless', 'trojan', 'hysteria2', 'tuic', //
  'socks', 'http', 'anytls',
};

/// Sections replaced by Avalon's own settings (D29).
const _ignoredSections = {
  'log', 'dns', 'ntp', 'certificate', 'inbounds', 'experimental', //
  'services',
};

/// Parses a sing-box configuration (CONFIG_PIPELINE §4). Keys are
/// `tag:<tag>`.
ConfigContent parseSingBox(Map<String, Object?> json) {
  final root = JsonObject(json, r'$');
  final warnings = <ImportWarning>[];
  final counts = <(WarningKind, String), int>{};
  void warn(WarningKind kind, String subject) =>
      counts[(kind, subject)] = (counts[(kind, subject)] ?? 0) + 1;

  for (final s in _ignoredSections) {
    if (root.has(s)) warn(WarningKind.ignoredSection, s);
  }
  if (root.list('endpoints').isNotEmpty) {
    warn(WarningKind.unsupportedNodeType, 'endpoint');
  }

  final nodes = <NodeDef>[];
  final groups = <(JsonObject, String, String)>[]; // raw, key, type
  final builtins = <String, String>{}; // tag -> built-in key
  final known = <String>{};

  final outbounds = root.list('outbounds');
  for (var i = 0; i < outbounds.length; i++) {
    final raw = outbounds[i];
    if (raw is! Map) throw root.invalid('outbounds[$i]');
    final o = JsonObject(
      {for (final e in raw.entries) '${e.key}': e.value},
      r'$.outbounds'
      '[$i]',
    );
    final type = o.str('type') ?? '';
    final tag = o.str('tag');
    if (tag == null) {
      warn(WarningKind.unreadableEntry, 'outbounds[$i].tag');
      continue;
    }
    final key = 'tag:$tag';
    switch (type) {
      case 'direct':
        builtins[tag] = ContentKeys.direct;
      case 'block':
        builtins[tag] = ContentKeys.reject;
      case 'selector' || 'urltest':
        groups.add((o, key, type));
        known.add(key);
      case _ when _nodeTypes.contains(type):
        try {
          nodes.add(_node(o, type, key, tag, warn));
          known.add(key);
        } on _Skip catch (s) {
          warn(s.kind, s.subject);
        } on ImportException catch (e) {
          warn(WarningKind.unreadableEntry, e.field ?? tag);
        }
      default:
        warn(WarningKind.unsupportedNodeType, type.isEmpty ? '?' : type);
    }
  }

  String? resolve(String tag) =>
      builtins[tag] ?? (known.contains('tag:$tag') ? 'tag:$tag' : null);

  final groupDefs = <GroupDef>[];
  for (final (o, key, type) in groups) {
    final members = <String>[];
    for (final tag in o.strings('outbounds')) {
      final m = resolve(tag);
      if (m == null) {
        warn(WarningKind.droppedMember, tag);
      } else {
        members.add(m);
      }
    }
    final test = type == 'urltest'
        ? GroupTest(
            url: o.str('url') ?? defaultTestUrl,
            intervalSeconds: durationSeconds(o.str('interval')) ?? 180,
            toleranceMs: o.integer('tolerance') ?? 50,
          )
        : null;
    groupDefs.add(
      GroupDef(
        key: key,
        name: key.substring(4),
        type: type == 'selector' ? GroupType.selector : GroupType.urltest,
        displayType: type == 'selector' ? 'Selector' : 'URLTest',
        members: members,
        test: test,
      ),
    );
  }

  final route = root.object('route');
  final ruleSets = <RuleSetRef>[];
  final unusable = <String>{};
  for (final raw in route?.list('rule_set') ?? const <Object?>[]) {
    if (raw is! Map) continue;
    final r = JsonObject({
      for (final e in raw.entries) '${e.key}': e.value,
    }, r'$.route.rule_set');
    final tag = r.str('tag');
    if (tag == null) continue;
    final url = r.str('url');
    if (r.str('type') != 'remote' || url == null) {
      warn(WarningKind.unsupportedRuleSet, tag);
      unusable.add(tag);
      continue;
    }
    ruleSets.add(
      RuleSetRef(
        tag: tag,
        url: url,
        format: r.str('format') == 'source'
            ? RuleSetFormat.source
            : RuleSetFormat.binary,
      ),
    );
  }

  final rules = <RuleDef>[];
  final routeRules = route?.list('rules') ?? const <Object?>[];
  for (var i = 0; i < routeRules.length; i++) {
    final raw = routeRules[i];
    if (raw is! Map) continue;
    final r = JsonObject(
      {for (final e in raw.entries) '${e.key}': e.value},
      r'$.route.rules'
      '[$i]',
    );
    try {
      final rule = _rule(r, resolve, unusable);
      if (rule != null) rules.add(rule);
    } on _Skip catch (s) {
      warn(s.kind, s.subject);
    } on ImportException catch (e) {
      warn(WarningKind.unreadableEntry, e.field ?? 'route.rules[$i]');
    }
  }

  var finalTarget = ContentKeys.direct;
  final finalTag = route?.str('final');
  if (finalTag == null) {
    warn(WarningKind.missingFinal, '');
  } else {
    final f = resolve(finalTag);
    if (f == null) {
      warn(WarningKind.missingFinal, finalTag);
    } else {
      finalTarget = f;
    }
  }

  for (final e in counts.entries) {
    warnings.add(
      ImportWarning(kind: e.key.$1, subject: e.key.$2, count: e.value),
    );
  }
  final insecure = nodes.where((n) => insecureTls(n.params)).length;
  if (insecure > 0) {
    warnings.add(ImportWarning(kind: WarningKind.insecureTls, count: insecure));
  }

  return ConfigContent(
    nodes: nodes,
    groups: groupDefs,
    rules: rules,
    ruleSets: ruleSets,
    finalTarget: finalTarget,
    warnings: warnings,
  );
}

NodeDef _node(
  JsonObject o,
  String type,
  String key,
  String tag,
  void Function(WarningKind, String) warn,
) {
  o.ignore(['type', 'tag']);
  final server = _need(o, 'server');
  final port = o.integer('server_port');
  final hasPortHopping = type == 'hysteria2' && o.has('server_ports');
  if ((port == null && !hasPortHopping) ||
      (port != null && (port < 1 || port > 65535))) {
    throw o.invalid('server_port');
  }
  final detour = o.str('detour');
  o.ignore(_dialOptions);

  NodeParams params;
  switch (type) {
    case 'shadowsocks':
      params = NodeParams.shadowsocks(
        method: _need(o, 'method'),
        password: Secret(_need(o, 'password')),
        plugin: o.str('plugin'),
        pluginOpts: o.str('plugin_opts'),
      );
    case 'vmess':
      o.ignore(['global_padding', 'authenticated_length']);
      params = NodeParams.vmess(
        uuid: Secret(_need(o, 'uuid')),
        alterId: o.integer('alter_id') ?? 0,
        cipher: o.str('security') ?? 'auto',
        transport: _transport(o),
        tls: _tls(o, required: false),
      );
    case 'vless':
      params = NodeParams.vless(
        uuid: Secret(_need(o, 'uuid')),
        flow: o.str('flow'),
        transport: _transport(o),
        tls: _tls(o, required: false),
      );
    case 'trojan':
      params = NodeParams.trojan(
        password: Secret(_need(o, 'password')),
        transport: _transport(o),
        tls: _tls(o, required: true)!,
      );
    case 'hysteria2':
      final obfs = o.object('obfs');
      if (obfs != null && obfs.str('type') != 'salamander') {
        throw const _Skip(WarningKind.unsupportedNodeOption, 'obfs');
      }
      o.ignore(['hop_interval', 'brutal_debug']);
      params = NodeParams.hysteria2(
        password: Secret(_need(o, 'password')),
        obfsPassword: obfs == null ? null : Secret(_need(obfs, 'password')),
        upMbps: o.integer('up_mbps'),
        downMbps: o.integer('down_mbps'),
        serverPorts: o.strings('server_ports'),
        tls: _tls(o, required: true)!,
      );
    case 'tuic':
      o.ignore(['udp_over_stream', 'zero_rtt_handshake', 'heartbeat']);
      params = NodeParams.tuic(
        uuid: Secret(_need(o, 'uuid')),
        password: Secret(_need(o, 'password')),
        congestionControl: o.str('congestion_control') ?? 'bbr',
        udpRelayMode: o.str('udp_relay_mode'),
        tls: _tls(o, required: true)!,
      );
    case 'socks':
      final version = o.str('version') ?? '5';
      if (version != '5') {
        throw _Skip(WarningKind.unsupportedNodeOption, 'socks$version');
      }
      final pass = o.str('password');
      params = NodeParams.socks5(
        username: o.str('username'),
        password: pass == null ? null : Secret(pass),
      );
    case 'http':
      final pass = o.str('password');
      params = NodeParams.http(
        username: o.str('username'),
        password: pass == null ? null : Secret(pass),
        tls: _tls(o, required: false),
      );
    default: // anytls
      o.ignore(['idle_session_timeout', 'min_idle_session']);
      params = NodeParams.anytls(
        password: Secret(_need(o, 'password')),
        idleSessionCheckInterval: o.str('idle_session_check_interval'),
        tls: _tls(o, required: true)!,
      );
  }

  for (final k in o.unread) {
    if (_noticedOptions.contains(k)) {
      warn(WarningKind.ignoredNodeOption, k);
    } else {
      throw _Skip(WarningKind.unsupportedNodeOption, k);
    }
  }
  return NodeDef(
    key: key,
    name: tag,
    server: server,
    port: port ?? 0,
    params: params,
    detourKey: detour == null ? null : 'tag:$detour',
  );
}

String _need(JsonObject o, String key) =>
    o.str(key) ??
    (throw ImportException(
      ImportErrorCode.missingField,
      field: '${o.path}.$key',
    ));

Tls? _tls(JsonObject o, {required bool required}) {
  final t = o.object('tls');
  if (t == null || !t.flag('enabled')) {
    if (required) throw const _Skip(WarningKind.unsupportedNodeOption, 'tls');
    return null;
  }
  t.ignore(['min_version', 'max_version', 'cipher_suites', 'disable_sni']);
  final utls = t.object('utls');
  final reality = t.object('reality');
  final tls = Tls(
    serverName: t.str('server_name'),
    insecure: t.flag('insecure'),
    alpn: t.strings('alpn'),
    fingerprint: utls != null && utls.flag('enabled')
        ? utls.str('fingerprint') ?? 'chrome'
        : null,
    reality: reality != null && reality.flag('enabled')
        ? Reality(
            publicKey: _need(reality, 'public_key'),
            shortId: reality.str('short_id'),
          )
        : null,
  );
  for (final k in t.unread) {
    throw _Skip(WarningKind.unsupportedNodeOption, 'tls.$k');
  }
  return tls;
}

Transport _transport(JsonObject o) {
  final t = o.object('transport');
  if (t == null) return const Transport.tcp();
  final type = t.str('type');
  switch (type) {
    case 'ws':
      final headers = t.object('headers');
      final early = t.integer('max_early_data') ?? 0;
      return Transport.ws(
        path: t.str('path') ?? '/',
        host: headers?.str('Host') ?? headers?.str('host'),
        maxEarlyData: early,
        earlyDataHeader: t.str('early_data_header_name'),
      );
    case 'grpc':
      t.ignore(['idle_timeout', 'ping_timeout', 'permit_without_stream']);
      return Transport.grpc(serviceName: t.str('service_name') ?? '');
    case 'http':
      t.ignore(['idle_timeout', 'ping_timeout']);
      return Transport.http2(
        path: t.str('path') ?? '/',
        host: t.strings('host'),
      );
  }
  throw _Skip(WarningKind.unsupportedNodeOption, 'transport.${type ?? '?'}');
}

const _ruleFields = {
  'domain', 'domain_suffix', 'domain_keyword', 'domain_regex', 'ip_cidr', //
  'source_ip_cidr', 'rule_set', 'process_name', 'process_path', 'port',
  'port_range', 'network', 'invert', 'outbound', 'action', 'type',
};

/// Actions Avalon generates itself (CONFIG_PIPELINE §6).
const _ownActions = {'sniff', 'hijack-dns'};

RuleDef? _rule(
  JsonObject r,
  String? Function(String tag) resolve,
  Set<String> unusableRuleSets,
) {
  final action = r.str('action') ?? 'route';
  if (_ownActions.contains(action)) return null;
  if (r.has('clash_mode')) return null; // Avalon adds the mode rules.
  if (r.str('type') == 'logical') {
    throw const _Skip(WarningKind.unsupportedRule, 'logical');
  }
  for (final k in r.map.keys) {
    if (!_ruleFields.contains(k)) throw _Skip(WarningKind.unsupportedRule, k);
  }
  final String target;
  switch (action) {
    case 'route':
      final out = r.str('outbound');
      if (out == null) {
        throw const _Skip(WarningKind.unsupportedRule, 'outbound');
      }
      target = resolve(out) ?? (throw _Skip(WarningKind.droppedMember, out));
    case 'reject':
      target = ContentKeys.reject;
    default:
      throw _Skip(WarningKind.unsupportedRule, action);
  }
  final sets = r.strings('rule_set');
  for (final s in sets) {
    if (unusableRuleSets.contains(s)) {
      throw _Skip(WarningKind.unsupportedRuleSet, s);
    }
  }
  final ports = <int>[];
  for (final p in r.strings('port')) {
    ports.add(int.tryParse(p) ?? (throw r.invalid('port')));
  }
  return RuleDef(
    domain: r.strings('domain'),
    domainSuffix: r.strings('domain_suffix'),
    domainKeyword: r.strings('domain_keyword'),
    domainRegex: r.strings('domain_regex'),
    ipCidr: r.strings('ip_cidr'),
    sourceIpCidr: r.strings('source_ip_cidr'),
    ruleSet: sets,
    processName: r.strings('process_name'),
    processPath: r.strings('process_path'),
    port: ports,
    portRange: r.strings('port_range'),
    network: r.strings('network'),
    invert: r.flag('invert'),
    target: target,
  );
}
