// The node form's rules (PRODUCT_SPEC §3.6).
import 'package:av_core/av_core.dart';
import 'package:test/test.dart';

const _uuid = '00000000-0000-4000-8000-000000000001';
const _pk = 'fakeRealityPublicKey0000000000000000000000A';

Matcher _fails(NodeField field, NodeDraftError error) => throwsA(
  isA<NodeDraftException>()
      .having((e) => e.field, 'field', field)
      .having((e) => e.error, 'error', error),
);

NodeDraft _fill(NodeDraft d, Map<NodeField, String> values) =>
    values.entries.fold(d, (d, e) => d.set(e.key, e.value));

void main() {
  test('builds a VLESS Reality node; the name falls back to the address', () {
    final d = _fill(const NodeDraft(), {
      NodeField.server: ' vps.example.com ',
      NodeField.uuid: _uuid,
      NodeField.flow: 'xtls-rprx-vision',
      NodeField.sni: 'www.apple.com',
      NodeField.publicKey: _pk,
      NodeField.shortId: '0a1b',
    });
    final node = d.build();
    expect(node.id, '');
    expect(node.name, 'vps.example.com');
    expect(node.server, 'vps.example.com');
    expect(node.port, 443);
    expect(
      node.params,
      const NodeParams.vless(
        uuid: Secret(_uuid),
        flow: 'xtls-rprx-vision',
        tls: Tls(
          serverName: 'www.apple.com',
          reality: Reality(publicKey: _pk, shortId: '0a1b'),
        ),
      ),
    );
    expect(d.set(NodeField.name, '东京').build().name, '东京');
  });

  test('builds each protocol from its required fields', () {
    NodeDraft base(Protocol p, Map<NodeField, String> v) => _fill(
      const NodeDraft().copyWith(protocol: p, security: NodeSecurity.none),
      {NodeField.server: 'a.example.com', ...v},
    );
    expect(
      base(Protocol.hysteria2, {
        NodeField.password: 'fake',
        NodeField.upMbps: '50',
        NodeField.sni: 'a.example.com',
      }).build().params,
      const NodeParams.hysteria2(
        password: Secret('fake'),
        upMbps: 50,
        tls: Tls(serverName: 'a.example.com'),
      ),
    );
    expect(
      base(Protocol.tuic, {
        NodeField.uuid: _uuid,
        NodeField.password: 'fake',
      }).build().params,
      const NodeParams.tuic(uuid: Secret(_uuid), password: Secret('fake')),
    );
    expect(
      base(Protocol.vmess, {NodeField.uuid: _uuid})
          .copyWith(transport: TransportKind.ws)
          .set(NodeField.wsPath, '/ws')
          .set(NodeField.wsHost, 'cdn.example.com')
          .build()
          .params,
      const NodeParams.vmess(
        uuid: Secret(_uuid),
        transport: Transport.ws(path: '/ws', host: 'cdn.example.com'),
      ),
    );
    expect(
      base(Protocol.trojan, {NodeField.password: 'fake'}).build().params,
      const NodeParams.trojan(password: Secret('fake')),
    );
    expect(
      base(Protocol.shadowsocks, {
        NodeField.method: 'aes-256-gcm',
        NodeField.password: 'fake',
      }).build().params,
      const NodeParams.shadowsocks(
        method: 'aes-256-gcm',
        password: Secret('fake'),
      ),
    );
    expect(base(Protocol.socks5, {}).build().params, const NodeParams.socks5());
    expect(
      base(Protocol.anytls, {
        NodeField.password: 'fake',
        NodeField.idleCheck: '30s',
      }).build().params,
      const NodeParams.anytls(
        password: Secret('fake'),
        idleSessionCheckInterval: '30s',
      ),
    );
    expect(
      base(Protocol.http, {
        NodeField.username: 'u',
        NodeField.password: 'p',
      }).copyWith(security: NodeSecurity.tls).build().params,
      const NodeParams.http(username: 'u', password: Secret('p'), tls: Tls()),
    );
  });

  test('reports the first problem in form order', () {
    const d = NodeDraft();
    expect(d.build, _fails(NodeField.server, NodeDraftError.required));
    final s = d.set(NodeField.server, 'a.example.com');
    expect(
      s.set(NodeField.server, 'https://a.example.com/x').build,
      _fails(NodeField.server, NodeDraftError.invalid),
    );
    expect(
      s.set(NodeField.port, '').build,
      _fails(NodeField.port, NodeDraftError.required),
    );
    expect(
      s.set(NodeField.port, '70000').build,
      _fails(NodeField.port, NodeDraftError.invalid),
    );
    expect(s.build, _fails(NodeField.uuid, NodeDraftError.required));
    expect(
      s.set(NodeField.uuid, 'not-a-uuid').build,
      _fails(NodeField.uuid, NodeDraftError.invalid),
    );
    final u = s.set(NodeField.uuid, _uuid);
    expect(
      u.set(NodeField.flow, 'xtls-rprx-direct').build,
      _fails(NodeField.flow, NodeDraftError.unsupported),
    );
    // Reality needs the SNI and the public key.
    expect(u.build, _fails(NodeField.sni, NodeDraftError.required));
    final sni = u.set(NodeField.sni, 'www.apple.com');
    expect(sni.build, _fails(NodeField.publicKey, NodeDraftError.required));
    // The core refuses a key of another format (base64url, 32 bytes).
    expect(
      sni.set(NodeField.publicKey, 'PK').build,
      _fails(NodeField.publicKey, NodeDraftError.invalid),
    );
    expect(
      sni.set(NodeField.publicKey, _pk).set(NodeField.shortId, 'xyz').build,
      _fails(NodeField.shortId, NodeDraftError.invalid),
    );
    // Shadowsocks 2022 takes a base64 key of the method's length.
    NodeDraft ss(String method, String password) =>
        _fill(const NodeDraft().copyWith(protocol: Protocol.shadowsocks), {
          NodeField.server: 'a.example.com',
          NodeField.method: method,
          NodeField.password: password,
        });
    expect(
      ss('2022-blake3-aes-128-gcm', 'fake').build,
      _fails(NodeField.password, NodeDraftError.invalid),
    );
    expect(
      ss('2022-blake3-aes-128-gcm', 'AAAAAAAAAAAAAAAAAAAAAA==').build(),
      isA<SelfNode>(),
    );
    expect(ss('aes-256-gcm', 'fake').build(), isA<SelfNode>());
    expect(
      _fill(const NodeDraft().copyWith(protocol: Protocol.shadowsocks), {
        NodeField.server: 'a.example.com',
        NodeField.method: 'rot13',
        NodeField.password: 'fake',
      }).build,
      _fails(NodeField.method, NodeDraftError.unsupported),
    );
  });

  test('a share link fills the form and builds back to the same node', () {
    for (final link in [
      'vless://$_uuid@a.example.com:443?security=reality&sni=www.apple.com'
          '&pbk=$_pk&sid=0a&flow=xtls-rprx-vision#A',
      'hy2://fake@b.example.com:8443?sni=b.example.com#B',
      'trojan://fake@c.example.com:443?type=ws&path=%2Fws&host=cdn.example.com#C',
      'ss://YWVzLTI1Ni1nY206ZmFrZQ@d.example.com:8388#D',
    ]) {
      final parsed = parseShareLink(link);
      final draft = NodeDraft.fromLink(parsed);
      final node = draft.build();
      expect(node.name, parsed.name, reason: link);
      expect(node.server, parsed.server, reason: link);
      expect(node.port, parsed.port, reason: link);
      expect(node.params.protocol, parsed.params.protocol, reason: link);
      expect(draft[NodeField.server], parsed.server);
    }
    final vless = NodeDraft.fromLink(
      parseShareLink(
        'vless://$_uuid@a.example.com:443?security=reality&sni=www.apple.com'
        '&pbk=$_pk#A',
      ),
    );
    expect(vless.security, NodeSecurity.reality);
    expect(vless[NodeField.publicKey], _pk);
    expect(vless[NodeField.uuid], _uuid);
  });

  test('editing: empty secret fields keep what is saved', () {
    const saved = SelfNode(
      id: 'n1',
      name: '东京',
      server: 'a.example.com',
      port: 443,
      params: NodeParams.trojan(
        password: Secret('fake-saved'),
        tls: Tls(serverName: 'a.example.com'),
      ),
    );
    final draft = NodeDraft.fromNode(
      name: saved.name,
      server: saved.server,
      port: saved.port,
      params: saved.params,
      withSecrets: false,
    );
    expect(draft[NodeField.password], '');
    final same = draft.set(NodeField.port, '8443').build(existing: saved);
    expect(same.id, 'n1');
    expect(same.port, 8443);
    expect((same.params as TrojanParams).password, const Secret('fake-saved'));

    final changed = draft
        .set(NodeField.password, 'fake-new')
        .build(existing: saved);
    expect((changed.params as TrojanParams).password, const Secret('fake-new'));

    // Another protocol cannot reuse the old secret.
    expect(
      () => draft.copyWith(protocol: Protocol.anytls).build(existing: saved),
      _fails(NodeField.password, NodeDraftError.required),
    );
  });

  test('AnyTLS share-link TLS options survive form edits and saving', () {
    final parsed = parseShareLink(
      'anytls://fake-password@proxy.example.com:443?sni=tls.example.com'
      '&insecure=1&alpn=h2,http%2F1.1&fp=chrome#AnyTLS',
    );
    final draft = NodeDraft.fromLink(parsed);
    expect(draft.build().params, parsed.params);

    final edited = draft
        .set(NodeField.sni, 'edited.example.com')
        .set(NodeField.port, '8443')
        .copyWith(transport: TransportKind.tcp)
        .build();
    expect(edited.port, 8443);
    expect(
      (edited.params as AnyTlsParams).tls,
      const Tls(
        serverName: 'edited.example.com',
        insecure: true,
        alpn: ['h2', 'http/1.1'],
        fingerprint: 'chrome',
      ),
    );
  });

  test('saved TLS options survive edits for each TLS protocol', () {
    const tls = Tls(
      serverName: 'tls.example.com',
      insecure: true,
      alpn: ['h2', 'http/1.1'],
      fingerprint: 'chrome',
    );
    const examples = <NodeParams>[
      NodeParams.hysteria2(password: Secret('fake-password'), tls: tls),
      NodeParams.tuic(
        uuid: Secret(_uuid),
        password: Secret('fake-password'),
        tls: tls,
      ),
      NodeParams.vless(uuid: Secret(_uuid), tls: tls),
      NodeParams.vmess(uuid: Secret(_uuid), tls: tls),
      NodeParams.trojan(password: Secret('fake-password'), tls: tls),
      NodeParams.anytls(password: Secret('fake-password'), tls: tls),
      NodeParams.http(
        username: 'fake-user',
        password: Secret('fake-password'),
        tls: tls,
      ),
    ];
    for (final params in examples) {
      final saved = SelfNode(
        id: 'saved-node',
        name: 'Saved',
        server: 'proxy.example.com',
        port: 443,
        params: params,
      );
      final draft = NodeDraft.fromNode(
        name: saved.name,
        server: saved.server,
        port: saved.port,
        params: saved.params,
        withSecrets: false,
      );
      expect(draft.build(existing: saved), saved, reason: params.protocol.name);
      final edited = draft
          .set(NodeField.sni, '')
          .set(NodeField.name, 'Edited')
          .build(existing: saved);
      final editedTls = switch (edited.params) {
        Hysteria2Params(:final tls) ||
        TuicParams(:final tls) ||
        TrojanParams(:final tls) ||
        AnyTlsParams(:final tls) => tls,
        VlessParams(:final tls) ||
        VmessParams(:final tls) ||
        HttpParams(:final tls) => tls,
        _ => null,
      };
      expect(
        editedTls,
        tls.copyWith(serverName: null),
        reason: params.protocol.name,
      );
    }
  });

  test('a newly parsed TLS value takes precedence over the saved node', () {
    const saved = SelfNode(
      id: 'saved-node',
      name: 'Saved',
      server: 'proxy.example.com',
      port: 443,
      params: NodeParams.anytls(
        password: Secret('fake-old-password'),
        tls: Tls(
          serverName: 'old.example.com',
          insecure: true,
          alpn: ['h2'],
          fingerprint: 'chrome',
        ),
      ),
    );
    final parsed = parseShareLink(
      'anytls://fake-new-password@proxy.example.com:443'
      '?sni=new.example.com&insecure=false',
    );
    final updated = NodeDraft.fromLink(parsed).build(existing: saved);
    expect(updated.id, saved.id);
    expect(updated.params, parsed.params);
  });

  test('a parsed plain node does not inherit the saved TLS options', () {
    const saved = SelfNode(
      id: 'saved-node',
      name: 'Saved',
      server: 'proxy.example.com',
      port: 443,
      params: NodeParams.vless(
        uuid: Secret(_uuid),
        tls: Tls(
          serverName: 'old.example.com',
          insecure: true,
          alpn: ['h2'],
          fingerprint: 'chrome',
        ),
      ),
    );
    final draft = NodeDraft.fromLink(
      parseShareLink('vless://$_uuid@proxy.example.com:443?security=none'),
    );
    expect((draft.build(existing: saved).params as VlessParams).tls, isNull);
    final secured = draft
        .copyWith(security: NodeSecurity.tls)
        .set(NodeField.sni, 'new.example.com')
        .build(existing: saved);
    expect(
      (secured.params as VlessParams).tls,
      const Tls(serverName: 'new.example.com'),
    );
  });

  test('hidden TLS options follow the source protocol and security choice', () {
    final draft = NodeDraft.fromLink(
      parseShareLink(
        'vless://$_uuid@proxy.example.com:443?security=reality'
        '&sni=tls.example.com&pbk=$_pk&sid=0a&fp=chrome&alpn=h2&insecure=1',
      ),
    );
    final reality = (draft.build().params as VlessParams).tls!;
    expect(reality.insecure, isTrue);
    expect(reality.alpn, ['h2']);
    expect(reality.fingerprint, 'chrome');
    expect(reality.reality, const Reality(publicKey: _pk, shortId: '0a'));

    final plain = draft.copyWith(security: NodeSecurity.none);
    expect((plain.build().params as VlessParams).tls, isNull);
    final tls = plain.copyWith(security: NodeSecurity.tls);
    expect(
      (tls.build().params as VlessParams).tls,
      reality.copyWith(reality: null),
    );
    expect(
      (tls.copyWith(security: NodeSecurity.reality).build().params
              as VlessParams)
          .tls,
      reality,
    );

    final vmess = draft.copyWith(protocol: Protocol.vmess);
    expect(vmess.effectiveSecurity, NodeSecurity.tls);
    expect(
      (vmess.build().params as VmessParams).tls,
      const Tls(serverName: 'tls.example.com'),
    );
    expect(
      (vmess.copyWith(protocol: Protocol.vless).build().params as VlessParams)
          .tls,
      reality,
    );
    expect(
      (draft.copyWith(protocol: Protocol.socks5).build().params as Socks5Params)
          .tls,
      isNull,
    );
  });
}
