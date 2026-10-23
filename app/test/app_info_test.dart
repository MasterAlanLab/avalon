import 'package:avalon/app/app_info.dart';
import 'package:avalon/app/layout.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  test('store channels use trusted store destinations without fallback', () {
    PackageInfo build({
      String? installer,
      String package = 'app.getavalon.avalon',
    }) => PackageInfo(
      appName: 'Avalon',
      packageName: package,
      version: '0.1.0',
      buildNumber: '4014',
      installerStore: installer,
    );
    expect(updateChannel(build(), AppPlatform.android).direct, isTrue);
    expect(updateChannel(build(), AppPlatform.android, channel: 'unknown'), (
      direct: false,
      store: null,
    ));
    expect(
      updateChannel(
        build(installer: 'com.android.vending'),
        AppPlatform.android,
      ).store.toString(),
      'https://play.google.com/store/apps/details?id=app.getavalon.avalon',
    );
    for (final package in ['other.app', 'dev.avalon.avalon']) {
      expect(
        updateChannel(
          build(package: package),
          AppPlatform.android,
          channel: 'google',
        ).store,
        isNull,
      );
    }
    expect(
      updateChannel(build(installer: 'com.apple.testflight'), AppPlatform.ios),
      (direct: false, store: null),
    );
    expect(
      updateChannel(
        build(),
        AppPlatform.ios,
        channel: 'apple',
        appleUrl: 'https://apps.apple.com/us/app/avalon/id123456',
      ).store?.host,
      'apps.apple.com',
    );
    for (final url in [
      'https://apps.apple.com.evil/app/id1',
      'https://user@apps.apple.com/app/id1',
      'https://apps.apple.com/app/id1?redirect=evil',
      'http://apps.apple.com/app/id1',
      'https://apps.apple.com:444/app/id1',
    ]) {
      expect(
        updateChannel(
          build(),
          AppPlatform.ios,
          channel: 'apple',
          appleUrl: url,
        ),
        (direct: false, store: null),
      );
    }
  });
}
