import 'dart:convert';
import 'dart:io';

import 'package:avalon/app/services.dart';
import 'package:avalon/data/database/database.dart';
import 'package:avalon/data/vault/vault.dart';
import 'package:avalon/runtime/host/windows_host.dart';
import 'package:avalon/runtime/host_gateway.dart';
import 'package:avalon/runtime/host_protocol.dart';
import 'package:avalon/runtime/runtime_host.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late _Backend backend;
  late WindowsHost host;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('avalon-windows-host-');
    backend = _Backend(directory.path);
    await Directory(backend.info.userStateDir).create(recursive: true);
    await Directory(backend.info.serviceStateDir).create(recursive: true);
    host = WindowsHost(backend: backend);
  });

  tearDown(() => directory.delete(recursive: true));

  test('UAC refusal preserves the current host and running session', () async {
    backend.userSession = 'user-session';
    backend.installAllowed = false;
    expect(await host.prepare(tun: true), isFalse);
    final snapshot = await HostGateway(host).snapshot();
    expect(snapshot.sessionId, 'user-session');
    expect(backend.userSession, 'user-session');
    expect(backend.events, isNot(contains('user:stop')));
    expect((await host.facts()).stateDir, backend.info.userStateDir);
  });

  test(
    'a rejected TUN candidate leaves the previous session running',
    () async {
      backend.userSession = 'user-session';
      expect(await host.prepare(tun: true), isTrue);
      expect((await host.facts()).stateDir, backend.info.serviceStateDir);
      backend.rejectCandidate = true;
      await expectLater(
        HostGateway(host).reload(
          sessionId: 'user-session',
          planPath: '${backend.info.serviceStateDir}/plan.next.json',
          planHash: 'candidate',
        ),
        throwsA(_code(HostErrorCode.planInvalid)),
      );
      expect(backend.userSession, 'user-session');
      expect(backend.events, isNot(contains('user:stop')));
      expect((await host.facts()).stateDir, backend.info.userStateDir);
    },
  );

  test(
    'TUN migration checks first, stops once and preserves private state',
    () async {
      backend.userSession = 'user-session';
      await host.prepare(tun: true);
      expect(backend.userSession, 'user-session');
      backend.events.clear();
      final next = await HostGateway(host).reload(
        sessionId: 'user-session',
        planPath: '${backend.info.serviceStateDir}/plan.next.json',
        planHash: 'tun',
      );
      expect(next.sessionId, 'service-session');
      expect(next.restarted, isTrue);
      expect(backend.userSession, isEmpty);
      expect(backend.importedState, backend.exportedState);
      expect(backend.events, [
        'service:capabilities',
        'service:hostCheckPlan',
        'user:snapshot',
        'user:stop',
        'user:hostExportState',
        'service:hostImportState',
        'user:hostShutdown',
        'service:start',
      ]);
      expect(backend.startRequest?['sessionId'], isNull);
      expect(backend.startRequest?['planHash'], 'tun');
    },
  );

  test('turning TUN off migrates to the ordinary helper', () async {
    backend.installed = true;
    backend.serviceRunning = true;
    backend.serviceSession = 'service-session';
    await host.prepare(tun: false);
    expect((await host.facts()).stateDir, backend.info.userStateDir);
    expect(backend.serviceSession, 'service-session');
    await HostGateway(host).reload(
      sessionId: 'service-session',
      planPath: '${backend.info.userStateDir}/plan.next.json',
      planHash: 'ports-only',
    );
    expect(backend.userSession, 'user-session');
    expect(backend.serviceSession, isEmpty);
    expect(
      backend.events.indexOf('user:hostCheckPlan'),
      lessThan(backend.events.indexOf('service:stop')),
    );
  });

  test(
    'reopening attaches to a running service without starting a user host',
    () async {
      backend.installed = true;
      backend.serviceRunning = true;
      backend.userAvailable = false;
      backend.serviceSession = 'existing';
      expect((await HostGateway(host).snapshot()).sessionId, 'existing');
      expect(backend.events, isNot(contains('start-user')));
      expect((await host.facts()).stateDir, backend.info.serviceStateDir);
    },
  );

  test('untrusted service does not fall back to an ordinary helper', () async {
    backend.installed = true;
    backend.serviceRunning = true;
    backend.userAvailable = false;
    backend.untrustedService = true;
    await expectLater(
      HostGateway(host).snapshot(),
      throwsA(_code(HostErrorCode.permissionDenied)),
    );
    expect(backend.events, isNot(contains('start-user')));
  });

  test('two active hosts are reported rather than selecting one', () async {
    backend.userSession = 'user-session';
    backend.serviceSession = 'service-session';
    backend.serviceRunning = true;
    await expectLater(
      HostGateway(host).snapshot(),
      throwsA(_code(HostErrorCode.sessionMismatch)),
    );
    expect(backend.events, isNot(contains('user:stop')));
    expect(backend.events, isNot(contains('service:stop')));
  });

  test('failure after migration leaves a real stopped session', () async {
    backend.userSession = 'user-session';
    await host.prepare(tun: true);
    backend.failImport = true;
    await expectLater(
      HostGateway(host).reload(
        sessionId: 'user-session',
        planPath: '${backend.info.serviceStateDir}/plan.next.json',
        planHash: 'tun',
      ),
      throwsA(_code(HostErrorCode.coreFailed)),
    );
    expect(backend.userSession, isEmpty);
    expect(backend.serviceSession, isEmpty);
    expect((await HostGateway(host).snapshot()).state, HostState.stopped);
    expect(backend.events.where((e) => e == 'user:start'), isEmpty);
  });

  test('a lost start reply recovers without a second start', () async {
    backend.userSession = 'user-session';
    await host.prepare(tun: true);
    backend.loseStartReply = true;
    final session = await HostGateway(host).reload(
      sessionId: 'user-session',
      planPath: '${backend.info.serviceStateDir}/plan.next.json',
      planHash: 'tun',
    );
    expect(session.sessionId, 'service-session');
    expect(session.restarted, isTrue);
    expect(backend.events.where((e) => e == 'service:start').length, 1);
    expect(backend.events, contains('service:queryCommand'));
  });

  test(
    'an absent ordinary helper can be restarted without reopening the app',
    () async {
      await host.prepare(tun: false);
      backend.userAvailable = false;
      backend.events.clear();
      expect(await host.prepare(tun: false), isTrue);
      expect(backend.events.where((event) => event == 'start-user').length, 1);
      expect((await HostGateway(host).snapshot()).state, HostState.stopped);
    },
  );

  test('updating an active service preserves its accepted session', () async {
    backend.installed = true;
    backend.serviceRunning = true;
    backend.serviceSession = 'accepted';
    backend.updateRequired = true;
    await expectLater(
      host.prepare(tun: true),
      throwsA(_code(HostErrorCode.coreFailed)),
    );
    expect(backend.serviceSession, 'accepted');
    expect(backend.events, isNot(contains('install')));
    expect(backend.events, isNot(contains('service:stop')));
  });

  test(
    'an idle outdated service is stopped and updated before reuse',
    () async {
      backend.installed = true;
      backend.serviceRunning = true;
      backend.updateRequired = true;
      expect(await host.prepare(tun: true), isTrue);
      expect(
        backend.events.indexOf('service:hostShutdown'),
        lessThan(backend.events.indexOf('install')),
      );
      expect(backend.updateRequired, isFalse);
      expect(
        backend.events.indexOf('install'),
        lessThan(backend.events.indexOf('start-service')),
      );
    },
  );

  test(
    'an incompatible helper receives no plan and its session can still stop',
    () async {
      backend.userSession = 'accepted';
      backend.protocolVersion = 2;
      await expectLater(
        HostGateway(host).reload(
          sessionId: 'accepted',
          planPath: '${backend.info.userStateDir}/plan.next.json',
          planHash: 'new',
        ),
        throwsA(_code(HostErrorCode.unsupported)),
      );
      expect(backend.userSession, 'accepted');
      expect(backend.events, isNot(contains('user:reload')));
      await HostGateway(host).stop();
      expect(backend.userSession, isEmpty);
    },
  );

  test('release does not stop an active host', () async {
    backend.userSession = 'active';
    await HostGateway(host).snapshot();
    await host.release();
    expect(backend.userSession, 'active');
    expect(backend.events, isNot(contains('user:hostShutdown')));
  });

  test(
    'compilation and runtime share the prepared Windows directory',
    () async {
      final runtime = RuntimeHost(transport: host, system: host);
      final app = await AppServices.open(
        database: AppDatabase(NativeDatabase.memory()),
        keyStore: MemoryKeyStore(),
        runtimeHost: runtime,
      );
      addTearDown(app.close);
      await host.prepare(tun: true);
      expect((await app.plans.host()).stateDir, backend.info.serviceStateDir);
    },
  );

  test(
    'the last service state is retained after an idle app restart',
    () async {
      backend.userSession = 'user-session';
      await host.prepare(tun: true);
      await HostGateway(host).reload(
        sessionId: 'user-session',
        planPath: '${backend.info.serviceStateDir}/plan.next.json',
        planHash: 'tun',
      );
      await HostGateway(host).stop();
      final reopened = WindowsHost(backend: backend);
      expect((await reopened.facts()).stateDir, backend.info.serviceStateDir);
    },
  );

  test(
    'shutdown lost acknowledgement routes future calls to the new host',
    () async {
      backend.userSession = 'user-session';
      await host.prepare(tun: true);
      backend.loseShutdownReply = true;
      await expectLater(
        HostGateway(host).reload(
          sessionId: 'user-session',
          planPath: '${backend.info.serviceStateDir}/plan.next.json',
          planHash: 'tun',
        ),
        throwsA(_code(HostErrorCode.timeout)),
      );
      expect((await HostGateway(host).snapshot()).state, HostState.stopped);
      expect((await host.facts()).stateDir, backend.info.serviceStateDir);
      expect(backend.importedState, backend.exportedState);
    },
  );
}

Matcher _code(HostErrorCode code) =>
    isA<HostException>().having((error) => error.error.code, 'code', code);

final class _Backend implements WindowsHostBackend {
  _Backend(this.root);
  final String root;
  final events = <String>[];
  bool installed = false, serviceRunning = false, userAvailable = true;
  bool updateRequired = false;
  int protocolVersion = 1;
  bool installAllowed = true, rejectCandidate = false;
  bool untrustedService = false, failImport = false;
  bool loseShutdownReply = false, loseStartReply = false;
  String userSession = '', serviceSession = '';
  Map<String, Object?>? importedState, startRequest;
  final exportedState = <String, Object?>{
    'version': 1,
    'files': {
      'tailscale/tailscaled.state': base64Encode(
        utf8.encode('private-identity'),
      ),
    },
  };

  WindowsHostInfo get info => WindowsHostInfo.fromJson({
    'sid': 'S-1-5-21-123',
    'userStateDir': '$root/user',
    'serviceStateDir': '$root/service',
    'userPipe': r'\\.\pipe\Avalon-user',
    'servicePipe': r'\\.\pipe\Avalon-service',
    'serviceName': 'AvalonHelper_S-1-5-21-123',
    'executablePath': r'C:\Program Files\Avalon\helper\avalon-helper.exe',
    'userExecutablePath': r'C:\Avalon\avalon-helper.exe',
    'installed': installed,
    'serviceRunning': serviceRunning,
    'updateRequired': updateRequired,
  });

  @override
  Future<WindowsHostInfo> inspect() async => info;

  @override
  Future<bool> install(WindowsHostInfo info) async {
    events.add('install');
    if (!installAllowed) return false;
    installed = true;
    updateRequired = false;
    return true;
  }

  @override
  Future<void> startService(WindowsHostInfo info) async {
    events.add('start-service');
    serviceRunning = true;
  }

  @override
  Future<void> startUser(WindowsHostInfo info) async {
    events.add('start-user');
    userAvailable = true;
  }

  @override
  Future<String> exchange(
    WindowsHostInfo info,
    bool service,
    String command,
    Map<String, Object?> request,
  ) async {
    events.add('${service ? 'service' : 'user'}:$command');
    if (service && untrustedService) {
      throw const HostException(
        HostError(HostErrorCode.permissionDenied, 'Untrusted server.'),
      );
    }
    if (service ? !serviceRunning : !userAvailable) {
      throw const HostException(
        HostError(HostErrorCode.unreachable, 'No host.'),
      );
    }
    final session = service ? serviceSession : userSession;
    Map<String, Object?> result = {};
    switch (command) {
      case 'snapshot':
        result = {
          'state': session.isEmpty ? 'stopped' : 'running',
          'sessionId': session,
        };
      case 'capabilities':
        result = {
          'protocolVersion': protocolVersion,
          'coreVersion': 'real-test-contract',
          'tun': service,
        };
      case 'hostCheckPlan':
        if (rejectCandidate) {
          return jsonEncode({
            'error': {'code': 'PLAN_INVALID', 'message': 'Invalid candidate.'},
          });
        }
      case 'stop':
        if (service) {
          serviceSession = '';
        } else {
          userSession = '';
        }
      case 'hostExportState':
        result = exportedState;
      case 'hostShutdown':
        if (service) {
          serviceRunning = false;
        } else {
          userAvailable = false;
        }
        if (loseShutdownReply) {
          throw const HostException(
            HostError(HostErrorCode.timeout, 'Lost reply.'),
          );
        }
      case 'hostImportState':
        if (failImport) {
          return jsonEncode({
            'error': {'code': 'CORE_FAILED', 'message': 'Import failed.'},
          });
        }
        importedState = request;
      case 'start':
        expect(
          service ? userSession : serviceSession,
          isEmpty,
          reason: 'Only one Windows engine may own a session.',
        );
        startRequest = request;
        if (service) {
          serviceSession = 'service-session';
        } else {
          userSession = 'user-session';
        }
        result = {'sessionId': service ? serviceSession : userSession};
        if (loseStartReply) {
          throw const HostException(
            HostError(HostErrorCode.timeout, 'Lost start reply.'),
          );
        }
      case 'queryCommand':
        result =
            request['requestId'] == startRequest?['requestId'] &&
                session.isNotEmpty
            ? {
                'status': 'done',
                'result': {'sessionId': session},
              }
            : {'status': 'unknown'};
    }
    return jsonEncode({'result': result});
  }
}
