// Backup export and restore over real databases (PRODUCT_SPEC §5, D18,
// DATA_MODEL §6).
import 'dart:convert';
import 'dart:typed_data';

import 'package:av_core/av_core.dart';
import 'package:avalon/app/services.dart';
import 'package:avalon/data/backup/backup_codec.dart';
import 'package:avalon/data/backup/backup_repository.dart';
import 'package:avalon/data/database/database.dart';
import 'package:avalon/data/vault/secret_store.dart';
import 'package:avalon/data/vault/vault.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const _links = '''
trojan://fake-password-a@a.example.com:443#A
trojan://fake-password-b@b.example.com:443#B
''';

const _self = SelfNode(
  id: '',
  name: '自建 VPS',
  server: 'vps.example.com',
  port: 443,
  params: NodeParams.trojan(password: Secret('fake-self')),
);

Future<AppServices> _device() => AppServices.open(
  database: AppDatabase(NativeDatabase.memory()),
  // Every device has its own master key.
  keyStore: MemoryKeyStore(),
  host: () async => const HostInfo(
    platform: HostPlatform.macos,
    stateDir: '/state',
    deviceName: 'test',
  ),
);

/// A device with a subscription-like file, a self node, a chain through
/// both, a membership, a choice, an override and changed settings.
Future<({AppServices s, String configId, String nodeId, String chainId})>
_filled() async {
  final s = await _device();
  final added = await s.imports.addFile(
    text: _links,
    defaultName: '新订阅',
    name: '我的机场',
  );
  final id = added.configurationId;
  await s.settings.updateDevice(
    (d) => d.copyWith(selectedConfigurationId: id, mixedPort: 1080),
  );
  final node = await s.selfService.addNode(_self);
  final content = (await s.configurations.content(id))!.content;
  final first = MemberRef.source(
    configurationId: id,
    key: content.nodes.first.key,
  );
  final chain = await s.selfService.addChain(
    Chain(
      id: '',
      name: '回国',
      hops: [
        first,
        MemberRef.selfNode(id: node.id),
      ],
    ),
    groupKeys: {LinkListGroups.selectKey},
  );
  await s.selections.select(id, LinkListGroups.selectKey, first);
  await s.settings.updatePolicy(
    (p) => p.copyWith(jsonOverride: const Secret('{"route":{"final":"A"}}')),
  );
  return (s: s, configId: id, nodeId: node.id, chainId: chain.id);
}

Matcher _fails(BackupErrorCode code) =>
    throwsA(isA<BackupException>().having((e) => e.code, 'code', code));

void main() {
  // Each simulated device opens its own in-memory database.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  // The real key-derivation cost makes a file in most of a second; fine for
  // the few times it happens here.
  const password = 'fake-backup-password';

  test('everything comes back on another device', () async {
    final from = await _filled();
    addTearDown(from.s.close);
    final file = await from.s.backups.export(password);
    final key = (await from.s.settings.device()).clashApiSecret!;

    final to = await _device();
    addTearDown(to.close);
    final summary = await to.backups.restore(file, password);
    expect(summary.configurations, 1);
    expect(summary.selfNodes, 1);
    expect(summary.chains, 1);

    final c = (await to.configurations.get(from.configId))!;
    expect(c.name, '我的机场');
    final content = (await to.configurations.content(from.configId))!;
    expect([for (final n in content.content.nodes) n.name], ['A', 'B']);
    expect(
      (content.content.nodes.first.params as TrojanParams).password,
      const Secret('fake-password-a'),
    );
    final node = (await to.selfContent.nodes()).single;
    expect(node.id, from.nodeId);
    expect((node.params as TrojanParams).password, const Secret('fake-self'));
    final chain = (await to.selfContent.chains()).single;
    expect(chain.id, from.chainId);
    expect(chain.name, '回国');
    expect(await to.selfContent.watchMemberships().first, hasLength(2));
    expect(await to.selections.get(from.configId), hasLength(1));
    final settings = await to.settings.device();
    expect(settings.mixedPort, 1080);
    expect(settings.selectedConfigurationId, from.configId);
    expect(settings.clashApiSecret, key);
    expect(
      (await to.settings.policy()).jsonOverride,
      const Secret('{"route":{"final":"A"}}'),
    );
    // And it runs: the restored data compiles with the override applied.
    await to.plans.compileSelected();
  });

  test('merge: same id replaced, local-only kept, settings replaced', () async {
    final from = await _filled();
    addTearDown(from.s.close);
    final file = await from.s.backups.export(password);

    // The same device moves on after the backup.
    await from.s.configurations.update(from.configId, name: '后来改的名字');
    final local = await from.s.imports.addFile(
      text: 'trojan://fake-password-c@c.example.com:443#C\n',
      defaultName: '新订阅',
      name: '备份之后加的',
    );
    final localNode = await from.s.selfService.addNode(
      _self.copyWith(name: '备份之后的节点'),
    );
    await from.s.settings.updateDevice((d) => d.copyWith(mixedPort: 2080));
    final secretsBefore = await from.s.db.select(from.s.db.secrets).get();

    await from.s.backups.restore(file, password);

    expect((await from.s.configurations.get(from.configId))!.name, '我的机场');
    expect(
      (await from.s.configurations.get(local.configurationId))!.name,
      '备份之后加的',
    );
    expect([
      for (final n in await from.s.selfContent.nodes()) n.name,
    ], containsAll(['自建 VPS', '备份之后的节点']));
    expect(
      (await from.s.selfContent.nodes()).firstWhere(
        (n) => n.id == localNode.id,
      ),
      isNotNull,
    );
    expect((await from.s.settings.device()).mixedPort, 1080);
    // Replaced objects do not leave their old secrets behind.
    expect(
      await from.s.db.select(from.s.db.secrets).get(),
      hasLength(secretsBefore.length),
    );
    // Restoring twice changes nothing more.
    await from.s.backups.restore(file, password);
    expect(await from.s.configurations.watchAll().first, hasLength(3));
    expect(await from.s.selfContent.chains(), hasLength(1));
  });

  test('a wrong password or a broken backup leaves the data alone', () async {
    final from = await _filled();
    addTearDown(from.s.close);
    final file = await from.s.backups.export(password);
    final to = await _device();
    addTearDown(to.close);

    await expectLater(
      to.backups.restore(file, 'another-password'),
      _fails(BackupErrorCode.wrongPassword),
    );
    await expectLater(
      to.backups.restore(Uint8List.fromList([1, 2, 3]), password),
      _fails(BackupErrorCode.notABackup),
    );
    expect(await to.selfContent.nodes(), isEmpty);
    expect(await to.configurations.watchAll().first, hasLength(1));
    expect(
      () => from.s.backups.export('short'),
      _fails(BackupErrorCode.passwordTooShort),
    );
  });

  group('the decrypted content', () {
    late AppDatabase db;
    late BackupRepository repo;
    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = BackupRepository(
        db,
        SecretStore(db, await Vault.open(MemoryKeyStore())),
      );
    });
    tearDown(() => db.close());

    test('is checked before anything is written', () async {
      await expectLater(
        repo.restore({'format': 'something-else'}),
        _fails(BackupErrorCode.notABackup),
      );
      await expectLater(
        repo.restore({'format': 'avalon-backup', 'schema': 2}),
        _fails(BackupErrorCode.unsupportedVersion),
      );
      await expectLater(
        repo.restore({
          'format': 'avalon-backup',
          'schema': 1,
          'selfNodes': [
            {'id': 1},
          ],
        }),
        _fails(BackupErrorCode.malformed),
      );
      await expectLater(
        repo.restore({
          'format': 'avalon-backup',
          'schema': 1,
          'configurations': [
            for (var i = 0; i <= BackupRepository.maxConfigurations; i++)
              {
                'id': 'c$i',
                'kind': 'file',
                'name': 'n',
                'autoUpdate': true,
                'createdAt': 0,
                'editedAt': 0,
              },
          ],
        }),
        _fails(BackupErrorCode.tooLarge),
      );
      expect(await db.select(db.selfNodes).get(), isEmpty);
    });

    test('has the documented shape and none of the device identity', () async {
      final from = await _filled();
      addTearDown(from.s.close);
      final json =
          jsonDecode(
                jsonEncode(
                  await BackupRepository(
                    from.s.db,
                    from.s.secrets,
                  ).export(appVersion: '0.1.0', platform: 'macos'),
                ),
              )
              as Map<String, dynamic>;
      expect(json.keys, [
        'format',
        'schema',
        'createdAt',
        'app',
        'configurations',
        'contents',
        'selfNodes',
        'chains',
        'memberships',
        'selections',
        'policy',
        'deviceSettings',
        'secrets',
      ]);
      expect(json['format'], 'avalon-backup');
      expect(json['schema'], 1);
      // A changed column must be a deliberate change of the backup format.
      Set<String> keys(String table) =>
          ((json[table] as List).first as Map<String, dynamic>).keys.toSet();
      expect(keys('configurations'), {
        'id',
        'kind',
        'name',
        'sourceSecretId',
        'sourceDisplay',
        'autoUpdate',
        'contentId',
        'usageUpload',
        'usageDownload',
        'usageTotal',
        'expireAt',
        'lastSuccessAt',
        'lastAttemptAt',
        'lastError',
        'createdAt',
        'editedAt',
      });
      expect(keys('contents'), {
        'id',
        'configurationId',
        'format',
        'modelJson',
        'secretId',
        'nodeCount',
        'digest',
        'warningsJson',
        'createdAt',
      });
      expect(keys('selfNodes'), {
        'id',
        'name',
        'protocol',
        'server',
        'port',
        'paramsJson',
        'secretId',
        'createdAt',
        'editedAt',
      });
      expect(keys('chains'), {
        'id',
        'name',
        'hopsJson',
        'createdAt',
        'editedAt',
      });
      expect(keys('memberships'), {
        'ownerKind',
        'ownerId',
        'configurationId',
        'groupKey',
        'createdAt',
      });
      expect(keys('selections'), {
        'configurationId',
        'groupKey',
        'memberJson',
        'manual',
        'editedAt',
      });
      final text = jsonEncode(json);
      expect(text, isNot(contains('cloudAccountId')));
      expect(text, isNot(contains('installation')));
      // Secrets are in the clear only here, inside the encrypted file.
      expect(text, contains('fake-password-a'));
    });
  });
}
