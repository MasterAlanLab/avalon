// Share links from CONFIG_PIPELINE §4. All credentials are fake.
import 'dart:convert';

import 'package:av_core/av_core.dart';
import 'package:test/test.dart';

const _uuid = '00000000-0000-4000-8000-000000000001';

Matcher _rejects(ImportErrorCode code, [String? field]) => throwsA(
  isA<ImportException>()
      .having((e) => e.code, 'code', code)
      .having((e) => e.field, 'field', field),
);

void main() {
  group('vless', () {
    test('reality over tcp with flow', () {
      final n = parseShareLink(
        'vless://$_uuid@example.com:443?type=tcp&security=reality'
        '&sni=www.apple.com&pbk=PUBKEY&sid=ab12&flow=xtls-rprx-vision'
        '&fp=chrome&encryption=none#%E9%A6%99%E6%B8%AF%2001',
      );
      expect(n.name, '香港 01');
      expect(n.server, 'example.com');
      expect(n.port, 443);
      expect(
        n.params,
        const NodeParams.vless(
          uuid: Secret(_uuid),
          flow: 'xtls-rprx-vision',
          tls: Tls(
            serverName: 'www.apple.com',
            fingerprint: 'chrome',
            reality: Reality(publicKey: 'PUBKEY', shortId: 'ab12'),
          ),
        ),
      );
    });

    test('UDP enabled flags retain Reality, Vision and TCP transport', () {
      for (final flag in ['true', '1', 'yes', 'TRUE', '%74rue']) {
        final node = parseShareLink(
          'vless://$_uuid@proxy.example.com:443?encryption=none'
          '&flow=xtls-rprx-vision&fp=chrome&security=reality'
          '&pbk=fakeRealityPublicKey0000000000000000000000A'
          '&sid=0a1b&sni=cover.example.com&type=tcp&udp=$flag#Example',
        );
        expect(node.name, 'Example');
        expect(
          node.params,
          const NodeParams.vless(
            uuid: Secret(_uuid),
            flow: 'xtls-rprx-vision',
            transport: Transport.tcp(),
            tls: Tls(
              serverName: 'cover.example.com',
              fingerprint: 'chrome',
              reality: Reality(
                publicKey: 'fakeRealityPublicKey0000000000000000000000A',
                shortId: '0a1b',
              ),
            ),
          ),
        );
      }
    });

    test('disabled, invalid and conflicting UDP flags are rejected', () {
      for (final query in [
        'udp=false',
        'udp=0',
        'udp=no',
        'udp=invalid',
        'udp=',
        'udp',
        'udp=true&udp=false',
        'udp=false&udp=true',
      ]) {
        expect(
          () => parseShareLink('vless://$_uuid@proxy.example.com:443?$query'),
          _rejects(ImportErrorCode.unsupportedValue, 'udp'),
        );
      }
    });

    test('UDP-enabled link lists retain the node', () {
      final parsed = parseContent(
        'vless://$_uuid@proxy.example.com:443?udp=true#accepted\n'
        'vless://$_uuid@proxy.example.com:443?udp=false#unsupported',
      );
      expect(parsed.content.nodes.single.name, 'accepted');
      expect(
        parsed.content.warnings,
        contains(
          const ImportWarning(
            kind: WarningKind.unreadableEntry,
            subject: 'udp',
          ),
        ),
      );
    });

    test('websocket with TLS and early data in the path', () {
      final n = parseShareLink(
        'vless://$_uuid@[2001:db8::1]:8443?type=ws&security=tls'
        '&path=%2Fws%3Fed%3D2048&host=cdn.example.com&sni=cdn.example.com',
      );
      expect(n.server, '2001:db8::1');
      final p = n.params as VlessParams;
      expect(
        p.transport,
        const Transport.ws(
          path: '/ws',
          host: 'cdn.example.com',
          maxEarlyData: 2048,
          earlyDataHeader: 'Sec-WebSocket-Protocol',
        ),
      );
      expect(p.tls, const Tls(serverName: 'cdn.example.com'));
    });

    test('grpc service name', () {
      final p =
          parseShareLink(
                'vless://$_uuid@example.com:443?type=grpc&serviceName=gun'
                '&security=tls&mode=gun',
              ).params
              as VlessParams;
      expect(p.transport, const Transport.grpc(serviceName: 'gun'));
    });

    test('reality without a public key is rejected', () {
      expect(
        () => parseShareLink(
          'vless://$_uuid@example.com:443?security=reality&sni=a.com',
        ),
        _rejects(ImportErrorCode.missingField, 'pbk'),
      );
    });

    test('unknown parameters are reported by name, not dropped', () {
      expect(
        () => parseShareLink('vless://$_uuid@example.com:443?foo=1'),
        _rejects(ImportErrorCode.unknownParameter, 'foo'),
      );
    });

    test('unsupported transports and encryption are rejected', () {
      expect(
        () => parseShareLink('vless://$_uuid@example.com:443?type=kcp'),
        _rejects(ImportErrorCode.unsupportedValue, 'type'),
      );
      expect(
        () => parseShareLink(
          'vless://$_uuid@example.com:443?encryption=aes-128-gcm',
        ),
        _rejects(ImportErrorCode.unsupportedValue, 'encryption'),
      );
      expect(
        () => parseShareLink(
          'vless://$_uuid@example.com:443?type=tcp&headerType=http',
        ),
        _rejects(ImportErrorCode.unsupportedValue, 'headerType'),
      );
    });

    test('missing port', () {
      expect(
        () => parseShareLink('vless://$_uuid@example.com'),
        _rejects(ImportErrorCode.missingField, 'port'),
      );
    });
  });

  group('vmess', () {
    String link(Map<String, Object> j) =>
        'vmess://${base64.encode(utf8.encode(jsonEncode(j)))}';

    test('v2 JSON with websocket and TLS', () {
      final n = parseShareLink(
        link({
          'v': '2',
          'ps': '日本 东京',
          'add': 'jp.example.com',
          'port': '443',
          'id': _uuid,
          'aid': '0',
          'scy': 'auto',
          'net': 'ws',
          'type': 'none',
          'host': 'jp.example.com',
          'path': '/v',
          'tls': 'tls',
          'sni': 'jp.example.com',
        }),
      );
      expect(n.name, '日本 东京');
      expect(n.port, 443);
      expect(
        n.params,
        const NodeParams.vmess(
          uuid: Secret(_uuid),
          transport: Transport.ws(path: '/v', host: 'jp.example.com'),
          tls: Tls(serverName: 'jp.example.com'),
        ),
      );
    });

    test('URL-safe Base64 without padding, numeric port', () {
      final raw = base64Url
          .encode(
            utf8.encode(
              jsonEncode({
                'add': '1.2.3.4',
                'port': 10086,
                'id': _uuid,
                'aid': 1,
                'net': 'tcp',
              }),
            ),
          )
          .replaceAll('=', '');
      final n = parseShareLink('vmess://$raw');
      expect((n.params as VmessParams).alterId, 1);
      expect(n.name, isNull);
    });

    test('unknown JSON keys and bad Base64', () {
      expect(
        () => parseShareLink(
          link({'add': 'a.com', 'port': '1', 'id': _uuid, 'xyz': '1'}),
        ),
        _rejects(ImportErrorCode.unknownParameter, 'xyz'),
      );
      expect(
        () => parseShareLink('vmess://%%%'),
        _rejects(ImportErrorCode.malformed),
      );
    });
  });

  test('trojan with grpc', () {
    final n = parseShareLink(
      'trojan://pa%2Bss@example.com:443?type=grpc&serviceName=svc'
      '&sni=example.com#Trojan',
    );
    expect(
      n.params,
      const NodeParams.trojan(
        password: Secret('pa+ss'),
        transport: Transport.grpc(serviceName: 'svc'),
        tls: Tls(serverName: 'example.com'),
      ),
    );
  });

  group('shadowsocks', () {
    const expected = NodeParams.shadowsocks(
      method: 'aes-256-gcm',
      password: Secret('secret'),
    );

    test('SIP002 Base64 user info', () {
      final info = base64Url
          .encode(utf8.encode('aes-256-gcm:secret'))
          .replaceAll('=', '');
      final n = parseShareLink('ss://$info@1.2.3.4:8388#SS');
      expect(n.params, expected);
      expect((n.name, n.server, n.port), ('SS', '1.2.3.4', 8388));
    });

    test('percent-encoded user info (2022 ciphers) with a plugin', () {
      final n = parseShareLink(
        'ss://2022-blake3-aes-128-gcm:AAAA%2Bkey%3D@example.com:443/'
        '?plugin=obfs-local%3Bobfs%3Dhttp%3Bobfs-host%3Dbing.com',
      );
      expect(
        n.params,
        const NodeParams.shadowsocks(
          method: '2022-blake3-aes-128-gcm',
          password: Secret('AAAA+key='),
          plugin: 'obfs-local',
          pluginOpts: 'obfs=http;obfs-host=bing.com',
        ),
      );
    });

    test('legacy whole-link Base64', () {
      final body = base64.encode(
        utf8.encode('aes-256-gcm:secret@1.2.3.4:8388'),
      );
      final n = parseShareLink('ss://$body#Legacy');
      expect(n.params, expected);
      expect((n.name, n.server, n.port), ('Legacy', '1.2.3.4', 8388));
    });
  });

  test('hysteria2 with obfs and port hopping (hy2 alias)', () {
    final n = parseShareLink(
      'hy2://auth@example.com:443?obfs=salamander&obfs-password=ob'
      '&sni=example.com&insecure=1&mport=20000-30000#HY2',
    );
    expect(
      n.params,
      const NodeParams.hysteria2(
        password: Secret('auth'),
        obfsPassword: Secret('ob'),
        serverPorts: ['20000:30000'],
        tls: Tls(serverName: 'example.com', insecure: true),
      ),
    );
  });

  test('tuic', () {
    final n = parseShareLink(
      'tuic://$_uuid:pw@example.com:443?congestion_control=cubic'
      '&alpn=h3&sni=example.com#TUIC',
    );
    expect(
      n.params,
      const NodeParams.tuic(
        uuid: Secret(_uuid),
        password: Secret('pw'),
        congestionControl: 'cubic',
        tls: Tls(serverName: 'example.com', alpn: ['h3']),
      ),
    );
    expect(
      () => parseShareLink('tuic://$_uuid@example.com:443'),
      _rejects(ImportErrorCode.missingField, 'password'),
    );
  });

  test('socks5 plain and Base64 credentials, http and https', () {
    expect(
      parseShareLink('socks5://user:pass@127.0.0.1:1080').params,
      const NodeParams.socks5(username: 'user', password: Secret('pass')),
    );
    final b64 = base64.encode(utf8.encode('user:pass'));
    expect(
      parseShareLink('socks://$b64@127.0.0.1:1080').params,
      const NodeParams.socks5(username: 'user', password: Secret('pass')),
    );
    expect(
      parseShareLink('http://proxy.example.com:8080').params,
      const NodeParams.http(),
    );
    expect(
      parseShareLink('https://u:p@proxy.example.com:443').params,
      const NodeParams.http(username: 'u', password: Secret('p'), tls: Tls()),
    );
  });

  test('anytls', () {
    expect(
      parseShareLink('anytls://pw@example.com:443?sni=example.com').params,
      const NodeParams.anytls(
        password: Secret('pw'),
        tls: Tls(serverName: 'example.com'),
      ),
    );
  });

  test('AnyTLS accepts UDP enabled flags without changing TLS parameters', () {
    for (final flag in ['true', '1', 'yes', 'TRUE', '%74rue']) {
      final node = parseShareLink(
        'anytls://fake-password@example.com:443?insecure=1'
        '&sni=tls.example.com&alpn=h2&fp=chrome&udp=$flag#AnyTLS%20test',
      );
      expect(node.name, 'AnyTLS test');
      expect(node.server, 'example.com');
      expect(node.port, 443);
      expect(
        node.params,
        const NodeParams.anytls(
          password: Secret('fake-password'),
          tls: Tls(
            serverName: 'tls.example.com',
            insecure: true,
            alpn: ['h2'],
            fingerprint: 'chrome',
          ),
        ),
      );
    }
  });

  test('AnyTLS refuses disabled, empty and invalid UDP flags', () {
    for (final query in [
      'udp=false',
      'udp=0',
      'udp=no',
      'udp=invalid',
      'udp=',
      'udp',
      'udp=true&udp=false',
      'udp=false&udp=true',
    ]) {
      expect(
        () => parseShareLink('anytls://fake-password@example.com:443?$query'),
        _rejects(ImportErrorCode.unsupportedValue, 'udp'),
      );
    }
  });

  test(
    'UDP compatibility is limited to supported schemes and known parameters',
    () {
      expect(
        () => parseShareLink('trojan://fake-password@example.com:443?udp=true'),
        _rejects(ImportErrorCode.unknownParameter, 'udp'),
      );
      expect(
        () =>
            parseShareLink('vless://$_uuid@example.com:443?udp=true&unknown=1'),
        _rejects(ImportErrorCode.unknownParameter, 'unknown'),
      );
      expect(
        () => parseShareLink(
          'anytls://fake-password@example.com:443?udp=true&unknown=1',
        ),
        _rejects(ImportErrorCode.unknownParameter, 'unknown'),
      );
    },
  );

  test('AnyTLS link lists keep UDP-enabled nodes and TLS warnings', () {
    final parsed = parseContent(
      'anytls://fake-password@example.com:443?udp=true&insecure=1#accepted\n'
      'anytls://fake-password@example.com:443?udp=false#unsupported',
    );
    expect(parsed.content.nodes.single.name, 'accepted');
    expect(
      parsed.content.warnings,
      contains(const ImportWarning(kind: WarningKind.insecureTls)),
    );
    expect(
      parsed.content.warnings,
      contains(
        const ImportWarning(kind: WarningKind.unreadableEntry, subject: 'udp'),
      ),
    );
  });

  test('unsupported schemes are not guessed as VLESS', () {
    expect(
      () => parseShareLink('ssr://abc'),
      _rejects(ImportErrorCode.unsupportedScheme),
    );
    expect(
      () => parseShareLink('example.com:443'),
      _rejects(ImportErrorCode.unsupportedScheme),
    );
  });
}
