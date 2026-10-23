// Rule sets kept up to date with the runtime (CONFIG_PIPELINE §8, D86):
// downloads through the session, reloads for new content, scheduled
// updates, and Clash providers fetched before a start.
import 'dart:convert';
import 'dart:io';

import 'package:av_core/av_core.dart';
import 'package:avalon/app/providers.dart';
import 'package:avalon/app/rule_set_updates.dart';
import 'package:avalon/data/database/database.dart';
import 'package:avalon/runtime/runtime_coordinator.dart';
import 'package:avalon/runtime/runtime_host.dart';
import 'package:avalon/services/download/fetcher.dart';
import 'package:avalon/services/resource_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../features/harness.dart';
import 'fake_host.dart';

const _links = 'trojan://fake-a@a.example.com:443#A\n';

List<int> _srs(String body) => [0x53, 0x52, 0x53, 0x01, ...utf8.encode(body)];

Map<String, Object?> _plan(Directory dir) =>
    (jsonDecode(File('${dir.path}/plan.json').readAsStringSync()) as Map)
        .cast<String, Object?>();

List<Map<String, Object?>> _ruleSets(Map<String, Object?> plan) =>
    ((plan['route']! as Map)['rule_set']! as List).cast<Map<String, Object?>>();

void main() {
  late Harness h;
  late FakeHost host;
  late Directory dir;
  final cn = RuleSetCatalog.geosite('cn');
  final defaults = {
    for (final rule in RuleSetCatalog.defaults) rule.url: _srs(rule.tag),
  };

  Future<void> start({bool localFetcher = false}) async {
    dir = Directory.systemTemp.createTempSync('rulesets');
    host = FakeHost(dir.path);
    h = await Harness.start(
      host: RuntimeHost(transport: host, system: host),
      stateDir: dir.path,
      overrides: [
        runtimePollIntervalProvider.overrideWithValue(const Duration(days: 1)),
        runtimeDebounceProvider.overrideWithValue(
          const Duration(milliseconds: 30),
        ),
        ruleSetCheckIntervalProvider.overrideWithValue(const Duration(days: 1)),
        if (localFetcher)
          // Providers on this machine's test server.
          resourceServiceProvider.overrideWith(
            (ref) => ResourceService(
              ref.watch(servicesProvider).ruleResources,
              Fetcher(userAgent: 'test'),
              stateDir: () async => dir.path,
              allowPrivateAddresses: true,
            ),
          ),
      ],
    );
    h.body = _links;
    final added = await h.services.imports.addSubscription(
      url: '${h.base}/sub',
      defaultName: '订阅',
    );
    await h.services.settings.updateDevice(
      (s) => s.copyWith(selectedConfigurationId: added.configurationId),
    );
    await h.container.read(runtimeProvider.notifier).ready;
  }

  /// Waits for what the runtime and the updater do in the background; each
  /// can start work for the other.
  Future<void> settled() async {
    for (var i = 0; i < 3; i++) {
      await h.container.read(runtimeProvider.notifier).idle();
      await h.container.read(ruleSetUpdaterProvider.notifier).idle();
    }
  }

  tearDown(() async {
    await settled();
    await h.stop();
    dir.deleteSync(recursive: true);
  });

  RuleSetUpdater updater() => h.container.read(ruleSetUpdaterProvider.notifier);
  int fetches() => host.sent.where((c) => c == 'fetch').length;

  Set<Object?> fetched() => {
    for (final c in host.commands)
      if (c.$1 == 'fetch') c.$2['url'],
  };

  test(
    'a start keeps, through the session, what the core downloaded',
    () async {
      await start();
      host.fetchBodies = defaults;
      await h.container.read(runtimeProvider.notifier).connect();
      await settled();
      final plan = await h.services.plans.compileSelected();
      final fetch = host.commands.firstWhere((c) => c.$1 == 'fetch').$2;
      expect(fetch['outboundTag'], plan.primaryTag);
      expect(
        File(fetch['destPath']! as String).parent.path,
        '${dir.path}/rulesets',
      );

      // Plans then read the files instead of downloading.
      final cached = await h.services.resources.cachedPaths();
      final local = _ruleSets(
        (await h.services.plans.compileSelected()).toJson(),
      ).firstWhere((r) => r['tag'] == 'geosite-cn');
      expect((local['type'], local['path']), ('local', cached[ruleSetKey(cn)]));
    },
  );

  test('a manual update needs the session when «经代理»', () async {
    await start();
    expect(await updater().update([cn]), RulesUpdateRefusal.needsProxy);
    host.fetchBodies = defaults;
    await h.container.read(runtimeProvider.notifier).connect();
    expect(await updater().update([cn]), isNull);
    // The start may have been keeping it already.
    await settled();
    expect(
      (await h.services.resources.cachedPaths())[ruleSetKey(cn)],
      startsWith('${dir.path}/rulesets/'),
    );
  });

  test('new content for a file the session reads reloads it', () async {
    await start();
    host.fetchBodies = {...defaults, cn.url: _srs('first')};
    await h.container.read(runtimeProvider.notifier).connect();
    await updater().update([cn]);
    await settled();
    final reloads = host.sent.where((c) => c == 'reload').length;

    host.fetchBodies = {...defaults, cn.url: _srs('second')};
    await updater().update([cn]);
    await h.settle(
      () => host.sent.where((c) => c == 'reload').length,
      (n) => n > reloads,
    );
    final paths = [
      for (final r in _ruleSets(_plan(dir)))
        if (r['tag'] == 'geosite-cn') r['path'],
    ];
    expect(
      paths.single,
      (await h.services.resources.cachedPaths())[ruleSetKey(cn)],
    );
  });

  test('scheduled updates: due ones only, «经代理» waits for a session', () async {
    await start();
    // Nothing runs: nothing is downloaded.
    await updater().updateDue();
    expect(fetches(), 0);

    // What the start keeps fails to download: a failure waits an hour.
    await h.container.read(runtimeProvider.notifier).connect();
    await settled();
    expect(fetches(), greaterThan(0));
    host.commands.clear();
    await updater().updateDue();
    expect(fetches(), 0);

    // An hour later: the catalog and what the configurations use.
    host.fetchBodies = defaults;
    final now = DateTime.now();
    await updater().updateDue(now: now.add(const Duration(minutes: 61)));
    final catalog = RuleSetCatalog.defaults.map((r) => r.url);
    expect(fetched(), containsAll(catalog));

    // Just updated: not due again until a day has passed.
    host.commands.clear();
    await updater().updateDue(now: now.add(const Duration(hours: 2)));
    expect(fetches(), 0);
    await updater().updateDue(now: now.add(const Duration(days: 1, hours: 1)));
    expect(fetched(), containsAll(catalog));

    // Turned off: never.
    host.commands.clear();
    await h.services.settings.updatePolicy(
      (p) => p.copyWith(geoAutoUpdate: false),
    );
    await updater().updateDue(now: now.add(const Duration(days: 30)));
    expect(fetches(), 0);
  });

  test('a Clash provider missing at start is fetched directly first', () async {
    await start(localFetcher: true);
    final provider = '${h.base}/ads.txt';
    h.body =
        '''
proxies:
  - {name: 香港, type: trojan, server: a.example.com, port: 443, password: fake-a}
proxy-groups:
  - {name: 节点选择, type: select, proxies: [香港, DIRECT]}
rule-providers:
  ads: {type: http, behavior: domain, format: text, url: '$provider'}
rules:
  - RULE-SET,ads,REJECT
  - MATCH,节点选择
''';
    final added = await h.services.imports.addSubscription(
      url: '${h.base}/clash',
      defaultName: 'Clash',
    );
    await h.services.settings.updateDevice(
      (s) => s.copyWith(selectedConfigurationId: added.configurationId),
    );
    await expectLater(
      h.services.plans.compileSelected(),
      throwsA(
        isA<CompileException>().having(
          (e) => e.code,
          'code',
          CompileErrorCode.ruleSetMissing,
        ),
      ),
    );
    // The test server answers every path with its body: the provider is
    // now this domain list.
    h.body = '+.ads.example\n';
    await h.container.read(runtimeProvider.notifier).connect();
    expect(host.state, 'running');
    final ads = _ruleSets(
      _plan(dir),
    ).firstWhere((r) => (r['tag']! as String).startsWith('provider-'));
    expect((ads['type'], ads['format']), ('local', 'source'));
    expect(
      File(ads['path']! as String).readAsStringSync(),
      contains('ads.example'),
    );
  });

  test(
    'Cloud rules cannot bypass the updater or runtime first-download guard',
    () async {
      await start(localFetcher: true);
      final url = '${h.base}/cloud-ads.txt';
      h.body =
          '''
proxies:
  - {name: A, type: trojan, server: a.example.com, port: 443, password: fake}
rule-providers:
  ads: {type: http, behavior: domain, format: text, url: '$url'}
rules:
  - RULE-SET,ads,REJECT
  - MATCH,A
''';
      final id = (await h.services.imports.addSubscription(
        url: '${h.base}/cloud',
        defaultName: 'Cloud',
      )).configurationId;
      final db = h.services.db;
      await db
          .into(db.syncDocuments)
          .insert(
            SyncDocumentsCompanion.insert(
              documentId: 'cloud-rules',
              recordId: 'cloud-rules',
              type: 'configuration',
              localId: Value(id),
              localEditedAt: 1,
              localDeleted: false,
            ),
          );
      await db
          .into(db.sourceProvenance)
          .insert(
            SourceProvenanceCompanion.insert(
              documentId: 'cloud-rules',
              origin: 'cloud',
              sourceGeneration: 'cloud',
            ),
          );
      await h.services.settings.updateDevice(
        (s) => s.copyWith(selectedConfigurationId: id),
      );
      await h.services.settings.updatePolicy(
        (p) => p.copyWith(geoVia: DownloadVia.direct, geoAutoUpdate: false),
      );
      final content = (await h.services.configurations.content(id))!.content;
      final rule = RuleSetCatalog.usedBy(
        content,
      ).singleWhere((r) => r.url == url);
      h.body = '+.ads.example\n';
      await updater().update([rule]);
      expect(
        (await h.services.ruleResources.all())[ruleSetKey(rule)]!.lastError,
        'fetch.blockedAddress',
      );
      await h.container.read(runtimeProvider.notifier).connect();
      await settled();
      expect(h.paths, isNot(contains('/cloud-ads.txt')));
      expect(host.sent, isNot(contains('start')));
      expect(
        (await h.services.ruleResources.all())[ruleSetKey(rule)]!.file,
        isNull,
      );
    },
  );
}
