// DEVELOPMENT ONLY: exercises the real iOS host on the simulator without
// requesting a VPN session. Build with -t gallery/ios_host_probe.dart.
// lib/main.dart never imports this entry point or its probe plan.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avalon/runtime/host/channel_host.dart';
import 'package:avalon/runtime/host_gateway.dart';
import 'package:avalon/runtime/host_protocol.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SizedBox.shrink());
  final summary = <String, Object?>{'ok': false};
  try {
    _require(kDebugMode && Platform.isIOS, 'debug iOS target required');
    await _probe(summary).timeout(const Duration(seconds: 60));
    summary['ok'] = true;
  } on HostException catch (error) {
    summary['failure'] = error.error.code.wire;
  } on TimeoutException {
    summary['failure'] = 'probe timed out';
  } on StateError catch (error) {
    // Assertion messages below are fixed labels, never native error text,
    // file paths, plan contents, account details or device names.
    summary['failure'] = error.message;
  } on Exception catch (error) {
    summary['failure'] = error.runtimeType.toString();
  }
  final encoded = jsonEncode(summary);
  await File(
    '${Directory.systemTemp.path}/avalon-ios-host-probe.json',
  ).writeAsString(encoded, flush: true);
  debugPrint('AVALON_IOS_HOST_PROBE $encoded');
}

Future<void> _probe(Map<String, Object?> summary) async {
  const host = ChannelHost();
  final gateway = HostGateway(host);
  File? plan;
  HttpServer? origin;
  ServerSocket? reservedPort;
  StreamSubscription<HttpRequest>? requests;
  var answered = 0;
  try {
    final facts = await host.facts();
    _require(
      Directory(facts.stateDir).isAbsolute,
      'host directory is absolute',
    );
    _require(
      await Directory(facts.stateDir).exists(),
      'host directory is present',
    );
    _require(
      (await Directory(facts.stateDir).stat()).mode & 0x1ff == 0x1c0,
      'host directory has private permissions',
    );
    summary['facts'] = {
      'directoryPresent': true,
      'directoryPrivate': true,
      'hasDeviceName': facts.deviceName.isNotEmpty,
    };

    final capabilities = await gateway.capabilities();
    _require(
      capabilities.protocolVersion == hostProtocolVersion,
      'protocol version matches',
    );
    _require(capabilities.platform == 'ios', 'native iOS host is present');
    _require(
      capabilities.coreVersion.isNotEmpty,
      'real core version is present',
    );
    summary['capabilities'] = {
      'platform': capabilities.platform,
      'protocolVersion': capabilities.protocolVersion,
      'coreVersion': capabilities.coreVersion,
    };

    final before = await gateway.snapshot();
    _idle(before);
    summary['before'] = _snapshot(before);

    origin = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    requests = origin.listen((request) {
      answered++;
      request.response.statusCode = HttpStatus.noContent;
      unawaited(request.response.close());
    });
    // Hold the plan's listening port throughout the probe: urlTest must
    // strip its inbound and controller rather than trying to bind them.
    reservedPort = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    plan = File(
      '${facts.stateDir}/ios-host-probe-${DateTime.now().microsecondsSinceEpoch}.json',
    );
    await plan.writeAsString(
      jsonEncode({
        'log': {'level': 'warn'},
        'inbounds': [
          {
            'type': 'mixed',
            'tag': 'probe-mixed',
            'listen': '127.0.0.1',
            'listen_port': reservedPort.port,
          },
        ],
        'outbounds': [
          {'type': 'direct', 'tag': 'probe-direct'},
        ],
        'route': {'final': 'probe-direct'},
        'experimental': {
          'clash_api': {
            'external_controller': '127.0.0.1:${reservedPort.port}',
          },
        },
      }),
      flush: true,
    );
    final latencies = await gateway.urlTest(
      planPath: plan.path,
      tags: const ['probe-direct'],
      url: 'http://127.0.0.1:${origin.port}/generate_204',
      timeout: const Duration(seconds: 5),
    );
    final latency = latencies['probe-direct'];
    _require(
      latency != null &&
          latency.error == null &&
          latency.delayMs != null &&
          latency.delayMs! > 0,
      'real direct probe answered',
    );
    _require(answered > 0, 'local HTTP origin received the probe');
    _require(
      (await plan.stat()).mode & 0x1ff == 0x180,
      'native host protects the submitted probe file',
    );
    summary['urlTest'] = {
      'delayMs': latency!.delayMs,
      'localOriginAnswered': true,
      'planListenersNotOpened': true,
      'planPrivate': true,
    };

    final after = await gateway.snapshot();
    _idle(after);
    summary['after'] = _snapshot(after);

    var unsupported = false;
    try {
      await host.prepare(tun: true);
    } on HostException catch (error) {
      unsupported = error.error.code == HostErrorCode.unsupported;
    }
    _require(unsupported, 'simulator prepare returns UNSUPPORTED');
    summary['prepare'] = 'UNSUPPORTED';
  } finally {
    await requests?.cancel();
    await origin?.close(force: true);
    await reservedPort?.close();
    if (plan != null && await plan.exists()) await plan.delete();
    await host.release();
  }
}

void _idle(HostSnapshot snapshot) {
  _require(snapshot.state == HostState.stopped, 'host remains stopped');
  _require(snapshot.sessionId.isEmpty, 'no VPN session was created');
  _require(
    snapshot.proxyActive == false &&
        snapshot.tunActive == false &&
        snapshot.systemProxyActive == false &&
        snapshot.tailnetActive == false,
    'host reports no active proxy or tunnel',
  );
}

Map<String, Object?> _snapshot(HostSnapshot snapshot) => {
  'state': snapshot.state.name,
  'hasSession': snapshot.sessionId.isNotEmpty,
  'proxyActive': snapshot.proxyActive,
  'tunActive': snapshot.tunActive,
  'systemProxyActive': snapshot.systemProxyActive,
  'tailnetActive': snapshot.tailnetActive,
};

void _require(bool condition, String label) {
  if (!condition) throw StateError(label);
}
