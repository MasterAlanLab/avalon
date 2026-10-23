import 'dart:convert';

import 'package:av_core/av_core.dart';
import 'package:drift/drift.dart';

import '../../cloud/sync_models.dart';
import '../database/database.dart';
import '../ids.dart';
import '../vault/content_secrets.dart';
import '../vault/secret_store.dart';
import '../vault/vault.dart';
import 'settings_repository.dart';
import 'sync_repository.dart';

/// Maps encrypted account documents to local business rows. It deliberately
/// bypasses user-edit repositories: remote writes never echo into the outbox.
final class SyncProjection {
  SyncProjection(this.db, this.secrets, this.sync);
  final AppDatabase db;
  final SecretStore secrets;
  final SyncRepository sync;

  Future<bool> _foreignReferences(
    String type,
    String localId,
    String account,
  ) async {
    final refs = <({String type, String id})>[];
    if (type == 'chain') {
      final row = await (db.select(
        db.chains,
      )..where((r) => r.id.equals(localId))).getSingleOrNull();
      if (row != null) {
        for (final raw in jsonDecode(row.hopsJson) as List) {
          final ref = raw as Map;
          if (ref['kind'] == 'source') {
            refs.add((
              type: 'configuration',
              id: ref['configurationId'] as String,
            ));
          }
          if (ref['kind'] == 'selfNode') {
            refs.add((type: 'node', id: ref['id'] as String));
          }
        }
      }
    } else if (type == 'selection') {
      final key = jsonDecode(localId) as List;
      refs.add((type: 'configuration', id: key[0] as String));
      final row =
          await (db.select(db.selections)..where(
                (s) =>
                    s.configurationId.equals(key[0] as String) &
                    s.groupKey.equals(key[1] as String),
              ))
              .getSingleOrNull();
      if (row != null) {
        final ref = jsonDecode(row.memberJson) as Map;
        if (ref['kind'] == 'source') {
          refs.add((
            type: 'configuration',
            id: ref['configurationId'] as String,
          ));
        }
        if (ref['kind'] == 'selfNode') {
          refs.add((type: 'node', id: ref['id'] as String));
        }
        if (ref['kind'] == 'chain') {
          refs.add((type: 'chain', id: ref['id'] as String));
        }
      }
    }
    if (type == 'node' || type == 'chain') {
      for (final m
          in await (db.select(db.memberships)..where(
                (m) => m.ownerKind.equals(type) & m.ownerId.equals(localId),
              ))
              .get()) {
        refs.add((type: 'configuration', id: m.configurationId));
      }
    }
    for (final ref in refs) {
      if (ref.type == 'configuration' && ref.id == 'self') continue;
      final owner = await _owner(ref.type, ref.id);
      if (owner?.row.accountId != null && owner!.row.accountId != account) {
        return true;
      }
      if (owner == null &&
          ref.id.startsWith('cloud:') &&
          !ref.id.startsWith('cloud:$account:')) {
        return true;
      }
    }
    return false;
  }

  Future<void> assertUploadOwner(
    FrozenSyncMutation mutation,
    String account,
  ) async {
    if (!mutation.uploadAllowed) throw const SyncReferenceOwnershipException();
    final document = await sync.document(mutation.documentId);
    if (document == null || document.row.accountId != account) {
      throw const SyncReferenceOwnershipException();
    }
    if (document.row.localId != null &&
        await _foreignReferences(
          document.row.type,
          document.row.localId!,
          account,
        )) {
      throw const SyncReferenceOwnershipException();
    }
  }

  /// Upgrade credential-bearing projections without changing user edit times.
  Future<void> resealCredentials() => db.transaction(() async {
    for (final row in await db.select(db.selfNodes).get()) {
      try {
        final joined = ContentSecrets.join(
          jsonDecode(row.paramsJson),
          await secrets.get(row.secretId),
        );
        final lifted = ContentSecrets.split(joined);
        if (canonicalSyncJson(lifted.public) ==
            canonicalSyncJson(jsonDecode(row.paramsJson))) {
          continue;
        }
        final entry = await secrets.put(lifted.secrets);
        await (db.update(
          db.selfNodes,
        )..where((r) => r.id.equals(row.id))).write(
          SelfNodesCompanion(
            paramsJson: Value(jsonEncode(lifted.public)),
            secretId: Value(entry),
          ),
        );
        await secrets.delete(row.secretId);
      } on VaultLockedException {
        // Preserve the row; its normal read reports the unavailable credential.
      }
    }
    for (final row in await db.select(db.contents).get()) {
      try {
        final joined = ContentSecrets.join(
          jsonDecode(row.modelJson),
          await secrets.get(row.secretId),
        );
        final lifted = ContentSecrets.split(joined);
        if (canonicalSyncJson(lifted.public) ==
            canonicalSyncJson(jsonDecode(row.modelJson))) {
          continue;
        }
        final entry = await secrets.put(lifted.secrets);
        await (db.update(db.contents)..where((r) => r.id.equals(row.id))).write(
          ContentsCompanion(
            modelJson: Value(jsonEncode(lifted.public)),
            secretId: Value(entry),
          ),
        );
        await secrets.delete(row.secretId);
      } on VaultLockedException {
        // Preserve the row; its normal read reports the unavailable credential.
      }
    }
  });

  Future<SyncDocumentSnapshot?> _owner(String type, String localId) async {
    if (type == 'policy') {
      final row = await (db.select(
        db.policyTable,
      )..where((p) => p.id.equals(1))).getSingleOrNull();
      if (row?.documentId != null) return _document(row!.documentId!);
      return _accountSingleton(type, 'policy', await _activeAccount());
    } else if (type == 'selection') {
      final key = jsonDecode(localId) as List;
      final row =
          await (db.select(db.selections)..where(
                (s) =>
                    s.configurationId.equals(key[0] as String) &
                    s.groupKey.equals(key[1] as String),
              ))
              .getSingleOrNull();
      if (row?.documentId != null) return _document(row!.documentId!);
      final parent = key[0] as String;
      final parentOwner = parent == 'self'
          ? null
          : await _owner('configuration', parent);
      final account = parentOwner?.row.accountId ?? await _activeAccount();
      return _accountSingleton(
        type,
        syncSelectionId(
          await _wireId('configuration', parent, account),
          key[1] as String,
        ),
        account,
      );
    }
    final rows = await (db.select(
      db.syncDocuments,
    )..where((d) => d.type.equals(type) & d.localId.equals(localId))).get();
    if (rows.length > 1) throw StateError('ambiguous local Cloud owner');
    return rows.isEmpty ? null : _document(rows.single.documentId);
  }

  Future<String?> _activeAccount() async {
    final row =
        await (db.select(db.cloudSession)
              ..where((r) => r.id.equals(1) & r.loggedIn.equals(true)))
            .getSingleOrNull();
    return row?.accountId;
  }

  Future<SyncDocumentSnapshot?> _accountSingleton(
    String type,
    String recordId,
    String? account,
  ) async {
    if (account == null) return null;
    final row =
        await (db.select(db.syncDocuments)..where(
              (d) =>
                  d.type.equals(type) &
                  d.recordId.equals(recordId) &
                  d.accountId.equals(account),
            ))
            .getSingleOrNull();
    return row == null ? null : _document(row.documentId);
  }

  Future<SyncDocumentSnapshot?> _document(String id) async {
    try {
      return await sync.document(id);
    } on VaultLockedException {
      final row = await (db.select(
        db.syncDocuments,
      )..where((d) => d.documentId.equals(id))).getSingleOrNull();
      return row == null
          ? null
          : SyncDocumentSnapshot(
              row: row,
              localPayload: null,
              remotePayload: null,
            );
    }
  }

  /// Invoked by the business repository inside its existing transaction.
  Future<void> edited(String type, String localId, bool deleted) async {
    try {
      await _edited(type, localId, deleted);
    } on VaultLockedException {
      // Local rename/delete/re-entry remains available after key loss.
      // Preserve unreadable Cloud owners for explicit sync failure reporting.
    }
  }

  Future<void> _edited(String type, String localId, bool deleted) async {
    if (type == 'configuration' && localId == AppDatabase.selfConfigurationId) {
      return;
    }
    final previous = await _owner(type, localId);
    final encoded = deleted
        ? null
        : await _encode(type, localId, previous?.row.accountId);
    final payload = encoded == null
        ? null
        : completeSyncPayload(
            SyncRecordType.values.byName(type),
            encoded,
            validate: false,
          );
    if (!deleted && payload == null) return;
    final recordId =
        previous?.row.recordId ??
        (type == 'policy'
            ? 'policy'
            : type == 'selection'
            ? syncSelectionId(
                payload!['configurationId']! as String,
                payload['groupKey']! as String,
              )
            : localId);
    // Deletion runs before the business row is removed, so that row still has
    // its previous edit time. The tombstone is a new user edit for strict LWW.
    final editedAt = deleted
        ? nowMs()
        : await _editedAt(type, localId) ?? nowMs();
    SyncIdentity? identity;
    try {
      identity = await sync.capture(0);
    } on VaultLockedException {
      // A damaged cloud session cannot prevent local canonical edits/deletion.
    }
    final canEnqueue =
        previous?.row.accountId != null &&
        previous!.row.accountId == identity?.accountId &&
        (await sync.state(previous.row.accountId!)).bootstrapCompleted;
    final uploadAllowed =
        previous?.row.accountId == null ||
        !await _foreignReferences(type, localId, previous!.row.accountId!);
    final owner = await sync.saveLocal(
      documentId: previous?.row.documentId,
      accountId: previous?.row.accountId,
      recordId: recordId,
      type: type,
      localId: localId,
      editedAt: editedAt,
      deleted: deleted,
      payload: payload,
      enqueue: canEnqueue,
      uploadAllowed: uploadAllowed,
    );
    if (type == 'policy') {
      await (db.update(db.policyTable)..where((r) => r.id.equals(1))).write(
        PolicyTableCompanion(
          documentId: Value(owner.row.documentId),
          cloudAccountId: Value(owner.row.accountId),
        ),
      );
    } else if (type == 'selection') {
      final key = jsonDecode(localId) as List;
      await (db.update(db.selections)..where(
            (r) =>
                r.configurationId.equals(key[0] as String) &
                r.groupKey.equals(key[1] as String),
          ))
          .write(
            SelectionsCompanion(
              documentId: Value(owner.row.documentId),
              cloudAccountId: Value(owner.row.accountId),
            ),
          );
    }
  }

  Future<int?> _editedAt(String type, String id) async => switch (type) {
    'configuration' => (await (db.select(
      db.configurations,
    )..where((r) => r.id.equals(id))).getSingleOrNull())?.editedAt,
    'node' => (await (db.select(
      db.selfNodes,
    )..where((r) => r.id.equals(id))).getSingleOrNull())?.editedAt,
    'chain' => (await (db.select(
      db.chains,
    )..where((r) => r.id.equals(id))).getSingleOrNull())?.editedAt,
    'policy' => (await (db.select(
      db.policyTable,
    )..where((r) => r.id.equals(1))).getSingleOrNull())?.editedAt,
    'selection' =>
      (await (db.select(db.selections)..where(
                (r) =>
                    r.configurationId.equals(
                      (jsonDecode(id) as List)[0] as String,
                    ) &
                    r.groupKey.equals((jsonDecode(id) as List)[1] as String),
              ))
              .getSingleOrNull())
          ?.editedAt,
    _ => throw ArgumentError.value(type),
  };

  Future<Map<String, Object?>?> _encode(
    String type,
    String id,
    String? account,
  ) async {
    switch (type) {
      case 'configuration':
        final row = await (db.select(
          db.configurations,
        )..where((r) => r.id.equals(id))).getSingleOrNull();
        if (row == null || row.kind == 'self') return null;
        final common = <String, Object?>{
          'kind': row.kind,
          'name': row.name,
          'autoUpdate': row.kind == 'subscription' && row.autoUpdate,
          'createdAt': row.createdAt,
        };
        if (row.kind == 'subscription') {
          final entry = await secrets.get(row.sourceSecretId!);
          final json =
              SecretCodec.join(jsonDecode(entry['model']!), entry)! as Map;
          final source = SubscriptionSource.fromJson(
            json.cast<String, dynamic>(),
          );
          return {
            ...common,
            'source': {
              'url': source.url.value,
              'headers': {
                for (final e in source.headers.entries) e.key: e.value.value,
              },
            },
          };
        }
        final content = await (db.select(
          db.contents,
        )..where((r) => r.configurationId.equals(id))).getSingle();
        final joined =
            ContentSecrets.join(
                  jsonDecode(content.modelJson),
                  await secrets.get(content.secretId),
                )!
                as Map;
        final model = ConfigContent.fromJson(
          joined.cast<String, dynamic>(),
        ).toJson()..remove('warnings');
        final lifted = SecretCodec.split(model);
        return {
          ...common,
          'format': content.format,
          'content': {'model': lifted.public, 'secrets': lifted.secrets},
        };
      case 'node':
        final row = await (db.select(
          db.selfNodes,
        )..where((r) => r.id.equals(id))).getSingleOrNull();
        if (row == null) return null;
        final joined =
            ContentSecrets.join(
                  jsonDecode(row.paramsJson),
                  await secrets.get(row.secretId),
                )!
                as Map;
        final params = NodeParams.fromJson(joined.cast<String, dynamic>());
        final lifted = SecretCodec.split(params.toJson());
        return {
          'name': row.name,
          'server': row.server,
          'port': row.port,
          'params': lifted.public,
          'secrets': lifted.secrets,
          'createdAt': row.createdAt,
          'memberships': await _memberships('node', id, account),
        };
      case 'chain':
        final row = await (db.select(
          db.chains,
        )..where((r) => r.id.equals(id))).getSingleOrNull();
        if (row == null) return null;
        return {
          'name': row.name,
          'createdAt': row.createdAt,
          'hops': [
            for (final h in jsonDecode(row.hopsJson) as List)
              await _wireMember((h as Map).cast<String, Object?>(), account),
          ],
          'memberships': await _memberships('chain', id, account),
        };
      case 'policy':
        final row = await (db.select(
          db.policyTable,
        )..where((r) => r.id.equals(1))).getSingleOrNull();
        if (row?.editedAt == null) return null;
        return {
          'jsonOverride': row!.overrideSecretId == null
              ? null
              : (await secrets.get(row.overrideSecretId!))['override'],
          'geo': {
            'autoUpdate': row.geoAutoUpdate,
            'interval': row.geoInterval,
            'via': row.geoVia,
          },
        };
      case 'selection':
        final key = jsonDecode(id) as List;
        final row =
            await (db.select(db.selections)..where(
                  (r) =>
                      r.configurationId.equals(key[0] as String) &
                      r.groupKey.equals(key[1] as String),
                ))
                .getSingleOrNull();
        if (row == null || !row.manual) return null;
        return {
          'configurationId': await _wireId(
            'configuration',
            row.configurationId,
            account,
          ),
          'groupKey': row.groupKey,
          'member': await _wireMember(
            (jsonDecode(row.memberJson) as Map).cast<String, Object?>(),
            account,
          ),
        };
      default:
        throw ArgumentError.value(type);
    }
  }

  Future<String> _wireId(String type, String localId, String? account) async {
    if (type == 'configuration' && localId == 'self') return 'self';
    final owner = await _owner(type, localId);
    if (owner != null) {
      return owner.row.recordId;
    }
    // A retained unresolved reference is scoped to the originating account.
    if (account != null && localId.startsWith('cloud:$account:$type:')) {
      return localId.substring('cloud:$account:$type:'.length);
    }
    return localId;
  }

  Future<Map<String, Object?>> _wireMember(
    Map<String, Object?> member,
    String? account,
  ) async => {
    ...member,
    if (member['kind'] == 'source')
      'configurationId': await _wireId(
        'configuration',
        member['configurationId']! as String,
        account,
      ),
    if (member['kind'] == 'selfNode')
      'id': await _wireId('node', member['id']! as String, account),
    if (member['kind'] == 'chain')
      'id': await _wireId('chain', member['id']! as String, account),
  };

  Future<List<Map<String, Object?>>> _memberships(
    String kind,
    String id,
    String? account,
  ) async {
    final projected = <Map<String, Object?>>[
      for (final row in await (db.select(
        db.memberships,
      )..where((m) => m.ownerKind.equals(kind) & m.ownerId.equals(id))).get())
        if (row.configurationId != 'self')
          {
            'configurationId': await _wireId(
              'configuration',
              row.configurationId,
              account,
            ),
            'groupKey': row.groupKey,
          },
    ];
    final previous = await _owner(kind, id);
    // A missing parent has no membership FK projection. Preserve its exact
    // wire reference when a user changes another field of this owner.
    for (final member
        in (previous?.localPayload?['memberships'] as List?) ?? const []) {
      final m = (member as Map).cast<String, Object?>();
      final parent = account == null
          ? m['configurationId'] as String
          : await _localId(
              account,
              'configuration',
              m['configurationId'] as String,
            );
      final exists = await (db.select(
        db.configurations,
      )..where((r) => r.id.equals(parent))).getSingleOrNull();
      if (exists == null &&
          !projected.any((p) => canonicalSyncJson(p) == canonicalSyncJson(m))) {
        projected.add(m);
      }
    }
    return projected;
  }

  /// Seed only business rows. No device preferences, caches or installation
  /// defaults are candidates; singleton documents retain their actual owner.
  Future<void> captureAll() => db.transaction(() async {
    for (final c in await db.select(db.configurations).get()) {
      if (c.kind != 'self') await edited('configuration', c.id, false);
    }
    for (final n in await db.select(db.selfNodes).get()) {
      await edited('node', n.id, false);
    }
    for (final c in await db.select(db.chains).get()) {
      await edited('chain', c.id, false);
    }
    await edited('policy', 'policy', false);
    for (final s in await db.select(db.selections).get()) {
      if (s.manual) {
        await edited(
          'selection',
          jsonEncode([s.configurationId, s.groupKey]),
          false,
        );
      }
    }
  });

  /// Run inside beginRebuild's identity-checked transaction. Binding the chosen
  /// local candidates retains IDs and source restrictions; no staged payload
  /// becomes a normal mirror or an ordinary outbox while rebuildRequired.
  Future<void> prepareRebuild(String accountId) async {
    await captureAll();
    await bootstrap(accountId, matchSubscriptions: false);
  }

  /// First pull finishes before binding anything. Exact URL duplicates match
  /// one to one, with deterministic order and Cloud headers as the winner.
  Future<void> bootstrap(
    String accountId, {
    bool matchSubscriptions = true,
  }) async {
    final all = await sync.documents();
    final locals =
        all
            .where((d) => d.row.accountId == null && !d.row.localDeleted)
            .toList()
          ..sort(
            (a, b) => (a.row.localId ?? a.row.documentId).compareTo(
              b.row.localId ?? b.row.documentId,
            ),
          );
    final remote =
        all
            .where(
              (d) =>
                  d.row.accountId == accountId &&
                  d.row.type == 'configuration' &&
                  d.remotePayload?['kind'] == 'subscription' &&
                  d.row.remoteDeleted == false,
            )
            .toList()
          ..sort((a, b) => a.row.recordId.compareTo(b.row.recordId));
    final consumed = <String>{};
    for (final local in locals) {
      if (!matchSubscriptions) break;
      if (local.row.type != 'configuration' ||
          local.localPayload?['kind'] != 'subscription') {
        continue;
      }
      final url = (local.localPayload!['source'] as Map)['url'];
      SyncDocumentSnapshot? match;
      for (final r in remote) {
        if (!consumed.contains(r.row.documentId) &&
            (r.remotePayload!['source'] as Map)['url'] == url) {
          match = r;
          break;
        }
      }
      if (match == null) continue;
      consumed.add(match.row.documentId);
      final oldAlias = match.row.localId;
      await (db.update(db.syncDocuments)
            ..where((d) => d.documentId.equals(match!.row.documentId)))
          .write(SyncDocumentsCompanion(localId: Value(local.row.localId)));
      // The discarded candidate owns no account outbox; its local identity is
      // now owned by the remote document. Keep all references to that identity.
      await (db.delete(
        db.syncDocuments,
      )..where((d) => d.documentId.equals(local.row.documentId))).go();
      await secrets.deleteIfUnowned(local.row.localPayloadSecretId);
      if (oldAlias != null && oldAlias != local.row.localId) {
        await _deleteProjection('configuration', oldAlias);
      }
      await project((await sync.document(match.row.documentId))!);
    }
    // Bind parents first so children encode aliases in the proper namespace.
    for (final type in [
      'configuration',
      'node',
      'chain',
      'policy',
      'selection',
    ]) {
      for (final local in locals.where((d) => d.row.type == type)) {
        final current = await sync.document(local.row.documentId);
        if (current == null || current.row.accountId != null) continue;
        // An inactive singleton belonging to a detached account is not an
        // eligible input for the next account's effective settings.
        if ((type == 'policy' || type == 'selection') &&
            (await _owner(type, current.row.localId!))?.row.documentId !=
                current.row.documentId) {
          continue;
        }
        if (await _foreignReferences(type, current.row.localId!, accountId)) {
          continue;
        }
        final payload = await _encode(type, current.row.localId!, accountId);
        if (payload == null) continue;
        final recordId = type == 'selection'
            ? syncSelectionId(
                payload['configurationId'] as String,
                payload['groupKey'] as String,
              )
            : current.row.recordId;
        // Only an unsent, unbound candidate can be re-keyed after URL binding.
        if (recordId != current.row.recordId) {
          await (db.update(db.syncDocuments)
                ..where((d) => d.documentId.equals(current.row.documentId)))
              .write(SyncDocumentsCompanion(recordId: Value(recordId)));
        }
        final existing = await sync.findDocument(accountId, recordId);
        if (existing != null) {
          if (current.row.localEditedAt > existing.row.localEditedAt) {
            await sync.saveLocal(
              documentId: existing.row.documentId,
              accountId: accountId,
              recordId: recordId,
              type: type,
              localId: current.row.localId,
              editedAt: current.row.localEditedAt,
              deleted: false,
              payload: completeSyncPayload(
                SyncRecordType.values.byName(type),
                payload,
                validate: false,
              ),
            );
          }
          await (db.delete(
            db.syncDocuments,
          )..where((d) => d.documentId.equals(current.row.documentId))).go();
          await secrets.deleteIfUnowned(current.row.localPayloadSecretId);
          await _setAccount(
            type,
            current.row.localId!,
            accountId,
            existing.row.documentId,
          );
          await project((await sync.document(existing.row.documentId))!);
          continue;
        }
        await sync.saveLocal(
          documentId: current.row.documentId,
          recordId: recordId,
          type: type,
          localId: current.row.localId,
          editedAt: current.row.localEditedAt,
          deleted: false,
          payload: completeSyncPayload(
            SyncRecordType.values.byName(type),
            payload,
            validate: false,
          ),
          enqueue: false,
        );
        await sync.bindDocument(current.row.documentId, accountId);
        await _setAccount(
          type,
          current.row.localId!,
          accountId,
          current.row.documentId,
        );
      }
    }
    await reconcile(accountId);
  }

  Future<void> _setAccount(
    String type,
    String id,
    String account,
    String document,
  ) async {
    switch (type) {
      case 'configuration':
        await (db.update(db.configurations)..where((r) => r.id.equals(id)))
            .write(ConfigurationsCompanion(cloudAccountId: Value(account)));
      case 'node':
        await (db.update(db.selfNodes)..where((r) => r.id.equals(id))).write(
          SelfNodesCompanion(cloudAccountId: Value(account)),
        );
      case 'chain':
        await (db.update(db.chains)..where((r) => r.id.equals(id))).write(
          ChainsCompanion(cloudAccountId: Value(account)),
        );
      case 'policy':
        await (db.update(db.policyTable)..where((r) => r.id.equals(1))).write(
          PolicyTableCompanion(
            cloudAccountId: Value(account),
            documentId: Value(document),
          ),
        );
      case 'selection':
        final key = jsonDecode(id) as List;
        await (db.update(db.selections)..where(
              (r) =>
                  r.configurationId.equals(key[0] as String) &
                  r.groupKey.equals(key[1] as String),
            ))
            .write(
              SelectionsCompanion(
                cloudAccountId: Value(account),
                documentId: Value(document),
              ),
            );
    }
  }

  Future<String> _localId(String account, String type, String wire) async {
    if (type == 'configuration' && wire == 'self') return 'self';
    final doc = await sync.findDocument(account, wire);
    return doc?.row.localId ?? 'cloud:$account:$type:$wire';
  }

  Future<Map<String, Object?>> _localMember(
    Map<Object?, Object?> member,
    String account,
  ) async => {
    ...member.cast<String, Object?>(),
    if (member['kind'] == 'source')
      'configurationId': await _localId(
        account,
        'configuration',
        member['configurationId'] as String,
      ),
    if (member['kind'] == 'selfNode')
      'id': await _localId(account, 'node', member['id'] as String),
    if (member['kind'] == 'chain')
      'id': await _localId(account, 'chain', member['id'] as String),
  };

  /// Revisit canonical references after each page, including owners from
  /// earlier pages whose parent arrived later. No editedAt or dirty changes.
  Future<void> reconcile(String account) async {
    for (final type in [
      'configuration',
      'node',
      'chain',
      'policy',
      'selection',
    ]) {
      for (final doc in await sync.documents(accountId: account)) {
        if (doc.row.type == type) await project(doc);
      }
    }
  }

  Future<void> project(SyncDocumentSnapshot doc) async {
    final row = doc.row;
    final account = row.accountId;
    if (account == null || row.remoteRevision == null) return;
    if ((await sync.state(account)).syncGeneration != row.syncGeneration) {
      throw const StaleSyncIdentity();
    }
    // The repository chose local-vs-remote LWW atomically. A newer unsent edit
    // stays effective; unresolved refs still live in its encrypted document.
    if (row.pendingMerge ||
        (doc.meta?.dirty == true &&
            row.localEditedAt > (row.remoteEditedAt ?? 0))) {
      if (!row.localDeleted &&
          row.localId != null &&
          (row.type == 'node' || row.type == 'chain')) {
        await _projectMemberships(
          doc,
          row.localId!,
          doc.localPayload!['memberships'] as List,
        );
      }
      return;
    }
    final id = row.localId ?? 'cloud:$account:${row.type}:${row.recordId}';
    if (row.localId == null) {
      await (db.update(db.syncDocuments)
            ..where((d) => d.documentId.equals(row.documentId)))
          .write(SyncDocumentsCompanion(localId: Value(id)));
    }
    if (row.localDeleted) {
      await _deleteProjection(row.type, id, documentId: row.documentId);
      return;
    }
    final p = doc.localPayload;
    if (p == null) return;
    final at = row.localEditedAt;
    switch (row.type) {
      case 'configuration':
        final provenance = await (db.select(
          db.sourceProvenance,
        )..where((r) => r.documentId.equals(row.documentId))).getSingleOrNull();
        final old = await (db.select(
          db.configurations,
        )..where((r) => r.id.equals(id))).getSingleOrNull();
        final previous = old == null
            ? null
            : await _encode('configuration', id, account);
        final previousSource = previous == null
            ? null
            : previous['kind'] == 'subscription'
            ? previous['source']
            : previous['content'];
        final nextSource = p['kind'] == 'subscription'
            ? p['source']
            : p['content'];
        if (old != null &&
            old.kind == p['kind'] &&
            canonicalSyncJson(previousSource) ==
                canonicalSyncJson(nextSource)) {
          String? refreshedSource;
          if (provenance?.origin == 'cloud' && old.sourceSecretId != null) {
            final sealed = await secrets.get(old.sourceSecretId!);
            if (sealed['cloudGeneration'] != provenance!.sourceGeneration) {
              refreshedSource = await secrets.put({
                ...sealed,
                'cloudGeneration': provenance.sourceGeneration,
              });
            }
          }
          await (db.update(
            db.configurations,
          )..where((r) => r.id.equals(id))).write(
            ConfigurationsCompanion(
              name: Value(p['name'] as String),
              autoUpdate: Value(p['autoUpdate'] as bool),
              editedAt: Value(at),
              cloudAccountId: Value(account),
              sourceSecretId: refreshedSource == null
                  ? const Value.absent()
                  : Value(refreshedSource),
            ),
          );
          if (refreshedSource != null) await secrets.delete(old.sourceSecretId);
          return;
        }
        String? sourceSecret;
        if (p['kind'] == 'subscription') {
          final source = p['source']! as Map;
          final model = SubscriptionSource(
            url: Secret(source['url'] as String),
            headers: {
              for (final e in (source['headers'] as Map).entries)
                e.key as String: Secret(e.value as String),
            },
          );
          final lifted = SecretCodec.split(model.toJson());
          sourceSecret = await secrets.put({
            ...lifted.secrets,
            'model': jsonEncode(lifted.public),
            if (provenance?.origin == 'cloud')
              'cloudGeneration': provenance!.sourceGeneration,
          });
        }
        final contents = await (db.select(
          db.contents,
        )..where((r) => r.configurationId.equals(id))).get();
        await (db.delete(
          db.contents,
        )..where((r) => r.configurationId.equals(id))).go();
        for (final c in contents) {
          await secrets.delete(c.secretId);
        }
        await db
            .into(db.configurations)
            .insertOnConflictUpdate(
              ConfigurationsCompanion.insert(
                id: id,
                kind: p['kind'] as String,
                name: p['name'] as String,
                sourceSecretId: Value(sourceSecret),
                sourceDisplay: Value(
                  p['kind'] == 'subscription'
                      ? Uri.parse((p['source'] as Map)['url'] as String).host
                      : null,
                ),
                autoUpdate: Value(p['autoUpdate'] as bool),
                createdAt: p['createdAt'] as int,
                editedAt: at,
                cloudAccountId: Value(account),
                contentId: const Value(null),
                lastSuccessAt: const Value(null),
                lastAttemptAt: const Value(null),
                lastError: const Value(null),
                usageUpload: const Value(null),
                usageDownload: const Value(null),
                usageTotal: const Value(null),
                expireAt: const Value(null),
              ),
            );
        await secrets.delete(old?.sourceSecretId);
        if (p['kind'] == 'file') {
          final c = p['content'] as Map;
          final model = SecretCodec.join(
            c['model'],
            (c['secrets'] as Map).cast<String, String>(),
          );
          final lifted = ContentSecrets.split(model);
          final contentId = newId();
          await db
              .into(db.contents)
              .insert(
                ContentsCompanion.insert(
                  id: contentId,
                  configurationId: id,
                  format: p['format'] as String,
                  modelJson: jsonEncode(lifted.public),
                  secretId: await secrets.put(lifted.secrets),
                  nodeCount: ((c['model'] as Map)['nodes'] as List).length,
                  digest: 'cloud:${row.remoteRevision}',
                  warningsJson: '[]',
                  createdAt: nowMs(),
                ),
              );
          await (db.update(db.configurations)..where((r) => r.id.equals(id)))
              .write(ConfigurationsCompanion(contentId: Value(contentId)));
        }
        // The storage verdict owns provenance. Applying our own acknowledged
        // mutation does not convert a locally authorized source into Cloud.
        if (provenance == null) {
          await sync.setSource(
            documentId: row.documentId,
            origin: 'local_user',
            allowPrivate: true,
          );
        }
      case 'node':
        final old = await (db.select(
          db.selfNodes,
        )..where((r) => r.id.equals(id))).getSingleOrNull();
        final joined = SecretCodec.join(
          p['params'],
          (p['secrets'] as Map).cast<String, String>(),
        );
        final lifted = ContentSecrets.split(joined);
        await db
            .into(db.selfNodes)
            .insertOnConflictUpdate(
              SelfNodesCompanion.insert(
                id: id,
                name: p['name'] as String,
                server: p['server'] as String,
                port: p['port'] as int,
                protocol: (p['params'] as Map)['protocol'] as String,
                paramsJson: jsonEncode(lifted.public),
                secretId: await secrets.put(lifted.secrets),
                createdAt: p['createdAt'] as int,
                editedAt: at,
                cloudAccountId: Value(account),
              ),
            );
        await secrets.delete(old?.secretId);
        await _projectMemberships(doc, id, p['memberships'] as List);
      case 'chain':
        await db
            .into(db.chains)
            .insertOnConflictUpdate(
              ChainsCompanion.insert(
                id: id,
                name: Value(p['name'] as String?),
                hopsJson: jsonEncode([
                  for (final h in p['hops'] as List)
                    await _localMember(h as Map, account),
                ]),
                createdAt: p['createdAt'] as int,
                editedAt: at,
                cloudAccountId: Value(account),
              ),
            );
        await _projectMemberships(doc, id, p['memberships'] as List);
      case 'policy':
        final old = await (db.select(
          db.policyTable,
        )..where((r) => r.id.equals(1))).getSingleOrNull();
        final geo = p['geo'] as Map;
        final override = p['jsonOverride'] as String?;
        await db
            .into(db.policyTable)
            .insertOnConflictUpdate(
              PolicyTableCompanion.insert(
                id: const Value(1),
                geoAutoUpdate: geo['autoUpdate'] as bool,
                geoInterval: geo['interval'] as String,
                geoVia: geo['via'] as String,
                overrideSecretId: Value(
                  override == null
                      ? null
                      : await secrets.put({'override': override}),
                ),
                editedAt: Value(at),
                cloudAccountId: Value(account),
                documentId: Value(row.documentId),
              ),
            );
        await secrets.delete(old?.overrideSecretId);
      case 'selection':
        final parent = await _localId(
          account,
          'configuration',
          p['configurationId'] as String,
        );
        if (await (db.select(
              db.configurations,
            )..where((r) => r.id.equals(parent))).getSingleOrNull() ==
            null) {
          return;
        }
        final group = p['groupKey'] as String;
        await db
            .into(db.selections)
            .insertOnConflictUpdate(
              SelectionsCompanion.insert(
                configurationId: parent,
                groupKey: group,
                memberJson: jsonEncode(
                  await _localMember(p['member'] as Map, account),
                ),
                manual: true,
                editedAt: at,
                cloudAccountId: Value(account),
                documentId: Value(row.documentId),
              ),
            );
        await (db.update(
          db.syncDocuments,
        )..where((d) => d.documentId.equals(row.documentId))).write(
          SyncDocumentsCompanion(localId: Value(jsonEncode([parent, group]))),
        );
    }
  }

  Future<void> _projectMemberships(
    SyncDocumentSnapshot doc,
    String id,
    List<Object?> members,
  ) async {
    await (db.delete(db.memberships)..where(
          (r) => r.ownerKind.equals(doc.row.type) & r.ownerId.equals(id),
        ))
        .go();
    for (final m in members.cast<Map<Object?, Object?>>()) {
      final parent = await _localId(
        doc.row.accountId!,
        'configuration',
        m['configurationId'] as String,
      );
      if (await (db.select(
            db.configurations,
          )..where((r) => r.id.equals(parent))).getSingleOrNull() ==
          null) {
        continue;
      }
      await db
          .into(db.memberships)
          .insert(
            MembershipsCompanion.insert(
              ownerKind: doc.row.type,
              ownerId: id,
              configurationId: parent,
              groupKey: m['groupKey'] as String,
              createdAt: doc.row.localEditedAt,
            ),
          );
    }
  }

  Future<void> _deleteProjection(
    String type,
    String id, {
    String? documentId,
  }) async {
    switch (type) {
      case 'configuration':
        final row = await (db.select(
          db.configurations,
        )..where((r) => r.id.equals(id))).getSingleOrNull();
        for (final c in await (db.select(
          db.contents,
        )..where((r) => r.configurationId.equals(id))).get()) {
          await secrets.delete(c.secretId);
        }
        await (db.delete(
          db.configurations,
        )..where((r) => r.id.equals(id))).go();
        await secrets.delete(row?.sourceSecretId);
        await SettingsRepository(db, secrets).updateDevice(
          (device) => device.selectedConfigurationId == id
              ? device.copyWith(selectedConfigurationId: null)
              : device,
        );
      // RuntimeCoordinator retains the running plan when no selected config
      // can be compiled; stopping or selecting another remains explicit.
      case 'node':
        final row = await (db.select(
          db.selfNodes,
        )..where((r) => r.id.equals(id))).getSingleOrNull();
        await (db.delete(db.selfNodes)..where((r) => r.id.equals(id))).go();
        await secrets.delete(row?.secretId);
        await (db.delete(db.memberships)
              ..where((r) => r.ownerKind.equals('node') & r.ownerId.equals(id)))
            .go();
      case 'chain':
        await (db.delete(db.chains)..where((r) => r.id.equals(id))).go();
        await (db.delete(
              db.memberships,
            )..where((r) => r.ownerKind.equals('chain') & r.ownerId.equals(id)))
            .go();
      case 'selection':
        if (documentId != null) {
          await (db.delete(
            db.selections,
          )..where((r) => r.documentId.equals(documentId))).go();
        }
      case 'policy':
        final old =
            await (db.select(db.policyTable)..where(
                  (r) => r.id.equals(1) & r.documentId.equals(documentId ?? ''),
                ))
                .getSingleOrNull();
        if (old != null) {
          await (db.delete(db.policyTable)..where((r) => r.id.equals(1))).go();
          await secrets.delete(old.overrideSecretId);
        }
    }
  }
}

final class SyncReferenceOwnershipException implements Exception {
  const SyncReferenceOwnershipException();
  @override
  String toString() => 'SyncReferenceOwnershipException';
}
