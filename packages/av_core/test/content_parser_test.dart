// Content parsing (CONFIG_PIPELINE §3–4). Fixtures use fake credentials.
import 'dart:convert';
import 'dart:io';

import 'package:av_core/av_core.dart';
import 'package:test/test.dart';

String _fixture(String name) => File('test/fixtures/$name').readAsStringSync();

Matcher _warns(WarningKind kind, [String? subject]) => contains(
  isA<ImportWarning>()
      .having((w) => w.kind, 'kind', kind)
      .having((w) => w.subject, 'subject', subject ?? anything),
);

Matcher _rejects(ImportErrorCode code, [String? field]) => throwsA(
  isA<ImportException>()
      .having((e) => e.code, 'code', code)
      .having((e) => e.field, 'field', field ?? anything),
);

void main() {
  group('sing-box', () {
    late ParsedContent parsed;
    late ConfigContent c;
    setUpAll(() {
      parsed = parseContent(_fixture('singbox_basic.json'));
      c = parsed.content;
    });

    test('nodes of the nine protocols, keyed by tag', () {
      expect([for (final n in c.nodes) n.key], ['tag:hk', 'tag:jp', 'tag:ss']);
      expect(
        c.node('tag:hk')!.params,
        const NodeParams.vless(
          uuid: Secret('00000000-0000-4000-8000-000000000001'),
          flow: 'xtls-rprx-vision',
          tls: Tls(
            serverName: 'www.apple.com',
            fingerprint: 'chrome',
            reality: Reality(
              publicKey: 'fakeRealityPublicKey0000000000000000000000A',
              shortId: 'ab',
            ),
          ),
        ),
      );
      expect(
        c.node('tag:jp')!.params,
        const NodeParams.hysteria2(
          password: Secret('fake-hy2'),
          obfsPassword: Secret('fake-obfs'),
          upMbps: 50,
          downMbps: 200,
          tls: Tls(serverName: 'jp.example.com', insecure: true),
        ),
      );
    });

    test('groups keep source order and drop missing members', () {
      expect(c.group('tag:Proxy')!.members, [
        'tag:auto',
        'tag:hk',
        'tag:jp',
        ContentKeys.direct,
      ]);
      expect(
        c.group('tag:auto')!.test,
        const GroupTest(
          url: 'https://cp.cloudflare.com',
          intervalSeconds: 180,
          toleranceMs: 100,
        ),
      );
      expect(c.finalTarget, 'tag:Proxy');
      expect(c.primaryGroup?.key, 'tag:Proxy');
    });

    test('rules map one to one; own and unsupported rules are skipped', () {
      expect(c.rules, [
        const RuleDef(
          domainSuffix: ['google.com', 'youtube.com'],
          target: 'tag:Proxy',
        ),
        const RuleDef(ruleSet: ['geosite-cn'], target: ContentKeys.direct),
        const RuleDef(
          port: [22, 25],
          portRange: ['1000:2000'],
          network: ['tcp'],
          target: ContentKeys.reject,
        ),
        const RuleDef(domain: ['a.com'], target: ContentKeys.reject),
      ]);
      expect(c.ruleSets, [
        const RuleSetRef(
          tag: 'geosite-cn',
          url: 'https://example.com/geosite-cn.srs',
          format: RuleSetFormat.binary,
        ),
      ]);
    });

    test('warnings explain everything that was skipped', () {
      final w = c.warnings;
      expect(w, _warns(WarningKind.unsupportedNodeType, 'wireguard'));
      expect(w, _warns(WarningKind.unsupportedNodeType, 'endpoint'));
      expect(w, _warns(WarningKind.unsupportedNodeOption, 'transport.quic'));
      expect(w, _warns(WarningKind.ignoredNodeOption, 'multiplex'));
      expect(w, _warns(WarningKind.droppedMember, 'gone'));
      expect(w, _warns(WarningKind.unsupportedRule, 'logical'));
      expect(w, _warns(WarningKind.unsupportedRule, 'ip_is_private'));
      expect(w, _warns(WarningKind.unsupportedRuleSet, 'local-set'));
      for (final s in ['log', 'dns', 'inbounds', 'experimental']) {
        expect(w, _warns(WarningKind.ignoredSection, s));
      }
      expect(w, contains(const ImportWarning(kind: WarningKind.insecureTls)));
    });
  });

  group('Clash', () {
    late ConfigContent c;
    setUpAll(() {
      final text = _fixture('clash_basic.yaml');
      expect(providersOf(text), {
        'remote': 'https://provider.example.com/list',
      });
      final parsed = parseContent(
        text,
        providers: {'remote': _fixture('provider_remote.yaml')},
      );
      expect(parsed.format, ContentFormat.clash);
      c = parsed.content;
    });

    test('proxies map to the nine protocols', () {
      expect(
        c.node('proxy:SS 01')!.params,
        const NodeParams.shadowsocks(
          method: 'aes-256-gcm',
          password: Secret('fake-ss'),
          plugin: 'obfs-local',
          pluginOpts: 'obfs=http;obfs-host=bing.com',
        ),
      );
      expect(
        c.node('proxy:VMess WS')!.params,
        const NodeParams.vmess(
          uuid: Secret('00000000-0000-4000-8000-000000000001'),
          transport: Transport.ws(path: '/ray', host: 'v.example.com'),
          tls: Tls(serverName: 'v.example.com'),
        ),
      );
      expect(
        (c.node('proxy:Reality')!.params as VlessParams).tls,
        const Tls(
          serverName: 'www.apple.com',
          fingerprint: 'chrome',
          reality: Reality(
            publicKey: 'fakeRealityPublicKey0000000000000000000000A',
            shortId: 'ab',
          ),
        ),
      );
      final hy2 = c.node('proxy:HY2')!.params as Hysteria2Params;
      expect((hy2.upMbps, hy2.downMbps), (50, 1000));
      expect(hy2.serverPorts, ['20000:30000']);
      expect(c.node('proxy:Chained')!.detourKey, 'proxy:Trojan');
    });

    test('providers: filter, prefix and inline payloads', () {
      expect(c.node('provider:remote/香港 01')!.name, '[P] 香港 01');
      expect(c.node('provider:remote/日本 01'), isNull);
      expect(c.node('provider:local/Inline HTTP'), isNotNull);
    });

    test('groups: members, use, include-all and approximations', () {
      expect(c.group('group:节点选择')!.members, [
        'group:自动选择',
        'proxy:SS 01',
        'proxy:Reality',
        ContentKeys.direct,
      ]);
      expect(c.group('group:自动选择')!.members, ['provider:remote/香港 01']);
      final fallback = c.group('group:故障转移')!;
      expect(
        (fallback.type, fallback.displayType),
        (GroupType.urltest, 'Fallback'),
      );
      expect(c.group('group:链式'), isNull);
      expect(c.group('group:全部')!.members, [
        'proxy:SS 01',
        'proxy:VMess WS',
        'proxy:Reality',
        'proxy:Trojan',
        'proxy:HY2',
        'proxy:TUIC',
      ]);
    });

    test('rules, rule sets and final target', () {
      expect(c.rules, [
        const RuleDef(domainSuffix: ['google.com'], target: 'group:节点选择'),
        const RuleDef(ruleSet: ['geosite-cn'], target: ContentKeys.direct),
        const RuleDef(ruleSet: ['geoip-cn'], target: ContentKeys.direct),
        isA<RuleDef>().having(
          (r) => r.ipCidr,
          'ipCidr',
          contains('10.0.0.0/8'),
        ),
        const RuleDef(ipCidr: ['8.8.8.8/32'], target: 'group:节点选择'),
        const RuleDef(portRange: ['8000:9000'], target: ContentKeys.reject),
        const RuleDef(ruleSet: ['provider-ads'], target: ContentKeys.reject),
        const RuleDef(processName: ['curl'], target: ContentKeys.direct),
      ]);
      expect(
        [for (final s in c.ruleSets) (s.tag, s.format)],
        [
          ('provider-ads', RuleSetFormat.clashDomainText),
          ('geosite-cn', RuleSetFormat.binary),
          ('geoip-cn', RuleSetFormat.binary),
        ],
      );
      expect(c.finalTarget, 'group:节点选择');
    });

    test('warnings', () {
      final w = c.warnings;
      expect(w, _warns(WarningKind.unsupportedNodeType, 'ssr'));
      expect(w, _warns(WarningKind.unsupportedNodeOption, 'plugin.shadow-tls'));
      expect(w, _warns(WarningKind.droppedMember, 'Missing'));
      expect(w, _warns(WarningKind.approximatedGroupType, 'Fallback'));
      expect(w, _warns(WarningKind.unsupportedGroupType, 'relay'));
      expect(w, _warns(WarningKind.unsupportedRuleSet, 'binary'));
      expect(w, _warns(WarningKind.unsupportedRule, 'AND'));
      expect(w, _warns(WarningKind.droppedMember, '链式'));
      for (final s in ['ports', 'mode', 'dns', 'tun']) {
        expect(w, _warns(WarningKind.ignoredSection, s));
      }
    });

    test('a provider that was not downloaded is a caller error', () {
      expect(
        () => parseContent(_fixture('clash_basic.yaml')),
        throwsStateError,
      );
    });
  });

  group('link lists', () {
    const links =
        'vless://00000000-0000-4000-8000-000000000001@a.example.com:443#A\n'
        'trojan://fake@b.example.com:443#A\n'
        'ssr://abcdef\n'
        'vless://00000000-0000-4000-8000-000000000001@c.example.com:443?x=1\n'
        'trojan://fake@d.example.com:443\n';

    void check(ParsedContent p) {
      final c = p.content;
      expect(p.format, ContentFormat.linkList);
      expect(
        [for (final n in c.nodes) n.name],
        ['A', 'A (2)', 'd.example.com'],
      );
      expect(c.group(LinkListGroups.selectKey)!.members, [
        LinkListGroups.autoKey,
        'A',
        'A (2)',
        'd.example.com',
      ]);
      expect(c.group(LinkListGroups.autoKey)!.type, GroupType.urltest);
      expect(c.finalTarget, LinkListGroups.selectKey);
      expect(c.rules, isEmpty);
      expect(c.warnings, _warns(WarningKind.unsupportedNodeType, 'ssr'));
      expect(c.warnings, _warns(WarningKind.unreadableEntry, 'x'));
    }

    test('plain', () => check(parseContent(links)));
    test(
      'Base64, wrapped at 76 columns',
      () => check(
        parseContent(
          base64
              .encode(utf8.encode(links))
              .replaceAllMapped(RegExp('.{76}'), (m) => '${m[0]}\n'),
        ),
      ),
    );
  });

  group('limits and rejection', () {
    test('unknown formats are rejected', () {
      expect(
        () => parseContent('hello world'),
        _rejects(ImportErrorCode.unknownFormat),
      );
      expect(
        () => parseContent('{"a": 1}'),
        _rejects(ImportErrorCode.unknownFormat),
      );
    });

    test('JSON deeper than 64 levels', () {
      final deep = '${'{"a":' * 70}1${'}' * 70}';
      expect(
        () => parseContent('{"outbounds": [], "x": $deep}'),
        _rejects(ImportErrorCode.tooLarge, 'depth'),
      );
    });

    test('YAML alias bombs stop at the node limit', () {
      final b = StringBuffer('a: &a [x, x, x, x, x, x, x, x, x, x]\n');
      for (var i = 1; i < 8; i++) {
        b.writeln(
          '${String.fromCharCode(97 + i)}: &${String.fromCharCode(97 + i)} '
          '[${List.filled(10, '*${String.fromCharCode(96 + i)}').join(', ')}]',
        );
      }
      b.writeln('proxies: []');
      expect(
        () => parseContent(b.toString()),
        _rejects(ImportErrorCode.tooLarge, 'yaml nodes'),
      );
    });

    test('YAML tags are refused', () {
      expect(
        () => parseContent('proxies: !!python/object:os.system []\n'),
        _rejects(ImportErrorCode.malformed, 'yaml tag'),
      );
    });

    test('more than 5000 nodes', () {
      final lines = [
        for (var i = 0; i < 5001; i++) 'trojan://fake@h$i.example.com:443',
      ].join('\n');
      expect(
        () => parseContent(lines),
        _rejects(ImportErrorCode.tooLarge, 'nodes'),
      );
    });
  });
}
