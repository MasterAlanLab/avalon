import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../cloud/sync_models.dart' show syncSelectionId;
import '../ids.dart';
import 'tables.dart';

part 'database.g.dart';

/// The one application database (D47): content, secrets and settings
/// commit together. Opened through a shared background isolate so a
/// headless engine (D75) sees the same streams.
@DriftDatabase(
  tables: [
    Configurations,
    Contents,
    SelfNodes,
    Chains,
    Memberships,
    Selections,
    DeviceSettingsTable,
    PolicyTable,
    RuleResources,
    Secrets,
    CloudSession,
    SyncMeta,
    SyncDocuments,
    SourceProvenance,
    SyncState,
    SyncArchives,
    SyncArchiveReferences,
    SyncRebuildEntries,
    SyncPullStages,
    SyncPullStageEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// The on-device database, shared across isolates and engines.
  factory AppDatabase.open() => AppDatabase(
    driftDatabase(
      name: 'avalon',
      native: const DriftNativeOptions(shareAcrossIsolates: true),
    ),
  );

  /// Fixed id of the built-in 「自建节点」 configuration.
  static const selfConfigurationId = 'self';

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      await into(configurations).insert(
        ConfigurationsCompanion.insert(
          id: selfConfigurationId,
          kind: 'self',
          name: '自建节点',
          autoUpdate: const Value(false),
          createdAt: now,
          editedAt: now,
        ),
      );
    },
    onUpgrade: (m, from, to) async {
      // A database from a newer app version is never read or written
      // (DATA_MODEL §5); the caller shows 「请更新 Avalon」. Throwing here
      // rolls the open back before anything changes.
      if (from > to) throw DatabaseTooNewException(from);
      // Each schema step goes here, with a test from every older version
      // (test/data/migration_test.dart).
      await customStatement('PRAGMA foreign_keys = OFF');
      // Drift does not wrap onUpgrade as a whole: individual table rebuilds
      // alone cannot roll back an earlier outbox/table change on later failure.
      await transaction(() async {
        if (from < 2) {
          // Rule resources became a pure download cache known by address and
          // format (D86). Nothing in it needs keeping: files download again.
          await m.deleteTable('rule_resources');
          await m.createTable(ruleResources);
        }
        if (from < 3) {
          // Rebuild the old single-record key without losing account state.
          // Payload hydration needs the OS vault and is completed by the data
          // layer; migrations never persist decrypted business JSON.
          final legacy = await customSelect('SELECT * FROM sync_meta').get();
          await m.createTable(syncDocuments);
          await m.createTable(sourceProvenance);
          await m.deleteTable('sync_meta');
          await m.createTable(syncMeta);
          for (final old in legacy) {
            final documentId = newId();
            final recordId = old.read<String>('record_id');
            final type = old.read<String>('type');
            final accountId = old.read<String>('account_id');
            final editedAt = old.read<int>('edited_at');
            final deleted = old.read<int>('deleted') != 0;
            await into(syncDocuments).insert(
              SyncDocumentsCompanion.insert(
                documentId: documentId,
                accountId: Value(accountId),
                recordId: recordId,
                type: type,
                localId: Value(
                  type == 'configuration' || type == 'node' || type == 'chain'
                      ? recordId
                      : null,
                ),
                remoteRevision: Value(old.readNullable<int>('remote_revision')),
                localEditedAt: editedAt,
                localDeleted: deleted,
              ),
            );
            await into(syncMeta).insert(
              SyncMetaCompanion.insert(
                documentId: documentId,
                recordId: recordId,
                type: type,
                accountId: accountId,
                remoteRevision: Value(old.readNullable<int>('remote_revision')),
                dirty: old.read<int>('dirty') != 0,
                deleted: deleted,
                editedAt: editedAt,
                mutationId: Value(old.readNullable<String>('mutation_id')),
              ),
            );
          }
          await m.alterTable(
            TableMigration(policyTable, newColumns: [policyTable.documentId]),
          );
          await m.alterTable(
            TableMigration(selections, newColumns: [selections.documentId]),
          );
          await m.alterTable(
            TableMigration(
              syncState,
              newColumns: [
                syncState.bootstrapCompleted,
                syncState.syncGeneration,
                syncState.backupState,
                syncState.rebuildAttemptId,
                syncState.rebuildLocalAttemptId,
                syncState.rebuildManifestSecretId,
                syncState.rebuildControlSecretId,
              ],
            ),
          );
          await _migrateCanonicalOwners();
        }
        if (from < 4) {
          // Legacy cursors and unknown results stay untouched. Binding their
          // generation requires the server's explicit compatibility guarantee;
          // opening a database must neither decrypt nor invent offline edits.
          // The v3 step above already creates/rebuilds these tables with the
          // current columns. Alter only a database that actually started at v3.
          if (from >= 3) {
            await m.alterTable(
              TableMigration(syncMeta, newColumns: [syncMeta.syncGeneration]),
            );
            await m.alterTable(
              TableMigration(
                syncDocuments,
                newColumns: [
                  syncDocuments.syncGeneration,
                  syncDocuments.pendingMerge,
                ],
              ),
            );
            await m.alterTable(
              TableMigration(
                syncState,
                newColumns: [
                  syncState.syncGeneration,
                  syncState.backupState,
                  syncState.rebuildAttemptId,
                  syncState.rebuildLocalAttemptId,
                  syncState.rebuildManifestSecretId,
                  syncState.rebuildControlSecretId,
                ],
              ),
            );
          }
          await m.createTable(syncArchives);
          await m.createTable(syncArchiveReferences);
          await m.createTable(syncRebuildEntries);
          await m.createTable(syncPullStages);
          await m.createTable(syncPullStageEntries);
        }
        final violations = await customSelect('PRAGMA foreign_key_check').get();
        if (violations.isNotEmpty) {
          throw StateError('migration foreign key check');
        }
        // The schema and user_version have one durable commit. Drift sets the
        // same version after onUpgrade; a crash between those steps must not
        // leave v3 tables labelled v2 and attempt their rebuild a second time.
        await customStatement('PRAGMA user_version = $to');
      });
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Preserve ownership before the vault-backed encoder hydrates payloads.
  /// This prevents retained A singletons or ordinary rows from binding to B.
  Future<void> _migrateCanonicalOwners() async {
    Future<String> owner({
      required String type,
      required String recordId,
      required String localId,
      required int editedAt,
      String? accountId,
    }) async {
      final existing =
          await (select(syncDocuments)..where(
                (d) =>
                    d.type.equals(type) &
                    d.recordId.equals(recordId) &
                    (accountId == null
                        ? d.accountId.isNull()
                        : d.accountId.equals(accountId)),
              ))
              .getSingleOrNull();
      final id = existing?.documentId ?? newId();
      if (existing == null) {
        await into(syncDocuments).insert(
          SyncDocumentsCompanion.insert(
            documentId: id,
            accountId: Value(accountId),
            recordId: recordId,
            type: type,
            localId: Value(localId),
            localEditedAt: editedAt,
            localDeleted: false,
          ),
        );
      } else {
        await (update(syncDocuments)..where((d) => d.documentId.equals(id)))
            .write(SyncDocumentsCompanion(localId: Value(localId)));
      }
      if (type != 'selection') {
        await into(sourceProvenance).insert(
          SourceProvenanceCompanion.insert(
            documentId: id,
            origin: accountId == null ? 'local_user' : 'cloud',
            originAccountId: Value(accountId),
            sourceGeneration: newId(),
          ),
          mode: InsertMode.insertOrIgnore,
        );
      }
      return id;
    }

    for (final row in await select(configurations).get()) {
      if (row.kind == 'self') continue;
      await owner(
        type: 'configuration',
        recordId: row.id,
        localId: row.id,
        editedAt: row.editedAt,
        accountId: row.cloudAccountId,
      );
    }
    for (final row in await select(selfNodes).get()) {
      await owner(
        type: 'node',
        recordId: row.id,
        localId: row.id,
        editedAt: row.editedAt,
        accountId: row.cloudAccountId,
      );
    }
    for (final row in await select(chains).get()) {
      await owner(
        type: 'chain',
        recordId: row.id,
        localId: row.id,
        editedAt: row.editedAt,
        accountId: row.cloudAccountId,
      );
    }
    for (final row in await select(policyTable).get()) {
      if (row.editedAt == null) continue;
      final id = await owner(
        type: 'policy',
        recordId: 'policy',
        localId: 'policy',
        editedAt: row.editedAt!,
        accountId: row.cloudAccountId,
      );
      await (update(policyTable)..where((r) => r.id.equals(row.id))).write(
        PolicyTableCompanion(documentId: Value(id)),
      );
    }
    for (final row in await select(selections).get()) {
      if (!row.manual) continue;
      final id = await owner(
        type: 'selection',
        recordId: syncSelectionId(row.configurationId, row.groupKey),
        localId: jsonEncode([row.configurationId, row.groupKey]),
        editedAt: row.editedAt,
        accountId: row.cloudAccountId,
      );
      await (update(selections)..where(
            (r) =>
                r.configurationId.equals(row.configurationId) &
                r.groupKey.equals(row.groupKey),
          ))
          .write(SelectionsCompanion(documentId: Value(id)));
    }
  }
}

final class DatabaseTooNewException implements Exception {
  const DatabaseTooNewException(this.version);

  final int version;
}
