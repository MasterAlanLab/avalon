// Writes test/data/schemas/v<N>.sqlite: a database of the current schema
// holding one of everything, for the migration tests of later versions
// (DATA_MODEL §5). Run once per schema version, before changing it:
//
//   flutter test tool/make_schema_fixture.dart
import 'dart:io';

import 'package:av_core/av_core.dart';
import 'package:avalon/app/services.dart';
import 'package:avalon/data/database/database.dart';
import 'package:avalon/data/vault/vault.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const _clash = '''
proxies:
  - {name: 香港 01, type: trojan, server: a.example.com, port: 443, password: fake-a}
  - {name: 日本 01, type: vmess, server: b.example.com, port: 443, uuid: 00000000-0000-4000-8000-000000000002}
proxy-groups:
  - {name: 节点选择, type: select, proxies: [香港 01, 日本 01, DIRECT]}
rules:
  - GEOSITE,openai,节点选择
  - MATCH,节点选择
''';

void main() {
  test('write the schema fixture', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((r) async {
      r.response.write(_clash);
      await r.response.close();
    });
    final probe = AppDatabase(NativeDatabase.memory());
    final version = probe.schemaVersion;
    await probe.close();
    final file = File('test/data/schemas/v$version.sqlite');
    if (file.existsSync()) file.deleteSync();
    final services = await AppServices.open(
      database: AppDatabase(NativeDatabase(file)),
      keyStore: MemoryKeyStore(),
      host: () async => const HostInfo(
        platform: HostPlatform.android,
        stateDir: '/state',
        deviceName: 'fixture',
      ),
    );
    final added = await services.imports.addSubscription(
      url: 'http://127.0.0.1:${server.port}/sub?token=fake',
      defaultName: '订阅',
    );
    final id = added.configurationId;
    final node = await services.selfContent.addNode(
      const SelfNode(
        id: '',
        name: '自建 VPS',
        server: 'vps.example.com',
        port: 443,
        params: NodeParams.trojan(password: Secret('fake-self')),
      ),
    );
    final content = (await services.configurations.content(id))!.content;
    await services.selfContent.addChain(
      Chain(
        id: '',
        name: '链',
        hops: [
          MemberRef.source(configurationId: id, key: content.nodes.first.key),
          MemberRef.selfNode(id: node.id),
        ],
      ),
    );
    await services.selections.select(
      id,
      content.groups.single.key,
      MemberRef.source(configurationId: id, key: content.nodes.last.key),
    );
    await services.settings.updateDevice(
      (s) => s.copyWith(
        selectedConfigurationId: id,
        mixedPort: 7891,
        perAppList: ['org.example.app'],
      ),
    );
    await services.settings.updatePolicy(
      (p) => p.copyWith(
        geoInterval: GeoInterval.weekly,
        jsonOverride: const Secret('{"route": {"rules": []}}'),
      ),
    );
    await services.close();
    await server.close(force: true);
    expect(file.existsSync(), isTrue);
  });
}
