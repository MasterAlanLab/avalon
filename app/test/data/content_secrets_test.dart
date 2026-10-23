import 'dart:convert';

import 'package:av_core/av_core.dart';
import 'package:avalon/data/backup/backup_repository.dart';
import 'package:avalon/data/database/database.dart';
import 'package:avalon/data/repositories/configuration_repository.dart';
import 'package:avalon/data/repositories/rule_resource_repository.dart';
import 'package:avalon/data/repositories/self_content_repository.dart';
import 'package:avalon/data/vault/content_secrets.dart';
import 'package:avalon/data/vault/secret_store.dart';
import 'package:avalon/data/vault/vault.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const _testUrl = 'https://probe.example.com/check?auth=private-probe-token';
const _ruleUrl = 'https://rules.example.com/data?auth=private-rule-token';
const _username = 'private-http-username';
const _password = 'private-http-password';

const _params = NodeParams.http(
  username: _username,
  password: Secret(_password),
);
const _content = ConfigContent(
  nodes: [
    NodeDef(
      key: 'http',
      name: 'HTTP',
      server: 'proxy.example.com',
      port: 443,
      params: _params,
    ),
  ],
  groups: [
    GroupDef(
      key: 'test',
      name: 'Test',
      type: GroupType.urltest,
      displayType: 'URLTest',
      members: ['http'],
      test: GroupTest(url: _testUrl),
    ),
  ],
  ruleSets: [
    RuleSetRef(
      tag: 'private-rules',
      url: _ruleUrl,
      format: RuleSetFormat.binary,
    ),
  ],
  finalTarget: 'test',
);

Future<String> _dump(AppDatabase db) async {
  final text = StringBuffer();
  for (final table in db.allTables) {
    final rows = await db
        .customSelect('SELECT * FROM ${table.actualTableName}')
        .get();
    for (final row in rows) {
      text.writeln(row.data.values.join('|'));
    }
  }
  return text.toString();
}

void _expectEncrypted(String dump) {
  for (final credential in [
    _testUrl,
    _ruleUrl,
    'private-probe-token',
    'private-rule-token',
    _username,
    _password,
  ]) {
    expect(dump, isNot(contains(credential)), reason: credential);
  }
}

void main() {
  test(
    'legacy and protected content preserve String fields and Secret values',
    () {
      final model = _content.toJson();
      final legacy = SecretCodec.split(model);
      final protected = ContentSecrets.split(model);

      expect(legacy.secrets.values, [_password]);
      expect(protected.secrets.values.toSet(), {
        _username,
        _password,
        _testUrl,
        _ruleUrl,
      });
      expect(ContentSecrets.join(legacy.public, legacy.secrets), model);
      expect(ContentSecrets.join(protected.public, protected.secrets), model);

      final resealed = ContentSecrets.split(
        ContentSecrets.join(protected.public, protected.secrets),
      );
      expect(resealed.public, protected.public);
      expect(resealed.secrets, protected.secrets);
    },
  );

  test('an incomplete secret entry fails instead of losing a URL', () {
    final protected = ContentSecrets.split(_content.toJson());
    expect(() => ContentSecrets.join(protected.public, {}), throwsStateError);
  });

  group('encrypted database projections and schema 1 backups', () {
    late AppDatabase db;
    late SecretStore secrets;
    late ConfigurationRepository configurations;
    late SelfContentRepository selfContent;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      secrets = SecretStore(db, await Vault.open(MemoryKeyStore()));
      configurations = ConfigurationRepository(db, secrets);
      selfContent = SelfContentRepository(db, secrets);
    });
    tearDown(() => db.close());

    Future<String> populate() async {
      final id = await configurations.add(
        kind: ConfigurationKind.file,
        name: 'Private resources',
        parsed: const ParsedContent(ContentFormat.singBox, _content),
        digest: 'test-digest',
      );
      await selfContent.addNode(
        const SelfNode(
          id: '',
          name: 'HTTP',
          server: 'proxy.example.com',
          port: 443,
          params: _params,
        ),
      );
      return id;
    }

    test(
      'all SQLite cells omit URL tokens and usernames after real writes',
      () async {
        final id = await populate();
        expect((await configurations.content(id))!.content, _content);
        expect((await selfContent.nodes()).single.params, _params);
        _expectEncrypted(await _dump(db));
      },
    );

    test(
      'export still opens with a schema 1 SecretCodec-only reader',
      () async {
        await populate();
        final backup = await BackupRepository(
          db,
          secrets,
        ).export(appVersion: 'test', platform: 'test');
        expect(backup['schema'], 1);
        final secretEntries =
            backup['secrets']! as Map<String, Map<String, String>>;
        final contentRow = (backup['contents']! as List).single as Map;
        final nodeRow = (backup['selfNodes']! as List).single as Map;

        // This is the old reader's code path, without the new String lifting.
        final decodedContent = ConfigContent.fromJson(
          SecretCodec.join(
                jsonDecode(contentRow['modelJson'] as String),
                secretEntries[contentRow['secretId']]!,
              )!
              as Map<String, dynamic>,
        );
        final decodedParams = NodeParams.fromJson(
          SecretCodec.join(
                jsonDecode(nodeRow['paramsJson'] as String),
                secretEntries[nodeRow['secretId']]!,
              )!
              as Map<String, dynamic>,
        );
        expect(decodedContent, _content);
        expect(decodedParams, _params);
        _expectEncrypted(await _dump(db));
      },
    );

    test(
      'legacy schema 1 backups reseal String credentials on restore',
      () async {
        final id = await populate();
        final backups = BackupRepository(db, secrets);
        final backup = await backups.export(
          appVersion: 'old',
          platform: 'test',
        );
        final entries = backup['secrets']! as Map<String, Map<String, String>>;
        final contentRow = (backup['contents']! as List).single as Map;
        expect(contentRow['modelJson'], contains(_testUrl));
        expect(contentRow['modelJson'], contains(_ruleUrl));
        expect(entries[contentRow['secretId']]!.values, [_password]);

        await configurations.delete(id);
        for (final node in await selfContent.nodes()) {
          await selfContent.deleteNode(node.id);
        }
        await backups.restore(backup);
        expect((await configurations.content(id))!.content, _content);
        expect((await selfContent.nodes()).single.params, _params);
        _expectEncrypted(await _dump(db));
        // Repeated restore does not double-lift URLs or lose password refs.
        await backups.restore(backup);
        expect((await configurations.content(id))!.content, _content);
        _expectEncrypted(await _dump(db));
      },
    );
  });

  group('opaque rule cache keys', () {
    late AppDatabase db;
    late RuleResourceRepository cache;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      cache = RuleResourceRepository(db);
    });
    tearDown(() => db.close());

    const rule = RuleSetRef(
      tag: 'rules',
      url: _ruleUrl,
      format: RuleSetFormat.binary,
    );

    test(
      'successful and failed downloads never store credential addresses',
      () async {
        await cache.saved(
          rule,
          file: 'verified.srs',
          sha256: 'digest',
          size: 123,
        );
        await cache.failed(rule, 'fetch.timeout');
        await cache.failed(
          rule.copyWith(format: RuleSetFormat.source),
          'resource.format',
        );

        final rows = await db.select(db.ruleResources).get();
        expect(rows, hasLength(2));
        expect(rows.map((row) => row.url).toSet(), {
          ruleSetAddressKey(_ruleUrl),
        });
        final cached = await cache.all();
        expect(cached[ruleSetKey(rule)]!.file, 'verified.srs');
        expect(cached[ruleSetKey(rule)]!.lastError, 'fetch.timeout');
        _expectEncrypted(await _dump(db));
      },
    );

    test('legacy cleanup merges latest content and attempt once', () async {
      await db
          .into(db.ruleResources)
          .insert(
            RuleResourcesCompanion.insert(
              url: _ruleUrl,
              format: RuleSetFormat.binary.name,
              file: const Value('old.srs'),
              sha256: const Value('old-digest'),
              size: const Value(100),
              updatedAt: const Value(100),
              checkedAt: const Value(300),
              lastError: const Value('fetch.timeout'),
            ),
          );
      await db
          .into(db.ruleResources)
          .insert(
            RuleResourcesCompanion.insert(
              url: ruleSetAddressKey(_ruleUrl),
              format: RuleSetFormat.binary.name,
              file: const Value('new.srs'),
              sha256: const Value('new-digest'),
              size: const Value(200),
              updatedAt: const Value(200),
              checkedAt: const Value(200),
              skipped: const Value(2),
            ),
          );
      // Formats remain separate even when they fetch the same address.
      await db
          .into(db.ruleResources)
          .insert(
            RuleResourcesCompanion.insert(
              url: _ruleUrl,
              format: RuleSetFormat.source.name,
              checkedAt: const Value(400),
              lastError: const Value('resource.format'),
            ),
          );

      await cache.obscureLegacyAddresses();
      final item = (await cache.all())[ruleSetKey(rule)]!;
      expect(
        (item.file, item.sha256, item.size, item.skipped),
        ('new.srs', 'new-digest', 200, 2),
      );
      expect(item.updatedAt!.millisecondsSinceEpoch, 200);
      expect(item.checkedAt!.millisecondsSinceEpoch, 300);
      expect(item.lastError, 'fetch.timeout');
      _expectEncrypted(await _dump(db));
      final first = (await db.select(db.ruleResources).get())
          .map((r) => r.toJson())
          .toList();
      await cache.obscureLegacyAddresses();
      expect(
        (await db.select(db.ruleResources).get())
            .map((r) => r.toJson())
            .toList(),
        first,
      );
    });
  });
}
