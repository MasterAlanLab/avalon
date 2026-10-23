import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:avalon/cloud/api_client.dart';
import 'package:avalon/cloud/cloud_models.dart';
import 'package:avalon/cloud/sync_models.dart';
import 'package:flutter_test/flutter_test.dart';

const _id = '2d893a37-e98b-4231-8155-5ae4b0b92609';
const _other = '55df2c26-0bcd-4b74-a359-14d57a34d704';
const _mid = '0341d974-f1cc-4e34-a451-a091b8a09e26';
const _time = '2026-10-13T00:00:00Z';

SyncMutation _mutation({String id = _id, String mid = _mid, int size = 0}) =>
    SyncMutation(
      mutationId: mid,
      recordId: id,
      type: SyncRecordType.configuration,
      baseRevision: 0,
      editedAt: 100,
      deleted: false,
      payload: {
        'kind': 'subscription',
        'name': 'source',
        'autoUpdate': true,
        'createdAt': 1,
        'source': {
          'url': 'https://example.invalid/?token=synthetic',
          'headers': {for (var i = 0; i < size; ++i) 'X-Large-$i': 's' * 16000},
        },
      },
    );

Map<String, Object?> _applied(SyncMutation m) => {
  'mutationId': m.mutationId,
  'status': 'applied',
  'revision': 1,
  'editedAt': 90,
};

Future<void> _json(
  HttpRequest request,
  Object? value, {
  int status = 200,
  bool version = true,
  bool noStore = true,
}) async {
  final response = request.response;
  response.statusCode = status;
  response.headers.contentType = ContentType.json;
  if (version) response.headers.set('Avalon-Sync-Version', '1');
  if (noStore) response.headers.set('Cache-Control', 'no-store');
  response.write(jsonEncode(value));
  await response.close();
}

Future<HttpServer> _server(Future<void> Function(HttpRequest) handle) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen(handle);
  addTearDown(() => server.close(force: true));
  return server;
}

String _url(HttpServer server) => 'http://127.0.0.1:${server.port}';

ApiClient _api(HttpServer server, {int legacyLimit = 1024 * 1024}) {
  final api = ApiClient(
    baseUri: Uri.parse(_url(server)),
    allowLoopbackHttp: true,
    responseMaxBytes: legacyLimit,
  );
  addTearDown(api.close);
  return api;
}

void main() {
  test(
    'native HTTP sends all three exact operations and matches a partial push prefix',
    () async {
      final sent = _mutation(size: 5);
      final other = _mutation(
        id: _other,
        mid: '968919c3-34bc-4231-93b2-4995c42e0a7c',
      );
      final visited = <String>[];
      final server = await _server((request) async {
        visited.add(request.uri.path);
        expect(request.headers.value('Avalon-Sync-Version'), '1');
        expect(
          request.headers.value(HttpHeaders.authorizationHeader),
          'Bearer synthetic-access',
        );
        switch (request.uri.path) {
          case '/v1/sync/activate':
            expect(request.uri.hasQuery, isFalse);
            expect(await utf8.decoder.bind(request).join(), isEmpty);
            await _json(request, {
              'deviceId': 'device',
              'syncActive': true,
              'deviceLimit': 10,
              'syncActiveDeviceCount': 1,
              'serverTime': _time,
            });
          case '/v1/sync/pull':
            expect(request.uri.queryParameters, {'cursor': '3', 'limit': '2'});
            expect(await utf8.decoder.bind(request).join(), isEmpty);
            await _json(request, {
              'records': <Object?>[],
              'nextCursor': 3,
              'hasMore': false,
              'serverTime': _time,
            });
          case '/v1/sync/push':
            final body = await utf8.decoder.bind(request).join();
            expect(
              body,
              canonicalSyncJson({
                'mutations': [sent.toJson(), other.toJson()],
              }),
            );
            await _json(request, {
              'results': [_applied(sent)],
              'processedCount': 1,
              'hasMore': true,
              'serverTime': _time,
            });
          default:
            fail('Unexpected endpoint');
        }
      });
      final api = _api(server, legacyLimit: 128);
      expect(
        (await api.activateSync(accessToken: 'synthetic-access')).syncActive,
        isTrue,
      );
      expect(
        (await api.pullSync(
          accessToken: 'synthetic-access',
          cursor: 3,
          limit: 2,
        )).nextCursor,
        3,
      );
      final pushed = await api.pushSync(
        accessToken: 'synthetic-access',
        mutations: [sent, other],
      );
      expect(pushed.results.single, isA<SyncAppliedResult>());
      expect(pushed.hasMore, isTrue);
      expect(visited.length, 3);
      await expectLater(
        api.emailStart(email: 's' * 70000),
        throwsArgumentError,
      );
    },
  );

  test(
    'success without version or no-store is rejected before DTO apply',
    () async {
      var count = 0;
      final server = await _server((request) async {
        ++count;
        await _json(
          request,
          {
            'deviceId': 'device',
            'syncActive': true,
            'deviceLimit': 10,
            'syncActiveDeviceCount': 1,
            'serverTime': _time,
          },
          version: count != 1,
          noStore: count != 2,
        );
      });
      final api = _api(server);
      await expectLater(
        api.activateSync(accessToken: 'synthetic-access'),
        throwsA(isA<CloudProtocolException>()),
      );
      await expectLater(
        api.activateSync(accessToken: 'synthetic-access'),
        throwsA(isA<CloudProtocolException>()),
      );
    },
  );

  test(
    'native sync response is gzip-decoded with the sync rather than legacy budget',
    () async {
      final sent = _mutation(size: 5);
      final record = {
        'recordId': sent.recordId,
        'type': 'configuration',
        'revision': 1,
        'editedAt': 90,
        'editedByDeviceId': 'device',
        'deleted': false,
        'schemaVersion': 1,
        'payload': sent.payload,
      };
      final server = await _server((request) async {
        request.response.headers.contentType = ContentType.json;
        request.response.headers.set('Avalon-Sync-Version', '1');
        request.response.headers.set('Cache-Control', 'no-store');
        request.response.headers.set(HttpHeaders.contentEncodingHeader, 'gzip');
        request.response.add(
          gzip.encode(
            utf8.encode(
              jsonEncode({
                'records': [record],
                'nextCursor': 1,
                'hasMore': false,
                'serverTime': _time,
              }),
            ),
          ),
        );
        await request.response.close();
      });
      final page = await _api(
        server,
        legacyLimit: 128,
      ).pullSync(accessToken: 'synthetic-access', cursor: 0);
      expect(page.records.single.payload, sent.payload);
    },
  );

  test(
    'transport terminates gzip at decoded size instead of compressed length',
    () async {
      final server = await _server((request) async {
        request.response.headers.set(HttpHeaders.contentEncodingHeader, 'gzip');
        request.response.add(gzip.encode(List<int>.filled(8192, 65)));
        await request.response.close();
      });
      final transport = HttpClientCloudTransport();
      addTearDown(transport.close);
      await expectLater(
        transport.send(
          CloudRequest(
            method: 'GET',
            uri: Uri.parse('${_url(server)}/'),
            headers: {},
            body: null,
            timeout: const Duration(seconds: 2),
            responseMaxBytes: 1024,
          ),
        ),
        throwsA(
          isA<CloudProtocolException>().having(
            (e) => e.reason,
            'reason',
            CloudProtocolFailure.responseTooLarge,
          ),
        ),
      );
    },
  );

  test('sync errors retain machine meaning without diagnostic text', () async {
    final server = await _server((request) async {
      await _json(request, {
        'error': {
          'code': 'SYNC_QUOTA_EXCEEDED',
          'message': 'synthetic-secret diagnostic',
        },
      }, status: 409);
    });
    await expectLater(
      _api(
        server,
      ).pushSync(accessToken: 'synthetic-access', mutations: [_mutation()]),
      throwsA(
        isA<CloudApiException>()
            .having((e) => e.code, 'code', CloudErrorCode.syncQuotaExceeded)
            .having((e) => e.message, 'message', isEmpty),
      ),
    );
  });

  test(
    'future schema and duplicate response keys reject the entire page',
    () async {
      var count = 0;
      final server = await _server((request) async {
        ++count;
        if (count == 1) {
          await _json(request, {
            'records': [
              {
                'recordId': _id,
                'type': 'node',
                'revision': 1,
                'editedAt': 1,
                'editedByDeviceId': 'device',
                'deleted': true,
                'schemaVersion': 2,
                'payload': null,
              },
            ],
            'nextCursor': 1,
            'hasMore': false,
            'serverTime': _time,
          });
        } else {
          request.response.headers.contentType = ContentType.json;
          request.response.headers.set('Avalon-Sync-Version', '1');
          request.response.headers.set('Cache-Control', 'no-store');
          request.response.write(
            '{"records":[],"nextCursor":0,"nextCursor":1,"hasMore":false,"serverTime":"2026-10-13T00:00:00Z"}',
          );
          await request.response.close();
        }
      });
      final api = _api(server);
      await expectLater(
        api.pullSync(accessToken: 'synthetic-access', cursor: 0),
        throwsA(
          isA<SyncValidationException>().having(
            (e) => e.reason,
            'reason',
            SyncValidationFailure.unsupportedSchema,
          ),
        ),
      );
      await expectLater(
        api.pullSync(accessToken: 'synthetic-access', cursor: 0),
        throwsA(isA<SyncValidationException>()),
      );
    },
  );

  test('sync redirects never carry Bearer to another origin', () async {
    var intercepted = 0;
    final destination = await _server((request) async {
      ++intercepted;
      await request.response.close();
    });
    final server = await _server((request) async {
      request.response.statusCode = 302;
      request.response.headers.set(
        HttpHeaders.locationHeader,
        '${_url(destination)}/',
      );
      await request.response.close();
    });
    await expectLater(
      _api(server).activateSync(accessToken: 'synthetic-access'),
      throwsA(
        isA<CloudProtocolException>().having(
          (e) => e.reason,
          'reason',
          CloudProtocolFailure.redirect,
        ),
      ),
    );
    expect(intercepted, 0);
  });

  test(
    'injected transport cannot bypass operation response byte cap',
    () async {
      final api = ApiClient(
        baseUri: Uri.parse('https://example.invalid'),
        transport: _LargeTransport(),
      );
      addTearDown(api.close);
      await expectLater(
        api.activateSync(accessToken: 'synthetic-access'),
        throwsA(
          isA<CloudProtocolException>().having(
            (e) => e.reason,
            'reason',
            CloudProtocolFailure.responseTooLarge,
          ),
        ),
      );
    },
  );
}

final class _LargeTransport implements CloudTransport {
  @override
  Future<CloudResponse> send(CloudRequest request) async => CloudResponse(
    statusCode: 200,
    headers: {},
    body: Uint8List(syncBodyMaxBytes + 1),
  );
  @override
  void close() {}
}
