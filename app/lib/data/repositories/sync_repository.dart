import 'dart:convert';

import 'package:drift/drift.dart';

import '../../cloud/sync_json.dart';
import '../database/database.dart';
import '../ids.dart';
import '../vault/secret_store.dart';
import '../vault/vault.dart';

/// Captured before HTTP; rechecked in the transaction applying its result.
final class SyncIdentity {
  const SyncIdentity(
    this.accountId,
    this.sessionId,
    this.workerEpoch, {
    this.syncGeneration,
    this.rebuildAttemptId,
    this.rebuildLocalAttemptId,
  });

  final String accountId;
  final String sessionId;
  final int workerEpoch;
  final String? syncGeneration;
  final String? rebuildAttemptId;
  final String? rebuildLocalAttemptId;
}

final class StaleSyncIdentity implements Exception {
  const StaleSyncIdentity();
}

final class SyncLegacyScopeUnverified implements Exception {
  const SyncLegacyScopeUnverified();
}

final class SyncRebuildIncomplete implements Exception {
  const SyncRebuildIncomplete();
}

/// Local frozen input exists before the server grants the attempt. The wire
/// manifest contains only record identities, types and immutable mutation IDs.
final class StoredSyncRebuildManifest {
  StoredSyncRebuildManifest({
    required this.identity,
    required this.localAttemptId,
    required List<Map<String, Object?>> entries,
  }) : entries = List.unmodifiable([
         for (final entry in entries) Map<String, Object?>.unmodifiable(entry),
       ]);

  final SyncIdentity identity;
  final String localAttemptId;
  final List<Map<String, Object?>> entries;
  String get manifestId => localAttemptId;
  Map<String, Object?> toJson() => {
    'manifestId': manifestId,
    'entries': entries,
  };
}

/// Decrypted only in memory. Neither payload nor envelope is diagnostic data.
final class SyncDocumentSnapshot {
  const SyncDocumentSnapshot({
    required this.row,
    required this.localPayload,
    required this.remotePayload,
    this.meta,
  });

  final SyncDocumentRow row;
  final Map<String, Object?>? localPayload;
  final Map<String, Object?>? remotePayload;
  final SyncMetaRow? meta;

  bool get dirty => meta?.dirty ?? false;

  Map<String, Object?> get localRecord => {
    'recordId': row.recordId,
    'type': row.type,
    'editedAt': row.localEditedAt,
    'deleted': row.localDeleted,
    'schemaVersion': row.localSchemaVersion,
    'payload': localPayload,
  };

  Map<String, Object?>? get remoteRecord => row.remoteEditedAt == null
      ? null
      : {
          'recordId': row.recordId,
          'type': row.type,
          'revision': row.remoteRevision,
          'editedAt': row.remoteEditedAt,
          'deleted': row.remoteDeleted,
          'schemaVersion': row.remoteSchemaVersion,
          'payload': remotePayload,
        };

  @override
  String toString() => 'SyncDocumentSnapshot(${row.documentId}, ${row.type})';
}

final class FrozenSyncMutation {
  FrozenSyncMutation({
    required this.documentId,
    required this.envelopeJson,
    required Map<String, Object?> envelope,
    this.uploadAllowed = true,
    this.syncGeneration,
    this.rebuildAttemptId,
  }) : envelope = immutableSyncJson(envelope) as Map<String, Object?>;

  final String documentId;
  final String envelopeJson;
  final Map<String, Object?> envelope;
  final bool uploadAllowed;
  final String? syncGeneration;
  final String? rebuildAttemptId;

  String get mutationId => envelope['mutationId'] as String;
  String get recordId => envelope['recordId'] as String;

  @override
  String toString() => 'FrozenSyncMutation($mutationId)';
}

/// Transactional canonical storage and two-slot outbox. HTTP and business
/// projection live outside this class; projection callbacks run in its owning
/// transaction, so mirrors, business rows and cursors roll back together.
final class SyncRepository {
  SyncRepository(this.db, this.secrets);

  final AppDatabase db;
  final SecretStore secrets;

  Future<SyncIdentity?> capture(int workerEpoch) => db.transaction(() async {
    final row = await (db.select(
      db.cloudSession,
    )..where((r) => r.id.equals(1))).getSingleOrNull();
    if (row == null || !row.loggedIn) return null;
    final access = await secrets.get(row.accessSecretId);
    final sessionId = access['sessionId'];
    if (sessionId == null) return null;
    final scope = await (db.select(
      db.syncState,
    )..where((r) => r.accountId.equals(row.accountId))).getSingleOrNull();
    return SyncIdentity(
      row.accountId,
      sessionId,
      workerEpoch,
      syncGeneration: scope?.syncGeneration,
      rebuildAttemptId: scope?.rebuildAttemptId,
      rebuildLocalAttemptId: scope?.rebuildLocalAttemptId,
    );
  });

  Future<void> _guard(SyncIdentity identity, bool Function() isCurrent) async {
    if (!isCurrent()) throw const StaleSyncIdentity();
    final row = await (db.select(
      db.cloudSession,
    )..where((r) => r.id.equals(1))).getSingleOrNull();
    if (row == null || !row.loggedIn || row.accountId != identity.accountId) {
      throw const StaleSyncIdentity();
    }
    final access = await secrets.get(row.accessSecretId);
    if (access['sessionId'] != identity.sessionId || !isCurrent()) {
      throw const StaleSyncIdentity();
    }
    final scope = await (db.select(
      db.syncState,
    )..where((r) => r.accountId.equals(identity.accountId))).getSingleOrNull();
    if (scope?.syncGeneration != identity.syncGeneration ||
        scope?.rebuildAttemptId != identity.rebuildAttemptId ||
        scope?.rebuildLocalAttemptId != identity.rebuildLocalAttemptId) {
      throw const StaleSyncIdentity();
    }
  }

  Future<SyncDocumentRow?> _row(String documentId) => (db.select(
    db.syncDocuments,
  )..where((r) => r.documentId.equals(documentId))).getSingleOrNull();

  Future<SyncMetaRow?> _meta(String accountId, String recordId) =>
      (db.select(db.syncMeta)..where(
            (r) => r.accountId.equals(accountId) & r.recordId.equals(recordId),
          ))
          .getSingleOrNull();

  Future<Map<String, Object?>?> _payload(String? secretId) async {
    if (secretId == null) return null;
    final entry = await secrets.get(secretId);
    return immutableSyncJson(jsonDecode(entry['payload']!))
        as Map<String, Object?>;
  }

  Future<SyncDocumentSnapshot> _snapshot(SyncDocumentRow row) async =>
      SyncDocumentSnapshot(
        row: row,
        localPayload: await _payload(row.localPayloadSecretId),
        remotePayload: await _payload(row.remotePayloadSecretId),
        meta: row.accountId == null
            ? null
            : await _meta(row.accountId!, row.recordId),
      );

  Future<SyncDocumentSnapshot?> document(String documentId) async {
    final row = await _row(documentId);
    return row == null ? null : _snapshot(row);
  }

  Future<SyncDocumentSnapshot?> findDocument(
    String accountId,
    String recordId,
  ) async {
    final row =
        await (db.select(db.syncDocuments)..where(
              (r) =>
                  r.accountId.equals(accountId) & r.recordId.equals(recordId),
            ))
            .getSingleOrNull();
    return row == null ? null : _snapshot(row);
  }

  Future<SyncDocumentSnapshot?> findLocalDocument(
    String type,
    String localId, {
    String? accountId,
  }) async {
    final rows =
        await (db.select(db.syncDocuments)..where(
              (r) =>
                  r.type.equals(type) &
                  r.localId.equals(localId) &
                  (accountId == null
                      ? const Constant(true)
                      : r.accountId.equals(accountId)),
            ))
            .get();
    if (rows.length > 1) throw StateError('ambiguous sync owner');
    return rows.isEmpty ? null : _snapshot(rows.single);
  }

  Future<List<SyncDocumentSnapshot>> documents({
    String? accountId,
    bool unbound = false,
  }) async {
    final query = db.select(db.syncDocuments);
    if (unbound) {
      query.where((r) => r.accountId.isNull());
    } else if (accountId != null) {
      query.where((r) => r.accountId.equals(accountId));
    }
    query.orderBy([(r) => OrderingTerm.asc(r.recordId)]);
    final result = <SyncDocumentSnapshot>[];
    for (final row in await query.get()) {
      result.add(await _snapshot(row));
    }
    return result;
  }

  Future<SyncStateRow> state(String accountId) async {
    await db
        .into(db.syncState)
        .insert(
          SyncStateCompanion.insert(accountId: accountId, cursor: 0),
          mode: InsertMode.insertOrIgnore,
        );
    return (db.select(
      db.syncState,
    )..where((r) => r.accountId.equals(accountId))).getSingle();
  }

  Stream<SyncStateRow?> watchState(String accountId) => (db.select(
    db.syncState,
  )..where((r) => r.accountId.equals(accountId))).watchSingleOrNull();

  SyncIdentity _scopedIdentity(SyncIdentity old, SyncStateRow scope) =>
      SyncIdentity(
        old.accountId,
        old.sessionId,
        old.workerEpoch,
        syncGeneration: scope.syncGeneration,
        rebuildAttemptId: scope.rebuildAttemptId,
        rebuildLocalAttemptId: scope.rebuildLocalAttemptId,
      );

  void _checkUuid(String value) {
    if (!RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    ).hasMatch(value)) {
      throw const SyncValidationException();
    }
  }

  void _checkFrozenScope(
    Map<String, String> sealed,
    SyncIdentity identity, {
    bool rebuilding = false,
  }) {
    if ((sealed['syncGeneration'] ?? '') != (identity.syncGeneration ?? '') ||
        (sealed['rebuildAttemptId'] ?? '') !=
            (rebuilding ? identity.rebuildAttemptId ?? '' : '') ||
        (rebuilding &&
            sealed['localAttemptId'] != identity.rebuildLocalAttemptId)) {
      throw const StaleSyncIdentity();
    }
  }

  /// The archive owns the original entry IDs, including unknown HTTP results.
  /// It never decrypts those entries or changes their frozen request body.
  Future<void> _archiveScope(String accountId, String reason) async {
    final scope = await state(accountId);
    final docs = await (db.select(
      db.syncDocuments,
    )..where((r) => r.accountId.equals(accountId))).get();
    final metas = await (db.select(
      db.syncMeta,
    )..where((r) => r.accountId.equals(accountId))).get();
    final rebuilding = await (db.select(
      db.syncRebuildEntries,
    )..where((r) => r.accountId.equals(accountId))).get();
    final pulling = await (db.select(
      db.syncPullStageEntries,
    )..where((r) => r.accountId.equals(accountId))).get();
    final pull = await fullPullStage(accountId);
    final references = <String>{
      if (scope.rebuildManifestSecretId != null) scope.rebuildManifestSecretId!,
      if (scope.rebuildControlSecretId != null) scope.rebuildControlSecretId!,
      for (final d in docs) ...[
        if (d.localPayloadSecretId != null) d.localPayloadSecretId!,
        if (d.remotePayloadSecretId != null) d.remotePayloadSecretId!,
      ],
      for (final m in metas) ...[
        if (m.pendingEnvelopeSecretId != null) m.pendingEnvelopeSecretId!,
        if (m.inFlightEnvelopeSecretId != null) m.inFlightEnvelopeSecretId!,
      ],
      for (final e in rebuilding) e.envelopeSecretId,
      for (final e in pulling) e.recordSecretId,
    };
    final id = newId();
    final payload = await secrets.put({
      'archive': canonicalSyncJson({
        'version': 1,
        'reason': reason,
        'state': scope.toJson(),
        'documents': [for (final d in docs) d.toJson()],
        'outbox': [for (final m in metas) m.toJson()],
        'rebuild': [for (final e in rebuilding) e.toJson()],
        'pull': pull?.toJson(),
        'pullEntries': [for (final e in pulling) e.toJson()],
      }),
    });
    await db
        .into(db.syncArchives)
        .insert(
          SyncArchivesCompanion.insert(
            id: id,
            accountId: accountId,
            syncGeneration: Value(scope.syncGeneration),
            payloadSecretId: payload,
            createdAt: nowMs(),
          ),
        );
    for (final secret in references) {
      await db
          .into(db.syncArchiveReferences)
          .insert(
            SyncArchiveReferencesCompanion.insert(
              archiveId: id,
              secretId: secret,
            ),
          );
    }
  }

  /// A null legacy generation is not evidence of a cleared Cloud dataset.
  /// The server must guarantee its unchanged migration before old cursors and
  /// unknown mutations can be bound to the first explicit generation.
  Future<SyncIdentity> adoptGeneration(
    SyncIdentity identity,
    bool Function() isCurrent,
    String syncGeneration, {
    String backupState = 'ready',
    bool preserveLegacyHistory = false,
    bool retireLegacyHistory = false,
  }) => db.transaction(() async {
    _checkUuid(syncGeneration);
    if (preserveLegacyHistory && retireLegacyHistory) {
      throw const SyncValidationException();
    }
    if (!{'rebuildRequired', 'rebuilding', 'ready'}.contains(backupState)) {
      throw const SyncValidationException();
    }
    await _guard(identity, isCurrent);
    final before = await state(identity.accountId);
    final docs = await (db.select(
      db.syncDocuments,
    )..where((r) => r.accountId.equals(identity.accountId))).get();
    final metas = await (db.select(
      db.syncMeta,
    )..where((r) => r.accountId.equals(identity.accountId))).get();
    if (before.syncGeneration == syncGeneration) {
      await (db.update(db.syncState)
            ..where((r) => r.accountId.equals(identity.accountId)))
          .write(SyncStateCompanion(backupState: Value(backupState)));
    } else if (before.syncGeneration == null && !retireLegacyHistory) {
      final history =
          before.cursor != 0 ||
          metas.isNotEmpty ||
          docs.any((d) => d.remoteRevision != null);
      if (history && !preserveLegacyHistory) {
        throw const SyncLegacyScopeUnverified();
      }
      if (history) {
        await _archiveScope(identity.accountId, 'legacy_scope_binding');
      }
      // Add scope metadata, not wire fields: the old canonical envelope JSON,
      // mutation ID, mirrors and cursor are byte-for-byte unchanged.
      final promoted = <String, String>{};
      Future<String?> promote(String? id) async {
        if (id == null) return null;
        if (promoted.containsKey(id)) return promoted[id];
        final entry = await secrets.get(id);
        if ((entry['syncGeneration'] ?? '').isNotEmpty) {
          throw const StaleSyncIdentity();
        }
        return promoted[id] = await secrets.put({
          ...entry,
          'syncGeneration': syncGeneration,
          'rebuildAttemptId': '',
        });
      }

      for (final m in metas) {
        await (db.update(db.syncMeta)..where(
              (r) =>
                  r.accountId.equals(identity.accountId) &
                  r.recordId.equals(m.recordId),
            ))
            .write(
              SyncMetaCompanion(
                syncGeneration: Value(syncGeneration),
                pendingEnvelopeSecretId: Value(
                  await promote(m.pendingEnvelopeSecretId),
                ),
                inFlightEnvelopeSecretId: Value(
                  await promote(m.inFlightEnvelopeSecretId),
                ),
              ),
            );
      }
      await (db.update(db.syncDocuments)
            ..where((r) => r.accountId.equals(identity.accountId)))
          .write(SyncDocumentsCompanion(syncGeneration: Value(syncGeneration)));
      await (db.update(
        db.syncState,
      )..where((r) => r.accountId.equals(identity.accountId))).write(
        SyncStateCompanion(
          syncGeneration: Value(syncGeneration),
          backupState: Value(backupState),
        ),
      );
    } else {
      await _archiveScope(identity.accountId, 'generation_retired');
      for (final row in docs) {
        final local = await _payload(row.localPayloadSecretId);
        final remote = await _payload(row.remotePayloadSecretId);
        final pending =
            row.pendingMerge ||
            (row.remoteEditedAt == null
                ? metas.any((m) => m.documentId == row.documentId && m.dirty)
                : row.localDeleted != row.remoteDeleted ||
                      row.localSchemaVersion != row.remoteSchemaVersion ||
                      canonicalSyncJson(local) != canonicalSyncJson(remote));
        await (db.update(
          db.syncDocuments,
        )..where((r) => r.documentId.equals(row.documentId))).write(
          SyncDocumentsCompanion(
            syncGeneration: Value(syncGeneration),
            pendingMerge: Value(pending),
            remoteRevision: const Value(null),
            remoteEditedAt: const Value(null),
            remoteDeleted: const Value(null),
            remoteSchemaVersion: const Value(null),
            remotePayloadSecretId: const Value(null),
          ),
        );
      }
      await (db.delete(
        db.syncMeta,
      )..where((r) => r.accountId.equals(identity.accountId))).go();
      await (db.delete(
        db.syncRebuildEntries,
      )..where((r) => r.accountId.equals(identity.accountId))).go();
      await (db.delete(
        db.syncPullStageEntries,
      )..where((r) => r.accountId.equals(identity.accountId))).go();
      await (db.delete(
        db.syncPullStages,
      )..where((r) => r.accountId.equals(identity.accountId))).go();
      await (db.update(
        db.syncState,
      )..where((r) => r.accountId.equals(identity.accountId))).write(
        SyncStateCompanion(
          syncGeneration: Value(syncGeneration),
          backupState: Value(backupState),
          cursor: const Value(0),
          bootstrapCompleted: const Value(false),
          lastSyncAt: const Value(null),
          blockedReason: const Value(null),
          rebuildAttemptId: const Value(null),
          rebuildLocalAttemptId: const Value(null),
          rebuildManifestSecretId: const Value(null),
          rebuildControlSecretId: const Value(null),
        ),
      );
    }
    final next = _scopedIdentity(identity, await state(identity.accountId));
    await _guard(next, isCurrent);
    return next;
  });

  Future<StoredSyncRebuildManifest?> rebuildManifest(
    SyncIdentity identity,
  ) async {
    await _guard(identity, () => true);
    final scope = await state(identity.accountId);
    final id = scope.rebuildManifestSecretId;
    if (id == null) return null;
    final entry = await secrets.get(id);
    if (entry['syncGeneration'] != identity.syncGeneration ||
        entry['localAttemptId'] != identity.rebuildLocalAttemptId) {
      throw const StaleSyncIdentity();
    }
    final manifest = jsonDecode(entry['manifest']!) as List;
    return StoredSyncRebuildManifest(
      identity: identity,
      localAttemptId: scope.rebuildLocalAttemptId!,
      entries: [for (final e in manifest) (e as Map).cast<String, Object?>()],
    );
  }

  /// Freeze the chosen device's current semantic content before start/claim.
  /// A later edit changes canonical content only, never this manifest.
  Future<StoredSyncRebuildManifest> beginRebuild(
    SyncIdentity identity,
    bool Function() isCurrent,
    String localAttemptId, {
    bool replaceExisting = false,
    Future<void> Function()? prepare,
    Future<void> Function(FrozenSyncMutation)? validate,
  }) => db.transaction(() async {
    _checkUuid(localAttemptId);
    await _guard(identity, isCurrent);
    if (identity.syncGeneration == null) throw const StaleSyncIdentity();
    final before = await state(identity.accountId);
    if (before.rebuildLocalAttemptId == localAttemptId) {
      return (await rebuildManifest(identity))!;
    }
    if (before.backupState == 'ready' ||
        (before.rebuildLocalAttemptId != null && !replaceExisting) ||
        before.rebuildControlSecretId != null) {
      throw const SyncRebuildIncomplete();
    }
    await _archiveScope(identity.accountId, 'rebuild_input_frozen');
    await (db.delete(
      db.syncMeta,
    )..where((r) => r.accountId.equals(identity.accountId))).go();
    await (db.delete(
      db.syncRebuildEntries,
    )..where((r) => r.accountId.equals(identity.accountId))).go();
    await prepare?.call();
    final snapshots = await documents(accountId: identity.accountId);
    final chosen = snapshots.where((d) => !d.row.localDeleted).toList();
    if (chosen.length > 100000) {
      throw const SyncValidationException(SyncValidationFailure.tooLarge);
    }
    final entries = <Map<String, Object?>>[];
    for (final doc in chosen) {
      final row = doc.row;
      if (doc.localPayload == null ||
          row.syncGeneration != identity.syncGeneration) {
        throw const SyncValidationException();
      }
      final mutationId = newId();
      final envelope = <String, Object?>{
        'mutationId': mutationId,
        'recordId': row.recordId,
        'type': row.type,
        'baseRevision': 0,
        'editedAt': row.localEditedAt,
        'deleted': false,
        'schemaVersion': row.localSchemaVersion,
        'payload': doc.localPayload,
      };
      final body = canonicalSyncJson(envelope);
      if (utf8.encode(body).length > syncRecordMaxBytes) {
        throw const SyncValidationException(SyncValidationFailure.tooLarge);
      }
      final allowed =
          (await secrets.get(row.localPayloadSecretId!))['uploadAllowed'] !=
          'false';
      if (!allowed) throw const SyncValidationException();
      await validate?.call(
        FrozenSyncMutation(
          documentId: row.documentId,
          envelopeJson: body,
          envelope: envelope,
          syncGeneration: identity.syncGeneration,
          uploadAllowed: allowed,
        ),
      );
      final frozen = await secrets.put({
        'envelope': body,
        'uploadAllowed': 'true',
        'syncGeneration': identity.syncGeneration!,
        'localAttemptId': localAttemptId,
        'rebuildAttemptId': '',
      });
      await db
          .into(db.syncRebuildEntries)
          .insert(
            SyncRebuildEntriesCompanion.insert(
              accountId: identity.accountId,
              syncGeneration: identity.syncGeneration!,
              attemptId: localAttemptId,
              ordinal: entries.length,
              documentId: row.documentId,
              recordId: row.recordId,
              type: row.type,
              mutationId: mutationId,
              envelopeSecretId: frozen,
            ),
          );
      entries.add({
        'recordId': row.recordId,
        'type': row.type,
        'mutationId': mutationId,
      });
    }
    final manifest = await secrets.put({
      'manifest': canonicalSyncJson(entries),
      'syncGeneration': identity.syncGeneration!,
      'localAttemptId': localAttemptId,
    });
    await (db.update(
      db.syncState,
    )..where((r) => r.accountId.equals(identity.accountId))).write(
      SyncStateCompanion(
        backupState: const Value('rebuilding'),
        rebuildAttemptId: const Value(null),
        rebuildLocalAttemptId: Value(localAttemptId),
        rebuildManifestSecretId: Value(manifest),
      ),
    );
    final next = _scopedIdentity(identity, await state(identity.accountId));
    await _guard(next, isCurrent);
    return StoredSyncRebuildManifest(
      identity: next,
      localAttemptId: localAttemptId,
      entries: entries,
    );
  });

  /// Only the successful start/claim response supplies the server attempt ID.
  /// Envelopes gain encrypted scope metadata; their exact wire body is kept.
  Future<SyncIdentity> bindRebuildAttempt(
    SyncIdentity identity,
    bool Function() isCurrent, {
    required String localAttemptId,
    required String serverAttemptId,
  }) => db.transaction(() async {
    _checkUuid(serverAttemptId);
    await _guard(identity, isCurrent);
    if (identity.rebuildLocalAttemptId != localAttemptId ||
        (identity.rebuildAttemptId != null &&
            identity.rebuildAttemptId != serverAttemptId)) {
      throw const StaleSyncIdentity();
    }
    final rows = await _rebuildEntries(identity);
    for (final row in rows) {
      final sealed = await secrets.get(row.envelopeSecretId);
      if (sealed['syncGeneration'] != identity.syncGeneration ||
          sealed['localAttemptId'] != localAttemptId ||
          ((sealed['rebuildAttemptId'] ?? '').isNotEmpty &&
              sealed['rebuildAttemptId'] != serverAttemptId)) {
        throw const StaleSyncIdentity();
      }
      if (sealed['rebuildAttemptId'] == serverAttemptId) continue;
      final next = await secrets.put({
        ...sealed,
        'rebuildAttemptId': serverAttemptId,
      });
      await (db.update(db.syncRebuildEntries)..where(
            (r) =>
                r.accountId.equals(identity.accountId) &
                r.syncGeneration.equals(identity.syncGeneration!) &
                r.attemptId.equals(localAttemptId) &
                r.recordId.equals(row.recordId),
          ))
          .write(SyncRebuildEntriesCompanion(envelopeSecretId: Value(next)));
      await secrets.deleteIfUnowned(row.envelopeSecretId);
    }
    await (db.update(db.syncState)
          ..where((r) => r.accountId.equals(identity.accountId)))
        .write(SyncStateCompanion(rebuildAttemptId: Value(serverAttemptId)));
    final next = _scopedIdentity(identity, await state(identity.accountId));
    await _guard(next, isCurrent);
    return next;
  });

  Future<List<SyncRebuildEntryRow>> _rebuildEntries(
    SyncIdentity identity,
  ) async {
    if (identity.syncGeneration == null ||
        identity.rebuildLocalAttemptId == null) {
      throw const SyncRebuildIncomplete();
    }
    return (db.select(db.syncRebuildEntries)
          ..where(
            (r) =>
                r.accountId.equals(identity.accountId) &
                r.syncGeneration.equals(identity.syncGeneration!) &
                r.attemptId.equals(identity.rebuildLocalAttemptId!),
          )
          ..orderBy([(r) => OrderingTerm.asc(r.ordinal)]))
        .get();
  }

  Future<List<FrozenSyncMutation>> prepareRebuildPush(
    SyncIdentity identity,
    bool Function() isCurrent, {
    int limit = 100,
    int maxBodyBytes = syncBodyMaxBytes,
    Future<void> Function(FrozenSyncMutation)? validate,
  }) => db.transaction(() async {
    await _guard(identity, isCurrent);
    if (identity.rebuildAttemptId == null) throw const SyncRebuildIncomplete();
    final batch = <FrozenSyncMutation>[];
    var bytes =
        16 +
        (identity.syncGeneration?.length ?? 0) +
        (identity.rebuildAttemptId?.length ?? 0) +
        64;
    for (final row in (await _rebuildEntries(
      identity,
    )).where((e) => !e.acknowledged).take(limit)) {
      final sealed = await secrets.get(row.envelopeSecretId);
      _checkFrozenScope(sealed, identity, rebuilding: true);
      final json = sealed['envelope']!;
      final envelope = (jsonDecode(json) as Map).cast<String, Object?>();
      if (envelope['mutationId'] != row.mutationId ||
          envelope['recordId'] != row.recordId ||
          envelope['type'] != row.type ||
          envelope['baseRevision'] != 0 ||
          envelope['deleted'] != false) {
        throw const SyncValidationException();
      }
      final nextBytes =
          bytes + utf8.encode(json).length + (batch.isEmpty ? 0 : 1);
      if (nextBytes > maxBodyBytes) {
        if (batch.isEmpty) {
          throw const SyncValidationException(SyncValidationFailure.tooLarge);
        }
        break;
      }
      final frozen = FrozenSyncMutation(
        documentId: row.documentId,
        envelopeJson: json,
        envelope: envelope,
        syncGeneration: identity.syncGeneration,
        rebuildAttemptId: identity.rebuildAttemptId,
        uploadAllowed: sealed['uploadAllowed'] != 'false',
      );
      await validate?.call(frozen);
      batch.add(frozen);
      bytes = nextBytes;
    }
    await _guard(identity, isCurrent);
    return batch;
  });

  /// Staged results advance progress only; no ordinary mirror or projection
  /// receives half a rebuild. An uncertain prefix is replayed unchanged.
  Future<void> commitRebuildPrefix(
    SyncIdentity identity,
    bool Function() isCurrent, {
    required List<FrozenSyncMutation> sent,
    required List<Map<String, Object?>> results,
  }) => db.transaction(() async {
    await _guard(identity, isCurrent);
    if (identity.rebuildAttemptId == null ||
        results.isEmpty ||
        results.length > sent.length) {
      throw const SyncValidationException();
    }
    final rows = {
      for (final e in await _rebuildEntries(identity)) e.mutationId: e,
    };
    for (var i = 0; i < results.length; i++) {
      final frozen = sent[i];
      final row = rows[frozen.mutationId];
      if (frozen.syncGeneration != identity.syncGeneration ||
          frozen.rebuildAttemptId != identity.rebuildAttemptId) {
        throw const StaleSyncIdentity();
      }
      if (row == null ||
          row.documentId != frozen.documentId ||
          results[i]['mutationId'] != frozen.mutationId ||
          results[i]['status'] != 'applied') {
        throw const SyncValidationException();
      }
      final sealed = await secrets.get(row.envelopeSecretId);
      _checkFrozenScope(sealed, identity, rebuilding: true);
      if (sealed['envelope'] != frozen.envelopeJson) {
        throw const SyncValidationException();
      }
      await (db.update(db.syncRebuildEntries)..where(
            (r) =>
                r.accountId.equals(identity.accountId) &
                r.syncGeneration.equals(identity.syncGeneration!) &
                r.attemptId.equals(identity.rebuildLocalAttemptId!) &
                r.recordId.equals(row.recordId),
          ))
          .write(const SyncRebuildEntriesCompanion(acknowledged: Value(true)));
    }
    await _guard(identity, isCurrent);
  });

  Future<Map<String, Object?>?> readRebuildControl(
    SyncIdentity identity,
  ) async {
    await _guard(identity, () => true);
    final scope = await state(identity.accountId);
    if (scope.rebuildControlSecretId == null) return null;
    final sealed = await secrets.get(scope.rebuildControlSecretId!);
    if (sealed['syncGeneration'] != identity.syncGeneration) {
      throw const StaleSyncIdentity();
    }
    return immutableSyncJson(jsonDecode(sealed['control']!))
        as Map<String, Object?>;
  }

  /// Persist exactly this operationId/action/body before sending any control
  /// request. Unknown outcomes cannot be replaced by a newly generated action.
  Future<void> saveRebuildControl(
    SyncIdentity identity,
    bool Function() isCurrent,
    Map<String, Object?> control,
  ) => db.transaction(() async {
    await _guard(identity, isCurrent);
    if (identity.syncGeneration == null) throw const StaleSyncIdentity();
    if (control['syncGeneration'] != identity.syncGeneration) {
      throw const StaleSyncIdentity();
    }
    _checkUuid(control['operationId'] as String);
    if (!{'start', 'claim', 'complete', 'cancel'}.contains(control['action'])) {
      throw const SyncValidationException();
    }
    final encoded = canonicalSyncJson(immutableSyncJson(control));
    if (utf8.encode(encoded).length > syncBodyMaxBytes) {
      throw const SyncValidationException(SyncValidationFailure.tooLarge);
    }
    final previous = await readRebuildControl(identity);
    if (previous != null) {
      if (canonicalSyncJson(previous) != encoded) {
        throw const SyncRebuildIncomplete();
      }
      return;
    }
    final id = await secrets.put({
      'control': encoded,
      'syncGeneration': identity.syncGeneration!,
    });
    await (db.update(db.syncState)
          ..where((r) => r.accountId.equals(identity.accountId)))
        .write(SyncStateCompanion(rebuildControlSecretId: Value(id)));
    await _guard(identity, isCurrent);
  });

  Future<void> clearRebuildControl(
    SyncIdentity identity,
    bool Function() isCurrent, {
    required String operationId,
  }) => db.transaction(() async {
    await _guard(identity, isCurrent);
    final previous = await readRebuildControl(identity);
    if (previous == null) return;
    if (previous['operationId'] != operationId) throw const StaleSyncIdentity();
    final old = (await state(identity.accountId)).rebuildControlSecretId;
    await (db.update(db.syncState)
          ..where((r) => r.accountId.equals(identity.accountId)))
        .write(const SyncStateCompanion(rebuildControlSecretId: Value(null)));
    await secrets.deleteIfUnowned(old);
    await _guard(identity, isCurrent);
  });

  /// Call only after the exact complete operation has succeeded remotely.
  Future<SyncIdentity> completeRebuild(
    SyncIdentity identity,
    bool Function() isCurrent,
  ) => db.transaction(() async {
    await _guard(identity, isCurrent);
    if (identity.rebuildAttemptId == null ||
        (await _rebuildEntries(identity)).any((e) => !e.acknowledged)) {
      throw const SyncRebuildIncomplete();
    }
    final rows = await _rebuildEntries(identity);
    for (final row in rows) {
      final doc = await document(row.documentId);
      if (doc == null) continue;
      final frozen =
          jsonDecode((await secrets.get(row.envelopeSecretId))['envelope']!)
              as Map;
      final changed =
          doc.row.localDeleted ||
          doc.row.localSchemaVersion != frozen['schemaVersion'] ||
          canonicalSyncJson(doc.localPayload) !=
              canonicalSyncJson(frozen['payload']);
      await (db.update(db.syncDocuments)
            ..where((r) => r.documentId.equals(row.documentId)))
          .write(SyncDocumentsCompanion(pendingMerge: Value(changed)));
    }
    // Keep the completed frozen attempt in an archive for diagnostics/recovery.
    await _archiveScope(identity.accountId, 'rebuild_published');
    await (db.delete(
      db.syncRebuildEntries,
    )..where((r) => r.accountId.equals(identity.accountId))).go();
    await (db.update(
      db.syncState,
    )..where((r) => r.accountId.equals(identity.accountId))).write(
      const SyncStateCompanion(
        backupState: Value('ready'),
        rebuildAttemptId: Value(null),
        rebuildLocalAttemptId: Value(null),
        rebuildManifestSecretId: Value(null),
        cursor: Value(0),
        bootstrapCompleted: Value(false),
      ),
    );
    final next = _scopedIdentity(identity, await state(identity.accountId));
    await _guard(next, isCurrent);
    return next;
  });

  Future<SyncIdentity> cancelRebuild(
    SyncIdentity identity,
    bool Function() isCurrent,
  ) => db.transaction(() async {
    await _guard(identity, isCurrent);
    await _archiveScope(identity.accountId, 'rebuild_cancelled');
    await (db.delete(
      db.syncRebuildEntries,
    )..where((r) => r.accountId.equals(identity.accountId))).go();
    await (db.update(
      db.syncState,
    )..where((r) => r.accountId.equals(identity.accountId))).write(
      const SyncStateCompanion(
        backupState: Value('rebuildRequired'),
        rebuildAttemptId: Value(null),
        rebuildLocalAttemptId: Value(null),
        rebuildManifestSecretId: Value(null),
      ),
    );
    final next = _scopedIdentity(identity, await state(identity.accountId));
    await _guard(next, isCurrent);
    return next;
  });

  Future<SyncPullStageRow?> fullPullStage(String accountId) => (db.select(
    db.syncPullStages,
  )..where((r) => r.accountId.equals(accountId))).getSingleOrNull();

  /// Counts retained offline edits and independent local candidates without
  /// decrypting payloads. An unchanged retired mirror is not a pending merge.
  Future<int> pendingMergeCount(String accountId) async {
    final rows =
        await (db.select(db.syncDocuments)..where(
              (r) =>
                  (r.accountId.equals(accountId) &
                      r.pendingMerge.equals(true)) |
                  (r.accountId.isNull() & r.localDeleted.equals(false)),
            ))
            .get();
    return rows.length;
  }

  Future<void> discardFullPull(
    SyncIdentity identity,
    bool Function() isCurrent,
  ) => db.transaction(() async {
    await _guard(identity, isCurrent);
    final rows = await (db.select(
      db.syncPullStageEntries,
    )..where((r) => r.accountId.equals(identity.accountId))).get();
    await (db.delete(
      db.syncPullStageEntries,
    )..where((r) => r.accountId.equals(identity.accountId))).go();
    await (db.delete(
      db.syncPullStages,
    )..where((r) => r.accountId.equals(identity.accountId))).go();
    for (final row in rows) {
      await secrets.deleteIfUnowned(row.recordSecretId);
    }
    await _guard(identity, isCurrent);
  });

  /// Each valid page is encrypted in an isolated staging area; no cursor or
  /// visible projection changes until the full immutable server head is ready.
  Future<void> stageFullPull(
    SyncIdentity identity,
    bool Function() isCurrent, {
    required int headRevision,
    required List<Map<String, Object?>> records,
    required int nextCursor,
    required bool hasMore,
  }) => db.transaction(() async {
    await _guard(identity, isCurrent);
    if (identity.syncGeneration == null ||
        headRevision < 0 ||
        headRevision > syncMaxRevision) {
      throw const SyncValidationException();
    }
    final old = await fullPullStage(identity.accountId);
    if (old != null &&
        (old.syncGeneration != identity.syncGeneration ||
            old.headRevision != headRevision ||
            old.complete)) {
      throw const StaleSyncIdentity();
    }
    var revision = old?.cursor ?? 0;
    for (final raw in records) {
      final record = immutableSyncJson(raw) as Map<String, Object?>;
      final next = record['revision'] as int;
      if (next <= revision || next > headRevision) {
        throw const SyncValidationException();
      }
      _checkLocal(
        record['type'] as String,
        record['deleted'] as bool,
        (record['payload'] as Map?)?.cast<String, Object?>(),
        record['schemaVersion'] as int,
      );
      final id = record['recordId'] as String;
      final existing =
          await (db.select(db.syncPullStageEntries)..where(
                (r) =>
                    r.accountId.equals(identity.accountId) &
                    r.recordId.equals(id),
              ))
              .getSingleOrNull();
      if (existing != null) throw const SyncValidationException();
      final secret = await secrets.put({'record': canonicalSyncJson(record)});
      await db
          .into(db.syncPullStageEntries)
          .insert(
            SyncPullStageEntriesCompanion.insert(
              accountId: identity.accountId,
              recordId: id,
              revision: next,
              recordSecretId: secret,
            ),
          );
      revision = next;
    }
    if (nextCursor != revision ||
        (hasMore ? revision >= headRevision : revision != headRevision)) {
      throw const SyncValidationException();
    }
    await db
        .into(db.syncPullStages)
        .insertOnConflictUpdate(
          SyncPullStagesCompanion.insert(
            accountId: identity.accountId,
            syncGeneration: identity.syncGeneration!,
            headRevision: headRevision,
            cursor: nextCursor,
            complete: !hasMore,
          ),
        );
    await _guard(identity, isCurrent);
  });

  Future<void> publishFullPull(
    SyncIdentity identity,
    bool Function() isCurrent, {
    required int headRevision,
    Future<void> Function(SyncDocumentSnapshot document)? project,
    Future<void> Function()? merge,
  }) => db.transaction(() async {
    await _guard(identity, isCurrent);
    final stage = await fullPullStage(identity.accountId);
    if (stage == null ||
        !stage.complete ||
        stage.syncGeneration != identity.syncGeneration ||
        stage.headRevision != headRevision ||
        stage.cursor != headRevision) {
      throw const StaleSyncIdentity();
    }
    final entries =
        await (db.select(db.syncPullStageEntries)
              ..where((r) => r.accountId.equals(identity.accountId))
              ..orderBy([(r) => OrderingTerm.asc(r.revision)]))
            .get();
    for (final e in entries) {
      final record =
          (jsonDecode((await secrets.get(e.recordSecretId))['record']!) as Map)
              .cast<String, Object?>();
      final snapshot = await _observe(
        identity.accountId,
        record,
        applyLocal: true,
      );
      await project?.call(snapshot);
    }
    await merge?.call();
    await (db.update(
      db.syncState,
    )..where((r) => r.accountId.equals(identity.accountId))).write(
      SyncStateCompanion(
        cursor: Value(headRevision),
        bootstrapCompleted: const Value(true),
      ),
    );
    await discardFullPull(identity, isCurrent);
    await _guard(identity, isCurrent);
  });

  /// Call from the same transaction as the actual user edit. Semantically
  /// unchanged payloads retain their original timestamp and mutation identity.
  /// [enqueue] is false for edits to another account's retained local content.
  Future<SyncDocumentSnapshot> saveLocal({
    String? documentId,
    String? accountId,
    required String recordId,
    required String type,
    String? localId,
    required int editedAt,
    required bool deleted,
    Map<String, Object?>? payload,
    bool enqueue = true,
    bool uploadAllowed = true,
    int schemaVersion = 1,
  }) => db.transaction(() async {
    _checkLocal(type, deleted, payload, schemaVersion);
    // Copy before the first await: a caller cannot mutate one payload between
    // sealing the local canonical and sealing its supposedly frozen envelope.
    final canonicalPayload =
        immutableSyncJson(payload) as Map<String, Object?>?;
    final scope = accountId == null ? null : await state(accountId);
    final old = documentId == null ? null : await _row(documentId);
    if (documentId != null && old == null) {
      throw StateError('sync document missing');
    }
    if (old != null &&
        (old.type != type ||
            old.recordId != recordId ||
            old.accountId != accountId)) {
      throw StateError('sync owner cannot change implicitly');
    }
    var unchanged = false;
    if (old != null &&
        old.localDeleted == deleted &&
        old.localSchemaVersion == schemaVersion) {
      try {
        unchanged =
            canonicalSyncJson(await _payload(old.localPayloadSecretId)) ==
            canonicalSyncJson(canonicalPayload);
      } on VaultLockedException {
        // Re-entering credentials repairs the local canonical while retaining
        // its account owner. An unreadable old value cannot prove equality.
      }
    }
    if (unchanged) return _snapshot(old!);
    final id = documentId ?? newId();
    final entry = deleted
        ? null
        : await secrets.put({
            'payload': canonicalSyncJson(canonicalPayload),
            'uploadAllowed': uploadAllowed ? 'true' : 'false',
          });
    if (old == null) {
      await db
          .into(db.syncDocuments)
          .insert(
            SyncDocumentsCompanion.insert(
              documentId: id,
              accountId: Value(accountId),
              recordId: recordId,
              type: type,
              localId: Value(localId),
              localPayloadSecretId: Value(entry),
              localEditedAt: editedAt,
              localDeleted: deleted,
              localSchemaVersion: Value(schemaVersion),
              syncGeneration: Value(scope?.syncGeneration),
              pendingMerge: Value(scope?.syncGeneration != null),
            ),
          );
    } else {
      await (db.update(
        db.syncDocuments,
      )..where((r) => r.documentId.equals(id))).write(
        SyncDocumentsCompanion(
          localId: localId == null ? const Value.absent() : Value(localId),
          localPayloadSecretId: Value(entry),
          localEditedAt: Value(editedAt),
          localDeleted: Value(deleted),
          localSchemaVersion: Value(schemaVersion),
          pendingMerge: Value(scope?.syncGeneration != null),
        ),
      );
    }
    final current = (await _row(id))!;
    if (accountId != null && enqueue) {
      await _freeze(current, canonicalPayload, uploadAllowed: uploadAllowed);
    }
    await secrets.deleteIfUnowned(old?.localPayloadSecretId);
    return _snapshot(current);
  });

  void _checkLocal(
    String type,
    bool deleted,
    Map<String, Object?>? payload,
    int schemaVersion,
  ) {
    if (!{
          'configuration',
          'node',
          'chain',
          'policy',
          'selection',
        }.contains(type) ||
        schemaVersion != 1 ||
        deleted != (payload == null)) {
      throw StateError('invalid canonical sync document');
    }
  }

  Future<void> _freeze(
    SyncDocumentRow row,
    Map<String, Object?>? payload, {
    bool? uploadAllowed,
  }) async {
    uploadAllowed ??=
        row.localPayloadSecretId == null ||
        (await secrets.get(row.localPayloadSecretId!))['uploadAllowed'] !=
            'false';
    final accountId = row.accountId!;
    final scope = await state(accountId);
    if (scope.syncGeneration != row.syncGeneration) {
      throw const StaleSyncIdentity();
    }
    if (scope.syncGeneration != null && scope.backupState != 'ready') return;
    final old = await _meta(accountId, row.recordId);
    final mutationId = newId();
    final envelope = {
      'mutationId': mutationId,
      'recordId': row.recordId,
      'type': row.type,
      'baseRevision': row.remoteRevision ?? 0,
      'editedAt': row.localEditedAt,
      'deleted': row.localDeleted,
      'schemaVersion': row.localSchemaVersion,
      'payload': payload,
    };
    final secretId = await secrets.put({
      'envelope': canonicalSyncJson(envelope),
      'uploadAllowed': uploadAllowed ? 'true' : 'false',
      'syncGeneration': scope.syncGeneration ?? '',
      'rebuildAttemptId': '',
    });
    await db
        .into(db.syncMeta)
        .insertOnConflictUpdate(
          SyncMetaCompanion.insert(
            accountId: accountId,
            recordId: row.recordId,
            documentId: row.documentId,
            type: row.type,
            remoteRevision: Value(row.remoteRevision),
            dirty: true,
            deleted: row.localDeleted,
            editedAt: row.localEditedAt,
            mutationId: Value(mutationId),
            pendingEnvelopeSecretId: Value(secretId),
            inFlightMutationId: Value(old?.inFlightMutationId),
            inFlightEnvelopeSecretId: Value(old?.inFlightEnvelopeSecretId),
            syncGeneration: Value(scope.syncGeneration),
          ),
        );
    await secrets.deleteIfUnowned(old?.pendingEnvelopeSecretId);
  }

  Future<SyncDocumentSnapshot> bindDocument(
    String documentId,
    String accountId, {
    bool enqueue = true,
  }) => db.transaction(() async {
    final old = (await _row(documentId))!;
    if (old.accountId != null && old.accountId != accountId) {
      throw StateError('sync document already bound');
    }
    await (db.update(
      db.syncDocuments,
    )..where((r) => r.documentId.equals(documentId))).write(
      SyncDocumentsCompanion(
        accountId: Value(accountId),
        syncGeneration: Value((await state(accountId)).syncGeneration),
        pendingMerge: Value((await state(accountId)).syncGeneration != null),
      ),
    );
    final row = (await _row(documentId))!;
    if (enqueue) await _freeze(row, await _payload(row.localPayloadSecretId));
    return _snapshot(row);
  });

  Future<void> setLocalId(String documentId, String localId) =>
      (db.update(db.syncDocuments)
            ..where((r) => r.documentId.equals(documentId)))
          .write(SyncDocumentsCompanion(localId: Value(localId)));

  /// Reconcile actual offline edits without regenerating IDs merely because
  /// the vault used a new encrypted entry or an unchanged projection arrived.
  Future<void> reconcileAccount(String accountId) => db.transaction(() async {
    final scope = await state(accountId);
    if (scope.syncGeneration != null && scope.backupState != 'ready') return;
    for (final snapshot in await documents(accountId: accountId)) {
      final row = snapshot.row;
      if (row.syncGeneration != scope.syncGeneration) {
        throw const StaleSyncIdentity();
      }
      final meta = snapshot.meta;
      Map<String, Object?>? previous;
      final pending = meta?.pendingEnvelopeSecretId;
      if (pending != null) {
        previous =
            (jsonDecode((await secrets.get(pending))['envelope']!) as Map)
                .cast<String, Object?>();
      }
      previous ??= snapshot.remoteRecord;
      if (scope.syncGeneration != null &&
          previous == null &&
          !row.pendingMerge) {
        continue;
      }
      if (previous == null ||
          previous['deleted'] != row.localDeleted ||
          previous['schemaVersion'] != row.localSchemaVersion ||
          canonicalSyncJson(previous['payload']) !=
              canonicalSyncJson(snapshot.localPayload)) {
        if (row.localDeleted || snapshot.localPayload != null) {
          await _freeze(row, snapshot.localPayload);
        }
      }
    }
  });

  /// Existing unknown results are retried before any fresh pending versions.
  /// Freeze only the prefix that fits the actual request budget. Unsent tails
  /// remain pending so a later local edit can replace them safely.
  Future<List<FrozenSyncMutation>> preparePush(
    SyncIdentity identity,
    bool Function() isCurrent, {
    int limit = 100,
    int maxBodyBytes = syncBodyMaxBytes,
    Future<void> Function(FrozenSyncMutation)? validate,
  }) => db.transaction(() async {
    await _guard(identity, isCurrent);
    if (identity.rebuildAttemptId != null ||
        identity.rebuildLocalAttemptId != null) {
      throw const SyncRebuildIncomplete();
    }
    final rows =
        await (db.select(db.syncMeta)
              ..where((r) => r.accountId.equals(identity.accountId))
              ..orderBy([(r) => OrderingTerm.asc(r.recordId)]))
            .get();
    final unresolved = rows.where((r) => r.inFlightMutationId != null).toList();
    final selected =
        (unresolved.isNotEmpty
                ? unresolved
                : rows.where((r) => r.dirty).toList())
            .take(limit);
    final batch = <FrozenSyncMutation>[];
    var bytes = 16; // {"mutations":[]} with no elements.
    for (final meta in selected) {
      final secretId =
          meta.inFlightEnvelopeSecretId ?? meta.pendingEnvelopeSecretId;
      if (secretId == null) throw StateError('sync envelope needs hydration');
      final sealed = await secrets.get(secretId);
      _checkFrozenScope(sealed, identity);
      if (meta.syncGeneration != identity.syncGeneration) {
        throw const StaleSyncIdentity();
      }
      final json = sealed['envelope']!;
      final envelope = (jsonDecode(json) as Map).cast<String, Object?>();
      final mutationId = envelope['mutationId'] as String;
      if (mutationId != (meta.inFlightMutationId ?? meta.mutationId)) {
        throw StateError('sync envelope identity mismatch');
      }
      final nextBytes =
          bytes + utf8.encode(json).length + (batch.isEmpty ? 0 : 1);
      if (nextBytes > maxBodyBytes) {
        if (batch.isEmpty) throw const SyncValidationException();
        break;
      }
      if (validate != null) {
        await validate(
          FrozenSyncMutation(
            documentId: meta.documentId,
            envelopeJson: json,
            envelope: envelope,
            uploadAllowed: sealed['uploadAllowed'] != 'false',
            syncGeneration: identity.syncGeneration,
          ),
        );
      }
      if (meta.inFlightMutationId == null &&
          sealed['uploadAllowed'] != 'false') {
        await (db.update(db.syncMeta)..where(
              (r) =>
                  r.accountId.equals(identity.accountId) &
                  r.recordId.equals(meta.recordId),
            ))
            .write(
              SyncMetaCompanion(
                inFlightMutationId: Value(mutationId),
                inFlightEnvelopeSecretId: Value(secretId),
              ),
            );
      }
      batch.add(
        FrozenSyncMutation(
          documentId: meta.documentId,
          envelopeJson: json,
          envelope: envelope,
          uploadAllowed: sealed['uploadAllowed'] != 'false',
          syncGeneration: identity.syncGeneration,
        ),
      );
      bytes = nextBytes;
    }
    await _guard(identity, isCurrent);
    return batch;
  });

  Future<void> commitPullPage(
    SyncIdentity identity,
    bool Function() isCurrent, {
    required List<Map<String, Object?>> records,
    required int nextCursor,
    Future<void> Function(SyncDocumentSnapshot document)? project,
    Future<void> Function()? reconcile,
  }) => db.transaction(() async {
    await _guard(identity, isCurrent);
    final current = await state(identity.accountId);
    var revision = current.cursor;
    for (final record in records) {
      if ((record['revision'] as int) <= revision) {
        throw StateError('sync page revision order');
      }
      revision = record['revision'] as int;
      final snapshot = await _observe(
        identity.accountId,
        record,
        applyLocal: true,
      );
      if (current.bootstrapCompleted && project != null) {
        await project(snapshot);
      }
    }
    if (nextCursor != revision) throw StateError('sync page cursor mismatch');
    await (db.update(db.syncState)
          ..where((r) => r.accountId.equals(identity.accountId)))
        .write(SyncStateCompanion(cursor: Value(nextCursor)));
    if (current.bootstrapCompleted && reconcile != null) await reconcile();
    await _guard(identity, isCurrent);
  });

  Future<SyncDocumentSnapshot> _observe(
    String accountId,
    Map<String, Object?> record, {
    required bool applyLocal,
  }) async {
    final recordId = record['recordId'] as String;
    final type = record['type'] as String;
    final revision = record['revision'] as int;
    final editedAt = record['editedAt'] as int;
    final deleted = record['deleted'] as bool;
    final schema = record['schemaVersion'] as int;
    final payload = (record['payload'] as Map?)?.cast<String, Object?>();
    _checkLocal(type, deleted, payload, schema);
    final existing = await findDocument(accountId, recordId);
    final scope = await state(accountId);
    var old = existing?.row;
    if (old != null && old.syncGeneration != scope.syncGeneration) {
      throw const StaleSyncIdentity();
    }
    if (old != null && old.type != type) throw StateError('sync type changed');
    if (old != null && (old.remoteRevision ?? 0) >= revision) {
      return _snapshot(old);
    }
    final meta = await _meta(accountId, recordId);
    // Retained cross-generation content may already be represented by the
    // newly published backup. No new-generation request was sent in this case,
    // so equal semantics can join its mirror without manufacturing an upload.
    // Once a mutation is frozen or in flight, only its exact result may clear it.
    final alreadyMerged =
        old?.pendingMerge == true &&
        meta?.dirty != true &&
        meta?.inFlightMutationId == null &&
        old!.localDeleted == deleted &&
        old.localSchemaVersion == schema &&
        canonicalSyncJson(existing?.localPayload) == canonicalSyncJson(payload);
    final takeRemote =
        applyLocal &&
        (old?.pendingMerge != true || alreadyMerged) &&
        !(meta?.dirty == true && old != null && old.localEditedAt > editedAt);
    final entry = deleted
        ? null
        : await secrets.put({'payload': canonicalSyncJson(payload)});
    if (old == null) {
      final id = newId();
      final localId = await _allocateLocalId(accountId, recordId, type);
      await db
          .into(db.syncDocuments)
          .insert(
            SyncDocumentsCompanion.insert(
              documentId: id,
              accountId: Value(accountId),
              recordId: recordId,
              type: type,
              localId: Value(localId),
              remoteRevision: Value(revision),
              remoteEditedAt: Value(editedAt),
              remoteDeleted: Value(deleted),
              remoteSchemaVersion: Value(schema),
              remotePayloadSecretId: Value(entry),
              localPayloadSecretId: Value(entry),
              localEditedAt: editedAt,
              localDeleted: deleted,
              localSchemaVersion: Value(schema),
              syncGeneration: Value(scope.syncGeneration),
            ),
          );
      old = await _row(id);
    } else {
      final previous = old;
      await (db.update(
        db.syncDocuments,
      )..where((r) => r.documentId.equals(previous.documentId))).write(
        SyncDocumentsCompanion(
          remoteRevision: Value(revision),
          remoteEditedAt: Value(editedAt),
          remoteDeleted: Value(deleted),
          remoteSchemaVersion: Value(schema),
          remotePayloadSecretId: Value(entry),
          localPayloadSecretId: takeRemote
              ? Value(entry)
              : const Value.absent(),
          localEditedAt: takeRemote ? Value(editedAt) : const Value.absent(),
          localDeleted: takeRemote ? Value(deleted) : const Value.absent(),
          localSchemaVersion: takeRemote ? Value(schema) : const Value.absent(),
          pendingMerge: takeRemote ? const Value(false) : const Value.absent(),
        ),
      );
      await secrets.deleteIfUnowned(previous.remotePayloadSecretId);
      if (takeRemote) {
        await secrets.deleteIfUnowned(previous.localPayloadSecretId);
      }
      old = await _row(previous.documentId);
    }
    final row = old!;
    await db
        .into(db.syncMeta)
        .insertOnConflictUpdate(
          SyncMetaCompanion.insert(
            documentId: row.documentId,
            accountId: accountId,
            recordId: recordId,
            type: type,
            remoteRevision: Value(revision),
            dirty: !takeRemote && (meta?.dirty ?? false),
            deleted: row.localDeleted,
            editedAt: row.localEditedAt,
            mutationId: Value(takeRemote ? null : meta?.mutationId),
            pendingEnvelopeSecretId: Value(
              takeRemote ? null : meta?.pendingEnvelopeSecretId,
            ),
            inFlightMutationId: Value(meta?.inFlightMutationId),
            inFlightEnvelopeSecretId: Value(meta?.inFlightEnvelopeSecretId),
            syncGeneration: Value(scope.syncGeneration),
          ),
        );
    if (takeRemote) {
      await secrets.deleteIfUnowned(meta?.pendingEnvelopeSecretId);
      await _remoteProvenance(
        row,
        payload,
        previousPayload: existing?.localPayload,
      );
    }
    return _snapshot(row);
  }

  Future<String?> _allocateLocalId(
    String accountId,
    String recordId,
    String type,
  ) async {
    return 'cloud:$accountId:$type:$recordId';
  }

  /// [results] is the completely validated processed prefix. A later edit
  /// keeps its pending slot; only the acknowledged sent slot is cleared.
  Future<void> commitPushPrefix(
    SyncIdentity identity,
    bool Function() isCurrent, {
    required List<FrozenSyncMutation> sent,
    required List<Map<String, Object?>> results,
    Future<void> Function(SyncDocumentSnapshot document)? project,
    Future<void> Function()? reconcile,
  }) => db.transaction(() async {
    await _guard(identity, isCurrent);
    if (results.isEmpty || results.length > sent.length) {
      throw StateError('invalid sync result prefix');
    }
    for (var i = 0; i < results.length; i++) {
      final mutation = sent[i];
      if (mutation.syncGeneration != identity.syncGeneration ||
          mutation.rebuildAttemptId != identity.rebuildAttemptId) {
        throw const StaleSyncIdentity();
      }
      final result = results[i];
      if (result['mutationId'] != mutation.mutationId) {
        throw StateError('sync result identity mismatch');
      }
      final envelope = mutation.envelope;
      final record = switch (result['status']) {
        'applied' => <String, Object?>{
          'recordId': envelope['recordId'],
          'type': envelope['type'],
          'revision': result['revision'],
          'editedAt': result['editedAt'],
          'deleted': envelope['deleted'],
          'schemaVersion': envelope['schemaVersion'],
          'payload': envelope['payload'],
        },
        'superseded' => (result['record'] as Map).cast<String, Object?>(),
        _ => throw StateError('invalid sync result status'),
      };
      if (record['recordId'] != mutation.recordId ||
          record['type'] != envelope['type']) {
        throw StateError('sync result owner mismatch');
      }
      final before = await _meta(identity.accountId, mutation.recordId);
      if (before == null || before.documentId != mutation.documentId) {
        throw StateError('sync result document mismatch');
      }
      if (before.syncGeneration != identity.syncGeneration) {
        throw const StaleSyncIdentity();
      }
      final wasCurrent = before.mutationId == mutation.mutationId;
      await _observe(identity.accountId, record, applyLocal: false);
      var row = (await _row(mutation.documentId))!;
      // Even a future local clock must converge after its explicit server
      // verdict. The highest previously observed mirror wins on old retries.
      if (wasCurrent || !before.dirty) {
        if (row.remoteEditedAt != null) {
          final previous = row;
          final previousPayload = await _payload(previous.localPayloadSecretId);
          await (db.update(
            db.syncDocuments,
          )..where((r) => r.documentId.equals(row.documentId))).write(
            SyncDocumentsCompanion(
              localPayloadSecretId: Value(row.remotePayloadSecretId),
              localEditedAt: Value(row.remoteEditedAt!),
              localDeleted: Value(row.remoteDeleted!),
              localSchemaVersion: Value(row.remoteSchemaVersion!),
              pendingMerge: const Value(false),
            ),
          );
          await secrets.deleteIfUnowned(previous.localPayloadSecretId);
          row = (await _row(row.documentId))!;
          if (result['status'] == 'superseded') {
            await _remoteProvenance(
              row,
              await _payload(row.localPayloadSecretId),
              previousPayload: previousPayload,
            );
          }
        }
      }
      await (db.update(db.syncMeta)..where(
            (r) =>
                r.accountId.equals(identity.accountId) &
                r.recordId.equals(mutation.recordId),
          ))
          .write(
            SyncMetaCompanion(
              dirty: wasCurrent ? const Value(false) : const Value.absent(),
              mutationId: wasCurrent ? const Value(null) : const Value.absent(),
              pendingEnvelopeSecretId: wasCurrent
                  ? const Value(null)
                  : const Value.absent(),
              inFlightMutationId:
                  before.inFlightMutationId == mutation.mutationId
                  ? const Value(null)
                  : const Value.absent(),
              inFlightEnvelopeSecretId:
                  before.inFlightMutationId == mutation.mutationId
                  ? const Value(null)
                  : const Value.absent(),
              editedAt: Value(row.localEditedAt),
              deleted: Value(row.localDeleted),
            ),
          );
      await secrets.deleteIfUnowned(before.pendingEnvelopeSecretId);
      await secrets.deleteIfUnowned(before.inFlightEnvelopeSecretId);
      if (project != null) await project(await _snapshot(row));
    }
    if (reconcile != null) await reconcile();
    await _guard(identity, isCurrent);
  });

  Future<void> completeBootstrap(
    SyncIdentity identity,
    bool Function() isCurrent, {
    required Future<void> Function() merge,
  }) => db.transaction(() async {
    await _guard(identity, isCurrent);
    await state(identity.accountId);
    await merge();
    await (db.update(db.syncState)
          ..where((r) => r.accountId.equals(identity.accountId)))
        .write(const SyncStateCompanion(bootstrapCompleted: Value(true)));
    await _guard(identity, isCurrent);
  });

  /// Restart a legacy first pull whose old cursor has no complete mirror.
  /// Modern interrupted bootstrap pages keep their cursor and resume normally.
  Future<void> resetBootstrapCursor(
    SyncIdentity identity,
    bool Function() isCurrent,
  ) => db.transaction(() async {
    await _guard(identity, isCurrent);
    final current = await state(identity.accountId);
    if (!current.bootstrapCompleted && current.cursor != 0) {
      final rows = await (db.select(
        db.syncDocuments,
      )..where((d) => d.accountId.equals(identity.accountId))).get();
      final completeMirrors = rows.where((d) => d.remoteEditedAt != null);
      final legacyMirror = rows.any(
        (d) => d.remoteRevision != null && d.remoteEditedAt == null,
      );
      if (completeMirrors.isEmpty || legacyMirror) {
        await (db.update(db.syncState)
              ..where((s) => s.accountId.equals(identity.accountId)))
            .write(const SyncStateCompanion(cursor: Value(0)));
      }
    }
    await _guard(identity, isCurrent);
  });

  Future<void> setBlocked(
    SyncIdentity identity,
    bool Function() isCurrent,
    String? reason, {
    bool success = false,
  }) => db.transaction(() async {
    await _guard(identity, isCurrent);
    await state(identity.accountId);
    await (db.update(
      db.syncState,
    )..where((r) => r.accountId.equals(identity.accountId))).write(
      SyncStateCompanion(
        blockedReason: Value(reason),
        lastSyncAt: success ? Value(nowMs()) : const Value.absent(),
      ),
    );
    await _guard(identity, isCurrent);
  });

  Future<SourceProvenanceRow?> provenance(String documentId) => (db.select(
    db.sourceProvenance,
  )..where((r) => r.documentId.equals(documentId))).getSingleOrNull();

  Future<SourceProvenanceRow?> provenanceForLocal(
    String type,
    String localId, {
    String? accountId,
  }) async {
    final document = await findLocalDocument(
      type,
      localId,
      accountId: accountId,
    );
    return document == null ? null : provenance(document.row.documentId);
  }

  /// Only a real local input/authorization path may set [allowPrivate].
  Future<SourceProvenanceRow> setSource({
    required String documentId,
    required String origin,
    String? originAccountId,
    bool allowPrivate = false,
    bool rotateGeneration = true,
  }) async {
    if (!{'local_user', 'cloud'}.contains(origin) ||
        (allowPrivate && origin != 'local_user')) {
      throw StateError('invalid source authority');
    }
    final old = await provenance(documentId);
    final generation = !rotateGeneration && old != null && old.origin == origin
        ? old.sourceGeneration
        : newId();
    await db
        .into(db.sourceProvenance)
        .insertOnConflictUpdate(
          SourceProvenanceCompanion.insert(
            documentId: documentId,
            origin: origin,
            originAccountId: Value(originAccountId),
            sourceGeneration: generation,
            privateConsentGeneration: Value(allowPrivate ? generation : null),
          ),
        );
    return (await provenance(documentId))!;
  }

  Object? _sourceFingerprint(String type, Map<String, Object?>? payload) {
    if (payload == null) return null;
    return switch (type) {
      'configuration' =>
        payload['kind'] == 'subscription'
            ? payload['source']
            : {'format': payload['format'], 'content': payload['content']},
      'policy' => payload['jsonOverride'],
      'node' => {
        'server': payload['server'],
        'port': payload['port'],
        'params': payload['params'],
        'secrets': payload['secrets'],
      },
      'chain' => payload['hops'],
      _ => null,
    };
  }

  Future<void> _remoteProvenance(
    SyncDocumentRow row,
    Map<String, Object?>? payload, {
    Map<String, Object?>? previousPayload,
  }) async {
    if (!{'configuration', 'node', 'chain', 'policy'}.contains(row.type)) {
      return;
    }
    final old = await provenance(row.documentId);
    if (old == null ||
        old.origin != 'cloud' ||
        canonicalSyncJson(_sourceFingerprint(row.type, previousPayload)) !=
            canonicalSyncJson(_sourceFingerprint(row.type, payload))) {
      await setSource(
        documentId: row.documentId,
        origin: 'cloud',
        originAccountId: row.accountId,
      );
    }
  }

  /// Account deletion archives that account's uncertain sync material before
  /// detaching its active scope. Local content and source restrictions remain;
  /// archived requests are recovery material and never an upload source.
  Future<void> detachAccount(String accountId) => db.transaction(() async {
    final docs = await (db.select(
      db.syncDocuments,
    )..where((r) => r.accountId.equals(accountId))).get();
    final metas = await (db.select(
      db.syncMeta,
    )..where((r) => r.accountId.equals(accountId))).get();
    final scope = await (db.select(
      db.syncState,
    )..where((r) => r.accountId.equals(accountId))).getSingleOrNull();
    final rebuild =
        await (db.select(db.syncRebuildEntries)
              ..where((r) => r.accountId.equals(accountId))
              ..limit(1))
            .get();
    final pulling =
        await (db.select(db.syncPullStageEntries)
              ..where((r) => r.accountId.equals(accountId))
              ..limit(1))
            .get();
    if (scope != null ||
        docs.isNotEmpty ||
        metas.isNotEmpty ||
        rebuild.isNotEmpty ||
        pulling.isNotEmpty ||
        await fullPullStage(accountId) != null) {
      // This owns manifest/control and every staged secret before their live
      // owner disappears. It also handles remnants of an earlier incomplete
      // detachment, without duplicating archives when there is no active scope.
      await _archiveScope(accountId, 'account_deleted');
    }
    await (db.update(
      db.syncDocuments,
    )..where((r) => r.accountId.equals(accountId))).write(
      const SyncDocumentsCompanion(
        accountId: Value(null),
        remoteRevision: Value(null),
        remoteEditedAt: Value(null),
        remoteDeleted: Value(null),
        remoteSchemaVersion: Value(null),
        remotePayloadSecretId: Value(null),
        syncGeneration: Value(null),
        pendingMerge: Value(false),
      ),
    );
    await (db.delete(
      db.syncMeta,
    )..where((r) => r.accountId.equals(accountId))).go();
    await (db.delete(
      db.syncRebuildEntries,
    )..where((r) => r.accountId.equals(accountId))).go();
    await (db.delete(
      db.syncPullStageEntries,
    )..where((r) => r.accountId.equals(accountId))).go();
    await (db.delete(
      db.syncPullStages,
    )..where((r) => r.accountId.equals(accountId))).go();
    await (db.delete(
      db.syncState,
    )..where((r) => r.accountId.equals(accountId))).go();
    for (final doc in docs) {
      await secrets.deleteIfUnowned(doc.remotePayloadSecretId);
    }
    for (final meta in metas) {
      await secrets.deleteIfUnowned(meta.pendingEnvelopeSecretId);
      await secrets.deleteIfUnowned(meta.inFlightEnvelopeSecretId);
    }
  });
}
