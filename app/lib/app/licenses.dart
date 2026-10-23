import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Licences the pub packages do not carry, added to the ones Flutter
/// collects from them (LICENSING §2): Avalon's own, and the native code
/// flutter_zxing compiles in.
void registerBundledLicenses() {
  LicenseRegistry.addLicense(() async* {
    for (final (packages, asset) in const [
      (['Avalon'], 'assets/licenses/AGPL-3.0.txt'),
      (['zxing-cpp'], 'assets/licenses/zxing-cpp.txt'),
      (['zint'], 'assets/licenses/zint.txt'),
      (['go-winio'], 'assets/licenses/go-winio.txt'),
      (['Wintun'], 'assets/licenses/wintun.txt'),
    ]) {
      yield LicenseEntryWithLineBreaks(
        packages,
        await rootBundle.loadString(asset),
      );
    }
  });
}

/// One package's licences.
final class PackageLicenses {
  const PackageLicenses(this.package, this.texts);

  final String package;

  /// Each licence as plain text, paragraphs separated by blank lines.
  final List<String> texts;
}

const _own = {'avalon_workspace', 'avalon', 'av_core', 'av_design'};

/// Every registered licence grouped by package, Avalon first, then by name.
Future<List<PackageLicenses>> collectLicenses() async {
  final byPackage = <String, List<String>>{};
  await for (final entry in LicenseRegistry.licenses) {
    final text = entry.paragraphs
        .map(
          (p) => p.indent == LicenseParagraph.centeredIndent
              ? p.text
              : '${'  ' * p.indent}${p.text}',
        )
        .join('\n\n');
    for (final package in entry.packages) {
      // The workspace's own packages are Avalon.
      final name = _own.contains(package) ? 'Avalon' : package;
      final texts = byPackage[name] ??= [];
      if (!texts.contains(text)) texts.add(text);
    }
  }
  final names = byPackage.keys.toList()
    ..sort((a, b) {
      if (a == 'Avalon') return -1;
      if (b == 'Avalon') return 1;
      return a.toLowerCase().compareTo(b.toLowerCase());
    });
  return [for (final n in names) PackageLicenses(n, byPackage[n]!)];
}
