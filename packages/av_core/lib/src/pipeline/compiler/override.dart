import 'dart:convert';

import 'plan.dart';

/// A validated JSON override (D19, CONFIG_PIPELINE §5).
final class OverrideDoc {
  const OverrideDoc({
    this.outbounds = const [],
    this.routeRules = const [],
    this.ruleSets = const [],
    this.routeFinal,
    this.dnsServers = const [],
    this.dnsRules = const [],
  });

  static const empty = OverrideDoc();

  final List<Map<String, Object?>> outbounds;
  final List<Map<String, Object?>> routeRules;
  final List<Map<String, Object?>> ruleSets;
  final String? routeFinal;
  final List<Map<String, Object?>> dnsServers;
  final List<Map<String, Object?>> dnsRules;
}

CompileException _invalid(String path, [String detail = '']) =>
    CompileException(
      CompileErrorCode.overrideInvalid,
      subject: path,
      detail: detail,
    );

/// Checks syntax, the allowed keys and field types; run when saving. Names
/// the override refers to are resolved when compiling.
OverrideDoc parseOverride(String text) {
  if (text.trim().isEmpty) return OverrideDoc.empty;
  final Object? root;
  try {
    root = jsonDecode(text);
  } on FormatException catch (e) {
    throw _invalid(r'$', 'offset ${e.offset ?? 0}');
  }
  if (root is! Map<String, Object?>) throw _invalid(r'$', 'object');

  void only(Map<String, Object?> m, Set<String> keys, String path) {
    for (final k in m.keys) {
      if (!keys.contains(k)) throw _invalid('$path.$k', 'not allowed');
    }
  }

  Map<String, Object?>? object(
    Map<String, Object?> m,
    String key,
    String path,
  ) {
    final v = m[key];
    if (v == null) return null;
    if (v is Map<String, Object?>) return v;
    throw _invalid('$path.$key', 'object');
  }

  List<Map<String, Object?>> objects(
    Map<String, Object?>? m,
    String key,
    String path, {
    bool tagged = false,
  }) {
    final v = m?[key];
    if (v == null) return const [];
    if (v is! List) throw _invalid('$path.$key', 'array');
    return [
      for (final (i, e) in v.indexed)
        if (e is Map<String, Object?> &&
            (!tagged ||
                (e['tag'] is String && (e['tag']! as String).isNotEmpty)))
          e
        else
          throw _invalid(
            '$path.$key[$i]',
            tagged ? 'object with tag' : 'object',
          ),
    ];
  }

  only(root, {'outbounds', 'route', 'dns'}, r'$');
  final route = object(root, 'route', r'$');
  final dns = object(root, 'dns', r'$');
  if (route != null) only(route, {'rules', 'rule_set', 'final'}, r'$.route');
  if (dns != null) only(dns, {'servers', 'rules'}, r'$.dns');
  final fin = route?['final'];
  if (fin != null && fin is! String) throw _invalid(r'$.route.final', 'string');

  return OverrideDoc(
    outbounds: objects(root, 'outbounds', r'$', tagged: true),
    routeRules: objects(route, 'rules', r'$.route'),
    ruleSets: objects(route, 'rule_set', r'$.route', tagged: true),
    routeFinal: fin as String?,
    dnsServers: objects(dns, 'servers', r'$.dns', tagged: true),
    dnsRules: objects(dns, 'rules', r'$.dns'),
  );
}

/// Rewrites outbound references in override objects from display names to
/// generated tags. [resolve] returns null for unknown names.
Map<String, Object?> rewriteReferences(
  Map<String, Object?> o,
  String path,
  String? Function(String name) resolve,
) {
  String map(String name, String at) =>
      resolve(name) ??
      (throw CompileException(
        CompileErrorCode.overrideReference,
        subject: name,
        detail: at,
      ));

  final out = Map<String, Object?>.of(o);
  for (final key in const ['outbound', 'detour', 'download_detour']) {
    final v = out[key];
    if (v is String) out[key] = map(v, '$path.$key');
  }
  final list = out['outbounds'];
  if (list is List) {
    out['outbounds'] = [
      for (final (i, n) in list.indexed)
        n is String ? map(n, '$path.outbounds[$i]') : n,
    ];
  }
  final def = out['default'];
  if (def is String && out['type'] == 'selector') {
    out['default'] = map(def, '$path.default');
  }
  return out;
}
