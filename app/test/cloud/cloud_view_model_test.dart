// Real AuthService, loopback HTTP and encrypted Drift storage; no production
// endpoint or credentials. Expectations never print codes or tokens.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avalon/app/providers.dart';
import 'package:avalon/cloud/api_client.dart';
import 'package:avalon/cloud/auth_service.dart';
import 'package:avalon/cloud/cloud_models.dart';
import 'package:avalon/cloud/cloud_revocation_retry.dart';
import 'package:avalon/cloud/sync_engine.dart';
import 'package:avalon/data/database/database.dart';
import 'package:avalon/data/repositories/cloud_session_repository.dart';
import 'package:avalon/data/repositories/sync_projection.dart';
import 'package:avalon/data/repositories/sync_repository.dart';
import 'package:avalon/data/vault/secret_store.dart';
import 'package:avalon/data/vault/vault.dart';
import 'package:avalon/features/cloud/cloud_state.dart';
import 'package:avalon/features/cloud/cloud_view_model.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime.now().toUtc();

Map<String, Object?> _tokens(String account, {int generation = 1}) => {
  'accountId': account,
  'deviceId': 'device-$account',
  'sessionId': 'session-$account-$generation',
  'accessToken': 'isolated-access-$account-$generation',
  'accessExpiresAt': _now.add(const Duration(minutes: 15)).toIso8601String(),
  'refreshToken': 'isolated-refresh-$account-$generation',
  'refreshExpiresAt': _now.add(const Duration(days: 90)).toIso8601String(),
};

Map<String, Object?> _account(String account, {bool otherDevice = false}) => {
  'account': {
    'id': account,
    'email': '$account@example.invalid',
    'displayName': 'Isolated profile',
  },
  'entitlement': null,
  'devices': [
    {
      'id': 'device-$account',
      'name': 'This test device',
      'os': 'macos',
      'syncActive': false,
      'lastSeenAt': _now.toIso8601String(),
    },
    if (otherDevice)
      {
        'id': 'other-$account',
        'name': 'Other test device',
        'os': 'android',
        'syncActive': false,
        'lastSeenAt': _now.toIso8601String(),
      },
  ],
  'currentDeviceId': 'device-$account',
  'deviceLimit': 10,
  'syncActiveDeviceCount': 0,
};

Future<void> _json(
  HttpRequest request,
  Map<String, Object?> body, {
  int status = HttpStatus.ok,
}) async {
  request.response.statusCode = status;
  request.response.headers.contentType = ContentType.json;
  request.response.write(jsonEncode(body));
  await request.response.close();
}

Future<void> _error(
  HttpRequest request,
  String code, {
  int status = HttpStatus.badRequest,
  String? reason,
}) => _json(request, {
  'error': {
    'code': code,
    'message': 'private diagnostic value must never enter UI state',
    'reason': ?reason,
  },
}, status: status);

Future<void> _until(bool Function() condition) async {
  final timeout = DateTime.now().add(const Duration(seconds: 3));
  while (!condition()) {
    if (DateTime.now().isAfter(timeout)) {
      fail('Safe Cloud state did not reach the expected condition.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  late AppDatabase db;
  late SecretStore secrets;
  late CloudSessionRepository sessions;
  late HttpServer server;
  late ApiClient api;
  late AuthService auth;
  late Future<void> Function(HttpRequest) handler;
  ProviderContainer? container;
  CloudRevocationRetryController? retry;
  SyncEngine? sync;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    secrets = SecretStore(db, await Vault.open(MemoryKeyStore()));
    sessions = CloudSessionRepository(db, secrets);
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    handler = (request) async {
      if (request.method == 'GET' && request.uri.path == '/v1/account') {
        await _json(request, _account('a'));
      } else if (request.uri.path == '/v1/auth/email/start') {
        await request.drain<void>();
        await _json(request, {
          'challengeId': 'isolated-challenge',
          'expiresAt': _now.add(const Duration(minutes: 10)).toIso8601String(),
        });
      } else if (request.uri.path == '/v1/auth/email/verify') {
        await request.drain<void>();
        await _json(request, _tokens('a'));
      } else if (request.uri.path == '/v1/auth/logout') {
        await request.drain<void>();
        request.response.statusCode = HttpStatus.noContent;
        await request.response.close();
      } else {
        await _error(request, 'NOT_FOUND', status: HttpStatus.notFound);
      }
    };
    server.listen((request) async => handler(request));
    api = ApiClient(
      baseUri: Uri.parse('http://127.0.0.1:${server.port}'),
      allowLoopbackHttp: true,
      timeout: const Duration(milliseconds: 300),
    );
    auth = AuthService(
      api: api,
      sessions: sessions,
      deviceName: 'Isolated model device',
      os: DeviceOs.macos,
      clock: () => _now,
    );
  });

  tearDown(() async {
    container?.dispose();
    container = null;
    retry?.dispose();
    retry = null;
    await sync?.dispose();
    sync = null;
    api.close();
    await server.close(force: true);
    await db.close();
  });

  Future<void> seed(
    String account, {
    int generation = 1,
    bool uncertain = false,
  }) async {
    final tokens = TokenResponse.fromJson(
      _tokens(account, generation: generation),
    );
    await sessions.save(
      StoredCloudSession(
        accountId: tokens.accountId,
        deviceId: tokens.deviceId,
        sessionId: tokens.sessionId,
        installationId: await sessions.installationId(),
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        accessExpiresAt: tokens.accessExpiresAt,
        refreshExpiresAt: tokens.refreshExpiresAt,
        email: '$account@example.invalid',
        displayName: 'Cached profile',
        refreshUncertain: uncertain,
      ),
    );
  }

  CloudViewModel mount({bool enabled = true}) {
    container = ProviderContainer(
      overrides: [
        cloudAuthServiceProvider.overrideWithValue(enabled ? auth : null),
        cloudSessionRepositoryProvider.overrideWithValue(sessions),
        cloudRevocationRetryProvider.overrideWithValue(retry),
        cloudSyncEngineProvider.overrideWithValue(sync),
      ],
    );
    return container!.read(cloudViewModelProvider.notifier);
  }

  CloudState state() => container!.read(cloudViewModelProvider);

  test(
    'real sync status reaches only the signed-in account and clears on logout',
    () async {
      await seed('a');
      final repository = SyncRepository(db, secrets);
      sync = SyncEngine(
        auth: auth,
        repository: repository,
        projection: SyncProjection(db, secrets, repository),
        db: db,
      );
      var activations = 0;
      handler = (request) async {
        if (request.uri.path == '/v1/account') {
          final current = await sessions.read();
          await _json(request, _account(current!.accountId));
        } else if (request.uri.path == '/v1/sync/activate') {
          activations++;
          request.response.headers.set('Cache-Control', 'no-store');
          await _error(
            request,
            'NO_ENTITLEMENT',
            status: HttpStatus.paymentRequired,
          );
        } else {
          expect(request.uri.path, '/v1/auth/logout');
          await request.drain<void>();
          request.response.statusCode = HttpStatus.noContent;
          await request.response.close();
        }
      };
      final model = mount();
      await model.initialize();
      expect(state().syncAvailable, isTrue);
      await model.syncNow();
      await _until(() => state().syncBlockedReason == 'NO_ENTITLEMENT');
      expect(state().syncing, isFalse);
      expect(state().lastSyncAt, isNull);
      expect(activations, 1);
      await model.logout();
      await _until(() => !state().signedIn);
      expect(state().syncBlockedReason, isNull);
      await seed('b');
      await model.refreshAccount();
      expect(state().account!.account.id, 'b');
      expect(state().syncBlockedReason, isNull);
      expect(state().syncing, isFalse);
    },
  );

  test('disabled development Cloud does not restore or send HTTP', () async {
    var requests = 0;
    handler = (request) async {
      ++requests;
      await _error(request, 'INTERNAL_ERROR');
    };
    final model = mount(enabled: false);
    await model.initialize();
    await model.sendEmail('a@example.invalid');
    expect(state().enabled, isFalse);
    expect(state().initialized, isTrue);
    expect(state().error, CloudUiError.disabled);
    expect(requests, 0);
  });

  test(
    'failed account restoration preserves cached signed-in profile',
    () async {
      await seed('a');
      handler = (request) async {
        (await request.response.detachSocket()).destroy();
      };
      await mount().initialize();
      expect(state().signedIn, isTrue);
      expect(state().email == 'a@example.invalid', isTrue);
      expect(state().account, isNull);
      expect(state().error, CloudUiError.offline);
    },
  );

  test('uncertain persisted refresh requires login without replay', () async {
    await seed('a', uncertain: true);
    var requests = 0;
    handler = (request) async {
      ++requests;
      await _error(request, 'INTERNAL_ERROR');
    };
    await mount().initialize();
    expect(requests, 0);
    expect(state().signedIn, isFalse);
    expect(state().requiresReauthentication, isTrue);
    expect(state().error, CloudUiError.reauthenticationRequired);
    expect((await sessions.read()) != null, isTrue);
  });

  test(
    'logout clears local UI before remote response and rejects late account',
    () async {
      await seed('a');
      final model = mount();
      await model.initialize();
      final generation = state().sessionGeneration;
      final accountEntered = Completer<void>();
      final logoutEntered = Completer<void>();
      final releaseAccount = Completer<void>();
      final releaseLogout = Completer<void>();
      handler = (request) async {
        if (request.uri.path == '/v1/account') {
          accountEntered.complete();
          await releaseAccount.future;
          await _json(request, _account('a'));
        } else {
          await request.drain<void>();
          logoutEntered.complete();
          await releaseLogout.future;
          request.response.statusCode = HttpStatus.noContent;
          await request.response.close();
        }
      };
      final account = model.refreshAccount();
      await accountEntered.future;
      final logout = model.logout();
      await logoutEntered.future;
      await _until(() => !state().signedIn);
      expect(state().account, isNull);
      expect(state().sessionGeneration, greaterThan(generation));
      releaseLogout.complete();
      await logout;
      releaseAccount.complete();
      await account;
      expect(state().signedIn, isFalse);
      expect(state().account, isNull);
      expect(state().error, isNull);
    },
  );

  test(
    'offline logout starts automatic new-queue retries without resume',
    () async {
      await seed('a');
      var online = false;
      var proofOnly = true;
      var attempts = 0;
      final standard = handler;
      handler = (request) async {
        if (request.uri.path != '/v1/auth/logout') {
          await standard(request);
          return;
        }
        ++attempts;
        proofOnly =
            proofOnly &&
            request.headers.value(HttpHeaders.authorizationHeader) == null;
        await request.drain<void>();
        if (!online) {
          (await request.response.detachSocket()).destroy();
        } else {
          request.response.statusCode = HttpStatus.noContent;
          await request.response.close();
        }
      };
      retry = CloudRevocationRetryController(
        readPendingCount: () async =>
            (await sessions.pendingRevocations()).length,
        retryPendingRevocations: auth.retryPendingRevocations,
        initialRetryDelay: const Duration(milliseconds: 25),
        maxRetryDelay: const Duration(milliseconds: 100),
      );
      retry!.resume();
      await retry!.idle;
      final model = mount();
      await model.initialize();
      await model.logout();
      expect(state().signedIn, isFalse);
      expect(state().pendingRevocationCount, 1);
      expect(state().error, CloudUiError.revocationPending);
      online = true;
      await _until(() => state().pendingRevocationCount == 0);
      expect((await sessions.pendingRevocations()).isEmpty, isTrue);
      expect(state().error, isNull);
      expect(attempts, greaterThanOrEqualTo(2));
      expect(proofOnly, isTrue);
    },
  );

  test(
    'delete timeout is unconfirmed and never reported as deletion success',
    () async {
      await seed('a');
      final model = mount();
      await model.initialize();
      handler = (request) async {
        await request.drain<void>();
        (await request.response.detachSocket()).destroy();
      };
      await model.deleteAccount();
      expect(state().accountDeleted, isFalse);
      expect(state().deletionNotice, isNull);
      expect(state().error, CloudUiError.deleteUnconfirmed);
      expect(state().signedIn, isTrue);
      expect((await sessions.read()) != null, isTrue);
    },
  );

  test('same-account new session changes confirmation generation', () async {
    await seed('a');
    final model = mount();
    await model.initialize();
    final first = state().sessionGeneration;
    await seed('a', generation: 2);
    await _until(() => state().sessionGeneration > first);
    expect(state().signedIn, isTrue);
    expect(state().account, isNull);
  });

  test('a late verification after logout cannot reopen Cloud UI', () async {
    final model = mount();
    await model.initialize();
    await model.sendEmail('a@example.invalid');
    handler = (request) async {
      await request.drain<void>();
      request.response.headers.set(HttpHeaders.retryAfterHeader, '60');
      await _error(request, 'RATE_LIMITED', status: HttpStatus.tooManyRequests);
    };
    await model.sendEmail('a@example.invalid');
    expect(state().challengeId, isNotNull);
    expect(state().challengeEmail, 'a@example.invalid');
    expect(state().challengeExpiresAt, isNotNull);
    expect(state().resendAvailableAt, isNotNull);
    final entered = Completer<void>();
    final release = Completer<void>();
    var discardedProofs = 0;
    handler = (request) async {
      await request.drain<void>();
      if (request.uri.path == '/v1/auth/email/verify') {
        entered.complete();
        await release.future;
        await _json(request, _tokens('a'));
      } else {
        ++discardedProofs;
        request.response.statusCode = HttpStatus.noContent;
        await request.response.close();
      }
    };
    final verification = model.verify('123456');
    await entered.future;
    final logout = model.logout();
    expect(state().challengeId, isNull);
    expect(state().challengeEmail, isNull);
    expect(state().challengeExpiresAt, isNull);
    expect(state().resendAvailableAt, isNull);
    expect(state().retryAfterSeconds, isNull);
    await logout;
    release.complete();
    await verification;
    expect(state().signedIn, isFalse);
    expect((await sessions.read()) == null, isTrue);
    expect(discardedProofs, 1);
  });
}
