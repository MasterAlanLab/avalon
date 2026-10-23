// The desktop shell (PRODUCT_SPEC §7, RUNTIME_HOST §9) with fake window,
// tray, hotkeys and login item over the real runtime and a fake host.
import 'dart:async';
import 'dart:io';

import 'package:av_core/av_core.dart';
import 'package:avalon/app/desktop_shell.dart';
import 'package:avalon/platform/desktop/desktop_window.dart';
import 'package:avalon/platform/desktop/global_hotkeys.dart';
import 'package:avalon/platform/desktop/login_item.dart';
import 'package:avalon/platform/desktop/system_tray.dart';
import 'package:avalon/runtime/runtime_coordinator.dart';
import 'package:avalon/runtime/runtime_host.dart';
import 'package:avalon/runtime/runtime_state.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/harness.dart';
import '../runtime/fake_host.dart';

// The streams are closed in tearDown.
// ignore_for_file: close_sinks

final class _Window implements DesktopWindow {
  var visible = false;
  var quit_ = false;
  final closes = StreamController<void>.broadcast();
  final quits = StreamController<void>.broadcast();

  @override
  Stream<void> get closeRequests => closes.stream;
  @override
  Stream<void> get quitRequests => quits.stream;
  @override
  Future<void> setup() async {}
  @override
  Future<void> show() async => visible = true;
  @override
  Future<void> hide() async => visible = false;
  @override
  Future<void> quit() async => quit_ = true;
}

final class _Tray implements SystemTray {
  _Tray({this.available = true});

  final bool available;
  String? icon;
  List<TrayItem> menu = const [];
  final chosen = StreamController<String>.broadcast();

  @override
  Stream<String> get choices => chosen.stream;
  @override
  Future<bool> show(String icon) async {
    this.icon = icon;
    return available;
  }

  @override
  Future<void> setIcon(String icon) async => this.icon = icon;
  @override
  Future<void> setMenu(List<TrayItem> items) async => menu = items;

  TrayItem item(String key) => [
    ...menu,
    for (final m in menu) ...m.children,
  ].firstWhere((i) => i.key == key);
}

final class _Hotkeys implements GlobalHotkeys {
  _Hotkeys(this.results);

  final Map<HotkeyAction, HotkeyResult> results;
  final handlers = <HotkeyAction, void Function()>{};

  @override
  Future<HotkeyResult> register(HotkeyAction a, void Function() f) async {
    handlers[a] = f;
    return results[a] ?? HotkeyResult.registered;
  }

  @override
  Future<void> unregisterAll() async => handlers.clear();
}

final class _LoginItem implements LoginItem {
  final calls = <bool>[];
  Exception? error;
  Completer<void>? hold;
  @override
  Future<void> set({required bool enabled}) async {
    calls.add(enabled);
    if (hold case final gate?) await gate.future;
    if (error case final problem?) throw problem;
  }
}

const _links = 'trojan://fake-a@a.example.com:443#A\n';

void main() {
  late Harness h;
  late FakeHost host;
  late Directory dir;
  late _Window window;
  late _Tray tray;
  late _Hotkeys hotkeys;
  late _LoginItem login;
  late DesktopShell shell;
  var quitCalled = false;

  Future<void> start({
    bool silent = false,
    bool trayAvailable = true,
    Map<HotkeyAction, HotkeyResult> results = const {},
  }) async {
    dir = Directory.systemTemp.createTempSync('shell');
    host = FakeHost(dir.path);
    h = await Harness.start(
      host: RuntimeHost(transport: host, system: host),
      overrides: [
        runtimePollIntervalProvider.overrideWithValue(const Duration(days: 1)),
        runtimeDebounceProvider.overrideWithValue(
          const Duration(milliseconds: 30),
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
    window = _Window();
    tray = _Tray(available: trayAvailable);
    hotkeys = _Hotkeys(results);
    login = _LoginItem();
    quitCalled = false;
    shell = DesktopShell(
      container: h.container,
      window: window,
      tray: tray,
      hotkeys: hotkeys,
      loginItem: login,
      icons: (idle: 'idle', running: 'running'),
      quitApp: () async => quitCalled = true,
      touchLoginItem: true,
    );
    await shell.start(silent: silent);
  }

  tearDown(() async {
    await window.closes.close();
    await window.quits.close();
    await tray.chosen.close();
    await h.stop();
    dir.deleteSync(recursive: true);
  });

  Future<void> settle() async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    await h.container.read(runtimeProvider.notifier).idle();
  }

  test('«静默启动» keeps the window hidden only where there is a tray', () async {
    await start(silent: true);
    expect(window.visible, isFalse);
    await h.stop();
    dir.deleteSync(recursive: true);

    await start(silent: true, trayAvailable: false);
    expect(window.visible, isTrue);
    expect(shell.trayShown, isFalse);
  });

  test('the tray menu follows the runtime and the mode', () async {
    await start();
    expect(window.visible, isTrue);
    expect(tray.icon, 'idle');
    expect(tray.item('mode:rule').checked, isTrue);

    // From the tray: start, then another mode.
    tray.chosen.add('toggle');
    await h.settle(() => tray.icon, (icon) => icon == 'running');
    expect(host.sent, contains('start'));
    tray.chosen.add('mode:global');
    await h.settle(
      () => tray.item('mode:global').checked,
      (checked) => checked == true,
    );
    expect((await h.services.settings.device()).mode, OutboundMode.global);
  });

  test('closing hides with a tray to come back from, else quits', () async {
    await start();
    window.closes.add(null);
    await settle();
    expect(window.visible, isFalse);
    expect(quitCalled, isFalse);
    tray.chosen.add('show');
    await settle();
    expect(window.visible, isTrue);

    // Connected, and «关闭窗口时保留» off: closing stops and quits.
    await h.container.read(runtimeProvider.notifier).connect();
    await h.services.settings.updateDevice(
      (s) => s.copyWith(keepOnClose: false),
    );
    window.closes.add(null);
    await h.settle(() => quitCalled, (q) => q);
    expect(host.sent, contains('stop'));
    expect(window.quit_, isTrue);
  });

  test('shortcuts: results for the settings, and what they do', () async {
    await start(results: {HotkeyAction.show: HotkeyResult.taken});
    expect(h.container.read(hotkeyResultsProvider), {
      HotkeyAction.toggle: HotkeyResult.registered,
      HotkeyAction.mode: HotkeyResult.registered,
      HotkeyAction.show: HotkeyResult.taken,
    });
    hotkeys.handlers[HotkeyAction.mode]!();
    await h.settle(() => h.services.settings.device(), (_) => true);
    await settle();
    expect((await h.services.settings.device()).mode, OutboundMode.global);
    hotkeys.handlers[HotkeyAction.toggle]!();
    await h.settle(() => tray.icon, (icon) => icon == 'running');
  });

  test(
    'system quit stops the runtime even when close keeps the window',
    () async {
      await start();
      await h.container.read(runtimeProvider.notifier).connect();
      window.quits.add(null);
      await h.settle(() => quitCalled, (quit) => quit);
      expect(host.sent, contains('stop'));
      expect(window.quit_, isTrue);
      expect(hotkeys.handlers, isEmpty);
    },
  );

  test(
    'quit waits for an in-flight connection and cancels its intent',
    () async {
      await start();
      final consent = host.consent = Completer<bool>();
      final connecting = h.container.read(runtimeProvider.notifier).connect();
      await h.settle(
        () => h.container.read(runtimeProvider).phase,
        (phase) => phase == RuntimePhase.starting,
      );
      final quitting = shell.quit();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(quitCalled, isFalse);
      consent.complete(true);
      await connecting;
      await quitting;
      expect(host.sent, isNot(contains('start')));
      expect(quitCalled, isTrue);
    },
  );

  test('a failed stop keeps the window open and allows another quit', () async {
    await start();
    await h.container.read(runtimeProvider.notifier).connect();
    host.stopError = {'code': 'unreachable', 'message': 'stop rejected'};
    await shell.quit();
    expect(quitCalled, isFalse);
    expect(window.visible, isTrue);
    expect(window.quit_, isFalse);
    expect(h.container.read(runtimeProvider).connected, isTrue);

    host.stopError = null;
    await shell.quit();
    expect(quitCalled, isTrue);
  });

  test(
    'login startup failures remain visible until an operation succeeds',
    () async {
      await start();
      await settle();
      login.error = PlatformException(code: 'approvalRequired');
      await h.services.settings.updateDevice(
        (s) => s.copyWith(launchAtStartup: false),
      );
      await h.settle(
        () => h.container.read(loginItemProblemProvider),
        (problem) => problem == LoginItemProblem.approvalRequired,
      );
      login.error = PlatformException(code: 'refused');
      await h.services.settings.updateDevice(
        (s) => s.copyWith(launchAtStartup: true),
      );
      await h.settle(
        () => h.container.read(loginItemProblemProvider),
        (problem) => problem == LoginItemProblem.failed,
      );
      login.error = null;
      await h.services.settings.updateDevice(
        (s) => s.copyWith(launchAtStartup: false),
      );
      await h.settle(
        () => h.container.read(loginItemProblemProvider),
        (problem) => problem == null,
      );
    },
  );

  test('login startup applies rapid preference changes in order', () async {
    await start();
    await settle();
    final gate = login.hold = Completer<void>();
    await h.services.settings.updateDevice(
      (s) => s.copyWith(launchAtStartup: false),
    );
    await h.settle(() => login.calls.length, (n) => n == 2);
    await h.services.settings.updateDevice(
      (s) => s.copyWith(launchAtStartup: true),
    );
    await settle();
    expect(login.calls, [true, false]);
    gate.complete();
    await h.settle(() => login.calls.length, (n) => n == 3);
    expect(login.calls, [true, false, true]);
  });
}
