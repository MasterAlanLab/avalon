// Explicit isolated server-file acceptance. Fixtures exist only in the child
// process environment; no account, token, or HTTP body is logged or stored.
import 'dart:convert';
import 'dart:io';

import 'package:av_core/av_core.dart';
import 'package:avalon/cloud/api_client.dart';
import 'package:avalon/cloud/auth_service.dart';
import 'package:avalon/cloud/cloud_models.dart';
import 'package:avalon/cloud/sync_engine.dart';
import 'package:avalon/cloud/sync_lifecycle_models.dart';
import 'package:avalon/data/database/database.dart';
import 'package:avalon/data/repositories/cloud_session_repository.dart';
import 'package:avalon/data/repositories/self_content_repository.dart';
import 'package:avalon/data/repositories/sync_projection.dart';
import 'package:avalon/data/repositories/sync_repository.dart';
import 'package:avalon/data/vault/secret_store.dart';
import 'package:avalon/data/vault/vault.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FileClient {
  _FileClient(this.db, this.api, this.auth, this.sync, this.nodes, this.worker);

  final AppDatabase db;
  final ApiClient api;
  final AuthService auth;
  final SyncRepository sync;
  final SelfContentRepository nodes;
  final SyncEngine worker;

  static Future<_FileClient> open(
    Map<String, Object?> fixture,
    String role,
  ) async {
    final identity = (fixture[role] as Map).cast<String, Object?>();
    final tokens = TokenResponse.fromJson(
      (identity['tokens'] as Map).cast<String, Object?>(),
    );
    final db = AppDatabase(NativeDatabase.memory());
    final secrets = SecretStore(db, await Vault.open(MemoryKeyStore()));
    final sessions = CloudSessionRepository(db, secrets);
    await db
        .into(db.cloudSession)
        .insert(
          CloudSessionCompanion.insert(
            id: const Value(1),
            accountId: '',
            email: '',
            displayName: '',
            deviceId: '',
            installationId: identity['installationId'] as String,
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
        installationId: identity['installationId'] as String,
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        accessExpiresAt: tokens.accessExpiresAt,
        refreshExpiresAt: tokens.refreshExpiresAt,
      ),
    );
    final api = ApiClient(
      baseUri: Uri.parse(fixture['baseUri'] as String),
      transport: HttpClientCloudTransport(),
      allowLoopbackHttp: true,
    );
    final auth = AuthService(
      api: api,
      sessions: sessions,
      deviceName: 'Isolated file-key acceptance',
      os: DeviceOs.android,
    );
    final sync = SyncRepository(db, secrets);
    final projection = SyncProjection(db, secrets, sync);
    return _FileClient(
      db,
      api,
      auth,
      sync,
      SelfContentRepository(db, secrets, onSyncEdit: projection.edited),
      SyncEngine(
        auth: auth,
        repository: sync,
        projection: projection,
        db: db,
        lifecycleEnabled: true,
      ),
    );
  }

  Future<SyncLifecycleStatus> status() async => (await auth.authorizedSync(
    (api, session) => api.syncLifecycle(accessToken: session.accessToken),
  )).value;

  Future<SelfNode> addSentinel(String name) => nodes.addNode(
    SelfNode(
      id: '',
      name: name,
      server: 'file-key.example.test',
      port: 443,
      params: const NodeParams.trojan(
        password: Secret('file-key-synthetic-password'),
      ),
    ),
  );

  Future<void> close() async {
    await worker.dispose();
    api.close();
    await db.close();
  }
}

void main() {
  final raw = Platform.environment['AVALON_CLOUD_SERVER_FILE_LIVE_FIXTURE'];
  test(
    'real server-file deleted cleanup and current-generation sync',
    () async {
      final fixture = (jsonDecode(raw!) as Map).cast<String, Object?>();
      for (final role in ['retired', 'rebuilt', 'active']) {
        final client = await _FileClient.open(fixture, role);
        addTearDown(client.close);
        final account = await client.auth.account();
        final session = (await client.auth.session())!;
        expect(account.account.id == session.accountId, isTrue);
        if (role == 'retired') {
          final sentinel = await client.addSentinel('Retired local sentinel');
          final state = await client.status();
          expect(state.spaceState, 'retired');
          expect(state.cleanup.keyState, 'deleted');
          expect(state.cleanup.onlineState, 'complete');
          expect(state.cleanup.pendingGenerationCount, 0);
          await client.worker.runNow();
          final worker = await client.worker.watch().first;
          expect(worker.blockedReason, 'SYNC_SPACE_RETIRED');
          expect(worker.lifecycle!.cleanup.keyState, 'deleted');
          expect((await client.nodes.nodes()).single.id == sentinel.id, isTrue);
          expect((await client.sync.state(session.accountId)).cursor, 0);
          stdout.writeln('FILEKEY_LIVE_RETIRED_PASS');
        } else if (role == 'rebuilt') {
          final before = await client.status();
          expect(before.spaceState, 'active');
          expect(before.backupState, 'rebuildRequired');
          expect(before.cleanup.keyState, 'deleted');
          expect(
            before.syncGeneration != before.cleanup.latestRetiredGeneration,
            isTrue,
          );
          final sentinel = await client.addSentinel('Rebuilt local sentinel');
          await client.worker.runNow();
          expect(
            (await client.worker.watch().first).blockedReason,
            'SYNC_REBUILD_REQUIRED',
          );
          expect((await client.nodes.nodes()).single.id == sentinel.id, isTrue);
          await client.worker.rebuildFromDevice();
          final after = await client.status();
          expect(after.syncGeneration == before.syncGeneration, isTrue);
          expect(after.backupState, 'ready');
          expect(after.headRevision, 1);
          expect(after.cleanup.keyState, 'deleted');
          expect((await client.worker.watch().first).blockedReason, isNull);
          stdout.writeln('FILEKEY_LIVE_CURRENT_GENERATION_PASS');
        } else {
          final sentinel = await client.addSentinel('Active local sentinel');
          await client.worker.runNow();
          final state = await client.status();
          expect(state.backupState, 'ready');
          expect(state.headRevision, 1);
          expect(state.cleanup.keyState, 'none');
          expect((await client.worker.watch().first).blockedReason, isNull);
          expect(
            (await client.sync.findLocalDocument('node', sentinel.id))!.dirty,
            isFalse,
          );
          final page = (await client.auth.authorizedSync(
            (api, session) => api.pullSyncV2(
              accessToken: session.accessToken,
              syncGeneration: state.syncGeneration!,
              cursor: 0,
            ),
          )).value;
          expect(page.records.length, 1);
          expect(page.records.single.payload!['name'], 'Active local sentinel');
          expect(
            page.records.single.payload!['secrets'],
            containsValue('file-key-synthetic-password'),
          );
          stdout.writeln('FILEKEY_LIVE_UPLOAD_DOWNLOAD_PASS');
          await expectLater(
            client.auth.authorizedSync(
              (api, session) =>
                  api.activateSync(accessToken: session.accessToken),
            ),
            throwsA(
              isA<CloudApiException>()
                  .having((e) => e.httpStatus, 'status', 426)
                  .having(
                    (e) => e.code,
                    'code',
                    CloudErrorCode.schemaUnsupported,
                  ),
            ),
          );
          expect(
            (await client.status()).syncGeneration == state.syncGeneration,
            isTrue,
          );
          stdout.writeln('FILEKEY_LIVE_NO_DOWNGRADE_PASS');
        }
      }
      stdout.writeln('FILEKEY_LIVE_DART_PASS');
    },
    skip: raw == null
        ? 'Requires an owned isolated server-file fixture.'
        : false,
  );
}
