import 'dart:async';

import 'package:avalon/common/common.dart';
import 'package:avalon/models/models.dart';

import 'desktop/model.dart';
import 'method.dart';

abstract class CoreHandlerInterface {
  /// Lifecycle hooks are supplied by the platform backends
  /// (`CoreLib` on Android, `CoreService` on desktop).
  Future<CoreLifecycleResult> start();

  Future<CoreLifecycleResult> restart();

  Future<CoreLifecycleResult> stop();

  Future<CoreLifecycleResult> close();

  Future<T?> _invokeMethod<T>({
    required CoreMethod method,
    Object? arguments,
    Duration? timeout,
  }) async {
    final invoke = () =>
        invokeMethod<T>(method: method, arguments: arguments, timeout: timeout);
    if (method == CoreMethod.getTraffic ||
        method == CoreMethod.getTotalTraffic) {
      return await invoke();
    }
    return await utils.handleWatch(
      onStart: () {
        commonPrint.log(
          'Invoke method ${method.name} ${DateTime.now()} $arguments',
        );
      },
      function: invoke,
      onEnd: (result, elapsedMilliseconds) {
        commonPrint.log(
          'Invoke method ${method.name} completed in ${elapsedMilliseconds}ms',
        );
      },
    );
  }

  Future<T?> invokeMethod<T>({
    required CoreMethod method,
    Object? arguments,
    Duration? timeout,
  });

  Future<bool> init(InitParams params) async {
    return await _invokeMethod<bool>(
          method: CoreMethod.initClash,
          arguments: params.toJson(),
        ) ??
        false;
  }

  Future<bool> get isInit async {
    return await _invokeMethod<bool>(method: CoreMethod.getIsInit) ?? false;
  }

  Future<bool> forceGc() async {
    return await _invokeMethod<bool>(method: CoreMethod.forceGc) ?? false;
  }

  Future<String> validateConfig(String path) async {
    return await _invokeMethod<String>(
          method: CoreMethod.validateConfig,
          arguments: path,
        ) ??
        '';
  }

  Future<String> updateConfig(UpdateParams updateParams) async {
    return await _invokeMethod<String>(
          method: CoreMethod.updateConfig,
          arguments: updateParams.toJson(),
        ) ??
        '';
  }

  Future<Map<String, dynamic>> getConfig(String path) async {
    final result = await _invokeMethod<Map<String, dynamic>>(
      method: CoreMethod.getConfig,
      arguments: path,
    );
    if (result == null) {
      throw const CoreMethodException(
        code: 'empty_result',
        message: 'Core returned an empty config result',
      );
    }
    return result;
  }

  Future<String> setupConfig(SetupParams setupParams) async {
    return await _invokeMethod<String>(
          method: CoreMethod.setupConfig,
          arguments: setupParams.toJson(),
        ) ??
        '';
  }

  Future<bool> crash() async {
    return await _invokeMethod<bool>(method: CoreMethod.crash) ?? false;
  }

  Future<ProxiesData> getProxies() async {
    final data = await _invokeMethod<Map<String, dynamic>>(
      method: CoreMethod.getProxies,
    );
    return data != null
        ? ProxiesData.fromJson(data)
        : const ProxiesData(proxies: {}, all: []);
  }

  Future<String> changeProxy(ChangeProxyParams changeProxyParams) async {
    return await _invokeMethod<String>(
          method: CoreMethod.changeProxy,
          arguments: changeProxyParams.toJson(),
        ) ??
        '';
  }

  Future<List<ExternalProvider>> getExternalProviders() async {
    final data = await _invokeMethod<List<dynamic>>(
      method: CoreMethod.getExternalProviders,
    );
    return data
            ?.whereType<Map>()
            .map(
              (item) =>
                  ExternalProvider.fromJson(Map<String, Object?>.from(item)),
            )
            .toList() ??
        [];
  }

  Future<ExternalProvider?> getExternalProvider(
    String externalProviderName,
  ) async {
    final data = await _invokeMethod<Map<String, dynamic>>(
      method: CoreMethod.getExternalProvider,
      arguments: externalProviderName,
    );
    return data == null ? null : ExternalProvider.fromJson(data);
  }

  Future<String> updateGeoData(String type) async {
    return await _invokeMethod<String>(
          method: CoreMethod.updateGeoData,
          arguments: type,
        ) ??
        '';
  }

  Future<String> sideLoadExternalProvider({
    required String providerName,
    required String data,
  }) async {
    return await _invokeMethod<String>(
          method: CoreMethod.sideLoadExternalProvider,
          arguments: {'providerName': providerName, 'data': data},
        ) ??
        '';
  }

  Future<String> updateExternalProvider(String providerName) async {
    return await _invokeMethod<String>(
          method: CoreMethod.updateExternalProvider,
          arguments: providerName,
        ) ??
        '';
  }

  Future<List<TrackerInfo>> getConnections() async {
    final data = await _invokeMethod<Map<String, dynamic>>(
      method: CoreMethod.getConnections,
    );
    final connections = data?['connections'];
    if (connections is! List) {
      return [];
    }
    return connections
        .whereType<Map>()
        .map((item) => TrackerInfo.fromJson(Map<String, Object?>.from(item)))
        .toList();
  }

  Future<bool> closeConnections() async {
    return await _invokeMethod<bool>(method: CoreMethod.closeConnections) ??
        false;
  }

  Future<bool> resetConnections() async {
    return await _invokeMethod<bool>(method: CoreMethod.resetConnections) ??
        false;
  }

  Future<bool> closeConnection(String id) async {
    return await _invokeMethod<bool>(
          method: CoreMethod.closeConnection,
          arguments: id,
        ) ??
        false;
  }

  Future<Traffic> getTotalTraffic(bool onlyStatisticsProxy) async {
    final data = await _invokeMethod<Map<String, dynamic>>(
      method: CoreMethod.getTotalTraffic,
      arguments: onlyStatisticsProxy,
    );
    return data == null ? const Traffic() : Traffic.fromJson(data);
  }

  Future<Traffic> getTraffic(bool onlyStatisticsProxy) async {
    final data = await _invokeMethod<Map<String, dynamic>>(
      method: CoreMethod.getTraffic,
      arguments: onlyStatisticsProxy,
    );
    return data == null ? const Traffic() : Traffic.fromJson(data);
  }

  Future<String> clearEffect(int profileId) async {
    return await _invokeMethod<String>(
          method: CoreMethod.clearEffect,
          arguments: profileId,
        ) ??
        '';
  }

  FutureOr<void> resetTraffic() {
    _invokeMethod(method: CoreMethod.resetTraffic);
  }

  FutureOr<void> startLog() {
    _invokeMethod(method: CoreMethod.startLog);
  }

  FutureOr<void> stopLog() {
    _invokeMethod<bool>(method: CoreMethod.stopLog);
  }

  Future<List<Log>> getLogs() async {
    final data = await _invokeMethod<List<dynamic>>(
      method: CoreMethod.getLogs,
    );
    return data
            ?.whereType<Map>()
            .map((item) => Log.fromJson(Map<String, Object?>.from(item)))
            .toList() ??
        [];
  }

  Future<bool> startListener() async {
    return await _invokeMethod<bool>(method: CoreMethod.startListener) ?? false;
  }

  Future<bool> stopListener() async {
    return await _invokeMethod<bool>(method: CoreMethod.stopListener) ?? false;
  }

  Future<Delay> asyncTestDelay(String url, String proxyName) async {
    final delayParams = {
      'proxy-name': proxyName,
      'timeout': httpTimeoutDuration.inMilliseconds,
      'test-url': url,
    };
    final data = await _invokeMethod<Map<String, dynamic>>(
      method: CoreMethod.asyncTestDelay,
      arguments: delayParams,
      timeout: const Duration(seconds: 6),
    );
    return data == null
        ? Delay(name: proxyName, value: -1, url: url)
        : Delay.fromJson(data);
  }

  Future<String> getCountryCode(String ip) async {
    return await _invokeMethod<String>(
          method: CoreMethod.getCountryCode,
          arguments: ip,
        ) ??
        '';
  }

  Future<int> getMemory() async {
    return await _invokeMethod<int>(method: CoreMethod.getMemory) ?? 0;
  }
}
