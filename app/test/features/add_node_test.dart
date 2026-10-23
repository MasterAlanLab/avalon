// Adding a self node: the form's view model down to the database
// (PRODUCT_SPEC §3.6).
import 'package:av_core/av_core.dart';
import 'package:avalon/features/add/add_state.dart';
import 'package:avalon/features/add/add_view_model.dart';
import 'package:avalon/features/proxies/proxies_state.dart';
import 'package:avalon/features/proxies/proxies_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

const _links = '''
trojan://fake-password@a.example.com:443#A
trojan://fake-password@b.example.com:443#B
''';

void main() {
  late Harness h;
  late ProviderContainer container;

  setUp(() async {
    h = await Harness.start()
      ..body = _links;
    container = h.container;
    container.listen(addViewModelProvider, (_, _) {});
    container.listen(proxiesStateProvider, (_, _) {});
  });
  tearDown(() => h.stop());

  AddViewModel form() => container.read(addViewModelProvider.notifier);
  AddState state() => container.read(addViewModelProvider);

  Future<ProxiesState> proxies(bool Function(ProxiesState s) ready) => h.settle(
    () => container.read(proxiesStateProvider),
    (s) => !s.loading && ready(s),
  );

  void fillTrojan() => form()
    ..setSegment(AddSegment.node)
    ..setProtocol(Protocol.trojan)
    ..setNodeField(NodeField.server, 'vps.example.com')
    ..setNodeField(NodeField.password, 'fake-self');

  test('a share link fills the form without saving', () async {
    form()
      ..setSegment(AddSegment.node)
      ..setLink(' hy2://fake-hy2@b.example.com:8443?sni=b.example.com#东京 ')
      ..parseLink();
    final draft = state().node;
    expect(state().linkError, isNull);
    expect(draft.protocol, Protocol.hysteria2);
    expect(draft[NodeField.name], '东京');
    expect(draft[NodeField.server], 'b.example.com');
    expect(draft[NodeField.port], '8443');
    expect(draft[NodeField.password], 'fake-hy2');
    expect(draft[NodeField.sni], 'b.example.com');
    expect(await h.services.selfContent.nodes(), isEmpty);
  });

  test('an unknown link is an error, not a guess', () {
    form()
      ..setSegment(AddSegment.node)
      ..setLink('wireguard://example')
      ..parseLink();
    expect(state().linkError!.code, 'import.unsupportedScheme');
    expect(state().node.protocol, Protocol.vless);
    // Editing the link clears the error.
    form().setLink('wireguard://exampl');
    expect(state().linkError, isNull);
  });

  test('a missing field stops the save and is named', () async {
    form()
      ..setSegment(AddSegment.node)
      ..setNodeField(NodeField.server, 'vps.example.com');
    expect(await form().saveNode(), isFalse);
    expect(state().nodeError!.field, NodeField.uuid);
    expect(state().nodeError!.error, NodeDraftError.required);
    expect(await h.services.selfContent.nodes(), isEmpty);
    // Typing into that field clears it.
    form().setNodeField(NodeField.uuid, '0');
    expect(state().nodeError, isNull);
  });

  test('the first node selects 「自建节点」 and shows in 「自定义」', () async {
    fillTrojan();
    expect(await form().saveNode(), isTrue);
    final saved = (await h.services.selfContent.nodes()).single;
    expect(saved.name, 'vps.example.com');
    expect((saved.params as TrojanParams).password, const Secret('fake-self'));
    expect(
      (await h.services.settings.device()).selectedConfigurationId,
      SelfSource.id,
    );
    final s = await proxies(
      (s) => s.groups.isNotEmpty && s.groups.first.members.isNotEmpty,
    );
    expect(s.groups.single.isCustom, isTrue);
    expect(s.groups.single.members.single.name, 'vps.example.com');
  });

  test(
    'with an imported configuration selected it joins the main selector',
    () async {
      form().setUrl('${h.base}/sub');
      expect(await form().saveSubscription(defaultName: '新订阅'), isNotNull);
      final id = (await h.services.settings.device()).selectedConfigurationId!;
      container.invalidate(addViewModelProvider);

      fillTrojan();
      form().setNodeField(NodeField.name, '自建 VPS');
      expect(await form().saveNode(), isTrue);

      // Still the imported configuration; nothing new is chosen.
      expect((await h.services.settings.device()).selectedConfigurationId, id);
      // The node and its membership arrive on separate watches.
      final s = await proxies(
        (s) =>
            s.groups.length > 1 &&
            s.groups[1].members.isNotEmpty &&
            s.groups.first.members.length == 4,
      );
      final main = s.groups.first;
      expect(main.name, LinkListGroups.select);
      expect(main.members.last.name, '自建 VPS');
      expect(main.current, 0);
      expect(s.groups[1].members.single.name, '自建 VPS');
      expect(await h.services.selections.get(id), isEmpty);
    },
  );
}
