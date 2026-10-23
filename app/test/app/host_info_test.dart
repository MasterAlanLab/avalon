import 'package:av_core/av_core.dart';
import 'package:avalon/app/services.dart';
import 'package:avalon/data/database/database.dart';
import 'package:avalon/data/vault/vault.dart';
import 'package:avalon/runtime/runtime_host.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dev.avalon/host');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  Future<AppServices> services() => AppServices.open(
    database: AppDatabase(NativeDatabase.memory()),
    keyStore: MemoryKeyStore(),
  );

  test(
    'iOS compilation facts use iOS and the App Group host directory',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'facts');
        return {'stateDir': '/shared/host', 'deviceName': 'iPhone'};
      });
      final app = await services();
      addTearDown(app.close);
      final facts = await app.plans.host();
      expect(
        (facts.platform, facts.stateDir, facts.deviceName),
        (HostPlatform.ios, '/shared/host', 'iPhone'),
      );
    },
  );

  test('Linux compilation facts no longer claim to be Android', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final app = await services();
    addTearDown(app.close);
    final facts = await app.plans.host();
    final expected = await RuntimeHost.ofThisPlatform()!.system.facts();
    expect(facts.platform, HostPlatform.linux);
    expect(facts.stateDir, expected.stateDir);
    expect(facts.deviceName, expected.deviceName);
  });
}
