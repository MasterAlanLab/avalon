import 'dart:async';
import 'dart:convert';

import '../data/repositories/cloud_session_repository.dart';
import 'api_client.dart';
import 'cloud_models.dart';

/// Identity of the actual authorized attempt, after any shared refresh.
/// A database consumer must check these fields and [generation] again in
/// its apply transaction; this result alone is not authorization to write.
final class CloudAuthorizedSyncResult<T> {
  const CloudAuthorizedSyncResult({
    required this.value,
    required this.accountId,
    required this.deviceId,
    required this.sessionId,
    required this.generation,
  });

  final T value;
  final String accountId;
  final String deviceId;
  final String sessionId;
  final int generation;
}

/// The caller has no active Cloud session. Local content remains available.
final class CloudSignedOutException implements Exception {
  const CloudSignedOutException();

  @override
  String toString() => 'CloudSignedOutException';
}

/// A response belongs to a session the user has already left.
final class CloudSessionChangedException implements Exception {
  const CloudSessionChangedException();

  @override
  String toString() => 'CloudSessionChangedException';
}

/// The refresh outcome is unknown. Reusing its token could revoke the
/// session, so another login is required even after an application restart.
final class CloudReauthenticationRequiredException implements Exception {
  const CloudReauthenticationRequiredException();

  @override
  String toString() => 'CloudReauthenticationRequiredException';
}

/// The server no longer accepts the logout proof. Its local task is finished,
/// but remote revocation was not confirmed; a rotated session may still exist.
final class CloudRevocationUnavailableException implements Exception {
  const CloudRevocationUnavailableException();

  @override
  String toString() => 'CloudRevocationUnavailableException';
}

/// C1's account/session workflow. HTTP stays in the Dart app process and
/// credentials are owned by the encrypted data repository. There is no
/// background login, Cookie jar, or automatic replay of a refresh request.
final class AuthService {
  AuthService({
    required this._api,
    required this._sessions,
    required this._deviceName,
    required this._os,
    DateTime Function()? clock,
  }) : _clock = clock ?? (() => DateTime.now().toUtc());

  final ApiClient _api;
  final CloudSessionStore _sessions;
  final String _deviceName;
  final DeviceOs _os;
  final DateTime Function() _clock;
  final _refreshes = <String, Future<StoredCloudSession>>{};
  Future<void>? _revocationDrain;
  Future<void> _writes = Future<void>.value();
  int _generation = 0;

  /// Synchronous cancellation guard. Pair with a transaction-local session
  /// read; it cannot substitute for checking accountId/sessionId in the DB.
  int get generation => _generation;

  Future<CloudAuthorizedSyncResult<T>> authorizedSync<T>(
    Future<T> Function(ApiClient api, StoredCloudSession session) request,
  ) async {
    final requestedGeneration = _generation;
    StoredCloudSession? requested;
    final value = await _authorized((session) {
      requested = session;
      return request(_api, session);
    });
    final identity = requested!;
    return CloudAuthorizedSyncResult(
      value: value,
      accountId: identity.accountId,
      deviceId: identity.deviceId,
      sessionId: identity.sessionId,
      generation: requestedGeneration,
    );
  }

  Future<EmailStartResponse> startEmail(String email) =>
      _api.emailStart(email: email);

  Future<StoredCloudSession?> session() => _sessions.read();

  Future<StoredCloudSession> verifyEmail({
    required String challengeId,
    required String code,
  }) async {
    final generation = ++_generation;
    // D96: one local identity. Commit encrypted proof and local logout before
    // a new login. Its eventual proof-only retry never carries new Bearer.
    await _write(_sessions.logoutLocally);
    final installationId = await _sessions.installationId();
    final tokens = await _api.emailVerify(
      challengeId: challengeId,
      code: code,
      device: DeviceInput(
        installationId: installationId,
        name: _deviceName,
        os: _os,
      ),
    );
    final session = _fromTokens(tokens, installationId: installationId);
    final saved = await _write(() async {
      if (generation != _generation) return false;
      await _sessions.save(session);
      return true;
    });
    if (!saved) {
      await _discardSession(tokens);
      throw const CloudSessionChangedException();
    }
    return session;
  }

  Future<AccountResponse> account() async {
    StoredCloudSession? requestedSession;
    final result = await _authorized((session) {
      requestedSession = session;
      return _api.getAccount(accessToken: session.accessToken);
    });
    await _write(() async {
      final requested = requestedSession!;
      if (requested.accountId != result.account.id ||
          requested.deviceId != result.currentDeviceId) {
        throw const CloudSessionChangedException();
      }
      // Metadata writes must preserve a concurrent refresh claim and any
      // newly rotated credentials. A late response cannot update a new login.
      if (!await _sessions.updateProfile(
        expectedSessionId: requested.sessionId,
        email: result.account.email ?? '',
        displayName: result.account.displayName ?? '',
        entitlementJson: jsonEncode(result.entitlement?.toJson()),
      )) {
        throw const CloudSessionChangedException();
      }
    });
    return result;
  }

  Future<void> removeDevice(String deviceId) => _authorized((session) {
    // The current product exposes removal only for other devices.
    if (deviceId == session.deviceId) {
      throw ArgumentError('remove another device through the device list');
    }
    return _api.removeDevice(
      accessToken: session.accessToken,
      deviceId: deviceId,
    );
  });

  /// The UI must have completed both account-deletion confirmations.
  /// Success unbinds only this account's local objects, preserving content.
  Future<DeleteAccountResponse> deleteAccount() async {
    StoredCloudSession? deletedSession;
    DeleteAccountResponse? response;
    try {
      await _authorized((session) async {
        deletedSession = session;
        response = await _api.deleteAccount(accessToken: session.accessToken);
        return response!;
      });
    } finally {
      // Even if the user switched accounts while awaiting the response,
      // known remote success must unbind the account that was deleted.
      if (response != null) {
        final deleted = deletedSession!;
        await _write(() async {
          await _sessions.detachAccount(deleted.accountId);
          await _sessions.clear(expectedSessionId: deleted.sessionId);
        });
      }
    }
    return response!;
  }

  /// Queue the revocation proof and clear active tokens atomically before
  /// waiting for the network. Transient failures remain encrypted for retry;
  /// an unusable proof terminates with revocation explicitly unconfirmed.
  Future<void> logout() async {
    ++_generation;
    final previous = await _write(_sessions.logoutLocally);
    if (previous != null) await _revoke(previous);
  }

  /// Explicit retry entry point for future startup/foreground/network wiring.
  /// This foundation does not install a lifecycle listener itself. Proofs
  /// never use the current account's access token, so switching accounts
  /// cannot make an old logout revoke the new session.
  Future<void> retryPendingRevocations() {
    final existing = _revocationDrain;
    if (existing != null) return existing;
    late final Future<void> pending;
    pending = () async {
      try {
        Object? firstError;
        StackTrace? firstStack;
        for (final proof in await _sessions.pendingRevocations()) {
          try {
            await _revoke(proof);
          } on Object catch (error, stack) {
            // A terminal proof must remain visible even when another proof
            // failed earlier. The remaining queue still drives later retries.
            if (firstError == null ||
                error is CloudRevocationUnavailableException) {
              firstError = error;
              firstStack = stack;
            }
          }
        }
        if (firstError != null) {
          Error.throwWithStackTrace(firstError, firstStack!);
        }
      } finally {
        if (identical(_revocationDrain, pending)) _revocationDrain = null;
      }
    }();
    _revocationDrain = pending;
    return pending;
  }

  Future<void> _revoke(PendingCloudRevocation proof) async {
    // The server owns expiry: a skewed local clock must not discard a proof
    // that it still accepts. This request never carries a current Bearer.
    try {
      await _api.logout(refreshToken: proof.refreshToken);
    } on CloudApiException catch (error) {
      if (error.httpStatus != 401 ||
          error.code != CloudErrorCode.authRequired) {
        rethrow;
      }
      await _finishRevocation(proof);
      throw const CloudRevocationUnavailableException();
    }
    await _finishRevocation(proof);
  }

  Future<void> _finishRevocation(PendingCloudRevocation proof) => _write(
    () => _sessions.completeRevocation(
      proof.sessionId,
      expectedRefreshToken: proof.refreshToken,
    ),
  );

  Future<T> _authorized<T>(
    Future<T> Function(StoredCloudSession session) request,
  ) async {
    final generation = _generation;
    var current = await _sessions.read();
    if (current == null) throw const CloudSignedOutException();
    var refreshed = false;
    if (current.refreshUncertain) {
      final inFlight = _refreshes[current.sessionId];
      if (inFlight == null) {
        throw const CloudReauthenticationRequiredException();
      }
      current = await inFlight;
      refreshed = true;
    }
    if (!current.accessExpiresAt.isAfter(_clock())) {
      current = await _refresh(current);
      refreshed = true;
    }
    try {
      final result = await request(current);
      await _requireCurrent(current, generation);
      return result;
    } on CloudApiException catch (error) {
      if (error.httpStatus != 401) rethrow;
      if (error.code.value == 'SESSION_REVOKED') {
        await _clearCurrent(current);
        rethrow;
      }
      // Only a known AUTH_REQUIRED response permits one access renewal.
      // Unknown/malformed 401s are not turned into speculative token replay.
      if (error.code.value != 'AUTH_REQUIRED') rethrow;
      if (refreshed) {
        await _clearCurrent(current);
        rethrow;
      }
      current = await _refresh(current);
      try {
        final result = await request(current);
        await _requireCurrent(current, generation);
        return result;
      } on CloudApiException catch (second) {
        if (second.httpStatus == 401) await _clearCurrent(current);
        rethrow;
      }
    }
  }

  Future<StoredCloudSession> _refresh(StoredCloudSession previous) {
    final existing = _refreshes[previous.sessionId];
    if (existing != null) return existing;
    late final Future<StoredCloudSession> pending;
    pending = () async {
      try {
        return await _doRefresh(previous);
      } finally {
        if (identical(_refreshes[previous.sessionId], pending)) {
          unawaited(_refreshes.remove(previous.sessionId));
        }
      }
    }();
    _refreshes[previous.sessionId] = pending;
    return pending;
  }

  Future<StoredCloudSession> _doRefresh(StoredCloudSession previous) async {
    final current = await _sessions.read();
    if (current == null || !_sameSession(current, previous)) {
      throw const CloudSessionChangedException();
    }
    if (current.refreshUncertain) {
      throw const CloudReauthenticationRequiredException();
    }
    if (current.refreshToken != previous.refreshToken) return current;
    if (!current.refreshExpiresAt.isAfter(_clock())) {
      await _clearCurrent(current);
      throw const CloudSignedOutException();
    }

    // Commit this guard before issuing the request: a crash after the
    // server rotates but before local persistence must not replay the old
    // refresh token on next launch. Concurrent callers join _refreshes.
    if (!await _sessions.claimRefresh(
      expectedSessionId: current.sessionId,
      expectedRefreshToken: current.refreshToken,
    )) {
      final latest = await _sessions.read();
      if (latest != null && _sameSession(latest, current)) {
        if (latest.refreshUncertain) {
          throw const CloudReauthenticationRequiredException();
        }
        if (latest.refreshToken != current.refreshToken) return latest;
      }
      throw const CloudSessionChangedException();
    }

    TokenResponse tokens;
    try {
      tokens = await _api.refresh(refreshToken: current.refreshToken);
      if (tokens.accountId != current.accountId ||
          tokens.deviceId != current.deviceId ||
          tokens.sessionId != current.sessionId) {
        throw const CloudReauthenticationRequiredException();
      }
    } on CloudApiException catch (error) {
      if (error.httpStatus == 401) {
        await _clearCurrent(current);
      } else if (error.httpStatus == 400 || error.httpStatus == 429) {
        // These known rejections did not rotate the token. A later explicit
        // attempt is allowed; this invocation still does not auto-retry.
        await _write(
          () => _sessions.replaceTokens(
            expectedSessionId: current.sessionId,
            expectedRefreshToken: current.refreshToken,
            session: current.copyWith(refreshUncertain: false),
          ),
        );
      }
      rethrow;
    }

    final rotated = _fromTokens(
      tokens,
      installationId: current.installationId,
      profile: current,
    );
    final saved = await _write(
      () => _sessions.replaceTokens(
        expectedSessionId: current.sessionId,
        expectedRefreshToken: current.refreshToken,
        session: rotated,
      ),
    );
    if (!saved) throw const CloudSessionChangedException();
    return rotated;
  }

  Future<void> _clearCurrent(StoredCloudSession session) => _write(() async {
    await _sessions.clear(expectedSessionId: session.sessionId);
  });

  Future<void> _requireCurrent(
    StoredCloudSession session,
    int generation,
  ) async {
    final current = await _sessions.read();
    if (generation != _generation ||
        current == null ||
        !_sameSession(current, session)) {
      throw const CloudSessionChangedException();
    }
  }

  Future<void> _discardSession(TokenResponse tokens) async {
    try {
      await _api.logout(refreshToken: tokens.refreshToken);
    } on CloudException {
      // The stale result never enters the vault or reopens local login.
      // Failure remains bounded by server-side expiry; no blind retry.
    }
  }

  Future<T> _write<T>(Future<T> Function() action) {
    final next = _writes.then((_) => action());
    _writes = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  static bool _sameSession(StoredCloudSession a, StoredCloudSession b) =>
      a.accountId == b.accountId && a.sessionId == b.sessionId;

  static StoredCloudSession _fromTokens(
    TokenResponse tokens, {
    required String installationId,
    StoredCloudSession? profile,
  }) => StoredCloudSession(
    accountId: tokens.accountId,
    deviceId: tokens.deviceId,
    sessionId: tokens.sessionId,
    installationId: installationId,
    accessToken: tokens.accessToken,
    refreshToken: tokens.refreshToken,
    accessExpiresAt: tokens.accessExpiresAt,
    refreshExpiresAt: tokens.refreshExpiresAt,
    email: profile?.email ?? '',
    displayName: profile?.displayName ?? '',
    entitlementJson: profile?.entitlementJson,
  );
}
