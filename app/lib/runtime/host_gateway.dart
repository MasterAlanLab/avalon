import 'dart:async';
import 'dart:convert';

import 'host_protocol.dart';

/// Carries one bridge command to the host and its JSON answer back. One
/// implementation per kind of host: a platform channel on Android and
/// Apple, a Windows named pipe or Linux Unix socket (D85, D124).
abstract interface class HostTransport {
  /// Throws when the host cannot be reached at all.
  Future<String> call(String command, String request);
}

/// The host's commands, typed (RUNTIME_HOST §2). The messages themselves
/// are the bridge's JSON on every platform; this is their only Dart form.
final class HostGateway {
  HostGateway(
    this._transport, {
    String Function()? newRequestId,
    this.lifecycleTimeout = const Duration(seconds: 30),
    this.commandTimeout = const Duration(seconds: 5),
  }) : _newRequestId = newRequestId ?? _counter();

  final HostTransport _transport;
  final String Function() _newRequestId;

  /// start and reload (RUNTIME_HOST §4).
  final Duration lifecycleTimeout;
  final Duration commandTimeout;

  static String Function() _counter() {
    final prefix = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    var next = 0;
    return () => '$prefix-${next++}';
  }

  Future<HostCapabilities> capabilities() async =>
      HostCapabilities.fromJson(await _read('capabilities', const {}));

  /// Starts the plan stored at [planPath]. [utcOffset] is the device's
  /// offset from UTC: the host counts «today's» traffic by it.
  Future<HostSession> start({
    required String planPath,
    required String planHash,
    Duration? utcOffset,
  }) async => HostSession.fromJson(
    await _command('start', {
      'planPath': planPath,
      'planHash': planHash,
      'utcOffsetSeconds': ?utcOffset?.inSeconds,
    }, lifecycleTimeout),
  );

  Future<HostSession> reload({
    required String sessionId,
    required String planPath,
    required String planHash,
    Duration? utcOffset,
  }) async => HostSession.fromJson(
    await _command('reload', {
      'sessionId': sessionId,
      'planPath': planPath,
      'planHash': planHash,
      'utcOffsetSeconds': ?utcOffset?.inSeconds,
    }, lifecycleTimeout),
  );

  Future<void> stop() => _command('stop', {}, commandTimeout);

  Future<void> setMode(String sessionId, String mode) => _command('setMode', {
    'sessionId': sessionId,
    'mode': mode,
  }, commandTimeout);

  Future<void> select(String sessionId, String groupTag, String memberTag) =>
      _command('select', {
        'sessionId': sessionId,
        'groupTag': groupTag,
        'memberTag': memberTag,
      }, commandTimeout);

  /// Measures how long the outbounds [tags] take to fetch [url]: in the
  /// running session ([sessionId]), or, with nothing running, through the
  /// outbounds of the plan at [planPath] alone, which takes over nothing
  /// (CONFIG_PIPELINE §9).
  Future<Map<String, HostLatency>> urlTest({
    String? sessionId,
    String? planPath,
    required List<String> tags,
    required String url,
    required Duration timeout,
  }) async {
    // Eight at a time (the bridge's limit), each up to [timeout].
    final rounds = (tags.length / 8).ceil().clamp(1, 1 << 20);
    final answer = await _command('urlTest', {
      'sessionId': ?sessionId,
      'planPath': ?planPath,
      'tags': tags,
      'url': url,
      'timeoutMs': timeout.inMilliseconds,
    }, timeout * rounds + lifecycleTimeout);
    return {
      for (final entry in (answer['results'] as Map? ?? const {}).entries)
        entry.key as String: HostLatency.fromJson(
          (entry.value as Map).cast<String, Object?>(),
        ),
    };
  }

  Future<HostSnapshot> snapshot() async =>
      HostSnapshot.fromJson(await _read('snapshot', const {}));

  Future<HostTailnetStatus> tailnetStatus() async =>
      HostTailnetStatus.fromJson(await _read('tailnetStatus', const {}));

  Future<HostTailnetStatus> tailnetLogin() async => HostTailnetStatus.fromJson(
    await _command('tailnetLogin', const {}, commandTimeout),
  );

  Future<HostTailnetStatus> tailnetLogout() async => HostTailnetStatus.fromJson(
    await _command('tailnetLogout', const {}, commandTimeout),
  );

  Future<HostLogPage> logs({required int afterSeq, int limit = 200}) async =>
      HostLogPage.fromJson(
        await _read('logs', {'afterSeq': afterSeq, 'limit': limit}),
      );

  /// Downloads [url] through [outboundTag] of the running session, into
  /// [destPath] when given (the answer crosses processes: keep bodies
  /// small otherwise).
  Future<HostFetch> fetch({
    required String sessionId,
    required String outboundTag,
    required String url,
    required int maxBytes,
    String? destPath,
    bool publicOnly = false,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    if (publicOnly && (await capabilities()).publicNetworkVersion != 1) {
      throw const HostException(
        HostError(
          HostErrorCode.unsupported,
          'public network guard unavailable',
        ),
      );
    }
    return HostFetch.fromJson(
      await _command('fetch', {
        'sessionId': sessionId,
        'outboundTag': outboundTag,
        'url': url,
        'maxBytes': maxBytes,
        'destPath': ?destPath,
        if (publicOnly) 'publicOnly': true,
        'timeoutMs': timeout.inMilliseconds,
      }, timeout + commandTimeout),
    );
  }

  Future<List<HostConnection>> connections(String sessionId) async {
    final answer = await _read('connections', {'sessionId': sessionId});
    return [
      for (final item in (answer['connections'] as List? ?? const []))
        HostConnection.fromJson((item as Map).cast<String, Object?>()),
    ];
  }

  Future<void> closeConnection(String sessionId, String id) => _command(
    'closeConnection',
    {'sessionId': sessionId, 'id': id},
    commandTimeout,
  );

  Future<void> closeAllConnections(String sessionId) =>
      _command('closeAllConnections', {'sessionId': sessionId}, commandTimeout);

  /// A question that changes nothing: when the host does not answer in
  /// time it is simply unreachable.
  Future<Map<String, Object?>> _read(
    String command,
    Map<String, Object?> request,
  ) async {
    try {
      return await _ask(command, request).timeout(commandTimeout);
    } on TimeoutException {
      throw const HostException(
        HostError(HostErrorCode.unreachable, 'the host did not answer'),
      );
    }
  }

  /// A command that changes something: it carries a request id, and when
  /// the wait runs out the host is asked what became of it rather than
  /// sent the command again (RUNTIME_HOST §4).
  Future<Map<String, Object?>> _command(
    String command,
    Map<String, Object?> request,
    Duration timeout,
  ) async {
    final id = _newRequestId();
    try {
      return await _ask(command, {
        ...request,
        'requestId': id,
      }).timeout(timeout);
    } on TimeoutException {
      return _recoverCommand(id);
    } on HostException catch (error) {
      if (error.error.code != HostErrorCode.timeout) rethrow;
      // A native IPC timer can expire before Dart's timer. The command
      // may still have completed in the extension: recover with the same
      // identifier instead of treating transport timeout as rejection.
      return _recoverCommand(id);
    }
  }

  Future<Map<String, Object?>> _recoverCommand(String id) async {
    final status = await _read('queryCommand', {'requestId': id});
    switch (status['status']) {
      case 'done':
        return (status['result'] as Map?)?.cast() ?? const {};
      case 'failed':
        throw HostException(
          HostError.fromJson((status['error']! as Map).cast()),
        );
      default:
        // Still running or never arrived: the snapshot will tell.
        throw const HostException(
          HostError(HostErrorCode.timeout, 'the host did not answer in time'),
        );
    }
  }

  Future<Map<String, Object?>> _ask(
    String command,
    Map<String, Object?> request,
  ) async {
    final String raw;
    try {
      raw = await _transport.call(command, jsonEncode(request));
    } on HostException {
      rethrow;
    } on Exception catch (e) {
      throw HostException(HostError(HostErrorCode.unreachable, '$e'));
    }
    final Object? response;
    try {
      response = jsonDecode(raw);
    } on FormatException catch (e) {
      throw HostException(
        HostError(HostErrorCode.unreachable, 'malformed answer', detail: '$e'),
      );
    }
    if (response is! Map) {
      throw const HostException(
        HostError(HostErrorCode.unreachable, 'malformed answer'),
      );
    }
    final error = response['error'];
    if (error is Map) throw HostException(HostError.fromJson(error.cast()));
    return (response['result'] as Map?)?.cast() ?? const {};
  }
}
