import 'dart:convert';

import '../../domain/content.dart';
import '../import_exception.dart';
import '../text.dart';
import 'clash.dart';
import 'limits.dart';
import 'singbox.dart';
import 'uri_list.dart';

enum ContentFormat { singBox, clash, linkList }

final class ParsedContent {
  const ParsedContent(this.format, this.content);

  final ContentFormat format;
  final ConfigContent content;
}

/// Clash proxy providers to download, by name, before [parseContent]; empty
/// for other formats.
Map<String, String> providersOf(String text) {
  final t = _clean(text);
  if (t.startsWith('{') && decodeJsonObject(t)?['outbounds'] != null) {
    return const {};
  }
  if (_linkList(t) != null) return const {};
  final doc = decodeYamlMap(t);
  return doc == null ? const {} : clashProviderUrls(doc);
}

/// Recognizes and parses subscription or file content (CONFIG_PIPELINE §3):
/// sing-box JSON, a share-link list (optionally Base64) or Clash YAML. The
/// file name and Content-Type are only hints and are not consulted.
/// [providers] holds the downloaded text of [providersOf]'s providers.
ParsedContent parseContent(
  String text, {
  Map<String, String> providers = const {},
}) {
  if (text.length > ImportLimits.maxChars) {
    throw const ImportException(ImportErrorCode.tooLarge, field: 'size');
  }
  final t = _clean(text);

  if (t.startsWith('{')) {
    final json = decodeJsonObject(t);
    if (json != null && json.containsKey('outbounds')) {
      return _checked(ContentFormat.singBox, parseSingBox(json));
    }
  }

  final lines = _linkList(t);
  if (lines != null) {
    return _checked(ContentFormat.linkList, parseLinkList(lines));
  }

  final yaml = decodeYamlMap(t);
  if (yaml != null &&
      (yaml.containsKey('proxies') || yaml.containsKey('proxy-providers'))) {
    return _checked(
      ContentFormat.clash,
      parseClash(yaml, providerTexts: providers),
    );
  }
  throw const ImportException(ImportErrorCode.unknownFormat);
}

String _clean(String text) =>
    (text.startsWith('﻿') ? text.substring(1) : text).trim();

final _base64Text = RegExp(r'^[A-Za-z0-9+/=_\-\s]+$');

List<String>? _linkList(String t) {
  final plain = linkLines(t);
  if (plain != null) return plain;
  if (!_base64Text.hasMatch(t)) return null;
  try {
    return linkLines(utf8.decode(decodeBase64Loose(t)));
  } on FormatException {
    return null;
  }
}

ParsedContent _checked(ContentFormat format, ConfigContent c) {
  void limit(int n, int max, String what) {
    if (n > max) {
      throw ImportException(
        ImportErrorCode.tooLarge,
        field: what,
        detail: '$n',
      );
    }
  }

  limit(c.nodes.length, ImportLimits.maxNodes, 'nodes');
  limit(c.groups.length, ImportLimits.maxGroups, 'groups');
  limit(c.rules.length, ImportLimits.maxRules, 'rules');
  return ParsedContent(format, c);
}
