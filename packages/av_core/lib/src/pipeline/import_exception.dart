/// Why an import, share link or override was rejected. The app maps [code]
/// to localized text; [field] names the parameter or path. Messages never
/// contain secrets.
enum ImportErrorCode {
  /// Not a share link of a supported protocol.
  unsupportedScheme,

  /// The text cannot be read at all (bad URI, Base64 or JSON).
  malformed,
  missingField,
  invalidField,

  /// A parameter Avalon does not know; nothing is guessed or dropped.
  unknownParameter,

  /// A known parameter with a value Avalon cannot express.
  unsupportedValue,

  /// Content is none of sing-box JSON, Clash YAML or a link list.
  unknownFormat,

  /// Over a size, depth or count limit (CONFIG_PIPELINE §3).
  tooLarge,
}

final class ImportException implements Exception {
  const ImportException(this.code, {this.field, this.detail});

  final ImportErrorCode code;

  /// Parameter name or path, e.g. `type` or `proxies[3].cipher`.
  final String? field;

  /// Non-secret extra context, e.g. the unsupported value.
  final String? detail;

  @override
  String toString() =>
      'ImportException(${code.name}'
      '${field == null ? '' : ', $field'}'
      '${detail == null ? '' : ': $detail'})';
}
