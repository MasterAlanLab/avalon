import 'package:av_design/av_design.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_error.dart';
import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/file_dialogs.dart';
import '../../services/backup_service.dart';

/// «导出备份…» (PRODUCT_SPEC §5): the password twice, then the system's
/// save dialog.
Future<void> exportBackup(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final password = await showAvPasswordPrompt(
    context,
    title: l.backupPassword,
    message: l.backupPasswordNote,
    placeholder: l.passwordHint,
    confirmPlaceholder: l.passwordAgainHint,
    save: l.exportBackupAction,
    cancel: l.cancel,
    validate: (password, again) =>
        password.length < BackupService.minPasswordLength
        ? l.passwordTooShort
        : (password == again ? null : l.passwordMismatch),
  );
  if (password == null || !context.mounted) return;
  showAvToast(context, l.backupEncrypting);
  final result = await attempt(() async {
    final bytes = await ref.read(backupServiceProvider).export(password);
    return ref
        .read(fileDialogsProvider)
        .save(name: BackupService.fileName(DateTime.now()), bytes: bytes);
  });
  if (!context.mounted) return;
  switch (result) {
    case Ok(value: true):
      showAvToast(context, l.backupExported);
    case Ok():
      break; // The save dialog was cancelled.
    case Err(:final error):
      await showAvNotice(context, title: error.message(l), ok: l.ok);
  }
}

/// «从文件恢复…»: pick the file, its password, confirm, then merge in one
/// go. On any failure nothing on this device changes.
Future<void> restoreBackup(BuildContext context, WidgetRef ref) async {
  final l = AppLocalizations.of(context);
  final PickedFile? file;
  try {
    file = await ref
        .read(fileDialogsProvider)
        .open(maxBytes: BackupService.maxFileBytes);
  } on FileTooLargeException {
    if (context.mounted) {
      await showAvNotice(context, title: l.backupTooLarge, ok: l.ok);
    }
    return;
  }
  if (file == null || !context.mounted) return;
  final password = await showAvPasswordPrompt(
    context,
    title: l.restorePassword,
    message: file.name,
    placeholder: l.passwordHint,
    save: l.reset,
    cancel: l.cancel,
  );
  if (password == null || !context.mounted) return;
  final confirmed = await showAvConfirm(
    context,
    title: l.restoreConfirmTitle,
    message: l.restoreConfirmBody,
    confirm: l.reset,
    cancel: l.cancel,
  );
  if (!confirmed || !context.mounted) return;
  showAvToast(context, l.restoring);
  final bytes = file.bytes;
  final result = await attempt(
    () => ref.read(backupServiceProvider).restore(bytes, password),
  );
  if (!context.mounted) return;
  switch (result) {
    case Ok(:final value):
      await showAvNotice(
        context,
        title: l.restoreDoneTitle,
        message: l.restoreDoneBody(
          value.configurations,
          value.selfNodes,
          value.chains,
        ),
        ok: l.ok,
      );
    case Err(:final error):
      await showAvNotice(context, title: error.message(l), ok: l.ok);
  }
}
