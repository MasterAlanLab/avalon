import 'dart:convert';

import 'package:flutter/services.dart';

import '../host_gateway.dart';
import '../host_protocol.dart';
import '../runtime_host.dart';

/// The host behind a platform channel (Android, iOS and macOS). Commands
/// travel as the bridge's own JSON: the native side passes them through
/// to the host and adds nothing (D85).
final class ChannelHost implements HostTransport, HostSystem {
  const ChannelHost();

  static const _channel = MethodChannel('dev.avalon/host');

  static HostException _failure(PlatformException error) => HostException(
    HostError(
      HostErrorCode.values.any((code) => code.wire == error.code)
          ? HostErrorCode.parse(error.code)
          : HostErrorCode.unreachable,
      error.message ?? error.code,
      detail: error.details is String ? error.details as String : null,
    ),
  );

  static Future<T?> _invoke<T>(String method, [Object? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (error) {
      throw _failure(error);
    } on MissingPluginException {
      throw const HostException(
        HostError(HostErrorCode.unreachable, 'the native host is unavailable'),
      );
    }
  }

  @override
  Future<String> call(String command, String request) async {
    final answer = await _invoke<String>('call', {
      'command': command,
      'request': request,
    });
    if (answer == null) {
      throw const HostException(
        HostError(HostErrorCode.unreachable, 'the host returned no answer'),
      );
    }
    return answer;
  }

  @override
  Future<HostFacts> facts() async {
    final facts = await _invoke<Map<Object?, Object?>>('facts');
    final dir = facts?['stateDir'];
    if (dir is! String || dir.isEmpty) {
      throw const HostException(
        HostError(HostErrorCode.unreachable, 'the host returned no directory'),
      );
    }
    return HostFacts(
      stateDir: dir,
      deviceName: facts?['deviceName'] as String? ?? '',
    );
  }

  @override
  Future<bool> prepare({required bool tun}) async =>
      await _invoke<bool>('prepare', {'tun': tun}) ?? false;

  @override
  Future<void> release() => _invoke<void>('release');

  @override
  Future<void> configure(HostOptions options) =>
      _invoke<void>('configure', jsonEncode(options.toJson()));
}
