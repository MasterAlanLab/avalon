import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../../domain/secret.dart';

/// planHash (CONFIG_PIPELINE §7): SHA-256 of the canonical JSON (keys
/// sorted) plus the bridge and core versions. Secrets enter as HMACs under a
/// per-installation key, so the hash changes when a secret does but never
/// reveals one.
String planHash(
  Map<String, Object?> tree, {
  required Uint8List key,
  required String bridgeVersion,
  required String coreVersion,
}) {
  final hmac = Hmac(sha256, key);
  Object? canonical(Object? v) => switch (v) {
    final Secret s => 'hmac:${hmac.convert(utf8.encode(s.value))}',
    final Map<String, Object?> m => {
      for (final k in m.keys.toList()..sort()) k: canonical(m[k]),
    },
    final List<Object?> l => [for (final e in l) canonical(e)],
    _ => v,
  };
  final body = jsonEncode([bridgeVersion, coreVersion, canonical(tree)]);
  return sha256.convert(utf8.encode(body)).toString();
}
