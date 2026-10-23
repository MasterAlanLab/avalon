// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'content.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GroupTest {

 String get url; int get intervalSeconds; int get toleranceMs;
/// Create a copy of GroupTest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupTestCopyWith<GroupTest> get copyWith => _$GroupTestCopyWithImpl<GroupTest>(this as GroupTest, _$identity);

  /// Serializes this GroupTest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupTest&&(identical(other.url, url) || other.url == url)&&(identical(other.intervalSeconds, intervalSeconds) || other.intervalSeconds == intervalSeconds)&&(identical(other.toleranceMs, toleranceMs) || other.toleranceMs == toleranceMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,intervalSeconds,toleranceMs);

@override
String toString() {
  return 'GroupTest(url: $url, intervalSeconds: $intervalSeconds, toleranceMs: $toleranceMs)';
}


}

/// @nodoc
abstract mixin class $GroupTestCopyWith<$Res>  {
  factory $GroupTestCopyWith(GroupTest value, $Res Function(GroupTest) _then) = _$GroupTestCopyWithImpl;
@useResult
$Res call({
 String url, int intervalSeconds, int toleranceMs
});




}
/// @nodoc
class _$GroupTestCopyWithImpl<$Res>
    implements $GroupTestCopyWith<$Res> {
  _$GroupTestCopyWithImpl(this._self, this._then);

  final GroupTest _self;
  final $Res Function(GroupTest) _then;

/// Create a copy of GroupTest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? url = null,Object? intervalSeconds = null,Object? toleranceMs = null,}) {
  return _then(_self.copyWith(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,intervalSeconds: null == intervalSeconds ? _self.intervalSeconds : intervalSeconds // ignore: cast_nullable_to_non_nullable
as int,toleranceMs: null == toleranceMs ? _self.toleranceMs : toleranceMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [GroupTest].
extension GroupTestPatterns on GroupTest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupTest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupTest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupTest value)  $default,){
final _that = this;
switch (_that) {
case _GroupTest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupTest value)?  $default,){
final _that = this;
switch (_that) {
case _GroupTest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String url,  int intervalSeconds,  int toleranceMs)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupTest() when $default != null:
return $default(_that.url,_that.intervalSeconds,_that.toleranceMs);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String url,  int intervalSeconds,  int toleranceMs)  $default,) {final _that = this;
switch (_that) {
case _GroupTest():
return $default(_that.url,_that.intervalSeconds,_that.toleranceMs);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String url,  int intervalSeconds,  int toleranceMs)?  $default,) {final _that = this;
switch (_that) {
case _GroupTest() when $default != null:
return $default(_that.url,_that.intervalSeconds,_that.toleranceMs);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroupTest implements GroupTest {
  const _GroupTest({required this.url, this.intervalSeconds = 180, this.toleranceMs = 50});
  factory _GroupTest.fromJson(Map<String, dynamic> json) => _$GroupTestFromJson(json);

@override final  String url;
@override@JsonKey() final  int intervalSeconds;
@override@JsonKey() final  int toleranceMs;

/// Create a copy of GroupTest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupTestCopyWith<_GroupTest> get copyWith => __$GroupTestCopyWithImpl<_GroupTest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupTestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupTest&&(identical(other.url, url) || other.url == url)&&(identical(other.intervalSeconds, intervalSeconds) || other.intervalSeconds == intervalSeconds)&&(identical(other.toleranceMs, toleranceMs) || other.toleranceMs == toleranceMs));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,url,intervalSeconds,toleranceMs);

@override
String toString() {
  return 'GroupTest(url: $url, intervalSeconds: $intervalSeconds, toleranceMs: $toleranceMs)';
}


}

/// @nodoc
abstract mixin class _$GroupTestCopyWith<$Res> implements $GroupTestCopyWith<$Res> {
  factory _$GroupTestCopyWith(_GroupTest value, $Res Function(_GroupTest) _then) = __$GroupTestCopyWithImpl;
@override @useResult
$Res call({
 String url, int intervalSeconds, int toleranceMs
});




}
/// @nodoc
class __$GroupTestCopyWithImpl<$Res>
    implements _$GroupTestCopyWith<$Res> {
  __$GroupTestCopyWithImpl(this._self, this._then);

  final _GroupTest _self;
  final $Res Function(_GroupTest) _then;

/// Create a copy of GroupTest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? url = null,Object? intervalSeconds = null,Object? toleranceMs = null,}) {
  return _then(_GroupTest(
url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,intervalSeconds: null == intervalSeconds ? _self.intervalSeconds : intervalSeconds // ignore: cast_nullable_to_non_nullable
as int,toleranceMs: null == toleranceMs ? _self.toleranceMs : toleranceMs // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$GroupDef {

 String get key; String get name; GroupType get type;/// Type shown to the user: Selector, URLTest, Fallback or LoadBalance.
/// Fallback and LoadBalance run as `urltest` (D28).
 String get displayType;/// Node keys, group keys or [ContentKeys] built-ins, in source order.
 List<String> get members; GroupTest? get test;
/// Create a copy of GroupDef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GroupDefCopyWith<GroupDef> get copyWith => _$GroupDefCopyWithImpl<GroupDef>(this as GroupDef, _$identity);

  /// Serializes this GroupDef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GroupDef&&(identical(other.key, key) || other.key == key)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.displayType, displayType) || other.displayType == displayType)&&const DeepCollectionEquality().equals(other.members, members)&&(identical(other.test, test) || other.test == test));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,name,type,displayType,const DeepCollectionEquality().hash(members),test);

@override
String toString() {
  return 'GroupDef(key: $key, name: $name, type: $type, displayType: $displayType, members: $members, test: $test)';
}


}

/// @nodoc
abstract mixin class $GroupDefCopyWith<$Res>  {
  factory $GroupDefCopyWith(GroupDef value, $Res Function(GroupDef) _then) = _$GroupDefCopyWithImpl;
@useResult
$Res call({
 String key, String name, GroupType type, String displayType, List<String> members, GroupTest? test
});


$GroupTestCopyWith<$Res>? get test;

}
/// @nodoc
class _$GroupDefCopyWithImpl<$Res>
    implements $GroupDefCopyWith<$Res> {
  _$GroupDefCopyWithImpl(this._self, this._then);

  final GroupDef _self;
  final $Res Function(GroupDef) _then;

/// Create a copy of GroupDef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? key = null,Object? name = null,Object? type = null,Object? displayType = null,Object? members = null,Object? test = freezed,}) {
  return _then(_self.copyWith(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as GroupType,displayType: null == displayType ? _self.displayType : displayType // ignore: cast_nullable_to_non_nullable
as String,members: null == members ? _self.members : members // ignore: cast_nullable_to_non_nullable
as List<String>,test: freezed == test ? _self.test : test // ignore: cast_nullable_to_non_nullable
as GroupTest?,
  ));
}
/// Create a copy of GroupDef
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GroupTestCopyWith<$Res>? get test {
    if (_self.test == null) {
    return null;
  }

  return $GroupTestCopyWith<$Res>(_self.test!, (value) {
    return _then(_self.copyWith(test: value));
  });
}
}


/// Adds pattern-matching-related methods to [GroupDef].
extension GroupDefPatterns on GroupDef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GroupDef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GroupDef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GroupDef value)  $default,){
final _that = this;
switch (_that) {
case _GroupDef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GroupDef value)?  $default,){
final _that = this;
switch (_that) {
case _GroupDef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String key,  String name,  GroupType type,  String displayType,  List<String> members,  GroupTest? test)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GroupDef() when $default != null:
return $default(_that.key,_that.name,_that.type,_that.displayType,_that.members,_that.test);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String key,  String name,  GroupType type,  String displayType,  List<String> members,  GroupTest? test)  $default,) {final _that = this;
switch (_that) {
case _GroupDef():
return $default(_that.key,_that.name,_that.type,_that.displayType,_that.members,_that.test);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String key,  String name,  GroupType type,  String displayType,  List<String> members,  GroupTest? test)?  $default,) {final _that = this;
switch (_that) {
case _GroupDef() when $default != null:
return $default(_that.key,_that.name,_that.type,_that.displayType,_that.members,_that.test);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GroupDef implements GroupDef {
  const _GroupDef({required this.key, required this.name, required this.type, required this.displayType, final  List<String> members = const <String>[], this.test}): _members = members;
  factory _GroupDef.fromJson(Map<String, dynamic> json) => _$GroupDefFromJson(json);

@override final  String key;
@override final  String name;
@override final  GroupType type;
/// Type shown to the user: Selector, URLTest, Fallback or LoadBalance.
/// Fallback and LoadBalance run as `urltest` (D28).
@override final  String displayType;
/// Node keys, group keys or [ContentKeys] built-ins, in source order.
 final  List<String> _members;
/// Node keys, group keys or [ContentKeys] built-ins, in source order.
@override@JsonKey() List<String> get members {
  if (_members is EqualUnmodifiableListView) return _members;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_members);
}

@override final  GroupTest? test;

/// Create a copy of GroupDef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GroupDefCopyWith<_GroupDef> get copyWith => __$GroupDefCopyWithImpl<_GroupDef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GroupDefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GroupDef&&(identical(other.key, key) || other.key == key)&&(identical(other.name, name) || other.name == name)&&(identical(other.type, type) || other.type == type)&&(identical(other.displayType, displayType) || other.displayType == displayType)&&const DeepCollectionEquality().equals(other._members, _members)&&(identical(other.test, test) || other.test == test));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,key,name,type,displayType,const DeepCollectionEquality().hash(_members),test);

@override
String toString() {
  return 'GroupDef(key: $key, name: $name, type: $type, displayType: $displayType, members: $members, test: $test)';
}


}

/// @nodoc
abstract mixin class _$GroupDefCopyWith<$Res> implements $GroupDefCopyWith<$Res> {
  factory _$GroupDefCopyWith(_GroupDef value, $Res Function(_GroupDef) _then) = __$GroupDefCopyWithImpl;
@override @useResult
$Res call({
 String key, String name, GroupType type, String displayType, List<String> members, GroupTest? test
});


@override $GroupTestCopyWith<$Res>? get test;

}
/// @nodoc
class __$GroupDefCopyWithImpl<$Res>
    implements _$GroupDefCopyWith<$Res> {
  __$GroupDefCopyWithImpl(this._self, this._then);

  final _GroupDef _self;
  final $Res Function(_GroupDef) _then;

/// Create a copy of GroupDef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? key = null,Object? name = null,Object? type = null,Object? displayType = null,Object? members = null,Object? test = freezed,}) {
  return _then(_GroupDef(
key: null == key ? _self.key : key // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as GroupType,displayType: null == displayType ? _self.displayType : displayType // ignore: cast_nullable_to_non_nullable
as String,members: null == members ? _self._members : members // ignore: cast_nullable_to_non_nullable
as List<String>,test: freezed == test ? _self.test : test // ignore: cast_nullable_to_non_nullable
as GroupTest?,
  ));
}

/// Create a copy of GroupDef
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$GroupTestCopyWith<$Res>? get test {
    if (_self.test == null) {
    return null;
  }

  return $GroupTestCopyWith<$Res>(_self.test!, (value) {
    return _then(_self.copyWith(test: value));
  });
}
}


/// @nodoc
mixin _$RuleDef {

 List<String> get domain; List<String> get domainSuffix; List<String> get domainKeyword; List<String> get domainRegex; List<String> get ipCidr; List<String> get sourceIpCidr; List<String> get ruleSet; List<String> get processName; List<String> get processPath; List<int> get port;/// Ranges such as `1000:2000`.
 List<String> get portRange;/// `tcp` or `udp`.
 List<String> get network; bool get invert;/// Node key, group key or a [ContentKeys] built-in.
 String get target;
/// Create a copy of RuleDef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RuleDefCopyWith<RuleDef> get copyWith => _$RuleDefCopyWithImpl<RuleDef>(this as RuleDef, _$identity);

  /// Serializes this RuleDef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RuleDef&&const DeepCollectionEquality().equals(other.domain, domain)&&const DeepCollectionEquality().equals(other.domainSuffix, domainSuffix)&&const DeepCollectionEquality().equals(other.domainKeyword, domainKeyword)&&const DeepCollectionEquality().equals(other.domainRegex, domainRegex)&&const DeepCollectionEquality().equals(other.ipCidr, ipCidr)&&const DeepCollectionEquality().equals(other.sourceIpCidr, sourceIpCidr)&&const DeepCollectionEquality().equals(other.ruleSet, ruleSet)&&const DeepCollectionEquality().equals(other.processName, processName)&&const DeepCollectionEquality().equals(other.processPath, processPath)&&const DeepCollectionEquality().equals(other.port, port)&&const DeepCollectionEquality().equals(other.portRange, portRange)&&const DeepCollectionEquality().equals(other.network, network)&&(identical(other.invert, invert) || other.invert == invert)&&(identical(other.target, target) || other.target == target));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(domain),const DeepCollectionEquality().hash(domainSuffix),const DeepCollectionEquality().hash(domainKeyword),const DeepCollectionEquality().hash(domainRegex),const DeepCollectionEquality().hash(ipCidr),const DeepCollectionEquality().hash(sourceIpCidr),const DeepCollectionEquality().hash(ruleSet),const DeepCollectionEquality().hash(processName),const DeepCollectionEquality().hash(processPath),const DeepCollectionEquality().hash(port),const DeepCollectionEquality().hash(portRange),const DeepCollectionEquality().hash(network),invert,target);

@override
String toString() {
  return 'RuleDef(domain: $domain, domainSuffix: $domainSuffix, domainKeyword: $domainKeyword, domainRegex: $domainRegex, ipCidr: $ipCidr, sourceIpCidr: $sourceIpCidr, ruleSet: $ruleSet, processName: $processName, processPath: $processPath, port: $port, portRange: $portRange, network: $network, invert: $invert, target: $target)';
}


}

/// @nodoc
abstract mixin class $RuleDefCopyWith<$Res>  {
  factory $RuleDefCopyWith(RuleDef value, $Res Function(RuleDef) _then) = _$RuleDefCopyWithImpl;
@useResult
$Res call({
 List<String> domain, List<String> domainSuffix, List<String> domainKeyword, List<String> domainRegex, List<String> ipCidr, List<String> sourceIpCidr, List<String> ruleSet, List<String> processName, List<String> processPath, List<int> port, List<String> portRange, List<String> network, bool invert, String target
});




}
/// @nodoc
class _$RuleDefCopyWithImpl<$Res>
    implements $RuleDefCopyWith<$Res> {
  _$RuleDefCopyWithImpl(this._self, this._then);

  final RuleDef _self;
  final $Res Function(RuleDef) _then;

/// Create a copy of RuleDef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? domain = null,Object? domainSuffix = null,Object? domainKeyword = null,Object? domainRegex = null,Object? ipCidr = null,Object? sourceIpCidr = null,Object? ruleSet = null,Object? processName = null,Object? processPath = null,Object? port = null,Object? portRange = null,Object? network = null,Object? invert = null,Object? target = null,}) {
  return _then(_self.copyWith(
domain: null == domain ? _self.domain : domain // ignore: cast_nullable_to_non_nullable
as List<String>,domainSuffix: null == domainSuffix ? _self.domainSuffix : domainSuffix // ignore: cast_nullable_to_non_nullable
as List<String>,domainKeyword: null == domainKeyword ? _self.domainKeyword : domainKeyword // ignore: cast_nullable_to_non_nullable
as List<String>,domainRegex: null == domainRegex ? _self.domainRegex : domainRegex // ignore: cast_nullable_to_non_nullable
as List<String>,ipCidr: null == ipCidr ? _self.ipCidr : ipCidr // ignore: cast_nullable_to_non_nullable
as List<String>,sourceIpCidr: null == sourceIpCidr ? _self.sourceIpCidr : sourceIpCidr // ignore: cast_nullable_to_non_nullable
as List<String>,ruleSet: null == ruleSet ? _self.ruleSet : ruleSet // ignore: cast_nullable_to_non_nullable
as List<String>,processName: null == processName ? _self.processName : processName // ignore: cast_nullable_to_non_nullable
as List<String>,processPath: null == processPath ? _self.processPath : processPath // ignore: cast_nullable_to_non_nullable
as List<String>,port: null == port ? _self.port : port // ignore: cast_nullable_to_non_nullable
as List<int>,portRange: null == portRange ? _self.portRange : portRange // ignore: cast_nullable_to_non_nullable
as List<String>,network: null == network ? _self.network : network // ignore: cast_nullable_to_non_nullable
as List<String>,invert: null == invert ? _self.invert : invert // ignore: cast_nullable_to_non_nullable
as bool,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RuleDef].
extension RuleDefPatterns on RuleDef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RuleDef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RuleDef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RuleDef value)  $default,){
final _that = this;
switch (_that) {
case _RuleDef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RuleDef value)?  $default,){
final _that = this;
switch (_that) {
case _RuleDef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> domain,  List<String> domainSuffix,  List<String> domainKeyword,  List<String> domainRegex,  List<String> ipCidr,  List<String> sourceIpCidr,  List<String> ruleSet,  List<String> processName,  List<String> processPath,  List<int> port,  List<String> portRange,  List<String> network,  bool invert,  String target)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RuleDef() when $default != null:
return $default(_that.domain,_that.domainSuffix,_that.domainKeyword,_that.domainRegex,_that.ipCidr,_that.sourceIpCidr,_that.ruleSet,_that.processName,_that.processPath,_that.port,_that.portRange,_that.network,_that.invert,_that.target);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> domain,  List<String> domainSuffix,  List<String> domainKeyword,  List<String> domainRegex,  List<String> ipCidr,  List<String> sourceIpCidr,  List<String> ruleSet,  List<String> processName,  List<String> processPath,  List<int> port,  List<String> portRange,  List<String> network,  bool invert,  String target)  $default,) {final _that = this;
switch (_that) {
case _RuleDef():
return $default(_that.domain,_that.domainSuffix,_that.domainKeyword,_that.domainRegex,_that.ipCidr,_that.sourceIpCidr,_that.ruleSet,_that.processName,_that.processPath,_that.port,_that.portRange,_that.network,_that.invert,_that.target);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> domain,  List<String> domainSuffix,  List<String> domainKeyword,  List<String> domainRegex,  List<String> ipCidr,  List<String> sourceIpCidr,  List<String> ruleSet,  List<String> processName,  List<String> processPath,  List<int> port,  List<String> portRange,  List<String> network,  bool invert,  String target)?  $default,) {final _that = this;
switch (_that) {
case _RuleDef() when $default != null:
return $default(_that.domain,_that.domainSuffix,_that.domainKeyword,_that.domainRegex,_that.ipCidr,_that.sourceIpCidr,_that.ruleSet,_that.processName,_that.processPath,_that.port,_that.portRange,_that.network,_that.invert,_that.target);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RuleDef implements RuleDef {
  const _RuleDef({final  List<String> domain = const <String>[], final  List<String> domainSuffix = const <String>[], final  List<String> domainKeyword = const <String>[], final  List<String> domainRegex = const <String>[], final  List<String> ipCidr = const <String>[], final  List<String> sourceIpCidr = const <String>[], final  List<String> ruleSet = const <String>[], final  List<String> processName = const <String>[], final  List<String> processPath = const <String>[], final  List<int> port = const <int>[], final  List<String> portRange = const <String>[], final  List<String> network = const <String>[], this.invert = false, required this.target}): _domain = domain,_domainSuffix = domainSuffix,_domainKeyword = domainKeyword,_domainRegex = domainRegex,_ipCidr = ipCidr,_sourceIpCidr = sourceIpCidr,_ruleSet = ruleSet,_processName = processName,_processPath = processPath,_port = port,_portRange = portRange,_network = network;
  factory _RuleDef.fromJson(Map<String, dynamic> json) => _$RuleDefFromJson(json);

 final  List<String> _domain;
@override@JsonKey() List<String> get domain {
  if (_domain is EqualUnmodifiableListView) return _domain;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_domain);
}

 final  List<String> _domainSuffix;
@override@JsonKey() List<String> get domainSuffix {
  if (_domainSuffix is EqualUnmodifiableListView) return _domainSuffix;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_domainSuffix);
}

 final  List<String> _domainKeyword;
@override@JsonKey() List<String> get domainKeyword {
  if (_domainKeyword is EqualUnmodifiableListView) return _domainKeyword;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_domainKeyword);
}

 final  List<String> _domainRegex;
@override@JsonKey() List<String> get domainRegex {
  if (_domainRegex is EqualUnmodifiableListView) return _domainRegex;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_domainRegex);
}

 final  List<String> _ipCidr;
@override@JsonKey() List<String> get ipCidr {
  if (_ipCidr is EqualUnmodifiableListView) return _ipCidr;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ipCidr);
}

 final  List<String> _sourceIpCidr;
@override@JsonKey() List<String> get sourceIpCidr {
  if (_sourceIpCidr is EqualUnmodifiableListView) return _sourceIpCidr;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sourceIpCidr);
}

 final  List<String> _ruleSet;
@override@JsonKey() List<String> get ruleSet {
  if (_ruleSet is EqualUnmodifiableListView) return _ruleSet;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ruleSet);
}

 final  List<String> _processName;
@override@JsonKey() List<String> get processName {
  if (_processName is EqualUnmodifiableListView) return _processName;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_processName);
}

 final  List<String> _processPath;
@override@JsonKey() List<String> get processPath {
  if (_processPath is EqualUnmodifiableListView) return _processPath;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_processPath);
}

 final  List<int> _port;
@override@JsonKey() List<int> get port {
  if (_port is EqualUnmodifiableListView) return _port;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_port);
}

/// Ranges such as `1000:2000`.
 final  List<String> _portRange;
/// Ranges such as `1000:2000`.
@override@JsonKey() List<String> get portRange {
  if (_portRange is EqualUnmodifiableListView) return _portRange;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_portRange);
}

/// `tcp` or `udp`.
 final  List<String> _network;
/// `tcp` or `udp`.
@override@JsonKey() List<String> get network {
  if (_network is EqualUnmodifiableListView) return _network;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_network);
}

@override@JsonKey() final  bool invert;
/// Node key, group key or a [ContentKeys] built-in.
@override final  String target;

/// Create a copy of RuleDef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RuleDefCopyWith<_RuleDef> get copyWith => __$RuleDefCopyWithImpl<_RuleDef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RuleDefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RuleDef&&const DeepCollectionEquality().equals(other._domain, _domain)&&const DeepCollectionEquality().equals(other._domainSuffix, _domainSuffix)&&const DeepCollectionEquality().equals(other._domainKeyword, _domainKeyword)&&const DeepCollectionEquality().equals(other._domainRegex, _domainRegex)&&const DeepCollectionEquality().equals(other._ipCidr, _ipCidr)&&const DeepCollectionEquality().equals(other._sourceIpCidr, _sourceIpCidr)&&const DeepCollectionEquality().equals(other._ruleSet, _ruleSet)&&const DeepCollectionEquality().equals(other._processName, _processName)&&const DeepCollectionEquality().equals(other._processPath, _processPath)&&const DeepCollectionEquality().equals(other._port, _port)&&const DeepCollectionEquality().equals(other._portRange, _portRange)&&const DeepCollectionEquality().equals(other._network, _network)&&(identical(other.invert, invert) || other.invert == invert)&&(identical(other.target, target) || other.target == target));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_domain),const DeepCollectionEquality().hash(_domainSuffix),const DeepCollectionEquality().hash(_domainKeyword),const DeepCollectionEquality().hash(_domainRegex),const DeepCollectionEquality().hash(_ipCidr),const DeepCollectionEquality().hash(_sourceIpCidr),const DeepCollectionEquality().hash(_ruleSet),const DeepCollectionEquality().hash(_processName),const DeepCollectionEquality().hash(_processPath),const DeepCollectionEquality().hash(_port),const DeepCollectionEquality().hash(_portRange),const DeepCollectionEquality().hash(_network),invert,target);

@override
String toString() {
  return 'RuleDef(domain: $domain, domainSuffix: $domainSuffix, domainKeyword: $domainKeyword, domainRegex: $domainRegex, ipCidr: $ipCidr, sourceIpCidr: $sourceIpCidr, ruleSet: $ruleSet, processName: $processName, processPath: $processPath, port: $port, portRange: $portRange, network: $network, invert: $invert, target: $target)';
}


}

/// @nodoc
abstract mixin class _$RuleDefCopyWith<$Res> implements $RuleDefCopyWith<$Res> {
  factory _$RuleDefCopyWith(_RuleDef value, $Res Function(_RuleDef) _then) = __$RuleDefCopyWithImpl;
@override @useResult
$Res call({
 List<String> domain, List<String> domainSuffix, List<String> domainKeyword, List<String> domainRegex, List<String> ipCidr, List<String> sourceIpCidr, List<String> ruleSet, List<String> processName, List<String> processPath, List<int> port, List<String> portRange, List<String> network, bool invert, String target
});




}
/// @nodoc
class __$RuleDefCopyWithImpl<$Res>
    implements _$RuleDefCopyWith<$Res> {
  __$RuleDefCopyWithImpl(this._self, this._then);

  final _RuleDef _self;
  final $Res Function(_RuleDef) _then;

/// Create a copy of RuleDef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? domain = null,Object? domainSuffix = null,Object? domainKeyword = null,Object? domainRegex = null,Object? ipCidr = null,Object? sourceIpCidr = null,Object? ruleSet = null,Object? processName = null,Object? processPath = null,Object? port = null,Object? portRange = null,Object? network = null,Object? invert = null,Object? target = null,}) {
  return _then(_RuleDef(
domain: null == domain ? _self._domain : domain // ignore: cast_nullable_to_non_nullable
as List<String>,domainSuffix: null == domainSuffix ? _self._domainSuffix : domainSuffix // ignore: cast_nullable_to_non_nullable
as List<String>,domainKeyword: null == domainKeyword ? _self._domainKeyword : domainKeyword // ignore: cast_nullable_to_non_nullable
as List<String>,domainRegex: null == domainRegex ? _self._domainRegex : domainRegex // ignore: cast_nullable_to_non_nullable
as List<String>,ipCidr: null == ipCidr ? _self._ipCidr : ipCidr // ignore: cast_nullable_to_non_nullable
as List<String>,sourceIpCidr: null == sourceIpCidr ? _self._sourceIpCidr : sourceIpCidr // ignore: cast_nullable_to_non_nullable
as List<String>,ruleSet: null == ruleSet ? _self._ruleSet : ruleSet // ignore: cast_nullable_to_non_nullable
as List<String>,processName: null == processName ? _self._processName : processName // ignore: cast_nullable_to_non_nullable
as List<String>,processPath: null == processPath ? _self._processPath : processPath // ignore: cast_nullable_to_non_nullable
as List<String>,port: null == port ? _self._port : port // ignore: cast_nullable_to_non_nullable
as List<int>,portRange: null == portRange ? _self._portRange : portRange // ignore: cast_nullable_to_non_nullable
as List<String>,network: null == network ? _self._network : network // ignore: cast_nullable_to_non_nullable
as List<String>,invert: null == invert ? _self.invert : invert // ignore: cast_nullable_to_non_nullable
as bool,target: null == target ? _self.target : target // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$RuleSetRef {

 String get tag; String get url; RuleSetFormat get format;
/// Create a copy of RuleSetRef
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RuleSetRefCopyWith<RuleSetRef> get copyWith => _$RuleSetRefCopyWithImpl<RuleSetRef>(this as RuleSetRef, _$identity);

  /// Serializes this RuleSetRef to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RuleSetRef&&(identical(other.tag, tag) || other.tag == tag)&&(identical(other.url, url) || other.url == url)&&(identical(other.format, format) || other.format == format));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tag,url,format);

@override
String toString() {
  return 'RuleSetRef(tag: $tag, url: $url, format: $format)';
}


}

/// @nodoc
abstract mixin class $RuleSetRefCopyWith<$Res>  {
  factory $RuleSetRefCopyWith(RuleSetRef value, $Res Function(RuleSetRef) _then) = _$RuleSetRefCopyWithImpl;
@useResult
$Res call({
 String tag, String url, RuleSetFormat format
});




}
/// @nodoc
class _$RuleSetRefCopyWithImpl<$Res>
    implements $RuleSetRefCopyWith<$Res> {
  _$RuleSetRefCopyWithImpl(this._self, this._then);

  final RuleSetRef _self;
  final $Res Function(RuleSetRef) _then;

/// Create a copy of RuleSetRef
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tag = null,Object? url = null,Object? format = null,}) {
  return _then(_self.copyWith(
tag: null == tag ? _self.tag : tag // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,format: null == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as RuleSetFormat,
  ));
}

}


/// Adds pattern-matching-related methods to [RuleSetRef].
extension RuleSetRefPatterns on RuleSetRef {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RuleSetRef value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RuleSetRef() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RuleSetRef value)  $default,){
final _that = this;
switch (_that) {
case _RuleSetRef():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RuleSetRef value)?  $default,){
final _that = this;
switch (_that) {
case _RuleSetRef() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String tag,  String url,  RuleSetFormat format)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RuleSetRef() when $default != null:
return $default(_that.tag,_that.url,_that.format);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String tag,  String url,  RuleSetFormat format)  $default,) {final _that = this;
switch (_that) {
case _RuleSetRef():
return $default(_that.tag,_that.url,_that.format);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String tag,  String url,  RuleSetFormat format)?  $default,) {final _that = this;
switch (_that) {
case _RuleSetRef() when $default != null:
return $default(_that.tag,_that.url,_that.format);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RuleSetRef implements RuleSetRef {
  const _RuleSetRef({required this.tag, required this.url, required this.format});
  factory _RuleSetRef.fromJson(Map<String, dynamic> json) => _$RuleSetRefFromJson(json);

@override final  String tag;
@override final  String url;
@override final  RuleSetFormat format;

/// Create a copy of RuleSetRef
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RuleSetRefCopyWith<_RuleSetRef> get copyWith => __$RuleSetRefCopyWithImpl<_RuleSetRef>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RuleSetRefToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RuleSetRef&&(identical(other.tag, tag) || other.tag == tag)&&(identical(other.url, url) || other.url == url)&&(identical(other.format, format) || other.format == format));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,tag,url,format);

@override
String toString() {
  return 'RuleSetRef(tag: $tag, url: $url, format: $format)';
}


}

/// @nodoc
abstract mixin class _$RuleSetRefCopyWith<$Res> implements $RuleSetRefCopyWith<$Res> {
  factory _$RuleSetRefCopyWith(_RuleSetRef value, $Res Function(_RuleSetRef) _then) = __$RuleSetRefCopyWithImpl;
@override @useResult
$Res call({
 String tag, String url, RuleSetFormat format
});




}
/// @nodoc
class __$RuleSetRefCopyWithImpl<$Res>
    implements _$RuleSetRefCopyWith<$Res> {
  __$RuleSetRefCopyWithImpl(this._self, this._then);

  final _RuleSetRef _self;
  final $Res Function(_RuleSetRef) _then;

/// Create a copy of RuleSetRef
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tag = null,Object? url = null,Object? format = null,}) {
  return _then(_RuleSetRef(
tag: null == tag ? _self.tag : tag // ignore: cast_nullable_to_non_nullable
as String,url: null == url ? _self.url : url // ignore: cast_nullable_to_non_nullable
as String,format: null == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as RuleSetFormat,
  ));
}


}


/// @nodoc
mixin _$ImportWarning {

 WarningKind get kind; String get subject; int get count;
/// Create a copy of ImportWarning
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ImportWarningCopyWith<ImportWarning> get copyWith => _$ImportWarningCopyWithImpl<ImportWarning>(this as ImportWarning, _$identity);

  /// Serializes this ImportWarning to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ImportWarning&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,subject,count);

@override
String toString() {
  return 'ImportWarning(kind: $kind, subject: $subject, count: $count)';
}


}

/// @nodoc
abstract mixin class $ImportWarningCopyWith<$Res>  {
  factory $ImportWarningCopyWith(ImportWarning value, $Res Function(ImportWarning) _then) = _$ImportWarningCopyWithImpl;
@useResult
$Res call({
 WarningKind kind, String subject, int count
});




}
/// @nodoc
class _$ImportWarningCopyWithImpl<$Res>
    implements $ImportWarningCopyWith<$Res> {
  _$ImportWarningCopyWithImpl(this._self, this._then);

  final ImportWarning _self;
  final $Res Function(ImportWarning) _then;

/// Create a copy of ImportWarning
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? subject = null,Object? count = null,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as WarningKind,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [ImportWarning].
extension ImportWarningPatterns on ImportWarning {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ImportWarning value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ImportWarning() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ImportWarning value)  $default,){
final _that = this;
switch (_that) {
case _ImportWarning():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ImportWarning value)?  $default,){
final _that = this;
switch (_that) {
case _ImportWarning() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( WarningKind kind,  String subject,  int count)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ImportWarning() when $default != null:
return $default(_that.kind,_that.subject,_that.count);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( WarningKind kind,  String subject,  int count)  $default,) {final _that = this;
switch (_that) {
case _ImportWarning():
return $default(_that.kind,_that.subject,_that.count);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( WarningKind kind,  String subject,  int count)?  $default,) {final _that = this;
switch (_that) {
case _ImportWarning() when $default != null:
return $default(_that.kind,_that.subject,_that.count);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ImportWarning implements ImportWarning {
  const _ImportWarning({required this.kind, this.subject = '', this.count = 1});
  factory _ImportWarning.fromJson(Map<String, dynamic> json) => _$ImportWarningFromJson(json);

@override final  WarningKind kind;
@override@JsonKey() final  String subject;
@override@JsonKey() final  int count;

/// Create a copy of ImportWarning
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ImportWarningCopyWith<_ImportWarning> get copyWith => __$ImportWarningCopyWithImpl<_ImportWarning>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ImportWarningToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ImportWarning&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.count, count) || other.count == count));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,subject,count);

@override
String toString() {
  return 'ImportWarning(kind: $kind, subject: $subject, count: $count)';
}


}

/// @nodoc
abstract mixin class _$ImportWarningCopyWith<$Res> implements $ImportWarningCopyWith<$Res> {
  factory _$ImportWarningCopyWith(_ImportWarning value, $Res Function(_ImportWarning) _then) = __$ImportWarningCopyWithImpl;
@override @useResult
$Res call({
 WarningKind kind, String subject, int count
});




}
/// @nodoc
class __$ImportWarningCopyWithImpl<$Res>
    implements _$ImportWarningCopyWith<$Res> {
  __$ImportWarningCopyWithImpl(this._self, this._then);

  final _ImportWarning _self;
  final $Res Function(_ImportWarning) _then;

/// Create a copy of ImportWarning
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? subject = null,Object? count = null,}) {
  return _then(_ImportWarning(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as WarningKind,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$ConfigContent {

 List<NodeDef> get nodes; List<GroupDef> get groups; List<RuleDef> get rules; List<RuleSetRef> get ruleSets;/// Where unmatched traffic goes: a node key, group key or built-in.
 String get finalTarget;/// Route with the default template instead of [rules] (link lists,
/// CONFIG_PIPELINE §4). Imported configurations without rules route
/// everything to [finalTarget].
 bool get defaultRules; List<ImportWarning> get warnings;
/// Create a copy of ConfigContent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ConfigContentCopyWith<ConfigContent> get copyWith => _$ConfigContentCopyWithImpl<ConfigContent>(this as ConfigContent, _$identity);

  /// Serializes this ConfigContent to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ConfigContent&&const DeepCollectionEquality().equals(other.nodes, nodes)&&const DeepCollectionEquality().equals(other.groups, groups)&&const DeepCollectionEquality().equals(other.rules, rules)&&const DeepCollectionEquality().equals(other.ruleSets, ruleSets)&&(identical(other.finalTarget, finalTarget) || other.finalTarget == finalTarget)&&(identical(other.defaultRules, defaultRules) || other.defaultRules == defaultRules)&&const DeepCollectionEquality().equals(other.warnings, warnings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(nodes),const DeepCollectionEquality().hash(groups),const DeepCollectionEquality().hash(rules),const DeepCollectionEquality().hash(ruleSets),finalTarget,defaultRules,const DeepCollectionEquality().hash(warnings));

@override
String toString() {
  return 'ConfigContent(nodes: $nodes, groups: $groups, rules: $rules, ruleSets: $ruleSets, finalTarget: $finalTarget, defaultRules: $defaultRules, warnings: $warnings)';
}


}

/// @nodoc
abstract mixin class $ConfigContentCopyWith<$Res>  {
  factory $ConfigContentCopyWith(ConfigContent value, $Res Function(ConfigContent) _then) = _$ConfigContentCopyWithImpl;
@useResult
$Res call({
 List<NodeDef> nodes, List<GroupDef> groups, List<RuleDef> rules, List<RuleSetRef> ruleSets, String finalTarget, bool defaultRules, List<ImportWarning> warnings
});




}
/// @nodoc
class _$ConfigContentCopyWithImpl<$Res>
    implements $ConfigContentCopyWith<$Res> {
  _$ConfigContentCopyWithImpl(this._self, this._then);

  final ConfigContent _self;
  final $Res Function(ConfigContent) _then;

/// Create a copy of ConfigContent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? nodes = null,Object? groups = null,Object? rules = null,Object? ruleSets = null,Object? finalTarget = null,Object? defaultRules = null,Object? warnings = null,}) {
  return _then(_self.copyWith(
nodes: null == nodes ? _self.nodes : nodes // ignore: cast_nullable_to_non_nullable
as List<NodeDef>,groups: null == groups ? _self.groups : groups // ignore: cast_nullable_to_non_nullable
as List<GroupDef>,rules: null == rules ? _self.rules : rules // ignore: cast_nullable_to_non_nullable
as List<RuleDef>,ruleSets: null == ruleSets ? _self.ruleSets : ruleSets // ignore: cast_nullable_to_non_nullable
as List<RuleSetRef>,finalTarget: null == finalTarget ? _self.finalTarget : finalTarget // ignore: cast_nullable_to_non_nullable
as String,defaultRules: null == defaultRules ? _self.defaultRules : defaultRules // ignore: cast_nullable_to_non_nullable
as bool,warnings: null == warnings ? _self.warnings : warnings // ignore: cast_nullable_to_non_nullable
as List<ImportWarning>,
  ));
}

}


/// Adds pattern-matching-related methods to [ConfigContent].
extension ConfigContentPatterns on ConfigContent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ConfigContent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ConfigContent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ConfigContent value)  $default,){
final _that = this;
switch (_that) {
case _ConfigContent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ConfigContent value)?  $default,){
final _that = this;
switch (_that) {
case _ConfigContent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<NodeDef> nodes,  List<GroupDef> groups,  List<RuleDef> rules,  List<RuleSetRef> ruleSets,  String finalTarget,  bool defaultRules,  List<ImportWarning> warnings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ConfigContent() when $default != null:
return $default(_that.nodes,_that.groups,_that.rules,_that.ruleSets,_that.finalTarget,_that.defaultRules,_that.warnings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<NodeDef> nodes,  List<GroupDef> groups,  List<RuleDef> rules,  List<RuleSetRef> ruleSets,  String finalTarget,  bool defaultRules,  List<ImportWarning> warnings)  $default,) {final _that = this;
switch (_that) {
case _ConfigContent():
return $default(_that.nodes,_that.groups,_that.rules,_that.ruleSets,_that.finalTarget,_that.defaultRules,_that.warnings);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<NodeDef> nodes,  List<GroupDef> groups,  List<RuleDef> rules,  List<RuleSetRef> ruleSets,  String finalTarget,  bool defaultRules,  List<ImportWarning> warnings)?  $default,) {final _that = this;
switch (_that) {
case _ConfigContent() when $default != null:
return $default(_that.nodes,_that.groups,_that.rules,_that.ruleSets,_that.finalTarget,_that.defaultRules,_that.warnings);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ConfigContent extends ConfigContent {
  const _ConfigContent({final  List<NodeDef> nodes = const <NodeDef>[], final  List<GroupDef> groups = const <GroupDef>[], final  List<RuleDef> rules = const <RuleDef>[], final  List<RuleSetRef> ruleSets = const <RuleSetRef>[], required this.finalTarget, this.defaultRules = false, final  List<ImportWarning> warnings = const <ImportWarning>[]}): _nodes = nodes,_groups = groups,_rules = rules,_ruleSets = ruleSets,_warnings = warnings,super._();
  factory _ConfigContent.fromJson(Map<String, dynamic> json) => _$ConfigContentFromJson(json);

 final  List<NodeDef> _nodes;
@override@JsonKey() List<NodeDef> get nodes {
  if (_nodes is EqualUnmodifiableListView) return _nodes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_nodes);
}

 final  List<GroupDef> _groups;
@override@JsonKey() List<GroupDef> get groups {
  if (_groups is EqualUnmodifiableListView) return _groups;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_groups);
}

 final  List<RuleDef> _rules;
@override@JsonKey() List<RuleDef> get rules {
  if (_rules is EqualUnmodifiableListView) return _rules;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rules);
}

 final  List<RuleSetRef> _ruleSets;
@override@JsonKey() List<RuleSetRef> get ruleSets {
  if (_ruleSets is EqualUnmodifiableListView) return _ruleSets;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ruleSets);
}

/// Where unmatched traffic goes: a node key, group key or built-in.
@override final  String finalTarget;
/// Route with the default template instead of [rules] (link lists,
/// CONFIG_PIPELINE §4). Imported configurations without rules route
/// everything to [finalTarget].
@override@JsonKey() final  bool defaultRules;
 final  List<ImportWarning> _warnings;
@override@JsonKey() List<ImportWarning> get warnings {
  if (_warnings is EqualUnmodifiableListView) return _warnings;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_warnings);
}


/// Create a copy of ConfigContent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ConfigContentCopyWith<_ConfigContent> get copyWith => __$ConfigContentCopyWithImpl<_ConfigContent>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ConfigContentToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ConfigContent&&const DeepCollectionEquality().equals(other._nodes, _nodes)&&const DeepCollectionEquality().equals(other._groups, _groups)&&const DeepCollectionEquality().equals(other._rules, _rules)&&const DeepCollectionEquality().equals(other._ruleSets, _ruleSets)&&(identical(other.finalTarget, finalTarget) || other.finalTarget == finalTarget)&&(identical(other.defaultRules, defaultRules) || other.defaultRules == defaultRules)&&const DeepCollectionEquality().equals(other._warnings, _warnings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_nodes),const DeepCollectionEquality().hash(_groups),const DeepCollectionEquality().hash(_rules),const DeepCollectionEquality().hash(_ruleSets),finalTarget,defaultRules,const DeepCollectionEquality().hash(_warnings));

@override
String toString() {
  return 'ConfigContent(nodes: $nodes, groups: $groups, rules: $rules, ruleSets: $ruleSets, finalTarget: $finalTarget, defaultRules: $defaultRules, warnings: $warnings)';
}


}

/// @nodoc
abstract mixin class _$ConfigContentCopyWith<$Res> implements $ConfigContentCopyWith<$Res> {
  factory _$ConfigContentCopyWith(_ConfigContent value, $Res Function(_ConfigContent) _then) = __$ConfigContentCopyWithImpl;
@override @useResult
$Res call({
 List<NodeDef> nodes, List<GroupDef> groups, List<RuleDef> rules, List<RuleSetRef> ruleSets, String finalTarget, bool defaultRules, List<ImportWarning> warnings
});




}
/// @nodoc
class __$ConfigContentCopyWithImpl<$Res>
    implements _$ConfigContentCopyWith<$Res> {
  __$ConfigContentCopyWithImpl(this._self, this._then);

  final _ConfigContent _self;
  final $Res Function(_ConfigContent) _then;

/// Create a copy of ConfigContent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? nodes = null,Object? groups = null,Object? rules = null,Object? ruleSets = null,Object? finalTarget = null,Object? defaultRules = null,Object? warnings = null,}) {
  return _then(_ConfigContent(
nodes: null == nodes ? _self._nodes : nodes // ignore: cast_nullable_to_non_nullable
as List<NodeDef>,groups: null == groups ? _self._groups : groups // ignore: cast_nullable_to_non_nullable
as List<GroupDef>,rules: null == rules ? _self._rules : rules // ignore: cast_nullable_to_non_nullable
as List<RuleDef>,ruleSets: null == ruleSets ? _self._ruleSets : ruleSets // ignore: cast_nullable_to_non_nullable
as List<RuleSetRef>,finalTarget: null == finalTarget ? _self.finalTarget : finalTarget // ignore: cast_nullable_to_non_nullable
as String,defaultRules: null == defaultRules ? _self.defaultRules : defaultRules // ignore: cast_nullable_to_non_nullable
as bool,warnings: null == warnings ? _self._warnings : warnings // ignore: cast_nullable_to_non_nullable
as List<ImportWarning>,
  ));
}


}

// dart format on
