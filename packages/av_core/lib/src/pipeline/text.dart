import 'dart:convert';

/// Decodes standard or URL-safe Base64, with or without padding, ignoring
/// whitespace. Throws [FormatException] when the input is not Base64.
List<int> decodeBase64Loose(String input) {
  var s = input.replaceAll(RegExp(r'\s'), '');
  s = s.replaceAll('-', '+').replaceAll('_', '/');
  if (s.length % 4 == 1) throw const FormatException('bad Base64 length');
  return base64.decode(s.padRight((s.length + 3) ~/ 4 * 4, '='));
}

/// Percent-decodes [s], keeping it unchanged when the escapes are invalid.
/// Unlike query decoding, `+` stays `+` (passwords in links use it).
String percentDecode(String s) {
  try {
    return Uri.decodeComponent(s);
  } on ArgumentError {
    return s;
  }
}
