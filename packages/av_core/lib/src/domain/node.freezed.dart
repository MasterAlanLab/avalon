// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'node.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
Transport _$TransportFromJson(
  Map<String, dynamic> json
) {
        switch (json['type']) {
                  case 'tcp':
          return TcpTransport.fromJson(
            json
          );
                case 'ws':
          return WsTransport.fromJson(
            json
          );
                case 'grpc':
          return GrpcTransport.fromJson(
            json
          );
                case 'http2':
          return Http2Transport.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'type',
  'Transport',
  'Invalid union type "${json['type']}"!'
);
        }
      
}

/// @nodoc
mixin _$Transport {



  /// Serializes this Transport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Transport);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Transport()';
}


}

/// @nodoc
class $TransportCopyWith<$Res>  {
$TransportCopyWith(Transport _, $Res Function(Transport) __);
}


/// Adds pattern-matching-related methods to [Transport].
extension TransportPatterns on Transport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( TcpTransport value)?  tcp,TResult Function( WsTransport value)?  ws,TResult Function( GrpcTransport value)?  grpc,TResult Function( Http2Transport value)?  http2,required TResult orElse(),}){
final _that = this;
switch (_that) {
case TcpTransport() when tcp != null:
return tcp(_that);case WsTransport() when ws != null:
return ws(_that);case GrpcTransport() when grpc != null:
return grpc(_that);case Http2Transport() when http2 != null:
return http2(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( TcpTransport value)  tcp,required TResult Function( WsTransport value)  ws,required TResult Function( GrpcTransport value)  grpc,required TResult Function( Http2Transport value)  http2,}){
final _that = this;
switch (_that) {
case TcpTransport():
return tcp(_that);case WsTransport():
return ws(_that);case GrpcTransport():
return grpc(_that);case Http2Transport():
return http2(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( TcpTransport value)?  tcp,TResult? Function( WsTransport value)?  ws,TResult? Function( GrpcTransport value)?  grpc,TResult? Function( Http2Transport value)?  http2,}){
final _that = this;
switch (_that) {
case TcpTransport() when tcp != null:
return tcp(_that);case WsTransport() when ws != null:
return ws(_that);case GrpcTransport() when grpc != null:
return grpc(_that);case Http2Transport() when http2 != null:
return http2(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  tcp,TResult Function( String path,  String? host,  int maxEarlyData,  String? earlyDataHeader)?  ws,TResult Function( String serviceName)?  grpc,TResult Function( String path,  List<String> host)?  http2,required TResult orElse(),}) {final _that = this;
switch (_that) {
case TcpTransport() when tcp != null:
return tcp();case WsTransport() when ws != null:
return ws(_that.path,_that.host,_that.maxEarlyData,_that.earlyDataHeader);case GrpcTransport() when grpc != null:
return grpc(_that.serviceName);case Http2Transport() when http2 != null:
return http2(_that.path,_that.host);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  tcp,required TResult Function( String path,  String? host,  int maxEarlyData,  String? earlyDataHeader)  ws,required TResult Function( String serviceName)  grpc,required TResult Function( String path,  List<String> host)  http2,}) {final _that = this;
switch (_that) {
case TcpTransport():
return tcp();case WsTransport():
return ws(_that.path,_that.host,_that.maxEarlyData,_that.earlyDataHeader);case GrpcTransport():
return grpc(_that.serviceName);case Http2Transport():
return http2(_that.path,_that.host);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  tcp,TResult? Function( String path,  String? host,  int maxEarlyData,  String? earlyDataHeader)?  ws,TResult? Function( String serviceName)?  grpc,TResult? Function( String path,  List<String> host)?  http2,}) {final _that = this;
switch (_that) {
case TcpTransport() when tcp != null:
return tcp();case WsTransport() when ws != null:
return ws(_that.path,_that.host,_that.maxEarlyData,_that.earlyDataHeader);case GrpcTransport() when grpc != null:
return grpc(_that.serviceName);case Http2Transport() when http2 != null:
return http2(_that.path,_that.host);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class TcpTransport implements Transport {
  const TcpTransport({final  String? $type}): $type = $type ?? 'tcp';
  factory TcpTransport.fromJson(Map<String, dynamic> json) => _$TcpTransportFromJson(json);



@JsonKey(name: 'type')
final String $type;



@override
Map<String, dynamic> toJson() {
  return _$TcpTransportToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TcpTransport);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'Transport.tcp()';
}


}




/// @nodoc
@JsonSerializable()

class WsTransport implements Transport {
  const WsTransport({this.path = '/', this.host, this.maxEarlyData = 0, this.earlyDataHeader, final  String? $type}): $type = $type ?? 'ws';
  factory WsTransport.fromJson(Map<String, dynamic> json) => _$WsTransportFromJson(json);

@JsonKey() final  String path;
 final  String? host;
@JsonKey() final  int maxEarlyData;
 final  String? earlyDataHeader;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of Transport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WsTransportCopyWith<WsTransport> get copyWith => _$WsTransportCopyWithImpl<WsTransport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WsTransportToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WsTransport&&(identical(other.path, path) || other.path == path)&&(identical(other.host, host) || other.host == host)&&(identical(other.maxEarlyData, maxEarlyData) || other.maxEarlyData == maxEarlyData)&&(identical(other.earlyDataHeader, earlyDataHeader) || other.earlyDataHeader == earlyDataHeader));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,host,maxEarlyData,earlyDataHeader);

@override
String toString() {
  return 'Transport.ws(path: $path, host: $host, maxEarlyData: $maxEarlyData, earlyDataHeader: $earlyDataHeader)';
}


}

/// @nodoc
abstract mixin class $WsTransportCopyWith<$Res> implements $TransportCopyWith<$Res> {
  factory $WsTransportCopyWith(WsTransport value, $Res Function(WsTransport) _then) = _$WsTransportCopyWithImpl;
@useResult
$Res call({
 String path, String? host, int maxEarlyData, String? earlyDataHeader
});




}
/// @nodoc
class _$WsTransportCopyWithImpl<$Res>
    implements $WsTransportCopyWith<$Res> {
  _$WsTransportCopyWithImpl(this._self, this._then);

  final WsTransport _self;
  final $Res Function(WsTransport) _then;

/// Create a copy of Transport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? path = null,Object? host = freezed,Object? maxEarlyData = null,Object? earlyDataHeader = freezed,}) {
  return _then(WsTransport(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,host: freezed == host ? _self.host : host // ignore: cast_nullable_to_non_nullable
as String?,maxEarlyData: null == maxEarlyData ? _self.maxEarlyData : maxEarlyData // ignore: cast_nullable_to_non_nullable
as int,earlyDataHeader: freezed == earlyDataHeader ? _self.earlyDataHeader : earlyDataHeader // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class GrpcTransport implements Transport {
  const GrpcTransport({this.serviceName = '', final  String? $type}): $type = $type ?? 'grpc';
  factory GrpcTransport.fromJson(Map<String, dynamic> json) => _$GrpcTransportFromJson(json);

@JsonKey() final  String serviceName;

@JsonKey(name: 'type')
final String $type;


/// Create a copy of Transport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GrpcTransportCopyWith<GrpcTransport> get copyWith => _$GrpcTransportCopyWithImpl<GrpcTransport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GrpcTransportToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GrpcTransport&&(identical(other.serviceName, serviceName) || other.serviceName == serviceName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,serviceName);

@override
String toString() {
  return 'Transport.grpc(serviceName: $serviceName)';
}


}

/// @nodoc
abstract mixin class $GrpcTransportCopyWith<$Res> implements $TransportCopyWith<$Res> {
  factory $GrpcTransportCopyWith(GrpcTransport value, $Res Function(GrpcTransport) _then) = _$GrpcTransportCopyWithImpl;
@useResult
$Res call({
 String serviceName
});




}
/// @nodoc
class _$GrpcTransportCopyWithImpl<$Res>
    implements $GrpcTransportCopyWith<$Res> {
  _$GrpcTransportCopyWithImpl(this._self, this._then);

  final GrpcTransport _self;
  final $Res Function(GrpcTransport) _then;

/// Create a copy of Transport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? serviceName = null,}) {
  return _then(GrpcTransport(
serviceName: null == serviceName ? _self.serviceName : serviceName // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class Http2Transport implements Transport {
  const Http2Transport({this.path = '/', final  List<String> host = const <String>[], final  String? $type}): _host = host,$type = $type ?? 'http2';
  factory Http2Transport.fromJson(Map<String, dynamic> json) => _$Http2TransportFromJson(json);

@JsonKey() final  String path;
 final  List<String> _host;
@JsonKey() List<String> get host {
  if (_host is EqualUnmodifiableListView) return _host;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_host);
}


@JsonKey(name: 'type')
final String $type;


/// Create a copy of Transport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Http2TransportCopyWith<Http2Transport> get copyWith => _$Http2TransportCopyWithImpl<Http2Transport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Http2TransportToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Http2Transport&&(identical(other.path, path) || other.path == path)&&const DeepCollectionEquality().equals(other._host, _host));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,path,const DeepCollectionEquality().hash(_host));

@override
String toString() {
  return 'Transport.http2(path: $path, host: $host)';
}


}

/// @nodoc
abstract mixin class $Http2TransportCopyWith<$Res> implements $TransportCopyWith<$Res> {
  factory $Http2TransportCopyWith(Http2Transport value, $Res Function(Http2Transport) _then) = _$Http2TransportCopyWithImpl;
@useResult
$Res call({
 String path, List<String> host
});




}
/// @nodoc
class _$Http2TransportCopyWithImpl<$Res>
    implements $Http2TransportCopyWith<$Res> {
  _$Http2TransportCopyWithImpl(this._self, this._then);

  final Http2Transport _self;
  final $Res Function(Http2Transport) _then;

/// Create a copy of Transport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? path = null,Object? host = null,}) {
  return _then(Http2Transport(
path: null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,host: null == host ? _self._host : host // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}


/// @nodoc
mixin _$Reality {

 String get publicKey; String? get shortId;
/// Create a copy of Reality
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RealityCopyWith<Reality> get copyWith => _$RealityCopyWithImpl<Reality>(this as Reality, _$identity);

  /// Serializes this Reality to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Reality&&(identical(other.publicKey, publicKey) || other.publicKey == publicKey)&&(identical(other.shortId, shortId) || other.shortId == shortId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,publicKey,shortId);

@override
String toString() {
  return 'Reality(publicKey: $publicKey, shortId: $shortId)';
}


}

/// @nodoc
abstract mixin class $RealityCopyWith<$Res>  {
  factory $RealityCopyWith(Reality value, $Res Function(Reality) _then) = _$RealityCopyWithImpl;
@useResult
$Res call({
 String publicKey, String? shortId
});




}
/// @nodoc
class _$RealityCopyWithImpl<$Res>
    implements $RealityCopyWith<$Res> {
  _$RealityCopyWithImpl(this._self, this._then);

  final Reality _self;
  final $Res Function(Reality) _then;

/// Create a copy of Reality
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? publicKey = null,Object? shortId = freezed,}) {
  return _then(_self.copyWith(
publicKey: null == publicKey ? _self.publicKey : publicKey // ignore: cast_nullable_to_non_nullable
as String,shortId: freezed == shortId ? _self.shortId : shortId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Reality].
extension RealityPatterns on Reality {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Reality value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Reality() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Reality value)  $default,){
final _that = this;
switch (_that) {
case _Reality():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Reality value)?  $default,){
final _that = this;
switch (_that) {
case _Reality() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String publicKey,  String? shortId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Reality() when $default != null:
return $default(_that.publicKey,_that.shortId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String publicKey,  String? shortId)  $default,) {final _that = this;
switch (_that) {
case _Reality():
return $default(_that.publicKey,_that.shortId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String publicKey,  String? shortId)?  $default,) {final _that = this;
switch (_that) {
case _Reality() when $default != null:
return $default(_that.publicKey,_that.shortId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Reality implements Reality {
  const _Reality({required this.publicKey, this.shortId});
  factory _Reality.fromJson(Map<String, dynamic> json) => _$RealityFromJson(json);

@override final  String publicKey;
@override final  String? shortId;

/// Create a copy of Reality
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RealityCopyWith<_Reality> get copyWith => __$RealityCopyWithImpl<_Reality>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RealityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Reality&&(identical(other.publicKey, publicKey) || other.publicKey == publicKey)&&(identical(other.shortId, shortId) || other.shortId == shortId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,publicKey,shortId);

@override
String toString() {
  return 'Reality(publicKey: $publicKey, shortId: $shortId)';
}


}

/// @nodoc
abstract mixin class _$RealityCopyWith<$Res> implements $RealityCopyWith<$Res> {
  factory _$RealityCopyWith(_Reality value, $Res Function(_Reality) _then) = __$RealityCopyWithImpl;
@override @useResult
$Res call({
 String publicKey, String? shortId
});




}
/// @nodoc
class __$RealityCopyWithImpl<$Res>
    implements _$RealityCopyWith<$Res> {
  __$RealityCopyWithImpl(this._self, this._then);

  final _Reality _self;
  final $Res Function(_Reality) _then;

/// Create a copy of Reality
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? publicKey = null,Object? shortId = freezed,}) {
  return _then(_Reality(
publicKey: null == publicKey ? _self.publicKey : publicKey // ignore: cast_nullable_to_non_nullable
as String,shortId: freezed == shortId ? _self.shortId : shortId // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$Tls {

 String? get serverName; bool get insecure; List<String> get alpn;/// uTLS client fingerprint, e.g. `chrome`.
 String? get fingerprint; Reality? get reality;
/// Create a copy of Tls
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TlsCopyWith<Tls> get copyWith => _$TlsCopyWithImpl<Tls>(this as Tls, _$identity);

  /// Serializes this Tls to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Tls&&(identical(other.serverName, serverName) || other.serverName == serverName)&&(identical(other.insecure, insecure) || other.insecure == insecure)&&const DeepCollectionEquality().equals(other.alpn, alpn)&&(identical(other.fingerprint, fingerprint) || other.fingerprint == fingerprint)&&(identical(other.reality, reality) || other.reality == reality));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,serverName,insecure,const DeepCollectionEquality().hash(alpn),fingerprint,reality);

@override
String toString() {
  return 'Tls(serverName: $serverName, insecure: $insecure, alpn: $alpn, fingerprint: $fingerprint, reality: $reality)';
}


}

/// @nodoc
abstract mixin class $TlsCopyWith<$Res>  {
  factory $TlsCopyWith(Tls value, $Res Function(Tls) _then) = _$TlsCopyWithImpl;
@useResult
$Res call({
 String? serverName, bool insecure, List<String> alpn, String? fingerprint, Reality? reality
});


$RealityCopyWith<$Res>? get reality;

}
/// @nodoc
class _$TlsCopyWithImpl<$Res>
    implements $TlsCopyWith<$Res> {
  _$TlsCopyWithImpl(this._self, this._then);

  final Tls _self;
  final $Res Function(Tls) _then;

/// Create a copy of Tls
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? serverName = freezed,Object? insecure = null,Object? alpn = null,Object? fingerprint = freezed,Object? reality = freezed,}) {
  return _then(_self.copyWith(
serverName: freezed == serverName ? _self.serverName : serverName // ignore: cast_nullable_to_non_nullable
as String?,insecure: null == insecure ? _self.insecure : insecure // ignore: cast_nullable_to_non_nullable
as bool,alpn: null == alpn ? _self.alpn : alpn // ignore: cast_nullable_to_non_nullable
as List<String>,fingerprint: freezed == fingerprint ? _self.fingerprint : fingerprint // ignore: cast_nullable_to_non_nullable
as String?,reality: freezed == reality ? _self.reality : reality // ignore: cast_nullable_to_non_nullable
as Reality?,
  ));
}
/// Create a copy of Tls
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RealityCopyWith<$Res>? get reality {
    if (_self.reality == null) {
    return null;
  }

  return $RealityCopyWith<$Res>(_self.reality!, (value) {
    return _then(_self.copyWith(reality: value));
  });
}
}


/// Adds pattern-matching-related methods to [Tls].
extension TlsPatterns on Tls {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Tls value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Tls() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Tls value)  $default,){
final _that = this;
switch (_that) {
case _Tls():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Tls value)?  $default,){
final _that = this;
switch (_that) {
case _Tls() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? serverName,  bool insecure,  List<String> alpn,  String? fingerprint,  Reality? reality)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Tls() when $default != null:
return $default(_that.serverName,_that.insecure,_that.alpn,_that.fingerprint,_that.reality);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? serverName,  bool insecure,  List<String> alpn,  String? fingerprint,  Reality? reality)  $default,) {final _that = this;
switch (_that) {
case _Tls():
return $default(_that.serverName,_that.insecure,_that.alpn,_that.fingerprint,_that.reality);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? serverName,  bool insecure,  List<String> alpn,  String? fingerprint,  Reality? reality)?  $default,) {final _that = this;
switch (_that) {
case _Tls() when $default != null:
return $default(_that.serverName,_that.insecure,_that.alpn,_that.fingerprint,_that.reality);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Tls implements Tls {
  const _Tls({this.serverName, this.insecure = false, final  List<String> alpn = const <String>[], this.fingerprint, this.reality}): _alpn = alpn;
  factory _Tls.fromJson(Map<String, dynamic> json) => _$TlsFromJson(json);

@override final  String? serverName;
@override@JsonKey() final  bool insecure;
 final  List<String> _alpn;
@override@JsonKey() List<String> get alpn {
  if (_alpn is EqualUnmodifiableListView) return _alpn;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_alpn);
}

/// uTLS client fingerprint, e.g. `chrome`.
@override final  String? fingerprint;
@override final  Reality? reality;

/// Create a copy of Tls
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TlsCopyWith<_Tls> get copyWith => __$TlsCopyWithImpl<_Tls>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TlsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Tls&&(identical(other.serverName, serverName) || other.serverName == serverName)&&(identical(other.insecure, insecure) || other.insecure == insecure)&&const DeepCollectionEquality().equals(other._alpn, _alpn)&&(identical(other.fingerprint, fingerprint) || other.fingerprint == fingerprint)&&(identical(other.reality, reality) || other.reality == reality));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,serverName,insecure,const DeepCollectionEquality().hash(_alpn),fingerprint,reality);

@override
String toString() {
  return 'Tls(serverName: $serverName, insecure: $insecure, alpn: $alpn, fingerprint: $fingerprint, reality: $reality)';
}


}

/// @nodoc
abstract mixin class _$TlsCopyWith<$Res> implements $TlsCopyWith<$Res> {
  factory _$TlsCopyWith(_Tls value, $Res Function(_Tls) _then) = __$TlsCopyWithImpl;
@override @useResult
$Res call({
 String? serverName, bool insecure, List<String> alpn, String? fingerprint, Reality? reality
});


@override $RealityCopyWith<$Res>? get reality;

}
/// @nodoc
class __$TlsCopyWithImpl<$Res>
    implements _$TlsCopyWith<$Res> {
  __$TlsCopyWithImpl(this._self, this._then);

  final _Tls _self;
  final $Res Function(_Tls) _then;

/// Create a copy of Tls
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? serverName = freezed,Object? insecure = null,Object? alpn = null,Object? fingerprint = freezed,Object? reality = freezed,}) {
  return _then(_Tls(
serverName: freezed == serverName ? _self.serverName : serverName // ignore: cast_nullable_to_non_nullable
as String?,insecure: null == insecure ? _self.insecure : insecure // ignore: cast_nullable_to_non_nullable
as bool,alpn: null == alpn ? _self._alpn : alpn // ignore: cast_nullable_to_non_nullable
as List<String>,fingerprint: freezed == fingerprint ? _self.fingerprint : fingerprint // ignore: cast_nullable_to_non_nullable
as String?,reality: freezed == reality ? _self.reality : reality // ignore: cast_nullable_to_non_nullable
as Reality?,
  ));
}

/// Create a copy of Tls
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RealityCopyWith<$Res>? get reality {
    if (_self.reality == null) {
    return null;
  }

  return $RealityCopyWith<$Res>(_self.reality!, (value) {
    return _then(_self.copyWith(reality: value));
  });
}
}

NodeParams _$NodeParamsFromJson(
  Map<String, dynamic> json
) {
        switch (json['protocol']) {
                  case 'hysteria2':
          return Hysteria2Params.fromJson(
            json
          );
                case 'tuic':
          return TuicParams.fromJson(
            json
          );
                case 'vless':
          return VlessParams.fromJson(
            json
          );
                case 'vmess':
          return VmessParams.fromJson(
            json
          );
                case 'trojan':
          return TrojanParams.fromJson(
            json
          );
                case 'shadowsocks':
          return ShadowsocksParams.fromJson(
            json
          );
                case 'socks5':
          return Socks5Params.fromJson(
            json
          );
                case 'anytls':
          return AnyTlsParams.fromJson(
            json
          );
                case 'http':
          return HttpParams.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'protocol',
  'NodeParams',
  'Invalid union type "${json['protocol']}"!'
);
        }
      
}

/// @nodoc
mixin _$NodeParams {



  /// Serializes this NodeParams to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodeParams);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'NodeParams()';
}


}

/// @nodoc
class $NodeParamsCopyWith<$Res>  {
$NodeParamsCopyWith(NodeParams _, $Res Function(NodeParams) __);
}


/// Adds pattern-matching-related methods to [NodeParams].
extension NodeParamsPatterns on NodeParams {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( Hysteria2Params value)?  hysteria2,TResult Function( TuicParams value)?  tuic,TResult Function( VlessParams value)?  vless,TResult Function( VmessParams value)?  vmess,TResult Function( TrojanParams value)?  trojan,TResult Function( ShadowsocksParams value)?  shadowsocks,TResult Function( Socks5Params value)?  socks5,TResult Function( AnyTlsParams value)?  anytls,TResult Function( HttpParams value)?  http,required TResult orElse(),}){
final _that = this;
switch (_that) {
case Hysteria2Params() when hysteria2 != null:
return hysteria2(_that);case TuicParams() when tuic != null:
return tuic(_that);case VlessParams() when vless != null:
return vless(_that);case VmessParams() when vmess != null:
return vmess(_that);case TrojanParams() when trojan != null:
return trojan(_that);case ShadowsocksParams() when shadowsocks != null:
return shadowsocks(_that);case Socks5Params() when socks5 != null:
return socks5(_that);case AnyTlsParams() when anytls != null:
return anytls(_that);case HttpParams() when http != null:
return http(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( Hysteria2Params value)  hysteria2,required TResult Function( TuicParams value)  tuic,required TResult Function( VlessParams value)  vless,required TResult Function( VmessParams value)  vmess,required TResult Function( TrojanParams value)  trojan,required TResult Function( ShadowsocksParams value)  shadowsocks,required TResult Function( Socks5Params value)  socks5,required TResult Function( AnyTlsParams value)  anytls,required TResult Function( HttpParams value)  http,}){
final _that = this;
switch (_that) {
case Hysteria2Params():
return hysteria2(_that);case TuicParams():
return tuic(_that);case VlessParams():
return vless(_that);case VmessParams():
return vmess(_that);case TrojanParams():
return trojan(_that);case ShadowsocksParams():
return shadowsocks(_that);case Socks5Params():
return socks5(_that);case AnyTlsParams():
return anytls(_that);case HttpParams():
return http(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( Hysteria2Params value)?  hysteria2,TResult? Function( TuicParams value)?  tuic,TResult? Function( VlessParams value)?  vless,TResult? Function( VmessParams value)?  vmess,TResult? Function( TrojanParams value)?  trojan,TResult? Function( ShadowsocksParams value)?  shadowsocks,TResult? Function( Socks5Params value)?  socks5,TResult? Function( AnyTlsParams value)?  anytls,TResult? Function( HttpParams value)?  http,}){
final _that = this;
switch (_that) {
case Hysteria2Params() when hysteria2 != null:
return hysteria2(_that);case TuicParams() when tuic != null:
return tuic(_that);case VlessParams() when vless != null:
return vless(_that);case VmessParams() when vmess != null:
return vmess(_that);case TrojanParams() when trojan != null:
return trojan(_that);case ShadowsocksParams() when shadowsocks != null:
return shadowsocks(_that);case Socks5Params() when socks5 != null:
return socks5(_that);case AnyTlsParams() when anytls != null:
return anytls(_that);case HttpParams() when http != null:
return http(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( Secret password,  Secret? obfsPassword,  int? upMbps,  int? downMbps,  List<String> serverPorts,  Tls tls)?  hysteria2,TResult Function( Secret uuid,  Secret password,  String congestionControl,  String? udpRelayMode,  Tls tls)?  tuic,TResult Function( Secret uuid,  String? flow,  Transport transport,  Tls? tls)?  vless,TResult Function( Secret uuid,  int alterId,  String cipher,  Transport transport,  Tls? tls)?  vmess,TResult Function( Secret password,  Transport transport,  Tls tls)?  trojan,TResult Function( String method,  Secret password,  String? plugin,  String? pluginOpts)?  shadowsocks,TResult Function( String? username,  Secret? password,  Tls? tls)?  socks5,TResult Function( Secret password,  String? idleSessionCheckInterval,  Tls tls)?  anytls,TResult Function( String? username,  Secret? password,  Tls? tls)?  http,required TResult orElse(),}) {final _that = this;
switch (_that) {
case Hysteria2Params() when hysteria2 != null:
return hysteria2(_that.password,_that.obfsPassword,_that.upMbps,_that.downMbps,_that.serverPorts,_that.tls);case TuicParams() when tuic != null:
return tuic(_that.uuid,_that.password,_that.congestionControl,_that.udpRelayMode,_that.tls);case VlessParams() when vless != null:
return vless(_that.uuid,_that.flow,_that.transport,_that.tls);case VmessParams() when vmess != null:
return vmess(_that.uuid,_that.alterId,_that.cipher,_that.transport,_that.tls);case TrojanParams() when trojan != null:
return trojan(_that.password,_that.transport,_that.tls);case ShadowsocksParams() when shadowsocks != null:
return shadowsocks(_that.method,_that.password,_that.plugin,_that.pluginOpts);case Socks5Params() when socks5 != null:
return socks5(_that.username,_that.password,_that.tls);case AnyTlsParams() when anytls != null:
return anytls(_that.password,_that.idleSessionCheckInterval,_that.tls);case HttpParams() when http != null:
return http(_that.username,_that.password,_that.tls);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( Secret password,  Secret? obfsPassword,  int? upMbps,  int? downMbps,  List<String> serverPorts,  Tls tls)  hysteria2,required TResult Function( Secret uuid,  Secret password,  String congestionControl,  String? udpRelayMode,  Tls tls)  tuic,required TResult Function( Secret uuid,  String? flow,  Transport transport,  Tls? tls)  vless,required TResult Function( Secret uuid,  int alterId,  String cipher,  Transport transport,  Tls? tls)  vmess,required TResult Function( Secret password,  Transport transport,  Tls tls)  trojan,required TResult Function( String method,  Secret password,  String? plugin,  String? pluginOpts)  shadowsocks,required TResult Function( String? username,  Secret? password,  Tls? tls)  socks5,required TResult Function( Secret password,  String? idleSessionCheckInterval,  Tls tls)  anytls,required TResult Function( String? username,  Secret? password,  Tls? tls)  http,}) {final _that = this;
switch (_that) {
case Hysteria2Params():
return hysteria2(_that.password,_that.obfsPassword,_that.upMbps,_that.downMbps,_that.serverPorts,_that.tls);case TuicParams():
return tuic(_that.uuid,_that.password,_that.congestionControl,_that.udpRelayMode,_that.tls);case VlessParams():
return vless(_that.uuid,_that.flow,_that.transport,_that.tls);case VmessParams():
return vmess(_that.uuid,_that.alterId,_that.cipher,_that.transport,_that.tls);case TrojanParams():
return trojan(_that.password,_that.transport,_that.tls);case ShadowsocksParams():
return shadowsocks(_that.method,_that.password,_that.plugin,_that.pluginOpts);case Socks5Params():
return socks5(_that.username,_that.password,_that.tls);case AnyTlsParams():
return anytls(_that.password,_that.idleSessionCheckInterval,_that.tls);case HttpParams():
return http(_that.username,_that.password,_that.tls);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( Secret password,  Secret? obfsPassword,  int? upMbps,  int? downMbps,  List<String> serverPorts,  Tls tls)?  hysteria2,TResult? Function( Secret uuid,  Secret password,  String congestionControl,  String? udpRelayMode,  Tls tls)?  tuic,TResult? Function( Secret uuid,  String? flow,  Transport transport,  Tls? tls)?  vless,TResult? Function( Secret uuid,  int alterId,  String cipher,  Transport transport,  Tls? tls)?  vmess,TResult? Function( Secret password,  Transport transport,  Tls tls)?  trojan,TResult? Function( String method,  Secret password,  String? plugin,  String? pluginOpts)?  shadowsocks,TResult? Function( String? username,  Secret? password,  Tls? tls)?  socks5,TResult? Function( Secret password,  String? idleSessionCheckInterval,  Tls tls)?  anytls,TResult? Function( String? username,  Secret? password,  Tls? tls)?  http,}) {final _that = this;
switch (_that) {
case Hysteria2Params() when hysteria2 != null:
return hysteria2(_that.password,_that.obfsPassword,_that.upMbps,_that.downMbps,_that.serverPorts,_that.tls);case TuicParams() when tuic != null:
return tuic(_that.uuid,_that.password,_that.congestionControl,_that.udpRelayMode,_that.tls);case VlessParams() when vless != null:
return vless(_that.uuid,_that.flow,_that.transport,_that.tls);case VmessParams() when vmess != null:
return vmess(_that.uuid,_that.alterId,_that.cipher,_that.transport,_that.tls);case TrojanParams() when trojan != null:
return trojan(_that.password,_that.transport,_that.tls);case ShadowsocksParams() when shadowsocks != null:
return shadowsocks(_that.method,_that.password,_that.plugin,_that.pluginOpts);case Socks5Params() when socks5 != null:
return socks5(_that.username,_that.password,_that.tls);case AnyTlsParams() when anytls != null:
return anytls(_that.password,_that.idleSessionCheckInterval,_that.tls);case HttpParams() when http != null:
return http(_that.username,_that.password,_that.tls);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class Hysteria2Params extends NodeParams {
  const Hysteria2Params({required this.password, this.obfsPassword, this.upMbps, this.downMbps, final  List<String> serverPorts = const <String>[], this.tls = const Tls(), final  String? $type}): _serverPorts = serverPorts,$type = $type ?? 'hysteria2',super._();
  factory Hysteria2Params.fromJson(Map<String, dynamic> json) => _$Hysteria2ParamsFromJson(json);

 final  Secret password;
 final  Secret? obfsPassword;
 final  int? upMbps;
 final  int? downMbps;
/// Port hopping ranges such as `20000:30000`.
 final  List<String> _serverPorts;
/// Port hopping ranges such as `20000:30000`.
@JsonKey() List<String> get serverPorts {
  if (_serverPorts is EqualUnmodifiableListView) return _serverPorts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_serverPorts);
}

@JsonKey() final  Tls tls;

@JsonKey(name: 'protocol')
final String $type;


/// Create a copy of NodeParams
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Hysteria2ParamsCopyWith<Hysteria2Params> get copyWith => _$Hysteria2ParamsCopyWithImpl<Hysteria2Params>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Hysteria2ParamsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Hysteria2Params&&(identical(other.password, password) || other.password == password)&&(identical(other.obfsPassword, obfsPassword) || other.obfsPassword == obfsPassword)&&(identical(other.upMbps, upMbps) || other.upMbps == upMbps)&&(identical(other.downMbps, downMbps) || other.downMbps == downMbps)&&const DeepCollectionEquality().equals(other._serverPorts, _serverPorts)&&(identical(other.tls, tls) || other.tls == tls));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,password,obfsPassword,upMbps,downMbps,const DeepCollectionEquality().hash(_serverPorts),tls);

@override
String toString() {
  return 'NodeParams.hysteria2(password: $password, obfsPassword: $obfsPassword, upMbps: $upMbps, downMbps: $downMbps, serverPorts: $serverPorts, tls: $tls)';
}


}

/// @nodoc
abstract mixin class $Hysteria2ParamsCopyWith<$Res> implements $NodeParamsCopyWith<$Res> {
  factory $Hysteria2ParamsCopyWith(Hysteria2Params value, $Res Function(Hysteria2Params) _then) = _$Hysteria2ParamsCopyWithImpl;
@useResult
$Res call({
 Secret password, Secret? obfsPassword, int? upMbps, int? downMbps, List<String> serverPorts, Tls tls
});


$TlsCopyWith<$Res> get tls;

}
/// @nodoc
class _$Hysteria2ParamsCopyWithImpl<$Res>
    implements $Hysteria2ParamsCopyWith<$Res> {
  _$Hysteria2ParamsCopyWithImpl(this._self, this._then);

  final Hysteria2Params _self;
  final $Res Function(Hysteria2Params) _then;

/// Create a copy of NodeParams
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? password = null,Object? obfsPassword = freezed,Object? upMbps = freezed,Object? downMbps = freezed,Object? serverPorts = null,Object? tls = null,}) {
  return _then(Hysteria2Params(
password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as Secret,obfsPassword: freezed == obfsPassword ? _self.obfsPassword : obfsPassword // ignore: cast_nullable_to_non_nullable
as Secret?,upMbps: freezed == upMbps ? _self.upMbps : upMbps // ignore: cast_nullable_to_non_nullable
as int?,downMbps: freezed == downMbps ? _self.downMbps : downMbps // ignore: cast_nullable_to_non_nullable
as int?,serverPorts: null == serverPorts ? _self._serverPorts : serverPorts // ignore: cast_nullable_to_non_nullable
as List<String>,tls: null == tls ? _self.tls : tls // ignore: cast_nullable_to_non_nullable
as Tls,
  ));
}

/// Create a copy of NodeParams
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TlsCopyWith<$Res> get tls {
  
  return $TlsCopyWith<$Res>(_self.tls, (value) {
    return _then(_self.copyWith(tls: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class TuicParams extends NodeParams {
  const TuicParams({required this.uuid, required this.password, this.congestionControl = 'bbr', this.udpRelayMode, this.tls = const Tls(), final  String? $type}): $type = $type ?? 'tuic',super._();
  factory TuicParams.fromJson(Map<String, dynamic> json) => _$TuicParamsFromJson(json);

 final  Secret uuid;
 final  Secret password;
@JsonKey() final  String congestionControl;
 final  String? udpRelayMode;
@JsonKey() final  Tls tls;

@JsonKey(name: 'protocol')
final String $type;


/// Create a copy of NodeParams
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TuicParamsCopyWith<TuicParams> get copyWith => _$TuicParamsCopyWithImpl<TuicParams>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TuicParamsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TuicParams&&(identical(other.uuid, uuid) || other.uuid == uuid)&&(identical(other.password, password) || other.password == password)&&(identical(other.congestionControl, congestionControl) || other.congestionControl == congestionControl)&&(identical(other.udpRelayMode, udpRelayMode) || other.udpRelayMode == udpRelayMode)&&(identical(other.tls, tls) || other.tls == tls));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uuid,password,congestionControl,udpRelayMode,tls);

@override
String toString() {
  return 'NodeParams.tuic(uuid: $uuid, password: $password, congestionControl: $congestionControl, udpRelayMode: $udpRelayMode, tls: $tls)';
}


}

/// @nodoc
abstract mixin class $TuicParamsCopyWith<$Res> implements $NodeParamsCopyWith<$Res> {
  factory $TuicParamsCopyWith(TuicParams value, $Res Function(TuicParams) _then) = _$TuicParamsCopyWithImpl;
@useResult
$Res call({
 Secret uuid, Secret password, String congestionControl, String? udpRelayMode, Tls tls
});


$TlsCopyWith<$Res> get tls;

}
/// @nodoc
class _$TuicParamsCopyWithImpl<$Res>
    implements $TuicParamsCopyWith<$Res> {
  _$TuicParamsCopyWithImpl(this._self, this._then);

  final TuicParams _self;
  final $Res Function(TuicParams) _then;

/// Create a copy of NodeParams
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? uuid = null,Object? password = null,Object? congestionControl = null,Object? udpRelayMode = freezed,Object? tls = null,}) {
  return _then(TuicParams(
uuid: null == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as Secret,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as Secret,congestionControl: null == congestionControl ? _self.congestionControl : congestionControl // ignore: cast_nullable_to_non_nullable
as String,udpRelayMode: freezed == udpRelayMode ? _self.udpRelayMode : udpRelayMode // ignore: cast_nullable_to_non_nullable
as String?,tls: null == tls ? _self.tls : tls // ignore: cast_nullable_to_non_nullable
as Tls,
  ));
}

/// Create a copy of NodeParams
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TlsCopyWith<$Res> get tls {
  
  return $TlsCopyWith<$Res>(_self.tls, (value) {
    return _then(_self.copyWith(tls: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class VlessParams extends NodeParams {
  const VlessParams({required this.uuid, this.flow, this.transport = const Transport.tcp(), this.tls, final  String? $type}): $type = $type ?? 'vless',super._();
  factory VlessParams.fromJson(Map<String, dynamic> json) => _$VlessParamsFromJson(json);

 final  Secret uuid;
 final  String? flow;
@JsonKey() final  Transport transport;
 final  Tls? tls;

@JsonKey(name: 'protocol')
final String $type;


/// Create a copy of NodeParams
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VlessParamsCopyWith<VlessParams> get copyWith => _$VlessParamsCopyWithImpl<VlessParams>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VlessParamsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VlessParams&&(identical(other.uuid, uuid) || other.uuid == uuid)&&(identical(other.flow, flow) || other.flow == flow)&&(identical(other.transport, transport) || other.transport == transport)&&(identical(other.tls, tls) || other.tls == tls));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uuid,flow,transport,tls);

@override
String toString() {
  return 'NodeParams.vless(uuid: $uuid, flow: $flow, transport: $transport, tls: $tls)';
}


}

/// @nodoc
abstract mixin class $VlessParamsCopyWith<$Res> implements $NodeParamsCopyWith<$Res> {
  factory $VlessParamsCopyWith(VlessParams value, $Res Function(VlessParams) _then) = _$VlessParamsCopyWithImpl;
@useResult
$Res call({
 Secret uuid, String? flow, Transport transport, Tls? tls
});


$TransportCopyWith<$Res> get transport;$TlsCopyWith<$Res>? get tls;

}
/// @nodoc
class _$VlessParamsCopyWithImpl<$Res>
    implements $VlessParamsCopyWith<$Res> {
  _$VlessParamsCopyWithImpl(this._self, this._then);

  final VlessParams _self;
  final $Res Function(VlessParams) _then;

/// Create a copy of NodeParams
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? uuid = null,Object? flow = freezed,Object? transport = null,Object? tls = freezed,}) {
  return _then(VlessParams(
uuid: null == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as Secret,flow: freezed == flow ? _self.flow : flow // ignore: cast_nullable_to_non_nullable
as String?,transport: null == transport ? _self.transport : transport // ignore: cast_nullable_to_non_nullable
as Transport,tls: freezed == tls ? _self.tls : tls // ignore: cast_nullable_to_non_nullable
as Tls?,
  ));
}

/// Create a copy of NodeParams
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TransportCopyWith<$Res> get transport {
  
  return $TransportCopyWith<$Res>(_self.transport, (value) {
    return _then(_self.copyWith(transport: value));
  });
}/// Create a copy of NodeParams
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TlsCopyWith<$Res>? get tls {
    if (_self.tls == null) {
    return null;
  }

  return $TlsCopyWith<$Res>(_self.tls!, (value) {
    return _then(_self.copyWith(tls: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class VmessParams extends NodeParams {
  const VmessParams({required this.uuid, this.alterId = 0, this.cipher = 'auto', this.transport = const Transport.tcp(), this.tls, final  String? $type}): $type = $type ?? 'vmess',super._();
  factory VmessParams.fromJson(Map<String, dynamic> json) => _$VmessParamsFromJson(json);

 final  Secret uuid;
@JsonKey() final  int alterId;
@JsonKey() final  String cipher;
@JsonKey() final  Transport transport;
 final  Tls? tls;

@JsonKey(name: 'protocol')
final String $type;


/// Create a copy of NodeParams
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$VmessParamsCopyWith<VmessParams> get copyWith => _$VmessParamsCopyWithImpl<VmessParams>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$VmessParamsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is VmessParams&&(identical(other.uuid, uuid) || other.uuid == uuid)&&(identical(other.alterId, alterId) || other.alterId == alterId)&&(identical(other.cipher, cipher) || other.cipher == cipher)&&(identical(other.transport, transport) || other.transport == transport)&&(identical(other.tls, tls) || other.tls == tls));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,uuid,alterId,cipher,transport,tls);

@override
String toString() {
  return 'NodeParams.vmess(uuid: $uuid, alterId: $alterId, cipher: $cipher, transport: $transport, tls: $tls)';
}


}

/// @nodoc
abstract mixin class $VmessParamsCopyWith<$Res> implements $NodeParamsCopyWith<$Res> {
  factory $VmessParamsCopyWith(VmessParams value, $Res Function(VmessParams) _then) = _$VmessParamsCopyWithImpl;
@useResult
$Res call({
 Secret uuid, int alterId, String cipher, Transport transport, Tls? tls
});


$TransportCopyWith<$Res> get transport;$TlsCopyWith<$Res>? get tls;

}
/// @nodoc
class _$VmessParamsCopyWithImpl<$Res>
    implements $VmessParamsCopyWith<$Res> {
  _$VmessParamsCopyWithImpl(this._self, this._then);

  final VmessParams _self;
  final $Res Function(VmessParams) _then;

/// Create a copy of NodeParams
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? uuid = null,Object? alterId = null,Object? cipher = null,Object? transport = null,Object? tls = freezed,}) {
  return _then(VmessParams(
uuid: null == uuid ? _self.uuid : uuid // ignore: cast_nullable_to_non_nullable
as Secret,alterId: null == alterId ? _self.alterId : alterId // ignore: cast_nullable_to_non_nullable
as int,cipher: null == cipher ? _self.cipher : cipher // ignore: cast_nullable_to_non_nullable
as String,transport: null == transport ? _self.transport : transport // ignore: cast_nullable_to_non_nullable
as Transport,tls: freezed == tls ? _self.tls : tls // ignore: cast_nullable_to_non_nullable
as Tls?,
  ));
}

/// Create a copy of NodeParams
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TransportCopyWith<$Res> get transport {
  
  return $TransportCopyWith<$Res>(_self.transport, (value) {
    return _then(_self.copyWith(transport: value));
  });
}/// Create a copy of NodeParams
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TlsCopyWith<$Res>? get tls {
    if (_self.tls == null) {
    return null;
  }

  return $TlsCopyWith<$Res>(_self.tls!, (value) {
    return _then(_self.copyWith(tls: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class TrojanParams extends NodeParams {
  const TrojanParams({required this.password, this.transport = const Transport.tcp(), this.tls = const Tls(), final  String? $type}): $type = $type ?? 'trojan',super._();
  factory TrojanParams.fromJson(Map<String, dynamic> json) => _$TrojanParamsFromJson(json);

 final  Secret password;
@JsonKey() final  Transport transport;
@JsonKey() final  Tls tls;

@JsonKey(name: 'protocol')
final String $type;


/// Create a copy of NodeParams
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrojanParamsCopyWith<TrojanParams> get copyWith => _$TrojanParamsCopyWithImpl<TrojanParams>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrojanParamsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrojanParams&&(identical(other.password, password) || other.password == password)&&(identical(other.transport, transport) || other.transport == transport)&&(identical(other.tls, tls) || other.tls == tls));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,password,transport,tls);

@override
String toString() {
  return 'NodeParams.trojan(password: $password, transport: $transport, tls: $tls)';
}


}

/// @nodoc
abstract mixin class $TrojanParamsCopyWith<$Res> implements $NodeParamsCopyWith<$Res> {
  factory $TrojanParamsCopyWith(TrojanParams value, $Res Function(TrojanParams) _then) = _$TrojanParamsCopyWithImpl;
@useResult
$Res call({
 Secret password, Transport transport, Tls tls
});


$TransportCopyWith<$Res> get transport;$TlsCopyWith<$Res> get tls;

}
/// @nodoc
class _$TrojanParamsCopyWithImpl<$Res>
    implements $TrojanParamsCopyWith<$Res> {
  _$TrojanParamsCopyWithImpl(this._self, this._then);

  final TrojanParams _self;
  final $Res Function(TrojanParams) _then;

/// Create a copy of NodeParams
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? password = null,Object? transport = null,Object? tls = null,}) {
  return _then(TrojanParams(
password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as Secret,transport: null == transport ? _self.transport : transport // ignore: cast_nullable_to_non_nullable
as Transport,tls: null == tls ? _self.tls : tls // ignore: cast_nullable_to_non_nullable
as Tls,
  ));
}

/// Create a copy of NodeParams
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TransportCopyWith<$Res> get transport {
  
  return $TransportCopyWith<$Res>(_self.transport, (value) {
    return _then(_self.copyWith(transport: value));
  });
}/// Create a copy of NodeParams
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TlsCopyWith<$Res> get tls {
  
  return $TlsCopyWith<$Res>(_self.tls, (value) {
    return _then(_self.copyWith(tls: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class ShadowsocksParams extends NodeParams {
  const ShadowsocksParams({required this.method, required this.password, this.plugin, this.pluginOpts, final  String? $type}): $type = $type ?? 'shadowsocks',super._();
  factory ShadowsocksParams.fromJson(Map<String, dynamic> json) => _$ShadowsocksParamsFromJson(json);

 final  String method;
 final  Secret password;
 final  String? plugin;
 final  String? pluginOpts;

@JsonKey(name: 'protocol')
final String $type;


/// Create a copy of NodeParams
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShadowsocksParamsCopyWith<ShadowsocksParams> get copyWith => _$ShadowsocksParamsCopyWithImpl<ShadowsocksParams>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ShadowsocksParamsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShadowsocksParams&&(identical(other.method, method) || other.method == method)&&(identical(other.password, password) || other.password == password)&&(identical(other.plugin, plugin) || other.plugin == plugin)&&(identical(other.pluginOpts, pluginOpts) || other.pluginOpts == pluginOpts));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,method,password,plugin,pluginOpts);

@override
String toString() {
  return 'NodeParams.shadowsocks(method: $method, password: $password, plugin: $plugin, pluginOpts: $pluginOpts)';
}


}

/// @nodoc
abstract mixin class $ShadowsocksParamsCopyWith<$Res> implements $NodeParamsCopyWith<$Res> {
  factory $ShadowsocksParamsCopyWith(ShadowsocksParams value, $Res Function(ShadowsocksParams) _then) = _$ShadowsocksParamsCopyWithImpl;
@useResult
$Res call({
 String method, Secret password, String? plugin, String? pluginOpts
});




}
/// @nodoc
class _$ShadowsocksParamsCopyWithImpl<$Res>
    implements $ShadowsocksParamsCopyWith<$Res> {
  _$ShadowsocksParamsCopyWithImpl(this._self, this._then);

  final ShadowsocksParams _self;
  final $Res Function(ShadowsocksParams) _then;

/// Create a copy of NodeParams
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? method = null,Object? password = null,Object? plugin = freezed,Object? pluginOpts = freezed,}) {
  return _then(ShadowsocksParams(
method: null == method ? _self.method : method // ignore: cast_nullable_to_non_nullable
as String,password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as Secret,plugin: freezed == plugin ? _self.plugin : plugin // ignore: cast_nullable_to_non_nullable
as String?,pluginOpts: freezed == pluginOpts ? _self.pluginOpts : pluginOpts // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
@JsonSerializable()

class Socks5Params extends NodeParams {
  const Socks5Params({this.username, this.password, this.tls, final  String? $type}): $type = $type ?? 'socks5',super._();
  factory Socks5Params.fromJson(Map<String, dynamic> json) => _$Socks5ParamsFromJson(json);

 final  String? username;
 final  Secret? password;
 final  Tls? tls;

@JsonKey(name: 'protocol')
final String $type;


/// Create a copy of NodeParams
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$Socks5ParamsCopyWith<Socks5Params> get copyWith => _$Socks5ParamsCopyWithImpl<Socks5Params>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$Socks5ParamsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Socks5Params&&(identical(other.username, username) || other.username == username)&&(identical(other.password, password) || other.password == password)&&(identical(other.tls, tls) || other.tls == tls));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,username,password,tls);

@override
String toString() {
  return 'NodeParams.socks5(username: $username, password: $password, tls: $tls)';
}


}

/// @nodoc
abstract mixin class $Socks5ParamsCopyWith<$Res> implements $NodeParamsCopyWith<$Res> {
  factory $Socks5ParamsCopyWith(Socks5Params value, $Res Function(Socks5Params) _then) = _$Socks5ParamsCopyWithImpl;
@useResult
$Res call({
 String? username, Secret? password, Tls? tls
});


$TlsCopyWith<$Res>? get tls;

}
/// @nodoc
class _$Socks5ParamsCopyWithImpl<$Res>
    implements $Socks5ParamsCopyWith<$Res> {
  _$Socks5ParamsCopyWithImpl(this._self, this._then);

  final Socks5Params _self;
  final $Res Function(Socks5Params) _then;

/// Create a copy of NodeParams
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? username = freezed,Object? password = freezed,Object? tls = freezed,}) {
  return _then(Socks5Params(
username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,password: freezed == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as Secret?,tls: freezed == tls ? _self.tls : tls // ignore: cast_nullable_to_non_nullable
as Tls?,
  ));
}

/// Create a copy of NodeParams
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TlsCopyWith<$Res>? get tls {
    if (_self.tls == null) {
    return null;
  }

  return $TlsCopyWith<$Res>(_self.tls!, (value) {
    return _then(_self.copyWith(tls: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class AnyTlsParams extends NodeParams {
  const AnyTlsParams({required this.password, this.idleSessionCheckInterval, this.tls = const Tls(), final  String? $type}): $type = $type ?? 'anytls',super._();
  factory AnyTlsParams.fromJson(Map<String, dynamic> json) => _$AnyTlsParamsFromJson(json);

 final  Secret password;
 final  String? idleSessionCheckInterval;
@JsonKey() final  Tls tls;

@JsonKey(name: 'protocol')
final String $type;


/// Create a copy of NodeParams
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnyTlsParamsCopyWith<AnyTlsParams> get copyWith => _$AnyTlsParamsCopyWithImpl<AnyTlsParams>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AnyTlsParamsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnyTlsParams&&(identical(other.password, password) || other.password == password)&&(identical(other.idleSessionCheckInterval, idleSessionCheckInterval) || other.idleSessionCheckInterval == idleSessionCheckInterval)&&(identical(other.tls, tls) || other.tls == tls));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,password,idleSessionCheckInterval,tls);

@override
String toString() {
  return 'NodeParams.anytls(password: $password, idleSessionCheckInterval: $idleSessionCheckInterval, tls: $tls)';
}


}

/// @nodoc
abstract mixin class $AnyTlsParamsCopyWith<$Res> implements $NodeParamsCopyWith<$Res> {
  factory $AnyTlsParamsCopyWith(AnyTlsParams value, $Res Function(AnyTlsParams) _then) = _$AnyTlsParamsCopyWithImpl;
@useResult
$Res call({
 Secret password, String? idleSessionCheckInterval, Tls tls
});


$TlsCopyWith<$Res> get tls;

}
/// @nodoc
class _$AnyTlsParamsCopyWithImpl<$Res>
    implements $AnyTlsParamsCopyWith<$Res> {
  _$AnyTlsParamsCopyWithImpl(this._self, this._then);

  final AnyTlsParams _self;
  final $Res Function(AnyTlsParams) _then;

/// Create a copy of NodeParams
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? password = null,Object? idleSessionCheckInterval = freezed,Object? tls = null,}) {
  return _then(AnyTlsParams(
password: null == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as Secret,idleSessionCheckInterval: freezed == idleSessionCheckInterval ? _self.idleSessionCheckInterval : idleSessionCheckInterval // ignore: cast_nullable_to_non_nullable
as String?,tls: null == tls ? _self.tls : tls // ignore: cast_nullable_to_non_nullable
as Tls,
  ));
}

/// Create a copy of NodeParams
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TlsCopyWith<$Res> get tls {
  
  return $TlsCopyWith<$Res>(_self.tls, (value) {
    return _then(_self.copyWith(tls: value));
  });
}
}

/// @nodoc
@JsonSerializable()

class HttpParams extends NodeParams {
  const HttpParams({this.username, this.password, this.tls, final  String? $type}): $type = $type ?? 'http',super._();
  factory HttpParams.fromJson(Map<String, dynamic> json) => _$HttpParamsFromJson(json);

 final  String? username;
 final  Secret? password;
 final  Tls? tls;

@JsonKey(name: 'protocol')
final String $type;


/// Create a copy of NodeParams
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HttpParamsCopyWith<HttpParams> get copyWith => _$HttpParamsCopyWithImpl<HttpParams>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$HttpParamsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HttpParams&&(identical(other.username, username) || other.username == username)&&(identical(other.password, password) || other.password == password)&&(identical(other.tls, tls) || other.tls == tls));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,username,password,tls);

@override
String toString() {
  return 'NodeParams.http(username: $username, password: $password, tls: $tls)';
}


}

/// @nodoc
abstract mixin class $HttpParamsCopyWith<$Res> implements $NodeParamsCopyWith<$Res> {
  factory $HttpParamsCopyWith(HttpParams value, $Res Function(HttpParams) _then) = _$HttpParamsCopyWithImpl;
@useResult
$Res call({
 String? username, Secret? password, Tls? tls
});


$TlsCopyWith<$Res>? get tls;

}
/// @nodoc
class _$HttpParamsCopyWithImpl<$Res>
    implements $HttpParamsCopyWith<$Res> {
  _$HttpParamsCopyWithImpl(this._self, this._then);

  final HttpParams _self;
  final $Res Function(HttpParams) _then;

/// Create a copy of NodeParams
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? username = freezed,Object? password = freezed,Object? tls = freezed,}) {
  return _then(HttpParams(
username: freezed == username ? _self.username : username // ignore: cast_nullable_to_non_nullable
as String?,password: freezed == password ? _self.password : password // ignore: cast_nullable_to_non_nullable
as Secret?,tls: freezed == tls ? _self.tls : tls // ignore: cast_nullable_to_non_nullable
as Tls?,
  ));
}

/// Create a copy of NodeParams
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TlsCopyWith<$Res>? get tls {
    if (_self.tls == null) {
    return null;
  }

  return $TlsCopyWith<$Res>(_self.tls!, (value) {
    return _then(_self.copyWith(tls: value));
  });
}
}


/// @nodoc
mixin _$NodeDef {

 String get key; String get name; String get server; int get port; NodeParams get params;/// Clash `dialer-proxy`: the key of the node or group to dial through.
 String? get detourKey;
/// Create a copy of NodeDef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$NodeDefCopyWith<NodeDef> get copyWith => _$NodeDefCopyWithImpl<NodeDef>(this as NodeDef, _$identity);

  /// Serializes this NodeDef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is NodeDef&&(identical(other.key, key) || other.key == key)&&(identical(other.name, name) || other.name == name)&&(identical(other.server, server) || other.server == server)&&(identical(other.port, port) || other.port == port)&&(identical(other.params, params) || other.params == params)&&(identical(other.detourKey, detourKey) || other.detourKey == detourKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,name,server,port,params,detourKey);

@override
String toString() {
  return 'NodeDef(key: $key, name: $name, server: $server, port: $port, params: $params, detourKey: $detourKey)';
}


}

/// @nodoc
abstract mixin class $NodeDefCopyWith<$Res>  {
  factory $NodeDefCopyWith(NodeDef value, $Res Function(NodeDef) _then) = _$NodeDefCopyWithImpl;
@useResult
$Res call({
 String key, String name, String server, int port, NodeParams params, String? detourKey
});


$NodeParamsCopyWith<$Res> get params;

}
/// @nodoc
class _$NodeDefCopyWithImpl<$Res>
    implements $NodeDefCopyWith<$Res> {
  _$NodeDefCopyWithImpl(this._self, this._then);

  final NodeDef _self;
  final $Res Function(NodeDef) _then;

/// Create a copy of NodeDef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? name = null,Object? server = null,Object? port = null,Object? params = null,Object? detourKey = freezed,}) {
  return _then(_self.copyWith(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,server: null == server ? _self.server : server // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,params: null == params ? _self.params : params // ignore: cast_nullable_to_non_nullable
as NodeParams,detourKey: freezed == detourKey ? _self.detourKey : detourKey // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of NodeDef
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NodeParamsCopyWith<$Res> get params {
  
  return $NodeParamsCopyWith<$Res>(_self.params, (value) {
    return _then(_self.copyWith(params: value));
  });
}
}


/// Adds pattern-matching-related methods to [NodeDef].
extension NodeDefPatterns on NodeDef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _NodeDef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _NodeDef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _NodeDef value)  $default,){
final _that = this;
switch (_that) {
case _NodeDef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _NodeDef value)?  $default,){
final _that = this;
switch (_that) {
case _NodeDef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  String name,  String server,  int port,  NodeParams params,  String? detourKey)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _NodeDef() when $default != null:
return $default(_that.key,_that.name,_that.server,_that.port,_that.params,_that.detourKey);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  String name,  String server,  int port,  NodeParams params,  String? detourKey)  $default,) {final _that = this;
switch (_that) {
case _NodeDef():
return $default(_that.key,_that.name,_that.server,_that.port,_that.params,_that.detourKey);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  String name,  String server,  int port,  NodeParams params,  String? detourKey)?  $default,) {final _that = this;
switch (_that) {
case _NodeDef() when $default != null:
return $default(_that.key,_that.name,_that.server,_that.port,_that.params,_that.detourKey);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _NodeDef implements NodeDef {
  const _NodeDef({required this.key, required this.name, required this.server, required this.port, required this.params, this.detourKey});
  factory _NodeDef.fromJson(Map<String, dynamic> json) => _$NodeDefFromJson(json);

@override final  String key;
@override final  String name;
@override final  String server;
@override final  int port;
@override final  NodeParams params;
/// Clash `dialer-proxy`: the key of the node or group to dial through.
@override final  String? detourKey;

/// Create a copy of NodeDef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$NodeDefCopyWith<_NodeDef> get copyWith => __$NodeDefCopyWithImpl<_NodeDef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$NodeDefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _NodeDef&&(identical(other.key, key) || other.key == key)&&(identical(other.name, name) || other.name == name)&&(identical(other.server, server) || other.server == server)&&(identical(other.port, port) || other.port == port)&&(identical(other.params, params) || other.params == params)&&(identical(other.detourKey, detourKey) || other.detourKey == detourKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,name,server,port,params,detourKey);

@override
String toString() {
  return 'NodeDef(key: $key, name: $name, server: $server, port: $port, params: $params, detourKey: $detourKey)';
}


}

/// @nodoc
abstract mixin class _$NodeDefCopyWith<$Res> implements $NodeDefCopyWith<$Res> {
  factory _$NodeDefCopyWith(_NodeDef value, $Res Function(_NodeDef) _then) = __$NodeDefCopyWithImpl;
@override @useResult
$Res call({
 String key, String name, String server, int port, NodeParams params, String? detourKey
});


@override $NodeParamsCopyWith<$Res> get params;

}
/// @nodoc
class __$NodeDefCopyWithImpl<$Res>
    implements _$NodeDefCopyWith<$Res> {
  __$NodeDefCopyWithImpl(this._self, this._then);

  final _NodeDef _self;
  final $Res Function(_NodeDef) _then;

/// Create a copy of NodeDef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? name = null,Object? server = null,Object? port = null,Object? params = null,Object? detourKey = freezed,}) {
  return _then(_NodeDef(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,server: null == server ? _self.server : server // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,params: null == params ? _self.params : params // ignore: cast_nullable_to_non_nullable
as NodeParams,detourKey: freezed == detourKey ? _self.detourKey : detourKey // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of NodeDef
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NodeParamsCopyWith<$Res> get params {
  
  return $NodeParamsCopyWith<$Res>(_self.params, (value) {
    return _then(_self.copyWith(params: value));
  });
}
}

// dart format on
