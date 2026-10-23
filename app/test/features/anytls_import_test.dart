// Share-link TLS policy must survive the form, encrypted storage, editing,
// and the Android plan sent to the host.
import 'package:av_core/av_core.dart';
import 'package:avalon/app/routes.dart';
import 'package:avalon/features/add/add_state.dart';
import 'package:avalon/features/add/add_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

const _link =
    'anytls://fake-password@proxy.example.com:443'
    '?insecure=1&sni=tls.example.com&udp=true&alpn=h2&fp=chrome#Test';

void main() {
  late Harness h;
  setUp(() async {
    h = await Harness.start(platform: HostPlatform.android);
    h.container.listen(addViewModelProvider, (_, _) {});
  });
  tearDown(() => h.stop());

  AddViewModel form() => h.container.read(addViewModelProvider.notifier);

  Future<Map<String, Object?>> outbound() async {
    final plan = await h.services.plans.compileSelected();
    return (plan.toJson()['outbounds']! as List)
        .cast<Map<String, Object?>>()
        .singleWhere((o) => o['type'] == 'anytls');
  }

  test(
    'link TLS policy survives save, reopen, edit and Android compile',
    () async {
      form()
        ..setSegment(AddSegment.node)
        ..setLink(_link)
        ..parseLink();
      expect(h.container.read(addViewModelProvider).linkError, isNull);
      expect(await form().saveNode(), isTrue);
      final node = (await h.services.selfContent.nodes()).single;
      expect((node.params as AnyTlsParams).tls.insecure, isTrue);

      h.container.invalidate(addViewModelProvider);
      await form().beginEdit(EditTarget(EditKind.node, node.id));
      expect(
        h.container.read(addViewModelProvider).node[NodeField.password],
        isEmpty,
      );
      form().setNodeField(NodeField.name, 'Renamed');
      expect(await form().saveNode(), isTrue);
      final saved = (await h.services.selfContent.nodes()).single;
      expect(saved.id, node.id);
      expect(saved.name, 'Renamed');
      expect(
        (saved.params as AnyTlsParams).password,
        const Secret('fake-password'),
      );

      final o = await outbound();
      expect(o['tls'], {
        'enabled': true,
        'server_name': 'tls.example.com',
        'insecure': true,
        'alpn': ['h2'],
        'utls': {'enabled': true, 'fingerprint': 'chrome'},
      });
      expect(o.containsKey('udp'), isFalse);
      expect(o.containsKey('network'), isFalse);
    },
  );

  test('reparsing repairs an old node and honors the new TLS policy', () async {
    final old = await h.services.selfService.addNode(
      const SelfNode(
        id: '',
        name: 'Old',
        server: 'proxy.example.com',
        port: 443,
        params: NodeParams.anytls(
          password: Secret('fake-password'),
          tls: Tls(serverName: 'tls.example.com'),
        ),
      ),
    );

    for (final insecure in [true, false]) {
      h.container.invalidate(addViewModelProvider);
      await form().beginEdit(EditTarget(EditKind.node, old.id));
      form()
        ..setLink(
          _link.replaceFirst('insecure=1', 'insecure=${insecure ? 1 : 0}'),
        )
        ..parseLink();
      expect(h.container.read(addViewModelProvider).linkError, isNull);
      expect(await form().saveNode(), isTrue);
      final saved = (await h.services.selfContent.nodes()).single;
      expect(saved.id, old.id);
      expect((saved.params as AnyTlsParams).tls.insecure, insecure);
      expect(
        (await h.services.settings.device()).selectedConfigurationId,
        SelfSource.id,
      );
      final tls = (await outbound())['tls']! as Map;
      expect(tls['insecure'] ?? false, insecure);
    }
  });
}
