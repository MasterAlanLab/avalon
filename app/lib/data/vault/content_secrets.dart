import 'package:av_core/av_core.dart';

/// URL query tokens and usernames are credentials too, although the domain
/// model uses Strings. Keep them with passwords in encrypted projections.
abstract final class ContentSecrets {
  static ({Object? public, Map<String, String> secrets}) split(Object? json) =>
      SecretCodec.split(_protect(json));

  static Object? join(Object? json, Map<String, String> secrets) =>
      _unprotect(SecretCodec.join(json, secrets));

  static Object? _protect(Object? value) {
    if (value is List) return value.map(_protect).toList();
    if (value is! Map) return value;
    return <String, Object?>{
      for (final entry in value.entries)
        entry.key as String:
            (entry.key == 'username' || entry.key == 'url') &&
                entry.value is String
            ? Secret(entry.value as String).toJson()
            : _protect(entry.value),
    };
  }

  static Object? _unprotect(Object? value) {
    if (value is List) return value.map(_unprotect).toList();
    if (value is! Map) return value;
    return <String, Object?>{
      for (final entry in value.entries)
        entry.key as String:
            (entry.key == 'username' || entry.key == 'url') &&
                entry.value is Map &&
                (entry.value as Map).length == 1 &&
                (entry.value as Map).containsKey(Secret.key)
            ? (entry.value as Map)[Secret.key]
            : _unprotect(entry.value),
    };
  }
}
