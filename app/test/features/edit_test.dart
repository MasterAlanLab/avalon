// Editing and deleting (PRODUCT_SPEC §3.4): the form's and the proxies
// page's view models down to the database.
import 'package:av_core/av_core.dart';
import 'package:avalon/app/routes.dart';
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
  - {name: 节点选择, type: select, proxies: [香港 01, 日本 01]}
  - {name: 流媒体, type: select, proxies: [香港 01, 日本 01]}
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
    container.listen(addViewModelProvider, (_, _) {});
    container.listen(chainOptionsProvider, (_, _) {});
    container.listen(proxiesStateProvider, (_, _) {});
  });
  tearDown(() => h.stop());

  AddViewModel form() => container.read(addViewModelProvider.notifier);
  AddState state() => container.read(addViewModelProvider);

  Future<String> addSubscription() async {
    form().setUrl('${h.base}/sub');
    expect(await form().saveSubscription(defaultName: '新订阅'), isNotNull);
    container.invalidate(addViewModelProvider);
    return (await h.services.settings.device()).selectedConfigurationId!;
  }

  Future<ProxiesState> proxies(bool Function(ProxiesState s) ready) => h.settle(
    () => container.read(proxiesStateProvider),
    (s) => !s.loading && ready(s),
  );

  group('subscription', () {
    test('opens prefilled; saving keeps the id and downloads once', () async {
      final id = await addSubscription();
      await form().beginEdit(EditTarget(EditKind.configuration, id));
      expect(state().loading, isFalse);
      expect(state().segment, AddSegment.subscription);
      expect(state().url, '${h.base}/sub');
      expect(state().name, '新订阅');
      expect(state().autoUpdate, isTrue);
      expect(state().fileOnly, isFalse);

      final before = h.requests;
      h.body = _clash.replaceAll('香港 01', '香港 02');
      form()
        ..setName('我的机场')
        ..setAutoUpdate(false);
      expect(await form().saveSubscription(defaultName: '新订阅'), isEmpty);
      expect(h.requests, before + 1);

      final c = (await h.services.configurations.get(id))!;
      expect(c.name, '我的机场');
      expect(c.autoUpdate, isFalse);
      final content = (await h.services.configurations.content(id))!.content;
      expect(content.nodes.first.name, '香港 02');
      // Still one configuration, still selected.
      expect(await h.services.configurations.watchAll().first, hasLength(2));
      expect((await h.services.settings.device()).selectedConfigurationId, id);
    });

    test('a failed download still keeps the edit', () async {
      final id = await addSubscription();
      await form().beginEdit(EditTarget(EditKind.configuration, id));
      h.status = 500;
      form().setName('改名');
      expect(await form().saveSubscription(defaultName: '新订阅'), isEmpty);
      final c = (await h.services.configurations.get(id))!;
      expect(c.name, '改名');
      expect(c.lastError, 'fetch.httpStatus.500');
    });

    test('a local file configuration only renames', () async {
      final added = await h.services.imports.addFile(
        text: _clash,
        defaultName: '新订阅',
        fileName: 'home.yaml',
      );
      await form().beginEdit(
        EditTarget(EditKind.configuration, added.configurationId),
      );
      expect(state().fileOnly, isTrue);
      expect(state().canSave, isTrue);
      final before = h.requests;
      form().setName('家里');
      expect(await form().saveSubscription(defaultName: '新订阅'), isEmpty);
      expect(h.requests, before);
      expect(
        (await h.services.configurations.get(added.configurationId))!.name,
        '家里',
      );
    });
  });

  group('node', () {
    test('secrets stay hidden and are kept when left empty', () async {
      final node = await h.services.selfService.addNode(_self);
      await form().beginEdit(EditTarget(EditKind.node, node.id));
      expect(state().segment, AddSegment.node);
      expect(state().node[NodeField.server], 'vps.example.com');
      expect(state().node[NodeField.password], '');
      expect(state().savedSecrets, {NodeField.password});

      form()
        ..setNodeField(NodeField.name, '东京')
        ..setNodeField(NodeField.port, '8443');
      expect(await form().saveNode(), isTrue);
      final saved = (await h.services.selfContent.nodes()).single;
      expect(saved.id, node.id);
      expect(saved.name, '东京');
      expect(saved.port, 8443);
      expect(
        (saved.params as TrojanParams).password,
        const Secret('fake-self'),
      );
    });

    test('another protocol needs its own secrets', () async {
      final node = await h.services.selfService.addNode(_self);
      await form().beginEdit(EditTarget(EditKind.node, node.id));
      form().setProtocol(Protocol.anytls);
      expect(state().savedSecrets, isEmpty);
      expect(await form().saveNode(), isFalse);
      expect(state().nodeError!.field, NodeField.password);
      // Back to the saved protocol, the secret counts again.
      form().setProtocol(Protocol.trojan);
      expect(state().savedSecrets, {NodeField.password});
      expect(await form().saveNode(), isTrue);
    });
  });

  group('chain', () {
    test('opens with its hops and groups; saving replaces them', () async {
      final id = await addSubscription();
      final node = await h.services.selfService.addNode(_self);
      final options = await h.settle(
        () => container.read(chainOptionsProvider),
        (ChainOptions o) => o.hops.length == 3,
      );
      final a = options.hops[0].ref;
      final b = options.hops[1].ref;
      final chain = await h.services.selfService.addChain(
        Chain(
          id: '',
          hops: [
            a,
            MemberRef.selfNode(id: node.id),
          ],
        ),
        groupKeys: {options.groups[0].key},
      );

      await form().beginEdit(EditTarget(EditKind.chain, chain.id));
      expect(state().segment, AddSegment.chain);
      expect(state().chain.hops, [a, MemberRef.selfNode(id: node.id)]);
      expect(state().chain.groups, {options.groups[0].key});

      form()
        ..setChainName('回国')
        ..addHop(b)
        ..moveHop(2, -1)
        ..toggleChainGroup(options.groups[0].key)
        ..toggleChainGroup(options.groups[1].key);
      expect(await form().saveChain(), isTrue);

      final saved = (await h.services.selfContent.chains()).single;
      expect(saved.id, chain.id);
      expect(saved.name, '回国');
      expect(saved.hops, [a, b, MemberRef.selfNode(id: node.id)]);
      final memberships = [
        for (final m in await h.services.selfContent.watchMemberships().first)
          if (m.ownerKind == MemberOwner.chain) (m.configurationId, m.groupKey),
      ];
      expect(memberships, [(id, options.groups[1].key)]);
    });
  });

  group('conflicts and missing objects', () {
    test(
      'a change made meanwhile reloads the form instead of saving',
      () async {
        final node = await h.services.selfService.addNode(_self);
        await form().beginEdit(EditTarget(EditKind.node, node.id));
        // Someone else edits it while the form is open.
        await Future<void>.delayed(const Duration(milliseconds: 5));
        await h.services.selfContent.updateNode(node.copyWith(name: '别处改的'));
        form().setNodeField(NodeField.name, '这里改的');
        expect(await form().saveNode(), isFalse);
        expect(state().error!.code, 'edit.conflict');
        expect(state().node[NodeField.name], '别处改的');
        expect((await h.services.selfContent.nodes()).single.name, '别处改的');

        // Saving again works on the reloaded object.
        form().setNodeField(NodeField.name, '再改');
        expect(await form().saveNode(), isTrue);
        expect((await h.services.selfContent.nodes()).single.name, '再改');
      },
    );

    test('an object that is gone cannot be saved', () async {
      await form().beginEdit(const EditTarget(EditKind.node, 'nope'));
      expect(state().error!.code, 'edit.missing');
      expect(state().canSave, isFalse);
      expect(await form().saveNode(), isFalse);
    });
  });

  group('deleting from 「自定义」', () {
    test('a node used by chains stays; the chains are named', () async {
      final a = await h.services.selfService.addNode(_self);
      final b = await h.services.selfService.addNode(
        _self.copyWith(name: '落地机'),
      );
      final chain = await h.services.selfService.addChain(
        Chain(
          id: '',
          hops: [
            MemberRef.selfNode(id: a.id),
            MemberRef.selfNode(id: b.id),
          ],
        ),
      );
      final shown = await proxies((s) => s.group?.members.length == 3);
      final model = container.read(proxiesViewModelProvider.notifier);

      final refused = await model.delete(MemberRef.selfNode(id: a.id));
      expect(refused, isA<NodeInUse>());
      expect((refused as NodeInUse).chainIds, [chain.id]);
      expect(shown.chainName(chain.id), '自建 VPS → 落地机');
      expect(await h.services.selfContent.nodes(), hasLength(2));

      expect(await model.delete(MemberRef.chain(id: chain.id)), isA<Deleted>());
      expect(await model.delete(MemberRef.selfNode(id: a.id)), isA<Deleted>());
      final s = await proxies((s) => s.group?.members.length == 1);
      expect(s.group!.members.single.name, '落地机');
    });
  });
}
