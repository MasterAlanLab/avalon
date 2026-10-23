import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../host_gateway.dart';
import '../host_protocol.dart';
import '../runtime_host.dart';
import 'windows_native.dart';

/// Windows owns two hosts: an ordinary process and a per-user TUN service.
/// Preparing a different host does not interrupt the accepted session. The
/// candidate is checked before that session is stopped and its state moved.
final class WindowsHost implements HostTransport, HostSystem {
  WindowsHost({required this.backend});

  factory WindowsHost.native() => WindowsHost(backend: WindowsProcessBackend());

  final WindowsHostBackend backend;
  WindowsHostInfo? _info;
  bool? _service;
  bool? _preparedService;
  Future<void>? _initializing;
  Future<void> _turn = Future.value();
  final _migrations = <String, Map<String, Object?>>{};
  int _migrating = 0;

  Future<T> _exclusive<T>(Future<T> Function() action) {
    final next = _turn.then((_) async {
      try {
        return await action();
      } on FileSystemException {
        throw const HostException(
          HostError(
            HostErrorCode.coreFailed,
            'The Windows host state could not be saved.',
          ),
        );
      }
    });
    _turn = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  Future<void> _initialize() =>
      _initializing ??= _discover().whenComplete(() => _initializing = null);

  Future<void> _discover() async {
    if (_service != null) return;
    final info = _info = await backend.inspect();
    Map<String, Object?>? user;
    try {
      user = _result(await backend.exchange(info, false, 'snapshot', const {}));
    } on HostException catch (error) {
      if (error.error.code != HostErrorCode.unreachable) rethrow;
    }
    Map<String, Object?>? service;
    if (info.serviceRunning) {
      // An existing service that cannot be authenticated must not cause a
      // second, unprivileged host to be started instead.
      service = _result(
        await backend.exchange(info, true, 'snapshot', const {}),
      );
    }
    if (_active(user) && _active(service)) {
      throw const HostException(
        HostError(
          HostErrorCode.sessionMismatch,
          'Two Windows hosts have active sessions; stop one before continuing.',
        ),
      );
    }
    final remembered = File('${info.userStateDir}/host-location.json');
    var rememberedService = false;
    if (await remembered.exists() && await remembered.length() <= 64) {
      try {
        final value = jsonDecode(await remembered.readAsString());
        rememberedService = value is Map && value['service'] == true;
      } on FormatException {
        throw const HostException(
          HostError(
            HostErrorCode.coreFailed,
            'The Windows host location is invalid.',
          ),
        );
      }
    }
    final selected = _active(service) || (!_active(user) && rememberedService);
    if (selected && service == null) {
      if (!info.installed) {
        throw const HostException(
          HostError(
            HostErrorCode.unreachable,
            'The previously used Windows service is not installed.',
          ),
        );
      }
      await backend.startService(info);
      await _waitForHost(info, true);
    } else if (!selected && user == null) {
      await backend.startUser(info);
      await _waitForHost(info, false);
    }
    // A failed start must leave discovery retryable.
    _service = selected;
  }

  static bool _active(Map<String, Object?>? snapshot) =>
      snapshot != null &&
      const {
        'starting',
        'running',
        'reloading',
        'stopping',
      }.contains(snapshot['state']);

  Future<Map<String, Object?>> _waitForHost(
    WindowsHostInfo info,
    bool service,
  ) async {
    final until = DateTime.now().add(const Duration(seconds: 10));
    while (true) {
      try {
        return await _requireProtocol(info, service);
      } on HostException catch (error) {
        if (error.error.code != HostErrorCode.unreachable ||
            DateTime.now().isAfter(until)) {
          rethrow;
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
  }

  Future<Map<String, Object?>> _requireProtocol(
    WindowsHostInfo info,
    bool service,
  ) async {
    final capabilities = _result(
      await backend.exchange(info, service, 'capabilities', const {}),
    );
    if (capabilities['protocolVersion'] != hostProtocolVersion) {
      throw const HostException(
        HostError(
          HostErrorCode.unsupported,
          'The Windows helper protocol is incompatible; update the helper before connecting.',
        ),
      );
    }
    return capabilities;
  }

  static Map<String, Object?> _result(String reply) {
    final Object? decoded;
    try {
      decoded = jsonDecode(reply);
    } on FormatException {
      throw const HostException(
        HostError(
          HostErrorCode.unreachable,
          'The Windows host reply is invalid.',
        ),
      );
    }
    if (decoded is Map && decoded['error'] is Map) {
      throw HostException(HostError.fromJson((decoded['error'] as Map).cast()));
    }
    if (decoded is! Map || decoded['result'] is! Map) {
      throw const HostException(
        HostError(
          HostErrorCode.unreachable,
          'The Windows host returned no result.',
        ),
      );
    }
    return (decoded['result'] as Map).cast<String, Object?>();
  }

  @override
  Future<bool> prepare({required bool tun}) => _exclusive(() async {
    await _initialize();
    var info = await backend.inspect();
    if (tun && (!info.installed || info.updateRequired)) {
      if (info.updateRequired && info.serviceRunning) {
        final snapshot = _result(
          await backend.exchange(info, true, 'snapshot', const {}),
        );
        if (_active(snapshot)) {
          throw const HostException(
            HostError(
              HostErrorCode.coreFailed,
              'Stop the active Windows tunnel before updating its service.',
            ),
          );
        }
        _result(await backend.exchange(info, true, 'hostShutdown', const {}));
        final until = DateTime.now().add(const Duration(seconds: 10));
        do {
          info = await backend.inspect();
          if (!info.serviceRunning) break;
          if (DateTime.now().isAfter(until)) {
            throw const HostException(
              HostError(
                HostErrorCode.timeout,
                'The Windows service did not stop for its update.',
              ),
            );
          }
          await Future<void>.delayed(const Duration(milliseconds: 100));
        } while (true);
      }
      if (!await backend.install(info)) return false;
      info = await backend.inspect();
      if (!info.installed || info.updateRequired) {
        throw const HostException(
          HostError(
            HostErrorCode.coreFailed,
            'The Windows service was not installed.',
          ),
        );
      }
    }
    if (tun) {
      if (!info.serviceRunning) await backend.startService(info);
    } else {
      try {
        _result(await backend.exchange(info, false, 'capabilities', const {}));
      } on HostException catch (error) {
        if (error.error.code != HostErrorCode.unreachable) rethrow;
        // Restart the same ordinary host after a crash. An authenticated
        // refusal must not be mistaken for an absent helper.
        await backend.startUser(info);
      }
    }
    _info = info;
    final capabilities = await _waitForHost(info, tun);
    if (tun && capabilities['tun'] != true) {
      throw const HostException(
        HostError(
          HostErrorCode.permissionDenied,
          'The Windows service cannot open TUN.',
        ),
      );
    }
    if (tun != _service) {
      await _copyRuleSets(info.directory(_service!), info.directory(tun));
    }
    _preparedService = tun;
    return true;
  });

  @override
  Future<HostFacts> facts() async {
    await _turn;
    await _initialize();
    return HostFacts(
      stateDir: _info!.directory(_preparedService ?? _service!),
      deviceName: Platform.localHostname,
    );
  }

  @override
  Future<String> call(String command, String request) async {
    final fields = (jsonDecode(request) as Map).cast<String, Object?>();
    if (command == 'queryCommand') {
      final migration = _migrations[fields['requestId']];
      if (migration != null) return jsonEncode({'result': migration});
    }
    if (command == 'snapshot' && _migrating > 0 && _service != null) {
      return backend.exchange(_info!, _service!, command, fields);
    }
    await _turn;
    await _initialize();
    if ((command == 'start' || command == 'reload') &&
        _preparedService != null &&
        _preparedService != _service) {
      final id = fields['requestId'] as String?;
      if (id != null) {
        if (_migrations.length >= 64) {
          _migrations.remove(_migrations.keys.first);
        }
        _migrations[id] = {'status': 'pending'};
      }
      _migrating++;
      return _exclusive(() async {
        try {
          final reply = await _migrateAndStart(command, fields);
          final result = _result(reply);
          if (id != null) {
            _migrations[id] = {'status': 'done', 'result': result};
          }
          return reply;
        } on HostException catch (error) {
          if (id != null) {
            if (error.error.code == HostErrorCode.timeout) {
              // The destination may have completed start after its reply was
              // lost. Let queryCommand reach its authoritative result cache.
              _migrations.remove(id);
            } else {
              _migrations[id] = {
                'status': 'failed',
                'error': {
                  'code': error.error.code.wire,
                  'message': error.error.message,
                },
              };
            }
          }
          rethrow;
        } on FileSystemException {
          if (id != null) {
            _migrations[id] = {
              'status': 'failed',
              'error': {
                'code': 'CORE_FAILED',
                'message': 'The Windows host state could not be saved.',
              },
            };
          }
          rethrow;
        } finally {
          _migrating--;
        }
      });
    }
    if (command == 'start' ||
        command == 'reload' ||
        (command == 'urlTest' && fields['planPath'] != null)) {
      await _requireProtocol(_info!, _service!);
    }
    return backend.exchange(_info!, _service!, command, fields);
  }

  Future<String> _migrateAndStart(
    String command,
    Map<String, Object?> request,
  ) async {
    final info = _info!;
    final previous = _service!;
    final target = _preparedService!;
    try {
      await _requireProtocol(info, target);
      // This also validates protected resource snapshots on the service side.
      _result(await backend.exchange(info, target, 'hostCheckPlan', request));
    } catch (_) {
      _preparedService = null;
      rethrow;
    }
    final snapshot = _result(
      await backend.exchange(info, previous, 'snapshot', const {}),
    );
    if (command == 'reload' && snapshot['sessionId'] != request['sessionId']) {
      _preparedService = null;
      throw const HostException(
        HostError(
          HostErrorCode.sessionMismatch,
          'The Windows session has changed.',
        ),
      );
    }
    final controls = HostGateway(
      _WindowsModeTransport(backend, info, previous),
    );
    await controls.stop();
    final state = _result(
      await backend.exchange(info, previous, 'hostExportState', const {}),
    );
    // Persist the state on the destination before giving up the source.
    // If this fails, the source still owns the last complete private state.
    _result(await backend.exchange(info, target, 'hostImportState', state));
    final marker = File('${info.userStateDir}/.host-location.json.tmp');
    await marker.writeAsString(jsonEncode({'service': target}), flush: true);
    await marker.rename('${info.userStateDir}/host-location.json');
    // From this point failures describe a stopped session on the new host.
    // Never revive the old host or substitute a direct connection.
    _service = target;
    _preparedService = null;
    _result(await backend.exchange(info, previous, 'hostShutdown', const {}));
    final start = Map<String, Object?>.of(request)..remove('sessionId');
    String response;
    try {
      response = await backend.exchange(info, target, 'start', start);
    } on HostException catch (error) {
      if (error.error.code != HostErrorCode.timeout) rethrow;
      final status = _result(
        await backend.exchange(info, target, 'queryCommand', {
          'requestId': start['requestId'],
        }),
      );
      if (status['status'] == 'done') {
        response = jsonEncode({'result': status['result']});
      } else if (status['status'] == 'failed') {
        throw HostException(
          HostError.fromJson((status['error'] as Map).cast()),
        );
      } else {
        rethrow;
      }
    }
    if (command == 'reload') {
      final result = _result(response);
      return jsonEncode({
        'result': {...result, 'method': 'restart'},
      });
    }
    return response;
  }

  // Desktop startup and proxy preferences are applied by DesktopShell and
  // DesktopProxyController; the Windows helper has no mobile host options.
  @override
  Future<void> configure(HostOptions options) async {}

  @override
  Future<void> release() => _exclusive(() async {
    if (_service == null) return;
    final info = _info!;
    final snapshot = _result(
      await backend.exchange(info, _service!, 'snapshot', const {}),
    );
    if (_active(snapshot)) return;
    _result(await backend.exchange(info, _service!, 'hostShutdown', const {}));
    _service = null;
    _preparedService = null;
  });

  /// The cache uses content-addressed names. Copy only verified resources
  /// as the ordinary user; plans and private engine state use the host IPC.
  static Future<void> _copyRuleSets(String source, String destination) async {
    final from = Directory('$source/rulesets');
    if (!await from.exists()) return;
    final to = Directory('$destination/rulesets');
    await to.create(recursive: true);
    final namePattern = RegExp(r'^([a-f0-9]{64})\.(srs|json)$');
    await for (final entry in from.list(followLinks: false)) {
      if (entry is! File) continue;
      final name = entry.uri.pathSegments.last;
      final match = namePattern.firstMatch(name);
      if (match == null || await entry.length() > 32 * 1024 * 1024) continue;
      final bytes = await entry.readAsBytes();
      if (bytes.length > 32 * 1024 * 1024 ||
          sha256.convert(bytes).toString() != match[1]) {
        continue;
      }
      final temp = File('${to.path}/.$name.migrating');
      await temp.writeAsBytes(bytes, flush: true);
      await temp.rename('${to.path}/$name');
    }
  }
}

final class WindowsHostInfo {
  WindowsHostInfo.fromJson(Map<String, Object?> json)
    : sid = _field(json, 'sid'),
      userStateDir = _field(json, 'userStateDir'),
      serviceStateDir = _field(json, 'serviceStateDir'),
      userPipe = _field(json, 'userPipe'),
      servicePipe = _field(json, 'servicePipe'),
      serviceName = _field(json, 'serviceName'),
      executablePath = _field(json, 'executablePath'),
      userExecutablePath = _field(json, 'userExecutablePath'),
      installed = json['installed'] == true,
      serviceRunning = json['serviceRunning'] == true,
      updateRequired = json['updateRequired'] == true;

  static String _field(Map<String, Object?> json, String name) {
    final value = json[name];
    if (value is String && value.isNotEmpty && !value.contains('\u0000')) {
      return value;
    }
    throw const HostException(
      HostError(
        HostErrorCode.unreachable,
        'The Windows host information is incomplete.',
      ),
    );
  }

  final String sid, userStateDir, serviceStateDir, userPipe, servicePipe;
  final String serviceName, executablePath, userExecutablePath;
  final bool installed, serviceRunning, updateRequired;

  String directory(bool service) => service ? serviceStateDir : userStateDir;
}

/// Platform operations are kept here so mode transitions can be exercised
/// without granting service or network privileges to a test runner.
abstract interface class WindowsHostBackend {
  Future<WindowsHostInfo> inspect();
  Future<void> startUser(WindowsHostInfo info);
  Future<void> startService(WindowsHostInfo info);
  Future<bool> install(WindowsHostInfo info);
  Future<String> exchange(
    WindowsHostInfo info,
    bool service,
    String command,
    Map<String, Object?> request,
  );
}

final class WindowsProcessBackend implements WindowsHostBackend {
  WindowsProcessBackend({
    this.native = const WindowsNative(),
    String? helperPath,
  }) : _helperPath = helperPath ?? _findHelper();

  final WindowsNative native;
  final String? _helperPath;
  String? _sid;

  static String? _findHelper() {
    final given = Platform.environment['AVALON_HELPER'];
    if (given != null && given.isNotEmpty) return given;
    final path =
        '${File(Platform.resolvedExecutable).parent.path}/avalon-helper.exe';
    return File(path).existsSync() ? path : null;
  }

  String get _helper =>
      _helperPath ??
      (throw const HostException(
        HostError(
          HostErrorCode.unreachable,
          'The Avalon Windows helper is not installed.',
        ),
      ));

  static HostException _nativeError(
    WindowsNativeException error,
  ) => HostException(
    HostError(switch (error.code) {
      'timeout' => HostErrorCode.timeout,
      'permissionDenied' || 'untrustedServer' => HostErrorCode.permissionDenied,
      'windowsApi' when error.win32Error == 5 => HostErrorCode.permissionDenied,
      'unsupportedPlatform' => HostErrorCode.unsupported,
      _ => HostErrorCode.unreachable,
    }, error.message),
  );

  Future<Map<String, Object?>> _action(String action, {String? sid}) async {
    Process? process;
    var exited = false;
    try {
      process = await Process.start(_helper, [
        '-windows-action',
        action,
        if (sid != null) ...['-sid', sid],
      ]);
      final output = process.stdout.fold<BytesBuilder>(BytesBuilder(), (
        bytes,
        chunk,
      ) {
        if (bytes.length + chunk.length > 65536) {
          throw const HostException(
            HostError(
              HostErrorCode.unreachable,
              'The Windows helper response exceeds the size limit.',
            ),
          );
        }
        return bytes..add(chunk);
      });
      // Drain stderr without retaining command output or possible secrets.
      final results = await Future.wait<Object?>([
        process.exitCode,
        output,
        process.stderr.drain<void>(),
      ], eagerError: true).timeout(const Duration(seconds: 15));
      exited = true;
      final reply = utf8.decode((results[1] as BytesBuilder).takeBytes());
      final result = WindowsHost._result(reply.trim());
      if (results[0] != 0) {
        throw const HostException(
          HostError(
            HostErrorCode.unreachable,
            'The Windows helper command failed.',
          ),
        );
      }
      return result;
    } on ProcessException {
      throw const HostException(
        HostError(
          HostErrorCode.unreachable,
          'The Windows helper could not start.',
        ),
      );
    } on TimeoutException {
      throw const HostException(
        HostError(HostErrorCode.timeout, 'The Windows helper did not answer.'),
      );
    } on FormatException {
      throw const HostException(
        HostError(
          HostErrorCode.unreachable,
          'The Windows helper response is invalid.',
        ),
      );
    } finally {
      if (process != null && !exited) {
        process.kill();
        // Process.run(...).timeout does not stop the child. Reap this direct
        // helper process, and bound cleanup if the OS cannot terminate it.
        await process.exitCode.timeout(
          const Duration(seconds: 2),
          onTimeout: () => -1,
        );
      }
    }
  }

  @override
  Future<WindowsHostInfo> inspect() async {
    try {
      _sid ??= await native.currentUserSid();
      return WindowsHostInfo.fromJson(await _action('init', sid: _sid));
    } on WindowsNativeException catch (error) {
      throw _nativeError(error);
    }
  }

  @override
  Future<void> startUser(WindowsHostInfo info) async {
    try {
      await Process.start(_helper, [
        '-sid',
        info.sid,
        '-state',
        info.userStateDir,
        '-socket',
        info.userPipe,
      ], mode: ProcessStartMode.detached);
    } on ProcessException {
      throw const HostException(
        HostError(
          HostErrorCode.unreachable,
          'The Windows helper could not start.',
        ),
      );
    }
  }

  @override
  Future<void> startService(WindowsHostInfo info) async {
    await _action('start-service', sid: info.sid);
  }

  @override
  Future<bool> install(WindowsHostInfo info) async {
    try {
      final status = await native.elevate(_helper, [
        '-windows-action',
        'install',
        '-sid',
        info.sid,
      ]);
      if (status == 1223) return false;
      if (status != 0) {
        throw const HostException(
          HostError(
            HostErrorCode.permissionDenied,
            'Installing the Windows service failed.',
          ),
        );
      }
      return true;
    } on WindowsNativeException catch (error) {
      if (error.win32Error == 1223) return false;
      throw _nativeError(error);
    }
  }

  @override
  Future<String> exchange(
    WindowsHostInfo info,
    bool service,
    String command,
    Map<String, Object?> request,
  ) async {
    var seconds = 45;
    if (command == 'urlTest') {
      final count = (request['tags'] as List?)?.length ?? 1;
      final rounds = (count / 8).ceil().clamp(1, 1 << 20);
      seconds =
          (((request['timeoutMs'] as int? ?? 5000) * rounds) / 1000).ceil() +
          10;
    } else if (command == 'fetch') {
      seconds = ((request['timeoutMs'] as int? ?? 30000) / 1000).ceil() + 10;
    }
    try {
      return await native.exchange(
        pipeName: service ? info.servicePipe : info.userPipe,
        line: jsonEncode({'command': command, 'request': request}),
        expectedHelperPath: service
            ? info.executablePath
            : info.userExecutablePath,
        serviceName: service ? info.serviceName : null,
        timeout: Duration(seconds: seconds),
      );
    } on WindowsNativeException catch (error) {
      throw _nativeError(error);
    }
  }
}

final class _WindowsModeTransport implements HostTransport {
  const _WindowsModeTransport(this.backend, this.info, this.service);
  final WindowsHostBackend backend;
  final WindowsHostInfo info;
  final bool service;

  @override
  Future<String> call(String command, String request) => backend.exchange(
    info,
    service,
    command,
    (jsonDecode(request) as Map).cast<String, Object?>(),
  );
}
