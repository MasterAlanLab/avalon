import 'dart:io';
import 'package:build_tool/src/error.dart';
import 'package:build_tool/src/tailscale_patch.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  final root = p.normalize(p.join(Directory.current.path, '../../../..'));
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('avalon_ts_patch_'));
  tearDown(() => tmp.deleteSync(recursive: true));
  Future<void> prepare() async {
    final source = p.join(tmp.path, 'core', 'Clash.Meta');
    Directory(p.dirname(source)).createSync(recursive: true);
    final clone = await Process.run('git', [
      'clone',
      '--shared',
      '--no-checkout',
      p.join(root, 'core', 'Clash.Meta'),
      source
    ]);
    expect(clone.exitCode, 0, reason: '${clone.stderr}');
    final checkout = await Process.run('git',
        ['checkout', '--detach', '0f7f05adff5e2c49775a112dcfe05a6aa36fda0c'],
        workingDirectory: source);
    expect(checkout.exitCode, 0, reason: '${checkout.stderr}');
    Directory(p.join(tmp.path, 'core', 'patches')).createSync();
    File(p.join(root, 'core', 'patches', 'tailscale-v2.patch'))
        .copySync(p.join(tmp.path, 'core', 'patches', 'tailscale-v2.patch'));
  }

  test('clean pinned checkout applies recorded patch idempotently', () async {
    await prepare();
    await ensureTailscalePatch(tmp.path);
    final file = File(p.join(
        tmp.path, 'core', 'Clash.Meta', 'adapter', 'outbound', 'tailscale.go'));
    final first = file.readAsStringSync();
    expect(first, contains('StartManaged'));
    await ensureTailscalePatch(tmp.path);
    expect(file.readAsStringSync(), first);
  });
  test('conflict preserves unrelated local edits', () async {
    await prepare();
    final file = File(p.join(
        tmp.path, 'core', 'Clash.Meta', 'adapter', 'outbound', 'tailscale.go'));
    file.writeAsStringSync('LOCAL FIXTURE CONTENT\n');
    await expectLater(
        ensureTailscalePatch(tmp.path), throwsA(isA<BuildException>()));
    expect(file.readAsStringSync(), 'LOCAL FIXTURE CONTENT\n');
  });
  test('missing tracked patch fails before building an old binary', () async {
    await expectLater(
        ensureTailscalePatch(tmp.path), throwsA(isA<BuildException>()));
  });
}
