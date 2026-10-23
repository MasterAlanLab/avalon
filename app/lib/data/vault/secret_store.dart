import 'package:drift/drift.dart';

import '../database/database.dart';
import '../ids.dart';
import 'vault.dart';

/// Secret entries in the database (DATA_MODEL §3). Call inside the owning
/// transaction so the owner and its secrets commit together.
base class SecretStore {
  SecretStore(this._db, this._vault);

  final AppDatabase _db;
  final Vault _vault;
  static const _proxyRecoveryId = 'avalon.runtime.system-proxy';

  /// A device-owned recovery record, outside backup and sync projections.
  /// The fixed owner survives orphan cleanup and never enters public JSON.
  Future<Map<String, String>?> systemProxyRecovery() async {
    final row = await (_db.select(
      _db.secrets,
    )..where((s) => s.id.equals(_proxyRecoveryId))).getSingleOrNull();
    return row == null
        ? null
        : _vault.unseal(row.id, row.nonce, row.ciphertext);
  }

  Future<void> saveSystemProxyRecovery(Map<String, String>? value) async {
    if (value == null) {
      await delete(_proxyRecoveryId);
      return;
    }
    final sealed = await _vault.seal(_proxyRecoveryId, value);
    await _db
        .into(_db.secrets)
        .insertOnConflictUpdate(
          SecretsCompanion.insert(
            id: _proxyRecoveryId,
            nonce: sealed.nonce,
            ciphertext: sealed.ciphertext,
            createdAt: nowMs(),
          ),
        );
  }

  /// Stores [secrets] under a new entry; returns its id.
  Future<String> put(Map<String, String> secrets) async {
    final id = newId();
    final sealed = await _vault.seal(id, secrets);
    await _db
        .into(_db.secrets)
        .insert(
          SecretsCompanion.insert(
            id: id,
            nonce: sealed.nonce,
            ciphertext: sealed.ciphertext,
            createdAt: nowMs(),
          ),
        );
    return id;
  }

  /// Throws [VaultLockedException] when the entry cannot be decrypted, and
  /// [StateError] when it does not exist.
  Future<Map<String, String>> get(String id) async {
    final row = await (_db.select(
      _db.secrets,
    )..where((s) => s.id.equals(id))).getSingleOrNull();
    if (row == null) throw StateError('secret $id missing');
    return _vault.unseal(id, row.nonce, row.ciphertext);
  }

  Future<void> delete(String? id) async {
    if (id == null) return;
    await (_db.delete(_db.secrets)..where((s) => s.id.equals(id))).go();
  }

  /// Removes entries no owner refers to (run at start-up, DATA_MODEL §3).
  Future<int> deleteOrphans() => _db.customUpdate(
    'DELETE FROM secrets WHERE id != \'$_proxyRecoveryId\' AND id NOT IN ('
    'SELECT source_secret_id FROM configurations WHERE source_secret_id IS NOT NULL '
    'UNION SELECT secret_id FROM contents '
    'UNION SELECT secret_id FROM self_nodes '
    'UNION SELECT override_secret_id FROM policy WHERE override_secret_id IS NOT NULL '
    'UNION SELECT secret_id FROM device_settings WHERE secret_id IS NOT NULL '
    'UNION SELECT local_payload_secret_id FROM sync_documents WHERE local_payload_secret_id IS NOT NULL '
    'UNION SELECT remote_payload_secret_id FROM sync_documents WHERE remote_payload_secret_id IS NOT NULL '
    'UNION SELECT pending_envelope_secret_id FROM sync_meta WHERE pending_envelope_secret_id IS NOT NULL '
    'UNION SELECT in_flight_envelope_secret_id FROM sync_meta WHERE in_flight_envelope_secret_id IS NOT NULL '
    'UNION SELECT rebuild_manifest_secret_id FROM sync_state WHERE rebuild_manifest_secret_id IS NOT NULL '
    'UNION SELECT rebuild_control_secret_id FROM sync_state WHERE rebuild_control_secret_id IS NOT NULL '
    'UNION SELECT payload_secret_id FROM sync_archives '
    'UNION SELECT secret_id FROM sync_archive_references '
    'UNION SELECT envelope_secret_id FROM sync_rebuild_entries '
    'UNION SELECT record_secret_id FROM sync_pull_stage_entries '
    'UNION SELECT access_secret_id FROM cloud_session '
    'UNION SELECT refresh_secret_id FROM cloud_session)',
    updates: {_db.secrets},
    updateKind: UpdateKind.delete,
  );

  /// Replacing one owner must not delete an entry still held by another slot.
  Future<void> deleteIfUnowned(String? id) async {
    if (id == null || id == _proxyRecoveryId) return;
    await _db.customUpdate(
      'DELETE FROM secrets WHERE id = ? AND id NOT IN ('
      'SELECT source_secret_id FROM configurations WHERE source_secret_id IS NOT NULL '
      'UNION SELECT secret_id FROM contents '
      'UNION SELECT secret_id FROM self_nodes '
      'UNION SELECT override_secret_id FROM policy WHERE override_secret_id IS NOT NULL '
      'UNION SELECT secret_id FROM device_settings WHERE secret_id IS NOT NULL '
      'UNION SELECT access_secret_id FROM cloud_session '
      'UNION SELECT refresh_secret_id FROM cloud_session '
      'UNION SELECT local_payload_secret_id FROM sync_documents WHERE local_payload_secret_id IS NOT NULL '
      'UNION SELECT remote_payload_secret_id FROM sync_documents WHERE remote_payload_secret_id IS NOT NULL '
      'UNION SELECT pending_envelope_secret_id FROM sync_meta WHERE pending_envelope_secret_id IS NOT NULL '
      'UNION SELECT in_flight_envelope_secret_id FROM sync_meta WHERE in_flight_envelope_secret_id IS NOT NULL '
      'UNION SELECT rebuild_manifest_secret_id FROM sync_state WHERE rebuild_manifest_secret_id IS NOT NULL '
      'UNION SELECT rebuild_control_secret_id FROM sync_state WHERE rebuild_control_secret_id IS NOT NULL '
      'UNION SELECT payload_secret_id FROM sync_archives '
      'UNION SELECT secret_id FROM sync_archive_references '
      'UNION SELECT envelope_secret_id FROM sync_rebuild_entries '
      'UNION SELECT record_secret_id FROM sync_pull_stage_entries)',
      variables: [Variable(id)],
      updates: {_db.secrets},
      updateKind: UpdateKind.delete,
    );
  }
}
