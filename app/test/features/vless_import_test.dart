// Fake VLESS Reality credentials exercise the actual form, encrypted
// repository, editor and Android plan without contacting a proxy server.
import 'package:av_core/av_core.dart';
import 'package:avalon/app/routes.dart';
import 'package:avalon/features/add/add_state.dart';
import 'package:avalon/features/add/add_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness.dart';

const _uuid = '00000000-0000-4000-8000-000000000001';
const _publicKey = 'fakeRealityPublicKey0000000000000000000000A';
const _shortId = '0a1b';
const _link =
    'vless://$_uuid@proxy.example.com:443'
    '?encryption=none&flow=xtls-rprx-vision&type=tcp&headerType=none'
    '&security=reality&sni=cover.example.com&fp=chrome'
    '&pbk=$_publicKey&sid=$_shortId&udp=true#Example';
const _params = NodeParams.vless(
  uuid: Secret(_uuid),
  flow: 'xtls-rprx-vision',
  transport: Transport.tcp(),
  tls: Tls(
    serverName: 'cover.example.com',
    fingerprint: 'chrome',
    reality: Reality(publicKey: _publicKey, shortId: _shortId),
  ),
);

void main() {
  late Harness h;
  setUp(() async {
    h = await Harness.start(platform: HostPlatform.android);
    h.container.listen(addViewModelProvider, (_, _) {});
  });
  tearDown(() => h.stop());

  AddViewModel form() => h.container.read(addViewModelProvider.notifier);

  test(
    'Reality link survives save, reopen editor and Android compile',
    () async {
      form()
        ..setSegment(AddSegment.node)
        ..setLink(_link)
        ..parseLink();
      final parsed = h.container.read(addViewModelProvider);
      expect(parsed.linkError, isNull);
      expect(parsed.node.protocol, Protocol.vless);
      expect(parsed.node.transport, TransportKind.tcp);
      expect(parsed.node.effectiveSecurity, NodeSecurity.reality);
      expect(await form().saveNode(), isTrue);

      final node = (await h.services.selfContent.nodes()).single;
      expect(node.params, _params);
      final row = await h.services.db
          .select(h.services.db.selfNodes)
          .getSingle();
      expect(row.paramsJson.contains(_uuid), isFalse);
      expect(await h.services.secrets.get(row.secretId), containsValue(_uuid));

      h.container.invalidate(addViewModelProvider);
      await form().beginEdit(EditTarget(EditKind.node, node.id));
      final editing = h.container.read(addViewModelProvider);
      expect(editing.node[NodeField.uuid], isEmpty);
      expect(editing.node[NodeField.publicKey], _publicKey);
      expect(editing.node[NodeField.shortId], _shortId);
      expect(editing.node[NodeField.flow], 'xtls-rprx-vision');
      expect(editing.node.transport, TransportKind.tcp);
      expect(editing.node.effectiveSecurity, NodeSecurity.reality);
      form().setNodeField(NodeField.name, 'Renamed example');
      expect(await form().saveNode(), isTrue);

      final saved = (await h.services.selfContent.nodes()).single;
      expect(saved.id, node.id);
      expect(saved.name, 'Renamed example');
      expect(saved.params, _params);
      final plan = await h.services.plans.compileSelected();
      final outbound = (plan.toJson()['outbounds']! as List)
          .cast<Map<String, Object?>>()
          .singleWhere((o) => o['type'] == 'vless');
      expect(outbound['tag'], 's:${saved.id}');
      expect(outbound['uuid'], _uuid);
      expect(outbound['flow'], 'xtls-rprx-vision');
      expect(outbound['tls'], {
        'enabled': true,
        'server_name': 'cover.example.com',
        'utls': {'enabled': true, 'fingerprint': 'chrome'},
        'reality': {
          'enabled': true,
          'public_key': _publicKey,
          'short_id': _shortId,
        },
      });
      // TCP is the default transport; the enabled UDP compatibility flag
      // does not narrow the outbound's default TCP and UDP capabilities.
      expect(outbound.containsKey('transport'), isFalse);
      expect(outbound.containsKey('network'), isFalse);
      expect(outbound.containsKey('udp'), isFalse);
    },
  );
}
