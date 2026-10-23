// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GroupTest _$GroupTestFromJson(Map<String, dynamic> json) => _GroupTest(
  url: json['url'] as String,
  intervalSeconds: (json['intervalSeconds'] as num?)?.toInt() ?? 180,
  toleranceMs: (json['toleranceMs'] as num?)?.toInt() ?? 50,
);

Map<String, dynamic> _$GroupTestToJson(_GroupTest instance) =>
    <String, dynamic>{
      'url': instance.url,
      'intervalSeconds': instance.intervalSeconds,
      'toleranceMs': instance.toleranceMs,
    };

_GroupDef _$GroupDefFromJson(Map<String, dynamic> json) => _GroupDef(
  key: json['key'] as String,
  name: json['name'] as String,
  type: $enumDecode(_$GroupTypeEnumMap, json['type']),
  displayType: json['displayType'] as String,
  members:
      (json['members'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  test: json['test'] == null
      ? null
      : GroupTest.fromJson(json['test'] as Map<String, dynamic>),
);

Map<String, dynamic> _$GroupDefToJson(_GroupDef instance) => <String, dynamic>{
  'key': instance.key,
  'name': instance.name,
  'type': _$GroupTypeEnumMap[instance.type]!,
  'displayType': instance.displayType,
  'members': instance.members,
  'test': ?instance.test?.toJson(),
};

const _$GroupTypeEnumMap = {
  GroupType.selector: 'selector',
  GroupType.urltest: 'urltest',
};

_RuleDef _$RuleDefFromJson(Map<String, dynamic> json) => _RuleDef(
  domain:
      (json['domain'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  domainSuffix:
      (json['domainSuffix'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  domainKeyword:
      (json['domainKeyword'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  domainRegex:
      (json['domainRegex'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  ipCidr:
      (json['ipCidr'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  sourceIpCidr:
      (json['sourceIpCidr'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  ruleSet:
      (json['ruleSet'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  processName:
      (json['processName'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  processPath:
      (json['processPath'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  port:
      (json['port'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const <int>[],
  portRange:
      (json['portRange'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  network:
      (json['network'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  invert: json['invert'] as bool? ?? false,
  target: json['target'] as String,
);

Map<String, dynamic> _$RuleDefToJson(_RuleDef instance) => <String, dynamic>{
  'domain': instance.domain,
  'domainSuffix': instance.domainSuffix,
  'domainKeyword': instance.domainKeyword,
  'domainRegex': instance.domainRegex,
  'ipCidr': instance.ipCidr,
  'sourceIpCidr': instance.sourceIpCidr,
  'ruleSet': instance.ruleSet,
  'processName': instance.processName,
  'processPath': instance.processPath,
  'port': instance.port,
  'portRange': instance.portRange,
  'network': instance.network,
  'invert': instance.invert,
  'target': instance.target,
};

_RuleSetRef _$RuleSetRefFromJson(Map<String, dynamic> json) => _RuleSetRef(
  tag: json['tag'] as String,
  url: json['url'] as String,
  format: $enumDecode(_$RuleSetFormatEnumMap, json['format']),
);

Map<String, dynamic> _$RuleSetRefToJson(_RuleSetRef instance) =>
    <String, dynamic>{
      'tag': instance.tag,
      'url': instance.url,
      'format': _$RuleSetFormatEnumMap[instance.format]!,
    };

const _$RuleSetFormatEnumMap = {
  RuleSetFormat.binary: 'binary',
  RuleSetFormat.source: 'source',
  RuleSetFormat.clashDomainYaml: 'clashDomainYaml',
  RuleSetFormat.clashDomainText: 'clashDomainText',
  RuleSetFormat.clashIpcidrYaml: 'clashIpcidrYaml',
  RuleSetFormat.clashIpcidrText: 'clashIpcidrText',
  RuleSetFormat.clashClassicalYaml: 'clashClassicalYaml',
  RuleSetFormat.clashClassicalText: 'clashClassicalText',
};

_ImportWarning _$ImportWarningFromJson(Map<String, dynamic> json) =>
    _ImportWarning(
      kind: $enumDecode(_$WarningKindEnumMap, json['kind']),
      subject: json['subject'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 1,
    );

Map<String, dynamic> _$ImportWarningToJson(_ImportWarning instance) =>
    <String, dynamic>{
      'kind': _$WarningKindEnumMap[instance.kind]!,
      'subject': instance.subject,
      'count': instance.count,
    };

const _$WarningKindEnumMap = {
  WarningKind.unsupportedNodeType: 'unsupportedNodeType',
  WarningKind.unsupportedNodeOption: 'unsupportedNodeOption',
  WarningKind.ignoredNodeOption: 'ignoredNodeOption',
  WarningKind.unreadableEntry: 'unreadableEntry',
  WarningKind.unsupportedRuleSet: 'unsupportedRuleSet',
  WarningKind.unsupportedGroupType: 'unsupportedGroupType',
  WarningKind.approximatedGroupType: 'approximatedGroupType',
  WarningKind.unsupportedRule: 'unsupportedRule',
  WarningKind.ignoredSection: 'ignoredSection',
  WarningKind.insecureTls: 'insecureTls',
  WarningKind.missingFinal: 'missingFinal',
  WarningKind.droppedMember: 'droppedMember',
};

_ConfigContent _$ConfigContentFromJson(Map<String, dynamic> json) =>
    _ConfigContent(
      nodes:
          (json['nodes'] as List<dynamic>?)
              ?.map((e) => NodeDef.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <NodeDef>[],
      groups:
          (json['groups'] as List<dynamic>?)
              ?.map((e) => GroupDef.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <GroupDef>[],
      rules:
          (json['rules'] as List<dynamic>?)
              ?.map((e) => RuleDef.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <RuleDef>[],
      ruleSets:
          (json['ruleSets'] as List<dynamic>?)
              ?.map((e) => RuleSetRef.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <RuleSetRef>[],
      finalTarget: json['finalTarget'] as String,
      defaultRules: json['defaultRules'] as bool? ?? false,
      warnings:
          (json['warnings'] as List<dynamic>?)
              ?.map((e) => ImportWarning.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ImportWarning>[],
    );

Map<String, dynamic> _$ConfigContentToJson(_ConfigContent instance) =>
    <String, dynamic>{
      'nodes': instance.nodes.map((e) => e.toJson()).toList(),
      'groups': instance.groups.map((e) => e.toJson()).toList(),
      'rules': instance.rules.map((e) => e.toJson()).toList(),
      'ruleSets': instance.ruleSets.map((e) => e.toJson()).toList(),
      'finalTarget': instance.finalTarget,
      'defaultRules': instance.defaultRules,
      'warnings': instance.warnings.map((e) => e.toJson()).toList(),
    };
