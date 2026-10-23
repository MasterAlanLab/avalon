// A host with the Core Bridge's behaviour and none of its work, for tests
// of what sits above the gateway.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:av_core/av_core.dart';
import 'package:avalon/runtime/host_gateway.dart';
import 'package:avalon/runtime/runtime_host.dart';

/// A host with the bridge's behaviour and none of its work.
final class FakeHost implements HostTransport, HostSystem {
  FakeHost(this.stateDir);

  final String stateDir;
  final commands = <(String, Map<String, Object?>)>[];
  var state = 'stopped';
  var sessionId = '';
  var planHash = '';
  var revision = 0;
  var sessions = 0;
  var downBps = 0;
  var released = 0;
  var mode = '';
  var selections = <String, String>{};
  var clashApiListen = '';
  bool? proxyActive;
  bool? tailnetActive;
  Map<String, Object?>? startError;
  Map<String, Object?>? stopError;
  Map<String, Object?>? snapshotError;
  Map<String, Object?>? snapshotCallError;

  /// Answers the next reload instead of doing it; [reloadKills] says
  /// whether the session died of it.
  Map<String, Object?>? reloadError;
  bool reloadKills = false;

  void _run(Map<String, Object?> request) {
    final plan =
        (jsonDecode(File(request['planPath']! as String).readAsStringSync())
                as Map)
            .cast<String, Object?>();
    final choices = PlanChoices.of(plan);
    proxyActive = (plan['inbounds'] as List? ?? const []).any(
      (i) => i is Map && ['mixed', 'socks', 'http'].contains(i['type']),
    );
    tailnetActive = (plan['endpoints'] as List? ?? const []).any(
      (e) => e is Map && e['type'] == 'tailscale',
    );
    final experimental = plan['experimental'];
    final clashApi = experimental is Map ? experimental['clash_api'] : null;
    clashApiListen = clashApi is Map
        ? clashApi['external_controller'] as String? ?? ''
        : '';
    state = 'running';
    sessionId = 's${++sessions}';
    planHash = request['planHash']! as String;
    mode = choices.mode ?? '';
    selections = {...choices.selections};
  }

  /// The host's log buffer, oldest first, as the bridge sends entries.
  var logs = <Map<String, Object?>>[];
  var droppedLogs = 0;

  /// What a download through the proxy gets, by address.
  var fetchBodies = <String, List<int>>{};

  /// The running session's connections, as the bridge sends them.
  var connections = <Map<String, Object?>>[];

  /// What a latency test answers per tag; a tag not listed times out.
  var latencies = <String, Map<String, Object?>>{};

  /// Holds latency tests until completed, to let a newer one overtake.
  Completer<void>? holdTests;

  /// Completes [prepare]; granted at once unless a test holds it.
  Completer<bool>? consent;
  bool granted = true;
  bool? askedForTun;

  @override
  Future<String> call(String command, String request) async {
    final decoded = (jsonDecode(request) as Map).cast<String, Object?>();
    commands.add((command, decoded));
    Object? result;
    switch (command) {
      case 'capabilities':
        result = {
          'protocolVersion': 1,
          'coreVersion': '1.14.2',
          'platform': 't',
        };
      case 'start':
        if (startError != null) {
          state = 'failed';
          return jsonEncode({'error': startError});
        }
        _run(decoded);
        result = {'sessionId': sessionId};
      case 'reload':
        if (reloadError != null) {
          if (reloadKills) {
            state = 'failed';
            sessionId = '';
          }
          return jsonEncode({'error': reloadError});
        }
        _run(decoded);
        result = {'sessionId': sessionId, 'method': 'restart'};
      case 'urlTest':
        if (holdTests case final gate?) await gate.future;
        result = {
          'results': {
            for (final tag in (decoded['tags']! as List).cast<String>())
              tag: latencies[tag] ?? {'error': 'timeout'},
          },
        };
      case 'logs':
        final after = (decoded['afterSeq']! as num).toInt();
        final page = [
          for (final entry in logs)
            if ((entry['seq']! as num).toInt() > after) entry,
        ];
        result = {
          'entries': page,
          'nextSeq': page.isEmpty
              ? (logs.isEmpty ? 0 : logs.last['seq'])
              : page.last['seq'],
          'dropped': droppedLogs,
        };
      case 'fetch':
        final body = fetchBodies[decoded['url']];
        if (body == null) {
          result = {'status': 404, 'size': 0};
        } else if (decoded['destPath'] case final String path) {
          await File(path).writeAsBytes(body);
          result = {'status': 200, 'size': body.length};
        } else {
          result = {
            'status': 200,
            'size': body.length,
            'body': utf8.decode(body),
          };
        }
      case 'connections':
        result = {'connections': connections};
      case 'closeConnection':
        connections.removeWhere((c) => c['id'] == decoded['id']);
      case 'closeAllConnections':
        connections.clear();
      case 'setMode':
        mode = decoded['mode']! as String;
      case 'select':
        selections[decoded['groupTag']! as String] =
            decoded['memberTag']! as String;
      case 'stop':
        if (stopError != null) return jsonEncode({'error': stopError});
        state = 'stopped';
        sessionId = '';
        planHash = '';
      case 'snapshot':
        if (snapshotCallError != null) {
          return jsonEncode({'error': snapshotCallError});
        }
        result = {
          'sessionId': sessionId,
          'revision': ++revision,
          'state': state,
          'proxyActive': ?proxyActive,
          'tailnetActive': ?tailnetActive,
          'clashApiListen': state == 'running' ? clashApiListen : '',
          if (state == 'running') ...{
            'planHash': planHash,
            'mode': mode,
            'selections': selections,
            'startedAt': 1791600000000,
            'downBps': downBps,
          },
          'todayDown': 4096,
          'error': ?snapshotError,
        };
    }
    return jsonEncode({'result': ?result});
  }

  @override
  Future<HostFacts> facts() async =>
      HostFacts(stateDir: stateDir, deviceName: 'test');

  @override
  Future<bool> prepare({required bool tun}) {
    askedForTun = tun;
    return consent?.future ?? Future.value(granted);
  }

  @override
  Future<void> release() async => released++;

  /// What [configure] was given, in order.
  final options = <HostOptions>[];

  @override
  Future<void> configure(HostOptions options) async =>
      this.options.add(options);

  List<String> get sent => [for (final c in commands) c.$1];
}
