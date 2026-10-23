import 'dart:async';

import 'package:av_design/av_design.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/format.dart';
import '../../cloud/cloud_models.dart';
import '../../cloud/sync_lifecycle_models.dart';
import '../../l10n/app_localizations.dart';
import 'cloud_state.dart';

/// The development account and sync page, displaying only real account data.
class CloudView extends StatefulWidget {
  const CloudView({
    super.key,
    required this.state,
    required this.onStartEmail,
    required this.onVerify,
    required this.onChangeEmail,
    required this.onReload,
    required this.onLogout,
    required this.onRemoveDevice,
    required this.onDeleteAccount,
    required this.onRetryRevocations,
    this.onSync,
    this.onRebuildFromDevice,
    this.onCancelRebuild,
  });

  final CloudState state;
  final ValueChanged<String> onStartEmail;
  final ValueChanged<String> onVerify;
  final VoidCallback onChangeEmail;
  final VoidCallback onReload;
  final VoidCallback onLogout;
  final ValueChanged<String> onRemoveDevice;
  final VoidCallback onDeleteAccount;
  final VoidCallback onRetryRevocations;
  final VoidCallback? onSync;
  final ValueChanged<bool>? onRebuildFromDevice;
  final VoidCallback? onCancelRebuild;

  @override
  State<CloudView> createState() => _CloudViewState();
}

class _CloudViewState extends State<CloudView> {
  late final TextEditingController _email;
  final _code = TextEditingController();
  Timer? _resendClock;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.state.challengeEmail ?? '');
    _watchResendLimit();
  }

  @override
  void didUpdateWidget(CloudView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.challengeId != widget.state.challengeId) {
      _code.clear();
    }
    if (!oldWidget.state.signedIn && widget.state.signedIn) {
      _email.clear();
      _code.clear();
    }
    if (oldWidget.state.resendAvailableAt != widget.state.resendAvailableAt) {
      _watchResendLimit();
    }
  }

  int get _resendSeconds {
    final until = widget.state.resendAvailableAt;
    if (until == null) return 0;
    final remaining = until.difference(DateTime.now()).inMilliseconds;
    return remaining <= 0 ? 0 : (remaining / 1000).ceil();
  }

  void _watchResendLimit() {
    _resendClock?.cancel();
    if (_resendSeconds == 0) return;
    // This is a server Retry-After deadline, not a visual animation duration
    // or a locally invented sending cooldown.
    _resendClock = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() {});
      if (_resendSeconds == 0) timer.cancel();
    });
  }

  @override
  void dispose() {
    _resendClock?.cancel();
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  bool _stillCurrent(int generation) =>
      mounted &&
      (widget.state.signedIn || widget.state.requiresReauthentication) &&
      widget.state.sessionGeneration == generation &&
      !widget.state.busy;

  bool _sameLifecycle(int sessionGeneration, SyncLifecycleStatus previous) {
    final current = widget.state.lifecycle;
    return _stillCurrent(sessionGeneration) &&
        widget.state.signedIn &&
        !widget.state.syncing &&
        current?.accountId == previous.accountId &&
        current?.deviceId == previous.deviceId &&
        current?.syncGeneration == previous.syncGeneration &&
        current?.spaceState == 'active' &&
        current?.backupState == previous.backupState &&
        current?.rebuild?.attemptId == previous.rebuild?.attemptId &&
        current?.rebuild?.ownerDeviceId == previous.rebuild?.ownerDeviceId;
  }

  Future<void> _rebuild({required bool takeOver}) async {
    final lifecycle = widget.state.lifecycle;
    final callback = widget.onRebuildFromDevice;
    if (lifecycle == null || callback == null) return;
    final generation = widget.state.sessionGeneration;
    final l = AppLocalizations.of(context);
    final confirmed = await showAvConfirm(
      context,
      title: takeOver ? l.cloudRebuildClaimTitle : l.cloudRebuildStartTitle,
      message: takeOver ? l.cloudRebuildClaimNote : l.cloudRebuildStartNote,
      confirm: takeOver ? l.cloudRebuildClaim : l.cloudRebuildStart,
      cancel: l.cancel,
    );
    if (confirmed && _sameLifecycle(generation, lifecycle)) callback(takeOver);
  }

  Future<void> _cancelRebuild() async {
    final lifecycle = widget.state.lifecycle;
    final callback = widget.onCancelRebuild;
    if (lifecycle == null || callback == null) return;
    final generation = widget.state.sessionGeneration;
    final l = AppLocalizations.of(context);
    final confirmed = await showAvConfirm(
      context,
      title: l.cloudRebuildCancelTitle,
      message: l.cloudRebuildCancelNote,
      confirm: l.cloudRebuildCancel,
      cancel: l.cancel,
      destructive: true,
    );
    if (confirmed && _sameLifecycle(generation, lifecycle)) callback();
  }

  Future<void> _logout() async {
    final generation = widget.state.sessionGeneration;
    final l = AppLocalizations.of(context);
    final confirmed = await showAvConfirm(
      context,
      title: l.cloudLogoutTitle,
      message: l.cloudLogoutNote,
      confirm: l.cloudLogout,
      cancel: l.cancel,
    );
    if (confirmed && _stillCurrent(generation)) widget.onLogout();
  }

  Future<void> _deleteAccount() async {
    final generation = widget.state.sessionGeneration;
    final l = AppLocalizations.of(context);
    final first = await showAvConfirm(
      context,
      title: l.cloudDeleteFirstTitle,
      message: l.cloudDeleteFirstNote,
      confirm: l.cloudDeleteContinue,
      cancel: l.cancel,
      destructive: true,
    );
    if (!first || !mounted || !_stillCurrent(generation)) return;
    final second = await showAvConfirm(
      context,
      title: l.cloudDeleteFinalTitle,
      message: l.cloudDeleteFinalNote,
      confirm: l.cloudDeleteAccount,
      cancel: l.cancel,
      destructive: true,
    );
    if (second && _stillCurrent(generation)) widget.onDeleteAccount();
  }

  Future<bool> _removeDevice(CloudDevice device) async {
    final generation = widget.state.sessionGeneration;
    final l = AppLocalizations.of(context);
    final confirmed = await showAvConfirm(
      context,
      title: l.cloudRemoveDeviceTitle(device.name),
      message: l.cloudRemoveDeviceNote,
      confirm: l.cloudRemoveDevice,
      cancel: l.cancel,
      destructive: true,
    );
    if (confirmed && _stillCurrent(generation)) {
      widget.onRemoveDevice(device.id);
    }
    // The row disappears only when the server returns the new device list.
    return false;
  }

  Future<void> _deviceMenu(CloudDevice device) async {
    final generation = widget.state.sessionGeneration;
    final l = AppLocalizations.of(context);
    final chosen = await showAvActions(
      context,
      actions: [AvAction(l.cloudRemoveDevice, destructive: true)],
      cancel: l.cancel,
    );
    if (chosen == 0 && _stillCurrent(generation)) {
      await _removeDevice(device);
    }
  }

  Widget _action(
    BuildContext context,
    String label,
    VoidCallback callback, {
    Key? key,
    bool enabled = true,
    bool destructive = false,
  }) => AvRow(
    key: key,
    title: label,
    titleColor: !enabled || widget.state.busy
        ? context.av.l3
        : destructive
        ? context.av.bad
        : context.av.tint,
    onTap: enabled && !widget.state.busy ? callback : null,
  );

  String _error(AppLocalizations l, CloudUiError error) => switch (error) {
    CloudUiError.disabled => l.cloudErrorDisabled,
    CloudUiError.invalidEmail => l.cloudErrorInvalidEmail,
    CloudUiError.invalidCode => l.cloudErrorInvalidCode,
    CloudUiError.validation => l.cloudErrorValidation,
    CloudUiError.challengeInvalid => l.cloudErrorChallengeInvalid,
    CloudUiError.challengeExpired => l.cloudErrorChallengeExpired,
    CloudUiError.challengeExhausted => l.cloudErrorChallengeExhausted,
    CloudUiError.challengeEnded => l.cloudErrorChallengeEnded,
    CloudUiError.rateLimited =>
      widget.state.retryAfterSeconds == null
          ? l.cloudErrorRateLimited
          : l.cloudErrorRateLimitedWait(widget.state.retryAfterSeconds!),
    CloudUiError.offline => l.cloudErrorOffline,
    CloudUiError.timeout => l.cloudErrorTimeout,
    CloudUiError.protocol => l.cloudErrorProtocol,
    CloudUiError.reauthenticationRequired => l.cloudErrorReauthenticate,
    CloudUiError.sessionRevoked => l.cloudErrorSessionRevoked,
    CloudUiError.deviceNotFound => l.cloudErrorDeviceNotFound,
    CloudUiError.currentDevice => l.cloudErrorCurrentDevice,
    CloudUiError.deleteUnconfirmed => l.cloudErrorDeleteUnconfirmed,
    CloudUiError.revocationPending => l.cloudPendingRevocationsNote,
    CloudUiError.revocationUnconfirmed => l.cloudRevocationUnconfirmed,
    CloudUiError.server => l.cloudErrorServer,
    CloudUiError.unknown => l.cloudErrorUnknown,
  };

  String _source(AppLocalizations l, PurchaseSource source) => switch (source) {
    PurchaseSource.apple => l.cloudAppleSource,
    PurchaseSource.google => l.cloudGoogleSource,
    PurchaseSource.web => l.cloudWebSource,
  };

  String _os(AppLocalizations l, DeviceOs os) => switch (os) {
    DeviceOs.ios => l.cloudDeviceIos,
    DeviceOs.android => l.cloudDeviceAndroid,
    DeviceOs.macos => l.cloudDeviceMacos,
    DeviceOs.windows => l.cloudDeviceWindows,
    DeviceOs.linux => l.cloudDeviceLinux,
  };

  IconData _deviceIcon(DeviceOs os) => switch (os) {
    DeviceOs.ios || DeviceOs.android => Symbols.smartphone_rounded,
    DeviceOs.macos ||
    DeviceOs.windows ||
    DeviceOs.linux => Symbols.computer_rounded,
  };

  String _time(DateTime time) =>
      DateFormat('yyyy-MM-dd HH:mm').format(time.toLocal());

  String _syncBlock(AppLocalizations l, String reason) => switch (reason) {
    'NO_ENTITLEMENT' => l.cloudSyncNoEntitlement,
    'DEVICE_LIMIT' => l.cloudSyncDeviceLimit,
    'SCHEMA_UNSUPPORTED' => l.cloudSyncSchemaUnsupported,
    'AUTH_REQUIRED' => l.cloudErrorReauthenticate,
    'SESSION_REVOKED' => l.cloudErrorSessionRevoked,
    'OFFLINE' => l.cloudErrorOffline,
    'RATE_LIMITED' => l.cloudErrorRateLimited,
    'SYNC_QUOTA_EXCEEDED' => l.cloudSyncQuotaExceeded,
    'VALIDATION' => l.cloudSyncValidation,
    'OWNERSHIP' => l.cloudSyncOwnership,
    'VAULT_LOCKED' => l.errorVaultLocked,
    'SYNC_REBUILD_REQUIRED' => l.cloudBackupRebuildRequired,
    'SYNC_REBUILD_IN_PROGRESS' => l.cloudBackupRebuilding,
    'SYNC_GENERATION_MISMATCH' => l.cloudSyncGenerationChanged,
    'SYNC_SNAPSHOT_CHANGED' => l.cloudSyncSnapshotChanged,
    'SYNC_ENTITLEMENT_UNVERIFIED' => l.cloudSyncVerificationPending,
    'SYNC_SPACE_RETIRED' => l.cloudBackupRetired,
    'SYNC_LEGACY_SCOPE_UNVERIFIED' => l.cloudSyncLegacyUnverified,
    'SYNC_REBUILD_INCOMPLETE' => l.cloudRebuildIncomplete,
    'SYNC_REBUILD_ATTEMPT_MISMATCH' ||
    'SYNC_REBUILD_OWNER_CHANGED' ||
    'SYNC_REBUILD_MANIFEST_MISMATCH' ||
    'SYNC_REBUILD_NOT_FOUND' => l.cloudRebuildChanged,
    _ => l.cloudErrorServer,
  };

  AvSettingsSection _lifecycle(BuildContext context, AppLocalizations l) {
    final state = widget.state;
    final lifecycle = state.lifecycle!;
    final attempt = lifecycle.rebuild;
    final owner = attempt?.ownerDeviceId == state.currentDeviceId;
    final canRebuild = lifecycle.spaceState == 'active';
    final cleanup = lifecycle.cleanup;
    return AvSettingsSection(
      header: l.cloudBackupTitle,
      rows: [
        AvRow(
          key: const ValueKey('cloud-backup-state'),
          title: switch (lifecycle.spaceState) {
            'retained' => l.cloudBackupRetained,
            'verificationPending' => l.cloudSyncVerificationPending,
            'retired' => l.cloudBackupRetired,
            _ => switch (lifecycle.backupState) {
              'ready' => l.cloudBackupReady,
              'rebuildRequired' => l.cloudBackupRebuildRequired,
              'rebuilding' => l.cloudBackupRebuilding,
              _ => l.cloudBackupNone,
            },
          },
        ),
        if (lifecycle.retentionUntil != null)
          AvRow(
            key: const ValueKey('cloud-retention-until'),
            title: l.cloudBackupRetentionUntil(
              _time(lifecycle.retentionUntil!),
            ),
          ),
        if (state.pendingMergeCount > 0)
          AvRow(
            key: const ValueKey('cloud-pending-merge'),
            title: l.cloudPendingMerge(state.pendingMergeCount),
          ),
        if (attempt != null) ...[
          AvRow(
            key: const ValueKey('cloud-rebuild-progress'),
            title: l.cloudRebuildProgress(
              attempt.stagedRecordCount,
              attempt.recordCount,
            ),
            subtitle: owner ? l.cloudRebuildThisDevice : l.cloudRebuildWaiting,
          ),
          if (canRebuild && owner && widget.onSync != null)
            _action(
              context,
              state.syncing ? l.cloudSyncing : l.cloudRebuildResume,
              widget.onSync!,
              key: const ValueKey('cloud-rebuild-resume'),
              enabled: !state.syncing,
            ),
          if (canRebuild && owner && widget.onCancelRebuild != null)
            _action(
              context,
              l.cloudRebuildCancel,
              _cancelRebuild,
              key: const ValueKey('cloud-rebuild-cancel'),
              enabled: !state.syncing,
              destructive: true,
            ),
          if (canRebuild && !owner && widget.onRebuildFromDevice != null)
            _action(
              context,
              l.cloudRebuildClaim,
              () => _rebuild(takeOver: true),
              key: const ValueKey('cloud-rebuild-claim'),
              enabled: !state.syncing,
            ),
        ],
        if (canRebuild &&
            lifecycle.backupState == 'rebuildRequired' &&
            widget.onRebuildFromDevice != null)
          _action(
            context,
            l.cloudRebuildStart,
            () => _rebuild(takeOver: false),
            key: const ValueKey('cloud-rebuild-start'),
            enabled: !state.syncing,
          ),
        if (cleanup.latestRetiredGeneration != null) ...[
          AvRow(
            key: const ValueKey('cloud-cleanup-online'),
            title: l.cloudCleanupOnline(switch (cleanup.onlineState) {
              'pending' => l.cloudCleanupPending,
              'running' => l.cloudCleanupRunning,
              'failed' => l.cloudCleanupFailed,
              'complete' => l.cloudCleanupComplete,
              _ => l.cloudCleanupNone,
            }),
          ),
          AvRow(
            key: const ValueKey('cloud-cleanup-key'),
            title: l.cloudCleanupKey(switch (cleanup.keyState) {
              'pending' => l.cloudCleanupPending,
              'waiting' => l.cloudCleanupWaiting,
              'failed' => l.cloudCleanupFailed,
              'deleted' => l.cloudCleanupKeyDeleted,
              'destroyed' => l.cloudCleanupKeyDestroyed,
              _ => l.cloudCleanupNone,
            }),
            subtitle: cleanup.keyState == 'deleted'
                ? l.cloudCleanupKeyDeletedNote
                : null,
          ),
        ],
      ],
      footer: l.cloudBackupLocalNote,
    );
  }

  bool get _validEmail =>
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(_email.text.trim());

  bool get _validCode => RegExp(r'^[0-9]{6}$').hasMatch(_code.text);

  void _submitLogin() {
    if (widget.state.busy) return;
    if (widget.state.emailChallengeStarted) {
      if (_validCode) widget.onVerify(_code.text);
    } else if (_validEmail && _resendSeconds == 0) {
      widget.onStartEmail(_email.text.trim());
    }
  }

  Widget _login(AppLocalizations l) {
    final state = widget.state;
    final started = state.emailChallengeStarted;
    final recipient = state.challengeEmail ?? _email.text.trim();
    return AvLoginForm(
      title: started ? l.cloudCheckInbox : l.cloudLoginTitle,
      subtitle: started ? l.cloudCodeSentTo : l.cloudLoginIntro,
      emailLabel: l.cloudEmailAddress,
      emailPlaceholder: l.cloudEmailPlaceholder,
      codeLabel: l.cloudSixDigitCode,
      submitLabel: started ? l.cloudVerifyCode : l.cloudSendCode,
      helper: state.busy
          ? l.cloudWorking
          : started && state.challengeExpiresAt != null
          ? l.cloudCodeExpires(_time(state.challengeExpiresAt!))
          : started
          ? l.cloudCodeHelper
          : _resendSeconds > 0
          ? l.cloudResendWait(_resendSeconds)
          : l.cloudLoginNote,
      emailController: _email,
      codeController: _code,
      showCode: started,
      submitEnabled: started ? _validCode : _validEmail && _resendSeconds == 0,
      busy: state.busy,
      onSubmit: _submitLogin,
      onChanged: () => setState(() {}),
      recipient: started ? recipient : null,
      error: state.error == null ? null : _error(l, state.error!),
      clearEmailLabel: l.cloudClearEmail,
      resendLabel: _resendSeconds > 0
          ? l.cloudResendWait(_resendSeconds)
          : l.cloudResendCode,
      onResend: recipient.isNotEmpty && _resendSeconds == 0
          ? () => widget.onStartEmail(recipient)
          : null,
      changeEmailLabel: l.cloudChangeEmail,
      onChangeEmail: widget.onChangeEmail,
      logoutLabel: state.requiresReauthentication ? l.cloudLogout : null,
      onLogout: state.requiresReauthentication ? _logout : null,
      logoutKey: const ValueKey('cloud-logout'),
      emailKey: const ValueKey('cloud-email'),
      codeKey: const ValueKey('cloud-code'),
      submitKey: ValueKey(started ? 'cloud-verify' : 'cloud-send'),
      resendKey: const ValueKey('cloud-send'),
    );
  }

  List<AvSettingsSection> _notices(BuildContext context, AppLocalizations l) {
    final state = widget.state;
    return [
      if (state.accountDeleted)
        AvSettingsSection(
          rows: [
            AvRow(title: l.cloudAccountDeleted),
            if (state.deletionNotice?.required ?? false)
              AvRow(
                title: l.cloudCancelSubscription(
                  state.deletionNotice!.sources
                      .map((s) => _source(l, s))
                      .join(' / '),
                ),
              ),
          ],
        ),
      if (state.pendingRevocationCount > 0)
        AvSettingsSection(
          header: l.cloudPendingRevocations(state.pendingRevocationCount),
          footer: l.cloudPendingRevocationsNote,
          rows: [
            _action(
              context,
              l.cloudRetryRevocations,
              widget.onRetryRevocations,
            ),
          ],
        ),
      if (state.revocationUnconfirmed &&
          state.error != CloudUiError.revocationUnconfirmed)
        AvSettingsSection(rows: [AvRow(title: l.cloudRevocationUnconfirmed)]),
    ];
  }

  Widget _device(BuildContext context, AppLocalizations l, CloudDevice device) {
    final state = widget.state;
    final current = device.id == state.currentDeviceId;
    final row = AvRow(
      key: ValueKey('cloud-device-${device.id}'),
      leading: AvIcon(_deviceIcon(device.os), color: context.av.l2),
      title: device.name,
      subtitle: [
        _os(l, device.os),
        current ? l.cloudThisDevice : l.cloudLastSeen(_time(device.lastSeenAt)),
        device.syncActive ? l.cloudSyncSlotActive : l.cloudNotSyncing,
      ].join(' · '),
      onSecondaryTap: current || state.busy ? null : () => _deviceMenu(device),
      onLongPress: current || state.busy ? null : () => _deviceMenu(device),
    );
    if (current) return row;
    return Semantics(
      customSemanticsActions: {
        CustomSemanticsAction(label: l.cloudRemoveDevice): () =>
            state.busy ? null : _removeDevice(device),
      },
      child: Dismissible(
        key: ValueKey('cloud-remove-${device.id}'),
        direction: state.busy
            ? DismissDirection.none
            : DismissDirection.endToStart,
        confirmDismiss: (_) => _removeDevice(device),
        background: ColoredBox(
          color: context.av.bad,
          child: AvRow(title: l.cloudRemoveDevice, titleColor: context.av.l1),
        ),
        child: row,
      ),
    );
  }

  List<AvSettingsSection> _account(BuildContext context, AppLocalizations l) {
    final state = widget.state;
    final account = state.account;
    final entitlement = account?.entitlement;
    final lifecycle = state.lifecycle;
    final regularSync =
        lifecycle == null ||
        lifecycle.spaceState == 'noSpace' ||
        (lifecycle.spaceState == 'active' && lifecycle.backupState == 'ready');
    return [
      AvSettingsSection(
        header: l.cloudAccount,
        rows: [
          AvRow(
            leading: AvIconTile(Symbols.person_rounded, AvHues.blue),
            title: state.displayName.isEmpty
                ? l.cloudSignedIn
                : state.displayName,
            subtitle: state.email.isEmpty ? null : state.email,
          ),
          _action(
            context,
            l.cloudReload,
            widget.onReload,
            key: const ValueKey('cloud-reload'),
          ),
        ],
      ),
      if (account != null)
        AvSettingsSection(
          header: l.cloudEntitlement,
          rows: [
            if (entitlement == null)
              AvRow(
                leading: AvIcon(
                  Symbols.cloud_off_rounded,
                  color: context.av.l2,
                ),
                title: l.cloudFreeAccount,
                subtitle: state.syncAvailable
                    ? l.cloudSyncFreeAccountNote
                    : l.cloudFreeAccountNote,
              )
            else
              AvRow(
                title: entitlement.plan == EntitlementPlan.monthly
                    ? l.cloudMonthly
                    : l.cloudYearly,
                subtitle: l.cloudEntitlementUntil(switch (entitlement.status) {
                  'active' => l.cloudEntitlementActive,
                  'expired' => l.cloudEntitlementExpired,
                  'revoked' => l.cloudEntitlementRevoked,
                  _ => l.cloudEntitlementUnknown,
                }, formatDate(entitlement.expiresAt)),
                value: _source(l, entitlement.source),
              ),
          ],
        ),
      if (entitlement != null && state.syncAvailable && widget.onSync != null)
        AvSettingsSection(
          header: l.cloudSyncTitle,
          rows: [
            AvRow(
              title: l.cloudLastSync,
              value: state.lastSyncAt == null
                  ? l.cloudNeverSynced
                  : _time(state.lastSyncAt!),
            ),
            if (state.syncBlockedReason != null)
              AvRow(
                key: const ValueKey('cloud-sync-block'),
                title: _syncBlock(l, state.syncBlockedReason!),
              ),
            if (regularSync)
              _action(
                context,
                state.syncing ? l.cloudSyncing : l.cloudSyncNow,
                widget.onSync!,
                key: const ValueKey('cloud-sync'),
                enabled: !state.syncing,
              ),
          ],
        ),
      if (state.lifecycle != null) _lifecycle(context, l),
      if (account != null)
        AvSettingsSection(
          header: l.cloudDevices(
            account.syncActiveDeviceCount,
            account.deviceLimit,
          ),
          rows: [
            for (final device in account.devices) _device(context, l, device),
          ],
          footer: l.cloudDeviceRemoveHint,
          right: true,
        ),
      AvSettingsSection(
        header: l.cloudAccount,
        right: true,
        rows: [
          _action(
            context,
            l.cloudLogout,
            _logout,
            key: const ValueKey('cloud-logout'),
          ),
          _action(
            context,
            l.cloudDeleteAccount,
            _deleteAccount,
            key: const ValueKey('cloud-delete'),
            destructive: true,
          ),
        ],
        footer: l.cloudDeleteFirstNote,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final l = AppLocalizations.of(context);
    final notices = _notices(context, l);
    if (!state.signedIn && state.enabled && !state.initializing) {
      return AvLoginPage(
        backLabel: l.tabTools,
        form: _login(l),
        notices: notices.isEmpty
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final notice in notices) ...[
                    if (notice.header != null) AvSectionHeader(notice.header!),
                    AvGroup(children: notice.rows),
                    if (notice.footer != null) AvSectionFooter(notice.footer!),
                  ],
                ],
              ),
      );
    }
    return AvSettingsPage(
      title: l.cloudTitle,
      backLabel: l.tabTools,
      sections: [
        if (state.initializing || state.busy)
          AvSettingsSection(
            rows: [
              AvRow(
                title: state.initializing ? l.cloudLoading : l.cloudWorking,
                trailing: AvSpin(
                  child: AvIcon(
                    Symbols.progress_activity_rounded,
                    color: context.av.tint,
                  ),
                ),
              ),
            ],
          ),
        if (state.error != null)
          AvSettingsSection(
            rows: [
              AvRow(
                leading: AvIcon(
                  Symbols.warning_rounded,
                  color: context.av.warn,
                ),
                title: _error(l, state.error!),
              ),
            ],
          ),
        ...notices,
        if (state.enabled && !state.initializing && state.signedIn)
          ..._account(context, l),
      ],
    );
  }
}
