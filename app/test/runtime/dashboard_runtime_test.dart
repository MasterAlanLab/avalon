// The dashboard as the runtime drives it: what the page shows while the
// proxy connects, runs, fails and stops (PRODUCT_SPEC §3.1).
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:av_core/av_core.dart';
import 'package:avalon/app/providers.dart';
import 'package:avalon/features/dashboard/dashboard_state.dart';
import 'package:avalon/features/dashboard/dashboard_view_model.dart';
import 'package:avalon/runtime/host_gateway.dart';
import 'package:avalon/runtime/runtime_coordinator.dart';
import 'package:avalon/runtime/runtime_host.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/harness.dart';

const _clash = '''
proxies:
  - {name: 香港 01, type: trojan, server: a.example.com, port: 443, password: fake-a}
proxy-groups:
  - {name: 节点选择, type: select, proxies: [香港 01, DIRECT]}
rules:
  - MATCH,节点选择
''';

final class _Host implements HostTransport, HostSystem {
  _Host(this.dir);

  final String dir;
  var state = 'stopped';
  var granted = true;
  Map<String, Object?>? startError;
  Map<String, Object?>? reloadError;
  Future<void> Function()? beforeReload;
  var reportActivity = true;
  var revision = 0;
  var planHash = '';
  var proxyActive = false;
  var tailnetActive = false;
  var tunActive = false;
  var systemProxyActive = false;
  final started = DateTime.now().subtract(const Duration(minutes: 5));

  void run(String request) {
    final decoded = (jsonDecode(request) as Map).cast<String, Object?>();
    final plan =
        jsonDecode(File(decoded['planPath']! as String).readAsStringSync())
            as Map;
    final tun = (plan['inbounds'] as List)
        .cast<Map<String, Object?>>()
        .where((inbound) => inbound['type'] == 'tun')
        .firstOrNull;
    proxyActive = (plan['inbounds'] as List).any(
      (inbound) =>
          ['mixed', 'http', 'socks'].contains((inbound as Map)['type']),
    );
    tailnetActive = (plan['endpoints'] as List? ?? const []).any(
      (endpoint) => (endpoint as Map)['type'] == 'tailscale',
    );
    planHash = decoded['planHash']! as String;
    tunActive = tun != null;
    systemProxyActive =
        ((tun?['platform'] as Map?)?['http_proxy'] as Map?)?['enabled'] == true;
    state = 'running';
  }

  @override
  Future<String> call(String command, String request) async {
    Object? result;
    switch (command) {
      case 'capabilities':
        result = {'protocolVersion': 1, 'coreVersion': '1.14.2'};
      case 'start':
        if (startError != null) return jsonEncode({'error': startError});
        run(request);
        result = {'sessionId': 's1'};
      case 'reload':
        final wait = beforeReload;
        beforeReload = null;
        await wait?.call();
        if (reloadError != null) return jsonEncode({'error': reloadError});
        run(request);
        result = {'sessionId': 's1', 'method': 'restart'};
      case 'stop':
        state = 'stopped';
      case 'snapshot':
        final running = state == 'running';
        result = {
          'sessionId': running ? 's1' : '',
          'revision': ++revision,
          'state': state,
          if (reportActivity) ...{
            'proxyActive': running && proxyActive,
            'tailnetActive': running && tailnetActive,
            'tunActive': running && tunActive,
            'systemProxyActive': running && systemProxyActive,
          },
          if (running) ...{
            'planHash': planHash,
            'startedAt': started.millisecondsSinceEpoch,
            'upBps': 2048,
            'downBps': 1048576,
          },
          'todayUp': 10,
          'todayDown': 20,
        };
    }
    return jsonEncode({'result': ?result});
  }

  @override
  Future<HostFacts> facts() async => HostFacts(stateDir: dir, deviceName: 't');

  @override
  Future<bool> prepare({required bool tun}) async => granted;

  @override
  Future<void> release() async {}

  @override
  Future<void> configure(HostOptions options) async {}
}

void main() {
  late Harness h;
  late _Host host;
  late Directory dir;

  Future<void> start({
    bool withHost = true,
    HostPlatform platform = HostPlatform.macos,
  }) async {
    dir = Directory.systemTemp.createTempSync('dashboard');
    host = _Host(dir.path);
    h = await Harness.start(
      host: withHost ? RuntimeHost(transport: host, system: host) : null,
      platform: platform,
      overrides: [
        runtimePollIntervalProvider.overrideWithValue(const Duration(days: 1)),
        runtimeDebounceProvider.overrideWithValue(const Duration(days: 1)),
      ],
    );
    h.body = _clash;
    h.container.listen(dashboardStateProvider, (_, _) {});
  }

  tearDown(() async {
    await h.stop();
    dir.deleteSync(recursive: true);
  });

  Future<void> select() async {
    final added = await h.services.imports.addSubscription(
      url: '${h.base}/sub',
      defaultName: '新订阅',
    );
    await h.services.settings.updateDevice(
      (s) => s.copyWith(selectedConfigurationId: added.configurationId),
    );
  }

  DashboardState page() => h.container.read(dashboardStateProvider);
  Future<DashboardState> settled(bool Function(DashboardState s) ready) =>
      h.settle(page, ready);

  test('ready, connected with live figures, then stopped again', () async {
    await start();
    await select();
    await h.container.read(runtimeProvider.notifier).ready;
    var s = await settled((s) => s.coreVersion.isNotEmpty && s.exit != null);
    expect(s.status, ConnectionStatus.disconnected);
    expect(s.coreVersion, '1.14.2');
    expect(s.connectedFor, isNull);
    expect((s.todayUp, s.todayDown), (10, 20));

    await h.container.read(dashboardViewModelProvider).togglePower();
    s = await settled((s) => s.connected);
    expect(s.status, ConnectionStatus.connected);
    expect(s.connectedFor!.inMinutes, 5);
    expect((s.upBps, s.downBps), (2048, 1048576));
    expect(s.speeds, [1048576]);
    expect(s.failure, isNull);

    await h.container.read(dashboardViewModelProvider).togglePower();
    s = await settled((s) => !s.connected);
    expect(s.status, ConnectionStatus.disconnected);
    expect((s.upBps, s.downBps), (0, 0));
    expect(s.speeds, isEmpty);
    expect(s.connectedFor, isNull);
  });

  test('a failure is put in the page\'s own terms', () async {
    await start();
    await h.container.read(runtimeProvider.notifier).ready;
    final power = h.container.read(dashboardViewModelProvider).togglePower;

    await power();
    expect(
      (await settled((s) => s.failure != null)).failure,
      ConnectionFailure.nothingSelected,
    );

    await select();
    host.granted = false;
    await power();
    expect(
      (await settled(
        (s) => s.failure == ConnectionFailure.permissionRefused,
      )).status,
      ConnectionStatus.disconnected,
    );

    host.granted = true;
    for (final (code, expected) in [
      ('PORT_IN_USE', ConnectionFailure.portInUse),
      ('PLAN_INVALID', ConnectionFailure.planRefused),
      ('CORE_FAILED', ConnectionFailure.coreFailed),
    ]) {
      host.startError = {'code': code, 'message': 'what the core said'};
      await power();
      final s = await settled((s) => s.failure == expected);
      expect(s.failureDetail, 'what the core said');
    }

    // A start that works clears it.
    host.startError = null;
    await power();
    expect((await settled((s) => s.connected)).failure, isNull);
  });

  test('where there is no host yet the page says unavailable', () async {
    await start(withHost: false);
    final s = await settled((s) => !s.loading);
    expect(s.status, ConnectionStatus.unavailable);
    expect((s.todayUp, s.todayDown), (null, null));
  });

  test('TUN and system proxy switch independently in a running plan', () async {
    await start(platform: HostPlatform.android);
    await select();
    final model = h.container.read(dashboardViewModelProvider);
    final runtime = h.container.read(runtimeProvider.notifier);
    await model.setSystemProxy(true);
    await runtime.ready;
    await runtime.connect();

    Future<void> expectMode(bool tun, bool proxy) async {
      final s = await settled(
        (s) => s.connected && s.tunEnabled == tun && s.systemProxy == proxy,
      );
      expect(s.status, ConnectionStatus.connected);
      expect((s.tunKnown, s.systemProxyKnown), (true, true));
      expect(s.failure, isNull);
      expect((host.tunActive, host.systemProxyActive), (tun, proxy));
      final saved = await h.services.settings.device();
      expect((saved.tunEnabled, saved.systemProxy), (tun, proxy));
    }

    Future<void> applyMode(bool tun, bool proxy) async {
      await h.settle(
        () => h.container.read(deviceSettingsProvider).value,
        (s) => s != null && s.tunEnabled == tun && s.systemProxy == proxy,
      );
      // This harness disables the debounce timer; explicitly run the
      // production coordinator after the saved settings reach providers.
      await runtime.sync();
      await expectMode(tun, proxy);
    }

    await expectMode(true, true);
    await model.setSystemProxy(false);
    // The dashboard reflects the tap before Android finishes restarting the
    // native session, so the control does not look stuck during the reload.
    expect(page().systemProxy, isFalse);
    await applyMode(true, false);
    await model.setTun(false);
    expect(page().tunEnabled, isFalse);
    await applyMode(false, false);
    await model.setTun(true);
    expect(page().tunEnabled, isTrue);
    await applyMode(true, false);
  });

  test(
    'rapid TUN taps stay visible when an older running reload finishes',
    () async {
      await start(platform: HostPlatform.android);
      await select();
      final model = h.container.read(dashboardViewModelProvider);
      final runtime = h.container.read(runtimeProvider.notifier);
      await runtime.ready;
      await runtime.connect();
      await settled((s) => s.connected && s.tunEnabled);

      final reloadStarted = Completer<void>();
      final releaseReload = Completer<void>();
      host.beforeReload = () {
        reloadStarted.complete();
        return releaseReload.future;
      };
      // Always release the native command, including after a failed assertion.
      addTearDown(() {
        if (!releaseReload.isCompleted) releaseReload.complete();
      });

      final first = model.setTun(false);
      expect(page().tunEnabled, isFalse);
      await first;
      await reloadStarted.future;

      // These taps occur while the first native restart is still pending.
      for (final enabled in [true, false, true]) {
        final save = model.setTun(enabled);
        expect(page().tunEnabled, enabled);
        expect(page().tunKnown, isTrue);
        expect(page().status, ConnectionStatus.reconnecting);
        await save;
      }
      await h.settle(
        () => h.container.read(deviceSettingsProvider).value?.tunEnabled,
        (enabled) => enabled == true,
      );

      final shown = <bool>[];
      final subscription = h.container.listen(
        dashboardStateProvider,
        (_, next) => shown.add(next.tunEnabled),
      );
      addTearDown(subscription.close);
      releaseReload.complete();
      await runtime.idle();

      expect(shown, everyElement(isTrue));
      expect(page().tunEnabled, isTrue);
      expect(page().status, ConnectionStatus.connected);
      expect(host.tunActive, isTrue);
      expect((await h.services.settings.device()).tunEnabled, isTrue);
      expect(h.container.read(runtimeProvider).pendingTun, isNull);
    },
  );

  test(
    'starting the proxy keeps its TUN off while Tailnet has a tunnel',
    () async {
      await start(platform: HostPlatform.android);
      await select();
      final model = h.container.read(dashboardViewModelProvider);
      final runtime = h.container.read(runtimeProvider.notifier);
      await runtime.ready;
      await model.setTun(false);
      await h.settle(
        () => h.container.read(deviceSettingsProvider).value?.tunEnabled,
        (enabled) => enabled == false,
      );
      await runtime.setTailnetEnabled(true);
      expect(host.tunActive, isTrue);
      expect(host.proxyActive, isFalse);
      expect(page().tunEnabled, isFalse);

      await runtime.connect();
      await runtime.idle();
      final s = await settled((s) => s.connected);
      expect((s.tunEnabled, s.systemProxy), (false, false));
      expect(s.tunKnown, isTrue);
      expect(
        (host.proxyActive, host.tailnetActive, host.tunActive),
        (true, true, true),
      );
      expect(h.container.read(runtimeProvider).pendingTun, isNull);

      // Writing the already saved value cannot leave an intent waiting for
      // a settings-stream change that will never arrive.
      await model.setTun(false);
      await runtime.idle();
      expect(h.container.read(runtimeProvider).pendingTun, isNull);
      expect(page().tunEnabled, isFalse);
    },
  );

  test(
    'turning proxy TUN off keeps Tailnet alive without the switch jumping back',
    () async {
      await start(platform: HostPlatform.android);
      await select();
      final model = h.container.read(dashboardViewModelProvider);
      final runtime = h.container.read(runtimeProvider.notifier);
      await runtime.ready;
      await runtime.setTailnetEnabled(true);
      await runtime.connect();
      await settled((s) => s.connected && s.tunEnabled);

      final shown = <bool>[];
      final subscription = h.container.listen(
        dashboardStateProvider,
        (_, next) => shown.add(next.tunEnabled),
      );
      addTearDown(subscription.close);
      final save = model.setTun(false);
      expect(page().tunEnabled, isFalse);
      await save;
      await h.settle(
        () => h.container.read(deviceSettingsProvider).value?.tunEnabled,
        (enabled) => enabled == false,
      );
      await runtime.sync();
      await runtime.idle();

      expect(shown, everyElement(isFalse));
      expect(page().status, ConnectionStatus.connected);
      expect(page().tunEnabled, isFalse);
      expect(page().tunKnown, isTrue);
      expect(page().failure, isNull);
      expect(
        (host.proxyActive, host.tailnetActive, host.tunActive),
        (true, true, true),
      );
      expect(h.container.read(runtimeProvider).snapshot.tunActive, isTrue);
      expect(h.container.read(runtimeProvider).pendingTun, isNull);
    },
  );

  for (final acceptedTun in [true, false]) {
    test(
      'a refused reload keeps accepted proxy TUN $acceptedTun with Tailnet on',
      () async {
        await start(platform: HostPlatform.android);
        await select();
        final model = h.container.read(dashboardViewModelProvider);
        final runtime = h.container.read(runtimeProvider.notifier);
        await runtime.ready;
        await model.setTun(acceptedTun);
        await h.settle(
          () => h.container.read(deviceSettingsProvider).value?.tunEnabled,
          (enabled) => enabled == acceptedTun,
        );
        await runtime.setTailnetEnabled(true);
        await runtime.connect();
        await settled((s) => s.connected);
        expect(page().tunEnabled, acceptedTun);
        expect(host.tunActive, isTrue);

        host.reloadError = {
          'code': 'PLAN_INVALID',
          'message': 'rejected new plan',
        };
        await model.setTun(!acceptedTun);
        expect(page().tunEnabled, !acceptedTun);
        await h.settle(
          () => h.container.read(deviceSettingsProvider).value?.tunEnabled,
          (enabled) => enabled == !acceptedTun,
        );
        await runtime.sync();
        await runtime.idle();
        final s = await settled(
          (s) => s.failure == ConnectionFailure.planRefused,
        );
        expect(s.status, ConnectionStatus.connected);
        expect(s.tunEnabled, acceptedTun);
        expect(s.tunKnown, isTrue);
        expect((host.tailnetActive, host.tunActive), (true, true));
        expect(h.container.read(runtimeProvider).pendingTun, isNull);
        expect((await h.services.settings.device()).tunEnabled, !acceptedTun);
      },
    );
  }

  test(
    'a rejected change shows the old session and preserves new preferences',
    () async {
      await start();
      await select();
      await h.services.settings.updateDevice(
        (s) => s.copyWith(systemProxy: true),
      );
      final runtime = h.container.read(runtimeProvider.notifier);
      await runtime.ready;
      await runtime.connect();
      var s = await settled((s) => s.connected);
      expect((s.tunEnabled, s.systemProxy), (true, true));

      host.reloadError = {
        'code': 'PLAN_INVALID',
        'message': 'rejected new plan',
      };
      await h.services.settings.updateDevice(
        (s) => s.copyWith(tunEnabled: false, systemProxy: false),
      );
      await h.settle(
        () => h.container.read(deviceSettingsProvider).value,
        (s) => s != null && !s.tunEnabled && !s.systemProxy,
      );
      await runtime.sync();
      s = await settled((s) => s.failure == ConnectionFailure.planRefused);
      expect(s.status, ConnectionStatus.connected);
      expect((s.tunEnabled, s.systemProxy), (true, true));
      expect((s.tunKnown, s.systemProxyKnown), (true, true));
      final saved = await h.services.settings.device();
      expect((saved.tunEnabled, saved.systemProxy), (false, false));

      await runtime.disconnect();
      s = await settled((s) => !s.connected);
      expect((s.tunEnabled, s.systemProxy), (false, false));
    },
  );

  test('compile failure leaves actual takeover visible', () async {
    await start();
    await select();
    final runtime = h.container.read(runtimeProvider.notifier);
    await runtime.ready;
    await runtime.connect();
    await settled((s) => s.connected);
    await h.services.settings.updateDevice(
      (s) => s.copyWith(
        tunEnabled: false,
        findProcess: false,
        perAppList: ['/Applications/Example.app'],
      ),
    );
    await h.settle(
      () => h.container.read(deviceSettingsProvider).value,
      (s) => s != null && !s.tunEnabled && !s.findProcess,
    );
    await runtime.sync();
    final s = await settled((s) => s.failure == ConnectionFailure.planFailed);
    expect(s.status, ConnectionStatus.connected);
    expect(s.tunEnabled, isTrue);
    expect(s.tunKnown, isTrue);
  });

  test(
    'old host activity is unknown while connected, not saved preferences',
    () async {
      await start();
      host.reportActivity = false;
      await select();
      final runtime = h.container.read(runtimeProvider.notifier);
      await runtime.ready;
      await runtime.connect();
      final s = await settled((s) => s.connected);
      expect((s.tunKnown, s.systemProxyKnown), (false, false));
      expect(s.connected, isTrue);
    },
  );
}
