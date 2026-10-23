import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../host_gateway.dart';
import '../host_protocol.dart';
import '../runtime_host.dart';

/// The desktop helper behind a Unix socket (Linux; RUNTIME_HOST §8): each
/// command is one connection carrying one line of the bridge's JSON each
/// way, so a long start never holds up a snapshot. The helper is started
/// when nothing answers; it outlives the app, like the mobile hosts.
final class SocketHost implements HostTransport, HostSystem {
  SocketHost({
    required this.socketPath,
    required this.stateDir,
    required this.helperPath,
    this.deviceName = '',
  });

  /// Where the helper listens: `$XDG_RUNTIME_DIR/avalon/host.sock`.
  final String socketPath;

  /// The helper's directory: `$XDG_STATE_HOME/avalon`.
  final String stateDir;

  /// The helper executable, started when nothing answers; null where it
  /// cannot be found (the host is then unreachable).
  final String? helperPath;
  final String deviceName;

  /// For the time a command may take the helper to start.
  static const startTimeout = Duration(seconds: 5);

  /// The sole root-owned Linux installation path (D112). File capabilities
  /// belong to this helper, never to the Flutter executable or a user bundle.
  static const installedLinuxHelperPath = '/usr/lib/avalon/avalon-helper';

  Future<void>? _starting;

  /// The host of a Linux desktop session, by the XDG directories.
  factory SocketHost.linux() {
    final env = Platform.environment;
    final home = env['HOME'] ?? '';
    final runtime = env['XDG_RUNTIME_DIR'];
    final state = env['XDG_STATE_HOME'] ?? '$home/.local/state';
    return SocketHost(
      socketPath: runtime == null || runtime.isEmpty
          ? '/tmp/avalon-${env['USER'] ?? 'user'}/host.sock'
          : '$runtime/avalon/host.sock',
      stateDir: '$state/avalon',
      helperPath: findLinuxHelper(
        environment: env,
        executablePath: Platform.resolvedExecutable,
      ),
      deviceName: Platform.localHostname,
    );
  }

  /// Explicit development override, then the installed capable helper, then
  /// an ordinary bundled helper. The installer never elevates bundle paths.
  static String? findLinuxHelper({
    required Map<String, String> environment,
    required String executablePath,
    bool Function(String)? fileExists,
  }) {
    final given = environment['AVALON_HELPER'];
    if (given != null && given.isNotEmpty) return given;
    final exists = fileExists ?? (path) => File(path).existsSync();
    final dir = File(executablePath).parent.path;
    for (final path in [
      installedLinuxHelperPath,
      '$dir/lib/avalon-helper',
      '$dir/avalon-helper',
    ]) {
      if (exists(path)) return path;
    }
    return null;
  }

  @override
  Future<String> call(String command, String request) async {
    Socket socket;
    try {
      socket = await _connect();
    } on SocketException catch (e) {
      throw HostException(HostError(HostErrorCode.unreachable, e.message));
    }
    try {
      final line = '{"command":${jsonEncode(command)},"request":$request}\n';
      socket.write(line);
      await socket.flush();
      final answer = await socket
          .cast<List<int>>()
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .first;
      return answer;
    } on StateError {
      // Closed without an answer: refused (another user) or the helper
      // went away mid-command.
      throw const HostException(
        HostError(HostErrorCode.unreachable, 'the helper closed the socket'),
      );
    } finally {
      socket.destroy();
    }
  }

  /// Connects, starting the helper first when nothing answers.
  Future<Socket> _connect() async {
    final address = InternetAddress(socketPath, type: InternetAddressType.unix);
    try {
      return await Socket.connect(address, 0);
    } on SocketException {
      await (_starting ??= _startHelper().whenComplete(() => _starting = null));
      final deadline = DateTime.now().add(startTimeout);
      while (true) {
        try {
          return await Socket.connect(address, 0);
        } on SocketException {
          if (DateTime.now().isAfter(deadline)) rethrow;
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      }
    }
  }

  Future<void> _startHelper() async {
    final helper = helperPath;
    if (helper == null) {
      throw const SocketException('the Avalon helper is not installed');
    }
    await Directory(stateDir).create(recursive: true);
    await Process.start(helper, [
      '-state',
      stateDir,
      '-socket',
      socketPath,
    ], mode: ProcessStartMode.detached);
  }

  @override
  Future<HostFacts> facts() async {
    // Plans and probes may be written before the helper is first contacted.
    await Directory(stateDir).create(recursive: true);
    return HostFacts(stateDir: stateDir, deviceName: deviceName);
  }

  /// The tunnel needs a helper with CAP_NET_ADMIN (deb and rpm set it
  /// when installing); without it the start is refused here, not halfway.
  @override
  Future<bool> prepare({required bool tun}) async {
    if (!tun) return true;
    final answer = jsonDecode(await call('capabilities', '{}'));
    final result = answer is Map ? answer['result'] : null;
    return result is Map && result['tun'] == true;
  }

  /// The helper is a process of the user's: nothing to let go of.
  @override
  Future<void> release() async {}

  // DesktopShell and DesktopProxyController apply these preferences in
  // the user's session. The Linux helper has no mobile host options.
  @override
  Future<void> configure(HostOptions options) async {}
}
