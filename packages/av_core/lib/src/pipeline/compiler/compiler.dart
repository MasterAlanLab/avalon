import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../domain/content.dart';
import '../../domain/node.dart';
import '../../domain/refs.dart';
import '../../domain/settings.dart';
import '../members.dart';
import '../rule_set_convert.dart';
import '../rule_sets.dart';
import 'compile_input.dart';
import 'outbound.dart';
import 'override.dart';
import 'plan.dart';
import 'plan_hash.dart';

/// Compiles one consistent snapshot into a sing-box configuration
/// (CONFIG_PIPELINE §6–7). Throws [CompileException]; never produces a
/// partial plan or drops content to make it compile.
CompiledPlan compile(CompileInput input) => _Compiler(input).run();

/// Tag of the injected 「自定义」 group.
const customTag = 'g:custom';
const _direct = 'direct';
const _reject = 'reject';
const _ts = 'ts-ep';
const _metacubexd =
    'https://github.com/MetaCubeX/metacubexd/archive/refs/heads/gh-pages.zip';
const _tailnetCidrs = ['100.64.0.0/10', 'fd7a:115c:a1e0::/48'];

final class _Compiler {
  _Compiler(this.input)
    : settings = input.settings,
      host = input.host,
      configId = switch (input.source) {
        ImportedSource(:final id) => id,
        SelfSource() => SelfSource.id,
      },
      content = switch (input.source) {
        ImportedSource(:final content) => content,
        SelfSource() => const ConfigContent(finalTarget: ContentKeys.custom),
      };

  final CompileInput input;
  final DeviceSettings settings;
  final HostInfo host;
  final String configId;
  final ConfigContent content;

  bool get isSelf => input.source is SelfSource;
  bool get tailnetActive => input.tailnet;

  final _outbounds = <String, Map<String, Object?>>{};
  final _tags = <String, PlanTag>{};

  /// Why a node, self node or chain tag could not be built.
  final _unavailable = <String, String>{};
  // A failed group is fatal only if the plan needs it.
  final _groups = <String, Object>{}; // key -> tag or CompileException
  final _groupMembers = <String, List<String>>{}; // key -> member keys
  final _building = <String>{};

  // ---------------------------------------------------------------- names

  static String _h(String key) =>
      sha256.convert(utf8.encode(key)).toString().substring(0, 10);

  String _nodeTag(String key) =>
      'n:${configId.length > 8 ? configId.substring(0, 8) : configId}:${_h(key)}';

  static String _groupTag(String key) =>
      key == ContentKeys.custom ? customTag : 'g:${_h(key)}';

  late final _catalog = MemberCatalog(
    configurationId: configId,
    content: content,
    otherContents: input.otherContents,
    selfNodes: input.selfNodes,
    chains: input.chains,
    memberships: input.memberships,
    tailnetExit: tailnetActive ? settings.tailnet.exit : null,
  );

  // -------------------------------------------------------------- members

  /// Tag for a content key (node, group or built-in) as a rule target or
  /// the final target; null with a reason in [_unavailable] / [_groups].
  /// Reject is null here: rules reject with an action, not an outbound.
  String? _keyTag(String key) {
    if (key == ContentKeys.direct) return _direct;
    if (key == ContentKeys.reject) return null;
    if (content.node(key) != null) return _contentNode(key);
    if (content.group(key) != null || key == ContentKeys.custom) {
      final g = _group(key);
      return g is String ? g : null;
    }
    return null;
  }

  String? _contentNode(String key) {
    final tag = _nodeTag(key);
    if (_outbounds.containsKey(tag)) return tag;
    if (_unavailable.containsKey(tag)) return null;
    final node = content.node(key)!;
    String? detour;
    if (node.detourKey case final d?) {
      detour = _keyTag(d);
      if (detour == null) {
        _unavailable[tag] = 'detour';
        return null;
      }
    }
    try {
      _outbounds[tag] = nodeOutbound(
        tag: tag,
        server: node.server,
        port: node.port,
        params: node.params,
        detour: detour,
      );
    } on UnsupportedNode catch (e) {
      _unavailable[tag] = e.reason;
      return null;
    }
    _tags[tag] = PlanTag(
      MemberRef.source(configurationId: configId, key: key),
      node.name,
    );
    return tag;
  }

  String? _selfNode(String id) {
    final tag = 's:$id';
    if (_outbounds.containsKey(tag)) return tag;
    if (_unavailable.containsKey(tag)) return null;
    final n = _catalog.selfNode(id);
    if (n == null) {
      _unavailable[tag] = 'missing';
      return null;
    }
    try {
      _outbounds[tag] = nodeOutbound(
        tag: tag,
        server: n.server,
        port: n.port,
        params: n.params,
      );
    } on UnsupportedNode catch (e) {
      _unavailable[tag] = e.reason;
      return null;
    }
    _tags[tag] = PlanTag(MemberRef.selfNode(id: id), n.name);
    return tag;
  }

  /// Chain `[A, B, C]` becomes instances `c:<id>:0..2`, each dialing
  /// through the previous one; the chain is the last instance.
  String? _chainTag(String id) {
    final key = 'c:$id';
    if (_unavailable.containsKey(key)) return null;
    final chain = _catalog.chain(id);
    if (chain == null) return _fail(key, 'missing');
    if (chain.hops.length < 2) return _fail(key, 'hops');
    final last = 'c:$id:${chain.hops.length - 1}';
    if (_outbounds.containsKey(last)) return last;

    final built = <(String, Map<String, Object?>, PlanTag)>[];
    for (final (i, hop) in chain.hops.indexed) {
      final node = _hop(hop, key);
      if (node == null) return null;
      final tag = 'c:$id:$i';
      try {
        built.add((
          tag,
          nodeOutbound(
            tag: tag,
            server: node.server,
            port: node.port,
            params: node.params,
            detour: i == 0 ? null : 'c:$id:${i - 1}',
          ),
          PlanTag(hop, node.name),
        ));
      } on UnsupportedNode catch (e) {
        return _fail(key, e.reason);
      }
    }
    for (final (tag, outbound, planTag) in built) {
      _outbounds[tag] = outbound;
      _tags[tag] = planTag;
    }
    _tags[last] = PlanTag(MemberRef.chain(id: id), _catalog.chainName(chain)!);
    return last;
  }

  /// The node a chain hop stands for; null (with the reason recorded under
  /// [key]) when the hop cannot be used.
  ({String server, int port, NodeParams params, String name})? _hop(
    MemberRef hop,
    String key,
  ) {
    switch (hop) {
      case SourceMember(:final configurationId, key: final nodeKey):
        final source = configurationId == configId
            ? content
            : input.otherContents[configurationId];
        final node = source?.node(nodeKey);
        if (node == null) {
          _fail(
            key,
            source?.group(nodeKey) != null ? 'hop-group' : 'hop-missing',
          );
          return null;
        }
        return (
          server: node.server,
          port: node.port,
          params: node.params,
          name: node.name,
        );
      case SelfNodeRef(:final id):
        final node = _catalog.selfNode(id);
        if (node == null) {
          _fail(key, 'hop-missing');
          return null;
        }
        return (
          server: node.server,
          port: node.port,
          params: node.params,
          name: node.name,
        );
      case TailnetExitRef():
        // Whether an exit node can be a hop is decided by S3.
        _fail(key, 'tailnet-hop');
        return null;
      case ChainRef() || BuiltinRef():
        _fail(key, 'hop-kind');
        return null;
    }
  }

  String? _fail(String key, String reason) {
    _unavailable[key] = reason;
    return null;
  }

  /// Resolves any member reference; returns the tag or the reason it is
  /// unusable.
  (String?, String) _member(MemberRef ref) {
    switch (ref) {
      case SourceMember(:final configurationId, :final key):
        if (configurationId != configId) return (null, 'other-configuration');
        if (key == ContentKeys.reject) return (_rejectTag(), '');
        final tag = _keyTag(key);
        if (tag != null) return (tag, '');
        final failed = _groups[key];
        if (failed is CompileException) return (null, failed.detail);
        return (null, _unavailable[_nodeTag(key)] ?? 'missing');
      case SelfNodeRef(:final id):
        return (_selfNode(id), _unavailable['s:$id'] ?? '');
      case ChainRef(:final id):
        return (_chainTag(id), _unavailable['c:$id'] ?? '');
      case TailnetExitRef():
        final ok = tailnetActive && settings.tailnet.exit == ref;
        return ok ? (_ts, '') : (null, 'tailnet-exit');
      case BuiltinRef(:final builtin):
        return builtin == Builtin.direct ? (_direct, '') : (_rejectTag(), '');
    }
  }

  /// REJECT as a member of a group: one `block` outbound, added when a
  /// group first uses it. (Rules that reject use `action: reject` instead.)
  String _rejectTag() {
    _outbounds.putIfAbsent(_reject, () => {'type': 'block', 'tag': _reject});
    _tags[_reject] = const PlanTag(
      MemberRef.builtin(builtin: Builtin.reject),
      'REJECT',
    );
    return _reject;
  }

  // --------------------------------------------------------------- groups

  /// Builds a group (memoized). Returns its tag or a [CompileException].
  Object _group(String key) {
    final done = _groups[key];
    if (done != null) return done;
    final tag = _groupTag(key);
    if (!_building.add(key)) {
      return CompileException(
        CompileErrorCode.memberUnavailable,
        subject: _catalog.displayName(key),
        detail: 'cycle',
      );
    }
    final result = _buildGroup(key, tag);
    _building.remove(key);
    _groups[key] = result;
    return result;
  }

  Object _buildGroup(String key, String tag) {
    final def = content.group(key);
    final isSelector = def == null || def.type == GroupType.selector;
    final name = _catalog.displayName(key);
    final members = <String>[];
    final memberKeys = <String>[];
    final refs = _catalog.membersOf(key);
    for (final ref in refs) {
      final (t, reason) = _member(ref);
      // A group that picks by latency has nothing to measure on REJECT.
      if (t == _reject && !isSelector) continue;
      if (t == null) {
        if (!isSelector) {
          return CompileException(
            CompileErrorCode.memberUnavailable,
            subject: _catalog.name(ref),
            detail: reason,
          );
        }
        continue;
      }
      if (!members.contains(t)) members.add(t);
      if (ref case SourceMember(key: final k)) memberKeys.add(k);
    }
    _groupMembers[key] = memberKeys;

    String? selected;
    if (isSelector) {
      final choice = input.selections[key];
      // A choice that left the group (e.g. the node vanished on refresh)
      // falls back to the first member; one that is still a member but
      // cannot be built is an error (PRODUCT_SPEC §3.2).
      if (choice != null && refs.contains(choice)) {
        final (t, reason) = _member(choice);
        if (t == null) {
          return CompileException(
            CompileErrorCode.memberUnavailable,
            subject: _catalog.name(choice),
            detail: reason,
          );
        }
        selected = t;
      }
    }
    if (members.isEmpty) {
      return CompileException(CompileErrorCode.emptyGroup, subject: name);
    }
    final intervalSeconds = def?.test?.intervalSeconds ?? 180;
    _outbounds[tag] = isSelector
        ? {
            'type': 'selector',
            'tag': tag,
            'outbounds': members,
            'default': selected ?? members.first,
            'interrupt_exist_connections': true,
          }
        : {
            'type': 'urltest',
            'tag': tag,
            'outbounds': members,
            'url': def.test?.url ?? settings.testUrl,
            'interval': '${intervalSeconds}s',
            // The pinned core defaults idle_timeout to 30 minutes and
            // refuses longer intervals. Preserve the imported cadence.
            if (intervalSeconds > 1800) 'idle_timeout': '${intervalSeconds}s',
            'tolerance': def.test?.toleranceMs ?? 50,
            'interrupt_exist_connections': true,
          };
    _tags[tag] = PlanTag(
      MemberRef.source(configurationId: configId, key: key),
      name,
    );
    return tag;
  }

  /// Fails with the group's error when the plan needs it (or anything it
  /// contains).
  void _require(String key, [Set<String>? seen]) {
    seen ??= {};
    if (!seen.add(key)) return;
    if (content.node(key) != null) {
      if (_contentNode(key) == null) {
        throw CompileException(
          CompileErrorCode.memberUnavailable,
          subject: _catalog.displayName(key),
          detail: _unavailable[_nodeTag(key)] ?? '',
        );
      }
      return;
    }
    if (content.group(key) == null && key != ContentKeys.custom) return;
    final g = _group(key);
    if (g is CompileException) throw g;
    for (final m in _groupMembers[key] ?? const <String>[]) {
      _require(m, seen);
    }
  }

  // ------------------------------------------------------------------ run

  CompiledPlan run() {
    if (!input.proxy && !input.tailnet) {
      throw const CompileException(CompileErrorCode.nothingToRun);
    }
    final override = isSelf
        ? OverrideDoc.empty
        : parseOverride(input.policy.jsonOverride?.value ?? '');
    final tree = input.proxy ? _proxyPlan(override) : _tailnetOnlyPlan();
    return CompiledPlan(
      tree: tree,
      planHash: planHash(
        _withoutChoices(tree),
        key: input.hashKey,
        bridgeVersion: host.bridgeVersion,
        coreVersion: host.coreVersion,
      ),
      tags: Map.unmodifiable(_tags),
      primaryTag: _primary ?? _direct,
    );
  }

  String? _primary;

  Map<String, Object?> _proxyPlan(OverrideDoc override) {
    _outbounds[_direct] = {'type': 'direct', 'tag': _direct};
    _tags[_direct] = const PlanTag(
      MemberRef.builtin(builtin: Builtin.direct),
      'DIRECT',
    );

    // Everything is offered to the plan so any member can be tested; what
    // the plan needs is checked below.
    for (final n in content.nodes) {
      _contentNode(n.key);
    }
    for (final n in input.selfNodes) {
      _selfNode(n.id);
    }
    for (final c in input.chains) {
      _chainTag(c.id);
    }
    for (final g in content.groups) {
      _group(g.key);
    }
    _group(ContentKeys.custom);

    // Main selector and final target.
    final primaryKey = isSelf
        ? ContentKeys.custom
        : content.primaryGroup?.key ?? content.finalTarget;
    if (primaryKey != ContentKeys.reject) {
      _require(primaryKey);
      _primary = _keyTag(primaryKey);
    }
    final rejectAll = content.finalTarget == ContentKeys.reject;
    String finalTag = _direct;
    if (!rejectAll) {
      _require(content.finalTarget);
      finalTag = _keyTag(content.finalTarget)!;
    }
    final primary = _primary ?? _direct;
    final downloadDetour = input.policy.geoVia == DownloadVia.proxy
        ? primary
        : _direct;

    // Rules, in CONFIG_PIPELINE §6 order.
    final ruleSetTags = <String>{RuleSetCatalog.dnsTag}; // DNS rule 4
    final rules = <Map<String, Object?>>[
      if (settings.sniff) {'action': 'sniff'},
      {'protocol': 'dns', 'action': 'hijack-dns'},
      if (tailnetActive) ..._tailnetRules(),
      ..._perAppRules(),
      if (settings.bypassLan) {'ip_is_private': true, 'outbound': _direct},
      // The core derives its mode list from rule conditions. Register
      // rule even when default_mode is global/direct: direct && !rule
      // matches exactly direct, preserving this rule's routing behavior.
      {
        'type': 'logical',
        'mode': 'and',
        'rules': [
          {'clash_mode': 'direct'},
          {'clash_mode': 'rule', 'invert': true},
        ],
        'outbound': _direct,
      },
      {'clash_mode': 'global', 'outbound': primary},
    ];

    String? overrideName(String name) => _overrideTag(name, override);
    for (final (i, r) in override.routeRules.indexed) {
      rules.add(
        rewriteReferences(
          r,
          r'$.route.rules'
          '[$i]',
          overrideName,
        ),
      );
      ruleSetTags.addAll(_ruleSetsOf(r));
    }

    if (isSelf || content.defaultRules) {
      for (final tag in RuleSetCatalog.defaultTags) {
        rules.add({'rule_set': tag, 'outbound': _direct});
        ruleSetTags.add(tag);
      }
    } else {
      for (final r in content.rules) {
        rules.add(_rule(r));
        ruleSetTags.addAll(r.ruleSet);
      }
    }
    if (rejectAll) rules.add({'action': 'reject'});

    // Rule sets: imported definitions, the default catalog, then override.
    final overrideSets = {
      for (final s in override.ruleSets) s['tag']! as String,
    };
    final ruleSets = <Map<String, Object?>>[];
    for (final tag in ruleSetTags) {
      if (overrideSets.contains(tag)) continue;
      ruleSets.add(_ruleSet(_ruleSetRef(tag), downloadDetour));
    }
    for (final (i, s) in override.ruleSets.indexed) {
      ruleSets.add(
        rewriteReferences(
          s,
          r'$.route.rule_set'
          '[$i]',
          overrideName,
        ),
      );
    }

    // Override outbounds: tags must not collide with generated ones.
    for (final (i, o) in override.outbounds.indexed) {
      final tag = o['tag']! as String;
      if (_outbounds.containsKey(tag) || tag == _ts) {
        throw CompileException(
          CompileErrorCode.overrideConflict,
          subject: tag,
          detail:
              r'$.outbounds'
              '[$i]',
        );
      }
    }
    final extraOutbounds = [
      for (final (i, o) in override.outbounds.indexed)
        rewriteReferences(
          o,
          r'$.outbounds'
          '[$i]',
          overrideName,
        ),
    ];
    if (override.routeFinal case final f?) {
      finalTag =
          overrideName(f) ??
          (throw CompileException(
            CompileErrorCode.overrideReference,
            subject: f,
            detail: r'$.route.final',
          ));
    }

    return {
      'log': {'level': settings.logLevel.name},
      'dns': _dns(primary, override),
      'inbounds': [
        if (settings.tunEnabled ||
            tailnetActive ||
            host.platform == HostPlatform.ios)
          _tun(
            withProxy: settings.tunEnabled || host.platform == HostPlatform.ios,
          ),
        {
          'type': 'mixed',
          'tag': 'mixed-in',
          'listen': settings.allowLan
              ? (settings.ipv6 ? '::' : '0.0.0.0')
              : '127.0.0.1',
          'listen_port': settings.mixedPort,
        },
      ],
      if (tailnetActive) 'endpoints': [_tailnetEndpoint()],
      'outbounds': [..._outbounds.values, ...extraOutbounds],
      'route': {
        'rules': rules,
        'rule_set': ruleSets,
        'final': finalTag,
        'auto_detect_interface': true,
        if (!host.isMobile || host.platform == HostPlatform.android)
          'find_process': settings.findProcess,
        'default_domain_resolver': 'direct',
      },
      'experimental': {
        // With the controller off the API still carries the mode; S5
        // confirms clash_mode works without a listener.
        'clash_api': {
          if (settings.clashApi) ...{
            'external_controller': settings.clashApiListen,
            'secret': ?settings.clashApiSecret,
            'external_ui': 'ui',
            'external_ui_download_url': _metacubexd,
            'external_ui_download_detour': downloadDetour,
          },
          'default_mode': settings.mode.name,
        },
        'cache_file': {
          'enabled': true,
          'path': '${host.stateDir}/cache.db',
          'store_fakeip': settings.fakeIp,
        },
      },
    };
  }

  /// Tailnet-only plan: only Tailscale addresses go through the TUN
  /// (CONFIG_PIPELINE §6).
  Map<String, Object?> _tailnetOnlyPlan() {
    _outbounds[_direct] = {'type': 'direct', 'tag': _direct};
    return {
      'log': {'level': settings.logLevel.name},
      'dns': {
        'servers': [
          {'type': 'local', 'tag': 'local'},
          if (settings.tailnet.magicDns)
            {
              'type': 'tailscale',
              'tag': 'ts',
              'endpoint': _ts,
              'accept_search_domain': true,
            },
        ],
        'rules': [
          if (settings.tailnet.magicDns)
            {
              'preferred_by': ['ts'],
              'server': 'ts',
            },
          if (settings.tailnet.magicDns)
            {
              'domain_suffix': ['ts.net'],
              'server': 'ts',
            },
        ],
        'final': 'local',
      },
      'inbounds': [_tun(withProxy: false)],
      'endpoints': [_tailnetEndpoint()],
      'outbounds': [..._outbounds.values],
      'route': {
        'rules': [
          if (settings.sniff) {'action': 'sniff'},
          {'protocol': 'dns', 'action': 'hijack-dns'},
          ..._tailnetRules(),
        ],
        'final': _direct,
        'auto_detect_interface': true,
        // The Tailscale endpoint reaches its control server by name; the
        // core refuses an endpoint with nothing to resolve it.
        'default_domain_resolver': 'local',
      },
      'experimental': {
        'cache_file': {'enabled': true, 'path': '${host.stateDir}/cache.db'},
      },
    };
  }

  List<Map<String, Object?>> _tailnetRules() => [
    {'ip_cidr': _tailnetCidrs, 'outbound': _ts},
    {
      'domain_suffix': ['ts.net'],
      'outbound': _ts,
    },
    {
      'preferred_by': [_ts],
      'outbound': _ts,
    },
  ];

  Map<String, Object?> _tailnetEndpoint() {
    final t = settings.tailnet;
    if (t.exit != null || t.advertiseExit) {
      throw const CompileException(
        CompileErrorCode.invalidSetting,
        subject: 'tailnet.exit',
        detail: 'tailnetExitRoutingUnverified',
      );
    }
    return {
      'type': 'tailscale',
      'tag': _ts,
      'state_directory': '${host.stateDir}/tailscale',
      'hostname': host.deviceName,
      'accept_routes': t.acceptRoutes,
      'advertise_exit_node': t.advertiseExit,
      if (t.exit case final e?) 'exit_node': e.name,
    };
  }

  List<Map<String, Object?>> _perAppRules() {
    if (host.isMobile || settings.perAppList.isEmpty) return const [];
    if (!settings.findProcess) {
      throw const CompileException(CompileErrorCode.perAppNeedsFindProcess);
    }
    // A macOS app is a bundle: its own executable and the helper processes
    // inside it (browsers network from those) all count as the app.
    final bundles = [
      for (final p in settings.perAppList)
        if (host.platform == HostPlatform.macos && p.endsWith('.app')) p,
    ];
    final paths = [
      for (final p in settings.perAppList)
        if (!bundles.contains(p)) p,
    ];
    return [
      {
        if (paths.isNotEmpty) 'process_path': paths,
        if (bundles.isNotEmpty)
          'process_path_regex': [
            for (final b in bundles) '^${RegExp.escape(b)}/',
          ],
        if (settings.perAppMode == PerAppMode.whitelist) 'invert': true,
        'outbound': _direct,
      },
    ];
  }

  Map<String, Object?> _tun({required bool withProxy}) {
    final android = host.platform == HostPlatform.android;
    final perApp = android && withProxy && settings.perAppList.isNotEmpty;
    return {
      'type': 'tun',
      'tag': 'tun-in',
      'address': ['172.19.0.1/30', if (settings.ipv6) 'fdfe:dcba:9876::1/126'],
      'mtu': settings.mtu,
      'auto_route': withProxy ? settings.autoRoute : true,
      'strict_route': withProxy ? settings.strictRoute : false,
      'stack': settings.tunStack.name,
      if (!withProxy) 'route_address': [..._tailnetCidrs, '100.100.100.100/32'],
      if (withProxy && settings.systemProxy && (android || host.isApple))
        'platform': {
          'http_proxy': {
            'enabled': true,
            'server': '127.0.0.1',
            'server_port': settings.mixedPort,
          },
        },
      if (perApp && settings.perAppMode == PerAppMode.whitelist)
        'include_package': settings.perAppList,
      if (perApp && settings.perAppMode == PerAppMode.blacklist)
        'exclude_package': settings.perAppList,
    };
  }

  Map<String, Object?> _dns(String primary, OverrideDoc override) {
    final remote = _dnsServer(settings.remoteDns, 'remote', detour: primary);
    final direct = _dnsServer(settings.directDns, 'direct');
    final magic = tailnetActive && settings.tailnet.magicDns;
    final own = {'remote', 'direct', 'fakeip', 'ts'};
    for (final (i, s) in override.dnsServers.indexed) {
      if (own.contains(s['tag'])) {
        throw CompileException(
          CompileErrorCode.overrideConflict,
          subject: s['tag']! as String,
          detail:
              r'$.dns.servers'
              '[$i]',
        );
      }
    }
    String? overrideName(String n) => _overrideTag(n, override);
    return {
      'servers': [
        remote,
        direct,
        if (settings.fakeIp)
          {
            'type': 'fakeip',
            'tag': 'fakeip',
            'inet4_range': '198.18.0.0/15',
            if (settings.ipv6) 'inet6_range': 'fc00::/18',
          },
        if (magic)
          {
            'type': 'tailscale',
            'tag': 'ts',
            'endpoint': _ts,
            'accept_search_domain': true,
          },
        for (final (i, s) in override.dnsServers.indexed)
          rewriteReferences(
            s,
            r'$.dns.servers'
            '[$i]',
            overrideName,
          ),
      ],
      'rules': [
        if (magic)
          {
            'preferred_by': ['ts'],
            'server': 'ts',
          },
        if (magic)
          {
            'domain_suffix': ['ts.net'],
            'server': 'ts',
          },
        {'clash_mode': 'direct', 'server': 'direct'},
        ...override.dnsRules,
        {'rule_set': 'geosite-cn', 'server': 'direct'},
        if (settings.fakeIp)
          {
            'query_type': ['A', 'AAAA'],
            'server': 'fakeip',
          },
      ],
      'final': 'remote',
      'strategy': settings.ipv6
          ? switch (settings.dnsStrategy) {
              DnsStrategy.preferIpv4 => 'prefer_ipv4',
              DnsStrategy.ipv4Only => 'ipv4_only',
              DnsStrategy.preferIpv6 => 'prefer_ipv6',
            }
          : 'ipv4_only',
    };
  }

  /// `https://host/path`, `tls://host[:port]`, `udp://ip[:port]` or a bare
  /// IP (PRODUCT_SPEC §3.10).
  Map<String, Object?> _dnsServer(String text, String tag, {String? detour}) {
    final value = text.trim();
    final uri = Uri.tryParse(value.contains('://') ? value : 'udp://$value');
    final scheme = uri?.scheme;
    final hostName = uri?.host ?? '';
    final allowed = tag == 'remote' ? {'https', 'tls'} : {'udp'};
    if (uri == null || hostName.isEmpty || !allowed.contains(scheme)) {
      throw CompileException(
        CompileErrorCode.invalidSetting,
        subject: tag == 'remote' ? 'remoteDns' : 'directDns',
      );
    }
    final isIp = RegExp(r'^[\d.]+$|:').hasMatch(hostName);
    if (tag == 'direct' && !isIp) {
      throw const CompileException(
        CompileErrorCode.invalidSetting,
        subject: 'directDns',
      );
    }
    return {
      'type': scheme,
      'tag': tag,
      'server': hostName,
      if (uri.hasPort) 'server_port': uri.port,
      if (scheme == 'https') 'path': uri.path.isEmpty ? '/dns-query' : uri.path,
      if (!isIp) 'domain_resolver': 'direct',
      'detour': ?detour,
    };
  }

  Map<String, Object?> _rule(RuleDef r) {
    final Map<String, Object?> action;
    if (r.target == ContentKeys.reject) {
      action = {'action': 'reject'};
    } else {
      _require(r.target);
      action = {'outbound': _keyTag(r.target)!};
    }
    return {
      if (r.domain.isNotEmpty) 'domain': r.domain,
      if (r.domainSuffix.isNotEmpty) 'domain_suffix': r.domainSuffix,
      if (r.domainKeyword.isNotEmpty) 'domain_keyword': r.domainKeyword,
      if (r.domainRegex.isNotEmpty) 'domain_regex': r.domainRegex,
      if (r.ipCidr.isNotEmpty) 'ip_cidr': r.ipCidr,
      if (r.sourceIpCidr.isNotEmpty) 'source_ip_cidr': r.sourceIpCidr,
      if (r.ruleSet.isNotEmpty) 'rule_set': r.ruleSet,
      if (r.processName.isNotEmpty) 'process_name': r.processName,
      if (r.processPath.isNotEmpty) 'process_path': r.processPath,
      if (r.port.isNotEmpty) 'port': r.port,
      if (r.portRange.isNotEmpty) 'port_range': r.portRange,
      if (r.network.isNotEmpty)
        'network': r.network.length == 1 ? r.network.single : r.network,
      if (r.invert) 'invert': true,
      ...action,
    };
  }

  RuleSetRef _ruleSetRef(String tag) =>
      RuleSetCatalog.resolve(tag, content) ??
      (throw CompileException(CompileErrorCode.ruleSetMissing, subject: tag));

  Map<String, Object?> _ruleSet(RuleSetRef r, String detour) {
    final cached = input.ruleSetCache[ruleSetKey(r)];
    final binary = r.format == RuleSetFormat.binary;
    if (cached != null) {
      return {
        'type': 'local',
        'tag': r.tag,
        'format': binary ? 'binary' : 'source',
        'path': cached,
      };
    }
    // Clash rule providers need converting first (CONFIG_PIPELINE §8).
    if (!binary && r.format != RuleSetFormat.source) {
      throw CompileException(CompileErrorCode.ruleSetMissing, subject: r.tag);
    }
    return {
      'type': 'remote',
      'tag': r.tag,
      'format': binary ? 'binary' : 'source',
      'url': r.url,
      'download_detour': detour,
    };
  }

  Iterable<String> _ruleSetsOf(Map<String, Object?> rule) sync* {
    final v = rule['rule_set'];
    if (v is String) yield v;
    if (v is List) yield* v.whereType<String>();
  }

  /// Display name (or override tag) to tag, for override references.
  String? _overrideTag(String name, OverrideDoc override) {
    if (name == _direct || name == 'DIRECT') return _direct;
    for (final o in override.outbounds) {
      if (o['tag'] == name) return name;
    }
    for (final g in content.groups) {
      if (g.name == name) {
        _require(g.key);
        return _keyTag(g.key);
      }
    }
    for (final n in content.nodes) {
      if (n.name == name) {
        _require(n.key);
        return _keyTag(n.key);
      }
    }
    for (final n in input.selfNodes) {
      if (n.name == name) return _selfNode(n.id);
    }
    for (final c in input.chains) {
      if (_catalog.chainName(c) == name) return _chainTag(c.id);
    }
    return null;
  }

  /// Selector choices are applied live (`select`), so they do not make a
  /// different plan.
  /// The plan without what the host switches in place (a selector's
  /// member, the outbound mode): those are not a change of plan
  /// (CONFIG_PIPELINE §7).
  static Map<String, Object?> _withoutChoices(Map<String, Object?> tree) {
    final experimental = tree['experimental'];
    final clashApi = experimental is Map<String, Object?>
        ? experimental['clash_api']
        : null;
    return {
      ...tree,
      'outbounds': [
        for (final o in tree['outbounds']! as List)
          if (o is Map<String, Object?> && o['type'] == 'selector')
            ({...o}..remove('default'))
          else
            o,
      ],
      if (experimental is Map<String, Object?> &&
          clashApi is Map<String, Object?>)
        'experimental': {
          ...experimental,
          'clash_api': {...clashApi}..remove('default_mode'),
        },
    };
  }
}
