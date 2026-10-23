// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_content.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SelfNode _$SelfNodeFromJson(Map<String, dynamic> json) => _SelfNode(
  id: json['id'] as String,
  name: json['name'] as String,
  server: json['server'] as String,
  port: (json['port'] as num).toInt(),
  params: NodeParams.fromJson(json['params'] as Map<String, dynamic>),
);

Map<String, dynamic> _$SelfNodeToJson(_SelfNode instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'server': instance.server,
  'port': instance.port,
  'params': instance.params.toJson(),
};

_Chain _$ChainFromJson(Map<String, dynamic> json) => _Chain(
  id: json['id'] as String,
  name: json['name'] as String?,
  hops: (json['hops'] as List<dynamic>)
      .map((e) => MemberRef.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ChainToJson(_Chain instance) => <String, dynamic>{
  'id': instance.id,
  'name': ?instance.name,
  'hops': instance.hops.map((e) => e.toJson()).toList(),
};

_Membership _$MembershipFromJson(Map<String, dynamic> json) => _Membership(
  ownerKind: $enumDecode(_$MemberOwnerEnumMap, json['ownerKind']),
  ownerId: json['ownerId'] as String,
  configurationId: json['configurationId'] as String,
  groupKey: json['groupKey'] as String,
);

Map<String, dynamic> _$MembershipToJson(_Membership instance) =>
    <String, dynamic>{
      'ownerKind': _$MemberOwnerEnumMap[instance.ownerKind]!,
      'ownerId': instance.ownerId,
      'configurationId': instance.configurationId,
      'groupKey': instance.groupKey,
    };

const _$MemberOwnerEnumMap = {
  MemberOwner.node: 'node',
  MemberOwner.chain: 'chain',
};
