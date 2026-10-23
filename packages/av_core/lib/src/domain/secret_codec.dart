import 'secret.dart';

/// Separates secrets from model JSON for storage (DATA_MODEL §3).
///
/// [split] replaces every `{"$secret": value}` with `{"$secretRef": id}` and
/// returns the values by id; the public part goes into the database as is,
/// the map is encrypted as one secrets entry. [join] reverses it.
abstract final class SecretCodec {
  static const refKey = r'$secretRef';

  static ({Object? public, Map<String, String> secrets}) split(Object? json) {
    final secrets = <String, String>{};
    Object? walk(Object? v) {
      if (v is Map) {
        if (v.length == 1 && v.containsKey(Secret.key)) {
          final id = 's${secrets.length}';
          secrets[id] = v[Secret.key] as String;
          return {refKey: id};
        }
        return {for (final e in v.entries) e.key as String: walk(e.value)};
      }
      if (v is List) return [for (final e in v) walk(e)];
      return v;
    }

    return (public: walk(json), secrets: secrets);
  }

  /// Throws [StateError] when a reference has no value, i.e. the secrets
  /// entry does not belong to this model.
  static Object? join(Object? public, Map<String, String> secrets) {
    Object? walk(Object? v) {
      if (v is Map) {
        if (v.length == 1 && v.containsKey(refKey)) {
          final id = v[refKey] as String;
          final value = secrets[id];
          if (value == null) throw StateError('missing secret $id');
          return {Secret.key: value};
        }
        return {for (final e in v.entries) e.key as String: walk(e.value)};
      }
      if (v is List) return [for (final e in v) walk(e)];
      return v;
    }

    return walk(public);
  }
}
