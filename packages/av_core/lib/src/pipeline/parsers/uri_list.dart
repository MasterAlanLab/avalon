import '../../domain/content.dart';
import '../../domain/node.dart';
import '../import_exception.dart';
import 'share_link.dart';

/// Group names generated for link lists (CONFIG_PIPELINE §4).
abstract final class LinkListGroups {
  static const select = '节点选择';
  static const auto = '自动选择';
  static const selectKey = 'group:$select';
  static const autoKey = 'group:$auto';
}

/// Test URL for generated URL-test groups; matches the default 测速地址.
const defaultTestUrl = 'https://www.gstatic.com/generate_204';

/// Lines that look like share links, or null when [text] is not a link
/// list.
List<String>? linkLines(String text) {
  final lines = [
    for (final l in text.split(RegExp(r'\r?\n')))
      if (l.trim().isNotEmpty) l.trim(),
  ];
  if (lines.isEmpty) return null;
  final scheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.-]*://');
  return lines.every(scheme.hasMatch) ? lines : null;
}

/// Builds content from share-link lines: nodes named after the link (else
/// the server address, duplicates numbered), a 「节点选择」 selector over
/// 「自动选择」 and every node, and an 「自动选择」 URL test. Rules stay empty
/// so the compiler applies the default template.
///
/// Unreadable or unsupported lines are skipped with a warning; a list with
/// no usable line is rejected.
ConfigContent parseLinkList(List<String> lines) {
  final nodes = <NodeDef>[];
  final names = <String>{};
  final skipped = <String, int>{};
  final unreadable = <String, int>{};

  for (final line in lines) {
    final LinkNode link;
    try {
      link = parseShareLink(line);
    } on ImportException catch (e) {
      if (e.code == ImportErrorCode.unsupportedScheme) {
        final scheme = line.substring(0, line.indexOf('://')).toLowerCase();
        skipped[scheme] = (skipped[scheme] ?? 0) + 1;
      } else {
        final what = e.field ?? e.code.name;
        unreadable[what] = (unreadable[what] ?? 0) + 1;
      }
      continue;
    }
    final base = link.name ?? link.server;
    var name = base;
    for (var i = 2; names.contains(name); i++) {
      name = '$base ($i)';
    }
    names.add(name);
    nodes.add(
      NodeDef(
        key: name,
        name: name,
        server: link.server,
        port: link.port,
        params: link.params,
      ),
    );
  }

  if (nodes.isEmpty) {
    throw const ImportException(ImportErrorCode.unknownFormat);
  }
  final keys = [for (final n in nodes) n.key];
  return ConfigContent(
    nodes: nodes,
    groups: [
      GroupDef(
        key: LinkListGroups.selectKey,
        name: LinkListGroups.select,
        type: GroupType.selector,
        displayType: 'Selector',
        members: [LinkListGroups.autoKey, ...keys],
      ),
      GroupDef(
        key: LinkListGroups.autoKey,
        name: LinkListGroups.auto,
        type: GroupType.urltest,
        displayType: 'URLTest',
        members: keys,
        test: const GroupTest(url: defaultTestUrl),
      ),
    ],
    finalTarget: LinkListGroups.selectKey,
    defaultRules: true,
    warnings: [
      for (final e in skipped.entries)
        ImportWarning(
          kind: WarningKind.unsupportedNodeType,
          subject: e.key,
          count: e.value,
        ),
      for (final e in unreadable.entries)
        ImportWarning(
          kind: WarningKind.unreadableEntry,
          subject: e.key,
          count: e.value,
        ),
      ..._insecure(nodes),
    ],
  );
}

/// The 「N 个节点关闭了证书验证」 warning, if any (CONFIG_PIPELINE §4).
List<ImportWarning> _insecure(List<NodeDef> nodes) {
  final n = nodes.where((n) => insecureTls(n.params)).length;
  return n == 0
      ? const []
      : [ImportWarning(kind: WarningKind.insecureTls, count: n)];
}

bool insecureTls(NodeParams p) => switch (p) {
  Hysteria2Params(:final tls) ||
  TuicParams(:final tls) ||
  TrojanParams(:final tls) ||
  AnyTlsParams(:final tls) => tls.insecure,
  VlessParams(:final tls) ||
  VmessParams(:final tls) ||
  Socks5Params(:final tls) ||
  HttpParams(:final tls) => tls?.insecure ?? false,
  ShadowsocksParams() => false,
};
