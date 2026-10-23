import 'dart:convert';
import 'dart:math';

import 'package:av_core/av_core.dart';
import 'package:drift/drift.dart';

import '../database/database.dart';
import '../ids.dart';
import '../vault/secret_store.dart';
import 'local_sync_edit.dart';

/// Device settings and the synced policy (DATA_MODEL §1.2). Both are single
/// rows created with the PRODUCT_SPEC §4 defaults on first read.
final class SettingsRepository {
  SettingsRepository(this._db, this._secrets, {this.onSyncEdit});

  final LocalSyncEdit? onSyncEdit;
  final AppDatabase _db;
  final SecretStore _secrets;

  Stream<DeviceSettings> watchDevice() =>
      (_db.select(
        _db.deviceSettingsTable,
      )..where((s) => s.id.equals(1))).watch().asyncMap((rows) async {
        if (rows.isEmpty) return device();
        return _decodeDevice(rows.single);
      });

  Future<DeviceSettings> device() async {
    final row = await (_db.select(
      _db.deviceSettingsTable,
    )..where((s) => s.id.equals(1))).getSingleOrNull();
    if (row != null) return _decodeDevice(row);
    return _db.transaction(() async {
      // A random Clash API key on first launch (PRODUCT_SPEC §3.10).
      final settings = DeviceSettings(clashApiSecret: Secret(_randomSecret()));
      await _writeDevice(settings, previousSecretId: null);
      return settings;
    });
  }

  /// Read-modify-write in one transaction.
  Future<DeviceSettings> updateDevice(
    DeviceSettings Function(DeviceSettings current) change,
  ) {
    return _db.transaction(() async {
      final current = await device();
      final next = change(current);
      final row = await (_db.select(
        _db.deviceSettingsTable,
      )..where((s) => s.id.equals(1))).getSingle();
      await _writeDevice(next, previousSecretId: row.secretId);
      return next;
    });
  }

  /// A fresh random Clash API key (PRODUCT_SPEC §3.10).
  Future<DeviceSettings> regenerateClashSecret() =>
      updateDevice((s) => s.copyWith(clashApiSecret: Secret(_randomSecret())));

  Future<DeviceSettings> _decodeDevice(DeviceSettingsRow row) async {
    final secrets = row.secretId == null
        ? const <String, String>{}
        : await _secrets.get(row.secretId!);
    final json = SecretCodec.join(jsonDecode(row.json), secrets);
    return DeviceSettings.fromJson(json! as Map<String, dynamic>);
  }

  Future<void> _writeDevice(
    DeviceSettings settings, {
    required String? previousSecretId,
  }) async {
    final (:public, :secrets) = SecretCodec.split(settings.toJson());
    final secretId = secrets.isEmpty ? null : await _secrets.put(secrets);
    await _db
        .into(_db.deviceSettingsTable)
        .insertOnConflictUpdate(
          DeviceSettingsTableCompanion.insert(
            id: const Value(1),
            json: jsonEncode(public),
            secretId: Value(secretId),
            editedAt: nowMs(),
          ),
        );
    await _secrets.delete(previousSecretId);
  }

  Stream<Policy> watchPolicy() =>
      (_db.select(
        _db.policyTable,
      )..where((p) => p.id.equals(1))).watch().asyncMap((rows) async {
        if (rows.isEmpty) return const Policy();
        return _decodePolicy(rows.single);
      });

  Future<Policy> policy() async {
    final row = await (_db.select(
      _db.policyTable,
    )..where((p) => p.id.equals(1))).getSingleOrNull();
    return row == null ? const Policy() : _decodePolicy(row);
  }

  Future<bool> isCloudOrigin() async {
    final row = await (_db.select(
      _db.policyTable,
    )..where((r) => r.id.equals(1))).getSingleOrNull();
    if (row?.documentId == null) return false;
    final provenance = await (_db.select(
      _db.sourceProvenance,
    )..where((r) => r.documentId.equals(row!.documentId!))).getSingleOrNull();
    return provenance?.origin == 'cloud';
  }

  Future<Policy> updatePolicy(Policy Function(Policy current) change) {
    return _db.transaction(() async {
      final row = await (_db.select(
        _db.policyTable,
      )..where((p) => p.id.equals(1))).getSingleOrNull();
      final current = row == null ? const Policy() : await _decodePolicy(row);
      final next = change(current);
      final override = next.jsonOverride;
      final secretId = override == null || override.isEmpty
          ? null
          : await _secrets.put({'override': override.value});
      await _db
          .into(_db.policyTable)
          .insertOnConflictUpdate(
            PolicyTableCompanion.insert(
              id: const Value(1),
              overrideSecretId: Value(secretId),
              geoAutoUpdate: next.geoAutoUpdate,
              geoInterval: next.geoInterval.name,
              geoVia: next.geoVia.name,
              editedAt: Value(nowMs()),
              cloudAccountId: Value(row?.cloudAccountId),
              documentId: Value(row?.documentId),
            ),
          );
      await _secrets.delete(row?.overrideSecretId);
      await onSyncEdit?.call('policy', 'policy', false);
      return next;
    });
  }

  Future<Policy> _decodePolicy(PolicyRow row) async => Policy(
    jsonOverride: row.overrideSecretId == null
        ? null
        : Secret((await _secrets.get(row.overrideSecretId!))['override']!),
    geoAutoUpdate: row.geoAutoUpdate,
    geoInterval: GeoInterval.values.byName(row.geoInterval),
    geoVia: DownloadVia.values.byName(row.geoVia),
  );

  static String _randomSecret() {
    final r = Random.secure();
    return base64Url
        .encode(List<int>.generate(24, (_) => r.nextInt(256)))
        .replaceAll('=', '');
  }
}
