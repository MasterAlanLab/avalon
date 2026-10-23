import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'layout.dart';

/// Source version used in backups and user agents. The actual installed
/// version and build number come from the native package metadata.
const appVersion = '2.0.0';
const appBuild = '1';

final installedBuildProvider = FutureProvider<PackageInfo>(
  (ref) => PackageInfo.fromPlatform(),
);

/// Store IDs are configured only for the actual signed distribution.
/// Unknown channels never fall back to another channel's update source.
({bool direct, Uri? store}) updateChannel(
  PackageInfo build,
  AppPlatform platform, {
  String channel = const String.fromEnvironment(
    'AVALON_DISTRIBUTION_CHANNEL',
    defaultValue: 'direct',
  ),
  String appleUrl = const String.fromEnvironment('AVALON_APP_STORE_URL'),
}) {
  final apple =
      channel == 'apple' ||
      (platform == AppPlatform.ios &&
          {'com.apple', 'com.apple.testflight'}.contains(build.installerStore));
  if (apple) {
    final uri = Uri.tryParse(appleUrl);
    final valid =
        uri != null &&
        uri.scheme == 'https' &&
        uri.host == 'apps.apple.com' &&
        uri.port == 443 &&
        uri.userInfo.isEmpty &&
        !uri.hasQuery &&
        !uri.hasFragment &&
        RegExp(r'^/(?:[a-z]{2}/)?app/(?:[^/]+/)?id[0-9]+$').hasMatch(uri.path);
    return (direct: false, store: valid ? uri : null);
  }
  if (channel == 'google' || build.installerStore == 'com.android.vending') {
    return (
      direct: false,
      store: build.packageName == 'app.getavalon.avalon'
          ? Uri.https('play.google.com', '/store/apps/details', {
              'id': build.packageName,
            })
          : null,
    );
  }
  return (direct: channel == 'direct', store: null);
}
