// The exit IP on the dashboard (CONFIG_PIPELINE §9): the device's own when
// nothing runs, through the main selector while a session does, measured
// again when the session or its exit changes.
import 'dart:convert';
import 'dart:io';

import 'package:av_core/av_core.dart';
import 'package:avalon/runtime/exit_ip_probe.dart';
import 'package:avalon/runtime/runtime_coordinator.dart';
import 'package:avalon/runtime/runtime_host.dart';
import 'package:avalon/services/exit_ip.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/harness.dart';
import 'fake_host.dart';

const _clash = '''
proxies:
  - {name: 香港 01, type: trojan, server: a.example.com, port: 443, password: fake-a}
  - {name: 日本 01, type: trojan, server: b.example.com, port: 443, password: fake-b}
proxy-groups:
  - {name: 节点选择, type: select, proxies: [香港 01, 日本 01]}
rules:
  - MATCH,节点选择
''';

const _home = '{"ip":"192.0.2.10","country":"CN"}';
const _proxied = '{"ip":"203.0.113.9","country":"HK","city":"Hong Kong"}';

void main() {
  late Harness h;
  late FakeHost host;
  late Directory dir;

  Future<void> start() async {
    dir = Directory.systemTemp.createTempSync('exit-ip');
    host = FakeHost(dir.path);
    h = await Harness.start(
      host: RuntimeHost(transport: host, system: host),
      exitIpPath: '/ip',
      overrides: [
        runtimePollIntervalProvider.overrideWithValue(const Duration(days: 1)),
        runtimeDebounceProvider.overrideWithValue(
          const Duration(milliseconds: 30),
        ),
      ],
    );
    h
      ..body = _clash
      ..bodies['/ip'] = _home;
    final added = await h.services.imports.addSubscription(
      url: '${h.base}/sub',
      defaultName: '订阅',
    );
    await h.services.settings.updateDevice(
      (s) => s.copyWith(selectedConfigurationId: added.configurationId),
    );
    await h.container.read(runtimeProvider.notifier).ready;
  }

  tearDown(() async {
    await h.stop();
    dir.deleteSync(recursive: true);
  });

  ExitIp? exitIp() => h.container.read(exitIpProvider);
  Future<ExitIp?> measured(bool Function(ExitIp? ip) ready) async {
    h.container.listen(exitIpProvider, (_, _) {});
    return h.settle(exitIp, ready);
  }

  String url() => '${h.base}/ip';

  /// Exit IP requests through the session (rule sets go through it too).
  List<Map<String, Object?>> exitFetches() => [
    for (final c in host.commands)
      if (c.$1 == 'fetch' && c.$2['url'] == url()) c.$2,
  ];

  test('nothing runs: the device\'s own exit, directly', () async {
    await start();
    final ip = await measured((ip) => ip != null);
    expect(ip!.ip, '192.0.2.10');
    expect(ip.location, '🇨🇳 CN');
    expect(host.sent, isNot(contains('fetch')));
  });

  test(
    'while running: through the main selector, again for a new exit',
    () async {
      await start();
      await measured((ip) => ip != null);
      host.fetchBodies = {url(): utf8.encode(_proxied)};
      final coordinator = h.container.read(runtimeProvider.notifier);
      await coordinator.connect();
      final ip = await measured((ip) => ip?.ip == '203.0.113.9');
      expect(ip!.location, '🇭🇰 Hong Kong, HK');
      final fetch = exitFetches().last;
      expect(fetch['outboundTag'], coordinator.primaryTag);
      expect(fetch.containsKey('destPath'), isFalse);

      // The user picks another member: the old result goes, a new one is
      // measured through it.
      await coordinator.idle();
      await h.container.read(exitIpProvider.notifier).idle();
      final fetches = exitFetches().length;
      final id = (await h.services.settings.device()).selectedConfigurationId!;
      final content = (await h.services.configurations.content(id))!.content;
      await h.services.selections.select(
        id,
        content.groups.single.key,
        MemberRef.source(configurationId: id, key: content.nodes.last.key),
      );
      await h.settle(() => exitFetches().length, (n) => n > fetches);
      final plan = await h.services.plans.compileSelected();
      final japan = plan.tags.entries
          .firstWhere((e) => e.value.name == '日本 01')
          .key;
      expect(host.selections[coordinator.primaryTag], japan);
      await measured((ip) => ip != null);

      // Stopped: the device's own again.
      await coordinator.disconnect();
      final home = await measured((ip) => ip?.ip == '192.0.2.10');
      expect(home, isNotNull);
    },
  );

  test('a failure shows nothing', () async {
    await start();
    h.bodies['/ip'] = 'not an answer';
    host.fetchBodies = {};
    await h.container.read(runtimeProvider.notifier).connect();
    h.container.listen(exitIpProvider, (_, _) {});
    await h.container.read(exitIpProvider.notifier).idle();
    expect(exitIp(), isNull);
  });
}
