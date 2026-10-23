// The proxies page from its view model down to an in-memory database.
import 'package:av_core/av_core.dart';
import 'package:avalon/features/add/add_view_model.dart';
import 'package:avalon/features/proxies/proxies_state.dart';
import 'package:avalon/features/proxies/proxies_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

const _clash = '''
proxies:
  - {name: 香港 01, type: trojan, server: a.example.com, port: 443, password: fake-a}
  - {name: 日本 01, type: vless, server: b.example.com, port: 443, uuid: 00000000-0000-4000-8000-000000000001, tls: true}
proxy-groups:
  - {name: 节点选择, type: select, proxies: [自动选择, 香港 01, 日本 01, DIRECT]}
  - {name: 自动选择, type: url-test, proxies: [香港 01, 日本 01], url: "https://www.gstatic.com/generate_204", interval: 300}
rules:
  - MATCH,节点选择
''';

const _self = SelfNode(
  id: '',
  name: '自建 VPS',
  server: 'vps.example.com',
  port: 443,
  params: NodeParams.trojan(
    password: Secret('fake-self'),
    tls: Tls(serverName: 'vps.example.com'),
  ),
);

void main() {
  late Harness h;
  late ProviderContainer container;

  setUp(() async {
    h = await Harness.start()
      ..body = _clash;
    container = h.container;
    container.listen(proxiesStateProvider, (_, _) {});
    container.listen(addViewModelProvider, (_, _) {});
  });
  tearDown(() => h.stop());

  Future<ProxiesState> page(bool Function(ProxiesState s) ready) => h.settle(
    () => container.read(proxiesStateProvider),
    (s) => !s.loading && ready(s),
  );

  Future<void> addSubscription() async {
    final form = container.read(addViewModelProvider.notifier)
      ..setUrl('${h.base}/sub');
    expect(await form.saveSubscription(defaultName: '新订阅'), isNotNull);
  }

  test('without a selected configuration there is nothing to show', () async {
    final s = await page((s) => true);
    expect(s.hasConfiguration, isFalse);
    expect(s.groups, isEmpty);
    expect(s.group, isNull);
  });

  test('groups in imported order with 「自定义」 second', () async {
    await addSubscription();
    final s = await page((s) => s.groups.isNotEmpty);
    expect([for (final g in s.groups) g.name], ['节点选择', null, '自动选择']);
    expect(s.groups[1].isCustom, isTrue);
    expect(s.groups[1].members, isEmpty);

    final select = s.group!;
    expect(select.name, '节点选择');
    expect(select.displayType, 'Selector');
    expect(select.selectable, isTrue);
    expect(
      [for (final m in select.members) m.name],
      ['自动选择', '香港 01', '日本 01', 'DIRECT'],
    );
    expect(
      [for (final m in select.members) m.kind],
      [
        ProxyMemberKind.group,
        ProxyMemberKind.node,
        ProxyMemberKind.node,
        ProxyMemberKind.direct,
      ],
    );
    expect(select.members[0].groupType, 'URLTest');
    expect(select.members[1].protocol, Protocol.trojan);
    expect(select.members[2].protocol, Protocol.vless);
    // Nothing chosen yet: the first member is in use.
    expect(select.current, 0);

    final auto = s.groups[2];
    expect(auto.selectable, isFalse);
    expect(auto.current, isNull);
  });

  test(
    'a choice is saved and survives a refresh that keeps the node',
    () async {
      await addSubscription();
      final s = await page((s) => s.groups.isNotEmpty);
      final model = container.read(proxiesViewModelProvider.notifier);
      await model.select(s.group!.key, s.group!.members[2].ref);
      expect((await page((s) => s.group?.current == 2)).group!.current, 2);

      // The chosen node disappears: the first member is used, but the choice
      // stays saved and comes back with the node.
      final id = (await h.services.settings.device()).selectedConfigurationId!;
      h.body = _clash
          .replaceAll(', 日本 01, DIRECT]', ', DIRECT]')
          .replaceAll('[香港 01, 日本 01]', '[香港 01]');
      await h.services.imports.refresh(id);
      final without = await page((s) => s.group?.members.length == 3);
      expect(without.group!.current, 0);
      expect((await h.services.selections.get(id)).values, hasLength(1));

      h.body = _clash;
      await h.services.imports.refresh(id);
      expect(
        (await page((s) => s.group?.members.length == 4)).group!.current,
        2,
      );
    },
  );

  test('a group asked for before the data arrives is shown', () async {
    await addSubscription();
    // As the route does on arrival, while the page is still loading.
    container.invalidate(proxiesStateProvider);
    container
        .read(proxiesViewModelProvider.notifier)
        .showGroup(ContentKeys.custom);
    final s = await page((s) => s.groups.isNotEmpty);
    expect(s.group!.isCustom, isTrue);
  });

  test('switching the group on show; direct mode is flagged', () async {
    await addSubscription();
    final s = await page((s) => s.groups.isNotEmpty);
    container
        .read(proxiesViewModelProvider.notifier)
        .showGroup(s.groups[2].key);
    expect((await page((s) => s.group?.name == '自动选择')).directMode, isFalse);

    await h.services.settings.updateDevice(
      (s) => s.copyWith(mode: OutboundMode.direct),
    );
    expect((await page((s) => s.directMode)).group!.name, '自动选择');
  });

  test(
    '「自定义」 lists self nodes and chains; a broken chain is flagged',
    () async {
      await addSubscription();
      final id = (await h.services.settings.device()).selectedConfigurationId!;
      final node = await h.services.selfContent.addNode(_self);
      await h.services.selfContent.addChain(
        Chain(
          id: '',
          hops: [
            MemberRef.source(configurationId: id, key: 'proxy:香港 01'),
            MemberRef.selfNode(id: node.id),
          ],
        ),
      );
      await h.services.selfContent.addChain(
        Chain(
          id: '',
          name: '坏链',
          hops: [
            MemberRef.source(configurationId: id, key: 'proxy:gone'),
            MemberRef.selfNode(id: node.id),
          ],
        ),
      );
      final s = await page(
        (s) => s.groups.length > 1 && s.groups[1].members.length == 3,
      );
      final custom = s.groups[1];
      expect(
        [for (final m in custom.members) m.name],
        ['自建 VPS', '香港 01 → 自建 VPS', '坏链'],
      );
      expect(custom.members[1].kind, ProxyMemberKind.chain);
      expect(custom.members[1].hops, 2);
      expect(custom.members[1].unavailable, isNull);
      expect(custom.members[2].unavailable, 'hop-missing');
      expect(custom.current, 0);
    },
  );

  test('the self configuration has only 「自定义」', () async {
    await h.services.selfContent.addNode(_self);
    await h.services.settings.updateDevice(
      (s) => s.copyWith(selectedConfigurationId: 'self'),
    );
    final s = await page((s) => s.groups.isNotEmpty);
    expect(s.groups, hasLength(1));
    expect(s.group!.isCustom, isTrue);
    expect(s.group!.members.single.name, '自建 VPS');
  });
}
