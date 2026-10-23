// The typed gateway over a transport that answers like the Core Bridge
// (RUNTIME_HOST §2, §4).
import 'dart:async';
import 'dart:convert';

import 'package:avalon/runtime/host_gateway.dart';
import 'package:avalon/runtime/host_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

/// Answers each command with what the test queued for it.
final class _Transport implements HostTransport {
  final sent = <(String, Map<String, Object?>)>[];
  final answers = <String, Object Function(Map<String, Object?> request)>{};

  @override
  Future<String> call(String command, String request) async {
    final decoded = (jsonDecode(request) as Map).cast<String, Object?>();
    sent.add((command, decoded));
    final answer = answers[command]!(decoded);
    if (answer is Future) return await answer as String;
    if (answer is Exception) throw answer;
    return answer as String;
  }
}

String _ok([Object? result]) => jsonEncode({'result': ?result});

void main() {
  late _Transport transport;
  late HostGateway gateway;
  var ids = 0;
  setUp(() {
    ids = 0;
    transport = _Transport();
    gateway = HostGateway(
      transport,
      newRequestId: () => 'r${ids++}',
      lifecycleTimeout: const Duration(milliseconds: 60),
      commandTimeout: const Duration(milliseconds: 60),
    );
  });

  test(
    'Tailnet status and account commands preserve native peer identity',
    () async {
      final payload = {
        'state': 'Running',
        'tailnet': 'fixture-tailnet',
        'self': {
          'id': 'self',
          'name': 'phone',
          'os': 'android',
          'ips': ['100.64.0.2'],
          'online': true,
        },
        'peers': [
          {
            'id': 'peer',
            'name': 'nas',
            'os': 'linux',
            'ips': ['100.64.0.3'],
            'online': true,
            'exitCapable': true,
          },
        ],
      };
      for (final command in [
        'tailnetStatus',
        'tailnetLogin',
        'tailnetLogout',
      ]) {
        transport.answers[command] = (_) => _ok(payload);
      }
      final status = await gateway.tailnetStatus();
      expect(status.connected, isTrue);
      expect(status.self!.id, 'self');
      expect(status.peers.single.id, 'peer');
      expect(status.peers.single.exitCapable, isTrue);
      await gateway.tailnetLogin();
      await gateway.tailnetLogout();
      expect(transport.sent[0].$2, isEmpty);
      expect(transport.sent[1].$2, {'requestId': 'r0'});
      expect(transport.sent[2].$2, {'requestId': 'r1'});
    },
  );

  test(
    'Cloud proxy download refuses a host without the public guard',
    () async {
      transport.answers['capabilities'] = (_) => _ok({
        'protocolVersion': 1,
        'coreVersion': 'fixture',
        'platform': 'test',
      });
      await expectLater(
        gateway.fetch(
          sessionId: 's',
          outboundTag: 'g',
          url: 'https://example.com/rules.srs',
          maxBytes: 1024,
          publicOnly: true,
        ),
        throwsA(
          isA<HostException>().having(
            (e) => e.error.code,
            'code',
            HostErrorCode.unsupported,
          ),
        ),
      );
      expect(transport.sent.map((s) => s.$1), ['capabilities']);
    },
  );

  test(
    'Cloud proxy download sends policy only after host capability proof',
    () async {
      transport.answers['capabilities'] = (_) => _ok({
        'protocolVersion': 1,
        'coreVersion': 'fixture',
        'platform': 'test',
        'publicNetworkVersion': 1,
      });
      transport.answers['fetch'] = (_) =>
          _ok({'status': 200, 'size': 2, 'body': 'ok'});
      await gateway.fetch(
        sessionId: 's',
        outboundTag: 'g',
        url: 'https://example.com/rules.srs',
        maxBytes: 1024,
        publicOnly: true,
      );
      expect(transport.sent.map((s) => s.$1), ['capabilities', 'fetch']);
      expect(transport.sent.last.$2['publicOnly'], isTrue);
    },
  );

  test(
    'a snapshot is read with what the bridge leaves out as defaults',
    () async {
      transport.answers['snapshot'] = (_) => _ok({
        'sessionId': 's1',
        'revision': 7,
        'state': 'running',
        'planHash': 'h',
        'mode': 'rule',
        'selections': {'g:1': 'n:a'},
        'upBps': 10,
        'downBps': 20,
        'upTotal': 300,
        'downTotal': 400,
        'todayUp': 1300,
        'todayDown': 1400,
        'somethingNew': true,
      });
      final s = await gateway.snapshot();
      expect((s.sessionId, s.revision, s.state), ('s1', 7, HostState.running));
      expect((s.planHash, s.mode), ('h', 'rule'));
      expect(s.selections, {'g:1': 'n:a'});
      expect((s.upBps, s.downBps, s.upTotal, s.downTotal), (10, 20, 300, 400));
      expect((s.todayUp, s.todayDown), (1300, 1400));
      expect(
        (s.proxyActive, s.tailnetActive, s.tunActive, s.systemProxyActive),
        (null, null, null, null),
      );
      expect(s.clashApiListen, isNull);

      transport.answers['snapshot'] = (_) => _ok({
        'sessionId': '',
        'revision': 8,
        'state': 'failed',
        'error': {'code': 'PORT_IN_USE', 'message': 'address already in use'},
      });
      final failed = await gateway.snapshot();
      expect(failed.state, HostState.failed);
      expect(failed.error!.code, HostErrorCode.portInUse);
      expect(failed.selections, isEmpty);
    },
  );

  test(
    'snapshot keeps actual activity separate from missing old fields',
    () async {
      transport.answers['snapshot'] = (_) => _ok({
        'state': 'running',
        'proxyActive': true,
        'tailnetActive': false,
        'tunActive': false,
        'systemProxyActive': false,
        'clashApiListen': '127.0.0.1:9090',
      });
      final running = await gateway.snapshot();
      expect(
        (
          running.proxyActive,
          running.tailnetActive,
          running.tunActive,
          running.systemProxyActive,
        ),
        (true, false, false, false),
      );
      expect(running.clashApiListen, '127.0.0.1:9090');

      transport.answers['snapshot'] = (_) => _ok({
        'state': 'stopped',
        'proxyActive': false,
        'tailnetActive': false,
        'tunActive': false,
        'systemProxyActive': false,
        'clashApiListen': '',
      });
      final stopped = await gateway.snapshot();
      expect(stopped.proxyActive, isFalse);
      expect(stopped.tunActive, isFalse);
      expect(stopped.clashApiListen, isEmpty);
    },
  );

  test('a host that cannot be reached is its own kind of error', () async {
    transport.answers['snapshot'] = (_) => Exception('service not bound');
    await expectLater(
      gateway.snapshot(),
      throwsA(
        isA<HostException>().having(
          (e) => e.error.code,
          'code',
          HostErrorCode.unreachable,
        ),
      ),
    );
    transport.answers['snapshot'] = (_) => 'not json';
    await expectLater(gateway.snapshot(), throwsA(isA<HostException>()));
  });

  group('when the wait runs out the host is asked, not told again', () {
    Completer<String> never() => Completer<String>();

    test('the command had finished', () async {
      transport.answers['start'] = (_) => never().future;
      transport.answers['queryCommand'] = (request) {
        expect(request['requestId'], 'r0');
        return _ok({
          'status': 'done',
          'result': {'sessionId': 'late'},
        });
      };
      final session = await gateway.start(planPath: '/p', planHash: 'h');
      expect(session.sessionId, 'late');
      expect([for (final s in transport.sent) s.$1], ['start', 'queryCommand']);
    });

    test('a native IPC timeout also queries the original command', () async {
      transport.answers['reload'] = (_) => const HostException(
        HostError(HostErrorCode.timeout, 'provider message did not arrive'),
      );
      transport.answers['queryCommand'] = (request) {
        expect(request, {'requestId': 'r0'});
        return _ok({
          'status': 'done',
          'result': {'sessionId': 'new-session', 'method': 'restart'},
        });
      };
      final session = await gateway.reload(
        sessionId: 'old-session',
        planPath: '/p',
        planHash: 'h',
      );
      expect((session.sessionId, session.restarted), ('new-session', true));
      expect(transport.sent.map((s) => s.$1), ['reload', 'queryCommand']);
      expect(ids, 1);
    });

    test('a native timeout recovers the actual rejected plan error', () async {
      transport.answers['start'] = (_) => const HostException(
        HostError(HostErrorCode.timeout, 'provider message did not arrive'),
      );
      transport.answers['queryCommand'] = (request) {
        expect(request, {'requestId': 'r0'});
        return _ok({
          'status': 'failed',
          'error': {
            'code': 'PLAN_INVALID',
            'message': 'invalid protected plan',
          },
        });
      };
      await expectLater(
        gateway.start(planPath: '/p', planHash: 'h'),
        throwsA(
          isA<HostException>()
              .having((e) => e.error.code, 'code', HostErrorCode.planInvalid)
              .having(
                (e) => e.error.message,
                'message',
                'invalid protected plan',
              ),
        ),
      );
      expect(transport.sent.map((s) => s.$1), ['start', 'queryCommand']);
    });

    test('a real core timeout keeps its original cached failure', () async {
      const error = {
        'code': 'TIMEOUT',
        'message': 'the download did not finish in time',
        'detail': 'context deadline exceeded',
      };
      transport.answers['fetch'] = (_) => jsonEncode({'error': error});
      transport.answers['queryCommand'] = (request) {
        expect(request, {'requestId': 'r0'});
        return _ok({'status': 'failed', 'error': error});
      };
      await expectLater(
        gateway.fetch(
          sessionId: 's',
          outboundTag: 'g',
          url: 'https://example.com/rules.srs',
          maxBytes: 1024,
        ),
        throwsA(
          isA<HostException>()
              .having((e) => e.error.code, 'code', HostErrorCode.timeout)
              .having((e) => e.error.message, 'message', error['message'])
              .having((e) => e.error.detail, 'detail', error['detail']),
        ),
      );
      expect(transport.sent.map((s) => s.$1), ['fetch', 'queryCommand']);
    });

    test('still running or unknown: a timeout, and no second start', () async {
      for (final status in ['pending', 'unknown']) {
        transport.sent.clear();
        transport.answers['start'] = (_) => never().future;
        transport.answers['queryCommand'] = (_) => _ok({'status': status});
        await expectLater(
          gateway.start(planPath: '/p', planHash: 'h'),
          throwsA(
            isA<HostException>().having(
              (e) => e.error.code,
              'code',
              HostErrorCode.timeout,
            ),
          ),
        );
        expect(transport.sent.where((s) => s.$1 == 'start'), hasLength(1));
      }
    });
  });
}
