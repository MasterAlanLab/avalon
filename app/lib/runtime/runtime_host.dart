import 'package:av_core/av_core.dart';
import 'package:flutter/foundation.dart';

import 'host/channel_host.dart';
import 'host/socket_host.dart';
import 'host/windows_host.dart';
import 'host_gateway.dart';

/// What the app must know about the host before it compiles a plan.
@immutable
final class HostFacts {
  const HostFacts({required this.stateDir, required this.deviceName});

  /// Where the host keeps its files; plans name files under it and the
  /// plan itself is written there.
  final String stateDir;
  final String deviceName;
}

/// The settings a host acts on by itself, without the app (RUNTIME_HOST
/// §8): its notification, and starting the last plan when the device
/// boots.
@immutable
final class HostOptions {
  const HostOptions({
    required this.speedNotification,
    required this.startAtBoot,
    this.systemProxy = false,
    this.mixedPort = 7890,
    this.language,
  });

  /// From the device settings: the speed in the notification, and a start
  /// at boot when both «开机自动启动» and «启动后自动连接» are on.
  factory HostOptions.of(DeviceSettings settings) => HostOptions(
    speedNotification: settings.speedNotification,
    startAtBoot: settings.launchAtStartup && settings.autoConnect,
    systemProxy: settings.systemProxy,
    mixedPort: settings.mixedPort,
    language: settings.locale,
  );

  final bool speedNotification;
  final bool startAtBoot;
  final bool systemProxy;
  final int mixedPort;

  /// The app's language for the host's own text; null follows the system.
  final String? language;

  Map<String, Object?> toJson() => {
    'speedNotification': speedNotification,
    'startAtBoot': startAtBoot,
    'systemProxy': systemProxy,
    'mixedPort': mixedPort,
    'language': ?language,
  };

  @override
  bool operator ==(Object other) =>
      other is HostOptions &&
      other.speedNotification == speedNotification &&
      other.startAtBoot == startAtBoot &&
      other.systemProxy == systemProxy &&
      other.mixedPort == mixedPort &&
      other.language == language;

  @override
  int get hashCode => Object.hash(
    speedNotification,
    startAtBoot,
    systemProxy,
    mixedPort,
    language,
  );
}

/// The parts of a host that are the platform's business rather than the
/// bridge's: its directory, the system's consent, its own settings, and
/// letting it rest.
abstract interface class HostSystem {
  Future<HostFacts> facts();

  /// Asks for what a session needs (on Android the VPN consent when the
  /// tunnel is on). False when the user refused.
  Future<bool> prepare({required bool tun});

  /// Lets go of a host with no session, so it need not stay in memory.
  Future<void> release();

  /// Hands the host the settings it acts on by itself; it keeps them for
  /// when the app is not there.
  Future<void> configure(HostOptions options);
}

/// The host of this device: its commands and its platform side.
final class RuntimeHost {
  RuntimeHost({required HostTransport transport, required this.system})
    : gateway = HostGateway(transport);

  final HostGateway gateway;
  final HostSystem system;

  /// Windows may move between its ordinary helper and privileged service.
  /// Resolve the destination before compiling paths for a reload.
  bool get preparesEveryReload => system is WindowsHost;

  /// Null on platforms without a native runtime host.
  static RuntimeHost? ofThisPlatform() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        const channel = ChannelHost();
        return RuntimeHost(transport: channel, system: channel);
      case TargetPlatform.linux:
        final socket = SocketHost.linux();
        return RuntimeHost(transport: socket, system: socket);
      case TargetPlatform.windows:
        final pipe = WindowsHost.native();
        return RuntimeHost(transport: pipe, system: pipe);
      default:
        return null;
    }
  }
}
