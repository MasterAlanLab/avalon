import 'dart:io';

import 'package:avalon/data/vault/vault.dart';
import 'package:avalon/platform/linux_key_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('linux-key-fixture-'));
  tearDown(() => dir.deleteSync(recursive: true));
  Map<String, String> environment() => {'XDG_DATA_HOME': dir.path};

  test('uses secure storage when Secret Service is available', () async {
    final store = await linuxKeyStore(
      environment: environment(),
      secretServiceAvailable: () async => true,
    );
    expect(store, isA<SecureStorageKeyStore>());
    expect(File('${dir.path}/avalon/master.key').existsSync(), isFalse);
  });

  test(
    'fallback persists owner-only key and remains on its original backend',
    () async {
      final store = await linuxKeyStore(
        environment: environment(),
        secretServiceAvailable: () async => false,
      );
      expect(store, isA<FileKeyStore>());
      final first = await store.readOrCreate();
      final file = File('${dir.path}/avalon/master.key');
      expect(file.statSync().mode & 0x1ff, 0x180); // 0600
      final reopened = await linuxKeyStore(
        environment: environment(),
        secretServiceAvailable: () async =>
            throw StateError('must not migrate backend'),
      );
      expect(await reopened.readOrCreate(allowCreate: false), first);
    },
  );

  test(
    'occupied vault without a file key does not create a replacement',
    () async {
      final store = await linuxKeyStore(
        environment: environment(),
        secretServiceAvailable: () async => false,
      );
      await expectLater(
        Vault.open(store, allowCreate: false),
        throwsA(isA<MasterKeyMissingException>()),
      );
      expect(File('${dir.path}/avalon/master.key').existsSync(), isFalse);
    },
  );

  test('uncertain service failures do not choose the file fallback', () async {
    await expectLater(
      linuxKeyStore(
        environment: environment(),
        secretServiceAvailable: () async =>
            throw const MasterKeyUnavailableException(),
      ),
      throwsA(isA<MasterKeyUnavailableException>()),
    );
    expect(File('${dir.path}/avalon/master.key').existsSync(), isFalse);
  });
}
