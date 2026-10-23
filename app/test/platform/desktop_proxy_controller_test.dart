import 'dart:io';

import 'package:avalon/app/desktop_proxy_controller.dart';
import 'package:avalon/platform/desktop/system_proxy.dart';
import 'package:avalon/runtime/runtime_coordinator.dart';
import 'package:avalon/runtime/runtime_host.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/harness.dart';
import '../runtime/fake_host.dart';

final class _Backend implements DesktopProxyBackend {
  @override
  String get name => 'test';
  final values = {'port': '8080'};
  bool fail = false;
  @override
  Future<Map<String, String>> read() async {
    if (fail) throw const SystemProxyException();
    return Map.of(values);
  }

  @override
  Map<String, String> target(int port) => {'port': '$port'};
  @override
  Future<void> write(
    Map<String, String> patch, {
    Map<String, String>? expected,
  }) async => values.addAll(patch);
}

void main() {
  test(
    'rejected port reload keeps proxy on accepted port; quit restores',
    () async {
      final dir = Directory.systemTemp.createTempSync('proxy-controller-');
      final host = FakeHost(dir.path);
      final backend = _Backend();
      Map<String, String>? journal;
      final manager = DesktopSystemProxy(
        backend: backend,
        readRecovery: () async => journal,
        saveRecovery: (v) async {
          journal = v;
        },
      );
      final h = await Harness.start(
        host: RuntimeHost(transport: host, system: host),
        overrides: [
          desktopSystemProxyProvider.overrideWithValue(manager),
          runtimePollIntervalProvider.overrideWithValue(
            const Duration(days: 1),
          ),
          runtimeDebounceProvider.overrideWithValue(
            const Duration(milliseconds: 10),
          ),
          desktopProxyPollIntervalProvider.overrideWithValue(
            const Duration(milliseconds: 30),
          ),
        ],
      );
      addTearDown(() async {
        await h.stop();
        dir.deleteSync(recursive: true);
      });
      final node = await h.services.imports.addFile(
        text: 'trojan://fixture@node.example:443#fixture',
        defaultName: 'fixture',
      );
      await h.services.settings.updateDevice(
        (s) => s.copyWith(
          selectedConfigurationId: node.configurationId,
          systemProxy: true,
          mixedPort: 7890,
        ),
      );
      final runtime = h.container.read(runtimeProvider.notifier);
      await runtime.ready;
      await runtime.connect();
      final controller = h.container.read(desktopProxyProvider.notifier);
      await controller.reconcile(force: true);
      expect(backend.values['port'], '7890');
      host.reloadError = {
        'code': 'invalidConfig',
        'message': 'fixture refused',
      };
      await h.services.settings.updateDevice(
        (s) => s.copyWith(mixedPort: 7891),
      );
      await h.settle(
        () => host.commands.where((c) => c.$1 == 'reload').length,
        (n) => n > 0,
      );
      await runtime.idle();
      await controller.reconcile(force: true);
      expect(h.container.read(runtimeProvider).activeMixedPort, 7890);
      expect(backend.values['port'], '7890');

      // An externally changed plan has no attested listener port.
      host.planHash = 'external-plan';
      await runtime.refresh();
      await controller.reconcile(force: true);
      expect(h.container.read(runtimeProvider).activeMixedPort, isNull);
      expect(h.container.read(desktopProxyProvider).known, isFalse);
      expect(h.container.read(desktopProxyProvider).active, isFalse);
      expect(backend.values['port'], '7890');
      host.reloadError = null;
      await runtime.sync();
      await controller.reconcile(force: true);
      expect(backend.values['port'], '7891');

      // A failed cleanup retains the journal; the next background check retries.
      backend.fail = true;
      await h.services.settings.updateDevice(
        (s) => s.copyWith(systemProxy: false),
      );
      await controller.reconcile(force: true);
      expect(h.container.read(desktopProxyProvider).failed, isTrue);
      expect(journal, isNotNull);
      backend.fail = false;
      await h.settle(() => backend.values['port'], (v) => v == '8080');
      expect(journal, isNull);

      await h.services.settings.updateDevice(
        (s) => s.copyWith(systemProxy: true),
      );
      await controller.reconcile(force: true);
      expect(backend.values['port'], '7891');
      expect(await controller.restoreForExit(), isTrue);
      // Even a still-running core cannot reapply proxy settings during quit.
      await controller.reconcile(force: true);
      expect(backend.values['port'], '8080');
      expect(journal, isNull);
    },
  );
}
