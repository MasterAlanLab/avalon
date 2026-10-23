import 'dart:convert';

import 'package:av_core/av_core.dart';
import 'package:avalon/cloud/sync_models.dart';
import 'package:flutter_test/flutter_test.dart';

const _id = '2d893a37-e98b-4231-8155-5ae4b0b92609';
const _other = '55df2c26-0bcd-4b74-a359-14d57a34d704';
const _mutation = '0341d974-f1cc-4e34-a451-a091b8a09e26';
const _serverTime = '2026-10-13T00:00:00Z';

Map<String, Object?> _node(NodeParams params) {
  final split = SecretCodec.split(params.toJson());
  return completeSyncPayload(SyncRecordType.node, {
    'name': '节点 😀',
    'server': 'proxy.example.invalid',
    'port': 443,
    'params': split.public,
    'secrets': split.secrets,
    'createdAt': 1,
    'memberships': [
      {'configurationId': _other, 'groupKey': 'group'},
    ],
  });
}

Map<String, Object?> _subscription() => {
  'kind': 'subscription',
  'name': 'Private source',
  'autoUpdate': false,
  'createdAt': 1,
  'source': {
    'url': 'https://example.invalid/sub?token=synthetic-source-secret',
    'headers': {'Authorization': 'synthetic-header-secret', 'X-Client': 'a'},
  },
};

Map<String, Object?> _file() {
  final parsed = parseContent(
    'trojan://synthetic-password@proxy.example.invalid:443#Node',
  );
  final model = Map<String, Object?>.from(parsed.content.toJson())
    ..remove('warnings');
  final split = SecretCodec.split(model);
  return completeSyncPayload(SyncRecordType.configuration, {
    'kind': 'file',
    'name': 'File',
    'autoUpdate': false,
    'createdAt': 1,
    'format': 'linkList',
    'content': {'model': split.public, 'secrets': split.secrets},
  });
}

SyncMutation _make(
  Map<String, Object?> payload, {
  SyncRecordType type = SyncRecordType.node,
  String id = _id,
}) => SyncMutation(
  mutationId: _mutation,
  recordId: id,
  type: type,
  baseRevision: 0,
  editedAt: 100,
  deleted: false,
  payload: payload,
);

SyncRecord _record({int revision = 1, String id = _id}) => SyncRecord(
  recordId: id,
  type: SyncRecordType.node,
  revision: revision,
  editedAt: 99,
  editedByDeviceId: 'device',
  deleted: false,
  payload: _node(
    const NodeParams.anytls(password: Secret('synthetic-password')),
  ),
);

Map<String, Object?> _copy(Map<String, Object?> value) =>
    jsonDecode(jsonEncode(value)) as Map<String, Object?>;

final _invalid = throwsA(isA<SyncValidationException>());

void main() {
  const tls = Tls(
    serverName: 'sni.example.invalid',
    insecure: true,
    alpn: ['h2'],
    fingerprint: 'chrome',
    reality: Reality(publicKey: 'synthetic-key', shortId: 'abcdef'),
  );
  const params = <NodeParams>[
    NodeParams.hysteria2(
      password: Secret('synthetic-password'),
      obfsPassword: Secret('synthetic-obfs'),
      upMbps: 500,
      downMbps: 600,
      serverPorts: ['10000:20000'],
      tls: tls,
    ),
    NodeParams.tuic(
      uuid: Secret(_id),
      password: Secret('synthetic-password'),
      congestionControl: 'cubic',
      udpRelayMode: 'quic',
      tls: tls,
    ),
    NodeParams.vless(uuid: Secret(_id), flow: 'xtls-rprx-vision', tls: tls),
    NodeParams.vmess(uuid: Secret(_id), alterId: 16, cipher: 'auto', tls: tls),
    NodeParams.trojan(password: Secret('synthetic-password'), tls: tls),
    NodeParams.shadowsocks(
      method: 'aes-128-gcm',
      password: Secret('synthetic-password'),
      plugin: 'synthetic-plugin',
      pluginOpts: 'synthetic-options',
    ),
    NodeParams.socks5(
      username: 'synthetic-user',
      password: Secret('synthetic-password'),
      tls: tls,
    ),
    NodeParams.anytls(
      password: Secret('synthetic-password'),
      idleSessionCheckInterval: '30s',
      tls: tls,
    ),
    NodeParams.http(
      username: 'synthetic-user',
      password: Secret('synthetic-password'),
      tls: tls,
    ),
  ];

  test(
    'five payload branches and both configuration kinds reject unknown fields',
    () {
      final selection = {
        'configurationId': 'self',
        'groupKey': 'e\u0301😀',
        'member': {'kind': 'builtin', 'builtin': 'direct'},
      };
      final values = [
        _make(_subscription(), type: SyncRecordType.configuration),
        _make(_file(), type: SyncRecordType.configuration),
        _make(_node(params.first)),
        _make({
          'name': null,
          'createdAt': 1,
          'memberships': [],
          'hops': [
            {'kind': 'selfNode', 'id': _id},
            {'kind': 'source', 'configurationId': _other, 'key': 'missing'},
          ],
        }, type: SyncRecordType.chain),
        _make(
          {
            'jsonOverride': null,
            'geo': {'autoUpdate': true, 'interval': 'daily', 'via': 'proxy'},
          },
          type: SyncRecordType.policy,
          id: 'policy',
        ),
        _make(
          selection,
          type: SyncRecordType.selection,
          id: syncSelectionId('self', selection['groupKey']! as String),
        ),
      ];
      for (final dto in values) {
        expect(SyncMutation.decode(dto.canonicalBytes).toJson(), dto.toJson());
        final modified = _copy(dto.toJson());
        (modified['payload']! as Map)['unknown'] = true;
        expect(() => SyncMutation.fromJson(modified), _invalid);
      }
    },
  );

  test(
    'local nullable adaptation does not impose upload limits on local edits',
    () {
      final local = _subscription()..['name'] = 'long-name' * 1000;
      final source = local['source']! as Map<String, Object?>;
      source['headers'] = {'Host': 'local-only.example.invalid'};
      final canonical = completeSyncPayload(
        SyncRecordType.configuration,
        local,
        validate: false,
      );
      expect((canonical['source']! as Map)['headers'], source['headers']);
      expect(
        () => _make(canonical, type: SyncRecordType.configuration),
        _invalid,
      );
      expect(() => canonical['name'] = 'changed', throwsUnsupportedError);
    },
  );

  test('captured payload cannot change through caller or nested maps', () {
    final source = _subscription();
    final dto = _make(source, type: SyncRecordType.configuration);
    final frozen = dto.canonicalJson;
    (source['source']! as Map)['url'] = 'https://changed.example.invalid';
    expect(dto.canonicalJson, frozen);
    expect(
      () => (dto.payload!['source']! as Map)['url'] = 'changed',
      throwsUnsupportedError,
    );
  });

  test(
    'secret coverage, explicit nullable fields and ID namespaces fail closed',
    () {
      final valid = _make(_node(params.first));
      final bad = <Map<String, Object?>>[];
      var candidate = _copy(valid.toJson());
      ((candidate['payload']! as Map)['secrets']! as Map)['s999'] = 'extra';
      bad.add(candidate);
      candidate = _copy(valid.toJson());
      ((candidate['payload']! as Map)['secrets']! as Map).clear();
      bad.add(candidate);
      candidate = _copy(valid.toJson());
      (((candidate['payload']! as Map)['params']! as Map)['tls']! as Map)
          .remove('reality');
      bad.add(candidate);
      bad.add(_copy(valid.toJson())..['recordId'] = 'policy');
      bad.add(_copy(valid.toJson())..['accountId'] = 'injected-account');
      for (final json in bad) {
        expect(() => SyncMutation.fromJson(json), _invalid);
      }
      for (final input in params) {
        final missing = _copy(_make(_node(input)).toJson());
        ((missing['payload']! as Map)['params']! as Map).remove('protocol');
        expect(() => SyncMutation.fromJson(missing), _invalid);
      }
    },
  );

  test('tombstones keep typed IDs and require explicit null payload', () {
    final dto = SyncMutation(
      mutationId: _mutation,
      recordId: _id,
      type: SyncRecordType.node,
      baseRevision: 0,
      editedAt: 100,
      deleted: true,
      payload: null,
    );
    expect(SyncMutation.decode(dto.canonicalBytes).deleted, isTrue);
    expect(
      () => SyncMutation.fromJson({...dto.toJson()}..remove('payload')),
      _invalid,
    );
    expect(
      () => SyncMutation.fromJson({...dto.toJson(), 'payload': {}}),
      _invalid,
    );
  });

  test('future types and schemas differ from malformed known records', () {
    final valid = _make(_node(params.first)).toJson();
    for (final change in [
      {'schemaVersion': 2},
      {'type': 'future'},
    ]) {
      expect(
        () => SyncMutation.fromJson({...valid, ...change}),
        throwsA(
          isA<SyncValidationException>().having(
            (e) => e.reason,
            'reason',
            SyncValidationFailure.unsupportedSchema,
          ),
        ),
      );
    }
    expect(
      () => SyncMutation.fromJson({...valid}..remove('schemaVersion')),
      throwsA(
        isA<SyncValidationException>().having(
          (e) => e.reason,
          'reason',
          SyncValidationFailure.invalidPayload,
        ),
      ),
    );
  });

  test(
    'strict JSON rejects duplicate keys, bad Unicode/UTF-8 and excessive depth',
    () {
      final invalid = [
        '{"a":1,"\\u0061":2}',
        '{"a":{"x":null,"x":1}}',
        r'{"a":"\ud800"}',
        r'{"a":"\udc00"}',
        '{"a":1} null',
        '{"a":01}',
        '{"a":1e999}',
        '${'[' * 65}0${']' * 65}',
      ];
      for (final raw in invalid) {
        expect(() => decodeSyncJson(utf8.encode(raw)), _invalid);
      }
      expect(() => decodeSyncJson([0xc0, 0xaf]), _invalid);
      expect(decodeSyncJson(utf8.encode(r'{"a":"\ud83d\ude00"}')), {'a': '😀'});
      expect(() => decodeSyncJson([32, 32], maxBytes: 1), _invalid);
    },
  );

  test('JCS uses UTF-16 ordering and no extra HTML or Unicode escapes', () {
    expect(
      canonicalSyncJson({'\ue000': 1, '😀': 2, 'a': '<>&\u2028\n', 'z': -0}),
      '{"a":"<>&\u2028\\n","z":0,"😀":2,"\ue000":1}',
    );
    expect(
      () => canonicalSyncJson({'invalid': String.fromCharCode(0xd800)}),
      _invalid,
    );
    expect(
      syncSelectionId('self', 'é'),
      isNot(syncSelectionId('self', 'e\u0301')),
    );
  });

  test(
    'scalar lengths accept supplementary names and bounds integer fields',
    () {
      final payload = _copy(_node(params.last))..['name'] = '😀' * 1024;
      expect(_make(payload).payload!['name'], payload['name']);
      payload['name'] = '😀' * 1025;
      expect(() => _make(payload), _invalid);
      for (final invalidPort in [0, 65536]) {
        expect(
          () => _make({..._node(params.last), 'port': invalidPort}),
          _invalid,
        );
      }
    },
  );

  test(
    'source URL shapes and unsupported or duplicate headers fail closed',
    () {
      for (final url in [
        'file:///tmp/source',
        'https://user:pass@example.invalid/',
        'https://example.invalid/#fragment',
        'https://example.invalid/%xx',
        'https://example.invalid/\\path',
      ]) {
        final payload = _subscription();
        (payload['source']! as Map)['url'] = url;
        expect(
          () => _make(payload, type: SyncRecordType.configuration),
          _invalid,
        );
      }
      for (final headers in [
        {'Host': 'injected'},
        {'X-Real-IP': 'x'},
        {'X-Forwarded-For': 'x'},
        {'Authorization': 'a', 'authorization': 'b'},
        {'X-Custom': 'a\r\nb'},
      ]) {
        final payload = _subscription();
        (payload['source']! as Map)['headers'] = headers;
        expect(
          () => _make(payload, type: SyncRecordType.configuration),
          _invalid,
        );
      }
    },
  );

  test(
    'file graph rejects missing and cyclic targets without dropping nodes',
    () {
      final payload = _copy(_file());
      final model = (payload['content']! as Map)['model']! as Map;
      final nodes = model['nodes']! as List;
      (nodes.first as Map)['detourKey'] = (nodes.first as Map)['key'];
      expect(
        () => _make(payload, type: SyncRecordType.configuration),
        _invalid,
      );
      (nodes.first as Map)['detourKey'] = 'missing';
      expect(
        () => _make(payload, type: SyncRecordType.configuration),
        _invalid,
      );
    },
  );

  test(
    'push validates acknowledged prefix and rejects duplicate input owners',
    () {
      final sent = _make(_node(params.first));
      final other = SyncMutation.fromJson({
        ...sent.toJson(),
        'recordId': _other,
        'mutationId': '968919c3-34bc-4231-93b2-4995c42e0a7c',
      });
      final response = {
        'results': [
          {
            'mutationId': sent.mutationId,
            'status': 'applied',
            'revision': 1,
            'editedAt': 90,
          },
        ],
        'processedCount': 1,
        'hasMore': true,
        'serverTime': _serverTime,
      };
      expect(
        SyncPushResponse.fromJson(
          response,
          mutations: [sent, other],
        ).processedCount,
        1,
      );
      expect(
        () => SyncPushResponse.fromJson(
          {...response, 'hasMore': false},
          mutations: [sent, other],
        ),
        _invalid,
      );
      expect(() => encodeSyncPush([sent, sent]), _invalid);
    },
  );

  test(
    'pull validates revision order and nextCursor and preserves unresolved references',
    () {
      final json = {
        'records': [
          _record().toJson(),
          _record(revision: 2, id: _other).toJson(),
        ],
        'nextCursor': 2,
        'hasMore': true,
        'serverTime': _serverTime,
      };
      final page = SyncPullResponse.fromJson(json, cursor: 0);
      expect((page.records.first.payload!['memberships']! as List).length, 1);
      expect(
        () => SyncPullResponse.fromJson({...json, 'nextCursor': 3}, cursor: 0),
        _invalid,
      );
      expect(() => SyncPullResponse.fromJson(json, cursor: 1), _invalid);
      expect(
        () => SyncPullResponse.fromJson({
          'records': [],
          'nextCursor': 0,
          'hasMore': true,
          'serverTime': _serverTime,
        }, cursor: 0),
        _invalid,
      );
    },
  );
}
