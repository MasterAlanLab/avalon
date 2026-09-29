import 'dart:io';

import 'package:drift/native.dart';
import 'package:avalon/database/database.dart';
import 'package:avalon/features/chains/chains.dart';
import 'package:avalon/features/chains/runtime.dart';
import 'package:avalon/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Database store;

  setUp(() {
    store = Database(NativeDatabase.memory());
  });

  tearDown(() async {
    await store.close();
  });

  test('assembles bound nodes and nested profile groups', () async {
    const profile = Profile(
      id: 1,
      label: 'Profile',
      autoUpdateDuration: Duration.zero,
    );
    const node = ProxyNode(
      id: 100,
      displayName: 'Node',
      type: 'socks',
      config: {'name': 'Node', 'type': 'socks', 'server': 'HOST', 'port': 1080},
      fingerprint: 'fingerprint',
    );
    const chain = ProxyChain(id: 200, name: 'Route');
    const hop = ProxyChainHop(
      id: 201,
      chainId: 200,
      order: 0,
      targetKind: 'group',
      groupName: 'Outer',
    );
    await store.profilesDao.putAll([profile.toCompanion()]);
    await store.restore(
      const [],
      const [],
      const [],
      const [],
      const [],
      proxyNodes: const [node],
      proxyNodeBindings: const [ProxyNodeBinding(profileId: 1, nodeId: 100)],
      proxyChains: const [chain],
      proxyChainHops: const [hop],
      proxyChainBindings: const [
        ProxyChainBinding(profileId: 1, chainId: 200, isDefault: true),
      ],
    );

    final artifact =
        await ProfileEffectiveConfigService(
          store: store,
          nodeStorePath: Directory.systemTemp.path,
        ).assemble(
          profileId: 1,
          profileConfig: const {
            'proxies': [],
            'proxy-groups': [
              {
                'name': 'Inner',
                'type': 'select',
                'proxies': ['Node'],
              },
              {
                'name': 'Outer',
                'type': 'select',
                'proxies': ['Inner'],
              },
            ],
          },
        );

    expect(artifact.isValid, isTrue);
    expect(artifact.chainResults.single.paths, hasLength(1));
    expect(artifact.config['proxies'], hasLength(2));
    // The unconfigured default chain is exposed through the generated default
    // outbound group so it is reachable from the rule graph.
    expect(artifact.config['proxy-groups'], hasLength(5));
  });

  test('normalizes map-form profile proxies before assembly', () async {
    final artifact =
        await ProfileEffectiveConfigService(
          store: store,
          nodeStorePath: Directory.systemTemp.path,
        ).assemble(
          profileId: 1,
          profileConfig: const {
            'proxies': {
              'Map node': {'type': 'socks5', 'server': 'HOST', 'port': 1080},
            },
          },
        );

    expect(artifact.isValid, isTrue);
    // udp 是补齐的：订阅直接带过来的 proxies 不经过节点库，省略 udp 的订阅会和
    // 分享链接导入的节点一样掉进 DIRECT 回落。
    expect(artifact.config['proxies'], [
      {
        'name': 'Map node',
        'type': 'socks5',
        'server': 'HOST',
        'port': 1080,
        'udp': true,
      },
    ]);
  });

  test('upgrades a legacy IPv4 manual outbound policy', () async {
    const node = ProxyNode(
      id: 500,
      displayName: 'Manual',
      type: 'socks5',
      config: {
        'name': 'Manual',
        'type': 'socks5',
        'server': 'manual.example.com',
        'port': 443,
      },
      fingerprint: 'manual-policy',
    );
    await store.restore(
      const [],
      const [],
      const [],
      const [],
      const [],
      proxyNodes: const [node],
      proxyNodeBindings: const [ProxyNodeBinding(profileId: 1, nodeId: 500)],
    );

    final artifact =
        await ProfileEffectiveConfigService(
          store: store,
          nodeStorePath: Directory.systemTemp.path,
        ).assemble(
          profileId: 1,
          profileConfig: const {
            'proxies': [],
            'proxy-groups': [
              {
                'name': 'PROXY',
                'type': 'select',
                'proxies': <String>[],
              },
            ],
            'rules': ['MATCH,PROXY'],
          },
          ipv6Available: false,
        );

    final groups = (artifact.config['proxy-groups'] as List).cast<Map>();
    final groupNames = groups.map((group) => group['name']).toSet();
    expect(groupNames, contains('__avalon_manual_nodes'));
    expect(groupNames, contains('PROXY'));
    final manualGroup = groups.singleWhere(
      (group) => group['name'] == '__avalon_manual_nodes',
    );
    expect(manualGroup['hidden'], isTrue);
    final rules = (artifact.config['rules'] as List).cast<String>();
    expect(rules, contains('GEOIP,CN,DIRECT,no-resolve'));
    expect(rules, contains('GEOIP,private,DIRECT,no-resolve'));
    expect(rules.last, 'MATCH,PROXY');
    final manual = (artifact.config['proxies'] as List).cast<Map>().singleWhere(
      (proxy) => proxy['name'] == 'Manual',
    );
    expect(manual['ip-version'], 'ipv4');
    expect((artifact.config['dns'] as Map)['direct-nameserver'], isNotEmpty);
  });

  test('reports an IPv6-only manual outbound on an IPv4-only host', () async {
    const node = ProxyNode(
      id: 501,
      displayName: 'IPv6 Manual',
      type: 'socks5',
      config: {
        'name': 'IPv6 Manual',
        'type': 'socks5',
        'server': '2001:db8::10',
        'port': 443,
      },
      fingerprint: 'manual-ipv6',
    );
    await store.restore(
      const [],
      const [],
      const [],
      const [],
      const [],
      proxyNodes: const [node],
      proxyNodeBindings: const [ProxyNodeBinding(profileId: 1, nodeId: 501)],
    );

    final artifact =
        await ProfileEffectiveConfigService(
          store: store,
          nodeStorePath: Directory.systemTemp.path,
        ).assemble(
          profileId: 1,
          profileConfig: const {'proxies': []},
          ipv6Available: false,
        );

    // A warning, not an error: one unusable node must not block the profile.
    expect(artifact.isValid, isTrue);
    final diagnostic = artifact.diagnostics.singleWhere(
      (item) => item.code == 'ipv6-only-node-on-ipv4-host',
    );
    expect(diagnostic.isError, isFalse);
  });

  test('keeps a MATCH,DIRECT subscription loadable with a manual node', () async {
    const node = ProxyNode(
      id: 503,
      displayName: 'Direct Manual',
      type: 'socks5',
      config: {
        'name': 'Direct Manual',
        'type': 'socks5',
        'server': 'manual.example.com',
        'port': 443,
      },
      fingerprint: 'direct-manual',
    );
    await store.restore(
      const [],
      const [],
      const [],
      const [],
      const [],
      proxyNodes: const [node],
      proxyNodeBindings: const [ProxyNodeBinding(profileId: 1, nodeId: 503)],
    );

    final artifact =
        await ProfileEffectiveConfigService(
          store: store,
          nodeStorePath: Directory.systemTemp.path,
        ).assemble(
          profileId: 1,
          isSubscriptionProfile: true,
          ipv6Available: false,
          profileConfig: const {
            'proxies': <Map<String, Object?>>[],
            'rules': ['DOMAIN,example.com,DIRECT', 'MATCH,DIRECT'],
          },
        );

    expect(artifact.isValid, isTrue);
    expect(
      artifact.diagnostics.map((item) => item.code),
      contains('unattached-manual-routing'),
    );
    expect(artifact.config['rules'], ['DOMAIN,example.com,DIRECT', 'MATCH,DIRECT']);
  });

  test('reads the outbound of a logical rule at the top level', () async {
    const node = ProxyNode(
      id: 504,
      displayName: 'Logical Manual',
      type: 'socks5',
      config: {
        'name': 'Logical Manual',
        'type': 'socks5',
        'server': 'manual.example.com',
        'port': 443,
      },
      fingerprint: 'logical-manual',
    );
    await store.restore(
      const [],
      const [],
      const [],
      const [],
      const [],
      proxyNodes: const [node],
      proxyNodeBindings: const [ProxyNodeBinding(profileId: 1, nodeId: 504)],
    );

    final artifact =
        await ProfileEffectiveConfigService(
          store: store,
          nodeStorePath: Directory.systemTemp.path,
        ).assemble(
          profileId: 1,
          isSubscriptionProfile: true,
          ipv6Available: false,
          profileConfig: const {
            'proxies': <Map<String, Object?>>[],
            'proxy-groups': [
              {
                'name': 'Manual',
                'type': 'select',
                'proxies': ['Logical Manual'],
              },
              {'name': 'PROXY', 'type': 'select', 'proxies': ['DIRECT']},
            ],
            'rules': [
              'AND,((DOMAIN,a.com),(NETWORK,UDP)),Manual',
              'MATCH,PROXY',
            ],
          },
        );

    // Manual is reachable through the logical rule, so nothing is appended.
    final proxy = (artifact.config['proxy-groups'] as List)
        .cast<Map>()
        .singleWhere((group) => group['name'] == 'PROXY');
    expect(proxy['proxies'], ['DIRECT']);
  });

  test(
    'preserves subscription rules while attaching a manual node group',
    () async {
      const node = ProxyNode(
        id: 502,
        displayName: 'Subscription Manual',
        type: 'socks5',
        config: {
          'name': 'Subscription Manual',
          'type': 'socks5',
          'server': 'manual.example.com',
          'port': 443,
        },
        fingerprint: 'subscription-manual',
      );
      await store.restore(
        const [],
        const [],
        const [],
        const [],
        const [],
        proxyNodes: const [node],
        proxyNodeBindings: const [ProxyNodeBinding(profileId: 1, nodeId: 502)],
      );

      final artifact =
          await ProfileEffectiveConfigService(
            store: store,
            nodeStorePath: Directory.systemTemp.path,
          ).assemble(
            profileId: 1,
            isSubscriptionProfile: true,
            ipv6Available: false,
            profileConfig: const {
              'proxies': <Map<String, Object?>>[],
              'proxy-groups': [
                {'name': 'PROXY', 'type': 'select', 'proxies': <String>[]},
              ],
              'rules': ['DOMAIN,cn,DIRECT', 'MATCH,PROXY'],
            },
          );

      expect(artifact.isValid, isTrue);
      expect(artifact.config['rules'], ['DOMAIN,cn,DIRECT', 'MATCH,PROXY']);
      final proxyGroup = (artifact.config['proxy-groups'] as List)
          .cast<Map>()
          .singleWhere((group) => group['name'] == 'PROXY');
      expect(proxyGroup['proxies'], contains('__avalon_manual_nodes'));
    },
  );

  test('leaves an explicit udp flag on profile proxies alone', () async {
    final artifact =
        await ProfileEffectiveConfigService(
          store: store,
          nodeStorePath: Directory.systemTemp.path,
        ).assemble(
          profileId: 1,
          profileConfig: const {
            'proxies': [
              {
                'name': 'Opted out',
                'type': 'socks5',
                'server': 'HOST',
                'port': 1080,
                'udp': false,
              },
              {
                'name': 'Native',
                'type': 'hysteria2',
                'server': 'HOST',
                'port': 443,
                'password': 'PASSWORD',
              },
            ],
          },
        );

    expect(artifact.isValid, isTrue);
    final proxies = {
      for (final proxy in artifact.config['proxies'] as List)
        (proxy as Map)['name']: proxy,
    };
    expect(proxies['Opted out']!['udp'], isFalse);
    expect(proxies['Native']!.containsKey('udp'), isFalse);
  });

  // 内核在配置缺 `udp` 时按不支持 UDP 处理，规则命中后会被跳过并回落到 DIRECT，
  // UDP 就带着真实地址从物理网卡直连出去。存量节点（分享链接导入时还没有补齐
  // 默认值的那些）只能靠生成阶段兜住。
  test('fills in udp for stored nodes that omit it', () async {
    const profile = Profile(
      id: 1,
      label: 'Profile',
      autoUpdateDuration: Duration.zero,
    );
    const gated = ProxyNode(
      id: 100,
      displayName: 'Gated',
      type: 'vless',
      config: {
        'name': 'Gated',
        'type': 'vless',
        'server': 'HOST',
        'port': 443,
        'uuid': 'UUID',
      },
      fingerprint: 'gated',
    );
    const optedOut = ProxyNode(
      id: 101,
      displayName: 'OptedOut',
      type: 'vless',
      config: {
        'name': 'OptedOut',
        'type': 'vless',
        'server': 'HOST',
        'port': 443,
        'uuid': 'UUID',
        'udp': false,
      },
      fingerprint: 'opted-out',
    );
    const native = ProxyNode(
      id: 102,
      displayName: 'Native',
      type: 'hysteria2',
      config: {
        'name': 'Native',
        'type': 'hysteria2',
        'server': 'HOST',
        'port': 443,
        'password': 'PASSWORD',
      },
      fingerprint: 'native',
    );
    await store.profilesDao.putAll([profile.toCompanion()]);
    await store.restore(
      const [],
      const [],
      const [],
      const [],
      const [],
      proxyNodes: const [gated, optedOut, native],
      proxyNodeBindings: const [
        ProxyNodeBinding(profileId: 1, nodeId: 100),
        ProxyNodeBinding(profileId: 1, nodeId: 101),
        ProxyNodeBinding(profileId: 1, nodeId: 102),
      ],
    );

    final artifact =
        await ProfileEffectiveConfigService(
          store: store,
          nodeStorePath: Directory.systemTemp.path,
        ).assemble(profileId: 1, profileConfig: const {'proxies': []});

    expect(artifact.isValid, isTrue);
    final proxies = {
      for (final proxy in artifact.config['proxies'] as List)
        (proxy as Map)['name']: proxy,
    };
    expect(proxies['Gated']!['udp'], isTrue);
    // 用户显式关掉的仍然是关掉的。
    expect(proxies['OptedOut']!['udp'], isFalse);
    // hysteria2 的 UDP 能力不看这个键，别塞一个内核不读的字段进去。
    expect(proxies['Native']!.containsKey('udp'), isFalse);
  });

  test('reports missing assets only when a node is used', () async {
    const profile = Profile(
      id: 1,
      label: 'Profile',
      autoUpdateDuration: Duration.zero,
    );
    const node = ProxyNode(
      id: 100,
      displayName: 'Node',
      type: 'socks',
      config: {'name': 'Node', 'type': 'socks', 'server': 'HOST', 'port': 1080},
      fingerprint: 'fingerprint',
    );
    const asset = ProxyNodeAsset(
      id: 300,
      nodeId: 100,
      fieldPath: 'tls.cert',
      fileName: 'cert.pem',
      relativePath: 'nodes/100/assets/cert.pem',
      sha256: 'hash',
      size: 4,
    );
    await store.profilesDao.putAll([profile.toCompanion()]);
    await store.restore(
      const [],
      const [],
      const [],
      const [],
      const [],
      proxyNodes: const [node],
      proxyNodeAssets: const [asset],
    );
    final service = ProfileEffectiveConfigService(
      store: store,
      nodeStorePath: Directory.systemTemp.path,
    );
    final unused = await service.assemble(
      profileId: 1,
      profileConfig: const {'proxies': []},
    );
    expect(unused.isValid, isTrue);

    await store.proxyNodeBindingsDao.put(
      const ProxyNodeBinding(profileId: 1, nodeId: 100),
    );
    final used = await service.assemble(
      profileId: 1,
      profileConfig: const {'proxies': []},
    );
    expect(used.isValid, isFalse);
    expect(
      used.diagnostics.map((item) => item.code),
      contains('missing-node-asset'),
    );
  });

  group('chain entry groups', () {
    const profile = Profile(
      id: 1,
      label: 'Profile',
      autoUpdateDuration: Duration.zero,
    );
    const node = ProxyNode(
      id: 100,
      displayName: 'Node',
      type: 'socks',
      config: {'name': 'Node', 'type': 'socks', 'server': 'HOST', 'port': 1080},
      fingerprint: 'fingerprint',
    );
    const chain = ProxyChain(id: 200, name: 'Route');
    const hop = ProxyChainHop(
      id: 201,
      chainId: 200,
      order: 0,
      targetKind: 'node',
      nodeId: 100,
    );
    const profileConfig = {
      'proxies': [
        {'name': 'Source', 'type': 'socks', 'server': 'HOST', 'port': 1080},
      ],
      'proxy-groups': [
        {
          'name': 'G',
          'type': 'select',
          'proxies': ['Source'],
        },
      ],
      'rules': ['MATCH,G'],
    };

    Future<void> seed({List<String> entryGroups = const []}) async {
      await store.profilesDao.putAll([profile.toCompanion()]);
      await store.restore(
        const [],
        const [],
        const [],
        const [],
        const [],
        proxyNodes: const [node],
        proxyChains: const [chain],
        proxyChainHops: const [hop],
        proxyChainBindings: [
          ProxyChainBinding(
            profileId: 1,
            chainId: 200,
            isDefault: true,
            entryGroups: entryGroups,
          ),
        ],
      );
    }

    Future<EffectiveConfigArtifact> assemble() {
      return ProfileEffectiveConfigService(
        store: store,
        nodeStorePath: Directory.systemTemp.path,
      ).assemble(profileId: 1, profileConfig: profileConfig);
    }

    List<String> membersOf(EffectiveConfigArtifact artifact, String name) {
      final group = (artifact.config['proxy-groups'] as List)
          .cast<Map>()
          .firstWhere((item) => item['name'] == name);
      return (group['proxies'] as List).map((item) => item.toString()).toList();
    }

    test(
      'connects an unconfigured chain to the effective MATCH group',
      () async {
        await seed();
        final artifact = await assemble();
        expect(membersOf(artifact, 'G'), ['Source', '__avalon_chains']);
        final aggregate = (artifact.config['proxy-groups'] as List)
            .cast<Map>()
            .singleWhere((item) => item['name'] == '__avalon_chains');
        expect(aggregate['hidden'], isTrue);
      },
    );

    test('adds the chain selector to the selected entry group', () async {
      await seed(entryGroups: const ['G']);
      final artifact = await assemble();
      final selector = artifact.chainResults.single.generatedGroups.first.name;
      final members = membersOf(artifact, 'G');
      expect(members.first, 'Source');
      expect(members, contains(selector));
      expect(
        (artifact.config['proxy-groups'] as List)
            .cast<Map>()
            .any((item) => item['name'] == '__avalon_chains'),
        isFalse,
      );
      expect(
        artifact.diagnostics.map((item) => item.code),
        isNot(contains('missing-chain-entry-group')),
      );
    });

    test('drops the entry once the binding is disabled', () async {
      await seed(entryGroups: const ['G']);
      await store.proxyChainBindingsDao.put(
        const ProxyChainBinding(
          profileId: 1,
          chainId: 200,
          enabled: false,
          entryGroups: ['G'],
        ),
      );
      final artifact = await assemble();
      expect(membersOf(artifact, 'G'), ['Source']);
      expect(artifact.chainResults, isEmpty);
    });

    test('warns when the entry group is missing from the profile', () async {
      await seed(entryGroups: const ['MISSING']);
      final artifact = await assemble();
      expect(membersOf(artifact, 'G'), ['Source']);
      expect(
        artifact.diagnostics.map((item) => item.code),
        contains('missing-chain-entry-group'),
      );
      expect(
        (artifact.config['proxy-groups'] as List)
            .cast<Map>()
            .any((item) => item['name'] == '__avalon_chains'),
        isFalse,
      );
      expect(artifact.isValid, isTrue);
    });

    // Backs `addProfileFromChain`: the generated stub profile ships an empty
    // entry group so the appended chain selector ends up as the only member,
    // and therefore the default outbound.
    test('makes the chain the sole member of an empty entry group', () async {
      await store.profilesDao.putAll([profile.toCompanion()]);
      await store.restore(
        const [],
        const [],
        const [],
        const [],
        const [],
        proxyNodes: const [node],
        proxyChains: const [chain],
        proxyChainHops: const [hop],
        proxyChainBindings: const [
          ProxyChainBinding(
            profileId: 1,
            chainId: 200,
            isDefault: true,
            entryGroups: ['PROXY'],
          ),
        ],
      );
      final artifact =
          await ProfileEffectiveConfigService(
            store: store,
            nodeStorePath: Directory.systemTemp.path,
          ).assemble(
            profileId: 1,
            profileConfig: const {
              'proxies': <Map<String, Object?>>[],
              'proxy-groups': [
                {'name': 'PROXY', 'type': 'select', 'proxies': <String>[]},
              ],
              'rules': ['MATCH,PROXY'],
            },
          );
      final selector = artifact.chainResults.single.generatedGroups.first.name;
      expect(selector, chain.name);
      expect(membersOf(artifact, 'PROXY'), [selector]);
      expect(
        artifact.diagnostics.map((item) => item.code),
        isNot(contains('missing-chain-entry-group')),
      );
      expect(artifact.isValid, isTrue);
    });
  });

  group('chain preview', () {
    const profile = Profile(
      id: 1,
      label: 'Profile',
      autoUpdateDuration: Duration.zero,
    );
    const node = ProxyNode(
      id: 100,
      displayName: 'Node',
      type: 'socks',
      config: {'name': 'Node', 'type': 'socks', 'server': 'HOST', 'port': 1080},
      fingerprint: 'fingerprint',
    );
    const chain = ProxyChain(id: 200, name: 'Route');

    setUp(() async {
      await store.profilesDao.putAll([profile.toCompanion()]);
      await store.restore(
        const [],
        const [],
        const [],
        const [],
        const [],
        proxyNodes: const [node],
        proxyChains: const [chain],
      );
    });

    Future<ChainPreview> preview(List<ProxyChainHop> hops) {
      return ProfileEffectiveConfigService(
        store: store,
        nodeStorePath: Directory.systemTemp.path,
      ).previewChain(
        profileId: 1,
        profileConfig: const {'proxies': []},
        chain: chain,
        hops: hops,
      );
    }

    test('counts the compiled paths of an unsaved chain', () async {
      final result = await preview(const [
        ProxyChainHop(
          id: 201,
          chainId: 200,
          order: 0,
          targetKind: 'node',
          nodeId: 100,
        ),
      ]);
      expect(result.pathCount, 1);
      expect(result.diagnostics, isEmpty);
      expect(result.isValid, isTrue);
    });

    test('reports an empty chain before it is saved', () async {
      final result = await preview(const []);
      expect(result.pathCount, 0);
      expect(
        result.diagnostics.map((item) => item.code),
        contains('empty-chain'),
      );
      expect(result.isValid, isFalse);
    });

    test('reports a hop that cannot be resolved in this profile', () async {
      final result = await preview(const [
        ProxyChainHop(
          id: 201,
          chainId: 200,
          order: 0,
          targetKind: 'node',
          nodeId: 999,
        ),
      ]);
      expect(
        result.diagnostics.map((item) => item.code),
        contains('invalid-hop'),
      );
      expect(result.isValid, isFalse);
    });

    test('exposes generated proxies, selector and node ids', () async {
      final result = await preview(const [
        ProxyChainHop(
          id: 201,
          chainId: 200,
          order: 0,
          targetKind: 'node',
          nodeId: 100,
        ),
        ProxyChainHop(
          id: 202,
          chainId: 200,
          order: 1,
          targetKind: 'local-endpoint',
          localEndpoint: {
            'type': 'socks5',
            'server': '127.0.0.1',
            'port': 7890,
          },
        ),
      ]);

      expect(result.isValid, isTrue);
      expect(result.generatedProxies, hasLength(2));
      expect(result.generatedGroups.single.proxies, hasLength(1));
      final terminal = result.generatedGroups.single.proxies.single;
      expect(result.generatedProxies[terminal]!['dialer-proxy'], isNotNull);
      expect(result.generatedNodeIds.values, contains('100'));
    });

    test('leaves the stored chain untouched', () async {
      await preview(const [
        ProxyChainHop(
          id: 201,
          chainId: 200,
          order: 0,
          targetKind: 'node',
          nodeId: 100,
        ),
      ]);
      expect(await store.proxyChainHopsDao.query(200).get(), isEmpty);
      expect(await store.proxyChainBindingsDao.query(1).get(), isEmpty);
    });
  });

  test('keeps a library node usable when only its chain is bound', () async {
    const profile = Profile(
      id: 1,
      label: 'Profile',
      autoUpdateDuration: Duration.zero,
    );
    const node = ProxyNode(
      id: 100,
      displayName: 'Manual',
      type: 'socks',
      config: {
        'name': 'Manual',
        'type': 'socks',
        'server': 'MANUAL_HOST',
        'port': 1080,
      },
      fingerprint: 'manual',
    );
    const chain = ProxyChain(id: 200, name: 'Route');
    const hop = ProxyChainHop(
      id: 201,
      chainId: 200,
      order: 0,
      targetKind: 'node',
      nodeId: 100,
    );
    await store.profilesDao.putAll([profile.toCompanion()]);
    await store.restore(
      const [],
      const [],
      const [],
      const [],
      const [],
      proxyNodes: const [node],
      proxyChains: const [chain],
      proxyChainHops: const [hop],
      proxyChainBindings: const [ProxyChainBinding(profileId: 1, chainId: 200)],
    );

    final artifact = await ProfileEffectiveConfigService(
      store: store,
      nodeStorePath: Directory.systemTemp.path,
    ).assemble(profileId: 1, profileConfig: const {'proxies': []});

    expect(artifact.diagnostics.map((item) => item.code), isEmpty);
    expect(artifact.isValid, isTrue);
    expect(artifact.chainResults.single.paths, hasLength(1));
    expect(
      (artifact.config['proxies'] as List).where(
        (item) => item is Map && item['server'] == 'MANUAL_HOST',
      ),
      hasLength(1),
    );
  });

  test('keeps distinct endpoints for same named source nodes', () async {
    const profile = Profile(
      id: 1,
      label: 'Profile',
      autoUpdateDuration: Duration.zero,
    );
    const first = ProxyNode(
      id: 100,
      displayName: 'Shared',
      type: 'socks',
      config: {
        'name': 'Shared',
        'type': 'socks',
        'server': 'HOST_A',
        'port': 1080,
      },
      sourceSnapshot: {
        'name': 'Shared',
        'type': 'socks',
        'server': 'HOST_A',
        'port': 1080,
      },
      source: ProxyNodeSource(
        kind: 'profile',
        profileId: 1,
        sourceKey: 'profile::Shared',
      ),
      fingerprint: 'first',
    );
    const second = ProxyNode(
      id: 101,
      displayName: 'Shared',
      type: 'socks',
      config: {
        'name': 'Shared',
        'type': 'socks',
        'server': 'HOST_B',
        'port': 1080,
      },
      sourceSnapshot: {
        'name': 'Shared',
        'type': 'socks',
        'server': 'HOST_B',
        'port': 1080,
      },
      source: ProxyNodeSource(
        kind: 'profile',
        profileId: 1,
        sourceKey: 'profile::Shared#1',
      ),
      fingerprint: 'second',
    );
    await store.profilesDao.putAll([profile.toCompanion()]);
    await store.restore(
      const [],
      const [],
      const [],
      const [],
      const [],
      proxyNodes: const [first, second],
      proxyNodeBindings: const [
        ProxyNodeBinding(profileId: 1, nodeId: 100),
        ProxyNodeBinding(profileId: 1, nodeId: 101),
      ],
    );

    final artifact =
        await ProfileEffectiveConfigService(
          store: store,
          nodeStorePath: Directory.systemTemp.path,
        ).assemble(
          profileId: 1,
          profileConfig: const {
            'proxies': [
              {
                'name': 'Shared',
                'type': 'socks',
                'server': 'HOST_A',
                'port': 1080,
              },
              {
                'name': 'Shared',
                'type': 'socks',
                'server': 'HOST_B',
                'port': 1080,
              },
            ],
          },
        );

    final proxies = (artifact.config['proxies'] as List).cast<Map>();
    expect(proxies, hasLength(2));
    expect(proxies.map((item) => item['server']).toSet(), {'HOST_A', 'HOST_B'});
    expect(proxies.map((item) => item['name']).toSet(), hasLength(2));
  });

  test(
    'does not expose a source node from another profile to a chain',
    () async {
      const firstProfile = Profile(
        id: 1,
        label: 'First',
        autoUpdateDuration: Duration.zero,
      );
      const secondProfile = Profile(
        id: 2,
        label: 'Second',
        autoUpdateDuration: Duration.zero,
      );
      const foreignNode = ProxyNode(
        id: 100,
        displayName: 'Foreign',
        type: 'socks',
        config: {
          'name': 'Foreign',
          'type': 'socks',
          'server': 'FOREIGN_HOST',
          'port': 1080,
        },
        source: ProxyNodeSource(kind: 'profile', profileId: 2),
        sourceSnapshot: {
          'name': 'Foreign',
          'type': 'socks',
          'server': 'FOREIGN_HOST',
          'port': 1080,
        },
        fingerprint: 'foreign',
      );
      const chain = ProxyChain(id: 200, name: 'Foreign route');
      const hop = ProxyChainHop(
        id: 201,
        chainId: 200,
        order: 0,
        targetKind: 'node',
        nodeId: 100,
      );
      await store.profilesDao.putAll([
        firstProfile.toCompanion(),
        secondProfile.toCompanion(),
      ]);
      await store.restore(
        const [],
        const [],
        const [],
        const [],
        const [],
        proxyNodes: const [foreignNode],
        proxyChains: const [chain],
        proxyChainHops: const [hop],
        proxyChainBindings: const [
          ProxyChainBinding(profileId: 1, chainId: 200),
        ],
      );

      final artifact = await ProfileEffectiveConfigService(
        store: store,
        nodeStorePath: Directory.systemTemp.path,
      ).assemble(profileId: 1, profileConfig: const {'proxies': []});

      expect(
        artifact.diagnostics.map((item) => item.code),
        contains('invalid-hop'),
      );
      expect(
        (artifact.config['proxies'] as List).where(
          (item) => item is Map && item['server'] == 'FOREIGN_HOST',
        ),
        isEmpty,
      );
    },
  );
}
