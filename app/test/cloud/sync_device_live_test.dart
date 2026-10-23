import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'sync_device_scenario.dart';

void main() {
  final control = Platform.environment['AVALON_DEVICE_SYNC_CONTROL_URL'] ?? '';
  test(
    'computer half of isolated physical-device five-type sync acceptance',
    () => runDeviceSyncScenario(controlUrl: control, role: 'sender'),
    skip: control.isEmpty ? 'Requires an isolated device sync fixture.' : false,
    timeout: const Timeout(Duration(minutes: 10)),
  );
}
