import 'dart:convert';

import 'package:av_core/av_core.dart';
import 'package:drift/drift.dart';

import '../database/database.dart';
import '../ids.dart';
import 'local_sync_edit.dart';

/// Selector choices per configuration and group (DATA_MODEL §1.2).
final class SelectionRepository {
  SelectionRepository(this._db, {this.onSyncEdit});

  final LocalSyncEdit? onSyncEdit;
  final AppDatabase _db;

  Stream<Map<String, MemberRef>> watch(String configurationId) =>
      (_db.select(_db.selections)
            ..where((s) => s.configurationId.equals(configurationId)))
          .watch()
          .map(_toMap);

  Future<Map<String, MemberRef>> get(String configurationId) async => _toMap(
    await (_db.select(
      _db.selections,
    )..where((s) => s.configurationId.equals(configurationId))).get(),
  );

  /// Saves a choice; [manual] choices are the ones synced.
  Future<void> select(
    String configurationId,
    String groupKey,
    MemberRef member, {
    bool manual = true,
  }) => _db.transaction(() async {
    final old =
        await (_db.select(_db.selections)..where(
              (s) =>
                  s.configurationId.equals(configurationId) &
                  s.groupKey.equals(groupKey),
            ))
            .getSingleOrNull();
    await _db
        .into(_db.selections)
        .insertOnConflictUpdate(
          SelectionsCompanion.insert(
            configurationId: configurationId,
            groupKey: groupKey,
            memberJson: jsonEncode(member.toJson()),
            manual: manual,
            editedAt: nowMs(),
            cloudAccountId: Value(old?.cloudAccountId),
            documentId: Value(old?.documentId),
          ),
        );
    if (manual) {
      await onSyncEdit?.call(
        'selection',
        jsonEncode([configurationId, groupKey]),
        false,
      );
    }
  });

  static Map<String, MemberRef> _toMap(List<SelectionRow> rows) => {
    for (final r in rows)
      r.groupKey: MemberRef.fromJson(
        jsonDecode(r.memberJson) as Map<String, dynamic>,
      ),
  };
}
