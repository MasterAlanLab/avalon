// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_content.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SelfNode {

 String get id; String get name; String get server; int get port; NodeParams get params;
/// Create a copy of SelfNode
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SelfNodeCopyWith<SelfNode> get copyWith => _$SelfNodeCopyWithImpl<SelfNode>(this as SelfNode, _$identity);

  /// Serializes this SelfNode to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SelfNode&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.server, server) || other.server == server)&&(identical(other.port, port) || other.port == port)&&(identical(other.params, params) || other.params == params));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,server,port,params);

@override
String toString() {
  return 'SelfNode(id: $id, name: $name, server: $server, port: $port, params: $params)';
}


}

/// @nodoc
abstract mixin class $SelfNodeCopyWith<$Res>  {
  factory $SelfNodeCopyWith(SelfNode value, $Res Function(SelfNode) _then) = _$SelfNodeCopyWithImpl;
@useResult
$Res call({
 String id, String name, String server, int port, NodeParams params
});


$NodeParamsCopyWith<$Res> get params;

}
/// @nodoc
class _$SelfNodeCopyWithImpl<$Res>
    implements $SelfNodeCopyWith<$Res> {
  _$SelfNodeCopyWithImpl(this._self, this._then);

  final SelfNode _self;
  final $Res Function(SelfNode) _then;

/// Create a copy of SelfNode
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? server = null,Object? port = null,Object? params = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,server: null == server ? _self.server : server // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,params: null == params ? _self.params : params // ignore: cast_nullable_to_non_nullable
as NodeParams,
  ));
}
/// Create a copy of SelfNode
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NodeParamsCopyWith<$Res> get params {
  
  return $NodeParamsCopyWith<$Res>(_self.params, (value) {
    return _then(_self.copyWith(params: value));
  });
}
}


/// Adds pattern-matching-related methods to [SelfNode].
extension SelfNodePatterns on SelfNode {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SelfNode value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SelfNode() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SelfNode value)  $default,){
final _that = this;
switch (_that) {
case _SelfNode():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SelfNode value)?  $default,){
final _that = this;
switch (_that) {
case _SelfNode() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String server,  int port,  NodeParams params)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SelfNode() when $default != null:
return $default(_that.id,_that.name,_that.server,_that.port,_that.params);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String server,  int port,  NodeParams params)  $default,) {final _that = this;
switch (_that) {
case _SelfNode():
return $default(_that.id,_that.name,_that.server,_that.port,_that.params);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String server,  int port,  NodeParams params)?  $default,) {final _that = this;
switch (_that) {
case _SelfNode() when $default != null:
return $default(_that.id,_that.name,_that.server,_that.port,_that.params);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SelfNode implements SelfNode {
  const _SelfNode({required this.id, required this.name, required this.server, required this.port, required this.params});
  factory _SelfNode.fromJson(Map<String, dynamic> json) => _$SelfNodeFromJson(json);

@override final  String id;
@override final  String name;
@override final  String server;
@override final  int port;
@override final  NodeParams params;

/// Create a copy of SelfNode
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SelfNodeCopyWith<_SelfNode> get copyWith => __$SelfNodeCopyWithImpl<_SelfNode>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SelfNodeToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SelfNode&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.server, server) || other.server == server)&&(identical(other.port, port) || other.port == port)&&(identical(other.params, params) || other.params == params));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,server,port,params);

@override
String toString() {
  return 'SelfNode(id: $id, name: $name, server: $server, port: $port, params: $params)';
}


}

/// @nodoc
abstract mixin class _$SelfNodeCopyWith<$Res> implements $SelfNodeCopyWith<$Res> {
  factory _$SelfNodeCopyWith(_SelfNode value, $Res Function(_SelfNode) _then) = __$SelfNodeCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String server, int port, NodeParams params
});


@override $NodeParamsCopyWith<$Res> get params;

}
/// @nodoc
class __$SelfNodeCopyWithImpl<$Res>
    implements _$SelfNodeCopyWith<$Res> {
  __$SelfNodeCopyWithImpl(this._self, this._then);

  final _SelfNode _self;
  final $Res Function(_SelfNode) _then;

/// Create a copy of SelfNode
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? server = null,Object? port = null,Object? params = null,}) {
  return _then(_SelfNode(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,server: null == server ? _self.server : server // ignore: cast_nullable_to_non_nullable
as String,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as int,params: null == params ? _self.params : params // ignore: cast_nullable_to_non_nullable
as NodeParams,
  ));
}

/// Create a copy of SelfNode
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$NodeParamsCopyWith<$Res> get params {
  
  return $NodeParamsCopyWith<$Res>(_self.params, (value) {
    return _then(_self.copyWith(params: value));
  });
}
}


/// @nodoc
mixin _$Chain {

 String get id;/// Null shows the hop names joined (PRODUCT_SPEC §3.7).
 String? get name; List<MemberRef> get hops;
/// Create a copy of Chain
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChainCopyWith<Chain> get copyWith => _$ChainCopyWithImpl<Chain>(this as Chain, _$identity);

  /// Serializes this Chain to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Chain&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other.hops, hops));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(hops));

@override
String toString() {
  return 'Chain(id: $id, name: $name, hops: $hops)';
}


}

/// @nodoc
abstract mixin class $ChainCopyWith<$Res>  {
  factory $ChainCopyWith(Chain value, $Res Function(Chain) _then) = _$ChainCopyWithImpl;
@useResult
$Res call({
 String id, String? name, List<MemberRef> hops
});




}
/// @nodoc
class _$ChainCopyWithImpl<$Res>
    implements $ChainCopyWith<$Res> {
  _$ChainCopyWithImpl(this._self, this._then);

  final Chain _self;
  final $Res Function(Chain) _then;

/// Create a copy of Chain
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = freezed,Object? hops = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,hops: null == hops ? _self.hops : hops // ignore: cast_nullable_to_non_nullable
as List<MemberRef>,
  ));
}

}


/// Adds pattern-matching-related methods to [Chain].
extension ChainPatterns on Chain {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Chain value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Chain() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Chain value)  $default,){
final _that = this;
switch (_that) {
case _Chain():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Chain value)?  $default,){
final _that = this;
switch (_that) {
case _Chain() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String? name,  List<MemberRef> hops)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Chain() when $default != null:
return $default(_that.id,_that.name,_that.hops);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String? name,  List<MemberRef> hops)  $default,) {final _that = this;
switch (_that) {
case _Chain():
return $default(_that.id,_that.name,_that.hops);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String? name,  List<MemberRef> hops)?  $default,) {final _that = this;
switch (_that) {
case _Chain() when $default != null:
return $default(_that.id,_that.name,_that.hops);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Chain extends Chain {
  const _Chain({required this.id, this.name, required final  List<MemberRef> hops}): _hops = hops,super._();
  factory _Chain.fromJson(Map<String, dynamic> json) => _$ChainFromJson(json);

@override final  String id;
/// Null shows the hop names joined (PRODUCT_SPEC §3.7).
@override final  String? name;
 final  List<MemberRef> _hops;
@override List<MemberRef> get hops {
  if (_hops is EqualUnmodifiableListView) return _hops;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_hops);
}


/// Create a copy of Chain
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChainCopyWith<_Chain> get copyWith => __$ChainCopyWithImpl<_Chain>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChainToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Chain&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&const DeepCollectionEquality().equals(other._hops, _hops));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,const DeepCollectionEquality().hash(_hops));

@override
String toString() {
  return 'Chain(id: $id, name: $name, hops: $hops)';
}


}

/// @nodoc
abstract mixin class _$ChainCopyWith<$Res> implements $ChainCopyWith<$Res> {
  factory _$ChainCopyWith(_Chain value, $Res Function(_Chain) _then) = __$ChainCopyWithImpl;
@override @useResult
$Res call({
 String id, String? name, List<MemberRef> hops
});




}
/// @nodoc
class __$ChainCopyWithImpl<$Res>
    implements _$ChainCopyWith<$Res> {
  __$ChainCopyWithImpl(this._self, this._then);

  final _Chain _self;
  final $Res Function(_Chain) _then;

/// Create a copy of Chain
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = freezed,Object? hops = null,}) {
  return _then(_Chain(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,hops: null == hops ? _self._hops : hops // ignore: cast_nullable_to_non_nullable
as List<MemberRef>,
  ));
}


}


/// @nodoc
mixin _$Membership {

 MemberOwner get ownerKind; String get ownerId; String get configurationId; String get groupKey;
/// Create a copy of Membership
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MembershipCopyWith<Membership> get copyWith => _$MembershipCopyWithImpl<Membership>(this as Membership, _$identity);

  /// Serializes this Membership to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Membership&&(identical(other.ownerKind, ownerKind) || other.ownerKind == ownerKind)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.configurationId, configurationId) || other.configurationId == configurationId)&&(identical(other.groupKey, groupKey) || other.groupKey == groupKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ownerKind,ownerId,configurationId,groupKey);

@override
String toString() {
  return 'Membership(ownerKind: $ownerKind, ownerId: $ownerId, configurationId: $configurationId, groupKey: $groupKey)';
}


}

/// @nodoc
abstract mixin class $MembershipCopyWith<$Res>  {
  factory $MembershipCopyWith(Membership value, $Res Function(Membership) _then) = _$MembershipCopyWithImpl;
@useResult
$Res call({
 MemberOwner ownerKind, String ownerId, String configurationId, String groupKey
});




}
/// @nodoc
class _$MembershipCopyWithImpl<$Res>
    implements $MembershipCopyWith<$Res> {
  _$MembershipCopyWithImpl(this._self, this._then);

  final Membership _self;
  final $Res Function(Membership) _then;

/// Create a copy of Membership
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? ownerKind = null,Object? ownerId = null,Object? configurationId = null,Object? groupKey = null,}) {
  return _then(_self.copyWith(
ownerKind: null == ownerKind ? _self.ownerKind : ownerKind // ignore: cast_nullable_to_non_nullable
as MemberOwner,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,configurationId: null == configurationId ? _self.configurationId : configurationId // ignore: cast_nullable_to_non_nullable
as String,groupKey: null == groupKey ? _self.groupKey : groupKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Membership].
extension MembershipPatterns on Membership {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Membership value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Membership() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Membership value)  $default,){
final _that = this;
switch (_that) {
case _Membership():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Membership value)?  $default,){
final _that = this;
switch (_that) {
case _Membership() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( MemberOwner ownerKind,  String ownerId,  String configurationId,  String groupKey)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Membership() when $default != null:
return $default(_that.ownerKind,_that.ownerId,_that.configurationId,_that.groupKey);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( MemberOwner ownerKind,  String ownerId,  String configurationId,  String groupKey)  $default,) {final _that = this;
switch (_that) {
case _Membership():
return $default(_that.ownerKind,_that.ownerId,_that.configurationId,_that.groupKey);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( MemberOwner ownerKind,  String ownerId,  String configurationId,  String groupKey)?  $default,) {final _that = this;
switch (_that) {
case _Membership() when $default != null:
return $default(_that.ownerKind,_that.ownerId,_that.configurationId,_that.groupKey);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Membership implements Membership {
  const _Membership({required this.ownerKind, required this.ownerId, required this.configurationId, required this.groupKey});
  factory _Membership.fromJson(Map<String, dynamic> json) => _$MembershipFromJson(json);

@override final  MemberOwner ownerKind;
@override final  String ownerId;
@override final  String configurationId;
@override final  String groupKey;

/// Create a copy of Membership
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MembershipCopyWith<_Membership> get copyWith => __$MembershipCopyWithImpl<_Membership>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$MembershipToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Membership&&(identical(other.ownerKind, ownerKind) || other.ownerKind == ownerKind)&&(identical(other.ownerId, ownerId) || other.ownerId == ownerId)&&(identical(other.configurationId, configurationId) || other.configurationId == configurationId)&&(identical(other.groupKey, groupKey) || other.groupKey == groupKey));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,ownerKind,ownerId,configurationId,groupKey);

@override
String toString() {
  return 'Membership(ownerKind: $ownerKind, ownerId: $ownerId, configurationId: $configurationId, groupKey: $groupKey)';
}


}

/// @nodoc
abstract mixin class _$MembershipCopyWith<$Res> implements $MembershipCopyWith<$Res> {
  factory _$MembershipCopyWith(_Membership value, $Res Function(_Membership) _then) = __$MembershipCopyWithImpl;
@override @useResult
$Res call({
 MemberOwner ownerKind, String ownerId, String configurationId, String groupKey
});




}
/// @nodoc
class __$MembershipCopyWithImpl<$Res>
    implements _$MembershipCopyWith<$Res> {
  __$MembershipCopyWithImpl(this._self, this._then);

  final _Membership _self;
  final $Res Function(_Membership) _then;

/// Create a copy of Membership
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? ownerKind = null,Object? ownerId = null,Object? configurationId = null,Object? groupKey = null,}) {
  return _then(_Membership(
ownerKind: null == ownerKind ? _self.ownerKind : ownerKind // ignore: cast_nullable_to_non_nullable
as MemberOwner,ownerId: null == ownerId ? _self.ownerId : ownerId // ignore: cast_nullable_to_non_nullable
as String,configurationId: null == configurationId ? _self.configurationId : configurationId // ignore: cast_nullable_to_non_nullable
as String,groupKey: null == groupKey ? _self.groupKey : groupKey // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
