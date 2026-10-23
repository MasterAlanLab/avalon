// What the per-app page can list on each platform (PRODUCT_SPEC §3.11).
import 'dart:io';

import 'package:avalon/platform/installed_apps.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('macOS', () {
    late Directory root;
    setUp(() {
      // Resolved: the temp directory is itself behind a link on macOS.
      root = Directory(
        Directory.systemTemp.createTempSync('apps').resolveSymbolicLinksSync(),
      );
    });
    tearDown(() => root.deleteSync(recursive: true));

    Directory bundle(String path) =>
        Directory('${root.path}/$path')..createSync(recursive: true);

    test('finds bundles in the folders and one level below', () async {
      bundle('Applications/Safari.app/Contents/MacOS');
      bundle('Applications/Utilities/Terminal.app');
      bundle('Applications/Vendor/Suite/Deep.app');
      bundle('Applications/.Hidden.app');
      bundle('Applications/Notes'); // Not a bundle.
      // A bundle's helpers are not programs of their own.
      bundle('Applications/Safari.app/Contents/Helpers/Helper.app');

      final apps = await MacInstalledApps(
        roots: ['${root.path}/Applications', '${root.path}/Missing'],
        self: '/elsewhere/avalon.app/Contents/MacOS/avalon',
      ).list();

      expect(
        {for (final app in apps) app.name: app.id},
        {
          'Safari': '${root.path}/Applications/Safari.app',
          'Terminal': '${root.path}/Applications/Utilities/Terminal.app',
        },
      );
    });

    test('a link is listed once, by the path the process runs from', () async {
      final real = bundle('System/Cryptex/Safari.app');
      Directory('${root.path}/Applications').createSync();
      Link('${root.path}/Applications/Safari.app').createSync(real.path);
      Link('${root.path}/Applications/Gone.app').createSync('/nowhere.app');

      final apps = await MacInstalledApps(
        roots: ['${root.path}/Applications', '${root.path}/System/Cryptex'],
        self: '/elsewhere/avalon',
      ).list();

      expect([for (final app in apps) app.id], [real.path]);
      expect(apps.single.name, 'Safari');
    });

    test('this app is not offered', () async {
      final own = bundle('Applications/avalon.app/Contents/MacOS');
      bundle('Applications/Other.app');

      final apps = await MacInstalledApps(
        roots: ['${root.path}/Applications'],
        self: '${own.path}/avalon',
      ).list();

      expect([for (final app in apps) app.name], ['Other']);
    });
  });

  group('native app list', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    const channel = MethodChannel('dev.avalon/apps');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    tearDown(() => messenger.setMockMethodCallHandler(channel, null));

    test('native package IDs and executable paths are preserved', () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'list');
        return [
          {'id': 'org.telegram.messenger', 'name': 'Telegram', 'system': false},
          {
            'id': r'C:\Program Files\Browser\browser.exe',
            'name': 'Browser',
            'system': true,
          },
        ];
      });

      final apps = await const ChannelInstalledApps().list();

      expect(apps.map((a) => a.id), [
        'org.telegram.messenger',
        r'C:\Program Files\Browser\browser.exe',
      ]);
      expect(apps.map((a) => a.name), ['Telegram', 'Browser']);
      expect(apps.map((a) => a.system), [false, true]);
    });
  });
}
