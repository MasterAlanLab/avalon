// All account credentials in these tests are fake.
import 'dart:convert';
import 'dart:io';

import 'package:av_core/av_core.dart';
import 'package:avalon/data/backup/backup_repository.dart';
import 'package:avalon/data/database/database.dart';
import 'package:avalon/data/repositories/cloud_session_repository.dart';
import 'package:avalon/data/repositories/configuration_repository.dart';
import 'package:avalon/data/repositories/selection_repository.dart';
import 'package:avalon/data/repositories/self_content_repository.dart';
import 'package:avalon/data/repositories/settings_repository.dart';
import 'package:avalon/data/vault/secret_store.dart';
import 'package:avalon/data/vault/vault.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FailingSecrets extends SecretStore {
  _FailingSecrets(super.db, super.vault, {this.failAtPut, this.failAtDelete});

  final int? failAtPut;
  final int? failAtDelete;
  int _puts = 0;
  int _deletes = 0;

  @override
  Future<String> put(Map<String, String> secrets) {
    if (++_puts == failAtPut) throw StateError('injected write failure');
    return super.put(secrets);
  }

  @override
  Future<void> delete(String? id) {
    if (++_deletes == failAtDelete) throw StateError('injected delete failure');
    return super.delete(id);
  }
}

StoredCloudSession _session(String installationId, {String account = 'a'}) =>
    StoredCloudSession(
      accountId: 'account-$account',
      deviceId: 'device-$account',
      sessionId: 'session-$account',
      installationId: installationId,
      accessToken: 'fake-access-token-$account',
      refreshToken: 'fake-refresh-token-$account',
      accessExpiresAt: DateTime.utc(2026, 10, 11, 10, 15),
      refreshExpiresAt: DateTime.utc(2027, 1, 9, 10),
      email: '$account@example.com',
      displayName: 'Account $account',
      entitlementJson: '{"plan":"free"}',
    );

void main() {
  late AppDatabase db;
  late Vault vault;
  late SecretStore secrets;
  late CloudSessionRepository sessions;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    vault = await Vault.open(MemoryKeyStore());
    secrets = SecretStore(db, vault);
    sessions = CloudSessionRepository(db, secrets);
  });
  tearDown(() => db.close());

  Future<Map<String, List<Map<String, Object?>>>> snapshot({
    bool includeCloud = true,
    bool includeSecrets = true,
  }) async => {
    for (final table in db.allTables)
      if ((includeCloud || table.actualTableName != 'cloud_session') &&
          (includeSecrets || table.actualTableName != 'secrets'))
        table.actualTableName: [
          for (final row
              in await db
                  .customSelect('SELECT * FROM ${table.actualTableName}')
                  .get())
            row.data,
        ],
  };

  Future<String> addConfiguration(String name) =>
      ConfigurationRepository(db, secrets).add(
        kind: ConfigurationKind.subscription,
        name: name,
        parsed: parseContent('trojan://fake-proxy-credential@proxy.test:443#N'),
        digest: 'digest-$name',
        source: const SubscriptionSource(
          url: Secret('https://subscription.test/?token=fake-subscription'),
        ),
      );

  Future<String> addNode(String name) async =>
      (await SelfContentRepository(db, secrets).addNode(
        SelfNode(
          id: '',
          name: name,
          server: 'node.test',
          port: 443,
          params: const NodeParams.trojan(password: Secret('fake-node-secret')),
        ),
      )).id;

  test('installation UUID is stable before login and after logout', () async {
    final ids = await Future.wait(
      List.generate(8, (_) => sessions.installationId()),
    );
    expect(ids.toSet(), hasLength(1));
    expect(
      ids.first,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(await sessions.read(), isNull);
    await sessions.save(_session(ids.first));
    expect(await sessions.clear(), isTrue);
    expect(await sessions.installationId(), ids.first);
    expect(await sessions.read(), isNull);
    final row = await db.select(db.cloudSession).getSingle();
    expect(row.loggedIn, isFalse);
    expect(row.accountId, isEmpty);
    expect(row.accessSecretId, isEmpty);
    expect(row.refreshSecretId, isEmpty);
    expect(await db.select(db.secrets).get(), isEmpty);
  });

  test(
    'installation and refresh uncertainty survive database restart',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'avalon-cloud-session-',
      );
      final file = File('${dir.path}/session.sqlite');
      final key = MemoryKeyStore();
      await db.close();
      var persistent = AppDatabase(NativeDatabase(file));
      try {
        var repo = CloudSessionRepository(
          persistent,
          SecretStore(persistent, await Vault.open(key)),
        );
        final id = await repo.installationId();
        await repo.save(_session(id).copyWith(refreshUncertain: true));
        await persistent.close();
        persistent = AppDatabase(NativeDatabase(file));
        repo = CloudSessionRepository(
          persistent,
          SecretStore(persistent, await Vault.open(key)),
        );
        expect(await repo.installationId(), id);
        expect((await repo.read())!.refreshUncertain, isTrue);
        expect(
          await repo.claimRefresh(
            expectedSessionId: 'session-a',
            expectedRefreshToken: 'fake-refresh-token-a',
          ),
          isFalse,
        );
        await repo.clear();
        await persistent.close();
        persistent = AppDatabase(NativeDatabase(file));
        repo = CloudSessionRepository(
          persistent,
          SecretStore(persistent, await Vault.open(key)),
        );
        expect(await repo.installationId(), id);
        expect(await repo.read(), isNull);
      } finally {
        await persistent.close();
        await dir.delete(recursive: true);
        db = AppDatabase(NativeDatabase.memory());
      }
    },
  );

  test('session round-trips with only encrypted tokens and metadata', () async {
    final expected = _session(await sessions.installationId());
    await sessions.save(expected);
    final actual = (await sessions.read())!;
    expect(actual.accountId, expected.accountId);
    expect(actual.deviceId, expected.deviceId);
    expect(actual.sessionId, expected.sessionId);
    expect(actual.accessToken, expected.accessToken);
    expect(actual.refreshToken, expected.refreshToken);
    expect(actual.accessExpiresAt, expected.accessExpiresAt);
    expect(actual.refreshExpiresAt, expected.refreshExpiresAt);
    expect(actual.accessExpiresAt.isUtc, isTrue);
    expect(actual.refreshExpiresAt.isUtc, isTrue);
    expect(actual.email, expected.email);
    expect(actual.displayName, expected.displayName);
    expect(actual.entitlementJson, expected.entitlementJson);
    expect(actual.refreshUncertain, isFalse);
    final dump = (await snapshot()).toString();
    for (final hidden in [
      expected.accessToken,
      expected.refreshToken,
      expected.sessionId,
      expected.accessExpiresAt.toIso8601String(),
      expected.refreshExpiresAt.toIso8601String(),
    ]) {
      expect(dump, isNot(contains(hidden)));
    }
    expect(actual.toString(), isNot(contains(expected.accessToken)));
    expect(actual.toString(), isNot(contains(expected.refreshToken)));
    expect(await db.select(db.secrets).get(), hasLength(2));
  });

  test('Cloud identity and credentials never enter a backup', () async {
    final current = _session(await sessions.installationId());
    await sessions.save(current);
    await addConfiguration('local');
    final backup = await BackupRepository(
      db,
      secrets,
    ).export(appVersion: 'test', platform: 'test');
    final text = jsonEncode(backup);
    for (final hidden in [
      current.installationId,
      current.sessionId,
      current.accessToken,
      current.refreshToken,
      'cloud_session',
      'installationId',
    ]) {
      expect(text, isNot(contains(hidden)));
    }
    expect(text, contains('fake-proxy-credential'));
    expect(text, contains('fake-subscription'));
  });

  test(
    'failed save rolls back new secrets and keeps the previous session',
    () async {
      final current = _session(await sessions.installationId());
      await sessions.save(current);
      final before = await snapshot();
      final failing = CloudSessionRepository(
        db,
        _FailingSecrets(db, vault, failAtPut: 2),
      );
      await expectLater(
        failing.save(_session(current.installationId, account: 'b')),
        throwsStateError,
      );
      expect(await snapshot(), equals(before));
      expect((await sessions.read())!.refreshToken, current.refreshToken);
    },
  );

  test(
    'failed old-secret deletion rolls back owner and both new secrets',
    () async {
      final current = _session(await sessions.installationId());
      await sessions.save(current);
      final before = await snapshot();
      final failing = CloudSessionRepository(
        db,
        _FailingSecrets(db, vault, failAtDelete: 2),
      );
      await expectLater(
        failing.save(_session(current.installationId, account: 'b')),
        throwsStateError,
      );
      expect(await snapshot(), equals(before));
    },
  );

  test(
    'CAS rotation rejects old refreshes and responses from another account',
    () async {
      final old = _session(await sessions.installationId());
      await sessions.save(old);
      final rotated = old.copyWith(
        accessToken: 'fake-rotated-access',
        refreshToken: 'fake-rotated-refresh',
        refreshUncertain: true,
      );
      expect(
        await sessions.replaceTokens(
          expectedSessionId: old.sessionId,
          expectedRefreshToken: old.refreshToken,
          session: rotated,
        ),
        isTrue,
      );
      expect((await sessions.read())!.refreshUncertain, isTrue);
      expect(await db.select(db.secrets).get(), hasLength(2));
      final beforeStale = await snapshot();
      expect(
        await sessions.replaceTokens(
          expectedSessionId: old.sessionId,
          expectedRefreshToken: old.refreshToken,
          session: old,
        ),
        isFalse,
      );
      expect(await snapshot(), equals(beforeStale));
      final nextAccount = _session(old.installationId, account: 'b');
      await sessions.save(nextAccount);
      expect(
        await sessions.replaceTokens(
          expectedSessionId: old.sessionId,
          expectedRefreshToken: rotated.refreshToken,
          session: rotated,
        ),
        isFalse,
      );
      expect(await sessions.clear(expectedSessionId: old.sessionId), isFalse);
      expect((await sessions.read())!.accountId, nextAccount.accountId);
    },
  );

  test(
    'logout keeps all content, proxy credentials, settings and sync state',
    () async {
      final configurationId = await addConfiguration('local');
      await addNode('local');
      await SettingsRepository(db, secrets).device();
      await SettingsRepository(db, secrets).updatePolicy(
        (policy) =>
            policy.copyWith(jsonOverride: const Secret('{"local":true}')),
      );
      await SelectionRepository(db).select(
        configurationId,
        LinkListGroups.selectKey,
        MemberRef.source(configurationId: configurationId, key: 'N'),
      );
      await db
          .update(db.configurations)
          .write(
            const ConfigurationsCompanion(cloudAccountId: Value('account-a')),
          );
      await db
          .into(db.syncMeta)
          .insert(
            SyncMetaCompanion.insert(
              documentId: 'test-document-$configurationId',
              recordId: configurationId,
              type: 'configuration',
              accountId: 'account-a',
              dirty: true,
              deleted: false,
              editedAt: 123,
            ),
          );
      await db
          .into(db.syncState)
          .insert(
            SyncStateCompanion.insert(accountId: 'account-a', cursor: 42),
          );
      final before = await snapshot(includeCloud: false);
      final current = _session(await sessions.installationId());
      await sessions.save(current);
      expect(
        await sessions.clear(expectedSessionId: current.sessionId),
        isTrue,
      );
      expect(await snapshot(includeCloud: false), equals(before));
      expect(await sessions.installationId(), current.installationId);
      expect(await secrets.deleteOrphans(), 0);
    },
  );

  test(
    'logout deletion failure restores session and both encrypted secrets',
    () async {
      final current = _session(await sessions.installationId());
      await sessions.save(current);
      final before = await snapshot();
      final failing = CloudSessionRepository(
        db,
        _FailingSecrets(db, vault, failAtDelete: 2),
      );
      await expectLater(failing.clear(), throwsStateError);
      expect(await snapshot(), equals(before));
      expect((await sessions.read())!.accessToken, current.accessToken);
    },
  );

  test(
    'failed CAS rotation rolls back credentials and uncertainty flag',
    () async {
      final current = _session(await sessions.installationId());
      await sessions.save(current);
      final before = await snapshot();
      final failing = CloudSessionRepository(
        db,
        _FailingSecrets(db, vault, failAtDelete: 2),
      );
      await expectLater(
        failing.replaceTokens(
          expectedSessionId: current.sessionId,
          expectedRefreshToken: current.refreshToken,
          session: current.copyWith(
            accessToken: 'fake-new-access',
            refreshToken: 'fake-new-refresh',
            refreshUncertain: true,
          ),
        ),
        throwsStateError,
      );
      expect(await snapshot(), equals(before));
      expect((await sessions.read())!.refreshUncertain, isFalse);
    },
  );

  test(
    'independent repositories can claim the same refresh only once',
    () async {
      final current = _session(await sessions.installationId());
      await sessions.save(current);
      final another = CloudSessionRepository(db, secrets);
      final claims = await Future.wait([
        sessions.claimRefresh(
          expectedSessionId: current.sessionId,
          expectedRefreshToken: current.refreshToken,
        ),
        another.claimRefresh(
          expectedSessionId: current.sessionId,
          expectedRefreshToken: current.refreshToken,
        ),
      ]);
      expect(claims.where((claimed) => claimed), hasLength(1));
      expect((await sessions.read())!.refreshUncertain, isTrue);
      final beforeRetry = await snapshot();
      expect(
        await CloudSessionRepository(db, secrets).claimRefresh(
          expectedSessionId: current.sessionId,
          expectedRefreshToken: current.refreshToken,
        ),
        isFalse,
      );
      expect(await snapshot(), equals(beforeRetry));
      expect(await db.select(db.secrets).get(), hasLength(2));
      expect(await secrets.deleteOrphans(), 0);
    },
  );

  test(
    'claim rejects stale credentials and rolls back a failed guard write',
    () async {
      final current = _session(await sessions.installationId());
      await sessions.save(current);
      final before = await snapshot();
      expect(
        await sessions.claimRefresh(
          expectedSessionId: 'stale-session',
          expectedRefreshToken: current.refreshToken,
        ),
        isFalse,
      );
      expect(
        await sessions.claimRefresh(
          expectedSessionId: current.sessionId,
          expectedRefreshToken: 'fake-stale-refresh-token',
        ),
        isFalse,
      );
      expect(await snapshot(), equals(before));
      final failing = CloudSessionRepository(
        db,
        _FailingSecrets(db, vault, failAtPut: 2),
      );
      await expectLater(
        failing.claimRefresh(
          expectedSessionId: current.sessionId,
          expectedRefreshToken: current.refreshToken,
        ),
        throwsStateError,
      );
      expect(await snapshot(), equals(before));
      expect((await sessions.read())!.refreshUncertain, isFalse);
      expect(
        await sessions.claimRefresh(
          expectedSessionId: current.sessionId,
          expectedRefreshToken: current.refreshToken,
        ),
        isTrue,
      );
    },
  );

  test(
    'profile merge cannot overwrite an already claimed refresh guard',
    () async {
      final current = _session(await sessions.installationId());
      await sessions.save(current);
      final oldSnapshot = (await sessions.read())!;
      expect(oldSnapshot.refreshUncertain, isFalse);
      final another = CloudSessionRepository(db, secrets);
      expect(
        await another.claimRefresh(
          expectedSessionId: oldSnapshot.sessionId,
          expectedRefreshToken: oldSnapshot.refreshToken,
        ),
        isTrue,
      );
      final secretRows = await db.select(db.secrets).get();
      expect(
        await sessions.updateProfile(
          expectedSessionId: oldSnapshot.sessionId,
          email: 'updated@example.com',
          displayName: 'Updated profile',
          entitlementJson: 'null',
        ),
        isTrue,
      );
      final merged = (await sessions.read())!;
      expect(merged.refreshUncertain, isTrue);
      expect(merged.accessToken, current.accessToken);
      expect(merged.refreshToken, current.refreshToken);
      expect(merged.email, 'updated@example.com');
      expect(merged.displayName, 'Updated profile');
      expect(merged.entitlementJson, 'null');
      expect(await db.select(db.secrets).get(), equals(secretRows));
      expect(
        await another.claimRefresh(
          expectedSessionId: merged.sessionId,
          expectedRefreshToken: merged.refreshToken,
        ),
        isFalse,
      );
    },
  );

  test(
    'profile merge preserves rotated credentials and rejects new sessions',
    () async {
      final current = _session(await sessions.installationId());
      await sessions.save(current);
      final rotated = current.copyWith(
        accessToken: 'fake-new-profile-access',
        refreshToken: 'fake-new-profile-refresh',
      );
      expect(
        await sessions.replaceTokens(
          expectedSessionId: current.sessionId,
          expectedRefreshToken: current.refreshToken,
          session: rotated,
        ),
        isTrue,
      );
      expect(
        await sessions.updateProfile(
          expectedSessionId: current.sessionId,
          email: 'profile@example.com',
          displayName: 'Profile after rotation',
          entitlementJson: '{"plan":"plus"}',
        ),
        isTrue,
      );
      expect((await sessions.read())!.accessToken, rotated.accessToken);
      expect((await sessions.read())!.refreshToken, rotated.refreshToken);
      await sessions.save(
        current.copyWith(
          sessionId: 'new-login-same-account',
          refreshToken: 'fake-new-login',
        ),
      );
      final beforeStale = await snapshot();
      expect(
        await sessions.updateProfile(
          expectedSessionId: current.sessionId,
          email: 'stale@example.com',
          displayName: 'Stale profile',
          entitlementJson: 'null',
        ),
        isFalse,
      );
      expect(await snapshot(), equals(beforeStale));
      await sessions.clear();
      expect(
        await sessions.updateProfile(
          expectedSessionId: 'new-login-same-account',
          email: 'stale@example.com',
          displayName: 'Stale profile',
          entitlementJson: 'null',
        ),
        isFalse,
      );
    },
  );

  test(
    'an explicit known refresh rejection can reset the guard for another claim',
    () async {
      final current = _session(await sessions.installationId());
      await sessions.save(current);
      expect(
        await sessions.claimRefresh(
          expectedSessionId: current.sessionId,
          expectedRefreshToken: current.refreshToken,
        ),
        isTrue,
      );
      final guarded = (await sessions.read())!;
      expect(
        await sessions.replaceTokens(
          expectedSessionId: current.sessionId,
          expectedRefreshToken: current.refreshToken,
          session: guarded.copyWith(refreshUncertain: false),
        ),
        isTrue,
      );
      expect((await sessions.read())!.refreshUncertain, isFalse);
      expect(
        await CloudSessionRepository(db, secrets).claimRefresh(
          expectedSessionId: current.sessionId,
          expectedRefreshToken: current.refreshToken,
        ),
        isTrue,
      );
    },
  );

  test('explicit logout works after loss of the Vault key', () async {
    final current = _session(await sessions.installationId());
    await sessions.save(current);
    final locked = CloudSessionRepository(
      db,
      SecretStore(db, await Vault.open(MemoryKeyStore())),
    );
    await expectLater(locked.read(), throwsA(isA<VaultLockedException>()));
    expect(await locked.clear(), isTrue);
    expect(await locked.installationId(), current.installationId);
    expect(await locked.read(), isNull);
    expect(await db.select(db.secrets).get(), isEmpty);
  });

  test('orphan cleanup preserves both Cloud token entries', () async {
    final current = _session(await sessions.installationId());
    await sessions.save(current);
    await secrets.put({'unused': 'fake-orphan'});
    expect(await secrets.deleteOrphans(), 1);
    expect(await db.select(db.secrets).get(), hasLength(2));
    expect((await sessions.read())!.refreshToken, current.refreshToken);
  });

  test(
    'account deletion detaches only the deleted account, preserving local data',
    () async {
      final oldConfig = await addConfiguration('old');
      final newConfig = await addConfiguration('new');
      final oldNode = await addNode('old');
      final newNode = await addNode('new');
      final chain = await SelfContentRepository(db, secrets).addChain(
        Chain(
          id: '',
          hops: [
            MemberRef.selfNode(id: oldNode),
            MemberRef.selfNode(id: newNode),
          ],
        ),
      );
      await SelectionRepository(db).select(
        oldConfig,
        LinkListGroups.selectKey,
        MemberRef.source(configurationId: oldConfig, key: 'N'),
      );
      await SettingsRepository(db, secrets).updatePolicy((policy) => policy);
      for (final binding in [
        (id: oldConfig, account: 'account-a'),
        (id: newConfig, account: 'account-b'),
      ]) {
        await (db.update(
          db.configurations,
        )..where((r) => r.id.equals(binding.id))).write(
          ConfigurationsCompanion(cloudAccountId: Value(binding.account)),
        );
        await db
            .into(db.syncMeta)
            .insert(
              SyncMetaCompanion.insert(
                documentId: 'test-document-${binding.id}',
                recordId: binding.id,
                type: 'configuration',
                accountId: binding.account,
                dirty: true,
                deleted: false,
                editedAt: 123,
              ),
            );
        await db
            .into(db.syncState)
            .insert(
              SyncStateCompanion.insert(accountId: binding.account, cursor: 42),
            );
      }
      for (final binding in [
        (id: oldNode, account: 'account-a'),
        (id: newNode, account: 'account-b'),
      ]) {
        await (db.update(db.selfNodes)..where((r) => r.id.equals(binding.id)))
            .write(SelfNodesCompanion(cloudAccountId: Value(binding.account)));
      }
      await (db.update(db.chains)..where((r) => r.id.equals(chain.id))).write(
        const ChainsCompanion(cloudAccountId: Value('account-a')),
      );
      await db
          .update(db.selections)
          .write(const SelectionsCompanion(cloudAccountId: Value('account-a')));
      await db
          .update(db.policyTable)
          .write(
            const PolicyTableCompanion(cloudAccountId: Value('account-a')),
          );
      final active = _session(await sessions.installationId(), account: 'b');
      await sessions.save(active);
      final before = await snapshot();
      await sessions.detachAccount('account-a');
      final after = await snapshot();
      for (final entry in before.entries) {
        if ({
          'sync_meta',
          'sync_state',
          'sync_archives',
          'sync_archive_references',
          'secrets',
        }.contains(entry.key)) {
          continue;
        }
        final expected = [
          for (final row in entry.value)
            if (row['cloud_account_id'] == 'account-a')
              {...row, 'cloud_account_id': null}
            else
              row,
        ];
        expect(after[entry.key], equals(expected), reason: entry.key);
      }
      expect((await db.select(db.syncMeta).get()).map((row) => row.accountId), [
        'account-b',
      ]);
      expect(
        (await db.select(db.syncState).get()).map((row) => row.accountId),
        ['account-b'],
      );
      final archive = await db.select(db.syncArchives).getSingle();
      expect(archive.accountId, 'account-a');
      final material =
          jsonDecode((await secrets.get(archive.payloadSecretId))['archive']!)
              as Map;
      expect(material['reason'], 'account_deleted');
      expect((material['state'] as Map)['cursor'], 42);
      expect(
        ((material['outbox'] as List).single as Map)['accountId'],
        'account-a',
      );
      expect(await db.select(db.syncArchiveReferences).get(), isEmpty);
      final oldSecrets = before['secrets']!;
      final newSecrets = after['secrets']!;
      expect(newSecrets, hasLength(oldSecrets.length + 1));
      for (final original in oldSecrets) {
        expect(
          newSecrets.singleWhere((row) => row['id'] == original['id']),
          original,
        );
      }
      expect(await secrets.deleteOrphans(), 0);
      expect((await sessions.read())!.accountId, active.accountId);
    },
  );

  test(
    'local logout encrypts the proof, retaining only Cloud queue ownership',
    () async {
      await addConfiguration('local');
      final localBefore = await snapshot(includeCloud: false);
      final current = _session(await sessions.installationId());
      await sessions.save(current);
      final proof = await sessions.logoutLocally();
      expect(proof!.sessionId, current.sessionId);
      expect(proof.refreshToken, current.refreshToken);
      expect(proof.refreshExpiresAt, current.refreshExpiresAt);
      expect(proof.toString(), isNot(contains(current.refreshToken)));
      expect(await sessions.read(), isNull);
      expect(await sessions.installationId(), current.installationId);
      expect(await sessions.logoutLocally(), isNull);
      final pending = await sessions.pendingRevocations();
      expect(pending, hasLength(1));
      expect(pending.single.refreshToken, current.refreshToken);
      expect(pending.single.refreshExpiresAt, current.refreshExpiresAt);
      final after = await snapshot(includeCloud: false);
      for (final entry in localBefore.entries) {
        if (entry.key != 'secrets') {
          expect(after[entry.key], equals(entry.value), reason: entry.key);
        } else {
          for (final secret in entry.value) {
            expect(after['secrets'], contains(equals(secret)));
          }
          expect(after['secrets'], hasLength(entry.value.length + 1));
        }
      }
      final owner = await (db.select(
        db.cloudSession,
      )..where((row) => row.id.equals(2))).getSingle();
      expect(owner.loggedIn, isFalse);
      expect(owner.accessSecretId, isEmpty);
      expect(owner.refreshSecretId, isNotEmpty);
      expect(owner.accountId, isEmpty);
      expect(owner.installationId, isEmpty);
      final dump = (await snapshot()).toString();
      expect(dump, isNot(contains(current.refreshToken)));
      expect(dump, isNot(contains(current.accessToken)));
      expect(dump, isNot(contains(current.sessionId)));
      final backup = jsonEncode(
        await BackupRepository(
          db,
          secrets,
        ).export(appVersion: 'test', platform: 'test'),
      );
      expect(backup, isNot(contains(current.refreshToken)));
      expect(backup, isNot(contains(current.sessionId)));
      expect(backup, isNot(contains('pending')));
      expect(await secrets.deleteOrphans(), 0);
    },
  );

  test(
    'pending proof survives restart alongside a different active account',
    () async {
      final dir = await Directory.systemTemp.createTemp(
        'avalon-cloud-pending-',
      );
      final file = File('${dir.path}/session.sqlite');
      final key = MemoryKeyStore();
      await db.close();
      var persistent = AppDatabase(NativeDatabase(file));
      try {
        var repo = CloudSessionRepository(
          persistent,
          SecretStore(persistent, await Vault.open(key)),
        );
        final id = await repo.installationId();
        final old = _session(id);
        await repo.save(old);
        await repo.logoutLocally();
        await repo.save(_session(id, account: 'b'));
        await persistent.close();
        persistent = AppDatabase(NativeDatabase(file));
        repo = CloudSessionRepository(
          persistent,
          SecretStore(persistent, await Vault.open(key)),
        );
        expect(await repo.installationId(), id);
        expect((await repo.read())!.accountId, 'account-b');
        final pending = await repo.pendingRevocations();
        expect(pending, hasLength(1));
        expect(pending.single.sessionId, old.sessionId);
        expect(pending.single.refreshToken, old.refreshToken);
        expect(pending.single.refreshExpiresAt, old.refreshExpiresAt);
        await repo.clear();
        await persistent.close();
        persistent = AppDatabase(NativeDatabase(file));
        repo = CloudSessionRepository(
          persistent,
          SecretStore(persistent, await Vault.open(key)),
        );
        expect(await repo.read(), isNull);
        expect(await repo.installationId(), id);
        expect(
          (await repo.pendingRevocations()).single.refreshToken,
          old.refreshToken,
        );
        expect(
          (await repo.pendingRevocations()).single.refreshExpiresAt,
          old.refreshExpiresAt,
        );
      } finally {
        await persistent.close();
        await dir.delete(recursive: true);
        db = AppDatabase(NativeDatabase.memory());
      }
    },
  );

  test(
    'save, rotation, clear and detach preserve earlier logout proofs',
    () async {
      final old = _session(await sessions.installationId());
      await sessions.save(old);
      await sessions.logoutLocally();
      final ownerBefore = await (db.select(
        db.cloudSession,
      )..where((row) => row.id.equals(2))).getSingle();
      final newAccount = _session(old.installationId, account: 'b');
      await sessions.save(newAccount);
      expect(
        await sessions.replaceTokens(
          expectedSessionId: newAccount.sessionId,
          expectedRefreshToken: newAccount.refreshToken,
          session: newAccount.copyWith(
            refreshToken: 'fake-rotated-b-refresh',
            refreshExpiresAt: newAccount.refreshExpiresAt.add(
              const Duration(days: 30),
            ),
          ),
        ),
        isTrue,
      );
      await sessions.detachAccount(old.accountId);
      await sessions.clear(expectedSessionId: newAccount.sessionId);
      expect(
        (await sessions.pendingRevocations()).single.sessionId,
        old.sessionId,
      );
      expect(
        await (db.select(
          db.cloudSession,
        )..where((row) => row.id.equals(2))).getSingle(),
        ownerBefore,
      );
      expect(await sessions.pendingRevocations(), hasLength(1));
      expect(
        (await sessions.pendingRevocations()).single.refreshExpiresAt,
        old.refreshExpiresAt,
      );
      expect(await db.select(db.secrets).get(), hasLength(1));
      expect(await secrets.deleteOrphans(), 0);
    },
  );

  test(
    'queuing the same session twice deduplicates and keeps its newest proof',
    () async {
      final current = _session(await sessions.installationId());
      await sessions.save(current);
      await sessions.logoutLocally();
      await sessions.save(current.copyWith(refreshToken: 'fake-newest-proof'));
      await sessions.logoutLocally();
      final pending = await sessions.pendingRevocations();
      expect(pending, hasLength(1));
      expect(pending.single.sessionId, current.sessionId);
      expect(pending.single.refreshToken, 'fake-newest-proof');
      expect(await db.select(db.secrets).get(), hasLength(1));
      expect(await secrets.deleteOrphans(), 0);
    },
  );

  test(
    'acknowledgement removes only that proof and never the active account',
    () async {
      final id = await sessions.installationId();
      for (final account in ['a', 'b']) {
        await sessions.save(_session(id, account: account));
        await sessions.logoutLocally();
      }
      await sessions.save(_session(id, account: 'c'));
      final activeBefore = await (db.select(
        db.cloudSession,
      )..where((row) => row.id.equals(1))).getSingle();
      await sessions.completeRevocation('session-a');
      expect(
        (await sessions.pendingRevocations()).single.sessionId,
        'session-b',
      );
      expect(await db.select(db.secrets).get(), hasLength(3));
      final beforeUnknown = await snapshot();
      await sessions.completeRevocation('session-a');
      await sessions.completeRevocation('unknown-session');
      expect(await snapshot(), equals(beforeUnknown));
      await sessions.completeRevocation('session-b');
      expect(await sessions.pendingRevocations(), isEmpty);
      expect(
        await (db.select(
          db.cloudSession,
        )..where((row) => row.id.equals(2))).get(),
        isEmpty,
      );
      expect(await db.select(db.secrets).get(), hasLength(2));
      expect(
        await (db.select(
          db.cloudSession,
        )..where((row) => row.id.equals(1))).getSingle(),
        activeBefore,
      );
      expect((await sessions.read())!.refreshToken, 'fake-refresh-token-c');
      expect(await secrets.deleteOrphans(), 0);
    },
  );

  test(
    'a stale token acknowledgement preserves the newer proof of the same session',
    () async {
      final current = _session(await sessions.installationId());
      await sessions.save(current);
      await sessions.logoutLocally();
      final replacement = current.copyWith(
        refreshToken: 'fake-newest-proof',
        refreshExpiresAt: current.refreshExpiresAt.add(const Duration(days: 1)),
      );
      await sessions.save(replacement);
      await sessions.logoutLocally();
      final before = await snapshot();

      await sessions.completeRevocation(
        current.sessionId,
        expectedRefreshToken: current.refreshToken,
      );
      expect(await snapshot(), equals(before));
      final retained = (await sessions.pendingRevocations()).single;
      expect(retained.refreshToken == replacement.refreshToken, isTrue);
      expect(retained.refreshExpiresAt, replacement.refreshExpiresAt);
      await sessions.completeRevocation(
        replacement.sessionId,
        expectedRefreshToken: replacement.refreshToken,
      );
      expect(await sessions.pendingRevocations(), isEmpty);
      expect(await db.select(db.secrets).get(), isEmpty);
    },
  );

  test('legacy encrypted proof without expiry remains readable', () async {
    final current = _session(await sessions.installationId());
    await sessions.save(current);
    await sessions.logoutLocally();
    final owner = await (db.select(
      db.cloudSession,
    )..where((row) => row.id.equals(2))).getSingle();
    final legacy = await secrets.put({
      'pending': jsonEncode([
        {'sessionId': current.sessionId, 'refreshToken': current.refreshToken},
      ]),
    });
    await (db.update(db.cloudSession)..where((row) => row.id.equals(2))).write(
      CloudSessionCompanion(refreshSecretId: Value(legacy)),
    );
    await secrets.delete(owner.refreshSecretId);

    final reopened = CloudSessionRepository(db, secrets);
    final pending = (await reopened.pendingRevocations()).single;
    expect(pending.sessionId, current.sessionId);
    expect(pending.refreshToken == current.refreshToken, isTrue);
    expect(pending.refreshExpiresAt, isNull);
    await reopened.completeRevocation(
      pending.sessionId,
      expectedRefreshToken: pending.refreshToken,
    );
    expect(await reopened.pendingRevocations(), isEmpty);
  });

  test('invalid decrypted proof expiry reports no secret input', () async {
    final current = _session(await sessions.installationId());
    await sessions.save(current);
    await sessions.logoutLocally();
    for (final invalidExpiry in [
      'not-a-date-${current.refreshToken}',
      123,
      <String, Object?>{'secret': current.refreshToken},
    ]) {
      final owner = await (db.select(
        db.cloudSession,
      )..where((row) => row.id.equals(2))).getSingle();
      final invalid = await secrets.put({
        'pending': jsonEncode([
          {
            'sessionId': current.sessionId,
            'refreshToken': current.refreshToken,
            'refreshExpiresAt': invalidExpiry,
          },
        ]),
      });
      await (db.update(db.cloudSession)..where((row) => row.id.equals(2)))
          .write(CloudSessionCompanion(refreshSecretId: Value(invalid)));
      await secrets.delete(owner.refreshSecretId);
      try {
        await sessions.pendingRevocations();
        fail('Invalid queue expiry must be rejected.');
      } on FormatException catch (error) {
        expect(error.toString().contains(current.refreshToken), isFalse);
        expect(error.toString().contains('not-a-date'), isFalse);
      }
    }
  });

  test(
    'queue write failure keeps the active session and leaves no proof',
    () async {
      final current = _session(await sessions.installationId());
      await sessions.save(current);
      final before = await snapshot();
      final failing = CloudSessionRepository(
        db,
        _FailingSecrets(db, vault, failAtPut: 1),
      );
      await expectLater(failing.logoutLocally(), throwsStateError);
      expect(await snapshot(), equals(before));
      expect(await sessions.pendingRevocations(), isEmpty);
      expect((await sessions.read())!.refreshToken, current.refreshToken);
    },
  );

  test(
    'queue replacement and active-secret deletion roll back together',
    () async {
      final id = await sessions.installationId();
      await sessions.save(_session(id));
      await sessions.logoutLocally();
      await sessions.save(_session(id, account: 'b'));
      final before = await snapshot();
      final failing = CloudSessionRepository(
        db,
        _FailingSecrets(db, vault, failAtDelete: 2),
      );
      await expectLater(failing.logoutLocally(), throwsStateError);
      expect(await snapshot(), equals(before));
      expect((await sessions.read())!.accountId, 'account-b');
      expect(
        (await sessions.pendingRevocations()).single.sessionId,
        'session-a',
      );
    },
  );

  test(
    'failed acknowledgement keeps the entire queue and its old secret',
    () async {
      final id = await sessions.installationId();
      for (final account in ['a', 'b']) {
        await sessions.save(_session(id, account: account));
        await sessions.logoutLocally();
      }
      for (final failure in [
        _FailingSecrets(db, vault, failAtPut: 1),
        _FailingSecrets(db, vault, failAtDelete: 1),
      ]) {
        final before = await snapshot();
        final failing = CloudSessionRepository(db, failure);
        await expectLater(
          failing.completeRevocation('session-a'),
          throwsStateError,
        );
        expect(await snapshot(), equals(before));
      }
      await sessions.completeRevocation('session-a');
      final beforeLast = await snapshot();
      final failing = CloudSessionRepository(
        db,
        _FailingSecrets(db, vault, failAtDelete: 1),
      );
      await expectLater(
        failing.completeRevocation('session-b'),
        throwsStateError,
      );
      expect(await snapshot(), equals(beforeLast));
    },
  );

  test(
    'a malformed decrypted queue never exposes the proof in errors',
    () async {
      final current = _session(await sessions.installationId());
      await sessions.save(current);
      await sessions.logoutLocally();
      final invalid = await secrets.put({
        'pending': '[{"refreshToken":"${current.refreshToken}"',
      });
      await (db.update(db.cloudSession)..where((row) => row.id.equals(2)))
          .write(CloudSessionCompanion(refreshSecretId: Value(invalid)));
      try {
        await sessions.pendingRevocations();
        fail('malformed queue must be rejected');
      } on FormatException catch (error) {
        expect(error.toString(), isNot(contains(current.refreshToken)));
      }
    },
  );
}
