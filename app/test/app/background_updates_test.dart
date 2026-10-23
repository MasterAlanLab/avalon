// The background run (D75): what is due is downloaded, a running session
// is reloaded for it, and the proxy is never started.
import 'dart:convert';
import 'dart:io';

import 'package:avalon/app/background_updates.dart';
import 'package:avalon/app/subscription_updates.dart';
import 'package:avalon/data/database/database.dart';
import 'package:avalon/runtime/runtime_coordinator.dart';
import 'package:avalon/runtime/runtime_host.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../features/harness.dart';
import '../runtime/fake_host.dart';

const _one = 'trojan://fake-a@a.example.com:443#A\n';
const _two =
    '$_one'
    'trojan://fake-b@b.example.com:443#B\n';

void main() {
  late Harness h;
  late FakeHost host;
  late Directory dir;
  late String id;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('background');
    host = FakeHost(dir.path);
    h = await Harness.start(
      host: RuntimeHost(transport: host, system: host),
      overrides: [
        runtimeConnectAtLaunchProvider.overrideWithValue(false),
        runtimePollIntervalProvider.overrideWithValue(const Duration(days: 1)),
        runtimeDebounceProvider.overrideWithValue(
          const Duration(milliseconds: 30),
        ),
      ],
    );
    h.body = _one;
    id = (await h.services.imports.addSubscription(
      url: '${h.base}/sub',
      defaultName: '订阅',
    )).configurationId;
    await h.services.settings.updateDevice(
      (s) => s.copyWith(selectedConfigurationId: id),
    );
  });

  tearDown(() async {
    await h.stop();
    dir.deleteSync(recursive: true);
  });

  /// The subscription was last downloaded 13 hours ago.
  Future<void> age() async {
    final db = h.services.db;
    await (db.update(db.configurations)..where((c) => c.id.equals(id))).write(
      ConfigurationsCompanion(
        lastSuccessAt: Value(
          DateTime.now()
              .subtract(const Duration(hours: 13))
              .millisecondsSinceEpoch,
        ),
      ),
    );
  }

  test('a due subscription is downloaded and the session reloaded', () async {
    final runtime = h.container.read(runtimeProvider.notifier);
    await runtime.ready;
    await runtime.connect();
    await runtime.idle();
    host.commands.clear();

    h.body = _two;
    await age();
    // A new engine: the services start over.
    h.container.invalidate(subscriptionUpdaterProvider);
    await updateInBackground(h.container);

    expect(host.sent, contains('reload'));
    final plan =
        jsonDecode(File('${dir.path}/plan.json').readAsStringSync()) as Map;
    expect(jsonEncode(plan), contains('b.example.com'));
  });

  test('«启动后自动连接» does not start the proxy from the background', () async {
    await h.services.settings.updateDevice(
      (s) => s.copyWith(autoConnect: true),
    );
    h.container.invalidate(runtimeProvider);
    await updateInBackground(h.container);
    expect(host.sent, isNot(contains('start')));
  });
}
