import 'dart:io';

import 'package:av_core/av_core.dart';
import 'package:avalon/app/providers.dart';
import 'package:avalon/features/settings/settings_view_model.dart';
import 'package:avalon/features/settings/web_panel.dart';
import 'package:avalon/platform/browser.dart';
import 'package:avalon/runtime/host_protocol.dart';
import 'package:avalon/runtime/runtime_coordinator.dart';
import 'package:avalon/runtime/runtime_host.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../runtime/fake_host.dart';
import 'harness.dart';

final class _Browser implements Browser {
  final opened = <Uri>[];
  bool succeeds = true;
  bool throws = false;

  @override
  Future<bool> open(Uri url) async {
    opened.add(url);
    if (throws) throw PlatformException(code: 'browser-unavailable');
    return succeeds;
  }
}

void main() {
  test('panel target requires a running, reported controller', () {
    for (final state in HostState.values) {
      if (state == HostState.running) continue;
      expect(
        webPanelTarget(
          HostSnapshot(state: state, clashApiListen: '127.0.0.1:9090'),
        ).problem,
        WebPanelProblem.notRunning,
      );
    }
    expect(
      webPanelTarget(const HostSnapshot(state: HostState.running)).problem,
      WebPanelProblem.unknown,
    );
    expect(
      webPanelTarget(
        const HostSnapshot(state: HostState.running, clashApiListen: ''),
      ).problem,
      WebPanelProblem.disabled,
    );
  });

  test('listen addresses produce local browser URLs without secrets', () {
    for (final (listen, expected) in [
      ('127.0.0.1:9090', 'http://127.0.0.1:9090/ui'),
      ('localhost:9000', 'http://localhost:9000/ui'),
      ('0.0.0.0:9090', 'http://127.0.0.1:9090/ui'),
      ('[::]:9090', 'http://[::1]:9090/ui'),
      ('[::1]:9000', 'http://[::1]:9000/ui'),
      ('192.168.1.10:9090', 'http://192.168.1.10:9090/ui'),
    ]) {
      final target = webPanelTarget(
        HostSnapshot(state: HostState.running, clashApiListen: listen),
      );
      expect(target.url.toString(), expected);
      expect(target.url!.query, isEmpty);
      expect(target.url!.userInfo, isEmpty);
    }
    for (final listen in ['127.0.0.1', '127.0.0.1:0', '[::1]:65536']) {
      expect(
        webPanelTarget(
          HostSnapshot(state: HostState.running, clashApiListen: listen),
        ).problem,
        WebPanelProblem.unknown,
      );
    }
  });

  test('a platform without a host reports that it is unavailable', () async {
    final browser = _Browser();
    final h = await Harness.start(
      overrides: [browserProvider.overrideWithValue(browser)],
    );
    addTearDown(h.stop);
    expect(
      await h.container.read(settingsViewModelProvider).openWebPanel(),
      WebPanelProblem.unavailable,
    );
    expect(browser.opened, isEmpty);
  });

  group('settings action', () {
    late Harness h;
    late FakeHost host;
    late Directory dir;
    late _Browser browser;

    setUp(() async {
      dir = Directory.systemTemp.createTempSync('avalon-web-panel-');
      host = FakeHost(dir.path);
      browser = _Browser();
      h = await Harness.start(
        host: RuntimeHost(transport: host, system: host),
        overrides: [
          browserProvider.overrideWithValue(browser),
          runtimePollIntervalProvider.overrideWithValue(
            const Duration(days: 1),
          ),
          runtimeDebounceProvider.overrideWithValue(const Duration(days: 1)),
        ],
      );
      await h.container.read(runtimeProvider.notifier).ready;
    });
    tearDown(() async {
      await h.stop();
      dir.deleteSync(recursive: true);
    });

    Future<void> connect({bool controller = true}) async {
      await h.services.selfContent.addNode(
        const SelfNode(
          id: '',
          name: 'Test',
          server: 'example.com',
          port: 443,
          params: NodeParams.trojan(password: Secret('fake-test-password')),
        ),
      );
      await h.services.settings.updateDevice(
        (s) => s.copyWith(
          selectedConfigurationId: SelfSource.id,
          clashApi: controller,
        ),
      );
      await h.container.read(runtimeProvider.notifier).connect();
    }

    Future<WebPanelProblem?> open() =>
        h.container.read(settingsViewModelProvider).openWebPanel();

    test('not running or controller disabled explains why', () async {
      expect(await open(), WebPanelProblem.notRunning);
      await connect(controller: false);
      expect(await open(), WebPanelProblem.disabled);
      expect(browser.opened, isEmpty);
    });

    test(
      'a rejected reload still opens the previous actual controller',
      () async {
        await connect();
        host.reloadError = {'code': 'PLAN_INVALID', 'message': 'bad plan'};
        await h.services.settings.updateDevice(
          (s) => s.copyWith(clashApiListen: '127.0.0.1:9191', clashApi: false),
        );
        await h.container.read(runtimeProvider.notifier).sync();
        expect(await open(), isNull);
        expect(browser.opened.single.toString(), 'http://127.0.0.1:9090/ui');
      },
    );

    test(
      'a failed refresh never opens a previously reported address',
      () async {
        await connect();
        host.snapshotCallError = {
          'code': 'HOST_UNREACHABLE',
          'message': 'unreachable',
        };
        expect(await open(), WebPanelProblem.unknown);
        expect(browser.opened, isEmpty);
      },
    );

    test('browser refusal and platform exceptions are reported', () async {
      await connect();
      browser.succeeds = false;
      expect(await open(), WebPanelProblem.browserFailed);
      browser.throws = true;
      expect(await open(), WebPanelProblem.browserFailed);
    });
  });
}
