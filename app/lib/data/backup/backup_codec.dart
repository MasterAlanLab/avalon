import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

enum BackupErrorCode {
  /// Not an Avalon backup file.
  notABackup,

  /// Written by a newer Avalon.
  unsupportedVersion,

  /// The password is wrong or the file was changed; the two cannot be told
  /// apart.
  wrongPassword,

  /// Larger than a backup may be.
  tooLarge,

  /// Decrypted, but the content is not what a backup holds.
  malformed,

  /// The password is shorter than 8 characters.
  passwordTooShort,
}

final class BackupException implements Exception {
  const BackupException(this.code);

  final BackupErrorCode code;

  @override
  String toString() => 'BackupException(${code.name})';
}

/// Argon2id cost. The defaults are the format's (DATA_MODEL §6); tests use
/// cheaper ones, and a reader takes whatever the file states.
final class BackupKdf {
  const BackupKdf({
    this.memoryKib = 65536,
    this.iterations = 3,
    this.parallelism = 1,
  });

  final int memoryKib;
  final int iterations;
  final int parallelism;
}

/// The `.avalonbackup` container (DATA_MODEL §6, D18):
///
/// ```text
/// "AVBK" | version u8 | salt 16B | memory_kib u32 | iterations u32
/// | parallelism u8 | nonce 24B | XChaCha20-Poly1305(gzip(JSON))
/// ```
///
/// The key is Argon2id(password); everything before the ciphertext is
/// authenticated as associated data. Integers are big-endian.
abstract final class BackupCodec {
  static const version = 1;
  static const minPasswordLength = 8;
  static const maxFileBytes = 64 * 1024 * 1024;

  /// A decompressed backup larger than this is refused.
  static const maxJsonBytes = 512 * 1024 * 1024;

  static const _magic = [0x41, 0x56, 0x42, 0x4B]; // AVBK
  static const _saltLength = 16;
  static const _nonceLength = 24;
  static const _macLength = 16;
  static const _headerLength = 4 + 1 + _saltLength + 4 + 4 + 1 + _nonceLength;

  /// Encrypts [json] under [password].
  static Future<Uint8List> seal(
    Map<String, Object?> json,
    String password, {
    BackupKdf kdf = const BackupKdf(),
  }) {
    if (password.length < minPasswordLength) {
      throw const BackupException(BackupErrorCode.passwordTooShort);
    }
    final random = Random.secure();
    Uint8List bytes(int n) =>
        Uint8List.fromList(List.generate(n, (_) => random.nextInt(256)));
    final salt = bytes(_saltLength);
    final nonce = bytes(_nonceLength);
    // Key derivation and compression are slow; keep them off the UI.
    return Isolate.run(() async {
      final header = BytesBuilder()
        ..add(_magic)
        ..addByte(version)
        ..add(salt)
        ..add(_u32(kdf.memoryKib))
        ..add(_u32(kdf.iterations))
        ..addByte(kdf.parallelism)
        ..add(nonce);
      final aad = header.toBytes();
      final box = await Xchacha20.poly1305Aead().encrypt(
        gzip.encode(utf8.encode(jsonEncode(json))),
        secretKey: await _key(password, salt, kdf),
        nonce: nonce,
        aad: aad,
      );
      return Uint8List.fromList([...aad, ...box.cipherText, ...box.mac.bytes]);
    });
  }

  /// Decrypts a backup file. Throws [BackupException].
  static Future<Map<String, Object?>> open(Uint8List file, String password) {
    if (file.length > maxFileBytes) {
      throw const BackupException(BackupErrorCode.tooLarge);
    }
    if (file.length < _headerLength + _macLength ||
        !_startsWith(file, _magic)) {
      throw const BackupException(BackupErrorCode.notABackup);
    }
    if (file[4] != version) {
      throw const BackupException(BackupErrorCode.unsupportedVersion);
    }
    final data = ByteData.sublistView(file);
    final salt = file.sublist(5, 5 + _saltLength);
    final kdf = BackupKdf(
      memoryKib: data.getUint32(5 + _saltLength),
      iterations: data.getUint32(5 + _saltLength + 4),
      parallelism: file[5 + _saltLength + 8],
    );
    // A file may not make this device spend unbounded memory or time.
    if (kdf.memoryKib < 8 ||
        kdf.memoryKib > 1024 * 1024 ||
        kdf.iterations < 1 ||
        kdf.iterations > 16 ||
        kdf.parallelism < 1 ||
        kdf.parallelism > 8) {
      throw const BackupException(BackupErrorCode.notABackup);
    }
    return Isolate.run(() async {
      final aad = file.sublist(0, _headerLength);
      final List<int> packed;
      try {
        packed = await Xchacha20.poly1305Aead().decrypt(
          SecretBox(
            file.sublist(_headerLength, file.length - _macLength),
            nonce: file.sublist(_headerLength - _nonceLength, _headerLength),
            mac: Mac(file.sublist(file.length - _macLength)),
          ),
          secretKey: await _key(password, salt, kdf),
          aad: aad,
        );
      } on SecretBoxAuthenticationError {
        throw const BackupException(BackupErrorCode.wrongPassword);
      }
      try {
        final json = jsonDecode(utf8.decode(_gunzip(packed)));
        if (json is Map<String, Object?>) return json;
      } on FormatException {
        // Falls through.
      }
      throw const BackupException(BackupErrorCode.malformed);
    });
  }

  static Future<SecretKey> _key(
    String password,
    List<int> salt,
    BackupKdf kdf,
  ) => Argon2id(
    memory: kdf.memoryKib,
    parallelism: kdf.parallelism,
    iterations: kdf.iterations,
    hashLength: 32,
  ).deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);

  /// Decompresses, refusing output beyond [maxJsonBytes].
  static List<int> _gunzip(List<int> packed) {
    final out = BytesBuilder(copy: false);
    final decoder = gzip.decoder.startChunkedConversion(
      ByteConversionSink.from(
        _Collector((chunk) {
          out.add(chunk);
          if (out.length > maxJsonBytes) {
            throw const BackupException(BackupErrorCode.tooLarge);
          }
        }),
      ),
    );
    try {
      decoder
        ..add(packed)
        ..close();
    } on FormatException {
      throw const BackupException(BackupErrorCode.malformed);
    }
    return out.takeBytes();
  }

  static Uint8List _u32(int value) =>
      (ByteData(4)..setUint32(0, value)).buffer.asUint8List();

  static bool _startsWith(List<int> bytes, List<int> prefix) {
    for (var i = 0; i < prefix.length; i++) {
      if (bytes[i] != prefix[i]) return false;
    }
    return true;
  }
}

/// A sink that hands every chunk to [_onChunk].
final class _Collector implements Sink<List<int>> {
  _Collector(this._onChunk);

  final void Function(List<int> chunk) _onChunk;

  @override
  void add(List<int> data) => _onChunk(data);

  @override
  void close() {}
}
