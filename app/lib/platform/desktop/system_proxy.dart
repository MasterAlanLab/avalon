import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';

/// OS values are opaque strings so original PAC settings and credentials
/// can be restored exactly. They only enter the encrypted recovery record.
abstract interface class DesktopProxyBackend {
  String get name;
  Future<Map<String, String>> read();
  Map<String, String> target(int port);
  Future<void> write(
    Map<String, String> values, {
    Map<String, String>? expected,
  });
}

final class SystemProxyOwnershipChanged implements Exception {
  const SystemProxyOwnershipChanged();
}

void _checkExpected(
  Map<String, String> current,
  Map<String, String>? expected,
) {
  if (expected != null &&
      expected.entries.any((e) => current[e.key] != e.value)) {
    throw const SystemProxyOwnershipChanged();
  }
}

final class SystemProxyException implements Exception {
  const SystemProxyException();
  @override
  String toString() => 'SystemProxyException';
}

/// Owns settings only while their current values still match ours. Every
/// write has a durable encrypted intent, including partially failed writes.
final class DesktopSystemProxy {
  DesktopSystemProxy({
    required this.backend,
    required this.readRecovery,
    required this.saveRecovery,
  });
  final DesktopProxyBackend backend;
  final Future<Map<String, String>?> Function() readRecovery;
  final Future<void> Function(Map<String, String>?) saveRecovery;

  Future<bool> active(int port) async {
    final target = backend.target(port);
    final current = await backend.read();
    return target.entries.every((e) => current[e.key] == e.value);
  }

  Future<void> apply(int port) async {
    if (port < 1024 || port > 65535) throw const SystemProxyException();
    final old = await readRecovery();
    if (old != null) {
      final journal = _journal(old);
      if (journal.applied.entries.every(
            (e) => backend.target(port)[e.key] == e.value,
          ) &&
          await active(port)) {
        return;
      }
      await restore();
    }
    final before = await backend.read();
    final applied = backend.target(port);
    if (applied.keys.any((key) => !before.containsKey(key))) {
      throw const SystemProxyException();
    }
    await saveRecovery({
      'journal': jsonEncode({
        'version': 1,
        'backend': backend.name,
        'before': {for (final key in applied.keys) key: before[key]},
        'applied': applied,
      }),
    });
    try {
      await backend.write(
        applied,
        expected: {for (final key in applied.keys) key: before[key]!},
      );
      if (!await active(port)) throw const SystemProxyException();
    } on Object {
      try {
        await restore();
      } on Object {
        /* Recovery remains durable. */
      }
      throw const SystemProxyException();
    }
  }

  Future<void> restore() async {
    final saved = await readRecovery();
    if (saved == null) return;
    final journal = _journal(saved);
    final current = await backend.read();
    // Proxy mode and endpoint are one semantic group: restoring only the
    // mode after the user chose another host would disable their new proxy.
    // Original values are allowed for writes interrupted halfway through.
    final changedExternally = journal.applied.entries.any(
      (e) =>
          current[e.key] != e.value && current[e.key] != journal.before[e.key],
    );
    if (changedExternally) {
      await saveRecovery(null);
      return;
    }
    final owned = {
      for (final entry in journal.applied.entries)
        if (current[entry.key] == entry.value)
          entry.key: journal.before[entry.key]!,
    };
    if (owned.isNotEmpty) {
      try {
        await backend.write(
          owned,
          expected: {
            for (final key in journal.applied.keys) key: current[key]!,
          },
        );
      } on SystemProxyOwnershipChanged {
        await saveRecovery(null);
        return;
      }
      final confirmed = await backend.read();
      if (owned.entries.any((e) => confirmed[e.key] != e.value)) {
        throw const SystemProxyException();
      }
    }
    await saveRecovery(null);
  }

  ({Map<String, String> before, Map<String, String> applied}) _journal(
    Map<String, String> value,
  ) {
    try {
      final data = jsonDecode(value['journal']!) as Map<String, dynamic>;
      final before = (data['before'] as Map).cast<String, String>();
      final applied = (data['applied'] as Map).cast<String, String>();
      if (data['version'] != 1 ||
          data['backend'] != backend.name ||
          before.length != applied.length ||
          applied.isEmpty ||
          applied.keys.any((k) => !before.containsKey(k)) ||
          applied.keys.any((k) => !backend.target(7890).containsKey(k))) {
        throw const SystemProxyException();
      }
      return (before: before, applied: applied);
    } on Object {
      throw const SystemProxyException();
    }
  }
}

final class WindowsProxyBackend implements DesktopProxyBackend {
  const WindowsProxyBackend();
  static const _channel = MethodChannel('avalon/system-proxy');
  @override
  String get name => 'wininet';
  @override
  Future<Map<String, String>> read() async {
    final result = await _channel.invokeMapMethod<String, Object?>('read');
    if (result == null ||
        result['flags'] is! int ||
        ['server', 'bypass', 'autoConfig'].any((k) => result[k] is! String)) {
      throw const SystemProxyException();
    }
    return {
      for (final key in ['flags', 'server', 'bypass', 'autoConfig'])
        key: result[key].toString(),
    };
  }

  @override
  Map<String, String> target(int port) => {
    'flags': '3',
    'server':
        'http=127.0.0.1:$port;https=127.0.0.1:$port;socks=127.0.0.1:$port',
    'bypass': '<local>;localhost;127.*;[::1]',
    'autoConfig': '',
  };
  @override
  Future<void> write(
    Map<String, String> values, {
    Map<String, String>? expected,
  }) async {
    // The native API updates the full option list; read untouched values
    // immediately before writing so per-field restoration preserves edits.
    final current = await read();
    _checkExpected(current, expected);
    final merged = {...current, ...values};
    final flags = int.tryParse(merged['flags']!);
    if (flags == null || flags < 0 || flags > 15) {
      throw const SystemProxyException();
    }
    try {
      await _channel.invokeMethod<void>('write', {
        ...merged,
        'flags': flags,
        if (expected != null)
          'expected': {
            ...expected,
            if (expected.containsKey('flags'))
              'flags': int.parse(expected['flags']!),
          },
      });
    } on PlatformException catch (e) {
      if (e.code == 'system_proxy_changed') {
        throw const SystemProxyOwnershipChanged();
      }
      throw const SystemProxyException();
    }
  }
}

/// GNOME's session settings. Other desktops fail visibly instead of
/// claiming to have set a proxy which their applications never use.
final class GnomeProxyBackend implements DesktopProxyBackend {
  GnomeProxyBackend({
    Future<ProcessResult> Function(String, List<String>)? run,
    Map<String, String>? environment,
  }) : _run =
           run ??
           ((executable, arguments) => Process.run(executable, arguments)),
       _supported =
           (environment ?? Platform.environment)['XDG_CURRENT_DESKTOP']
               ?.toUpperCase()
               .split(':')
               .any((v) => v == 'GNOME' || v == 'UNITY') ??
           false;
  final Future<ProcessResult> Function(String, List<String>) _run;
  final bool _supported;
  static const _schema = 'org.gnome.system.proxy';
  static const _keys = {
    'http.host': ('$_schema.http', 'host'),
    'http.port': ('$_schema.http', 'port'),
    'http.use-authentication': ('$_schema.http', 'use-authentication'),
    'https.host': ('$_schema.https', 'host'),
    'https.port': ('$_schema.https', 'port'),
    'socks.host': ('$_schema.socks', 'host'),
    'socks.port': ('$_schema.socks', 'port'),
    'use-same-proxy': (_schema, 'use-same-proxy'),
    'mode': (_schema, 'mode'),
  };
  @override
  String get name => 'gnome';
  @override
  Future<Map<String, String>> read() async => {
    for (final entry in _keys.entries)
      entry.key: await _command(['get', entry.value.$1, entry.value.$2]),
  };
  @override
  Map<String, String> target(int port) => {
    'http.host': "'127.0.0.1'",
    'http.port': '$port',
    'http.use-authentication': 'false',
    'https.host': "'127.0.0.1'",
    'https.port': '$port',
    'socks.host': "'127.0.0.1'",
    'socks.port': '$port',
    'use-same-proxy': 'false',
    'mode': "'manual'",
  };
  @override
  Future<void> write(
    Map<String, String> values, {
    Map<String, String>? expected,
  }) async {
    final live = expected == null ? null : Map.of(expected);
    for (final entry in values.entries) {
      final key = _keys[entry.key];
      if (key == null || entry.value.length > 16384) {
        throw const SystemProxyException();
      }
      if (await _command(['writable', key.$1, key.$2]) != 'true') {
        throw const SystemProxyException();
      }
      if (live != null) _checkExpected(await read(), live);
      await _command(['set', key.$1, key.$2, entry.value]);
      live?[entry.key] = entry.value;
    }
  }

  Future<String> _command(List<String> arguments) async {
    if (!_supported) throw const SystemProxyException();
    try {
      final result = await _run(
        'gsettings',
        arguments,
      ).timeout(const Duration(seconds: 5));
      if (result.exitCode != 0) throw const SystemProxyException();
      return (result.stdout as String).trim();
    } on Object {
      throw const SystemProxyException();
    }
  }
}
