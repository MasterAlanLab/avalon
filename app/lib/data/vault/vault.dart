import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the 32-byte master key lives (DATA_MODEL §3).
abstract interface class MasterKeyStore {
  /// Reads the key, creating it only for a confirmed first use.
  ///
  /// Existing encrypted entries require [allowCreate] to be false. A missing
  /// key then reports unavailability without replacing recovery material.
  Future<Uint8List> readOrCreate({bool allowCreate = true});
}

/// No key was found for existing encrypted entries. This does not establish
/// permanent loss: secure storage may become accessible again later.
final class MasterKeyMissingException implements Exception {
  const MasterKeyMissingException();

  @override
  String toString() => 'MasterKeyMissingException';
}

/// Reading or saving secure storage failed. Never treat this as first use or
/// expose platform errors, which can contain private storage details.
final class MasterKeyUnavailableException implements Exception {
  const MasterKeyUnavailableException();

  @override
  String toString() => 'MasterKeyUnavailableException';
}

/// Keychain, Android Keystore, Windows Credential Store or Secret Service.
final class SecureStorageKeyStore implements MasterKeyStore {
  const SecureStorageKeyStore([
    this._storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(resetOnError: false),
    ),
  ]);

  static const _name = 'avalon.master_key';
  final FlutterSecureStorage _storage;

  @override
  Future<Uint8List> readOrCreate({bool allowCreate = true}) async {
    // Preserve injected namespaces and algorithms, too; no plugin error may
    // discard an existing master key before the app decides how to recover.
    final options = _storage.aOptions.copyWith(resetOnError: false);
    final String? stored;
    try {
      stored = await _storage.read(key: _name, aOptions: options);
    } on Exception {
      throw const MasterKeyUnavailableException();
    }
    if (stored != null) return _decodeKey(stored);
    if (!allowCreate) throw const MasterKeyMissingException();
    final key = _randomKey();
    try {
      await _storage.write(
        key: _name,
        value: base64.encode(key),
        aOptions: options,
      );
    } on Exception {
      throw const MasterKeyUnavailableException();
    }
    return key;
  }
}

/// A key file readable only by its owner (0600), for where the system store
/// cannot be used: Linux without a Secret Service (D23) and ad-hoc signed
/// macOS debug builds (D77).
final class FileKeyStore implements MasterKeyStore {
  const FileKeyStore(this._file);

  final File _file;

  @override
  Future<Uint8List> readOrCreate({bool allowCreate = true}) async {
    try {
      if (await _file.exists()) {
        return _decodeKey((await _file.readAsString()).trim());
      }
    } on FileSystemException {
      throw const MasterKeyUnavailableException();
    }
    if (!allowCreate) throw const MasterKeyMissingException();
    final key = _randomKey();
    try {
      await _file.parent.create(recursive: true);
      // Created empty and restricted first, so the key is never world-readable.
      await _file.writeAsString('', flush: true);
      if (!Platform.isWindows) {
        final chmod = await Process.run('/bin/chmod', ['600', _file.path]);
        if (chmod.exitCode != 0) {
          await _file.delete();
          throw const MasterKeyUnavailableException();
        }
      }
      await _file.writeAsString(base64.encode(key), flush: true);
    } on FileSystemException {
      throw const MasterKeyUnavailableException();
    } on ProcessException {
      throw const MasterKeyUnavailableException();
    }
    return key;
  }
}

/// For tests.
final class MemoryKeyStore implements MasterKeyStore {
  MemoryKeyStore([Uint8List? key]) : _key = key ?? _randomKey();

  final Uint8List _key;

  @override
  Future<Uint8List> readOrCreate({bool allowCreate = true}) async => _key;
}

Uint8List _decodeKey(String stored) {
  final Uint8List key;
  try {
    key = base64.decode(stored);
  } on FormatException {
    // FormatException's source must never retain the stored key.
    throw const FormatException('master key is damaged');
  }
  _validateKey(key);
  return key;
}

void _validateKey(Uint8List key) {
  if (key.length != 32) {
    throw const FormatException('master key is damaged');
  }
}

Uint8List _randomKey() {
  final r = Random.secure();
  return Uint8List.fromList(List.generate(32, (_) => r.nextInt(256)));
}

/// An entry could not be decrypted: the master key was reset (e.g. the
/// keychain was wiped) or the entry was tampered with. Non-secret content
/// stays usable (DATA_MODEL §3).
final class VaultLockedException implements Exception {
  const VaultLockedException(this.id);

  final String id;

  @override
  String toString() => 'VaultLockedException($id)';
}

/// Seals secret entries with XChaCha20-Poly1305; the entry id is the AAD, so
/// entries cannot be swapped between owners.
final class Vault {
  Vault._(this._key);

  static Future<Vault> open(
    MasterKeyStore store, {
    bool allowCreate = true,
  }) async {
    final key = await store.readOrCreate(allowCreate: allowCreate);
    _validateKey(key);
    return Vault._(SecretKey(key));
  }

  final SecretKey _key;
  final _cipher = Xchacha20.poly1305Aead();

  /// A key for another purpose, derived from the master key (HMAC-SHA256
  /// of [purpose]). It is as per-installation as the master key and reveals
  /// nothing about it; the plan hash uses one (CONFIG_PIPELINE §7).
  Future<Uint8List> deriveKey(String purpose) async {
    final mac = await Hmac.sha256().calculateMac(
      utf8.encode(purpose),
      secretKey: _key,
    );
    return Uint8List.fromList(mac.bytes);
  }

  /// Encrypts [secrets] (a flat map, as `SecretCodec.split` returns).
  Future<({Uint8List nonce, Uint8List ciphertext})> seal(
    String id,
    Map<String, String> secrets,
  ) async {
    final box = await _cipher.encrypt(
      utf8.encode(jsonEncode(secrets)),
      secretKey: _key,
      aad: utf8.encode(id),
    );
    return (
      nonce: Uint8List.fromList(box.nonce),
      ciphertext: Uint8List.fromList([...box.cipherText, ...box.mac.bytes]),
    );
  }

  Future<Map<String, String>> unseal(
    String id,
    Uint8List nonce,
    Uint8List ciphertext,
  ) async {
    const macLength = 16;
    if (ciphertext.length < macLength) throw VaultLockedException(id);
    final box = SecretBox(
      ciphertext.sublist(0, ciphertext.length - macLength),
      nonce: nonce,
      mac: Mac(ciphertext.sublist(ciphertext.length - macLength)),
    );
    try {
      final clear = await _cipher.decrypt(
        box,
        secretKey: _key,
        aad: utf8.encode(id),
      );
      return (jsonDecode(utf8.decode(clear)) as Map<String, Object?>)
          .cast<String, String>();
    } on SecretBoxAuthenticationError {
      throw VaultLockedException(id);
    }
  }
}
