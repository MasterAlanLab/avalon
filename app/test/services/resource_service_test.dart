// Rule-set downloads (CONFIG_PIPELINE §8): checked, converted and kept
// under their hash in the host's directory.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:av_core/av_core.dart';
import 'package:avalon/data/database/database.dart';
import 'package:avalon/data/repositories/rule_resource_repository.dart';
import 'package:avalon/services/download/fetcher.dart';
import 'package:avalon/services/resource_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// A binary rule set as far as the check reads it: `SRS`, a version.
Uint8List _srs(String body) =>
    Uint8List.fromList([0x53, 0x52, 0x53, 0x01, ...utf8.encode(body)]);

void main() {
  late HttpServer server;
  late Directory dir;
  late AppDatabase db;
  late RuleResourceRepository cache;
  late ResourceService resources;
  final files = <String, List<int>>{};

  setUp(() async {
    files.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((r) async {
      final body = files[r.uri.path];
      if (body == null) {
        r.response.statusCode = 404;
      } else {
        r.response.add(body);
      }
      await r.response.close();
    });
    dir = Directory.systemTemp.createTempSync('rulesets');
    db = AppDatabase(NativeDatabase.memory());
    cache = RuleResourceRepository(db);
    resources = ResourceService(
      cache,
      Fetcher(userAgent: 'test', maxBytes: ResourceService.maxBytes),
      stateDir: () async => dir.path,
      allowPrivateAddresses: true,
    );
  });
  tearDown(() async {
    await server.close(force: true);
    await db.close();
    dir.deleteSync(recursive: true);
  });

  RuleSetRef ref(String path, RuleSetFormat format, {String tag = 't'}) =>
      RuleSetRef(
        tag: tag,
        url: 'http://127.0.0.1:${server.port}$path',
        format: format,
      );
  List<String> kept() => [
    for (final f in Directory('${dir.path}/rulesets').listSync())
      f.uri.pathSegments.last,
  ]..sort();

  test(
    'a binary rule set is kept under its hash, and found by the plans',
    () async {
      final rule = ref('/cn.srs', RuleSetFormat.binary);
      files['/cn.srs'] = _srs('one');
      expect(await resources.missing([rule]), [rule]);

      final first = await resources.update(rule);
      expect(first, (error: null, replaced: false));
      final item = (await cache.all())[ruleSetKey(rule)]!;
      expect(item.file, '${item.sha256}.srs');
      expect(item.size, 7);
      expect(item.updatedAt, isNotNull);
      expect(kept(), [item.file]);
      expect(await resources.cachedPaths(), {
        ruleSetKey(rule): '${dir.path}/rulesets/${item.file}',
      });
      expect(await resources.missing([rule]), isEmpty);

      // The same content again: nothing for a running plan to reload.
      expect((await resources.update(rule)).replaced, isFalse);

      // New content: a new file; the old one stays until pruned.
      files['/cn.srs'] = _srs('two');
      expect(await resources.update(rule), (error: null, replaced: true));
      expect(kept(), hasLength(2));
      await resources.prune();
      expect(kept(), [(await cache.all())[ruleSetKey(rule)]!.file]);
    },
  );

  test(
    'a source rule set is kept as it is, a Clash provider converted',
    () async {
      files['/s.json'] = utf8.encode(
        '{"version": 2, "rules": [{"domain": ["a.com"]}]}',
      );
      files['/ads.txt'] = utf8.encode('+.ads.example\nbad*.wild\n');
      final source = ref('/s.json', RuleSetFormat.source);
      final clash = ref('/ads.txt', RuleSetFormat.clashDomainText);
      expect((await resources.update(source)).error, isNull);
      expect((await resources.update(clash)).error, isNull);
      final cached = await cache.all();
      final converted = File(
        '${dir.path}/rulesets/${cached[ruleSetKey(clash)]!.file}',
      );
      expect(converted.path, endsWith('.json'));
      expect(jsonDecode(converted.readAsStringSync()), {
        'version': 2,
        'rules': [
          {
            'domain_suffix': ['ads.example'],
          },
        ],
      });
      expect(cached[ruleSetKey(clash)]!.skipped, 1);
    },
  );

  test('a failure is recorded and what was downloaded stays', () async {
    final rule = ref('/cn.srs', RuleSetFormat.binary);
    files['/cn.srs'] = _srs('good');
    await resources.update(rule);
    final good = (await cache.all())[ruleSetKey(rule)]!;

    // Not a rule set at all (a login page, say).
    files['/cn.srs'] = utf8.encode('<html>please sign in</html>');
    expect(await resources.update(rule), (
      error: 'resource.format',
      replaced: false,
    ));
    var item = (await cache.all())[ruleSetKey(rule)]!;
    expect((item.file, item.lastError), (good.file, 'resource.format'));
    expect(item.updatedAt, good.updatedAt);

    // Gone from the server.
    files.remove('/cn.srs');
    expect((await resources.update(rule)).error, 'fetch.httpStatus.404');
    item = (await cache.all())[ruleSetKey(rule)]!;
    expect(item.file, good.file);
    expect(kept(), [good.file]);

    // Never downloaded and failing: a row with only the error.
    final other = ref('/missing.srs', RuleSetFormat.binary);
    await resources.update(other);
    final failed = (await cache.all())[ruleSetKey(other)]!;
    expect((failed.file, failed.lastError), (null, 'fetch.httpStatus.404'));
    expect(await resources.missing([other]), [other]);
  });

  test('through the proxy, the host writes the file', () async {
    final rule = ref('/cn.srs', RuleSetFormat.binary);
    String? asked;
    final result = await resources.update(
      rule,
      throughProxy: (url, dest, max, {publicOnly = false}) async {
        asked = url.toString();
        expect(max, ResourceService.maxBytes);
        expect(File(dest).parent.path, '${dir.path}/rulesets');
        await File(dest).writeAsBytes(_srs('via proxy'));
      },
    );
    expect(result.error, isNull);
    expect(asked, rule.url);
    // The download's temporary file is gone; the kept one remains.
    expect(kept(), [(await cache.all())[ruleSetKey(rule)]!.file]);

    final failed = await resources.update(
      ref('/x.srs', RuleSetFormat.binary),
      throughProxy: (_, _, _, {publicOnly = false}) async =>
          throw Exception('HTTP 502'),
    );
    expect(failed.error, 'resource.proxy');
  });

  test('Cloud rule downloads ignore a caller local-network override', () async {
    final rule = ref('/cloud.srs', RuleSetFormat.binary);
    files['/cloud.srs'] = _srs('cached locally');
    await resources.update(rule);
    final old = (await cache.all())[ruleSetKey(rule)]!;

    files['/cloud.srs'] = _srs('remote replacement');
    expect(await resources.update(rule, cloudSource: true), (
      error: 'fetch.blockedAddress',
      replaced: false,
    ));
    final after = (await cache.all())[ruleSetKey(rule)]!;
    expect(after.file, old.file);
    expect(after.sha256, old.sha256);
    expect(kept(), [old.file]);
  });

  test(
    'Cloud proxy downloads carry the public-only policy into the host',
    () async {
      const rule = RuleSetRef(
        tag: 'cloud',
        url: 'https://example.com/cloud.srs',
        format: RuleSetFormat.binary,
      );
      var invoked = false;
      final result = await resources.update(
        rule,
        cloudSource: true,
        throughProxy: (_, dest, _, {publicOnly = false}) async {
          invoked = publicOnly;
          await File(dest).writeAsBytes(_srs('guarded'));
        },
      );
      expect(result.error, isNull);
      expect(invoked, isTrue);
      expect((await cache.all())[ruleSetKey(rule)]!.file, isNotNull);
    },
  );

  test('the check knows a binary rule set from anything else', () {
    expect(
      () => ResourceService.prepare(RuleSetFormat.binary, Uint8List(0)),
      throwsA(isA<RuleSetFormatException>()),
    );
    expect(
      () => ResourceService.prepare(
        RuleSetFormat.source,
        Uint8List.fromList(utf8.encode('{"rules": []}')),
      ),
      throwsA(isA<RuleSetFormatException>()),
    );
  });

  test('tidying while a download is under way keeps the new file', () async {
    final rule = ref('/cn.srs', RuleSetFormat.binary);
    final release = Completer<void>();
    final downloading = resources.update(
      rule,
      throughProxy: (url, destPath, maxBytes, {publicOnly = false}) async {
        await release.future;
        await File(destPath).writeAsBytes(_srs('cn'));
      },
    );
    // Asked to tidy meanwhile: it waits for the download.
    final tidying = resources.prune();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    release.complete();
    expect((await downloading).error, isNull);
    await tidying;
    final path = (await resources.cachedPaths())[ruleSetKey(rule)];
    expect(path, isNotNull);
    expect(File(path!).existsSync(), isTrue);
    // Nothing half-written is left behind.
    expect(Directory('${dir.path}/rulesets').listSync().map((e) => e.path), [
      path,
    ]);
  });

  test(
    'moving to an App Group keeps only verified registered rule sets',
    () async {
      final rule = ref('/cn.srs', RuleSetFormat.binary);
      files['/cn.srs'] = _srs('cached before the iOS host');
      await resources.update(rule);
      final item = (await cache.all())[ruleSetKey(rule)]!;
      final original = File('${dir.path}/rulesets/${item.file}');
      // Neither the database/vault nor saved plaintext plans are migrated.
      File('${dir.path}/avalon.sqlite').writeAsStringSync('private database');
      File('${dir.path}/plan.json').writeAsStringSync('private plan');
      File(
        '${dir.path}/rulesets/unregistered.srs',
      ).writeAsStringSync('unregistered');
      final shared = Directory('${dir.path}/app-group')..createSync();
      final migrated = ResourceService(
        cache,
        Fetcher(userAgent: 'test'),
        stateDir: () async => shared.path,
        legacyStateDir: () async => dir.path,
      );
      final paths = await migrated.cachedPaths();
      final destination = File(paths[ruleSetKey(rule)]!);
      expect(destination.parent.path, '${shared.path}/rulesets');
      expect(destination.readAsBytesSync(), original.readAsBytesSync());
      expect(
        shared.listSync(recursive: true).whereType<File>().map((f) => f.path),
        [destination.path],
      );
      expect(original.existsSync(), isTrue);
      expect((await cache.all())[ruleSetKey(rule)]!.updatedAt, item.updatedAt);
      expect(await migrated.missing([rule]), isEmpty);

      // A repeat does not overwrite the shared copy with a changed source.
      original.writeAsBytesSync(_srs('tampered'));
      expect(await migrated.cachedPaths(), paths);
      expect(destination.readAsBytesSync(), _srs('cached before the iOS host'));
    },
  );

  test(
    'a damaged old cache is left missing for the normal downloader',
    () async {
      final rule = ref('/cn.srs', RuleSetFormat.binary);
      files['/cn.srs'] = _srs('original');
      await resources.update(rule);
      final item = (await cache.all())[ruleSetKey(rule)]!;
      File(
        '${dir.path}/rulesets/${item.file}',
      ).writeAsBytesSync(_srs('tampered'));
      final shared = Directory('${dir.path}/app-group')..createSync();
      final migrated = ResourceService(
        cache,
        Fetcher(userAgent: 'test'),
        stateDir: () async => shared.path,
        legacyStateDir: () async => dir.path,
      );
      expect(await migrated.cachedPaths(), isEmpty);
      expect(await migrated.missing([rule]), [rule]);
      expect(Directory('${shared.path}/rulesets').listSync(), isEmpty);
    },
  );
}
