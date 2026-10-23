// Data layer (DATA_MODEL §2–5) on an in-memory database. Credentials are
// fake.
import 'package:av_core/av_core.dart';
import 'package:avalon/data/database/database.dart';
import 'package:avalon/data/repositories/configuration_repository.dart';
import 'package:avalon/data/repositories/selection_repository.dart';
import 'package:avalon/data/repositories/self_content_repository.dart';
import 'package:avalon/data/repositories/settings_repository.dart';
import 'package:avalon/data/vault/secret_store.dart';
import 'package:avalon/data/vault/vault.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const _subscriptionUrl = 'https://sub.example.com/api?token=fake-token';

final _links = parseContent(
  'vless://00000000-0000-4000-8000-0000000000aa@a.example.com:443#A\n'
  'trojan://fake-trojan-password@b.example.com:443#B\n',
);

/// Fails the n-th secret write, to test rollback.
final class _FailingSecrets extends SecretStore {
  _FailingSecrets(super.db, super.vault, this.failAt);

  final int failAt;
  int _writes = 0;

  @override
  Future<String> put(Map<String, String> secrets) async {
    if (++_writes == failAt) throw StateError('injected');
    return super.put(secrets);
  }
}

void main() {
  late AppDatabase db;
  late Vault vault;
  late SecretStore secrets;
  late ConfigurationRepository configs;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    vault = await Vault.open(MemoryKeyStore());
    secrets = SecretStore(db, vault);
    configs = ConfigurationRepository(db, secrets);
  });
  tearDown(() => db.close());

  Future<int> count(TableInfo<Table, Object?> t) async =>
      (await db.select(t).get()).length;

  /// Every text cell of every table, to search for plaintext.
  Future<String> dump() async {
    final out = StringBuffer();
    for (final t in db.allTables) {
      for (final row
          in await db
              .customSelect('SELECT * FROM ${t.actualTableName}')
              .get()) {
        out.writeln(row.data.values.join('|'));
      }
    }
    return out.toString();
  }

  Future<String> addSubscription() => configs.add(
    kind: ConfigurationKind.subscription,
    name: '机场',
    parsed: _links,
    digest: 'd1',
    source: const SubscriptionSource(
      url: Secret(_subscriptionUrl),
      headers: {'Authorization': Secret('Bearer fake-header')},
    ),
    usage: Usage(
      upload: 1,
      download: 2,
      total: 100,
      expireAt: DateTime.utc(2027, 1, 1),
    ),
  );

  test('the built-in 自建节点 configuration exists from the start', () async {
    final all = await configs.watchAll().first;
    expect(all.single.id, AppDatabase.selfConfigurationId);
    expect(() => configs.delete('self'), throwsArgumentError);
  });

  test(
    'a subscription round-trips; no secret is stored in plaintext',
    () async {
      final id = await addSubscription();
      final c = await configs.get(id);
      expect(c!.name, '机场');
      expect(c.sourceDisplay, 'sub.example.com');
      expect(c.usage!.total, 100);
      final stored = await configs.content(id);
      expect(stored!.content, _links.content);
      expect(stored.format, ContentFormat.linkList);
      expect((await configs.source(id))!.url.value, _subscriptionUrl);

      final text = await dump();
      for (final s in [
        'fake-token',
        'fake-header',
        'fake-trojan-password',
        '00000000-0000-4000-8000-0000000000aa',
      ]) {
        expect(text, isNot(contains(s)), reason: s);
      }
    },
  );

  test(
    'a refresh is dropped when the source changed while downloading',
    () async {
      final id = await addSubscription();
      final before = await configs.sourceSecretId(id);
      await configs.update(
        id,
        source: const SubscriptionSource(
          url: Secret('https://new.example.com/s'),
        ),
      );
      final replaced = parseContent('trojan://fake@c.example.com:443#C');
      expect(
        await configs.replaceContent(
          id,
          expectedSourceSecretId: before,
          parsed: replaced,
          digest: 'd2',
        ),
        isFalse,
      );
      expect((await configs.content(id))!.digest, 'd1');

      expect(
        await configs.replaceContent(
          id,
          expectedSourceSecretId: await configs.sourceSecretId(id),
          parsed: replaced,
          digest: 'd2',
        ),
        isTrue,
      );
      expect((await configs.content(id))!.content.nodes.single.name, 'C');
    },
  );

  test(
    'deleting removes content, secrets, selections and memberships',
    () async {
      final baseSecrets = await count(db.secrets);
      final id = await addSubscription();
      final self = SelfContentRepository(db, secrets);
      await self.addNode(
        const SelfNode(
          id: '',
          name: 'N',
          server: 'n.example.com',
          port: 1,
          params: NodeParams.trojan(password: Secret('p')),
        ),
        joinGroup: (configurationId: id, groupKey: LinkListGroups.selectKey),
      );
      await SelectionRepository(db).select(
        id,
        LinkListGroups.selectKey,
        MemberRef.source(configurationId: id, key: 'A'),
      );
      await configs.delete(id);
      expect(await count(db.contents), 0);
      expect(await count(db.selections), 0);
      expect(await count(db.memberships), 0);
      // Only the self node's entry is left.
      expect(await count(db.secrets), baseSecrets + 1);
    },
  );

  test('a failure mid-write leaves nothing behind', () async {
    final failing = ConfigurationRepository(db, _FailingSecrets(db, vault, 2));
    await expectLater(
      failing.add(
        kind: ConfigurationKind.subscription,
        name: 'x',
        parsed: _links,
        digest: 'd',
        source: const SubscriptionSource(url: Secret('https://x.example.com')),
      ),
      throwsStateError,
    );
    expect(await count(db.configurations), 1); // only 自建节点
    expect(await count(db.contents), 0);
    expect(await count(db.secrets), 0);
  });

  group('self content', () {
    late SelfContentRepository self;
    setUp(() => self = SelfContentRepository(db, secrets));

    test('nodes used by a chain cannot be deleted', () async {
      final a = await self.addNode(
        const SelfNode(
          id: '',
          name: 'A',
          server: 'a.example.com',
          port: 443,
          params: NodeParams.trojan(password: Secret('fake-a')),
        ),
      );
      final b = await self.addNode(
        const SelfNode(
          id: '',
          name: 'B',
          server: 'b.example.com',
          port: 443,
          params: NodeParams.trojan(password: Secret('fake-b')),
        ),
      );
      final chain = await self.addChain(
        Chain(
          id: '',
          hops: [
            MemberRef.selfNode(id: a.id),
            MemberRef.selfNode(id: b.id),
          ],
        ),
      );
      expect(() => self.deleteNode(a.id), throwsA(isA<NodeInUseException>()));
      await self.deleteChain(chain.id);
      await self.deleteNode(a.id);
      expect([for (final n in await self.nodes()) n.name], ['B']);
      expect(
        (await self.nodes()).single.params,
        const NodeParams.trojan(password: Secret('fake-b')),
      );
    });

    test('chains need two valid hops', () {
      expect(
        () => self.addChain(
          const Chain(
            id: '',
            hops: [MemberRef.selfNode(id: 'a')],
          ),
        ),
        throwsA(isA<InvalidHopException>()),
      );
      expect(
        () => self.addChain(
          const Chain(
            id: '',
            hops: [
              MemberRef.selfNode(id: 'a'),
              MemberRef.builtin(builtin: Builtin.direct),
            ],
          ),
        ),
        throwsA(isA<InvalidHopException>()),
      );
    });
  });

  group('settings', () {
    late SettingsRepository settings;
    setUp(() => settings = SettingsRepository(db, secrets));

    test(
      'defaults with a generated Clash API key, stable across reads',
      () async {
        final first = await settings.device();
        expect(first.mixedPort, 7890);
        expect(first.clashApiSecret!.value.length, greaterThan(20));
        expect((await settings.device()).clashApiSecret, first.clashApiSecret);
        expect(await dump(), isNot(contains(first.clashApiSecret!.value)));
      },
    );

    test('the JSON override is stored encrypted', () async {
      await settings.updatePolicy(
        (p) => p.copyWith(
          jsonOverride: const Secret('{"route": {"final": "fake-x"}}'),
        ),
      );
      expect((await settings.policy()).jsonOverride!.value, contains('fake-x'));
      expect(await dump(), isNot(contains('fake-x')));
      await settings.updatePolicy((p) => p.copyWith(jsonOverride: null));
      expect((await settings.policy()).jsonOverride, isNull);
      expect(await count(db.secrets), 0);
    });
  });

  group('vault', () {
    test('another master key cannot open entries', () async {
      final id = await secrets.put({'s0': 'fake'});
      final other = SecretStore(db, await Vault.open(MemoryKeyStore()));
      expect(() => other.get(id), throwsA(isA<VaultLockedException>()));
    });

    test('entries cannot be moved to another id', () async {
      final id = await secrets.put({'s0': 'fake'});
      final row = await (db.select(
        db.secrets,
      )..where((s) => s.id.equals(id))).getSingle();
      expect(
        () => vault.unseal('other-id', row.nonce, row.ciphertext),
        throwsA(isA<VaultLockedException>()),
      );
    });
  });

  test('a database from a newer version is refused untouched', () async {
    final newer = AppDatabase(
      NativeDatabase.memory(
        setup: (raw) => raw.execute('PRAGMA user_version = 99'),
      ),
    );
    await expectLater(
      newer.select(newer.configurations).get(),
      throwsA(isA<DatabaseTooNewException>()),
    );
    await newer.close();
  });
}
