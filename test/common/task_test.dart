import 'package:avalon/common/task.dart';
import 'package:avalon/enum/enum.dart';
import 'package:avalon/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

int _double(int value) => value * 2;

void main() {
  test('encoding helpers round-trip structured data', () async {
    final encoded = await encodeJSONTask({
      'name': 'Avalon',
      'values': [1, true, null],
    });
    final decoded = await decodeJSONTask<Map<String, dynamic>>(encoded);

    expect(decoded['name'], 'Avalon');
    expect(decoded['values'], [1, true, null]);
    expect(await encodeYamlTask({'enabled': true}), contains('enabled: true'));
    expect(await encodeMD5Task('abc'), '900150983cd24fb0d6963f7d28e17f72');
  });

  test('toGroupsTask converts, selects, and sorts core proxy data', () async {
    final proxies = <String, dynamic>{
      'Selector': {
        'name': 'Selector',
        'type': 'Selector',
        'now': 'Beta',
        'all': ['Zulu', 'Beta', 'missing'],
      },
      'Direct': {'name': 'Direct', 'type': 'Direct'},
      'Zulu': {'name': 'Zulu', 'type': 'Direct'},
      'Beta': {'name': 'Beta', 'type': 'Direct'},
    };
    final groups = await toGroupsTask(
      ComputeGroupsState(
        proxiesData: ProxiesData(
          all: const ['Selector', 'Direct'],
          proxies: proxies,
        ),
        sortType: ProxiesSortType.name,
        delayMap: const {},
        selectedMap: const {'Selector': 'Beta'},
        defaultTestUrl: 'https://example.com/generate_204',
      ),
    );

    expect(groups, hasLength(1));
    expect(groups.single.name, 'Selector');
    expect(groups.single.all.map((proxy) => proxy.name), ['Beta', 'Zulu']);
  });

  test('toGroupsTask returns empty data without proxies', () async {
    final groups = await toGroupsTask(
      const ComputeGroupsState(
        proxiesData: ProxiesData(proxies: {}, all: []),
        sortType: ProxiesSortType.none,
        delayMap: {},
        selectedMap: {},
        defaultTestUrl: '',
      ),
    );

    expect(groups, isEmpty);
  });

  test(
    'makeRealProfileTask normalizes runtime config and added rules',
    () async {
      final rawConfig = await decodeJSONTask<Map<String, dynamic>>(
        await encodeJSONTask({
          'dns': {
            'enable': true,
            'nameserver': ['1.1.1.1'],
          },
          'sniffer': {
            'sniff': {
              'HTTP': {
                'ports': [80, '443'],
              },
            },
          },
          'proxy-providers': {
            'remote': {'type': 'http', 'url': 'https://example.com/proxy.yaml'},
            'file': {'type': 'file', 'path': './local.yaml'},
          },
          'rule-providers': {
            'remote': {'type': 'http', 'url': 'https://example.com/rule.yaml'},
          },
          'rules': ['DOMAIN,existing.example,DIRECT', 'MATCH,Original'],
        }),
      );
      final result = await makeRealProfileTask(
        MakeRealProfileState(
          profilesPath: '/profiles',
          profileId: 7,
          rawConfig: rawConfig,
          realPatchConfig: const PatchClashConfig(
            mixedPort: 7893,
            port: 7890,
            socksPort: 7891,
            redirPort: 7892,
            tproxyPort: 7894,
            allowLan: true,
            ipv6: true,
            hosts: {'router.local': '192.168.1.1,192.168.1.2'},
          ),
          overrideDns: false,
          appendSystemDns: true,
          proxyGroups: const [],
          rules: const [],
          addedRules: const [
            Rule(
              ruleAction: RuleAction.DOMAIN_SUFFIX,
              content: 'added.example',
              ruleTarget: 'MATCH',
            ),
          ],
          defaultUA: 'Avalon-Test',
        ),
      );
      final config = loadYaml(result.a) as YamlMap;

      expect(result.b, hasLength(32));
      expect(config['mixed-port'], 7893);
      expect(config['allow-lan'], true);
      expect(config['global-ua'], 'Avalon-Test');
      expect(config['profile']['store-selected'], false);
      expect(
        config['dns']['nameserver'],
        containsAll(['1.1.1.1', 'system://']),
      );
      expect(config['hosts']['router.local'], ['192.168.1.1', '192.168.1.2']);
      expect(config['sniffer']['sniff']['HTTP']['ports'], ['80', '443']);
      expect(
        config['proxy-providers']['remote']['path'],
        startsWith('/profiles/providers/7/proxies/'),
      );
      expect(
        config['rule-providers']['remote']['path'],
        startsWith('/profiles/providers/7/rules/'),
      );
      expect(config['rules'], [
        'DOMAIN-SUFFIX,added.example,Original',
        'DOMAIN,existing.example,DIRECT',
        'MATCH,Original',
      ]);
    },
  );

  test('makeRealProfileTask replaces DNS and explicit custom data', () async {
    final result = await makeRealProfileTask(
      const MakeRealProfileState(
        profilesPath: '/profiles',
        profileId: 9,
        rawConfig: {},
        realPatchConfig: PatchClashConfig(),
        overrideDns: true,
        appendSystemDns: false,
        proxyGroups: [
          ProxyGroup(
            id: 1,
            name: 'Select',
            type: GroupType.Selector,
            proxies: ['DIRECT'],
          ),
        ],
        rules: [
          Rule(
            ruleAction: RuleAction.DOMAIN,
            content: 'custom.example',
            ruleTarget: 'DIRECT',
          ),
        ],
        addedRules: [],
        defaultUA: 'Fallback-UA',
      ),
    );
    final config = loadYaml(result.a) as YamlMap;

    expect(config['dns']['enable'], true);
    expect(config['dns']['nameserver'], contains('system://'));
    expect(config['proxy-groups'], hasLength(2));
    final groups = config['proxy-groups'] as YamlList;
    expect(
      groups.firstWhere((item) => item['name'] == 'Select')['id'],
      isNull,
    );
    expect(config['rules'], ['DOMAIN,custom.example,DIRECT']);
  });

  test(
    'makeRealProfileTask keeps generated chain groups with custom data',
    () async {
      final result = await makeRealProfileTask(
        const MakeRealProfileState(
          profilesPath: '/profiles',
          profileId: 10,
          rawConfig: {
            'proxy-groups': [
              {
                'name': '__avalon_chain_1_selector',
                'type': 'select',
                'proxies': ['CHAIN'],
              },
            ],
          },
          realPatchConfig: PatchClashConfig(),
          overrideDns: false,
          appendSystemDns: false,
          proxyGroups: [
            ProxyGroup(
              id: 1,
              name: 'Select',
              type: GroupType.Selector,
              proxies: ['DIRECT'],
            ),
          ],
          rules: [],
          addedRules: [],
          defaultUA: 'Fallback-UA',
        ),
      );
      final config = loadYaml(result.a) as YamlMap;
      expect(config['proxy-groups'], hasLength(3));
      expect(
        (config['proxy-groups'] as YamlList).map((item) => item['name']),
        contains('__avalon_chain_1_selector'),
      );
    },
  );

  test('makeRealProfileTask adds GLOBAL pointing at PROXY', () async {
    final result = await makeRealProfileTask(
      const MakeRealProfileState(
        profilesPath: '/profiles',
        profileId: 12,
        rawConfig: {
          'proxies': [
            {'name': 'CHAIN_EXIT', 'type': 'socks5'},
          ],
          'proxy-groups': [
            {
              'name': 'PROXY',
              'type': 'select',
              'proxies': ['CHAIN_EXIT'],
            },
          ],
        },
        realPatchConfig: PatchClashConfig(),
        overrideDns: false,
        appendSystemDns: false,
        proxyGroups: [],
        rules: [],
        addedRules: [],
        defaultUA: 'Fallback-UA',
      ),
    );
    final config = loadYaml(result.a) as YamlMap;
    final globals = (config['proxy-groups'] as YamlList)
        .where((item) => item['name'] == 'GLOBAL')
        .toList();
    expect(globals, hasLength(1));
    expect(globals.single['proxies'], ['PROXY']);
  });

  test('makeRealProfileTask preserves an explicit GLOBAL group', () async {
    final result = await makeRealProfileTask(
      const MakeRealProfileState(
        profilesPath: '/profiles',
        profileId: 13,
        rawConfig: {
          'proxy-groups': [
            {
              'name': 'PROXY',
              'type': 'select',
              'proxies': ['DIRECT'],
            },
            {
              'name': 'GLOBAL',
              'type': 'select',
              'proxies': ['PROXY'],
            },
          ],
        },
        realPatchConfig: PatchClashConfig(),
        overrideDns: false,
        appendSystemDns: false,
        proxyGroups: [],
        rules: [],
        addedRules: [],
        defaultUA: 'Fallback-UA',
      ),
    );
    final config = loadYaml(result.a) as YamlMap;
    final names = (config['proxy-groups'] as YamlList)
        .map((item) => item['name'])
        .toList();
    expect(names.where((name) => name == 'GLOBAL'), hasLength(1));
  });

  test('makeRealProfileTask avoids introducing a GLOBAL group cycle', () async {
    final result = await makeRealProfileTask(
      const MakeRealProfileState(
        profilesPath: '/profiles',
        profileId: 14,
        rawConfig: {
          'proxy-groups': [
            {
              'name': 'PROXY',
              'type': 'select',
              'proxies': ['GLOBAL'],
            },
            {
              'name': 'SAFE',
              'type': 'select',
              'proxies': ['DIRECT'],
            },
          ],
          'rules': ['MATCH,PROXY'],
        },
        realPatchConfig: PatchClashConfig(),
        overrideDns: false,
        appendSystemDns: false,
        proxyGroups: [],
        rules: [],
        addedRules: [],
        defaultUA: 'Fallback-UA',
      ),
    );
    final config = loadYaml(result.a) as YamlMap;
    final global = (config['proxy-groups'] as YamlList).firstWhere(
      (item) => item['name'] == 'GLOBAL',
    );
    expect(global['proxies'], ['SAFE']);
  });

  Future<YamlMap> buildRealProfile(
    PatchClashConfig patchConfig, {
    Map<String, dynamic> rawConfig = const {},
    bool overrideDns = true,
    bool? tunTakesIpv6,
  }) async {
    final result = await makeRealProfileTask(
      MakeRealProfileState(
        profilesPath: '/profiles',
        profileId: 11,
        rawConfig: rawConfig,
        realPatchConfig: patchConfig,
        // 桌面端 SetupAction._tunTakesIpv6 就是这么算的。
        tunTakesIpv6:
            tunTakesIpv6 ?? (patchConfig.tun.enable && patchConfig.tun.ipv6),
        overrideDns: overrideDns,
        appendSystemDns: false,
        proxyGroups: const [],
        rules: const [],
        addedRules: const [],
        defaultUA: 'Fallback-UA',
      ),
    );
    return loadYaml(result.a) as YamlMap;
  }

  test('makeRealProfileTask lets TUN take over IPv6 only on request', () async {
    // 默认：TUN 打开即接管 IPv6，内核在 ipv6: false 时会清空 inet6-address，
    // 让 IPv6 绕过隧道泄漏真实地址。
    final on = await buildRealProfile(
      const PatchClashConfig(tun: Tun(enable: true, autoRoute: true)),
    );
    expect(on['tun']['strict-route'], true);
    expect(on['tun']['inet6-address'], ['fdfe:dcba:9876::1/126']);
    expect(on['ipv6'], true);

    // 用户关掉 TUN IPv6 后不接管：不下发 inet6-address，也不覆盖用户关掉的全局开关。
    final tunOnly = await buildRealProfile(
      const PatchClashConfig(
        tun: Tun(enable: true, autoRoute: true, ipv6: false),
      ),
    );
    expect(tunOnly['tun']['enable'], true);
    expect(tunOnly['tun']['inet6-address'], isEmpty);
    expect(tunOnly['ipv6'], false);

    // 用户自己打开全局 IPv6 时保持原样。
    final globalIpv6 = await buildRealProfile(
      const PatchClashConfig(ipv6: true, tun: Tun(ipv6: false)),
    );
    expect(globalIpv6['ipv6'], true);
    expect(globalIpv6['tun']['inet6-address'], isEmpty);

    // TUN 没开就不该接管，哪怕 tun.ipv6 是默认的 true。
    final off = await buildRealProfile(const PatchClashConfig());
    expect(off['tun']['enable'], false);
    expect(off['tun']['inet6-address'], isEmpty);
    expect(off['ipv6'], false);

    // Android：虚拟网卡由 VpnService 建立，tun.enable 恒为 false，接管与否由调用方
    // 依据 VPN 的 IPv6 开关算出来后传进来。
    final android = await buildRealProfile(
      const PatchClashConfig(),
      tunTakesIpv6: true,
    );
    expect(android['tun']['enable'], false);
    expect(android['ipv6'], true);
  });

  test('makeRealProfileTask gates the IPv6 fake-ip pool on dns.ipv6', () async {
    final off = await buildRealProfile(const PatchClashConfig());
    expect(off['dns']['fake-ip-range6'], '');

    final on = await buildRealProfile(
      const PatchClashConfig(dns: Dns(ipv6: true)),
    );
    expect(on['dns']['fake-ip-range6'], 'fdfe:dcba:9876::1/64');
  });

  test(
    'makeRealProfileTask gates the IPv6 fake-ip pool for profile DNS too',
    () async {
      // 订阅自带 dns 块且未开启覆盖时，其余键沿用订阅，但 v6 fake 池仍由本地开关
      // 决定，否则订阅写的 ipv6: true 会架空设置里的 DNS IPv6 开关。
      const profileDns = {
        'dns': {
          'enable': true,
          'ipv6': true,
          'enhanced-mode': 'fake-ip',
          'fake-ip-range6': 'fdfe:dcba:9876::1/64',
          'nameserver': ['223.5.5.5'],
        },
      };

      final off = await buildRealProfile(
        const PatchClashConfig(),
        rawConfig: profileDns,
        overrideDns: false,
      );
      expect(off['dns']['nameserver'], ['223.5.5.5']);
      expect(off['dns']['fake-ip-range6'], '');

      final on = await buildRealProfile(
        const PatchClashConfig(dns: Dns(ipv6: true)),
        rawConfig: profileDns,
        overrideDns: false,
      );
      expect(on['dns']['fake-ip-range6'], 'fdfe:dcba:9876::1/64');
    },
  );

  test('log and list tasks produce stable mapped output', () async {
    final logs = [
      const Log(
        logLevel: LogLevel.info,
        payload: 'first',
        dateTime: '2026-07-26 10:00:00',
      ),
      const Log(
        logLevel: LogLevel.error,
        payload: 'second',
        dateTime: '2026-07-26 10:00:01',
      ),
    ];

    final encoded = await encodeLogsTask(logs);

    expect(encoded, contains('first'));
    expect(encoded, contains('\n'));
    expect(await mapListTask([1, 2, 3], _double), [2, 4, 6]);
  });
}
