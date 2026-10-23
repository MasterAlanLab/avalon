// Opt-in cross-process acceptance. Only the fixture URL crosses the device
// boundary; session credentials and decrypted fixture data remain in memory.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:av_core/av_core.dart';
import 'package:avalon/app/services.dart';
import 'package:avalon/cloud/api_client.dart';
import 'package:avalon/cloud/cloud_development_config.dart';
import 'package:avalon/cloud/cloud_models.dart';
import 'package:avalon/data/database/database.dart';
import 'package:avalon/data/repositories/cloud_session_repository.dart';
import 'package:avalon/data/repositories/sync_repository.dart';
import 'package:avalon/data/vault/vault.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';

const deviceSyncApplicationId = 'app.getavalon.avalon.syncacceptance';

/// Runs one half of the same ordered business-repository scenario.
/// It never starts the runtime host, changes VPN state, or opens a personal DB.
Future<void> runDeviceSyncScenario({
  required String controlUrl,
  required String role,
}) async {
  if (role != 'sender' && role != 'peer') {
    throw StateError('Device sync acceptance role is invalid.');
  }
  final control = _Control(_loopback(controlUrl, allowPath: true));
  _Client? client;
  try {
    final fixture = await control.fixture();
    client = await _Client.open(fixture, role);
    await client.sync('initial_activation');
    await control.barrier('ready', role);

    if (role == 'sender') {
      await client.create('A', policy: false);
      await client.sync('a_upload');
      await client.check('A', edited: false, policy: false);
    }
    await control.barrier('a_published', role);

    if (role == 'peer') {
      await client.sync('a_download');
      await client.check('A', edited: false, policy: false);
      await client.edit('A', policy: true);
      await client.sync('b_edit_a_upload');
    }
    await control.barrier('b_edited_a', role);

    if (role == 'sender') {
      await client.sync('b_edit_a_download');
      await client.check('A', edited: true, policy: true);
    }
    await control.barrier('a_edit_received', role);

    if (role == 'peer') {
      await client.create('B', policy: false);
      await client.sync('b_upload');
      await client.check('B', edited: false, policy: false);
    }
    await control.barrier('b_published', role);

    if (role == 'sender') {
      await client.sync('b_download');
      await client.check('B', edited: false, policy: false);
      await client.edit('B', policy: true);
      await client.sync('a_edit_b_upload');
    }
    await control.barrier('a_edited_b', role);

    if (role == 'peer') {
      await client.sync('a_edit_b_download');
      await client.check('B', edited: true, policy: true);
    }
    await control.barrier('b_edit_received', role);

    if (role == 'sender') {
      await client.delete('A');
      await client.sync('a_delete_upload');
    }
    await control.barrier('a_deleted', role);

    if (role == 'peer') {
      await client.sync('a_delete_download');
      await client.checkDeleted('A');
      await client.delete('B');
      await client.sync('b_delete_upload');
    }
    await control.barrier('b_deleted', role);

    if (role == 'sender') {
      await client.sync('b_delete_download');
      await client.checkDeleted('B');
    }
    await control.barrier('deletes_received', role);

    if (role == 'sender') await client.retryInjectedFailures();
    await control.barrier('retry_published', role);
    if (role == 'peer') {
      await client.sync('retry_download');
      final nodes = await client.services.selfContent.nodes();
      _check(
        nodes.length == 1 && nodes.single.name == 'Acceptance retry',
        'retry_download_single_record',
      );
      _check(
        nodes.single.params ==
            const NodeParams.trojan(password: Secret(_secret)),
        'retry_download_secret',
      );
    }
    await control.barrier('complete', role);
    stdout.writeln('DEVICE_SYNC_${role.toUpperCase()}_PASS');
  } finally {
    await client?.close();
    control.close();
  }
}

const _secret = 'device-acceptance-synthetic-secret';

final class _Client {
  _Client(this.services, this.repository, this.transport, this.role);

  final AppServices services;
  final SyncRepository repository;
  final _Transport transport;
  final String role;
  final _ids = <String, _SetIds>{};

  static Future<_Client> open(Map<String, Object?> fixture, String role) async {
    final identity = _map(fixture[role]);
    TokenResponse tokens;
    try {
      tokens = TokenResponse.fromJson(_map(identity['tokens']));
    } on Object {
      throw StateError('Device sync fixture identity is invalid.');
    }
    final installationId = identity['installationId'];
    _check(installationId is String, 'fixture_installation');
    final base = fixture['baseUri'];
    _check(base is String, 'fixture_base');
    _check(fixture['syncProtocolVersion'] == 2, 'fixture_protocol');
    final transport = _Transport(
      identity['testIp'] as String? ?? fixture['testIp'] as String?,
    );
    final services = await AppServices.open(
      database: AppDatabase(NativeDatabase.memory()),
      keyStore: MemoryKeyStore(),
      exitIpUrl: '',
      cloudConfig: CloudDevelopmentConfig(
        baseUri: _loopback(base as String),
        syncProtocolVersion: 2,
      ),
      cloudTransport: transport,
    );
    try {
      // Restore only the fixture's installation sentinel before saving its
      // signed session through the real encrypted session repository.
      await (services.db.update(
        services.db.cloudSession,
      )..where((row) => row.id.equals(1))).write(
        CloudSessionCompanion(installationId: Value(installationId as String)),
      );
      await services.cloudSessions.save(
        StoredCloudSession(
          accountId: tokens.accountId,
          deviceId: tokens.deviceId,
          sessionId: tokens.sessionId,
          installationId: installationId,
          accessToken: tokens.accessToken,
          refreshToken: tokens.refreshToken,
          accessExpiresAt: tokens.accessExpiresAt,
          refreshExpiresAt: tokens.refreshExpiresAt,
        ),
      );
      final account = await services.cloudAuth!.account();
      _check(account.account.id == tokens.accountId, 'session_identity');
      return _Client(
        services,
        SyncRepository(services.db, services.secrets),
        transport,
        role,
      );
    } on Object {
      await services.close();
      rethrow;
    }
  }

  Future<void> sync(String stage) async {
    final worker = services.cloudSync;
    _check(worker != null, '${stage}_worker');
    await worker!.runNow();
    final state = await worker.watch().first;
    if (state.blockedReason != null || state.lastSyncAt == null) {
      // Reasons are the production worker's fixed categories, not server text.
      throw StateError(
        'Device sync $role/$stage failed: '
        '${state.blockedReason ?? 'NO_COMPLETED_SYNC'}.',
      );
    }
    _check(state.lifecycle?.backupState == 'ready', '${stage}_backup_ready');
    stdout.writeln('DEVICE_SYNC_STAGE $role $stage');
  }

  Future<void> create(String prefix, {required bool policy}) async {
    final parsed = parseContent(
      'trojan://$_secret@file.example.test:443#Acceptance-file',
    );
    final config = await services.configurations.add(
      kind: ConfigurationKind.file,
      name: 'Acceptance $prefix file',
      parsed: parsed,
      digest: 'device-acceptance-$prefix',
    );
    Future<SelfNode> node(String suffix) => services.selfContent.addNode(
      SelfNode(
        id: '',
        name: 'Acceptance $prefix $suffix',
        server: '$suffix.example.test',
        port: 443,
        params: const NodeParams.trojan(password: Secret(_secret)),
      ),
      joinGroup: suffix == 'first'
          ? (configurationId: config, groupKey: ContentKeys.custom)
          : null,
    );
    final first = await node('first');
    final second = await node('second');
    final chain = await services.selfContent.addChain(
      Chain(
        id: '',
        name: 'Acceptance $prefix chain',
        hops: [
          MemberRef.selfNode(id: first.id),
          MemberRef.source(
            configurationId: config,
            key: parsed.content.nodes.single.key,
          ),
        ],
      ),
      joinGroups: [(configurationId: config, groupKey: ContentKeys.custom)],
    );
    await services.settings.updatePolicy(
      (value) => value.copyWith(geoAutoUpdate: policy),
    );
    await services.selections.select(
      config,
      ContentKeys.custom,
      MemberRef.chain(id: chain.id),
    );
    _ids[prefix] = _SetIds(config, first.id, second.id, chain.id);
  }

  Future<_SetIds> ids(String prefix) async {
    final known = _ids[prefix];
    if (known != null) return known;
    final account = await services.cloudSessions.read();
    _check(account != null, 'map_session');
    final documents = await repository.documents(accountId: account!.accountId);
    String id(String type, String name) {
      final candidates = documents.where(
        (document) =>
            document.row.type == type &&
            !document.row.localDeleted &&
            document.localPayload?['name'] == name,
      );
      _check(candidates.length == 1, 'map_${prefix}_$type');
      final document = candidates.single;
      _check(document.row.localId != null, 'map_${prefix}_${type}_alias');
      return document.row.localId!;
    }

    final result = _SetIds(
      id('configuration', 'Acceptance $prefix file'),
      id('node', 'Acceptance $prefix first'),
      id('node', 'Acceptance $prefix second'),
      id('chain', 'Acceptance $prefix chain'),
    );
    _ids[prefix] = result;
    return result;
  }

  Future<void> check(
    String prefix, {
    required bool edited,
    required bool policy,
  }) async {
    final value = await ids(prefix);
    final suffix = edited ? ' edited' : '';
    final config = await services.configurations.get(value.config);
    _check(config?.name == 'Acceptance $prefix file$suffix', '${prefix}_file');
    final content = await services.configurations.content(value.config);
    _check(content != null, '${prefix}_file_content');
    final parsed = parseContent(
      'trojan://$_secret@file.example.test:443#Acceptance-file',
    );
    _check(
      _same(content!.content.nodes, parsed.content.nodes),
      '${prefix}_file_model_and_secret',
    );
    final first = await services.selfContent.node(value.first);
    _check(first != null, '${prefix}_node');
    _check(
      first!.node.name == 'Acceptance $prefix first$suffix' &&
          first.node.port == (edited ? 8443 : 443) &&
          first.node.params ==
              const NodeParams.trojan(password: Secret(_secret)),
      '${prefix}_node_value_and_secret',
    );
    final chain = await services.selfContent.chain(value.chain);
    _check(chain != null, '${prefix}_chain');
    final hops = [
      MemberRef.selfNode(id: value.first),
      MemberRef.source(
        configurationId: value.config,
        key: parsed.content.nodes.single.key,
      ),
    ];
    final expectedHops = edited ? hops.reversed.toList() : hops;
    _check(
      chain!.chain.name == 'Acceptance $prefix chain$suffix' &&
          _same(chain.chain.hops, expectedHops),
      '${prefix}_chain_aliases',
    );
    final memberships = await services.db.select(services.db.memberships).get();
    for (final (kind, owner) in [
      ('node', value.first),
      ('chain', value.chain),
    ]) {
      _check(
        memberships.any(
          (membership) =>
              membership.ownerKind == kind &&
              membership.ownerId == owner &&
              membership.configurationId == value.config &&
              membership.groupKey == ContentKeys.custom,
        ),
        '${prefix}_${kind}_membership_aliases',
      );
    }
    _check(
      (await services.settings.policy()).geoAutoUpdate == policy,
      '${prefix}_policy',
    );
    final selection = await services.selections.get(value.config);
    _check(
      selection[ContentKeys.custom] ==
          (edited
              ? MemberRef.selfNode(id: value.second)
              : MemberRef.chain(id: value.chain)),
      '${prefix}_selection_alias',
    );
    final account = await services.cloudSessions.read();
    final documents = await repository.documents(accountId: account!.accountId);
    _check(
      documents.map((document) => document.row.type).toSet().containsAll({
        'configuration',
        'node',
        'chain',
        'policy',
        'selection',
      }),
      '${prefix}_five_types',
    );
    _check(documents.every((document) => !document.dirty), '${prefix}_no_echo');
    stdout.writeln(
      'DEVICE_SYNC_CHECK $role $prefix ${edited ? 'edited' : 'new'}',
    );
  }

  Future<void> edit(String prefix, {required bool policy}) async {
    final value = await ids(prefix);
    await services.configurations.update(
      value.config,
      name: 'Acceptance $prefix file edited',
    );
    final first = await services.selfContent.node(value.first);
    _check(first != null, 'edit_${prefix}_node');
    await services.selfContent.updateNode(
      first!.node.copyWith(name: 'Acceptance $prefix first edited', port: 8443),
    );
    final chain = await services.selfContent.chain(value.chain);
    _check(chain != null, 'edit_${prefix}_chain');
    await services.selfContent.updateChain(
      chain!.chain.copyWith(
        name: 'Acceptance $prefix chain edited',
        hops: chain.chain.hops.reversed.toList(),
      ),
    );
    await services.settings.updatePolicy(
      (value) => value.copyWith(geoAutoUpdate: policy),
    );
    await services.selections.select(
      value.config,
      ContentKeys.custom,
      MemberRef.selfNode(id: value.second),
    );
  }

  Future<void> delete(String prefix) async {
    final value = await ids(prefix);
    await services.selfContent.deleteChain(value.chain);
    await services.selfContent.deleteNode(value.first);
    await services.selfContent.deleteNode(value.second);
    await services.configurations.delete(value.config);
    await checkDeleted(prefix);
  }

  Future<void> checkDeleted(String prefix) async {
    final value = await ids(prefix);
    _check(
      await services.configurations.get(value.config) == null &&
          await services.selfContent.node(value.first) == null &&
          await services.selfContent.node(value.second) == null &&
          await services.selfContent.chain(value.chain) == null,
      '${prefix}_deleted_content',
    );
    _check(
      (await services.selections.get(value.config)).isEmpty,
      '${prefix}_deleted_selection',
    );
    final memberships = await services.db.select(services.db.memberships).get();
    _check(
      memberships.every(
        (membership) => membership.configurationId != value.config,
      ),
      '${prefix}_deleted_memberships',
    );
    stdout.writeln('DEVICE_SYNC_DELETE $role $prefix');
  }

  Future<void> retryInjectedFailures() async {
    final node = await services.selfContent.addNode(
      const SelfNode(
        id: '',
        name: 'Acceptance retry baseline',
        server: 'retry.example.test',
        port: 443,
        params: NodeParams.trojan(password: Secret(_secret)),
      ),
    );
    await sync('retry_seed_upload');
    // Keep these sequential user edits in distinct fixture clock ticks. Equal
    // effective edit times deliberately retain the existing server winner.
    await Future<void>.delayed(const Duration(seconds: 2));
    await services.selfContent.updateNode(
      node.copyWith(name: 'Acceptance retry'),
    );
    final worker = services.cloudSync!;
    transport.offline = true;
    await worker.runNow();
    _check(
      (await worker.watch().first).blockedReason == 'OFFLINE',
      'injected_offline_reported',
    );
    _check(
      (await repository.findLocalDocument('node', node.id))?.dirty == true,
      'injected_offline_edit_preserved',
    );
    transport.offline = false;
    transport.dropNextPush = true;
    await worker.runNow();
    _check(transport.droppedPush != null, 'injected_ack_was_dropped');
    _check(
      (await worker.watch().first).blockedReason == 'OFFLINE',
      'injected_ack_loss_reported',
    );
    transport.offline = false;
    await sync('injected_failure_recovery');
    _check(transport.identicalRetry, 'injected_ack_retry_same_request');
    _check(
      (await repository.findLocalDocument('node', node.id))?.dirty == false,
      'injected_retry_outbox_cleared',
    );
    final recovered = await services.selfContent.nodes();
    _check(recovered.length == 1, 'injected_retry_single_record');
    _check(
      recovered.single.name == 'Acceptance retry' &&
          recovered.single.params ==
              const NodeParams.trojan(password: Secret(_secret)),
      'injected_retry_value_and_secret',
    );
    stdout.writeln('DEVICE_SYNC_INJECTED_OFFLINE_AND_ACK_RETRY_PASS');
  }

  Future<void> close() => services.close();
}

final class _SetIds {
  const _SetIds(this.config, this.first, this.second, this.chain);
  final String config;
  final String first;
  final String second;
  final String chain;
}

final class _Transport implements CloudTransport {
  _Transport(this.testIp);
  final String? testIp;
  final _http = HttpClientCloudTransport();
  bool offline = false;
  bool dropNextPush = false;
  Uint8List? droppedPush;
  bool identicalRetry = false;

  @override
  Future<CloudResponse> send(CloudRequest request) async {
    if (offline) throw const CloudNetworkException();
    final push = request.uri.path == '/v1/sync/push';
    if (push && droppedPush != null) {
      identicalRetry = _same(request.body ?? const <int>[], droppedPush!);
    }
    final response = await _http.send(
      CloudRequest(
        method: request.method,
        uri: request.uri,
        headers: {...request.headers, 'X-Cloud-Test-IP': ?testIp},
        body: request.body,
        timeout: request.timeout,
        responseMaxBytes: request.responseMaxBytes,
      ),
    );
    if (push && dropNextPush && response.statusCode == 200) {
      dropNextPush = false;
      droppedPush = Uint8List.fromList(request.body!);
      offline = true;
      throw const CloudNetworkException();
    }
    return response;
  }

  @override
  void close() => _http.close();
}

final class _Control {
  _Control(this.base);
  final Uri base;
  final _http = HttpClient()..connectionTimeout = const Duration(seconds: 10);

  Uri _uri(String suffix, [String? role]) => base.replace(
    path: '${base.path.replaceAll(RegExp(r'/+$'), '')}/$suffix',
    queryParameters: role == null ? null : {'role': role},
  );

  Future<Map<String, Object?>> fixture() => _request('GET', _uri('fixture'));

  Future<void> barrier(String stage, String role) async {
    final uri = _uri('barrier/$stage', role);
    await _request('POST', uri);
    final deadline = DateTime.now().add(const Duration(minutes: 3));
    while (true) {
      final result = await _request('GET', _uri('barrier/$stage'));
      if (result['ready'] == true) return;
      if (DateTime.now().isAfter(deadline)) {
        throw StateError('Device sync barrier $stage timed out.');
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }

  Future<Map<String, Object?>> _request(String method, Uri uri) async {
    try {
      final request = await _http.openUrl(method, uri);
      request.followRedirects = false;
      final response = await request.close().timeout(
        const Duration(seconds: 15),
      );
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw StateError('Control response was rejected.');
      }
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in response) {
        bytes.add(chunk);
        if (bytes.length > 128 * 1024) {
          throw StateError('Control response exceeded its limit.');
        }
      }
      return bytes.length == 0
          ? <String, Object?>{}
          : _map(jsonDecode(utf8.decode(bytes.takeBytes())));
    } on Object {
      throw StateError('Device sync loopback control request failed.');
    }
  }

  void close() => _http.close(force: true);
}

Uri _loopback(String value, {bool allowPath = false}) {
  final uri = Uri.tryParse(value);
  if (uri == null ||
      uri.scheme != 'http' ||
      !['127.0.0.1', 'localhost', '::1'].contains(uri.host) ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      (!allowPath && uri.path.isNotEmpty && uri.path != '/')) {
    throw StateError('Device sync acceptance requires loopback URLs.');
  }
  return uri;
}

Map<String, Object?> _map(Object? value) {
  if (value is! Map) {
    throw StateError('Device sync fixture shape is invalid.');
  }
  return value.cast<String, Object?>();
}

void _check(bool condition, String stage) {
  if (!condition) throw StateError('Device sync check failed: $stage.');
}

bool _same<T>(List<T> left, List<T> right) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) return false;
  }
  return true;
}
