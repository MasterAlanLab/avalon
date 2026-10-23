import 'dart:convert';
import 'dart:io';

import 'package:avalon/data/vault/vault.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory dir;

  setUp(() => dir = Directory.systemTemp.createTempSync('av_key'));
  tearDown(() => dir.deleteSync(recursive: true));

  test('creates a 0600 key file once and reads it back', () async {
    final file = File('${dir.path}/nested/master.key');
    final key = await FileKeyStore(file).readOrCreate();
    expect(key, hasLength(32));
    expect(await FileKeyStore(file).readOrCreate(), key);
    if (!Platform.isWindows) {
      expect(file.statSync().mode & 0x1FF, 0x180); // rw-------
    }
  });

  test('refuses a damaged key file instead of replacing it', () async {
    final file = File('${dir.path}/master.key')..writeAsStringSync('AAAA');
    await expectLater(FileKeyStore(file).readOrCreate(), throwsFormatException);
    expect(file.readAsStringSync(), 'AAAA');
  });

  test('a missing key cannot replace existing encrypted material', () async {
    final file = File('${dir.path}/nested/master.key');
    await expectLater(
      Vault.open(FileKeyStore(file), allowCreate: false),
      throwsA(isA<MasterKeyMissingException>()),
    );
    expect(file.existsSync(), isFalse);
    expect(file.parent.existsSync(), isFalse);
  });

  test('an existing file key remains readable without creation', () async {
    final file = File('${dir.path}/master.key');
    final key = await FileKeyStore(file).readOrCreate();
    final stored = file.readAsStringSync();
    expect(await FileKeyStore(file).readOrCreate(allowCreate: false), key);
    expect(file.readAsStringSync(), stored);
  });

  test(
    'a malformed file key is preserved and never echoed in errors',
    () async {
      const stored = 'synthetic-private-key%';
      final file = File('${dir.path}/master.key')..writeAsStringSync(stored);
      await expectLater(
        FileKeyStore(file).readOrCreate(allowCreate: false),
        throwsA(
          isA<FormatException>()
              .having((e) => e.source, 'source', isNull)
              .having((e) => e.toString(), 'error', isNot(contains(stored))),
        ),
      );
      expect(file.readAsStringSync(), stored);
    },
  );

  test(
    'file creation failure stays unavailable without deleting data',
    () async {
      final marker = File('${dir.path}/keep')..writeAsStringSync('keep');
      await expectLater(
        FileKeyStore(File(dir.path)).readOrCreate(),
        throwsA(isA<MasterKeyUnavailableException>()),
      );
      expect(marker.readAsStringSync(), 'keep');
    },
  );

  test(
    'Vault refuses invalid injected key lengths before encrypting',
    () async {
      for (final length in [0, 31, 33]) {
        await expectLater(
          Vault.open(MemoryKeyStore(Uint8List(length))),
          throwsFormatException,
        );
      }
      final vault = await Vault.open(MemoryKeyStore(), allowCreate: false);
      final entry = await vault.seal('entry', {
        'password': 'synthetic-password',
      });
      expect(await vault.unseal('entry', entry.nonce, entry.ciphertext), {
        'password': 'synthetic-password',
      });
    },
  );

  group('OS secure storage', () {
    const channel = MethodChannel(
      'plugins.it_nomads.com/flutter_secure_storage',
    );
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    late List<MethodCall> calls;
    String? stored;
    String? failingMethod;

    setUp(() {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      calls = [];
      stored = null;
      failingMethod = null;
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        if (call.method == failingMethod) {
          throw PlatformException(
            code: 'TEMPORARILY_UNAVAILABLE',
            message: 'synthetic-private-detail',
          );
        }
        return switch (call.method) {
          'read' => stored,
          'write' => () {
            stored = (call.arguments as Map)['value'] as String;
            return null;
          }(),
          _ => throw StateError('unexpected storage mutation'),
        };
      });
    });

    tearDown(() {
      messenger.setMockMethodCallHandler(channel, null);
      debugDefaultTargetPlatformOverride = null;
    });

    test('first use creates once with destructive reset disabled', () async {
      final store = const SecureStorageKeyStore();
      final key = await store.readOrCreate();
      expect(key, hasLength(32));
      expect(await store.readOrCreate(allowCreate: false), key);
      expect(calls.map((c) => c.method), ['read', 'write', 'read']);
      final original = const AndroidOptions().toMap();
      for (final call in calls) {
        final args = call.arguments as Map;
        expect(args['key'], 'avalon.master_key');
        expect(args['options'], {...original, 'resetOnError': 'false'});
      }
    });

    test('missing key with old ciphertext does not write or delete', () async {
      await expectLater(
        Vault.open(const SecureStorageKeyStore(), allowCreate: false),
        throwsA(isA<MasterKeyMissingException>()),
      );
      expect(calls.map((c) => c.method), ['read']);
      expect(stored, isNull);
    });

    test(
      'a transient read failure never becomes permission to create',
      () async {
        failingMethod = 'read';
        await expectLater(
          const SecureStorageKeyStore().readOrCreate(),
          throwsA(
            isA<MasterKeyUnavailableException>().having(
              (e) => e.toString(),
              'error',
              isNot(contains('synthetic-private-detail')),
            ),
          ),
        );
        expect(calls.map((c) => c.method), ['read']);
        expect(stored, isNull);
      },
    );

    test('failed key persistence cannot open a Vault', () async {
      failingMethod = 'write';
      await expectLater(
        Vault.open(const SecureStorageKeyStore()),
        throwsA(isA<MasterKeyUnavailableException>()),
      );
      expect(calls.map((c) => c.method), ['read', 'write']);
      expect(stored, isNull);
    });

    test('damaged and incorrectly sized keys are never replaced', () async {
      for (final value in [
        'synthetic-private-key%',
        base64.encode(Uint8List(31)),
        base64.encode(Uint8List(33)),
      ]) {
        calls.clear();
        stored = value;
        await expectLater(
          const SecureStorageKeyStore().readOrCreate(),
          throwsA(
            isA<FormatException>().having((e) => e.source, 'source', isNull),
          ),
        );
        expect(calls.map((c) => c.method), ['read']);
        expect(stored, value);
      }
    });

    test(
      'reset prevention preserves injected algorithms and namespace',
      () async {
        const options = AndroidOptions.biometric(
          storageNamespace: 'synthetic-existing-namespace',
          preferencesKeyPrefix: 'synthetic-prefix',
          enforceBiometrics: true,
          migrateOnAlgorithmChange: false,
        );
        final key = Uint8List.fromList(List.generate(32, (i) => i));
        stored = base64.encode(key);
        final store = const SecureStorageKeyStore(
          FlutterSecureStorage(aOptions: options),
        );
        expect(await store.readOrCreate(allowCreate: false), key);
        expect((calls.single.arguments as Map)['options'], {
          ...options.toMap(),
          'resetOnError': 'false',
        });
      },
    );
  });
}
