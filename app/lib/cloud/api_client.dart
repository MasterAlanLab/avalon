import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'cloud_models.dart';
import 'sync_json.dart' show syncScalarLength;
import 'sync_lifecycle_models.dart';
import 'sync_models.dart';

sealed class CloudException implements Exception {
  const CloudException();
}

final class CloudNetworkException extends CloudException {
  const CloudNetworkException();

  @override
  String toString() => 'CloudNetworkException';
}

final class CloudTimeoutException extends CloudException {
  const CloudTimeoutException();

  @override
  String toString() => 'CloudTimeoutException';
}

enum CloudProtocolFailure { invalidResponse, responseTooLarge, redirect }

final class CloudProtocolException extends CloudException {
  const CloudProtocolException([
    this.reason = CloudProtocolFailure.invalidResponse,
  ]);

  final CloudProtocolFailure reason;

  @override
  String toString() => 'CloudProtocolException(${reason.name})';
}

final class CloudApiException extends CloudException {
  const CloudApiException({
    required this.httpStatus,
    required this.code,
    required this.message,
    this.retryAfter,
    this.reason,
  });

  final int httpStatus;
  final CloudErrorCode code;

  /// Diagnostic text only. Never log it or branch on its contents.
  final String message;
  final Duration? retryAfter;

  /// Known machine reason for HTTP 400 VALIDATION. Only the email verification
  /// workflow consumes this field; it never branches on diagnostic text.
  final EmailChallengeReason? reason;

  @override
  String toString() => 'CloudApiException($httpStatus)';
}

/// One attempt only. Authentication orchestration belongs to AuthService.
abstract interface class CloudTransport {
  Future<CloudResponse> send(CloudRequest request);

  void close();
}

final class CloudRequest {
  CloudRequest({
    required this.method,
    required this.uri,
    required Map<String, String> headers,
    required this.body,
    required this.timeout,
    required this.responseMaxBytes,
  }) : headers = Map.unmodifiable(headers);

  final String method;
  final Uri uri;
  final Map<String, String> headers;
  final Uint8List? body;
  final Duration timeout;
  final int responseMaxBytes;
}

final class CloudResponse {
  CloudResponse({
    required this.statusCode,
    required Map<String, String> headers,
    required this.body,
  }) : headers = Map.unmodifiable(headers);

  final int statusCode;
  final Map<String, String> headers;
  final Uint8List body;
}

/// Native Dart HTTP, with one deadline covering connection, upload and body.
/// All redirects are rejected, so a token can never reach another origin.
final class HttpClientCloudTransport implements CloudTransport {
  HttpClientCloudTransport({HttpClient? httpClient})
    : _client = httpClient ?? HttpClient();

  final HttpClient _client;

  @override
  Future<CloudResponse> send(CloudRequest request) async {
    HttpClientRequest? activeRequest;
    var expired = false;
    var status = 0;
    Future<CloudResponse> sendOnce() async {
      activeRequest = await _client.openUrl(request.method, request.uri);
      if (expired) {
        activeRequest!.abort();
        throw const CloudTimeoutException();
      }
      activeRequest!.followRedirects = false;
      request.headers.forEach(activeRequest!.headers.set);
      if (request.body case final body?) {
        activeRequest!.contentLength = body.length;
        activeRequest!.add(body);
      }
      final response = await activeRequest!.close();
      status = response.statusCode;
      final headers = <String, String>{};
      response.headers.forEach((name, values) {
        headers[name.toLowerCase()] = values.join(',');
      });
      if (status >= 300 && status < 400) {
        activeRequest!.abort();
        throw const CloudProtocolException(CloudProtocolFailure.redirect);
      }
      if (response.compressionState !=
              HttpClientResponseCompressionState.decompressed &&
          response.contentLength > request.responseMaxBytes) {
        activeRequest!.abort();
        if (status == HttpStatus.unauthorized) {
          return _unauthorized(headers);
        }
        throw const CloudProtocolException(
          CloudProtocolFailure.responseTooLarge,
        );
      }
      final bytes = BytesBuilder(copy: false);
      await for (final chunk in response) {
        if (bytes.length + chunk.length > request.responseMaxBytes) {
          activeRequest!.abort();
          if (status == HttpStatus.unauthorized) {
            return _unauthorized(headers);
          }
          throw const CloudProtocolException(
            CloudProtocolFailure.responseTooLarge,
          );
        }
        bytes.add(chunk);
      }
      return CloudResponse(
        statusCode: status,
        headers: headers,
        body: bytes.takeBytes(),
      );
    }

    try {
      return await sendOnce().timeout(
        request.timeout,
        onTimeout: () {
          expired = true;
          activeRequest?.abort();
          if (status == HttpStatus.unauthorized) return _unauthorized();
          throw const CloudTimeoutException();
        },
      );
    } on CloudException {
      rethrow;
    } on Object {
      // Socket/HTTP/TLS errors may carry URLs and credential-bearing headers.
      // Keep only their category and retain any already-observed 401.
      if (status == HttpStatus.unauthorized) return _unauthorized();
      throw const CloudNetworkException();
    }
  }

  CloudResponse _unauthorized([Map<String, String> headers = const {}]) =>
      CloudResponse(
        statusCode: HttpStatus.unauthorized,
        headers: headers,
        body: Uint8List(0),
      );

  @override
  void close() => _client.close(force: true);
}

final class ApiClient {
  ApiClient({
    required Uri baseUri,
    CloudTransport? transport,
    HttpClient? httpClient,
    bool allowLoopbackHttp = false,
    this.timeout = const Duration(seconds: 15),
    this.responseMaxBytes = 1024 * 1024,
    this.requestMaxBytes = 64 * 1024,
  }) : baseUri = _validateBaseUri(baseUri, allowLoopbackHttp),
       _transport = _createTransport(
         transport,
         httpClient,
         timeout,
         responseMaxBytes,
         requestMaxBytes,
       );

  static CloudTransport _createTransport(
    CloudTransport? transport,
    HttpClient? httpClient,
    Duration timeout,
    int responseMaxBytes,
    int requestMaxBytes,
  ) {
    if (timeout <= Duration.zero ||
        responseMaxBytes <= 0 ||
        requestMaxBytes <= 0 ||
        (transport != null && httpClient != null)) {
      throw ArgumentError('Invalid Cloud transport configuration.');
    }
    return transport ?? HttpClientCloudTransport(httpClient: httpClient);
  }

  final Uri baseUri;
  final Duration timeout;
  final int responseMaxBytes;
  final int requestMaxBytes;
  final CloudTransport _transport;

  Future<EmailStartResponse> emailStart({required String email}) async =>
      _parse(
        await _send(
          'POST',
          ['v1', 'auth', 'email', 'start'],
          body: {'email': _nonempty(email)},
        ),
        EmailStartResponse.fromJson,
      );

  Future<TokenResponse> emailVerify({
    required String challengeId,
    required String code,
    required DeviceInput device,
  }) async {
    if (!RegExp(r'^[0-9]{6}$').hasMatch(code)) {
      throw ArgumentError('Invalid Cloud verification code.');
    }
    _nonempty(device.installationId);
    _nonempty(device.name);
    return _parse(
      await _send(
        'POST',
        ['v1', 'auth', 'email', 'verify'],
        body: {
          'challengeId': _nonempty(challengeId),
          'code': code,
          'device': device.toJson(),
        },
      ),
      TokenResponse.fromJson,
    );
  }

  Future<TokenResponse> refresh({required String refreshToken}) async => _parse(
    await _send(
      'POST',
      ['v1', 'auth', 'refresh'],
      body: {'refreshToken': _nonempty(refreshToken)},
    ),
    TokenResponse.fromJson,
  );

  Future<void> logout({String? accessToken, String? refreshToken}) async {
    if ((accessToken == null || accessToken.isEmpty) &&
        (refreshToken == null || refreshToken.isEmpty)) {
      throw ArgumentError('Cloud logout requires a credential.');
    }
    await _send(
      'POST',
      ['v1', 'auth', 'logout'],
      accessToken: accessToken,
      body: refreshToken == null
          ? null
          : {'refreshToken': _nonempty(refreshToken)},
      successStatus: HttpStatus.noContent,
    );
  }

  Future<AccountResponse> getAccount({required String accessToken}) async =>
      _parse(
        await _send('GET', ['v1', 'account'], accessToken: accessToken),
        AccountResponse.fromJson,
      );

  Future<DeleteAccountResponse> deleteAccount({
    required String accessToken,
  }) async => _parse(
    await _send('DELETE', ['v1', 'account'], accessToken: accessToken),
    DeleteAccountResponse.fromJson,
  );

  Future<void> removeDevice({
    required String accessToken,
    required String deviceId,
  }) async {
    // A dot path segment would be normalized by Uri and change the endpoint.
    if (deviceId == '.' || deviceId == '..') {
      throw ArgumentError('Invalid Cloud device identifier.');
    }
    await _send(
      'DELETE',
      ['v1', 'devices', _nonempty(deviceId)],
      accessToken: accessToken,
      successStatus: HttpStatus.noContent,
    );
  }

  Future<SyncActivateResponse> activateSync({
    required String accessToken,
  }) async => _parseSync(
    await _send(
      'POST',
      ['v1', 'sync', 'activate'],
      accessToken: accessToken,
      sync: true,
    ),
    SyncActivateResponse.fromJson,
  );

  Future<SyncPullResponse> pullSync({
    required String accessToken,
    required int cursor,
    int limit = 500,
  }) async {
    validateSyncPullInput(cursor, limit);
    return _parseSync(
      await _send(
        'GET',
        ['v1', 'sync', 'pull'],
        accessToken: accessToken,
        query: {'cursor': '$cursor', 'limit': '$limit'},
        sync: true,
      ),
      (json) => SyncPullResponse.fromJson(json, cursor: cursor, limit: limit),
    );
  }

  Future<SyncPushResponse> pushSync({
    required String accessToken,
    required List<SyncMutation> mutations,
  }) async {
    // A caller may mutate its list while awaiting HTTP. Match the result to
    // the exact immutable sequence whose frozen envelopes were sent.
    final sent = List<SyncMutation>.unmodifiable(mutations);
    final encoded = encodeSyncPush(sent);
    return _parseSync(
      await _send(
        'POST',
        ['v1', 'sync', 'push'],
        accessToken: accessToken,
        encodedBody: encoded,
        sync: true,
      ),
      (json) => SyncPushResponse.fromJson(json, mutations: sent),
    );
  }

  /// Explicit protocol 2 preview. Protocol 1 methods remain unchanged; an
  /// unsupported peer is reported and never retried with a lower version.
  Future<SyncLifecycleStatus> syncLifecycle({
    required String accessToken,
  }) async => _parseSync(
    await _send(
      'GET',
      ['v1', 'sync', 'status'],
      accessToken: accessToken,
      sync: true,
      syncVersion: '2',
    ),
    SyncLifecycleStatus.fromJson,
    expectedVersion: '2',
  );

  Future<SyncActivateV2Response> activateSyncV2({
    required String accessToken,
    required String? syncGeneration,
  }) async {
    validateSyncGeneration(syncGeneration, nullable: true);
    return _parseSync(
      await _send(
        'POST',
        ['v1', 'sync', 'activate'],
        accessToken: accessToken,
        body: {'syncGeneration': syncGeneration},
        sync: true,
        syncVersion: '2',
      ),
      (json) => SyncActivateV2Response.fromJson(
        json,
        expectedGeneration: syncGeneration,
      ),
      expectedVersion: '2',
    );
  }

  Future<SyncPullV2Response> pullSyncV2({
    required String accessToken,
    required String syncGeneration,
    required int cursor,
    int limit = 500,
  }) async {
    validateSyncGeneration(syncGeneration);
    validateSyncPullInput(cursor, limit);
    return _parseSync(
      await _send(
        'GET',
        ['v1', 'sync', 'pull'],
        accessToken: accessToken,
        query: {
          'syncGeneration': syncGeneration,
          'cursor': '$cursor',
          'limit': '$limit',
        },
        sync: true,
        syncVersion: '2',
      ),
      (json) => SyncPullV2Response.fromJson(
        json,
        syncGeneration: syncGeneration,
        cursor: cursor,
        limit: limit,
      ),
      expectedVersion: '2',
    );
  }

  Future<SyncPushV2Response> pushSyncV2({
    required String accessToken,
    required String syncGeneration,
    required String? rebuildAttemptId,
    required List<SyncMutation> mutations,
  }) async {
    final sent = List<SyncMutation>.unmodifiable(mutations);
    final encoded = encodeSyncPushV2(
      syncGeneration: syncGeneration,
      rebuildAttemptId: rebuildAttemptId,
      mutations: sent,
    );
    return _parseSync(
      await _send(
        'POST',
        ['v1', 'sync', 'push'],
        accessToken: accessToken,
        encodedBody: encoded,
        sync: true,
        syncVersion: '2',
      ),
      (json) => SyncPushV2Response.fromJson(
        json,
        syncGeneration: syncGeneration,
        rebuildAttemptId: rebuildAttemptId,
        mutations: sent,
      ),
      expectedVersion: '2',
    );
  }

  Future<SyncRebuildAttempt> getSyncRebuild({
    required String accessToken,
    required String syncGeneration,
    required String attemptId,
  }) async {
    validateSyncGeneration(syncGeneration);
    validateSyncGeneration(attemptId);
    return _parseSync(
      await _send(
        'GET',
        ['v1', 'sync', 'rebuild'],
        accessToken: accessToken,
        query: {'syncGeneration': syncGeneration, 'attemptId': attemptId},
        sync: true,
        syncVersion: '2',
      ),
      (json) {
        final result = SyncRebuildAttempt.fromJson(json);
        if (result.syncGeneration != syncGeneration ||
            result.attemptId != attemptId) {
          throw const SyncValidationException();
        }
        return result;
      },
      expectedVersion: '2',
    );
  }

  Future<SyncRebuildControlResponse> controlSyncRebuild({
    required String accessToken,
    required SyncRebuildControlRequest request,
  }) async => _parseSync(
    await _send(
      'POST',
      ['v1', 'sync', 'rebuild'],
      accessToken: accessToken,
      encodedBody: request.canonicalBytes,
      sync: true,
      syncVersion: '2',
    ),
    (json) => SyncRebuildControlResponse.fromJson(json, request: request),
    expectedVersion: '2',
  );

  void close() => _transport.close();

  Future<CloudResponse> _send(
    String method,
    List<String> path, {
    Map<String, Object?>? body,
    Uint8List? encodedBody,
    Map<String, String>? query,
    String? accessToken,
    int successStatus = HttpStatus.ok,
    bool sync = false,
    String syncVersion = '1',
  }) async {
    final requestLimit = sync ? syncBodyMaxBytes : requestMaxBytes;
    final responseLimit = sync ? syncBodyMaxBytes : responseMaxBytes;
    final headers = <String, String>{
      HttpHeaders.acceptHeader: 'application/json',
      if (sync) 'Avalon-Sync-Version': syncVersion,
    };
    if (accessToken != null) {
      _nonempty(accessToken);
      if (RegExp(r'[\s\x00-\x1f\x7f]').hasMatch(accessToken)) {
        throw ArgumentError('Invalid Cloud access token.');
      }
      headers[HttpHeaders.authorizationHeader] = 'Bearer $accessToken';
    }
    Uint8List? encoded = encodedBody;
    if (body != null || encoded != null) {
      encoded ??= Uint8List.fromList(utf8.encode(jsonEncode(body)));
      if (encoded.length > requestLimit) {
        throw ArgumentError('Cloud request exceeds its byte limit.');
      }
      headers[HttpHeaders.contentTypeHeader] =
          'application/json; charset=utf-8';
    }
    CloudResponse response;
    try {
      final pending = _transport.send(
        CloudRequest(
          method: method,
          uri: baseUri.replace(pathSegments: path, queryParameters: query),
          headers: headers,
          body: encoded,
          timeout: timeout,
          responseMaxBytes: responseLimit,
        ),
      );
      // Native transport aborts its request on its deadline, retaining any
      // observed 401. An outer timer would race and hide that HTTP status.
      response = await (_transport is HttpClientCloudTransport
          ? pending
          : pending.timeout(timeout));
    } on CloudException {
      rethrow;
    } on TimeoutException {
      throw const CloudTimeoutException();
    } on Object {
      throw const CloudNetworkException();
    }
    if (response.statusCode == HttpStatus.unauthorized) {
      if (sync) {
        throw _syncApiError(
          response,
          fallbackCode: CloudErrorCode.unknownAuthError,
          expectedVersion: syncVersion,
        );
      }
      throw _apiError(response, fallbackCode: CloudErrorCode.unknownAuthError);
    }
    if (response.body.length > responseLimit) {
      throw const CloudProtocolException(CloudProtocolFailure.responseTooLarge);
    }
    if (response.statusCode >= 300 && response.statusCode < 400) {
      throw const CloudProtocolException(CloudProtocolFailure.redirect);
    }
    if (response.statusCode != successStatus) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        throw const CloudProtocolException();
      }
      throw sync
          ? _syncApiError(response, expectedVersion: syncVersion)
          : _apiError(response);
    }
    if (successStatus == HttpStatus.noContent && response.body.isNotEmpty) {
      throw const CloudProtocolException();
    }
    return response;
  }

  T _parseSync<T>(
    CloudResponse response,
    T Function(Map<String, Object?>) decode, {
    String expectedVersion = '1',
  }) {
    final type = response.headers[HttpHeaders.contentTypeHeader];
    final encoding = response.headers[HttpHeaders.contentEncodingHeader];
    if (type?.split(';').first.trim().toLowerCase() != 'application/json' ||
        response.headers['avalon-sync-version'] != expectedVersion ||
        response.headers[HttpHeaders.cacheControlHeader]
                ?.trim()
                .toLowerCase() !=
            'no-store' ||
        (encoding != null && encoding != 'identity' && encoding != 'gzip')) {
      throw const CloudProtocolException();
    }
    try {
      final json = decodeSyncJson(response.body);
      if (json is! Map<String, Object?>) throw const CloudProtocolException();
      return decode(json);
    } on SyncValidationException {
      rethrow;
    } on CloudException {
      rethrow;
    } on Object {
      throw const CloudProtocolException();
    }
  }

  CloudApiException _syncApiError(
    CloudResponse response, {
    CloudErrorCode? fallbackCode,
    String expectedVersion = '1',
  }) {
    var code = fallbackCode ?? const CloudErrorCode('HTTP_ERROR');
    // Error diagnostics are deliberately discarded. HTTP status still owns
    // 401 behavior if an intermediary damaged or truncated its JSON.
    try {
      if ((expectedVersion == '2' &&
              response.headers['avalon-sync-version'] != '2') ||
          response.body.length > syncBodyMaxBytes ||
          response.headers[HttpHeaders.cacheControlHeader]
                  ?.trim()
                  .toLowerCase() !=
              'no-store') {
        throw const CloudProtocolException();
      }
      final json = decodeSyncJson(response.body);
      if (json is! Map<String, Object?> ||
          json.length != 1 ||
          json['error'] is! Map<String, Object?>) {
        throw const CloudProtocolException();
      }
      final error = json['error']! as Map<String, Object?>;
      final rawCode = error['code'];
      final message = error['message'];
      if (error.length != 2 ||
          rawCode is! String ||
          message is! String ||
          syncScalarLength(message) > 512 ||
          !(expectedVersion == '2'
                  ? _syncV2Errors[response.statusCode]
                  : _syncErrors[response.statusCode])!
              .contains(rawCode)) {
        throw const CloudProtocolException();
      }
      code = CloudErrorCode(rawCode);
    } on Object {
      if (response.statusCode != HttpStatus.unauthorized) {
        throw const CloudProtocolException();
      }
    }
    final rawRetry = response.headers[HttpHeaders.retryAfterHeader];
    final seconds =
        rawRetry != null && RegExp(r'^[1-9][0-9]*$').hasMatch(rawRetry)
        ? int.tryParse(rawRetry)
        : null;
    if ((response.statusCode == 429 && (seconds == null || seconds <= 0)) ||
        (response.statusCode == 503 && seconds != 30)) {
      throw const CloudProtocolException();
    }
    return CloudApiException(
      httpStatus: response.statusCode,
      code: code,
      message: '',
      retryAfter: seconds == null ? null : Duration(seconds: seconds),
    );
  }

  static const _syncErrors = <int, Set<String>>{
    400: {'VALIDATION'},
    401: {'AUTH_REQUIRED', 'SESSION_REVOKED'},
    402: {'NO_ENTITLEMENT'},
    409: {'DEVICE_LIMIT', 'SYNC_NOT_ACTIVE', 'SYNC_QUOTA_EXCEEDED'},
    413: {'VALIDATION'},
    415: {'VALIDATION'},
    426: {'SCHEMA_UNSUPPORTED'},
    429: {'RATE_LIMITED'},
    500: {'INTERNAL_ERROR'},
    503: {'INTERNAL_ERROR'},
  };

  static final _syncV2Errors = <int, Set<String>>{
    ..._syncErrors,
    404: {'SYNC_REBUILD_NOT_FOUND'},
    409: {
      'DEVICE_LIMIT',
      'SYNC_NOT_ACTIVE',
      'SYNC_QUOTA_EXCEEDED',
      'SYNC_GENERATION_MISMATCH',
      'SYNC_SPACE_RETIRED',
      'SYNC_REBUILD_REQUIRED',
      'SYNC_REBUILD_IN_PROGRESS',
      'SYNC_REBUILD_ATTEMPT_MISMATCH',
      'SYNC_REBUILD_OWNER_CHANGED',
      'SYNC_REBUILD_MANIFEST_MISMATCH',
    },
    503: {'INTERNAL_ERROR', 'SYNC_ENTITLEMENT_UNVERIFIED'},
  };

  T _parse<T>(CloudResponse response, T Function(Map<String, Object?>) decode) {
    try {
      final contentType = response.headers[HttpHeaders.contentTypeHeader];
      if (contentType?.split(';').first.trim().toLowerCase() !=
          'application/json') {
        throw const CloudProtocolException();
      }
      return decode(_json(response.body));
    } on CloudException {
      rethrow;
    } on Object {
      throw const CloudProtocolException();
    }
  }

  CloudApiException _apiError(
    CloudResponse response, {
    CloudErrorCode? fallbackCode,
  }) {
    var code = fallbackCode ?? const CloudErrorCode('HTTP_ERROR');
    var message = '';
    EmailChallengeReason? reason;
    if (response.body.length <= responseMaxBytes) {
      try {
        final error = _json(response.body)['error'];
        if (error is Map<String, Object?>) {
          final rawCode = error['code'];
          final rawMessage = error['message'];
          if (rawCode is String && rawCode.isNotEmpty && rawMessage is String) {
            code = CloudErrorCode(rawCode);
            message = rawMessage;
            if (response.statusCode == 400 &&
                code == CloudErrorCode.validation) {
              final rawReason = error['reason'];
              for (final candidate in EmailChallengeReason.values) {
                if (candidate.name == rawReason) {
                  reason = candidate;
                  break;
                }
              }
            }
          }
        }
      } on Object {
        // HTTP status remains useful even when an intermediary sent HTML or
        // the unauthorized body was truncated or violated the schema.
      }
    }
    final seconds = int.tryParse(
      response.headers[HttpHeaders.retryAfterHeader] ?? '',
    );
    return CloudApiException(
      httpStatus: response.statusCode,
      code: code,
      message: message,
      reason: reason,
      retryAfter: seconds != null && seconds > 0
          ? Duration(seconds: seconds)
          : null,
    );
  }

  Map<String, Object?> _json(Uint8List bytes) {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, Object?>) {
      throw const CloudProtocolException();
    }
    return decoded;
  }

  static Uri _validateBaseUri(Uri uri, bool allowLoopbackHttp) {
    final loopback =
        uri.host == 'localhost' || uri.host == '127.0.0.1' || uri.host == '::1';
    if (!uri.hasAuthority ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        (!uri.isScheme('https') &&
            !(allowLoopbackHttp && uri.isScheme('http') && loopback))) {
      throw ArgumentError('Invalid Cloud base URI.');
    }
    return uri.replace(path: '/');
  }

  String _nonempty(String value) {
    if (value.isEmpty) throw ArgumentError('Invalid Cloud request value.');
    if (value.length > requestMaxBytes) {
      throw ArgumentError('Cloud request exceeds its byte limit.');
    }
    return value;
  }
}
