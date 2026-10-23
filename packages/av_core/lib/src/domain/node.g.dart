// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'node.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TcpTransport _$TcpTransportFromJson(Map<String, dynamic> json) =>
    TcpTransport($type: json['type'] as String?);

Map<String, dynamic> _$TcpTransportToJson(TcpTransport instance) =>
    <String, dynamic>{'type': instance.$type};

WsTransport _$WsTransportFromJson(Map<String, dynamic> json) => WsTransport(
  path: json['path'] as String? ?? '/',
  host: json['host'] as String?,
  maxEarlyData: (json['maxEarlyData'] as num?)?.toInt() ?? 0,
  earlyDataHeader: json['earlyDataHeader'] as String?,
  $type: json['type'] as String?,
);

Map<String, dynamic> _$WsTransportToJson(WsTransport instance) =>
    <String, dynamic>{
      'path': instance.path,
      'host': ?instance.host,
      'maxEarlyData': instance.maxEarlyData,
      'earlyDataHeader': ?instance.earlyDataHeader,
      'type': instance.$type,
    };

GrpcTransport _$GrpcTransportFromJson(Map<String, dynamic> json) =>
    GrpcTransport(
      serviceName: json['serviceName'] as String? ?? '',
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$GrpcTransportToJson(GrpcTransport instance) =>
    <String, dynamic>{
      'serviceName': instance.serviceName,
      'type': instance.$type,
    };

Http2Transport _$Http2TransportFromJson(Map<String, dynamic> json) =>
    Http2Transport(
      path: json['path'] as String? ?? '/',
      host:
          (json['host'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const <String>[],
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$Http2TransportToJson(Http2Transport instance) =>
    <String, dynamic>{
      'path': instance.path,
      'host': instance.host,
      'type': instance.$type,
    };

_Reality _$RealityFromJson(Map<String, dynamic> json) => _Reality(
  publicKey: json['publicKey'] as String,
  shortId: json['shortId'] as String?,
);

Map<String, dynamic> _$RealityToJson(_Reality instance) => <String, dynamic>{
  'publicKey': instance.publicKey,
  'shortId': ?instance.shortId,
};

_Tls _$TlsFromJson(Map<String, dynamic> json) => _Tls(
  serverName: json['serverName'] as String?,
  insecure: json['insecure'] as bool? ?? false,
  alpn:
      (json['alpn'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  fingerprint: json['fingerprint'] as String?,
  reality: json['reality'] == null
      ? null
      : Reality.fromJson(json['reality'] as Map<String, dynamic>),
);

Map<String, dynamic> _$TlsToJson(_Tls instance) => <String, dynamic>{
  'serverName': ?instance.serverName,
  'insecure': instance.insecure,
  'alpn': instance.alpn,
  'fingerprint': ?instance.fingerprint,
  'reality': ?instance.reality?.toJson(),
};

Hysteria2Params _$Hysteria2ParamsFromJson(Map<String, dynamic> json) =>
    Hysteria2Params(
      password: Secret.fromJson(json['password'] as Map<String, dynamic>),
      obfsPassword: json['obfsPassword'] == null
          ? null
          : Secret.fromJson(json['obfsPassword'] as Map<String, dynamic>),
      upMbps: (json['upMbps'] as num?)?.toInt(),
      downMbps: (json['downMbps'] as num?)?.toInt(),
      serverPorts:
          (json['serverPorts'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      tls: json['tls'] == null
          ? const Tls()
          : Tls.fromJson(json['tls'] as Map<String, dynamic>),
      $type: json['protocol'] as String?,
    );

Map<String, dynamic> _$Hysteria2ParamsToJson(Hysteria2Params instance) =>
    <String, dynamic>{
      'password': instance.password.toJson(),
      'obfsPassword': ?instance.obfsPassword?.toJson(),
      'upMbps': ?instance.upMbps,
      'downMbps': ?instance.downMbps,
      'serverPorts': instance.serverPorts,
      'tls': instance.tls.toJson(),
      'protocol': instance.$type,
    };

TuicParams _$TuicParamsFromJson(Map<String, dynamic> json) => TuicParams(
  uuid: Secret.fromJson(json['uuid'] as Map<String, dynamic>),
  password: Secret.fromJson(json['password'] as Map<String, dynamic>),
  congestionControl: json['congestionControl'] as String? ?? 'bbr',
  udpRelayMode: json['udpRelayMode'] as String?,
  tls: json['tls'] == null
      ? const Tls()
      : Tls.fromJson(json['tls'] as Map<String, dynamic>),
  $type: json['protocol'] as String?,
);

Map<String, dynamic> _$TuicParamsToJson(TuicParams instance) =>
    <String, dynamic>{
      'uuid': instance.uuid.toJson(),
      'password': instance.password.toJson(),
      'congestionControl': instance.congestionControl,
      'udpRelayMode': ?instance.udpRelayMode,
      'tls': instance.tls.toJson(),
      'protocol': instance.$type,
    };

VlessParams _$VlessParamsFromJson(Map<String, dynamic> json) => VlessParams(
  uuid: Secret.fromJson(json['uuid'] as Map<String, dynamic>),
  flow: json['flow'] as String?,
  transport: json['transport'] == null
      ? const Transport.tcp()
      : Transport.fromJson(json['transport'] as Map<String, dynamic>),
  tls: json['tls'] == null
      ? null
      : Tls.fromJson(json['tls'] as Map<String, dynamic>),
  $type: json['protocol'] as String?,
);

Map<String, dynamic> _$VlessParamsToJson(VlessParams instance) =>
    <String, dynamic>{
      'uuid': instance.uuid.toJson(),
      'flow': ?instance.flow,
      'transport': instance.transport.toJson(),
      'tls': ?instance.tls?.toJson(),
      'protocol': instance.$type,
    };

VmessParams _$VmessParamsFromJson(Map<String, dynamic> json) => VmessParams(
  uuid: Secret.fromJson(json['uuid'] as Map<String, dynamic>),
  alterId: (json['alterId'] as num?)?.toInt() ?? 0,
  cipher: json['cipher'] as String? ?? 'auto',
  transport: json['transport'] == null
      ? const Transport.tcp()
      : Transport.fromJson(json['transport'] as Map<String, dynamic>),
  tls: json['tls'] == null
      ? null
      : Tls.fromJson(json['tls'] as Map<String, dynamic>),
  $type: json['protocol'] as String?,
);

Map<String, dynamic> _$VmessParamsToJson(VmessParams instance) =>
    <String, dynamic>{
      'uuid': instance.uuid.toJson(),
      'alterId': instance.alterId,
      'cipher': instance.cipher,
      'transport': instance.transport.toJson(),
      'tls': ?instance.tls?.toJson(),
      'protocol': instance.$type,
    };

TrojanParams _$TrojanParamsFromJson(Map<String, dynamic> json) => TrojanParams(
  password: Secret.fromJson(json['password'] as Map<String, dynamic>),
  transport: json['transport'] == null
      ? const Transport.tcp()
      : Transport.fromJson(json['transport'] as Map<String, dynamic>),
  tls: json['tls'] == null
      ? const Tls()
      : Tls.fromJson(json['tls'] as Map<String, dynamic>),
  $type: json['protocol'] as String?,
);

Map<String, dynamic> _$TrojanParamsToJson(TrojanParams instance) =>
    <String, dynamic>{
      'password': instance.password.toJson(),
      'transport': instance.transport.toJson(),
      'tls': instance.tls.toJson(),
      'protocol': instance.$type,
    };

ShadowsocksParams _$ShadowsocksParamsFromJson(Map<String, dynamic> json) =>
    ShadowsocksParams(
      method: json['method'] as String,
      password: Secret.fromJson(json['password'] as Map<String, dynamic>),
      plugin: json['plugin'] as String?,
      pluginOpts: json['pluginOpts'] as String?,
      $type: json['protocol'] as String?,
    );

Map<String, dynamic> _$ShadowsocksParamsToJson(ShadowsocksParams instance) =>
    <String, dynamic>{
      'method': instance.method,
      'password': instance.password.toJson(),
      'plugin': ?instance.plugin,
      'pluginOpts': ?instance.pluginOpts,
      'protocol': instance.$type,
    };

Socks5Params _$Socks5ParamsFromJson(Map<String, dynamic> json) => Socks5Params(
  username: json['username'] as String?,
  password: json['password'] == null
      ? null
      : Secret.fromJson(json['password'] as Map<String, dynamic>),
  tls: json['tls'] == null
      ? null
      : Tls.fromJson(json['tls'] as Map<String, dynamic>),
  $type: json['protocol'] as String?,
);

Map<String, dynamic> _$Socks5ParamsToJson(Socks5Params instance) =>
    <String, dynamic>{
      'username': ?instance.username,
      'password': ?instance.password?.toJson(),
      'tls': ?instance.tls?.toJson(),
      'protocol': instance.$type,
    };

AnyTlsParams _$AnyTlsParamsFromJson(Map<String, dynamic> json) => AnyTlsParams(
  password: Secret.fromJson(json['password'] as Map<String, dynamic>),
  idleSessionCheckInterval: json['idleSessionCheckInterval'] as String?,
  tls: json['tls'] == null
      ? const Tls()
      : Tls.fromJson(json['tls'] as Map<String, dynamic>),
  $type: json['protocol'] as String?,
);

Map<String, dynamic> _$AnyTlsParamsToJson(AnyTlsParams instance) =>
    <String, dynamic>{
      'password': instance.password.toJson(),
      'idleSessionCheckInterval': ?instance.idleSessionCheckInterval,
      'tls': instance.tls.toJson(),
      'protocol': instance.$type,
    };

HttpParams _$HttpParamsFromJson(Map<String, dynamic> json) => HttpParams(
  username: json['username'] as String?,
  password: json['password'] == null
      ? null
      : Secret.fromJson(json['password'] as Map<String, dynamic>),
  tls: json['tls'] == null
      ? null
      : Tls.fromJson(json['tls'] as Map<String, dynamic>),
  $type: json['protocol'] as String?,
);

Map<String, dynamic> _$HttpParamsToJson(HttpParams instance) =>
    <String, dynamic>{
      'username': ?instance.username,
      'password': ?instance.password?.toJson(),
      'tls': ?instance.tls?.toJson(),
      'protocol': instance.$type,
    };

_NodeDef _$NodeDefFromJson(Map<String, dynamic> json) => _NodeDef(
  key: json['key'] as String,
  name: json['name'] as String,
  server: json['server'] as String,
  port: (json['port'] as num).toInt(),
  params: NodeParams.fromJson(json['params'] as Map<String, dynamic>),
  detourKey: json['detourKey'] as String?,
);

Map<String, dynamic> _$NodeDefToJson(_NodeDef instance) => <String, dynamic>{
  'key': instance.key,
  'name': instance.name,
  'server': instance.server,
  'port': instance.port,
  'params': instance.params.toJson(),
  'detourKey': ?instance.detourKey,
};
