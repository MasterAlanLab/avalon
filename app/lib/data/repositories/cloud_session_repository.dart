import 'dart:convert';

import 'package:drift/drift.dart';

import '../database/database.dart';
import '../ids.dart';
import '../vault/secret_store.dart';
import 'sync_repository.dart';

/// The persisted account snapshot. Tokens never appear in its diagnostics.
final class StoredCloudSession {
  StoredCloudSession({
    required this.accountId,
    required this.deviceId,
    required this.sessionId,
    required this.installationId,
    required this.accessToken,
    required this.refreshToken,
    required DateTime accessExpiresAt,
    required DateTime refreshExpiresAt,
    this.email = '',
    this.displayName = '',
    this.entitlementJson,
    this.refreshUncertain = false,
  }) : accessExpiresAt = accessExpiresAt.toUtc(),
       refreshExpiresAt = refreshExpiresAt.toUtc();

  final String accountId;
  final String deviceId;
  final String sessionId;
  final String installationId;
  final String accessToken;
  final String refreshToken;
  final DateTime accessExpiresAt;
  final DateTime refreshExpiresAt;
  final String email;
  final String displayName;
  final String? entitlementJson;
  final bool refreshUncertain;

  StoredCloudSession copyWith({
    String? accountId,
    String? deviceId,
    String? sessionId,
    String? installationId,
    String? accessToken,
    String? refreshToken,
    DateTime? accessExpiresAt,
    DateTime? refreshExpiresAt,
    String? email,
    String? displayName,
    String? entitlementJson,
    bool? refreshUncertain,
  }) => StoredCloudSession(
    accountId: accountId ?? this.accountId,
    deviceId: deviceId ?? this.deviceId,
    sessionId: sessionId ?? this.sessionId,
    installationId: installationId ?? this.installationId,
    accessToken: accessToken ?? this.accessToken,
    refreshToken: refreshToken ?? this.refreshToken,
    accessExpiresAt: accessExpiresAt ?? this.accessExpiresAt,
    refreshExpiresAt: refreshExpiresAt ?? this.refreshExpiresAt,
    email: email ?? this.email,
    displayName: displayName ?? this.displayName,
    entitlementJson: entitlementJson ?? this.entitlementJson,
    refreshUncertain: refreshUncertain ?? this.refreshUncertain,
  );

  @override
  String toString() =>
      'StoredCloudSession(accountId: $accountId, deviceId: $deviceId, '
      'sessionId: $sessionId)';
}

/// A refresh proof used only to revoke its original session after logout.
/// It stays encrypted until the server acknowledges or rejects this proof.
final class PendingCloudRevocation {
  const PendingCloudRevocation({
    required this.sessionId,
    required this.refreshToken,
    this.refreshExpiresAt,
  });

  final String sessionId;
  final String refreshToken;

  /// The proof's original expiry, never extended by a later rotation.
  /// Null only for a queue entry written before this field was persisted.
  final DateTime? refreshExpiresAt;

  @override
  String toString() => 'PendingCloudRevocation(sessionId: $sessionId)';
}

/// The storage boundary used by Cloud authentication, without HTTP DTOs.
abstract interface class CloudSessionStore {
  Future<String> installationId();
  Future<StoredCloudSession?> read();
  Future<void> save(StoredCloudSession session);
  Future<bool> updateProfile({
    required String expectedSessionId,
    required String email,
    required String displayName,
    required String entitlementJson,
  });
  Future<bool> claimRefresh({
    required String expectedSessionId,
    required String expectedRefreshToken,
  });
  Future<bool> replaceTokens({
    required String expectedSessionId,
    required String expectedRefreshToken,
    required StoredCloudSession session,
  });
  Future<bool> clear({String? expectedSessionId});
  Future<void> detachAccount(String accountId);
  Future<PendingCloudRevocation?> logoutLocally();
  Future<List<PendingCloudRevocation>> pendingRevocations();
  Future<void> completeRevocation(
    String sessionId, {
    String? expectedRefreshToken,
  });
}

/// Owns only the local Cloud session. Logout preserves content and sync state.
/// Row 1 keeps the active session or the logged-out installation UUID. Row 2
/// is a logged-out owner for the encrypted revocation queue in refreshSecretId;
/// its other text columns are empty. Neither row enters backups. All active
/// session operations select row 1, leaving queued proofs across new logins.
final class CloudSessionRepository implements CloudSessionStore {
  CloudSessionRepository(this._db, this._secrets);

  final AppDatabase _db;
  final SecretStore _secrets;

  Future<CloudSessionRow?> _row() => (_db.select(
    _db.cloudSession,
  )..where((s) => s.id.equals(1))).getSingleOrNull();

  Future<CloudSessionRow?> _pendingRow() => (_db.select(
    _db.cloudSession,
  )..where((s) => s.id.equals(2))).getSingleOrNull();

  @override
  Future<String> installationId() => _db.transaction(() async {
    final current = await _row();
    if (current != null) return current.installationId;
    final id = newId();
    await _writeLoggedOut(id);
    return id;
  });

  @override
  Future<StoredCloudSession?> read() => _db.transaction(() async {
    final row = await _row();
    return row == null || !row.loggedIn ? null : await _decode(row);
  });

  Stream<StoredCloudSession?> watch() => (_db.select(
    _db.cloudSession,
  )..where((s) => s.id.equals(1))).watch().asyncMap((_) => read());

  @override
  Future<void> save(StoredCloudSession session) => _db.transaction(() async {
    _validate(session);
    if (session.installationId != await installationId()) {
      throw ArgumentError('session belongs to a different installation');
    }
    await _write(session, previous: await _row());
  });

  /// Merge only public profile data, retaining the current token references
  /// and refresh guard even if another instance claimed or rotated refresh.
  @override
  Future<bool> updateProfile({
    required String expectedSessionId,
    required String email,
    required String displayName,
    required String entitlementJson,
  }) => _db.transaction(() async {
    final row = await _row();
    if (row == null || !row.loggedIn) return false;
    final access = await _secrets.get(row.accessSecretId);
    if (_required(access, 'sessionId') != expectedSessionId) return false;
    await (_db.update(
      _db.cloudSession,
    )..where((row) => row.id.equals(1))).write(
      CloudSessionCompanion(
        email: Value(email),
        displayName: Value(displayName),
        entitlementJson: Value(entitlementJson),
        updatedAt: Value(nowMs()),
      ),
    );
    return true;
  });

  /// Atomically claim a refresh across AuthService instances and isolates.
  /// Persisting the guard before HTTP prevents replay after a process crash.
  @override
  Future<bool> claimRefresh({
    required String expectedSessionId,
    required String expectedRefreshToken,
  }) => _db.transaction(() async {
    final row = await _row();
    if (row == null || !row.loggedIn) return false;
    final current = await _decode(row);
    if (current.sessionId != expectedSessionId ||
        current.refreshToken != expectedRefreshToken ||
        current.refreshUncertain) {
      return false;
    }
    await _write(current.copyWith(refreshUncertain: true), previous: row);
    return true;
  });

  /// A response from an older refresh or account cannot replace new tokens.
  @override
  Future<bool> replaceTokens({
    required String expectedSessionId,
    required String expectedRefreshToken,
    required StoredCloudSession session,
  }) => _db.transaction(() async {
    final row = await _row();
    if (row == null || !row.loggedIn) return false;
    final current = await _decode(row);
    if (current.sessionId != expectedSessionId ||
        current.refreshToken != expectedRefreshToken) {
      return false;
    }
    _validate(session);
    if (session.accountId != current.accountId ||
        session.deviceId != current.deviceId ||
        session.sessionId != current.sessionId ||
        session.installationId != current.installationId) {
      throw ArgumentError('token replacement changes session identity');
    }
    await _write(session, previous: row);
    return true;
  });

  /// Drops only the active account's two encrypted entries. The installation,
  /// proxy credentials, local content, Cloud bindings and sync cursor survive.
  @override
  Future<bool> clear({String? expectedSessionId}) => _db.transaction(() async {
    final row = await _row();
    if (row == null || !row.loggedIn) return false;
    if (expectedSessionId != null) {
      final access = await _secrets.get(row.accessSecretId);
      if (access['sessionId'] != expectedSessionId) return false;
    }
    await _writeLoggedOut(row.installationId);
    await _deleteSecrets(row);
    return true;
  });

  /// The queue and logout commit together, before any network request. The
  /// proof cannot refresh or revoke any subsequently logged-in session.
  @override
  Future<PendingCloudRevocation?> logoutLocally() => _db.transaction(() async {
    final current = await _row();
    if (current == null || !current.loggedIn) return null;
    final access = await _secrets.get(current.accessSecretId);
    final refresh = await _secrets.get(current.refreshSecretId);
    final expiry = DateTime.tryParse(_required(refresh, 'refreshExpiresAt'));
    if (expiry == null) {
      throw const FormatException('stored Cloud refresh expiry is invalid');
    }
    final proof = PendingCloudRevocation(
      sessionId: _required(access, 'sessionId'),
      refreshToken: _required(refresh, 'refreshToken'),
      refreshExpiresAt: expiry.toUtc(),
    );
    final owner = await _pendingRow();
    final pending = await _readPending(owner);
    final existing = pending.indexWhere((p) => p.sessionId == proof.sessionId);
    if (existing < 0) {
      pending.add(proof);
    } else {
      pending[existing] = proof;
    }
    await _writePending(pending, previous: owner);
    await _writeLoggedOut(current.installationId);
    await _deleteSecrets(current);
    return proof;
  });

  @override
  Future<List<PendingCloudRevocation>> pendingRevocations() =>
      _db.transaction(() async {
        return List.unmodifiable(await _readPending(await _pendingRow()));
      });

  /// Removes an acknowledged or terminally rejected proof. A late response
  /// cannot remove a newer proof for the same session when a token is supplied.
  @override
  Future<void> completeRevocation(
    String sessionId, {
    String? expectedRefreshToken,
  }) => _db.transaction(() async {
    final owner = await _pendingRow();
    final pending = await _readPending(owner);
    final remaining = pending
        .where(
          (proof) =>
              proof.sessionId != sessionId ||
              (expectedRefreshToken != null &&
                  proof.refreshToken != expectedRefreshToken),
        )
        .toList();
    if (remaining.length == pending.length) return;
    await _writePending(remaining, previous: owner);
  });

  /// Account deletion retains all local content and credentials, detaching
  /// only this account's bindings and sync bookkeeping.
  @override
  Future<void> detachAccount(String accountId) => _db.transaction(() async {
    await SyncRepository(_db, _secrets).detachAccount(accountId);
    await (_db.update(_db.configurations)
          ..where((r) => r.cloudAccountId.equals(accountId)))
        .write(const ConfigurationsCompanion(cloudAccountId: Value(null)));
    await (_db.update(_db.selfNodes)
          ..where((r) => r.cloudAccountId.equals(accountId)))
        .write(const SelfNodesCompanion(cloudAccountId: Value(null)));
    await (_db.update(_db.chains)
          ..where((r) => r.cloudAccountId.equals(accountId)))
        .write(const ChainsCompanion(cloudAccountId: Value(null)));
    await (_db.update(_db.selections)
          ..where((r) => r.cloudAccountId.equals(accountId)))
        .write(const SelectionsCompanion(cloudAccountId: Value(null)));
    await (_db.update(_db.policyTable)
          ..where((r) => r.cloudAccountId.equals(accountId)))
        .write(const PolicyTableCompanion(cloudAccountId: Value(null)));
    await (_db.delete(
      _db.syncMeta,
    )..where((r) => r.accountId.equals(accountId))).go();
    await (_db.delete(
      _db.syncState,
    )..where((r) => r.accountId.equals(accountId))).go();
  });

  Future<StoredCloudSession> _decode(CloudSessionRow row) async {
    final access = await _secrets.get(row.accessSecretId);
    final refresh = await _secrets.get(row.refreshSecretId);
    return StoredCloudSession(
      accountId: row.accountId,
      deviceId: row.deviceId,
      sessionId: _required(access, 'sessionId'),
      installationId: row.installationId,
      accessToken: _required(access, 'accessToken'),
      refreshToken: _required(refresh, 'refreshToken'),
      accessExpiresAt: DateTime.parse(_required(access, 'accessExpiresAt')),
      refreshExpiresAt: DateTime.parse(_required(refresh, 'refreshExpiresAt')),
      email: row.email,
      displayName: row.displayName,
      entitlementJson: row.entitlementJson.isEmpty ? null : row.entitlementJson,
      refreshUncertain: refresh['refreshUncertain'] == 'true',
    );
  }

  Future<List<PendingCloudRevocation>> _readPending(
    CloudSessionRow? owner,
  ) async {
    if (owner == null) return [];
    final secret = await _secrets.get(owner.refreshSecretId);
    try {
      final decoded = jsonDecode(secret['pending'] ?? '');
      if (decoded is! List) throw const FormatException();
      final pending = <PendingCloudRevocation>[];
      final ids = <String>{};
      for (final entry in decoded) {
        if (entry is! Map ||
            entry['sessionId'] is! String ||
            entry['refreshToken'] is! String) {
          throw const FormatException();
        }
        final id = entry['sessionId'] as String;
        final token = entry['refreshToken'] as String;
        if (id.isEmpty || token.isEmpty || !ids.add(id)) {
          throw const FormatException();
        }
        final rawExpiry = entry['refreshExpiresAt'];
        DateTime? expiry;
        if (rawExpiry != null) {
          if (rawExpiry is! String) throw const FormatException();
          expiry = DateTime.tryParse(rawExpiry)?.toUtc();
          if (expiry == null) throw const FormatException();
        }
        pending.add(
          PendingCloudRevocation(
            sessionId: id,
            refreshToken: token,
            refreshExpiresAt: expiry,
          ),
        );
      }
      return pending;
    } on FormatException {
      // jsonDecode's exception can contain its input, including tokens.
      throw const FormatException('stored Cloud revocation queue is invalid');
    }
  }

  Future<void> _writePending(
    List<PendingCloudRevocation> pending, {
    required CloudSessionRow? previous,
  }) async {
    if (pending.isEmpty) {
      await (_db.delete(
        _db.cloudSession,
      )..where((row) => row.id.equals(2))).go();
    } else {
      final secretId = await _secrets.put({
        'pending': jsonEncode([
          for (final proof in pending)
            {
              'sessionId': proof.sessionId,
              'refreshToken': proof.refreshToken,
              if (proof.refreshExpiresAt != null)
                'refreshExpiresAt': proof.refreshExpiresAt!
                    .toUtc()
                    .toIso8601String(),
            },
        ]),
      });
      await _db
          .into(_db.cloudSession)
          .insertOnConflictUpdate(
            CloudSessionCompanion.insert(
              id: const Value(2),
              accountId: '',
              email: '',
              displayName: '',
              deviceId: '',
              installationId: '',
              accessSecretId: '',
              refreshSecretId: secretId,
              entitlementJson: '',
              loggedIn: false,
              updatedAt: nowMs(),
            ),
          );
    }
    if (previous != null) await _deleteSecrets(previous);
  }

  Future<void> _write(
    StoredCloudSession session, {
    required CloudSessionRow? previous,
  }) async {
    final accessId = await _secrets.put({
      'accessToken': session.accessToken,
      'sessionId': session.sessionId,
      'accessExpiresAt': session.accessExpiresAt.toIso8601String(),
    });
    final refreshId = await _secrets.put({
      'refreshToken': session.refreshToken,
      'refreshExpiresAt': session.refreshExpiresAt.toIso8601String(),
      'refreshUncertain': session.refreshUncertain.toString(),
    });
    await _db
        .into(_db.cloudSession)
        .insertOnConflictUpdate(
          CloudSessionCompanion.insert(
            id: const Value(1),
            accountId: session.accountId,
            email: session.email,
            displayName: session.displayName,
            deviceId: session.deviceId,
            installationId: session.installationId,
            accessSecretId: accessId,
            refreshSecretId: refreshId,
            entitlementJson: session.entitlementJson ?? '',
            loggedIn: true,
            updatedAt: nowMs(),
          ),
        );
    if (previous != null) await _deleteSecrets(previous);
  }

  Future<void> _writeLoggedOut(String installationId) => _db
      .into(_db.cloudSession)
      .insertOnConflictUpdate(
        CloudSessionCompanion.insert(
          id: const Value(1),
          accountId: '',
          email: '',
          displayName: '',
          deviceId: '',
          installationId: installationId,
          accessSecretId: '',
          refreshSecretId: '',
          entitlementJson: '',
          loggedIn: false,
          updatedAt: nowMs(),
        ),
      )
      .then((_) {});

  Future<void> _deleteSecrets(CloudSessionRow row) async {
    if (row.accessSecretId.isNotEmpty) {
      await _secrets.delete(row.accessSecretId);
    }
    if (row.refreshSecretId.isNotEmpty) {
      await _secrets.delete(row.refreshSecretId);
    }
  }

  static String _required(Map<String, String> values, String name) {
    final value = values[name];
    if (value == null || value.isEmpty) {
      throw const FormatException('stored Cloud session is incomplete');
    }
    return value;
  }

  static void _validate(StoredCloudSession session) {
    if ([
      session.accountId,
      session.deviceId,
      session.sessionId,
      session.installationId,
      session.accessToken,
      session.refreshToken,
    ].any((value) => value.isEmpty)) {
      throw ArgumentError('Cloud session identity or credentials are empty');
    }
  }
}
