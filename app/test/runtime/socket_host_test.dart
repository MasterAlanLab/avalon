// The desktop helper through its Unix socket (RUNTIME_HOST §8, spike S4):
// the real helper, started by the transport when nothing answers. Needs the
// helper built for this machine:
//
//   (cd core && go build -tags "$(cat BUILD_TAGS)" -ldflags -checklinkname=0 \
//       -o out/avalon-helper ./cmd/avalon-helper)
//   AVALON_HELPER=$PWD/core/out/avalon-helper flutter test test/runtime/socket_host_test.dart
@TestOn('linux || mac-os')
library;

import 'dart:convert';
import 'dart:io';

import 'package:avalon/runtime/host/socket_host.dart';
import 'package:avalon/runtime/host_gateway.dart';
import 'package:avalon/runtime/host_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Linux selects the installed capable helper before user bundles', () {
    const bundle = '/home/test/avalon/avalon';
    final candidates = <String>[];
    final resolved = SocketHost.findLinuxHelper(
      environment: const {},
      executablePath: bundle,
      fileExists: (path) {
        candidates.add(path);
        return true;
      },
    );
    expect(resolved, '/usr/lib/avalon/avalon-helper');
    expect(candidates, [SocketHost.installedLinuxHelperPath]);
  });

  test(
    'Linux retains explicit development override and unprivileged fallback',
    () {
      expect(
        SocketHost.findLinuxHelper(
          environment: const {'AVALON_HELPER': '/dev/helper'},
          executablePath: '/home/test/avalon/avalon',
          fileExists: (_) => throw StateError('override must be explicit'),
        ),
        '/dev/helper',
      );
      expect(
        SocketHost.findLinuxHelper(
          environment: const {},
          executablePath: '/home/test/avalon/avalon',
          fileExists: (path) => path == '/home/test/avalon/lib/avalon-helper',
        ),
        '/home/test/avalon/lib/avalon-helper',
      );
      expect(
        SocketHost.findLinuxHelper(
          environment: const {'AVALON_HELPER': ''},
          executablePath: '/home/test/avalon/avalon',
          fileExists: (_) => false,
        ),
        isNull,
      );
    },
  );

  final helper = Platform.environment['AVALON_HELPER'];
  late Directory dir;
  late SocketHost host;

  setUp(() async {
    // Socket paths are short (104 bytes on macOS).
    dir = await Directory('/tmp').createTemp('avs');
    host = SocketHost(
      socketPath: '${dir.path}/run/host.sock',
      stateDir: '${dir.path}/state',
      helperPath: helper,
      deviceName: 'test',
    );
  });

  tearDown(() async {
    // Only the helper this test started: matched by its socket path.
    await Process.run('pkill', ['-f', host.socketPath]);
    await dir.delete(recursive: true);
  });

  test(
    'starts the helper, runs a plan and stops it',
    () async {
      final gateway = HostGateway(host);
      final facts = await host.facts();
      // Ports only: no consent needed.
      expect(await host.prepare(tun: false), isTrue);

      final port = await (() async {
        final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
        final p = probe.port;
        await probe.close();
        return p;
      })();
      final plan = File('${facts.stateDir}/plan.json');
      await plan.writeAsString(
        jsonEncode({
          'log': {'level': 'info'},
          'inbounds': [
            {
              'type': 'mixed',
              'tag': 'mixed-in',
              'listen': '127.0.0.1',
              'listen_port': port,
            },
          ],
          'outbounds': [
            {'type': 'direct', 'tag': 'direct'},
          ],
        }),
      );
      final capabilities = await gateway.capabilities();
      expect(capabilities.protocolVersion, 1);
      expect(capabilities.coreVersion, isNotEmpty);
      final session = await gateway.start(planPath: plan.path, planHash: 'h');
      expect(session.sessionId, isNotEmpty);
      final running = await gateway.snapshot();
      expect(running.state, HostState.running);
      expect(running.planHash, 'h');
      expect(running.proxyActive, isTrue);
      expect(running.tunActive, isFalse);
      expect(running.systemProxyActive, isFalse);
      expect(running.tailnetActive, isFalse);
      expect(running.clashApiListen, isEmpty);
      // The mixed port answers.
      final socket = await Socket.connect(InternetAddress.loopbackIPv4, port);
      socket.destroy();

      await gateway.stop();
      final stopped = await gateway.snapshot();
      expect(stopped.state, HostState.stopped);
      expect(stopped.proxyActive, isFalse);

      // A new connection to the helper that keeps running.
      final again = SocketHost(
        socketPath: host.socketPath,
        stateDir: host.stateDir,
        helperPath: null,
      );
      expect(
        (await HostGateway(again).capabilities()).platform,
        capabilities.platform,
      );
    },
    skip: helper == null ? 'AVALON_HELPER is not set' : false,
  );

  test('without a helper the host is unreachable', () async {
    final none = SocketHost(
      socketPath: '${dir.path}/none.sock',
      stateDir: '${dir.path}/state',
      helperPath: null,
    );
    await expectLater(
      HostGateway(none).capabilities(),
      throwsA(
        isA<HostException>().having(
          (e) => e.error.code,
          'code',
          HostErrorCode.unreachable,
        ),
      ),
    );
  });
}
