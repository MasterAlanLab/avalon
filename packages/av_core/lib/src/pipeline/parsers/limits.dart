import 'dart:convert';

import 'package:yaml/yaml.dart';

import '../import_exception.dart';

/// Input limits (CONFIG_PIPELINE §3).
abstract final class ImportLimits {
  static const maxChars = 16 * 1024 * 1024;
  static const maxJsonDepth = 64;
  static const maxYamlNodes = 200000;
  static const maxNodes = 5000;
  static const maxGroups = 500;
  static const maxRules = 50000;
}

ImportException _tooLarge(String what) =>
    ImportException(ImportErrorCode.tooLarge, field: what);

/// Decodes a JSON object, enforcing the depth limit. Null when [text] is
/// not JSON or not an object.
Map<String, Object?>? decodeJsonObject(String text) {
  final Object? value;
  try {
    value = jsonDecode(text);
  } on FormatException {
    return null;
  }
  if (value is! Map<String, Object?>) return null;
  // Iterative walk: the decoder itself is not recursive, keep it that way.
  final stack = <(Object?, int)>[(value, 1)];
  while (stack.isNotEmpty) {
    final (v, depth) = stack.removeLast();
    if (depth > ImportLimits.maxJsonDepth) throw _tooLarge('depth');
    if (v is Map) {
      for (final c in v.values) {
        stack.add((c, depth + 1));
      }
    } else if (v is List) {
      for (final c in v) {
        stack.add((c, depth + 1));
      }
    }
  }
  return value;
}

/// YAML tags (`!foo`, `!!python/object`) at the start of a value. The YAML
/// library does not expose tags, and Avalon accepts none.
final _tag = RegExp(r'^\s*(?:-\s+)*(?:[^\s#][^#\n]*?:\s+)?!', multiLine: true);

/// Decodes a YAML mapping into plain maps and lists. Aliases are expanded
/// while counting, so a "billion laughs" document stops at the node limit.
/// Null when [text] is not YAML or not a mapping.
Map<String, Object?>? decodeYamlMap(String text) {
  if (_tag.hasMatch(text)) {
    throw const ImportException(ImportErrorCode.malformed, field: 'yaml tag');
  }
  final Object? doc;
  try {
    doc = loadYaml(text);
  } on YamlException {
    return null;
  }
  if (doc is! Map) return null;
  var count = 0;
  Object? plain(Object? v) {
    if (++count > ImportLimits.maxYamlNodes) throw _tooLarge('yaml nodes');
    if (v is Map) {
      return <String, Object?>{
        for (final e in v.entries) '${e.key}': plain(e.value),
      };
    }
    if (v is List) return [for (final e in v) plain(e)];
    return v;
  }

  return plain(doc)! as Map<String, Object?>;
}
