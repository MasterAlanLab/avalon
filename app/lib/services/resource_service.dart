import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:av_core/av_core.dart';
import 'package:crypto/crypto.dart';

import '../data/repositories/rule_resource_repository.dart';
import 'download/fetcher.dart';
import 'error_code.dart';

/// Downloads [url] through the running proxy into [destPath], no larger
/// than [maxBytes]. Throws when it cannot.
typedef ProxyDownload =
    Future<void> Function(
      Uri url,
      String destPath,
      int maxBytes, {
      bool publicOnly,
    });

/// What a rule-set update did.
typedef RuleSetUpdate = ({
  /// The error code; null when the download succeeded.
  String? error,

  /// A file the plans already read was replaced by different content: a
  /// running session must reload to use it (D10).
  bool replaced,
});

/// Rule-set files (CONFIG_PIPELINE §8): downloads them directly or
/// through the proxy, checks and converts them, and keeps them in the
/// host's `rulesets/` directory under their SHA-256 for the plans to read.
final class ResourceService {
  ResourceService(
    this._cache,
    this._fetcher, {
    required this.stateDir,
    this.legacyStateDir,
    this.allowPrivateAddresses = false,
  });

  final RuleResourceRepository _cache;
  final Fetcher _fetcher;

  /// The host's directory; the core reads the files from there.
  final Future<String> Function() stateDir;

  /// The application's earlier rule-set directory on iOS. Moving the
  /// host into an App Group must preserve verified downloaded resources,
  /// while the database, vault and old runtime plans remain app-private.
  final Future<String> Function()? legacyStateDir;

  /// Rule-set addresses come from content, which may not reach the local
  /// network (as for providers). Tests serve files from this machine.
  final bool allowPrivateAddresses;

  /// Downloads and [prune] take turns: tidying while a download is under
  /// way would delete its file between being written and being recorded.
  Future<void> _turn = Future.value();

  Future<T> _exclusive<T>(Future<T> Function() work) {
    final result = _turn.then((_) => work());
    _turn = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  /// No rule set is this large; a bigger answer is not one.
  static const maxBytes = 32 * 1024 * 1024;

  final _random = Random.secure();

  Future<Directory> _directory() async {
    final dir = Directory('${await stateDir()}/rulesets');
    await dir.create(recursive: true);
    await _migrateLegacyCache(dir);
    return dir;
  }

  Future<void> _migrateLegacyCache(Directory dir) async {
    final legacy = legacyStateDir;
    if (legacy == null) return;
    final String sourceDir;
    try {
      sourceDir = '${await legacy()}/rulesets';
    } on FileSystemException {
      return;
    }
    if (sourceDir == dir.path) return;
    for (final item in (await _cache.all()).values) {
      final hash = item.sha256;
      final name = item.file;
      // Copy only registered, content-addressed resources; no arbitrary
      // paths, symlinks or other files from the app's support directory.
      if (hash == null ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(hash) ||
          name != '$hash.${item.format.fileExtension}') {
        continue;
      }
      final source = File('$sourceDir/$name');
      final destination = File('${dir.path}/$name');
      final temp = File('${dir.path}/.$name.migrating');
      try {
        if (destination.existsSync() ||
            await FileSystemEntity.type(source.path, followLinks: false) !=
                FileSystemEntityType.file ||
            await source.length() > maxBytes) {
          continue;
        }
        final bytes = await source.readAsBytes();
        if (bytes.length > maxBytes ||
            sha256.convert(bytes).toString() != hash) {
          continue;
        }
        await temp.writeAsBytes(bytes, flush: true);
        await temp.rename(destination.path);
      } on FileSystemException {
        // An unavailable or damaged cache is downloaded again normally.
      } finally {
        try {
          if (temp.existsSync()) await temp.delete();
        } on FileSystemException {
          // A hidden partial migration is never used by the core.
        }
      }
    }
  }

  /// Downloads [ref] (through [throughProxy] when given) and keeps it. A
  /// failure is recorded with its code; what was downloaded before stays.
  Future<RuleSetUpdate> update(
    RuleSetRef ref, {
    ProxyDownload? throughProxy,
    bool cloudSource = false,
  }) => _exclusive(() => _update(ref, throughProxy, cloudSource));

  Future<RuleSetUpdate> _update(
    RuleSetRef ref,
    ProxyDownload? throughProxy,
    bool cloudSource,
  ) async {
    final Directory dir;
    try {
      dir = await _directory();
    } on FileSystemException {
      await _cache.failed(ref, 'resource.storage');
      return (error: 'resource.storage', replaced: false);
    }
    String code;
    try {
      final Uint8List bytes;
      if (throughProxy == null) {
        bytes = (await _fetcher.get(
          Uri.parse(ref.url),
          allowPrivate: allowPrivateAddresses,
          cloudSource: cloudSource,
        )).bytes;
      } else {
        final temp = File('${dir.path}/.download-${_random.nextInt(1 << 32)}');
        try {
          await throughProxy(
            Uri.parse(ref.url),
            temp.path,
            maxBytes,
            publicOnly: cloudSource,
          );
          bytes = await temp.readAsBytes();
        } finally {
          if (temp.existsSync()) await temp.delete();
        }
      }
      final (data, skipped) = prepare(ref.format, bytes);
      final sha = sha256.convert(data).toString();
      final name = '$sha.${ref.format.fileExtension}';
      final file = File('${dir.path}/$name');
      if (!file.existsSync()) {
        // Hidden while written, like the downloads: [prune] passes over it.
        final temp = File('${dir.path}/.$name.tmp');
        await temp.writeAsBytes(data, flush: true);
        await temp.rename(file.path);
      }
      final before = (await _cache.all())[ruleSetKey(ref)]?.file;
      await _cache.saved(
        ref,
        file: name,
        sha256: sha,
        size: data.length,
        skipped: skipped,
      );
      return (error: null, replaced: before != null && before != name);
    } on FetchException catch (e) {
      code = errorCode(e);
    } on RuleSetFormatException {
      code = 'resource.format';
    } on FormatException {
      code = 'resource.format';
    } on FileSystemException {
      code = 'resource.storage';
    } on Exception {
      // The proxy could not download it (the host said why in its log).
      code = 'resource.proxy';
    }
    await _cache.failed(ref, code);
    return (error: code, replaced: false);
  }

  /// Checks a download and turns it into what the core reads: binary and
  /// source rule sets as they are, Clash providers converted to source.
  static (Uint8List data, int skipped) prepare(
    RuleSetFormat format,
    Uint8List bytes,
  ) {
    switch (format) {
      case RuleSetFormat.binary:
        // `SRS`, then the format version.
        if (bytes.length < 4 ||
            bytes[0] != 0x53 ||
            bytes[1] != 0x52 ||
            bytes[2] != 0x53) {
          throw const RuleSetFormatException('not a binary rule set');
        }
        return (bytes, 0);
      case RuleSetFormat.source:
        final doc = jsonDecode(utf8.decode(bytes));
        if (doc is! Map || doc['rules'] is! List || doc['version'] is! int) {
          throw const RuleSetFormatException('not a source rule set');
        }
        return (bytes, 0);
      default:
        final (:ruleSet, :skipped) = convertClashRuleSet(
          utf8.decode(bytes, allowMalformed: true),
          format,
        );
        return (Uint8List.fromList(utf8.encode(jsonEncode(ruleSet))), skipped);
    }
  }

  /// The files the core can read now, by [ruleSetKey], as paths.
  Future<Map<String, String>> cachedPaths() => _exclusive(() async {
    final dir = legacyStateDir == null
        ? '${await stateDir()}/rulesets'
        : (await _directory()).path;
    return {
      for (final item in (await _cache.all()).values)
        if (item.file case final file?)
          if (File('$dir/$file').existsSync()) item.key: '$dir/$file',
    };
  });

  /// Of [refs], those with no file yet.
  Future<List<RuleSetRef>> missing(Iterable<RuleSetRef> refs) async {
    final cached = await cachedPaths();
    return [
      for (final ref in refs)
        if (!cached.containsKey(ruleSetKey(ref))) ref,
    ];
  }

  /// Deletes files no cache entry points at any more. Called once a
  /// session started or reloaded with the current files: until then the
  /// running core may still read an older one (CONFIG_PIPELINE §8).
  Future<void> prune() => _exclusive(_prune);

  Future<void> _prune() async {
    final Directory dir;
    try {
      dir = await _directory();
    } on FileSystemException {
      return;
    }
    final kept = {for (final item in (await _cache.all()).values) ?item.file};
    try {
      await for (final entry in dir.list()) {
        final name = entry.uri.pathSegments.last;
        if (entry is File && !name.startsWith('.') && !kept.contains(name)) {
          await entry.delete();
        }
      }
    } on FileSystemException {
      // Gone or unreadable meanwhile: nothing to tidy.
    }
  }
}
