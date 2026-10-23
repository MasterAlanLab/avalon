// Optional real Linux session-settings acceptance from a macOS/Linux host.
// app/linux/tool/check_system_proxy.sh provisions the disposable DBus/dconf
// container. The Dart backend executes its actual gsettings argument lists
// inside that session; no proxy settings on the host are read or changed.
import 'dart:io';

import 'package:avalon/platform/desktop/system_proxy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final container = Platform.environment['AVALON_GNOME_CONTAINER'];
  final docker = Platform.environment['AVALON_DOCKER'] ?? 'docker';
  final enabled = container != null && container.isNotEmpty;
  final reason = enabled ? false : 'run app/linux/tool/check_system_proxy.sh';
  Future<ProcessResult> native(String executable, List<String> arguments) =>
      Process.run(docker, [
        'exec',
        '--env',
        'DBUS_SESSION_BUS_ADDRESS=unix:path=/home/avalon-test/bus',
        container!,
        executable,
        ...arguments,
      ]);
  final backend = GnomeProxyBackend(
    environment: const {'XDG_CURRENT_DESKTOP': 'GNOME'},
    run: native,
  );
  const schema = 'org.gnome.system.proxy';

  Future<String> gsettings(List<String> arguments) async {
    final result = await native('gsettings', arguments);
    expect(result.exitCode, 0, reason: 'native gsettings command failed');
    return (result.stdout as String).trim();
  }

  Future<void> set(String owner, String key, String value) async {
    await gsettings(['set', owner, key, value]);
  }

  Future<Map<String, String>> initialize({String mode = "'auto'"}) async {
    await backend.write({
      'http.host': "'original-http.example'",
      'http.port': '3128',
      'http.use-authentication': 'true',
      'https.host': "'original-https.example'",
      'https.port': '4443',
      'socks.host': "'original-socks.example'",
      'socks.port': '1080',
      'use-same-proxy': 'true',
      'mode': mode,
    });
    await set(schema, 'autoconfig-url', "'https://pac.example.test/original'");
    await set('$schema.http', 'authentication-user', "'fixture-user'");
    await set('$schema.http', 'authentication-password', "'fixture-value'");
    return backend.read();
  }

  test(
    'real schema supports every backend key and restores original PAC/authentication settings',
    () async {
      final keys = await gsettings(['list-keys', schema]);
      expect(keys.split('\n'), contains('use-same-proxy'));
      expect(
        (await gsettings(['list-keys', '$schema.http'])).split('\n'),
        contains('use-authentication'),
      );
      final before = await initialize();
      Map<String, String>? recovery;
      DesktopSystemProxy create() => DesktopSystemProxy(
        backend: backend,
        readRecovery: () async => recovery,
        saveRecovery: (value) async => recovery = value,
      );
      await create().apply(7890);
      expect(await create().active(7890), isTrue);
      expect(await backend.read(), backend.target(7890));
      expect(
        await gsettings(['get', schema, 'autoconfig-url']),
        "'https://pac.example.test/original'",
      );
      expect(
        await gsettings(['get', '$schema.http', 'authentication-user']),
        "'fixture-user'",
      );
      expect(
        await gsettings(['get', '$schema.http', 'authentication-password']),
        "'fixture-value'",
      );
      await create().restore();
      expect(await backend.read(), before);
      expect(recovery, isNull);
    },
    skip: reason,
  );

  test(
    'real external endpoint and port edits retain the complete proxy group',
    () async {
      for (final entry in {
        'host': "'user-proxy.example'",
        'port': '9090',
      }.entries) {
        await initialize();
        Map<String, String>? recovery;
        final proxy = DesktopSystemProxy(
          backend: backend,
          readRecovery: () async => recovery,
          saveRecovery: (value) async => recovery = value,
        );
        await proxy.apply(7890);
        await set('$schema.http', entry.key, entry.value);
        final userSelected = await backend.read();
        await proxy.restore();
        expect(await backend.read(), userSelected);
        expect(recovery, isNull);
      }
    },
    skip: reason,
  );

  test(
    'real mode and PAC edits preserve the users selected automatic proxy',
    () async {
      await initialize(mode: "'none'");
      Map<String, String>? recovery;
      final proxy = DesktopSystemProxy(
        backend: backend,
        readRecovery: () async => recovery,
        saveRecovery: (value) async => recovery = value,
      );
      await proxy.apply(7890);
      const newPac = "'https://pac.example.test/user-selected'";
      await set(schema, 'autoconfig-url', newPac);
      await set(schema, 'mode', "'auto'");
      final userSelected = await backend.read();
      await proxy.restore();
      expect(await backend.read(), userSelected);
      expect(await gsettings(['get', schema, 'autoconfig-url']), newPac);
      expect(recovery, isNull);
    },
    skip: reason,
  );
}
