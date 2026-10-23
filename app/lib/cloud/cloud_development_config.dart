import 'package:flutter/foundation.dart';

/// Explicit development opt-in while full C1 is unfinished. Release builds
/// never construct Cloud services, even when both defines were supplied.
final class CloudDevelopmentConfig {
  CloudDevelopmentConfig({required this.baseUri, this.syncProtocolVersion = 1});

  final Uri baseUri;
  final int syncProtocolVersion;

  static CloudDevelopmentConfig? fromBuild({
    bool release = kReleaseMode,
    bool enabled = const bool.fromEnvironment('AVALON_CLOUD_PREVIEW'),
    String baseUrl = const String.fromEnvironment('AVALON_CLOUD_BASE_URL'),
    int syncProtocolVersion = const int.fromEnvironment(
      'AVALON_CLOUD_SYNC_VERSION',
      defaultValue: 1,
    ),
  }) {
    if (release || !enabled || baseUrl.trim().isEmpty) return null;
    if (syncProtocolVersion != 1 && syncProtocolVersion != 2) return null;
    final uri = Uri.tryParse(baseUrl.trim());
    if (uri == null ||
        !uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        (uri.scheme != 'https' &&
            !(uri.scheme == 'http' &&
                ['localhost', '127.0.0.1', '::1'].contains(uri.host)))) {
      return null;
    }
    return CloudDevelopmentConfig(
      baseUri: uri,
      syncProtocolVersion: syncProtocolVersion,
    );
  }
}
