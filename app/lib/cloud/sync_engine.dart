import 'dart:async';

import '../data/database/database.dart';
import '../data/ids.dart';
import '../data/repositories/sync_projection.dart';
import '../data/repositories/sync_repository.dart';
import '../data/vault/vault.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'sync_lifecycle_models.dart';
import 'sync_models.dart';

final class SyncStatus {
  const SyncStatus({
    this.accountId,
    this.busy = false,
    this.blockedReason,
    this.lastSyncAt,
    this.lifecycle,
    this.pendingMergeCount = 0,
  });
  final String? accountId;
  final bool busy;
  final String? blockedReason;
  final DateTime? lastSyncAt;
  final SyncLifecycleStatus? lifecycle;
  final int pendingMergeCount;
  @override
  String toString() => 'SyncStatus(busy: $busy, reason: $blockedReason)';
}

/// One serial worker per foreground application. Database watches signal
/// committed changes; the durable outbox is the authority after a restart.
final class SyncEngine {
  SyncEngine({
    required this.auth,
    required this.repository,
    required this.projection,
    required this.db,
    this.lifecycleEnabled = false,
  });
  final AuthService auth;
  final SyncRepository repository;
  final SyncProjection projection;
  final AppDatabase db;
  final bool lifecycleEnabled;
  final _statuses = StreamController<SyncStatus>.broadcast();
  SyncStatus _status = const SyncStatus();
  SyncLifecycleStatus? _lifecycle;
  StreamSubscription<Object?>? _edits;
  StreamSubscription<Object?>? _documents;
  StreamSubscription<Object?>? _sessions;
  Timer? _debounce;
  Timer? _periodic;
  Timer? _retry;
  Future<void>? _running;
  bool _disposed = false;
  bool _foreground = true;
  bool _started = false;
  bool _rerun = false;
  int _epoch = 0;
  int _failures = 0;
  _RebuildIntent? _requestedRebuild;

  Future<void> rebuildFromDevice({bool takeOver = false}) =>
      _requestRebuild(takeOver ? 'claim' : 'start');

  Future<void> cancelRebuild() => _requestRebuild('cancel');

  Future<void> _requestRebuild(String action) async {
    final lifecycle = _lifecycle;
    if (!lifecycleEnabled ||
        _disposed ||
        lifecycle == null ||
        lifecycle.syncGeneration == null ||
        _requestedRebuild != null) {
      throw const _LifecycleChanged();
    }
    final intent = _RebuildIntent(action, lifecycle, auth.generation);
    _requestedRebuild = intent;
    try {
      final active = _running;
      if (active != null) await active;
      if (_disposed || auth.generation != intent.authGeneration) {
        throw const StaleSyncIdentity();
      }
      await runNow();
      final error = await intent.completed.future;
      if (error is Exception) throw error;
      if (error is Error) throw error;
    } finally {
      if (identical(_requestedRebuild, intent)) _requestedRebuild = null;
    }
  }

  Stream<SyncStatus> watch() async* {
    yield _status;
    yield* _statuses.stream;
  }

  void start() {
    if (_started || _disposed) return;
    _started = true;
    _edits = db
        .select(db.syncMeta)
        .watch()
        .map(
          (rows) => rows
              .where((r) => r.dirty && r.mutationId != null)
              .map((r) => '${r.accountId}:${r.mutationId}')
              .join('|'),
        )
        .distinct()
        .listen((_) => trigger());
    _documents = db
        .select(db.syncDocuments)
        .watch()
        .map(
          (rows) => rows
              .map(
                (r) =>
                    '${r.documentId}:${r.localEditedAt}:${r.localDeleted}:${r.localPayloadSecretId}',
              )
              .join('|'),
        )
        .distinct()
        .listen((_) => trigger());
    _sessions = db
        .select(db.cloudSession)
        .watch()
        .asyncMap((_) async {
          final identity = await repository.capture(0);
          return identity == null
              ? ''
              : '${identity.accountId}:${identity.sessionId}';
        })
        .distinct()
        .listen(
          (_) {
            _epoch++;
            trigger(immediate: true);
          },
          onError: (Object error) {
            _emit(SyncStatus(blockedReason: _reason(error)));
          },
        );
    _periodic = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_foreground) trigger(immediate: true);
    });
    trigger(immediate: true);
  }

  void foreground(bool active) {
    _foreground = active;
    if (active) trigger(immediate: true);
  }

  void trigger({bool immediate = false}) {
    if (_disposed || !_foreground) return;
    _debounce?.cancel();
    _debounce = Timer(
      immediate ? Duration.zero : const Duration(seconds: 2),
      () {
        unawaited(runNow());
      },
    );
  }

  Future<void> runNow() {
    if (_disposed) return Future<void>.value();
    final active = _running;
    if (active != null) {
      _rerun = true;
      return active;
    }
    late final Future<void> operation;
    operation = _run().whenComplete(() {
      if (identical(_running, operation)) {
        _running = null;
        if (_rerun && !_disposed && _foreground) {
          _rerun = false;
          trigger(immediate: true);
        }
      }
    });
    _running = operation;
    return operation;
  }

  void _emit(SyncStatus value) {
    if (value.accountId == null || value.accountId != _lifecycle?.accountId) {
      _lifecycle = value.lifecycle;
    } else if (value.lifecycle != null) {
      _lifecycle = value.lifecycle;
    }
    value = SyncStatus(
      accountId: value.accountId,
      busy: value.busy,
      blockedReason: value.blockedReason,
      lastSyncAt: value.lastSyncAt,
      lifecycle: value.lifecycle ?? _lifecycle,
      pendingMergeCount: value.pendingMergeCount,
    );
    _status = value;
    if (!_disposed) _statuses.add(value);
  }

  Future<void> _run() async {
    final intent = _requestedRebuild?.completed.isCompleted == false
        ? _requestedRebuild
        : null;
    final generation = auth.generation;
    final epoch = _epoch;
    SyncIdentity? captured;
    try {
      captured = await repository.capture(epoch);
    } on Object catch (error) {
      intent?.reject(error);
      _emit(SyncStatus(blockedReason: _reason(error)));
      return;
    }
    final initialIdentity = captured;
    if (initialIdentity == null) {
      _emit(const SyncStatus());
      intent?.reject(const CloudSignedOutException());
      return;
    }
    var identity = initialIdentity;
    bool current() =>
        !_disposed && auth.generation == generation && _epoch == epoch;
    void response<T>(CloudAuthorizedSyncResult<T> result) {
      if (!current() ||
          result.generation != generation ||
          result.accountId != identity.accountId ||
          result.sessionId != identity.sessionId) {
        throw const StaleSyncIdentity();
      }
    }

    late SyncStateRow state;
    try {
      state = await repository.state(identity.accountId);
    } on Object catch (error) {
      intent?.reject(error);
      _emit(
        SyncStatus(
          accountId: identity.accountId,
          blockedReason: _reason(error),
        ),
      );
      return;
    }
    _emit(
      SyncStatus(
        accountId: identity.accountId,
        busy: true,
        lastSyncAt: state.lastSyncAt == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                state.lastSyncAt!,
                isUtc: true,
              ),
      ),
    );
    try {
      if (lifecycleEnabled) {
        final prepared = await _prepareLifecycle(
          identity,
          current,
          generation,
          adopted: (value) => identity = value,
          intent: intent,
        );
        if (prepared == null) {
          intent?.reject(const _LifecycleChanged());
          return;
        }
        identity = prepared;
        state = await repository.state(identity.accountId);
      } else {
        final activated = await auth.authorizedSync(
          (api, s) => api.activateSync(accessToken: s.accessToken),
        );
        response(activated);
        if (activated.value.deviceId != activated.deviceId) {
          throw const StaleSyncIdentity();
        }
      }
      await repository.resetBootstrapCursor(identity, current);
      await projection.captureAll();
      if (lifecycleEnabled && !state.bootstrapCompleted) {
        await _fullPull(identity, current, generation);
        state = await repository.state(identity.accountId);
      }
      final refreshedState = await repository.state(identity.accountId);
      await repository.reconcileAccount(identity.accountId);
      var cursor = refreshedState.cursor;
      while (true) {
        final fetched = await auth.authorizedSync<SyncPullResponse>(
          (api, s) async => lifecycleEnabled
              ? (await api.pullSyncV2(
                  accessToken: s.accessToken,
                  syncGeneration: identity.syncGeneration!,
                  cursor: cursor,
                )).data
              : await api.pullSync(accessToken: s.accessToken, cursor: cursor),
        );
        response(fetched);
        final page = fetched.value;
        await repository.commitPullPage(
          identity,
          current,
          records: [for (final r in page.records) r.toJson()],
          nextCursor: page.nextCursor,
          project: projection.project,
          reconcile: state.bootstrapCompleted
              ? () => projection.reconcile(identity.accountId)
              : null,
        );
        cursor = page.nextCursor;
        if (!page.hasMore) break;
      }
      if (lifecycleEnabled && _lifecycle?.spaceOrigin == 'rebuilt') {
        await repository.completeBootstrap(
          identity,
          current,
          merge: () => projection.reconcile(identity.accountId),
        );
      } else if (!state.bootstrapCompleted) {
        await repository.completeBootstrap(
          identity,
          current,
          merge: () => projection.bootstrap(identity.accountId),
        );
      } else {
        await repository.completeBootstrap(
          identity,
          current,
          merge: () => projection.bootstrap(
            identity.accountId,
            matchSubscriptions: false,
          ),
        );
      }
      while (true) {
        final frozen = await repository.preparePush(
          identity,
          current,
          maxBodyBytes: lifecycleEnabled
              ? syncBodyMaxBytes - 256
              : syncBodyMaxBytes,
          validate: (mutation) async {
            await projection.assertUploadOwner(mutation, identity.accountId);
            SyncMutation.fromJson(mutation.envelope);
          },
        );
        if (frozen.isEmpty) break;
        final mutations = [
          for (final f in frozen) SyncMutation.fromJson(f.envelope),
        ];
        final pushed = await auth.authorizedSync<SyncPushResponse>(
          (api, s) async => lifecycleEnabled
              ? (await api.pushSyncV2(
                  accessToken: s.accessToken,
                  syncGeneration: identity.syncGeneration!,
                  rebuildAttemptId: null,
                  mutations: mutations,
                )).data
              : await api.pushSync(
                  accessToken: s.accessToken,
                  mutations: mutations,
                ),
        );
        response(pushed);
        final result = pushed.value;
        await repository.commitPushPrefix(
          identity,
          current,
          sent: frozen,
          results: [
            for (final r in result.results)
              switch (r) {
                SyncAppliedResult() => {
                  'mutationId': r.mutationId,
                  'status': 'applied',
                  'revision': r.revision,
                  'editedAt': r.editedAt,
                },
                SyncSupersededResult() => {
                  'mutationId': r.mutationId,
                  'status': 'superseded',
                  'record': r.record.toJson(),
                },
              },
          ],
          project: projection.project,
          reconcile: () => projection.reconcile(identity.accountId),
        );
      }
      await repository.setBlocked(identity, current, null, success: true);
      _failures = 0;
      _retry?.cancel();
      final done = await repository.state(identity.accountId);
      _emit(
        SyncStatus(
          accountId: identity.accountId,
          lastSyncAt: DateTime.fromMillisecondsSinceEpoch(
            done.lastSyncAt!,
            isUtc: true,
          ),
          pendingMergeCount: lifecycleEnabled
              ? await repository.pendingMergeCount(identity.accountId)
              : 0,
        ),
      );
      intent?.resolve();
    } on StaleSyncIdentity {
      intent?.reject(const StaleSyncIdentity());
      if (!_disposed) trigger(immediate: true);
    } on CloudSessionChangedException {
      intent?.reject(const CloudSessionChangedException());
      if (!_disposed) trigger(immediate: true);
    } on CloudSignedOutException {
      intent?.reject(const CloudSignedOutException());
      _emit(const SyncStatus());
    } on Object catch (caught) {
      final error = caught is _ScopedSyncFailure ? caught.cause : caught;
      if (caught is _ScopedSyncFailure) identity = caught.identity;
      intent?.reject(error);
      if (!current()) return;
      final reason = _reason(error);
      try {
        await repository.setBlocked(identity, current, reason);
      } on StaleSyncIdentity {
        return;
      }
      _emit(
        SyncStatus(
          accountId: identity.accountId,
          blockedReason: reason,
          lastSyncAt: _status.lastSyncAt,
        ),
      );
      _retry?.cancel();
      if (error is CloudApiException && error.retryAfter != null) {
        _retry = Timer(error.retryAfter!, () => trigger(immediate: true));
      } else if (reason == 'OFFLINE' || reason == 'INTERNAL_ERROR') {
        _failures++;
        final seconds = (5 * (1 << _failures.clamp(0, 6))).clamp(5, 300);
        _retry = Timer(
          Duration(seconds: seconds),
          () => trigger(immediate: true),
        );
      }
    }
  }

  T _authorizedValue<T>(
    CloudAuthorizedSyncResult<T> result,
    SyncIdentity identity,
    bool Function() current,
    int authGeneration,
  ) {
    if (!current() ||
        result.generation != authGeneration ||
        result.accountId != identity.accountId ||
        result.sessionId != identity.sessionId) {
      throw const StaleSyncIdentity();
    }
    return result.value;
  }

  Future<SyncLifecycleStatus> _readLifecycle(
    SyncIdentity identity,
    bool Function() current,
    int authGeneration,
  ) async {
    final response = await auth.authorizedSync(
      (api, session) => api.syncLifecycle(accessToken: session.accessToken),
    );
    final value = _authorizedValue(response, identity, current, authGeneration);
    if (value.accountId != response.accountId ||
        value.deviceId != response.deviceId) {
      throw const StaleSyncIdentity();
    }
    _lifecycle = value;
    return value;
  }

  Future<SyncIdentity?> _prepareLifecycle(
    SyncIdentity original,
    bool Function() current,
    int authGeneration, {
    required void Function(SyncIdentity) adopted,
    _RebuildIntent? intent,
  }) async {
    var lifecycle = await _readLifecycle(original, current, authGeneration);
    // Retirement and uncertain purchase authority are never interpreted as
    // permission to create a new space or change the local key.
    if (lifecycle.spaceState == 'retired' ||
        lifecycle.spaceState == 'verificationPending') {
      final reason = lifecycle.spaceState == 'retired'
          ? 'SYNC_SPACE_RETIRED'
          : 'SYNC_ENTITLEMENT_UNVERIFIED';
      await repository.setBlocked(original, current, reason);
      _emit(
        SyncStatus(
          accountId: original.accountId,
          blockedReason: reason,
          lifecycle: lifecycle,
          pendingMergeCount: await repository.pendingMergeCount(
            original.accountId,
          ),
        ),
      );
      return null;
    }
    if (lifecycle.syncGeneration == null && lifecycle.spaceState == 'noSpace') {
      final initial = await auth.authorizedSync(
        (api, session) => api.activateSyncV2(
          accessToken: session.accessToken,
          syncGeneration: null,
        ),
      );
      final activated = _authorizedValue(
        initial,
        original,
        current,
        authGeneration,
      );
      if (activated.deviceId != initial.deviceId) {
        throw const StaleSyncIdentity();
      }
      lifecycle = await _readLifecycle(original, current, authGeneration);
      if (lifecycle.syncGeneration != activated.syncGeneration) {
        throw const _LifecycleChanged();
      }
    }
    final generation = lifecycle.syncGeneration;
    if (generation == null) throw const _LifecycleChanged();
    var identity = await repository.adoptGeneration(
      original,
      current,
      generation,
      backupState: lifecycle.backupState,
      preserveLegacyHistory: lifecycle.spaceOrigin == 'legacy',
      retireLegacyHistory: lifecycle.spaceOrigin == 'rebuilt',
    );
    adopted(identity);
    if (lifecycle.spaceState == 'active') {
      final activatedResponse = await auth.authorizedSync(
        (api, session) => api.activateSyncV2(
          accessToken: session.accessToken,
          syncGeneration: generation,
        ),
      );
      final activated = _authorizedValue(
        activatedResponse,
        identity,
        current,
        authGeneration,
      );
      if (activated.deviceId != activatedResponse.deviceId) {
        throw const StaleSyncIdentity();
      }
      if (activated.backupState != lifecycle.backupState ||
          activated.rebuildAttemptId != lifecycle.rebuild?.attemptId) {
        throw const _LifecycleChanged();
      }
      final pending = await repository.readRebuildControl(identity);
      if (pending != null) {
        identity = await _sendRebuildControl(
          identity,
          current,
          authGeneration,
          SyncRebuildControlRequest.fromJson(pending),
        );
        adopted(identity);
        lifecycle = await _readLifecycle(identity, current, authGeneration);
      }
      if (identity.rebuildLocalAttemptId != null &&
          (lifecycle.backupState == 'ready' ||
              lifecycle.rebuild?.attemptId != identity.rebuildAttemptId ||
              lifecycle.rebuild?.ownerDeviceId != lifecycle.deviceId)) {
        // A different device may already have published this generation.
        // Quarantine our abandoned attempt before joining its ready backup.
        identity = await db.transaction(() async {
          final next = await repository.cancelRebuild(identity, current);
          return repository.adoptGeneration(
            next,
            current,
            generation,
            backupState: lifecycle.backupState,
          );
        });
        adopted(identity);
      }
      if (intent != null) {
        if (!intent.matches(lifecycle, authGeneration)) {
          throw const _LifecycleChanged();
        }
        if (intent.action == 'cancel') {
          final attempt = lifecycle.rebuild;
          if (attempt == null ||
              attempt.ownerDeviceId != lifecycle.deviceId ||
              identity.rebuildAttemptId != attempt.attemptId) {
            throw const _LifecycleChanged();
          }
          identity = await _sendRebuildControl(
            identity,
            current,
            authGeneration,
            SyncRebuildControlRequest.cancel(
              operationId: newId(),
              syncGeneration: generation,
              expectedAttemptId: attempt.attemptId,
            ),
          );
          adopted(identity);
          intent.resolve();
          lifecycle = await _readLifecycle(identity, current, authGeneration);
        } else {
          final attempt = lifecycle.rebuild;
          if (lifecycle.backupState == 'rebuilding' &&
              attempt?.ownerDeviceId == lifecycle.deviceId &&
              attempt?.attemptId == identity.rebuildAttemptId) {
            // A confirmed retry resumes the immutable attempt already owned.
          } else {
            if ((intent.action == 'start' &&
                    lifecycle.backupState != 'rebuildRequired') ||
                (intent.action == 'claim' &&
                    lifecycle.backupState != 'rebuilding')) {
              throw const _LifecycleChanged();
            }
            final frozen = await repository.beginRebuild(
              identity,
              current,
              newId(),
              replaceExisting: true,
              prepare: () => projection.prepareRebuild(identity.accountId),
              validate: (mutation) async {
                await projection.assertUploadOwner(
                  mutation,
                  identity.accountId,
                );
                SyncMutation.fromJson(mutation.envelope);
              },
            );
            identity = frozen.identity;
            adopted(identity);
            final manifest = SyncRebuildManifest.fromJson(frozen.toJson());
            final request = intent.action == 'claim'
                ? SyncRebuildControlRequest.claim(
                    operationId: newId(),
                    syncGeneration: generation,
                    expectedAttemptId: attempt!.attemptId,
                    manifest: manifest,
                  )
                : SyncRebuildControlRequest.start(
                    operationId: newId(),
                    syncGeneration: generation,
                    manifest: manifest,
                  );
            identity = await _sendRebuildControl(
              identity,
              current,
              authGeneration,
              request,
            );
            adopted(identity);
            lifecycle = await _readLifecycle(identity, current, authGeneration);
          }
        }
      }
      if (lifecycle.backupState == 'rebuilding' &&
          lifecycle.rebuild?.ownerDeviceId == lifecycle.deviceId &&
          lifecycle.rebuild?.attemptId == identity.rebuildAttemptId) {
        identity = await _uploadRebuild(identity, current, authGeneration);
        adopted(identity);
        lifecycle = await _readLifecycle(identity, current, authGeneration);
      }
    }
    final reason = switch (lifecycle.spaceState) {
      'retained' => 'NO_ENTITLEMENT',
      'verificationPending' => 'SYNC_ENTITLEMENT_UNVERIFIED',
      'retired' => 'SYNC_SPACE_RETIRED',
      'active' => switch (lifecycle.backupState) {
        'ready' => null,
        'rebuilding' => 'SYNC_REBUILD_IN_PROGRESS',
        _ => 'SYNC_REBUILD_REQUIRED',
      },
      _ => 'SYNC_REBUILD_REQUIRED',
    };
    if (reason != null) {
      await repository.setBlocked(identity, current, reason);
      _emit(
        SyncStatus(
          accountId: identity.accountId,
          blockedReason: reason,
          lastSyncAt: _status.lastSyncAt,
          lifecycle: lifecycle,
          pendingMergeCount: await repository.pendingMergeCount(
            identity.accountId,
          ),
        ),
      );
      return null;
    }
    return identity;
  }

  Future<SyncIdentity> _sendRebuildControl(
    SyncIdentity identity,
    bool Function() current,
    int authGeneration,
    SyncRebuildControlRequest request,
  ) async {
    await repository.saveRebuildControl(identity, current, request.toJson());
    late CloudAuthorizedSyncResult<SyncRebuildControlResponse> response;
    try {
      response = await auth.authorizedSync(
        (api, session) => api.controlSyncRebuild(
          accessToken: session.accessToken,
          request: request,
        ),
      );
    } on CloudApiException catch (error) {
      if ({400, 413, 415}.contains(error.httpStatus) ||
          (error.httpStatus == 409 &&
              !{
                'DEVICE_LIMIT',
                'SYNC_NOT_ACTIVE',
                'SYNC_QUOTA_EXCEEDED',
              }.contains(error.code.value))) {
        // A confirmed rejection unlocks user choices, preserving the exact
        // old operation in an encrypted archive. Ambiguous transport/200/5xx
        // outcomes keep the frozen operation as the only retry authority.
        final next = await db.transaction(() async {
          final next = await repository.cancelRebuild(identity, current);
          await repository.clearRebuildControl(
            next,
            current,
            operationId: request.operationId,
          );
          return next;
        });
        throw _ScopedSyncFailure(next, error);
      }
      rethrow;
    }
    final receipt = _authorizedValue(
      response,
      identity,
      current,
      authGeneration,
    );
    final attempt = receipt.attempt;
    if (attempt.ownerDeviceId != response.deviceId) {
      throw const StaleSyncIdentity();
    }
    final lifecycle = await _readLifecycle(identity, current, authGeneration);
    if (lifecycle.syncGeneration != identity.syncGeneration) {
      throw const _LifecycleChanged();
    }
    return db.transaction(() async {
      var next = identity;
      if (request.action == 'start' || request.action == 'claim') {
        final manifest = await repository.rebuildManifest(identity);
        if (manifest == null || manifest.manifestId != attempt.manifestId) {
          throw const SyncRebuildIncomplete();
        }
        // An original idempotent receipt may belong to a superseded attempt.
        // Only fresh status grants permission to write the current staging area.
        if (lifecycle.rebuild?.attemptId != attempt.attemptId ||
            lifecycle.rebuild?.ownerDeviceId != response.deviceId ||
            lifecycle.spaceState != 'active') {
          next = await repository.cancelRebuild(identity, current);
          await repository.clearRebuildControl(
            next,
            current,
            operationId: request.operationId,
          );
          return next;
        }
        next = await repository.bindRebuildAttempt(
          identity,
          current,
          localAttemptId: manifest.localAttemptId,
          serverAttemptId: attempt.attemptId,
        );
      } else if (request.action == 'complete') {
        if (lifecycle.backupState != 'ready') throw const _LifecycleChanged();
        next = await repository.completeRebuild(identity, current);
      } else {
        next = await repository.cancelRebuild(identity, current);
      }
      await repository.clearRebuildControl(
        next,
        current,
        operationId: request.operationId,
      );
      return next;
    });
  }

  Future<SyncIdentity> _uploadRebuild(
    SyncIdentity identity,
    bool Function() current,
    int authGeneration,
  ) async {
    while (true) {
      final frozen = await repository.prepareRebuildPush(
        identity,
        current,
        validate: (mutation) async {
          await projection.assertUploadOwner(mutation, identity.accountId);
          SyncMutation.fromJson(mutation.envelope);
        },
      );
      if (frozen.isEmpty) break;
      final response = await auth.authorizedSync(
        (api, session) => api.pushSyncV2(
          accessToken: session.accessToken,
          syncGeneration: identity.syncGeneration!,
          rebuildAttemptId: identity.rebuildAttemptId,
          mutations: [
            for (final mutation in frozen)
              SyncMutation.fromJson(mutation.envelope),
          ],
        ),
      );
      final result = _authorizedValue(
        response,
        identity,
        current,
        authGeneration,
      );
      await repository.commitRebuildPrefix(
        identity,
        current,
        sent: frozen,
        results: [
          for (final r in result.results)
            if (r is SyncAppliedResult)
              {
                'mutationId': r.mutationId,
                'status': 'applied',
                'revision': r.revision,
                'editedAt': r.editedAt,
              },
        ],
      );
      final lifecycle = await _readLifecycle(identity, current, authGeneration);
      if (lifecycle.syncGeneration != identity.syncGeneration ||
          lifecycle.rebuild?.attemptId != identity.rebuildAttemptId ||
          lifecycle.rebuild?.ownerDeviceId != lifecycle.deviceId) {
        throw const _LifecycleChanged();
      }
      _emit(
        SyncStatus(
          accountId: identity.accountId,
          busy: true,
          lifecycle: lifecycle,
          lastSyncAt: _status.lastSyncAt,
        ),
      );
    }
    final manifest = await repository.rebuildManifest(identity);
    if (manifest == null) throw const SyncRebuildIncomplete();
    return _sendRebuildControl(
      identity,
      current,
      authGeneration,
      SyncRebuildControlRequest.complete(
        operationId: newId(),
        syncGeneration: identity.syncGeneration!,
        expectedAttemptId: identity.rebuildAttemptId!,
        manifestId: manifest.manifestId,
      ),
    );
  }

  Future<void> _fullPull(
    SyncIdentity identity,
    bool Function() current,
    int authGeneration,
  ) async {
    // Pages stay encrypted and invisible until one unchanged server head has
    // been completely received. A moving head never replaces local content.
    for (var attempt = 0; attempt < 3; attempt++) {
      final stage = await repository.fullPullStage(identity.accountId);
      var cursor = stage?.cursor ?? 0;
      int? head = stage?.headRevision;
      var changed = false;
      while (stage?.complete != true) {
        final response = await auth.authorizedSync(
          (api, session) => api.pullSyncV2(
            accessToken: session.accessToken,
            syncGeneration: identity.syncGeneration!,
            cursor: cursor,
          ),
        );
        final page = _authorizedValue(
          response,
          identity,
          current,
          authGeneration,
        );
        head ??= page.headRevision;
        if (head != page.headRevision) {
          changed = true;
          break;
        }
        await repository.stageFullPull(
          identity,
          current,
          headRevision: head,
          records: [for (final record in page.records) record.toJson()],
          nextCursor: page.nextCursor,
          hasMore: page.hasMore,
        );
        cursor = page.nextCursor;
        if (!page.hasMore) break;
      }
      if (changed) {
        await repository.discardFullPull(identity, current);
        continue;
      }
      final confirmed = await _readLifecycle(identity, current, authGeneration);
      if (confirmed.syncGeneration != identity.syncGeneration) {
        throw const _LifecycleChanged();
      }
      if (confirmed.headRevision != head || confirmed.backupState != 'ready') {
        await repository.discardFullPull(identity, current);
        continue;
      }
      await repository.publishFullPull(
        identity,
        current,
        headRevision: head!,
        project: projection.project,
        merge: () => confirmed.spaceOrigin == 'rebuilt'
            ? projection.reconcile(identity.accountId)
            : projection.bootstrap(identity.accountId),
      );
      return;
    }
    throw const _SnapshotChanged();
  }

  static String _reason(Object error) {
    if (error is _LifecycleChanged) return 'SYNC_GENERATION_MISMATCH';
    if (error is _SnapshotChanged) return 'SYNC_SNAPSHOT_CHANGED';
    if (error is SyncLegacyScopeUnverified) {
      return 'SYNC_LEGACY_SCOPE_UNVERIFIED';
    }
    if (error is SyncRebuildIncomplete) return 'SYNC_REBUILD_INCOMPLETE';
    if (error is CloudApiException) return error.code.value;
    if (error is VaultLockedException) return 'VAULT_LOCKED';
    if (error is CloudReauthenticationRequiredException) return 'AUTH_REQUIRED';
    if (error is SyncReferenceOwnershipException) return 'OWNERSHIP';
    if (error is SyncValidationException) {
      return error.reason == SyncValidationFailure.unsupportedSchema
          ? 'SCHEMA_UNSUPPORTED'
          : 'VALIDATION';
    }
    if (error is CloudProtocolException) return 'VALIDATION';
    if (error is CloudNetworkException || error is CloudTimeoutException) {
      return 'OFFLINE';
    }
    return 'INTERNAL_ERROR';
  }

  Future<void> dispose() async {
    _disposed = true;
    _epoch++;
    _debounce?.cancel();
    _periodic?.cancel();
    _retry?.cancel();
    await _edits?.cancel();
    await _documents?.cancel();
    await _sessions?.cancel();
    try {
      await _running;
    } on Object {
      /* Disposed workers cannot apply. */
    }
    await _statuses.close();
  }
}

final class _LifecycleChanged implements Exception {
  const _LifecycleChanged();
}

final class _SnapshotChanged implements Exception {
  const _SnapshotChanged();
}

final class _ScopedSyncFailure implements Exception {
  const _ScopedSyncFailure(this.identity, this.cause);
  final SyncIdentity identity;
  final Object cause;
}

final class _RebuildIntent {
  _RebuildIntent(this.action, this.status, this.authGeneration);
  final String action;
  final SyncLifecycleStatus status;
  final int authGeneration;
  final completed = Completer<Object?>();
  bool matches(SyncLifecycleStatus fresh, int generation) =>
      generation == authGeneration &&
      fresh.accountId == status.accountId &&
      fresh.deviceId == status.deviceId &&
      fresh.syncGeneration == status.syncGeneration &&
      fresh.backupState == status.backupState &&
      fresh.rebuild?.attemptId == status.rebuild?.attemptId &&
      fresh.rebuild?.ownerDeviceId == status.rebuild?.ownerDeviceId &&
      fresh.spaceState == 'active';
  void resolve() {
    if (!completed.isCompleted) completed.complete(null);
  }

  void reject(Object error) {
    if (!completed.isCompleted) completed.complete(error);
  }
}
