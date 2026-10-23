import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Family for Latin text in goldens (SF Pro, read from the host).
const goldenTextFamily = 'GoldenText';

/// Fallback family for CJK text in goldens (PingFang SC, read from the host).
const goldenCjkFamily = 'GoldenCJK';

/// False when the host lacks the Apple system fonts; goldens then skip.
bool goldenFontsAvailable = false;

/// The app uses each platform's system font (D62) and bundles none, while
/// `flutter test` renders unknown fonts as fixed-width boxes that overflow
/// any real layout. Goldens therefore borrow the macOS system fonts, which
/// are what iOS and macOS show: SF Pro for Latin with PingFang SC as the CJK
/// fallback (as on Apple platforms), SF Mono for monospace, and the bundled
/// Material Symbols for icons.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await _loadBundledFonts();
  goldenFontsAvailable = await _loadHostFonts();
  if (Platform.environment['AVALON_REQUIRE_GOLDEN_FONTS'] == '1' &&
      !goldenFontsAvailable) {
    throw StateError(
      'CI requires the macOS SF Pro, SF Mono and PingFang fonts.',
    );
  }
  await testMain();
}

Future<void> _loadBundledFonts() async {
  final manifest =
      json.decode(await rootBundle.loadString('FontManifest.json'))
          as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final loader = FontLoader(entry['family'] as String);
    for (final font in (entry['fonts'] as List).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

Future<bool> _loadHostFonts() async {
  const fonts = '/System/Library/Fonts';
  final sf = File('$fonts/SFNS.ttf');
  final mono = File('$fonts/SFNSMono.ttf');
  final pingFang = _findPingFang();
  if (!sf.existsSync() || !mono.existsSync() || pingFang == null) return false;

  Future<void> load(List<String> families, List<Uint8List> faces) async {
    for (final family in families) {
      final loader = FontLoader(family);
      for (final face in faces) {
        loader.addFont(Future.value(ByteData.sublistView(face)));
      }
      await loader.load();
    }
  }

  final ttc = pingFang.readAsBytesSync();
  final cjk = [
    for (final weight in ['Regular', 'Medium', 'Semibold'])
      _ttcFace(ttc, 'PingFang SC $weight'),
  ];
  await load([goldenTextFamily], [sf.readAsBytesSync()]);
  await load(['monospace', 'Menlo', 'Consolas'], [mono.readAsBytesSync()]);
  // Text fields style through CupertinoTheme, which names these families;
  // PingFang covers both scripts there.
  await load([
    goldenCjkFamily,
    'CupertinoSystemText',
    'CupertinoSystemDisplay',
  ], cjk);
  return true;
}

/// PingFang ships as a downloadable system asset on recent macOS.
File? _findPingFang() {
  for (final path in [
    '/System/Library/Fonts/PingFang.ttc',
    '/Library/Fonts/PingFang.ttc',
  ]) {
    if (File(path).existsSync()) return File(path);
  }
  final assets = Directory('/System/Library/AssetsV2');
  if (!assets.existsSync()) return null;
  for (final kind in assets.listSync().whereType<Directory>()) {
    if (!kind.path.contains('MobileAsset_Font')) continue;
    for (final asset in kind.listSync().whereType<Directory>()) {
      final file = File('${asset.path}/AssetData/PingFang.ttc');
      if (file.existsSync()) return file;
    }
  }
  return null;
}

/// Copies the face whose full name is [fullName] out of a TrueType
/// collection into a standalone font, since the engine loads face 0 only.
Uint8List _ttcFace(Uint8List ttc, String fullName) {
  final d = ByteData.sublistView(ttc);
  final count = d.getUint32(8);
  for (var i = 0; i < count; i++) {
    final dir = d.getUint32(12 + 4 * i);
    final tables = d.getUint16(dir + 4);
    if (_fullName(d, dir, tables) != fullName) continue;
    final header = 12 + 16 * tables;
    var size = header;
    for (var t = 0; t < tables; t++) {
      size += (d.getUint32(dir + 24 + 16 * t) + 3) & ~3;
    }
    final out = Uint8List(size);
    final o = ByteData.sublistView(out);
    out.setRange(0, 12, ttc, dir);
    var pos = header;
    for (var t = 0; t < tables; t++) {
      final rec = dir + 12 + 16 * t;
      final offset = d.getUint32(rec + 8), length = d.getUint32(rec + 12);
      out.setRange(12 + 16 * t, 20 + 16 * t, ttc, rec); // tag, checksum
      o.setUint32(20 + 16 * t, pos);
      o.setUint32(24 + 16 * t, length);
      out.setRange(pos, pos + length, ttc, offset);
      pos += (length + 3) & ~3;
    }
    return out;
  }
  throw StateError('$fullName not found in collection');
}

/// The Windows/English full name (name ID 4) of the face at [dir].
String? _fullName(ByteData d, int dir, int tables) {
  for (var t = 0; t < tables; t++) {
    final rec = dir + 12 + 16 * t;
    if (d.getUint32(rec) != 0x6E616D65) continue; // 'name'
    final table = d.getUint32(rec + 8);
    final records = d.getUint16(table + 2);
    final strings = table + d.getUint16(table + 4);
    for (var r = 0; r < records; r++) {
      final n = table + 6 + 12 * r;
      if (d.getUint16(n) != 3 ||
          d.getUint16(n + 4) != 0x409 ||
          d.getUint16(n + 6) != 4) {
        continue;
      }
      final length = d.getUint16(n + 8), start = strings + d.getUint16(n + 10);
      return String.fromCharCodes([
        for (var k = 0; k < length; k += 2) d.getUint16(start + k),
      ]);
    }
  }
  return null;
}
