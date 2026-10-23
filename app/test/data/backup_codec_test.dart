// The .avalonbackup container (DATA_MODEL §6).
import 'dart:typed_data';

import 'package:avalon/data/backup/backup_codec.dart';
import 'package:flutter_test/flutter_test.dart';

// The real cost (64 MiB) makes every test take most of a second.
const _fast = BackupKdf(memoryKib: 64, iterations: 1);
const _password = 'fake-password';
const _json = {
  'format': 'avalon-backup',
  'schema': 1,
  'secrets': {
    's1': {'password': 'fake-node-password'},
  },
  'text': '中文内容',
};

Matcher _fails(BackupErrorCode code) =>
    throwsA(isA<BackupException>().having((e) => e.code, 'code', code));

void main() {
  test('round trip; nothing readable in the file', () async {
    final file = await BackupCodec.seal(_json, _password, kdf: _fast);
    expect(String.fromCharCodes(file.sublist(0, 4)), 'AVBK');
    expect(file[4], 1);
    final text = String.fromCharCodes(file);
    expect(text, isNot(contains('avalon-backup')));
    expect(text, isNot(contains('fake-node-password')));
    expect(await BackupCodec.open(file, _password), _json);
  });

  test('two exports of the same data differ', () async {
    final a = await BackupCodec.seal(_json, _password, kdf: _fast);
    final b = await BackupCodec.seal(_json, _password, kdf: _fast);
    expect(a, isNot(b));
  });

  test('the format default cost works too', () async {
    final file = await BackupCodec.seal(_json, _password);
    expect(ByteData.sublistView(file).getUint32(21), 65536);
    expect(await BackupCodec.open(file, _password), _json);
  });

  test('a short password is refused', () {
    expect(
      () => BackupCodec.seal(_json, '1234567', kdf: _fast),
      _fails(BackupErrorCode.passwordTooShort),
    );
  });

  test('a wrong password and a changed file look the same', () async {
    final file = await BackupCodec.seal(_json, _password, kdf: _fast);
    await expectLater(
      BackupCodec.open(file, 'another-password'),
      _fails(BackupErrorCode.wrongPassword),
    );
    // Flip one bit of the ciphertext, then one of the header (the salt).
    final body = Uint8List.fromList(file)..[file.length - 20] ^= 1;
    await expectLater(
      BackupCodec.open(body, _password),
      _fails(BackupErrorCode.wrongPassword),
    );
    final header = Uint8List.fromList(file)..[6] ^= 1;
    await expectLater(
      BackupCodec.open(header, _password),
      _fails(BackupErrorCode.wrongPassword),
    );
  });

  test('other files are told apart', () async {
    expect(
      () => BackupCodec.open(Uint8List.fromList('{"a":1}'.codeUnits), 'x'),
      _fails(BackupErrorCode.notABackup),
    );
    final file = await BackupCodec.seal(_json, _password, kdf: _fast);
    expect(
      () => BackupCodec.open(Uint8List.fromList(file)..[4] = 2, _password),
      _fails(BackupErrorCode.unsupportedVersion),
    );
    // A header asking for absurd memory is not followed.
    final greedy = Uint8List.fromList(file);
    ByteData.sublistView(greedy).setUint32(21, 0xFFFFFFFF);
    expect(
      () => BackupCodec.open(greedy, _password),
      _fails(BackupErrorCode.notABackup),
    );
    expect(
      () =>
          BackupCodec.open(Uint8List(BackupCodec.maxFileBytes + 1), _password),
      _fails(BackupErrorCode.tooLarge),
    );
  });
}
