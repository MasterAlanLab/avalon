// Invoked only by the isolated private-server harness. No account/token fixture
// is written to a file, sent to real email, or printed by this test.
import 'dart:convert';
import 'dart:io';

import 'package:av_core/av_core.dart';
import 'package:avalon/cloud/api_client.dart';
import 'package:avalon/cloud/auth_service.dart';
import 'package:avalon/cloud/cloud_models.dart';
import 'package:avalon/cloud/sync_engine.dart';
import 'package:avalon/cloud/sync_lifecycle_models.dart';
import 'package:avalon/cloud/sync_models.dart' show canonicalSyncJson;
import 'package:avalon/data/database/database.dart';
import 'package:avalon/data/ids.dart';
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

const _password = 'live-fixture-only-password';

final class _LiveTransport implements CloudTransport {
  _LiveTransport(this.testIp);
  final String testIp;
  final _http = HttpClientCloudTransport();
  bool dropNextPush = false;
  final pushBodies = <String>[];
  final controlBodies = <String>[];
  final dropControlActions = <String>{};

  @override
  Future<CloudResponse> send(CloudRequest request) async {
    if (request.uri.path == '/v1/sync/push') {
      pushBodies.add(utf8.decode(request.body!));
    }
    String? controlAction;
    if (request.uri.path == '/v1/sync/rebuild' && request.method == 'POST') {
      final body = utf8.decode(request.body!);
      controlBodies.add(body);
      controlAction = (jsonDecode(body) as Map)['action'] as String;
    }
    final response = await _http.send(
      CloudRequest(
        method: request.method,
        uri: request.uri,
        headers: {...request.headers, 'X-Cloud-Test-IP': testIp},
        body: request.body,
        timeout: request.timeout,
        responseMaxBytes: request.responseMaxBytes,
      ),
    );
    if (dropNextPush &&
        request.uri.path == '/v1/sync/push' &&
        response.statusCode == 200) {
      dropNextPush = false;
      throw const CloudNetworkException();
    }
    if (response.statusCode == 200 &&
        controlAction != null &&
        dropControlActions.remove(controlAction)) {
      throw const CloudNetworkException();
    }
    return response;
  }

  @override
  void close() => _http.close();
}

final class _LiveClient {
  _LiveClient(
    this.db,
    this.api,
    this.auth,
    this.sessions,
    this.sync,
    this.projection,
    this.worker,
    this.nodes,
    this.configurations,
    this.settings,
    this.selections,
    this.transport,
  );
  final AppDatabase db;
  final ApiClient api;
  final AuthService auth;
  final CloudSessionRepository sessions;
  final SyncRepository sync;
  final SyncProjection projection;
  SyncEngine worker;
  final SelfContentRepository nodes;
  final ConfigurationRepository configurations;
  final SettingsRepository settings;
  final SelectionRepository selections;
  final _LiveTransport transport;

  static Future<_LiveClient> open(
    Map<String, Object?> all,
    String name, {
    bool expiredAccess = false,
    bool lifecycleEnabled = false,
  }) async {
    final fixture = (all[name] as Map).cast<String, Object?>();
    final tokens = TokenResponse.fromJson(
      (fixture['tokens'] as Map).cast<String, Object?>(),
    );
    final db = AppDatabase(NativeDatabase.memory());
    final secrets = SecretStore(db, await Vault.open(MemoryKeyStore()));
    final sessions = CloudSessionRepository(db, secrets);
    // Seed the installation sentinel before restoring the signed fixture's
    // tokens, exactly as an existing installation retains its stable identity.
    await db
        .into(db.cloudSession)
        .insert(
          CloudSessionCompanion.insert(
            id: const Value(1),
            accountId: '',
            email: '',
            displayName: '',
            deviceId: '',
            installationId: fixture['installationId'] as String,
            accessSecretId: '',
            refreshSecretId: '',
            entitlementJson: 'null',
            loggedIn: false,
            updatedAt: 0,
          ),
        );
    await sessions.save(
      StoredCloudSession(
        accountId: tokens.accountId,
        deviceId: tokens.deviceId,
        sessionId: tokens.sessionId,
        installationId: fixture['installationId'] as String,
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        accessExpiresAt: expiredAccess
            ? DateTime.now().toUtc().subtract(const Duration(minutes: 1))
            : tokens.accessExpiresAt,
        refreshExpiresAt: tokens.refreshExpiresAt,
      ),
    );
    final transport = _LiveTransport(all['testIp'] as String);
    final api = ApiClient(
      baseUri: Uri.parse(all['baseUri'] as String),
      transport: transport,
      allowLoopbackHttp: true,
    );
    final auth = AuthService(
      api: api,
      sessions: sessions,
      deviceName: 'Dart live fixture',
      os: DeviceOs.android,
    );
    final sync = SyncRepository(db, secrets);
    final projection = SyncProjection(db, secrets, sync);
    final worker = SyncEngine(
      auth: auth,
      repository: sync,
      projection: projection,
      db: db,
      lifecycleEnabled: lifecycleEnabled,
    );
    final nodes = SelfContentRepository(
      db,
      secrets,
      onSyncEdit: projection.edited,
    );
    return _LiveClient(
      db,
      api,
      auth,
      sessions,
      sync,
      projection,
      worker,
      nodes,
      ConfigurationRepository(db, secrets, onSyncEdit: projection.edited),
      SettingsRepository(db, secrets, onSyncEdit: projection.edited),
      SelectionRepository(db, onSyncEdit: projection.edited),
      transport,
    );
  }

  Future<void> close() async {
    await worker.dispose();
    api.close();
    await db.close();
  }

  Future<void> enableLifecycle() async {
    await worker.dispose();
    worker = SyncEngine(
      auth: auth,
      repository: sync,
      projection: projection,
      db: db,
      lifecycleEnabled: true,
    );
  }
}

void main() {
  final raw = Platform.environment['AVALON_CLOUD_SYNC_LIVE_FIXTURE'];
  test(
    'real Go/PostgreSQL auth and sync worker with encrypted local SQLite',
    () async {
      final fixture = (jsonDecode(raw!) as Map).cast<String, Object?>();
      final sender = await _LiveClient.open(
        fixture,
        'sender',
        expiredAccess: true,
      );
      addTearDown(sender.close);
      final peer = await _LiveClient.open(fixture, 'peer');
      addTearDown(peer.close);
      final outsider = await _LiveClient.open(fixture, 'outsider');
      addTearDown(outsider.close);
      final free = await _LiveClient.open(fixture, 'free');
      addTearDown(free.close);

      final before = (await sender.sessions.read())!;
      final account = await sender.auth.account();
      final afterRefresh = (await sender.sessions.read())!;
      expect(
        account.account.id == before.accountId,
        isTrue,
        reason: 'LIVE_SESSION_IDENTITY',
      );
      expect(
        afterRefresh.refreshToken != before.refreshToken,
        isTrue,
        reason: 'LIVE_REFRESH_ROTATED',
      );
      expect(
        afterRefresh.sessionId == before.sessionId,
        isTrue,
        reason: 'LIVE_REFRESH_SAME_SESSION',
      );
      stdout.writeln('LIVE_STAGE session');

      final node = await sender.nodes.addNode(
        const SelfNode(
          id: '',
          name: 'Live node',
          server: 'proxy.example.test',
          port: 443,
          params: NodeParams.trojan(password: Secret(_password)),
        ),
      );
      await sender.worker.runNow();
      final state = await sender.sync.state(before.accountId);
      expect(
        state.bootstrapCompleted,
        isTrue,
        reason: 'LIVE_BOOTSTRAP_COMPLETE',
      );
      expect(state.blockedReason, isNull, reason: 'LIVE_UPLOAD_UNBLOCKED');
      final owner = (await sender.sync.findLocalDocument('node', node.id))!;
      expect(
        owner.row.accountId == before.accountId,
        isTrue,
        reason: 'LIVE_UPLOAD_BOUND',
      );
      expect(owner.dirty, isFalse, reason: 'LIVE_UPLOAD_CONFIRMED');
      expect(
        owner.row.remoteRevision != null,
        isTrue,
        reason: 'LIVE_UPLOAD_REVISION',
      );
      stdout.writeln('LIVE_STAGE worker_upload');

      await sender.nodes.updateNode(node.copyWith(name: 'Live edited'));
      sender.transport.dropNextPush = true;
      final pushBefore = sender.transport.pushBodies.length;
      await sender.worker.runNow();
      final unknown = (await sender.sync.document(owner.row.documentId))!;
      expect(unknown.dirty, isTrue, reason: 'LIVE_UNKNOWN_RESULT_DIRTY');
      expect(
        unknown.meta!.inFlightMutationId != null,
        isTrue,
        reason: 'LIVE_UNKNOWN_RESULT_FROZEN',
      );
      final sentBody = sender.transport.pushBodies[pushBefore];
      await sender.worker.runNow();
      final accepted = (await sender.sync.document(owner.row.documentId))!;
      expect(accepted.dirty, isFalse, reason: 'LIVE_RETRY_CONFIRMED');
      expect(
        accepted.meta!.inFlightMutationId,
        isNull,
        reason: 'LIVE_RETRY_CLEARED',
      );
      expect(
        sender.transport.pushBodies
            .skip(pushBefore)
            .every((body) => body == sentBody),
        isTrue,
        reason: 'LIVE_RETRY_EXACT_BODY',
      );
      stdout.writeln('LIVE_STAGE retry');

      await peer.worker.runNow();
      final peerAccount = (await peer.sessions.read())!.accountId;
      final downloaded = (await peer.sync.findDocument(
        peerAccount,
        owner.row.recordId,
      ))!;
      final restoredNode = (await peer.nodes.node(
        downloaded.row.localId!,
      ))!.node;
      expect(restoredNode.name, 'Live edited', reason: 'LIVE_PEER_NAME');
      expect(
        restoredNode.params is TrojanParams,
        isTrue,
        reason: 'LIVE_PEER_PROTOCOL',
      );
      expect(
        (restoredNode.params as TrojanParams).password.value == _password,
        isTrue,
        reason: 'LIVE_PEER_CREDENTIAL',
      );
      expect(downloaded.dirty, isFalse, reason: 'LIVE_REMOTE_NO_ECHO');
      stdout.writeln('LIVE_STAGE peer_pull');

      await outsider.worker.runNow();
      expect(
        await outsider.nodes.nodes(),
        isEmpty,
        reason: 'LIVE_ACCOUNT_ISOLATION',
      );
      final outsideAccount = (await outsider.sessions.read())!.accountId;
      expect(
        await outsider.sync.documents(accountId: outsideAccount),
        isEmpty,
        reason: 'LIVE_CANONICAL_ISOLATION',
      );
      stdout.writeln('LIVE_STAGE isolation');

      await sender.auth.removeDevice((await peer.sessions.read())!.deviceId);
      var revoked = false;
      try {
        await peer.auth.account();
      } on CloudApiException catch (error) {
        revoked =
            error.httpStatus == 401 && error.code.value == 'SESSION_REVOKED';
      }
      expect(revoked, isTrue, reason: 'LIVE_REVOKED_SESSION_REJECTED');
      expect(
        await peer.auth.session(),
        isNull,
        reason: 'LIVE_REVOKED_SESSION_CLEARED',
      );
      expect(
        await peer.nodes.nodes(),
        hasLength(1),
        reason: 'LIVE_REVOKED_LOCAL_CONTENT_RETAINED',
      );
      stdout.writeln('LIVE_STAGE revocation');

      final freeNode = await free.nodes.addNode(
        const SelfNode(
          id: '',
          name: 'Free local node',
          server: 'free.example.test',
          port: 443,
          params: NodeParams.trojan(password: Secret('free-fixture-password')),
        ),
      );
      await free.worker.runNow();
      final freeAccount = (await free.sessions.read())!.accountId;
      expect(
        (await free.sync.state(freeAccount)).blockedReason,
        'NO_ENTITLEMENT',
        reason: 'LIVE_ENTITLEMENT_FAILURE',
      );
      expect(
        (await free.nodes.node(freeNode.id)) != null,
        isTrue,
        reason: 'LIVE_FREE_LOCAL_FEATURES',
      );
      stdout.writeln('LIVE_STAGE local_first');
      stdout.writeln('LIVE_CLIENT_SYNC_PASS');
    },
    skip: raw == null ? 'run the isolated private-server live harness' : false,
    timeout: const Timeout(Duration(minutes: 2)),
  );
  final v2Raw = Platform.environment['AVALON_CLOUD_SYNC_V2_LIVE_FIXTURE'];
  test(
    'real protocol 2 migration, rebuild publication and durable worker replay',
    () async {
      final fixture = (jsonDecode(v2Raw!) as Map).cast<String, Object?>();
      Future<_LiveClient> client(String name, {bool lifecycle = true}) async {
        final value = await _LiveClient.open(
          fixture,
          name,
          lifecycleEnabled: lifecycle,
        );
        addTearDown(value.close);
        return value;
      }

      final sender = await client('sender');
      final peer = await client('peer');
      final outsider = await client('outsider');
      final free = await client('free');
      final owner = await client('rebuilt');
      final receiver = await client('rebuiltPeer');
      final legacy = await client('legacy', lifecycle: false);
      Future<String> token(_LiveClient value) async =>
          (await value.sessions.read())!.accessToken;
      Future<SyncLifecycleStatus> status(_LiveClient value) async =>
          value.api.syncLifecycle(accessToken: await token(value));

      expect(
        (await status(sender)).spaceState,
        'noSpace',
        reason: 'LIVE_V2_INITIAL_NO_SPACE',
      );
      final initialNode = await sender.nodes.addNode(
        const SelfNode(
          id: '',
          name: 'V2 initial',
          server: 'initial.example.test',
          port: 443,
          params: NodeParams.trojan(password: Secret(_password)),
        ),
      );
      sender.transport.dropNextPush = true;
      await sender.worker.runNow();
      final initialDocument = (await sender.sync.findLocalDocument(
        'node',
        initialNode.id,
      ))!;
      expect(
        initialDocument.meta!.inFlightMutationId != null,
        isTrue,
        reason: 'LIVE_V2_INITIAL_UNKNOWN_FROZEN',
      );
      await sender.worker.runNow();
      expect(
        sender.transport.pushBodies.toSet().length,
        1,
        reason: 'LIVE_V2_INITIAL_EXACT_RETRY',
      );
      final initial = await status(sender);
      expect(initial.spaceOrigin, 'initial', reason: 'LIVE_V2_INITIAL_ORIGIN');
      expect(
        initial.headRevision,
        1,
        reason: 'LIVE_V2_INITIAL_REPLAY_NO_EXTRA_REVISION',
      );
      await peer.worker.runNow();
      final receivedInitial = (await peer.nodes.nodes()).single;
      expect(
        receivedInitial.name,
        'V2 initial',
        reason: 'LIVE_V2_INITIAL_PEER_CONTENT',
      );
      expect(
        (receivedInitial.params as TrojanParams).password.value == _password,
        isTrue,
        reason: 'LIVE_V2_INITIAL_PEER_SECRET',
      );
      stdout.writeln('LIVE_STAGE v2_initial');

      // A committed protocol 1 mutation with an unknown response must be
      // promoted in place after the server explicitly proves legacy origin.
      final legacyNode = await legacy.nodes.addNode(
        const SelfNode(
          id: '',
          name: 'Legacy unknown',
          server: 'legacy.example.test',
          port: 443,
          params: NodeParams.trojan(password: Secret(_password)),
        ),
      );
      legacy.transport.dropNextPush = true;
      await legacy.worker.runNow();
      final legacyBefore = (await legacy.sync.findLocalDocument(
        'node',
        legacyNode.id,
      ))!;
      final oldMutation = legacyBefore.meta!.inFlightMutationId;
      expect(
        oldMutation != null,
        isTrue,
        reason: 'LIVE_V2_LEGACY_UNKNOWN_FROZEN',
      );
      await legacy.enableLifecycle();
      await legacy.worker.runNow();
      final legacyStatus = await status(legacy);
      final legacyAfter = (await legacy.sync.document(
        legacyBefore.row.documentId,
      ))!;
      expect(
        legacyStatus.spaceOrigin,
        'legacy',
        reason: 'LIVE_V2_LEGACY_PROOF',
      );
      expect(
        legacyStatus.headRevision,
        1,
        reason: 'LIVE_V2_LEGACY_REPLAY_NO_EXTRA_REVISION',
      );
      expect(
        legacyAfter.row.recordId == legacyBefore.row.recordId,
        isTrue,
        reason: 'LIVE_V2_LEGACY_RECORD_PRESERVED',
      );
      expect(
        legacyAfter.dirty,
        isFalse,
        reason: 'LIVE_V2_LEGACY_UNKNOWN_RESOLVED',
      );
      final legacyBodies = legacy.transport.pushBodies
          .map((body) => (jsonDecode(body) as Map)['mutations'])
          .toList();
      expect(
        jsonEncode(legacyBodies.first) == jsonEncode(legacyBodies.last),
        isTrue,
        reason: 'LIVE_V2_LEGACY_MUTATION_UNCHANGED',
      );
      await _liveFailure(
        legacy.api.pullSync(accessToken: await token(legacy), cursor: 0),
        426,
        'SCHEMA_UNSUPPORTED',
        'LIVE_V2_LEGACY_NO_DOWNGRADE',
      );
      stdout.writeln('LIVE_STAGE v2_legacy');

      final rebuilt = await status(owner);
      final generation = rebuilt.syncGeneration!;
      expect(rebuilt.spaceOrigin, 'rebuilt', reason: 'LIVE_V2_REBUILT_ORIGIN');
      expect(
        rebuilt.backupState,
        'rebuildRequired',
        reason: 'LIVE_V2_REBUILD_REQUIRED',
      );
      await owner.worker.runNow();
      await receiver.worker.runNow();
      final foreignStart = SyncRebuildControlRequest.start(
        operationId: newId(),
        syncGeneration: generation,
        manifest: SyncRebuildManifest(manifestId: newId(), entries: []),
      );
      final foreignAttempt = await receiver.api.controlSyncRebuild(
        accessToken: await token(receiver),
        request: foreignStart,
      );
      await _liveFailure(
        owner.api.controlSyncRebuild(
          accessToken: await token(owner),
          request: SyncRebuildControlRequest.cancel(
            operationId: newId(),
            syncGeneration: generation,
            expectedAttemptId: foreignAttempt.attempt.attemptId,
          ),
        ),
        409,
        'SYNC_REBUILD_OWNER_CHANGED',
        'LIVE_V2_OWNER_GUARD',
      );
      final claim = await owner.api.controlSyncRebuild(
        accessToken: await token(owner),
        request: SyncRebuildControlRequest.claim(
          operationId: newId(),
          syncGeneration: generation,
          expectedAttemptId: foreignAttempt.attempt.attemptId,
          manifest: SyncRebuildManifest(manifestId: newId(), entries: []),
        ),
      );
      final superseded = await receiver.api.getSyncRebuild(
        accessToken: await token(receiver),
        syncGeneration: generation,
        attemptId: foreignAttempt.attempt.attemptId,
      );
      expect(
        superseded.phase,
        'superseded',
        reason: 'LIVE_V2_CLAIM_RETIRES_OLD_OWNER',
      );
      final originalStart = await receiver.api.controlSyncRebuild(
        accessToken: await token(receiver),
        request: foreignStart,
      );
      expect(
        originalStart.attempt.attemptId == foreignAttempt.attempt.attemptId,
        isTrue,
        reason: 'LIVE_V2_OLD_RECEIPT_NO_OWNER_RESTORE',
      );
      expect(
        (await status(owner)).rebuild!.attemptId == claim.attempt.attemptId,
        isTrue,
        reason: 'LIVE_V2_CURRENT_OWNER_UNCHANGED',
      );
      await owner.api.controlSyncRebuild(
        accessToken: await token(owner),
        request: SyncRebuildControlRequest.cancel(
          operationId: newId(),
          syncGeneration: generation,
          expectedAttemptId: claim.attempt.attemptId,
        ),
      );
      expect(
        (await status(owner)).backupState,
        'rebuildRequired',
        reason: 'LIVE_V2_CANCEL_RETURNS_REQUIRED',
      );
      stdout.writeln('LIVE_STAGE v2_owner');

      for (final name in ['Rebuild A', 'Rebuild B']) {
        await owner.nodes.addNode(
          SelfNode(
            id: '',
            name: name,
            server: 'rebuild.example.test',
            port: 443,
            params: const NodeParams.trojan(password: Secret(_password)),
          ),
        );
      }
      final independent = await receiver.nodes.addNode(
        const SelfNode(
          id: '',
          name: 'Independent offline',
          server: 'offline.example.test',
          port: 443,
          params: NodeParams.trojan(password: Secret(_password)),
        ),
      );
      await owner.worker.runNow();
      owner.transport.dropControlActions.addAll(['start', 'complete']);
      owner.transport.dropNextPush = true;
      await expectLater(
        owner.worker.rebuildFromDevice(),
        throwsA(isA<CloudNetworkException>()),
      );
      final started = (await status(owner)).rebuild!;
      expect(
        started.stagedRecordCount,
        0,
        reason: 'LIVE_V2_START_UNKNOWN_COMMITTED',
      );
      await owner.enableLifecycle();
      await owner.worker.runNow();
      final staged = (await status(owner)).rebuild!;
      expect(
        staged.stagedRecordCount,
        staged.recordCount,
        reason: 'LIVE_V2_PUSH_UNKNOWN_STAGED',
      );
      expect(
        staged.attemptId == started.attemptId,
        isTrue,
        reason: 'LIVE_V2_START_RETRY_SAME_ATTEMPT',
      );
      await _liveFailure(
        receiver.api.pullSyncV2(
          accessToken: await token(receiver),
          syncGeneration: generation,
          cursor: 0,
        ),
        409,
        'SYNC_REBUILD_IN_PROGRESS',
        'LIVE_V2_STAGING_NOT_DOWNLOADABLE',
      );
      stdout.writeln('LIVE_STAGE v2_staging');

      await owner.enableLifecycle();
      await owner.worker.runNow();
      expect(
        (await status(owner)).backupState,
        'ready',
        reason: 'LIVE_V2_COMPLETE_UNKNOWN_PUBLISHED',
      );
      await owner.enableLifecycle();
      await owner.worker.runNow();
      final ownerState = await owner.sync.state(rebuilt.accountId);
      expect(
        ownerState.blockedReason,
        isNull,
        reason: 'LIVE_V2_COMPLETE_REPLAY_CONFIRMED',
      );
      expect(
        ownerState.bootstrapCompleted,
        isTrue,
        reason: 'LIVE_V2_REBUILD_FULL_PULL_COMPLETE',
      );
      for (final action in ['start', 'complete']) {
        final bodies = owner.transport.controlBodies
            .where((body) => (jsonDecode(body) as Map)['action'] == action)
            .toList();
        expect(
          bodies.length,
          greaterThanOrEqualTo(2),
          reason: 'LIVE_V2_CONTROL_REPLAY_EXECUTED',
        );
        expect(bodies.toSet().length, 1, reason: 'LIVE_V2_CONTROL_EXACT_RETRY');
      }
      expect(
        owner.transport.pushBodies.toSet().length,
        1,
        reason: 'LIVE_V2_STAGED_PUSH_EXACT_RETRY',
      );
      final published = await owner.api.getSyncRebuild(
        accessToken: await token(owner),
        syncGeneration: generation,
        attemptId: started.attemptId,
      );
      expect(published.phase, 'published', reason: 'LIVE_V2_PUBLISHED_RECEIPT');
      expect(
        published.publishedCursor,
        2,
        reason: 'LIVE_V2_ONE_COMPLETE_SNAPSHOT',
      );
      await receiver.worker.runNow();
      final receiverNodes = await receiver.nodes.nodes();
      expect(
        receiverNodes.map((value) => value.name).toSet(),
        {'Independent offline', 'Rebuild A', 'Rebuild B'},
        reason: 'LIVE_V2_PEER_ATOMIC_FULL_PULL',
      );
      final independentDocument = (await receiver.sync.findLocalDocument(
        'node',
        independent.id,
      ))!;
      expect(
        independentDocument.row.accountId,
        isNull,
        reason: 'LIVE_V2_INDEPENDENT_LOCAL_NOT_AUTO_UPLOADED',
      );
      final page = await receiver.api.pullSyncV2(
        accessToken: await token(receiver),
        syncGeneration: generation,
        cursor: 0,
      );
      expect(page.records.length, 2, reason: 'LIVE_V2_NO_OLD_MIRROR_REUPLOAD');
      expect(
        page.nextCursor,
        page.headRevision,
        reason: 'LIVE_V2_PULL_FINAL_HEAD',
      );
      stdout.writeln('LIVE_STAGE v2_publish');

      await outsider.worker.runNow();
      expect(
        await outsider.nodes.nodes(),
        isEmpty,
        reason: 'LIVE_V2_ACCOUNT_ISOLATION',
      );
      await _liveFailure(
        outsider.api.getSyncRebuild(
          accessToken: await token(outsider),
          syncGeneration: generation,
          attemptId: started.attemptId,
        ),
        404,
        'SYNC_REBUILD_NOT_FOUND',
        'LIVE_V2_ATTEMPT_ISOLATION',
      );
      final local = await free.nodes.addNode(
        const SelfNode(
          id: '',
          name: 'Free local',
          server: 'free.example.test',
          port: 443,
          params: NodeParams.trojan(password: Secret(_password)),
        ),
      );
      await free.worker.runNow();
      expect(
        (await free.sync.state(
          (await free.sessions.read())!.accountId,
        )).blockedReason,
        'NO_ENTITLEMENT',
        reason: 'LIVE_V2_FREE_NO_SYNC',
      );
      expect(
        await free.nodes.node(local.id) != null,
        isTrue,
        reason: 'LIVE_V2_FREE_LOCAL_RETAINED',
      );
      stdout.writeln('LIVE_STAGE v2_isolation');
      try {
        await _fiveTypeRoundTrip(sender, peer);
      } on Object catch (error, stack) {
        final position = RegExp(
          r'sync_live_test\.dart:(\d+):(\d+)',
        ).firstMatch(stack.toString());
        final type = error.runtimeType.toString().toUpperCase().replaceAll(
          RegExp('[^A-Z0-9_]'),
          '_',
        );
        stdout.writeln(
          'LIVE_V2_FIVE_TYPES_FAILURE_TYPE_${type}_'
          'LINE_${position?.group(1) ?? 'UNKNOWN'}',
        );
        rethrow;
      }
      stdout.writeln('LIVE_CLIENT_SYNC_V2_PASS');
    },
    skip: v2Raw == null
        ? 'run the isolated private-server live harness'
        : false,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

Future<void> _fiveTypeRoundTrip(_LiveClient sender, _LiveClient peer) async {
  // These are new records in the already-isolated fixture. All edits take the
  // same business-repository path as the app; only the frozen late request
  // below uses the repository's durable outbox to control delivery order.
  final parsed = parseContent(
    'trojan://five-type-file-secret@file.example.test:443#Five-type-file',
  );
  final configuration = await sender.configurations.add(
    kind: ConfigurationKind.file,
    name: 'Five-type file A',
    parsed: parsed,
    digest: 'five-type-synthetic-file',
  );
  final first = await sender.nodes.addNode(
    const SelfNode(
      id: '',
      name: 'Five-type first A',
      server: 'first.example.test',
      port: 443,
      params: NodeParams.trojan(password: Secret(_password)),
    ),
    joinGroup: (configurationId: configuration, groupKey: ContentKeys.custom),
  );
  final second = await sender.nodes.addNode(
    const SelfNode(
      id: '',
      name: 'Five-type second A',
      server: 'second.example.test',
      port: 443,
      params: NodeParams.trojan(password: Secret(_password)),
    ),
  );
  final chain = await sender.nodes.addChain(
    Chain(
      id: '',
      name: 'Five-type chain A',
      hops: [
        MemberRef.selfNode(id: first.id),
        MemberRef.source(
          configurationId: configuration,
          key: parsed.content.nodes.single.key,
        ),
      ],
    ),
    joinGroups: [
      (configurationId: configuration, groupKey: ContentKeys.custom),
    ],
  );
  await sender.settings.updatePolicy((p) => p.copyWith(geoAutoUpdate: false));
  await sender.selections.select(
    configuration,
    ContentKeys.custom,
    MemberRef.chain(id: chain.id),
  );
  stdout.writeln('LIVE_V2_FIVE_TYPES_SEEDED');

  Future<void> run(_LiveClient client, String label) async {
    await client.worker.runNow();
    final status = await client.worker.watch().first;
    final stage = label.toUpperCase();
    final blocked = (status.blockedReason ?? 'NONE').replaceAll(
      RegExp('[^A-Z0-9_]'),
      '_',
    );
    stdout.writeln('LIVE_V2_FIVE_TYPES_WORKER_${stage}_BLOCKED_$blocked');
    expect(
      status.blockedReason,
      isNull,
      reason: 'LIVE_V2_FIVE_TYPES_WORKER_UNBLOCKED',
    );
  }

  await run(sender, 'sender_initial');
  await run(peer, 'peer_initial');

  Future<String> localId(_LiveClient client, String wireId) async {
    final account = (await client.sessions.read())!.accountId;
    final document = await client.sync.findDocument(account, wireId);
    expect(
      document?.row.localId != null,
      isTrue,
      reason: 'LIVE_V2_FIVE_TYPES_DOCUMENT_PROJECTED',
    );
    return document!.row.localId!;
  }

  final peerConfiguration = await localId(peer, configuration);
  final peerFirst = await localId(peer, first.id);
  final peerSecond = await localId(peer, second.id);
  final peerChain = await localId(peer, chain.id);
  final peerFile = (await peer.configurations.content(peerConfiguration))!;
  expect(
    (await peer.configurations.get(peerConfiguration))!.name,
    'Five-type file A',
    reason: 'LIVE_V2_CONFIGURATION_A_TO_B',
  );
  expect(
    peerFile.content.nodes.single == parsed.content.nodes.single,
    isTrue,
    reason: 'LIVE_V2_FILE_MODEL_AND_SECRET_A_TO_B',
  );
  final downloadedFirst = (await peer.nodes.node(peerFirst))!.node;
  expect(downloadedFirst.name, first.name, reason: 'LIVE_V2_NODE_A_TO_B');
  expect(
    downloadedFirst.params == first.params,
    isTrue,
    reason: 'LIVE_V2_NODE_SECRET_A_TO_B',
  );
  final downloadedChain = (await peer.nodes.chain(peerChain))!.chain;
  expect(downloadedChain.hops, [
    MemberRef.selfNode(id: peerFirst),
    MemberRef.source(
      configurationId: peerConfiguration,
      key: parsed.content.nodes.single.key,
    ),
  ], reason: 'LIVE_V2_CHAIN_LOCAL_REFERENCES_A_TO_B');
  final memberships = await peer.db.select(peer.db.memberships).get();
  expect(
    memberships.any(
          (m) =>
              m.ownerKind == 'node' &&
              m.ownerId == peerFirst &&
              m.configurationId == peerConfiguration &&
              m.groupKey == ContentKeys.custom,
        ) &&
        memberships.any(
          (m) =>
              m.ownerKind == 'chain' &&
              m.ownerId == peerChain &&
              m.configurationId == peerConfiguration &&
              m.groupKey == ContentKeys.custom,
        ),
    isTrue,
    reason: 'LIVE_V2_MEMBERSHIP_LOCAL_REFERENCES_A_TO_B',
  );
  expect(
    (await peer.settings.policy()).geoAutoUpdate,
    isFalse,
    reason: 'LIVE_V2_POLICY_A_TO_B',
  );
  expect(
    (await peer.selections.get(peerConfiguration))[ContentKeys.custom],
    MemberRef.chain(id: peerChain),
    reason: 'LIVE_V2_SELECTION_LOCAL_REFERENCE_A_TO_B',
  );
  stdout.writeln('LIVE_STAGE v2_five_types_a_to_b');

  await peer.configurations.update(peerConfiguration, name: 'Five-type file B');
  await peer.nodes.updateNode(
    downloadedFirst.copyWith(name: 'Five-type first B', port: 8443),
  );
  await peer.nodes.updateChain(
    downloadedChain.copyWith(
      name: 'Five-type chain B',
      hops: downloadedChain.hops.reversed.toList(),
    ),
  );
  await peer.settings.updatePolicy((p) => p.copyWith(geoAutoUpdate: true));
  await peer.selections.select(
    peerConfiguration,
    ContentKeys.custom,
    MemberRef.selfNode(id: peerSecond),
  );
  await run(peer, 'peer_edit');
  await run(sender, 'sender_edit');
  expect(
    (await sender.configurations.get(configuration))!.name,
    'Five-type file B',
    reason: 'LIVE_V2_CONFIGURATION_B_TO_A',
  );
  final returnedFirst = (await sender.nodes.node(first.id))!.node;
  expect(
    returnedFirst.name == 'Five-type first B' && returnedFirst.port == 8443,
    isTrue,
    reason: 'LIVE_V2_NODE_B_TO_A',
  );
  final returnedChain = (await sender.nodes.chain(chain.id))!.chain;
  expect(returnedChain.name, 'Five-type chain B');
  expect(
    returnedChain.hops,
    chain.hops.reversed.toList(),
    reason: 'LIVE_V2_CHAIN_LOCAL_REFERENCES_B_TO_A',
  );
  expect(
    (await sender.settings.policy()).geoAutoUpdate,
    isTrue,
    reason: 'LIVE_V2_POLICY_B_TO_A',
  );
  expect(
    (await sender.selections.get(configuration))[ContentKeys.custom],
    MemberRef.selfNode(id: second.id),
    reason: 'LIVE_V2_SELECTION_LOCAL_REFERENCE_B_TO_A',
  );
  for (final client in [sender, peer]) {
    final account = (await client.sessions.read())!.accountId;
    final documents = await client.sync.documents(accountId: account);
    expect(documents.map((d) => d.row.type).toSet(), {
      'configuration',
      'node',
      'chain',
      'policy',
      'selection',
    }, reason: 'LIVE_V2_FIVE_TYPES_BOUND');
    expect(
      documents.every((d) => !d.dirty),
      isTrue,
      reason: 'LIVE_V2_FIVE_TYPES_NO_ECHO',
    );
  }
  stdout.writeln('LIVE_STAGE v2_five_types_b_to_a');

  // Freeze B's older edit before A observes it. A then publishes a newer edit,
  // so B's delayed request must be judged without replacing the newer value.
  final oldPeerNode = (await peer.nodes.node(peerFirst))!.node;
  await peer.nodes.updateNode(oldPeerNode.copyWith(name: 'Delayed older B'));
  final identity = (await peer.sync.capture(0))!;
  final frozen = await peer.sync.preparePush(identity, () => true);
  expect(frozen.length, 1, reason: 'LIVE_V2_CONFLICT_OLD_EDIT_FROZEN');
  final olderTime = (await peer.nodes.node(peerFirst))!.editedAt;
  await Future<void>.delayed(const Duration(milliseconds: 20));
  await sender.nodes.updateNode(returnedFirst.copyWith(name: 'Newer A wins'));
  expect(
    (await sender.nodes.node(first.id))!.editedAt.isAfter(olderTime),
    isTrue,
    reason: 'LIVE_V2_CONFLICT_DISTINCT_EDIT_TIMES',
  );
  await run(sender, 'sender_newer');
  final pushesBefore = peer.transport.pushBodies.length;
  await run(peer, 'peer_delayed');
  expect(
    peer.transport.pushBodies.length > pushesBefore,
    isTrue,
    reason: 'LIVE_V2_CONFLICT_OLD_REQUEST_DELIVERED',
  );
  final replay =
      (jsonDecode(peer.transport.pushBodies[pushesBefore]) as Map)['mutations']
          as List;
  expect(
    canonicalSyncJson(replay.single) == frozen.single.envelopeJson,
    isTrue,
    reason: 'LIVE_V2_CONFLICT_OLD_REQUEST_UNCHANGED',
  );
  await run(sender, 'sender_converge');
  expect(
    (await peer.nodes.node(peerFirst))!.node.name == 'Newer A wins' &&
        (await sender.nodes.node(first.id))!.node.name == 'Newer A wins',
    isTrue,
    reason: 'LIVE_V2_CONFLICT_CONVERGED',
  );
  expect(
    await peer.sync.preparePush(identity, () => true),
    isEmpty,
    reason: 'LIVE_V2_CONFLICT_NO_REUPLOAD_LOOP',
  );
  stdout.writeln('LIVE_STAGE v2_late_conflict');

  await expectLater(
    peer.nodes.deleteNode(peerFirst),
    throwsA(isA<NodeInUseException>()),
    reason: 'LIVE_V2_CHAIN_PREVENTS_HOP_DELETION',
  );
  await peer.nodes.deleteChain(peerChain);
  await peer.nodes.deleteNode(peerFirst);
  await peer.configurations.delete(peerConfiguration);
  await run(peer, 'peer_delete');
  await run(sender, 'sender_delete');
  expect(await sender.nodes.chain(chain.id), isNull);
  expect(await sender.nodes.node(first.id), isNull);
  expect(await sender.configurations.get(configuration), isNull);
  expect(await sender.configurations.content(configuration), isNull);
  expect(
    await sender.selections.get(configuration),
    isEmpty,
    reason: 'LIVE_V2_CONFIGURATION_DELETE_CLEARS_SELECTION',
  );
  expect(
    (await sender.db.select(sender.db.memberships).get()).any(
      (m) => m.configurationId == configuration,
    ),
    isFalse,
    reason: 'LIVE_V2_CONFIGURATION_DELETE_CLEARS_MEMBERSHIPS',
  );
  final account = (await sender.sessions.read())!.accountId;
  for (final record in [configuration, first.id, chain.id]) {
    expect(
      (await sender.sync.findDocument(account, record))!.row.localDeleted,
      isTrue,
      reason: 'LIVE_V2_REMOTE_TOMBSTONE_APPLIED',
    );
  }
  await sender.nodes.deleteNode(second.id);
  await run(sender, 'sender_delete_second');
  await run(peer, 'peer_delete_second');
  expect(
    await peer.nodes.node(peerSecond),
    isNull,
    reason: 'LIVE_V2_NODE_DELETE_A_TO_B',
  );
  stdout.writeln('LIVE_STAGE v2_bidirectional_delete');
}

Future<void> _liveFailure(
  Future<Object?> request,
  int status,
  String code,
  String reason,
) async {
  var rejected = false;
  try {
    await request;
  } on CloudApiException catch (error) {
    rejected = error.httpStatus == status && error.code.value == code;
  }
  expect(rejected, isTrue, reason: reason);
}
