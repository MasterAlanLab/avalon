import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avalon/cloud/api_client.dart';
import 'package:avalon/cloud/cloud_models.dart';
import 'package:flutter_test/flutter_test.dart';

const _access = 'test-sensitive-access';
const _refresh = 'test-sensitive-refresh';
const _email = 'sensitive@example.invalid';
const _device = DeviceInput(
  installationId: 'aa3d808f-b7d9-40a3-aed5-0cefc5e6470b',
  name: 'Test device',
  os: DeviceOs.linux,
);

Map<String, Object?> _tokens() => {
  'accessToken': _access,
  'accessExpiresAt': '2026-10-11T01:15:00Z',
  'refreshToken': _refresh,
  'refreshExpiresAt': '2027-01-09T01:00:00.000Z',
  'accountId': 'account',
  'deviceId': 'device',
  'sessionId': 'session',
};

Map<String, Object?> _account() => {
  'account': {'id': 'account', 'email': _email, 'displayName': null},
  'entitlement': null,
  'devices': [
    {
      'id': 'device',
      'name': 'Test device',
      'os': 'linux',
      'syncActive': false,
      'lastSeenAt': '2026-10-11T01:00:00Z',
    },
  ],
  'currentDeviceId': 'device',
  'deviceLimit': 10,
  'syncActiveDeviceCount': 0,
};

Future<HttpServer> _server(Future<void> Function(HttpRequest) handler) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen(handler);
  addTearDown(() => server.close(force: true));
  return server;
}

ApiClient _api(
  HttpServer server, {
  Duration timeout = const Duration(seconds: 2),
  int responseMaxBytes = 1024 * 1024,
  int requestMaxBytes = 64 * 1024,
}) {
  final api = ApiClient(
    baseUri: Uri.parse('http://127.0.0.1:${server.port}'),
    allowLoopbackHttp: true,
    timeout: timeout,
    responseMaxBytes: responseMaxBytes,
    requestMaxBytes: requestMaxBytes,
  );
  addTearDown(api.close);
  return api;
}

Future<void> _json(
  HttpResponse response,
  Object body, {
  int status = 200,
}) async {
  response.statusCode = status;
  response.headers.contentType = ContentType.json;
  response.write(jsonEncode(body));
  await response.close();
}

Future<Map<String, Object?>> _body(HttpRequest request) async =>
    jsonDecode(await utf8.decoder.bind(request).join()) as Map<String, Object?>;

void main() {
  test(
    'all seven operations send the agreed paths and exact request DTOs',
    () async {
      final requests = <String>[];
      final server = await _server((request) async {
        final key = '${request.method} ${request.uri.path}';
        requests.add(key);
        expect(request.headers.value(HttpHeaders.cookieHeader), isNull);
        if (request.uri.path.startsWith('/v1/auth/email/') ||
            request.uri.path == '/v1/auth/refresh') {
          expect(
            request.headers.value(HttpHeaders.authorizationHeader),
            isNull,
          );
          expect(request.headers.contentType?.mimeType, 'application/json');
        } else {
          expect(
            request.headers.value(HttpHeaders.authorizationHeader),
            'Bearer $_access',
          );
          expect(await utf8.decoder.bind(request).join(), isEmpty);
          expect(request.headers.contentType, isNull);
        }
        switch (key) {
          case 'POST /v1/auth/email/start':
            expect(await _body(request), {'email': _email});
            await _json(request.response, {
              'challengeId': 'challenge',
              'expiresAt': '2026-10-11T01:10:00Z',
            });
          case 'POST /v1/auth/email/verify':
            expect(await _body(request), {
              'challengeId': 'challenge',
              'code': '000123',
              'device': _device.toJson(),
            });
            await _json(request.response, _tokens());
          case 'POST /v1/auth/refresh':
            expect(await _body(request), {'refreshToken': _refresh});
            await _json(request.response, _tokens());
          case 'GET /v1/account':
            await _json(request.response, _account());
          case 'DELETE /v1/account':
            await _json(request.response, {
              'cancelSubscription': {
                'required': true,
                'sources': ['apple', 'web'],
              },
            });
          case 'POST /v1/auth/logout':
          case 'DELETE /v1/devices/other':
            request.response.statusCode = 204;
            await request.response.close();
          default:
            fail('Unexpected operation');
        }
      });
      final api = _api(server);
      expect((await api.emailStart(email: _email)).challengeId, 'challenge');
      final verified = await api.emailVerify(
        challengeId: 'challenge',
        code: '000123',
        device: _device,
      );
      expect(verified.accessToken, _access);
      expect(verified.accessExpiresAt, DateTime.utc(2026, 10, 11, 1, 15));
      expect((await api.refresh(refreshToken: _refresh)).sessionId, 'session');
      final account = await api.getAccount(accessToken: _access);
      expect(account.account.email, _email);
      expect(account.entitlement, isNull);
      expect(account.devices.single.os, DeviceOs.linux);
      expect(
        (await api.deleteAccount(
          accessToken: _access,
        )).cancelSubscription.sources,
        [PurchaseSource.apple, PurchaseSource.web],
      );
      await api.logout(accessToken: _access);
      await api.removeDevice(accessToken: _access, deviceId: 'other');
      expect(requests, [
        'POST /v1/auth/email/start',
        'POST /v1/auth/email/verify',
        'POST /v1/auth/refresh',
        'GET /v1/account',
        'DELETE /v1/account',
        'POST /v1/auth/logout',
        'DELETE /v1/devices/other',
      ]);
    },
  );

  test('email start preserves the server UTC challenge expiry', () async {
    final server = await _server((request) async {
      expect(request.method, 'POST');
      expect(request.uri.path, '/v1/auth/email/start');
      expect(
        request.headers.value(HttpHeaders.authorizationHeader) == null,
        isTrue,
      );
      expect((await _body(request))['email'] == _email, isTrue);
      await _json(request.response, {
        'challengeId': 'test-sensitive-challenge',
        'expiresAt': '2026-10-11T01:10:00.123456Z',
      });
    });

    final challenge = await _api(server).emailStart(email: _email);
    expect(challenge.challengeId == 'test-sensitive-challenge', isTrue);
    expect(challenge.expiresAt, DateTime.utc(2026, 10, 11, 1, 10, 0, 123, 456));
    expect(challenge.expiresAt.isUtc, isTrue);
    expect(challenge.toString().contains('test-sensitive-challenge'), isFalse);
  });

  for (final invalid in <(String, Map<String, Object?>)>[
    ('missing', {}),
    ('null', {'expiresAt': null}),
    ('non-string', {'expiresAt': 1791671400}),
    ('invalid', {'expiresAt': '$_access $_email'}),
    ('normalized date', {'expiresAt': '2026-02-30T01:10:00Z'}),
    ('UTC offset', {'expiresAt': '2026-10-11T01:10:00+00:00'}),
    ('non-UTC offset', {'expiresAt': '2026-10-11T09:10:00+08:00'}),
    ('local time', {'expiresAt': '2026-10-11T01:10:00'}),
  ]) {
    test('email start rejects ${invalid.$1} expiry safely over HTTP', () async {
      final server = await _server((request) async {
        await request.drain<void>();
        await _json(request.response, {
          'challengeId': '$_access $_refresh $_email',
          ...invalid.$2,
        });
      });

      try {
        await _api(server).emailStart(email: _email);
        fail('Expected invalid challenge expiry to fail.');
      } on CloudProtocolException catch (error) {
        expect(error.reason, CloudProtocolFailure.invalidResponse);
        expect(error.toString().contains(_access), isFalse);
        expect(error.toString().contains(_refresh), isFalse);
        expect(error.toString().contains(_email), isFalse);
      }
    });
  }

  for (final reason in EmailChallengeReason.values) {
    test(
      'challenge validation preserves ${reason.name} without diagnostics',
      () async {
        const sensitive = '$_email $_access $_refresh';
        final server = await _server((request) async {
          await request.drain<void>();
          await _json(request.response, {
            'error': {
              'code': 'VALIDATION',
              'message': sensitive,
              'reason': reason.name,
            },
          }, status: 400);
        });
        try {
          await _api(server).emailVerify(
            challengeId: 'challenge',
            code: '000123',
            device: _device,
          );
          fail('Expected challenge validation failure.');
        } on CloudApiException catch (error) {
          expect(error.httpStatus, 400);
          expect(error.code, CloudErrorCode.validation);
          expect(error.reason, reason);
          expect(error.toString(), 'CloudApiException(400)');
          expect(error.toString().contains(_email), isFalse);
          expect(error.toString().contains(_access), isFalse);
          expect(error.toString().contains(_refresh), isFalse);
        }
      },
    );
  }

  for (final invalid in <(String, Map<String, Object?>)>[
    ('absent', {}),
    ('null', {'reason': null}),
    ('unknown', {'reason': '$_email $_access'}),
    ('non-string', {'reason': 5}),
    (
      'object',
      {
        'reason': {'secret': _refresh},
      },
    ),
  ]) {
    test(
      'challenge validation handles ${invalid.$1} reason generically',
      () async {
        final server = await _server((request) async {
          await request.drain<void>();
          await _json(request.response, {
            'error': {
              'code': 'VALIDATION',
              'message': 'diagnostic text',
              ...invalid.$2,
            },
          }, status: 400);
        });
        await expectLater(
          _api(server).emailVerify(
            challengeId: 'challenge',
            code: '000123',
            device: _device,
          ),
          throwsA(
            isA<CloudApiException>()
                .having((e) => e.httpStatus, 'status', 400)
                .having((e) => e.code, 'code', CloudErrorCode.validation)
                .having((e) => e.reason, 'reason', isNull),
          ),
        );
      },
    );
  }

  for (final other in <(int, String)>[
    (401, 'VALIDATION'),
    (429, 'RATE_LIMITED'),
    (400, 'INTERNAL_ERROR'),
  ]) {
    test(
      'HTTP ${other.$1} ${other.$2} cannot activate a challenge reason',
      () async {
        final server = await _server((request) async {
          await request.drain<void>();
          await _json(request.response, {
            'error': {
              'code': other.$2,
              'message': 'diagnostic text',
              'reason': 'expired',
            },
          }, status: other.$1);
        });
        await expectLater(
          _api(server).emailVerify(
            challengeId: 'challenge',
            code: '000123',
            device: _device,
          ),
          throwsA(
            isA<CloudApiException>()
                .having((e) => e.httpStatus, 'status', other.$1)
                .having((e) => e.reason, 'reason', isNull),
          ),
        );
      },
    );
  }

  test('redirect never forwards Bearer or body to another origin', () async {
    var recipientRequests = 0;
    final recipient = await _server((request) async {
      recipientRequests++;
      await _json(request.response, _tokens());
    });
    final source = await _server((request) async {
      await request.drain<void>();
      request.response.statusCode = 307;
      request.response.headers.set(
        HttpHeaders.locationHeader,
        'http://127.0.0.1:${recipient.port}/stolen',
      );
      await request.response.close();
    });
    final api = _api(source);
    await expectLater(
      api.getAccount(accessToken: _access),
      throwsA(isA<CloudProtocolException>()),
    );
    await expectLater(
      api.refresh(refreshToken: _refresh),
      throwsA(isA<CloudProtocolException>()),
    );
    expect(recipientRequests, 0);
  });

  test('same-origin redirect is rejected without retrying mutation', () async {
    var requests = 0;
    final source = await _server((request) async {
      requests++;
      await request.drain<void>();
      request.response.statusCode = 308;
      request.response.headers.set(HttpHeaders.locationHeader, '/new-refresh');
      await request.response.close();
    });
    await expectLater(
      _api(source).refresh(refreshToken: _refresh),
      throwsA(isA<CloudProtocolException>()),
    );
    expect(requests, 1);
  });

  test(
    'logout accepts proof only, both credentials, and repeated 204',
    () async {
      var requests = 0;
      final server = await _server((request) async {
        requests++;
        expect(request.method, 'POST');
        expect(request.uri.path, '/v1/auth/logout');
        expect(await _body(request), {'refreshToken': _refresh});
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          requests == 2 ? 'Bearer $_access' : isNull,
        );
        request.response.statusCode = 204;
        await request.response.close();
      });
      final api = _api(server);
      await api.logout(refreshToken: _refresh);
      await api.logout(accessToken: _access, refreshToken: _refresh);
      await api.logout(refreshToken: _refresh);
      expect(requests, 3);
      await expectLater(api.logout(), throwsArgumentError);
      await expectLater(api.logout(refreshToken: ''), throwsArgumentError);
      expect(requests, 3);
    },
  );

  test('logout credential conflict propagates 400 without retry', () async {
    var requests = 0;
    final server = await _server((request) async {
      requests++;
      await request.drain<void>();
      await _json(request.response, {
        'error': {'code': 'VALIDATION', 'message': 'session mismatch'},
      }, status: 400);
    });
    await expectLater(
      _api(server).logout(accessToken: _access, refreshToken: _refresh),
      throwsA(
        isA<CloudApiException>()
            .having((error) => error.httpStatus, 'status', 400)
            .having((error) => error.code, 'code', CloudErrorCode.validation),
      ),
    );
    expect(requests, 1);
  });

  test(
    'device removal preserves not-found and current-device validation errors',
    () async {
      final server = await _server((request) async {
        final current = request.uri.pathSegments.last == 'device';
        await _json(request.response, {
          'error': {
            'code': current ? 'VALIDATION' : 'NOT_FOUND',
            'message': 'cannot remove',
          },
        }, status: current ? 400 : 404);
      });
      final api = _api(server);
      await expectLater(
        api.removeDevice(accessToken: _access, deviceId: 'missing'),
        throwsA(
          isA<CloudApiException>()
              .having((error) => error.httpStatus, 'status', 404)
              .having((error) => error.code, 'code', CloudErrorCode.notFound),
        ),
      );
      await expectLater(
        api.removeDevice(accessToken: _access, deviceId: 'device'),
        throwsA(
          isA<CloudApiException>()
              .having((error) => error.httpStatus, 'status', 400)
              .having((error) => error.code, 'code', CloudErrorCode.validation),
        ),
      );
    },
  );

  test(
    'unknown error code is retained and diagnostics stay out of toString',
    () async {
      const sensitive =
          '$_email $_access $_refresh https://secret.invalid/path';
      final server = await _server((request) async {
        await request.drain<void>();
        request.response.headers.set(HttpHeaders.retryAfterHeader, '23');
        await _json(request.response, {
          'error': {'code': 'NEW_SERVER_CODE', 'message': sensitive},
        }, status: 429);
      });
      try {
        await _api(server).refresh(refreshToken: _refresh);
        fail('Expected API failure');
      } on CloudApiException catch (error) {
        expect(error.httpStatus, 429);
        expect(error.code.value, 'NEW_SERVER_CODE');
        expect(error.message, sensitive);
        expect(error.retryAfter, const Duration(seconds: 23));
        expect(error.toString(), 'CloudApiException(429)');
        expect(error.code.toString(), 'CloudErrorCode');
        expect(error.toString(), isNot(contains(_email)));
        expect(error.toString(), isNot(contains(_access)));
      }
    },
  );

  test('malformed 401 stays an authentication error', () async {
    final server = await _server((request) async {
      request.response.statusCode = 401;
      request.response.write('<html>$_access $_email</html>');
      await request.response.close();
    });
    await expectLater(
      _api(server).getAccount(accessToken: _access),
      throwsA(
        isA<CloudApiException>()
            .having((error) => error.httpStatus, 'status', 401)
            .having(
              (error) => error.code,
              'code',
              CloudErrorCode.unknownAuthError,
            ),
      ),
    );
  });

  test('401 with a too-large body stays an authentication error', () async {
    final server = await _server((request) async {
      request.response.statusCode = 401;
      request.response.write('x' * 200);
      await request.response.close();
    });
    await expectLater(
      _api(server, responseMaxBytes: 32).getAccount(accessToken: _access),
      throwsA(
        isA<CloudApiException>().having((e) => e.httpStatus, 'status', 401),
      ),
    );
  });

  test('401 stalled body retains status at its overall deadline', () async {
    final release = Completer<void>();
    addTearDown(() {
      if (!release.isCompleted) release.complete();
    });
    final server = await _server((request) async {
      request.response.statusCode = 401;
      request.response.write('incomplete');
      await request.response.flush();
      await release.future;
    });
    await expectLater(
      _api(
        server,
        timeout: const Duration(milliseconds: 100),
      ).getAccount(accessToken: _access),
      throwsA(
        isA<CloudApiException>().having((e) => e.httpStatus, 'status', 401),
      ),
    );
  });

  test('known session revocation code is preserved', () async {
    final server = await _server((request) async {
      await _json(request.response, {
        'error': {'code': 'SESSION_REVOKED', 'message': 'revoked'},
      }, status: 401);
    });
    await expectLater(
      _api(server).getAccount(accessToken: _access),
      throwsA(
        isA<CloudApiException>().having(
          (error) => error.code,
          'code',
          CloudErrorCode.sessionRevoked,
        ),
      ),
    );
  });

  test('bounds declared and chunked response bodies', () async {
    for (final declared in [true, false]) {
      final server = await _server((request) async {
        if (declared) request.response.contentLength = 200;
        request.response.write('x' * 200);
        await request.response.close();
      });
      await expectLater(
        _api(server, responseMaxBytes: 32).emailStart(email: _email),
        throwsA(
          isA<CloudProtocolException>().having(
            (error) => error.reason,
            'reason',
            CloudProtocolFailure.responseTooLarge,
          ),
        ),
      );
    }
  });

  test('deadline covers stalled headers, no automatic refresh retry', () async {
    var requests = 0;
    final release = Completer<void>();
    addTearDown(() {
      if (!release.isCompleted) release.complete();
    });
    final server = await _server((request) async {
      requests++;
      await request.drain<void>();
      await release.future;
    });
    final watch = Stopwatch()..start();
    await expectLater(
      _api(
        server,
        timeout: const Duration(milliseconds: 100),
      ).refresh(refreshToken: _refresh),
      throwsA(isA<CloudTimeoutException>()),
    );
    expect(watch.elapsed, lessThan(const Duration(seconds: 1)));
    expect(requests, 1);
  });

  test('deadline covers a successful response with stalled body', () async {
    final release = Completer<void>();
    addTearDown(() {
      if (!release.isCompleted) release.complete();
    });
    final server = await _server((request) async {
      request.response.headers.contentType = ContentType.json;
      request.response.write('{');
      await request.response.flush();
      await release.future;
    });
    await expectLater(
      _api(
        server,
        timeout: const Duration(milliseconds: 100),
      ).emailStart(email: _email),
      throwsA(isA<CloudTimeoutException>()),
    );
  });

  test('request bound is checked before any network activity', () async {
    var requests = 0;
    final server = await _server((request) async {
      requests++;
      await request.response.close();
    });
    await expectLater(
      _api(server, requestMaxBytes: 10).emailStart(email: _email),
      throwsArgumentError,
    );
    expect(requests, 0);
  });

  test('device identifier stays one escaped path segment', () async {
    final server = await _server((request) async {
      expect(request.uri.pathSegments, [
        'v1',
        'devices',
        'device/with?query#x',
      ]);
      expect(request.uri.hasQuery, false);
      expect(request.uri.hasFragment, false);
      request.response.statusCode = 204;
      await request.response.close();
    });
    await _api(
      server,
    ).removeDevice(accessToken: _access, deviceId: 'device/with?query#x');
  });

  test('only explicitly opted-in loopback HTTP base URLs are accepted', () {
    for (final uri in [
      'http://127.0.0.1',
      'https://user:secret@example.invalid',
      'https://example.invalid?secret=1',
      'https://example.invalid#secret',
      'https://example.invalid/v1',
      'relative',
    ]) {
      expect(() => ApiClient(baseUri: Uri.parse(uri)), throwsArgumentError);
    }
    for (final host in ['example.invalid', '192.168.1.5', '0.0.0.0']) {
      expect(
        () => ApiClient(
          baseUri: Uri.parse('http://$host'),
          allowLoopbackHttp: true,
        ),
        throwsArgumentError,
      );
    }
    final secure = ApiClient(baseUri: Uri.parse('https://example.invalid'));
    addTearDown(secure.close);
    for (final host in ['127.0.0.1', 'localhost', '[::1]']) {
      final local = ApiClient(
        baseUri: Uri.parse('http://$host'),
        allowLoopbackHttp: true,
      );
      addTearDown(local.close);
    }
  });

  test('connection failure has a safe network classification', () async {
    final closed = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = closed.port;
    await closed.close(force: true);
    final api = ApiClient(
      baseUri: Uri.parse('http://127.0.0.1:$port'),
      allowLoopbackHttp: true,
    );
    addTearDown(api.close);
    await expectLater(
      api.emailStart(email: _email),
      throwsA(isA<CloudNetworkException>()),
    );
  });

  test('non-JSON success is a safe protocol failure', () async {
    final server = await _server((request) async {
      request.response.headers.contentType = ContentType.html;
      request.response.write('$_email $_access');
      await request.response.close();
    });
    await expectLater(
      _api(server).emailStart(email: _email),
      throwsA(isA<CloudProtocolException>()),
    );
  });

  test('strict UTC timestamps reject offsets and normalized invalid dates', () {
    for (final date in [
      '2026-10-11T01:15:00+00:00',
      '2026-10-11T01:15:00',
      '2026-02-30T01:15:00Z',
      '2026-10-11T25:15:00Z',
    ]) {
      final json = _tokens()..['accessExpiresAt'] = date;
      expect(() => TokenResponse.fromJson(json), throwsFormatException);
    }
    final tokens = TokenResponse.fromJson(_tokens());
    expect(tokens.toString(), isNot(contains(_access)));
    expect(tokens.toString(), isNot(contains(_refresh)));
  });

  test(
    'nullable entitlement and an unknown entitlement status are preserved',
    () {
      final json = _account()
        ..['entitlement'] = {
          'plan': 'monthly',
          'source': 'web',
          'status': 'new_pending_status',
          'expiresAt': '2026-11-11T01:00:00Z',
        };
      final account = AccountResponse.fromJson(json);
      expect(account.entitlement?.status, 'new_pending_status');
      expect(account.entitlement?.plan, EntitlementPlan.monthly);
      expect(() => account.devices.clear(), throwsUnsupportedError);
    },
  );

  test('all five operating systems decode and inconsistent snapshots fail', () {
    for (final os in DeviceOs.values) {
      final device = {
        'id': 'device',
        'name': 'Test',
        'os': os.name,
        'syncActive': false,
        'lastSeenAt': '2026-10-11T01:00:00Z',
      };
      expect(CloudDevice.fromJson(device).os, os);
    }
    expect(
      () => AccountResponse.fromJson(_account()..['syncActiveDeviceCount'] = 1),
      throwsFormatException,
    );
  });

  test(
    'injected transport is also bounded and unauthorized wins over size',
    () async {
      final transport = _StubTransport(
        CloudResponse(statusCode: 401, headers: {}, body: Uint8List(100)),
      );
      final api = ApiClient(
        baseUri: Uri.parse('https://example.invalid'),
        transport: transport,
        responseMaxBytes: 10,
      );
      addTearDown(api.close);
      await expectLater(
        api.getAccount(accessToken: _access),
        throwsA(
          isA<CloudApiException>().having((e) => e.httpStatus, 'status', 401),
        ),
      );
    },
  );

  test('unexpected successful status or nonempty 204 is rejected', () async {
    final api = ApiClient(
      baseUri: Uri.parse('https://example.invalid'),
      transport: _StubTransport(
        CloudResponse(
          statusCode: 204,
          headers: {},
          body: Uint8List.fromList([1]),
        ),
      ),
    );
    addTearDown(api.close);
    await expectLater(
      api.logout(accessToken: _access),
      throwsA(isA<CloudProtocolException>()),
    );
    await expectLater(
      api.emailStart(email: _email),
      throwsA(isA<CloudProtocolException>()),
    );
  });
}

final class _StubTransport implements CloudTransport {
  _StubTransport(this.response);

  final CloudResponse response;

  @override
  Future<CloudResponse> send(CloudRequest request) async => response;

  @override
  void close() {}
}
