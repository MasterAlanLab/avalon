import 'package:av_core/av_core.dart';
import 'package:avalon/cloud/sync_models.dart';
import 'package:avalon/data/database/database.dart';
import 'package:avalon/data/repositories/cloud_session_repository.dart';
import 'package:avalon/data/repositories/configuration_repository.dart';
import 'package:avalon/data/repositories/selection_repository.dart';
import 'package:avalon/data/repositories/self_content_repository.dart';
import 'package:avalon/data/repositories/settings_repository.dart';
import 'package:avalon/data/repositories/sync_projection.dart';
import 'package:avalon/data/repositories/sync_repository.dart';
import 'package:avalon/data/vault/secret_store.dart';
import 'package:avalon/data/vault/vault.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const _nodeId = '00000000-0000-4000-8000-000000000001';
const _configId = '00000000-0000-4000-8000-000000000002';
const _url = 'https://subscription.example.com/api?token=test-private-token';
final _parsed = parseContent(
  'trojan://test-password@node.example.com:443#test',
);

void main() {
  late AppDatabase db;
  late SecretStore secrets;
  late SyncRepository sync;
  late SyncProjection projection;
  late ConfigurationRepository configs;
  late SelfContentRepository self;
  late SettingsRepository settings;
  late SelectionRepository selections;
  late CloudSessionRepository sessions;
  late SyncIdentity identity;

  Future<void> login(String account) async {
    final installation = await sessions.installationId();
    await sessions.save(
      StoredCloudSession(
        accountId: account,
        deviceId: 'device-$account',
        sessionId: 'session-$account',
        installationId: installation,
        accessToken: 'fake-access',
        refreshToken: 'fake-refresh',
        accessExpiresAt: DateTime.utc(2030),
        refreshExpiresAt: DateTime.utc(2031),
      ),
    );
    identity = (await sync.capture(1))!;
  }

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    secrets = SecretStore(db, await Vault.open(MemoryKeyStore()));
    sync = SyncRepository(db, secrets);
    projection = SyncProjection(db, secrets, sync);
    configs = ConfigurationRepository(
      db,
      secrets,
      onSyncEdit: projection.edited,
    );
    self = SelfContentRepository(db, secrets, onSyncEdit: projection.edited);
    settings = SettingsRepository(db, secrets, onSyncEdit: projection.edited);
    selections = SelectionRepository(db, onSyncEdit: projection.edited);
    sessions = CloudSessionRepository(db, secrets);
    await login('account-a');
  });
  tearDown(() => db.close());

  Future<void> bootstrap() => sync.completeBootstrap(
    identity,
    () => true,
    merge: () => projection.bootstrap(identity.accountId),
  );

  Future<String> subscription({
    String name = 'Local',
    String header = 'local-value',
  }) => configs.add(
    kind: ConfigurationKind.subscription,
    name: name,
    parsed: _parsed,
    digest: 'test-digest',
    source: SubscriptionSource(
      url: const Secret(_url),
      headers: {'X-Token': Secret(header)},
    ),
  );

  SyncRecord record(
    String id,
    SyncRecordType type,
    int revision,
    Map<String, Object?> payload, {
    int editedAt = 100,
  }) => SyncRecord(
    recordId: id,
    type: type,
    revision: revision,
    editedAt: editedAt,
    editedByDeviceId: 'device-remote',
    deleted: false,
    payload: completeSyncPayload(type, payload),
  );

  Future<void> pull(List<SyncRecord> records) => sync.commitPullPage(
    identity,
    () => true,
    records: records.map((r) => r.toJson()).toList(),
    nextCursor: records.last.revision,
    project: projection.project,
    reconcile: () => projection.reconcile(identity.accountId),
  );

  Map<String, Object?> subscriptionPayload(String name, String header) => {
    'kind': 'subscription',
    'name': name,
    'autoUpdate': true,
    'createdAt': 1,
    'source': {
      'url': _url,
      'headers': {'X-Token': header},
    },
  };

  test(
    'all five business types and nine protocols produce the exact fixed schema',
    () async {
      final config = await subscription();
      await configs.add(
        kind: ConfigurationKind.file,
        name: 'File',
        parsed: _parsed,
        digest: 'file-digest',
      );
      final params = <NodeParams>[
        const NodeParams.hysteria2(
          password: Secret('h-password'),
          obfsPassword: Secret('h-obfs'),
        ),
        const NodeParams.tuic(
          uuid: Secret('uuid'),
          password: Secret('t-password'),
        ),
        const NodeParams.vless(uuid: Secret('uuid')),
        const NodeParams.vmess(uuid: Secret('uuid')),
        const NodeParams.trojan(password: Secret('tr-password')),
        const NodeParams.shadowsocks(
          method: 'aes-128-gcm',
          password: Secret('ss-password'),
        ),
        const NodeParams.socks5(
          username: 'private-username',
          password: Secret('s-password'),
        ),
        const NodeParams.anytls(password: Secret('a-password')),
        const NodeParams.http(
          username: 'private-username',
          password: Secret('http-password'),
        ),
      ];
      final nodes = <SelfNode>[];
      for (final p in params) {
        nodes.add(
          await self.addNode(
            SelfNode(
              id: 'unused',
              name: p.protocol.name,
              server: 'node.example.com',
              port: 443,
              params: p,
            ),
            joinGroup: (configurationId: config, groupKey: 'custom'),
          ),
        );
      }
      await self.addChain(
        Chain(
          id: 'unused',
          hops: [
            MemberRef.selfNode(id: nodes[0].id),
            MemberRef.selfNode(id: nodes[1].id),
          ],
        ),
      );
      await settings.updatePolicy((p) => p.copyWith(geoAutoUpdate: false));
      await selections.select(
        config,
        'custom',
        MemberRef.selfNode(id: nodes.last.id),
      );
      await bootstrap();
      final pending = await sync.preparePush(identity, () => true);
      expect(pending, hasLength(14));
      final mutations = pending
          .map((m) => SyncMutation.fromJson(m.envelope))
          .toList();
      expect(
        mutations.map((m) => m.type).toSet(),
        SyncRecordType.values.toSet(),
      );
      final subscriptionMutation = mutations.firstWhere(
        (m) =>
            m.type == SyncRecordType.configuration &&
            m.payload!['kind'] == 'subscription',
      );
      expect(subscriptionMutation.payload!.containsKey('content'), isFalse);
      final file = mutations.firstWhere(
        (m) =>
            m.type == SyncRecordType.configuration &&
            m.payload!['kind'] == 'file',
      );
      expect(
        ((file.payload!['content'] as Map)['model'] as Map).containsKey(
          'warnings',
        ),
        isFalse,
      );
      final text = StringBuffer();
      for (final table in db.allTables) {
        for (final r
            in await db
                .customSelect('SELECT * FROM ${table.actualTableName}')
                .get()) {
          text.write(r.data.values.join('|'));
        }
      }
      for (final secret in [
        'private-username',
        'h-password',
        'test-private-token',
        'local-value',
      ]) {
        expect(text.toString(), isNot(contains(secret)));
      }
    },
  );

  for (final type in ['configuration', 'node', 'chain']) {
    test(
      '$type deletion timestamps the new tombstone, not the old row',
      () async {
        Future<SelfNode> addNode(String name) => self.addNode(
          SelfNode(
            id: '',
            name: name,
            server: 'delete.example.test',
            port: 443,
            params: const NodeParams.trojan(password: Secret('delete-secret')),
          ),
        );

        final String local;
        if (type == 'configuration') {
          local = await subscription();
        } else if (type == 'node') {
          local = (await addNode('Delete node')).id;
        } else {
          final first = await addNode('First hop');
          final second = await addNode('Second hop');
          local = (await self.addChain(
            Chain(
              id: '',
              hops: [
                MemberRef.selfNode(id: first.id),
                MemberRef.selfNode(id: second.id),
              ],
            ),
          )).id;
        }
        await bootstrap();
        final sent = await sync.preparePush(identity, () => true);
        // Model the server's confirmed effective time. Projection restores this
        // same old timestamp into the business row before the user deletes it.
        await sync.commitPushPrefix(
          identity,
          () => true,
          sent: sent,
          results: [
            for (final (index, mutation) in sent.indexed)
              {
                'mutationId': mutation.mutationId,
                'status': 'applied',
                'revision': index + 1,
                'editedAt': 100,
              },
          ],
          project: projection.project,
        );
        final before = (await sync.findDocument('account-a', local))!;
        expect(before.row.localEditedAt, 100);
        final nowBeforeDelete = DateTime.now().toUtc().millisecondsSinceEpoch;
        switch (type) {
          case 'configuration':
            await configs.delete(local);
          case 'node':
            await self.deleteNode(local);
          case 'chain':
            await self.deleteChain(local);
        }
        final deleted = (await sync.findDocument('account-a', local))!;
        expect(
          deleted.row.localEditedAt,
          greaterThan(before.row.localEditedAt),
        );
        expect(
          deleted.row.localEditedAt,
          greaterThanOrEqualTo(nowBeforeDelete),
        );
        expect(
          deleted.row.localEditedAt,
          lessThanOrEqualTo(DateTime.now().toUtc().millisecondsSinceEpoch),
        );
        expect(deleted.row.documentId, before.row.documentId);
        expect(deleted.row.accountId, 'account-a');
        expect(deleted.row.localDeleted, isTrue);
        expect(deleted.localPayload, isNull);
        final tombstone = (await sync.preparePush(identity, () => true)).single;
        expect(tombstone.mutationId, isNot(before.meta!.mutationId));
        expect(tombstone.recordId, local);
        expect(tombstone.envelope['editedAt'], deleted.row.localEditedAt);
        expect(tombstone.envelope['deleted'], isTrue);
        expect(tombstone.envelope['payload'], isNull);
        expect(
          (await sync.preparePush(identity, () => true)).single.envelopeJson,
          tombstone.envelopeJson,
        );
      },
    );
  }

  test(
    'unknown earlier upload cannot clear a newer business deletion',
    () async {
      final node = await self.addNode(
        const SelfNode(
          id: '',
          name: 'Delete while upload outcome is unknown',
          server: 'delete.example.test',
          port: 443,
          params: NodeParams.trojan(password: Secret('delete-secret')),
        ),
      );
      await bootstrap();
      final original = (await sync.preparePush(identity, () => true)).single;
      await self.deleteNode(node.id);
      final deleted = (await sync.findDocument('account-a', node.id))!;
      expect(deleted.row.localDeleted, isTrue);
      expect(deleted.dirty, isTrue);
      expect(deleted.meta!.mutationId, isNot(original.mutationId));
      expect(
        (await sync.preparePush(identity, () => true)).single.envelopeJson,
        original.envelopeJson,
      );
      await sync.commitPushPrefix(
        identity,
        () => true,
        sent: [original],
        results: [
          {
            'mutationId': original.mutationId,
            'status': 'applied',
            'revision': 1,
            'editedAt': original.envelope['editedAt'],
          },
        ],
        project: projection.project,
      );
      expect(await self.node(node.id), isNull);
      final retained = (await sync.findDocument('account-a', node.id))!;
      expect(retained.row.localDeleted, isTrue);
      expect(retained.dirty, isTrue);
      expect(retained.meta!.mutationId, deleted.meta!.mutationId);
      expect(retained.meta!.inFlightMutationId, isNull);
      final pending = (await sync.preparePush(identity, () => true)).single;
      expect(pending.mutationId, deleted.meta!.mutationId);
      expect(pending.envelope['deleted'], isTrue);
      expect(pending.envelope['payload'], isNull);
      expect(pending.envelope['editedAt'], deleted.row.localEditedAt);
    },
  );

  test('exact URL duplicates bind one to one and Cloud headers win', () async {
    final first = await subscription(name: 'first');
    final second = await subscription(name: 'second');
    final localOrder = [first, second]..sort();
    await pull([
      record(
        _configId,
        SyncRecordType.configuration,
        1,
        subscriptionPayload('Cloud', 'remote-secret'),
      ),
    ]);
    await bootstrap();
    final bound = (await sync.findDocument('account-a', _configId))!;
    expect(bound.row.localId, localOrder.first);
    expect(
      (await configs.source(localOrder.first))!.headers['X-Token']!.value,
      'remote-secret',
    );
    expect(await configs.isCloudOrigin(localOrder.first), isTrue);
    expect(
      (await configs.watchAll().first).where(
        (c) => c.kind == ConfigurationKind.subscription,
      ),
      hasLength(2),
    );
    expect(
      (await sync.preparePush(
        identity,
        () => true,
      )).where((m) => m.envelope['type'] == 'configuration'),
      hasLength(1),
    );
  });

  test(
    'selection rekeys after subscription binding and references its Cloud wire ID',
    () async {
      final local = await subscription();
      await selections.select(
        local,
        'custom',
        const MemberRef.builtin(builtin: Builtin.direct),
      );
      await pull([
        record(
          _configId,
          SyncRecordType.configuration,
          1,
          subscriptionPayload('Cloud', 'remote'),
        ),
      ]);
      await bootstrap();
      final selection = (await sync.preparePush(
        identity,
        () => true,
      )).firstWhere((m) => m.envelope['type'] == 'selection');
      final mutation = SyncMutation.fromJson(selection.envelope);
      expect(mutation.recordId, syncSelectionId(_configId, 'custom'));
      expect(mutation.payload!['configurationId'], _configId);
    },
  );

  test(
    'cross-page membership survives node rename before its parent arrives',
    () async {
      await bootstrap();
      await pull([
        record(_nodeId, SyncRecordType.node, 1, {
          'name': 'remote',
          'server': 'node.example.com',
          'port': 443,
          'createdAt': 1,
          'params': {
            'protocol': 'socks5',
            'username': 'remote-user',
            'password': {r'$secretRef': 's0'},
          },
          'secrets': {'s0': 'remote-password'},
          'memberships': [
            {'configurationId': _configId, 'groupKey': 'custom'},
          ],
        }),
      ]);
      final node = (await self.nodes()).single;
      expect(await db.select(db.memberships).get(), isEmpty);
      await self.updateNode(node.copyWith(name: 'renamed'));
      final doc = (await sync.findDocument('account-a', _nodeId))!;
      expect(doc.localPayload!['memberships'], [
        {'configurationId': _configId, 'groupKey': 'custom'},
      ]);
      await pull([
        record(
          _configId,
          SyncRecordType.configuration,
          2,
          subscriptionPayload('parent', 'remote'),
        ),
      ]);
      // The current dirty node stays effective and retains canonical refs.
      expect((await self.nodes()).single.name, 'renamed');
      expect(
        (await sync.findDocument(
          'account-a',
          _nodeId,
        ))!.localPayload!['memberships'],
        hasLength(1),
      );
      final membership = (await db.select(db.memberships).get()).single;
      final parent = (await sync.findDocument('account-a', _configId))!;
      expect(membership.ownerKind, 'node');
      expect(membership.ownerId, node.id);
      expect(membership.configurationId, parent.row.localId);
      expect(membership.groupKey, 'custom');
    },
  );

  test(
    'Cloud trust invalidates an in-flight local source snapshot even when the URL is unchanged',
    () async {
      final local = await subscription();
      await bootstrap();
      final sent = await sync.preparePush(identity, () => true);
      await sync.commitPushPrefix(
        identity,
        () => true,
        sent: sent,
        results: [
          {
            'mutationId': sent.single.mutationId,
            'status': 'applied',
            'revision': 1,
            'editedAt': 100,
          },
        ],
        project: projection.project,
      );
      final document = (await sync.findDocument('account-a', local))!;
      await sync.setSource(
        documentId: document.row.documentId,
        origin: 'local_user',
        allowPrivate: true,
      );
      final before = (await configs.sourceSnapshot(local))!;
      expect(before.cloudSource, isFalse);
      expect(
        (await sync.provenance(document.row.documentId))!.origin,
        'local_user',
      );

      await pull([
        record(
          local,
          SyncRecordType.configuration,
          2,
          subscriptionPayload('Cloud', 'local-value'),
          editedAt: 200,
        ),
      ]);
      final after = (await configs.sourceSnapshot(local))!;
      expect(after.source, before.source);
      expect(after.cloudSource, isTrue);
      expect(after.sourceSecretId, isNot(before.sourceSecretId));
      expect((await configs.content(local))!.digest, 'test-digest');
      expect(
        await configs.replaceContent(
          local,
          expectedSourceSecretId: before.sourceSecretId,
          parsed: parseContent('trojan://stale@stale.example.com:443#stale'),
          digest: 'stale-result',
        ),
        isFalse,
      );
      expect(
        await configs.markRefreshed(
          local,
          expectedSourceSecretId: before.sourceSecretId,
          checkSource: true,
          usage: const Usage(upload: 999, download: 999),
        ),
        isFalse,
      );
      await configs.recordFailure(
        local,
        'stale-error',
        expectedSourceSecretId: before.sourceSecretId,
        checkSource: true,
      );
      expect((await configs.content(local))!.digest, 'test-digest');
      expect((await configs.get(local))!.lastError, isNull);
      expect((await configs.get(local))!.usage, isNull);
    },
  );

  test(
    'a changed Cloud subscription clears cached content and refresh metadata while auto-update is disabled',
    () async {
      await bootstrap();
      await pull([
        record(
          _configId,
          SyncRecordType.configuration,
          1,
          subscriptionPayload('Cloud', 'remote'),
        ),
      ]);
      final document = (await sync.findDocument('account-a', _configId))!;
      final local = document.row.localId!;
      final snapshot = (await configs.sourceSnapshot(local))!;
      expect(
        await configs.replaceContent(
          local,
          expectedSourceSecretId: snapshot.sourceSecretId,
          parsed: _parsed,
          digest: 'cached-before-source-change',
          usage: Usage(
            upload: 12,
            download: 34,
            total: 100,
            expireAt: DateTime.utc(2030),
          ),
        ),
        isTrue,
      );
      await configs.recordFailure(local, 'previous-error');
      expect((await configs.get(local))!.lastSuccessAt, isNotNull);
      expect((await configs.get(local))!.usage, isNotNull);

      const nextUrl = 'https://new.example.com/api?token=new-private-token';
      await pull([
        record(_configId, SyncRecordType.configuration, 2, {
          ...subscriptionPayload('Changed', 'new-header'),
          'autoUpdate': false,
          'source': {
            'url': nextUrl,
            'headers': {'X-Token': 'new-header'},
          },
        }, editedAt: 200),
      ]);
      final changed = (await configs.get(local))!;
      expect(changed.autoUpdate, isFalse);
      expect(changed.lastSuccessAt, isNull);
      expect(changed.lastAttemptAt, isNull);
      expect(changed.lastError, isNull);
      expect(changed.usage, isNull);
      expect(await configs.content(local), isNull);
      expect((await configs.source(local))!.url.value, nextUrl);
      expect(await configs.isCloudOrigin(local), isTrue);
      expect(
        await configs.markRefreshed(
          local,
          expectedSourceSecretId: snapshot.sourceSecretId,
          checkSource: true,
        ),
        isFalse,
      );
      expect((await configs.get(local))!.lastSuccessAt, isNull);
    },
  );

  test(
    'a damaged Cloud session cannot prevent a local canonical tombstone',
    () async {
      final node = await self.addNode(
        const SelfNode(
          id: 'unused',
          name: 'Local',
          server: 'node.example.com',
          port: 443,
          params: NodeParams.trojan(password: Secret('local-password')),
        ),
      );
      await bootstrap();
      final before = (await sync.findDocument('account-a', node.id))!;
      final session = await (db.select(
        db.cloudSession,
      )..where((r) => r.id.equals(1))).getSingle();
      await (db.update(db.secrets)
            ..where((r) => r.id.equals(session.accessSecretId)))
          .write(SecretsCompanion(ciphertext: Value(Uint8List.fromList([1]))));
      await expectLater(sessions.read(), throwsA(isA<VaultLockedException>()));

      await self.deleteNode(node.id);
      expect(await self.nodes(), isEmpty);
      final deleted = (await sync.findDocument('account-a', node.id))!;
      expect(deleted.row.documentId, before.row.documentId);
      expect(deleted.row.accountId, 'account-a');
      expect(deleted.row.localDeleted, isTrue);
      expect(deleted.localPayload, isNull);

      // A recovered session reconciles the local deletion into the same account.
      await login('account-a');
      await sync.reconcileAccount('account-a');
      final mutation = SyncMutation.fromJson(
        (await sync.preparePush(identity, () => true)).single.envelope,
      );
      expect(mutation.recordId, node.id);
      expect(mutation.deleted, isTrue);
      expect(mutation.payload, isNull);
    },
  );

  test(
    're-entered node credentials repair a damaged encrypted canonical owner',
    () async {
      final node = await self.addNode(
        const SelfNode(
          id: 'unused',
          name: 'Local',
          server: 'node.example.com',
          port: 443,
          params: NodeParams.http(
            username: 'old-user',
            password: Secret('old-password'),
          ),
        ),
      );
      await bootstrap();
      final before = (await sync.findDocument('account-a', node.id))!;
      final stored = await (db.select(
        db.selfNodes,
      )..where((r) => r.id.equals(node.id))).getSingle();
      for (final secretId in [
        before.row.localPayloadSecretId!,
        stored.secretId,
      ]) {
        await (db.update(
          db.secrets,
        )..where((r) => r.id.equals(secretId))).write(
          SecretsCompanion(ciphertext: Value(Uint8List.fromList([1]))),
        );
      }
      await expectLater(self.nodes(), throwsA(isA<VaultLockedException>()));
      await expectLater(
        sync.findDocument('account-a', node.id),
        throwsA(isA<VaultLockedException>()),
      );

      const repairedParams = NodeParams.http(
        username: 'reentered-user',
        password: Secret('reentered-password'),
      );
      await self.updateNode(node.copyWith(params: repairedParams));
      expect((await self.nodes()).single.params, repairedParams);
      final repaired = (await sync.findDocument('account-a', node.id))!;
      expect(repaired.row.documentId, before.row.documentId);
      expect(repaired.row.accountId, 'account-a');
      expect(
        repaired.row.localPayloadSecretId,
        isNot(before.row.localPayloadSecretId),
      );
      expect(
        repaired.localPayload!['params'],
        containsPair('username', 'reentered-user'),
      );
      expect(
        (repaired.localPayload!['secrets'] as Map).values,
        contains('reentered-password'),
      );
      final pending = SyncMutation.fromJson(
        (await sync.preparePush(identity, () => true)).single.envelope,
      );
      expect(pending.recordId, node.id);
      expect(pending.payload, repaired.localPayload);
    },
  );

  test(
    'a remote deletion clears the selected configuration and its choices',
    () async {
      await bootstrap();
      await pull([
        record(
          _configId,
          SyncRecordType.configuration,
          1,
          subscriptionPayload('Cloud', 'remote'),
        ),
      ]);
      final local = (await sync.findDocument(
        'account-a',
        _configId,
      ))!.row.localId!;
      await settings.updateDevice(
        (device) => device.copyWith(selectedConfigurationId: local),
      );
      await selections.select(
        local,
        'custom',
        const MemberRef.builtin(builtin: Builtin.direct),
      );
      expect((await settings.device()).selectedConfigurationId, local);

      await pull([
        SyncRecord(
          recordId: _configId,
          type: SyncRecordType.configuration,
          revision: 2,
          editedAt: 200,
          editedByDeviceId: 'remote',
          deleted: true,
          payload: null,
        ),
      ]);
      expect(await configs.get(local), isNull);
      expect((await settings.device()).selectedConfigurationId, isNull);
      expect(await selections.get(local), isEmpty);
      expect(
        (await sync.findDocument('account-a', _configId))!.row.localDeleted,
        isTrue,
      );
    },
  );

  test(
    'uploads acknowledge edit time without changing local subscription trust or cache',
    () async {
      final local = await subscription();
      await bootstrap();
      final sent = await sync.preparePush(identity, () => true);
      await sync.commitPushPrefix(
        identity,
        () => true,
        sent: sent,
        results: [
          {
            'mutationId': sent.single.mutationId,
            'status': 'applied',
            'revision': 1,
            'editedAt': 100,
          },
        ],
        project: projection.project,
      );
      expect(await configs.isCloudOrigin(local), isFalse);
      expect((await configs.content(local))!.digest, 'test-digest');
      expect((await configs.get(local))!.editedAt.millisecondsSinceEpoch, 100);
      expect(await sync.preparePush(identity, () => true), isEmpty);
    },
  );

  test(
    'automatic selections and refreshes never produce user mutations',
    () async {
      final local = await subscription();
      await bootstrap();
      final before = (await sync.preparePush(identity, () => true)).single;
      await selections.select(
        local,
        'custom',
        const MemberRef.builtin(builtin: Builtin.direct),
        manual: false,
      );
      await configs.markRefreshed(
        local,
        usage: const Usage(upload: 12, download: 34),
      );
      final after = (await sync.preparePush(identity, () => true)).single;
      expect(after.envelopeJson, before.envelopeJson);
      expect(await sync.documents(accountId: 'account-a'), hasLength(1));
    },
  );

  test(
    'detached Cloud aliases can bind their nodes, memberships and chain to a new account',
    () async {
      const secondNode = '00000000-0000-4000-8000-000000000003';
      const chainId = '00000000-0000-4000-8000-000000000004';
      Map<String, Object?> remoteNode(String name) => {
        'name': name,
        'server': 'node.example.com',
        'port': 443,
        'createdAt': 1,
        'params': {'protocol': 'http', 'username': null, 'password': null},
        'secrets': <String, String>{},
        'memberships': [
          {'configurationId': _configId, 'groupKey': 'custom'},
        ],
      };
      await bootstrap();
      await pull([
        record(
          _configId,
          SyncRecordType.configuration,
          1,
          subscriptionPayload('Retained subscription', 'retained-header'),
        ),
        record(_nodeId, SyncRecordType.node, 2, remoteNode('first')),
        record(secondNode, SyncRecordType.node, 3, remoteNode('second')),
        record(chainId, SyncRecordType.chain, 4, {
          'name': 'Retained chain',
          'createdAt': 1,
          'hops': [
            {'kind': 'selfNode', 'id': _nodeId},
            {'kind': 'selfNode', 'id': secondNode},
          ],
          'memberships': [
            {'configurationId': _configId, 'groupKey': 'custom'},
          ],
        }),
      ]);
      final retained = await sync.documents(accountId: 'account-a');
      expect(
        retained.every((d) => d.row.localId!.startsWith('cloud:account-a:')),
        isTrue,
      );

      await sessions.detachAccount('account-a');
      await sessions.logoutLocally();
      await login('account-b');
      await bootstrap();
      final pending = await sync.preparePush(identity, () => true);
      expect(pending.map((m) => m.recordId).toSet(), {
        _configId,
        _nodeId,
        secondNode,
        chainId,
      });
      for (final mutation in pending) {
        await projection.assertUploadOwner(mutation, 'account-b');
        final wire = SyncMutation.fromJson(mutation.envelope);
        if (wire.type == SyncRecordType.node ||
            wire.type == SyncRecordType.chain) {
          expect(wire.payload!['memberships'], [
            {'configurationId': _configId, 'groupKey': 'custom'},
          ]);
        }
        if (wire.type == SyncRecordType.chain) {
          expect(wire.payload!['hops'], [
            {'kind': 'selfNode', 'id': _nodeId},
            {'kind': 'selfNode', 'id': secondNode},
          ]);
        }
      }
      expect(await sync.documents(accountId: 'account-a'), isEmpty);
      final rebound = await sync.documents(accountId: 'account-b');
      expect(rebound, hasLength(4));
      expect(
        rebound.map((d) => d.row.localId).toSet(),
        retained.map((d) => d.row.localId).toSet(),
      );
      expect(await self.nodes(), hasLength(2));
      expect(await self.chains(), hasLength(1));
    },
  );

  test(
    'editing B policy after its tombstone revives only B and preserves A canonical',
    () async {
      await settings.updatePolicy((p) => p.copyWith(geoAutoUpdate: false));
      await bootstrap();
      final originalA = (await sync.findDocument('account-a', 'policy'))!;
      expect(originalA.row.localId, 'policy');
      await sessions.logoutLocally();
      await login('account-b');
      await bootstrap();
      await pull([
        record('policy', SyncRecordType.policy, 1, {
          'jsonOverride': null,
          'geo': {'autoUpdate': true, 'interval': 'daily', 'via': 'direct'},
        }),
      ]);
      final originalB = (await sync.findDocument('account-b', 'policy'))!;
      await pull([
        SyncRecord(
          recordId: 'policy',
          type: SyncRecordType.policy,
          revision: 2,
          editedAt: 200,
          editedByDeviceId: 'remote',
          deleted: true,
          payload: null,
        ),
      ]);
      expect(await db.select(db.policyTable).get(), isEmpty);

      await settings.updatePolicy(
        (p) => p.copyWith(geoInterval: GeoInterval.weekly),
      );
      final revived = (await sync.findDocument('account-b', 'policy'))!;
      expect(revived.row.documentId, originalB.row.documentId);
      expect(revived.row.remoteDeleted, isTrue);
      expect(revived.row.localDeleted, isFalse);
      final effective = (await db.select(db.policyTable).get()).single;
      expect(effective.cloudAccountId, 'account-b');
      expect(effective.documentId, originalB.row.documentId);
      expect(
        (await sync.findDocument('account-a', 'policy'))!.localPayload,
        originalA.localPayload,
      );
      final sent = SyncMutation.fromJson(
        (await sync.preparePush(identity, () => true)).single.envelope,
      );
      expect(sent.recordId, 'policy');
      expect(sent.deleted, isFalse);
      expect(sent.payload!['geo'], containsPair('interval', 'weekly'));
      await login('account-a');
      await sync.reconcileAccount('account-a');
      final pendingA = SyncMutation.fromJson(
        (await sync.preparePush(identity, () => true)).single.envelope,
      );
      expect(pendingA.payload, originalA.localPayload);
    },
  );

  test(
    'self selection after B tombstone keeps the fixed selection ID account-scoped',
    () async {
      const group = 'custom';
      final selectionId = syncSelectionId('self', group);
      await selections.select(
        'self',
        group,
        const MemberRef.builtin(builtin: Builtin.direct),
      );
      await bootstrap();
      final originalA = (await sync.findDocument('account-a', selectionId))!;
      await sessions.logoutLocally();
      await login('account-b');
      await bootstrap();
      await pull([
        record(selectionId, SyncRecordType.selection, 1, {
          'configurationId': 'self',
          'groupKey': group,
          'member': {'kind': 'builtin', 'builtin': 'direct'},
        }),
      ]);
      final originalB = (await sync.findDocument('account-b', selectionId))!;
      await pull([
        SyncRecord(
          recordId: selectionId,
          type: SyncRecordType.selection,
          revision: 2,
          editedAt: 200,
          editedByDeviceId: 'remote',
          deleted: true,
          payload: null,
        ),
      ]);
      expect(await selections.get('self'), isEmpty);

      await selections.select(
        'self',
        group,
        const MemberRef.builtin(builtin: Builtin.reject),
      );
      final revived = (await sync.findDocument('account-b', selectionId))!;
      expect(revived.row.documentId, originalB.row.documentId);
      expect(revived.row.remoteDeleted, isTrue);
      expect(revived.row.localDeleted, isFalse);
      final effective = (await db.select(db.selections).get()).single;
      expect(effective.cloudAccountId, 'account-b');
      expect(effective.documentId, originalB.row.documentId);
      expect(
        (await sync.findDocument('account-a', selectionId))!.localPayload,
        originalA.localPayload,
      );
      final sent = SyncMutation.fromJson(
        (await sync.preparePush(identity, () => true)).single.envelope,
      );
      expect(sent.recordId, selectionId);
      expect(sent.deleted, isFalse);
      expect(sent.payload!['configurationId'], 'self');
      expect(sent.payload!['member'], {'kind': 'builtin', 'builtin': 'reject'});
      await login('account-a');
      await sync.reconcileAccount('account-a');
      final pendingA = SyncMutation.fromJson(
        (await sync.preparePush(identity, () => true)).single.envelope,
      );
      expect(pendingA.payload, originalA.localPayload);
    },
  );

  test(
    'a foreign account edit stays local and never enters the new account outbox',
    () async {
      final node = await self.addNode(
        const SelfNode(
          id: 'unused',
          name: 'A',
          server: 'node.example.com',
          port: 443,
          params: NodeParams.http(username: 'private-account-a-user'),
        ),
      );
      await bootstrap();
      final sent = await sync.preparePush(identity, () => true);
      await sync.commitPushPrefix(
        identity,
        () => true,
        sent: sent,
        results: [
          {
            'mutationId': sent.single.mutationId,
            'status': 'applied',
            'revision': 1,
            'editedAt': 100,
          },
        ],
      );
      await login('account-b');
      await self.updateNode(node.copyWith(name: 'A edited while B'));
      expect(await sync.preparePush(identity, () => true), isEmpty);
      expect(
        (await sync.documents(
          accountId: 'account-a',
        )).single.localPayload!['name'],
        'A edited while B',
      );
      await login('account-a');
      await sync.reconcileAccount('account-a');
      expect(
        (await sync.preparePush(
          identity,
          () => true,
        )).single.envelope['payload'],
        containsPair('name', 'A edited while B'),
      );
    },
  );

  test(
    'local subscription input remains usable when Cloud rejects its URL',
    () async {
      final id = await configs.add(
        kind: ConfigurationKind.subscription,
        name: 'LAN',
        parsed: _parsed,
        digest: 'd',
        source: const SubscriptionSource(url: Secret('http://127.0.0.1/sub')),
      );
      expect((await configs.source(id))!.url.value, 'http://127.0.0.1/sub');
      await bootstrap();
      final sent = await sync.preparePush(identity, () => true);
      // The DTO validates syntax; socket permissions are enforced downstream.
      expect(sent, hasLength(1));
      expect(await configs.content(id), isNotNull);
    },
  );
  test(
    'joining rebuilt backup preserves local candidates without auto binding or upload',
    () async {
      const generation = '10000000-0000-4000-8000-000000000002';
      final local = await subscription(name: 'independent local');
      identity = await sync.adoptGeneration(identity, () => true, generation);
      final remote = record(
        _configId,
        SyncRecordType.configuration,
        1,
        subscriptionPayload('new backup', 'remote-secret'),
      );
      await sync.stageFullPull(
        identity,
        () => true,
        headRevision: 1,
        records: [remote.toJson()],
        nextCursor: 1,
        hasMore: false,
      );
      await sync.publishFullPull(
        identity,
        () => true,
        headRevision: 1,
        project: projection.project,
        merge: () => projection.reconcile('account-a'),
      );
      await projection.captureAll();
      await sync.reconcileAccount('account-a');
      final localRow = await (db.select(
        db.configurations,
      )..where((r) => r.id.equals(local))).getSingle();
      expect(localRow.cloudAccountId, isNull);
      expect(
        (await configs.source(local))!.headers['X-Token']!.value,
        'local-value',
      );
      final independent = await sync.findLocalDocument('configuration', local);
      expect(independent!.row.accountId, isNull);
      expect(await sync.preparePush(identity, () => true), isEmpty);
      expect(await sync.pendingMergeCount('account-a'), 1);
      final adopted = (await sync.findDocument('account-a', _configId))!;
      expect(adopted.row.localId, isNot(local));
      expect((await configs.get(adopted.row.localId!))!.name, 'new backup');
      expect(await configs.isCloudOrigin(adopted.row.localId!), isTrue);
      expect(
        (await configs.source(adopted.row.localId!))!.headers['X-Token']!.value,
        'remote-secret',
      );
    },
  );
}
