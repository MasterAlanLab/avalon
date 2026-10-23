// Import flow end to end against a local server and an in-memory database.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:av_core/av_core.dart';
import 'package:avalon/data/database/database.dart';
import 'package:avalon/data/repositories/configuration_repository.dart';
import 'package:avalon/data/vault/secret_store.dart';
import 'package:avalon/data/vault/vault.dart';
import 'package:avalon/services/download/fetcher.dart';
import 'package:avalon/services/import_service.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const _clash = '''
proxies:
  - {name: A, type: trojan, server: a.example.com, port: 443, password: fake-a}
proxy-providers:
  more: {type: http, url: "PROVIDER_URL"}
proxy-groups:
  - {name: 节点选择, type: select, proxies: [A], use: [more]}
rules:
  - MATCH,节点选择
''';

const _provider = '''
proxies:
  - {name: B, type: trojan, server: b.example.com, port: 443, password: fake-b}
''';

void main() {
  late HttpServer server;
  late String base;
  late AppDatabase db;
  late ConfigurationRepository configs;
  late ImportService service;
  var subscription = _clash;
  var status = 200;
  Completer<void>? providerGate;
  Completer<void>? subscriptionGate;
  Completer<void>? subscriptionStarted;

  setUp(() async {
    subscription = _clash;
    status = 200;
    providerGate = null;
    subscriptionGate = null;
    subscriptionStarted = null;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    base = 'http://127.0.0.1:${server.port}';
    server.listen((r) async {
      if (r.uri.path == '/provider') {
        await providerGate?.future;
        r.response.write(_provider);
      } else {
        if (subscriptionStarted case final started? when !started.isCompleted) {
          started.complete();
        }
        await subscriptionGate?.future;
        r.response.statusCode = status;
        r.response.headers
          // Non-ASCII titles travel Base64-encoded.
          ..set('profile-title', 'base64:${base64.encode(utf8.encode('我的机场'))}')
          ..set('subscription-userinfo', 'upload=1; download=2; total=3');
        r.response.write(
          subscription.replaceAll('PROVIDER_URL', '$base/provider'),
        );
      }
      await r.response.close();
    });
    db = AppDatabase(NativeDatabase.memory());
    configs = ConfigurationRepository(
      db,
      SecretStore(db, await Vault.open(MemoryKeyStore())),
    );
    service = ImportService(configs, Fetcher(userAgent: 'test'));
  });
  tearDown(() async {
    await server.close(force: true);
    await db.close();
  });

  test('adds a subscription with its providers in one save', () async {
    final result = await service.addSubscription(
      url: '$base/sub?token=fake-token',
      defaultName: '新订阅',
    );
    final c = (await configs.get(result.configurationId))!;
    expect(c.name, '我的机场');
    expect(c.kind, ConfigurationKind.subscription);
    expect(c.usage!.total, 3);
    final content = (await configs.content(result.configurationId))!.content;
    expect([for (final n in content.nodes) n.name], ['A', 'B']);
    expect(
      (await configs.source(result.configurationId))!.url.value,
      endsWith('token=fake-token'),
    );
  });

  test('unreadable content saves nothing', () async {
    subscription = 'not a configuration';
    await expectLater(
      service.addSubscription(url: '$base/s', defaultName: 'x'),
      throwsA(isA<ImportException>()),
    );
    expect(await configs.watchAll().first, hasLength(1)); // 自建节点
  });

  test('cancelling during a provider download saves nothing', () async {
    providerGate = Completer<void>();
    final cancel = FetchCancel();
    final pending = service.addSubscription(
      url: '$base/s',
      defaultName: 'x',
      cancel: cancel,
    );
    final expectation = expectLater(
      pending,
      throwsA(
        isA<FetchException>().having(
          (e) => e.code,
          'code',
          FetchErrorCode.cancelled,
        ),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));
    cancel.cancel();
    providerGate!.complete();
    await expectation;
    expect(await configs.watchAll().first, hasLength(1));
  });

  test('refresh: unchanged, updated, failed', () async {
    final id = (await service.addSubscription(
      url: '$base/s',
      defaultName: 'x',
    )).configurationId;
    expect(await service.refresh(id), RefreshOutcome.unchanged);

    subscription = _clash.replaceAll('fake-a', 'fake-a2');
    expect(await service.refresh(id), RefreshOutcome.updated);
    final node = (await configs.content(id))!.content.node('proxy:A')!;
    expect((node.params as TrojanParams).password.value, 'fake-a2');

    status = 500;
    await expectLater(service.refresh(id), throwsA(isA<FetchException>()));
    final c = (await configs.get(id))!;
    expect(c.lastError, 'fetch.httpStatus.500');
    expect((await configs.content(id))!.content.nodes, hasLength(2));
    expect(jsonEncode(c.lastError), isNot(contains('token')));
  });

  test(
    'Cloud provenance survives detach and blocks a private refresh',
    () async {
      final id = (await service.addSubscription(
        url: '$base/s',
        defaultName: 'x',
      )).configurationId;
      final contentBefore = (await configs.content(id))!.digest;
      await db
          .into(db.syncDocuments)
          .insert(
            SyncDocumentsCompanion.insert(
              documentId: 'remote-config',
              recordId: 'remote-record',
              type: 'configuration',
              localId: Value(id),
              accountId: const Value('old-account'),
              localEditedAt: 1,
              localDeleted: false,
            ),
          );
      await db
          .into(db.sourceProvenance)
          .insert(
            SourceProvenanceCompanion.insert(
              documentId: 'remote-config',
              origin: 'cloud',
              originAccountId: const Value('old-account'),
              sourceGeneration: 'remote-generation',
            ),
          );
      // Logout detaches ownership; it cannot turn a remote URL into local
      // user consent, even though the local configuration remains stored.
      await (db.update(db.syncDocuments)
            ..where((d) => d.documentId.equals('remote-config')))
          .write(const SyncDocumentsCompanion(accountId: Value(null)));
      await expectLater(
        service.refresh(id),
        throwsA(
          isA<FetchException>().having(
            (e) => e.code,
            'code',
            FetchErrorCode.blockedAddress,
          ),
        ),
      );
      expect((await configs.content(id))!.digest, contentBefore);
      expect((await configs.get(id))!.lastError, 'fetch.blockedAddress');
      // Editing the source is not an implicit grant for Cloud content.
      await service.updateSubscription(
        id,
        url: '$base/edited',
        autoUpdate: true,
      );
      expect(await configs.isCloudOrigin(id), isTrue);
      expect((await configs.get(id))!.lastError, 'fetch.blockedAddress');
    },
  );

  test(
    'an unchanged old download cannot mark an edited source as refreshed',
    () async {
      final id = (await service.addSubscription(
        url: '$base/original',
        defaultName: 'x',
      )).configurationId;
      final before = (await configs.get(id))!;
      subscriptionGate = Completer<void>();
      subscriptionStarted = Completer<void>();
      final pending = service.refresh(id);
      await subscriptionStarted!.future;
      await configs.update(
        id,
        source: SubscriptionSource(url: Secret('$base/new-source')),
      );
      subscriptionGate!.complete();
      expect(await pending, RefreshOutcome.discarded);
      final after = (await configs.get(id))!;
      expect(after.lastSuccessAt, before.lastSuccessAt);
      expect(after.lastAttemptAt, before.lastAttemptAt);
      expect(after.lastError, isNull);
    },
  );

  test(
    'an old failed download cannot attach its error to an edited source',
    () async {
      final id = (await service.addSubscription(
        url: '$base/original',
        defaultName: 'x',
      )).configurationId;
      final before = (await configs.get(id))!;
      status = 500;
      subscriptionGate = Completer<void>();
      subscriptionStarted = Completer<void>();
      final pending = service.refresh(id);
      final expectation = expectLater(pending, throwsA(isA<FetchException>()));
      await subscriptionStarted!.future;
      await configs.update(
        id,
        source: SubscriptionSource(url: Secret('$base/new-source')),
      );
      subscriptionGate!.complete();
      await expectation;
      final after = (await configs.get(id))!;
      expect(after.lastAttemptAt, before.lastAttemptAt);
      expect(after.lastError, isNull);
    },
  );
}
