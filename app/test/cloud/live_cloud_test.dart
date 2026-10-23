// Opt-in integration against the real Go/PostgreSQL loopback sandbox.
// Run with AVALON_CLOUD_BASE_URL and AVALON_CLOUD_MAILBOX_DIR. No server,
// account, mailbox or credentials are synthesized by this test.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:av_core/av_core.dart';
import 'package:avalon/cloud/api_client.dart';
import 'package:avalon/cloud/auth_service.dart';
import 'package:avalon/cloud/cloud_models.dart';
import 'package:avalon/data/database/database.dart';
import 'package:avalon/data/repositories/cloud_session_repository.dart';
import 'package:avalon/data/repositories/configuration_repository.dart';
import 'package:avalon/data/vault/secret_store.dart';
import 'package:avalon/data/vault/vault.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

final _uuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

void main() {
  final configuredBase = Platform.environment['AVALON_CLOUD_BASE_URL'];
  final configuredMailbox = Platform.environment['AVALON_CLOUD_MAILBOX_DIR'];
  final unconfigured = configuredBase == null && configuredMailbox == null;

  test(
    'real Cloud sandbox: seven operations, rotation, isolation, encrypted local state',
    () async {
      final baseUri = _sandboxBase(configuredBase);
      final mailbox = Directory(configuredMailbox ?? '');
      if (configuredMailbox == null || !await mailbox.exists()) {
        throw StateError('Configure an existing sandbox mailbox directory.');
      }
      final api = ApiClient(
        baseUri: baseUri,
        allowLoopbackHttp: true,
        timeout: const Duration(seconds: 5),
      );
      final clients = <_LocalClient>[];
      final cleanups = <_AccountCleanup>[];
      addTearDown(() async {
        var failed = false;
        for (final cleanup in cleanups.reversed) {
          if (cleanup.deleted) continue;
          try {
            await cleanup.delete(api, mailbox);
          } on Object {
            failed = true;
          }
        }
        api.close();
        for (final client in clients.reversed) {
          await client.db.close();
        }
        if (failed) {
          throw StateError(
            'Sandbox cleanup failed; a temporary test account may remain.',
          );
        }
      });

      Future<_LocalClient> client() async {
        final result = await _LocalClient.open(api);
        clients.add(result);
        return result;
      }

      final primary = await client();
      final otherDevice = await client();
      final foreign = await client();
      final accountA = _AccountCleanup(_temporaryEmail(), primary);
      final accountB = _AccountCleanup(_temporaryEmail(), foreign);
      cleanups.addAll([accountA, accountB]);

      // 1. Start and verify against the real mailbox. A code remains a String
      // throughout, including any leading zero; it is never parsed as an int.
      final first = await _login(primary, accountA, mailbox);
      final stored = await primary.sessions.read();
      expect(stored != null, isTrue);
      expect(stored!.accessToken == first.accessToken, isTrue);
      expect(stored.refreshToken == first.refreshToken, isTrue);
      expect(stored.accessExpiresAt.isUtc, isTrue);
      expect(stored.refreshExpiresAt.isUtc, isTrue);
      await _noPlaintextTokens(primary, first);

      // 2. Free accounts log in without activating paid synchronization.
      final free = await primary.auth.account();
      expect(free.entitlement, isNull);
      expect(free.syncActiveDeviceCount, 0);
      expect(free.deviceLimit, 10);
      expect(free.devices.length, 1);
      expect(free.devices.single.syncActive, isFalse);
      expect(free.account.email == accountA.email, isTrue);

      // 3. A second login on the same installation adds a session, not a device.
      final second = await _login(primary, accountA, mailbox);
      expect(second.accountId == first.accountId, isTrue);
      expect(second.deviceId == first.deviceId, isTrue);
      expect(second.sessionId != first.sessionId, isTrue);
      expect((await primary.auth.account()).devices.length, 1);

      // 4. Add another physical installation plus an unrelated account.
      final target = await _login(otherDevice, accountA, mailbox);
      final outsider = await _login(foreign, accountB, mailbox);
      expect(target.accountId == second.accountId, isTrue);
      expect(target.deviceId != second.deviceId, isTrue);
      expect(outsider.accountId != second.accountId, isTrue);
      final devices = await primary.auth.account();
      expect(devices.devices.length, 2);
      expect(devices.syncActiveDeviceCount, 0);

      // 5. A historical refresh proof may revoke only its original session,
      // even after rotation. Repeating that proof is an idempotent 204.
      final rotatedFirst = await api.refresh(refreshToken: first.refreshToken);
      expect(rotatedFirst.sessionId == first.sessionId, isTrue);
      expect(rotatedFirst.refreshToken != first.refreshToken, isTrue);
      await api.logout(refreshToken: first.refreshToken);
      await api.logout(refreshToken: first.refreshToken);
      await _apiFailure(
        api.getAccount(accessToken: rotatedFirst.accessToken),
        status: 401,
        code: CloudErrorCode.sessionRevoked,
      );
      await _apiFailure(
        api.logout(
          accessToken: second.accessToken,
          refreshToken: rotatedFirst.refreshToken,
        ),
        status: 400,
        code: CloudErrorCode.validation,
      );
      // A conflict must not revoke the unrelated Bearer session.
      expect(
        (await primary.auth.account()).account.id == second.accountId,
        isTrue,
      );

      // 6. Exercise AuthService's actual refresh and atomic encrypted replace.
      // Moving only the client's clock forces renewal without waiting 15 min.
      final renew = primary.authWithClock(
        () => second.accessExpiresAt.add(const Duration(seconds: 1)),
      );
      await renew.account();
      final rotatedSecond = await primary.sessions.read();
      expect(rotatedSecond != null, isTrue);
      expect(rotatedSecond!.sessionId == second.sessionId, isTrue);
      expect(rotatedSecond.deviceId == second.deviceId, isTrue);
      expect(rotatedSecond.refreshToken != second.refreshToken, isTrue);
      expect(rotatedSecond.refreshUncertain, isFalse);
      accountA.sessions.add(rotatedSecond);
      await _noPlaintextTokens(primary, rotatedSecond);

      // Replaying the consumed token revokes the whole session. Its new JWT
      // must stop working, and AuthService clears only that active session.
      await _apiFailure(
        api.refresh(refreshToken: second.refreshToken),
        status: 401,
        code: CloudErrorCode.sessionRevoked,
      );
      await _apiFailure(
        primary.auth.account(),
        status: 401,
        code: CloudErrorCode.sessionRevoked,
      );
      expect(await primary.sessions.read(), isNull);

      // 7. Relogin to remove the other installation. Unknown/cross-account IDs
      // return 404; trying to remove the current device returns 400.
      final active = await _login(primary, accountA, mailbox);
      await _apiFailure(
        api.removeDevice(
          accessToken: active.accessToken,
          deviceId: '00000000-0000-4000-8000-000000000000',
        ),
        status: 404,
        code: CloudErrorCode.notFound,
      );
      await _apiFailure(
        primary.auth.removeDevice(outsider.deviceId),
        status: 404,
        code: CloudErrorCode.notFound,
      );
      await _apiFailure(
        api.removeDevice(
          accessToken: active.accessToken,
          deviceId: active.deviceId,
        ),
        status: 400,
        code: CloudErrorCode.validation,
      );
      await primary.auth.removeDevice(target.deviceId);
      await _apiFailure(
        otherDevice.auth.account(),
        status: 401,
        code: CloudErrorCode.sessionRevoked,
      );
      expect(await otherDevice.sessions.read(), isNull);
      expect((await primary.auth.account()).devices.length, 1);

      // 8. Seed actual encrypted local proxy/subscription credentials. Online
      // logout clears active Cloud tokens, acknowledges its queue and keeps
      // local content. The same data also survives subsequent account delete.
      final configurations = ConfigurationRepository(
        primary.db,
        primary.secrets,
      );
      final localId = await configurations.add(
        kind: ConfigurationKind.subscription,
        name: 'Sandbox local subscription',
        parsed: parseContent(
          'trojan://sandbox-local-password@proxy.example.invalid:443#Local',
        ),
        digest: 'sandbox-local-content',
        source: const SubscriptionSource(
          url: Secret(
            'https://subscription.example.invalid/?token=sandbox-local',
          ),
        ),
      );
      await (primary.db.update(
        primary.db.configurations,
      )..where((row) => row.id.equals(localId))).write(
        ConfigurationsCompanion(cloudAccountId: Value(active.accountId)),
      );
      final localSecretCount =
          (await primary.db.select(primary.db.secrets).get()).length - 2;
      await primary.auth.logout();
      expect(await primary.sessions.read(), isNull);
      expect(await primary.sessions.pendingRevocations(), isEmpty);
      expect((await configurations.content(localId)) != null, isTrue);
      expect(
        (await primary.db.select(primary.db.secrets).get()).length,
        localSecretCount,
      );
      await _apiFailure(
        api.getAccount(accessToken: active.accessToken),
        status: 401,
        code: CloudErrorCode.sessionRevoked,
      );

      // This is the fifth and final email challenge for account A, below the
      // documented 5/hour sandbox limit. Deletion also revokes every session.
      final deleting = await _login(primary, accountA, mailbox);
      final deleted = await primary.auth.deleteAccount();
      accountA.deleted = true;
      expect(deleted.cancelSubscription.required, isFalse);
      expect(deleted.cancelSubscription.sources, isEmpty);
      expect(await primary.sessions.read(), isNull);
      expect((await configurations.get(localId)) != null, isTrue);
      expect(
        (await configurations.content(localId))!.digest ==
            'sandbox-local-content',
        isTrue,
      );
      expect(
        (await configurations.source(localId))!.url.value ==
            'https://subscription.example.invalid/?token=sandbox-local',
        isTrue,
      );
      final local = await (primary.db.select(
        primary.db.configurations,
      )..where((row) => row.id.equals(localId))).getSingle();
      expect(local.cloudAccountId, isNull);
      expect(
        (await primary.db.select(primary.db.secrets).get()).length,
        localSecretCount,
      );
      await _apiFailure(
        api.getAccount(accessToken: deleting.accessToken),
        status: 401,
      );
      // No unrelated account was changed by A's isolation/removal/deletion.
      expect(
        (await foreign.auth.account()).account.id == outsider.accountId,
        isTrue,
      );
      await foreign.auth.deleteAccount();
      accountB.deleted = true;
    },
    skip: unconfigured
        ? 'Set AVALON_CLOUD_BASE_URL and AVALON_CLOUD_MAILBOX_DIR for the real loopback sandbox.'
        : false,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

Uri _sandboxBase(String? configured) {
  try {
    if (configured == null) throw const FormatException();
    final uri = Uri.parse(configured);
    if (uri.scheme != 'http' ||
        !['127.0.0.1', '::1', 'localhost'].contains(uri.host) ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/')) {
      throw const FormatException();
    }
    return uri;
  } on Object {
    throw StateError(
      'Live Cloud tests require an explicit loopback sandbox URL.',
    );
  }
}

String _temporaryEmail() {
  final random = Random.secure();
  final nonce = List.generate(
    12,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
  return 'avalon-live-${DateTime.now().microsecondsSinceEpoch}-$nonce@sandbox.invalid';
}

Future<StoredCloudSession> _login(
  _LocalClient client,
  _AccountCleanup account,
  Directory mailbox,
) async {
  final challenge = await client.auth.startEmail(account.email);
  final code = await _mailCode(mailbox, challenge.challengeId);
  account.verificationAttempted = true;
  final session = await client.auth.verifyEmail(
    challengeId: challenge.challengeId,
    code: code,
  );
  account.sessions.add(session);
  return session;
}

Future<String> _mailCode(Directory mailbox, String challengeId) async {
  if (!_uuid.hasMatch(challengeId)) {
    throw StateError('The sandbox returned an invalid challenge identifier.');
  }
  final file = File(
    '${mailbox.path}${Platform.pathSeparator}$challengeId.json',
  );
  final watch = Stopwatch()..start();
  while (watch.elapsed < const Duration(seconds: 5)) {
    try {
      if (await FileSystemEntity.isLink(file.path)) {
        throw StateError('Sandbox mailbox entries must be regular files.');
      }
      if (await file.exists()) {
        if ((await file.stat()).size > 64 * 1024) {
          throw StateError('Sandbox mailbox entry exceeds its byte limit.');
        }
        final decoded = jsonDecode(await file.readAsString());
        final code = decoded is Map<String, Object?> ? decoded['code'] : null;
        if (code is! String || !RegExp(r'^[0-9]{6}$').hasMatch(code)) {
          throw StateError('Sandbox mailbox entry has an invalid code format.');
        }
        return code;
      }
    } on FileSystemException {
      throw StateError('The sandbox mailbox could not be read.');
    } on FormatException {
      // JSON/UTF-8 exceptions may include the mailbox contents and its code.
      throw StateError('The sandbox mailbox returned invalid JSON.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  throw StateError('No sandbox mail arrived within five seconds.');
}

Future<void> _apiFailure(
  Future<Object?> pending, {
  required int status,
  CloudErrorCode? code,
}) async {
  try {
    await pending;
  } on CloudApiException catch (error) {
    expect(error.httpStatus, status);
    if (code != null) expect(error.code == code, isTrue);
    return;
  }
  fail('The sandbox did not return the expected API rejection.');
}

Future<void> _noPlaintextTokens(
  _LocalClient client,
  StoredCloudSession session,
) async {
  for (final table in client.db.allTables) {
    for (final row
        in await client.db
            .customSelect('SELECT * FROM ${table.actualTableName}')
            .get()) {
      final raw = row.data.values.join('|');
      expect(raw.contains(session.accessToken), isFalse);
      expect(raw.contains(session.refreshToken), isFalse);
    }
  }
}

final class _LocalClient {
  _LocalClient(this.api, this.db, this.secrets, this.sessions);

  static Future<_LocalClient> open(ApiClient api) async {
    final db = AppDatabase(NativeDatabase.memory());
    try {
      final secrets = SecretStore(db, await Vault.open(MemoryKeyStore()));
      return _LocalClient(
        api,
        db,
        secrets,
        CloudSessionRepository(db, secrets),
      );
    } on Object {
      await db.close();
      rethrow;
    }
  }

  final ApiClient api;
  final AppDatabase db;
  final SecretStore secrets;
  final CloudSessionRepository sessions;
  late final auth = authWithClock(null);

  AuthService authWithClock(DateTime Function()? clock) => AuthService(
    api: api,
    sessions: sessions,
    deviceName: 'Real sandbox integration device',
    os: DeviceOs.macos,
    clock: clock,
  );
}

final class _AccountCleanup {
  _AccountCleanup(this.email, this.client);

  final String email;
  final _LocalClient client;
  final sessions = <StoredCloudSession>[];
  bool verificationAttempted = false;
  bool deleted = false;

  Future<void> delete(ApiClient api, Directory mailbox) async {
    // Try acquired sessions first: a failing assertion should not need to send
    // another email. A fresh login is used only if all sessions were revoked.
    for (final session in sessions.reversed) {
      try {
        await api.deleteAccount(accessToken: session.accessToken);
        deleted = true;
        return;
      } on CloudApiException catch (error) {
        if (error.httpStatus != 401) rethrow;
      }
    }
    // A verification response could have been lost after creating the account;
    // only a start request with no verification attempt needs no cleanup login.
    if (!verificationAttempted) return;
    final session = await _login(client, this, mailbox);
    await api.deleteAccount(accessToken: session.accessToken);
    deleted = true;
  }
}
