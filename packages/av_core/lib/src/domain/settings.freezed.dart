// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TailnetSettings {

 bool get enabled;/// Selected exit node; null is 「不使用」.
 TailnetExitRef? get exit; bool get acceptRoutes; bool get magicDns; bool get advertiseExit;
/// Create a copy of TailnetSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TailnetSettingsCopyWith<TailnetSettings> get copyWith => _$TailnetSettingsCopyWithImpl<TailnetSettings>(this as TailnetSettings, _$identity);

  /// Serializes this TailnetSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TailnetSettings&&(identical(other.enabled, enabled) || other.enabled == enabled)&&const DeepCollectionEquality().equals(other.exit, exit)&&(identical(other.acceptRoutes, acceptRoutes) || other.acceptRoutes == acceptRoutes)&&(identical(other.magicDns, magicDns) || other.magicDns == magicDns)&&(identical(other.advertiseExit, advertiseExit) || other.advertiseExit == advertiseExit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enabled,const DeepCollectionEquality().hash(exit),acceptRoutes,magicDns,advertiseExit);

@override
String toString() {
  return 'TailnetSettings(enabled: $enabled, exit: $exit, acceptRoutes: $acceptRoutes, magicDns: $magicDns, advertiseExit: $advertiseExit)';
}


}

/// @nodoc
abstract mixin class $TailnetSettingsCopyWith<$Res>  {
  factory $TailnetSettingsCopyWith(TailnetSettings value, $Res Function(TailnetSettings) _then) = _$TailnetSettingsCopyWithImpl;
@useResult
$Res call({
 bool enabled, TailnetExitRef? exit, bool acceptRoutes, bool magicDns, bool advertiseExit
});




}
/// @nodoc
class _$TailnetSettingsCopyWithImpl<$Res>
    implements $TailnetSettingsCopyWith<$Res> {
  _$TailnetSettingsCopyWithImpl(this._self, this._then);

  final TailnetSettings _self;
  final $Res Function(TailnetSettings) _then;

/// Create a copy of TailnetSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? enabled = null,Object? exit = freezed,Object? acceptRoutes = null,Object? magicDns = null,Object? advertiseExit = null,}) {
  return _then(_self.copyWith(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,exit: freezed == exit ? _self.exit : exit // ignore: cast_nullable_to_non_nullable
as TailnetExitRef?,acceptRoutes: null == acceptRoutes ? _self.acceptRoutes : acceptRoutes // ignore: cast_nullable_to_non_nullable
as bool,magicDns: null == magicDns ? _self.magicDns : magicDns // ignore: cast_nullable_to_non_nullable
as bool,advertiseExit: null == advertiseExit ? _self.advertiseExit : advertiseExit // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [TailnetSettings].
extension TailnetSettingsPatterns on TailnetSettings {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TailnetSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TailnetSettings() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TailnetSettings value)  $default,){
final _that = this;
switch (_that) {
case _TailnetSettings():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TailnetSettings value)?  $default,){
final _that = this;
switch (_that) {
case _TailnetSettings() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool enabled,  TailnetExitRef? exit,  bool acceptRoutes,  bool magicDns,  bool advertiseExit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TailnetSettings() when $default != null:
return $default(_that.enabled,_that.exit,_that.acceptRoutes,_that.magicDns,_that.advertiseExit);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool enabled,  TailnetExitRef? exit,  bool acceptRoutes,  bool magicDns,  bool advertiseExit)  $default,) {final _that = this;
switch (_that) {
case _TailnetSettings():
return $default(_that.enabled,_that.exit,_that.acceptRoutes,_that.magicDns,_that.advertiseExit);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool enabled,  TailnetExitRef? exit,  bool acceptRoutes,  bool magicDns,  bool advertiseExit)?  $default,) {final _that = this;
switch (_that) {
case _TailnetSettings() when $default != null:
return $default(_that.enabled,_that.exit,_that.acceptRoutes,_that.magicDns,_that.advertiseExit);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TailnetSettings implements TailnetSettings {
  const _TailnetSettings({this.enabled = false, this.exit, this.acceptRoutes = true, this.magicDns = true, this.advertiseExit = false});
  factory _TailnetSettings.fromJson(Map<String, dynamic> json) => _$TailnetSettingsFromJson(json);

@override@JsonKey() final  bool enabled;
/// Selected exit node; null is 「不使用」.
@override final  TailnetExitRef? exit;
@override@JsonKey() final  bool acceptRoutes;
@override@JsonKey() final  bool magicDns;
@override@JsonKey() final  bool advertiseExit;

/// Create a copy of TailnetSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TailnetSettingsCopyWith<_TailnetSettings> get copyWith => __$TailnetSettingsCopyWithImpl<_TailnetSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TailnetSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TailnetSettings&&(identical(other.enabled, enabled) || other.enabled == enabled)&&const DeepCollectionEquality().equals(other.exit, exit)&&(identical(other.acceptRoutes, acceptRoutes) || other.acceptRoutes == acceptRoutes)&&(identical(other.magicDns, magicDns) || other.magicDns == magicDns)&&(identical(other.advertiseExit, advertiseExit) || other.advertiseExit == advertiseExit));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,enabled,const DeepCollectionEquality().hash(exit),acceptRoutes,magicDns,advertiseExit);

@override
String toString() {
  return 'TailnetSettings(enabled: $enabled, exit: $exit, acceptRoutes: $acceptRoutes, magicDns: $magicDns, advertiseExit: $advertiseExit)';
}


}

/// @nodoc
abstract mixin class _$TailnetSettingsCopyWith<$Res> implements $TailnetSettingsCopyWith<$Res> {
  factory _$TailnetSettingsCopyWith(_TailnetSettings value, $Res Function(_TailnetSettings) _then) = __$TailnetSettingsCopyWithImpl;
@override @useResult
$Res call({
 bool enabled, TailnetExitRef? exit, bool acceptRoutes, bool magicDns, bool advertiseExit
});




}
/// @nodoc
class __$TailnetSettingsCopyWithImpl<$Res>
    implements _$TailnetSettingsCopyWith<$Res> {
  __$TailnetSettingsCopyWithImpl(this._self, this._then);

  final _TailnetSettings _self;
  final $Res Function(_TailnetSettings) _then;

/// Create a copy of TailnetSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? enabled = null,Object? exit = freezed,Object? acceptRoutes = null,Object? magicDns = null,Object? advertiseExit = null,}) {
  return _then(_TailnetSettings(
enabled: null == enabled ? _self.enabled : enabled // ignore: cast_nullable_to_non_nullable
as bool,exit: freezed == exit ? _self.exit : exit // ignore: cast_nullable_to_non_nullable
as TailnetExitRef?,acceptRoutes: null == acceptRoutes ? _self.acceptRoutes : acceptRoutes // ignore: cast_nullable_to_non_nullable
as bool,magicDns: null == magicDns ? _self.magicDns : magicDns // ignore: cast_nullable_to_non_nullable
as bool,advertiseExit: null == advertiseExit ? _self.advertiseExit : advertiseExit // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$DeviceSettings {

// General.
/// `zh` or `en`; null until the first launch picks the system language.
 String? get locale; Appearance get appearance;// Start-up.
 bool get launchAtStartup; bool get silentStart; bool get autoConnect; bool get keepOnClose; bool get speedNotification;// Proxy.
 bool get systemProxy; bool get allowLan; int get mixedPort;// Latency test.
 String get testUrl; int get testTimeoutMs;// TUN.
 bool get tunEnabled; TunStack get tunStack; int get mtu; bool get autoRoute; bool get strictRoute;// DNS.
 String get remoteDns; String get directDns; bool get fakeIp; DnsStrategy get dnsStrategy;// Routing.
 bool get sniff; bool get sniffOverrideDestination; bool get bypassLan; bool get ipv6; bool get findProcess;// Clash API.
 bool get clashApi; String get clashApiListen;/// Generated on first launch (PRODUCT_SPEC §3.10).
 Secret? get clashApiSecret;// Core.
 LogLevel get logLevel;// Per-app proxy (empty list: everything follows the rules, D13).
 PerAppMode get perAppMode; List<String> get perAppList;// Running choices (DATA_MODEL §2: stored with the device settings).
 String? get selectedConfigurationId; OutboundMode get mode; TailnetSettings get tailnet;
/// Create a copy of DeviceSettings
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeviceSettingsCopyWith<DeviceSettings> get copyWith => _$DeviceSettingsCopyWithImpl<DeviceSettings>(this as DeviceSettings, _$identity);

  /// Serializes this DeviceSettings to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeviceSettings&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.appearance, appearance) || other.appearance == appearance)&&(identical(other.launchAtStartup, launchAtStartup) || other.launchAtStartup == launchAtStartup)&&(identical(other.silentStart, silentStart) || other.silentStart == silentStart)&&(identical(other.autoConnect, autoConnect) || other.autoConnect == autoConnect)&&(identical(other.keepOnClose, keepOnClose) || other.keepOnClose == keepOnClose)&&(identical(other.speedNotification, speedNotification) || other.speedNotification == speedNotification)&&(identical(other.systemProxy, systemProxy) || other.systemProxy == systemProxy)&&(identical(other.allowLan, allowLan) || other.allowLan == allowLan)&&(identical(other.mixedPort, mixedPort) || other.mixedPort == mixedPort)&&(identical(other.testUrl, testUrl) || other.testUrl == testUrl)&&(identical(other.testTimeoutMs, testTimeoutMs) || other.testTimeoutMs == testTimeoutMs)&&(identical(other.tunEnabled, tunEnabled) || other.tunEnabled == tunEnabled)&&(identical(other.tunStack, tunStack) || other.tunStack == tunStack)&&(identical(other.mtu, mtu) || other.mtu == mtu)&&(identical(other.autoRoute, autoRoute) || other.autoRoute == autoRoute)&&(identical(other.strictRoute, strictRoute) || other.strictRoute == strictRoute)&&(identical(other.remoteDns, remoteDns) || other.remoteDns == remoteDns)&&(identical(other.directDns, directDns) || other.directDns == directDns)&&(identical(other.fakeIp, fakeIp) || other.fakeIp == fakeIp)&&(identical(other.dnsStrategy, dnsStrategy) || other.dnsStrategy == dnsStrategy)&&(identical(other.sniff, sniff) || other.sniff == sniff)&&(identical(other.sniffOverrideDestination, sniffOverrideDestination) || other.sniffOverrideDestination == sniffOverrideDestination)&&(identical(other.bypassLan, bypassLan) || other.bypassLan == bypassLan)&&(identical(other.ipv6, ipv6) || other.ipv6 == ipv6)&&(identical(other.findProcess, findProcess) || other.findProcess == findProcess)&&(identical(other.clashApi, clashApi) || other.clashApi == clashApi)&&(identical(other.clashApiListen, clashApiListen) || other.clashApiListen == clashApiListen)&&(identical(other.clashApiSecret, clashApiSecret) || other.clashApiSecret == clashApiSecret)&&(identical(other.logLevel, logLevel) || other.logLevel == logLevel)&&(identical(other.perAppMode, perAppMode) || other.perAppMode == perAppMode)&&const DeepCollectionEquality().equals(other.perAppList, perAppList)&&(identical(other.selectedConfigurationId, selectedConfigurationId) || other.selectedConfigurationId == selectedConfigurationId)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.tailnet, tailnet) || other.tailnet == tailnet));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,locale,appearance,launchAtStartup,silentStart,autoConnect,keepOnClose,speedNotification,systemProxy,allowLan,mixedPort,testUrl,testTimeoutMs,tunEnabled,tunStack,mtu,autoRoute,strictRoute,remoteDns,directDns,fakeIp,dnsStrategy,sniff,sniffOverrideDestination,bypassLan,ipv6,findProcess,clashApi,clashApiListen,clashApiSecret,logLevel,perAppMode,const DeepCollectionEquality().hash(perAppList),selectedConfigurationId,mode,tailnet]);

@override
String toString() {
  return 'DeviceSettings(locale: $locale, appearance: $appearance, launchAtStartup: $launchAtStartup, silentStart: $silentStart, autoConnect: $autoConnect, keepOnClose: $keepOnClose, speedNotification: $speedNotification, systemProxy: $systemProxy, allowLan: $allowLan, mixedPort: $mixedPort, testUrl: $testUrl, testTimeoutMs: $testTimeoutMs, tunEnabled: $tunEnabled, tunStack: $tunStack, mtu: $mtu, autoRoute: $autoRoute, strictRoute: $strictRoute, remoteDns: $remoteDns, directDns: $directDns, fakeIp: $fakeIp, dnsStrategy: $dnsStrategy, sniff: $sniff, sniffOverrideDestination: $sniffOverrideDestination, bypassLan: $bypassLan, ipv6: $ipv6, findProcess: $findProcess, clashApi: $clashApi, clashApiListen: $clashApiListen, clashApiSecret: $clashApiSecret, logLevel: $logLevel, perAppMode: $perAppMode, perAppList: $perAppList, selectedConfigurationId: $selectedConfigurationId, mode: $mode, tailnet: $tailnet)';
}


}

/// @nodoc
abstract mixin class $DeviceSettingsCopyWith<$Res>  {
  factory $DeviceSettingsCopyWith(DeviceSettings value, $Res Function(DeviceSettings) _then) = _$DeviceSettingsCopyWithImpl;
@useResult
$Res call({
 String? locale, Appearance appearance, bool launchAtStartup, bool silentStart, bool autoConnect, bool keepOnClose, bool speedNotification, bool systemProxy, bool allowLan, int mixedPort, String testUrl, int testTimeoutMs, bool tunEnabled, TunStack tunStack, int mtu, bool autoRoute, bool strictRoute, String remoteDns, String directDns, bool fakeIp, DnsStrategy dnsStrategy, bool sniff, bool sniffOverrideDestination, bool bypassLan, bool ipv6, bool findProcess, bool clashApi, String clashApiListen, Secret? clashApiSecret, LogLevel logLevel, PerAppMode perAppMode, List<String> perAppList, String? selectedConfigurationId, OutboundMode mode, TailnetSettings tailnet
});


$TailnetSettingsCopyWith<$Res> get tailnet;

}
/// @nodoc
class _$DeviceSettingsCopyWithImpl<$Res>
    implements $DeviceSettingsCopyWith<$Res> {
  _$DeviceSettingsCopyWithImpl(this._self, this._then);

  final DeviceSettings _self;
  final $Res Function(DeviceSettings) _then;

/// Create a copy of DeviceSettings
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? locale = freezed,Object? appearance = null,Object? launchAtStartup = null,Object? silentStart = null,Object? autoConnect = null,Object? keepOnClose = null,Object? speedNotification = null,Object? systemProxy = null,Object? allowLan = null,Object? mixedPort = null,Object? testUrl = null,Object? testTimeoutMs = null,Object? tunEnabled = null,Object? tunStack = null,Object? mtu = null,Object? autoRoute = null,Object? strictRoute = null,Object? remoteDns = null,Object? directDns = null,Object? fakeIp = null,Object? dnsStrategy = null,Object? sniff = null,Object? sniffOverrideDestination = null,Object? bypassLan = null,Object? ipv6 = null,Object? findProcess = null,Object? clashApi = null,Object? clashApiListen = null,Object? clashApiSecret = freezed,Object? logLevel = null,Object? perAppMode = null,Object? perAppList = null,Object? selectedConfigurationId = freezed,Object? mode = null,Object? tailnet = null,}) {
  return _then(_self.copyWith(
locale: freezed == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String?,appearance: null == appearance ? _self.appearance : appearance // ignore: cast_nullable_to_non_nullable
as Appearance,launchAtStartup: null == launchAtStartup ? _self.launchAtStartup : launchAtStartup // ignore: cast_nullable_to_non_nullable
as bool,silentStart: null == silentStart ? _self.silentStart : silentStart // ignore: cast_nullable_to_non_nullable
as bool,autoConnect: null == autoConnect ? _self.autoConnect : autoConnect // ignore: cast_nullable_to_non_nullable
as bool,keepOnClose: null == keepOnClose ? _self.keepOnClose : keepOnClose // ignore: cast_nullable_to_non_nullable
as bool,speedNotification: null == speedNotification ? _self.speedNotification : speedNotification // ignore: cast_nullable_to_non_nullable
as bool,systemProxy: null == systemProxy ? _self.systemProxy : systemProxy // ignore: cast_nullable_to_non_nullable
as bool,allowLan: null == allowLan ? _self.allowLan : allowLan // ignore: cast_nullable_to_non_nullable
as bool,mixedPort: null == mixedPort ? _self.mixedPort : mixedPort // ignore: cast_nullable_to_non_nullable
as int,testUrl: null == testUrl ? _self.testUrl : testUrl // ignore: cast_nullable_to_non_nullable
as String,testTimeoutMs: null == testTimeoutMs ? _self.testTimeoutMs : testTimeoutMs // ignore: cast_nullable_to_non_nullable
as int,tunEnabled: null == tunEnabled ? _self.tunEnabled : tunEnabled // ignore: cast_nullable_to_non_nullable
as bool,tunStack: null == tunStack ? _self.tunStack : tunStack // ignore: cast_nullable_to_non_nullable
as TunStack,mtu: null == mtu ? _self.mtu : mtu // ignore: cast_nullable_to_non_nullable
as int,autoRoute: null == autoRoute ? _self.autoRoute : autoRoute // ignore: cast_nullable_to_non_nullable
as bool,strictRoute: null == strictRoute ? _self.strictRoute : strictRoute // ignore: cast_nullable_to_non_nullable
as bool,remoteDns: null == remoteDns ? _self.remoteDns : remoteDns // ignore: cast_nullable_to_non_nullable
as String,directDns: null == directDns ? _self.directDns : directDns // ignore: cast_nullable_to_non_nullable
as String,fakeIp: null == fakeIp ? _self.fakeIp : fakeIp // ignore: cast_nullable_to_non_nullable
as bool,dnsStrategy: null == dnsStrategy ? _self.dnsStrategy : dnsStrategy // ignore: cast_nullable_to_non_nullable
as DnsStrategy,sniff: null == sniff ? _self.sniff : sniff // ignore: cast_nullable_to_non_nullable
as bool,sniffOverrideDestination: null == sniffOverrideDestination ? _self.sniffOverrideDestination : sniffOverrideDestination // ignore: cast_nullable_to_non_nullable
as bool,bypassLan: null == bypassLan ? _self.bypassLan : bypassLan // ignore: cast_nullable_to_non_nullable
as bool,ipv6: null == ipv6 ? _self.ipv6 : ipv6 // ignore: cast_nullable_to_non_nullable
as bool,findProcess: null == findProcess ? _self.findProcess : findProcess // ignore: cast_nullable_to_non_nullable
as bool,clashApi: null == clashApi ? _self.clashApi : clashApi // ignore: cast_nullable_to_non_nullable
as bool,clashApiListen: null == clashApiListen ? _self.clashApiListen : clashApiListen // ignore: cast_nullable_to_non_nullable
as String,clashApiSecret: freezed == clashApiSecret ? _self.clashApiSecret : clashApiSecret // ignore: cast_nullable_to_non_nullable
as Secret?,logLevel: null == logLevel ? _self.logLevel : logLevel // ignore: cast_nullable_to_non_nullable
as LogLevel,perAppMode: null == perAppMode ? _self.perAppMode : perAppMode // ignore: cast_nullable_to_non_nullable
as PerAppMode,perAppList: null == perAppList ? _self.perAppList : perAppList // ignore: cast_nullable_to_non_nullable
as List<String>,selectedConfigurationId: freezed == selectedConfigurationId ? _self.selectedConfigurationId : selectedConfigurationId // ignore: cast_nullable_to_non_nullable
as String?,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as OutboundMode,tailnet: null == tailnet ? _self.tailnet : tailnet // ignore: cast_nullable_to_non_nullable
as TailnetSettings,
  ));
}
/// Create a copy of DeviceSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TailnetSettingsCopyWith<$Res> get tailnet {
  
  return $TailnetSettingsCopyWith<$Res>(_self.tailnet, (value) {
    return _then(_self.copyWith(tailnet: value));
  });
}
}


/// Adds pattern-matching-related methods to [DeviceSettings].
extension DeviceSettingsPatterns on DeviceSettings {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeviceSettings value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeviceSettings() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeviceSettings value)  $default,){
final _that = this;
switch (_that) {
case _DeviceSettings():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeviceSettings value)?  $default,){
final _that = this;
switch (_that) {
case _DeviceSettings() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? locale,  Appearance appearance,  bool launchAtStartup,  bool silentStart,  bool autoConnect,  bool keepOnClose,  bool speedNotification,  bool systemProxy,  bool allowLan,  int mixedPort,  String testUrl,  int testTimeoutMs,  bool tunEnabled,  TunStack tunStack,  int mtu,  bool autoRoute,  bool strictRoute,  String remoteDns,  String directDns,  bool fakeIp,  DnsStrategy dnsStrategy,  bool sniff,  bool sniffOverrideDestination,  bool bypassLan,  bool ipv6,  bool findProcess,  bool clashApi,  String clashApiListen,  Secret? clashApiSecret,  LogLevel logLevel,  PerAppMode perAppMode,  List<String> perAppList,  String? selectedConfigurationId,  OutboundMode mode,  TailnetSettings tailnet)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeviceSettings() when $default != null:
return $default(_that.locale,_that.appearance,_that.launchAtStartup,_that.silentStart,_that.autoConnect,_that.keepOnClose,_that.speedNotification,_that.systemProxy,_that.allowLan,_that.mixedPort,_that.testUrl,_that.testTimeoutMs,_that.tunEnabled,_that.tunStack,_that.mtu,_that.autoRoute,_that.strictRoute,_that.remoteDns,_that.directDns,_that.fakeIp,_that.dnsStrategy,_that.sniff,_that.sniffOverrideDestination,_that.bypassLan,_that.ipv6,_that.findProcess,_that.clashApi,_that.clashApiListen,_that.clashApiSecret,_that.logLevel,_that.perAppMode,_that.perAppList,_that.selectedConfigurationId,_that.mode,_that.tailnet);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? locale,  Appearance appearance,  bool launchAtStartup,  bool silentStart,  bool autoConnect,  bool keepOnClose,  bool speedNotification,  bool systemProxy,  bool allowLan,  int mixedPort,  String testUrl,  int testTimeoutMs,  bool tunEnabled,  TunStack tunStack,  int mtu,  bool autoRoute,  bool strictRoute,  String remoteDns,  String directDns,  bool fakeIp,  DnsStrategy dnsStrategy,  bool sniff,  bool sniffOverrideDestination,  bool bypassLan,  bool ipv6,  bool findProcess,  bool clashApi,  String clashApiListen,  Secret? clashApiSecret,  LogLevel logLevel,  PerAppMode perAppMode,  List<String> perAppList,  String? selectedConfigurationId,  OutboundMode mode,  TailnetSettings tailnet)  $default,) {final _that = this;
switch (_that) {
case _DeviceSettings():
return $default(_that.locale,_that.appearance,_that.launchAtStartup,_that.silentStart,_that.autoConnect,_that.keepOnClose,_that.speedNotification,_that.systemProxy,_that.allowLan,_that.mixedPort,_that.testUrl,_that.testTimeoutMs,_that.tunEnabled,_that.tunStack,_that.mtu,_that.autoRoute,_that.strictRoute,_that.remoteDns,_that.directDns,_that.fakeIp,_that.dnsStrategy,_that.sniff,_that.sniffOverrideDestination,_that.bypassLan,_that.ipv6,_that.findProcess,_that.clashApi,_that.clashApiListen,_that.clashApiSecret,_that.logLevel,_that.perAppMode,_that.perAppList,_that.selectedConfigurationId,_that.mode,_that.tailnet);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? locale,  Appearance appearance,  bool launchAtStartup,  bool silentStart,  bool autoConnect,  bool keepOnClose,  bool speedNotification,  bool systemProxy,  bool allowLan,  int mixedPort,  String testUrl,  int testTimeoutMs,  bool tunEnabled,  TunStack tunStack,  int mtu,  bool autoRoute,  bool strictRoute,  String remoteDns,  String directDns,  bool fakeIp,  DnsStrategy dnsStrategy,  bool sniff,  bool sniffOverrideDestination,  bool bypassLan,  bool ipv6,  bool findProcess,  bool clashApi,  String clashApiListen,  Secret? clashApiSecret,  LogLevel logLevel,  PerAppMode perAppMode,  List<String> perAppList,  String? selectedConfigurationId,  OutboundMode mode,  TailnetSettings tailnet)?  $default,) {final _that = this;
switch (_that) {
case _DeviceSettings() when $default != null:
return $default(_that.locale,_that.appearance,_that.launchAtStartup,_that.silentStart,_that.autoConnect,_that.keepOnClose,_that.speedNotification,_that.systemProxy,_that.allowLan,_that.mixedPort,_that.testUrl,_that.testTimeoutMs,_that.tunEnabled,_that.tunStack,_that.mtu,_that.autoRoute,_that.strictRoute,_that.remoteDns,_that.directDns,_that.fakeIp,_that.dnsStrategy,_that.sniff,_that.sniffOverrideDestination,_that.bypassLan,_that.ipv6,_that.findProcess,_that.clashApi,_that.clashApiListen,_that.clashApiSecret,_that.logLevel,_that.perAppMode,_that.perAppList,_that.selectedConfigurationId,_that.mode,_that.tailnet);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeviceSettings implements DeviceSettings {
  const _DeviceSettings({this.locale, this.appearance = Appearance.light, this.launchAtStartup = true, this.silentStart = false, this.autoConnect = false, this.keepOnClose = true, this.speedNotification = true, this.systemProxy = false, this.allowLan = false, this.mixedPort = 7890, this.testUrl = 'https://www.gstatic.com/generate_204', this.testTimeoutMs = 5000, this.tunEnabled = true, this.tunStack = TunStack.mixed, this.mtu = 9000, this.autoRoute = true, this.strictRoute = true, this.remoteDns = 'https://1.1.1.1/dns-query', this.directDns = '223.5.5.5', this.fakeIp = true, this.dnsStrategy = DnsStrategy.preferIpv4, this.sniff = true, this.sniffOverrideDestination = false, this.bypassLan = true, this.ipv6 = false, this.findProcess = true, this.clashApi = true, this.clashApiListen = '127.0.0.1:9090', this.clashApiSecret, this.logLevel = LogLevel.info, this.perAppMode = PerAppMode.whitelist, final  List<String> perAppList = const <String>[], this.selectedConfigurationId, this.mode = OutboundMode.rule, this.tailnet = const TailnetSettings()}): _perAppList = perAppList;
  factory _DeviceSettings.fromJson(Map<String, dynamic> json) => _$DeviceSettingsFromJson(json);

// General.
/// `zh` or `en`; null until the first launch picks the system language.
@override final  String? locale;
@override@JsonKey() final  Appearance appearance;
// Start-up.
@override@JsonKey() final  bool launchAtStartup;
@override@JsonKey() final  bool silentStart;
@override@JsonKey() final  bool autoConnect;
@override@JsonKey() final  bool keepOnClose;
@override@JsonKey() final  bool speedNotification;
// Proxy.
@override@JsonKey() final  bool systemProxy;
@override@JsonKey() final  bool allowLan;
@override@JsonKey() final  int mixedPort;
// Latency test.
@override@JsonKey() final  String testUrl;
@override@JsonKey() final  int testTimeoutMs;
// TUN.
@override@JsonKey() final  bool tunEnabled;
@override@JsonKey() final  TunStack tunStack;
@override@JsonKey() final  int mtu;
@override@JsonKey() final  bool autoRoute;
@override@JsonKey() final  bool strictRoute;
// DNS.
@override@JsonKey() final  String remoteDns;
@override@JsonKey() final  String directDns;
@override@JsonKey() final  bool fakeIp;
@override@JsonKey() final  DnsStrategy dnsStrategy;
// Routing.
@override@JsonKey() final  bool sniff;
@override@JsonKey() final  bool sniffOverrideDestination;
@override@JsonKey() final  bool bypassLan;
@override@JsonKey() final  bool ipv6;
@override@JsonKey() final  bool findProcess;
// Clash API.
@override@JsonKey() final  bool clashApi;
@override@JsonKey() final  String clashApiListen;
/// Generated on first launch (PRODUCT_SPEC §3.10).
@override final  Secret? clashApiSecret;
// Core.
@override@JsonKey() final  LogLevel logLevel;
// Per-app proxy (empty list: everything follows the rules, D13).
@override@JsonKey() final  PerAppMode perAppMode;
 final  List<String> _perAppList;
@override@JsonKey() List<String> get perAppList {
  if (_perAppList is EqualUnmodifiableListView) return _perAppList;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_perAppList);
}

// Running choices (DATA_MODEL §2: stored with the device settings).
@override final  String? selectedConfigurationId;
@override@JsonKey() final  OutboundMode mode;
@override@JsonKey() final  TailnetSettings tailnet;

/// Create a copy of DeviceSettings
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeviceSettingsCopyWith<_DeviceSettings> get copyWith => __$DeviceSettingsCopyWithImpl<_DeviceSettings>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeviceSettingsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeviceSettings&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.appearance, appearance) || other.appearance == appearance)&&(identical(other.launchAtStartup, launchAtStartup) || other.launchAtStartup == launchAtStartup)&&(identical(other.silentStart, silentStart) || other.silentStart == silentStart)&&(identical(other.autoConnect, autoConnect) || other.autoConnect == autoConnect)&&(identical(other.keepOnClose, keepOnClose) || other.keepOnClose == keepOnClose)&&(identical(other.speedNotification, speedNotification) || other.speedNotification == speedNotification)&&(identical(other.systemProxy, systemProxy) || other.systemProxy == systemProxy)&&(identical(other.allowLan, allowLan) || other.allowLan == allowLan)&&(identical(other.mixedPort, mixedPort) || other.mixedPort == mixedPort)&&(identical(other.testUrl, testUrl) || other.testUrl == testUrl)&&(identical(other.testTimeoutMs, testTimeoutMs) || other.testTimeoutMs == testTimeoutMs)&&(identical(other.tunEnabled, tunEnabled) || other.tunEnabled == tunEnabled)&&(identical(other.tunStack, tunStack) || other.tunStack == tunStack)&&(identical(other.mtu, mtu) || other.mtu == mtu)&&(identical(other.autoRoute, autoRoute) || other.autoRoute == autoRoute)&&(identical(other.strictRoute, strictRoute) || other.strictRoute == strictRoute)&&(identical(other.remoteDns, remoteDns) || other.remoteDns == remoteDns)&&(identical(other.directDns, directDns) || other.directDns == directDns)&&(identical(other.fakeIp, fakeIp) || other.fakeIp == fakeIp)&&(identical(other.dnsStrategy, dnsStrategy) || other.dnsStrategy == dnsStrategy)&&(identical(other.sniff, sniff) || other.sniff == sniff)&&(identical(other.sniffOverrideDestination, sniffOverrideDestination) || other.sniffOverrideDestination == sniffOverrideDestination)&&(identical(other.bypassLan, bypassLan) || other.bypassLan == bypassLan)&&(identical(other.ipv6, ipv6) || other.ipv6 == ipv6)&&(identical(other.findProcess, findProcess) || other.findProcess == findProcess)&&(identical(other.clashApi, clashApi) || other.clashApi == clashApi)&&(identical(other.clashApiListen, clashApiListen) || other.clashApiListen == clashApiListen)&&(identical(other.clashApiSecret, clashApiSecret) || other.clashApiSecret == clashApiSecret)&&(identical(other.logLevel, logLevel) || other.logLevel == logLevel)&&(identical(other.perAppMode, perAppMode) || other.perAppMode == perAppMode)&&const DeepCollectionEquality().equals(other._perAppList, _perAppList)&&(identical(other.selectedConfigurationId, selectedConfigurationId) || other.selectedConfigurationId == selectedConfigurationId)&&(identical(other.mode, mode) || other.mode == mode)&&(identical(other.tailnet, tailnet) || other.tailnet == tailnet));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hashAll([runtimeType,locale,appearance,launchAtStartup,silentStart,autoConnect,keepOnClose,speedNotification,systemProxy,allowLan,mixedPort,testUrl,testTimeoutMs,tunEnabled,tunStack,mtu,autoRoute,strictRoute,remoteDns,directDns,fakeIp,dnsStrategy,sniff,sniffOverrideDestination,bypassLan,ipv6,findProcess,clashApi,clashApiListen,clashApiSecret,logLevel,perAppMode,const DeepCollectionEquality().hash(_perAppList),selectedConfigurationId,mode,tailnet]);

@override
String toString() {
  return 'DeviceSettings(locale: $locale, appearance: $appearance, launchAtStartup: $launchAtStartup, silentStart: $silentStart, autoConnect: $autoConnect, keepOnClose: $keepOnClose, speedNotification: $speedNotification, systemProxy: $systemProxy, allowLan: $allowLan, mixedPort: $mixedPort, testUrl: $testUrl, testTimeoutMs: $testTimeoutMs, tunEnabled: $tunEnabled, tunStack: $tunStack, mtu: $mtu, autoRoute: $autoRoute, strictRoute: $strictRoute, remoteDns: $remoteDns, directDns: $directDns, fakeIp: $fakeIp, dnsStrategy: $dnsStrategy, sniff: $sniff, sniffOverrideDestination: $sniffOverrideDestination, bypassLan: $bypassLan, ipv6: $ipv6, findProcess: $findProcess, clashApi: $clashApi, clashApiListen: $clashApiListen, clashApiSecret: $clashApiSecret, logLevel: $logLevel, perAppMode: $perAppMode, perAppList: $perAppList, selectedConfigurationId: $selectedConfigurationId, mode: $mode, tailnet: $tailnet)';
}


}

/// @nodoc
abstract mixin class _$DeviceSettingsCopyWith<$Res> implements $DeviceSettingsCopyWith<$Res> {
  factory _$DeviceSettingsCopyWith(_DeviceSettings value, $Res Function(_DeviceSettings) _then) = __$DeviceSettingsCopyWithImpl;
@override @useResult
$Res call({
 String? locale, Appearance appearance, bool launchAtStartup, bool silentStart, bool autoConnect, bool keepOnClose, bool speedNotification, bool systemProxy, bool allowLan, int mixedPort, String testUrl, int testTimeoutMs, bool tunEnabled, TunStack tunStack, int mtu, bool autoRoute, bool strictRoute, String remoteDns, String directDns, bool fakeIp, DnsStrategy dnsStrategy, bool sniff, bool sniffOverrideDestination, bool bypassLan, bool ipv6, bool findProcess, bool clashApi, String clashApiListen, Secret? clashApiSecret, LogLevel logLevel, PerAppMode perAppMode, List<String> perAppList, String? selectedConfigurationId, OutboundMode mode, TailnetSettings tailnet
});


@override $TailnetSettingsCopyWith<$Res> get tailnet;

}
/// @nodoc
class __$DeviceSettingsCopyWithImpl<$Res>
    implements _$DeviceSettingsCopyWith<$Res> {
  __$DeviceSettingsCopyWithImpl(this._self, this._then);

  final _DeviceSettings _self;
  final $Res Function(_DeviceSettings) _then;

/// Create a copy of DeviceSettings
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? locale = freezed,Object? appearance = null,Object? launchAtStartup = null,Object? silentStart = null,Object? autoConnect = null,Object? keepOnClose = null,Object? speedNotification = null,Object? systemProxy = null,Object? allowLan = null,Object? mixedPort = null,Object? testUrl = null,Object? testTimeoutMs = null,Object? tunEnabled = null,Object? tunStack = null,Object? mtu = null,Object? autoRoute = null,Object? strictRoute = null,Object? remoteDns = null,Object? directDns = null,Object? fakeIp = null,Object? dnsStrategy = null,Object? sniff = null,Object? sniffOverrideDestination = null,Object? bypassLan = null,Object? ipv6 = null,Object? findProcess = null,Object? clashApi = null,Object? clashApiListen = null,Object? clashApiSecret = freezed,Object? logLevel = null,Object? perAppMode = null,Object? perAppList = null,Object? selectedConfigurationId = freezed,Object? mode = null,Object? tailnet = null,}) {
  return _then(_DeviceSettings(
locale: freezed == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as String?,appearance: null == appearance ? _self.appearance : appearance // ignore: cast_nullable_to_non_nullable
as Appearance,launchAtStartup: null == launchAtStartup ? _self.launchAtStartup : launchAtStartup // ignore: cast_nullable_to_non_nullable
as bool,silentStart: null == silentStart ? _self.silentStart : silentStart // ignore: cast_nullable_to_non_nullable
as bool,autoConnect: null == autoConnect ? _self.autoConnect : autoConnect // ignore: cast_nullable_to_non_nullable
as bool,keepOnClose: null == keepOnClose ? _self.keepOnClose : keepOnClose // ignore: cast_nullable_to_non_nullable
as bool,speedNotification: null == speedNotification ? _self.speedNotification : speedNotification // ignore: cast_nullable_to_non_nullable
as bool,systemProxy: null == systemProxy ? _self.systemProxy : systemProxy // ignore: cast_nullable_to_non_nullable
as bool,allowLan: null == allowLan ? _self.allowLan : allowLan // ignore: cast_nullable_to_non_nullable
as bool,mixedPort: null == mixedPort ? _self.mixedPort : mixedPort // ignore: cast_nullable_to_non_nullable
as int,testUrl: null == testUrl ? _self.testUrl : testUrl // ignore: cast_nullable_to_non_nullable
as String,testTimeoutMs: null == testTimeoutMs ? _self.testTimeoutMs : testTimeoutMs // ignore: cast_nullable_to_non_nullable
as int,tunEnabled: null == tunEnabled ? _self.tunEnabled : tunEnabled // ignore: cast_nullable_to_non_nullable
as bool,tunStack: null == tunStack ? _self.tunStack : tunStack // ignore: cast_nullable_to_non_nullable
as TunStack,mtu: null == mtu ? _self.mtu : mtu // ignore: cast_nullable_to_non_nullable
as int,autoRoute: null == autoRoute ? _self.autoRoute : autoRoute // ignore: cast_nullable_to_non_nullable
as bool,strictRoute: null == strictRoute ? _self.strictRoute : strictRoute // ignore: cast_nullable_to_non_nullable
as bool,remoteDns: null == remoteDns ? _self.remoteDns : remoteDns // ignore: cast_nullable_to_non_nullable
as String,directDns: null == directDns ? _self.directDns : directDns // ignore: cast_nullable_to_non_nullable
as String,fakeIp: null == fakeIp ? _self.fakeIp : fakeIp // ignore: cast_nullable_to_non_nullable
as bool,dnsStrategy: null == dnsStrategy ? _self.dnsStrategy : dnsStrategy // ignore: cast_nullable_to_non_nullable
as DnsStrategy,sniff: null == sniff ? _self.sniff : sniff // ignore: cast_nullable_to_non_nullable
as bool,sniffOverrideDestination: null == sniffOverrideDestination ? _self.sniffOverrideDestination : sniffOverrideDestination // ignore: cast_nullable_to_non_nullable
as bool,bypassLan: null == bypassLan ? _self.bypassLan : bypassLan // ignore: cast_nullable_to_non_nullable
as bool,ipv6: null == ipv6 ? _self.ipv6 : ipv6 // ignore: cast_nullable_to_non_nullable
as bool,findProcess: null == findProcess ? _self.findProcess : findProcess // ignore: cast_nullable_to_non_nullable
as bool,clashApi: null == clashApi ? _self.clashApi : clashApi // ignore: cast_nullable_to_non_nullable
as bool,clashApiListen: null == clashApiListen ? _self.clashApiListen : clashApiListen // ignore: cast_nullable_to_non_nullable
as String,clashApiSecret: freezed == clashApiSecret ? _self.clashApiSecret : clashApiSecret // ignore: cast_nullable_to_non_nullable
as Secret?,logLevel: null == logLevel ? _self.logLevel : logLevel // ignore: cast_nullable_to_non_nullable
as LogLevel,perAppMode: null == perAppMode ? _self.perAppMode : perAppMode // ignore: cast_nullable_to_non_nullable
as PerAppMode,perAppList: null == perAppList ? _self._perAppList : perAppList // ignore: cast_nullable_to_non_nullable
as List<String>,selectedConfigurationId: freezed == selectedConfigurationId ? _self.selectedConfigurationId : selectedConfigurationId // ignore: cast_nullable_to_non_nullable
as String?,mode: null == mode ? _self.mode : mode // ignore: cast_nullable_to_non_nullable
as OutboundMode,tailnet: null == tailnet ? _self.tailnet : tailnet // ignore: cast_nullable_to_non_nullable
as TailnetSettings,
  ));
}

/// Create a copy of DeviceSettings
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TailnetSettingsCopyWith<$Res> get tailnet {
  
  return $TailnetSettingsCopyWith<$Res>(_self.tailnet, (value) {
    return _then(_self.copyWith(tailnet: value));
  });
}
}


/// @nodoc
mixin _$Policy {

/// sing-box JSON fragment merged into imported configurations (D19).
 Secret? get jsonOverride; bool get geoAutoUpdate; GeoInterval get geoInterval; DownloadVia get geoVia;
/// Create a copy of Policy
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PolicyCopyWith<Policy> get copyWith => _$PolicyCopyWithImpl<Policy>(this as Policy, _$identity);

  /// Serializes this Policy to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Policy&&(identical(other.jsonOverride, jsonOverride) || other.jsonOverride == jsonOverride)&&(identical(other.geoAutoUpdate, geoAutoUpdate) || other.geoAutoUpdate == geoAutoUpdate)&&(identical(other.geoInterval, geoInterval) || other.geoInterval == geoInterval)&&(identical(other.geoVia, geoVia) || other.geoVia == geoVia));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,jsonOverride,geoAutoUpdate,geoInterval,geoVia);

@override
String toString() {
  return 'Policy(jsonOverride: $jsonOverride, geoAutoUpdate: $geoAutoUpdate, geoInterval: $geoInterval, geoVia: $geoVia)';
}


}

/// @nodoc
abstract mixin class $PolicyCopyWith<$Res>  {
  factory $PolicyCopyWith(Policy value, $Res Function(Policy) _then) = _$PolicyCopyWithImpl;
@useResult
$Res call({
 Secret? jsonOverride, bool geoAutoUpdate, GeoInterval geoInterval, DownloadVia geoVia
});




}
/// @nodoc
class _$PolicyCopyWithImpl<$Res>
    implements $PolicyCopyWith<$Res> {
  _$PolicyCopyWithImpl(this._self, this._then);

  final Policy _self;
  final $Res Function(Policy) _then;

/// Create a copy of Policy
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? jsonOverride = freezed,Object? geoAutoUpdate = null,Object? geoInterval = null,Object? geoVia = null,}) {
  return _then(_self.copyWith(
jsonOverride: freezed == jsonOverride ? _self.jsonOverride : jsonOverride // ignore: cast_nullable_to_non_nullable
as Secret?,geoAutoUpdate: null == geoAutoUpdate ? _self.geoAutoUpdate : geoAutoUpdate // ignore: cast_nullable_to_non_nullable
as bool,geoInterval: null == geoInterval ? _self.geoInterval : geoInterval // ignore: cast_nullable_to_non_nullable
as GeoInterval,geoVia: null == geoVia ? _self.geoVia : geoVia // ignore: cast_nullable_to_non_nullable
as DownloadVia,
  ));
}

}


/// Adds pattern-matching-related methods to [Policy].
extension PolicyPatterns on Policy {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Policy value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Policy() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Policy value)  $default,){
final _that = this;
switch (_that) {
case _Policy():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Policy value)?  $default,){
final _that = this;
switch (_that) {
case _Policy() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Secret? jsonOverride,  bool geoAutoUpdate,  GeoInterval geoInterval,  DownloadVia geoVia)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Policy() when $default != null:
return $default(_that.jsonOverride,_that.geoAutoUpdate,_that.geoInterval,_that.geoVia);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Secret? jsonOverride,  bool geoAutoUpdate,  GeoInterval geoInterval,  DownloadVia geoVia)  $default,) {final _that = this;
switch (_that) {
case _Policy():
return $default(_that.jsonOverride,_that.geoAutoUpdate,_that.geoInterval,_that.geoVia);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Secret? jsonOverride,  bool geoAutoUpdate,  GeoInterval geoInterval,  DownloadVia geoVia)?  $default,) {final _that = this;
switch (_that) {
case _Policy() when $default != null:
return $default(_that.jsonOverride,_that.geoAutoUpdate,_that.geoInterval,_that.geoVia);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Policy implements Policy {
  const _Policy({this.jsonOverride, this.geoAutoUpdate = true, this.geoInterval = GeoInterval.daily, this.geoVia = DownloadVia.proxy});
  factory _Policy.fromJson(Map<String, dynamic> json) => _$PolicyFromJson(json);

/// sing-box JSON fragment merged into imported configurations (D19).
@override final  Secret? jsonOverride;
@override@JsonKey() final  bool geoAutoUpdate;
@override@JsonKey() final  GeoInterval geoInterval;
@override@JsonKey() final  DownloadVia geoVia;

/// Create a copy of Policy
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PolicyCopyWith<_Policy> get copyWith => __$PolicyCopyWithImpl<_Policy>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PolicyToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Policy&&(identical(other.jsonOverride, jsonOverride) || other.jsonOverride == jsonOverride)&&(identical(other.geoAutoUpdate, geoAutoUpdate) || other.geoAutoUpdate == geoAutoUpdate)&&(identical(other.geoInterval, geoInterval) || other.geoInterval == geoInterval)&&(identical(other.geoVia, geoVia) || other.geoVia == geoVia));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,jsonOverride,geoAutoUpdate,geoInterval,geoVia);

@override
String toString() {
  return 'Policy(jsonOverride: $jsonOverride, geoAutoUpdate: $geoAutoUpdate, geoInterval: $geoInterval, geoVia: $geoVia)';
}


}

/// @nodoc
abstract mixin class _$PolicyCopyWith<$Res> implements $PolicyCopyWith<$Res> {
  factory _$PolicyCopyWith(_Policy value, $Res Function(_Policy) _then) = __$PolicyCopyWithImpl;
@override @useResult
$Res call({
 Secret? jsonOverride, bool geoAutoUpdate, GeoInterval geoInterval, DownloadVia geoVia
});




}
/// @nodoc
class __$PolicyCopyWithImpl<$Res>
    implements _$PolicyCopyWith<$Res> {
  __$PolicyCopyWithImpl(this._self, this._then);

  final _Policy _self;
  final $Res Function(_Policy) _then;

/// Create a copy of Policy
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? jsonOverride = freezed,Object? geoAutoUpdate = null,Object? geoInterval = null,Object? geoVia = null,}) {
  return _then(_Policy(
jsonOverride: freezed == jsonOverride ? _self.jsonOverride : jsonOverride // ignore: cast_nullable_to_non_nullable
as Secret?,geoAutoUpdate: null == geoAutoUpdate ? _self.geoAutoUpdate : geoAutoUpdate // ignore: cast_nullable_to_non_nullable
as bool,geoInterval: null == geoInterval ? _self.geoInterval : geoInterval // ignore: cast_nullable_to_non_nullable
as GeoInterval,geoVia: null == geoVia ? _self.geoVia : geoVia // ignore: cast_nullable_to_non_nullable
as DownloadVia,
  ));
}


}

// dart format on
