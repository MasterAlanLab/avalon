import 'dart:io';
import 'dart:typed_data';

const sourceDir = 'tool/branding/status';
const outputDir = 'assets/images/icon';
const statusIconNames = ['status_1', 'status_2', 'status_3'];
const statusPngSize = 256;
const trayIcoSize = 32;
const trayBackgroundColor = '#17191D';
const trayCornerRadiusRatio = 230 / 1024;

Future<void> main() async {
  final rsvgConvert = await _findExecutable('rsvg-convert');
  if (rsvgConvert == null) {
    stderr.writeln(
      'rsvg-convert is required. Install librsvg before generating icons.',
    );
    exitCode = 1;
    return;
  }

  await Directory(outputDir).create(recursive: true);
  final tempDir = await Directory.systemTemp.createTemp('status_icons_');
  try {
    for (final name in statusIconNames) {
      final source = File('$sourceDir/$name.svg');
      if (!source.existsSync()) {
        stderr.writeln('Missing source SVG: ${source.path}');
        exitCode = 1;
        return;
      }

      final png = File('$outputDir/$name.png');
      final icoPng = File('${tempDir.path}/$name-32.png');
      final windowsSource = await _createWindowsTraySource(
        source: source,
        output: File('${tempDir.path}/$name-windows.svg'),
      );
      final ico = File('$outputDir/$name.ico');

      await _renderSvg(
        rsvgConvert: rsvgConvert,
        source: source,
        output: png,
        width: statusPngSize,
        height: statusPngSize,
      );
      await _renderSvg(
        rsvgConvert: rsvgConvert,
        source: windowsSource,
        output: icoPng,
        width: trayIcoSize,
        height: trayIcoSize,
      );
      await ico.writeAsBytes(_buildIco(await icoPng.readAsBytes()));

      stdout.writeln('Generated ${png.path} and ${ico.path}');
    }
  } finally {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  }
}

/// Builds the Windows-only tray variant. PNG is also used by Linux/macOS and
/// remains transparent, while Windows gets the same dark rounded backplate as
/// the Android launcher icon so the mark stays visible in light mode.
Future<File> _createWindowsTraySource({
  required File source,
  required File output,
}) async {
  final svg = await source.readAsString();
  final root = RegExp(r'<svg\b[^>]*>').firstMatch(svg);
  final viewBoxMatch = RegExp(
    r'''viewBox\s*=\s*["']\s*([^"']+?)\s*["']''',
  ).firstMatch(svg);
  if (root == null || viewBoxMatch == null) {
    throw FormatException('Missing SVG root/viewBox in ${source.path}');
  }

  final viewBox = viewBoxMatch.group(1)!
      .trim()
      .split(RegExp(r'\s+|,'))
      .map(double.parse)
      .toList();
  if (viewBox.length != 4) {
    throw FormatException('Invalid SVG viewBox in ${source.path}');
  }
  final x = viewBox[0];
  final y = viewBox[1];
  final width = viewBox[2];
  final height = viewBox[3];
  final radius = width * trayCornerRadiusRatio;
  final background =
      '<rect x="$x" y="$y" width="$width" height="$height" '
      'rx="$radius" fill="$trayBackgroundColor"/>';
  final wrapped = svg.replaceRange(root.end, root.end, '\n  $background');
  await output.writeAsString(wrapped);
  return output;
}

Future<String?> _findExecutable(String executable) async {
  final result = await Process.run('which', [executable]);
  if (result.exitCode != 0) {
    return null;
  }
  return (result.stdout as String).trim();
}

Future<void> _renderSvg({
  required String rsvgConvert,
  required File source,
  required File output,
  required int width,
  required int height,
}) async {
  final result = await Process.run(rsvgConvert, [
    '-w',
    '$width',
    '-h',
    '$height',
    '-o',
    output.path,
    source.path,
  ]);
  if (result.exitCode != 0) {
    stderr
      ..writeln('Failed to render ${source.path} -> ${output.path}')
      ..writeln(result.stderr);
    exit(result.exitCode);
  }
}

Uint8List _buildIco(List<int> pngBytes) {
  const headerSize = 6;
  const directoryEntrySize = 16;
  const imageOffset = headerSize + directoryEntrySize;

  final bytes = BytesBuilder(copy: false)
    ..add(_uint16(0))
    ..add(_uint16(1))
    ..add(_uint16(1))
    ..add([32, 32, 0, 0])
    ..add(_uint16(1))
    ..add(_uint16(32))
    ..add(_uint32(pngBytes.length))
    ..add(_uint32(imageOffset))
    ..add(pngBytes);

  return bytes.toBytes();
}

Uint8List _uint16(int value) {
  return (ByteData(2)..setUint16(0, value, Endian.little)).buffer.asUint8List();
}

Uint8List _uint32(int value) {
  return (ByteData(4)..setUint32(0, value, Endian.little)).buffer.asUint8List();
}
