import 'dart:async';
import 'dart:io';

import 'package:avalon/platform/desktop/single_instance.dart';
import 'package:flutter_test/flutter_test.dart';

File _dartExecutable() {
  var directory = File(Platform.resolvedExecutable).parent;
  while (directory.parent.path != directory.path) {
    final candidate = File(
      '${directory.path}/dart-sdk/bin/dart${Platform.isWindows ? '.exe' : ''}',
    );
    if (candidate.existsSync()) return candidate;
    directory = directory.parent;
  }
  throw StateError('Cannot locate the Dart SDK beside flutter_tester.');
}

void main() {
  test(
    'a second process shows the first window and finishes promptly',
    () async {
      final directory = Directory.systemTemp.createTempSync('avalon-instance-');
      addTearDown(() => directory.deleteSync(recursive: true));
      final shown = Completer<void>();
      final instance = await SingleInstance.claim(
        directory.path,
        onShow: shown.complete,
      );
      expect(instance, isNotNull);
      addTearDown(instance!.release);
      final process = await Process.start(_dartExecutable().path, [
        '--packages=${File('../.dart_tool/package_config.json').absolute.path}',
        File('test/platform/single_instance_probe.dart').absolute.path,
        directory.path,
      ]);
      addTearDown(() => process.kill());
      final errors = process.stderr
          .transform(const SystemEncoding().decoder)
          .join();
      unawaited(process.stdout.drain<void>());
      expect(
        await process.exitCode.timeout(const Duration(seconds: 10)),
        0,
        reason: await errors,
      );
      await shown.future.timeout(const Duration(seconds: 2));
    },
  );
}
