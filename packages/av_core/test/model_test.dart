import 'dart:convert';

import 'package:av_core/av_core.dart';
import 'package:test/test.dart';

void main() {
  const content = ConfigContent(
    nodes: [
      NodeDef(
        key: 'proxy:A',
        name: 'A',
        server: 'a.example.com',
        port: 443,
        params: NodeParams.vless(
          uuid: Secret('00000000-0000-4000-8000-000000000001'),
          transport: Transport.ws(path: '/ws'),
          tls: Tls(
            serverName: 'a.example.com',
            reality: Reality(publicKey: 'PK'),
          ),
        ),
      ),
      NodeDef(
        key: 'proxy:B',
        name: 'B',
        server: 'b.example.com',
        port: 8388,
        params: NodeParams.shadowsocks(
          method: 'aes-256-gcm',
          password: Secret('fake-password'),
        ),
        detourKey: 'proxy:A',
      ),
    ],
    groups: [
      GroupDef(
        key: 'group:Proxy',
        name: 'Proxy',
        type: GroupType.selector,
        displayType: 'Selector',
        members: ['proxy:A', 'proxy:B', ContentKeys.direct],
      ),
    ],
    rules: [
      RuleDef(ruleSet: ['geosite-cn'], target: ContentKeys.direct),
    ],
    finalTarget: 'group:Proxy',
    warnings: [ImportWarning(kind: WarningKind.insecureTls, count: 2)],
  );

  test('secrets are lifted out of model JSON and restored', () {
    final (:public, :secrets) = SecretCodec.split(content.toJson());
    final stored = jsonEncode(public);
    expect(stored, isNot(contains('fake-password')));
    expect(stored, isNot(contains('00000000-0000-4000-8000-000000000001')));
    expect(secrets.values, contains('fake-password'));

    final joined = SecretCodec.join(jsonDecode(stored), secrets);
    expect(ConfigContent.fromJson(joined! as Map<String, dynamic>), content);
    expect(
      () => SecretCodec.join(jsonDecode(stored), const {}),
      throwsStateError,
    );
  });

  test('secrets never print', () {
    expect('${const Secret('fake-password')}', isNot(contains('fake')));
    expect('${content.nodes[1]}', isNot(contains('fake-password')));
  });
}
