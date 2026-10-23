import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/cloud/sync_device_scenario.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const buildControl = String.fromEnvironment('AVALON_DEVICE_SYNC_CONTROL_URL');
  testWidgets(
    'Android half of isolated physical-device five-type sync acceptance',
    (tester) async {
      await tester.runAsync(() async {
        var control = buildControl;
        if (control.isEmpty) {
          // Only a test control URL is persisted here, never credentials.
          // Register the test synchronously; read runtime input in its body.
          final runtime = File(
            '/data/user/0/$deviceSyncApplicationId/files/sync-control-url',
          );
          if (await runtime.exists()) {
            try {
              control = (await runtime.readAsString()).trim();
            } finally {
              await runtime.delete();
            }
          }
        }
        if (control.isEmpty) {
          throw StateError('Device sync runtime control URL is missing.');
        }
        await runDeviceSyncScenario(controlUrl: control, role: 'peer');
      });
    },
    skip: !Platform.isAndroid,
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
