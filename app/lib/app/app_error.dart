import 'package:av_core/av_core.dart';

import '../l10n/app_localizations.dart';
import '../services/download/fetcher.dart';
import '../services/error_code.dart';
import 'log.dart';

/// The outcome of a ViewModel command.
sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.error);

  final AppError error;
}

/// A failure shown on the page that caused it. [code] is the redaction-safe
/// form from [errorCode]; [message] turns it into one localized sentence.
final class AppError {
  const AppError(this.code);

  factory AppError.from(Object error) => AppError(
    error is CompileException && error.subject == 'cloud.networkGuard'
        ? 'cloud.networkGuard'
        : errorCode(error),
  );

  final String code;

  /// True when the user cancelled; pages show nothing for it.
  bool get cancelled => code == 'fetch.${FetchErrorCode.cancelled.name}';

  String message(AppLocalizations l) => errorText(l, code);
}

/// Runs [body] and captures expected failures (exceptions, not programming
/// errors) as [Err].
Future<Result<T>> attempt<T>(Future<T> Function() body) async {
  try {
    return Ok(await body());
  } on Exception catch (e) {
    final error = AppError.from(e);
    if (error.code == 'unknown') Log.warn('command failed: $e');
    return Err(error);
  }
}

/// Maps an [errorCode] (also stored as a card's last error) to text.
String errorText(AppLocalizations l, String code) {
  final parts = code.split('.');
  final kind = parts.length > 1 ? '${parts[0]}.${parts[1]}' : code;
  final detail = parts.length > 2 ? parts.skip(2).join('.') : '';
  return switch (kind) {
    'fetch.invalidUrl' => l.errorInvalidUrl,
    'fetch.blockedAddress' => l.errorBlockedAddress,
    'fetch.timeout' => l.errorTimeout,
    'fetch.tooLarge' => l.errorTooLarge,
    'fetch.tooManyRedirects' => l.errorTooManyRedirects,
    'fetch.httpStatus' => l.errorHttpStatus(int.tryParse(detail) ?? 0),
    'fetch.tls' => l.errorTls,
    'fetch.network' => l.errorNetwork,
    'import.unsupportedScheme' => l.errorUnsupportedScheme,
    'import.malformed' => l.errorMalformed,
    'import.missingField' => l.errorMissingField(detail),
    'import.invalidField' => l.errorInvalidField(detail),
    'import.unknownParameter' => l.errorUnknownParameter(detail),
    'import.unsupportedValue' => l.errorUnsupportedValue(detail),
    'import.unknownFormat' => l.errorUnknownFormat,
    'import.tooLarge' => l.errorTooLargeContent(detail),
    'vault.locked' => l.errorVaultLocked,
    'backup.wrongPassword' => l.backupWrongPassword,
    'backup.notABackup' => l.backupNotABackup,
    'backup.unsupportedVersion' => l.backupUnsupportedVersion,
    'backup.tooLarge' => l.backupTooLarge,
    'backup.malformed' => l.backupMalformed,
    'backup.passwordTooShort' => l.passwordTooShort,
    'edit.conflict' => l.errorEditConflict,
    'scan.notSubscription' => l.scanNotSubscription,
    'edit.missing' => l.errorNotFound,
    'configuration.inUse' => l.errorConfigurationInUse,
    'cloud.networkGuard' => l.cloudNetworkGuard,
    _ => l.errorUnknown,
  };
}

/// User-visible import problems; routine import handling stays silent (D122).
String? warningText(AppLocalizations l, ImportWarning w) => switch (w.kind) {
  WarningKind.unsupportedNodeType => l.warnUnsupportedNodeType(
    w.count,
    w.subject,
  ),
  WarningKind.unsupportedNodeOption => l.warnUnsupportedNodeOption(
    w.count,
    w.subject,
  ),
  WarningKind.ignoredNodeOption => l.warnIgnoredNodeOption(w.count, w.subject),
  WarningKind.unreadableEntry => l.warnUnreadableEntry(w.count, w.subject),
  WarningKind.unsupportedRuleSet => l.warnUnsupportedRuleSet(w.subject),
  WarningKind.unsupportedGroupType => l.warnUnsupportedGroupType(w.subject),
  WarningKind.approximatedGroupType || WarningKind.ignoredSection => null,
  WarningKind.unsupportedRule => l.warnUnsupportedRule(w.count, w.subject),
  WarningKind.insecureTls => l.warnInsecureTls(w.count),
  WarningKind.missingFinal => l.warnMissingFinal,
  WarningKind.droppedMember => l.warnDroppedMember(w.subject),
};

/// Why a plan could not be compiled, in one sentence. [source] is the
/// override text, to turn a syntax error's offset into a line and column.
String compileErrorText(
  AppLocalizations l,
  CompileException e, {
  String source = '',
}) {
  if (e.subject == 'cloud.networkGuard') return l.cloudNetworkGuard;
  if (e.subject == 'tailnet.exit') return l.tailnetExitNotReady;
  switch (e.code) {
    case CompileErrorCode.memberUnavailable:
      return l.compileMemberUnavailable(e.subject);
    case CompileErrorCode.emptyGroup:
      return l.compileEmptyGroup(e.subject);
    case CompileErrorCode.ruleSetMissing:
      return l.compileRuleSetMissing(e.subject);
    case CompileErrorCode.perAppNeedsFindProcess:
      return l.compilePerAppNeedsFindProcess;
    case CompileErrorCode.invalidSetting:
      return l.compileInvalidSetting(e.subject);
    case CompileErrorCode.overrideReference:
      return l.overrideReference(e.subject, e.detail);
    case CompileErrorCode.overrideConflict:
      return l.overrideConflict(e.subject, e.detail);
    case CompileErrorCode.nothingToRun:
      return l.errorUnknown;
    case CompileErrorCode.overrideInvalid:
      final detail = e.detail;
      if (detail.startsWith('offset ')) {
        final (line, column) = lineAndColumn(
          source,
          int.tryParse(detail.substring(7)) ?? 0,
        );
        return l.overrideSyntax(line, column);
      }
      return switch (detail) {
        'not allowed' => l.overrideNotAllowed(e.subject),
        'object' =>
          e.subject == r'$'
              ? l.overrideNotObject
              : l.overrideWrongType(e.subject, l.jsonObject),
        'array' => l.overrideWrongType(e.subject, l.jsonArray),
        'string' => l.overrideWrongType(e.subject, l.jsonString),
        'object with tag' => l.overrideWrongType(e.subject, l.jsonTaggedObject),
        _ => l.overrideWrongType(e.subject, detail),
      };
  }
}

/// 1-based line and column of [offset] in [text].
(int line, int column) lineAndColumn(String text, int offset) {
  final end = offset.clamp(0, text.length);
  var line = 1;
  var lineStart = 0;
  for (var i = 0; i < end; i++) {
    if (text.codeUnitAt(i) == 0x0A) {
      line++;
      lineStart = i + 1;
    }
  }
  return (line, end - lineStart + 1);
}
