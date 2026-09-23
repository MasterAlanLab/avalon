import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:avalon/common/common.dart';
import 'package:avalon/database/database.dart';
import 'package:avalon/enum/enum.dart';
import 'package:avalon/models/models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';

Future<T> decodeJSONTask<T>(String data) async {
  return compute<String, T>(_decodeJSON, data);
}

Future<T> _decodeJSON<T>(String content) async {
  return json.decode(content);
}

Future<String> encodeJSONTask<T>(T data) async {
  return compute<T, String>(_encodeJSON, data);
}

Future<String> _encodeJSON<T>(T content) async {
  return json.encode(content);
}

Future<String> encodeYamlTask<T>(T data) async {
  return compute<T, String>(_encodeYaml, data);
}

Future<String> _encodeYaml<T>(T content) async {
  return yaml.encode(content);
}

Future<String> encodeMD5Task(String data) async {
  return compute<String, String>(_encodeMD5, data);
}

Future<String> _encodeMD5<T>(String content) async {
  return content.toMd5();
}

Future<List<Group>> toGroupsTask(ComputeGroupsState data) async {
  return compute<ComputeGroupsState, List<Group>>(_toGroupsTask, data);
}

Future<List<Group>> _toGroupsTask(ComputeGroupsState state) async {
  final proxiesData = state.proxiesData;
  final all = proxiesData.all;
  final sortType = state.sortType;
  final delayMap = state.delayMap;
  final selectedMap = state.selectedMap;
  final defaultTestUrl = state.defaultTestUrl;
  final proxies = proxiesData.proxies;
  if (proxies.isEmpty) return [];
  final groupsRaw = all
      .where((name) {
        final proxy = proxies[name] ?? {};
        return GroupTypeExtension.valueList.contains(proxy['type']);
      })
      .map((groupName) {
        final group = proxies[groupName];
        group['all'] = ((group['all'] ?? []) as List)
            .map((name) => proxies[name])
            .where((proxy) => proxy != null)
            .toList();
        return group;
      })
      .toList();
  final groups = groupsRaw.map((e) => Group.fromJson(e)).toList();
  return computeSort(
    groups: groups,
    sortType: sortType,
    delayMap: delayMap,
    selectedMap: selectedMap,
    defaultTestUrl: defaultTestUrl,
  );
}

Future<VM2<String, String>> makeRealProfileTask(
  MakeRealProfileState data,
) async {
  return compute<MakeRealProfileState, VM2<String, String>>(
    _makeRealProfileTask,
    data,
  );
}

Future<VM2<String, String>> _makeRealProfileTask(
  MakeRealProfileState data,
) async {
  final rawConfig = Map.from(data.rawConfig);
  final realPatchConfig = data.realPatchConfig;
  final profilesPath = data.profilesPath;
  final profileId = data.profileId;
  final overrideDns = data.overrideDns;
  final addedRules = data.addedRules;
  final appendSystemDns = data.appendSystemDns;
  final defaultUA = data.defaultUA;
  String getProvidersFilePathInner(String type, String url) {
    return join(
      profilesPath,
      'providers',
      profileId.toString(),
      type,
      url.toMd5(),
    );
  }

  rawConfig['external-controller'] = realPatchConfig.externalController.value;
  rawConfig['external-ui'] = '';
  rawConfig['interface-name'] = '';
  rawConfig['external-ui-url'] = '';
  rawConfig['tcp-concurrent'] = realPatchConfig.tcpConcurrent;
  rawConfig['unified-delay'] = realPatchConfig.unifiedDelay;
  // 虚拟网卡接管 IPv6 时必须同时打开全局 IPv6：mihomo 在 `ipv6: false` 时会清空 tun
  // 的 inet6-address（config.parseIPV6），虚拟网卡不再承载 IPv6，系统的 IPv6 流量会
  // 绕过隧道从物理网卡直出，泄漏真实地址（DNS 查询、WebRTC 候选地址）；在 Android 上
  // 同样意味着 VpnService 已经接管了 ::/0，内核却拿不到 IPv6 能力。
  // 反过来，不接管时也不该替用户打开全局 IPv6。是否解析 AAAA 与此无关，仍由
  // dns.ipv6 决定。setup.dart 的运行时补丁路径需同步这条规则。
  final tunTakesIpv6 = data.tunTakesIpv6;
  rawConfig['ipv6'] = realPatchConfig.ipv6 || tunTakesIpv6;
  rawConfig['log-level'] = realPatchConfig.logLevel.name;
  rawConfig['port'] = 0;
  rawConfig['socks-port'] = 0;
  rawConfig['keep-alive-interval'] = realPatchConfig.keepAliveInterval;
  rawConfig['mixed-port'] = realPatchConfig.mixedPort;
  rawConfig['port'] = realPatchConfig.port;
  rawConfig['socks-port'] = realPatchConfig.socksPort;
  rawConfig['redir-port'] = realPatchConfig.redirPort;
  rawConfig['tproxy-port'] = realPatchConfig.tproxyPort;
  rawConfig['find-process-mode'] = realPatchConfig.findProcessMode.name;
  rawConfig['allow-lan'] = realPatchConfig.allowLan;
  rawConfig['mode'] = realPatchConfig.mode.name;
  if (rawConfig['tun'] == null) {
    rawConfig['tun'] = {};
  }
  rawConfig['tun']['enable'] = realPatchConfig.tun.enable;
  rawConfig['tun']['device'] = realPatchConfig.tun.device;
  rawConfig['tun']['dns-hijack'] = realPatchConfig.tun.dnsHijack;
  rawConfig['tun']['stack'] = realPatchConfig.tun.stack.name;
  rawConfig['tun']['route-address'] = realPatchConfig.tun.routeAddress;
  rawConfig['tun']['auto-route'] = realPatchConfig.tun.autoRoute;
  rawConfig['tun']['strict-route'] = realPatchConfig.tun.strictRoute;
  // 不接管 IPv6 时不下发 inet6-address，sing-tun 就不会为虚拟网卡装上 ::/0 路由。
  rawConfig['tun']['inet6-address'] = tunTakesIpv6
      ? realPatchConfig.tun.inet6Address
      : const <String>[];
  rawConfig['geodata-loader'] = realPatchConfig.geodataLoader.name;
  if (rawConfig['sniffer']?['sniff'] != null) {
    for (final value in (rawConfig['sniffer']?['sniff'] as Map).values) {
      if (value['ports'] != null && value['ports'] is List) {
        value['ports'] =
            value['ports']?.map((item) => item.toString()).toList() ?? [];
      }
    }
  }
  if (rawConfig['profile'] == null) {
    rawConfig['profile'] = {};
  }
  if (rawConfig['proxy-providers'] != null) {
    final proxyProviders = rawConfig['proxy-providers'] as Map;
    for (final key in proxyProviders.keys) {
      final proxyProvider = proxyProviders[key];
      if (proxyProvider['type'] != 'http') {
        continue;
      }
      if (proxyProvider['url'] != null) {
        proxyProvider['path'] = getProvidersFilePathInner(
          'proxies',
          proxyProvider['url'],
        );
      }
    }
  }
  if (rawConfig['rule-providers'] != null) {
    final ruleProviders = rawConfig['rule-providers'] as Map;
    for (final key in ruleProviders.keys) {
      final ruleProvider = ruleProviders[key];
      if (ruleProvider['type'] != 'http') {
        continue;
      }
      if (ruleProvider['url'] != null) {
        ruleProvider['path'] = getProvidersFilePathInner(
          'rules',
          ruleProvider['url'],
        );
      }
    }
  }
  rawConfig['profile']['store-selected'] = false;
  rawConfig['geox-url'] = realPatchConfig.geoXUrl.raw;
  rawConfig['global-ua'] = realPatchConfig.globalUa ?? defaultUA;
  if (rawConfig['hosts'] == null) {
    rawConfig['hosts'] = {};
  }
  for (final host in realPatchConfig.hosts.entries) {
    rawConfig['hosts'][host.key] = host.value.splitByMultipleSeparators;
  }
  if (rawConfig['dns'] == null) {
    rawConfig['dns'] = {};
  }
  final isEnableDns = rawConfig['dns']['enable'] == true;
  const systemDns = 'system://';
  if (overrideDns || !isEnableDns) {
    final dns = switch (!isEnableDns) {
      true => realPatchConfig.dns.copyWith(
        nameserver: [...realPatchConfig.dns.nameserver, systemDns],
      ),
      false => realPatchConfig.dns,
    };
    rawConfig['dns'] = dns.toJson();
    rawConfig['dns']['nameserver-policy'] = {};
    for (final entry in dns.nameserverPolicy.entries) {
      rawConfig['dns']['nameserver-policy'][entry.key] =
          entry.value.splitByMultipleSeparators;
    }
  }
  // 走到这里 rawConfig['dns'] 可能仍是订阅原样带来的 map（YamlMap / const map 都是
  // 只读的），先复制成可写的再改。
  rawConfig['dns'] = Map<String, dynamic>.from(rawConfig['dns'] as Map);
  // fake-ip 模式下 AAAA 在 withFakeIP 中间件就被短路了，走不到检查 dns.ipv6 的
  // withResolver，没有 v6 池时一律返回空应答。所以让 dns.ipv6 同时控制 v6 池，
  // 这个开关在 fake-ip 下才真正有意义。
  // 这条必须留在上面的分支外：订阅自带 dns 块时（overrideDns 关闭）整段会被跳过，
  // 订阅写的 `ipv6: true` 会架空本地开关，把 v6 fake 池交回给订阅决定。
  rawConfig['dns']['fake-ip-range6'] = realPatchConfig.dns.ipv6
      ? realPatchConfig.dns.fakeIpRange6
      : '';
  if (appendSystemDns) {
    final List<String> nameserver = List<String>.from(
      rawConfig['dns']['nameserver'] ?? [],
    );
    if (!nameserver.contains(systemDns)) {
      rawConfig['dns']['nameserver'] = [...nameserver, systemDns];
    }
  }
  List<String> rules = [];
  if (data.rules.isEmpty) {
    if (rawConfig['rules'] != null) {
      rules = List<String>.from(rawConfig['rules']);
    }
    if (addedRules.isNotEmpty) {
      final hasMatchPlaceholder = addedRules.any(
        (item) => item.ruleTarget?.toUpperCase() == 'MATCH',
      );
      String? replacementTarget;

      if (hasMatchPlaceholder) {
        for (int i = rules.length - 1; i >= 0; i--) {
          final parsed = Rule.parse(rules[i]);
          if (parsed.ruleAction == RuleAction.MATCH) {
            final target = parsed.ruleTarget;
            if (target != null && target.isNotEmpty) {
              replacementTarget = target;
              break;
            }
          }
        }
      }
      final List<String> finalAddedRules;

      if (replacementTarget?.isNotEmpty == true) {
        finalAddedRules = [];
        for (int i = 0; i < addedRules.length; i++) {
          final parsed = addedRules[i];
          if (parsed.ruleTarget?.toUpperCase() == 'MATCH') {
            finalAddedRules.add(
              parsed.copyWith(ruleTarget: replacementTarget).rawValue,
            );
          } else {
            finalAddedRules.add(addedRules[i].rawValue);
          }
        }
      } else {
        finalAddedRules = addedRules.map((e) => e.rawValue).toList();
      }
      rules = [...finalAddedRules, ...rules];
    }
  } else {
    rules = data.rules.map((item) => item.rawValue).toList();
  }
  if (data.proxyGroups.isNotEmpty) {
    final generatedGroups = rawConfig['proxy-groups'] is List
        ? (rawConfig['proxy-groups'] as List)
              .whereType<Map>()
              .where(
                (group) =>
                    group['name']?.toString().startsWith('__avalon_') == true,
              )
              .map((group) => Map<String, dynamic>.from(group))
              .toList()
        : const <Map<String, dynamic>>[];
    rawConfig['proxy-groups'] = [
      ...data.proxyGroups.map(_proxyGroupConfig),
      ...generatedGroups,
    ];
  }
  rawConfig['rules'] = rules;
  _ensureGlobalProxyGroup(rawConfig);
  final yaml = await _encodeYaml(Map<String, dynamic>.from(rawConfig));
  return VM2(yaml, yaml.toMd5());
}

Map<String, dynamic> _proxyGroupConfig(ProxyGroup group) {
  final config = Map<String, dynamic>.from(group.toJson())
    ..remove('id')
    ..remove('profileId')
    ..remove('order');
  return config;
}

/// mihomo's global mode selects the `GLOBAL` outbound directly.  When the
/// config omits that group mihomo creates an implicit selector whose default
/// is usually DIRECT, so switching from rule mode silently bypasses PROXY and
/// any generated chain selector.  Keep an explicit, validated entry in every
/// assembled profile so a mode-only hot update has the same outbound graph.
void _ensureGlobalProxyGroup(Map<String, dynamic> config) {
  final entries = <dynamic>[];
  final groups = <Map<String, dynamic>>[];
  final rawGroups = config['proxy-groups'];
  if (rawGroups is List) {
    for (final raw in rawGroups) {
      if (raw is Map) {
        final group = Map<String, dynamic>.from(raw);
        groups.add(group);
        entries.add(group);
      } else {
        entries.add(raw);
      }
    }
  }

  String? groupName(Map<String, dynamic> group) {
    final value = group['name']?.toString().trim();
    return value == null || value.isEmpty ? null : value;
  }

  final groupByName = <String, Map<String, dynamic>>{};
  for (final group in groups) {
    final name = groupName(group);
    if (name != null) groupByName.putIfAbsent(name, () => group);
  }
  if (groupByName.containsKey('GLOBAL')) {
    config['proxy-groups'] = entries;
    return;
  }

  final proxyNames = <String>{};
  final rawProxies = config['proxies'];
  if (rawProxies is List) {
    for (final raw in rawProxies) {
      if (raw is Map) {
        final name = raw['name']?.toString().trim();
        if (name != null && name.isNotEmpty) proxyNames.add(name);
      }
    }
  }

  final reserved = {
    'DIRECT',
    'REJECT',
    'REJECT-DROP',
    'COMPATIBLE',
    'PASS',
    'PASS-RULE',
    'GLOBAL',
  };

  bool isKnownTarget(String name) =>
      groupByName.containsKey(name) ||
      proxyNames.contains(name) ||
      reserved.contains(name);

  // Reject a group that would introduce a direct or indirect group cycle.
  bool isAcyclicGroup(String name) {
    final visiting = <String>{};
    final visited = <String>{};
    bool visit(String current) {
      if (visited.contains(current)) return true;
      if (!visiting.add(current)) return false;
      final group = groupByName[current];
      final members = group?['proxies'];
      if (members is List) {
        for (final member in members) {
          final memberName = member.toString().trim();
          if (memberName == 'GLOBAL' || !isKnownTarget(memberName)) {
            return false;
          }
          if (groupByName.containsKey(memberName) && !visit(memberName)) {
            return false;
          }
        }
      }
      visiting.remove(current);
      visited.add(current);
      return true;
    }

    return visit(name);
  }

  bool usable(String? name) {
    if (name == null || name.isEmpty || name == 'GLOBAL') return false;
    if (reserved.contains(name) && groupByName.containsKey(name)) return false;
    if (!isKnownTarget(name)) return false;
    return !groupByName.containsKey(name) || isAcyclicGroup(name);
  }

  String? target;
  if (usable('PROXY')) target = 'PROXY';

  // Profiles without PROXY commonly use a single custom group as the MATCH
  // target.  Reuse that target before falling back to an arbitrary group.
  if (target == null && config['rules'] is List) {
    for (final rawRule in (config['rules'] as List).reversed) {
      final parts = rawRule.toString().split(',');
      if (parts.length < 2 || parts.first.trim().toUpperCase() != 'MATCH') {
        continue;
      }
      final candidate = parts[1].trim();
      if (usable(candidate)) {
        target = candidate;
        break;
      }
    }
  }

  if (target == null && usable('__avalon_chains')) target = '__avalon_chains';
  if (target == null) {
    for (final group in groups) {
      final candidate = groupName(group);
      if (usable(candidate)) {
        target = candidate;
        break;
      }
    }
  }
  if (target == null) {
    for (final candidate in proxyNames) {
      if (!reserved.contains(candidate)) {
        target = candidate;
        break;
      }
    }
  }

  // A profile with no usable outbound still gets an explicit, deterministic
  // GLOBAL selector rather than relying on mihomo's implicit DIRECT default.
  target ??= 'DIRECT';
  entries.add({
    'name': 'GLOBAL',
    'type': 'select',
    'proxies': [target],
  });
  config['proxy-groups'] = entries;
}

Future<List<String>> shakingProfileTask(
  VM2<Iterable<int>, Iterable<int>> data,
) async {
  return compute<
    VM3<Iterable<int>, Iterable<int>, RootIsolateToken>,
    List<String>
  >(_shakingProfileTask, VM3(data.a, data.b, RootIsolateToken.instance!));
}

Future<List<String>> _shakingProfileTask(
  VM3<Iterable<int>, Iterable<int>, RootIsolateToken> data,
) async {
  final profileIds = data.a;
  final scriptIds = data.b;
  final token = data.c;
  BackgroundIsolateBinaryMessenger.ensureInitialized(token);
  final profilesDir = Directory(await appPath.profilesPath);
  final scriptsDir = Directory(await appPath.scriptsDirPath);
  final providersDir = Directory(await appPath.getProvidersRootPath());
  final List<String> targets = [];
  void scanDirectory(
    Directory dir,
    Iterable<int> baseNames, {
    bool skipProvidersFolder = false,
  }) {
    if (!dir.existsSync()) return;
    final entities = dir.listSync(recursive: false, followLinks: false);

    for (final entity in entities) {
      if (entity is File) {
        final id = basenameWithoutExtension(entity.path);
        if (!baseNames.contains(int.tryParse(id))) {
          targets.add(entity.path);
        }
      } else if (skipProvidersFolder && entity is Directory) {
        if (basename(entity.path) == 'providers') {
          continue;
        }
      }
    }
  }

  scanDirectory(profilesDir, profileIds, skipProvidersFolder: true);
  scanDirectory(providersDir, profileIds);
  scanDirectory(scriptsDir, scriptIds);
  return targets;
}

Future<String> encodeLogsTask(List<Log> data) async {
  return compute<List<Log>, String>(_encodeLogsTask, data);
}

Future<String> _encodeLogsTask(List<Log> data) async {
  final logsRaw = data.map((item) => item.toString());
  final logsRawString = logsRaw.join('\n');
  return logsRawString;
}

Future<MigrationData> oldToNowTask(Map<String, Object?> data) async {
  final homeDir = await appPath.homeDirPath;
  return compute<VM3<Map<String, Object?>, String, String>, MigrationData>(
    _oldToNowTask,
    VM3(data, homeDir, homeDir),
  );
}

Future<MigrationData> _oldToNowTask(
  VM3<Map<String, Object?>, String, String> data,
) async {
  final configMap = data.a;
  final sourcePath = data.b;
  final targetPath = data.c;

  final accessControlMap = configMap['accessControl'];
  final isAccessControl = configMap['isAccessControl'];
  if (accessControlMap != null) {
    (accessControlMap as Map)['enable'] = isAccessControl;
    if (configMap['vpnProps'] != null) {
      final vpnPropsRaw = configMap['vpnProps'] as Map;
      vpnPropsRaw['accessControl'] = accessControlMap;
    }
  }
  if (configMap['vpnProps'] != null) {
    final vpnPropsRaw = configMap['vpnProps'] as Map;
    vpnPropsRaw['accessControlProps'] = vpnPropsRaw['accessControl'];
  }
  configMap['davProps'] = configMap['dav'];
  final appSettingProps =
      configMap['appSetting'] as Map<String, dynamic>? ?? {};
  appSettingProps['restoreStrategy'] = appSettingProps['recoveryStrategy'];
  configMap['appSettingProps'] = appSettingProps;
  configMap['proxiesStyleProps'] = configMap['proxiesStyle'];
  configMap['proxiesStyleProps'] = configMap['proxiesStyle'];
  List rawScripts = configMap['scripts'] as List<dynamic>? ?? [];
  if (rawScripts.isEmpty) {
    final scriptPropsJson = configMap['scriptProps'] as Map<String, dynamic>?;
    if (scriptPropsJson != null) {
      rawScripts = scriptPropsJson['scripts'] as List<dynamic>? ?? [];
    }
  }
  final Map<String, int> idMap = {};
  final List<Script> scripts = [];
  for (final rawScript in rawScripts) {
    final id = rawScript['id'] as String?;
    final content = rawScript['content'] as String?;
    final label = rawScript['label'] as String?;
    if (id == null || content == null || label == null) {
      continue;
    }
    final newId = idMap.updateCacheValue(rawScript['id'], () => snowflake.id);
    final path = _getScriptPath(targetPath, newId.toString());
    final file = File(path);
    await file.safeWriteAsString(content);
    scripts.add(
      Script(id: newId, label: label, lastUpdateTime: DateTime.now()),
    );
  }
  final List rawRules = configMap['rules'] as List<dynamic>? ?? [];
  final List<Rule> rules = [];
  final List<ProfileRuleLink> links = [];
  for (final rawRule in rawRules) {
    final id = idMap.updateCacheValue(rawRule['id'], () => snowflake.id);
    rawRule['id'] = id;
    final value = rawRule['value'] ?? '';
    rules.add(Rule.parse(value, id: id));
    links.add(ProfileRuleLink(ruleId: id));
  }
  final List rawProfiles = configMap['profiles'] as List<dynamic>? ?? [];
  final List<Profile> profiles = [];
  for (final rawProfile in rawProfiles) {
    final rawId = rawProfile['id'] as String?;
    if (rawId == null) {
      continue;
    }
    final profileId = idMap.updateCacheValue(rawId, () => snowflake.id);
    rawProfile['id'] = profileId;
    final overwrite = rawProfile['overwrite'] as Map?;
    if (overwrite != null) {
      final standardOverwrite = overwrite['standardOverwrite'] as Map?;
      if (standardOverwrite != null) {
        final addedRules = standardOverwrite['addedRules'] as List? ?? [];
        for (final addRule in addedRules) {
          final id = idMap.updateCacheValue(addRule['id'], () => snowflake.id);
          final value = addRule['value'] ?? '';
          rules.add(Rule.parse(value, id: id));
          links.add(
            ProfileRuleLink(
              profileId: profileId,
              ruleId: id,
              scene: RuleScene.added,
            ),
          );
        }
        final disabledRuleIds = standardOverwrite['disabledRuleIds'] as List?;
        if (disabledRuleIds != null) {
          for (final disabledRuleId in disabledRuleIds) {
            final newDisabledRuleId = idMap[disabledRuleId];
            if (newDisabledRuleId != null) {
              links.add(
                ProfileRuleLink(
                  profileId: profileId,
                  ruleId: newDisabledRuleId,
                  scene: RuleScene.disabled,
                ),
              );
            }
          }
        }
      }
      final scriptOverwrite = overwrite['scriptOverwrite'] as Map?;
      if (scriptOverwrite != null) {
        final scriptId = scriptOverwrite['scriptId'] as String?;
        rawProfile['scriptId'] = scriptId != null ? idMap[scriptId] : null;
      }
      rawProfile['overwriteType'] = overwrite['type'];
    }

    final sourceFile = File(_getProfilePath(sourcePath, rawId));
    final targetFilePath = _getProfilePath(targetPath, profileId.toString());
    await sourceFile.safeCopy(targetFilePath);
    profiles.add(Profile.fromJson(rawProfile));
  }
  final currentProfileId = configMap['currentProfileId'];
  configMap['currentProfileId'] = currentProfileId != null
      ? idMap[currentProfileId]
      : null;
  return MigrationData(
    configMap: configMap,
    profiles: profiles,
    rules: rules,
    scripts: scripts,
    links: links,
  );
}

Future<String> backupTask(
  Map<String, dynamic> configMap,
  Iterable<String> fileNames, {
  String? databaseSnapshotPath,
}) async {
  return compute<
    VM4<Map<String, dynamic>, Iterable<String>, RootIsolateToken, String?>,
    String
  >(
    _backupTask,
    VM4(configMap, fileNames, RootIsolateToken.instance!, databaseSnapshotPath),
  );
}

Future<String> _backupTask<T>(
  VM4<Map<String, dynamic>, Iterable<String>, RootIsolateToken, String?> args,
) async {
  final configMap = args.a;
  final fileNames = args.b;
  final token = args.c;
  BackgroundIsolateBinaryMessenger.ensureInitialized(token);
  final dbPath = args.d ?? await appPath.databasePath;
  final configStr = json.encode(configMap);
  final profilesDir = Directory(await appPath.profilesPath);
  final scriptsDir = Directory(await appPath.scriptsDirPath);
  final nodesDir = Directory(await appPath.nodesDirPath);
  final tempFilePath = await appPath.tempFilePath;
  final tempBasePath = '$tempFilePath-${utils.id}';
  final tempZipFilePath = '$tempBasePath.zip';
  final tempDBFile = File('$tempBasePath.sqlite');
  final tempConfigFile = File('$tempBasePath.json');
  final tempManifestFile = File('$tempBasePath-manifest.json');
  final dbFile = File(dbPath);
  final encoder = ZipFileEncoder();
  var encoderClosed = false;
  try {
    if (await dbFile.exists()) {
      await dbFile.copy(tempDBFile.path);
    }
    encoder.create(tempZipFilePath);
    await tempConfigFile.writeAsString(configStr);
    if (await tempDBFile.exists()) {
      await encoder.addFile(tempDBFile, backupDatabaseName);
    }
    await encoder.addFile(tempConfigFile, configJsonName);
    if (await profilesDir.exists()) {
      await encoder.addDirectory(
        profilesDir,
        filter: (file, _) {
          if (!fileNames.contains(basename(file.path))) {
            return ZipFileOperation.skip;
          }
          return ZipFileOperation.include;
        },
      );
    }
    if (await scriptsDir.exists()) {
      await encoder.addDirectory(
        scriptsDir,
        filter: (file, _) {
          if (!fileNames.contains(basename(file.path))) {
            return ZipFileOperation.skip;
          }
          return ZipFileOperation.include;
        },
      );
    }
    if (await nodesDir.exists()) {
      await encoder.addDirectory(nodesDir, followLinks: false);
    }
    final entries = <Map<String, Object?>>[
      if (await tempDBFile.exists())
        await _manifestEntry(backupDatabaseName, tempDBFile),
      await _manifestEntry(configJsonName, tempConfigFile),
      ...await _manifestEntries(profilesDir, 'profiles', fileNames),
      ...await _manifestEntries(scriptsDir, 'scripts', fileNames),
      ...await _manifestEntries(nodesDir, 'nodes', null),
    ];
    await tempManifestFile.writeAsString(
      json.encode({
        'version': backupManifestVersion,
        'createdAt': DateTime.now().toIso8601String(),
        'appVersion': configMap['version'],
        'entries': entries,
      }),
    );
    await encoder.addFile(tempManifestFile, backupManifestName);
    encoder.close();
    encoderClosed = true;
    return tempZipFilePath;
  } finally {
    if (!encoderClosed) {
      encoder.close();
    }
    await tempConfigFile.safeDelete();
    await tempManifestFile.safeDelete();
    await tempDBFile.safeDelete();
  }
}

Future<Map<String, Object?>> _manifestEntry(String path, File file) async {
  final bytes = await file.readAsBytes();
  return {
    'path': path,
    'sha256': sha256.convert(bytes).toString(),
    'size': bytes.length,
  };
}

Future<List<Map<String, Object?>>> _manifestEntries(
  Directory directory,
  String prefix,
  Iterable<String>? fileNames,
) async {
  if (!await directory.exists()) return const [];
  final result = <Map<String, Object?>>[];
  await for (final entity in directory.list(
    recursive: true,
    followLinks: false,
  )) {
    if (entity is! File) continue;
    if (fileNames != null && !fileNames.contains(basename(entity.path))) {
      continue;
    }
    final archivePath = posix.joinAll([
      prefix,
      ...split(relative(entity.path, from: directory.path)),
    ]);
    result.add(await _manifestEntry(archivePath, entity));
  }
  result.sort((a, b) => (a['path'] as String).compareTo(b['path'] as String));
  return result;
}

Future<void> verifyBackupManifest(String restoreDirPath) async {
  final manifestFile = File(join(restoreDirPath, backupManifestName));
  if (!await manifestFile.exists()) return;
  final Object? decoded;
  try {
    decoded = json.decode(await manifestFile.readAsString());
  } catch (_) {
    throw currentAppLocalizations.invalidBackupFile;
  }
  if (decoded is! Map) throw currentAppLocalizations.invalidBackupFile;
  final version = decoded['version'];
  if (version is! int || version > backupManifestVersion) {
    throw currentAppLocalizations.invalidBackupFile;
  }
  final entries = decoded['entries'];
  if (entries is! List) throw currentAppLocalizations.invalidBackupFile;
  final restoreRoot = normalize(restoreDirPath);
  for (final entry in entries) {
    if (entry is! Map) throw currentAppLocalizations.invalidBackupFile;
    final path = entry['path']?.toString();
    final digest = entry['sha256']?.toString();
    if (path == null || digest == null) {
      throw currentAppLocalizations.invalidBackupFile;
    }
    final relativePath = posix.normalize(path);
    final filePath = normalize(join(restoreDirPath, relativePath));
    if (posix.isAbsolute(relativePath) ||
        relativePath.startsWith('../') ||
        !isWithin(restoreRoot, filePath)) {
      throw currentAppLocalizations.invalidBackupFile;
    }
    final file = File(filePath);
    if (!await file.exists()) throw currentAppLocalizations.invalidBackupFile;
    final bytes = await file.readAsBytes();
    if (sha256.convert(bytes).toString() != digest.toLowerCase()) {
      throw currentAppLocalizations.invalidBackupFile;
    }
  }
}

Future<MigrationData> restoreTask() async {
  return compute<RootIsolateToken, MigrationData>(
    _restoreTask,
    RootIsolateToken.instance!,
  );
}

Future<MigrationData> _restoreTask(RootIsolateToken token) async {
  BackgroundIsolateBinaryMessenger.ensureInitialized(token);
  final backupFilePath = await appPath.backupFilePath;
  final restoreDirPath = await appPath.restoreDirPath;
  final homeDirPath = await appPath.homeDirPath;
  final zipDecoder = ZipDecoder();
  final input = InputFileStream(backupFilePath);
  late final Archive archive;
  try {
    archive = zipDecoder.decodeStream(input);
  } catch (_) {
    await input.close();
    rethrow;
  }
  try {
    await _extractRestoreArchive(archive, restoreDirPath);
  } finally {
    await input.close();
  }
  await verifyBackupManifest(restoreDirPath);
  final restoreConfigFile = File(join(restoreDirPath, configJsonName));
  if (!await restoreConfigFile.exists()) {
    throw currentAppLocalizations.invalidBackupFile;
  }
  final restoreConfigMap =
      json.decode(await restoreConfigFile.readAsString())
          as Map<String, Object?>?;
  final version = restoreConfigMap?['version'] ?? 0;
  MigrationData migrationData = MigrationData(configMap: restoreConfigMap);
  if (version == 0 && restoreConfigMap != null) {
    migrationData = await _oldToNowTask(
      VM3(restoreConfigMap, restoreDirPath, homeDirPath),
    );
    return migrationData;
  }
  final backupDatabaseFile = File(join(restoreDirPath, backupDatabaseName));
  if (!await backupDatabaseFile.exists()) {
    return migrationData;
  }
  final database = Database(
    driftDatabase(
      name: 'database',
      native: DriftNativeOptions(
        databaseDirectory: () async => Directory(restoreDirPath),
      ),
    ),
  );
  try {
    final results = await Future.wait([
      database.profilesDao.query().get(),
      database.scriptsDao.query().get(),
      database.rules.all().map((item) => item.toRule()).get(),
      database.profileRuleLinks.all().map((item) => item.toLink()).get(),
      database.proxyGroups.all().map((item) => item.toProxyGroup()).get(),
      database.proxyNodesDao.query().get(),
      database.proxyNodeBindings
          .all()
          .map((item) => item.toProxyNodeBinding())
          .get(),
      database.proxyChainsDao.query().get(),
      database.proxyChainHops.all().map((item) => item.toProxyChainHop()).get(),
      database.proxyChainBindings
          .all()
          .map((item) => item.toProxyChainBinding())
          .get(),
      database.proxyNodeAssets
          .all()
          .map((item) => item.toProxyNodeAsset())
          .get(),
      database.proxyGroupMembers
          .all()
          .map((item) => item.toProxyGroupMember())
          .get(),
    ]);
    final profiles = results[0].cast<Profile>();
    final scripts = results[1].cast<Script>();
    migrationData = migrationData.copyWith(
      profiles: profiles,
      scripts: scripts,
      rules: results[2].cast<Rule>(),
      links: results[3].cast<ProfileRuleLink>(),
      proxyGroups: results[4].cast<ProxyGroup>(),
      proxyNodes: results[5].cast<ProxyNode>(),
      proxyNodeBindings: results[6].cast<ProxyNodeBinding>(),
      proxyChains: results[7].cast<ProxyChain>(),
      proxyChainHops: results[8].cast<ProxyChainHop>(),
      proxyChainBindings: results[9].cast<ProxyChainBinding>(),
      proxyNodeAssets: results[10].cast<ProxyNodeAsset>(),
      proxyGroupMembers: results[11].cast<ProxyGroupMember>(),
    );
    await verifyRestoredNodeAssets(
      restoreDirPath: restoreDirPath,
      assets: migrationData.proxyNodeAssets,
    );
    return migrationData;
  } finally {
    await database.close();
  }
}

Future<void> verifyRestoredNodeAssets({
  required String restoreDirPath,
  required List<ProxyNodeAsset> assets,
}) async {
  final restoreRoot = normalize(restoreDirPath);
  for (final asset in assets) {
    final relativePath = posix.normalize(asset.relativePath);
    final filePath = normalize(join(restoreDirPath, relativePath));
    if (posix.isAbsolute(relativePath) ||
        relativePath == '.' ||
        relativePath == '..' ||
        relativePath.startsWith('../') ||
        !isWithin(restoreRoot, filePath) ||
        !relativePath.startsWith('nodes/')) {
      throw currentAppLocalizations.invalidBackupFile;
    }
    final file = File(filePath);
    if (!await file.exists()) throw currentAppLocalizations.invalidBackupFile;
    final digest = sha256.convert(await file.readAsBytes()).toString();
    if (digest != asset.sha256.toLowerCase()) {
      throw currentAppLocalizations.invalidBackupFile;
    }
  }
}

class FileReplacement {
  FileReplacement._(this.path, this._backupPath);

  final String path;
  final String? _backupPath;

  bool get hasPrevious => _backupPath != null;

  Future<void> commit() async {
    final backupPath = _backupPath;
    if (backupPath != null) await File(backupPath).safeDelete();
  }

  Future<void> rollback() async {
    final backupPath = _backupPath;
    if (backupPath == null) {
      await File(path).safeDelete();
      return;
    }
    final backup = File(backupPath);
    if (!await backup.exists()) return;
    await File(path).safeDelete();
    await backup.rename(path);
  }
}

Future<FileReplacement> replaceFileAtomically(
  String path,
  String content,
) async {
  final target = File(path);
  await target.parent.create(recursive: true);
  String? backupPath;
  if (await target.exists()) {
    backupPath = '$path.bak-${utils.id}';
    await File(backupPath).safeDelete();
    await target.copy(backupPath);
  }
  final temporary = File('$path.tmp-${utils.id}');
  try {
    await temporary.writeAsString(content, flush: true);
    try {
      await temporary.rename(path);
    } on FileSystemException {
      if (backupPath == null) rethrow;
      await target.safeDelete();
      await temporary.rename(path);
    }
  } catch (_) {
    final replacement = FileReplacement._(path, backupPath);
    await replacement.rollback();
    rethrow;
  } finally {
    await temporary.safeDelete();
  }
  return FileReplacement._(path, backupPath);
}

class RestoredFileTransaction {
  RestoredFileTransaction._();

  final Map<String, String> _replaced = {};
  final List<String> _created = [];

  Future<void> commit() async {
    for (final backup in _replaced.values) {
      await File(backup).safeDelete();
    }
    _replaced.clear();
    _created.clear();
  }

  Future<void> rollback() async {
    for (final path in _created) {
      await File(path).safeDelete();
    }
    for (final entry in _replaced.entries) {
      final backup = File(entry.value);
      if (!await backup.exists()) continue;
      await File(entry.key).safeDelete();
      await backup.rename(entry.key);
    }
    _replaced.clear();
    _created.clear();
  }
}

Future<RestoredFileTransaction> applyRestoredProfileFiles({
  required String restoreDirPath,
  required String homeDirPath,
  required List<Profile> profiles,
  required List<Script> scripts,
}) async {
  final copyMapList = <VM2<String, String>>[
    for (final item in profiles)
      VM2(
        _getProfilePath(restoreDirPath, item.id.toString()),
        _getProfilePath(homeDirPath, item.id.toString()),
      ),
    for (final item in scripts)
      VM2(
        _getScriptPath(restoreDirPath, item.id.toString()),
        _getScriptPath(homeDirPath, item.id.toString()),
      ),
  ];
  final transaction = RestoredFileTransaction._();
  try {
    for (final item in copyMapList) {
      final source = File(item.a);
      if (!await source.exists()) continue;
      final target = File(item.b);
      await Directory(dirname(target.path)).create(recursive: true);
      if (await target.exists()) {
        final backup = '${target.path}.restore-${utils.id}';
        await File(backup).safeDelete();
        await target.rename(backup);
        transaction._replaced[target.path] = backup;
      } else {
        transaction._created.add(target.path);
      }
      await source.copy(target.path);
    }
    return transaction;
  } catch (_) {
    await transaction.rollback();
    rethrow;
  }
}

Future<void> installRestoredNodeAssets({required bool isOverride}) async {
  final source = Directory(join(await appPath.restoreDirPath, 'nodes'));
  final target = Directory(await appPath.nodesDirPath);
  if (!await source.exists()) {
    if (isOverride) await target.safeDelete(recursive: true);
    return;
  }
  final stage = Directory('${target.path}.restore-${utils.id}');
  await stage.safeDelete(recursive: true);
  await _copyDirectory(source, stage);
  if (!isOverride) {
    try {
      await _copyDirectory(stage, target);
    } finally {
      await stage.safeDelete(recursive: true);
    }
    return;
  }
  final previous = Directory('${target.path}.previous-${utils.id}');
  await previous.safeDelete(recursive: true);
  var movedPrevious = false;
  try {
    if (await target.exists()) {
      await target.rename(previous.path);
      movedPrevious = true;
    }
    await stage.rename(target.path);
    await previous.safeDelete(recursive: true);
  } catch (_) {
    await target.safeDelete(recursive: true);
    if (movedPrevious && await previous.exists()) {
      await previous.rename(target.path);
    }
    rethrow;
  } finally {
    await stage.safeDelete(recursive: true);
  }
}

Future<void> _copyDirectory(Directory source, Directory target) async {
  await target.create(recursive: true);
  await for (final entity in source.list(followLinks: false)) {
    final destination = join(target.path, basename(entity.path));
    if (entity is Directory) {
      await _copyDirectory(entity, Directory(destination));
    } else if (entity is File) {
      await entity.copy(destination);
    }
  }
}

Future<void> _extractRestoreArchive(
  Archive archive,
  String restoreDirPath,
) async {
  final dir = Directory(restoreDirPath);
  if (await dir.exists()) {
    await dir.delete(recursive: true);
  }
  await dir.create(recursive: true);
  final restoreRoot = normalize(restoreDirPath);
  final extractedPaths = <String>{};
  for (final file in archive.files) {
    if (file.name.isEmpty || file.name.contains('\\')) {
      throw currentAppLocalizations.invalidBackupFile;
    }
    final relativePath = posix.normalize(file.name);
    if (posix.isAbsolute(relativePath) ||
        relativePath == '.' ||
        relativePath == '..' ||
        relativePath.startsWith('../') ||
        file.isSymbolicLink) {
      throw currentAppLocalizations.invalidBackupFile;
    }
    final outPath = normalize(join(restoreDirPath, relativePath));
    if (outPath != restoreRoot && !isWithin(restoreRoot, outPath)) {
      throw currentAppLocalizations.invalidBackupFile;
    }
    if (!extractedPaths.add(outPath)) {
      throw currentAppLocalizations.invalidBackupFile;
    }
    if (file.isDirectory) {
      await Directory(outPath).create(recursive: true);
      continue;
    }
    await Directory(dirname(outPath)).create(recursive: true);
    final outputStream = OutputFileStream(outPath);
    file.writeContent(outputStream);
    await outputStream.close();
  }
}

String _getScriptPath(String root, String fileName) {
  return join(root, 'scripts', '$fileName.js');
}

String _getProfilePath(String root, String fileName) {
  return join(root, 'profiles', '$fileName.yaml');
}

Future<List<T>> mapListTask<T, S>(List<S> results, T Function(S) mapper) async {
  return compute<VM2<List<S>, T Function(S)>, List<T>>(
    _mapListTask,
    VM2(results, mapper),
  );
}

Future<List<T>> _mapListTask<T, S>(VM2<List<S>, T Function(S)> vm2) async {
  final results = vm2.a;
  final mapper = vm2.b;
  return results.map((item) => mapper(item)).toList();
}
