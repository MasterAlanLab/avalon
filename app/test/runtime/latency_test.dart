// Latency tests and what the host actually uses, as pages see them
// (PRODUCT_SPEC §3.2, CONFIG_PIPELINE §9).
import 'dart:async';
import 'dart:io';

import 'package:av_core/av_core.dart';
import 'package:avalon/features/dashboard/dashboard_view_model.dart';
import 'package:avalon/features/proxies/proxies_view_model.dart';
import 'package:avalon/runtime/actual_selections.dart';
import 'package:avalon/runtime/latency.dart';
import 'package:avalon/runtime/runtime_coordinator.dart';
import 'package:avalon/runtime/runtime_host.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/harness.dart';
import 'fake_host.dart';

const _clash = '''
proxies:
  - {name: 香港, type: trojan, server: a.example.com, port: 443, password: fake-a}
  - {name: 日本, type: trojan, server: b.example.com, port: 443, password: fake-b}
proxy-groups:
  - {name: 节点选择, type: select, proxies: [自动, 香港, 日本, DIRECT, REJECT]}
  - {name: 自动, type: url-test, proxies: [香港, 日本], url: 'http://www.gstatic.com/generate_204', interval: 300}
rules:
  - MATCH,节点选择
''';

void main() {
  late Harness h;
  late FakeHost host;
  late Directory dir;
  late String id;
  late ConfigContent content;

  Future<void> start({bool withHost = true}) async {
    dir = Directory.systemTemp.createTempSync('latency');
    host = FakeHost(dir.path);
    h = await Harness.start(
      host: withHost ? RuntimeHost(transport: host, system: host) : null,
      overrides: [
        runtimePollIntervalProvider.overrideWithValue(const Duration(days: 1)),
        runtimeDebounceProvider.overrideWithValue(
          const Duration(milliseconds: 30),
        ),
      ],
    );
    h.body = _clash;
    final added = await h.services.imports.addSubscription(
      url: '${h.base}/sub',
      defaultName: '新订阅',
    );
    id = added.configurationId;
    await h.services.settings.updateDevice(
      (s) => s.copyWith(selectedConfigurationId: id),
    );
    content = (await h.services.configurations.content(id))!.content;
    await h.container.read(runtimeProvider.notifier).ready;
    // Pages keep these alive.
    h.container.listen(proxiesStateProvider, (_, _) {});
    h.container.listen(dashboardStateProvider, (_, _) {});
    h.container.listen(latencyProvider, (_, _) {});
  }

  tearDown(() async {
    await h.stop();
    dir.deleteSync(recursive: true);
  });

  MemberRef node(String name) => MemberRef.source(
    configurationId: id,
    key: content.nodes.firstWhere((n) => n.name == name).key,
  );
  MemberRef group(String name) => MemberRef.source(
    configurationId: id,
    key: content.groups.firstWhere((g) => g.name == name).key,
  );
  Future<String> tag(MemberRef member) async =>
      (await h.services.plans.compileSelected()).tagOf(member)!;
  LatencyController latency() => h.container.read(latencyProvider.notifier);
  Map<LatencyKey, Latency> results() => h.container.read(latencyProvider);

  test(
    'with nothing running the plan is probed, and nothing is left',
    () async {
      await start();
      host.latencies = {
        await tag(node('香港')): {'delayMs': 82},
        await tag(node('日本')): {'error': 'connection refused'},
      };
      const direct = MemberRef.builtin(builtin: Builtin.direct);
      const reject = MemberRef.builtin(builtin: Builtin.reject);
      final refusal = await latency().test([
        node('香港'),
        node('日本'),
        direct,
        reject,
      ]);
      expect(refusal, isNull);

      final request = host.commands.lastWhere((c) => c.$1 == 'urlTest').$2;
      expect(request['sessionId'], isNull);
      expect(request['planPath'], '${dir.path}/probe.json');
      expect(request['url'], 'https://www.gstatic.com/generate_204');
      expect(request['timeoutMs'], 5000);
      // REJECT is not tested: it answers nothing by design.
      expect(request['tags'], hasLength(3));
      expect(File('${dir.path}/probe.json').existsSync(), isFalse);
      expect(host.state, 'stopped');

      final hongKong = results()[(id, node('香港'))]!;
      expect((hongKong.status, hongKong.ms), (LatencyStatus.measured, 82));
      expect(results()[(id, node('日本'))]!.status, LatencyStatus.failed);
      // DIRECT was asked and did not answer in time.
      expect(results()[(id, direct)]!.status, LatencyStatus.timedOut);
      expect(results()[(id, reject)], isNull);
    },
  );

  test('while connected the session is tested, and results turn stale '
      'when it ends', () async {
    await start();
    final coordinator = h.container.read(runtimeProvider.notifier);
    await coordinator.connect();
    host.latencies = {
      await tag(node('香港')): {'delayMs': 210},
    };
    await latency().test([node('香港')]);
    final request = host.commands.lastWhere((c) => c.$1 == 'urlTest').$2;
    expect(request['sessionId'], coordinator.sessionId);
    expect(request['planPath'], isNull);
    expect(results()[(id, node('香港'))]!.stale, isFalse);

    await coordinator.disconnect();
    final after = results()[(id, node('香港'))]!;
    expect((after.ms, after.stale), (210, true));
  });

  test('a new test address turns results stale', () async {
    await start();
    host.latencies = {
      await tag(node('香港')): {'delayMs': 82},
    };
    await latency().test([node('香港')]);
    expect(results()[(id, node('香港'))]!.stale, isFalse);
    await h.services.settings.updateDevice(
      (s) => s.copyWith(testUrl: 'https://cp.cloudflare.com/'),
    );
    final after = await h.settle(
      () => results()[(id, node('香港'))]!,
      (r) => r.stale,
    );
    expect(after.ms, 82);
  });

  test('an older test arriving late does not overwrite a newer one', () async {
    await start();
    final hongKong = await tag(node('香港'));
    host
      ..latencies = {
        hongKong: {'delayMs': 500},
      }
      ..holdTests = Completer<void>();
    final slow = latency().test([node('香港')]);
    await h.settle(
      () => results()[(id, node('香港'))],
      (r) => r?.status == LatencyStatus.testing,
    );
    final gate = host.holdTests!;
    host
      ..holdTests = null
      ..latencies = {
        hongKong: {'delayMs': 90},
      };
    await latency().test([node('香港')]);
    expect(results()[(id, node('香港'))]!.ms, 90);
    host.latencies = {
      hongKong: {'delayMs': 500},
    };
    gate.complete();
    await slow;
    expect(results()[(id, node('香港'))]!.ms, 90);
  });

  test('where there is no host a test says so', () async {
    await start(withHost: false);
    expect(await latency().test([node('香港')]), LatencyRefusal.noHost);
    expect(results(), isEmpty);
  });

  test('the proxies page shows latencies and what the host uses', () async {
    await start();
    host.latencies = {
      await tag(node('香港')): {'delayMs': 82},
    };
    await h.container.read(proxiesViewModelProvider.notifier).test([
      node('香港'),
      node('日本'),
    ]);
    var page = h.container.read(proxiesStateProvider);
    var select = page.groups.firstWhere((g) => g.name == '节点选择');
    expect(select.members[1].latency!.ms, 82);
    expect(select.members[2].latency!.status, LatencyStatus.timedOut);
    // Not connected: the automatic group's pick is unknown.
    final auto = page.groups.firstWhere((g) => g.name == '自动');
    expect(auto.current, isNull);
    expect(select.current, 0);

    // Connected, the host reports the automatic group's pick.
    final coordinator = h.container.read(runtimeProvider.notifier);
    await coordinator.connect();
    host.selections[await tag(group('自动'))] = await tag(node('日本'));
    await coordinator.refresh();
    page = await h.settle(
      () => h.container.read(proxiesStateProvider),
      (s) => s.groups.firstWhere((g) => g.name == '自动').current != null,
    );
    expect(page.groups.firstWhere((g) => g.name == '自动').current, 1);
    select = page.groups.firstWhere((g) => g.name == '节点选择');
    expect(select.current, 0);

    // And the dashboard follows the pick down to the node.
    final actual = h.container.read(actualSelectionsProvider);
    expect(actual.resolve(group('节点选择')), node('日本'));
    final dashboard = await h.settle(
      () => h.container.read(dashboardStateProvider),
      (s) => s.exit?.name == '日本',
    );
    expect(dashboard.exit!.latency!.status, LatencyStatus.timedOut);
  });
}
