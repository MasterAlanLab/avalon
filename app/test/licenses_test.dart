import 'dart:io';

import 'package:avalon/app/licenses.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled application and native licenses remain available', () async {
    LicenseRegistry.reset();
    registerBundledLicenses();
    // The workspace package carries the same text; it is not listed twice.
    final agpl = File('../LICENSE').readAsStringSync();
    LicenseRegistry.addLicense(
      () =>
          Stream.value(LicenseEntryWithLineBreaks(['avalon_workspace'], agpl)),
    );
    final all = await collectLicenses();
    final avalon = all.singleWhere((license) => license.package == 'Avalon');
    expect(avalon.texts.single, contains('GNU AFFERO GENERAL PUBLIC LICENSE'));
    final names = [for (final p in all) p.package];
    expect(names, isNot(contains('avalon_workspace')));
    expect(names, containsAll(['zxing-cpp', 'zint']));
    final zxing = all.firstWhere((p) => p.package == 'zxing-cpp');
    expect(zxing.texts.single, contains('Apache License'));
    expect(zxing.texts.single, contains('Nu-book'));
  });
}
