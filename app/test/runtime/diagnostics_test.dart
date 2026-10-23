// The logs and connections pages against a host that behaves like the
// Core Bridge (PRODUCT_SPEC §3.8).
import 'dart:convert';
import 'dart:io';

import 'package:avalon/features/diagnostics/connections_state.dart';
import 'package:avalon/features/diagnostics/connections_view_model.dart';
import 'package:avalon/features/diagnostics/logs_state.dart';
import 'package:avalon/features/diagnostics/logs_view_model.dart';
import 'package:avalon/runtime/runtime_coordinator.dart';
import 'package:avalon/runtime/runtime_host.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/harness.dart';
import 'fake_host.dart';

const _clash = '''
proxies:
  - {name: 香港, type: trojan, server: a.example.com, port: 443, password: fake-a}
proxy-groups:
  - {name: 节点选择, type: select, proxies: [香港, DIRECT]}
rules:
  - MATCH,节点选择
''';

Map<String, Object?> _line(int seq, String level, String message) => {
  'seq': seq,
  'time': DateTime(2026, 10, 10, 13, 0, seq).millisecondsSinceEpoch,
  'level': level,
  'message': message,
};

void main() {
  late Harness h;
  late FakeHost host;
  late Directory dir;

  Future<void> start({bool withHost = true}) async {
    dir = Directory.systemTemp.createTempSync('diagnostics');
    host = FakeHost(dir.path);
    h = await Harness.start(
      host: withHost ? RuntimeHost(transport: host, system: host) : null,
      overrides: [
        runtimePollIntervalProvider.overrideWithValue(
          const Duration(milliseconds: 20),
        ),
      ],
    );
    h.body = _clash;
    final added = await h.services.imports.addSubscription(
      url: '${h.base}/sub',
      defaultName: '新订阅',
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

  group('logs', () {
    LogsState logs() => h.container.read(logsViewModelProvider);

    test(
      'read on opening, then followed while running; newest first',
      () async {
        await start();
        host.logs = [
          _line(1, 'error', 'initialize rule-set[0]: i/o timeout'),
          _line(2, 'info', 'sing-box started'),
        ];
        h.container.listen(logsViewModelProvider, (_, _) {});
        var s = await h.settle(logs, (s) => s.entries.length == 2);
        expect(s.shown.map((e) => e.seq), [2, 1]);
        expect(s.entries.first.time, DateTime(2026, 10, 10, 13, 0, 1));

        // Not running: nothing more is asked.
        host.logs.add(_line(3, 'info', 'late'));
        await Future<void>.delayed(const Duration(milliseconds: 80));
        expect(logs().entries, hasLength(2));

        // Running: new lines arrive, only the new ones are asked for.
        await h.container.read(runtimeProvider.notifier).connect();
        s = await h.settle(logs, (s) => s.entries.length == 3);
        final asked = [
          for (final c in host.commands)
            if (c.$1 == 'logs') c.$2['afterSeq'],
        ];
        expect(asked.first, 0);
        expect(asked.skip(1), everyElement(greaterThanOrEqualTo(2)));
        expect(s.shown.first.message, 'late');
      },
    );

    test('the export is the whole buffer, redacted', () async {
      await start();
      host.logs = [
        _line(
          1,
          'info',
          'fetch https://user:secret@sub.example.com/s?token=abc',
        ),
        _line(2, 'debug', 'dns: exchanged example.com'),
      ];
      h.container.listen(logsViewModelProvider, (_, _) {});
      await h.settle(logs, (s) => s.entries.length == 2);
      final model = h.container.read(logsViewModelProvider.notifier)
        ..setFilter(LogFilter.info);
      final file = model.export(
        platform: 'android',
        now: DateTime(2026, 10, 10, 13, 30),
      );
      expect(file.name, 'avalon-log-20261010-133000.txt');
      final text = utf8.decode(file.bytes);
      expect(text, startsWith('Avalon '));
      expect(text, contains('· android'));
      // Every line, not only the level on show.
      expect(text, contains('dns: exchanged example.com'));
      expect(text, contains('2026-10-10 13:00:01 INFO '));
      expect(text, isNot(contains('secret')));
      expect(text, isNot(contains('abc')));
    });
  });

  group('connections', () {
    ConnectionsState page() => h.container.read(connectionsStateProvider);

    Future<String> tagOf(String name) async {
      final plan = await h.services.plans.compileSelected();
      return plan.tags.entries.firstWhere((e) => e.value.name == name).key;
    }

    test(
      'nothing while stopped; while running, rows in the user\'s names',
      () async {
        await start();
        h.container.listen(connectionsStateProvider, (_, _) {});
        expect(page().connected, isFalse);
        expect(page().rows, isEmpty);

        await h.container.read(runtimeProvider.notifier).connect();
        host.connections = [
          {
            'id': 'c1',
            'host': 'github.com:443',
            'network': 'tcp',
            'process': 'org.example.browser',
            'rule': '',
            'chain': [await tagOf('节点选择'), await tagOf('香港')],
            'upload': 2048,
            'download': 1048576,
            'createdAt': 1,
          },
          {
            'id': 'c2',
            'host': '223.5.5.5:53',
            'chain': ['direct'],
            'rule': 'rule_set=geosite-cn',
          },
        ];
        final s = await h.settle(page, (s) => s.rows.length == 2);
        expect(s.connected, isTrue);
        final row = s.rows.first;
        expect(
          (row.host, row.app, row.rule),
          ('github.com:443', 'org.example.browser', ''),
        );
        expect(row.route, ['节点选择', '香港']);
        expect((row.upload, row.download), (2048, 1048576));
        expect(s.rows.last.route, ['DIRECT']);
      },
    );

    test('closing one, and closing all', () async {
      await start();
      h.container.listen(connectionsStateProvider, (_, _) {});
      await h.container.read(runtimeProvider.notifier).connect();
      host.connections = [
        {'id': 'c1', 'host': 'a.com:443', 'chain': []},
        {'id': 'c2', 'host': 'b.com:443', 'chain': []},
      ];
      await h.settle(page, (s) => s.rows.length == 2);
      final model = h.container.read(connectionsViewModelProvider.notifier);
      await model.close('c1');
      expect(page().rows.map((r) => r.id), ['c2']);
      final sent = host.commands.lastWhere((c) => c.$1 == 'closeConnection').$2;
      expect(sent['id'], 'c1');

      await model.closeAll();
      expect(page().rows, isEmpty);
      expect(host.commands.map((c) => c.$1), contains('closeAllConnections'));
      expect(page().connected, isTrue);
    });

    test('stopping empties the page', () async {
      await start();
      h.container.listen(connectionsStateProvider, (_, _) {});
      final coordinator = h.container.read(runtimeProvider.notifier);
      await coordinator.connect();
      host.connections = [
        {'id': 'c1', 'host': 'a.com:443', 'chain': []},
      ];
      await h.settle(page, (s) => s.rows.isNotEmpty);
      await coordinator.disconnect();
      final s = await h.settle(page, (s) => !s.connected);
      expect(s.rows, isEmpty);
    });
  });
}
