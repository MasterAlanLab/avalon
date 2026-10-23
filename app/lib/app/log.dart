import 'dart:developer' as developer;
import 'dart:io';

/// The app's one logger. Messages are redacted before
/// they are written: credentials in URLs, sensitive query parameters and
/// authorization headers never reach a log.
abstract final class Log {
  static void info(String message) => _write(800, message);
  static void warn(String message) => _write(900, message);
  static void error(String message, [Object? error]) =>
      _write(1000, error == null ? message : '$message: $error');

  static void _write(int level, String message) {
    final text = redact(message);
    developer.log(text, name: 'avalon', level: level);
    // Debug builds started outside `flutter run` have no log viewer.
    assert(() {
      stderr.writeln('[avalon] $text');
      return true;
    }());
  }
}

final _userInfo = RegExp(r'([a-zA-Z][a-zA-Z0-9+.-]*://)[^/@\s]+@');
final _query = RegExp(
  r'([?&;](?:token|key|secret|password|passwd|pass|auth|sig|signature|code|uuid)=)[^&#\s]*',
  caseSensitive: false,
);
final _header = RegExp(
  r'((?:authorization|proxy-authorization|cookie)\s*[:=]\s*)\S.*$',
  caseSensitive: false,
  multiLine: true,
);

/// Masks credentials in free text. Values already wrapped in `Secret` never
/// print in the first place; this covers URLs and headers in error texts.
String redact(String text) => text
    .replaceAllMapped(_userInfo, (m) => '${m[1]}•••@')
    .replaceAllMapped(_query, (m) => '${m[1]}•••')
    .replaceAllMapped(_header, (m) => '${m[1]}•••');
