// Compiler (CONFIG_PIPELINE §6–7). Golden plans are stored redacted;
// regenerate with `UPDATE_GOLDENS=1 dart test test/compiler_test.dart` and
// review the diff.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:av_core/av_core.dart';
import 'package:test/test.dart';

final _key = Uint8List.fromList(List.filled(32, 7));

const _mac = HostInfo(
  platform: HostPlatform.macos,
  stateDir: '/state',
  deviceName: 'mac',
  bridgeVersion: '1',
  coreVersion: '1.14.2',
);
const _android = HostInfo(
  platform: HostPlatform.android,
  stateDir: '/data/state',
  deviceName: 'pixel',
);
const _windows = HostInfo(
  platform: HostPlatform.windows,
  stateDir: r'C:\ProgramData\Avalon',
  deviceName: 'pc',
);

ConfigContent _content(
  String fixture, {
  Map<String, String> providers = const {},
}) => parseContent(
  File('test/fixtures/$fixture').readAsStringSync(),
  providers: providers,
).content;

void _golden(String name, CompiledPlan plan) {
  final file = File('test/goldens/$name.json');
  final text =
      '${const JsonEncoder.withIndent('  ').convert(plan.redacted())}\n';
  if (Platform.environment['UPDATE_GOLDENS'] == '1' || !file.existsSync()) {
    file.writeAsStringSync(text);
  }
  expect(text, file.readAsStringSync(), reason: 'golden $name');
  _export(name, plan);
}

void _export(String name, CompiledPlan plan) {
  // For checking against the real core (core/check_plans.sh): the same
  // plan with the fixtures' fake secrets in place.
  final export = Platform.environment['AV_EXPORT_PLANS'];
  if (export != null) {
    File('$export/$name.json')
      ..createSync(recursive: true)
      ..writeAsStringSync(jsonEncode(plan.toJson()));
  }
}

const _selfNode = SelfNode(
  id: 'n1',
  name: '自建 VPS',
  server: 'vps.example.com',
  port: 443,
  params: NodeParams.trojan(
    password: Secret('fake-self'),
    tls: Tls(serverName: 'vps.example.com'),
  ),
);

Matcher _fails(CompileErrorCode code, [String? subject]) => throwsA(
  isA<CompileException>()
      .having((e) => e.code, 'code', code)
      .having((e) => e.subject, 'subject', subject ?? anything),
);

void main() {
  final links = parseContent(
    'vless://00000000-0000-4000-8000-000000000001@a.example.com:443'
    '?security=reality&sni=www.apple.com'
    '&pbk=fakeRealityPublicKey0000000000000000000000A#A\n'
    'hy2://fake-hy2@b.example.com:443?sni=b.example.com#B\n',
  ).content;

  test('link list on macOS, rule mode, defaults', () {
    final plan = compile(
      CompileInput(
        source: ImportedSource(id: 'cfg-links-0001', content: links),
        settings: const DeviceSettings(clashApiSecret: Secret('fake-api')),
        host: _mac,
        hashKey: _key,
      ),
    );
    _golden('plan_linklist_macos', plan);
    expect(
      plan.primaryTag,
      plan.tags.entries
          .firstWhere((e) => e.value.name == LinkListGroups.select)
          .key,
    );
  });

  test('long automatic-group intervals retain their imported cadence', () {
    for (final type in ['url-test', 'fallback', 'load-balance']) {
      for (final interval in [300, 1800, 1801, 7200, 86400]) {
        final content = parseContent('''
proxies: []
proxy-groups:
  - {name: Auto, type: $type, proxies: [DIRECT], interval: $interval}
rules:
  - MATCH,Auto
''').content;
        final plan = compile(
          CompileInput(
            source: ImportedSource(id: 'cfg', content: content),
            settings: const DeviceSettings(),
            host: _android,
            hashKey: _key,
          ),
        );
        final group = (plan.toJson()['outbounds']! as List<Object?>)
            .cast<Map<String, Object?>>()
            .singleWhere((outbound) => outbound['type'] == 'urltest');
        expect(group['interval'], '${interval}s');
        expect(group['idle_timeout'], interval > 1800 ? '${interval}s' : null);
        final export = Platform.environment['AV_EXPORT_PLANS'];
        if (export != null) {
          File('$export/plan_interval_${type}_$interval.json')
            ..createSync(recursive: true)
            ..writeAsStringSync(jsonEncode(plan.toJson()));
        }
      }
    }
  });

  test('every initial mode registers all three runtime modes', () {
    // sing-box derives the switchable modes from route/DNS conditions,
    // plus default_mode. A plan started in global or direct must still
    // accept switching back to rule without restarting the session.
    Set<String> modes(Object? value) => switch (value) {
      final Map<Object?, Object?> map => {
        if (map['clash_mode'] case final String mode) mode,
        for (final nested in map.values) ...modes(nested),
      },
      final List<Object?> list => {for (final nested in list) ...modes(nested)},
      _ => <String>{},
    };

    for (final (name, source) in <(String, CompileSource)>[
      ('links', ImportedSource(id: 'cfg', content: links)),
      (
        'final_only',
        ImportedSource(id: 'cfg', content: links.copyWith(defaultRules: false)),
      ),
      ('self', const SelfSource()),
    ]) {
      String? hash;
      for (final initial in OutboundMode.values) {
        final plan = compile(
          CompileInput(
            source: source,
            settings: DeviceSettings(mode: initial, clashApi: false),
            host: _android,
            hashKey: _key,
            selfNodes: const [_selfNode],
          ),
        );
        final json = plan.toJson();
        expect(
          {...modes(json['route']), ...modes(json['dns'])},
          containsAll(OutboundMode.values.map((mode) => mode.name)),
          reason: '${source.runtimeType}, initial ${initial.name}',
        );
        expect(plan.choices.mode, initial.name);
        hash ??= plan.planHash;
        expect(plan.planHash, hash);
        _export('plan_modes_${name}_${initial.name}', plan);
      }
    }
  });

  test('Clash on Android: self node, chain, membership, override', () {
    final clash = _content(
      'clash_basic.yaml',
      providers: {
        'remote': File('test/fixtures/provider_remote.yaml').readAsStringSync(),
      },
    );
    const chain = Chain(
      id: 'ch1',
      hops: [
        MemberRef.source(
          configurationId: 'cfg-clash-0002',
          key: 'proxy:Trojan',
        ),
        MemberRef.selfNode(id: 'n1'),
      ],
    );
    final plan = compile(
      CompileInput(
        source: ImportedSource(id: 'cfg-clash-0002', content: clash),
        settings: const DeviceSettings(
          systemProxy: true,
          perAppList: ['org.example.browser'],
          clashApiSecret: Secret('fake-api'),
        ),
        policy: const Policy(
          jsonOverride: Secret(
            '{"outbounds": [{"type": "selector", "tag": "Media", '
            '"outbounds": ["节点选择", "DIRECT"]}], '
            '"route": {"rules": [{"domain_suffix": ["netflix.com"], '
            '"outbound": "Media"}]}}',
          ),
        ),
        host: _android,
        hashKey: _key,
        selfNodes: const [_selfNode],
        chains: const [chain],
        memberships: const [
          Membership(
            ownerKind: MemberOwner.chain,
            ownerId: 'ch1',
            configurationId: 'cfg-clash-0002',
            groupKey: 'group:节点选择',
          ),
        ],
        selections: const {'group:节点选择': MemberRef.chain(id: 'ch1')},
        ruleSetCache: {
          ruleSetKeyOf(
            'https://rules.example.com/ads.txt',
            RuleSetFormat.clashDomainText,
          ): '/data/state/rulesets/ads.json',
        },
      ),
    );
    _golden('plan_clash_android', plan);
    final outbounds = plan.toJson()['outbounds']! as List;
    final hop1 = outbounds.cast<Map<String, Object?>>().firstWhere(
      (o) => o['tag'] == 'c:ch1:1',
    );
    expect(hop1['detour'], 'c:ch1:0');
    expect(hop1['password'], 'fake-self');
    expect(plan.tags['c:ch1:1']!.ref, const MemberRef.chain(id: 'ch1'));
  });

  test('unverified Tailscale exits fail before a runtime plan is emitted', () {
    const exit = MemberRef.tailnetExit(
      tailnet: 'example.github',
      nodeStableId: 'n-home',
      name: 'home-nas',
    );
    expect(
      () => compile(
        CompileInput(
          source: const SelfSource(),
          settings: const DeviceSettings(
            mode: OutboundMode.global,
            clashApi: false,
            tailnet: TailnetSettings(
              enabled: true,
              exit: exit as TailnetExitRef,
            ),
          ),
          host: _windows,
          hashKey: _key,
          selfNodes: const [_selfNode],
          selections: const {ContentKeys.custom: exit},
          tailnet: true,
        ),
      ),
      _fails(CompileErrorCode.invalidSetting, 'tailnet.exit'),
    );
    expect(
      () => compile(
        CompileInput(
          source: const SelfSource(),
          settings: const DeviceSettings(
            tailnet: TailnetSettings(enabled: true, advertiseExit: true),
          ),
          host: _windows,
          hashKey: _key,
          proxy: false,
          tailnet: true,
        ),
      ),
      _fails(CompileErrorCode.invalidSetting, 'tailnet.exit'),
    );
  });

  test('Tailscale only', () {
    final plan = compile(
      CompileInput(
        source: const SelfSource(),
        settings: const DeviceSettings(),
        host: _mac,
        hashKey: _key,
        proxy: false,
        tailnet: true,
      ),
    );
    _golden('plan_tailnet_only', plan);
  });

  test('Android keeps Tailnet routes when the ordinary proxy TUN is off', () {
    final plan = compile(
      CompileInput(
        source: const SelfSource(),
        settings: const DeviceSettings(
          tunEnabled: false,
          systemProxy: true,
          tailnet: TailnetSettings(enabled: true),
        ),
        host: _android,
        hashKey: _key,
        selfNodes: const [_selfNode],
        tailnet: true,
      ),
    ).toJson();
    final inbounds = (plan['inbounds'] as List).cast<Map<String, Object?>>();
    expect(inbounds.where((i) => i['type'] == 'mixed'), hasLength(1));
    final tun = inbounds.singleWhere((i) => i['type'] == 'tun');
    expect(tun['route_address'], [
      '100.64.0.0/10',
      'fd7a:115c:a1e0::/48',
      '100.100.100.100/32',
    ]);
    expect(tun['platform'], isNull);
    expect(tun['auto_route'], isTrue);
    expect(tun['strict_route'], isFalse);
    expect(
      (plan['endpoints'] as List).single,
      containsPair('type', 'tailscale'),
    );
  });

  test('AnyTLS share link retains TLS options in the Android runtime plan', () {
    final node = NodeDraft.fromLink(
      parseShareLink(
        'anytls://fake-password@proxy.example.com:443'
        '?insecure=1&sni=tls.example.com&udp=true&alpn=h2&fp=chrome',
      ),
    ).build().copyWith(id: 'anytls-test');
    final plan = compile(
      CompileInput(
        source: const SelfSource(),
        settings: const DeviceSettings(
          mode: OutboundMode.global,
          clashApi: false,
        ),
        host: _android,
        hashKey: _key,
        selfNodes: [node],
        selections: const {
          ContentKeys.custom: MemberRef.selfNode(id: 'anytls-test'),
        },
      ),
    );
    final outbound = (plan.toJson()['outbounds']! as List)
        .cast<Map<String, Object?>>()
        .singleWhere((o) => o['type'] == 'anytls');
    expect(outbound['password'], 'fake-password');
    expect(outbound['tls'], {
      'enabled': true,
      'server_name': 'tls.example.com',
      'insecure': true,
      'alpn': ['h2'],
      'utls': {'enabled': true, 'fingerprint': 'chrome'},
    });
    expect(outbound.containsKey('network'), isFalse);
    expect(outbound.containsKey('udp'), isFalse);
    final export = Platform.environment['AV_EXPORT_PLANS'];
    if (export != null) {
      File('$export/plan_anytls_link_android.json')
        ..createSync(recursive: true)
        ..writeAsStringSync(jsonEncode(plan.toJson()));
    }
  });

  group('plan hash', () {
    CompileInput input({String password = 'fake-hy2', String? select}) =>
        CompileInput(
          source: ImportedSource(
            id: 'cfg',
            content: links.copyWith(
              nodes: [
                links.nodes[0],
                links.nodes[1].copyWith(
                  params: (links.nodes[1].params as Hysteria2Params).copyWith(
                    password: Secret(password),
                  ),
                ),
              ],
            ),
          ),
          settings: const DeviceSettings(),
          host: _mac,
          hashKey: _key,
          selections: {
            if (select != null)
              LinkListGroups.selectKey: MemberRef.source(
                configurationId: 'cfg',
                key: select,
              ),
          },
        );

    test('is stable and follows secrets without revealing them', () {
      final a = compile(input()).planHash;
      expect(compile(input()).planHash, a);
      expect(compile(input(password: 'other')).planHash, isNot(a));
    });

    test('ignores selector choices, applied live with select', () {
      expect(compile(input(select: 'B')).planHash, compile(input()).planHash);
    });

    test('secrets reach the host but never the redacted view', () {
      final plan = compile(input());
      expect(jsonEncode(plan.toJson()), contains('fake-hy2'));
      expect(jsonEncode(plan.redacted()), isNot(contains('fake-hy2')));
    });
  });

  group('errors', () {
    CompileInput base({
      ConfigContent? content,
      DeviceSettings settings = const DeviceSettings(),
      Map<String, MemberRef> selections = const {},
      List<Chain> chains = const [],
      List<Membership> memberships = const [],
      Policy policy = const Policy(),
      HostInfo host = _mac,
    }) => CompileInput(
      source: ImportedSource(id: 'cfg', content: content ?? links),
      settings: settings,
      host: host,
      hashKey: _key,
      selections: selections,
      chains: chains,
      memberships: memberships,
      policy: policy,
    );

    test('per-app on macOS: app bundles match everything inside them', () {
      Map<String, Object?> perAppRule(HostInfo host) {
        final plan = compile(
          base(
            host: host,
            settings: const DeviceSettings(
              perAppMode: PerAppMode.blacklist,
              perAppList: [
                '/Applications/Google Chrome.app',
                '/usr/local/bin/curl',
              ],
            ),
          ),
        );
        final rules = ((plan.toJson()['route']! as Map)['rules']! as List)
            .cast<Map<String, Object?>>();
        return rules.firstWhere(
          (r) =>
              r.containsKey('process_path') ||
              r.containsKey('process_path_regex'),
        );
      }

      final mac = perAppRule(_mac);
      expect(mac['process_path'], ['/usr/local/bin/curl']);
      expect(mac['process_path_regex'], [
        r'^/Applications/Google Chrome\.app/',
      ]);
      expect(mac.containsKey('invert'), isFalse);
      // Elsewhere a path is a path.
      final windows = perAppRule(_windows);
      expect(windows['process_path'], hasLength(2));
      expect(windows.containsKey('process_path_regex'), isFalse);
    });

    test('a selection that left the group falls back to the first member', () {
      final plan = compile(
        base(
          selections: {
            LinkListGroups.selectKey: const MemberRef.source(
              configurationId: 'cfg',
              key: 'vanished',
            ),
          },
        ),
      );
      final selector = (plan.toJson()['outbounds']! as List)
          .cast<Map<String, Object?>>()
          .firstWhere((o) => o['tag'] == plan.primaryTag);
      expect(selector['default'], (selector['outbounds']! as List).first);
    });

    test('a selected chain with a missing hop', () {
      const chain = Chain(
        id: 'broken',
        name: '坏链',
        hops: [
          MemberRef.selfNode(id: 'gone'),
          MemberRef.selfNode(id: 'x'),
        ],
      );
      final membership = const Membership(
        ownerKind: MemberOwner.chain,
        ownerId: 'broken',
        configurationId: 'cfg',
        groupKey: LinkListGroups.selectKey,
      );
      // Not selected: left out, the plan compiles.
      expect(
        () => compile(base(chains: [chain], memberships: [membership])),
        returnsNormally,
      );
      expect(
        () => compile(
          base(
            chains: [chain],
            memberships: [membership],
            selections: {
              LinkListGroups.selectKey: const MemberRef.chain(id: 'broken'),
            },
          ),
        ),
        _fails(CompileErrorCode.memberUnavailable, '坏链'),
      );
    });

    test('a URL-test candidate that cannot be expressed', () {
      ConfigContent with_(List<RuleDef> rules) => links.copyWith(
        nodes: [
          ...links.nodes,
          const NodeDef(
            key: 'S',
            name: 'S',
            server: 's.example.com',
            port: 1080,
            params: NodeParams.socks5(tls: Tls()),
          ),
        ],
        groups: [
          links.groups[0],
          links.groups[1].copyWith(members: [...links.groups[1].members, 'S']),
        ],
        rules: rules,
        defaultRules: rules.isEmpty,
      );
      // The URL test is unusable as a whole; unselected, it is left out.
      expect(() => compile(base(content: with_(const []))), returnsNormally);
      expect(
        () => compile(
          base(
            content: with_(const []),
            selections: {
              LinkListGroups.selectKey: const MemberRef.source(
                configurationId: 'cfg',
                key: LinkListGroups.autoKey,
              ),
            },
          ),
        ),
        _fails(CompileErrorCode.memberUnavailable, LinkListGroups.auto),
      );
      expect(
        () => compile(
          base(
            content: with_(const [
              RuleDef(domain: ['x.com'], target: LinkListGroups.autoKey),
            ]),
          ),
        ),
        _fails(CompileErrorCode.memberUnavailable, 'S'),
      );
    });

    test('desktop per-app proxy needs find process', () {
      expect(
        () => compile(
          base(
            settings: const DeviceSettings(
              findProcess: false,
              perAppList: ['/Applications/Safari.app'],
            ),
          ),
        ),
        _fails(CompileErrorCode.perAppNeedsFindProcess),
      );
    });

    test('Clash rule providers must be converted first', () {
      final clash = _content(
        'clash_basic.yaml',
        providers: {
          'remote': File(
            'test/fixtures/provider_remote.yaml',
          ).readAsStringSync(),
        },
      );
      expect(
        () => compile(base(content: clash)),
        _fails(CompileErrorCode.ruleSetMissing, 'provider-ads'),
      );
    });

    test('override: malformed, unknown names, conflicts', () {
      Policy o(String json) => Policy(jsonOverride: Secret(json));
      expect(
        () => compile(base(policy: o('{"log": {}}'))),
        _fails(CompileErrorCode.overrideInvalid, r'$.log'),
      );
      expect(
        () => compile(
          base(policy: o('{"route": {"rules": [{"outbound": "Nope"}]}}')),
        ),
        _fails(CompileErrorCode.overrideReference, 'Nope'),
      );
      expect(
        () => compile(
          base(
            policy: o('{"outbounds": [{"type": "direct", "tag": "direct"}]}'),
          ),
        ),
        _fails(CompileErrorCode.overrideConflict, 'direct'),
      );
    });

    test('a direct DNS that is not an address', () {
      expect(
        () => compile(
          base(settings: const DeviceSettings(directDns: 'dns.example')),
        ),
        _fails(CompileErrorCode.invalidSetting, 'directDns'),
      );
    });

    test('nothing to run', () {
      expect(
        () => compile(
          CompileInput(
            source: const SelfSource(),
            settings: const DeviceSettings(),
            host: _mac,
            hashKey: _key,
            proxy: false,
          ),
        ),
        _fails(CompileErrorCode.nothingToRun),
      );
    });
  });

  group('REJECT as a group member', () {
    // The core has a `block` outbound, so a group keeps REJECT as a member
    // (core/bridge/core_facts_test.go).
    final content = parseContent('''
proxies:
  - {name: 香港, type: trojan, server: a.example.com, port: 443, password: fake-a}
proxy-groups:
  - {name: 广告拦截, type: select, proxies: [REJECT, DIRECT]}
  - {name: 节点选择, type: select, proxies: [香港, DIRECT]}
  - {name: 自动, type: url-test, proxies: [香港, REJECT], url: 'http://www.gstatic.com/generate_204', interval: 300}
rules:
  - DOMAIN-SUFFIX,ads.example.com,广告拦截
  - DOMAIN-SUFFIX,fast.example.com,自动
  - MATCH,节点选择
''').content;
    String keyOf(String name) =>
        content.groups.firstWhere((g) => g.name == name).key;
    CompileInput input({Map<String, MemberRef> selections = const {}}) =>
        CompileInput(
          source: ImportedSource(id: 'cfg', content: content),
          settings: const DeviceSettings(),
          host: _mac,
          hashKey: _key,
          selections: selections,
        );
    Map<String, Object?> outbound(CompiledPlan plan, String name) {
      final tag = plan.tags.entries.firstWhere((e) => e.value.name == name).key;
      return (plan.toJson()['outbounds']! as List)
          .cast<Map<String, Object?>>()
          .firstWhere((o) => o['tag'] == tag);
    }

    test('a selector keeps it, and starts on it when it is first', () {
      final plan = compile(input());
      final outbounds = (plan.toJson()['outbounds']! as List)
          .cast<Map<String, Object?>>();
      expect(outbounds.where((o) => o['type'] == 'block'), [
        {'type': 'block', 'tag': 'reject'},
      ]);
      final ads = outbound(plan, '广告拦截');
      expect(ads['outbounds'], ['reject', 'direct']);
      expect(ads['default'], 'reject');
      expect(
        plan.tags['reject']!.ref,
        const MemberRef.builtin(builtin: Builtin.reject),
      );
    });

    test('choosing it compiles, and so does choosing away from it', () {
      const reject = MemberRef.builtin(builtin: Builtin.reject);
      const direct = MemberRef.builtin(builtin: Builtin.direct);
      final ads = keyOf('广告拦截');
      expect(
        outbound(compile(input(selections: {ads: reject})), '广告拦截')['default'],
        'reject',
      );
      expect(
        outbound(compile(input(selections: {ads: direct})), '广告拦截')['default'],
        'direct',
      );
    });

    test('a group that picks by latency leaves it out', () {
      final auto = outbound(compile(input()), '自动');
      expect(auto['type'], 'urltest');
      expect(auto['outbounds'], hasLength(1));
      expect(auto['outbounds'], isNot(contains('reject')));
    });

    test('the catalog shows the same current member as the plan uses', () {
      final catalog = MemberCatalog(configurationId: 'cfg', content: content);
      expect(
        catalog.currentOf(keyOf('广告拦截'), const {}),
        const MemberRef.builtin(builtin: Builtin.reject),
      );
    });

    test('without such a group there is no block outbound', () {
      final plan = compile(
        CompileInput(
          source: ImportedSource(id: 'cfg', content: links),
          settings: const DeviceSettings(),
          host: _mac,
          hashKey: _key,
        ),
      );
      expect(
        (plan.toJson()['outbounds']! as List).where(
          (o) => (o as Map)['type'] == 'block',
        ),
        isEmpty,
      );
    });
  });
}
