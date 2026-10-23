import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Starting with the user's session (PRODUCT_SPEC §3.9 «开机自动启动»,
/// RUNTIME_HOST §9): a login item on macOS, the Run key on Windows, an XDG
/// autostart entry on Linux. Our own rather than a plugin: the one in the
/// design (launch_at_startup) pins a win32 that share_plus cannot share.
abstract interface class LoginItem {
  /// Throws when the system refuses.
  Future<void> set({required bool enabled});

  static LoginItem host() => switch (defaultTargetPlatform) {
    TargetPlatform.macOS => const MacLoginItem(),
    TargetPlatform.windows => WindowsLoginItem(Platform.resolvedExecutable),
    TargetPlatform.linux => LinuxLoginItem(Platform.resolvedExecutable),
    _ => const NoLoginItem(),
  };
}

final class NoLoginItem implements LoginItem {
  const NoLoginItem();

  @override
  Future<void> set({required bool enabled}) async {}
}

/// SMAppService (macOS 13 and later), through the window's channel.
final class MacLoginItem implements LoginItem {
  const MacLoginItem();

  static const _channel = MethodChannel('avalon/login-item');

  @override
  Future<void> set({required bool enabled}) =>
      _channel.invokeMethod<void>('set', enabled);
}

/// `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`.
final class WindowsLoginItem implements LoginItem {
  const WindowsLoginItem(this.executable);

  final String executable;
  static const _key = r'HKCU\Software\Microsoft\Windows\CurrentVersion\Run';

  @override
  Future<void> set({required bool enabled}) async {
    final result = await Process.run(
      'reg',
      enabled
          ? [
              'add',
              _key,
              '/v',
              'Avalon',
              '/t',
              'REG_SZ',
              '/d',
              '"$executable"',
              '/f',
            ]
          : ['delete', _key, '/v', 'Avalon', '/f'],
    );
    // Deleting what is not there is fine.
    if (enabled && result.exitCode != 0) {
      throw ProcessException(
        'reg',
        const [],
        '${result.stderr}',
        result.exitCode,
      );
    }
  }
}

/// `$XDG_CONFIG_HOME/autostart/avalon.desktop`.
final class LinuxLoginItem implements LoginItem {
  LinuxLoginItem(this.executable, {String? configHome})
    : configHome =
          configHome ??
          Platform.environment['XDG_CONFIG_HOME'] ??
          '${Platform.environment['HOME']}/.config';

  final String executable;
  final String configHome;

  File get file => File('$configHome/autostart/avalon.desktop');

  @override
  Future<void> set({required bool enabled}) async {
    if (!enabled) {
      if (file.existsSync()) await file.delete();
      return;
    }
    await file.parent.create(recursive: true);
    await file.writeAsString(
      '[Desktop Entry]\n'
      'Type=Application\n'
      'Name=Avalon\n'
      'Exec="$executable"\n'
      'X-GNOME-Autostart-enabled=true\n',
    );
  }
}
