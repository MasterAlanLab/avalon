import 'dart:convert';

import 'package:crypto/crypto.dart';

enum ChainTargetKind { node, group, localEndpoint }

enum ChainDiagnosticSeverity { warning, error }

class ChainDiagnostic {
  const ChainDiagnostic({
    required this.severity,
    required this.code,
    required this.message,
    this.path,
  });

  final ChainDiagnosticSeverity severity;
  final String code;
  final String message;
  final String? path;

  bool get isError => severity == ChainDiagnosticSeverity.error;
}

class ChainTarget {
  const ChainTarget._({required this.kind, this.id, this.config});

  const ChainTarget.node(String id)
    : this._(kind: ChainTargetKind.node, id: id);

  const ChainTarget.group(String id)
    : this._(kind: ChainTargetKind.group, id: id);

  const ChainTarget.localEndpoint(Map<String, dynamic> config)
    : this._(kind: ChainTargetKind.localEndpoint, config: config);

  final ChainTargetKind kind;
  final String? id;
  final Map<String, dynamic>? config;
}

class ChainHop {
  const ChainHop({required this.target});

  final ChainTarget target;
}

class ChainCompileRequest {
  const ChainCompileRequest({
    required this.name,
    required this.hops,
    required this.nodes,
    this.groups = const {},
    this.branchLimit = 64,
    this.generatedPrefix = '__avalon_chain',
    this.reservedNames = const {},
  });

  final String name;
  final List<ChainHop> hops;
  final Map<String, Map<String, dynamic>> nodes;
  final Map<String, List<ChainTarget>> groups;
  final int branchLimit;
  final String generatedPrefix;
  final Set<String> reservedNames;
}

class ChainPath {
  const ChainPath({required this.targets, required this.generatedNames});

  final List<String> targets;
  final List<String> generatedNames;
}

class ChainGeneratedGroup {
  const ChainGeneratedGroup({
    required this.name,
    required this.proxies,
    this.type = 'select',
  });

  final String name;
  final List<String> proxies;
  final String type;

  Map<String, dynamic> toConfig() => {
    'name': name,
    'type': type,
    'proxies': List<String>.from(proxies),
  };
}

class ChainCompileResult {
  const ChainCompileResult({
    required this.generatedProxies,
    required this.generatedGroups,
    required this.paths,
    required this.diagnostics,
  });

  final Map<String, Map<String, dynamic>> generatedProxies;
  final List<ChainGeneratedGroup> generatedGroups;
  final List<ChainPath> paths;
  final List<ChainDiagnostic> diagnostics;

  bool get isValid => diagnostics.every((item) => !item.isError);
}

class DialerChainCompiler {
  ChainCompileResult compile(ChainCompileRequest request) {
    final diagnostics = <ChainDiagnostic>[];
    final compatibilityWarnings = <String>{};
    if (request.hops.isEmpty) {
      return const ChainCompileResult(
        generatedProxies: {},
        generatedGroups: [],
        paths: [],
        diagnostics: [
          ChainDiagnostic(
            severity: ChainDiagnosticSeverity.error,
            code: 'empty-chain',
            message: 'A chain must contain at least one hop.',
          ),
        ],
      );
    }
    if (request.branchLimit < 1 || request.branchLimit > 1024) {
      return const ChainCompileResult(
        generatedProxies: {},
        generatedGroups: [],
        paths: [],
        diagnostics: [
          ChainDiagnostic(
            severity: ChainDiagnosticSeverity.error,
            code: 'invalid-branch-limit',
            message: 'The branch limit must be between 1 and 1024.',
          ),
        ],
      );
    }

    final choices = <List<_ResolvedTarget>>[];
    for (var index = 0; index < request.hops.length; index++) {
      final hopChoices = _resolve(
        request.hops[index].target,
        request,
        diagnostics,
        <String>{},
        'hops[$index]',
      );
      if (hopChoices.isEmpty) {
        return ChainCompileResult(
          generatedProxies: const {},
          generatedGroups: const [],
          paths: const [],
          diagnostics: List.unmodifiable(diagnostics),
        );
      }
      choices.add(hopChoices);
    }

    var combinations = 1;
    for (final hopChoices in choices) {
      if (combinations > request.branchLimit ~/ hopChoices.length) {
        diagnostics.add(
          ChainDiagnostic(
            severity: ChainDiagnosticSeverity.error,
            code: 'branch-limit-exceeded',
            message:
                'The chain expands to more than ${request.branchLimit} paths.',
            path: request.name,
          ),
        );
        return ChainCompileResult(
          generatedProxies: const {},
          generatedGroups: const [],
          paths: const [],
          diagnostics: List.unmodifiable(diagnostics),
        );
      }
      combinations *= hopChoices.length;
    }

    final paths = <ChainPath>[];
    final generated = <String, Map<String, dynamic>>{};
    final usedNames = <String>{...request.reservedNames};
    final terminals = <String>[];
    var pathIndex = 0;
    _walkPaths(choices, 0, <_ResolvedTarget>[], (selected) {
      pathIndex++;
      final generatedNames = <String>[];
      String? previous;
      for (var hopIndex = 0; hopIndex < selected.length; hopIndex++) {
        final target = selected[hopIndex];
        _addCompatibilityWarnings(
          target,
          hopIndex: hopIndex,
          requestName: request.name,
          diagnostics: diagnostics,
          emitted: compatibilityWarnings,
        );
        final base = _segment(target.name);
        final desiredName =
            '${request.generatedPrefix}_${_segment(request.name)}_${pathIndex}_${hopIndex + 1}_$base';
        final generatedName = _allocateName(desiredName, usedNames);
        usedNames.add(generatedName);
        final config = _copyMap(target.config);
        config['name'] = generatedName;
        if (config['dialer-proxy'] != null) {
          _addCompatibilityWarning(
            code: 'existing-dialer-proxy',
            message:
                'The existing dialer-proxy on ${target.name} is replaced for this chain hop.',
            target: target,
            requestName: request.name,
            diagnostics: diagnostics,
            emitted: compatibilityWarnings,
          );
        }
        if (previous != null) {
          config['dialer-proxy'] = previous;
        } else {
          config.remove('dialer-proxy');
        }
        generated[generatedName] = config;
        generatedNames.add(generatedName);
        previous = generatedName;
      }
      final targetIds = selected.map((item) => item.key).toList();
      paths.add(ChainPath(targets: targetIds, generatedNames: generatedNames));
      terminals.add(generatedNames.last);
    });

    // Generated proxy names stay namespaced because they are implementation
    // details, while the selector is exposed on the proxies page. Keep that
    // user-facing selector aligned with the chain name.
    final selectorName = request.name.trim();
    final groupName = _allocateName(
      selectorName.isEmpty ? 'chain' : selectorName,
      usedNames,
    );
    return ChainCompileResult(
      generatedProxies: Map.unmodifiable(generated),
      generatedGroups: [
        ChainGeneratedGroup(name: groupName, proxies: terminals),
      ],
      paths: List.unmodifiable(paths),
      diagnostics: List.unmodifiable(diagnostics),
    );
  }

  List<_ResolvedTarget> _resolve(
    ChainTarget target,
    ChainCompileRequest request,
    List<ChainDiagnostic> diagnostics,
    Set<String> groupStack,
    String path,
  ) {
    switch (target.kind) {
      case ChainTargetKind.node:
        final id = target.id;
        final config = id == null ? null : request.nodes[id];
        if (id == null || config == null) {
          diagnostics.add(
            ChainDiagnostic(
              severity: ChainDiagnosticSeverity.error,
              code: 'missing-node',
              message: 'The chain references a missing node.',
              path: path,
            ),
          );
          return const [];
        }
        final name = config['name']?.toString() ?? id;
        return [_ResolvedTarget(key: id, name: name, config: config)];
      case ChainTargetKind.localEndpoint:
        final config = target.config;
        final type = config?['type']?.toString().trim().toLowerCase();
        final server = config?['server']?.toString().trim();
        final port = int.tryParse(config?['port']?.toString() ?? '');
        final validType = const {'http', 'socks', 'socks5'}.contains(type);
        if (config == null ||
            !validType ||
            server == null ||
            server.isEmpty ||
            port == null ||
            port < 1 ||
            port > 65535) {
          diagnostics.add(
            ChainDiagnostic(
              severity: ChainDiagnosticSeverity.error,
              code: 'invalid-local-endpoint',
              message:
                  'A local endpoint requires an HTTP or SOCKS server and a valid port.',
              path: path,
            ),
          );
          return const [];
        }
        final name = config['name']?.toString() ?? 'local-endpoint';
        return [
          _ResolvedTarget(key: 'local:$name', name: name, config: config),
        ];
      case ChainTargetKind.group:
        final id = target.id;
        if (id == null || !request.groups.containsKey(id)) {
          diagnostics.add(
            ChainDiagnostic(
              severity: ChainDiagnosticSeverity.error,
              code: 'missing-group',
              message: 'The chain references a missing group.',
              path: path,
            ),
          );
          return const [];
        }
        if (groupStack.contains(id)) {
          diagnostics.add(
            ChainDiagnostic(
              severity: ChainDiagnosticSeverity.error,
              code: 'group-cycle',
              message: 'The chain group reference contains a cycle.',
              path: path,
            ),
          );
          return const [];
        }
        final nextStack = {...groupStack, id};
        final members = request.groups[id]!;
        if (members.isEmpty) {
          diagnostics.add(
            ChainDiagnostic(
              severity: ChainDiagnosticSeverity.error,
              code: 'empty-group',
              message: 'A chain group must contain at least one usable target.',
              path: path,
            ),
          );
          return const [];
        }
        final result = <_ResolvedTarget>[];
        for (var index = 0; index < members.length; index++) {
          result.addAll(
            _resolve(
              members[index],
              request,
              diagnostics,
              nextStack,
              '$path[$index]',
            ),
          );
        }
        return result;
    }
  }

  void _addCompatibilityWarnings(
    _ResolvedTarget target, {
    required int hopIndex,
    required String requestName,
    required List<ChainDiagnostic> diagnostics,
    required Set<String> emitted,
  }) {
    if (hopIndex == 0) return;
    final config = target.config;
    final type = config['type']?.toString().trim().toLowerCase();
    final hasUdpTransport = <String>{
      'hysteria',
      'hysteria2',
      'tuic',
      'wireguard',
    }.contains(type);
    // 这里不再看 `udp`：applyDefaultUdp 之后它对绝大多数类型恒为 true，再拿它当
    // 信号会让每一条多跳链路都挂上这条警告。真正需要提醒的是「UDP 是这一跳的
    // 传输本身」（hasUdpTransport）、UoT，以及显式关掉 UDP 的情况。
    final explicitUdp =
        _isTrue(config['udp-over-tcp']) ||
        _isTrue(config['udp_over_tcp']) ||
        config['network']?.toString().toLowerCase() == 'udp';
    final udpDisabled =
        _isTrue(config['disable-udp']) || _isTrue(config['disable_udp']);
    if (hasUdpTransport || explicitUdp || udpDisabled) {
      _addCompatibilityWarning(
        code: 'udp-chain-compatibility',
        message:
            'This relay hop uses UDP transport or disables UDP; verify that the dialer chain supports the required UDP path.',
        target: target,
        requestName: requestName,
        diagnostics: diagnostics,
        emitted: emitted,
      );
    }

    final security = config['security']?.toString().trim().toLowerCase();
    final reality =
        security == 'reality' ||
        config['reality-opts'] is Map ||
        config['reality_opts'] is Map ||
        _isTrue(config['reality']);
    if (reality) {
      _addCompatibilityWarning(
        code: 'reality-chain-compatibility',
        message:
            'Reality is configured on a relay hop; verify SNI, fingerprint, and key material remain valid through the dialer chain.',
        target: target,
        requestName: requestName,
        diagnostics: diagnostics,
        emitted: emitted,
      );
    }

    final shadowTls =
        type == 'shadow-tls' ||
        config['shadow-tls-opts'] is Map ||
        config['shadow_tls_opts'] is Map ||
        config['shadow-tls'] is Map ||
        _isTrue(config['shadow-tls']);
    if (shadowTls) {
      _addCompatibilityWarning(
        code: 'shadow-tls-chain-compatibility',
        message:
            'ShadowTLS is configured on a relay hop; verify the relay preserves its TLS handshake and server name.',
        target: target,
        requestName: requestName,
        diagnostics: diagnostics,
        emitted: emitted,
      );
    }
  }

  void _addCompatibilityWarning({
    required String code,
    required String message,
    required _ResolvedTarget target,
    required String requestName,
    required List<ChainDiagnostic> diagnostics,
    required Set<String> emitted,
  }) {
    final key = '$code:${target.key}';
    if (!emitted.add(key)) return;
    diagnostics.add(
      ChainDiagnostic(
        severity: ChainDiagnosticSeverity.warning,
        code: code,
        message: message,
        path: requestName,
      ),
    );
  }

  bool _isTrue(dynamic value) {
    if (value is bool) return value;
    return value?.toString().trim().toLowerCase() == 'true';
  }

  void _walkPaths(
    List<List<_ResolvedTarget>> choices,
    int index,
    List<_ResolvedTarget> selected,
    void Function(List<_ResolvedTarget>) callback,
  ) {
    if (index == choices.length) {
      callback(List.unmodifiable(selected));
      return;
    }
    for (final choice in choices[index]) {
      selected.add(choice);
      _walkPaths(choices, index + 1, selected, callback);
      selected.removeLast();
    }
  }

  String _segment(String value) {
    final segment = value
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '_')
        .replaceAll(RegExp('_+'), '_');
    return segment.isEmpty ? 'chain' : segment;
  }
}

class EffectiveConfigRequest {
  const EffectiveConfigRequest({
    required this.profileConfig,
    this.nodes = const {},
    this.nodeBindings = const [],
    this.groups = const {},
    this.chains = const [],
    this.nodeAliases = const {},
  });

  final Map<String, dynamic> profileConfig;
  final Map<String, Map<String, dynamic>> nodes;
  final List<String> nodeBindings;
  final Map<String, List<ChainTarget>> groups;
  final List<ChainCompileRequest> chains;
  final Map<String, String> nodeAliases;
}

class EffectiveConfigArtifact {
  const EffectiveConfigArtifact({
    required this.config,
    required this.digest,
    required this.chainResults,
    required this.diagnostics,
    this.previewChainIndexes = const {},
    this.boundProxyNames = const {},
  });

  final Map<String, dynamic> config;
  final String digest;
  final List<ChainCompileResult> chainResults;
  final List<ChainDiagnostic> diagnostics;
  final Map<int, int> previewChainIndexes;

  /// Maps a node-library binding id to the name allocated in [config].  The
  /// allocator may add a suffix when a subscription already owns the same
  /// display name, so callers must use this map instead of guessing names.
  final Map<String, String> boundProxyNames;

  bool get isValid => diagnostics.every((item) => !item.isError);
}

class ChainPreview {
  const ChainPreview({
    required this.pathCount,
    required this.diagnostics,
    this.generatedProxies = const {},
    this.generatedGroups = const [],
    this.generatedNodeIds = const {},
  });

  final int pathCount;
  final List<ChainDiagnostic> diagnostics;
  final Map<String, Map<String, dynamic>> generatedProxies;
  final List<ChainGeneratedGroup> generatedGroups;
  final Map<String, String> generatedNodeIds;

  bool get isValid => diagnostics.every((item) => !item.isError);
}

class EffectiveConfigAssembler {
  EffectiveConfigArtifact assemble(EffectiveConfigRequest request) {
    final config = _copyMap(request.profileConfig);
    final diagnostics = <ChainDiagnostic>[];
    final proxies = <String, dynamic>{};
    final usedNames = <String>{};
    final referenceNames = <String, String>{};
    final boundProxyNames = <String, String>{};
    final sourceGroupConfigs = <Map<String, dynamic>>[];
    final sourceGroups = config['proxy-groups'];
    if (sourceGroups is List) {
      var unnamedIndex = 0;
      for (final raw in sourceGroups) {
        if (raw is! Map) continue;
        final group = _copyMap(raw.cast<String, dynamic>());
        final desired = group['name']?.toString().trim();
        final base = desired == null || desired.isEmpty
            ? 'source-group-$unnamedIndex'
            : desired;
        unnamedIndex++;
        final allocated = _allocateName(base, usedNames);
        usedNames.add(allocated);
        group['name'] = allocated;
        sourceGroupConfigs.add(group);
        if (desired != null && desired.isNotEmpty) {
          referenceNames.putIfAbsent(desired, () => allocated);
        }
      }
    }
    final sourceProxies = _proxyEntries(config['proxies']);
    if (sourceProxies != null) {
      var unnamedIndex = 0;
      for (final raw in sourceProxies) {
        if (raw is Map) {
          final proxy = _copyMap(raw.cast<String, dynamic>());
          final desired = proxy['name']?.toString().trim();
          final name = desired == null || desired.isEmpty
              ? 'source-$unnamedIndex'
              : desired;
          unnamedIndex++;
          final allocated = _allocateName(name, usedNames);
          usedNames.add(allocated);
          proxy['name'] = allocated;
          proxies[allocated] = proxy;
          if (desired != null && desired.isNotEmpty) {
            referenceNames.putIfAbsent(desired, () => allocated);
          }
        }
      }
    }
    for (final id in request.nodeBindings) {
      final node = request.nodes[id];
      if (node == null) {
        diagnostics.add(
          ChainDiagnostic(
            severity: ChainDiagnosticSeverity.error,
            code: 'missing-bound-node',
            message: 'A bound node is missing from the node library.',
            path: id,
          ),
        );
        continue;
      }
      final copy = _copyMap(node);
      final originalName = copy['name']?.toString().trim();
      final desiredName =
          request.nodeAliases[id] ?? copy['name']?.toString() ?? id;
      final name = _allocateName(desiredName, usedNames);
      usedNames.add(name);
      copy['name'] = name;
      proxies[name] = copy;
      boundProxyNames[id] = name;
      referenceNames.putIfAbsent(id, () => name);
      if (originalName != null && originalName.isNotEmpty) {
        referenceNames.putIfAbsent(originalName, () => name);
      }
      final alias = request.nodeAliases[id];
      if (alias != null && alias.trim().isNotEmpty) {
        referenceNames.putIfAbsent(alias.trim(), () => name);
      }
    }

    for (final group in sourceGroupConfigs) {
      final members = group['proxies'];
      if (members is List) {
        group['proxies'] = members
            .map(
              (member) =>
                  referenceNames[member.toString()] ?? member.toString(),
            )
            .toList();
      }
    }

    final chainResults = <ChainCompileResult>[];
    final groupConfigs = <Map<String, dynamic>>[];
    for (final chain in request.chains) {
      final result = DialerChainCompiler().compile(
        ChainCompileRequest(
          name: chain.name,
          hops: chain.hops,
          nodes: {...request.nodes, ...chain.nodes},
          groups: {...request.groups, ...chain.groups},
          branchLimit: chain.branchLimit,
          generatedPrefix: chain.generatedPrefix,
          reservedNames: {
            ...chain.reservedNames,
            ...usedNames,
            ...groupConfigs.map((item) => item['name']?.toString() ?? ''),
          },
        ),
      );
      chainResults.add(result);
      diagnostics.addAll(result.diagnostics);
      for (final proxy in result.generatedProxies.values) {
        final copy = _copyMap(proxy);
        final name = copy['name'].toString();
        proxies[name] = copy;
        usedNames.add(name);
      }
      for (final group in result.generatedGroups) {
        groupConfigs.add(group.toConfig());
        usedNames.add(group.name);
      }
    }

    config['proxies'] = proxies.values.toList();
    final groups = <Map<String, dynamic>>[];
    groups.addAll(sourceGroupConfigs);
    groups.addAll(groupConfigs);
    config['proxy-groups'] = groups;
    return EffectiveConfigArtifact(
      config: config,
      digest: effectiveConfigDigest(config),
      chainResults: List.unmodifiable(chainResults),
      diagnostics: List.unmodifiable(diagnostics),
      boundProxyNames: Map.unmodifiable(boundProxyNames),
    );
  }
}

class _ResolvedTarget {
  const _ResolvedTarget({
    required this.key,
    required this.name,
    required this.config,
  });

  final String key;
  final String name;
  final Map<String, dynamic> config;
}

Map<String, dynamic> _copyMap(Map source) {
  return {
    for (final entry in source.entries)
      entry.key.toString(): _copyValue(entry.value),
  };
}

dynamic _copyValue(dynamic value) {
  if (value is Map) {
    return {
      for (final entry in value.entries)
        entry.key.toString(): _copyValue(entry.value),
    };
  }
  if (value is List) return value.map(_copyValue).toList();
  if (value is Set) return value.map(_copyValue).toList();
  return value;
}

String _allocateName(String desired, Iterable<String> used) {
  final names = used.toSet();
  if (!names.contains(desired)) return desired;
  var index = 2;
  while (names.contains('$desired ($index)')) {
    index++;
  }
  return '$desired ($index)';
}

String effectiveConfigDigest(Map<String, dynamic> config) {
  final normalized = _sortValue(config);
  return sha256.convert(utf8.encode(jsonEncode(normalized))).toString();
}

List<Object?>? _proxyEntries(Object? raw) {
  if (raw is List) return List<Object?>.from(raw);
  if (raw is Map) {
    if (raw['type'] != null) return [raw];
    return raw.entries.map((entry) {
      if (entry.value is! Map) return entry.value;
      final value = _copyMap(entry.value as Map);
      value.putIfAbsent('name', () => entry.key.toString());
      return value;
    }).toList();
  }
  return null;
}

dynamic _sortValue(dynamic value) {
  if (value is Map) {
    final normalized = {
      for (final entry in value.entries) entry.key.toString(): entry.value,
    };
    final keys = normalized.keys.toList()..sort();
    return {for (final key in keys) key: _sortValue(normalized[key])};
  }
  if (value is List) return value.map(_sortValue).toList();
  return value;
}
