// The design system builds on widgets/Cupertino only (D60) and never depends
// on the app.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lib/ imports neither Material nor the app', () {
    final forbidden = RegExp(
      r'''^\s*(?:import|export)\s+['"](package:flutter/material\.dart|package:avalon/)''',
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
