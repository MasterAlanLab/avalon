import 'dart:convert';
import 'dart:isolate';

import 'package:av_core/av_core.dart';
import 'package:crypto/crypto.dart';

import '../data/repositories/configuration_repository.dart';
import 'download/fetcher.dart';
import 'error_code.dart';

final class ImportResult {
  const ImportResult(this.configurationId, this.warnings);

  final String configurationId;

  /// Shown after saving (PRODUCT_SPEC §3.5).
  final List<ImportWarning> warnings;
}

/// The outcome of a refresh.
enum RefreshOutcome { updated, unchanged, discarded }

/// Adding and refreshing subscriptions and files (PRODUCT_SPEC §3.5,
/// CONFIG_PIPELINE §2–3). Parsing runs off the UI isolate. Throws
/// [FetchException] or [ImportException]; nothing is saved on failure or
/// cancellation.
final class ImportService {
  ImportService(this._configs, this._fetcher);

  final ConfigurationRepository _configs;
  final Fetcher _fetcher;

  Future<ImportResult> addSubscription({
    required String url,
    required String defaultName,
    String? name,
    Map<String, String> headers = const {},
    bool autoUpdate = true,
    FetchCancel? cancel,
  }) async {
    final uri = _validUrl(url);
    final fetched = await _fetcher.get(uri, headers: headers, cancel: cancel);
    final parsed = await _parse(
      fetched.text,
      originPrivate: fetched.privateOrigin,
      cancel: cancel,
    );
    _checkCancelled(cancel);
    final id = await _configs.add(
      kind: ConfigurationKind.subscription,
      name: _name(name, fetched.title, fetched.fileName, defaultName),
      parsed: parsed,
      digest: _digest(fetched.text),
      source: SubscriptionSource(
        url: Secret(url.trim()),
        headers: {for (final e in headers.entries) e.key: Secret(e.value)},
      ),
      usage: fetched.usage,
      autoUpdate: autoUpdate,
    );
    return ImportResult(id, parsed.content.warnings);
  }

  /// A local `.json` or `.yaml` file. Providers it references are
  /// downloaded, never from private addresses.
  /// A local file larger than this is refused, as a download would be.
  static const maxFileBytes = 16 * 1024 * 1024;

  /// The text of a local file: UTF-8, with a leading byte-order mark
  /// dropped. Throws [ImportException] for anything else.
  static String decodeText(List<int> bytes) {
    final start =
        bytes.length >= 3 &&
            bytes[0] == 0xEF &&
            bytes[1] == 0xBB &&
            bytes[2] == 0xBF
        ? 3
        : 0;
    try {
      return utf8.decode(bytes.sublist(start));
    } on FormatException {
      throw const ImportException(ImportErrorCode.malformed);
    }
  }

  Future<ImportResult> addFile({
    required String text,
    required String defaultName,
    String? name,
    String? fileName,
    FetchCancel? cancel,
  }) async {
    final parsed = await _parse(text, originPrivate: false, cancel: cancel);
    _checkCancelled(cancel);
    final base = fileName == null
        ? null
        : fileName.contains('.')
        ? fileName.substring(0, fileName.lastIndexOf('.'))
        : fileName;
    final id = await _configs.add(
      kind: ConfigurationKind.file,
      name: _name(name, null, base, defaultName),
      parsed: parsed,
      digest: _digest(text),
      autoUpdate: false,
    );
    return ImportResult(id, parsed.content.warnings);
  }

  /// Saves an edited subscription, then downloads it once (PRODUCT_SPEC
  /// §3.4). The edit stays saved even when that download fails; the
  /// failure is recorded on the card as for any refresh.
  Future<void> updateSubscription(
    String id, {
    required String url,
    String? name,
    required bool autoUpdate,
    DateTime? ifEditedAt,
    FetchCancel? cancel,
  }) async {
    _validUrl(url);
    final old = await _configs.source(id);
    final changed = old?.url.value != url.trim();
    await _configs.update(
      id,
      name: name,
      autoUpdate: autoUpdate,
      // Headers belong to the link; a new link starts without them.
      source: changed ? SubscriptionSource(url: Secret(url.trim())) : null,
      ifEditedAt: ifEditedAt,
    );
    try {
      await refresh(id, cancel: cancel);
    } on FetchException {
      // Recorded on the card by refresh().
    } on ImportException {
      // Recorded on the card by refresh().
    }
  }

  /// Downloads a subscription again. Failures are recorded on the card and
  /// rethrown; the old content stays (CONFIG_PIPELINE §2).
  Future<RefreshOutcome> refresh(String id, {FetchCancel? cancel}) async {
    final snapshot = await _configs.sourceSnapshot(id);
    if (snapshot == null) return RefreshOutcome.discarded;
    final source = snapshot.source;
    final expected = snapshot.sourceSecretId;
    try {
      final uri = _validUrl(source.url.value);
      final fetched = await _fetcher.get(
        uri,
        headers: {for (final e in source.headers.entries) e.key: e.value.value},
        allowPrivate: !snapshot.cloudSource,
        cloudSource: snapshot.cloudSource,
        cancel: cancel,
      );
      final digest = _digest(fetched.text);
      if ((await _configs.content(id))?.digest == digest) {
        final saved = await _configs.markRefreshed(
          id,
          usage: fetched.usage,
          expectedSourceSecretId: expected,
          checkSource: true,
        );
        return saved ? RefreshOutcome.unchanged : RefreshOutcome.discarded;
      }
      final parsed = await _parse(
        fetched.text,
        originPrivate: fetched.privateOrigin,
        cloudSource: snapshot.cloudSource,
        cancel: cancel,
      );
      _checkCancelled(cancel);
      final saved = await _configs.replaceContent(
        id,
        expectedSourceSecretId: expected,
        parsed: parsed,
        digest: digest,
        usage: fetched.usage,
      );
      return saved ? RefreshOutcome.updated : RefreshOutcome.discarded;
    } on FetchException catch (e) {
      if (e.code != FetchErrorCode.cancelled) {
        await _configs.recordFailure(
          id,
          errorCode(e),
          expectedSourceSecretId: expected,
          checkSource: true,
        );
      }
      rethrow;
    } on ImportException catch (e) {
      await _configs.recordFailure(
        id,
        errorCode(e),
        expectedSourceSecretId: expected,
        checkSource: true,
      );
      rethrow;
    }
  }

  Future<ParsedContent> _parse(
    String text, {
    required bool originPrivate,
    bool cloudSource = false,
    FetchCancel? cancel,
  }) async {
    final providers = await Isolate.run(() => providersOf(text));
    final texts = <String, String>{};
    for (final e in providers.entries) {
      _checkCancelled(cancel);
      final url = Uri.tryParse(e.value);
      if (url == null) {
        throw ImportException(
          ImportErrorCode.invalidField,
          field: 'proxy-providers.${e.key}.url',
        );
      }
      // Any provider failing fails the whole import (CONFIG_PIPELINE §2).
      texts[e.key] = (await _fetcher.get(
        url,
        allowPrivate: originPrivate,
        cloudSource: cloudSource,
        cancel: cancel,
      )).text;
    }
    _checkCancelled(cancel);
    return Isolate.run(() => parseContent(text, providers: texts));
  }

  static Uri _validUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null ||
        !(uri.isScheme('http') || uri.isScheme('https')) ||
        uri.host.isEmpty) {
      throw const FetchException(FetchErrorCode.invalidUrl);
    }
    return uri;
  }

  static void _checkCancelled(FetchCancel? cancel) {
    if (cancel?.isCancelled ?? false) {
      throw const FetchException(FetchErrorCode.cancelled);
    }
  }

  static String _name(
    String? entered,
    String? title,
    String? fileName,
    String fallback,
  ) {
    for (final n in [entered, title, fileName]) {
      if (n != null && n.trim().isNotEmpty) return n.trim();
    }
    return fallback;
  }

  static String _digest(String text) =>
      sha256.convert(utf8.encode(text)).toString();
}
