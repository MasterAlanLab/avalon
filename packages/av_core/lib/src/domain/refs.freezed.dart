// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'refs.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
MemberRef _$MemberRefFromJson(
  Map<String, dynamic> json
) {
        switch (json['kind']) {
                  case 'source':
          return SourceMember.fromJson(
            json
          );
                case 'selfNode':
          return SelfNodeRef.fromJson(
            json
          );
                case 'chain':
          return ChainRef.fromJson(
            json
          );
                case 'tailnetExit':
          return TailnetExitRef.fromJson(
            json
          );
                case 'builtin':
          return BuiltinRef.fromJson(
            json
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'kind',
  'MemberRef',
  'Invalid union type "${json['kind']}"!'
);
        }
      
}

/// @nodoc
mixin _$MemberRef {



  /// Serializes this MemberRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MemberRef);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'MemberRef()';
}


}

/// @nodoc
class $MemberRefCopyWith<$Res>  {
$MemberRefCopyWith(MemberRef _, $Res Function(MemberRef) __);
}


/// Adds pattern-matching-related methods to [MemberRef].
extension MemberRefPatterns on MemberRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SourceMember value)?  source,TResult Function( SelfNodeRef value)?  selfNode,TResult Function( ChainRef value)?  chain,TResult Function( TailnetExitRef value)?  tailnetExit,TResult Function( BuiltinRef value)?  builtin,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SourceMember() when source != null:
return source(_that);case SelfNodeRef() when selfNode != null:
return selfNode(_that);case ChainRef() when chain != null:
return chain(_that);case TailnetExitRef() when tailnetExit != null:
return tailnetExit(_that);case BuiltinRef() when builtin != null:
return builtin(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SourceMember value)  source,required TResult Function( SelfNodeRef value)  selfNode,required TResult Function( ChainRef value)  chain,required TResult Function( TailnetExitRef value)  tailnetExit,required TResult Function( BuiltinRef value)  builtin,}){
final _that = this;
switch (_that) {
case SourceMember():
return source(_that);case SelfNodeRef():
return selfNode(_that);case ChainRef():
return chain(_that);case TailnetExitRef():
return tailnetExit(_that);case BuiltinRef():
return builtin(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SourceMember value)?  source,TResult? Function( SelfNodeRef value)?  selfNode,TResult? Function( ChainRef value)?  chain,TResult? Function( TailnetExitRef value)?  tailnetExit,TResult? Function( BuiltinRef value)?  builtin,}){
final _that = this;
switch (_that) {
case SourceMember() when source != null:
return source(_that);case SelfNodeRef() when selfNode != null:
return selfNode(_that);case ChainRef() when chain != null:
return chain(_that);case TailnetExitRef() when tailnetExit != null:
return tailnetExit(_that);case BuiltinRef() when builtin != null:
return builtin(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String configurationId,  String key)?  source,TResult Function( String id)?  selfNode,TResult Function( String id)?  chain,TResult Function( String tailnet,  String nodeStableId,  String name)?  tailnetExit,TResult Function( Builtin builtin)?  builtin,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SourceMember() when source != null:
return source(_that.configurationId,_that.key);case SelfNodeRef() when selfNode != null:
return selfNode(_that.id);case ChainRef() when chain != null:
return chain(_that.id);case TailnetExitRef() when tailnetExit != null:
return tailnetExit(_that.tailnet,_that.nodeStableId,_that.name);case BuiltinRef() when builtin != null:
return builtin(_that.builtin);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String configurationId,  String key)  source,required TResult Function( String id)  selfNode,required TResult Function( String id)  chain,required TResult Function( String tailnet,  String nodeStableId,  String name)  tailnetExit,required TResult Function( Builtin builtin)  builtin,}) {final _that = this;
switch (_that) {
case SourceMember():
return source(_that.configurationId,_that.key);case SelfNodeRef():
return selfNode(_that.id);case ChainRef():
return chain(_that.id);case TailnetExitRef():
return tailnetExit(_that.tailnet,_that.nodeStableId,_that.name);case BuiltinRef():
return builtin(_that.builtin);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String configurationId,  String key)?  source,TResult? Function( String id)?  selfNode,TResult? Function( String id)?  chain,TResult? Function( String tailnet,  String nodeStableId,  String name)?  tailnetExit,TResult? Function( Builtin builtin)?  builtin,}) {final _that = this;
switch (_that) {
case SourceMember() when source != null:
return source(_that.configurationId,_that.key);case SelfNodeRef() when selfNode != null:
return selfNode(_that.id);case ChainRef() when chain != null:
return chain(_that.id);case TailnetExitRef() when tailnetExit != null:
return tailnetExit(_that.tailnet,_that.nodeStableId,_that.name);case BuiltinRef() when builtin != null:
return builtin(_that.builtin);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class SourceMember extends MemberRef {
  const SourceMember({required this.configurationId, required this.key, final  String? $type}): $type = $type ?? 'source',super._();
  factory SourceMember.fromJson(Map<String, dynamic> json) => _$SourceMemberFromJson(json);

 final  String configurationId;
 final  String key;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of MemberRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SourceMemberCopyWith<SourceMember> get copyWith => _$SourceMemberCopyWithImpl<SourceMember>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SourceMemberToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SourceMember&&(identical(other.configurationId, configurationId) || other.configurationId == configurationId)&&(identical(other.key, key) || other.key == key));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,configurationId,key);

@override
String toString() {
  return 'MemberRef.source(configurationId: $configurationId, key: $key)';
}


}

/// @nodoc
abstract mixin class $SourceMemberCopyWith<$Res> implements $MemberRefCopyWith<$Res> {
  factory $SourceMemberCopyWith(SourceMember value, $Res Function(SourceMember) _then) = _$SourceMemberCopyWithImpl;
@useResult
$Res call({
 String configurationId, String key
});




}
/// @nodoc
class _$SourceMemberCopyWithImpl<$Res>
    implements $SourceMemberCopyWith<$Res> {
  _$SourceMemberCopyWithImpl(this._self, this._then);

  final SourceMember _self;
  final $Res Function(SourceMember) _then;

/// Create a copy of MemberRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? configurationId = null,Object? key = null,}) {
  return _then(SourceMember(
configurationId: null == configurationId ? _self.configurationId : configurationId // ignore: cast_nullable_to_non_nullable
as String,key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class SelfNodeRef extends MemberRef {
  const SelfNodeRef({required this.id, final  String? $type}): $type = $type ?? 'selfNode',super._();
  factory SelfNodeRef.fromJson(Map<String, dynamic> json) => _$SelfNodeRefFromJson(json);

 final  String id;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of MemberRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SelfNodeRefCopyWith<SelfNodeRef> get copyWith => _$SelfNodeRefCopyWithImpl<SelfNodeRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SelfNodeRefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SelfNodeRef&&(identical(other.id, id) || other.id == id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'MemberRef.selfNode(id: $id)';
}


}

/// @nodoc
abstract mixin class $SelfNodeRefCopyWith<$Res> implements $MemberRefCopyWith<$Res> {
  factory $SelfNodeRefCopyWith(SelfNodeRef value, $Res Function(SelfNodeRef) _then) = _$SelfNodeRefCopyWithImpl;
@useResult
$Res call({
 String id
});




}
/// @nodoc
class _$SelfNodeRefCopyWithImpl<$Res>
    implements $SelfNodeRefCopyWith<$Res> {
  _$SelfNodeRefCopyWithImpl(this._self, this._then);

  final SelfNodeRef _self;
  final $Res Function(SelfNodeRef) _then;

/// Create a copy of MemberRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(SelfNodeRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class ChainRef extends MemberRef {
  const ChainRef({required this.id, final  String? $type}): $type = $type ?? 'chain',super._();
  factory ChainRef.fromJson(Map<String, dynamic> json) => _$ChainRefFromJson(json);

 final  String id;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of MemberRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChainRefCopyWith<ChainRef> get copyWith => _$ChainRefCopyWithImpl<ChainRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChainRefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChainRef&&(identical(other.id, id) || other.id == id));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id);

@override
String toString() {
  return 'MemberRef.chain(id: $id)';
}


}

/// @nodoc
abstract mixin class $ChainRefCopyWith<$Res> implements $MemberRefCopyWith<$Res> {
  factory $ChainRefCopyWith(ChainRef value, $Res Function(ChainRef) _then) = _$ChainRefCopyWithImpl;
@useResult
$Res call({
 String id
});




}
/// @nodoc
class _$ChainRefCopyWithImpl<$Res>
    implements $ChainRefCopyWith<$Res> {
  _$ChainRefCopyWithImpl(this._self, this._then);

  final ChainRef _self;
  final $Res Function(ChainRef) _then;

/// Create a copy of MemberRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(ChainRef(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class TailnetExitRef extends MemberRef {
  const TailnetExitRef({required this.tailnet, required this.nodeStableId, required this.name, final  String? $type}): $type = $type ?? 'tailnetExit',super._();
  factory TailnetExitRef.fromJson(Map<String, dynamic> json) => _$TailnetExitRefFromJson(json);

 final  String tailnet;
 final  String nodeStableId;
 final  String name;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of MemberRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TailnetExitRefCopyWith<TailnetExitRef> get copyWith => _$TailnetExitRefCopyWithImpl<TailnetExitRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TailnetExitRefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TailnetExitRef&&(identical(other.tailnet, tailnet) || other.tailnet == tailnet)&&(identical(other.nodeStableId, nodeStableId) || other.nodeStableId == nodeStableId)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tailnet,nodeStableId,name);

@override
String toString() {
  return 'MemberRef.tailnetExit(tailnet: $tailnet, nodeStableId: $nodeStableId, name: $name)';
}


}

/// @nodoc
abstract mixin class $TailnetExitRefCopyWith<$Res> implements $MemberRefCopyWith<$Res> {
  factory $TailnetExitRefCopyWith(TailnetExitRef value, $Res Function(TailnetExitRef) _then) = _$TailnetExitRefCopyWithImpl;
@useResult
$Res call({
 String tailnet, String nodeStableId, String name
});




}
/// @nodoc
class _$TailnetExitRefCopyWithImpl<$Res>
    implements $TailnetExitRefCopyWith<$Res> {
  _$TailnetExitRefCopyWithImpl(this._self, this._then);

  final TailnetExitRef _self;
  final $Res Function(TailnetExitRef) _then;

/// Create a copy of MemberRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? tailnet = null,Object? nodeStableId = null,Object? name = null,}) {
  return _then(TailnetExitRef(
tailnet: null == tailnet ? _self.tailnet : tailnet // ignore: cast_nullable_to_non_nullable
as String,nodeStableId: null == nodeStableId ? _self.nodeStableId : nodeStableId // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
@JsonSerializable()

class BuiltinRef extends MemberRef {
  const BuiltinRef({required this.builtin, final  String? $type}): $type = $type ?? 'builtin',super._();
  factory BuiltinRef.fromJson(Map<String, dynamic> json) => _$BuiltinRefFromJson(json);

 final  Builtin builtin;

@JsonKey(name: 'kind')
final String $type;


/// Create a copy of MemberRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuiltinRefCopyWith<BuiltinRef> get copyWith => _$BuiltinRefCopyWithImpl<BuiltinRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BuiltinRefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuiltinRef&&(identical(other.builtin, builtin) || other.builtin == builtin));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,builtin);

@override
String toString() {
  return 'MemberRef.builtin(builtin: $builtin)';
}


}

/// @nodoc
abstract mixin class $BuiltinRefCopyWith<$Res> implements $MemberRefCopyWith<$Res> {
  factory $BuiltinRefCopyWith(BuiltinRef value, $Res Function(BuiltinRef) _then) = _$BuiltinRefCopyWithImpl;
@useResult
$Res call({
 Builtin builtin
});




}
/// @nodoc
class _$BuiltinRefCopyWithImpl<$Res>
    implements $BuiltinRefCopyWith<$Res> {
  _$BuiltinRefCopyWithImpl(this._self, this._then);

  final BuiltinRef _self;
  final $Res Function(BuiltinRef) _then;

/// Create a copy of MemberRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? builtin = null,}) {
  return _then(BuiltinRef(
builtin: null == builtin ? _self.builtin : builtin // ignore: cast_nullable_to_non_nullable
as Builtin,
  ));
}


}

// dart format on
