// What can be switched in a running plan, and telling a switch from a
// change that needs a reload (RUNTIME_HOST §5).
import 'dart:typed_data';

import 'package:av_core/av_core.dart';
import 'package:test/test.dart';

const _host = HostInfo(
  platform: HostPlatform.android,
  stateDir: '/state',
  deviceName: 'phone',
);

void main() {
  final content = parseContent('''
proxies:
  - {name: 香港, type: trojan, server: a.example.com, port: 443, password: fake-a}
  - {name: 日本, type: trojan, server: b.example.com, port: 443, password: fake-b}
proxy-groups:
  - {name: 节点选择, type: select, proxies: [香港, 日本, DIRECT]}
  - {name: 流媒体, type: select, proxies: [日本, 香港]}
rules:
  - DOMAIN-SUFFIX,netflix.com,流媒体
  - MATCH,节点选择
''').content;
  String key(String name) =>
      content.groups.firstWhere((g) => g.name == name).key;
  MemberRef node(String name) => MemberRef.source(
    configurationId: 'cfg',
    key: content.nodes.firstWhere((n) => n.name == name).key,
  );

  CompiledPlan plan({
    DeviceSettings settings = const DeviceSettings(),
    Map<String, MemberRef> selections = const {},
  }) => compile(
    CompileInput(
      source: ImportedSource(id: 'cfg', content: content),
      settings: settings,
      host: _host,
      hashKey: Uint8List.fromList(List.filled(32, 3)),
      selections: selections,
    ),
  );
  String tag(CompiledPlan p, String name) =>
      p.tags.entries.firstWhere((e) => e.value.name == name).key;

  test('the choices are the mode and each selector\'s member', () {
    final p = plan(selections: {key('节点选择'): node('日本')});
    final choices = p.choices;
    expect(choices.mode, 'rule');
    expect(choices.selections, {
      tag(p, '节点选择'): tag(p, '日本'),
      tag(p, '流媒体'): tag(p, '日本'),
    });
  });

  test('choosing a member or the mode is not a change of plan', () {
    final base = plan();
    final chosen = plan(selections: {key('节点选择'): node('日本')});
    final direct = plan(
      settings: const DeviceSettings(mode: OutboundMode.direct),
    );
    expect(chosen.planHash, base.planHash);
    expect(direct.planHash, base.planHash);
    expect(chosen.choices.selections, isNot(base.choices.selections));
    expect(direct.choices.mode, 'direct');
  });

  test('anything else is', () {
    final base = plan().planHash;
    for (final settings in const [
      DeviceSettings(mixedPort: 7891),
      DeviceSettings(tunEnabled: false),
      DeviceSettings(logLevel: LogLevel.debug),
      DeviceSettings(perAppList: ['org.example.app']),
    ]) {
      expect(plan(settings: settings).planHash, isNot(base));
    }
  });

  test('a member\'s tag; a chain is its last hop', () {
    final p = plan();
    expect(p.tagOf(node('香港')), tag(p, '香港'));
    expect(p.tagOf(const MemberRef.builtin(builtin: Builtin.direct)), 'direct');
    expect(p.tagOf(const MemberRef.chain(id: 'missing')), isNull);
    final chained = compile(
      CompileInput(
        source: ImportedSource(id: 'cfg', content: content),
        settings: const DeviceSettings(),
        host: _host,
        hashKey: Uint8List.fromList(List.filled(32, 3)),
        chains: [
          Chain(id: 'c1', name: '链', hops: [node('香港'), node('日本')]),
        ],
      ),
    );
    expect(chained.tagOf(const MemberRef.chain(id: 'c1')), 'c:c1:1');
  });
}
