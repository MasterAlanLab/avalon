import 'dart:convert';
import 'dart:typed_data';

import 'package:av_core/av_core.dart' show parseOverride;
import 'package:crypto/crypto.dart';

import 'sync_json.dart';
import 'sync_schema.dart';

export 'sync_json.dart'
    show
        SyncValidationException,
        SyncValidationFailure,
        canonicalSyncBytes,
        canonicalSyncJson,
        decodeSyncJson,
        decodeSyncJsonText,
        syncBodyMaxBytes,
        syncRecordMaxBytes,
        syncMaxRevision;

enum SyncRecordType { configuration, node, chain, policy, selection }

/// Outgoing domain serializers omit nulls. Only this explicit adapter adds
/// the nulls mandated by schema 1; incoming fromJson never fills fields.
Map<String, Object?> completeSyncPayload(
  SyncRecordType type,
  Map<String, Object?> payload, {
  bool validate = true,
}) {
  final name = switch (type) {
    SyncRecordType.configuration => 'SyncConfigurationPayload',
    SyncRecordType.node => 'SyncNodePayload',
    SyncRecordType.chain => 'SyncChainPayload',
    SyncRecordType.policy => 'SyncPolicyPayload',
    SyncRecordType.selection => 'SyncSelectionPayload',
  };
  final result = _object(
    _complete(_object(syncSchemaDefinitions[name]), payload),
  );
  if (validate) {
    _validateNamed(name, result);
    _validatePayload(type, result);
  }
  return immutableSyncJson(result) as Map<String, Object?>;
}

Object? _complete(Map<String, Object?> schema, Object? value) {
  final ref = schema[r'$ref'];
  if (ref is String) {
    return _complete(
      _object(syncSchemaDefinitions[ref.split('/').last]),
      value,
    );
  }
  if (value == null) return null;
  final choices = schema['oneOf'];
  if (choices is List<Object?>) {
    for (final raw in choices) {
      var branch = _object(raw);
      final reference = branch[r'$ref'];
      if (reference is String) {
        branch = _object(syncSchemaDefinitions[reference.split('/').last]);
      }
      if (value is Map<String, Object?> && branch['properties'] is Map) {
        final props = _object(branch['properties']);
        final discriminators = props.entries.where(
          (e) => e.value is Map && (e.value! as Map)['enum'] is List,
        );
        if (discriminators.every(
          (e) => ((e.value! as Map)['enum']! as List).contains(value[e.key]),
        )) {
          return _complete(branch, value);
        }
      } else if (value is String && branch['type'] == 'string') {
        return value;
      }
    }
    return value;
  }
  if (value is Map<String, Object?> && schema['properties'] is Map) {
    final result = Map<String, Object?>.from(value);
    for (final prop in _object(schema['properties']).entries) {
      final field = _object(prop.value);
      if (result.containsKey(prop.key)) {
        result[prop.key] = _complete(field, result[prop.key]);
      } else if (field['nullable'] == true ||
          (field['oneOf'] is List &&
              (field['oneOf']! as List).any(
                (e) => e is Map && e['nullable'] == true,
              ))) {
        result[prop.key] = null;
      }
    }
    return result;
  }
  if (value is List<Object?> && schema['items'] is Map) {
    return [
      for (final item in value) _complete(_object(schema['items']), item),
    ];
  }
  return value;
}

String syncSelectionId(String configurationId, String groupKey) {
  _validateNamed('SyncConfigurationId', configurationId);
  final hash = base64Url
      .encode(sha256.convert(utf8.encode(groupKey)).bytes)
      .replaceAll('=', '')
      .substring(0, 22);
  syncScalarLength(groupKey);
  return 'sel:$configurationId:$hash';
}

/// Immutable, fully validated wire JSON. It never exposes secrets through
/// toString. Domain/database adapters are separate from this boundary DTO.
final class SyncMutation {
  factory SyncMutation({
    required String mutationId,
    required String recordId,
    required SyncRecordType type,
    required int baseRevision,
    required int editedAt,
    required bool deleted,
    int schemaVersion = 1,
    required Map<String, Object?>? payload,
  }) => SyncMutation.fromJson({
    'mutationId': mutationId,
    'recordId': recordId,
    'type': type.name,
    'baseRevision': baseRevision,
    'editedAt': editedAt,
    'deleted': deleted,
    'schemaVersion': schemaVersion,
    'payload': payload,
  });

  SyncMutation._(this._json);

  factory SyncMutation.fromJson(Map<String, Object?> json) {
    final frozen = _validatedEnvelope(json, mutation: true);
    return SyncMutation._(frozen);
  }

  factory SyncMutation.decode(List<int> bytes) => SyncMutation.fromJson(
    _object(decodeSyncJson(bytes, maxBytes: syncRecordMaxBytes)),
  );

  final Map<String, Object?> _json;
  String get mutationId => _json['mutationId']! as String;
  String get recordId => _json['recordId']! as String;
  SyncRecordType get type => _recordType(_json['type']);
  int get baseRevision => _json['baseRevision']! as int;
  int get editedAt => _json['editedAt']! as int;
  bool get deleted => _json['deleted']! as bool;
  int get schemaVersion => _json['schemaVersion']! as int;
  Map<String, Object?>? get payload =>
      _json['payload'] as Map<String, Object?>?;
  Map<String, Object?> toJson() => _json;
  String get canonicalJson => canonicalSyncJson(_json);
  Uint8List get canonicalBytes =>
      canonicalSyncBytes(_json, maxBytes: syncRecordMaxBytes);

  @override
  String toString() => 'SyncMutation(${type.name})';
}

final class SyncRecord {
  factory SyncRecord({
    required String recordId,
    required SyncRecordType type,
    required int revision,
    required int editedAt,
    required String editedByDeviceId,
    required bool deleted,
    int schemaVersion = 1,
    required Map<String, Object?>? payload,
  }) => SyncRecord.fromJson({
    'recordId': recordId,
    'type': type.name,
    'revision': revision,
    'editedAt': editedAt,
    'editedByDeviceId': editedByDeviceId,
    'deleted': deleted,
    'schemaVersion': schemaVersion,
    'payload': payload,
  });

  SyncRecord._(this._json);

  factory SyncRecord.fromJson(Map<String, Object?> json) =>
      SyncRecord._(_validatedEnvelope(json, mutation: false));

  factory SyncRecord.decode(List<int> bytes) => SyncRecord.fromJson(
    _object(decodeSyncJson(bytes, maxBytes: syncRecordMaxBytes)),
  );

  final Map<String, Object?> _json;
  String get recordId => _json['recordId']! as String;
  SyncRecordType get type => _recordType(_json['type']);
  int get revision => _json['revision']! as int;
  int get editedAt => _json['editedAt']! as int;
  String get editedByDeviceId => _json['editedByDeviceId']! as String;
  bool get deleted => _json['deleted']! as bool;
  int get schemaVersion => _json['schemaVersion']! as int;
  Map<String, Object?>? get payload =>
      _json['payload'] as Map<String, Object?>?;
  Map<String, Object?> toJson() => _json;
  String get canonicalJson => canonicalSyncJson(_json);
  Uint8List get canonicalBytes =>
      canonicalSyncBytes(_json, maxBytes: syncRecordMaxBytes);

  @override
  String toString() => 'SyncRecord(${type.name})';
}

final class SyncActivateResponse {
  SyncActivateResponse._(Map<String, Object?> json)
    : deviceId = json['deviceId']! as String,
      syncActive = json['syncActive']! as bool,
      deviceLimit = json['deviceLimit']! as int,
      syncActiveDeviceCount = json['syncActiveDeviceCount']! as int,
      serverTime = _timestamp(json['serverTime']);

  factory SyncActivateResponse.fromJson(Map<String, Object?> json) {
    _validateNamed('SyncActivateResponse', json);
    return SyncActivateResponse._(json);
  }

  final String deviceId;
  final bool syncActive;
  final int deviceLimit;
  final int syncActiveDeviceCount;
  final DateTime serverTime;
}

sealed class SyncPushResult {
  const SyncPushResult(this.mutationId);
  final String mutationId;
}

final class SyncAppliedResult extends SyncPushResult {
  const SyncAppliedResult({
    required String mutationId,
    required this.revision,
    required this.editedAt,
  }) : super(mutationId);

  final int revision;
  final int editedAt;
}

final class SyncSupersededResult extends SyncPushResult {
  const SyncSupersededResult({required String mutationId, required this.record})
    : super(mutationId);

  final SyncRecord record;
}

final class SyncPushResponse {
  SyncPushResponse._({
    required List<SyncPushResult> results,
    required this.processedCount,
    required this.hasMore,
    required this.serverTime,
  }) : results = List.unmodifiable(results);

  factory SyncPushResponse.fromJson(
    Map<String, Object?> json, {
    required List<SyncMutation> mutations,
  }) {
    _validateNamed('SyncPushResponse', json);
    final rawResults = _list(json['results']);
    final count = json['processedCount']! as int;
    final hasMore = json['hasMore']! as bool;
    if (count != rawResults.length ||
        count > mutations.length ||
        hasMore != (count < mutations.length)) {
      invalidSync();
    }
    final results = <SyncPushResult>[];
    for (final (index, raw) in rawResults.indexed) {
      final result = _object(raw);
      final sent = mutations[index];
      final mutationId = result['mutationId']! as String;
      if (mutationId != sent.mutationId) invalidSync();
      if (result['status'] == 'applied') {
        final editedAt = result['editedAt']! as int;
        if (editedAt > sent.editedAt) invalidSync();
        results.add(
          SyncAppliedResult(
            mutationId: mutationId,
            revision: result['revision']! as int,
            editedAt: editedAt,
          ),
        );
      } else {
        final record = SyncRecord.fromJson(_object(result['record']));
        if (record.recordId != sent.recordId || record.type != sent.type) {
          invalidSync();
        }
        results.add(
          SyncSupersededResult(mutationId: mutationId, record: record),
        );
      }
    }
    return SyncPushResponse._(
      results: results,
      processedCount: count,
      hasMore: hasMore,
      serverTime: _timestamp(json['serverTime']),
    );
  }

  final List<SyncPushResult> results;
  final int processedCount;
  final bool hasMore;
  final DateTime serverTime;
}

final class SyncPullResponse {
  SyncPullResponse._({
    required List<SyncRecord> records,
    required this.nextCursor,
    required this.hasMore,
    required this.serverTime,
  }) : records = List.unmodifiable(records);

  factory SyncPullResponse.fromJson(
    Map<String, Object?> json, {
    required int cursor,
    int limit = 500,
  }) {
    validateSyncPullInput(cursor, limit);
    _validateNamed('SyncPullResponse', json);
    final records = _list(
      json['records'],
    ).map((raw) => SyncRecord.fromJson(_object(raw))).toList();
    if (records.length > limit) invalidSync();
    var previous = cursor;
    final ids = <String>{};
    for (final record in records) {
      if (record.revision <= previous || !ids.add(record.recordId)) {
        invalidSync();
      }
      previous = record.revision;
    }
    final next = json['nextCursor']! as int;
    final hasMore = json['hasMore']! as bool;
    if (next != previous || (records.isEmpty && hasMore)) invalidSync();
    return SyncPullResponse._(
      records: records,
      nextCursor: next,
      hasMore: hasMore,
      serverTime: _timestamp(json['serverTime']),
    );
  }

  final List<SyncRecord> records;
  final int nextCursor;
  final bool hasMore;
  final DateTime serverTime;
}

void validateSyncPullInput(int cursor, int limit) {
  if (cursor < 0 || cursor > syncMaxRevision || limit < 1 || limit > 500) {
    invalidSync();
  }
}

Uint8List encodeSyncPush(List<SyncMutation> mutations) {
  final json = {'mutations': mutations.map((m) => m.toJson()).toList()};
  _validateNamed('SyncPushRequest', json);
  if (mutations.map((m) => m.mutationId).toSet().length != mutations.length ||
      mutations.map((m) => m.recordId).toSet().length != mutations.length) {
    invalidSync();
  }
  return canonicalSyncBytes(json);
}

Map<String, Object?> _validatedEnvelope(
  Map<String, Object?> json, {
  required bool mutation,
}) {
  final type = _recordType(json['type']);
  if (json['schemaVersion'] is int && json['schemaVersion'] != 1) {
    invalidSync(SyncValidationFailure.unsupportedSchema);
  }
  final frozen = immutableSyncJson(json) as Map<String, Object?>;
  _validateNamed(mutation ? 'SyncMutation' : 'SyncRecord', frozen);
  final id = frozen['recordId']! as String;
  if (type == SyncRecordType.policy) {
    if (id != 'policy') invalidSync();
  } else if (type == SyncRecordType.selection) {
    if (!_selectionPattern.hasMatch(id)) invalidSync();
  } else {
    _validateNamed('SyncUuid', id);
  }
  if (frozen['deleted'] == false) {
    final payload = _object(frozen['payload']);
    _validatePayload(type, payload);
    if (type == SyncRecordType.selection &&
        id !=
            syncSelectionId(
              payload['configurationId']! as String,
              payload['groupKey']! as String,
            )) {
      invalidSync();
    }
  }
  canonicalSyncBytes(frozen, maxBytes: syncRecordMaxBytes);
  return frozen;
}

void _validatePayload(SyncRecordType type, Map<String, Object?> payload) {
  switch (type) {
    case SyncRecordType.configuration:
      if (payload['kind'] == 'subscription') {
        final source = _object(payload['source']);
        validateSyncResourceUrl(source['url']! as String);
        _validateHeaders(_object(source['headers']));
      } else {
        final content = _object(payload['content']);
        final model = _object(content['model']);
        _validateSecretCoverage(model, _object(content['secrets']));
        _validateContent(model);
      }
    case SyncRecordType.node:
      _validateSecretCoverage(payload['params'], _object(payload['secrets']));
      _validateMemberships(_list(payload['memberships']));
    case SyncRecordType.chain:
      _validateMemberships(_list(payload['memberships']));
      final identities = <String>{};
      for (final raw in _list(payload['hops'])) {
        final hop = _object(raw);
        final identity = switch (hop['kind']) {
          'source' => canonicalSyncJson({
            'kind': 'source',
            'configurationId': hop['configurationId'],
            'key': hop['key'],
          }),
          'selfNode' => canonicalSyncJson({
            'kind': 'selfNode',
            'id': hop['id'],
          }),
          'tailnetExit' => canonicalSyncJson({
            'kind': 'tailnetExit',
            'tailnet': hop['tailnet'],
            'nodeStableId': hop['nodeStableId'],
          }),
          _ => invalidSync(),
        };
        if (!identities.add(identity)) invalidSync();
      }
    case SyncRecordType.policy:
      final override = payload['jsonOverride'] as String?;
      if (override != null && override.trim().isNotEmpty) {
        decodeSyncJsonText(override);
        try {
          parseOverride(override);
        } on Object {
          invalidSync();
        }
      }
    case SyncRecordType.selection:
      break;
  }
}

void _validateSecretCoverage(Object? model, Map<String, Object?> secrets) {
  final refs = <String>{};
  void collect(Object? value) {
    if (value is Map<String, Object?>) {
      if (value.containsKey(r'$secretRef')) {
        refs.add(value[r'$secretRef']! as String);
      } else {
        value.values.forEach(collect);
      }
    } else if (value is List<Object?>) {
      value.forEach(collect);
    }
  }

  collect(model);
  if (refs.length != secrets.length || !refs.containsAll(secrets.keys)) {
    invalidSync();
  }
}

void _validateMemberships(List<Object?> memberships) {
  for (final raw in memberships) {
    final item = _object(raw);
    if (item['configurationId'] == 'self' && item['groupKey'] == 'custom') {
      invalidSync();
    }
  }
}

void validateSyncResourceUrl(String raw) {
  // Do not silently normalize an authenticated URL to validate a different
  // address. DNS and actual connected-IP checks are the resource service's
  // responsibility, including every redirect and core-initiated connection.
  if (raw.trim() != raw || RegExp(r'[\x00-\x20\x7f\\]').hasMatch(raw)) {
    invalidSync();
  }
  for (var i = 0; i < raw.length; ++i) {
    if (raw.codeUnitAt(i) == 0x25) {
      if (i + 2 >= raw.length ||
          !RegExp(r'^[0-9a-fA-F]{2}$').hasMatch(raw.substring(i + 1, i + 3))) {
        invalidSync();
      }
      i += 2;
    }
  }
  try {
    final uri = Uri.tryParse(raw);
    if (uri == null ||
        !(uri.isScheme('https') || uri.isScheme('http')) ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasFragment ||
        (uri.hasPort && (uri.port < 1 || uri.port > 65535))) {
      invalidSync();
    }
  } on FormatException {
    invalidSync();
  }
}

void _validateHeaders(Map<String, Object?> headers) {
  final names = <String>{};
  for (final entry in headers.entries) {
    final name = entry.key.toLowerCase();
    if (syncScalarLength(entry.key) > 256 ||
        !_headerToken.hasMatch(entry.key) ||
        !names.add(name) ||
        RegExp(r'[\r\n\x00]').hasMatch(entry.value! as String) ||
        (!const {
              'authorization',
              'cookie',
              'user-agent',
              'accept',
              'accept-language',
              'referer',
              'origin',
            }.contains(name) &&
            !name.startsWith('x-')) ||
        name.startsWith('x-forwarded-') ||
        name == 'x-real-ip') {
      invalidSync();
    }
  }
}

void _validateContent(Map<String, Object?> model) {
  final nodes = _list(model['nodes']).map(_object).toList();
  final groups = _list(model['groups']).map(_object).toList();
  final entities = <String, Map<String, Object?>>{};
  final edges = <String, Set<String>>{};
  const builtins = {'builtin:direct', 'builtin:reject'};
  for (final entity in [...nodes, ...groups]) {
    final key = entity['key']! as String;
    if (builtins.contains(key) || entities.containsKey(key)) invalidSync();
    entities[key] = entity;
    edges[key] = {};
  }
  void reference(String from, String target) {
    if (builtins.contains(target)) return;
    if (!entities.containsKey(target)) invalidSync();
    edges[from]!.add(target);
  }

  for (final node in nodes) {
    final detour = node['detourKey'] as String?;
    if (detour != null) reference(node['key']! as String, detour);
  }
  for (final group in groups) {
    if (group['type'] == 'selector') {
      if (group['displayType'] != 'Selector' || group['test'] != null) {
        invalidSync();
      }
    } else {
      if (group['displayType'] == 'Selector' || group['test'] == null) {
        invalidSync();
      }
      validateSyncResourceUrl(_object(group['test'])['url']! as String);
    }
    for (final target in _list(group['members'])) {
      reference(group['key']! as String, target! as String);
    }
  }
  // Kahn traversal avoids recursive stack growth on a maximum-size model.
  final incoming = {for (final key in entities.keys) key: 0};
  for (final targets in edges.values) {
    for (final key in targets) {
      incoming[key] = incoming[key]! + 1;
    }
  }
  final ready = [
    for (final e in incoming.entries)
      if (e.value == 0) e.key,
  ];
  var visited = 0;
  while (ready.isNotEmpty) {
    final key = ready.removeLast();
    ++visited;
    for (final target in edges[key]!) {
      final next = incoming[target]! - 1;
      incoming[target] = next;
      if (next == 0) ready.add(target);
    }
  }
  if (visited != entities.length) invalidSync();
  final tags = <String>{};
  for (final raw in _list(model['ruleSets'])) {
    final set = _object(raw);
    if (!tags.add(set['tag']! as String)) invalidSync();
    validateSyncResourceUrl(set['url']! as String);
  }
  for (final raw in _list(model['rules'])) {
    final rule = _object(raw);
    final target = rule['target']! as String;
    if (!entities.containsKey(target) && !builtins.contains(target)) {
      invalidSync();
    }
    for (final tag in _list(rule['ruleSet'])) {
      if (!tags.contains(tag)) invalidSync();
    }
  }
  final finalTarget = model['finalTarget']! as String;
  if (!entities.containsKey(finalTarget) && !builtins.contains(finalTarget)) {
    invalidSync();
  }
}

void _validateNamed(String name, Object? value) {
  if ((name == 'SyncRecord' || name == 'SyncMutation') &&
      value is Map<String, Object?>) {
    _recordType(value['type']);
    if (value['schemaVersion'] is int && value['schemaVersion'] != 1) {
      invalidSync(SyncValidationFailure.unsupportedSchema);
    }
  }
  _validate(_object(syncSchemaDefinitions[name]), value);
}

/// A deliberately limited evaluator for the compiled, frozen Sync schema;
/// not a general JSON-schema framework or remotely configurable validator.
void _validate(Map<String, Object?> schema, Object? value) {
  final ref = schema[r'$ref'];
  if (ref is String) {
    _validateNamed(ref.split('/').last, value);
    return;
  }
  final choices = schema['oneOf'];
  if (choices is List<Object?>) {
    var matches = 0;
    for (final choice in choices) {
      try {
        final branch = _object(choice);
        final ref = branch[r'$ref'];
        final resolved = ref is String
            ? _object(syncSchemaDefinitions[ref.split('/').last])
            : branch;
        final props = resolved['properties'];
        if (value is Map<String, Object?> && props is Map<String, Object?>) {
          var mismatch = false;
          for (final key in const [
            'type',
            'protocol',
            'kind',
            'deleted',
            'status',
          ]) {
            final spec = props[key];
            if (spec is Map<String, Object?> && spec['enum'] is List) {
              if (!(spec['enum']! as List).contains(value[key])) {
                mismatch = true;
              }
            }
          }
          if (mismatch) continue;
        }
        _validate(branch, value);
        ++matches;
      } on SyncValidationException {
        // The enclosing union requires exactly one complete branch.
      }
    }
    if (matches != 1) invalidSync();
    return;
  }
  if (value == null) {
    if (schema['nullable'] != true ||
        (schema['enum'] is List && !(schema['enum']! as List).contains(null))) {
      invalidSync();
    }
    return;
  }
  final allowed = schema['enum'];
  if (allowed is List && !allowed.contains(value)) invalidSync();
  switch (schema['type']) {
    case 'object':
      final map = _object(value);
      final max = schema['maxProperties'] as int?;
      if (max != null && map.length > max) invalidSync();
      final props = schema['properties'] == null
          ? const <String, Object?>{}
          : _object(schema['properties']);
      for (final field in schema['required'] as List? ?? const []) {
        if (!map.containsKey(field)) invalidSync();
      }
      for (final entry in map.entries) {
        syncScalarLength(entry.key);
        final spec = props[entry.key];
        if (spec != null) continue;
        if (schema['additionalProperties'] is Map<String, Object?>) {
          _validate(_object(schema['additionalProperties']), entry.value);
        } else {
          invalidSync();
        }
      }
      for (final prop in props.entries) {
        if (map.containsKey(prop.key)) {
          _validate(_object(prop.value), map[prop.key]);
        }
      }
    case 'array':
      final list = _list(value);
      if (list.length < (schema['minItems'] as int? ?? 0) ||
          list.length > (schema['maxItems'] as int? ?? syncMaxRevision)) {
        invalidSync();
      }
      final unique = schema['uniqueItems'] == true ? <String>{} : null;
      for (final item in list) {
        _validate(_object(schema['items']), item);
        if (unique != null && !unique.add(canonicalSyncJson(item))) {
          invalidSync();
        }
      }
    case 'string':
      if (value is! String) invalidSync();
      final length = syncScalarLength(value);
      if (length < (schema['minLength'] as int? ?? 0) ||
          length > (schema['maxLength'] as int? ?? syncMaxRevision)) {
        invalidSync();
      }
      final pattern = schema['pattern'] as String?;
      if (pattern != null && !RegExp(pattern).hasMatch(value)) invalidSync();
      if (schema['format'] == 'date-time') _timestamp(value);
    case 'integer':
      if (value is! int ||
          value < (schema['minimum'] as int? ?? -syncMaxRevision) ||
          value > (schema['maximum'] as int? ?? syncMaxRevision)) {
        invalidSync();
      }
    case 'boolean':
      if (value is! bool) invalidSync();
    default:
      invalidSync();
  }
}

Map<String, Object?> _object(Object? value) {
  if (value is! Map<String, Object?>) invalidSync();
  return value;
}

List<Object?> _list(Object? value) {
  if (value is! List<Object?>) invalidSync();
  return value;
}

SyncRecordType _recordType(Object? value) {
  for (final type in SyncRecordType.values) {
    if (type.name == value) return type;
  }
  invalidSync(
    value is String
        ? SyncValidationFailure.unsupportedSchema
        : SyncValidationFailure.invalidPayload,
  );
}

DateTime _timestamp(Object? value) {
  if (value is! String) invalidSync();
  final match = _utcPattern.firstMatch(value);
  if (match == null) invalidSync();
  final date = DateTime.tryParse(value);
  if (date == null ||
      !date.isUtc ||
      date.year != int.parse(match[1]!) ||
      date.month != int.parse(match[2]!) ||
      date.day != int.parse(match[3]!) ||
      date.hour != int.parse(match[4]!) ||
      date.minute != int.parse(match[5]!) ||
      date.second != int.parse(match[6]!)) {
    invalidSync();
  }
  return date;
}

final _utcPattern = RegExp(
  r'^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.\d+)?Z$',
);
final _selectionPattern = RegExp(
  r'^sel:(?:self|[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}):[A-Za-z0-9_-]{22}$',
);
final _headerToken = RegExp(r"^[!#$%&'*+.^_`|~0-9A-Za-z-]+$");
