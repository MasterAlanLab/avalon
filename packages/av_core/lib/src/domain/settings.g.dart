// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TailnetSettings _$TailnetSettingsFromJson(Map<String, dynamic> json) =>
    _TailnetSettings(
      enabled: json['enabled'] as bool? ?? false,
      exit: json['exit'] == null
          ? null
          : TailnetExitRef.fromJson(json['exit'] as Map<String, dynamic>),
      acceptRoutes: json['acceptRoutes'] as bool? ?? true,
      magicDns: json['magicDns'] as bool? ?? true,
      advertiseExit: json['advertiseExit'] as bool? ?? false,
    );

Map<String, dynamic> _$TailnetSettingsToJson(_TailnetSettings instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'exit': ?instance.exit?.toJson(),
      'acceptRoutes': instance.acceptRoutes,
      'magicDns': instance.magicDns,
      'advertiseExit': instance.advertiseExit,
    };

_DeviceSettings _$DeviceSettingsFromJson(
  Map<String, dynamic> json,
) => _DeviceSettings(
  locale: json['locale'] as String?,
  appearance:
      $enumDecodeNullable(_$AppearanceEnumMap, json['appearance']) ??
      Appearance.light,
  launchAtStartup: json['launchAtStartup'] as bool? ?? true,
  silentStart: json['silentStart'] as bool? ?? false,
  autoConnect: json['autoConnect'] as bool? ?? false,
  keepOnClose: json['keepOnClose'] as bool? ?? true,
  speedNotification: json['speedNotification'] as bool? ?? true,
  systemProxy: json['systemProxy'] as bool? ?? false,
  allowLan: json['allowLan'] as bool? ?? false,
  mixedPort: (json['mixedPort'] as num?)?.toInt() ?? 7890,
  testUrl: json['testUrl'] as String? ?? 'https://www.gstatic.com/generate_204',
  testTimeoutMs: (json['testTimeoutMs'] as num?)?.toInt() ?? 5000,
  tunEnabled: json['tunEnabled'] as bool? ?? true,
  tunStack:
      $enumDecodeNullable(_$TunStackEnumMap, json['tunStack']) ??
      TunStack.mixed,
  mtu: (json['mtu'] as num?)?.toInt() ?? 9000,
  autoRoute: json['autoRoute'] as bool? ?? true,
  strictRoute: json['strictRoute'] as bool? ?? true,
  remoteDns: json['remoteDns'] as String? ?? 'https://1.1.1.1/dns-query',
  directDns: json['directDns'] as String? ?? '223.5.5.5',
  fakeIp: json['fakeIp'] as bool? ?? true,
  dnsStrategy:
      $enumDecodeNullable(_$DnsStrategyEnumMap, json['dnsStrategy']) ??
      DnsStrategy.preferIpv4,
  sniff: json['sniff'] as bool? ?? true,
  sniffOverrideDestination: json['sniffOverrideDestination'] as bool? ?? false,
  bypassLan: json['bypassLan'] as bool? ?? true,
  ipv6: json['ipv6'] as bool? ?? false,
  findProcess: json['findProcess'] as bool? ?? true,
  clashApi: json['clashApi'] as bool? ?? true,
  clashApiListen: json['clashApiListen'] as String? ?? '127.0.0.1:9090',
  clashApiSecret: json['clashApiSecret'] == null
      ? null
      : Secret.fromJson(json['clashApiSecret'] as Map<String, dynamic>),
  logLevel:
      $enumDecodeNullable(_$LogLevelEnumMap, json['logLevel']) ?? LogLevel.info,
  perAppMode:
      $enumDecodeNullable(_$PerAppModeEnumMap, json['perAppMode']) ??
      PerAppMode.whitelist,
  perAppList:
      (json['perAppList'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  selectedConfigurationId: json['selectedConfigurationId'] as String?,
  mode:
      $enumDecodeNullable(_$OutboundModeEnumMap, json['mode']) ??
      OutboundMode.rule,
  tailnet: json['tailnet'] == null
      ? const TailnetSettings()
      : TailnetSettings.fromJson(json['tailnet'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DeviceSettingsToJson(_DeviceSettings instance) =>
    <String, dynamic>{
      'locale': ?instance.locale,
      'appearance': _$AppearanceEnumMap[instance.appearance]!,
      'launchAtStartup': instance.launchAtStartup,
      'silentStart': instance.silentStart,
      'autoConnect': instance.autoConnect,
      'keepOnClose': instance.keepOnClose,
      'speedNotification': instance.speedNotification,
      'systemProxy': instance.systemProxy,
      'allowLan': instance.allowLan,
      'mixedPort': instance.mixedPort,
      'testUrl': instance.testUrl,
      'testTimeoutMs': instance.testTimeoutMs,
      'tunEnabled': instance.tunEnabled,
      'tunStack': _$TunStackEnumMap[instance.tunStack]!,
      'mtu': instance.mtu,
      'autoRoute': instance.autoRoute,
      'strictRoute': instance.strictRoute,
      'remoteDns': instance.remoteDns,
      'directDns': instance.directDns,
      'fakeIp': instance.fakeIp,
      'dnsStrategy': _$DnsStrategyEnumMap[instance.dnsStrategy]!,
      'sniff': instance.sniff,
      'sniffOverrideDestination': instance.sniffOverrideDestination,
      'bypassLan': instance.bypassLan,
      'ipv6': instance.ipv6,
      'findProcess': instance.findProcess,
      'clashApi': instance.clashApi,
      'clashApiListen': instance.clashApiListen,
      'clashApiSecret': ?instance.clashApiSecret?.toJson(),
      'logLevel': _$LogLevelEnumMap[instance.logLevel]!,
      'perAppMode': _$PerAppModeEnumMap[instance.perAppMode]!,
      'perAppList': instance.perAppList,
      'selectedConfigurationId': ?instance.selectedConfigurationId,
      'mode': _$OutboundModeEnumMap[instance.mode]!,
      'tailnet': instance.tailnet.toJson(),
    };

const _$AppearanceEnumMap = {
  Appearance.light: 'light',
  Appearance.dark: 'dark',
};

const _$TunStackEnumMap = {
  TunStack.gvisor: 'gvisor',
  TunStack.system: 'system',
  TunStack.mixed: 'mixed',
};

const _$DnsStrategyEnumMap = {
  DnsStrategy.preferIpv4: 'preferIpv4',
  DnsStrategy.ipv4Only: 'ipv4Only',
  DnsStrategy.preferIpv6: 'preferIpv6',
};

const _$LogLevelEnumMap = {
  LogLevel.debug: 'debug',
  LogLevel.info: 'info',
  LogLevel.warn: 'warn',
  LogLevel.error: 'error',
};

const _$PerAppModeEnumMap = {
  PerAppMode.whitelist: 'whitelist',
  PerAppMode.blacklist: 'blacklist',
};

const _$OutboundModeEnumMap = {
  OutboundMode.rule: 'rule',
  OutboundMode.global: 'global',
  OutboundMode.direct: 'direct',
};

_Policy _$PolicyFromJson(Map<String, dynamic> json) => _Policy(
  jsonOverride: json['jsonOverride'] == null
      ? null
      : Secret.fromJson(json['jsonOverride'] as Map<String, dynamic>),
  geoAutoUpdate: json['geoAutoUpdate'] as bool? ?? true,
  geoInterval:
      $enumDecodeNullable(_$GeoIntervalEnumMap, json['geoInterval']) ??
      GeoInterval.daily,
  geoVia:
      $enumDecodeNullable(_$DownloadViaEnumMap, json['geoVia']) ??
      DownloadVia.proxy,
);

Map<String, dynamic> _$PolicyToJson(_Policy instance) => <String, dynamic>{
  'jsonOverride': ?instance.jsonOverride?.toJson(),
  'geoAutoUpdate': instance.geoAutoUpdate,
  'geoInterval': _$GeoIntervalEnumMap[instance.geoInterval]!,
  'geoVia': _$DownloadViaEnumMap[instance.geoVia]!,
};

const _$GeoIntervalEnumMap = {
  GeoInterval.daily: 'daily',
  GeoInterval.weekly: 'weekly',
};

const _$DownloadViaEnumMap = {
  DownloadVia.proxy: 'proxy',
  DownloadVia.direct: 'direct',
};
