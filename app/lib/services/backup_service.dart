import 'dart:typed_data';

import '../data/backup/backup_codec.dart';
import '../data/backup/backup_repository.dart';
import '../data/vault/secret_store.dart';

/// File backups (PRODUCT_SPEC §5, D18): everything the user made, encrypted
/// with a password. Restoring never connects, logs in or grants anything.
final class BackupService {
  BackupService(
    this._backups,
    this._secrets, {
    required this.appVersion,
    required this.platform,
  });

  final BackupRepository _backups;
  final SecretStore _secrets;
  final String appVersion;

  /// `android`, `ios`, `macos`, `windows` or `linux`.
  final String platform;

  static const minPasswordLength = BackupCodec.minPasswordLength;

  /// A file larger than this cannot be a backup.
  static const maxFileBytes = BackupCodec.maxFileBytes;

  /// `Avalon-2026-10-09.avalonbackup`.
  static String fileName(DateTime now) {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'Avalon-${now.year}-${two(now.month)}-${two(now.day)}'
        '.avalonbackup';
  }

  /// The encrypted backup file. Throws [BackupException] for a password
  /// under 8 characters.
  Future<Uint8List> export(String password) async {
    if (password.length < minPasswordLength) {
      throw const BackupException(BackupErrorCode.passwordTooShort);
    }
    return BackupCodec.seal(
      await _backups.export(appVersion: appVersion, platform: platform),
      password,
    );
  }

  /// Decrypts, checks and merges a backup in one go. Throws
  /// [BackupException]; on any failure the device's data is unchanged.
  Future<RestoreSummary> restore(Uint8List file, String password) async {
    final summary = await _backups.restore(
      await BackupCodec.open(file, password),
    );
    await _secrets.deleteOrphans();
    return summary;
  }
}
