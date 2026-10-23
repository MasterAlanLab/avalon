import '../../cloud/cloud_models.dart';
import '../../cloud/sync_lifecycle_models.dart';

/// UI failures have no server message, request body, or credential attached.
enum CloudUiError {
  disabled,
  invalidEmail,
  invalidCode,
  validation,
  challengeInvalid,
  challengeExpired,
  challengeExhausted,
  challengeEnded,
  rateLimited,
  offline,
  timeout,
  protocol,
  reauthenticationRequired,
  sessionRevoked,
  deviceNotFound,
  currentDevice,
  deleteUnconfirmed,
  revocationPending,
  revocationUnconfirmed,
  server,
  unknown,
}

/// Only the account profile reaches Views. Session credentials stay in data.
final class CloudState {
  const CloudState({
    this.enabled = true,
    this.initialized = false,
    this.initializing = false,
    this.busy = false,
    this.signedIn = false,
    this.requiresReauthentication = false,
    this.sessionGeneration = 0,
    this.email = '',
    this.displayName = '',
    this.currentDeviceId,
    this.account,
    this.challengeId,
    this.challengeEmail,
    this.challengeExpiresAt,
    this.resendAvailableAt,
    this.retryAfterSeconds,
    this.error,
    this.pendingRevocationCount = 0,
    this.revocationUnconfirmed = false,
    this.deletionNotice,
    this.accountDeleted = false,
    this.syncAvailable = false,
    this.syncing = false,
    this.syncBlockedReason,
    this.lastSyncAt,
    this.lifecycle,
    this.pendingMergeCount = 0,
  });

  final bool enabled;
  final bool initialized;
  final bool initializing;
  final bool busy;
  final bool signedIn;
  final bool requiresReauthentication;

  /// Changes when the active session changes, including the same account
  /// logging in again. Confirmation dialogs must capture and recheck it.
  final int sessionGeneration;
  final String email;
  final String displayName;
  final String? currentDeviceId;
  final AccountResponse? account;
  final String? challengeId;

  /// The accepted challenge's email, kept only in memory for page recreation.
  final String? challengeEmail;
  final DateTime? challengeExpiresAt;
  final DateTime? resendAvailableAt;
  final int? retryAfterSeconds;
  final CloudUiError? error;
  final int pendingRevocationCount;
  final bool revocationUnconfirmed;
  final CancelSubscriptionNotice? deletionNotice;
  final bool accountDeleted;
  final bool syncAvailable;
  final bool syncing;
  final String? syncBlockedReason;
  final DateTime? lastSyncAt;
  final SyncLifecycleStatus? lifecycle;
  final int pendingMergeCount;

  bool get emailChallengeStarted => challengeId != null;

  CloudState copyWith({
    bool? enabled,
    bool? initialized,
    bool? initializing,
    bool? busy,
    bool? signedIn,
    bool? requiresReauthentication,
    int? sessionGeneration,
    String? email,
    String? displayName,
    String? currentDeviceId,
    bool clearCurrentDevice = false,
    AccountResponse? account,
    bool clearAccount = false,
    String? challengeId,
    String? challengeEmail,
    bool clearChallenge = false,
    DateTime? challengeExpiresAt,
    DateTime? resendAvailableAt,
    bool clearResend = false,
    int? retryAfterSeconds,
    bool clearRetryAfter = false,
    CloudUiError? error,
    bool clearError = false,
    int? pendingRevocationCount,
    bool? revocationUnconfirmed,
    CancelSubscriptionNotice? deletionNotice,
    bool clearDeletionNotice = false,
    bool? accountDeleted,
    bool? syncAvailable,
    bool? syncing,
    String? syncBlockedReason,
    DateTime? lastSyncAt,
    bool clearSync = false,
    bool clearSyncBlock = false,
    SyncLifecycleStatus? lifecycle,
    int? pendingMergeCount,
  }) => CloudState(
    enabled: enabled ?? this.enabled,
    initialized: initialized ?? this.initialized,
    initializing: initializing ?? this.initializing,
    busy: busy ?? this.busy,
    signedIn: signedIn ?? this.signedIn,
    requiresReauthentication:
        requiresReauthentication ?? this.requiresReauthentication,
    sessionGeneration: sessionGeneration ?? this.sessionGeneration,
    email: email ?? this.email,
    displayName: displayName ?? this.displayName,
    currentDeviceId: clearCurrentDevice
        ? null
        : currentDeviceId ?? this.currentDeviceId,
    account: clearAccount ? null : account ?? this.account,
    challengeId: clearChallenge ? null : challengeId ?? this.challengeId,
    challengeEmail: clearChallenge
        ? null
        : challengeEmail ?? this.challengeEmail,
    challengeExpiresAt: clearChallenge
        ? null
        : challengeExpiresAt ?? this.challengeExpiresAt,
    resendAvailableAt: clearResend
        ? null
        : resendAvailableAt ?? this.resendAvailableAt,
    retryAfterSeconds: clearRetryAfter
        ? null
        : retryAfterSeconds ?? this.retryAfterSeconds,
    error: clearError ? null : error ?? this.error,
    pendingRevocationCount:
        pendingRevocationCount ?? this.pendingRevocationCount,
    revocationUnconfirmed: revocationUnconfirmed ?? this.revocationUnconfirmed,
    deletionNotice: clearDeletionNotice
        ? null
        : deletionNotice ?? this.deletionNotice,
    accountDeleted: accountDeleted ?? this.accountDeleted,
    syncAvailable: syncAvailable ?? this.syncAvailable,
    syncing: clearSync ? false : syncing ?? this.syncing,
    syncBlockedReason: clearSync || clearSyncBlock
        ? null
        : syncBlockedReason ?? this.syncBlockedReason,
    lastSyncAt: clearSync ? null : lastSyncAt ?? this.lastSyncAt,
    lifecycle: clearSync ? null : lifecycle ?? this.lifecycle,
    pendingMergeCount: clearSync
        ? 0
        : pendingMergeCount ?? this.pendingMergeCount,
  );

  @override
  String toString() =>
      'CloudState(initialized: $initialized, signedIn: $signedIn, '
      'busy: $busy, error: $error)';
}
