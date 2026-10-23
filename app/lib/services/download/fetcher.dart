import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:av_core/av_core.dart';

/// Why a download failed (CONFIG_PIPELINE §2).
enum FetchErrorCode {
  /// Not an http(s) URL.
  invalidUrl,

  /// The address is local or private and the source did not allow that.
  blockedAddress,
  timeout,
  tooLarge,
  tooManyRedirects,
  httpStatus,
  tls,
  network,
  cancelled,
}

final class FetchException implements Exception {
  const FetchException(this.code, {this.status, this.detail});

  final FetchErrorCode code;

  /// HTTP status for [FetchErrorCode.httpStatus].
  final int? status;

  /// Redacted context.
  final String? detail;

  @override
  String toString() =>
      'FetchException(${code.name}${status == null ? '' : ' $status'})';
}

/// A downloaded subscription or file.
final class Fetched {
  const Fetched({
    required this.bytes,
    required this.finalUrl,
    this.usage,
    this.title,
    this.fileName,
    this.privateOrigin = false,
  });

  /// The body as received.
  final Uint8List bytes;
  final Uri finalUrl;

  /// Only the address of the first actual connection can grant providers
  /// access to the private network; a later DNS lookup is not consent.
  final bool privateOrigin;

  /// The body as text (UTF-8, malformed sequences replaced).
  String get text => utf8.decode(bytes, allowMalformed: true);

  /// From `subscription-userinfo`.
  final Usage? usage;

  /// From `profile-title` (supports `base64:`).
  final String? title;

  /// From `Content-Disposition`.
  final String? fileName;
}

/// Lets an in-flight download be abandoned (PRODUCT_SPEC §3.5 「取消」).
final class FetchCancel {
  bool _cancelled = false;
  final _listeners = <void Function()>[];

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final l in _listeners) {
      l();
    }
  }

  void _onCancel(void Function() f) => _listeners.add(f);
}

/// HTTP GET with the CONFIG_PIPELINE §2 rules: limits, manual redirects
/// without forwarding credentials across origins, and an address policy
/// checked on the connection actually made.
final class Fetcher {
  Fetcher({
    required this.userAgent,
    this.connectTimeout = const Duration(seconds: 10),
    this.totalTimeout = const Duration(seconds: 60),
    this.maxBytes = 16 * 1024 * 1024,
    this.maxRedirects = 5,
  });

  final String userAgent;
  final Duration connectTimeout;
  final Duration totalTimeout;
  final int maxBytes;
  final int maxRedirects;

  /// Downloads [url]. A URL the user typed may point at the local machine
  /// or a private network ([allowPrivate], i.e. explicit consent); URLs
  /// that come from content may only do so when their source did.
  Future<Fetched> get(
    Uri url, {
    Map<String, String> headers = const {},
    bool allowPrivate = true,
    bool cloudSource = false,
    FetchCancel? cancel,
  }) async {
    _checkUrl(url, cloudSource: cloudSource);
    if (cloudSource) _checkCloudHeaders(headers);
    final client = HttpClient()
      ..connectionTimeout = connectTimeout
      ..userAgent = userAgent
      ..findProxy = (_) => 'DIRECT';
    cancel?._onCancel(() => client.close(force: true));
    // Only the user-entered origin may be private; redirects re-check.
    var privateOk = allowPrivate && !cloudSource;
    bool? originPrivate;
    client.connectionFactory = (uri, proxyHost, proxyPort) => _connect(
      uri,
      privateOk: privateOk,
      onAddress: (private) => originPrivate ??= private,
    );

    try {
      return await _follow(
        client,
        url,
        headers,
        cancel,
        (ok) => privateOk = ok,
        () => allowPrivate && !cloudSource && (originPrivate ?? false),
        cloudSource: cloudSource,
      ).timeout(totalTimeout);
    } on TimeoutException {
      throw const FetchException(FetchErrorCode.timeout);
    } on FetchException {
      rethrow;
    } on Object catch (e) {
      // Socket, HTTP and OS errors, including those caused by cancelling.
      if (cancel?.isCancelled ?? false) {
        throw const FetchException(FetchErrorCode.cancelled);
      }
      if (e is HandshakeException) {
        throw FetchException(FetchErrorCode.tls, detail: e.message);
      }
      if (e is SocketException || e is HttpException || e is OSError) {
        throw FetchException(FetchErrorCode.network, detail: '$e');
      }
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  Future<Fetched> _follow(
    HttpClient client,
    Uri url,
    Map<String, String> headers,
    FetchCancel? cancel,
    void Function(bool) setPrivateOk,
    bool Function() privateOriginAllowed, {
    required bool cloudSource,
  }) async {
    final origin = url;
    var current = url;
    for (var hop = 0; ; hop++) {
      if (cancel?.isCancelled ?? false) {
        throw const FetchException(FetchErrorCode.cancelled);
      }
      final request = await client.getUrl(_withoutUserInfo(current));
      request.followRedirects = false;
      // Credentials only go to the origin they were given for.
      if (_sameOrigin(current, origin)) {
        if (current.userInfo.isNotEmpty) {
          request.headers.set(
            HttpHeaders.authorizationHeader,
            'Basic ${base64.encode(utf8.encode(Uri.decodeComponent(current.userInfo)))}',
          );
        }
        headers.forEach(request.headers.set);
      }
      final response = await request.close();

      if (response.isRedirect) {
        await response.drain<void>();
        final location = response.headers.value(HttpHeaders.locationHeader);
        if (location == null) {
          throw FetchException(
            FetchErrorCode.httpStatus,
            status: response.statusCode,
          );
        }
        if (hop + 1 > maxRedirects) {
          throw const FetchException(FetchErrorCode.tooManyRedirects);
        }
        final next = current.resolve(location);
        _checkUrl(next, cloudSource: cloudSource);
        // Never grant private access through a second DNS lookup or to
        // a cloud source, even when a redirect changes its DNS answer.
        setPrivateOk(privateOriginAllowed());
        current = next;
        continue;
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        await response.drain<void>();
        throw FetchException(
          FetchErrorCode.httpStatus,
          status: response.statusCode,
        );
      }
      final body = await _read(response, cancel);
      return Fetched(
        bytes: body,
        finalUrl: current,
        privateOrigin: privateOriginAllowed(),
        usage: parseUserInfo(response.headers.value('subscription-userinfo')),
        title: parseProfileTitle(response.headers.value('profile-title')),
        fileName: parseFileName(response.headers.value('content-disposition')),
      );
    }
  }

  Future<Uint8List> _read(
    HttpClientResponse response,
    FetchCancel? cancel,
  ) async {
    if (response.contentLength > maxBytes) {
      throw const FetchException(FetchErrorCode.tooLarge);
    }
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in response) {
      if (cancel?.isCancelled ?? false) {
        throw const FetchException(FetchErrorCode.cancelled);
      }
      bytes.add(chunk);
      if (bytes.length > maxBytes) {
        throw const FetchException(FetchErrorCode.tooLarge);
      }
    }
    return bytes.takeBytes();
  }

  Future<ConnectionTask<Socket>> _connect(
    Uri uri, {
    required bool privateOk,
    required void Function(bool) onAddress,
  }) async {
    final List<InternetAddress> addresses;
    try {
      addresses = await InternetAddress.lookup(uri.host);
    } on SocketException catch (e) {
      throw FetchException(FetchErrorCode.network, detail: e.message);
    }
    // Check the address actually used, not a separate lookup (rebinding).
    final address = addresses.first;
    if (!privateOk && isPrivateAddress(address)) {
      throw const FetchException(FetchErrorCode.blockedAddress);
    }
    onAddress(isPrivateAddress(address));
    final port = uri.hasPort ? uri.port : (uri.isScheme('https') ? 443 : 80);
    if (uri.isScheme('https')) {
      return SecureSocket.startConnect(address, port);
    }
    return Socket.startConnect(address, port);
  }

  static Uri _withoutUserInfo(Uri u) => u.replace(userInfo: '');

  static void _checkUrl(Uri uri, {required bool cloudSource}) {
    if ((!uri.isScheme('http') && !uri.isScheme('https')) ||
        uri.host.isEmpty ||
        uri.port < 1 ||
        uri.port > 65535 ||
        (cloudSource && (uri.userInfo.isNotEmpty || uri.hasFragment))) {
      throw const FetchException(FetchErrorCode.invalidUrl);
    }
  }

  static void _checkCloudHeaders(Map<String, String> headers) {
    final seen = <String>{};
    final token = RegExp(r"^[!#$%&'*+.^_`|~0-9A-Za-z-]+$");
    const allowed = {
      'authorization',
      'cookie',
      'user-agent',
      'accept',
      'accept-language',
      'referer',
      'origin',
    };
    if (headers.length > 32) {
      throw const FetchException(FetchErrorCode.invalidUrl);
    }
    for (final entry in headers.entries) {
      final name = entry.key.toLowerCase();
      if (!token.hasMatch(entry.key) ||
          entry.key.length > 256 ||
          !seen.add(name) ||
          entry.value.runes.length > 16384 ||
          entry.value.contains(RegExp(r'[\r\n\x00]')) ||
          !(allowed.contains(name) ||
              (name.startsWith('x-') &&
                  !name.startsWith('x-forwarded-') &&
                  name != 'x-real-ip'))) {
        throw const FetchException(FetchErrorCode.invalidUrl);
      }
    }
  }

  static bool _sameOrigin(Uri a, Uri b) =>
      a.scheme == b.scheme && a.host == b.host && a.port == b.port;
}

/// Non-public destinations, including reserved ranges and IPv4-mapped IPv6.
bool isPrivateAddress(InternetAddress a) {
  // Globally numbered infrastructure endpoint; never a cloud-authored
  // proxy or resource target. Keep aligned with the native Bridge guard.
  if (a.address == '168.63.129.16') return true;
  if (a.isLoopback || a.isLinkLocal) return true;
  final b = a.rawAddress;
  if (a.type == InternetAddressType.IPv4) {
    return b[0] == 10 ||
        b[0] == 0 ||
        (b[0] == 172 && b[1] >= 16 && b[1] < 32) ||
        (b[0] == 192 && b[1] == 168) ||
        (b[0] == 100 && b[1] >= 64 && b[1] < 128) ||
        (b[0] == 192 && b[1] == 0 && (b[2] == 0 || b[2] == 2)) ||
        (b[0] == 192 && b[1] == 88 && b[2] == 99) ||
        (b[0] == 198 && (b[1] == 18 || b[1] == 19)) ||
        (b[0] == 198 && b[1] == 51 && b[2] == 100) ||
        (b[0] == 203 && b[1] == 0 && b[2] == 113) ||
        b[0] >= 224;
  }
  if (a.type == InternetAddressType.IPv6) {
    if (b.take(10).every((x) => x == 0) && b[10] == 255 && b[11] == 255) {
      return isPrivateAddress(
        InternetAddress.fromRawAddress(Uint8List.fromList(b.sublist(12))),
      );
    }
    return (b[0] & 0xe0) != 0x20 ||
        b.take(12).every((x) => x == 0) ||
        (b[0] & 0xfe) == 0xfc ||
        b[0] == 0xff ||
        (b[0] == 0xfe && (b[1] & 0xc0) == 0xc0) ||
        (b[0] == 1 && b.skip(1).take(7).every((x) => x == 0)) ||
        (b[0] == 0x20 && b[1] == 1 && b[2] < 2) ||
        (b[0] == 0x20 && b[1] == 1 && b[2] == 0x0d && b[3] == 0xb8) ||
        (b[0] == 0x20 && b[1] == 2) ||
        (b[0] == 0x3f && b[1] == 0xff && (b[2] & 0xf0) == 0);
  }
  return false;
}

/// `upload=1; download=2; total=3; expire=1700000000`.
Usage? parseUserInfo(String? header) {
  if (header == null || header.trim().isEmpty) return null;
  final values = <String, int>{};
  for (final part in header.split(';')) {
    final kv = part.split('=');
    if (kv.length != 2) continue;
    final n = int.tryParse(kv[1].trim().split('.').first);
    if (n != null) values[kv[0].trim().toLowerCase()] = n;
  }
  if (values.isEmpty) return null;
  final expire = values['expire'];
  return Usage(
    upload: values['upload'] ?? 0,
    download: values['download'] ?? 0,
    total: values['total'],
    expireAt: expire == null || expire <= 0
        ? null
        : DateTime.fromMillisecondsSinceEpoch(expire * 1000, isUtc: true),
  );
}

/// `profile-title`, plain or `base64:…`.
String? parseProfileTitle(String? header) {
  if (header == null || header.trim().isEmpty) return null;
  final h = header.trim();
  if (h.toLowerCase().startsWith('base64:')) {
    try {
      return utf8.decode(base64.decode(base64.normalize(h.substring(7))));
    } on FormatException {
      return null;
    }
  }
  return h;
}

/// File name from `Content-Disposition` (RFC 6266, incl. `filename*`).
String? parseFileName(String? header) {
  if (header == null) return null;
  final star = RegExp(
    r"filename\*\s*=\s*(?:UTF-8|utf-8)''([^;]+)",
  ).firstMatch(header);
  String? name;
  if (star != null) {
    try {
      name = Uri.decodeComponent(star.group(1)!.trim());
    } on ArgumentError {
      return null;
    }
  } else {
    name = RegExp(
      r'filename\s*=\s*"?([^";]+)"?',
    ).firstMatch(header)?.group(1)?.trim();
  }
  if (name == null || name.isEmpty) return null;
  // Strip the extension: it names the format, not the subscription.
  final dot = name.lastIndexOf('.');
  return dot > 0 ? name.substring(0, dot) : name;
}
