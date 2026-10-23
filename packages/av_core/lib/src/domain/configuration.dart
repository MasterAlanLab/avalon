import 'package:freezed_annotation/freezed_annotation.dart';

import 'secret.dart';

part 'configuration.freezed.dart';
part 'configuration.g.dart';

enum ConfigurationKind { subscription, file, self }

/// Traffic and expiry from `subscription-userinfo` (CONFIG_PIPELINE §2).
@freezed
abstract class Usage with _$Usage {
  const factory Usage({
    @Default(0) int upload,
    @Default(0) int download,
    int? total,
    DateTime? expireAt,
  }) = _Usage;

  factory Usage.fromJson(Map<String, dynamic> json) => _$UsageFromJson(json);
}

/// Where a subscription comes from. Both URL and headers are secrets
/// (DATA_MODEL §3).
@freezed
abstract class SubscriptionSource with _$SubscriptionSource {
  const factory SubscriptionSource({
    required Secret url,
    @Default(<String, Secret>{}) Map<String, Secret> headers,
  }) = _SubscriptionSource;

  factory SubscriptionSource.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionSourceFromJson(json);
}

/// A configuration card (PRODUCT_SPEC §3.3).
@freezed
abstract class Configuration with _$Configuration {
  const factory Configuration({
    required String id,
    required ConfigurationKind kind,
    required String name,

    /// Subscription host, for display only.
    String? sourceDisplay,
    @Default(true) bool autoUpdate,
    Usage? usage,
    DateTime? lastSuccessAt,
    DateTime? lastAttemptAt,

    /// The last refresh error, already redacted.
    String? lastError,
    required DateTime createdAt,
    required DateTime editedAt,
  }) = _Configuration;
}
