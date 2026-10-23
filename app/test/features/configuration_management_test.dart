import 'package:av_core/av_core.dart';
import 'package:avalon/app/providers.dart';
import 'package:avalon/features/configurations/self_content_management_state.dart';
import 'package:avalon/features/configurations/self_content_management_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

const _node = SelfNode(
  id: '',
  name: '入口',
  server: 'node.example.com',
  port: 443,
  params: NodeParams.trojan(password: Secret('fixture-password')),
);

void main() {
  late Harness h;

  setUp(() async {
    h = await Harness.start();
    h.container.listen(selfContentManagementStateProvider, (_, _) {});
  });
  tearDown(() => h.stop());

  Future<SelfContentManagementState> shown(
    bool Function(SelfContentManagementState) ready,
  ) => h.settle(
    () => h.container.read(selfContentManagementStateProvider),
    (state) => !state.loading && ready(state),
  );

  test(
    'lists all saved nodes and chains without selecting a configuration',
    () async {
      final a = await h.services.selfService.addNode(_node);
      final b = await h.services.selfService.addNode(
        _node.copyWith(name: '出口'),
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
      await h.services.settings.updateDevice(
        (settings) => settings.copyWith(selectedConfigurationId: null),
      );

      var state = await shown(
        (s) => s.nodes.length == 2 && s.chains.length == 1,
      );
      expect(state.nodes.map((item) => item.ref), [
        MemberRef.selfNode(id: a.id),
        MemberRef.selfNode(id: b.id),
      ]);
      expect(state.nodes.map((item) => item.protocol), [
        Protocol.trojan,
        Protocol.trojan,
      ]);
      expect(state.chains.single.ref, MemberRef.chain(id: chain.id));
      expect(state.chains.single.name, '入口 → 出口');
      expect(state.chains.single.hops, 2);
      expect(
        (await h.services.settings.device()).selectedConfigurationId,
        isNull,
      );

      await h.services.selfContent.updateNode(a.copyWith(name: '新入口'));
      state = await shown((s) => s.chains.single.name == '新入口 → 出口');
      expect(state.nodes.first.name, '新入口');
      await h.services.selfContent.updateChain(chain.copyWith(name: '常用链路'));
      await shown((s) => s.chains.single.name == '常用链路');

      await h.services.selfContent.deleteChain(chain.id);
      await h.services.selfContent.deleteNode(a.id);
      await h.services.selfContent.deleteNode(b.id);
      state = await shown((s) => s.nodes.isEmpty && s.chains.isEmpty);
      expect(state.error, isNull);
      expect(
        (await h.services.settings.device()).selectedConfigurationId,
        isNull,
      );
    },
  );

  test(
    'default chain names resolve imported hops outside the selected configuration',
    () async {
      final source = await h.services.imports.addFile(
        text: 'trojan://fixture@source.example.com:443#订阅入口',
        defaultName: '来源',
      );
      final content = (await h.services.configurations.content(
        source.configurationId,
      ))!.content;
      final node = await h.services.selfService.addNode(
        _node.copyWith(name: '落地'),
      );
      await h.services.selfService.addChain(
        Chain(
          id: '',
          hops: [
            MemberRef.source(
              configurationId: source.configurationId,
              key: content.nodes.single.key,
            ),
            MemberRef.selfNode(id: node.id),
          ],
        ),
      );
      await h.services.settings.updateDevice(
        (settings) => settings.copyWith(selectedConfigurationId: null),
      );
      final state = await shown(
        (s) => s.chains.length == 1 && s.chains.single.name == '订阅入口 → 落地',
      );
      expect(state.nodes.single.name, '落地');
      expect(
        h.container.read(deviceSettingsProvider).value?.selectedConfigurationId,
        isNull,
      );
    },
  );
}
