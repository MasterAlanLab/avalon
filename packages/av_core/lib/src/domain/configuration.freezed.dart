// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'configuration.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Usage {

 int get upload; int get download; int? get total; DateTime? get expireAt;
/// Create a copy of Usage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UsageCopyWith<Usage> get copyWith => _$UsageCopyWithImpl<Usage>(this as Usage, _$identity);

  /// Serializes this Usage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Usage&&(identical(other.upload, upload) || other.upload == upload)&&(identical(other.download, download) || other.download == download)&&(identical(other.total, total) || other.total == total)&&(identical(other.expireAt, expireAt) || other.expireAt == expireAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,upload,download,total,expireAt);

@override
String toString() {
  return 'Usage(upload: $upload, download: $download, total: $total, expireAt: $expireAt)';
}


}

/// @nodoc
abstract mixin class $UsageCopyWith<$Res>  {
  factory $UsageCopyWith(Usage value, $Res Function(Usage) _then) = _$UsageCopyWithImpl;
@useResult
$Res call({
 int upload, int download, int? total, DateTime? expireAt
});




}
/// @nodoc
class _$UsageCopyWithImpl<$Res>
    implements $UsageCopyWith<$Res> {
  _$UsageCopyWithImpl(this._self, this._then);

  final Usage _self;
  final $Res Function(Usage) _then;

/// Create a copy of Usage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? upload = null,Object? download = null,Object? total = freezed,Object? expireAt = freezed,}) {
  return _then(_self.copyWith(
upload: null == upload ? _self.upload : upload // ignore: cast_nullable_to_non_nullable
as int,download: null == download ? _self.download : download // ignore: cast_nullable_to_non_nullable
as int,total: freezed == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int?,expireAt: freezed == expireAt ? _self.expireAt : expireAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Usage].
extension UsagePatterns on Usage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Usage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Usage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Usage value)  $default,){
final _that = this;
switch (_that) {
case _Usage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Usage value)?  $default,){
final _that = this;
switch (_that) {
case _Usage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int upload,  int download,  int? total,  DateTime? expireAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Usage() when $default != null:
return $default(_that.upload,_that.download,_that.total,_that.expireAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int upload,  int download,  int? total,  DateTime? expireAt)  $default,) {final _that = this;
switch (_that) {
case _Usage():
return $default(_that.upload,_that.download,_that.total,_that.expireAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int upload,  int download,  int? total,  DateTime? expireAt)?  $default,) {final _that = this;
switch (_that) {
case _Usage() when $default != null:
return $default(_that.upload,_that.download,_that.total,_that.expireAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Usage implements Usage {
  const _Usage({this.upload = 0, this.download = 0, this.total, this.expireAt});
  factory _Usage.fromJson(Map<String, dynamic> json) => _$UsageFromJson(json);

@override@JsonKey() final  int upload;
@override@JsonKey() final  int download;
@override final  int? total;
@override final  DateTime? expireAt;

/// Create a copy of Usage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UsageCopyWith<_Usage> get copyWith => __$UsageCopyWithImpl<_Usage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$UsageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Usage&&(identical(other.upload, upload) || other.upload == upload)&&(identical(other.download, download) || other.download == download)&&(identical(other.total, total) || other.total == total)&&(identical(other.expireAt, expireAt) || other.expireAt == expireAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,upload,download,total,expireAt);

@override
String toString() {
  return 'Usage(upload: $upload, download: $download, total: $total, expireAt: $expireAt)';
}


}

/// @nodoc
abstract mixin class _$UsageCopyWith<$Res> implements $UsageCopyWith<$Res> {
  factory _$UsageCopyWith(_Usage value, $Res Function(_Usage) _then) = __$UsageCopyWithImpl;
@override @useResult
$Res call({
 int upload, int download, int? total, DateTime? expireAt
});




}
/// @nodoc
class __$UsageCopyWithImpl<$Res>
    implements _$UsageCopyWith<$Res> {
  __$UsageCopyWithImpl(this._self, this._then);

  final _Usage _self;
  final $Res Function(_Usage) _then;

/// Create a copy of Usage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? upload = null,Object? download = null,Object? total = freezed,Object? expireAt = freezed,}) {
  return _then(_Usage(
upload: null == upload ? _self.upload : upload // ignore: cast_nullable_to_non_nullable
as int,download: null == download ? _self.download : download // ignore: cast_nullable_to_non_nullable
as int,total: freezed == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int?,expireAt: freezed == expireAt ? _self.expireAt : expireAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$SubscriptionSource {

 Secret get url; Map<String, Secret> get headers;
/// Create a copy of SubscriptionSource
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubscriptionSourceCopyWith<SubscriptionSource> get copyWith => _$SubscriptionSourceCopyWithImpl<SubscriptionSource>(this as SubscriptionSource, _$identity);

  /// Serializes this SubscriptionSource to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubscriptionSource&&(identical(other.url, url) || other.url == url)&&const DeepCollectionEquality().equals(other.headers, headers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,const DeepCollectionEquality().hash(headers));

@override
String toString() {
  return 'SubscriptionSource(url: $url, headers: $headers)';
}


}

/// @nodoc
abstract mixin class $SubscriptionSourceCopyWith<$Res>  {
  factory $SubscriptionSourceCopyWith(SubscriptionSource value, $Res Function(SubscriptionSource) _then) = _$SubscriptionSourceCopyWithImpl;
@useResult
$Res call({
 Secret url, Map<String, Secret> headers
});




}
/// @nodoc
class _$SubscriptionSourceCopyWithImpl<$Res>
    implements $SubscriptionSourceCopyWith<$Res> {
  _$SubscriptionSourceCopyWithImpl(this._self, this._then);

  final SubscriptionSource _self;
  final $Res Function(SubscriptionSource) _then;

/// Create a copy of SubscriptionSource
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? headers = null,}) {
  return _then(_self.copyWith(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as Secret,headers: null == headers ? _self.headers : headers // ignore: cast_nullable_to_non_nullable
as Map<String, Secret>,
  ));
}

}


/// Adds pattern-matching-related methods to [SubscriptionSource].
extension SubscriptionSourcePatterns on SubscriptionSource {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubscriptionSource value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubscriptionSource() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubscriptionSource value)  $default,){
final _that = this;
switch (_that) {
case _SubscriptionSource():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubscriptionSource value)?  $default,){
final _that = this;
switch (_that) {
case _SubscriptionSource() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Secret url,  Map<String, Secret> headers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubscriptionSource() when $default != null:
return $default(_that.url,_that.headers);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Secret url,  Map<String, Secret> headers)  $default,) {final _that = this;
switch (_that) {
case _SubscriptionSource():
return $default(_that.url,_that.headers);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Secret url,  Map<String, Secret> headers)?  $default,) {final _that = this;
switch (_that) {
case _SubscriptionSource() when $default != null:
return $default(_that.url,_that.headers);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SubscriptionSource implements SubscriptionSource {
  const _SubscriptionSource({required this.url, final  Map<String, Secret> headers = const <String, Secret>{}}): _headers = headers;
  factory _SubscriptionSource.fromJson(Map<String, dynamic> json) => _$SubscriptionSourceFromJson(json);

@override final  Secret url;
 final  Map<String, Secret> _headers;
@override@JsonKey() Map<String, Secret> get headers {
  if (_headers is EqualUnmodifiableMapView) return _headers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_headers);
}


/// Create a copy of SubscriptionSource
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubscriptionSourceCopyWith<_SubscriptionSource> get copyWith => __$SubscriptionSourceCopyWithImpl<_SubscriptionSource>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SubscriptionSourceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubscriptionSource&&(identical(other.url, url) || other.url == url)&&const DeepCollectionEquality().equals(other._headers, _headers));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,const DeepCollectionEquality().hash(_headers));

@override
String toString() {
  return 'SubscriptionSource(url: $url, headers: $headers)';
}


}

/// @nodoc
abstract mixin class _$SubscriptionSourceCopyWith<$Res> implements $SubscriptionSourceCopyWith<$Res> {
  factory _$SubscriptionSourceCopyWith(_SubscriptionSource value, $Res Function(_SubscriptionSource) _then) = __$SubscriptionSourceCopyWithImpl;
@override @useResult
$Res call({
 Secret url, Map<String, Secret> headers
});




}
/// @nodoc
class __$SubscriptionSourceCopyWithImpl<$Res>
    implements _$SubscriptionSourceCopyWith<$Res> {
  __$SubscriptionSourceCopyWithImpl(this._self, this._then);

  final _SubscriptionSource _self;
  final $Res Function(_SubscriptionSource) _then;

/// Create a copy of SubscriptionSource
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? headers = null,}) {
  return _then(_SubscriptionSource(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as Secret,headers: null == headers ? _self._headers : headers // ignore: cast_nullable_to_non_nullable
as Map<String, Secret>,
  ));
}


}

/// @nodoc
mixin _$Configuration {

 String get id; ConfigurationKind get kind; String get name;/// Subscription host, for display only.
 String? get sourceDisplay; bool get autoUpdate; Usage? get usage; DateTime? get lastSuccessAt; DateTime? get lastAttemptAt;/// The last refresh error, already redacted.
 String? get lastError; DateTime get createdAt; DateTime get editedAt;
/// Create a copy of Configuration
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConfigurationCopyWith<Configuration> get copyWith => _$ConfigurationCopyWithImpl<Configuration>(this as Configuration, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Configuration&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.name, name) || other.name == name)&&(identical(other.sourceDisplay, sourceDisplay) || other.sourceDisplay == sourceDisplay)&&(identical(other.autoUpdate, autoUpdate) || other.autoUpdate == autoUpdate)&&(identical(other.usage, usage) || other.usage == usage)&&(identical(other.lastSuccessAt, lastSuccessAt) || other.lastSuccessAt == lastSuccessAt)&&(identical(other.lastAttemptAt, lastAttemptAt) || other.lastAttemptAt == lastAttemptAt)&&(identical(other.lastError, lastError) || other.lastError == lastError)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.editedAt, editedAt) || other.editedAt == editedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,kind,name,sourceDisplay,autoUpdate,usage,lastSuccessAt,lastAttemptAt,lastError,createdAt,editedAt);

@override
String toString() {
  return 'Configuration(id: $id, kind: $kind, name: $name, sourceDisplay: $sourceDisplay, autoUpdate: $autoUpdate, usage: $usage, lastSuccessAt: $lastSuccessAt, lastAttemptAt: $lastAttemptAt, lastError: $lastError, createdAt: $createdAt, editedAt: $editedAt)';
}


}

/// @nodoc
abstract mixin class $ConfigurationCopyWith<$Res>  {
  factory $ConfigurationCopyWith(Configuration value, $Res Function(Configuration) _then) = _$ConfigurationCopyWithImpl;
@useResult
$Res call({
 String id, ConfigurationKind kind, String name, String? sourceDisplay, bool autoUpdate, Usage? usage, DateTime? lastSuccessAt, DateTime? lastAttemptAt, String? lastError, DateTime createdAt, DateTime editedAt
});


$UsageCopyWith<$Res>? get usage;

}
/// @nodoc
class _$ConfigurationCopyWithImpl<$Res>
    implements $ConfigurationCopyWith<$Res> {
  _$ConfigurationCopyWithImpl(this._self, this._then);

  final Configuration _self;
  final $Res Function(Configuration) _then;

/// Create a copy of Configuration
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? name = null,Object? sourceDisplay = freezed,Object? autoUpdate = null,Object? usage = freezed,Object? lastSuccessAt = freezed,Object? lastAttemptAt = freezed,Object? lastError = freezed,Object? createdAt = null,Object? editedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ConfigurationKind,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sourceDisplay: freezed == sourceDisplay ? _self.sourceDisplay : sourceDisplay // ignore: cast_nullable_to_non_nullable
as String?,autoUpdate: null == autoUpdate ? _self.autoUpdate : autoUpdate // ignore: cast_nullable_to_non_nullable
as bool,usage: freezed == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as Usage?,lastSuccessAt: freezed == lastSuccessAt ? _self.lastSuccessAt : lastSuccessAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastAttemptAt: freezed == lastAttemptAt ? _self.lastAttemptAt : lastAttemptAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,editedAt: null == editedAt ? _self.editedAt : editedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}
/// Create a copy of Configuration
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UsageCopyWith<$Res>? get usage {
    if (_self.usage == null) {
    return null;
  }

  return $UsageCopyWith<$Res>(_self.usage!, (value) {
    return _then(_self.copyWith(usage: value));
  });
}
}


/// Adds pattern-matching-related methods to [Configuration].
extension ConfigurationPatterns on Configuration {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Configuration value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Configuration() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Configuration value)  $default,){
final _that = this;
switch (_that) {
case _Configuration():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Configuration value)?  $default,){
final _that = this;
switch (_that) {
case _Configuration() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  ConfigurationKind kind,  String name,  String? sourceDisplay,  bool autoUpdate,  Usage? usage,  DateTime? lastSuccessAt,  DateTime? lastAttemptAt,  String? lastError,  DateTime createdAt,  DateTime editedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Configuration() when $default != null:
return $default(_that.id,_that.kind,_that.name,_that.sourceDisplay,_that.autoUpdate,_that.usage,_that.lastSuccessAt,_that.lastAttemptAt,_that.lastError,_that.createdAt,_that.editedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  ConfigurationKind kind,  String name,  String? sourceDisplay,  bool autoUpdate,  Usage? usage,  DateTime? lastSuccessAt,  DateTime? lastAttemptAt,  String? lastError,  DateTime createdAt,  DateTime editedAt)  $default,) {final _that = this;
switch (_that) {
case _Configuration():
return $default(_that.id,_that.kind,_that.name,_that.sourceDisplay,_that.autoUpdate,_that.usage,_that.lastSuccessAt,_that.lastAttemptAt,_that.lastError,_that.createdAt,_that.editedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  ConfigurationKind kind,  String name,  String? sourceDisplay,  bool autoUpdate,  Usage? usage,  DateTime? lastSuccessAt,  DateTime? lastAttemptAt,  String? lastError,  DateTime createdAt,  DateTime editedAt)?  $default,) {final _that = this;
switch (_that) {
case _Configuration() when $default != null:
return $default(_that.id,_that.kind,_that.name,_that.sourceDisplay,_that.autoUpdate,_that.usage,_that.lastSuccessAt,_that.lastAttemptAt,_that.lastError,_that.createdAt,_that.editedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Configuration implements Configuration {
  const _Configuration({required this.id, required this.kind, required this.name, this.sourceDisplay, this.autoUpdate = true, this.usage, this.lastSuccessAt, this.lastAttemptAt, this.lastError, required this.createdAt, required this.editedAt});
  

@override final  String id;
@override final  ConfigurationKind kind;
@override final  String name;
/// Subscription host, for display only.
@override final  String? sourceDisplay;
@override@JsonKey() final  bool autoUpdate;
@override final  Usage? usage;
@override final  DateTime? lastSuccessAt;
@override final  DateTime? lastAttemptAt;
/// The last refresh error, already redacted.
@override final  String? lastError;
@override final  DateTime createdAt;
@override final  DateTime editedAt;

/// Create a copy of Configuration
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConfigurationCopyWith<_Configuration> get copyWith => __$ConfigurationCopyWithImpl<_Configuration>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Configuration&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.name, name) || other.name == name)&&(identical(other.sourceDisplay, sourceDisplay) || other.sourceDisplay == sourceDisplay)&&(identical(other.autoUpdate, autoUpdate) || other.autoUpdate == autoUpdate)&&(identical(other.usage, usage) || other.usage == usage)&&(identical(other.lastSuccessAt, lastSuccessAt) || other.lastSuccessAt == lastSuccessAt)&&(identical(other.lastAttemptAt, lastAttemptAt) || other.lastAttemptAt == lastAttemptAt)&&(identical(other.lastError, lastError) || other.lastError == lastError)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.editedAt, editedAt) || other.editedAt == editedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,kind,name,sourceDisplay,autoUpdate,usage,lastSuccessAt,lastAttemptAt,lastError,createdAt,editedAt);

@override
String toString() {
  return 'Configuration(id: $id, kind: $kind, name: $name, sourceDisplay: $sourceDisplay, autoUpdate: $autoUpdate, usage: $usage, lastSuccessAt: $lastSuccessAt, lastAttemptAt: $lastAttemptAt, lastError: $lastError, createdAt: $createdAt, editedAt: $editedAt)';
}


}

/// @nodoc
abstract mixin class _$ConfigurationCopyWith<$Res> implements $ConfigurationCopyWith<$Res> {
  factory _$ConfigurationCopyWith(_Configuration value, $Res Function(_Configuration) _then) = __$ConfigurationCopyWithImpl;
@override @useResult
$Res call({
 String id, ConfigurationKind kind, String name, String? sourceDisplay, bool autoUpdate, Usage? usage, DateTime? lastSuccessAt, DateTime? lastAttemptAt, String? lastError, DateTime createdAt, DateTime editedAt
});


@override $UsageCopyWith<$Res>? get usage;

}
/// @nodoc
class __$ConfigurationCopyWithImpl<$Res>
    implements _$ConfigurationCopyWith<$Res> {
  __$ConfigurationCopyWithImpl(this._self, this._then);

  final _Configuration _self;
  final $Res Function(_Configuration) _then;

/// Create a copy of Configuration
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? name = null,Object? sourceDisplay = freezed,Object? autoUpdate = null,Object? usage = freezed,Object? lastSuccessAt = freezed,Object? lastAttemptAt = freezed,Object? lastError = freezed,Object? createdAt = null,Object? editedAt = null,}) {
  return _then(_Configuration(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as ConfigurationKind,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,sourceDisplay: freezed == sourceDisplay ? _self.sourceDisplay : sourceDisplay // ignore: cast_nullable_to_non_nullable
as String?,autoUpdate: null == autoUpdate ? _self.autoUpdate : autoUpdate // ignore: cast_nullable_to_non_nullable
as bool,usage: freezed == usage ? _self.usage : usage // ignore: cast_nullable_to_non_nullable
as Usage?,lastSuccessAt: freezed == lastSuccessAt ? _self.lastSuccessAt : lastSuccessAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastAttemptAt: freezed == lastAttemptAt ? _self.lastAttemptAt : lastAttemptAt // ignore: cast_nullable_to_non_nullable
as DateTime?,lastError: freezed == lastError ? _self.lastError : lastError // ignore: cast_nullable_to_non_nullable
as String?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,editedAt: null == editedAt ? _self.editedAt : editedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

/// Create a copy of Configuration
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$UsageCopyWith<$Res>? get usage {
    if (_self.usage == null) {
    return null;
  }

  return $UsageCopyWith<$Res>(_self.usage!, (value) {
    return _then(_self.copyWith(usage: value));
  });
}
}

// dart format on
