import 'dart:typed_data';

import 'sync_json.dart';
import 'sync_models.dart';

/// Protocol 2 draft DTOs. These never authorize a request or infer a Cloud
/// generation from a local cursor. All incoming fields are required explicitly.
final class SyncLifecycleStatus {
  SyncLifecycleStatus._(Map<String, Object?> json)
    : accountId = json['accountId']! as String,
      deviceId = json['deviceId']! as String,
      syncGeneration = json['syncGeneration'] as String?,
      spaceOrigin = json['spaceOrigin'] as String?,
      headRevision = json['headRevision'] as int?,
      spaceState = json['spaceState']! as String,
      backupState = json['backupState']! as String,
      entitlementExpiresAt = _nullableTime(json['entitlementExpiresAt']),
      retentionUntil = _nullableTime(json['retentionUntil']),
      rebuild = json['rebuild'] == null
          ? null
          : SyncRebuildAttempt.fromJson(_map(json['rebuild'])),
      cleanup = SyncCleanupStatus.fromJson(_map(json['cleanup'])),
      serverTime = _time(json['serverTime']);

  factory SyncLifecycleStatus.fromJson(Map<String, Object?> json) {
    _keys(json, const {
      'accountId',
      'deviceId',
      'syncGeneration',
      'spaceOrigin',
      'headRevision',
      'spaceState',
      'backupState',
      'entitlementExpiresAt',
      'retentionUntil',
      'rebuild',
      'cleanup',
      'serverTime',
    });
    _opaque(json['accountId']);
    _opaque(json['deviceId']);
    _nullableUuid(json['syncGeneration']);
    _choice(json['spaceOrigin'], const {null, 'initial', 'legacy', 'rebuilt'});
    _nullableInteger(json['headRevision'], syncMaxRevision);
    _choice(json['spaceState'], const {
      'noSpace',
      'active',
      'retained',
      'verificationPending',
      'retired',
    });
    _choice(json['backupState'], const {
      'none',
      'ready',
      'rebuildRequired',
      'rebuilding',
    });
    final result = SyncLifecycleStatus._(json);
    final empty = result.syncGeneration == null;
    if (empty != (result.spaceState == 'noSpace') ||
        empty != (result.spaceOrigin == null) ||
        empty != (result.headRevision == null) ||
        (empty && result.backupState != 'none') ||
        (!empty &&
            result.backupState == 'none' &&
            result.spaceState != 'retired') ||
        (result.spaceState == 'retired' && result.backupState != 'none') ||
        (result.backupState == 'rebuilding') != (result.rebuild != null) ||
        (result.rebuild != null &&
            (result.rebuild!.syncGeneration != result.syncGeneration ||
                result.rebuild!.phase != 'staging')) ||
        ((result.backupState == 'rebuildRequired' ||
                result.backupState == 'rebuilding') &&
            (result.headRevision != 0 || result.spaceOrigin != 'rebuilt')) ||
        (result.entitlementExpiresAt != null &&
            result.retentionUntil != null &&
            result.retentionUntil!.isBefore(result.entitlementExpiresAt!))) {
      invalidSync();
    }
    return result;
  }

  final String accountId;
  final String deviceId;
  final String? syncGeneration;
  final String? spaceOrigin;
  final int? headRevision;
  final String spaceState;
  final String backupState;
  final DateTime? entitlementExpiresAt;
  final DateTime? retentionUntil;
  final SyncRebuildAttempt? rebuild;
  final SyncCleanupStatus cleanup;
  final DateTime serverTime;

  @override
  String toString() => 'SyncLifecycleStatus($spaceState, $backupState)';
}

final class SyncCleanupStatus {
  SyncCleanupStatus._(Map<String, Object?> json)
    : pendingGenerationCount = json['pendingGenerationCount']! as int,
      latestRetiredGeneration = json['latestRetiredGeneration'] as String?,
      latestRetiredAt = _nullableTime(json['latestRetiredAt']),
      onlineState = json['onlineState']! as String,
      keyState = json['keyState']! as String;

  factory SyncCleanupStatus.fromJson(Map<String, Object?> json) {
    _keys(json, const {
      'pendingGenerationCount',
      'latestRetiredGeneration',
      'latestRetiredAt',
      'onlineState',
      'keyState',
    });
    _integer(json['pendingGenerationCount'], 100000);
    _nullableUuid(json['latestRetiredGeneration']);
    _choice(json['onlineState'], const {
      'none',
      'pending',
      'running',
      'failed',
      'complete',
    });
    _choice(json['keyState'], const {
      'none',
      'pending',
      'waiting',
      'failed',
      'deleted',
      'destroyed',
    });
    final result = SyncCleanupStatus._(json);
    if ((result.latestRetiredGeneration == null) !=
            (result.latestRetiredAt == null) ||
        (result.latestRetiredGeneration == null &&
            (result.pendingGenerationCount != 0 ||
                result.onlineState != 'none' ||
                result.keyState != 'none')) ||
        (result.onlineState == 'complete' &&
            (result.keyState == 'deleted' || result.keyState == 'destroyed') &&
            result.pendingGenerationCount != 0)) {
      invalidSync();
    }
    return result;
  }

  final int pendingGenerationCount;
  final String? latestRetiredGeneration;
  final DateTime? latestRetiredAt;
  final String onlineState;

  /// `deleted` confirms online key removal, not disaster-backup erasure.
  /// `destroyed` retains the legacy sandbox meaning only.
  final String keyState;
}

final class SyncRebuildAttempt {
  SyncRebuildAttempt._(Map<String, Object?> json)
    : syncGeneration = json['syncGeneration']! as String,
      attemptId = json['attemptId']! as String,
      ownerDeviceId = json['ownerDeviceId']! as String,
      manifestId = json['manifestId']! as String,
      phase = json['phase']! as String,
      recordCount = json['recordCount']! as int,
      stagedRecordCount = json['stagedRecordCount']! as int,
      publishedCursor = json['publishedCursor'] as int?,
      startedAt = _time(json['startedAt']),
      finishedAt = _nullableTime(json['finishedAt']),
      serverTime = _time(json['serverTime']);

  factory SyncRebuildAttempt.fromJson(Map<String, Object?> json) {
    _keys(json, _attemptKeys);
    _uuid(json['syncGeneration']);
    _uuid(json['attemptId']);
    _opaque(json['ownerDeviceId']);
    _uuid(json['manifestId']);
    _choice(json['phase'], const {
      'staging',
      'published',
      'cancelled',
      'superseded',
    });
    _integer(json['recordCount'], 100000);
    _integer(json['stagedRecordCount'], 100000);
    _nullableInteger(json['publishedCursor'], syncMaxRevision);
    final result = SyncRebuildAttempt._(json);
    if (result.stagedRecordCount > result.recordCount ||
        (result.phase == 'published') != (result.publishedCursor != null) ||
        (result.phase == 'staging') != (result.finishedAt == null) ||
        (result.finishedAt?.isBefore(result.startedAt) ?? false) ||
        (result.phase == 'published' &&
            (result.stagedRecordCount != result.recordCount ||
                result.publishedCursor != result.recordCount))) {
      invalidSync();
    }
    return result;
  }

  final String syncGeneration;
  final String attemptId;
  final String ownerDeviceId;
  final String manifestId;
  final String phase;
  final int recordCount;
  final int stagedRecordCount;
  final int? publishedCursor;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final DateTime serverTime;

  @override
  String toString() => 'SyncRebuildAttempt($phase)';
}

final class SyncRebuildManifestEntry {
  factory SyncRebuildManifestEntry({
    required String recordId,
    required SyncRecordType type,
    required String mutationId,
  }) => SyncRebuildManifestEntry.fromJson({
    'recordId': recordId,
    'type': type.name,
    'mutationId': mutationId,
  });

  SyncRebuildManifestEntry._(this.recordId, this.type, this.mutationId);

  factory SyncRebuildManifestEntry.fromJson(Map<String, Object?> json) {
    _keys(json, const {'recordId', 'type', 'mutationId'});
    _choice(json['type'], {for (final t in SyncRecordType.values) t.name});
    final type = SyncRecordType.values.byName(json['type']! as String);
    final rawRecord = json['recordId'];
    _opaque(rawRecord);
    final record = rawRecord! as String;
    if (syncScalarLength(record) > 100) invalidSync();
    switch (type) {
      case SyncRecordType.configuration ||
          SyncRecordType.node ||
          SyncRecordType.chain:
        _uuid(record);
      case SyncRecordType.policy:
        if (record != 'policy') invalidSync();
      case SyncRecordType.selection:
        if (!_selection.hasMatch(record)) invalidSync();
    }
    _uuid(json['mutationId']);
    return SyncRebuildManifestEntry._(
      record,
      type,
      json['mutationId']! as String,
    );
  }

  final String recordId;
  final SyncRecordType type;
  final String mutationId;
  Map<String, Object?> toJson() => {
    'recordId': recordId,
    'type': type.name,
    'mutationId': mutationId,
  };
}

final class SyncRebuildManifest {
  factory SyncRebuildManifest({
    required String manifestId,
    required List<SyncRebuildManifestEntry> entries,
  }) => SyncRebuildManifest.fromJson({
    'manifestId': manifestId,
    'entries': [for (final e in entries) e.toJson()],
  });

  SyncRebuildManifest._(this.manifestId, this.entries);

  factory SyncRebuildManifest.fromJson(Map<String, Object?> json) {
    _keys(json, const {'manifestId', 'entries'});
    _uuid(json['manifestId']);
    final raw = json['entries'];
    if (raw is! List || raw.length > 100000) invalidSync();
    final entries = <SyncRebuildManifestEntry>[];
    final ids = <String>{};
    String? previous;
    for (final value in raw) {
      final e = SyncRebuildManifestEntry.fromJson(_map(value));
      if ((previous != null && previous.compareTo(e.recordId) >= 0) ||
          !ids.add(e.mutationId)) {
        invalidSync();
      }
      previous = e.recordId;
      entries.add(e);
    }
    canonicalSyncBytes(json);
    return SyncRebuildManifest._(
      json['manifestId']! as String,
      List.unmodifiable(entries),
    );
  }

  final String manifestId;
  final List<SyncRebuildManifestEntry> entries;
  Map<String, Object?> toJson() => {
    'manifestId': manifestId,
    'entries': [for (final e in entries) e.toJson()],
  };
  @override
  String toString() => 'SyncRebuildManifest(${entries.length} records)';
}

final class SyncRebuildControlRequest {
  SyncRebuildControlRequest._(Map<String, Object?> json)
    : _json = immutableSyncJson(json) as Map<String, Object?>;

  factory SyncRebuildControlRequest.start({
    required String operationId,
    required String syncGeneration,
    required SyncRebuildManifest manifest,
  }) => SyncRebuildControlRequest.fromJson({
    'operationId': operationId,
    'syncGeneration': syncGeneration,
    'action': 'start',
    'expectedAttemptId': null,
    'manifest': manifest.toJson(),
  });

  factory SyncRebuildControlRequest.claim({
    required String operationId,
    required String syncGeneration,
    required String expectedAttemptId,
    required SyncRebuildManifest manifest,
  }) => SyncRebuildControlRequest.fromJson({
    'operationId': operationId,
    'syncGeneration': syncGeneration,
    'action': 'claim',
    'expectedAttemptId': expectedAttemptId,
    'manifest': manifest.toJson(),
  });

  factory SyncRebuildControlRequest.cancel({
    required String operationId,
    required String syncGeneration,
    required String expectedAttemptId,
  }) => SyncRebuildControlRequest.fromJson({
    'operationId': operationId,
    'syncGeneration': syncGeneration,
    'action': 'cancel',
    'expectedAttemptId': expectedAttemptId,
  });

  factory SyncRebuildControlRequest.complete({
    required String operationId,
    required String syncGeneration,
    required String expectedAttemptId,
    required String manifestId,
  }) => SyncRebuildControlRequest.fromJson({
    'operationId': operationId,
    'syncGeneration': syncGeneration,
    'action': 'complete',
    'expectedAttemptId': expectedAttemptId,
    'manifestId': manifestId,
  });

  factory SyncRebuildControlRequest.fromJson(Map<String, Object?> json) {
    _choice(json['action'], const {'start', 'claim', 'cancel', 'complete'});
    final action = json['action'] as String;
    _keys(json, {
      'operationId',
      'syncGeneration',
      'action',
      'expectedAttemptId',
      if (action == 'start' || action == 'claim') 'manifest',
      if (action == 'complete') 'manifestId',
    });
    _uuid(json['operationId']);
    _uuid(json['syncGeneration']);
    if (action == 'start') {
      if (json['expectedAttemptId'] != null) invalidSync();
    } else {
      _uuid(json['expectedAttemptId']);
    }
    if (action == 'start' || action == 'claim') {
      SyncRebuildManifest.fromJson(_map(json['manifest']));
    }
    if (action == 'complete') _uuid(json['manifestId']);
    canonicalSyncBytes(json);
    return SyncRebuildControlRequest._(json);
  }

  final Map<String, Object?> _json;
  String get operationId => _json['operationId']! as String;
  String get syncGeneration => _json['syncGeneration']! as String;
  String get action => _json['action']! as String;
  String? get expectedAttemptId => _json['expectedAttemptId'] as String?;
  String? get manifestId => action == 'complete'
      ? _json['manifestId'] as String?
      : (action == 'start' || action == 'claim')
      ? (_json['manifest']! as Map)['manifestId'] as String
      : null;
  int? get recordCount => action == 'start' || action == 'claim'
      ? ((_json['manifest']! as Map)['entries']! as List).length
      : null;
  Map<String, Object?> toJson() => _json;
  Uint8List get canonicalBytes => canonicalSyncBytes(_json);
  @override
  String toString() => 'SyncRebuildControlRequest($action)';
}

final class SyncRebuildControlResponse {
  SyncRebuildControlResponse._(this.operationId, this.attempt);
  factory SyncRebuildControlResponse.fromJson(
    Map<String, Object?> json, {
    required SyncRebuildControlRequest request,
  }) {
    _keys(json, {..._attemptKeys, 'operationId'});
    _uuid(json['operationId']);
    final raw = Map<String, Object?>.of(json)..remove('operationId');
    final attempt = SyncRebuildAttempt.fromJson(raw);
    if (json['operationId'] != request.operationId ||
        attempt.syncGeneration != request.syncGeneration ||
        (request.manifestId != null &&
            attempt.manifestId != request.manifestId) ||
        (request.recordCount != null &&
            (attempt.recordCount != request.recordCount ||
                attempt.stagedRecordCount != 0)) ||
        ((request.action == 'cancel' || request.action == 'complete') &&
            attempt.attemptId != request.expectedAttemptId) ||
        (request.action == 'claim' &&
            attempt.attemptId == request.expectedAttemptId) ||
        attempt.phase !=
            switch (request.action) {
              'complete' => 'published',
              'cancel' => 'cancelled',
              _ => 'staging',
            }) {
      invalidSync();
    }
    return SyncRebuildControlResponse._(
      json['operationId']! as String,
      attempt,
    );
  }
  final String operationId;
  final SyncRebuildAttempt attempt;
}

final class SyncActivateV2Response {
  SyncActivateV2Response._(
    this.syncGeneration,
    this.backupState,
    this.rebuildAttemptId,
    this.data,
  );

  factory SyncActivateV2Response.fromJson(
    Map<String, Object?> json, {
    required String? expectedGeneration,
  }) {
    _keys(json, const {
      'deviceId',
      'syncActive',
      'deviceLimit',
      'syncActiveDeviceCount',
      'serverTime',
      'syncGeneration',
      'backupState',
      'rebuildAttemptId',
    });
    _uuid(json['syncGeneration']);
    _nullableUuid(json['rebuildAttemptId']);
    _choice(json['backupState'], const {
      'ready',
      'rebuildRequired',
      'rebuilding',
    });
    if ((expectedGeneration != null &&
            json['syncGeneration'] != expectedGeneration) ||
        (json['backupState'] == 'rebuilding') !=
            (json['rebuildAttemptId'] != null) ||
        (expectedGeneration == null && json['backupState'] != 'ready')) {
      invalidSync();
    }
    final raw = Map<String, Object?>.of(json)
      ..remove('syncGeneration')
      ..remove('backupState')
      ..remove('rebuildAttemptId');
    return SyncActivateV2Response._(
      json['syncGeneration']! as String,
      json['backupState']! as String,
      json['rebuildAttemptId'] as String?,
      SyncActivateResponse.fromJson(raw),
    );
  }

  final String syncGeneration;
  final String backupState;
  final String? rebuildAttemptId;
  final SyncActivateResponse data;
  String get deviceId => data.deviceId;
  bool get syncActive => data.syncActive;
  int get deviceLimit => data.deviceLimit;
  int get syncActiveDeviceCount => data.syncActiveDeviceCount;
  DateTime get serverTime => data.serverTime;
}

final class SyncPushV2Response {
  SyncPushV2Response._(
    this.syncGeneration,
    this.rebuildAttemptId,
    this.writeState,
    this.data,
  );

  factory SyncPushV2Response.fromJson(
    Map<String, Object?> json, {
    required String syncGeneration,
    required String? rebuildAttemptId,
    required List<SyncMutation> mutations,
  }) {
    _keys(json, const {
      'syncGeneration',
      'rebuildAttemptId',
      'writeState',
      'results',
      'processedCount',
      'hasMore',
      'serverTime',
    });
    _uuid(json['syncGeneration']);
    _nullableUuid(json['rebuildAttemptId']);
    if (json['syncGeneration'] != syncGeneration ||
        json['rebuildAttemptId'] != rebuildAttemptId ||
        json['writeState'] !=
            (rebuildAttemptId == null ? 'published' : 'staged')) {
      invalidSync();
    }
    final raw = Map<String, Object?>.of(json)
      ..remove('syncGeneration')
      ..remove('rebuildAttemptId')
      ..remove('writeState');
    final data = SyncPushResponse.fromJson(raw, mutations: mutations);
    if (rebuildAttemptId != null &&
        data.results.any((result) => result is! SyncAppliedResult)) {
      invalidSync();
    }
    return SyncPushV2Response._(
      syncGeneration,
      rebuildAttemptId,
      json['writeState']! as String,
      data,
    );
  }

  final String syncGeneration;
  final String? rebuildAttemptId;
  final String writeState;
  final SyncPushResponse data;
  List<SyncPushResult> get results => data.results;
  int get processedCount => data.processedCount;
  bool get hasMore => data.hasMore;
  DateTime get serverTime => data.serverTime;
}

final class SyncPullV2Response {
  SyncPullV2Response._(this.syncGeneration, this.headRevision, this.data);

  factory SyncPullV2Response.fromJson(
    Map<String, Object?> json, {
    required String syncGeneration,
    required int cursor,
    required int limit,
  }) {
    _keys(json, const {
      'syncGeneration',
      'rebuildAttemptId',
      'headRevision',
      'records',
      'nextCursor',
      'hasMore',
      'serverTime',
    });
    _uuid(json['syncGeneration']);
    if (json['syncGeneration'] != syncGeneration ||
        json['rebuildAttemptId'] != null) {
      invalidSync();
    }
    _integer(json['headRevision'], syncMaxRevision);
    final raw = Map<String, Object?>.of(json)
      ..remove('syncGeneration')
      ..remove('rebuildAttemptId')
      ..remove('headRevision');
    final data = SyncPullResponse.fromJson(raw, cursor: cursor, limit: limit);
    final head = json['headRevision']! as int;
    if (data.nextCursor > head || data.hasMore != (data.nextCursor < head)) {
      invalidSync();
    }
    return SyncPullV2Response._(syncGeneration, head, data);
  }

  final String syncGeneration;
  final int headRevision;
  final SyncPullResponse data;
  String? get rebuildAttemptId => null;
  List<SyncRecord> get records => data.records;
  int get nextCursor => data.nextCursor;
  bool get hasMore => data.hasMore;
  DateTime get serverTime => data.serverTime;
}

Uint8List encodeSyncPushV2({
  required String syncGeneration,
  required String? rebuildAttemptId,
  required List<SyncMutation> mutations,
}) {
  _uuid(syncGeneration);
  _nullableUuid(rebuildAttemptId);
  if (mutations.isEmpty || mutations.length > 100) invalidSync();
  if (mutations.map((m) => m.mutationId).toSet().length != mutations.length ||
      mutations.map((m) => m.recordId).toSet().length != mutations.length) {
    invalidSync();
  }
  if (rebuildAttemptId != null &&
      mutations.any((m) => m.deleted || m.baseRevision != 0)) {
    invalidSync();
  }
  return canonicalSyncBytes({
    'syncGeneration': syncGeneration,
    'rebuildAttemptId': rebuildAttemptId,
    'mutations': [for (final m in mutations) m.toJson()],
  });
}

void validateSyncGeneration(String? value, {bool nullable = false}) =>
    nullable ? _nullableUuid(value) : _uuid(value);

const _attemptKeys = {
  'syncGeneration',
  'attemptId',
  'ownerDeviceId',
  'manifestId',
  'phase',
  'recordCount',
  'stagedRecordCount',
  'publishedCursor',
  'startedAt',
  'finishedAt',
  'serverTime',
};
final _uuidPattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
);
final _selection = RegExp(
  r'^sel:(?:self|[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}):[A-Za-z0-9_-]{22}$',
);
final _timePattern = RegExp(
  r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.\d+)?Z$',
);

Map<String, Object?> _map(Object? value) {
  if (value is! Map<String, Object?>) invalidSync();
  return value;
}

void _keys(Map<String, Object?> json, Set<String> expected) {
  if (json.length != expected.length || !expected.every(json.containsKey)) {
    invalidSync();
  }
}

void _opaque(Object? value) {
  if (value is! String || syncScalarLength(value) == 0) invalidSync();
}

void _uuid(Object? value) {
  if (value is! String || value.length != 36 || !_uuidPattern.hasMatch(value)) {
    invalidSync();
  }
}

void _nullableUuid(Object? value) {
  if (value != null) _uuid(value);
}

void _integer(Object? value, int maximum) {
  if (value is! int || value < 0 || value > maximum) invalidSync();
}

void _nullableInteger(Object? value, int maximum) {
  if (value != null) _integer(value, maximum);
}

void _choice(Object? value, Set<Object?> choices) {
  if (!choices.contains(value)) invalidSync();
}

DateTime? _nullableTime(Object? value) => value == null ? null : _time(value);
DateTime _time(Object? value) {
  if (value is! String) invalidSync();
  final match = _timePattern.firstMatch(value);
  final parsed = DateTime.tryParse(value);
  if (match == null ||
      parsed == null ||
      !parsed.isUtc ||
      parsed.year != int.parse(match[1]!) ||
      parsed.month != int.parse(match[2]!) ||
      parsed.day != int.parse(match[3]!) ||
      parsed.hour != int.parse(match[4]!) ||
      parsed.minute != int.parse(match[5]!) ||
      parsed.second != int.parse(match[6]!)) {
    invalidSync();
  }
  return parsed;
}
