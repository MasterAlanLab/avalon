import 'dart:async';
import 'dart:ui' show AppExitResponse;

import 'package:avalon/platform/desktop/desktop_window.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('window_manager');
  final messenger = binding.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('a startup error window can exit without an active shell', () async {
    final destroyed = Completer<void>();
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'destroy') destroyed.complete();
      return null;
    });
    final window = WindowManagerWindow();
    await window.setup();
    expect(await binding.handleRequestAppExit(), AppExitResponse.exit);
    window.onWindowClose();
    await destroyed.future;
  });

  test(
    'system exit waits for the shell instead of closing immediately',
    () async {
      final calls = <String>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        return null;
      });
      final window = WindowManagerWindow();
      await window.setup();
      final requested = Completer<void>();
      final subscription = window.quitRequests.listen(
        (_) => requested.complete(),
      );
      expect(await binding.handleRequestAppExit(), AppExitResponse.cancel);
      await requested.future;
      expect(calls, isNot(contains('destroy')));

      await window.quit();
      expect(calls.last, 'destroy');
      expect(await binding.handleRequestAppExit(), AppExitResponse.exit);
      await subscription.cancel();
    },
  );
}
