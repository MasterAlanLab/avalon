import 'package:av_core/av_core.dart';
import 'package:drift/drift.dart';

import '../database/database.dart';
import '../ids.dart';

/// A downloaded rule set as the cache knows it (D86).
final class CachedRuleSet {
  const CachedRuleSet({
    required this.url,
    required this.format,
    this.file,
    this.sha256,
    this.size,
    this.updatedAt,
    this.checkedAt,
    this.lastError,
    this.skipped = 0,
  });

  /// Opaque `sha256:<digest>` identity. Never display or download this value;
  /// the real address belongs to the decrypted configuration's RuleSetRef.
  final String url;
  final RuleSetFormat format;

  /// File name under the host's `rulesets/`; null until downloaded.
  final String? file;
  final String? sha256;
  final int? size;
  final DateTime? updatedAt;
  final DateTime? checkedAt;

  /// The last attempt's error code; null when it succeeded.
  final String? lastError;

  /// Lines of a Clash provider that sing-box cannot express.
  final int skipped;

  String get key => ruleSetKeyOf(url, format);
}

/// The rule-set download cache (CONFIG_PIPELINE §8).
final class RuleResourceRepository {
  RuleResourceRepository(this._db);

  final AppDatabase _db;

  Stream<Map<String, CachedRuleSet>> watch() =>
      _db.select(_db.ruleResources).watch().map(_byKey);

  Future<Map<String, CachedRuleSet>> all() async =>
      _byKey(await _db.select(_db.ruleResources).get());

  /// Re-key older plaintext cache addresses, retaining the newest verified
  /// file and the newest attempt independently when duplicate rows exist.
  Future<void> obscureLegacyAddresses() => _db.transaction(() async {
    final groups = <String, List<RuleResourceRow>>{};
    for (final row in await _db.select(_db.ruleResources).get()) {
      final key = '${row.format} ${ruleSetAddressKey(row.url)}';
      (groups[key] ??= []).add(row);
    }
    for (final rows in groups.values) {
      final address = ruleSetAddressKey(rows.first.url);
      if (rows.length == 1 && rows.single.url == address) continue;
      rows.sort((a, b) {
        final date = (a.checkedAt ?? a.updatedAt ?? -1).compareTo(
          b.checkedAt ?? b.updatedAt ?? -1,
        );
        return date == 0 ? a.url.compareTo(b.url) : date;
      });
      final attempt = rows.last;
      final successes = rows.where((r) => r.file != null).toList()
        ..sort((a, b) => (a.updatedAt ?? -1).compareTo(b.updatedAt ?? -1));
      final content = successes.isEmpty ? attempt : successes.last;
      for (final row in rows) {
        await (_db.delete(_db.ruleResources)..where(
              (r) => r.url.equals(row.url) & r.format.equals(row.format),
            ))
            .go();
      }
      await _db
          .into(_db.ruleResources)
          .insert(
            RuleResourcesCompanion.insert(
              url: address,
              format: attempt.format,
              file: Value(content.file),
              sha256: Value(content.sha256),
              size: Value(content.size),
              updatedAt: Value(content.updatedAt),
              checkedAt: Value(attempt.checkedAt),
              lastError: Value(attempt.lastError),
              skipped: Value(content.skipped),
            ),
          );
    }
  });

  /// A download of [ref] succeeded and is kept as [file].
  Future<void> saved(
    RuleSetRef ref, {
    required String file,
    required String sha256,
    required int size,
    int skipped = 0,
  }) {
    final now = nowMs();
    return _db
        .into(_db.ruleResources)
        .insertOnConflictUpdate(
          RuleResourcesCompanion.insert(
            url: ruleSetAddressKey(ref.url),
            format: ref.format.name,
            file: Value(file),
            sha256: Value(sha256),
            size: Value(size),
            updatedAt: Value(now),
            checkedAt: Value(now),
            lastError: const Value(null),
            skipped: Value(skipped),
          ),
        );
  }

  /// A download of [ref] failed; what was downloaded before stays.
  Future<void> failed(RuleSetRef ref, String code) => _db.transaction(() async {
    final address = ruleSetAddressKey(ref.url);
    final key = (_db.select(_db.ruleResources)
      ..where((r) => r.url.equals(address) & r.format.equals(ref.format.name)));
    final now = nowMs();
    if (await key.getSingleOrNull() == null) {
      await _db
          .into(_db.ruleResources)
          .insert(
            RuleResourcesCompanion.insert(
              url: address,
              format: ref.format.name,
              checkedAt: Value(now),
              lastError: Value(code),
            ),
          );
      return;
    }
    await (_db.update(_db.ruleResources)..where(
          (r) => r.url.equals(address) & r.format.equals(ref.format.name),
        ))
        .write(
          RuleResourcesCompanion(checkedAt: Value(now), lastError: Value(code)),
        );
  });

  static Map<String, CachedRuleSet> _byKey(List<RuleResourceRow> rows) {
    DateTime? time(int? ms) => ms == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    final cached = <String, CachedRuleSet>{};
    for (final r in rows) {
      final format = RuleSetFormat.values.where((f) => f.name == r.format);
      if (format.isEmpty) continue;
      final item = CachedRuleSet(
        url: r.url,
        format: format.single,
        file: r.file,
        sha256: r.sha256,
        size: r.size,
        updatedAt: time(r.updatedAt),
        checkedAt: time(r.checkedAt),
        lastError: r.lastError,
        skipped: r.skipped,
      );
      cached[item.key] = item;
    }
    return cached;
  }
}
