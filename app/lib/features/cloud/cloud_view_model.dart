import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../cloud/api_client.dart';
import '../../cloud/auth_service.dart';
import '../../cloud/cloud_models.dart';
import '../../cloud/cloud_revocation_retry.dart';
import '../../cloud/sync_engine.dart';
import '../../data/repositories/cloud_session_repository.dart';
import 'cloud_state.dart';

final cloudViewModelProvider = NotifierProvider<CloudViewModel, CloudState>(
  CloudViewModel.new,
);

/// Restoration and HTTP are asynchronous; local application startup never
/// waits on this model. Views receive neither tokens nor diagnostic messages.
class CloudViewModel extends Notifier<CloudState> {
  AuthService? _auth;
  CloudSessionRepository? _sessions;
  CloudRevocationRetryController? _retry;
  SyncEngine? _sync;
  SyncStatus? _syncStatus;
  String? _accountId;
  String? _sessionId;
  int _operation = 0;
  Future<void>? _initialization;

  @override
  CloudState build() {
    ++_operation;
    _initialization = null;
    _sessionId = null;
    _accountId = null;
    _syncStatus = null;
    _auth = ref.watch(cloudAuthServiceProvider);
    _retry = ref.watch(cloudRevocationRetryProvider);
    final auth = _auth;
    if (auth == null) {
      return const CloudState(enabled: false, initialized: true);
    }
    _sync = ref.watch(cloudSyncEngineProvider);
    final sync = _sync?.watch().listen((status) {
      _syncStatus = status;
      if (ref.mounted) _projectSync(status);
    });
    _sessions = ref.read(cloudSessionRepositoryProvider);
    final sessions = _sessions!.watch().listen((session) {
      if (ref.mounted) _projectSession(session);
    });
    final retries = _retry?.statuses.listen((status) {
      if (!ref.mounted) return;
      state = state.copyWith(
        pendingRevocationCount: status.queuedCount,
        revocationUnconfirmed:
            state.revocationUnconfirmed || status.remoteRevocationUnconfirmed,
        error: status.remoteRevocationUnconfirmed
            ? CloudUiError.revocationUnconfirmed
            : null,
        clearError:
            !status.remoteRevocationUnconfirmed &&
            status.queuedCount == 0 &&
            state.error == CloudUiError.revocationPending,
      );
    });
    ref.onDispose(() {
      ++_operation;
      unawaited(sessions.cancel());
      if (retries != null) unawaited(retries.cancel());
      if (sync != null) unawaited(sync.cancel());
    });
    unawaited(Future<void>.microtask(initialize));
    return CloudState(syncAvailable: _sync != null);
  }

  Future<void> initialize() {
    if (_auth == null || !ref.mounted || state.initialized) {
      return Future<void>.value();
    }
    return _initialization ??= _restore();
  }

  Future<void> _restore() async {
    final operation = ++_operation;
    state = state.copyWith(initializing: true, clearError: true);
    try {
      final session = await _auth!.session();
      if (!_current(operation)) return;
      _projectSession(session);
      if (session != null) {
        if (session.refreshUncertain) {
          _requireLogin();
        } else {
          await _loadAccount(operation);
        }
      }
    } on Object catch (error) {
      if (_current(operation)) await _failure(error, operation);
    } finally {
      if (_current(operation)) {
        await _updateQueue(operation);
        if (_current(operation)) {
          state = state.copyWith(initialized: true, initializing: false);
        }
      }
    }
  }

  Future<void> sendEmail(String email) async {
    final normalized = email.trim();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(normalized)) {
      _show(CloudUiError.invalidEmail);
      return;
    }
    final operation = _begin();
    if (operation == null) return;
    try {
      final challenge = await _auth!.startEmail(normalized);
      if (_current(operation)) {
        state = state.copyWith(
          challengeId: challenge.challengeId,
          challengeEmail: normalized,
          challengeExpiresAt: challenge.expiresAt,
          clearResend: true,
          clearRetryAfter: true,
        );
      }
    } on Object catch (error) {
      if (_current(operation)) await _failure(error, operation);
    } finally {
      _finish(operation);
    }
  }

  Future<void> verify(String code) async {
    final challenge = state.challengeId;
    if (challenge == null || !RegExp(r'^\d{6}$').hasMatch(code)) {
      _show(CloudUiError.invalidCode);
      return;
    }
    final operation = _begin();
    if (operation == null) return;
    var checkingCode = true;
    try {
      final session = await _auth!.verifyEmail(
        challengeId: challenge,
        code: code,
      );
      checkingCode = false;
      if (!_current(operation)) return;
      _projectSession(session);
      state = state.copyWith(clearChallenge: true, clearResend: true);
      await _loadAccount(operation);
    } on Object catch (error) {
      if (_current(operation)) {
        await _failure(error, operation, emailVerification: checkingCode);
      }
    } finally {
      _finish(operation);
    }
  }

  void changeEmail() {
    if (state.busy) return;
    ++_operation;
    state = state.copyWith(
      clearChallenge: true,
      clearResend: true,
      clearRetryAfter: true,
      clearError: true,
    );
  }

  Future<void> refreshAccount() async {
    final operation = _begin();
    if (operation == null) return;
    try {
      await _loadAccount(operation);
      final sync = _sync;
      if (_current(operation) && sync != null && sync.lifecycleEnabled) {
        await sync.runNow();
      }
    } on Object catch (error) {
      if (_current(operation)) await _failure(error, operation);
    } finally {
      _finish(operation);
    }
  }

  Future<void> syncNow() async {
    final sync = _sync;
    if (sync == null || !state.signedIn || state.syncing || state.busy) return;
    final generation = state.sessionGeneration;
    try {
      await sync.runNow();
    } on Object {
      if (ref.mounted && state.sessionGeneration == generation) {
        state = state.copyWith(syncBlockedReason: 'INTERNAL_ERROR');
      }
    }
  }

  Future<void> rebuildFromDevice({bool takeOver = false}) async {
    final sync = _sync;
    final lifecycle = state.lifecycle;
    if (sync == null ||
        !state.signedIn ||
        state.syncing ||
        lifecycle?.spaceState != 'active' ||
        (takeOver
            ? lifecycle?.backupState != 'rebuilding' ||
                  lifecycle?.rebuild?.ownerDeviceId == state.currentDeviceId
            : lifecycle?.backupState != 'rebuildRequired')) {
      return;
    }
    final operation = _begin();
    if (operation == null) return;
    final session = state.sessionGeneration;
    try {
      await sync.rebuildFromDevice(takeOver: takeOver);
    } on Object {
      if (_current(operation) && state.sessionGeneration == session) {
        state = state.copyWith(
          syncBlockedReason: state.syncBlockedReason ?? 'INTERNAL_ERROR',
        );
      }
    } finally {
      _finish(operation);
    }
  }

  Future<void> cancelRebuild() async {
    final sync = _sync;
    final lifecycle = state.lifecycle;
    if (sync == null ||
        !state.signedIn ||
        state.syncing ||
        lifecycle?.spaceState != 'active' ||
        lifecycle?.backupState != 'rebuilding' ||
        lifecycle?.rebuild?.ownerDeviceId != state.currentDeviceId) {
      return;
    }
    final operation = _begin();
    if (operation == null) return;
    final session = state.sessionGeneration;
    try {
      await sync.cancelRebuild();
    } on Object {
      if (_current(operation) && state.sessionGeneration == session) {
        state = state.copyWith(
          syncBlockedReason: state.syncBlockedReason ?? 'INTERNAL_ERROR',
        );
      }
    } finally {
      _finish(operation);
    }
  }

  Future<void> logout() async {
    // Logout may cancel an in-flight account read or verification. The
    // service queues the original proof before contacting the network.
    final operation = _begin(interrupt: true);
    if (operation == null) return;
    state = state.copyWith(clearChallenge: true, clearResend: true);
    try {
      await _auth!.logout();
    } on CloudRevocationUnavailableException {
      _retry?.noteUnconfirmed();
      if (_current(operation)) {
        state = state.copyWith(
          revocationUnconfirmed: true,
          error: CloudUiError.revocationUnconfirmed,
        );
      }
    } on Object catch (error) {
      if (_current(operation)) {
        // Do not claim a local logout if the storage transaction failed.
        await _failure(error, operation);
        if (_current(operation) && !state.signedIn) {
          state = state.copyWith(error: CloudUiError.revocationPending);
        }
      }
    } finally {
      if (_current(operation)) {
        await _reconcile(operation);
        await _updateQueue(operation);
      }
      _finish(operation);
    }
  }

  Future<void> deleteAccount() async {
    final operation = _begin();
    if (operation == null) return;
    try {
      final response = await _auth!.deleteAccount();
      if (!_current(operation)) return;
      await _reconcile(operation);
      if (_current(operation)) {
        state = state.copyWith(
          accountDeleted: true,
          deletionNotice: response.cancelSubscription,
        );
      }
    } on Object catch (error) {
      if (_current(operation)) {
        await _failure(error, operation);
        // Neither a timeout nor a later 401 proves deletion succeeded.
        if (_current(operation) &&
            (error is CloudNetworkException ||
                error is CloudTimeoutException ||
                error is CloudProtocolException)) {
          state = state.copyWith(error: CloudUiError.deleteUnconfirmed);
        }
      }
    } finally {
      _finish(operation);
    }
  }

  Future<void> removeDevice(String deviceId) async {
    if (deviceId == state.currentDeviceId) {
      _show(CloudUiError.currentDevice);
      return;
    }
    final operation = _begin();
    if (operation == null) return;
    try {
      await _auth!.removeDevice(deviceId);
      if (!_current(operation)) return;
      final previous = state.account;
      if (previous != null) {
        final devices = previous.devices
            .where((device) => device.id != deviceId)
            .toList();
        state = state.copyWith(
          account: AccountResponse(
            account: previous.account,
            entitlement: previous.entitlement,
            devices: devices,
            currentDeviceId: previous.currentDeviceId,
            deviceLimit: previous.deviceLimit,
            syncActiveDeviceCount: devices
                .where((device) => device.syncActive)
                .length,
          ),
        );
      }
      await _loadAccount(operation);
    } on Object catch (error) {
      if (_current(operation)) await _failure(error, operation);
    } finally {
      _finish(operation);
    }
  }

  Future<void> retryRevocations() async {
    final operation = _begin();
    if (operation == null) return;
    try {
      if (_retry != null) {
        await _retry!.trigger();
      } else {
        await _auth!.retryPendingRevocations();
      }
    } on CloudRevocationUnavailableException {
      if (_current(operation)) {
        state = state.copyWith(revocationUnconfirmed: true);
      }
    } on Object catch (error) {
      if (_current(operation)) await _failure(error, operation);
    } finally {
      if (_current(operation)) {
        await _updateQueue(operation);
        if (_current(operation) && state.revocationUnconfirmed) {
          state = state.copyWith(error: CloudUiError.revocationUnconfirmed);
        } else if (_current(operation) && state.pendingRevocationCount > 0) {
          state = state.copyWith(error: CloudUiError.revocationPending);
        }
      }
      _finish(operation);
    }
  }

  void clearNotice() => state = state.copyWith(
    clearError: true,
    clearDeletionNotice: true,
    accountDeleted: false,
  );

  Future<void> _loadAccount(int operation) async {
    final response = await _auth!.account();
    if (!_current(operation)) return;
    final session = await _auth!.session();
    if (!_current(operation) || session == null) return;
    _projectSession(session);
    state = state.copyWith(
      account: response,
      email: response.account.email ?? '',
      displayName: response.account.displayName ?? '',
      currentDeviceId: response.currentDeviceId,
      requiresReauthentication: false,
      signedIn: true,
    );
    final retry = _retry;
    if (retry != null) unawaited(retry.trigger());
  }

  Future<void> _reconcile(int operation) async {
    try {
      final session = await _auth!.session();
      if (_current(operation)) _projectSession(session);
    } on Object {
      if (_current(operation)) _show(CloudUiError.unknown);
    }
  }

  void _projectSession(StoredCloudSession? session) {
    final changed = session?.sessionId != _sessionId;
    _sessionId = session?.sessionId;
    _accountId = session?.accountId;
    state = state.copyWith(
      signedIn: session != null && (changed || !state.requiresReauthentication),
      requiresReauthentication: changed ? false : null,
      sessionGeneration: changed ? state.sessionGeneration + 1 : null,
      email: session?.email ?? '',
      displayName: session?.displayName ?? '',
      currentDeviceId: session?.deviceId,
      clearCurrentDevice: session == null,
      clearAccount: changed || session == null,
      clearSync: changed || session == null,
    );
    if (session == null) {
      state = state.copyWith(requiresReauthentication: false);
    }
    final status = _syncStatus;
    if (status != null) _projectSync(status);
  }

  void _projectSync(SyncStatus status) {
    if (status.accountId == null || status.accountId != _accountId) return;
    state = state.copyWith(
      syncing: status.busy,
      lastSyncAt: status.lastSyncAt,
      syncBlockedReason: status.blockedReason,
      clearSyncBlock: status.blockedReason == null,
      lifecycle: status.lifecycle,
      pendingMergeCount: status.pendingMergeCount,
    );
  }

  Future<void> _updateQueue(int operation) async {
    try {
      final count = (await _sessions!.pendingRevocations()).length;
      if (!_current(operation)) return;
      state = state.copyWith(
        pendingRevocationCount: count,
        revocationUnconfirmed:
            state.revocationUnconfirmed ||
            (_retry?.status.remoteRevocationUnconfirmed ?? false),
      );
      // A new offline logout can add the first proof after the startup drain
      // found an empty queue. Schedule this new work without waiting on it.
      final retry = _retry;
      if (count > 0 && retry != null) unawaited(retry.trigger());
    } on Object {
      if (_current(operation)) _show(CloudUiError.unknown);
    }
  }

  Future<void> _failure(
    Object error,
    int operation, {
    bool emailVerification = false,
  }) async {
    await _reconcile(operation);
    if (!_current(operation)) return;
    if (error is CloudSessionChangedException) return;
    if (error is CloudReauthenticationRequiredException) {
      _requireLogin();
      return;
    }
    final mapped = switch (error) {
      CloudNetworkException() => CloudUiError.offline,
      CloudTimeoutException() => CloudUiError.timeout,
      CloudProtocolException() => CloudUiError.protocol,
      CloudSignedOutException() => CloudUiError.reauthenticationRequired,
      CloudApiException(:final code) => switch (code.value) {
        'AUTH_REQUIRED' => CloudUiError.reauthenticationRequired,
        'SESSION_REVOKED' => CloudUiError.sessionRevoked,
        'RATE_LIMITED' => CloudUiError.rateLimited,
        'VALIDATION' =>
          emailVerification
              ? switch (error.reason) {
                  EmailChallengeReason.wrongCode =>
                    CloudUiError.challengeInvalid,
                  EmailChallengeReason.consumed ||
                  EmailChallengeReason.missing => CloudUiError.challengeEnded,
                  EmailChallengeReason.expired => CloudUiError.challengeExpired,
                  EmailChallengeReason.attemptsExceeded =>
                    CloudUiError.challengeExhausted,
                  null => CloudUiError.validation,
                }
              : CloudUiError.validation,
        'NOT_FOUND' => CloudUiError.deviceNotFound,
        'INTERNAL_ERROR' => CloudUiError.server,
        _ => CloudUiError.unknown,
      },
      _ => CloudUiError.unknown,
    };
    final delay = error is CloudApiException ? error.retryAfter : null;
    state = state.copyWith(
      error: mapped,
      // Terminal challenges require a fresh send; wrongCode remains usable.
      clearChallenge:
          mapped == CloudUiError.challengeEnded ||
          mapped == CloudUiError.challengeExpired ||
          mapped == CloudUiError.challengeExhausted,
      retryAfterSeconds: delay?.inSeconds,
      clearRetryAfter: delay == null,
      resendAvailableAt: mapped == CloudUiError.rateLimited && delay != null
          ? DateTime.now().toUtc().add(delay)
          : null,
    );
  }

  void _requireLogin() => state = state.copyWith(
    signedIn: false,
    requiresReauthentication: true,
    clearAccount: true,
    error: CloudUiError.reauthenticationRequired,
  );

  int? _begin({bool interrupt = false}) {
    if (!ref.mounted || _auth == null) {
      if (ref.mounted) _show(CloudUiError.disabled);
      return null;
    }
    if (!interrupt && (state.busy || state.initializing)) return null;
    final operation = ++_operation;
    state = state.copyWith(
      busy: true,
      initialized: true,
      initializing: false,
      clearError: true,
      clearRetryAfter: true,
      clearDeletionNotice: true,
      accountDeleted: false,
    );
    return operation;
  }

  bool _current(int operation) => ref.mounted && operation == _operation;

  void _finish(int operation) {
    if (_current(operation)) state = state.copyWith(busy: false);
  }

  void _show(CloudUiError error) {
    if (ref.mounted) state = state.copyWith(error: error);
  }
}
