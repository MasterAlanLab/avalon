import 'dart:io';

import 'package:av_core/av_core.dart';
import 'package:avalon/data/database/database.dart';
import 'package:drift/drift.dart' show Value, BooleanExpressionOperators;
import 'package:flutter_test/flutter_test.dart';

import '../features/harness.dart';

const _links =
    '{"outbounds":[{"type":"trojan","tag":"Public",'
    '"server":"public.example.com","server_port":443,'
    '"password":"fake-password","tls":{"enabled":true}}],'
    '"route":{"final":"Public"}}';
const _node = SelfNode(
  id: '',
  name: 'Local',
  server: 'node.example.com',
  port: 443,
  params: NodeParams.trojan(password: Secret('fake-password')),
);

void main() {
  late Harness h;
  late Directory resources;
  setUp(() async {
    resources = Directory.systemTemp.createTempSync('cloud-plan-guard');
    h = await Harness.start(stateDir: resources.path)
      ..body = _links;
  });
  tearDown(() async {
    await h.stop();
    await resources.delete(recursive: true);
  });

  Future<String> cloud(String type, String localId) async {
    final db = h.services.db;
    final existing =
        await (db.select(db.syncDocuments)
              ..where((d) => d.type.equals(type) & d.localId.equals(localId)))
            .getSingleOrNull();
    final documentId = existing?.documentId ?? 'cloud-$type-$localId';
    if (existing == null) {
      await db
          .into(db.syncDocuments)
          .insert(
            SyncDocumentsCompanion.insert(
              documentId: documentId,
              recordId: documentId,
              type: type,
              localId: Value(localId),
              localEditedAt: 1,
              localDeleted: false,
            ),
          );
    }
    await db
        .into(db.sourceProvenance)
        .insertOnConflictUpdate(
          SourceProvenanceCompanion.insert(
            documentId: documentId,
            origin: 'cloud',
            sourceGeneration: 'generation',
          ),
        );
    return documentId;
  }

  Future<String> subscription() async {
    final id = (await h.services.imports.addSubscription(
      url: '${h.base}/sub',
      defaultName: 'Local',
    )).configurationId;
    await h.services.settings.updateDevice(
      (s) => s.copyWith(selectedConfigurationId: id),
    );
    return id;
  }

  Matcher blocked(String reason) => throwsA(
    isA<CompileException>()
        .having((e) => e.subject, 'subject', 'cloud.networkGuard')
        .having((e) => e.detail, 'reason', reason),
  );

  Future<void> cacheDefaultRules() async {
    for (final ref in [
      RuleSetCatalog.geosite('cn'),
      RuleSetCatalog.geoip('cn'),
    ]) {
      await h.services.resources.update(
        ref,
        throughProxy: (_, dest, _, {publicOnly = false}) async {
          await File(dest).writeAsBytes([0x53, 0x52, 0x53, 1]);
        },
      );
    }
  }

  test('remote endpoint restrictions survive account detach', () async {
    final id = await subscription();
    // Cloud native downloads remain forbidden; endpoint coverage is only
    // exercised once required rules have entered the trusted local cache.
    await cacheDefaultRules();
    final local = await h.services.plans.compileSelected();
    final doc = await cloud('configuration', id);
    final guarded = await h.services.plans.compileSelected();
    expect(guarded.planHash, isNot(local.planHash));
    final envelope = guarded.toJson()['_avalon_public_network'] as Map;
    expect(envelope['version'], 1);
    expect(envelope['endpointTags'], isNotEmpty);
    await (h.services.db.update(h.services.db.syncDocuments)
          ..where((d) => d.documentId.equals(doc)))
        .write(const SyncDocumentsCompanion(accountId: Value(null)));
    final detached = await h.services.plans.compileSelected();
    expect(detached.toJson()['_avalon_public_network'], envelope);
    expect(detached.planHash, guarded.planHash);
    // A separate locally imported configuration has no remote endpoints.
    await subscription();
    expect(
      (await h.services.plans.compileSelected()).tree,
      isNot(contains('_avalon_public_network')),
    );
  });

  test(
    'Cloud configuration cannot start native uncached rule downloads',
    () async {
      final id = await subscription();
      await cloud('configuration', id);
      await expectLater(
        h.services.plans.compileSelected(),
        blocked('cloudRuleSetNativeGuardRequired'),
      );
    },
  );

  test(
    'Cloud automatic URL tests remain blocked despite cached rules',
    () async {
      h.body = 'trojan://fake-password@public.example.com:443#Public';
      final id = await subscription();
      await cacheDefaultRules();
      await cloud('configuration', id);
      await expectLater(
        h.services.plans.compileSelected(),
        blocked('cloudUrlTestNativeGuardRequired'),
      );
    },
  );

  test('remote self nodes carry the native endpoint guard', () async {
    final node = await h.services.selfService.addNode(_node);
    await h.services.plans.compileSelected();
    await cloud('node', node.id);
    final plan = await h.services.plans.compileSelected();
    final envelope = plan.toJson()['_avalon_public_network'] as Map;
    expect(envelope['endpointTags'], ['s:${node.id}']);
  });

  test('a remote chain guards every concrete locally authored hop', () async {
    final first = await h.services.selfService.addNode(_node);
    final second = await h.services.selfService.addNode(
      _node.copyWith(name: 'Second', server: 'second.example.com'),
    );
    final chain = await h.services.selfService.addChain(
      Chain(
        id: '',
        hops: [
          MemberRef.selfNode(id: first.id),
          MemberRef.selfNode(id: second.id),
        ],
      ),
    );
    await h.services.plans.compileSelected();
    await cloud('chain', chain.id);
    final plan = await h.services.plans.compileSelected();
    final envelope = plan.toJson()['_avalon_public_network'] as Map;
    expect(envelope['endpointTags'], ['c:${chain.id}:0', 'c:${chain.id}:1']);
  });

  test('policy guard applies only to the singleton current owner', () async {
    await subscription();
    await h.services.settings.updatePolicy(
      (p) => p.copyWith(
        jsonOverride: const Secret(
          '{"dns":{"servers":[{"tag":"extra","type":"local"}]}}',
        ),
      ),
    );
    final doc = await cloud('policy', 'other-account-policy');
    await h.services.plans.compileSelected();
    await (h.services.db.update(h.services.db.policyTable)
          ..where((p) => p.id.equals(1)))
        .write(PolicyTableCompanion(documentId: Value(doc)));
    await expectLater(
      h.services.plans.compileSelected(),
      blocked('cloudOverrideNativeGuardRequired'),
    );
  });
}
