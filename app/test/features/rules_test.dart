// GEO rule-set availability and persisted update settings (PRODUCT_SPEC §3.12).
import 'package:av_core/av_core.dart';
import 'package:avalon/app/rule_set_updates.dart';
import 'package:avalon/features/rules/rules_state.dart';
import 'package:avalon/features/rules/rules_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

const _clash = '''
proxies:
  - {name: 香港 01, type: trojan, server: a.example.com, port: 443, password: fake-a}
proxy-groups:
  - {name: 节点选择, type: select, proxies: [香港 01]}
rule-providers:
  ads:
    type: http
    behavior: domain
    format: text
    url: https://rules.example.com/ads.txt
rules:
  - GEOSITE,openai,节点选择
  - GEOSITE,CN,DIRECT
  - GEOIP,telegram,节点选择
  - RULE-SET,ads,REJECT
  - MATCH,节点选择
''';

List<String> _tags(RulesState s) => [for (final i in s.items) i.tag];

void main() {
  test('each source is listed once, the defaults first', () {
    const mirror = RuleSetRef(
      tag: 'geosite-cn',
      url: 'https://mirror.example.com/geosite-cn.srs',
      format: RuleSetFormat.binary,
    );
    final refs = collectRuleSets([
      (
        content: const ConfigContent(
          finalTarget: ContentKeys.direct,
          rules: [
            RuleDef(
              ruleSet: ['geosite-cn', 'geosite-openai'],
              target: ContentKeys.direct,
            ),
          ],
        ),
        self: false,
      ),
      // The same name from another address is another rule set.
      (
        content: const ConfigContent(
          finalTarget: ContentKeys.direct,
          ruleSets: [mirror],
          rules: [
            RuleDef(
              ruleSet: ['geosite-cn', 'geosite-openai'],
              target: ContentKeys.direct,
            ),
          ],
        ),
        self: false,
      ),
      (
        content: const ConfigContent(finalTarget: ContentKeys.custom),
        self: true,
      ),
    ]);
    expect(
      [for (final r in refs) r.tag],
      [
        'geosite-cn',
        'geosite-geolocation-!cn',
        'geoip-cn',
        'geosite-openai',
        'geosite-cn',
      ],
    );
    expect(refs.last, mirror);
  });

  group('view model', () {
    late Harness h;
    setUp(() async => h = await Harness.start());
    tearDown(() => h.stop());

    Future<RulesState> ready() {
      h.container.listen(rulesStateProvider, (_, _) {});
      return h.settle(
        () => h.container.read(rulesStateProvider),
        (s) => !s.loading,
      );
    }

    RulesViewModel model() => h.container.read(rulesViewModelProvider);

    test('with nothing imported the default catalog is listed', () async {
      final s = await ready();
      expect(_tags(s), ['geosite-cn', 'geosite-geolocation-!cn', 'geoip-cn']);
      expect(s.items.map((i) => i.kind), [
        RuleSetKind.geosite,
        RuleSetKind.geosite,
        RuleSetKind.geoip,
      ]);
      expect(s.items.every((i) => !i.downloaded && !i.busy), isTrue);
      expect(
        (s.autoUpdate, s.interval, s.via),
        (true, GeoInterval.daily, DownloadVia.proxy),
      );
    });

    test(
      'rule sets a configuration uses are added, and leave with it',
      () async {
        await ready();
        h.body = _clash;
        final added = await h.services.imports.addSubscription(
          url: '${h.base}/sub',
          defaultName: '新订阅',
        );
        final s = await h.settle(
          () => h.container.read(rulesStateProvider),
          (s) => s.items.length > 3,
        );
        expect(_tags(s), [
          'geosite-cn',
          'geosite-geolocation-!cn',
          'geoip-cn',
          'geosite-openai',
          'geoip-telegram',
          'provider-ads',
        ]);
        expect(s.items.last.kind, RuleSetKind.ruleset);
        expect(s.items.last.url, 'https://rules.example.com/ads.txt');

        await h.services.configurations.delete(added.configurationId);
        final after = await h.settle(
          () => h.container.read(rulesStateProvider),
          (s) => s.items.length == 3,
        );
        expect(_tags(after).last, 'geoip-cn');
      },
    );

    test('rule sets sharing a name show where each comes from', () async {
      await ready();
      h.body = '''
{"outbounds": [{"type": "trojan", "tag": "a", "server": "a.example.com",
  "server_port": 443, "password": "fake"}],
 "route": {"rule_set": [{"type": "remote", "tag": "geosite-cn",
   "format": "binary", "url": "https://mirror.example.com/geosite-cn.srs"}],
  "rules": [{"rule_set": "geosite-cn", "outbound": "direct"}],
  "final": "a"}}
''';
      await h.services.imports.addSubscription(
        url: '${h.base}/sub',
        defaultName: '新订阅',
      );
      final s = await h.settle(
        () => h.container.read(rulesStateProvider),
        (s) => s.items.length > 3,
      );
      expect(
        [for (final i in s.items) (i.tag, i.host)],
        [
          ('geosite-cn', 'raw.githubusercontent.com'),
          ('geosite-geolocation-!cn', null),
          ('geoip-cn', null),
          ('geosite-cn', 'mirror.example.com'),
        ],
      );
    });

    test('update settings are saved at once, as synced policy', () async {
      await ready();
      await model().setAutoUpdate(false);
      await model().setInterval(GeoInterval.weekly);
      await model().setVia(DownloadVia.direct);
      final policy = await h.services.settings.policy();
      expect(
        (policy.geoAutoUpdate, policy.geoInterval, policy.geoVia),
        (false, GeoInterval.weekly, DownloadVia.direct),
      );
      final s = await h.settle(
        () => h.container.read(rulesStateProvider),
        (s) => s.via == DownloadVia.direct,
      );
      expect((s.autoUpdate, s.interval), (false, GeoInterval.weekly));
    });

    test('a manual update through the proxy asks for the proxy', () async {
      final s = await ready();
      final refs = [for (final i in s.items) i.ref];
      expect(await model().update(refs), RulesUpdateRefusal.needsProxy);
    });
  });
}
