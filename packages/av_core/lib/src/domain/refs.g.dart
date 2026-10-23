// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refs.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SourceMember _$SourceMemberFromJson(Map<String, dynamic> json) => SourceMember(
  configurationId: json['configurationId'] as String,
  key: json['key'] as String,
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$SourceMemberToJson(SourceMember instance) =>
    <String, dynamic>{
      'configurationId': instance.configurationId,
      'key': instance.key,
      'kind': instance.$type,
    };

SelfNodeRef _$SelfNodeRefFromJson(Map<String, dynamic> json) =>
    SelfNodeRef(id: json['id'] as String, $type: json['kind'] as String?);

Map<String, dynamic> _$SelfNodeRefToJson(SelfNodeRef instance) =>
    <String, dynamic>{'id': instance.id, 'kind': instance.$type};

ChainRef _$ChainRefFromJson(Map<String, dynamic> json) =>
    ChainRef(id: json['id'] as String, $type: json['kind'] as String?);

Map<String, dynamic> _$ChainRefToJson(ChainRef instance) => <String, dynamic>{
  'id': instance.id,
  'kind': instance.$type,
};

TailnetExitRef _$TailnetExitRefFromJson(Map<String, dynamic> json) =>
    TailnetExitRef(
      tailnet: json['tailnet'] as String,
      nodeStableId: json['nodeStableId'] as String,
      name: json['name'] as String,
      $type: json['kind'] as String?,
    );

Map<String, dynamic> _$TailnetExitRefToJson(TailnetExitRef instance) =>
    <String, dynamic>{
      'tailnet': instance.tailnet,
      'nodeStableId': instance.nodeStableId,
      'name': instance.name,
      'kind': instance.$type,
    };

BuiltinRef _$BuiltinRefFromJson(Map<String, dynamic> json) => BuiltinRef(
  builtin: $enumDecode(_$BuiltinEnumMap, json['builtin']),
  $type: json['kind'] as String?,
);

Map<String, dynamic> _$BuiltinRefToJson(BuiltinRef instance) =>
    <String, dynamic>{
      'builtin': _$BuiltinEnumMap[instance.builtin]!,
      'kind': instance.$type,
    };

const _$BuiltinEnumMap = {Builtin.direct: 'direct', Builtin.reject: 'reject'};
