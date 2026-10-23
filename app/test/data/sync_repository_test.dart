import 'dart:convert';

import 'package:avalon/data/database/database.dart';
import 'package:avalon/data/repositories/cloud_session_repository.dart';
import 'package:avalon/data/repositories/sync_repository.dart';
import 'package:avalon/data/vault/secret_store.dart';
import 'package:avalon/data/vault/vault.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const _recordId = '00000000-0000-4000-8000-000000000001';
const _secret = 'sync-test-password-never-plaintext';
late String _installation;

Map<String, Object?> _node(String name) => {
  'name': name,
  'server': 'test.example.com',
  'port': 443,
  'params': {
    'protocol': 'trojan',
    'password': {r'$secret': 'password'},
  },
  'secrets': {'password': _secret},
  'createdAt': 10,
  'memberships': <Object?>[],
};

Map<String, Object?> _remote(
  String name, {
  int revision = 1,
  int editedAt = 100,
  bool deleted = false,
  String recordId = _recordId,
}) => {
  'recordId': recordId,
  'type': 'node',
  'revision': revision,
  'editedAt': editedAt,
  'deleted': deleted,
  'schemaVersion': 1,
  'payload': deleted ? null : _node(name),
};

StoredCloudSession _session(String account, String session) =>
    StoredCloudSession(
      accountId: account,
      deviceId: 'device-$account',
      sessionId: session,
      installationId: _installation,
      accessToken: 'fake-access-$session',
      refreshToken: 'fake-refresh-$session',
      accessExpiresAt: DateTime.utc(2030),
      refreshExpiresAt: DateTime.utc(2031),
    );

void main() {
  late AppDatabase db;
  late SecretStore secrets;
  late CloudSessionRepository sessions;
  late SyncRepository repository;
  late SyncIdentity identity;
  var current = true;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    final vault = await Vault.open(MemoryKeyStore());
    secrets = SecretStore(db, vault);
    sessions = CloudSessionRepository(db, secrets);
    repository = SyncRepository(db, secrets);
    _installation = await sessions.installationId();
    await sessions.save(_session('account-a', 'session-a'));
    identity = (await repository.capture(1))!;
    current = true;
  });
  tearDown(() => db.close());

  Future<SyncDocumentSnapshot> edit(
    String name, {
    String? documentId,
    String account = 'account-a',
    int editedAt = 200,
    String recordId = _recordId,
    bool enqueue = true,
  }) => repository.saveLocal(
    documentId: documentId,
    accountId: account,
    recordId: recordId,
    type: 'node',
    localId: recordId,
    editedAt: editedAt,
    deleted: false,
    payload: _node(name),
    enqueue: enqueue,
  );

  Future<List<FrozenSyncMutation>> send() =>
      repository.preparePush(identity, () => current);

  Future<void> applied(
    List<FrozenSyncMutation> sent, {
    int revision = 1,
    int editedAt = 200,
  }) => repository.commitPushPrefix(
    identity,
    () => current,
    sent: sent,
    results: [
      {
        'mutationId': sent.first.mutationId,
        'status': 'applied',
        'revision': revision,
        'editedAt': editedAt,
      },
    ],
  );

  test(
    'request budget freezes only sent prefix and leaves tail replaceable',
    () async {
      final first = await edit('first');
      final tail = await edit(
        'unsent tail',
        recordId: '00000000-0000-4000-8000-000000000002',
      );
      final sealed = await secrets.get(first.meta!.pendingEnvelopeSecretId!);
      final prefix = await repository.preparePush(
        identity,
        () => current,
        maxBodyBytes: 16 + utf8.encode(sealed['envelope']!).length,
      );
      expect(prefix.single.recordId, first.row.recordId);
      final unsent = (await repository.document(tail.row.documentId))!;
      expect(unsent.meta!.inFlightMutationId, isNull);
      final newer = await edit(
        'new tail credentials',
        documentId: tail.row.documentId,
        recordId: tail.row.recordId,
        editedAt: 201,
      );
      await applied(prefix);
      final next = await send();
      expect(next.single.mutationId, newer.meta!.mutationId);
      expect(
        next.single.envelope['payload'],
        containsPair('name', 'new tail credentials'),
      );
      expect(next.single.mutationId, isNot(tail.meta!.mutationId));
    },
  );

  test('preflight rejection rolls back every newly frozen slot', () async {
    final first = await edit('first');
    final second = await edit(
      'second',
      recordId: '00000000-0000-4000-8000-000000000002',
    );
    await expectLater(
      repository.preparePush(
        identity,
        () => current,
        validate: (mutation) async {
          if (mutation.recordId == second.row.recordId) {
            throw StateError('blocked');
          }
        },
      ),
      throwsStateError,
    );
    expect(
      (await repository.document(
        first.row.documentId,
      ))!.meta!.inFlightMutationId,
      isNull,
    );
    expect(
      (await repository.document(
        second.row.documentId,
      ))!.meta!.inFlightMutationId,
      isNull,
    );
    expect(await send(), hasLength(2));
  });

  test(
    'new edit during an unknown request preserves both frozen slots',
    () async {
      final first = await edit('first');
      final sent = await send();
      final firstPending = first.meta!.pendingEnvelopeSecretId!;
      final newer = await edit(
        'newer',
        documentId: first.row.documentId,
        editedAt: 201,
      );
      expect(newer.meta!.inFlightMutationId, sent.single.mutationId);
      expect(newer.meta!.pendingEnvelopeSecretId, isNot(firstPending));
      expect(await secrets.deleteOrphans(), 0);
      expect((await send()).single.envelopeJson, sent.single.envelopeJson);
      await applied(sent);
      final after = (await repository.document(first.row.documentId))!;
      expect(after.localPayload!['name'], 'newer');
      expect(after.row.localEditedAt, 201);
      expect(after.remotePayload!['name'], 'first');
      expect(after.dirty, isTrue);
      expect(after.meta!.mutationId, newer.meta!.mutationId);
      expect(after.meta!.inFlightMutationId, isNull);
      expect((await send()).single.mutationId, newer.meta!.mutationId);
      // The second edit remains frozen against its original observed revision.
      expect((await send()).single.envelope['baseRevision'], 0);
    },
  );

  test(
    'lost response retries exact ID, body and baseRevision across restart',
    () async {
      await edit('pending');
      final original = await send();
      repository = SyncRepository(db, secrets);
      await repository.commitPullPage(
        identity,
        () => current,
        records: [_remote('older', revision: 5, editedAt: 100)],
        nextCursor: 5,
      );
      final retry = await send();
      expect(retry.single.mutationId, original.single.mutationId);
      expect(retry.single.envelopeJson, original.single.envelopeJson);
      expect(retry.single.envelope['baseRevision'], 0);
    },
  );

  test(
    'superseded future timestamp clears the judged edit and converges',
    () async {
      final first = await edit('future', editedAt: 9000000000000);
      final sent = await send();
      await repository.commitPushPrefix(
        identity,
        () => current,
        sent: sent,
        results: [
          {
            'mutationId': sent.single.mutationId,
            'status': 'superseded',
            'record': _remote('server-winner', editedAt: 100),
          },
        ],
      );
      final after = (await repository.document(first.row.documentId))!;
      expect(after.localPayload!['name'], 'server-winner');
      expect(after.row.localEditedAt, 100);
      expect(after.dirty, isFalse);
      expect(after.meta!.pendingEnvelopeSecretId, isNull);
      expect(after.meta!.inFlightEnvelopeSecretId, isNull);
      expect(await send(), isEmpty);
    },
  );

  test(
    'pull cancellation retains unresolved request; old replay never regresses',
    () async {
      final first = await edit('old');
      final sent = await send();
      await repository.commitPullPage(
        identity,
        () => current,
        records: [_remote('latest', revision: 10, editedAt: 300)],
        nextCursor: 10,
      );
      final pulled = (await repository.document(first.row.documentId))!;
      expect(pulled.dirty, isFalse);
      expect(pulled.meta!.inFlightMutationId, sent.single.mutationId);
      expect((await send()).single.envelopeJson, sent.single.envelopeJson);
      await applied(sent, revision: 5, editedAt: 200);
      final after = (await repository.document(first.row.documentId))!;
      expect(after.localPayload!['name'], 'latest');
      expect(after.row.remoteRevision, 10);
      expect(after.meta!.inFlightMutationId, isNull);
    },
  );

  test(
    'superseded old request cannot clear a newer edit even in same millisecond',
    () async {
      final first = await edit('old');
      final sent = await send();
      final next = await edit('new', documentId: first.row.documentId);
      await repository.commitPushPrefix(
        identity,
        () => current,
        sent: sent,
        results: [
          {
            'mutationId': sent.single.mutationId,
            'status': 'superseded',
            'record': _remote('remote-winner'),
          },
        ],
      );
      final after = (await repository.document(first.row.documentId))!;
      expect(after.localPayload!['name'], 'new');
      expect(after.meta!.mutationId, next.meta!.mutationId);
      expect(after.dirty, isTrue);
      expect(after.remotePayload!['name'], 'remote-winner');
    },
  );

  test('processed prefix leaves unprocessed suffix frozen', () async {
    await edit('a');
    await edit('b', recordId: '00000000-0000-4000-8000-000000000002');
    final batch = await send();
    expect(batch, hasLength(2));
    await applied(batch);
    final remaining = await send();
    expect(remaining, hasLength(1));
    expect(remaining.single.envelopeJson, batch.last.envelopeJson);
  });

  test(
    'late account or replaced session results cannot write anything',
    () async {
      final first = await edit('a');
      final batch = await send();
      await sessions.save(_session('account-b', 'session-b'));
      await expectLater(applied(batch), throwsA(isA<StaleSyncIdentity>()));
      final preserved = (await repository.document(first.row.documentId))!;
      expect(preserved.dirty, isTrue);
      expect(preserved.meta!.inFlightMutationId, batch.single.mutationId);
      expect(preserved.row.remoteRevision, isNull);
      await sessions.save(_session('account-a', 'replacement-session'));
      await expectLater(applied(batch), throwsA(isA<StaleSyncIdentity>()));
    },
  );

  test(
    'worker stopping during projection rolls back whole page and secrets',
    () async {
      await repository.completeBootstrap(
        identity,
        () => current,
        merge: () async {},
      );
      final countBefore = (await db.select(db.secrets).get()).length;
      await expectLater(
        repository.commitPullPage(
          identity,
          () => current,
          records: [_remote('incoming')],
          nextCursor: 1,
          project: (_) async {
            await db
                .into(db.chains)
                .insert(
                  ChainsCompanion.insert(
                    id: 'projection',
                    hopsJson: '[]',
                    createdAt: 1,
                    editedAt: 1,
                  ),
                );
            current = false;
          },
        ),
        throwsA(isA<StaleSyncIdentity>()),
      );
      expect(await repository.documents(), isEmpty);
      expect(await db.select(db.chains).get(), isEmpty);
      expect((await repository.state('account-a')).cursor, 0);
      expect((await db.select(db.secrets).get()).length, countBefore);
    },
  );

  test(
    'projection failure rolls back processed prefix and can retry',
    () async {
      final first = await edit('a');
      final batch = await send();
      final countBefore = (await db.select(db.secrets).get()).length;
      await expectLater(
        repository.commitPushPrefix(
          identity,
          () => current,
          sent: batch,
          results: [
            {
              'mutationId': batch.single.mutationId,
              'status': 'applied',
              'revision': 1,
              'editedAt': 200,
            },
          ],
          project: (_) async => throw StateError('projection failed'),
        ),
        throwsStateError,
      );
      final after = (await repository.document(first.row.documentId))!;
      expect(after.row.remoteRevision, isNull);
      expect(after.dirty, isTrue);
      expect(after.meta!.inFlightMutationId, batch.single.mutationId);
      expect((await db.select(db.secrets).get()).length, countBefore);
      await applied(batch);
      expect((await repository.document(first.row.documentId))!.dirty, isFalse);
    },
  );

  test(
    'bootstrap marker remains false for a nonzero persisted cursor',
    () async {
      var projections = 0;
      await repository.commitPullPage(
        identity,
        () => current,
        records: [_remote('first')],
        nextCursor: 1,
        project: (_) async => projections++,
      );
      expect((await repository.state('account-a')).cursor, 1);
      expect((await repository.state('account-a')).bootstrapCompleted, isFalse);
      expect(projections, 0);
      await expectLater(
        repository.completeBootstrap(
          identity,
          () => current,
          merge: () async => throw StateError('interrupted merge'),
        ),
        throwsStateError,
      );
      expect((await repository.state('account-a')).bootstrapCompleted, isFalse);
      await repository.completeBootstrap(
        identity,
        () => current,
        merge: () async {},
      );
      expect((await repository.state('account-a')).bootstrapCompleted, isTrue);
    },
  );

  test(
    'same UUID in two accounts has isolated canonical owners and aliases',
    () async {
      await repository.commitPullPage(
        identity,
        () => current,
        records: [_remote('account-a')],
        nextCursor: 1,
      );
      await sessions.save(_session('account-b', 'session-b'));
      final b = (await repository.capture(2))!;
      await repository.commitPullPage(
        b,
        () => current,
        records: [_remote('account-b')],
        nextCursor: 1,
      );
      final aDocument = (await repository.findDocument(
        'account-a',
        _recordId,
      ))!;
      final bDocument = (await repository.findDocument(
        'account-b',
        _recordId,
      ))!;
      expect(aDocument.row.documentId, isNot(bDocument.row.documentId));
      expect(aDocument.row.localId, isNot(bDocument.row.localId));
      expect(aDocument.localPayload!['name'], 'account-a');
      expect(bDocument.localPayload!['name'], 'account-b');
    },
  );

  test(
    'semantically unchanged hydration preserves time and mutation',
    () async {
      final first = await edit('unchanged');
      final hydrated = await edit(
        'unchanged',
        documentId: first.row.documentId,
        editedAt: 999,
      );
      expect(hydrated.row.localEditedAt, 200);
      expect(hydrated.meta!.mutationId, first.meta!.mutationId);
      await repository.reconcileAccount('account-a');
      expect(
        (await repository.document(first.row.documentId))!.meta!.mutationId,
        first.meta!.mutationId,
      );
    },
  );

  test(
    'offline same-millisecond edit reconciles without changing retained inflight',
    () async {
      final first = await edit('before');
      final batch = await send();
      final afterOffline = await edit(
        'offline',
        documentId: first.row.documentId,
        enqueue: false,
      );
      expect(afterOffline.meta!.mutationId, first.meta!.mutationId);
      await repository.reconcileAccount('account-a');
      final reconciled = (await repository.document(first.row.documentId))!;
      expect(reconciled.meta!.mutationId, isNot(first.meta!.mutationId));
      expect(reconciled.meta!.inFlightMutationId, batch.single.mutationId);
      expect(reconciled.row.localEditedAt, 200);
    },
  );

  test(
    'SQLite contains no canonical credentials; orphan cleanup keeps every slot',
    () async {
      final first = await edit('first');
      final batch = await send();
      await edit('second', documentId: first.row.documentId, editedAt: 201);
      await repository.commitPullPage(
        identity,
        () => current,
        records: [_remote('mirror', editedAt: 100)],
        nextCursor: 1,
      );
      final unused = await secrets.put({'unused': 'fake'});
      expect(await secrets.deleteOrphans(), 1);
      await expectLater(secrets.get(unused), throwsStateError);
      expect((await send()).single.envelopeJson, batch.single.envelopeJson);
      for (final table in [
        'sync_documents',
        'sync_meta',
        'sync_state',
        'source_provenance',
      ]) {
        final rows = await db.customSelect('SELECT * FROM $table').get();
        expect(
          jsonEncode(rows.map((r) => r.data).toList()),
          isNot(contains(_secret)),
        );
      }
      expect(
        (await repository.document(
          first.row.documentId,
        ))!.remotePayload!['name'],
        'mirror',
      );
    },
  );

  test(
    'account detachment preserves canonical secret and cloud provenance only for its owner',
    () async {
      final a = await edit('a');
      await repository.setSource(
        documentId: a.row.documentId,
        origin: 'cloud',
        originAccountId: 'account-a',
      );
      await send();
      final b = await edit('b', account: 'account-b');
      await repository.detachAccount('account-a');
      final local = (await repository.document(a.row.documentId))!;
      expect(local.row.accountId, isNull);
      expect(local.localPayload!['name'], 'a');
      expect(local.meta, isNull);
      expect((await repository.provenance(a.row.documentId))!.origin, 'cloud');
      expect((await repository.document(b.row.documentId))!.dirty, isTrue);
      expect(await secrets.deleteOrphans(), 0);
    },
  );

  test(
    'cloud source rotates consent on a real source change but not a rename',
    () async {
      Map<String, Object?> subscription(String name, String url) => {
        'kind': 'subscription',
        'name': name,
        'autoUpdate': false,
        'createdAt': 10,
        'source': {'url': url, 'headers': <String, Object?>{}},
      };
      final local = await repository.saveLocal(
        accountId: 'account-a',
        recordId: _recordId,
        type: 'configuration',
        localId: _recordId,
        editedAt: 10,
        deleted: false,
        payload: subscription('local', 'https://a.example.com'),
      );
      final consent = await repository.setSource(
        documentId: local.row.documentId,
        origin: 'local_user',
        allowPrivate: true,
      );
      expect(consent.privateConsentGeneration, consent.sourceGeneration);
      Future<void> pull(int revision, String name, String url) =>
          repository.commitPullPage(
            identity,
            () => current,
            records: [
              {
                'recordId': _recordId,
                'type': 'configuration',
                'revision': revision,
                'editedAt': revision + 100,
                'deleted': false,
                'schemaVersion': 1,
                'payload': subscription(name, url),
              },
            ],
            nextCursor: revision,
          );
      await pull(1, 'cloud', 'https://a.example.com');
      final cloud = (await repository.provenance(local.row.documentId))!;
      expect(cloud.privateConsentGeneration, isNull);
      expect(cloud.sourceGeneration, isNot(consent.sourceGeneration));
      await pull(2, 'renamed', 'https://a.example.com');
      expect(
        (await repository.provenance(local.row.documentId))!.sourceGeneration,
        cloud.sourceGeneration,
      );
      await pull(3, 'new-source', 'https://b.example.com');
      expect(
        (await repository.provenance(local.row.documentId))!.sourceGeneration,
        isNot(cloud.sourceGeneration),
      );
    },
  );
  const generationOne = '10000000-0000-4000-8000-000000000001';
  const generationTwo = '10000000-0000-4000-8000-000000000002';
  const localAttempt = '20000000-0000-4000-8000-000000000001';
  const serverAttempt = '20000000-0000-4000-8000-000000000002';
  const operation = '30000000-0000-4000-8000-000000000001';

  Future<void> adopt(String generation, {String backupState = 'ready'}) async {
    identity = await repository.adoptGeneration(
      identity,
      () => current,
      generation,
      backupState: backupState,
    );
  }

  test(
    'legacy unknown envelope needs proof and preserves exact retry body',
    () async {
      await edit('unknown legacy upload');
      final oldIdentity = identity;
      final original = (await send()).single;
      await expectLater(
        repository.adoptGeneration(identity, () => current, generationOne),
        throwsA(isA<SyncLegacyScopeUnverified>()),
      );
      expect((await send()).single.envelopeJson, original.envelopeJson);
      identity = await repository.adoptGeneration(
        identity,
        () => current,
        generationOne,
        preserveLegacyHistory: true,
      );
      final scoped = (await send()).single;
      expect(scoped.envelopeJson, original.envelopeJson);
      expect(scoped.mutationId, original.mutationId);
      expect(scoped.syncGeneration, generationOne);
      expect(await db.select(db.syncArchives).get(), hasLength(1));
      await secrets.deleteOrphans();
      final archived = await db.select(db.syncArchiveReferences).get();
      expect(archived, isNotEmpty);
      for (final reference in archived) {
        expect(await secrets.get(reference.secretId), isNotEmpty);
      }
      await expectLater(
        repository.preparePush(oldIdentity, () => current),
        throwsA(isA<StaleSyncIdentity>()),
      );
    },
  );

  test(
    'new generation isolates old mirrors and retains genuine offline edits',
    () async {
      await adopt(generationOne);
      await repository.commitPullPage(
        identity,
        () => current,
        records: [
          _remote('unchanged mirror'),
          _remote(
            'old remote',
            revision: 2,
            recordId: '00000000-0000-4000-8000-000000000002',
          ),
        ],
        nextCursor: 2,
      );
      final local = (await repository.findDocument(
        'account-a',
        '00000000-0000-4000-8000-000000000002',
      ))!;
      await edit(
        'offline change',
        documentId: local.row.documentId,
        recordId: local.row.recordId,
        editedAt: 300,
      );
      final oldSent = (await send()).single;
      final oldIdentity = identity;
      await adopt(generationTwo);
      await repository.reconcileAccount('account-a');
      final sent = await send();
      expect(sent, hasLength(1));
      expect(sent.single.recordId, local.row.recordId);
      expect(sent.single.mutationId, isNot(oldSent.mutationId));
      expect(sent.single.envelope['editedAt'], 300);
      expect(sent.single.envelope['baseRevision'], 0);
      expect(sent.single.syncGeneration, generationTwo);
      final retained = (await repository.findDocument('account-a', _recordId))!;
      expect(retained.localPayload!['name'], 'unchanged mirror');
      expect(retained.row.pendingMerge, isFalse);
      expect(retained.row.remoteRevision, isNull);
      expect((await repository.state('account-a')).cursor, 0);
      await expectLater(
        repository.commitPushPrefix(
          oldIdentity,
          () => current,
          sent: [oldSent],
          results: [
            {
              'mutationId': oldSent.mutationId,
              'status': 'applied',
              'revision': 3,
              'editedAt': 300,
            },
          ],
        ),
        throwsA(isA<StaleSyncIdentity>()),
      );
      expect(
        (await repository.document(
          local.row.documentId,
        ))!.localPayload!['name'],
        'offline change',
      );
      expect(await secrets.deleteOrphans(), 0);
    },
  );

  test(
    'explicit legacy retirement archives rather than relabels unknown requests',
    () async {
      await repository.commitPullPage(
        identity,
        () => current,
        records: [_remote('unchanged legacy mirror')],
        nextCursor: 1,
      );
      final original = await edit(
        'unconfirmed local',
        recordId: '00000000-0000-4000-8000-000000000002',
      );
      final sent = (await send()).single;
      identity = await repository.adoptGeneration(
        identity,
        () => current,
        generationTwo,
        retireLegacyHistory: true,
      );
      await repository.reconcileAccount('account-a');
      final replacement = (await send()).single;
      expect(replacement.recordId, original.row.recordId);
      expect(replacement.mutationId, isNot(sent.mutationId));
      expect(
        (await repository.findDocument(
          'account-a',
          _recordId,
        ))!.row.pendingMerge,
        isFalse,
      );
      final archives = await db.select(db.syncArchives).get();
      expect(archives, hasLength(1));
      final metadata =
          jsonDecode(
                (await secrets.get(
                  archives.single.payloadSecretId,
                ))['archive']!,
              )
              as Map;
      expect((metadata['state'] as Map)['cursor'], 1);
      expect(
        ((metadata['outbox'] as List).cast<Map<String, Object?>>().singleWhere(
          (m) => m['recordId'] == original.row.recordId,
        ))['inFlightMutationId'],
        sent.mutationId,
      );
    },
  );

  test(
    'rebuild is immutable, resumable and does not project staged acknowledgements',
    () async {
      await adopt(generationOne, backupState: 'rebuildRequired');
      final doc = await edit('frozen input', editedAt: 123);
      expect(doc.meta, isNull);
      final manifest = await repository.beginRebuild(
        identity,
        () => current,
        localAttempt,
      );
      identity = manifest.identity;
      expect(manifest.toJson(), {
        'manifestId': localAttempt,
        'entries': [
          {
            'recordId': _recordId,
            'type': 'node',
            'mutationId': manifest.entries.single['mutationId'],
          },
        ],
      });
      identity = await repository.bindRebuildAttempt(
        identity,
        () => current,
        localAttemptId: localAttempt,
        serverAttemptId: serverAttempt,
      );
      final sent = await repository.prepareRebuildPush(identity, () => current);
      await edit(
        'edit after freeze',
        documentId: doc.row.documentId,
        editedAt: 124,
      );
      identity = (await repository.capture(2))!;
      final replay = await repository.prepareRebuildPush(
        identity,
        () => current,
      );
      expect(replay.single.envelopeJson, sent.single.envelopeJson);
      expect(replay.single.envelope['editedAt'], 123);
      expect(
        (replay.single.envelope['payload'] as Map)['name'],
        'frozen input',
      );
      await expectLater(
        repository.completeRebuild(identity, () => current),
        throwsA(isA<SyncRebuildIncomplete>()),
      );
      await repository.commitRebuildPrefix(
        identity,
        () => current,
        sent: replay,
        results: [
          {
            'mutationId': replay.single.mutationId,
            'status': 'applied',
            'revision': 1,
            'editedAt': 123,
          },
        ],
      );
      expect(
        await repository.prepareRebuildPush(identity, () => current),
        isEmpty,
      );
      final staged = (await repository.document(doc.row.documentId))!;
      expect(staged.row.remoteRevision, isNull);
      expect(staged.localPayload!['name'], 'edit after freeze');
      expect((await repository.state('account-a')).cursor, 0);
      identity = await repository.completeRebuild(identity, () => current);
      expect(identity.rebuildAttemptId, isNull);
      expect(
        (await repository.document(doc.row.documentId))!.row.pendingMerge,
        isTrue,
      );
      expect((await repository.state('account-a')).bootstrapCompleted, isFalse);
      expect(await db.select(db.syncArchives).get(), hasLength(2));
      expect(await secrets.deleteOrphans(), 0);
    },
  );

  test(
    'unknown control is encrypted, immutable and cleared by exact operation only',
    () async {
      await adopt(generationOne, backupState: 'rebuildRequired');
      final control = <String, Object?>{
        'operationId': operation,
        'syncGeneration': generationOne,
        'action': 'start',
        'manifest': {'manifestId': localAttempt, 'entries': <Object?>[]},
      };
      await repository.saveRebuildControl(identity, () => current, control);
      final secretId = (await repository.state(
        'account-a',
      )).rebuildControlSecretId;
      await repository.saveRebuildControl(identity, () => current, control);
      expect(
        (await repository.state('account-a')).rebuildControlSecretId,
        secretId,
      );
      identity = (await repository.capture(2))!;
      expect(await repository.readRebuildControl(identity), control);
      await expectLater(
        repository.saveRebuildControl(identity, () => current, {
          ...control,
          'operationId': localAttempt,
        }),
        throwsA(isA<SyncRebuildIncomplete>()),
      );
      await expectLater(
        repository.clearRebuildControl(
          identity,
          () => current,
          operationId: localAttempt,
        ),
        throwsA(isA<StaleSyncIdentity>()),
      );
      expect(await repository.readRebuildControl(identity), control);
      await repository.clearRebuildControl(
        identity,
        () => current,
        operationId: operation,
      );
      expect(await repository.readRebuildControl(identity), isNull);
      expect(await secrets.deleteOrphans(), 0);
    },
  );

  test(
    'full pull stages encrypted pages and publishes projections atomically',
    () async {
      await adopt(generationOne);
      final old = await edit('local offline edit', editedAt: 300);
      await repository.stageFullPull(
        identity,
        () => current,
        headRevision: 2,
        records: [_remote('server old', editedAt: 100)],
        nextCursor: 1,
        hasMore: true,
      );
      expect((await repository.state('account-a')).cursor, 0);
      expect(
        (await repository.document(old.row.documentId))!.remotePayload,
        isNull,
      );
      await expectLater(
        repository.publishFullPull(identity, () => current, headRevision: 2),
        throwsA(isA<StaleSyncIdentity>()),
      );
      await repository.stageFullPull(
        identity,
        () => current,
        headRevision: 2,
        records: [
          _remote(
            'remote second',
            revision: 2,
            recordId: '00000000-0000-4000-8000-000000000002',
          ),
        ],
        nextCursor: 2,
        hasMore: false,
      );
      await expectLater(
        repository.publishFullPull(
          identity,
          () => current,
          headRevision: 2,
          project: (_) async => throw StateError('projection failed'),
        ),
        throwsStateError,
      );
      expect((await repository.state('account-a')).cursor, 0);
      expect(
        (await repository.document(old.row.documentId))!.remotePayload,
        isNull,
      );
      expect(await db.select(db.syncPullStageEntries).get(), hasLength(2));
      final projected = <String>[];
      await repository.publishFullPull(
        identity,
        () => current,
        headRevision: 2,
        project: (d) async => projected.add(d.row.recordId),
      );
      expect(projected, hasLength(2));
      expect((await repository.state('account-a')).cursor, 2);
      expect((await repository.state('account-a')).bootstrapCompleted, isTrue);
      final retained = (await repository.document(old.row.documentId))!;
      expect(retained.localPayload!['name'], 'local offline edit');
      expect(retained.remotePayload!['name'], 'server old');
      expect(retained.row.pendingMerge, isTrue);
      expect(await db.select(db.syncPullStageEntries).get(), isEmpty);
      expect(await repository.fullPullStage('account-a'), isNull);
    },
  );

  test(
    'changed full pull head requires discarding isolated pages, not merging snapshots',
    () async {
      await adopt(generationOne);
      await repository.stageFullPull(
        identity,
        () => current,
        headRevision: 2,
        records: [_remote('obsolete page')],
        nextCursor: 1,
        hasMore: true,
      );
      await expectLater(
        repository.stageFullPull(
          identity,
          () => current,
          headRevision: 3,
          records: [_remote('new snapshot')],
          nextCursor: 1,
          hasMore: true,
        ),
        throwsA(isA<StaleSyncIdentity>()),
      );
      await repository.discardFullPull(identity, () => current);
      expect(await repository.fullPullStage('account-a'), isNull);
      expect(await db.select(db.syncPullStageEntries).get(), isEmpty);
      await repository.stageFullPull(
        identity,
        () => current,
        headRevision: 1,
        records: [_remote('fresh snapshot')],
        nextCursor: 1,
        hasMore: false,
      );
      await repository.publishFullPull(
        identity,
        () => current,
        headRevision: 1,
      );
      expect(
        (await repository.findDocument(
          'account-a',
          _recordId,
        ))!.localPayload!['name'],
        'fresh snapshot',
      );
    },
  );
  test(
    'equal retained content joins new backup while an already frozen edit waits for its result',
    () async {
      await adopt(generationOne);
      final doc = await edit('same new content', enqueue: false, editedAt: 300);
      expect(doc.row.pendingMerge, isTrue);
      await repository.stageFullPull(
        identity,
        () => current,
        headRevision: 1,
        records: [_remote('same new content', editedAt: 200)],
        nextCursor: 1,
        hasMore: false,
      );
      await repository.publishFullPull(
        identity,
        () => current,
        headRevision: 1,
      );
      final joined = (await repository.document(doc.row.documentId))!;
      expect(joined.row.pendingMerge, isFalse);
      expect(joined.row.localEditedAt, 200);
      await repository.reconcileAccount('account-a');
      expect(await send(), isEmpty);

      final editAgain = await edit(
        'same frozen content',
        documentId: doc.row.documentId,
        editedAt: 400,
      );
      final frozen = (await send()).single;
      await repository.commitPullPage(
        identity,
        () => current,
        records: [_remote('same frozen content', revision: 2, editedAt: 350)],
        nextCursor: 2,
      );
      final awaiting = (await repository.document(doc.row.documentId))!;
      expect(awaiting.row.pendingMerge, isTrue);
      expect(awaiting.dirty, isTrue);
      expect(awaiting.meta!.mutationId, editAgain.meta!.mutationId);
      expect((await send()).single.envelopeJson, frozen.envelopeJson);
    },
  );
  test(
    'deleting an account isolates active rebuild and unknown control while preserving local secrets',
    () async {
      await adopt(generationOne, backupState: 'rebuildRequired');
      final a = await edit('rebuilding local');
      await repository.setSource(
        documentId: a.row.documentId,
        origin: 'cloud',
        originAccountId: 'account-a',
      );
      final other = await edit('other account', account: 'account-b');
      final manifest = await repository.beginRebuild(
        identity,
        () => current,
        localAttempt,
      );
      identity = await repository.bindRebuildAttempt(
        manifest.identity,
        () => current,
        localAttemptId: localAttempt,
        serverAttemptId: serverAttempt,
      );
      final control = <String, Object?>{
        'operationId': operation,
        'syncGeneration': generationOne,
        'action': 'cancel',
        'expectedAttemptId': serverAttempt,
      };
      await repository.saveRebuildControl(identity, () => current, control);
      final scope = await repository.state('account-a');
      final manifestMaterial = await secrets.get(
        scope.rebuildManifestSecretId!,
      );
      final controlMaterial = await secrets.get(scope.rebuildControlSecretId!);
      final frozen = (await repository.prepareRebuildPush(
        identity,
        () => current,
      )).single;
      final oldArchives = await db.select(db.syncArchives).get();
      final entry = await db.select(db.syncRebuildEntries).getSingle();
      final frozenMaterial = await secrets.get(entry.envelopeSecretId);

      await repository.detachAccount('account-a');
      expect(await db.select(db.syncRebuildEntries).get(), isEmpty);
      expect(
        await (db.select(
          db.syncState,
        )..where((r) => r.accountId.equals('account-a'))).get(),
        isEmpty,
      );
      final local = (await repository.document(a.row.documentId))!;
      expect(local.row.accountId, isNull);
      expect(local.row.syncGeneration, isNull);
      expect(local.row.pendingMerge, isFalse);
      expect(local.localPayload!['name'], 'rebuilding local');
      expect((local.localPayload!['secrets'] as Map)['password'], _secret);
      expect((await repository.provenance(a.row.documentId))!.origin, 'cloud');
      expect(
        (await repository.document(other.row.documentId))!.row.accountId,
        'account-b',
      );
      expect((await repository.document(other.row.documentId))!.dirty, isTrue);
      final archives = await db.select(db.syncArchives).get();
      expect(archives, hasLength(oldArchives.length + 1));
      for (final old in oldArchives) {
        expect(archives.any((r) => r.id == old.id), isTrue);
      }
      expect(await secrets.deleteOrphans(), 0);
      expect(
        await secrets.get(scope.rebuildManifestSecretId!),
        manifestMaterial,
      );
      expect(await secrets.get(scope.rebuildControlSecretId!), controlMaterial);
      expect(await secrets.get(entry.envelopeSecretId), frozenMaterial);
      final newest = archives.singleWhere(
        (r) => !oldArchives.any((old) => old.id == r.id),
      );
      final archived =
          jsonDecode((await secrets.get(newest.payloadSecretId))['archive']!)
              as Map;
      expect(archived['reason'], 'account_deleted');
      expect((archived['state'] as Map)['rebuildAttemptId'], serverAttempt);
      expect(
        ((archived['rebuild'] as List).single as Map)['mutationId'],
        frozen.mutationId,
      );
      await expectLater(
        repository.commitRebuildPrefix(
          identity,
          () => current,
          sent: [frozen],
          results: [
            {
              'mutationId': frozen.mutationId,
              'status': 'applied',
              'revision': 1,
              'editedAt': 200,
            },
          ],
        ),
        throwsA(isA<StaleSyncIdentity>()),
      );
      await repository.detachAccount('account-a');
      expect(
        await db.select(db.syncArchives).get(),
        hasLength(archives.length),
      );
    },
  );

  test(
    'deleting an account archives incomplete full pull and permits a fresh scope',
    () async {
      await adopt(generationOne);
      final a = await edit('local offline', enqueue: false);
      final unknown = (await send()).singleOrNull;
      expect(unknown, isNull);
      await repository.stageFullPull(
        identity,
        () => current,
        headRevision: 2,
        records: [_remote('unpublished half')],
        nextCursor: 1,
        hasMore: true,
      );
      final stage = await db.select(db.syncPullStageEntries).getSingle();
      final stageMaterial = await secrets.get(stage.recordSecretId);
      await repository.detachAccount('account-a');
      expect(await db.select(db.syncPullStageEntries).get(), isEmpty);
      expect(await db.select(db.syncPullStages).get(), isEmpty);
      expect(await secrets.deleteOrphans(), 0);
      expect(await secrets.get(stage.recordSecretId), stageMaterial);
      final local = (await repository.document(a.row.documentId))!;
      expect(local.row.syncGeneration, isNull);
      expect(local.row.pendingMerge, isFalse);
      expect(local.localPayload!['name'], 'local offline');
      expect(local.remotePayload, isNull);
      final archives = await db.select(db.syncArchives).get();
      final archived =
          jsonDecode(
                (await secrets.get(
                  archives.single.payloadSecretId,
                ))['archive']!,
              )
              as Map;
      expect((archived['pull'] as Map)['cursor'], 1);
      expect((archived['pull'] as Map)['headRevision'], 2);
      expect((archived['pullEntries'] as List), hasLength(1));

      await sessions.save(_session('account-c', 'session-c'));
      identity = (await repository.capture(2))!;
      identity = await repository.adoptGeneration(
        identity,
        () => current,
        generationTwo,
      );
      await repository.stageFullPull(
        identity,
        () => current,
        headRevision: 0,
        records: [],
        nextCursor: 0,
        hasMore: false,
      );
      await repository.publishFullPull(
        identity,
        () => current,
        headRevision: 0,
      );
      expect((await repository.state('account-c')).bootstrapCompleted, isTrue);
      expect(
        (await repository.document(a.row.documentId))!.row.accountId,
        isNull,
      );
      expect(await send(), isEmpty);
    },
  );

  test(
    'account deletion rollback keeps original scope and encrypted staging owners',
    () async {
      await adopt(generationOne);
      final a = await edit('preserved local', enqueue: false);
      await repository.stageFullPull(
        identity,
        () => current,
        headRevision: 2,
        records: [_remote('retained stage')],
        nextCursor: 1,
        hasMore: true,
      );
      final before = await repository.state('account-a');
      final archiveCount = (await db.select(db.syncArchives).get()).length;
      final secretCount = (await db.select(db.secrets).get()).length;
      await db.customStatement(
        'CREATE TRIGGER fail_detach BEFORE DELETE ON sync_pull_stages '
        "BEGIN SELECT RAISE(ABORT, 'injected detach failure'); END",
      );
      await expectLater(repository.detachAccount('account-a'), throwsException);
      expect(
        (await repository.document(a.row.documentId))!.row.accountId,
        'account-a',
      );
      expect(
        (await repository.document(a.row.documentId))!.row.syncGeneration,
        generationOne,
      );
      expect(await repository.state('account-a'), before);
      expect(await db.select(db.syncPullStageEntries).get(), hasLength(1));
      expect(await db.select(db.syncPullStages).get(), hasLength(1));
      expect(await db.select(db.syncArchives).get(), hasLength(archiveCount));
      expect(await db.select(db.secrets).get(), hasLength(secretCount));
      expect(await secrets.deleteOrphans(), 0);
      await db.customStatement('DROP TRIGGER fail_detach');
      await repository.detachAccount('account-a');
      expect(await db.select(db.syncPullStages).get(), isEmpty);
    },
  );
}
