import 'package:av_core/av_core.dart';

import '../data/backup/backup_codec.dart';
import '../data/ids.dart';
import '../data/repositories/self_content_repository.dart';
import '../data/vault/vault.dart';
import '../platform/file_dialogs.dart';
import 'download/fetcher.dart';

/// A short, non-secret code for a failure: stored as a card's last error and
/// mapped to localized text by the UI (`app/app_error.dart`). Fields are
/// paths into the content (`proxies.3.server`), never values.
String errorCode(Object e) => switch (e) {
  FetchException(:final code, :final status) =>
    status == null ? 'fetch.${code.name}' : 'fetch.${code.name}.$status',
  ImportException(:final code, :final field) =>
    field == null ? 'import.${code.name}' : 'import.${code.name}.$field',
  VaultLockedException() => 'vault.locked',
  EditConflictException() => 'edit.conflict',
  NodeInUseException() => 'node.inUse',
  BackupException(:final code) => 'backup.${code.name}',
  FileTooLargeException() => 'fetch.tooLarge',
  _ => 'unknown',
};
