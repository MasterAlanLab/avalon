import 'dart:convert';

import 'package:av_core/av_core.dart';
import 'package:drift/drift.dart';

import '../database/database.dart';
import '../ids.dart';
import '../vault/content_secrets.dart';
import '../vault/secret_store.dart';
import 'local_sync_edit.dart';

/// A self node is still a hop of these chains (PRODUCT_SPEC §3.4).
final class NodeInUseException implements Exception {
  const NodeInUseException(this.chainIds);

  final List<String> chainIds;
}

/// A chain hop that can never be valid (a group, a chain, a built-in).
final class InvalidHopException implements Exception {
  const InvalidHopException(this.index);

  final int index;
}

/// Self nodes, chains and their group memberships (PRODUCT_SPEC §3.6–3.7).
final class SelfContentRepository {
  SelfContentRepository(this._db, this._secrets, {this.onSyncEdit});

  final LocalSyncEdit? onSyncEdit;
  final AppDatabase _db;
  final SecretStore _secrets;

  Stream<List<SelfNode>> watchNodes() =>
      (_db.select(_db.selfNodes)
            ..orderBy([(n) => OrderingTerm.asc(n.createdAt)]))
          .watch()
          .asyncMap((rows) => Future.wait(rows.map(_node)));

  Future<List<SelfNode>> nodes() async {
    final rows = await (_db.select(
      _db.selfNodes,
    )..orderBy([(n) => OrderingTerm.asc(n.createdAt)])).get();
    return Future.wait(rows.map(_node));
  }

  /// Saves a node; with [joinGroup] it also joins that group of an imported
  /// configuration (PRODUCT_SPEC §3.6). Returns the node with its new id.
  Future<SelfNode> addNode(
    SelfNode node, {
    ({String configurationId, String groupKey})? joinGroup,
  }) {
    return _db.transaction(() async {
      final saved = node.copyWith(id: newId());
      final now = nowMs();
      final (paramsJson, secretId) = await _putParams(saved.params);
      await _db
          .into(_db.selfNodes)
          .insert(
            SelfNodesCompanion.insert(
              id: saved.id,
              name: saved.name,
              protocol: saved.params.protocol.name,
              server: saved.server,
              port: saved.port,
              paramsJson: paramsJson,
              secretId: secretId,
              createdAt: now,
              editedAt: now,
            ),
          );
      if (joinGroup != null) {
        await _db
            .into(_db.memberships)
            .insert(
              MembershipsCompanion.insert(
                ownerKind: MemberOwner.node.name,
                ownerId: saved.id,
                configurationId: joinGroup.configurationId,
                groupKey: joinGroup.groupKey,
                createdAt: now,
              ),
            );
      }
      await onSyncEdit?.call('node', saved.id, false);
      return saved;
    });
  }

  /// One node with when it was last edited, for the edit form.
  Future<({SelfNode node, DateTime editedAt})?> node(String id) async {
    final row = await (_db.select(
      _db.selfNodes,
    )..where((n) => n.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return (node: await _node(row), editedAt: fromMs(row.editedAt)!);
  }

  /// With [ifEditedAt] the edit is refused ([EditConflictException]) when
  /// the node changed since then.
  Future<void> updateNode(SelfNode node, {DateTime? ifEditedAt}) {
    return _db.transaction(() async {
      final row = await (_db.select(
        _db.selfNodes,
      )..where((n) => n.id.equals(node.id))).getSingle();
      checkUnchanged(row.editedAt, ifEditedAt);
      final (paramsJson, secretId) = await _putParams(node.params);
      await (_db.update(
        _db.selfNodes,
      )..where((n) => n.id.equals(node.id))).write(
        SelfNodesCompanion(
          name: Value(node.name),
          protocol: Value(node.params.protocol.name),
          server: Value(node.server),
          port: Value(node.port),
          paramsJson: Value(paramsJson),
          secretId: Value(secretId),
          editedAt: Value(nowMs()),
        ),
      );
      await _secrets.delete(row.secretId);
      await onSyncEdit?.call('node', node.id, false);
    });
  }

  /// Refused with [NodeInUseException] while any chain uses the node.
  Future<void> deleteNode(String id) {
    return _db.transaction(() async {
      final users = [
        for (final c in await chains())
          if (c.hops.any((h) => h is SelfNodeRef && h.id == id)) c.id,
      ];
      if (users.isNotEmpty) throw NodeInUseException(users);
      final row = await (_db.select(
        _db.selfNodes,
      )..where((n) => n.id.equals(id))).getSingleOrNull();
      if (row == null) return;
      await onSyncEdit?.call('node', id, true);
      await (_db.delete(_db.selfNodes)..where((n) => n.id.equals(id))).go();
      await _deleteMemberships(MemberOwner.node, id);
      await _secrets.delete(row.secretId);
    });
  }

  Stream<List<Chain>> watchChains() =>
      (_db.select(_db.chains)..orderBy([(c) => OrderingTerm.asc(c.createdAt)]))
          .watch()
          .map((rows) => rows.map(_chain).toList());

  Future<List<Chain>> chains() async {
    final rows = await (_db.select(
      _db.chains,
    )..orderBy([(c) => OrderingTerm.asc(c.createdAt)])).get();
    return rows.map(_chain).toList();
  }

  /// Chains need at least two hops of the hop kinds (DATA_MODEL §1.3).
  /// With [joinGroups] the chain also joins those groups of imported
  /// configurations (PRODUCT_SPEC §3.7).
  Future<Chain> addChain(
    Chain chain, {
    List<({String configurationId, String groupKey})> joinGroups = const [],
  }) {
    _checkHops(chain.hops);
    return _db.transaction(() async {
      final saved = chain.copyWith(id: newId());
      final now = nowMs();
      await _db
          .into(_db.chains)
          .insert(
            ChainsCompanion.insert(
              id: saved.id,
              name: Value(saved.name),
              hopsJson: jsonEncode([for (final h in saved.hops) h.toJson()]),
              createdAt: now,
              editedAt: now,
            ),
          );
      for (final group in joinGroups) {
        await _db
            .into(_db.memberships)
            .insert(
              MembershipsCompanion.insert(
                ownerKind: MemberOwner.chain.name,
                ownerId: saved.id,
                configurationId: group.configurationId,
                groupKey: group.groupKey,
                createdAt: now,
              ),
            );
      }
      await onSyncEdit?.call('chain', saved.id, false);
      return saved;
    });
  }

  /// One chain with when it was last edited, for the edit form.
  Future<({Chain chain, DateTime editedAt})?> chain(String id) async {
    final row = await (_db.select(
      _db.chains,
    )..where((c) => c.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return (chain: _chain(row), editedAt: fromMs(row.editedAt)!);
  }

  /// Saves name and hops. [groups] replaces the chain's memberships within
  /// that configuration (others stay). With [ifEditedAt] the edit is
  /// refused ([EditConflictException]) when the chain changed since then.
  Future<void> updateChain(
    Chain chain, {
    ({String configurationId, Set<String> groupKeys})? groups,
    DateTime? ifEditedAt,
  }) {
    _checkHops(chain.hops);
    return _db.transaction(() async {
      final row = await (_db.select(
        _db.chains,
      )..where((c) => c.id.equals(chain.id))).getSingle();
      checkUnchanged(row.editedAt, ifEditedAt);
      final now = nowMs();
      await (_db.update(_db.chains)..where((c) => c.id.equals(chain.id))).write(
        ChainsCompanion(
          name: Value(chain.name),
          hopsJson: Value(jsonEncode([for (final h in chain.hops) h.toJson()])),
          editedAt: Value(now),
        ),
      );
      if (groups == null) {
        await onSyncEdit?.call('chain', chain.id, false);
        return;
      }
      await (_db.delete(_db.memberships)..where(
            (m) =>
                m.ownerKind.equals(MemberOwner.chain.name) &
                m.ownerId.equals(chain.id) &
                m.configurationId.equals(groups.configurationId),
          ))
          .go();
      for (final key in groups.groupKeys) {
        await _db
            .into(_db.memberships)
            .insert(
              MembershipsCompanion.insert(
                ownerKind: MemberOwner.chain.name,
                ownerId: chain.id,
                configurationId: groups.configurationId,
                groupKey: key,
                createdAt: now,
              ),
            );
      }
      await onSyncEdit?.call('chain', chain.id, false);
    });
  }

  Future<void> deleteChain(String id) {
    return _db.transaction(() async {
      await onSyncEdit?.call('chain', id, true);
      await (_db.delete(_db.chains)..where((c) => c.id.equals(id))).go();
      await _deleteMemberships(MemberOwner.chain, id);
    });
  }

  Stream<List<Membership>> watchMemberships() => _db
      .select(_db.memberships)
      .watch()
      .map(
        (rows) => [
          for (final r in rows)
            Membership(
              ownerKind: MemberOwner.values.byName(r.ownerKind),
              ownerId: r.ownerId,
              configurationId: r.configurationId,
              groupKey: r.groupKey,
            ),
        ],
      );

  Future<void> _deleteMemberships(MemberOwner kind, String id) => (_db.delete(
    _db.memberships,
  )..where((m) => m.ownerKind.equals(kind.name) & m.ownerId.equals(id))).go();

  static void _checkHops(List<MemberRef> hops) {
    if (hops.length < 2) throw const InvalidHopException(-1);
    for (final (i, h) in hops.indexed) {
      if (!h.canBeHop) throw InvalidHopException(i);
    }
  }

  Future<(String, String)> _putParams(NodeParams params) async {
    final (:public, :secrets) = ContentSecrets.split(params.toJson());
    return (jsonEncode(public), await _secrets.put(secrets));
  }

  Future<SelfNode> _node(SelfNodeRow r) async {
    final secrets = await _secrets.get(r.secretId);
    final json = ContentSecrets.join(jsonDecode(r.paramsJson), secrets);
    return SelfNode(
      id: r.id,
      name: r.name,
      server: r.server,
      port: r.port,
      params: NodeParams.fromJson(json! as Map<String, dynamic>),
    );
  }

  static Chain _chain(ChainRow r) => Chain(
    id: r.id,
    name: r.name,
    hops: [
      for (final h in jsonDecode(r.hopsJson) as List)
        MemberRef.fromJson(h as Map<String, dynamic>),
    ],
  );
}
