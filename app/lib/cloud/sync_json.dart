import 'dart:convert';
import 'dart:typed_data';

const syncBodyMaxBytes = 64 * 1024 * 1024;
const syncRecordMaxBytes = 32 * 1024 * 1024;
const syncJsonMaxDepth = 64;
const syncMaxRevision = 9007199254740991;

enum SyncValidationFailure {
  invalidJson,
  invalidPayload,
  unsupportedSchema,
  tooLarge,
}

/// Safe to report: never retains a body, JSON key, URL, or credential.
final class SyncValidationException implements Exception {
  const SyncValidationException([
    this.reason = SyncValidationFailure.invalidPayload,
  ]);

  final SyncValidationFailure reason;

  @override
  String toString() => 'SyncValidationException(${reason.name})';
}

Never invalidSync([
  SyncValidationFailure reason = SyncValidationFailure.invalidPayload,
]) => throw SyncValidationException(reason);

Object? decodeSyncJson(List<int> bytes, {int maxBytes = syncBodyMaxBytes}) {
  if (bytes.length > maxBytes) invalidSync(SyncValidationFailure.tooLarge);
  try {
    return decodeSyncJsonText(utf8.decode(bytes));
  } on SyncValidationException {
    rethrow;
  } on Object {
    invalidSync(SyncValidationFailure.invalidJson);
  }
}

Object? decodeSyncJsonText(String text) {
  try {
    final reader = _Reader(text);
    final value = reader.value(1);
    reader.space();
    if (reader.index != text.length) {
      invalidSync(SyncValidationFailure.invalidJson);
    }
    return value;
  } on SyncValidationException {
    rethrow;
  } on Object {
    invalidSync(SyncValidationFailure.invalidJson);
  }
}

/// Unicode scalar count, rejecting unpaired UTF-16 surrogates on all paths.
int syncScalarLength(String value) {
  var count = 0;
  for (var i = 0; i < value.length; ++i) {
    final unit = value.codeUnitAt(i);
    if (unit >= 0xd800 && unit <= 0xdbff) {
      if (++i >= value.length) invalidSync();
      final low = value.codeUnitAt(i);
      if (low < 0xdc00 || low > 0xdfff) invalidSync();
    } else if (unit >= 0xdc00 && unit <= 0xdfff) {
      invalidSync();
    }
    ++count;
  }
  return count;
}

Object? immutableSyncJson(Object? value, [int depth = 1]) {
  if (depth > syncJsonMaxDepth) invalidSync();
  if (value is String) {
    syncScalarLength(value);
    return value;
  }
  if (value == null || value is bool || value is int) return value;
  if (value is Map<String, Object?>) {
    final copied = <String, Object?>{};
    for (final entry in value.entries) {
      syncScalarLength(entry.key);
      copied[entry.key] = immutableSyncJson(entry.value, depth + 1);
    }
    return Map<String, Object?>.unmodifiable(copied);
  }
  if (value is List<Object?>) {
    return List<Object?>.unmodifiable([
      for (final item in value) immutableSyncJson(item, depth + 1),
    ]);
  }
  // All numeric fields in Sync* are integers. Decimal numbers belong only
  // inside the opaque override string, never the JCS wire object.
  invalidSync();
}

/// RFC 8785 for the frozen Sync schema (only safe integer numeric fields).
/// UTF-16 key ordering and JSON escaping use Dart's standard codecs. There
/// are no floating point fields requiring a separate ECMAScript serializer.
String canonicalSyncJson(Object? value) {
  final out = StringBuffer();
  void write(Object? v, int depth) {
    if (depth > syncJsonMaxDepth) invalidSync();
    if (v is Map<String, Object?>) {
      final keys = v.keys.toList()..sort();
      out.write('{');
      for (var i = 0; i < keys.length; ++i) {
        if (i != 0) out.write(',');
        final key = keys[i];
        syncScalarLength(key);
        out.write(jsonEncode(key));
        out.write(':');
        write(v[key], depth + 1);
      }
      out.write('}');
    } else if (v is List<Object?>) {
      out.write('[');
      for (var i = 0; i < v.length; ++i) {
        if (i != 0) out.write(',');
        write(v[i], depth + 1);
      }
      out.write(']');
    } else if (v is String) {
      syncScalarLength(v);
      out.write(jsonEncode(v));
    } else if (v == null || v is bool) {
      out.write(jsonEncode(v));
    } else if (v is int && v.abs() <= syncMaxRevision) {
      out.write(v);
    } else {
      invalidSync();
    }
  }

  write(value, 1);
  return out.toString();
}

Uint8List canonicalSyncBytes(Object? value, {int maxBytes = syncBodyMaxBytes}) {
  final bytes = Uint8List.fromList(utf8.encode(canonicalSyncJson(value)));
  if (bytes.length > maxBytes) invalidSync(SyncValidationFailure.tooLarge);
  return bytes;
}

final class _Reader {
  _Reader(this.text);

  final String text;
  int index = 0;

  void space() {
    while (index < text.length &&
        const [0x20, 0x09, 0x0a, 0x0d].contains(text.codeUnitAt(index))) {
      ++index;
    }
  }

  bool take(String token) {
    if (!text.startsWith(token, index)) return false;
    index += token.length;
    return true;
  }

  Object? value(int depth) {
    if (depth > syncJsonMaxDepth) {
      invalidSync(SyncValidationFailure.invalidJson);
    }
    space();
    if (index >= text.length) invalidSync(SyncValidationFailure.invalidJson);
    if (take('{')) {
      final result = <String, Object?>{};
      space();
      if (take('}')) return result;
      do {
        space();
        final key = string();
        if (result.containsKey(key)) {
          invalidSync(SyncValidationFailure.invalidJson);
        }
        space();
        if (!take(':')) invalidSync(SyncValidationFailure.invalidJson);
        result[key] = value(depth + 1);
        space();
        if (take('}')) return result;
      } while (take(','));
      invalidSync(SyncValidationFailure.invalidJson);
    }
    if (take('[')) {
      final result = <Object?>[];
      space();
      if (take(']')) return result;
      do {
        result.add(value(depth + 1));
        space();
        if (take(']')) return result;
      } while (take(','));
      invalidSync(SyncValidationFailure.invalidJson);
    }
    if (text.codeUnitAt(index) == 0x22) return string();
    if (take('true')) return true;
    if (take('false')) return false;
    if (take('null')) return null;
    final match = _number.matchAsPrefix(text, index);
    if (match == null) invalidSync(SyncValidationFailure.invalidJson);
    index = match.end;
    final decoded = jsonDecode(match[0]!);
    if (decoded is! num || !decoded.isFinite) {
      invalidSync(SyncValidationFailure.invalidJson);
    }
    // JSON Schema integer denotes the value, not a particular spelling.
    if (decoded is double &&
        decoded.abs() <= syncMaxRevision &&
        decoded == decoded.truncateToDouble()) {
      return decoded.toInt();
    }
    return decoded;
  }

  String string() {
    final start = index;
    if (!take('"')) invalidSync(SyncValidationFailure.invalidJson);
    var escaped = false;
    while (index < text.length) {
      final unit = text.codeUnitAt(index++);
      if (unit < 0x20) invalidSync(SyncValidationFailure.invalidJson);
      if (!escaped && unit == 0x22) {
        final decoded = jsonDecode(text.substring(start, index)) as String;
        syncScalarLength(decoded);
        return decoded;
      }
      if (!escaped && unit == 0x5c) {
        escaped = true;
      } else {
        escaped = false;
      }
    }
    invalidSync(SyncValidationFailure.invalidJson);
  }

  static final _number = RegExp(
    r'-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?',
  );
}
