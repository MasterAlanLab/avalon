// Adding a chain: the form's view model down to the database
// (PRODUCT_SPEC §3.7).
import 'package:av_core/av_core.dart';
import 'package:avalon/features/add/add_state.dart';
import 'package:avalon/features/add/add_view_model.dart';
import 'package:avalon/features/add/chain_options.dart';
import 'package:avalon/features/proxies/proxies_state.dart';
import 'package:avalon/features/proxies/proxies_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

const _clash = '''
proxies:
  - {name: 香港 01, type: trojan, server: a.example.com, port: 443, password: fake-a}
  - {name: 日本 01, type: trojan, server: b.example.com, port: 443, password: fake-b}
proxy-groups:
  - {name: 节点选择, type: select, proxies: [自动选择, 香港 01, 日本 01]}
  - {name: 自动选择, type: url-test, proxies: [香港 01, 日本 01], url: "https://www.gstatic.com/generate_204", interval: 300}
  - {name: 流媒体, type: select, proxies: [香港 01, 日本 01]}
rules:
  - MATCH,节点选择
''';

const _self = SelfNode(
  id: '',
  name: '自建 VPS',
  server: 'vps.example.com',
  port: 443,
  params: NodeParams.trojan(password: Secret('fake-self')),
);

void main() {
  late Harness h;
  late ProviderContainer container;

  setUp(() async {
    h = await Harness.start()
      ..body = _clash;
    container = h.container;
    container.listen(addViewModelProvider, (_, _) {});
    container.listen(chainOptionsProvider, (_, _) {});
    container.listen(proxiesStateProvider, (_, _) {});
  });
  tearDown(() => h.stop());

  AddViewModel form() => container.read(addViewModelProvider.notifier);
  AddState state() => container.read(addViewModelProvider);

  Future<ChainOptions> options(bool Function(ChainOptions o) ready) =>
      h.settle(() => container.read(chainOptionsProvider), ready);

  Future<void> addSubscription() async {
    form().setUrl('${h.base}/sub');
    expect(await form().saveSubscription(defaultName: '新订阅'), isNotNull);
    container.invalidate(addViewModelProvider);
  }

  test('with nothing added there is nothing to chain', () async {
    final o = await options((o) => true);
    expect(o.hops, isEmpty);
    expect(o.groups, isEmpty);
    form().setSegment(AddSegment.chain);
    expect(state().canSave, isFalse);
    expect(await form().saveChain(), isFalse);
  });

  test('hops come from the configuration and the self nodes', () async {
    await addSubscription();
    await h.services.selfService.addNode(_self);
    final o = await options((o) => o.hops.length == 3);
    expect([for (final x in o.hops) x.name], ['香港 01', '日本 01', '自建 VPS']);
    expect(o.hops.last.ref, isA<SelfNodeRef>());
    // Selector groups only, without 「自定义」; the main one is ticked.
    expect([for (final g in o.groups) g.name], ['节点选择', '流媒体']);
    expect(o.defaultGroups, {o.groups.first.key});
  });

  test('saving joins the ticked groups and shows in 「自定义」', () async {
    await addSubscription();
    final id = (await h.services.settings.device()).selectedConfigurationId!;
    final o = await options((o) => o.hops.length == 2);

    form()
      ..setSegment(AddSegment.chain)
      ..addHop(o.hops[0].ref);
    expect(state().canSave, isFalse);
    form()
      ..addHop(o.hops[1].ref)
      ..addHop(o.hops[1].ref) // already there: ignored
      ..moveHop(0, 1)
      ..toggleChainGroup(o.groups[1].key); // main + 流媒体
    expect(state().chain.hops, [o.hops[1].ref, o.hops[0].ref]);
    expect(state().canSave, isTrue);
    expect(await form().saveChain(), isTrue);

    final chain = (await h.services.selfContent.chains()).single;
    expect(chain.name, isNull);
    expect(chain.hops, [o.hops[1].ref, o.hops[0].ref]);
    // The imported configuration stays selected.
    expect((await h.services.settings.device()).selectedConfigurationId, id);

    final s = await h.settle(
      () => container.read(proxiesStateProvider),
      (ProxiesState s) =>
          !s.loading &&
          s.groups.length == 4 &&
          s.groups[1].members.isNotEmpty &&
          s.groups[0].members.length == 4 &&
          s.groups[3].members.length == 3,
    );
    const name = '日本 01 → 香港 01';
    expect(s.groups[1].members.single.name, name);
    expect(s.groups[1].members.single.kind, ProxyMemberKind.chain);
    expect(s.groups[0].members.last.name, name); // 节点选择
    expect(s.groups[3].members.last.name, name); // 流媒体
    expect(s.groups[2].members, hasLength(2)); // 自动选择: untouched
  });

  test('unticking every group keeps the chain in 「自定义」 only', () async {
    await addSubscription();
    final o = await options((o) => o.hops.length == 2);
    form()
      ..setSegment(AddSegment.chain)
      ..setChainName(' 回国 ')
      ..addHop(o.hops[0].ref)
      ..addHop(o.hops[1].ref)
      ..toggleChainGroup(o.groups[0].key);
    expect(await form().saveChain(), isTrue);
    expect((await h.services.selfContent.chains()).single.name, '回国');
    final memberships = await h.services.selfContent.watchMemberships().first;
    expect(memberships, isEmpty);
  });

  test('self nodes alone can form a chain; 「自建节点」 gets selected', () async {
    final a = await h.services.selfContent.addNode(_self);
    final b = await h.services.selfContent.addNode(_self.copyWith(name: '落地机'));
    final o = await options((o) => o.hops.length == 2);
    expect(o.groups, isEmpty);
    form()
      ..setSegment(AddSegment.chain)
      ..addHop(MemberRef.selfNode(id: a.id))
      ..addHop(MemberRef.selfNode(id: b.id));
    expect(await form().saveChain(), isTrue);
    expect(
      (await h.services.settings.device()).selectedConfigurationId,
      SelfSource.id,
    );
  });
}
