// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'configuration.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Usage _$UsageFromJson(Map<String, dynamic> json) => _Usage(
  upload: (json['upload'] as num?)?.toInt() ?? 0,
  download: (json['download'] as num?)?.toInt() ?? 0,
  total: (json['total'] as num?)?.toInt(),
  expireAt: json['expireAt'] == null
      ? null
      : DateTime.parse(json['expireAt'] as String),
);

Map<String, dynamic> _$UsageToJson(_Usage instance) => <String, dynamic>{
  'upload': instance.upload,
  'download': instance.download,
  'total': ?instance.total,
  'expireAt': ?instance.expireAt?.toIso8601String(),
};

_SubscriptionSource _$SubscriptionSourceFromJson(Map<String, dynamic> json) =>
    _SubscriptionSource(
      url: Secret.fromJson(json['url'] as Map<String, dynamic>),
      headers:
          (json['headers'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, Secret.fromJson(e as Map<String, dynamic>)),
          ) ??
          const <String, Secret>{},
    );

Map<String, dynamic> _$SubscriptionSourceToJson(_SubscriptionSource instance) =>
    <String, dynamic>{
      'url': instance.url.toJson(),
      'headers': instance.headers.map((k, e) => MapEntry(k, e.toJson())),
    };
