/// First-batch Cloud DTOs. Secrets and diagnostic messages are never included
/// in their default string representation.
enum DeviceOs { ios, android, macos, windows, linux }

enum PurchaseSource { apple, google, web }

enum EntitlementPlan { monthly, yearly }

/// Reasons carried only by challenge validation failures. Unknown wire values
/// remain a generic validation error; the server owns the attempt count.
enum EmailChallengeReason {
  wrongCode,
  expired,
  attemptsExceeded,
  consumed,
  missing,
}

final class DeviceInput {
  const DeviceInput({
    required this.installationId,
    required this.name,
    required this.os,
  });

  final String installationId;
  final String name;
  final DeviceOs os;

  Map<String, Object?> toJson() => {
    'installationId': installationId,
    'name': name,
    'os': os.name,
  };
}

final class EmailStartResponse {
  const EmailStartResponse({
    required this.challengeId,
    required this.expiresAt,
  });

  factory EmailStartResponse.fromJson(Map<String, Object?> json) =>
      EmailStartResponse(
        challengeId: _string(json, 'challengeId'),
        expiresAt: _timestamp(json, 'expiresAt'),
      );

  final String challengeId;

  /// Server-provided expiry. This does not restrict resending a challenge.
  final DateTime expiresAt;
}

final class TokenResponse {
  const TokenResponse({
    required this.accessToken,
    required this.accessExpiresAt,
    required this.refreshToken,
    required this.refreshExpiresAt,
    required this.accountId,
    required this.deviceId,
    required this.sessionId,
  });

  factory TokenResponse.fromJson(Map<String, Object?> json) => TokenResponse(
    accessToken: _string(json, 'accessToken'),
    accessExpiresAt: _timestamp(json, 'accessExpiresAt'),
    refreshToken: _string(json, 'refreshToken'),
    refreshExpiresAt: _timestamp(json, 'refreshExpiresAt'),
    accountId: _string(json, 'accountId'),
    deviceId: _string(json, 'deviceId'),
    sessionId: _string(json, 'sessionId'),
  );

  final String accessToken;
  final DateTime accessExpiresAt;
  final String refreshToken;
  final DateTime refreshExpiresAt;
  final String accountId;
  final String deviceId;
  final String sessionId;
}

final class CloudAccount {
  const CloudAccount({
    required this.id,
    required this.email,
    required this.displayName,
  });

  factory CloudAccount.fromJson(Map<String, Object?> json) => CloudAccount(
    id: _string(json, 'id'),
    email: _nullableString(json, 'email'),
    displayName: _nullableString(json, 'displayName'),
  );

  final String id;
  final String? email;
  final String? displayName;
}

final class CloudEntitlement {
  const CloudEntitlement({
    required this.plan,
    required this.source,
    required this.status,
    required this.expiresAt,
  });

  factory CloudEntitlement.fromJson(Map<String, Object?> json) =>
      CloudEntitlement(
        plan: _enum(EntitlementPlan.values, _string(json, 'plan')),
        source: _enum(PurchaseSource.values, _string(json, 'source')),
        status: _string(json, 'status'),
        expiresAt: _timestamp(json, 'expiresAt'),
      );

  final EntitlementPlan plan;
  final PurchaseSource source;

  /// Known states are active/expired/revoked. Preserve future unknown states;
  /// a non-null record does not imply an active entitlement.
  final String status;
  final DateTime expiresAt;

  Map<String, Object?> toJson() => {
    'plan': plan.name,
    'source': source.name,
    'status': status,
    'expiresAt': expiresAt.toUtc().toIso8601String(),
  };
}

final class CloudDevice {
  const CloudDevice({
    required this.id,
    required this.name,
    required this.os,
    required this.syncActive,
    required this.lastSeenAt,
  });

  factory CloudDevice.fromJson(Map<String, Object?> json) => CloudDevice(
    id: _string(json, 'id'),
    name: _string(json, 'name'),
    os: _enum(DeviceOs.values, _string(json, 'os')),
    syncActive: _boolean(json, 'syncActive'),
    lastSeenAt: _timestamp(json, 'lastSeenAt'),
  );

  final String id;
  final String name;
  final DeviceOs os;
  final bool syncActive;
  final DateTime lastSeenAt;
}

final class AccountResponse {
  AccountResponse({
    required this.account,
    required this.entitlement,
    required List<CloudDevice> devices,
    required this.currentDeviceId,
    required this.deviceLimit,
    required this.syncActiveDeviceCount,
  }) : devices = List.unmodifiable(devices);

  factory AccountResponse.fromJson(Map<String, Object?> json) {
    final devices = _list(
      json,
      'devices',
    ).map((value) => CloudDevice.fromJson(_object(value))).toList();
    if (!json.containsKey('entitlement')) _invalid();
    final rawEntitlement = json['entitlement'];
    final response = AccountResponse(
      account: CloudAccount.fromJson(_object(json['account'])),
      entitlement: rawEntitlement == null
          ? null
          : CloudEntitlement.fromJson(_object(rawEntitlement)),
      devices: devices,
      currentDeviceId: _string(json, 'currentDeviceId'),
      deviceLimit: _integer(json, 'deviceLimit'),
      syncActiveDeviceCount: _integer(json, 'syncActiveDeviceCount'),
    );
    final ids = devices.map((device) => device.id).toSet();
    if (response.deviceLimit != 10 ||
        response.syncActiveDeviceCount < 0 ||
        response.syncActiveDeviceCount > response.deviceLimit ||
        response.syncActiveDeviceCount !=
            devices.where((device) => device.syncActive).length ||
        ids.length != devices.length ||
        !ids.contains(response.currentDeviceId)) {
      _invalid();
    }
    return response;
  }

  final CloudAccount account;
  final CloudEntitlement? entitlement;
  final List<CloudDevice> devices;
  final String currentDeviceId;
  final int deviceLimit;
  final int syncActiveDeviceCount;
}

final class CancelSubscriptionNotice {
  CancelSubscriptionNotice({
    required this.required,
    required List<PurchaseSource> sources,
  }) : sources = List.unmodifiable(sources);

  factory CancelSubscriptionNotice.fromJson(Map<String, Object?> json) {
    final sources = _list(json, 'sources').map((value) {
      if (value is! String) _invalid();
      return _enum(PurchaseSource.values, value);
    }).toList();
    final required = _boolean(json, 'required');
    if (sources.toSet().length != sources.length ||
        required != sources.isNotEmpty) {
      _invalid();
    }
    return CancelSubscriptionNotice(required: required, sources: sources);
  }

  final bool required;
  final List<PurchaseSource> sources;
}

final class DeleteAccountResponse {
  const DeleteAccountResponse({required this.cancelSubscription});

  factory DeleteAccountResponse.fromJson(Map<String, Object?> json) =>
      DeleteAccountResponse(
        cancelSubscription: CancelSubscriptionNotice.fromJson(
          _object(json['cancelSubscription']),
        ),
      );

  final CancelSubscriptionNotice cancelSubscription;
}

/// Known codes are constants, while newer server codes retain their wire value.
final class CloudErrorCode {
  const CloudErrorCode(this.value);

  static const authRequired = CloudErrorCode('AUTH_REQUIRED');
  static const unknownAuthError = CloudErrorCode('UNKNOWN_AUTH_ERROR');
  static const sessionRevoked = CloudErrorCode('SESSION_REVOKED');
  static const noEntitlement = CloudErrorCode('NO_ENTITLEMENT');
  static const deviceLimit = CloudErrorCode('DEVICE_LIMIT');
  static const schemaUnsupported = CloudErrorCode('SCHEMA_UNSUPPORTED');
  static const rateLimited = CloudErrorCode('RATE_LIMITED');
  static const purchaseOwnedByOther = CloudErrorCode('PURCHASE_OWNED_BY_OTHER');
  static const validation = CloudErrorCode('VALIDATION');
  static const internalError = CloudErrorCode('INTERNAL_ERROR');
  static const notFound = CloudErrorCode('NOT_FOUND');

  // Protocol 1 sync-only additions; the original account DTO/error parser
  // and seven operation wire definitions remain unchanged.
  static const syncNotActive = CloudErrorCode('SYNC_NOT_ACTIVE');
  static const syncQuotaExceeded = CloudErrorCode('SYNC_QUOTA_EXCEEDED');

  final String value;

  @override
  bool operator ==(Object other) =>
      other is CloudErrorCode && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'CloudErrorCode';
}

Map<String, Object?> _object(Object? value) {
  if (value is! Map<String, Object?>) _invalid();
  return value;
}

String _string(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) _invalid();
  return value;
}

String? _nullableString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (!json.containsKey(key) || (value != null && value is! String)) _invalid();
  return value as String?;
}

bool _boolean(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! bool) _invalid();
  return value;
}

int _integer(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int) _invalid();
  return value;
}

List<Object?> _list(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! List<Object?>) _invalid();
  return value;
}

T _enum<T extends Enum>(List<T> values, String raw) {
  for (final value in values) {
    if (value.name == raw) return value;
  }
  return _invalid();
}

final _utcPattern = RegExp(
  r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.\d+)?Z$',
);

DateTime _timestamp(Map<String, Object?> json, String key) {
  final raw = _string(json, key);
  final match = _utcPattern.firstMatch(raw);
  if (match == null) _invalid();
  final date = DateTime.tryParse(raw);
  if (date == null ||
      !date.isUtc ||
      date.year != int.parse(match.group(1)!) ||
      date.month != int.parse(match.group(2)!) ||
      date.day != int.parse(match.group(3)!) ||
      date.hour != int.parse(match.group(4)!) ||
      date.minute != int.parse(match.group(5)!) ||
      date.second != int.parse(match.group(6)!)) {
    _invalid();
  }
  return date;
}

Never _invalid() => throw const FormatException('Invalid Cloud response.');
