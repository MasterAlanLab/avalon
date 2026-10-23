// Import boundaries stay enforced as features are added.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

final _directive = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

/// (file, imported uri, resolved lib-relative path or null) for every
/// import/export in lib/.
List<(String, String, String?)> _imports() {
  final out = <(String, String, String?)>[];
  final lib = Directory('lib').absolute.uri;
  for (final f in Directory('lib').listSync(recursive: true)) {
    if (f is! File || !f.path.endsWith('.dart')) continue;
    final file = f.absolute.uri;
    for (final m in _directive.allMatches(f.readAsStringSync())) {
      final uri = m.group(1)!;
      String? local;
      if (uri.startsWith('package:avalon/')) {
        local = uri.substring('package:avalon/'.length);
      } else if (!uri.contains(':')) {
        final resolved = file.resolve(uri).toString();
        local = resolved.startsWith(lib.toString())
            ? resolved.substring(lib.toString().length)
            : '../${resolved.split('/app/').last}';
      }
      out.add((file.toString().substring(lib.toString().length), uri, local));
    }
  }
  return out;
}

void main() {
  final imports = _imports();

  String? feature(String path) =>
      path.startsWith('features/') ? path.split('/')[1] : null;

  test('lib/ never reaches outside itself (gallery, tests, tools)', () {
    final bad = [
      for (final (file, uri, local) in imports)
        if (local != null && local.startsWith('../')) '$file -> $uri',
    ];
    expect(bad, isEmpty);
  });

  test('no Material components (D60)', () {
    final bad = [
      for (final (file, uri, _) in imports)
        if (uri == 'package:flutter/material.dart') file,
    ];
    expect(bad, isEmpty);
  });

  test('features do not import each other', () {
    final bad = [
      for (final (file, uri, local) in imports)
        if (local != null &&
            feature(file) != null &&
            feature(local) != null &&
            feature(file) != feature(local))
          '$file -> $uri',
    ];
    expect(bad, isEmpty);
  });

  test('only data/ uses Drift', () {
    final bad = [
      for (final (file, uri, _) in imports)
        if (uri.startsWith('package:drift') && !file.startsWith('data/')) file,
    ];
    expect(bad, isEmpty);
  });

  test('only runtime/ touches the host transports (D85)', () {
    // Everything else talks to the coordinator; the channel and socket
    // behind the gateway are runtime's own business.
    final bad = [
      for (final (file, uri, local) in imports)
        if (local != null &&
            local.startsWith('runtime/host/') &&
            !file.startsWith('runtime/'))
          '$file -> $uri',
    ];
    expect(bad, isEmpty);
  });

  test('only the coordinator is the pages\' way to the host', () {
    // Pages read `runtimeProvider`; they never hold a gateway.
    final bad = [
      for (final (file, uri, local) in imports)
        if (local != null &&
            file.startsWith('features/') &&
            (local == 'runtime/host_gateway.dart' ||
                local == 'runtime/runtime_host.dart'))
          '$file -> $uri',
    ];
    expect(bad, isEmpty);
  });
}
