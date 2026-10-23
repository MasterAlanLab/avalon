// av_core stays pure Dart (D40): no Flutter, no dart:io or dart:ui, so the
// pipeline runs in isolates, CLI tools and plain `dart test`.
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('lib/ imports no Flutter, dart:io or dart:ui', () {
    final forbidden = RegExp(
      r'''^\s*(?:import|export)\s+['"](package:flutter|dart:io|dart:ui)''',
      multiLine: true,
    );
    final bad = [
      for (final f in Directory('lib').listSync(recursive: true))
        if (f is File &&
            f.path.endsWith('.dart') &&
            forbidden.hasMatch(f.readAsStringSync()))
          f.path,
    ];
    expect(bad, isEmpty);
  });
}
