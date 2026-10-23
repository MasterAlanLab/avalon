import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:yaml/yaml.dart';

import '../domain/content.dart';

/// The identity of a downloaded rule set: what is fetched (the address)
/// and how it is read (the format). Configurations may give one name to
/// different addresses, so the tag is not it (DECISIONS O3, D86).
String ruleSetKey(RuleSetRef ref) => ruleSetKeyOf(ref.url, ref.format);

String ruleSetKeyOf(String url, RuleSetFormat format) =>
    '${format.name} ${ruleSetAddressKey(url)}';

/// The cache needs identity, never an address it can fetch. Already obscured
/// addresses remain stable when reading a persisted row.
String ruleSetAddressKey(String url) =>
    RegExp(r'^sha256:[a-f0-9]{64}$').hasMatch(url)
    ? url
    : 'sha256:${sha256.convert(utf8.encode(url))}';

extension RuleSetFormatFile on RuleSetFormat {
  /// The core reads it as is; the others are converted first.
  bool get isSingBox =>
      this == RuleSetFormat.binary || this == RuleSetFormat.source;

  /// The file the core reads: binary `.srs`, or source `.json` (also what
  /// Clash rule providers are converted to).
  String get fileExtension => this == RuleSetFormat.binary ? 'srs' : 'json';
}

/// Why a downloaded rule set cannot be used.
final class RuleSetFormatException implements Exception {
  const RuleSetFormatException(this.message);

  final String message;

  @override
  String toString() => 'RuleSetFormatException($message)';
}

/// A Clash rule provider as a sing-box source rule set (CONFIG_PIPELINE
/// §8): `domain` and `ipcidr` lists, and `classical` rules where sing-box
/// has the matching field. Lines it cannot express are skipped and
/// counted.
({Map<String, Object?> ruleSet, int skipped}) convertClashRuleSet(
  String text,
  RuleSetFormat format,
) {
  final entries = switch (format) {
    RuleSetFormat.clashDomainYaml ||
    RuleSetFormat.clashIpcidrYaml ||
    RuleSetFormat.clashClassicalYaml => _yamlPayload(text),
    RuleSetFormat.clashDomainText ||
    RuleSetFormat.clashIpcidrText ||
    RuleSetFormat.clashClassicalText => _lines(text),
    RuleSetFormat.binary || RuleSetFormat.source => throw ArgumentError(
      'not a Clash rule provider: $format',
    ),
  };
  final fields = <String, List<Object>>{};
  var skipped = 0;
  void add(String field, Object value) => (fields[field] ??= []).add(value);

  bool domain(String entry) {
    // `+.example.com`: the domain and every subdomain. `.example.com`:
    // subdomains only. `*.example.com`: one level of subdomain.
    // `example.com`: that domain.
    if (entry.startsWith('+.')) {
      add('domain_suffix', entry.substring(2));
    } else if (entry.startsWith('.')) {
      add('domain_suffix', entry);
    } else if (entry.startsWith('*.') && !entry.substring(2).contains('*')) {
      add('domain_regex', '^[^.]+${RegExp.escape(entry.substring(1))}\$');
    } else if (entry.contains('*')) {
      return false;
    } else {
      add('domain', entry);
    }
    return true;
  }

  bool cidr(String entry) {
    if (!_isCidr(entry)) return false;
    add('ip_cidr', entry);
    return true;
  }

  for (final entry in entries) {
    final ok = switch (format) {
      RuleSetFormat.clashDomainYaml ||
      RuleSetFormat.clashDomainText => domain(entry),
      RuleSetFormat.clashIpcidrYaml ||
      RuleSetFormat.clashIpcidrText => cidr(entry),
      _ => _classical(entry, add),
    };
    if (!ok) skipped++;
  }

  // Within one sing-box rule, domain fields and address fields must both
  // match; a provider means any of its lines. So each kind is a rule of
  // its own, and the rules of a rule set are alternatives.
  const groups = [
    ['domain', 'domain_suffix', 'domain_keyword', 'domain_regex'],
    ['ip_cidr'],
    ['source_ip_cidr'],
    ['process_name'],
    ['process_path'],
    ['port'],
    ['port_range'],
  ];
  return (
    ruleSet: {
      'version': 2,
      'rules': [
        for (final group in groups)
          if (group.any(fields.containsKey))
            {for (final field in group) field: ?fields[field]},
      ],
    },
    skipped: skipped,
  );
}

bool _classical(String entry, void Function(String, Object) add) {
  final parts = [for (final p in entry.split(',')) p.trim()];
  if (parts.length < 2) return false;
  final value = parts[1];
  switch (parts[0].toUpperCase()) {
    case 'DOMAIN':
      add('domain', value);
    case 'DOMAIN-SUFFIX':
      add('domain_suffix', value);
    case 'DOMAIN-KEYWORD':
      add('domain_keyword', value);
    case 'DOMAIN-REGEX':
      add('domain_regex', value);
    case 'IP-CIDR' || 'IP-CIDR6':
      if (!_isCidr(value)) return false;
      add('ip_cidr', value);
    case 'SRC-IP-CIDR':
      if (!_isCidr(value)) return false;
      add('source_ip_cidr', value);
    case 'PROCESS-NAME':
      add('process_name', value);
    case 'PROCESS-PATH':
      add('process_path', value);
    case 'DST-PORT':
      final range = RegExp(r'^(\d+)-(\d+)$').firstMatch(value);
      final port = int.tryParse(value);
      if (range != null) {
        add('port_range', '${range[1]}:${range[2]}');
      } else if (port != null && port > 0 && port < 65536) {
        add('port', port);
      } else {
        return false;
      }
    default:
      return false;
  }
  return true;
}

bool _isCidr(String value) {
  final slash = value.indexOf('/');
  final address = slash < 0 ? value : value.substring(0, slash);
  if (slash >= 0 && int.tryParse(value.substring(slash + 1)) == null) {
    return false;
  }
  return RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(address) ||
      (address.contains(':') && RegExp(r'^[0-9a-fA-F:.]+$').hasMatch(address));
}

List<String> _yamlPayload(String text) {
  final Object? doc;
  try {
    doc = loadYaml(text);
  } on YamlException catch (e) {
    throw RuleSetFormatException('malformed YAML: ${e.message}');
  }
  final payload = doc is YamlMap ? doc['payload'] : null;
  if (payload is! YamlList) {
    throw const RuleSetFormatException('no payload list');
  }
  return [
    for (final item in payload)
      if (item != null && '$item'.trim().isNotEmpty) '$item'.trim(),
  ];
}

List<String> _lines(String text) => [
  for (final line in text.split('\n'))
    if (line.trim() case final l when l.isNotEmpty && !l.startsWith('#')) l,
];
