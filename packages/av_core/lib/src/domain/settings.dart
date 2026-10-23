import 'package:freezed_annotation/freezed_annotation.dart';

import 'refs.dart';
import 'secret.dart';

part 'settings.freezed.dart';
part 'settings.g.dart';

enum OutboundMode { rule, global, direct }

enum Appearance { light, dark }

enum TunStack { gvisor, system, mixed }

enum DnsStrategy { preferIpv4, ipv4Only, preferIpv6 }

enum LogLevel { debug, info, warn, error }

enum PerAppMode { whitelist, blacklist }

enum GeoInterval { daily, weekly }

enum DownloadVia { proxy, direct }

/// Tailscale settings (PRODUCT_SPEC §3.13).
@freezed
abstract class TailnetSettings with _$TailnetSettings {
  const factory TailnetSettings({
    @Default(false) bool enabled,

    /// Selected exit node; null is 「不使用」.
    TailnetExitRef? exit,
    @Default(true) bool acceptRoutes,
    @Default(true) bool magicDns,
    @Default(false) bool advertiseExit,
  }) = _TailnetSettings;

  factory TailnetSettings.fromJson(Map<String, dynamic> json) =>
      _$TailnetSettingsFromJson(json);
}

/// Per-device settings (DATA_MODEL §1.2): not synced, part of backups.
/// Defaults are PRODUCT_SPEC §4.
@freezed
abstract class DeviceSettings with _$DeviceSettings {
  const factory DeviceSettings({
    // General.
    /// `zh` or `en`; null until the first launch picks the system language.
    String? locale,
    @Default(Appearance.light) Appearance appearance,

    // Start-up.
    @Default(true) bool launchAtStartup,
    @Default(false) bool silentStart,
    @Default(false) bool autoConnect,
    @Default(true) bool keepOnClose,
    @Default(true) bool speedNotification,

    // Proxy.
    @Default(false) bool systemProxy,
    @Default(false) bool allowLan,
    @Default(7890) int mixedPort,

    // Latency test.
    @Default('https://www.gstatic.com/generate_204') String testUrl,
    @Default(5000) int testTimeoutMs,

    // TUN.
    @Default(true) bool tunEnabled,
    @Default(TunStack.mixed) TunStack tunStack,
    @Default(9000) int mtu,
    @Default(true) bool autoRoute,
    @Default(true) bool strictRoute,

    // DNS.
    @Default('https://1.1.1.1/dns-query') String remoteDns,
    @Default('223.5.5.5') String directDns,
    @Default(true) bool fakeIp,
    @Default(DnsStrategy.preferIpv4) DnsStrategy dnsStrategy,

    // Routing.
    @Default(true) bool sniff,
    @Default(false) bool sniffOverrideDestination,
    @Default(true) bool bypassLan,
    @Default(false) bool ipv6,
    @Default(true) bool findProcess,

    // Clash API.
    @Default(true) bool clashApi,
    @Default('127.0.0.1:9090') String clashApiListen,

    /// Generated on first launch (PRODUCT_SPEC §3.10).
    Secret? clashApiSecret,

    // Core.
    @Default(LogLevel.info) LogLevel logLevel,

    // Per-app proxy (empty list: everything follows the rules, D13).
    @Default(PerAppMode.whitelist) PerAppMode perAppMode,
    @Default(<String>[]) List<String> perAppList,

    // Running choices (DATA_MODEL §2: stored with the device settings).
    String? selectedConfigurationId,
    @Default(OutboundMode.rule) OutboundMode mode,
    @Default(TailnetSettings()) TailnetSettings tailnet,
  }) = _DeviceSettings;

  factory DeviceSettings.fromJson(Map<String, dynamic> json) =>
      _$DeviceSettingsFromJson(json);
}

/// Settings synced through Cloud (DATA_MODEL §1.2).
@freezed
abstract class Policy with _$Policy {
  const factory Policy({
    /// sing-box JSON fragment merged into imported configurations (D19).
    Secret? jsonOverride,
    @Default(true) bool geoAutoUpdate,
    @Default(GeoInterval.daily) GeoInterval geoInterval,
    @Default(DownloadVia.proxy) DownloadVia geoVia,
  }) = _Policy;

  factory Policy.fromJson(Map<String, dynamic> json) => _$PolicyFromJson(json);
}
