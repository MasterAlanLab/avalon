// Real authorization, encrypted SQLite, projections and worker. Only the
// transport is controlled; no account, subscription or physical device is used.
import 'dart:async';
import 'dart:convert';

import 'package:av_core/av_core.dart';
import 'package:avalon/cloud/api_client.dart';
import 'package:avalon/cloud/auth_service.dart';
import 'package:avalon/cloud/cloud_models.dart';
import 'package:avalon/cloud/sync_engine.dart';
import 'package:avalon/cloud/sync_models.dart';
import 'package:avalon/data/database/database.dart';
import 'package:avalon/data/repositories/cloud_session_repository.dart';
import 'package:avalon/data/repositories/self_content_repository.dart';
import 'package:avalon/data/repositories/sync_projection.dart';
import 'package:avalon/data/repositories/sync_repository.dart';
import 'package:avalon/data/vault/secret_store.dart';
import 'package:avalon/data/vault/vault.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const _now = '2026-10-13T00:00:00Z';
const _id = '00000000-0000-4000-8000-000000000001';
const _other = '00000000-0000-4000-8000-000000000002';

CloudResponse _response(Object? json, {int status = 200, int version = 1}) =>
    CloudResponse(
      statusCode: status,
      headers: {
        'content-type': 'application/json',
        'cache-control': 'no-store',
        'avalon-sync-version': '$version',
      },
      body: Uint8List.fromList(utf8.encode(jsonEncode(json))),
    );

String _account(CloudRequest request) =>
    request.headers['authorization']!.split('-').last;

CloudResponse _activation(CloudRequest request) => _response({
  'deviceId': 'device-${_account(request)}',
  'syncActive': true,
  'deviceLimit': 10,
  'syncActiveDeviceCount': 1,
  'serverTime': _now,
});

const _cloudGeneration = '00000000-0000-4000-8000-000000000010';
const _cloudAttempt = '00000000-0000-4000-8000-000000000011';

Map<String, Object?> _lifecycleJson({
  String spaceState = 'active',
  String backupState = 'rebuildRequired',
  int head = 0,
  Map<String, Object?>? rebuild,
}) => {
  'accountId': 'a',
  'deviceId': 'device-a',
  'syncGeneration': _cloudGeneration,
  'spaceOrigin': 'rebuilt',
  'headRevision': head,
  'spaceState': spaceState,
  'backupState': backupState,
  'entitlementExpiresAt': '2026-11-01T00:00:00Z',
  'retentionUntil': '2026-12-01T00:00:00Z',
  'rebuild': rebuild,
  'serverTime': _now,
  'cleanup': {
    'pendingGenerationCount': 0,
    'latestRetiredGeneration': null,
    'latestRetiredAt': null,
    'onlineState': 'none',
    'keyState': 'none',
  },
};

// Only HTTP is synthetic: the engine still uses real auth orchestration,
// encrypted persistent manifests, projections, local edits and guards.
final class _LifecycleCloud {
  String backupState = 'rebuildRequired';
  String owner = 'device-a';
  String? manifestId;
  int recordCount = 0;
  int head = 0;
  String? dropAction;
  bool dropPush = false;
  bool replacedAfterStart = false;
  final receipts = <String, Map<String, Object?>>{};
  final applied = <String, Map<String, Object?>>{};
  final records = <String, Map<String, Object?>>{};

  Map<String, Object?> attempt(String phase) => {
    'syncGeneration': _cloudGeneration,
    'attemptId': _cloudAttempt,
    'ownerDeviceId': owner,
    'manifestId': manifestId!,
    'phase': phase,
    'recordCount': recordCount,
    'stagedRecordCount': records.length,
    'publishedCursor': phase == 'published' ? head : null,
    'startedAt': _now,
    'finishedAt': phase == 'staging' ? null : _now,
    'serverTime': _now,
  };

  Future<CloudResponse> send(CloudRequest request) async {
    expect(request.headers['Avalon-Sync-Version'], '2');
    switch (request.uri.path) {
      case '/v1/sync/status':
        return _response(
          _lifecycleJson(
            backupState: backupState,
            head: head,
            rebuild: backupState == 'rebuilding' ? attempt('staging') : null,
          ),
          version: 2,
        );
      case '/v1/sync/activate':
        return _response({
          'deviceId': 'device-a',
          'syncActive': true,
          'deviceLimit': 10,
          'syncActiveDeviceCount': 1,
          'serverTime': _now,
          'syncGeneration': _cloudGeneration,
          'backupState': backupState,
          'rebuildAttemptId': backupState == 'rebuilding'
              ? _cloudAttempt
              : null,
        }, version: 2);
      case '/v1/sync/rebuild':
        final body = (jsonDecode(utf8.decode(request.body!)) as Map)
            .cast<String, Object?>();
        final operation = body['operationId']! as String;
        final action = body['action']! as String;
        var receipt = receipts[operation];
        if (receipt == null) {
          if (action == 'start') {
            final manifest = body['manifest']! as Map;
            manifestId = manifest['manifestId'] as String;
            recordCount = (manifest['entries'] as List).length;
            backupState = 'rebuilding';
          } else if (action == 'complete') {
            expect(records.length, recordCount);
            backupState = 'ready';
            head = records.length;
          } else {
            fail('Unexpected synthetic rebuild action.');
          }
          receipt = {
            ...attempt(action == 'complete' ? 'published' : 'staging'),
            'operationId': operation,
          };
          receipts[operation] = receipt;
          if (dropAction == action) {
            dropAction = null;
            throw const CloudNetworkException();
          }
          if (replacedAfterStart && action == 'start') owner = 'other-device';
        }
        return _response(receipt, version: 2);
      case '/v1/sync/push':
        final body = jsonDecode(utf8.decode(request.body!)) as Map;
        final staged = body['rebuildAttemptId'] != null;
        final mutations = body['mutations'] as List;
        final results = <Object?>[];
        for (final value in mutations) {
          final m = (value as Map).cast<String, Object?>();
          final id = m['mutationId']! as String;
          final result = applied.putIfAbsent(id, () {
            final revision = staged ? records.length + 1 : ++head;
            records[m['recordId']! as String] =
                {...m, 'revision': revision, 'editedByDeviceId': 'device-a'}
                  ..remove('mutationId')
                  ..remove('baseRevision');
            return {
              'mutationId': id,
              'status': 'applied',
              'revision': revision,
              'editedAt': m['editedAt'],
            };
          });
          results.add(result);
        }
        if (dropPush) {
          dropPush = false;
          throw const CloudNetworkException();
        }
        return _response({
          'syncGeneration': _cloudGeneration,
          'rebuildAttemptId': body['rebuildAttemptId'],
          'writeState': staged ? 'staged' : 'published',
          'results': results,
          'processedCount': results.length,
          'hasMore': false,
          'serverTime': _now,
        }, version: 2);
      case '/v1/sync/pull':
        final cursor = int.parse(request.uri.queryParameters['cursor']!);
        final page =
            records.values
                .where((r) => (r['revision']! as int) > cursor)
                .toList()
              ..sort(
                (a, b) =>
                    (a['revision']! as int).compareTo(b['revision']! as int),
              );
        return _response({
          'syncGeneration': _cloudGeneration,
          'rebuildAttemptId': null,
          'headRevision': head,
          'records': page,
          'nextCursor': head,
          'hasMore': false,
          'serverTime': _now,
        }, version: 2);
      default:
        fail('Unexpected synthetic lifecycle route.');
    }
  }
}

final class _Transport implements CloudTransport {
  late Future<CloudResponse> Function(CloudRequest) handle;
  final requests = <CloudRequest>[];
  int active = 0;
  int maximumActive = 0;

  @override
  Future<CloudResponse> send(CloudRequest request) async {
    requests.add(request);
    active++;
    if (active > maximumActive) maximumActive = active;
    try {
      return await handle(request);
    } finally {
      active--;
    }
  }

  @override
  void close() {}
}

Future<void> _until(bool Function() condition) async {
  final deadline = DateTime.now().add(const Duration(seconds: 5));
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Worker did not reach the expected safe state.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  late AppDatabase db;
  late SecretStore secrets;
  late CloudSessionRepository sessions;
  late SyncRepository repository;
  late SyncProjection projection;
  late SelfContentRepository content;
  late AuthService auth;
  late SyncEngine engine;
  late ApiClient api;
  late _Transport transport;
  late StreamSubscription<SyncStatus> statuses;
  late List<SyncStatus> observed;
  final releases = <Completer<void>>[];
  var revision = 100;

  Future<void> seed(String account, {String? sessionId}) async => sessions.save(
    StoredCloudSession(
      accountId: account,
      deviceId: 'device-$account',
      sessionId: sessionId ?? 'session-$account',
      installationId: await sessions.installationId(),
      accessToken: 'synthetic-access-$account',
      refreshToken: 'synthetic-refresh-$account',
      accessExpiresAt: DateTime.utc(2030),
      refreshExpiresAt: DateTime.utc(2031),
    ),
  );

  Future<CloudResponse> successful(CloudRequest request) async {
    switch (request.uri.path) {
      case '/v1/sync/activate':
        return _activation(request);
      case '/v1/sync/pull':
        return _response({
          'records': <Object?>[],
          'nextCursor': int.parse(request.uri.queryParameters['cursor']!),
          'hasMore': false,
          'serverTime': _now,
        });
      case '/v1/sync/push':
        final body = jsonDecode(utf8.decode(request.body!)) as Map;
        final mutations = body['mutations']! as List;
        return _response({
          'results': [
            for (final m in mutations)
              {
                'mutationId': (m as Map)['mutationId'],
                'status': 'applied',
                'revision': ++revision,
                'editedAt': m['editedAt'],
              },
          ],
          'processedCount': mutations.length,
          'hasMore': false,
          'serverTime': _now,
        });
      default:
        throw StateError('Unexpected synthetic worker route.');
    }
  }

  Future<SelfNode> node(String name) => content.addNode(
    SelfNode(
      id: '',
      name: name,
      server: 'node.example.invalid',
      port: 443,
      params: const NodeParams.anytls(password: Secret('synthetic-password')),
    ),
  );

  SyncRecord remoteNode(String name, {int revision = 1}) {
    final split = SecretCodec.split(
      const NodeParams.anytls(password: Secret('synthetic-password')).toJson(),
    );
    return SyncRecord(
      recordId: _id,
      type: SyncRecordType.node,
      revision: revision,
      editedAt: 100,
      editedByDeviceId: 'remote-device',
      deleted: false,
      payload: completeSyncPayload(SyncRecordType.node, {
        'name': name,
        'server': 'node.example.invalid',
        'port': 443,
        'params': split.public,
        'secrets': split.secrets,
        'createdAt': 1,
        'memberships': <Object?>[],
      }),
    );
  }

  setUp(() async {
    releases.clear();
    revision = 100;
    db = AppDatabase(NativeDatabase.memory());
    secrets = SecretStore(db, await Vault.open(MemoryKeyStore()));
    sessions = CloudSessionRepository(db, secrets);
    repository = SyncRepository(db, secrets);
    projection = SyncProjection(db, secrets, repository);
    content = SelfContentRepository(db, secrets, onSyncEdit: projection.edited);
    transport = _Transport()..handle = successful;
    api = ApiClient(
      baseUri: Uri.parse('https://cloud.example.invalid'),
      transport: transport,
    );
    auth = AuthService(
      api: api,
      sessions: sessions,
      deviceName: 'Synthetic worker device',
      os: DeviceOs.android,
      clock: () => DateTime.utc(2026, 10, 13),
    );
    engine = SyncEngine(
      auth: auth,
      repository: repository,
      projection: projection,
      db: db,
    );
    observed = [];
    statuses = engine.watch().listen(observed.add);
    await seed('a');
  });

  tearDown(() async {
    for (final release in releases) {
      if (!release.isCompleted) release.complete();
    }
    await engine.dispose();
    await statuses.cancel();
    api.close();
    await db.close();
  });

  test(
    'a delayed ordinary network failure cannot lose the new-account wakeup',
    () async {
      engine.foreground(false);
      engine.start();
      // Allow the initial database watches to settle while scheduling is paused.
      await Future<void>.delayed(const Duration(milliseconds: 30));
      final entered = Completer<void>();
      final release = Completer<void>();
      releases.add(release);
      transport.handle = (request) async {
        if (request.uri.path == '/v1/sync/activate' &&
            _account(request) == 'a') {
          entered.complete();
          await release.future;
          throw const CloudNetworkException();
        }
        return successful(request);
      };
      engine.foreground(true);
      await entered.future.timeout(const Duration(seconds: 2));
      await sessions.logoutLocally();
      await seed('b');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      release.complete();
      await _until(
        () => observed.any((s) => s.accountId == 'b' && s.lastSyncAt != null),
      );
      final a = await repository.state('a');
      final b = await repository.state('b');
      expect(a.blockedReason, isNull);
      expect(a.bootstrapCompleted, isFalse);
      expect(b.bootstrapCompleted, isTrue);
      expect(b.lastSyncAt, isNotNull);
      expect(transport.maximumActive, 1);
      expect(
        transport.requests
            .where((r) => r.uri.path == '/v1/sync/activate')
            .map(_account),
        ['a', 'b'],
      );
    },
  );

  test(
    'same-account session replacement resumes after the old network attempt fails',
    () async {
      engine.foreground(false);
      engine.start();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      final entered = Completer<void>();
      final release = Completer<void>();
      releases.add(release);
      var activationCount = 0;
      transport.handle = (request) async {
        if (request.uri.path == '/v1/sync/activate' && ++activationCount == 1) {
          entered.complete();
          await release.future;
          throw const CloudNetworkException();
        }
        return successful(request);
      };
      engine.foreground(true);
      await entered.future.timeout(const Duration(seconds: 2));
      await seed('a', sessionId: 'replacement-session-a');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      release.complete();
      await _until(
        () => observed.any((s) => s.accountId == 'a' && s.lastSyncAt != null),
      );
      final state = await repository.state('a');
      expect(state.blockedReason, isNull);
      expect(state.bootstrapCompleted, isTrue);
      expect((await sessions.read())!.sessionId, 'replacement-session-a');
      expect(activationCount, 2);
      expect(transport.maximumActive, 1);
    },
  );

  test(
    'logout while pulling cannot apply a late page or advance its cursor',
    () async {
      final saved = await node('local survives logout');
      engine.foreground(false);
      engine.start();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      final entered = Completer<void>();
      final release = Completer<void>();
      releases.add(release);
      transport.handle = (request) async {
        if (request.uri.path == '/v1/sync/pull') {
          entered.complete();
          await release.future;
          return _response({
            'records': [remoteNode('late remote content').toJson()],
            'nextCursor': 1,
            'hasMore': false,
            'serverTime': _now,
          });
        }
        return successful(request);
      };
      engine.foreground(true);
      await entered.future.timeout(const Duration(seconds: 2));
      await sessions.logoutLocally();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      release.complete();
      await _until(() => observed.last.accountId == null);
      final state = await repository.state('a');
      expect(state.cursor, 0);
      expect(state.bootstrapCompleted, isFalse);
      expect(state.lastSyncAt, isNull);
      expect((await content.node(saved.id))!.node.name, saved.name);
      expect(await content.node(_id), isNull);
      expect(
        transport.requests.any((r) => r.uri.path == '/v1/sync/push'),
        isFalse,
      );
      expect((await repository.documents()).single.row.accountId, isNull);
      expect(await sessions.read(), isNull);
    },
  );

  test(
    'disposing an in-flight worker keeps a returned page outside the database',
    () async {
      final entered = Completer<void>();
      final release = Completer<void>();
      releases.add(release);
      transport.handle = (request) async {
        if (request.uri.path == '/v1/sync/pull') {
          entered.complete();
          await release.future;
          return _response({
            'records': [remoteNode('late after dispose').toJson()],
            'nextCursor': 1,
            'hasMore': false,
            'serverTime': _now,
          });
        }
        return successful(request);
      };
      final run = engine.runNow();
      await entered.future.timeout(const Duration(seconds: 2));
      final disposed = engine.dispose();
      release.complete();
      await run;
      await disposed;
      final state = await repository.state('a');
      expect(state.cursor, 0);
      expect(state.bootstrapCompleted, isFalse);
      expect(state.lastSyncAt, isNull);
      expect(await db.select(db.selfNodes).get(), isEmpty);
      expect(await repository.documents(), isEmpty);
    },
  );

  test(
    'manual and local-edit triggers merge into one serial follow-up run',
    () async {
      final saved = await node('before');
      await engine.runNow();
      expect((await repository.state('a')).bootstrapCompleted, isTrue);
      engine.foreground(false);
      engine.start();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      final entered = Completer<void>();
      final release = Completer<void>();
      releases.add(release);
      var activationCount = 0;
      transport.requests.clear();
      transport.handle = (request) async {
        if (request.uri.path == '/v1/sync/activate') {
          activationCount++;
          if (activationCount == 1) {
            entered.complete();
            await release.future;
          }
        }
        return successful(request);
      };
      engine.foreground(true);
      await entered.future.timeout(const Duration(seconds: 2));
      await content.updateNode(saved.copyWith(name: 'edited while syncing'));
      final first = engine.runNow();
      final second = engine.runNow();
      expect(identical(first, second), isTrue);
      // Exercise the real two-second local-edit debounce while HTTP is pending.
      await Future<void>.delayed(const Duration(milliseconds: 2100));
      release.complete();
      await first;
      await _until(
        () =>
            activationCount == 2 &&
            observed.last.lastSyncAt != null &&
            !observed.last.busy,
      );
      expect(transport.maximumActive, 1);
      expect(activationCount, 2);
      final pushes = transport.requests
          .where((r) => r.uri.path == '/v1/sync/push')
          .toList();
      expect(pushes, hasLength(1));
      final sent = jsonDecode(utf8.decode(pushes.single.body!)) as Map;
      expect(
        ((sent['mutations']! as List).single as Map)['payload'],
        containsPair('name', 'edited while syncing'),
      );
      expect((await content.node(saved.id))!.node.name, 'edited while syncing');
      expect(
        (await db.select(db.syncMeta).get()).every((m) => !m.dirty),
        isTrue,
      );
    },
  );

  test(
    'a newly created unbound node wakes the completed account automatically',
    () async {
      await engine.runNow();
      expect((await repository.state('a')).bootstrapCompleted, isTrue);
      engine.foreground(false);
      engine.start();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      transport.requests.clear();
      engine.foreground(true);
      await _until(
        () =>
            transport.requests.any((r) => r.uri.path == '/v1/sync/pull') &&
            !observed.last.busy,
      );
      transport.requests.clear();
      final saved = await node('new local node triggers sync');
      // No manual worker call follows this edit: its committed document must
      // wake the worker even before an account-specific outbox row exists.
      await _until(
        () =>
            transport.requests.any((r) => r.uri.path == '/v1/sync/push') &&
            !observed.last.busy,
      );
      final pushes = transport.requests
          .where((r) => r.uri.path == '/v1/sync/push')
          .toList();
      expect(pushes, hasLength(1));
      final body = jsonDecode(utf8.decode(pushes.single.body!)) as Map;
      final sent = (body['mutations']! as List).single as Map;
      expect(sent['payload'], containsPair('name', saved.name));
      expect((await repository.documents()).single.row.accountId, 'a');
      expect((await db.select(db.syncMeta).get()).single.dirty, isFalse);
      expect((await content.node(saved.id))!.node.name, saved.name);
      expect(transport.maximumActive, 1);
    },
  );

  test(
    'a locked session vault blocks sync without throwing or changing local data',
    () async {
      final saved = await node('local content remains intact');
      final row = await (db.select(
        db.cloudSession,
      )..where((r) => r.id.equals(1))).getSingle();
      await (db.update(db.secrets)
            ..where((s) => s.id.equals(row.accessSecretId)))
          .write(SecretsCompanion(ciphertext: Value(Uint8List(0))));
      await engine.runNow();
      await _until(() => observed.last.blockedReason == 'VAULT_LOCKED');
      expect(transport.requests, isEmpty);
      expect((await content.node(saved.id))!.node.name, saved.name);
      expect((await repository.state('a')).cursor, 0);
      expect((await repository.documents()).single.row.accountId, isNull);
    },
  );

  test(
    'an unsupported record rejects its whole page without advancing cursor',
    () async {
      await repository.state('a');
      await (db.update(
        db.syncState,
      )..where((s) => s.accountId.equals('a'))).write(
        const SyncStateCompanion(
          cursor: Value(7),
          bootstrapCompleted: Value(true),
        ),
      );
      final valid = remoteNode('not partially applied', revision: 8).toJson();
      final future = Map<String, Object?>.from(valid)
        ..['recordId'] = _other
        ..['revision'] = 9
        ..['schemaVersion'] = 2;
      transport.handle = (request) async {
        if (request.uri.path == '/v1/sync/pull') {
          expect(request.uri.queryParameters['cursor'], '7');
          return _response({
            'records': [valid, future],
            'nextCursor': 9,
            'hasMore': false,
            'serverTime': _now,
          });
        }
        return successful(request);
      };
      await engine.runNow();
      final state = await repository.state('a');
      expect(state.cursor, 7);
      expect(state.blockedReason, 'SCHEMA_UNSUPPORTED');
      expect(await db.select(db.selfNodes).get(), isEmpty);
      expect(await repository.documents(), isEmpty);
      expect(
        transport.requests.any((r) => r.uri.path == '/v1/sync/push'),
        isFalse,
      );
    },
  );

  test(
    'expired entitlement stops before bootstrap, pull or push and keeps local content',
    () async {
      final saved = await node('local remains available');
      transport.handle = (request) async {
        expect(request.uri.path, '/v1/sync/activate');
        return _response({
          'error': {
            'code': 'NO_ENTITLEMENT',
            'message': 'Entitlement expired.',
          },
        }, status: 402);
      };
      await engine.runNow();
      final state = await repository.state('a');
      expect(state.bootstrapCompleted, isFalse);
      expect(state.cursor, 0);
      expect(state.blockedReason, 'NO_ENTITLEMENT');
      expect(transport.requests, hasLength(1));
      expect((await content.node(saved.id))!.node.name, saved.name);
      expect((await repository.documents()).single.row.accountId, isNull);
      expect((await sessions.read())!.accountId, 'a');
    },
  );

  test(
    'invalid upload fields block only sync and never roll back a local edit',
    () async {
      final saved = await node('local name ' * 1000);
      expect((await content.node(saved.id))!.node.name, saved.name);
      await engine.runNow();
      final state = await repository.state('a');
      expect(state.blockedReason, 'VALIDATION');
      expect(state.lastSyncAt, isNull);
      expect(
        transport.requests.any((r) => r.uri.path == '/v1/sync/push'),
        isFalse,
      );
      expect((await content.node(saved.id))!.node.name, saved.name);
      expect((await db.select(db.syncMeta).get()).single.dirty, isTrue);
      await content.updateNode(saved.copyWith(name: 'valid corrected name'));
      await engine.runNow();
      final recovered = await repository.state('a');
      expect(recovered.blockedReason, isNull);
      expect(recovered.lastSyncAt, isNotNull);
      expect((await content.node(saved.id))!.node.name, 'valid corrected name');
    },
  );

  Future<void> enableLifecycle() async {
    await engine.dispose();
    await statuses.cancel();
    engine = SyncEngine(
      auth: auth,
      repository: repository,
      projection: projection,
      db: db,
      lifecycleEnabled: true,
    );
    observed.clear();
    statuses = engine.watch().listen(observed.add);
  }

  test(
    'v2 expired account can read status but never reads or writes payload',
    () async {
      await enableLifecycle();
      final saved = await node('retained local content');
      transport.handle = (request) async {
        expect(request.uri.path, '/v1/sync/status');
        return _response(
          _lifecycleJson(spaceState: 'retained', backupState: 'ready'),
          version: 2,
        );
      };
      await engine.runNow();
      expect((await repository.state('a')).blockedReason, 'NO_ENTITLEMENT');
      expect(transport.requests, hasLength(1));
      expect((await content.node(saved.id))!.node.name, saved.name);
      expect((await repository.documents()).single.row.accountId, isNull);
    },
  );

  test(
    'v2 new cleared space waits for explicit local rebuild selection',
    () async {
      await enableLifecycle();
      final saved = await node('not automatically restored');
      final cloud = _LifecycleCloud();
      transport.handle = cloud.send;
      await engine.runNow();
      expect(
        (await repository.state('a')).blockedReason,
        'SYNC_REBUILD_REQUIRED',
      );
      expect(cloud.receipts, isEmpty);
      expect(cloud.records, isEmpty);
      expect((await content.node(saved.id))!.node.name, saved.name);
      expect((await repository.documents()).single.row.accountId, isNull);
    },
  );

  for (final interruption in ['start', 'push', 'complete']) {
    test(
      'v2 $interruption lost response resumes exactly one immutable rebuild after restart',
      () async {
        await enableLifecycle();
        final saved = await node('original local rebuild content');
        final cloud = _LifecycleCloud();
        transport.handle = cloud.send;
        await engine.runNow();
        if (interruption == 'push') {
          cloud.dropPush = true;
        } else {
          cloud.dropAction = interruption;
        }
        await expectLater(
          engine.rebuildFromDevice(),
          throwsA(isA<CloudNetworkException>()),
        );
        final before = await repository.state('a');
        expect(before.bootstrapCompleted, isFalse);
        expect(before.cursor, 0);
        expect(before.lastSyncAt, isNull);
        expect((await content.node(saved.id))!.node.name, saved.name);
        final firstRequests = transport.requests
            .where(
              (r) =>
                  r.uri.path ==
                      (interruption == 'push'
                          ? '/v1/sync/push'
                          : '/v1/sync/rebuild') &&
                  (interruption == 'push' ||
                      (jsonDecode(utf8.decode(r.body!)) as Map)['action'] ==
                          interruption),
            )
            .toList();
        expect(firstRequests, hasLength(1));
        final firstBytes = firstRequests.single.body!;
        // New engine instance reads durable state; no in-memory retry plan survives.
        await enableLifecycle();
        await engine.runNow();
        final recovered = await repository.state('a');
        expect(recovered.backupState, 'ready');
        expect(recovered.bootstrapCompleted, isTrue);
        expect(recovered.blockedReason, isNull);
        expect(recovered.lastSyncAt, isNotNull);
        expect(
          cloud.receipts.values.where((r) => r['phase'] == 'staging'),
          hasLength(1),
        );
        expect(
          cloud.records.values.where((r) => r['type'] == 'node'),
          hasLength(1),
        );
        final replay = transport.requests
            .where(
              (r) =>
                  r.uri.path ==
                      (interruption == 'push'
                          ? '/v1/sync/push'
                          : '/v1/sync/rebuild') &&
                  (interruption == 'push' ||
                      (jsonDecode(utf8.decode(r.body!)) as Map)['action'] ==
                          interruption),
            )
            .toList();
        expect(replay, hasLength(2));
        expect(replay.last.body, orderedEquals(firstBytes));
        expect((await content.node(saved.id))!.node.name, saved.name);
        expect(
          (await repository.documents(accountId: 'a')).single.row.localEditedAt,
          cloud.records.values.single['editedAt'],
        );
      },
    );
  }

  test(
    'v2 original start receipt grants no writes after another device takes ownership',
    () async {
      await enableLifecycle();
      await node('local chosen input');
      final cloud = _LifecycleCloud()..replacedAfterStart = true;
      transport.handle = cloud.send;
      await engine.runNow();
      await expectLater(engine.rebuildFromDevice(), throwsA(isA<Exception>()));
      expect(
        (await repository.state('a')).blockedReason,
        'SYNC_REBUILD_IN_PROGRESS',
      );
      expect(
        transport.requests.any((r) => r.uri.path == '/v1/sync/push'),
        isFalse,
      );
      expect(cloud.records, isEmpty);
      expect(await db.select(db.syncArchives).get(), isNotEmpty);
      expect(
        (await repository.documents(
          accountId: 'a',
        )).single.localPayload!['name'],
        'local chosen input',
      );
    },
  );

  test(
    'v2 moving full-download head stays invisible and never binds independent local nodes',
    () async {
      await enableLifecycle();
      final independent = await node('independent stays local');
      var pull = 0;
      var head = 2;
      transport.handle = (request) async {
        switch (request.uri.path) {
          case '/v1/sync/status':
            return _response(
              _lifecycleJson(backupState: 'ready', head: head),
              version: 2,
            );
          case '/v1/sync/activate':
            return _response({
              'deviceId': 'device-a',
              'syncActive': true,
              'deviceLimit': 10,
              'syncActiveDeviceCount': 1,
              'serverTime': _now,
              'syncGeneration': _cloudGeneration,
              'backupState': 'ready',
              'rebuildAttemptId': null,
            }, version: 2);
          case '/v1/sync/pull':
            final cursor = int.parse(request.uri.queryParameters['cursor']!);
            pull++;
            if (pull == 1) {
              return _response({
                'syncGeneration': _cloudGeneration,
                'rebuildAttemptId': null,
                'headRevision': 2,
                'records': [remoteNode('half snapshot').toJson()],
                'nextCursor': 1,
                'hasMore': true,
                'serverTime': _now,
              }, version: 2);
            }
            if (pull == 2) {
              expect(await db.select(db.selfNodes).get(), hasLength(1));
              expect((await repository.state('a')).cursor, 0);
              head = 3;
              return _response({
                'syncGeneration': _cloudGeneration,
                'rebuildAttemptId': null,
                'headRevision': 3,
                'records': [
                  remoteNode('changed snapshot', revision: 3).toJson(),
                ],
                'nextCursor': 3,
                'hasMore': false,
                'serverTime': _now,
              }, version: 2);
            }
            return _response({
              'syncGeneration': _cloudGeneration,
              'rebuildAttemptId': null,
              'headRevision': 3,
              'records': cursor == 0
                  ? [remoteNode('complete snapshot', revision: 3).toJson()]
                  : <Object?>[],
              'nextCursor': 3,
              'hasMore': false,
              'serverTime': _now,
            }, version: 2);
          default:
            fail('A follower must not upload or rebuild implicitly.');
        }
      };
      await engine.runNow();
      expect((await repository.state('a')).blockedReason, isNull);
      expect((await repository.state('a')).cursor, 3);
      expect((await content.node(independent.id))!.node.name, independent.name);
      expect(
        (await db.select(db.selfNodes).get()).map((r) => r.name),
        containsAll([independent.name, 'complete snapshot']),
      );
      expect(
        (await repository.documents(
          unbound: true,
        )).single.localPayload!['name'],
        independent.name,
      );
      expect(await db.select(db.syncPullStages).get(), isEmpty);
    },
  );

  test(
    'v2 other-device publication quarantines the old owned attempt and retains later local edits',
    () async {
      await enableLifecycle();
      final saved = await node('frozen original');
      final cloud = _LifecycleCloud();
      transport.handle = cloud.send;
      await engine.runNow();
      cloud.dropPush = true;
      await expectLater(
        engine.rebuildFromDevice(),
        throwsA(isA<CloudNetworkException>()),
      );
      await content.updateNode(saved.copyWith(name: 'edited after freeze'));
      // Another device publishes the new backup while A was disconnected.
      cloud.backupState = 'ready';
      cloud.owner = 'other-device';
      cloud.head = cloud.records.length;
      await enableLifecycle();
      await engine.runNow();
      final joined = await repository.state('a');
      expect(joined.blockedReason, isNull);
      expect(joined.backupState, 'ready');
      expect(joined.rebuildAttemptId, isNull);
      expect(joined.rebuildLocalAttemptId, isNull);
      expect((await content.node(saved.id))!.node.name, 'edited after freeze');
      expect(
        cloud.records.values.single['payload'],
        containsPair('name', 'edited after freeze'),
      );
      expect(
        cloud.receipts.values.where((r) => r['phase'] == 'staging'),
        hasLength(1),
      );
      expect(await db.select(db.syncArchives).get(), isNotEmpty);
    },
  );
}
