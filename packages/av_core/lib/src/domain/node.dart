import 'package:freezed_annotation/freezed_annotation.dart';

import 'secret.dart';

part 'node.freezed.dart';
part 'node.g.dart';

/// The nine protocols Avalon supports (PRODUCT_SPEC §3.6).
enum Protocol {
  hysteria2('Hysteria2'),
  tuic('TUIC'),
  vless('VLESS'),
  vmess('VMess'),
  trojan('Trojan'),
  shadowsocks('Shadowsocks'),
  socks5('SOCKS5'),
  anytls('AnyTLS'),
  http('HTTP');

  const Protocol(this.label);

  final String label;
}

/// V2Ray transport for VLESS, VMess and Trojan.
@Freezed(unionKey: 'type')
sealed class Transport with _$Transport {
  const factory Transport.tcp() = TcpTransport;

  const factory Transport.ws({
    @Default('/') String path,
    String? host,
    @Default(0) int maxEarlyData,
    String? earlyDataHeader,
  }) = WsTransport;

  const factory Transport.grpc({@Default('') String serviceName}) =
      GrpcTransport;

  const factory Transport.http2({
    @Default('/') String path,
    @Default(<String>[]) List<String> host,
  }) = Http2Transport;

  factory Transport.fromJson(Map<String, dynamic> json) =>
      _$TransportFromJson(json);
}

/// Reality settings of a TLS client.
@freezed
abstract class Reality with _$Reality {
  const factory Reality({required String publicKey, String? shortId}) =
      _Reality;

  factory Reality.fromJson(Map<String, dynamic> json) =>
      _$RealityFromJson(json);
}

/// TLS client settings. `insecure` only comes from imported content; the
/// node form never sets it (CONFIG_PIPELINE §4).
@freezed
abstract class Tls with _$Tls {
  const factory Tls({
    String? serverName,
    @Default(false) bool insecure,
    @Default(<String>[]) List<String> alpn,

    /// uTLS client fingerprint, e.g. `chrome`.
    String? fingerprint,
    Reality? reality,
  }) = _Tls;

  factory Tls.fromJson(Map<String, dynamic> json) => _$TlsFromJson(json);
}

/// Protocol-specific settings. Hysteria2, TUIC, Trojan and AnyTLS always use
/// TLS; for the others `tls == null` means plain.
@Freezed(unionKey: 'protocol')
sealed class NodeParams with _$NodeParams {
  const NodeParams._();

  const factory NodeParams.hysteria2({
    required Secret password,
    Secret? obfsPassword,
    int? upMbps,
    int? downMbps,

    /// Port hopping ranges such as `20000:30000`.
    @Default(<String>[]) List<String> serverPorts,
    @Default(Tls()) Tls tls,
  }) = Hysteria2Params;

  const factory NodeParams.tuic({
    required Secret uuid,
    required Secret password,
    @Default('bbr') String congestionControl,
    String? udpRelayMode,
    @Default(Tls()) Tls tls,
  }) = TuicParams;

  const factory NodeParams.vless({
    required Secret uuid,
    String? flow,
    @Default(Transport.tcp()) Transport transport,
    Tls? tls,
  }) = VlessParams;

  const factory NodeParams.vmess({
    required Secret uuid,
    @Default(0) int alterId,
    @Default('auto') String cipher,
    @Default(Transport.tcp()) Transport transport,
    Tls? tls,
  }) = VmessParams;

  const factory NodeParams.trojan({
    required Secret password,
    @Default(Transport.tcp()) Transport transport,
    @Default(Tls()) Tls tls,
  }) = TrojanParams;

  const factory NodeParams.shadowsocks({
    required String method,
    required Secret password,
    String? plugin,
    String? pluginOpts,
  }) = ShadowsocksParams;

  const factory NodeParams.socks5({
    String? username,
    Secret? password,
    Tls? tls,
  }) = Socks5Params;

  const factory NodeParams.anytls({
    required Secret password,
    String? idleSessionCheckInterval,
    @Default(Tls()) Tls tls,
  }) = AnyTlsParams;

  const factory NodeParams.http({
    String? username,
    Secret? password,
    Tls? tls,
  }) = HttpParams;

  factory NodeParams.fromJson(Map<String, dynamic> json) =>
      _$NodeParamsFromJson(json);

  Protocol get protocol => switch (this) {
    Hysteria2Params() => Protocol.hysteria2,
    TuicParams() => Protocol.tuic,
    VlessParams() => Protocol.vless,
    VmessParams() => Protocol.vmess,
    TrojanParams() => Protocol.trojan,
    ShadowsocksParams() => Protocol.shadowsocks,
    Socks5Params() => Protocol.socks5,
    AnyTlsParams() => Protocol.anytls,
    HttpParams() => Protocol.http,
  };
}

/// A proxy node: from imported content (`key` unique within its
/// configuration, DATA_MODEL §1.3) or built by the user.
@freezed
abstract class NodeDef with _$NodeDef {
  const factory NodeDef({
    required String key,
    required String name,
    required String server,
    required int port,
    required NodeParams params,

    /// Clash `dialer-proxy`: the key of the node or group to dial through.
    String? detourKey,
  }) = _NodeDef;

  factory NodeDef.fromJson(Map<String, dynamic> json) =>
      _$NodeDefFromJson(json);
}
