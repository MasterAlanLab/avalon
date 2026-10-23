import 'dart:convert';

import 'package:av_core/av_core.dart';
import 'package:drift/drift.dart';

import '../database/database.dart';
import '../ids.dart';
import '../repositories/local_sync_edit.dart';
import '../vault/content_secrets.dart';
import '../vault/secret_store.dart';
import 'backup_codec.dart';

/// What a restore brought in.
final class RestoreSummary {
  const RestoreSummary({
    required this.configurations,
    required this.selfNodes,
    required this.chains,
  });

  /// Imported configurations (not counting 「自建节点」).
  final int configurations;
  final int selfNodes;
  final int chains;
}

/// The plaintext of a backup (DATA_MODEL §6): everything a user made, with
/// the secrets it needs, and none of this device's identity. Rows keep
/// their column names; the Cloud binding of a row is not part of a backup.
final class BackupRepository {
  BackupRepository(this._db, this._secrets, {this.onSyncEdit});

  final LocalSyncEdit? onSyncEdit;

  static const format = 'avalon-backup';
  static const schema = 1;
  static const maxConfigurations = 1000;
  static const maxNodes = 50000;

  final AppDatabase _db;
  final SecretStore _secrets;

  static Map<String, Object?> _row(Map<String, dynamic> json) =>
      Map<String, Object?>.of(json)
        ..remove('cloudAccountId')
        ..remove('documentId');

  /// Reads everything in one transaction, secrets decrypted.
  Future<Map<String, Object?>> export({
    required String appVersion,
    required String platform,
  }) => _db.transaction(() async {
    final secrets = <String, Map<String, String>>{};
    Future<void> need(String? id) async {
      if (id != null) secrets[id] = await _secrets.get(id);
    }

    final configurations = await _db.select(_db.configurations).get();
    final contents = await _db.select(_db.contents).get();
    final nodes = await _db.select(_db.selfNodes).get();
    final chains = await _db.select(_db.chains).get();
    final memberships = await _db.select(_db.memberships).get();
    final selections = await _db.select(_db.selections).get();
    final settings = await (_db.select(
      _db.deviceSettingsTable,
    )..where((s) => s.id.equals(1))).getSingleOrNull();
    final policy = await (_db.select(
      _db.policyTable,
    )..where((p) => p.id.equals(1))).getSingleOrNull();

    for (final c in configurations) {
      await need(c.sourceSecretId);
    }
    for (final c in contents) {
      await need(c.secretId);
    }
    for (final n in nodes) {
      await need(n.secretId);
    }
    await need(settings?.secretId);
    await need(policy?.overrideSecretId);

    // Schema 1 readers join SecretCodec markers only. URLs and usernames
    // must therefore remain Strings in the in-memory backup projection;
    // the backup file seals the entire document with the user's password.
    // Restore lifts these fields back into this device's encrypted storage.
    Map<String, Object?> legacyProjection(
      Map<String, dynamic> row,
      String field,
      String secretId,
    ) {
      final lifted = SecretCodec.split(
        ContentSecrets.join(
          jsonDecode(row[field] as String),
          secrets[secretId]!,
        ),
      );
      secrets[secretId] = lifted.secrets;
      return _row(row)..[field] = jsonEncode(lifted.public);
    }

    return {
      'format': format,
      'schema': schema,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'app': {'version': appVersion, 'platform': platform},
      'configurations': [for (final r in configurations) _row(r.toJson())],
      'contents': [
        for (final r in contents)
          legacyProjection(r.toJson(), 'modelJson', r.secretId),
      ],
      'selfNodes': [
        for (final r in nodes)
          legacyProjection(r.toJson(), 'paramsJson', r.secretId),
      ],
      'chains': [for (final r in chains) _row(r.toJson())],
      'memberships': [for (final r in memberships) _row(r.toJson())],
      'selections': [for (final r in selections) _row(r.toJson())],
      'policy': policy == null ? null : _row(policy.toJson()),
      'deviceSettings': settings == null ? null : _row(settings.toJson()),
      // No rule resources: they are a download cache (D86).
      'secrets': secrets,
    };
  });

  /// Merges a decrypted backup (D18) in one transaction: objects with the
  /// same id are replaced, others are added, what only this device has
  /// stays, and the settings are replaced as a whole. Secrets are sealed
  /// again under this device's key. Throws [BackupException] before
  /// anything is written when the backup is not usable.
  Future<RestoreSummary> restore(Map<String, Object?> backup) async {
    final parsed = _parse(backup);
    return _db.transaction(() async {
      // A secret of the backup, sealed here under a new id.
      Future<String?> reseal(String? id) async {
        if (id == null) return null;
        final values = parsed.secrets[id];
        if (values == null) {
          throw const BackupException(BackupErrorCode.malformed);
        }
        return _secrets.put(values);
      }

      for (final c in parsed.configurations) {
        final old = await (_db.select(
          _db.configurations,
        )..where((x) => x.id.equals(c.id))).getSingleOrNull();
        // The replaced configuration's content and secrets go with it.
        for (final content in await (_db.select(
          _db.contents,
        )..where((x) => x.configurationId.equals(c.id))).get()) {
          await _secrets.delete(content.secretId);
        }
        await (_db.delete(
          _db.contents,
        )..where((x) => x.configurationId.equals(c.id))).go();
        await _db
            .into(_db.configurations)
            .insertOnConflictUpdate(
              c
                  .toCompanion(false)
                  .copyWith(
                    sourceSecretId: Value(await reseal(c.sourceSecretId)),
                    cloudAccountId: const Value.absent(),
                    editedAt: Value(nowMs()),
                  ),
            );
        await _secrets.delete(old?.sourceSecretId);
      }
      for (final c in parsed.contents) {
        final lifted = ContentSecrets.split(
          ContentSecrets.join(
            jsonDecode(c.modelJson),
            parsed.secrets[c.secretId]!,
          ),
        );
        await _db
            .into(_db.contents)
            .insert(
              c
                  .toCompanion(false)
                  .copyWith(
                    modelJson: Value(jsonEncode(lifted.public)),
                    secretId: Value(await _secrets.put(lifted.secrets)),
                  ),
            );
      }
      for (final n in parsed.selfNodes) {
        final lifted = ContentSecrets.split(
          ContentSecrets.join(
            jsonDecode(n.paramsJson),
            parsed.secrets[n.secretId]!,
          ),
        );
        final old = await (_db.select(
          _db.selfNodes,
        )..where((x) => x.id.equals(n.id))).getSingleOrNull();
        await _db
            .into(_db.selfNodes)
            .insertOnConflictUpdate(
              n
                  .toCompanion(false)
                  .copyWith(
                    paramsJson: Value(jsonEncode(lifted.public)),
                    secretId: Value(await _secrets.put(lifted.secrets)),
                    cloudAccountId: const Value.absent(),
                    editedAt: Value(nowMs()),
                  ),
            );
        await _secrets.delete(old?.secretId);
      }
      for (final c in parsed.chains) {
        await _db
            .into(_db.chains)
            .insertOnConflictUpdate(
              c
                  .toCompanion(false)
                  .copyWith(
                    cloudAccountId: const Value.absent(),
                    editedAt: Value(nowMs()),
                  ),
            );
      }
      final known = {
        for (final c in await _db.select(_db.configurations).get()) c.id,
      };
      for (final m in parsed.memberships) {
        if (!known.contains(m.configurationId)) continue;
        await _db
            .into(_db.memberships)
            .insert(m.toCompanion(false), mode: InsertMode.insertOrIgnore);
      }
      for (final s in parsed.selections) {
        if (!known.contains(s.configurationId)) continue;
        final existing =
            await (_db.select(_db.selections)..where(
                  (r) =>
                      r.configurationId.equals(s.configurationId) &
                      r.groupKey.equals(s.groupKey),
                ))
                .getSingleOrNull();
        await _db
            .into(_db.selections)
            .insertOnConflictUpdate(
              s
                  .toCompanion(false)
                  .copyWith(
                    cloudAccountId: const Value.absent(),
                    documentId: Value(existing?.documentId),
                    editedAt: Value(nowMs()),
                  ),
            );
      }

      // Settings are replaced as a whole.
      final settings = parsed.deviceSettings;
      if (settings != null) {
        final old = await (_db.select(
          _db.deviceSettingsTable,
        )..where((x) => x.id.equals(1))).getSingleOrNull();
        await _db
            .into(_db.deviceSettingsTable)
            .insertOnConflictUpdate(
              settings
                  .toCompanion(false)
                  .copyWith(
                    id: const Value(1),
                    secretId: Value(await reseal(settings.secretId)),
                    editedAt: Value(nowMs()),
                  ),
            );
        await _secrets.delete(old?.secretId);
      }
      final policy = parsed.policy;
      if (policy != null) {
        final old = await (_db.select(
          _db.policyTable,
        )..where((x) => x.id.equals(1))).getSingleOrNull();
        await _db
            .into(_db.policyTable)
            .insertOnConflictUpdate(
              policy
                  .toCompanion(false)
                  .copyWith(
                    id: const Value(1),
                    overrideSecretId: Value(
                      await reseal(policy.overrideSecretId),
                    ),
                    editedAt: Value(nowMs()),
                    cloudAccountId: const Value.absent(),
                    documentId: Value(old?.documentId),
                  ),
            );
        await _secrets.delete(old?.overrideSecretId);
      }
      for (final c in parsed.configurations) {
        if (c.kind != 'self') {
          await onSyncEdit?.call('configuration', c.id, false);
        }
      }
      for (final n in parsed.selfNodes) {
        await onSyncEdit?.call('node', n.id, false);
      }
      for (final c in parsed.chains) {
        await onSyncEdit?.call('chain', c.id, false);
      }
      if (parsed.policy != null) {
        await onSyncEdit?.call('policy', 'policy', false);
      }
      for (final s in parsed.selections) {
        if (s.manual && known.contains(s.configurationId)) {
          await onSyncEdit?.call(
            'selection',
            jsonEncode([s.configurationId, s.groupKey]),
            false,
          );
        }
      }

      return RestoreSummary(
        configurations: parsed.configurations
            .where((c) => c.kind != ConfigurationKind.self.name)
            .length,
        selfNodes: parsed.selfNodes.length,
        chains: parsed.chains.length,
      );
    });
  }

  /// Checks format, version, limits and shapes; nothing is written.
  static _Parsed _parse(Map<String, Object?> b) {
    if (b['format'] != format) {
      throw const BackupException(BackupErrorCode.notABackup);
    }
    final version = b['schema'];
    if (version is! int || version < 1) {
      throw const BackupException(BackupErrorCode.malformed);
    }
    if (version > schema) {
      throw const BackupException(BackupErrorCode.unsupportedVersion);
    }
    try {
      List<Map<String, dynamic>> rows(String key) => [
        for (final r in (b[key] as List?) ?? const <Object?>[])
          (r! as Map).cast<String, dynamic>(),
      ];
      Map<String, dynamic>? row(String key) =>
          (b[key] as Map?)?.cast<String, dynamic>();
      // Embedded JSON must at least be JSON.
      void json(String text) => jsonDecode(text);

      final configurations = [
        for (final r in rows('configurations')) ConfigurationRow.fromJson(r),
      ];
      final contents = [
        for (final r in rows('contents')) ContentRow.fromJson(r),
      ];
      final selfNodes = [
        for (final r in rows('selfNodes')) SelfNodeRow.fromJson(r),
      ];
      final chains = [for (final r in rows('chains')) ChainRow.fromJson(r)];
      final nodes =
          contents.fold<int>(0, (n, c) => n + c.nodeCount) + selfNodes.length;
      if (configurations.length > maxConfigurations || nodes > maxNodes) {
        throw const BackupException(BackupErrorCode.tooLarge);
      }
      final ids = {for (final c in configurations) c.id};
      for (final c in configurations) {
        ConfigurationKind.values.byName(c.kind);
      }
      for (final c in contents) {
        if (!ids.contains(c.configurationId)) {
          throw const FormatException('content without configuration');
        }
        ContentFormat.values.byName(c.format);
        json(c.modelJson);
        json(c.warningsJson);
      }
      for (final n in selfNodes) {
        Protocol.values.byName(n.protocol);
        json(n.paramsJson);
      }
      for (final c in chains) {
        json(c.hopsJson);
      }
      final selections = [
        for (final r in rows('selections')) SelectionRow.fromJson(r),
      ];
      for (final s in selections) {
        json(s.memberJson);
      }
      final settings = row('deviceSettings');
      final settingsRow = settings == null
          ? null
          : DeviceSettingsRow.fromJson({...settings, 'id': 1});
      final secrets = {
        for (final e in ((b['secrets'] as Map?) ?? const {}).entries)
          e.key as String: (e.value as Map).cast<String, String>(),
      };
      if (settingsRow != null) {
        // The stored JSON holds placeholders where its secrets were.
        DeviceSettings.fromJson(
          SecretCodec.join(
                jsonDecode(settingsRow.json),
                secrets[settingsRow.secretId] ?? const {},
              )!
              as Map<String, dynamic>,
        );
      }
      final policy = row('policy');
      final policyRow = policy == null
          ? null
          : PolicyRow.fromJson({...policy, 'id': 1});
      if (policyRow != null) {
        GeoInterval.values.byName(policyRow.geoInterval);
        DownloadVia.values.byName(policyRow.geoVia);
      }
      return _Parsed(
        configurations: configurations,
        contents: contents,
        selfNodes: selfNodes,
        chains: chains,
        memberships: [
          for (final r in rows('memberships')) MembershipRow.fromJson(r),
        ],
        selections: selections,
        deviceSettings: settingsRow,
        policy: policyRow,
        // A backup from before D86 lists rule resources; they are a cache
        // and are not restored.
        secrets: secrets,
      );
    } on BackupException {
      rethrow;
      // Wrong types and missing fields surface as errors, not exceptions.
      // ignore: avoid_catches_without_on_clauses
    } catch (_) {
      throw const BackupException(BackupErrorCode.malformed);
    }
  }
}

final class _Parsed {
  const _Parsed({
    required this.configurations,
    required this.contents,
    required this.selfNodes,
    required this.chains,
    required this.memberships,
    required this.selections,
    required this.deviceSettings,
    required this.policy,
    required this.secrets,
  });

  final List<ConfigurationRow> configurations;
  final List<ContentRow> contents;
  final List<SelfNodeRow> selfNodes;
  final List<ChainRow> chains;
  final List<MembershipRow> memberships;
  final List<SelectionRow> selections;
  final DeviceSettingsRow? deviceSettings;
  final PolicyRow? policy;
  final Map<String, Map<String, String>> secrets;
}
