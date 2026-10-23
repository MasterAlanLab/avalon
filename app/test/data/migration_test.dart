// Every older schema upgrades to the current one (DATA_MODEL §5): the
// result has exactly the tables, columns and indexes of a database created
// new, and the user's data is still there. Fixtures are real databases
// written by tool/make_schema_fixture.dart while each version was current.
import 'dart:io';

import 'package:avalon/data/database/database.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// The schema as SQLite describes it: name and statement of every table,
/// index and trigger.
Future<Map<String, String>> _schema(AppDatabase db) async {
  final rows = await db
      .customSelect(
        "SELECT name, sql FROM sqlite_master WHERE sql IS NOT NULL "
        "AND name NOT LIKE 'sqlite_%' ORDER BY name",
      )
      .get();
  return {
    for (final r in rows)
      r.read<String>('name'): r
          .read<String>('sql')
          .replaceAll(RegExp(r'\s+'), ' '),
  };
}

Future<int> _count(AppDatabase db, String table) async =>
    (await db.customSelect('SELECT COUNT(*) AS n FROM $table').getSingle())
        .read<int>('n');

/// Read-only raw SQL probe after a failed upgrade; do not rerun that upgrade.
final class _SchemaTwoProbe extends AppDatabase {
  _SchemaTwoProbe(super.e);

  @override
  int get schemaVersion => 2;
}

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('migration'));
  tearDown(() => dir.deleteSync(recursive: true));

  Future<AppDatabase> fromFixture(int version) async {
    final copy = File('${dir.path}/v$version.sqlite');
    File('test/data/schemas/v$version.sqlite').copySync(copy.path);
    return AppDatabase(NativeDatabase(copy));
  }

  test('every older schema has a fixture', () {
    final current = AppDatabase(NativeDatabase.memory());
    addTearDown(current.close);
    for (var v = 1; v < current.schemaVersion; v++) {
      expect(
        File('test/data/schemas/v$v.sqlite').existsSync(),
        isTrue,
        reason: 'write v$v.sqlite before raising the schema past it',
      );
    }
  });

  for (final fixtureVersion in [1, 2, 3]) {
    test(
      'v$fixtureVersion upgrades to the current schema and keeps the data',
      () async {
        final upgraded = await fromFixture(fixtureVersion);
        final fresh = AppDatabase(NativeDatabase.memory());
        addTearDown(upgraded.close);
        addTearDown(fresh.close);

        expect(await _schema(upgraded), await _schema(fresh));
        final version = await upgraded
            .customSelect('PRAGMA user_version')
            .getSingle();
        expect(version.data.values.single, fresh.schemaVersion);

        // One of everything the fixture holds.
        expect(await _count(upgraded, 'configurations'), 2); // 自建节点 + one
        expect(await _count(upgraded, 'contents'), 1);
        expect(await _count(upgraded, 'self_nodes'), 1);
        expect(await _count(upgraded, 'chains'), 1);
        expect(await _count(upgraded, 'selections'), 1);
        // v3 also captures the five canonical business documents encrypted.
        expect(await _count(upgraded, 'secrets'), fixtureVersion == 3 ? 10 : 5);
        final settings = await upgraded
            .select(upgraded.deviceSettingsTable)
            .getSingle();
        expect(settings.json, contains('"mixedPort":7891'));
        final policy = await upgraded.select(upgraded.policyTable).getSingle();
        expect(policy.geoInterval, 'weekly');
        expect(policy.overrideSecretId, isNotNull);
        // The rule-resource cache starts empty (D86).
        expect(await _count(upgraded, 'rule_resources'), 0);

        // And the upgraded database takes the new columns.
        await upgraded
            .into(upgraded.ruleResources)
            .insert(
              RuleResourcesCompanion.insert(
                url: 'https://example.com/a.srs',
                format: 'binary',
                file: const Value('abc.srs'),
              ),
            );
        expect(await _count(upgraded, 'rule_resources'), 1);
      },
    );
  }

  test(
    'v2 migration keeps legacy dirty edits, cursors and encrypted session owners',
    () async {
      final copy = File('${dir.path}/legacy-sync.sqlite');
      File('test/data/schemas/v2.sqlite').copySync(copy.path);
      final upgraded = AppDatabase(
        NativeDatabase(
          copy,
          setup: (raw) {
            final config =
                raw
                        .select(
                          "SELECT id FROM configurations WHERE kind = 'subscription'",
                        )
                        .single['id']
                    as String;
            final node =
                raw.select('SELECT id FROM self_nodes').single['id'] as String;
            final secret =
                raw.select('SELECT id FROM secrets LIMIT 1').single['id']
                    as String;
            raw.execute(
              'UPDATE configurations SET cloud_account_id = ? WHERE id = ?',
              ['account-a', config],
            );
            raw.execute(
              'INSERT INTO sync_meta(record_id,type,account_id,remote_revision,dirty,deleted,edited_at,mutation_id) VALUES(?,?,?,?,?,?,?,?)',
              [
                config,
                'configuration',
                'account-a',
                7,
                1,
                0,
                123,
                'legacy-mutation',
              ],
            );
            raw.execute(
              'INSERT INTO sync_meta(record_id,type,account_id,remote_revision,dirty,deleted,edited_at,mutation_id) VALUES(?,?,?,?,?,?,?,?)',
              [node, 'node', 'account-b', 9, 1, 1, 124, 'legacy-deletion'],
            );
            raw.execute(
              'INSERT INTO sync_state(account_id,cursor,last_sync_at,blocked_reason) VALUES(?,?,?,?)',
              ['account-a', 42, 100, 'SYNC_NOT_ACTIVE'],
            );
            raw.execute(
              'INSERT INTO sync_state(account_id,cursor,last_sync_at,blocked_reason) VALUES(?,?,?,?)',
              ['account-b', 99, 200, null],
            );
            raw.execute(
              'INSERT OR REPLACE INTO cloud_session(id,account_id,email,display_name,device_id,installation_id,access_secret_id,refresh_secret_id,entitlement_json,logged_in,updated_at) VALUES(?,?,?,?,?,?,?,?,?,?,?)',
              [
                1,
                'account-a',
                'test@example.com',
                'fixture',
                'device',
                'installation',
                secret,
                secret,
                '{}',
                1,
                100,
              ],
            );
          },
        ),
      );
      addTearDown(upgraded.close);
      final metas = await upgraded.select(upgraded.syncMeta).get();
      expect(metas, hasLength(2));
      for (final meta in metas) {
        final document = await (upgraded.select(
          upgraded.syncDocuments,
        )..where((r) => r.documentId.equals(meta.documentId))).getSingle();
        expect(document.accountId, meta.accountId);
        expect(document.recordId, meta.recordId);
        expect(document.localId, meta.recordId);
        expect(document.localEditedAt, meta.editedAt);
        expect(document.localDeleted, meta.deleted);
        expect(meta.dirty, isTrue);
        expect(meta.mutationId, startsWith('legacy-'));
      }
      final states = await upgraded.select(upgraded.syncState).get();
      expect(states.map((s) => s.cursor).toSet(), {42, 99});
      expect(states.every((s) => !s.bootstrapCompleted), isTrue);
      final session = await upgraded.select(upgraded.cloudSession).getSingle();
      expect(session.accountId, 'account-a');
      expect(session.loggedIn, isTrue);
      expect(session.accessSecretId, session.refreshSecretId);
      expect(await _count(upgraded, 'secrets'), 5);
      // The new account-composite key accepts another account's same wire UUID.
      final first = metas.first;
      await upgraded
          .into(upgraded.syncMeta)
          .insert(
            SyncMetaCompanion.insert(
              recordId: first.recordId,
              type: first.type,
              accountId: 'account-c',
              documentId: 'isolated-owner',
              dirty: false,
              deleted: false,
              editedAt: 1,
            ),
          );
      expect(await _count(upgraded, 'sync_meta'), 3);
    },
  );

  test(
    'failed v3 migration rolls back every table and existing content',
    () async {
      final copy = File('${dir.path}/rollback.sqlite');
      File('test/data/schemas/v2.sqlite').copySync(copy.path);
      final failing = AppDatabase(
        NativeDatabase(
          copy,
          setup: (raw) {
            raw.execute(
              "CREATE TRIGGER fail_v3 BEFORE UPDATE ON selections BEGIN SELECT RAISE(ABORT, 'injected migration failure'); END",
            );
          },
        ),
      );
      await expectLater(
        failing.customSelect('SELECT 1').get(),
        throwsA(isA<Exception>()),
      );
      await failing.close();
      final probe = _SchemaTwoProbe(NativeDatabase(copy));
      addTearDown(probe.close);
      final version = await probe
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(version.data.values.single, 2);
      final schema = await _schema(probe);
      expect(schema.containsKey('sync_documents'), isFalse);
      expect(schema.containsKey('source_provenance'), isFalse);
      expect(schema['selections'], isNot(contains('document_id')));
      expect(schema['sync_meta'], isNot(contains('document_id')));
      expect(schema['sync_state'], isNot(contains('bootstrap_completed')));
      expect(await _count(probe, 'configurations'), 2);
      expect(await _count(probe, 'contents'), 1);
      expect(await _count(probe, 'self_nodes'), 1);
      expect(await _count(probe, 'secrets'), 5);
    },
  );
  test(
    'v3 preserves unknown envelopes and cursors without guessing a generation',
    () async {
      final copy = File('${dir.path}/legacy-v3.sqlite');
      File('test/data/schemas/v3.sqlite').copySync(copy.path);
      List<int>? originalCiphertext;
      String? secretId;
      final upgraded = AppDatabase(
        NativeDatabase(
          copy,
          setup: (raw) {
            final secret = raw
                .select('SELECT id,ciphertext FROM secrets LIMIT 1')
                .single;
            secretId = secret['id'] as String;
            originalCiphertext = List<int>.from(
              secret['ciphertext'] as List<int>,
            );
            raw.execute(
              'INSERT INTO sync_documents(document_id,account_id,record_id,type,'
              'local_id,remote_revision,remote_edited_at,remote_deleted,remote_schema_version,'
              'remote_payload_secret_id,local_payload_secret_id,local_edited_at,local_deleted) '
              'VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?)',
              [
                'legacy-document',
                'account-v3',
                '00000000-0000-4000-8000-000000000001',
                'node',
                'local-node',
                7,
                100,
                0,
                1,
                secretId,
                secretId,
                200,
                0,
              ],
            );
            raw.execute(
              'INSERT INTO sync_meta(record_id,type,account_id,document_id,'
              'remote_revision,dirty,deleted,edited_at,mutation_id,pending_envelope_secret_id,'
              'in_flight_mutation_id,in_flight_envelope_secret_id) VALUES(?,?,?,?,?,?,?,?,?,?,?,?)',
              [
                '00000000-0000-4000-8000-000000000001',
                'node',
                'account-v3',
                'legacy-document',
                7,
                1,
                0,
                200,
                'pending-mutation',
                secretId,
                'unknown-mutation',
                secretId,
              ],
            );
            raw.execute(
              'INSERT INTO sync_state(account_id,cursor,last_sync_at,bootstrap_completed) '
              'VALUES(?,?,?,?)',
              ['account-v3', 42, 123, 1],
            );
          },
        ),
      );
      addTearDown(upgraded.close);
      final state = await upgraded.select(upgraded.syncState).getSingle();
      expect(state.cursor, 42);
      expect(state.bootstrapCompleted, isTrue);
      expect(state.syncGeneration, isNull);
      expect(state.backupState, 'legacy');
      final meta = await upgraded.select(upgraded.syncMeta).getSingle();
      expect(meta.inFlightMutationId, 'unknown-mutation');
      expect(meta.mutationId, 'pending-mutation');
      expect(meta.pendingEnvelopeSecretId, secretId);
      expect(meta.inFlightEnvelopeSecretId, secretId);
      expect(meta.syncGeneration, isNull);
      final document = await (upgraded.select(
        upgraded.syncDocuments,
      )..where((r) => r.documentId.equals('legacy-document'))).getSingle();
      expect(document.localId, 'local-node');
      expect(document.localEditedAt, 200);
      expect(document.remoteRevision, 7);
      expect(document.pendingMerge, isFalse);
      final encrypted = await (upgraded.select(
        upgraded.secrets,
      )..where((r) => r.id.equals(secretId!))).getSingle();
      expect(encrypted.ciphertext, originalCiphertext);
      expect(await _count(upgraded, 'sync_archives'), 0);
      expect(await _count(upgraded, 'sync_rebuild_entries'), 0);
      expect(await _count(upgraded, 'sync_pull_stages'), 0);
    },
  );
}
