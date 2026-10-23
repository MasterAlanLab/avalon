import 'dart:convert';

/// Key formats the core checks as it loads a plan (D84). A node with a
/// malformed key would make it refuse the whole plan, so such a node is
/// unavailable (CONFIG_PIPELINE §6) and the form refuses it.
abstract final class NodeKeys {
  /// Reality's X25519 public key: 32 bytes in base64url without padding,
  /// as sing-box decodes it (`base64.RawURLEncoding`).
  static bool realityPublicKey(String key) =>
      RegExp(r'^[A-Za-z0-9_-]{43}$').hasMatch(key);

  /// Reality's short id: up to 8 bytes in hex, an even number of digits.
  static bool realityShortId(String id) =>
      RegExp(r'^([0-9a-fA-F]{2}){0,8}$').hasMatch(id);

  /// Shadowsocks 2022 takes base64 keys (standard alphabet, padded) of the
  /// method's key length, several separated by `:` except for ChaCha20.
  /// Other methods take any password.
  static bool shadowsocksPassword(String method, String password) {
    final length = switch (method) {
      '2022-blake3-aes-128-gcm' => 16,
      '2022-blake3-aes-256-gcm' || '2022-blake3-chacha20-poly1305' => 32,
      _ => null,
    };
    if (length == null) return true;
    final keys = password.split(':');
    if (method == '2022-blake3-chacha20-poly1305' && keys.length > 1) {
      return false;
    }
    final padded = RegExp(r'^[A-Za-z0-9+/]+={0,2}$');
    return keys.every((key) {
      if (key.length % 4 != 0 || !padded.hasMatch(key)) return false;
      try {
        return base64.decode(key).length == length;
      } on FormatException {
        return false;
      }
    });
  }
}
