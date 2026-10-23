// Key formats the core checks as it loads a plan (D84).
import 'package:av_core/av_core.dart';
import 'package:test/test.dart';

void main() {
  test('an imported node with a malformed key is unavailable', () {
    NodeDef node(String key, NodeParams params) => NodeDef(
      key: key,
      name: key,
      server: 'a.example.com',
      port: 443,
      params: params,
    );
    final content = ConfigContent(
      nodes: [
        node(
          'bad-reality',
          const NodeParams.vless(
            uuid: Secret('00000000-0000-0000-0000-000000000000'),
            tls: Tls(
              serverName: 'www.apple.com',
              reality: Reality(publicKey: 'PK'),
            ),
          ),
        ),
        node(
          'bad-2022',
          const NodeParams.shadowsocks(
            method: '2022-blake3-aes-128-gcm',
            password: Secret('fake'),
          ),
        ),
        node(
          'good',
          const NodeParams.shadowsocks(
            method: 'aes-256-gcm',
            password: Secret('fake'),
          ),
        ),
      ],
      finalTarget: ContentKeys.direct,
    );
    final catalog = MemberCatalog(configurationId: 'c', content: content);
    String? reason(String key) =>
        catalog.unavailable(MemberRef.source(configurationId: 'c', key: key));
    expect(reason('bad-reality'), 'reality-key');
    expect(reason('bad-2022'), 'shadowsocks-key');
    expect(reason('good'), isNull);
  });
}
