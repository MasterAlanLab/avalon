import 'dart:io';
import 'package:path/path.dart' as p;
import 'error.dart';

/// Reproducible additions to the pinned FlClash mihomo revision. Applying this
/// before fingerprints makes a clean checkout and a local patched checkout
/// build identical core artifacts. Never resets user edits in the submodule.
Future<void> ensureTailscalePatch(String rootDir) async {
  final source = p.join(rootDir, 'core', 'Clash.Meta');
  final patch =
      p.absolute(p.join(rootDir, 'core', 'patches', 'tailscale-v2.patch'));
  if (!File(patch).existsSync()) {
    throw BuildException('Missing tracked Tailscale core patch: $patch');
  }
  Future<ProcessResult> git(List<String> args) =>
      Process.run('git', args, workingDirectory: source);
  final revision = await git(['rev-parse', 'HEAD']);
  if (revision.exitCode != 0 ||
      '${revision.stdout}'.trim() !=
          '0f7f05adff5e2c49775a112dcfe05a6aa36fda0c') {
    throw BuildException(
        'Tailscale patch requires pinned mihomo 0f7f05ad. Rebase the patch explicitly when updating the submodule.');
  }
  if ((await git(['apply', '--reverse', '--check', patch])).exitCode == 0) {
    return;
  }
  if ((await git(['apply', '--check', patch])).exitCode != 0) {
    throw BuildException(
        'Tailscale patch conflicts with mihomo working-tree changes. No files were reset.');
  }
  final applied = await git(['apply', patch]);
  if (applied.exitCode != 0) {
    throw BuildException('Tailscale core patch application failed.');
  }
}
