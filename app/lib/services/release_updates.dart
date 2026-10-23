import 'dart:convert';

import 'download/fetcher.dart';

/// These are public project pages, never account or device endpoints.
final projectSource = Uri.parse(
  'https://github.com/MasterAlanLab/avalon/tree/main',
);
final projectReleases = Uri.parse(
  'https://github.com/MasterAlanLab/avalon/releases',
);
final projectPrivacy = Uri.parse('https://getavalon.app/legal/privacy-policy');

enum UpdateResultKind { available, current, noRelease }

final class ReleaseUpdate {
  const ReleaseUpdate(this.kind, {this.version, this.page});
  final UpdateResultKind kind;
  final String? version;
  final Uri? page;
}

/// Only releases carrying the current client's manifest qualify. An old
/// implementation's numerically higher version is never offered as an update.
final class ReleaseUpdates {
  ReleaseUpdates({required this.platform, Future<String> Function(Uri)? read})
    : _read = read ?? _fetch;

  final Future<String> Function(Uri) _read;
  final String platform;
  static final _endpoint = Uri.parse(
    'https://api.github.com/repos/MasterAlanLab/avalon/releases?per_page=20',
  );

  static Future<String> _fetch(Uri uri) async => (await Fetcher(
    userAgent: 'Avalon update check',
    maxBytes: uri.host == 'api.github.com' ? 512 * 1024 : 16384,
    totalTimeout: const Duration(seconds: 20),
  ).get(uri, allowPrivate: false, cloudSource: true)).text;

  Future<ReleaseUpdate> check(String installedVersion) async {
    final installed = _version(installedVersion);
    if (installed == null) {
      throw const FormatException('Invalid installed version');
    }
    final decoded = jsonDecode(await _read(_endpoint));
    if (decoded is! List<dynamic>) {
      throw const FormatException('Invalid release list');
    }
    ReleaseUpdate? candidate;
    List<int>? newest;
    for (final item in decoded.take(20)) {
      if (item is! Map<String, dynamic> ||
          item['draft'] != false ||
          item['prerelease'] != false) {
        continue;
      }
      final page = Uri.tryParse(
        item['html_url'] is String ? item['html_url'] as String : '',
      );
      if (page == null || !_releasePage(page)) continue;
      final assets = item['assets'];
      if (assets is! List<dynamic>) continue;
      for (final asset in assets) {
        if (asset is! Map<String, dynamic> ||
            asset['name'] != 'avalon-client-release.json') {
          continue;
        }
        final size = asset['size'];
        final raw = asset['browser_download_url'];
        if (size is! int || size < 1 || size > 16384 || raw is! String) {
          throw const FormatException('Invalid release manifest');
        }
        final manifestUrl = Uri.tryParse(raw);
        if (manifestUrl == null || !_assetUrl(manifestUrl, page)) {
          throw const FormatException('Untrusted release manifest');
        }
        final rawManifest = await _read(manifestUrl);
        if (utf8.encode(rawManifest).length > 16384) {
          throw const FormatException('Release manifest exceeds limit');
        }
        final manifest = jsonDecode(rawManifest);
        if (manifest is! Map<String, dynamic> ||
            manifest['schema'] != 1 ||
            manifest['application'] != 'app.getavalon.avalon' ||
            manifest['engine'] != 'sing-box' ||
            manifest['hostProtocol'] != 1) {
          throw const FormatException('Incompatible release manifest');
        }
        final version = manifest['version'];
        final platforms = manifest['platforms'];
        if (platforms is! List<dynamic> || platforms.any((v) => v is! String)) {
          throw const FormatException('Invalid release platforms');
        }
        if (!platforms.contains(platform)) continue;
        final parsed = version is String ? _version(version) : null;
        if (parsed == null || item['tag_name'] != 'v$version') {
          throw const FormatException('Invalid release version');
        }
        if (newest == null || _compare(parsed, newest) > 0) {
          newest = parsed;
          candidate = ReleaseUpdate(
            _compare(parsed, installed) > 0
                ? UpdateResultKind.available
                : UpdateResultKind.current,
            version: version as String,
            page: page,
          );
        }
      }
    }
    return candidate ?? const ReleaseUpdate(UpdateResultKind.noRelease);
  }

  static bool _trustedGithub(Uri uri) =>
      uri.scheme == 'https' &&
      uri.host == 'github.com' &&
      uri.port == 443 &&
      uri.userInfo.isEmpty &&
      !uri.hasQuery &&
      !uri.hasFragment;

  static bool _releasePage(Uri uri) =>
      _trustedGithub(uri) &&
      RegExp(
        r'^/MasterAlanLab/avalon/releases/tag/v[0-9]+\.[0-9]+\.[0-9]+$',
      ).hasMatch(uri.path);

  static bool _assetUrl(Uri uri, Uri page) =>
      _trustedGithub(uri) &&
      uri.path ==
          '/MasterAlanLab/avalon/releases/download/${page.pathSegments.last}/avalon-client-release.json';

  static List<int>? _version(String value) {
    if (!RegExp(
      r'^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$',
    ).hasMatch(value)) {
      return null;
    }
    final values = value.split('.').map(int.tryParse).toList();
    return values.any((v) => v == null) ? null : values.cast<int>();
  }

  static int _compare(List<int> left, List<int> right) {
    for (var i = 0; i < 3; i++) {
      final result = left[i].compareTo(right[i]);
      if (result != 0) return result;
    }
    return 0;
  }
}
