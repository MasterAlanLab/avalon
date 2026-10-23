import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avalon/app/log.dart';
import 'package:avalon/services/download/fetcher.dart';
import 'package:flutter_test/flutter_test.dart';

/// A local server; [handle] answers each request and records headers.
Future<(HttpServer, List<HttpHeaders>)> _serve(
  FutureOr<void> Function(HttpRequest r) handle,
) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final seen = <HttpHeaders>[];
  server.listen((r) async {
    seen.add(r.headers);
    await handle(r);
    await r.response.close();
  });
  return (server, seen);
}

Matcher _fails(FetchErrorCode code) =>
    throwsA(isA<FetchException>().having((e) => e.code, 'code', code));

void main() {
  final fetcher = Fetcher(userAgent: 'Avalon/0.1 clash.meta', maxBytes: 1024);

  test('downloads and reads the subscription headers', () async {
    final (server, seen) = await _serve((r) {
      r.response.headers
        ..set(
          'subscription-userinfo',
          'upload=1; download=2; total=300; expire=1800000000',
        )
        ..set('profile-title', 'base64:${base64.encode(utf8.encode('机场'))}')
        ..set(
          'content-disposition',
          "attachment; filename*=UTF-8''%E6%9C%BA%E5%9C%BA.yaml",
        );
      r.response.write('proxies: []');
    });
    final f = await fetcher.get(
      Uri.parse('http://127.0.0.1:${server.port}/sub'),
    );
    expect(f.text, 'proxies: []');
    expect((f.usage!.upload, f.usage!.download, f.usage!.total), (1, 2, 300));
    expect(
      f.usage!.expireAt,
      DateTime.fromMillisecondsSinceEpoch(1800000000000, isUtc: true),
    );
    expect(f.title, '机场');
    expect(f.fileName, '机场');
    expect(f.privateOrigin, isTrue);
    expect(seen.single.value('user-agent'), 'Avalon/0.1 clash.meta');
    await server.close();
  });

  test('credentials are not forwarded across origins on redirect', () async {
    final (target, targetSeen) = await _serve((r) => r.response.write('ok'));
    final (origin, originSeen) = await _serve((r) {
      r.response
        ..statusCode = 302
        ..headers.set('location', 'http://127.0.0.1:${target.port}/x');
    });
    final f = await fetcher.get(
      Uri.parse('http://user:fake-pass@127.0.0.1:${origin.port}/s'),
      headers: {'X-Token': 'fake-token'},
    );
    expect(f.text, 'ok');
    expect(originSeen.single.value('authorization'), startsWith('Basic '));
    expect(originSeen.single.value('x-token'), 'fake-token');
    expect(targetSeen.single.value('authorization'), isNull);
    expect(targetSeen.single.value('x-token'), isNull);
    await origin.close();
    await target.close();
  });

  test('private addresses need consent', () async {
    final (server, _) = await _serve((r) => r.response.write('x'));
    await expectLater(
      fetcher.get(
        Uri.parse('http://127.0.0.1:${server.port}/'),
        allowPrivate: false,
      ),
      _fails(FetchErrorCode.blockedAddress),
    );
    await server.close();
  });

  test('Cloud cannot inherit explicit local-network permission', () async {
    final (server, seen) = await _serve((r) => r.response.write('secret'));
    try {
      await expectLater(
        fetcher.get(
          Uri.parse('http://127.0.0.1:${server.port}/'),
          allowPrivate: true,
          cloudSource: true,
        ),
        _fails(FetchErrorCode.blockedAddress),
      );
      expect(seen, isEmpty);
    } finally {
      await server.close(force: true);
    }
  });

  test('Cloud rejects URL credentials, fragments and unsafe headers', () async {
    for (final url in [
      'https://fake-user:fake-password@example.com/sub',
      'https://example.com/sub#fake-secret',
    ]) {
      await expectLater(
        fetcher.get(Uri.parse(url), cloudSource: true),
        _fails(FetchErrorCode.invalidUrl),
      );
    }
    for (final headers in [
      {'Host': 'localhost'},
      {'X-Forwarded-For': '127.0.0.1'},
      {'X-Real-IP': '127.0.0.1'},
      {'X-Token': 'fake\r\nHost: localhost'},
      {'Cookie': 'a\u0000b'},
      {'Accept': '*/*', 'accept': 'application/json'},
    ]) {
      await expectLater(
        fetcher.get(
          Uri.parse('https://example.com/sub'),
          cloudSource: true,
          headers: headers,
        ),
        _fails(FetchErrorCode.invalidUrl),
      );
    }
  });

  test('mapped IPv6 and reserved ranges are never public destinations', () {
    for (final address in [
      '::ffff:127.0.0.1',
      '::ffff:10.1.2.3',
      '168.63.129.16',
      '::ffff:168.63.129.16',
      '224.0.0.1',
      '255.255.255.255',
      '192.0.2.1',
      '198.18.1.1',
      '192.88.99.1',
      '64:ff9b::7f00:1',
      '2001:db8::1',
      '2001::1',
      '2002:7f00:1::1',
      '3fff::1',
      'ff02::1',
      '100::1',
    ]) {
      expect(
        isPrivateAddress(InternetAddress(address)),
        isTrue,
        reason: address,
      );
    }
    for (final address in ['8.8.8.8', '2606:4700:4700::1111']) {
      expect(
        isPrivateAddress(InternetAddress(address)),
        isFalse,
        reason: address,
      );
    }
  });

  test('limits: size, redirects, status', () async {
    final (big, _) = await _serve((r) => r.response.write('x' * 2000));
    await expectLater(
      fetcher.get(Uri.parse('http://127.0.0.1:${big.port}/')),
      _fails(FetchErrorCode.tooLarge),
    );
    late HttpServer loop;
    (loop, _) = await _serve((r) {
      r.response
        ..statusCode = 302
        ..headers.set('location', 'http://127.0.0.1:${loop.port}/again');
    });
    await expectLater(
      fetcher.get(Uri.parse('http://127.0.0.1:${loop.port}/')),
      _fails(FetchErrorCode.tooManyRedirects),
    );
    final (missing, _) = await _serve((r) => r.response.statusCode = 404);
    await expectLater(
      fetcher.get(Uri.parse('http://127.0.0.1:${missing.port}/')),
      throwsA(isA<FetchException>().having((e) => e.status, 'status', 404)),
    );
    await expectLater(
      fetcher.get(Uri.parse('ftp://example.com/x')),
      _fails(FetchErrorCode.invalidUrl),
    );
    for (final s in [big, loop, missing]) {
      await s.close();
    }
  });

  test('a cancelled download stops', () async {
    final (slow, _) = await _serve((r) async {
      r.response.write('start');
      await r.response.flush();
      await Future<void>.delayed(const Duration(seconds: 2));
    });
    final cancel = FetchCancel();
    final pending = fetcher.get(
      Uri.parse('http://127.0.0.1:${slow.port}/'),
      cancel: cancel,
    );
    final expectation = expectLater(pending, _fails(FetchErrorCode.cancelled));
    await Future<void>.delayed(const Duration(milliseconds: 200));
    cancel.cancel();
    await expectation;
    await slow.close(force: true);
  });

  test('log redaction', () {
    expect(
      redact('GET https://user:pw@sub.example.com/x?token=abc&n=1 failed'),
      'GET https://•••@sub.example.com/x?token=•••&n=1 failed',
    );
    expect(redact('Authorization: Bearer abc'), 'Authorization: •••');
  });
}
