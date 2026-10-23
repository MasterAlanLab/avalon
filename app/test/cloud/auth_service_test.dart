// Real Dart HTTP and encrypted Drift storage, isolated to the loopback server
// and in-memory database. No production endpoint or credentials are used.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:av_core/av_core.dart';
import 'package:avalon/cloud/api_client.dart';
import 'package:avalon/cloud/auth_service.dart';
import 'package:avalon/cloud/cloud_models.dart';
import 'package:avalon/cloud/cloud_revocation_retry.dart';
import 'package:avalon/data/database/database.dart';
import 'package:avalon/data/repositories/cloud_session_repository.dart';
import 'package:avalon/data/repositories/configuration_repository.dart';
import 'package:avalon/data/vault/secret_store.dart';
import 'package:avalon/data/vault/vault.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

final _now = DateTime.utc(2026, 10, 11, 9);

Map<String, Object?> _tokens(
  String account, {
  int generation = 1,
  bool expiredAccess = false,
}) => {
  'accountId': account,
  'deviceId': 'device-$account',
  'sessionId': 'session-$account',
  'accessToken': 'test-access-$account-$generation',
  'accessExpiresAt': _now
      .add(Duration(minutes: expiredAccess ? -1 : 15))
      .toIso8601String(),
  'refreshToken': 'test-refresh-$account-$generation',
  'refreshExpiresAt': _now.add(const Duration(days: 90)).toIso8601String(),
};

Map<String, Object?> _account(String account) => {
  'account': {
    'id': account,
    'email': '$account@example.invalid',
    'displayName': 'Loopback account',
  },
  'entitlement': null,
  'devices': [
    {
      'id': 'device-$account',
      'name': 'Loopback device',
      'os': 'macos',
      'syncActive': false,
      'lastSeenAt': _now.toIso8601String(),
    },
  ],
  'currentDeviceId': 'device-$account',
  'deviceLimit': 10,
  'syncActiveDeviceCount': 0,
};

Future<Map<String, Object?>> _body(HttpRequest request) async =>
    (jsonDecode(await utf8.decoder.bind(request).join()) as Map)
        .cast<String, Object?>();

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

Future<void> _revoked(HttpRequest request) => _json(request, {
  'error': {'code': 'SESSION_REVOKED', 'message': 'Session revoked.'},
}, status: HttpStatus.unauthorized);

void main() {
  late HttpServer server;
  late ApiClient api;
  late AppDatabase db;
  late SecretStore secrets;
  late CloudSessionRepository sessions;
  late AuthService auth;
  late Future<void> Function(HttpRequest) handle;

  AuthService newAuth() => AuthService(
    api: api,
    sessions: sessions,
    deviceName: 'Loopback device',
    os: DeviceOs.macos,
    clock: () => _now,
  );

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    secrets = SecretStore(db, await Vault.open(MemoryKeyStore()));
    sessions = CloudSessionRepository(db, secrets);
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    handle = (request) async {
      await _json(request, {
        'error': {'code': 'VALIDATION', 'message': 'Unexpected test route.'},
      }, status: HttpStatus.notFound);
      fail('Unexpected ${request.method} ${request.uri.path}');
    };
    server.listen((request) async => handle(request));
    api = ApiClient(
      baseUri: Uri.parse('http://127.0.0.1:${server.port}'),
      allowLoopbackHttp: true,
      timeout: const Duration(seconds: 2),
    );
    auth = newAuth();
  });

  tearDown(() async {
    api.close();
    await server.close(force: true);
    await db.close();
  });

  Future<void> seed(String account, {bool expiredAccess = false}) async {
    final tokens = TokenResponse.fromJson(
      _tokens(account, expiredAccess: expiredAccess),
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
      ),
    );
  }

  test('email login persists credentials only in encrypted entries', () async {
    String? receivedInstallation;
    handle = (request) async {
      if (request.uri.path == '/v1/auth/email/start') {
        expect((await _body(request))['email'] == 'a@example.invalid', isTrue);
        await _json(request, {
          'challengeId': 'loopback-challenge',
          'expiresAt': _now.add(const Duration(minutes: 10)).toIso8601String(),
        });
      } else if (request.uri.path == '/v1/auth/email/verify') {
        final body = await _body(request);
        expect(body['challengeId'], 'loopback-challenge');
        // A boolean expectation prevents credential values entering failures.
        expect(body['code'] == '000123', isTrue);
        final device = (body['device'] as Map).cast<String, Object?>();
        receivedInstallation = device['installationId'] as String;
        expect(device['os'], 'macos');
        expect(device['name'], 'Loopback device');
        await _json(request, _tokens('a'));
      } else {
        fail('Unexpected login route ${request.uri.path}');
      }
    };

    final challenge = await auth.startEmail('a@example.invalid');
    expect(challenge.expiresAt, _now.add(const Duration(minutes: 10)));
    final loggedIn = await auth.verifyEmail(
      challengeId: challenge.challengeId,
      code: '000123',
    );
    final restored = await sessions.read();
    expect(restored!.accountId, 'a');
    expect(restored.installationId, receivedInstallation);
    expect(restored.accessToken == loggedIn.accessToken, isTrue);
    expect(restored.refreshToken == loggedIn.refreshToken, isTrue);
    expect(restored.refreshUncertain, isFalse);
    expect((await db.select(db.secrets).get()).length, 2);

    final dump = StringBuffer();
    for (final table in db.allTables) {
      for (final row
          in await db
              .customSelect('SELECT * FROM ${table.actualTableName}')
              .get()) {
        dump.write(row.data.values.join('|'));
      }
    }
    expect(dump.toString().contains(loggedIn.accessToken), isFalse);
    expect(dump.toString().contains(loggedIn.refreshToken), isFalse);
  });

  test(
    'authorized sync captures refreshed identity and cancellation generation',
    () async {
      await seed('a', expiredAccess: true);
      handle = (request) async {
        if (request.uri.path == '/v1/auth/refresh') {
          await request.drain<void>();
          await _json(request, _tokens('a', generation: 2));
        } else {
          expect(request.uri.path, '/v1/account');
          expect(
            request.headers.value('Authorization') ==
                'Bearer ${_tokens('a', generation: 2)['accessToken']}',
            isTrue,
          );
          await _json(request, _account('a'));
        }
      };
      final generation = auth.generation;
      final result = await auth.authorizedSync(
        (api, session) => api.getAccount(accessToken: session.accessToken),
      );
      expect(result.accountId, 'a');
      expect(result.deviceId, 'device-a');
      expect(result.sessionId, 'session-a');
      expect(result.generation, generation);
      expect(result.value.account.id, 'a');
    },
  );

  test('authorized sync rejects a late result after local logout', () async {
    await seed('a');
    final entered = Completer<void>();
    final release = Completer<void>();
    handle = (request) async {
      if (request.uri.path == '/v1/account') {
        entered.complete();
        await release.future;
        await _json(request, _account('a'));
      } else {
        expect(request.uri.path, '/v1/auth/logout');
        await request.drain<void>();
        request.response.statusCode = HttpStatus.noContent;
        await request.response.close();
      }
    };
    final oldGeneration = auth.generation;
    final result = auth.authorizedSync(
      (api, session) => api.getAccount(accessToken: session.accessToken),
    );
    final rejected = expectLater(
      result,
      throwsA(isA<CloudSessionChangedException>()),
    );
    await entered.future.timeout(const Duration(seconds: 1));
    await auth.logout();
    release.complete();
    await rejected;
    expect(auth.generation, greaterThan(oldGeneration));
    expect(await sessions.read(), isNull);
  });

  test(
    'account switch commits old logout proof before contacting login',
    () async {
      await seed('a');
      handle = (request) async {
        expect(request.uri.path, '/v1/auth/email/verify');
        expect(await sessions.read(), isNull);
        final proofs = await sessions.pendingRevocations();
        expect(proofs.single.sessionId, 'session-a');
        expect(
          proofs.single.refreshToken == _tokens('a')['refreshToken'],
          isTrue,
        );
        await request.drain<void>();
        await _json(request, _tokens('b'));
      };
      await auth.verifyEmail(challengeId: 'new-challenge', code: '000123');
      expect((await sessions.read())!.accountId, 'b');
      expect(
        (await sessions.pendingRevocations()).single.sessionId,
        'session-a',
      );
    },
  );

  test('expired access joins one refresh even after dispatch', () async {
    await seed('a', expiredAccess: true);
    final entered = Completer<void>();
    final release = Completer<void>();
    var refreshes = 0;
    var accountReads = 0;
    handle = (request) async {
      if (request.uri.path == '/v1/auth/refresh') {
        ++refreshes;
        expect(
          (await _body(request))['refreshToken'] ==
              _tokens('a')['refreshToken'],
          isTrue,
        );
        if (!entered.isCompleted) entered.complete();
        await release.future;
        await _json(request, _tokens('a', generation: 2));
      } else {
        expect(request.uri.path, '/v1/account');
        ++accountReads;
        expect(
          request.headers.value(HttpHeaders.authorizationHeader) ==
              'Bearer ${_tokens('a', generation: 2)['accessToken']}',
          isTrue,
        );
        await _json(request, _account('a'));
      }
    };

    final first = auth.account();
    final firstResult = expectLater(first, completes);
    await entered.future.timeout(const Duration(seconds: 1));
    final second = auth.account();
    final secondResult = expectLater(second, completes);
    // If a second refresh begins it will enter before the first is released.
    await Future<void>.delayed(const Duration(milliseconds: 30));
    release.complete();
    await Future.wait([firstResult, secondResult]);
    expect(refreshes, 1);
    expect(accountReads, 2);
    final rotated = await sessions.read();
    expect(rotated!.refreshUncertain, isFalse);
    expect(
      rotated.refreshToken == _tokens('a', generation: 2)['refreshToken'],
      isTrue,
    );
  });

  test('malformed refresh outcome survives restart without replay', () async {
    await seed('a', expiredAccess: true);
    var refreshes = 0;
    handle = (request) async {
      expect(request.uri.path, '/v1/auth/refresh');
      ++refreshes;
      await _body(request);
      expect((await sessions.read())!.refreshUncertain, isTrue);
      // A server may have rotated the token before this response was lost.
      request.response.headers.contentType = ContentType.json;
      request.response.write('{');
      await request.response.close();
    };

    await expectLater(auth.account(), throwsA(isA<CloudProtocolException>()));
    expect((await sessions.read())!.refreshUncertain, isTrue);
    await expectLater(
      newAuth().account(),
      throwsA(isA<CloudReauthenticationRequiredException>()),
    );
    expect(refreshes, 1);
  });

  test('a restarted service cannot replay an in-flight refresh', () async {
    await seed('a', expiredAccess: true);
    final entered = Completer<void>();
    final release = Completer<void>();
    var refreshes = 0;
    handle = (request) async {
      if (request.uri.path == '/v1/auth/refresh') {
        ++refreshes;
        await _body(request);
        expect((await sessions.read())!.refreshUncertain, isTrue);
        entered.complete();
        await release.future;
        await _json(request, _tokens('a', generation: 2));
      } else {
        expect(request.uri.path, '/v1/account');
        await _json(request, _account('a'));
      }
    };

    final pending = expectLater(auth.account(), completes);
    await entered.future.timeout(const Duration(seconds: 1));
    await expectLater(
      newAuth().account(),
      throwsA(isA<CloudReauthenticationRequiredException>()),
    );
    release.complete();
    await pending;
    expect(refreshes, 1);
    expect((await sessions.read())!.refreshUncertain, isFalse);
  });

  test('refresh timeout survives restart without replay', () async {
    api.close();
    api = ApiClient(
      baseUri: Uri.parse('http://127.0.0.1:${server.port}'),
      allowLoopbackHttp: true,
      timeout: const Duration(milliseconds: 150),
    );
    auth = newAuth();
    await seed('a', expiredAccess: true);
    final entered = Completer<void>();
    final release = Completer<void>();
    var refreshes = 0;
    handle = (request) async {
      expect(request.uri.path, '/v1/auth/refresh');
      ++refreshes;
      await _body(request);
      if (!entered.isCompleted) entered.complete();
      await release.future;
      await request.response.close();
    };

    final pending = expectLater(
      auth.account(),
      throwsA(isA<CloudTimeoutException>()),
    );
    await entered.future.timeout(const Duration(seconds: 1));
    await pending;
    expect((await sessions.read())!.refreshUncertain, isTrue);
    await expectLater(
      newAuth().account(),
      throwsA(isA<CloudReauthenticationRequiredException>()),
    );
    release.complete();
    expect(refreshes, 1);
  });

  test('logout during refresh cannot restore the local session', () async {
    await seed('a', expiredAccess: true);
    final entered = Completer<void>();
    final release = Completer<void>();
    var logouts = 0;
    handle = (request) async {
      if (request.uri.path == '/v1/auth/refresh') {
        await _body(request);
        entered.complete();
        await release.future;
        await _json(request, _tokens('a', generation: 2));
      } else {
        expect(request.uri.path, '/v1/auth/logout');
        ++logouts;
        request.response.statusCode = HttpStatus.noContent;
        await request.response.close();
      }
    };

    final pending = expectLater(
      auth.account(),
      throwsA(isA<CloudSessionChangedException>()),
    );
    await entered.future.timeout(const Duration(seconds: 1));
    await auth.logout();
    expect(await sessions.read(), isNull);
    release.complete();
    await pending;
    expect(await sessions.read(), isNull);
    expect(logouts, 1);
    expect(await db.select(db.secrets).get(), isEmpty);
  });

  test('a delayed revoked response cannot clear a new account', () async {
    await seed('a');
    final entered = Completer<void>();
    final release = Completer<void>();
    handle = (request) async {
      if (request.uri.path == '/v1/account') {
        entered.complete();
        await release.future;
        await _revoked(request);
      } else {
        expect(request.uri.path, '/v1/auth/email/verify');
        await _body(request);
        await _json(request, _tokens('b'));
      }
    };

    final pending = expectLater(
      auth.account(),
      throwsA(isA<CloudApiException>()),
    );
    await entered.future.timeout(const Duration(seconds: 1));
    await auth.verifyEmail(challengeId: 'new-challenge', code: '000123');
    release.complete();
    await pending;
    final current = await sessions.read();
    expect(current!.accountId, 'b');
    expect(current.sessionId, 'session-b');
    expect(current.refreshUncertain, isFalse);
  });

  test(
    'offline logout persists a proof until a restarted service revokes',
    () async {
      await seed('a');
      final entered = Completer<void>();
      final release = Completer<void>();
      var logouts = 0;
      handle = (request) async {
        expect(request.uri.path, '/v1/auth/logout');
        ++logouts;
        final body = await _body(request);
        expect(
          request.headers.value(HttpHeaders.authorizationHeader) == null,
          isTrue,
        );
        expect(body.keys.toList(), ['refreshToken']);
        expect(body['refreshToken'] == _tokens('a')['refreshToken'], isTrue);
        if (logouts == 1) {
          entered.complete();
          await release.future;
          final socket = await request.response.detachSocket(
            writeHeaders: false,
          );
          socket.destroy();
        } else {
          request.response.statusCode = HttpStatus.noContent;
          await request.response.close();
        }
      };

      final failedLogout = expectLater(
        auth.logout(),
        throwsA(isA<CloudNetworkException>()),
      );
      await entered.future.timeout(const Duration(seconds: 1));
      // Local logout and durable encrypted queue commit before HTTP completion.
      expect(await sessions.read(), isNull);
      final pending = await sessions.pendingRevocations();
      expect(pending.length, 1);
      expect(pending.single.sessionId, 'session-a');
      expect(
        pending.single.refreshToken == _tokens('a')['refreshToken'],
        isTrue,
      );
      release.complete();
      await failedLogout;

      await newAuth().retryPendingRevocations();
      expect(await sessions.read(), isNull);
      expect(await sessions.pendingRevocations(), isEmpty);
      expect(await db.select(db.secrets).get(), isEmpty);
      expect(logouts, 2);
    },
  );

  test(
    'revoking an old queued session cannot clear a new active account',
    () async {
      await seed('a');
      var logouts = 0;
      handle = (request) async {
        expect(request.uri.path, '/v1/auth/logout');
        ++logouts;
        final body = await _body(request);
        // Never mix the new account's Bearer with the old revocation proof.
        expect(
          request.headers.value(HttpHeaders.authorizationHeader) == null,
          isTrue,
        );
        expect(body.keys.toList(), ['refreshToken']);
        expect(body['refreshToken'] == _tokens('a')['refreshToken'], isTrue);
        if (logouts == 1) {
          final socket = await request.response.detachSocket(
            writeHeaders: false,
          );
          socket.destroy();
        } else {
          request.response.statusCode = HttpStatus.noContent;
          await request.response.close();
        }
      };

      await expectLater(auth.logout(), throwsA(isA<CloudNetworkException>()));
      expect((await sessions.pendingRevocations()).length, 1);
      await seed('b');
      await newAuth().retryPendingRevocations();

      final current = await sessions.read();
      expect(current!.accountId, 'b');
      expect(current.sessionId, 'session-b');
      expect(current.accessToken == _tokens('b')['accessToken'], isTrue);
      expect(current.refreshToken == _tokens('b')['refreshToken'], isTrue);
      expect(await sessions.pendingRevocations(), isEmpty);
      expect((await db.select(db.secrets).get()).length, 2);
      expect(logouts, 2);
    },
  );

  test(
    'a local expiry estimate still submits proof and accepts server acknowledgement',
    () async {
      await seed('a');
      final current = (await sessions.read())!;
      await sessions.save(
        current.copyWith(
          refreshExpiresAt: _now.subtract(const Duration(seconds: 1)),
        ),
      );
      var logouts = 0;
      handle = (request) async {
        expect(request.uri.path, '/v1/auth/logout');
        ++logouts;
        expect(
          request.headers.value(HttpHeaders.authorizationHeader) == null,
          isTrue,
        );
        expect(
          (await _body(request))['refreshToken'] == current.refreshToken,
          isTrue,
        );
        request.response.statusCode = HttpStatus.noContent;
        await request.response.close();
      };

      await auth.logout();
      expect(logouts, 1);
      expect(await sessions.read(), isNull);
      expect(await sessions.pendingRevocations(), isEmpty);
    },
  );

  test(
    'AUTH_REQUIRED retires an unusable proof as failure without retry or clearing a new account',
    () async {
      await seed('a');
      await sessions.logoutLocally();
      await seed('b');
      var logouts = 0;
      handle = (request) async {
        expect(request.uri.path, '/v1/auth/logout');
        ++logouts;
        expect(
          request.headers.value(HttpHeaders.authorizationHeader) == null,
          isTrue,
        );
        expect(
          (await _body(request))['refreshToken'] ==
              _tokens('a')['refreshToken'],
          isTrue,
        );
        await _json(request, {
          'error': {'code': 'AUTH_REQUIRED', 'message': 'Proof is expired.'},
        }, status: HttpStatus.unauthorized);
      };

      await expectLater(
        auth.retryPendingRevocations(),
        throwsA(isA<CloudRevocationUnavailableException>()),
      );
      expect(await sessions.pendingRevocations(), isEmpty);
      final current = (await sessions.read())!;
      expect(current.sessionId, 'session-b');
      expect(current.refreshToken == _tokens('b')['refreshToken'], isTrue);
      await newAuth().retryPendingRevocations();
      expect(logouts, 1);
    },
  );

  test(
    'a terminal proof after network failure stays visible while other proofs finish',
    () async {
      for (final account in ['a', 'b', 'd']) {
        await seed(account);
        await sessions.logoutLocally();
      }
      await seed('c');
      var networkAvailable = false;
      var logouts = 0;
      Object? reported;
      handle = (request) async {
        expect(request.uri.path, '/v1/auth/logout');
        ++logouts;
        expect(
          request.headers.value(HttpHeaders.authorizationHeader) == null,
          isTrue,
        );
        final body = await _body(request);
        expect(body.keys.toList(), ['refreshToken']);
        if (body['refreshToken'] == _tokens('a')['refreshToken'] &&
            !networkAvailable) {
          final socket = await request.response.detachSocket(
            writeHeaders: false,
          );
          socket.destroy();
        } else if (body['refreshToken'] == _tokens('b')['refreshToken']) {
          await _json(request, {
            'error': {'code': 'AUTH_REQUIRED', 'message': 'Proof expired.'},
          }, status: HttpStatus.unauthorized);
        } else {
          expect(
            body['refreshToken'] == _tokens('a')['refreshToken'] ||
                body['refreshToken'] == _tokens('d')['refreshToken'],
            isTrue,
          );
          request.response.statusCode = HttpStatus.noContent;
          await request.response.close();
        }
      };
      final controller = CloudRevocationRetryController(
        readPendingCount: () async =>
            (await sessions.pendingRevocations()).length,
        retryPendingRevocations: () async {
          try {
            await auth.retryPendingRevocations();
          } on Object catch (error) {
            reported = error;
            rethrow;
          }
        },
      );
      addTearDown(controller.dispose);

      controller.resume();
      await controller.idle;
      expect(reported, isA<CloudRevocationUnavailableException>());
      expect(logouts, 3);
      expect(controller.status.queuedCount, 1);
      expect(controller.status.remoteRevocationUnconfirmed, isTrue);
      expect(
        (await sessions.pendingRevocations()).single.sessionId,
        'session-a',
      );
      expect((await sessions.read())!.sessionId, 'session-c');

      controller.pause();
      networkAvailable = true;
      controller.resume();
      await controller.idle;
      expect(logouts, 4);
      expect(controller.status.queuedCount, 0);
      expect(controller.status.remoteRevocationUnconfirmed, isTrue);
      expect(await sessions.pendingRevocations(), isEmpty);
      expect((await sessions.read())!.sessionId, 'session-c');
    },
  );

  for (final malformed in [false, true]) {
    test(
      '${malformed ? 'malformed' : 'UNKNOWN_AUTH_ERROR'} 401 retains its proof for a later retry',
      () async {
        await seed('a');
        var logouts = 0;
        handle = (request) async {
          expect(request.uri.path, '/v1/auth/logout');
          ++logouts;
          await _body(request);
          if (logouts > 1) {
            request.response.statusCode = HttpStatus.noContent;
            await request.response.close();
          } else if (malformed) {
            request.response.statusCode = HttpStatus.unauthorized;
            request.response.headers.contentType = ContentType.json;
            request.response.write('{');
            await request.response.close();
          } else {
            await _json(request, {
              'error': {
                'code': 'UNKNOWN_AUTH_ERROR',
                'message': 'Unrecognized authorization result.',
              },
            }, status: HttpStatus.unauthorized);
          }
        };

        await expectLater(
          auth.logout(),
          throwsA(
            isA<CloudApiException>()
                .having((error) => error.httpStatus, 'HTTP status', 401)
                .having(
                  (error) => error.code,
                  'fallback error code',
                  CloudErrorCode.unknownAuthError,
                ),
          ),
        );
        expect(await sessions.read(), isNull);
        expect(await sessions.pendingRevocations(), hasLength(1));
        await newAuth().retryPendingRevocations();
        expect(await sessions.pendingRevocations(), isEmpty);
        expect(logouts, 2);
      },
    );
  }

  test(
    'a delayed AUTH_REQUIRED cannot discard a replacement proof for the same session',
    () async {
      await seed('a');
      final original = (await sessions.read())!;
      await sessions.logoutLocally();
      final entered = Completer<void>();
      final release = Completer<void>();
      var logouts = 0;
      handle = (request) async {
        expect(request.uri.path, '/v1/auth/logout');
        ++logouts;
        final body = await _body(request);
        expect(
          request.headers.value(HttpHeaders.authorizationHeader) == null,
          isTrue,
        );
        if (logouts == 1) {
          expect(body['refreshToken'] == original.refreshToken, isTrue);
          entered.complete();
          await release.future;
          await _json(request, {
            'error': {'code': 'AUTH_REQUIRED', 'message': 'Proof expired.'},
          }, status: HttpStatus.unauthorized);
        } else {
          expect(body['refreshToken'] == 'test-replacement-proof', isTrue);
          request.response.statusCode = HttpStatus.noContent;
          await request.response.close();
        }
      };

      final failedOldProof = expectLater(
        auth.retryPendingRevocations(),
        throwsA(isA<CloudRevocationUnavailableException>()),
      );
      await entered.future.timeout(const Duration(seconds: 1));
      await sessions.save(
        original.copyWith(refreshToken: 'test-replacement-proof'),
      );
      await sessions.logoutLocally();
      await seed('b');
      release.complete();
      await failedOldProof;

      final pending = await sessions.pendingRevocations();
      expect(pending, hasLength(1));
      expect(pending.single.refreshToken == 'test-replacement-proof', isTrue);
      expect((await sessions.read())!.sessionId, 'session-b');
      await newAuth().retryPendingRevocations();
      expect(await sessions.pendingRevocations(), isEmpty);
      expect((await sessions.read())!.sessionId, 'session-b');
      expect(logouts, 2);
    },
  );

  test(
    'delete clears tokens, detaches its account, and keeps local data',
    () async {
      await seed('a');
      final configs = ConfigurationRepository(db, secrets);
      final parsed = parseContent(
        'trojan://test-proxy-password@proxy.example.invalid:443#Local',
      );
      final own = await configs.add(
        kind: ConfigurationKind.subscription,
        name: 'Own local subscription',
        parsed: parsed,
        digest: 'loopback-digest',
        source: const SubscriptionSource(
          url: Secret(
            'https://subscription.example.invalid/?token=test-source',
          ),
        ),
      );
      final other = await configs.add(
        kind: ConfigurationKind.file,
        name: 'Other account local file',
        parsed: parsed,
        digest: 'other-digest',
      );
      await (db.update(db.configurations)..where((r) => r.id.equals(own)))
          .write(const ConfigurationsCompanion(cloudAccountId: Value('a')));
      await (db.update(db.configurations)..where((r) => r.id.equals(other)))
          .write(const ConfigurationsCompanion(cloudAccountId: Value('b')));
      final localSecretsBefore = (await db.select(db.secrets).get()).length - 2;
      handle = (request) async {
        expect(request.method, 'DELETE');
        expect(request.uri.path, '/v1/account');
        await _json(request, {
          'cancelSubscription': {
            'required': true,
            'sources': ['web'],
          },
        });
      };

      final deleted = await auth.deleteAccount();
      expect(deleted.cancelSubscription.required, isTrue);
      expect(deleted.cancelSubscription.sources, [PurchaseSource.web]);
      expect(await sessions.read(), isNull);
      final rows = await db.select(db.configurations).get();
      expect(rows.singleWhere((r) => r.id == own).cloudAccountId, isNull);
      expect(rows.singleWhere((r) => r.id == other).cloudAccountId, 'b');
      expect((await configs.get(own))!.name, 'Own local subscription');
      expect((await configs.content(own))!.digest, 'loopback-digest');
      expect(
        (await configs.source(own))!.url.value ==
            'https://subscription.example.invalid/?token=test-source',
        isTrue,
      );
      expect((await db.select(db.secrets).get()).length, localSecretsBefore);
      expect((await configs.content(other))!.digest, 'other-digest');
    },
  );
}
