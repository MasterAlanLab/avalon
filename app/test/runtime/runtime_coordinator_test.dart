// The coordinator against a host that behaves like the Core Bridge, with
// the real services underneath (RUNTIME_HOST §4).
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:av_core/av_core.dart';
import 'package:avalon/app/app_error.dart';
import 'package:avalon/app/providers.dart';
import 'package:avalon/features/configurations/configurations_view_model.dart';
import 'package:avalon/features/dashboard/dashboard_state.dart';
import 'package:avalon/features/dashboard/dashboard_view_model.dart';
import 'package:avalon/platform/installed_apps.dart';
import 'package:avalon/runtime/host_gateway.dart';
import 'package:avalon/runtime/host_protocol.dart';
import 'package:avalon/runtime/runtime_coordinator.dart';
import 'package:avalon/runtime/runtime_host.dart';
import 'package:avalon/runtime/runtime_state.dart';
import 'package:avalon/services/plan_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/harness.dart';
import 'fake_host.dart';

const _clash = '''
proxies:
  - {name: 香港 01, type: trojan, server: a.example.com, port: 443, password: fake-a}
  - {name: 日本 01, type: trojan, server: b.example.com, port: 443, password: fake-b}
proxy-groups:
  - {name: 节点选择, type: select, proxies: [香港 01, 日本 01, DIRECT]}
rules:
  - MATCH,节点选择
''';

final class _Installed implements InstalledApps {
  const _Installed(this.ids);

  final List<String> ids;

  @override
  Future<List<InstalledApp>> list() async => [
    for (final id in ids) InstalledApp(id: id, name: id),
  ];
}

/// The real gateway still handles the query; this transport can hold or
/// fail it to exercise overlapping polls and actions without a timer race.
final class _Snapshots implements HostTransport {
  _Snapshots(this.host);

  final FakeHost host;
  Completer<void>? held;
  bool unreachable = false;
  int queries = 0;

  @override
  Future<String> call(String command, String request) async {
    if (command == 'snapshot') {
      queries++;
      if (unreachable) {
        throw const HostException(
          HostError(HostErrorCode.unreachable, 'the host did not answer'),
        );
      }
      final answer = await host.call(command, request);
      if (held case final gate?) await gate.future;
      return answer;
    }
    return host.call(command, request);
  }
}

void main() {
  late Harness h;
  late FakeHost host;
  late _Snapshots snapshots;
  late Directory dir;

  Future<void> start({
    bool withHost = true,
    bool running = false,
    HostPlatform platform = HostPlatform.macos,
    List<String>? installed,
  }) async {
    dir = Directory.systemTemp.createTempSync('runtime');
    host = FakeHost(dir.path);
    snapshots = _Snapshots(host);
    if (running) {
      host
        ..state = 'running'
        ..sessionId = 'old'
        ..planHash = 'old-hash';
    }
    h = await Harness.start(
      host: withHost ? RuntimeHost(transport: snapshots, system: host) : null,
      platform: platform,
      overrides: [
        if (installed != null)
          installedAppsProvider.overrideWithValue(_Installed(installed)),
        // Tests ask for snapshots themselves.
        runtimePollIntervalProvider.overrideWithValue(const Duration(days: 1)),
        runtimeDebounceProvider.overrideWithValue(
          const Duration(milliseconds: 30),
        ),
      ],
    );
    h.body = _clash;
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

  /// The plan file the host restarts from.
  Map<String, Object?> kept() =>
      (jsonDecode(File('${dir.path}/plan.json').readAsStringSync()) as Map)
          .cast<String, Object?>();

  RuntimeCoordinator coordinator() =>
      h.container.read(runtimeProvider.notifier);
  RuntimeState state() => h.container.read(runtimeProvider);

  /// The coordinator after it has looked at the host once.
  Future<RuntimeCoordinator> ready() async {
    final c = coordinator();
    await c.ready;
    return c;
  }

  test(
    'Tailnet starts without a configuration and keeps the proxy off',
    () async {
      await start();
      final c = await ready();
      await c.setTailnetEnabled(true);
      expect(state().connected, isTrue);
      expect(state().proxyConnected, isFalse);
      expect(state().activeMixedPort, isNull);
      expect(host.askedForTun, isTrue);
      expect(
        h.container.read(dashboardStateProvider).status,
        ConnectionStatus.disconnected,
      );
      final plan = kept();
      expect(
        (plan['endpoints'] as List).single,
        containsPair('type', 'tailscale'),
      );
      final tun = (plan['inbounds'] as List).single as Map;
      expect(tun['route_address'], contains('100.64.0.0/10'));
      await c.stopAll();
      expect(state().connected, isFalse);
      expect((await h.services.settings.device()).tailnet.enabled, isTrue);
    },
  );

  test(
    'ordinary proxy and Tailnet can each be stopped independently',
    () async {
      await start();
      await select();
      final c = await ready();
      await c.connect();
      await c.setTailnetEnabled(true);
      expect(state().proxyConnected, isTrue);
      await c.disconnect();
      expect(state().connected, isTrue);
      expect(state().proxyConnected, isFalse);
      expect(kept()['endpoints'], isNotEmpty);
      await c.connect();
      expect(state().proxyConnected, isTrue);
      await c.setTailnetEnabled(false);
      expect(state().proxyConnected, isTrue);
      expect(kept()['endpoints'], isNull);
      await c.disconnect();
      expect(state().connected, isFalse);
    },
  );

  test('overlapping polls and actions share a confirmed snapshot', () async {
    await start();
    final c = await ready();
    final before = snapshots.queries;
    snapshots.held = Completer<void>();
    final poll = c.refresh();
    final action = c.refresh();
    expect(snapshots.queries, before + 1);
    snapshots.held!.complete();
    expect(await poll, isTrue);
    expect(await action, isTrue);
    snapshots.held = null;
    expect(await c.refresh(), isTrue);
    expect(snapshots.queries, before + 2);
  });

  test('an unreachable host leaves last state but cannot confirm it', () async {
    await start();
    await select();
    final c = await ready();
    await c.connect();
    final previous = state().snapshot;
    snapshots.unreachable = true;
    expect(await c.refresh(), isFalse);
    expect(state().snapshot, same(previous));
    expect(state().connected, isTrue);
    snapshots.unreachable = false;
    expect(await c.refresh(), isTrue);
  });

  test('an older revision cannot confirm or replace current state', () async {
    await start();
    await select();
    final c = await ready();
    await c.connect();
    final previous = state().snapshot;
    host.revision = previous.revision - 2;
    expect(await c.refresh(), isFalse);
    expect(state().snapshot, same(previous));
  });

  test('a poll crossing stop cannot revive the stopped session', () async {
    await start();
    await select();
    final c = await ready();
    await c.connect();
    snapshots.held = Completer<void>();
    final poll = c.refresh();
    // The response was produced while running; delivery is held until
    // after the stop command to exercise a stale in-flight snapshot.
    await Future<void>.delayed(Duration.zero);
    final stop = c.disconnect();
    await h.settle(state, (s) => s.phase == RuntimePhase.stopped);
    snapshots.held!.complete();
    expect(await poll, isFalse);
    await stop;
    snapshots.held = null;
    expect(state().phase, RuntimePhase.stopped);
    expect(state().snapshot.state, HostState.stopped);
  });

  test(
    'connect compiles the selection, hands the plan over and runs',
    () async {
      await start();
      await select();
      final c = await ready();
      expect(state().phase, RuntimePhase.stopped);
      expect(state().coreVersion, '1.14.2');
      // Nothing runs: the host need not stay in memory.
      expect(host.released, 1);

      final phases = <RuntimePhase>[];
      h.container.listen(runtimeProvider, (_, next) => phases.add(next.phase));
      await c.connect();

      expect(phases.first, RuntimePhase.starting);
      expect(state().phase, RuntimePhase.running);
      expect(state().connected, isTrue);
      expect(state().failure, isNull);
      expect(c.sessionId, 's1');
      expect(host.askedForTun, isTrue);

      final request = host.commands.firstWhere((c) => c.$1 == 'start').$2;
      final expected = await h.services.plans.compileSelected();
      expect(request['planHash'], expected.planHash);
      expect(
        request['utcOffsetSeconds'],
        DateTime.now().timeZoneOffset.inSeconds,
      );
      // The plan itself went by file, into the host's directory, and is
      // kept there as the one to restart from.
      expect(File(request['planPath']! as String).parent.path, dir.path);
      final plan =
          jsonDecode(File('${dir.path}/plan.json').readAsStringSync()) as Map;
      expect(plan['outbounds'], isNotEmpty);
      expect(jsonEncode(plan), contains('fake-a'));

      // The snapshot taken right after is the state pages see.
      expect(state().snapshot.planHash, expected.planHash);
      expect(state().snapshot.startedAt, isNotNull);
      expect(state().snapshot.todayDown, 4096);
    },
  );

  test('connecting twice starts once; toggle stops', () async {
    await start();
    await select();
    final c = await ready();
    await Future.wait([c.connect(), c.connect()]);
    expect(host.sent.where((c) => c == 'start'), hasLength(1));

    await c.toggle();
    expect(state().phase, RuntimePhase.stopped);
    expect(host.sent, contains('stop'));
    expect(host.released, 2);

    await c.toggle();
    expect(state().connected, isTrue);
    expect(c.sessionId, 's2');
  });

  test('the system refused: nothing starts, and it says why', () async {
    await start();
    await select();
    final c = await ready();
    host.granted = false;
    await c.connect();
    expect(state().phase, RuntimePhase.stopped);
    expect(state().failure, isA<PermissionRefused>());
    expect(host.sent, isNot(contains('start')));
  });

  test('stop pressed while the system asks: no start afterwards', () async {
    await start();
    await select();
    final c = await ready();
    host.consent = Completer<bool>();
    final connecting = c.connect();
    await h.settle(state, (s) => s.phase == RuntimePhase.starting);
    final stopping = c.disconnect();
    host.consent!.complete(true);
    await Future.wait([connecting, stopping]);
    expect(state().phase, RuntimePhase.stopped);
    expect(state().failure, isNull);
    expect(host.sent, isNot(contains('start')));
  });

  test('nothing selected, and a plan the host refuses', () async {
    await start();
    final c = await ready();
    await c.connect();
    expect(
      state().failure,
      isA<NothingToRun>().having(
        (f) => f.reason,
        'reason',
        PlanUnavailable.nothingSelected,
      ),
    );
    expect(host.sent, isNot(contains('start')));

    await select();
    host.startError = {
      'code': 'PORT_IN_USE',
      'message': 'address already in use',
    };
    await c.connect();
    expect(state().phase, RuntimePhase.stopped);
    expect(
      state().failure,
      isA<HostFailed>().having(
        (f) => f.error.code,
        'code',
        HostErrorCode.portInUse,
      ),
    );

    // The next attempt clears it.
    host.startError = null;
    await c.connect();
    expect(state().failure, isNull);
    expect(state().connected, isTrue);
  });

  test(
    'the host stopped by itself: the state follows, nothing reconnects',
    () async {
      await start();
      await select();
      final c = await ready();
      await c.connect();

      // The user turned the VPN off in the system's settings.
      host
        ..state = 'stopped'
        ..sessionId = ''
        ..planHash = '';
      await c.refresh();
      expect(state().phase, RuntimePhase.stopped);
      expect(state().failure, isNull);
      expect(c.sessionId, '');
      expect(host.sent.where((c) => c == 'start'), hasLength(1));

      // And when it died of something, that is shown.
      await c.connect();
      host
        ..state = 'failed'
        ..sessionId = ''
        ..snapshotError = {'code': 'CORE_FAILED', 'message': 'tun closed'};
      await c.refresh();
      expect(state().phase, RuntimePhase.stopped);
      expect(state().failure, isA<HostFailed>());
    },
  );

  test('a session the host already runs is adopted at start-up', () async {
    await start(running: true);
    final c = await ready();
    expect(state().phase, RuntimePhase.running);
    expect(c.sessionId, 'old');
    expect(state().snapshot.planHash, 'old-hash');
    // It is in use: not let go.
    expect(host.released, 0);
    // The switch then stops it.
    await c.toggle();
    expect(state().phase, RuntimePhase.stopped);
  });

  group('while running, the session follows what the user changes', () {
    late RuntimeCoordinator c;
    late String configurationId;

    Future<void> running() async {
      await start();
      await select();
      configurationId =
          (await h.services.settings.device()).selectedConfigurationId!;
      c = await ready();
      await c.connect();
      host.commands.clear();
    }

    /// Lets the listeners fire, the debounce pass and the queue empty.
    Future<void> settled() async {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      await c.sync();
    }

    Future<(String, String, String)> group() async {
      final plan = await h.services.plans.compileSelected();
      String tag(String name) =>
          plan.tags.entries.firstWhere((e) => e.value.name == name).key;
      return (tag('节点选择'), tag('香港 01'), tag('日本 01'));
    }

    test('a member is switched in place', () async {
      await running();
      final (groupTag, hongKong, japan) = await group();
      expect(host.selections[groupTag], hongKong);
      final content = (await h.services.configurations.content(
        configurationId,
      ))!.content;
      await h.services.selections.select(
        configurationId,
        content.groups.single.key,
        MemberRef.source(
          configurationId: configurationId,
          key: content.nodes.last.key,
        ),
      );
      await settled();
      expect(host.sent, isNot(contains('reload')));
      final sent = host.commands.firstWhere((c) => c.$1 == 'select').$2;
      expect((sent['groupTag'], sent['memberTag']), (groupTag, japan));
      expect(sent['sessionId'], 's1');
      expect(state().snapshot.selections[groupTag], japan);
      expect(c.sessionId, 's1');
      // A restart (at boot, or by the system) runs it too.
      expect(PlanChoices.of(kept()).selections[groupTag], japan);
    });

    test('the mode is switched in place', () async {
      await running();
      await h.services.settings.updateDevice(
        (s) => s.copyWith(mode: OutboundMode.direct),
      );
      await settled();
      expect(host.sent, isNot(contains('reload')));
      expect(
        host.commands.firstWhere((c) => c.$1 == 'setMode').$2['mode'],
        'direct',
      );
      expect(state().snapshot.mode, 'direct');
      expect(PlanChoices.of(kept()).mode, 'direct');
    });

    test('a setting that changes the plan reloads it, once settled', () async {
      await running();
      final phases = <RuntimePhase>[];
      h.container.listen(runtimeProvider, (_, next) => phases.add(next.phase));
      // Several writes in a row, as a refresh or a form would make.
      await h.services.settings.updateDevice(
        (s) => s.copyWith(mixedPort: 7891),
      );
      await h.services.settings.updateDevice(
        (s) => s.copyWith(mixedPort: 7892),
      );
      await settled();
      expect(host.sent.where((c) => c == 'reload'), hasLength(1));
      expect(phases, contains(RuntimePhase.reloading));
      expect(state().phase, RuntimePhase.running);
      expect(c.sessionId, 's2');
      final request = host.commands.firstWhere((c) => c.$1 == 'reload').$2;
      expect(request['sessionId'], 's1');
      expect(
        request['planHash'],
        (await h.services.plans.compileSelected()).planHash,
      );
      final plan =
          jsonDecode(File('${dir.path}/plan.json').readAsStringSync()) as Map;
      expect(jsonEncode(plan), contains('7892'));
    });

    test('a poll crossing reload cannot retain the old controller', () async {
      await running();
      final oldSession = state().snapshot.sessionId;
      snapshots.held = Completer<void>();
      final poll = c.refresh();
      await h.services.settings.updateDevice(
        (s) => s.copyWith(clashApi: true, clashApiListen: '127.0.0.1:9191'),
      );
      final reload = c.sync();
      await h.settle(() => host.sessionId, (id) => id != oldSession);
      snapshots.held!.complete();
      expect(await poll, isFalse);
      await reload;
      snapshots.held = null;
      expect(state().snapshot.sessionId, host.sessionId);
      expect(state().snapshot.clashApiListen, '127.0.0.1:9191');
    });

    test('what does not change the plan sends nothing', () async {
      await running();
      await h.services.settings.updateDevice(
        (s) => s.copyWith(appearance: Appearance.dark, locale: 'en'),
      );
      await settled();
      expect(
        host.sent.where(
          (c) => const {'reload', 'select', 'setMode'}.contains(c),
        ),
        isEmpty,
      );
      expect(c.sessionId, 's1');
    });

    test(
      'a plan the core refuses leaves the session and the old plan',
      () async {
        await running();
        expect(state().activeMixedPort, 7890);
        final before = File('${dir.path}/plan.json').readAsStringSync();
        host.reloadError = {'code': 'PLAN_INVALID', 'message': 'decode config'};
        await h.services.settings.updateDevice(
          (s) => s.copyWith(mixedPort: 7891),
        );
        await settled();
        expect(state().phase, RuntimePhase.running);
        expect(state().activeMixedPort, 7890);
        expect((await h.services.settings.device()).mixedPort, 7891);
        expect(c.sessionId, 's1');
        expect(
          state().failure,
          isA<HostFailed>().having(
            (f) => f.error.code,
            'code',
            HostErrorCode.planInvalid,
          ),
        );
        // The plan to restart from is still the one that runs.
        expect(File('${dir.path}/plan.json').readAsStringSync(), before);

        // Fixed: the next change goes through and clears the failure.
        host.reloadError = null;
        await h.services.settings.updateDevice(
          (s) => s.copyWith(mixedPort: 7893),
        );
        await settled();
        expect(state().failure, isNull);
        expect(c.sessionId, 's2');
        expect(state().activeMixedPort, 7893);
        await c.disconnect();
        expect(state().activeMixedPort, isNull);
      },
    );

    test(
      'a reload that cost the session ends as stopped, with the reason',
      () async {
        await running();
        host
          ..reloadError = {
            'code': 'PORT_IN_USE',
            'message': 'address already in use',
          }
          ..reloadKills = true;
        await h.services.settings.updateDevice(
          (s) => s.copyWith(mixedPort: 80),
        );
        await settled();
        expect(state().phase, RuntimePhase.stopped);
        expect(state().connected, isFalse);
        expect(
          state().failure,
          isA<HostFailed>().having(
            (f) => f.error.code,
            'code',
            HostErrorCode.portInUse,
          ),
        );
      },
    );

    test('a change that cannot be compiled keeps the session', () async {
      await running();
      // Per-app on desktop needs find process; here the override is what
      // breaks: it names an outbound that does not exist.
      await h.services.settings.updatePolicy(
        (p) => p.copyWith(
          jsonOverride: const Secret(
            '{"route": {"rules": [{"domain": ["a.com"], "outbound": "nowhere"}]}}',
          ),
        ),
      );
      await settled();
      expect(state().phase, RuntimePhase.running);
      expect(state().failure, isA<PlanFailed>());
      expect(host.sent, isNot(contains('reload')));
    });

    test('a mode chosen in an external panel becomes the user\'s', () async {
      await running();
      // Someone switches the mode on the Clash API.
      host.mode = 'Global';
      await c.refresh();
      await settled();
      expect((await h.services.settings.device()).mode, OutboundMode.global);
      // Nothing is sent back to undo it.
      expect(host.sent, isNot(contains('setMode')));
      expect(host.sent, isNot(contains('reload')));
      expect(host.mode, 'Global');
    });

    test('a member chosen in an external panel becomes the user\'s', () async {
      await running();
      final (groupTag, _, japan) = await group();
      host.selections[groupTag] = japan;
      await c.refresh();
      await settled();
      final content = (await h.services.configurations.content(
        configurationId,
      ))!.content;
      final saved = await h.services.selections.watch(configurationId).first;
      expect(
        saved[content.groups.single.key],
        MemberRef.source(
          configurationId: configurationId,
          key: content.nodes.last.key,
        ),
      );
      expect(host.sent, isNot(contains('select')));
      expect(host.selections[groupTag], japan);
    });

    test('our own switch is not taken for an external one', () async {
      await running();
      final (groupTag, hongKong, _) = await group();
      await h.services.settings.updateDevice(
        (s) => s.copyWith(mode: OutboundMode.direct),
      );
      await settled();
      for (var i = 0; i < 3; i++) {
        await c.refresh();
      }
      expect((await h.services.settings.device()).mode, OutboundMode.direct);
      expect(host.selections[groupTag], hongKong);
      expect(host.sent.where((c) => c == 'setMode'), hasLength(1));
    });

    test('after a stop nothing is followed any more', () async {
      await running();
      await c.disconnect();
      host.commands.clear();
      await h.services.settings.updateDevice(
        (s) => s.copyWith(mixedPort: 7891),
      );
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(host.commands, isEmpty);
    });
  });

  test(
    'the configuration in use cannot be deleted from under the proxy',
    () async {
      await start();
      await select();
      final id = (await h.services.settings.device()).selectedConfigurationId!;
      final c = await ready();
      final model = h.container.read(configurationsViewModelProvider.notifier);
      h.container.listen(configurationsViewModelProvider, (_, _) {});
      await c.connect();

      final refused = await model.delete(id);
      expect(
        refused,
        isA<Err<void>>().having(
          (e) => e.error.code,
          'code',
          'configuration.inUse',
        ),
      );
      expect(await h.services.configurations.content(id), isNotNull);
      expect((await h.services.settings.device()).selectedConfigurationId, id);

      // Disconnected, it can go.
      await c.disconnect();
      expect(await model.delete(id), isA<Ok<void>>());
      expect(await h.services.configurations.content(id), isNull);
    },
  );

  test('a session adopted at start-up is brought in line', () async {
    await start(running: true);
    await select();
    host
      ..mode = 'rule'
      ..selections = {};
    final c = await ready();
    await c.sync();
    // The host ran another plan ('old-hash'): the current one is loaded.
    expect(host.sent, contains('reload'));
    expect(state().phase, RuntimePhase.running);
    expect(
      state().snapshot.planHash,
      (await h.services.plans.compileSelected()).planHash,
    );
  });

  test(
    'a cold session port is unknown until the same plan is confirmed',
    () async {
      await start();
      await select();
      final plan = await h.services.plans.compileSelected();
      host
        ..state = 'running'
        ..sessionId = 'old'
        ..planHash = plan.planHash;
      final ports = <int?>[];
      h.container.listen(runtimeProvider, (_, next) {
        if (next.connected) ports.add(next.activeMixedPort);
      });
      h.container.invalidate(runtimeProvider);
      final c = await ready();
      await c.sync();
      expect(ports.first, isNull);
      expect(state().activeMixedPort, 7890);
      expect(host.sent, isNot(contains('reload')));
    },
  );

  test('the host is told the settings it acts on by itself', () async {
    await start();
    await ready();
    await h.settle(() => host.options.length, (n) => n > 0);
    // Defaults: speed shown; no start at boot without «启动后自动连接».
    expect(host.options.last.speedNotification, isTrue);
    expect(host.options.last.startAtBoot, isFalse);
    await h.services.settings.updateDevice(
      (s) =>
          s.copyWith(autoConnect: true, speedNotification: false, locale: 'en'),
    );
    await h.settle(
      () => host.options.last,
      (o) => o.startAtBoot && !o.speedNotification && o.language == 'en',
    );
    final count = host.options.length;
    // What the host does not use sends nothing.
    await h.services.settings.updateDevice((s) => s.copyWith(fakeIp: true));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(host.options.length, count);
  });

  test('«启动后自动连接» connects as the app opens, once', () async {
    await start();
    await select();
    await h.services.settings.updateDevice(
      (s) => s.copyWith(autoConnect: true),
    );
    // The app opens again.
    h.container.invalidate(runtimeProvider);
    await ready();
    await h.settle(() => state().phase, (p) => p == RuntimePhase.running);
    expect(host.sent.where((c) => c == 'start'), hasLength(1));
  });

  test('an allow list with no app installed does not start', () async {
    await start(platform: HostPlatform.android, installed: ['com.example.b']);
    await select();
    await h.services.settings.updateDevice(
      (s) => s.copyWith(
        perAppMode: PerAppMode.whitelist,
        perAppList: ['com.example.gone'],
      ),
    );
    final c = await ready();
    await c.connect();
    expect(state().phase, RuntimePhase.stopped);
    expect(state().failure, isA<NoListedAppInstalled>());
    expect(host.sent, isNot(contains('start')));

    // One of them installed: it starts, taking only that app.
    await h.services.settings.updateDevice(
      (s) => s.copyWith(perAppList: ['com.example.gone', 'com.example.b']),
    );
    await c.connect();
    expect(state().phase, RuntimePhase.running);

    // Changed while running to none installed: the session goes on.
    host.commands.clear();
    await h.services.settings.updateDevice(
      (s) => s.copyWith(perAppList: ['com.example.gone']),
    );
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await c.sync();
    expect(host.sent, isNot(contains('reload')));
    expect(state().phase, RuntimePhase.running);
    expect(state().failure, isA<NoListedAppInstalled>());
  });

  test('where the host is not built yet, nothing is attempted', () async {
    await start(withHost: false);
    await select();
    expect(state().available, isFalse);
    await coordinator().connect();
    expect(state().phase, RuntimePhase.stopped);
    expect(host.commands, isEmpty);
  });
}
