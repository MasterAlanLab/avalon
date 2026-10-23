import 'dart:convert';
import 'dart:io';

import 'package:avalon/data/backup/backup_repository.dart';
import 'package:avalon/data/database/database.dart';
import 'package:avalon/data/vault/secret_store.dart';
import 'package:avalon/data/vault/vault.dart';
import 'package:avalon/platform/desktop/system_proxy.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

final class _Backend implements DesktopProxyBackend {
  @override
  String get name => 'test';
  final values = {'host': 'original', 'port': '443', 'mode': 'auto'};
  bool failOnce = false;
  bool competingWrite = false;
  @override
  Future<Map<String, String>> read() async => Map.of(values);
  @override
  Map<String, String> target(int port) => {
    'host': '127.0.0.1',
    'port': '$port',
    'mode': 'manual',
  };
  @override
  Future<void> write(
    Map<String, String> patch, {
    Map<String, String>? expected,
  }) async {
    if (competingWrite) {
      competingWrite = false;
      values['host'] = 'new-user-proxy';
    }
    if (expected != null &&
        expected.entries.any((e) => values[e.key] != e.value)) {
      throw const SystemProxyOwnershipChanged();
    }
    for (final entry in patch.entries) {
      values[entry.key] = entry.value;
      if (failOnce) {
        failOnce = false;
        throw const SystemProxyException();
      }
    }
  }
}

void main() {
  test(
    'crash recovery preserves original settings and newer user changes',
    () async {
      final backend = _Backend();
      Map<String, String>? recovery;
      DesktopSystemProxy create() => DesktopSystemProxy(
        backend: backend,
        readRecovery: () async => recovery,
        saveRecovery: (value) async {
          recovery = value;
        },
      );
      await create().apply(7890);
      expect(await create().active(7890), isTrue);
      await create().apply(7890);
      await create().restore();
      expect(backend.values, {
        'host': 'original',
        'port': '443',
        'mode': 'auto',
      });
      await create().apply(7890);
      backend.values['host'] = 'user-changed';
      await create().restore();
      // Mode and endpoint are one group: don't disable the user's new proxy.
      expect(backend.values, {
        'host': 'user-changed',
        'port': '7890',
        'mode': 'manual',
      });
      expect(recovery, isNull);
    },
  );

  test(
    'partial failure rolls back only the values this operation changed',
    () async {
      final backend = _Backend()..failOnce = true;
      Map<String, String>? recovery;
      final proxy = DesktopSystemProxy(
        backend: backend,
        readRecovery: () async => recovery,
        saveRecovery: (value) async {
          recovery = value;
        },
      );
      await expectLater(
        proxy.apply(7890),
        throwsA(isA<SystemProxyException>()),
      );
      expect(backend.values, {
        'host': 'original',
        'port': '443',
        'mode': 'auto',
      });
      expect(recovery, isNull);
    },
  );

  test(
    'a concurrent OS edit immediately before restore is preserved',
    () async {
      final backend = _Backend();
      Map<String, String>? recovery;
      final proxy = DesktopSystemProxy(
        backend: backend,
        readRecovery: () async => recovery,
        saveRecovery: (value) async {
          recovery = value;
        },
      );
      await proxy.apply(7890);
      backend.competingWrite = true;
      await proxy.restore();
      expect(backend.values, {
        'host': 'new-user-proxy',
        'port': '7890',
        'mode': 'manual',
      });
      expect(recovery, isNull);
    },
  );

  test(
    'encrypted recovery survives orphan cleanup and is excluded from backup',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final secrets = SecretStore(db, await Vault.open(MemoryKeyStore()));
      addTearDown(db.close);
      const privateValue =
          'https://user:private-password@proxy.example/pac?token=private-token';
      final journal = {
        'journal': jsonEncode({'before': privateValue}),
      };
      await secrets.saveSystemProxyRecovery(journal);
      await secrets.deleteOrphans();
      expect(await secrets.systemProxyRecovery(), journal);
      final row = (await db.select(db.secrets).get()).single;
      expect(
        utf8.decode(row.ciphertext, allowMalformed: true),
        isNot(contains('private-password')),
      );
      final backup = await BackupRepository(
        db,
        secrets,
      ).export(appVersion: 'test', platform: 'test');
      expect(jsonEncode(backup), isNot(contains('private-token')));
      await secrets.saveSystemProxyRecovery(null);
      expect(await secrets.systemProxyRecovery(), isNull);
    },
  );

  test(
    'GNOME uses argument lists and rejects unsupported desktop sessions',
    () async {
      final calls = <List<String>>[];
      final backend = GnomeProxyBackend(
        environment: {'XDG_CURRENT_DESKTOP': 'ubuntu:GNOME'},
        run: (exe, args) async {
          expect(exe, 'gsettings');
          calls.add(args);
          return ProcessResult(
            1,
            0,
            args.first == 'writable' ? 'true' : '',
            '',
          );
        },
      );
      const oldValue = "'host with space; \$(do-not-run)'";
      await backend.write({'http.host': oldValue});
      expect(calls.last, [
        'set',
        'org.gnome.system.proxy.http',
        'host',
        oldValue,
      ]);
      final unsupported = GnomeProxyBackend(
        environment: {'XDG_CURRENT_DESKTOP': 'KDE'},
        run: (_, _) async =>
            throw StateError('must not write unused GNOME settings'),
      );
      await expectLater(
        unsupported.read(),
        throwsA(isA<SystemProxyException>()),
      );
    },
  );
}
