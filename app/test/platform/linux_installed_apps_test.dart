import 'dart:io';

import 'package:avalon/platform/installed_apps.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  setUp(() {
    dir = Directory(
      Directory.systemTemp
          .createTempSync('linux-apps-')
          .resolveSymbolicLinksSync(),
    );
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<String> executable(String name) async {
    final file = File('${dir.path}/bin/$name');
    await file.parent.create(recursive: true);
    await file.writeAsString('fixture, not executable code');
    final result = await Process.run('/bin/chmod', ['700', file.path]);
    expect(result.exitCode, 0);
    return file.path;
  }

  Future<void> entry(String root, String id, String content) async {
    final file = File('${dir.path}/$root/$id.desktop');
    await file.parent.create(recursive: true);
    await file.writeAsString('[Desktop Entry]\nType=Application\n$content\n');
  }

  LinuxInstalledApps listing() => LinuxInstalledApps(
    roots: ['${dir.path}/user', '${dir.path}/system'],
    environment: {
      'PATH': '${dir.path}/bin',
      'LANG': 'zh_CN.UTF-8',
      'XDG_CURRENT_DESKTOP': 'GNOME:Unity',
    },
    self: '${dir.path}/bin/avalon',
  );

  test(
    'uses resolved executables, localized names, quotes and env launchers',
    () async {
      final quoted = await executable('With Spaces');
      final browser = await executable('browser');
      await entry(
        'system',
        'quoted',
        'Name=Default\nName[zh_CN]=程序\nExec="$quoted" %U',
      );
      await entry(
        'user',
        'browser',
        'Name=Browser\nExec=/usr/bin/env MODE=test browser %u',
      );
      final apps = await listing().list();
      expect(
        {for (final app in apps) app.name: app.id},
        {'程序': quoted, 'Browser': browser},
      );
    },
  );

  test(
    'user Hidden entry masks system entry and unavailable apps are omitted',
    () async {
      final browser = await executable('browser');
      await executable('avalon');
      await entry('user', 'hidden', 'Hidden=true\nName=Hidden\nExec=browser');
      await entry('system', 'hidden', 'Name=System\nExec=browser');
      await entry(
        'system',
        'nodisplay',
        'NoDisplay=true\nName=Hidden\nExec=browser',
      );
      await entry('system', 'missing', 'Name=Missing\nExec=missing');
      await entry(
        'system',
        'tryexec',
        'Name=Absent\nTryExec=missing\nExec=browser',
      );
      await entry('system', 'kde', 'Name=KDE\nOnlyShowIn=KDE;\nExec=browser');
      await entry('system', 'own', 'Name=Avalon\nExec=avalon');
      await entry(
        'system',
        'visible',
        'Name=Visible\nNotShowIn=KDE;\nExec=browser',
      );
      final apps = await listing().list();
      expect(apps.single.id, browser);
      expect(apps.single.name, 'Visible');
    },
  );

  test('deduplicates links and never executes launcher syntax', () async {
    final browser = await executable('browser');
    await Link('${dir.path}/bin/browser-link').create(browser);
    await entry('user', 'one', 'Name=One\nExec=browser');
    await entry('system', 'two', 'Name=Two\nExec=browser-link');
    await entry('system', 'broken', 'Name=Bad\nExec="browser');
    await entry('system', 'substitution', 'Name=Bad\nExec=\$(browser)');
    final apps = await listing().list();
    expect(apps.length, 1);
    expect(apps.single.id, browser);
  });
}
