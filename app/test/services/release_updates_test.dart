import 'dart:convert';

import 'package:avalon/services/release_updates.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, Object> release(String version, {String? asset}) => {
    'draft': false,
    'prerelease': false,
    'tag_name': 'v$version',
    'html_url':
        'https://github.com/MasterAlanLab/avalon/releases/tag/v$version',
    'assets': [
      if (asset != null)
        {
          'name': 'avalon-client-release.json',
          'size': 100,
          'browser_download_url': asset,
        },
    ],
  };
  String asset(String version) =>
      'https://github.com/MasterAlanLab/avalon/releases/download/v$version/avalon-client-release.json';
  Map<String, Object> manifest(String version) => {
    'schema': 1,
    'application': 'app.getavalon.avalon',
    'engine': 'sing-box',
    'hostProtocol': 1,
    'version': version,
    'platforms': ['android', 'macos'],
  };

  test('older implementation without a manifest is never offered', () async {
    var reads = 0;
    final updates = ReleaseUpdates(
      platform: 'android',
      read: (_) async {
        reads++;
        return jsonEncode([release('1.0.0'), release('9.0.0')]);
      },
    );
    expect((await updates.check('2.0.0')).kind, UpdateResultKind.noRelease);
    expect(reads, 1);
  });

  test(
    'actual manifest byte limit is enforced independently of metadata',
    () async {
      final updates = ReleaseUpdates(
        platform: 'android',
        read: (uri) async => uri.host == 'api.github.com'
            ? jsonEncode([release('0.2.0', asset: asset('0.2.0'))])
            : jsonEncode({
                ...manifest('0.2.0'),
                'padding': List.filled(6000, '\u4e2d').join(),
              }),
      );
      await expectLater(updates.check('0.1.0'), throwsFormatException);
    },
  );

  test(
    'only the installed platform and compatible current engine qualify',
    () async {
      Future<String> read(Uri uri) async => jsonEncode(
        uri.host == 'api.github.com'
            ? [release('2.0.1', asset: asset('2.0.1'))]
            : manifest('2.0.1'),
      );
      final updates = ReleaseUpdates(platform: 'android', read: read);
      final result = await updates.check('2.0.0');
      expect(result.kind, UpdateResultKind.available);
      expect(result.version, '2.0.1');
      expect(result.page!.path, '/MasterAlanLab/avalon/releases/tag/v2.0.1');
      expect((await updates.check('2.0.1')).kind, UpdateResultKind.current);
      final other = ReleaseUpdates(platform: 'windows', read: read);
      expect((await other.check('0.1.0')).kind, UpdateResultKind.noRelease);
    },
  );

  test('prereleases and the obsolete avalon tag prefix are ignored', () async {
    for (final item in [
      {...release('2.0.1', asset: asset('2.0.1')), 'prerelease': true},
      release('2.0.1-beta.1', asset: asset('2.0.1-beta.1')),
      {
        ...release('2.0.1', asset: asset('2.0.1')),
        'tag_name': 'avalon-v2.0.1',
        'html_url':
            'https://github.com/MasterAlanLab/avalon/releases/tag/avalon-v2.0.1',
      },
    ]) {
      var reads = 0;
      final updates = ReleaseUpdates(
        platform: 'android',
        read: (_) async {
          reads++;
          return jsonEncode([item]);
        },
      );
      expect((await updates.check('2.0.0')).kind, UpdateResultKind.noRelease);
      expect(reads, 1);
    }
  });

  test('foreign and cross-release manifest URLs fail before fetching', () async {
    for (final url in [
      'https://github.com.evil.test/avalon-client-release.json',
      'https://github.com/MasterAlanLab/avalon/releases/download/v0.3.0/avalon-client-release.json',
      'http://github.com/MasterAlanLab/avalon/releases/download/v0.2.0/avalon-client-release.json',
    ]) {
      var reads = 0;
      final updates = ReleaseUpdates(
        platform: 'android',
        read: (_) async {
          reads++;
          return jsonEncode([release('0.2.0', asset: url)]);
        },
      );
      await expectLater(updates.check('0.1.0'), throwsFormatException);
      expect(reads, 1);
    }
  });

  test(
    'foreign applications, incompatible engines, unknown protocols, and tag mismatch fail closed',
    () async {
      for (final patch in [
        {'application': 'dev.avalon.avalon'},
        {'engine': 'other'},
        {'hostProtocol': 9},
        {'version': '0.4.0'},
      ]) {
        final updates = ReleaseUpdates(
          platform: 'android',
          read: (uri) async => jsonEncode(
            uri.host == 'api.github.com'
                ? [release('0.2.0', asset: asset('0.2.0'))]
                : {...manifest('0.2.0'), ...patch},
          ),
        );
        await expectLater(updates.check('0.1.0'), throwsFormatException);
      }
    },
  );
}
