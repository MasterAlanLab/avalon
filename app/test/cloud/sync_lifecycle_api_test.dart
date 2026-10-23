import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:avalon/cloud/api_client.dart';
import 'package:avalon/cloud/sync_lifecycle_models.dart';
import 'package:avalon/cloud/sync_models.dart';
import 'package:flutter_test/flutter_test.dart';

const _generation = '2d893a37-e98b-4231-8155-5ae4b0b92609';
const _otherGeneration = '55df2c26-0bcd-4b74-a359-14d57a34d704';
const _attempt = '0341d974-f1cc-4e34-a451-a091b8a09e26';
const _manifest = '968919c3-34bc-4231-93b2-4995c42e0a7c';
const _operation = '063088c0-b99c-4972-aa22-5b068f542868';
const _mutationId = '9af58316-556e-40e7-9fa0-e5c31470cd91';
const _time = '2026-10-13T00:00:00Z';

SyncMutation _mutation() => SyncMutation(
  mutationId: _mutationId,
  recordId: _otherGeneration,
  type: SyncRecordType.configuration,
  baseRevision: 0,
  editedAt: 100,
  deleted: false,
  payload: {
    'kind': 'subscription',
    'name': 'synthetic-only',
    'autoUpdate': false,
    'createdAt': 1,
    'source': {
      'url': 'https://example.invalid/?token=synthetic',
      'headers': <String, Object?>{},
    },
  },
);

Map<String, Object?> _attemptJson({String phase = 'staging', int count = 0}) =>
    {
      'syncGeneration': _generation,
      'attemptId': _attempt,
      'ownerDeviceId': 'device',
      'manifestId': _manifest,
      'phase': phase,
      'recordCount': count,
      'stagedRecordCount': count,
      'publishedCursor': phase == 'published' ? count : null,
      'startedAt': _time,
      'finishedAt': phase == 'staging' ? null : _time,
      'serverTime': _time,
    };

Map<String, Object?> _status({String origin = 'legacy', bool empty = false}) =>
    {
      'accountId': 'account',
      'deviceId': 'device',
      'syncGeneration': empty ? null : _generation,
      'spaceOrigin': empty ? null : origin,
      'headRevision': empty ? null : 0,
      'spaceState': empty ? 'noSpace' : 'active',
      'backupState': empty ? 'none' : 'ready',
      'entitlementExpiresAt': empty ? null : '2026-10-14T00:00:00Z',
      'retentionUntil': empty ? null : '2026-11-13T00:00:00Z',
      'rebuild': null,
      'cleanup': {
        'pendingGenerationCount': 0,
        'latestRetiredGeneration': null,
        'latestRetiredAt': null,
        'onlineState': 'none',
        'keyState': 'none',
      },
      'serverTime': _time,
    };

Map<String, Object?> _activate({bool v2 = true}) => {
  'deviceId': 'device',
  'syncActive': true,
  'deviceLimit': 10,
  'syncActiveDeviceCount': 1,
  'serverTime': _time,
  if (v2) ...{
    'syncGeneration': _generation,
    'backupState': 'ready',
    'rebuildAttemptId': null,
  },
};

Map<String, Object?> _pull({int head = 0}) => {
  'syncGeneration': _generation,
  'rebuildAttemptId': null,
  'headRevision': head,
  'records': <Object?>[],
  'nextCursor': 0,
  'hasMore': false,
  'serverTime': _time,
};

Map<String, Object?> _push({String? attempt}) => {
  'syncGeneration': _generation,
  'rebuildAttemptId': attempt,
  'writeState': attempt == null ? 'published' : 'staged',
  'results': [
    {
      'mutationId': _mutationId,
      'status': 'applied',
      'revision': 1,
      'editedAt': 90,
    },
  ],
  'processedCount': 1,
  'hasMore': false,
  'serverTime': _time,
};

CloudResponse _response(
  Object? body, {
  int status = 200,
  String? version = '2',
  String? retryAfter,
}) => CloudResponse(
  statusCode: status,
  headers: {
    'content-type': 'application/json',
    'cache-control': 'no-store',
    'avalon-sync-version': ?version,
    'retry-after': ?retryAfter,
  },
  body: Uint8List.fromList(utf8.encode(jsonEncode(body))),
);

final class _Transport implements CloudTransport {
  _Transport(this.handle);
  final FutureOr<CloudResponse> Function(CloudRequest) handle;
  final requests = <CloudRequest>[];
  @override
  Future<CloudResponse> send(CloudRequest request) async {
    requests.add(request);
    return handle(request);
  }

  @override
  void close() {}
}

ApiClient _api(_Transport transport) {
  final api = ApiClient(
    baseUri: Uri.parse('http://127.0.0.1:21323'),
    allowLoopbackHttp: true,
    transport: transport,
  );
  addTearDown(api.close);
  return api;
}

Map<String, Object?> _body(CloudRequest r) =>
    jsonDecode(utf8.decode(r.body!)) as Map<String, Object?>;

void main() {
  test(
    'v2 first allocation sends explicit null; legacy API still sends v1',
    () async {
      final transport = _Transport(
        (r) => r.headers['Avalon-Sync-Version'] == '2'
            ? _response(_activate())
            : _response(_activate(v2: false), version: '1'),
      );
      final api = _api(transport);
      final created = await api.activateSyncV2(
        accessToken: 'synthetic-token',
        syncGeneration: null,
      );
      expect(created.syncGeneration, _generation);
      expect(_body(transport.requests.first), {'syncGeneration': null});
      await api.activateSync(accessToken: 'synthetic-token');
      expect(transport.requests.last.body, isNull);
      expect(transport.requests.last.headers['Avalon-Sync-Version'], '1');
    },
  );

  test(
    'free lifecycle status handles no-space and authoritative legacy origin',
    () async {
      final transport = _Transport((_) => _response(_status(empty: true)));
      final api = _api(transport);
      final free = await api.syncLifecycle(accessToken: 'synthetic-token');
      expect(free.syncGeneration, isNull);
      expect(free.backupState, 'none');
      expect(transport.requests.single.uri.path, '/v1/sync/status');
      final migrated = SyncLifecycleStatus.fromJson(_status());
      expect(migrated.spaceOrigin, 'legacy');
      expect(migrated.headRevision, 0);
    },
  );

  test(
    'status rejects unknown fields, origins, incoherent scope and fake cleanup',
    () {
      for (final bad in <Map<String, Object?>>[
        {..._status(), 'unknown': true},
        {..._status(), 'spaceOrigin': 'restored'},
        {..._status(), 'syncGeneration': null},
        {..._status(), 'spaceState': 'retired'},
        {..._status(), 'backupState': 'rebuildRequired'},
        {..._status(), 'headRevision': -1},
        {..._status(), 'serverTime': '2026-02-30T00:00:00Z'},
        {
          ..._status(),
          'backupState': 'rebuilding',
          'rebuild': {..._attemptJson(), 'syncGeneration': _otherGeneration},
        },
        {
          ..._status(),
          'cleanup': {
            'pendingGenerationCount': 1,
            'latestRetiredGeneration': _otherGeneration,
            'latestRetiredAt': _time,
            'onlineState': 'complete',
            'keyState': 'destroyed',
          },
        },
      ]) {
        expect(
          () => SyncLifecycleStatus.fromJson(bad),
          throwsA(isA<SyncValidationException>()),
        );
      }
    },
  );

  test(
    'v2 accepts online deleted and legacy destroyed without retiring an active space',
    () async {
      for (final keyState in ['deleted', 'destroyed']) {
        final transport = _Transport(
          (_) => _response({
            ..._status(),
            'cleanup': {
              'pendingGenerationCount': 0,
              'latestRetiredGeneration': _otherGeneration,
              'latestRetiredAt': _time,
              'onlineState': 'complete',
              'keyState': keyState,
            },
          }),
        );
        final result = await _api(
          transport,
        ).syncLifecycle(accessToken: 'synthetic-token');
        expect(result.cleanup.keyState, keyState);
        expect(result.cleanup.onlineState, 'complete');
        expect(result.cleanup.pendingGenerationCount, 0);
        expect(result.cleanup.latestRetiredGeneration, _otherGeneration);
        expect(result.syncGeneration, _generation);
        expect(result.spaceState, 'active');
        expect(result.backupState, 'ready');
        expect(transport.requests, hasLength(1));
        expect(transport.requests.single.headers['Avalon-Sync-Version'], '2');
      }
    },
  );

  test(
    'deleted and destroyed require coherent retirement and complete cleanup evidence',
    () {
      for (final keyState in ['deleted', 'destroyed']) {
        final complete = <String, Object?>{
          'pendingGenerationCount': 0,
          'latestRetiredGeneration': _otherGeneration,
          'latestRetiredAt': _time,
          'onlineState': 'complete',
          'keyState': keyState,
        };
        for (final cleanup in [
          {...complete, 'pendingGenerationCount': 1},
          {...complete, 'latestRetiredGeneration': null},
          {...complete, 'latestRetiredAt': null},
          {
            ...complete,
            'latestRetiredGeneration': null,
            'latestRetiredAt': null,
          },
        ]) {
          expect(
            () => SyncLifecycleStatus.fromJson({
              ..._status(),
              'cleanup': cleanup,
            }),
            throwsA(isA<SyncValidationException>()),
            reason: '$keyState must not manufacture cleanup completion',
          );
        }
        for (final cleanup in [
          {...complete, 'pendingGenerationCount': 1, 'keyState': 'waiting'},
          {...complete, 'pendingGenerationCount': 1, 'onlineState': 'pending'},
        ]) {
          final result = SyncLifecycleStatus.fromJson({
            ..._status(),
            'cleanup': cleanup,
          });
          expect(result.cleanup.pendingGenerationCount, 1);
        }
      }
    },
  );

  test('v2 rejects unknown cleanup key states without downgrade', () async {
    final transport = _Transport(
      (_) => _response({
        ..._status(),
        'cleanup': {
          'pendingGenerationCount': 0,
          'latestRetiredGeneration': _otherGeneration,
          'latestRetiredAt': _time,
          'onlineState': 'complete',
          'keyState': 'purged',
        },
      }),
    );
    await expectLater(
      _api(transport).syncLifecycle(accessToken: 'synthetic-token'),
      throwsA(isA<SyncValidationException>()),
    );
    expect(transport.requests, hasLength(1));
    expect(transport.requests.single.headers['Avalon-Sync-Version'], '2');
  });

  test(
    'v2 rejects a protocol1 success without an automatic downgrade',
    () async {
      final transport = _Transport((_) => _response(_status(), version: '1'));
      await expectLater(
        _api(transport).syncLifecycle(accessToken: 'synthetic-token'),
        throwsA(isA<CloudProtocolException>()),
      );
      expect(transport.requests, hasLength(1));
      expect(transport.requests.single.headers['Avalon-Sync-Version'], '2');
    },
  );

  test(
    'generation conflicts are machine errors and diagnostics are discarded',
    () async {
      final transport = _Transport(
        (_) => _response({
          'error': {
            'code': 'SYNC_GENERATION_MISMATCH',
            'message': 'synthetic-sensitive-diagnostic',
          },
        }, status: 409),
      );
      await expectLater(
        _api(transport).pullSyncV2(
          accessToken: 'synthetic-token',
          syncGeneration: _generation,
          cursor: 0,
        ),
        throwsA(
          isA<CloudApiException>()
              .having((e) => e.code.value, 'code', 'SYNC_GENERATION_MISMATCH')
              .having((e) => e.message, 'message', isEmpty),
        ),
      );
    },
  );

  test(
    'unverified entitlement pauses with exact retry instead of pretending cleanup',
    () async {
      final transport = _Transport(
        (_) => _response(
          {
            'error': {'code': 'SYNC_ENTITLEMENT_UNVERIFIED', 'message': ''},
          },
          status: 503,
          retryAfter: '30',
        ),
      );
      await expectLater(
        _api(transport).activateSyncV2(
          accessToken: 'synthetic-token',
          syncGeneration: _generation,
        ),
        throwsA(
          isA<CloudApiException>().having(
            (e) => e.retryAfter,
            'retryAfter',
            const Duration(seconds: 30),
          ),
        ),
      );
    },
  );

  test(
    'damaged 401 retains auth status; malformed non-auth error is rejected',
    () async {
      final unauthorized = _Transport(
        (_) => _response({'bad': true}, status: 401, version: null),
      );
      await expectLater(
        _api(unauthorized).syncLifecycle(accessToken: 'synthetic-token'),
        throwsA(
          isA<CloudApiException>().having((e) => e.httpStatus, 'status', 401),
        ),
      );
      final conflict = _Transport(
        (_) => _response(
          {
            'error': {'code': 'SYNC_GENERATION_MISMATCH', 'message': ''},
          },
          status: 409,
          version: null,
        ),
      );
      await expectLater(
        _api(conflict).syncLifecycle(accessToken: 'synthetic-token'),
        throwsA(isA<CloudProtocolException>()),
      );
    },
  );

  test(
    'staging push freezes context and rejects an ack from a different attempt',
    () async {
      final transport = _Transport((_) => _response(_push(attempt: _manifest)));
      await expectLater(
        _api(transport).pushSyncV2(
          accessToken: 'synthetic-token',
          syncGeneration: _generation,
          rebuildAttemptId: _attempt,
          mutations: [_mutation()],
        ),
        throwsA(isA<SyncValidationException>()),
      );
      final body = _body(transport.requests.single);
      expect(body['syncGeneration'], _generation);
      expect(body['rebuildAttemptId'], _attempt);
      expect((body['mutations']! as List).single, _mutation().toJson());
    },
  );

  test(
    'staged ack stays staged and cannot be confused with a published backup',
    () async {
      final transport = _Transport((_) => _response(_push(attempt: _attempt)));
      final result = await _api(transport).pushSyncV2(
        accessToken: 'synthetic-token',
        syncGeneration: _generation,
        rebuildAttemptId: _attempt,
        mutations: [_mutation()],
      );
      expect(result.writeState, 'staged');
      expect(result.results.single, isA<SyncAppliedResult>());
      final wrong = {..._push(attempt: _attempt), 'writeState': 'published'};
      expect(
        () => SyncPushV2Response.fromJson(
          wrong,
          syncGeneration: _generation,
          rebuildAttemptId: _attempt,
          mutations: [_mutation()],
        ),
        throwsA(isA<SyncValidationException>()),
      );
    },
  );

  test('staging rejects old-base or tombstone before sending HTTP', () async {
    final transport = _Transport((_) => _response(_push(attempt: _attempt)));
    final api = _api(transport);
    for (final changed in [
      {..._mutation().toJson(), 'baseRevision': 1},
      {..._mutation().toJson(), 'deleted': true, 'payload': null},
    ]) {
      await expectLater(
        api.pushSyncV2(
          accessToken: 'synthetic-token',
          syncGeneration: _generation,
          rebuildAttemptId: _attempt,
          mutations: [SyncMutation.fromJson(changed)],
        ),
        throwsA(isA<SyncValidationException>()),
      );
    }
    expect(transport.requests, isEmpty);
  });

  test('v2 refuses duplicate batch identities before sending HTTP', () async {
    final transport = _Transport((_) => _response(_push()));
    final api = _api(transport);
    final sameRecord = SyncMutation.fromJson({
      ..._mutation().toJson(),
      'mutationId': _operation,
    });
    final sameMutation = SyncMutation.fromJson({
      ..._mutation().toJson(),
      'recordId': _generation,
    });
    for (final attempt in [null, _attempt]) {
      for (final second in [_mutation(), sameRecord, sameMutation]) {
        await expectLater(
          api.pushSyncV2(
            accessToken: 'synthetic-token',
            syncGeneration: _generation,
            rebuildAttemptId: attempt,
            mutations: [_mutation(), second],
          ),
          throwsA(isA<SyncValidationException>()),
        );
      }
    }
    expect(transport.requests, isEmpty);
  });

  test('a superseded result cannot acknowledge an immutable staged entry', () {
    final mutation = _mutation();
    final record = SyncRecord(
      recordId: mutation.recordId,
      type: mutation.type,
      revision: 1,
      editedAt: mutation.editedAt,
      editedByDeviceId: 'device',
      deleted: false,
      payload: mutation.payload,
    );
    final superseded = {
      'mutationId': mutation.mutationId,
      'status': 'superseded',
      'record': record.toJson(),
    };
    expect(
      () => SyncPushV2Response.fromJson(
        {
          ..._push(attempt: _attempt),
          'results': [superseded],
        },
        syncGeneration: _generation,
        rebuildAttemptId: _attempt,
        mutations: [mutation],
      ),
      throwsA(isA<SyncValidationException>()),
    );
    final normal = SyncPushV2Response.fromJson(
      {
        ..._push(),
        'results': [superseded],
      },
      syncGeneration: _generation,
      rebuildAttemptId: null,
      mutations: [mutation],
    );
    expect(normal.results.single, isA<SyncSupersededResult>());
  });

  test('pull binds generation and validates stable-head completion', () async {
    final transport = _Transport((_) => _response(_pull()));
    final result = await _api(transport).pullSyncV2(
      accessToken: 'synthetic-token',
      syncGeneration: _generation,
      cursor: 0,
    );
    expect(result.headRevision, 0);
    expect(transport.requests.single.uri.queryParameters, {
      'syncGeneration': _generation,
      'cursor': '0',
      'limit': '500',
    });
    for (final bad in [
      _pull(head: 1),
      {..._pull(), 'syncGeneration': _otherGeneration},
      {..._pull(), 'rebuildAttemptId': _attempt},
      {..._pull(), 'headRevision': 9007199254740992},
    ]) {
      expect(
        () => SyncPullV2Response.fromJson(
          bad,
          syncGeneration: _generation,
          cursor: 0,
          limit: 500,
        ),
        throwsA(isA<SyncValidationException>()),
      );
    }
  });

  test(
    'manifest allows empty snapshot but rejects duplicate identity and unsorted list',
    () {
      final empty = SyncRebuildManifest(manifestId: _manifest, entries: []);
      expect(empty.entries, isEmpty);
      final first = SyncRebuildManifestEntry(
        recordId: _generation,
        type: SyncRecordType.node,
        mutationId: _mutationId,
      );
      final second = SyncRebuildManifestEntry(
        recordId: _otherGeneration,
        type: SyncRecordType.node,
        mutationId: _operation,
      );
      for (final entries in [
        [first, first],
        [second, first],
        [
          first,
          SyncRebuildManifestEntry(
            recordId: _otherGeneration,
            type: SyncRecordType.node,
            mutationId: _mutationId,
          ),
        ],
      ]) {
        expect(
          () => SyncRebuildManifest(manifestId: _manifest, entries: entries),
          throwsA(isA<SyncValidationException>()),
        );
      }
      expect(
        () => SyncRebuildManifestEntry(
          recordId: 'policy',
          type: SyncRecordType.node,
          mutationId: _mutationId,
        ),
        throwsA(isA<SyncValidationException>()),
      );
    },
  );

  test(
    'control sends immutable manifest and matches operation, generation and attempt',
    () async {
      final request = SyncRebuildControlRequest.start(
        operationId: _operation,
        syncGeneration: _generation,
        manifest: SyncRebuildManifest(manifestId: _manifest, entries: []),
      );
      final transport = _Transport(
        (_) => _response({..._attemptJson(), 'operationId': _operation}),
      );
      final api = _api(transport);
      final response = await api.controlSyncRebuild(
        accessToken: 'synthetic-token',
        request: request,
      );
      expect(response.attempt.phase, 'staging');
      expect(_body(transport.requests.single), request.toJson());
      for (final bad in [
        {..._attemptJson(), 'operationId': _mutationId},
        {
          ..._attemptJson(),
          'operationId': _operation,
          'manifestId': _mutationId,
        },
        {
          ..._attemptJson(),
          'operationId': _operation,
          'syncGeneration': _otherGeneration,
        },
        {
          ..._attemptJson(count: 1),
          'operationId': _operation,
          'stagedRecordCount': 0,
        },
        {..._attemptJson(count: 1), 'operationId': _operation},
      ]) {
        expect(
          () => SyncRebuildControlResponse.fromJson(bad, request: request),
          throwsA(isA<SyncValidationException>()),
        );
      }
    },
  );

  test('control rejects cancellation or publication of another attempt', () {
    final cancel = SyncRebuildControlRequest.cancel(
      operationId: _operation,
      syncGeneration: _generation,
      expectedAttemptId: _attempt,
    );
    final complete = SyncRebuildControlRequest.complete(
      operationId: _operation,
      syncGeneration: _generation,
      expectedAttemptId: _attempt,
      manifestId: _manifest,
    );
    for (final (request, phase) in [
      (cancel, 'cancelled'),
      (complete, 'published'),
    ]) {
      final wrong = {
        ..._attemptJson(phase: phase),
        'operationId': _operation,
        'attemptId': _mutationId,
      };
      expect(
        () => SyncRebuildControlResponse.fromJson(wrong, request: request),
        throwsA(isA<SyncValidationException>()),
      );
    }
    final published = SyncRebuildControlResponse.fromJson({
      ..._attemptJson(phase: 'published'),
      'operationId': _operation,
    }, request: complete);
    expect(published.attempt.publishedCursor, 0);
  });

  test('claim obtains a new attempt and cannot accept the old owner scope', () {
    final request = SyncRebuildControlRequest.claim(
      operationId: _operation,
      syncGeneration: _generation,
      expectedAttemptId: _attempt,
      manifest: SyncRebuildManifest(manifestId: _manifest, entries: []),
    );
    expect(
      () => SyncRebuildControlResponse.fromJson({
        ..._attemptJson(),
        'operationId': _operation,
      }, request: request),
      throwsA(isA<SyncValidationException>()),
    );
  });

  test('control replay preserves the original immutable body', () async {
    final manifest = SyncRebuildManifest(
      manifestId: _manifest,
      entries: [
        SyncRebuildManifestEntry(
          recordId: _otherGeneration,
          type: SyncRecordType.configuration,
          mutationId: _mutationId,
        ),
      ],
    );
    final original = SyncRebuildControlRequest.start(
      operationId: _operation,
      syncGeneration: _generation,
      manifest: manifest,
    );
    final persisted = SyncRebuildControlRequest.fromJson(
      jsonDecode(utf8.decode(original.canonicalBytes)) as Map<String, Object?>,
    );
    final transport = _Transport(
      (_) => _response({
        ..._attemptJson(count: 1),
        'stagedRecordCount': 0,
        'operationId': _operation,
      }),
    );
    final api = _api(transport);
    await api.controlSyncRebuild(
      accessToken: 'synthetic-token',
      request: original,
    );
    await api.controlSyncRebuild(
      accessToken: 'synthetic-token',
      request: persisted,
    );
    expect(transport.requests.last.body, transport.requests.first.body);
    expect(persisted.recordCount, 1);
    expect(() => persisted.toJson().clear(), throwsUnsupportedError);
    expect(
      () => ((persisted.toJson()['manifest']! as Map)['entries']! as List)
          .clear(),
      throwsUnsupportedError,
    );
    expect(persisted.toString(), isNot(contains(_operation)));
  });

  test(
    'attempt status rejects a cross-scope response without leaking payload',
    () async {
      final transport = _Transport(
        (_) => _response({..._attemptJson(), 'attemptId': _manifest}),
      );
      await expectLater(
        _api(transport).getSyncRebuild(
          accessToken: 'synthetic-token',
          syncGeneration: _generation,
          attemptId: _attempt,
        ),
        throwsA(isA<SyncValidationException>()),
      );
      expect(transport.requests.single.uri.queryParameters, {
        'syncGeneration': _generation,
        'attemptId': _attempt,
      });
    },
  );
}
