import 'package:avalon/platform/desktop/global_hotkeys.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('avalon/hotkeys');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'native registration distinguishes occupied and unsupported shortcuts',
    () async {
      final calls = <String>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        if (call.method == 'unregisterAll') return null;
        return switch (call.arguments) {
          'toggle' => 'registered',
          'mode' => 'taken',
          _ => 'unsupported',
        };
      });
      final hotkeys = NativeHotkeys();
      expect(
        await hotkeys.register(HotkeyAction.toggle, () {}),
        HotkeyResult.registered,
      );
      expect(
        await hotkeys.register(HotkeyAction.mode, () {}),
        HotkeyResult.taken,
      );
      expect(
        await hotkeys.register(HotkeyAction.show, () {}),
        HotkeyResult.unsupported,
      );
      await hotkeys.unregisterAll();
      expect(calls, ['register', 'register', 'register', 'unregisterAll']);
    },
  );

  test(
    'unknown native results are not reported as successful registration',
    () async {
      messenger.setMockMethodCallHandler(channel, (_) async => 'invalid');
      await expectLater(
        NativeHotkeys().register(HotkeyAction.toggle, () {}),
        throwsFormatException,
      );
    },
  );
}
