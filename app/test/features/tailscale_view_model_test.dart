import 'dart:convert';
import 'dart:io';

import 'package:avalon/app/providers.dart';
import 'package:avalon/features/tailscale/tailscale_view_model.dart';
import 'package:avalon/platform/browser.dart';
import 'package:avalon/runtime/host_gateway.dart';
import 'package:avalon/runtime/runtime_coordinator.dart';
import 'package:avalon/runtime/runtime_host.dart';
import 'package:flutter_test/flutter_test.dart';

import '../runtime/fake_host.dart';
import 'harness.dart';

final class _Browser implements Browser {
  final opened = <Uri>[];
  @override
  Future<bool> open(Uri url) async {
    opened.add(url);
    return true;
  }
}

final class _TailnetTransport implements HostTransport {
  _TailnetTransport(this.host);
  final FakeHost host;
  String loginUrl = 'https://login.tailscale.com/a/fixture';
  bool loginFails = false;
  @override
  Future<String> call(String command, String request) async {
    if (command == 'tailnetLogin' && loginFails) {
      return jsonEncode({
        'error': {'code': 'CORE_FAILED', 'message': 'account operation failed'},
      });
    }
    if (command.startsWith('tailnet')) {
      return jsonEncode({
        'result': {
          'state': 'NeedsLogin',
          'loginUrl': loginUrl,
          'peers': <Object?>[],
        },
      });
    }
    return host.call(command, request);
  }
}

void main() {
  late Harness h;
  late Directory dir;
  late _TailnetTransport transport;
  late _Browser browser;
  late TailscaleViewModel model;
  setUp(() async {
    dir = Directory.systemTemp.createTempSync('tailnet-vm');
    final host = FakeHost(dir.path);
    transport = _TailnetTransport(host);
    browser = _Browser();
    h = await Harness.start(
      host: RuntimeHost(transport: transport, system: host),
      overrides: [
        browserProvider.overrideWithValue(browser),
        runtimePollIntervalProvider.overrideWithValue(const Duration(days: 1)),
      ],
    );
    h.container.listen(tailscaleViewModelProvider, (_, _) {});
    model = h.container.read(tailscaleViewModelProvider.notifier);
    await h.container.read(runtimeProvider.notifier).ready;
  });
  tearDown(() async {
    await h.stop();
    dir.deleteSync(recursive: true);
  });

  test(
    'enabling starts a real runtime plan and opens only its authorized login',
    () async {
      await model.setEnabled(true);
      expect(browser.opened.single.host, 'login.tailscale.com');
      expect(h.container.read(runtimeProvider).proxyConnected, isFalse);
      expect((await h.services.settings.device()).tailnet.enabled, isTrue);
      await model.setEnabled(false);
      expect(h.container.read(runtimeProvider).connected, isFalse);
    },
  );

  test('an untrusted authorization URL never reaches the browser', () async {
    transport.loginUrl = 'https://login.tailscale.com.evil.example/a';
    await model.setEnabled(true);
    expect(browser.opened, isEmpty);
    expect(h.container.read(tailscaleViewModelProvider).browserFailed, isTrue);
  });

  test('a login failure remains visible after the status refresh', () async {
    await model.setEnabled(true);
    transport.loginFails = true;
    await model.login();
    expect(
      h.container.read(tailscaleViewModelProvider).error,
      'account operation failed',
    );
    await model.refresh();
    expect(
      h.container.read(tailscaleViewModelProvider).error,
      'account operation failed',
    );
  });

  test('an unverified local exit is not silently saved', () async {
    await model.setEnabled(true);
    await model.setAdvertiseExit(true);
    expect((await h.services.settings.device()).tailnet.advertiseExit, isFalse);
    expect(h.container.read(tailscaleViewModelProvider).error, isNotNull);
  });

  test(
    'clearing an old advertised exit restores the enabled Tailnet',
    () async {
      await h.services.settings.updateDevice(
        (s) => s.copyWith(tailnet: s.tailnet.copyWith(advertiseExit: true)),
      );
      await model.setEnabled(true);
      expect(h.container.read(runtimeProvider).connected, isFalse);
      expect(h.container.read(runtimeProvider).failure, isNotNull);
      await model.setAdvertiseExit(false);
      expect(h.container.read(runtimeProvider).connected, isTrue);
      expect(h.container.read(runtimeProvider).failure, isNull);
      expect(
        (await h.services.settings.device()).tailnet.advertiseExit,
        isFalse,
      );
    },
  );
}
