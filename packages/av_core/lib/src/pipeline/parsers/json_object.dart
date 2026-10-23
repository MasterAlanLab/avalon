import '../import_exception.dart';

/// Typed reads from a decoded JSON/YAML map, with the path in errors and a
/// record of which keys were read (to find options Avalon does not know).
final class JsonObject {
  JsonObject(this.map, this.path);

  final Map<String, Object?> map;
  final String path;
  final _read = <String>{};

  ImportException invalid(String key) =>
      ImportException(ImportErrorCode.invalidField, field: '$path.$key');

  bool has(String key) => map.containsKey(key);

  /// Strings, numbers and booleans read as text; empty reads as null.
  String? str(String key) {
    _read.add(key);
    final v = map[key];
    if (v == null) return null;
    if (v is String) return v.trim().isEmpty ? null : v.trim();
    if (v is num || v is bool) return '$v';
    throw invalid(key);
  }

  int? integer(String key) {
    _read.add(key);
    final v = map[key];
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) {
      final n = int.tryParse(v.trim());
      if (n != null) return n;
    }
    throw invalid(key);
  }

  bool flag(String key) {
    _read.add(key);
    final v = map[key];
    if (v == null) return false;
    if (v is bool) return v;
    if (v is String) return const {'true', '1', 'yes'}.contains(v.trim());
    if (v is num) return v != 0;
    throw invalid(key);
  }

  /// A string or a list of strings.
  List<String> strings(String key) {
    _read.add(key);
    final v = map[key];
    if (v == null) return const [];
    if (v is String) return v.trim().isEmpty ? const [] : [v.trim()];
    if (v is List) {
      return [
        for (final e in v)
          if (e is String || e is num) '$e'.trim() else throw invalid(key),
      ];
    }
    throw invalid(key);
  }

  JsonObject? object(String key) {
    _read.add(key);
    final v = map[key];
    if (v == null) return null;
    if (v is Map) {
      return JsonObject({
        for (final e in v.entries) '${e.key}': e.value,
      }, '$path.$key');
    }
    throw invalid(key);
  }

  List<Object?> list(String key) {
    _read.add(key);
    final v = map[key];
    if (v == null) return const [];
    if (v is List) return v;
    throw invalid(key);
  }

  /// Marks keys as handled without reading them.
  void ignore(Iterable<String> keys) => _read.addAll(keys);

  /// Keys present but never read or ignored.
  Iterable<String> get unread => map.keys.where((k) => !_read.contains(k));
}

/// Parses Go-style durations such as `3m`, `1m30s` or `180` (seconds).
int? durationSeconds(String? text) {
  if (text == null) return null;
  final plain = int.tryParse(text);
  if (plain != null) return plain;
  final parts = RegExp(r'(\d+(?:\.\d+)?)(h|ms|m|s)').allMatches(text);
  if (parts.isEmpty || parts.map((m) => m.group(0)).join() != text) {
    return null;
  }
  var seconds = 0.0;
  for (final m in parts) {
    final n = double.parse(m.group(1)!);
    seconds += switch (m.group(2)) {
      'h' => n * 3600,
      'm' => n * 60,
      's' => n,
      _ => n / 1000,
    };
  }
  return seconds.round();
}
