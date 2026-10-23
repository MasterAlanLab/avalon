import 'dart:convert';

import 'package:av_core/av_core.dart';
import 'package:drift/drift.dart';

import '../database/database.dart';
import '../ids.dart';
import '../vault/content_secrets.dart';
import '../vault/secret_store.dart';
import 'local_sync_edit.dart';

/// Content of a configuration as stored: the model with secrets joined back.
final class StoredContent {
  const StoredContent({
    required this.format,
    required this.content,
    required this.digest,
  });

  final ContentFormat format;
  final ConfigContent content;

  /// SHA-256 of the text it was parsed from.
  final String digest;
}

/// Configurations and their contents (DATA_MODEL §2, §4). Every write is one
/// transaction: configuration, content and secrets commit or roll back
/// together.
final class ConfigurationRepository {
  ConfigurationRepository(this._db, this._secrets, {this.onSyncEdit});

  final LocalSyncEdit? onSyncEdit;
  final AppDatabase _db;
  final SecretStore _secrets;

  Stream<List<Configuration>> watchAll() =>
      (_db.select(_db.configurations)
            ..orderBy([(c) => OrderingTerm.asc(c.createdAt)]))
          .watch()
          .map((rows) => rows.map(_toModel).toList());

  /// Node counts by configuration, without decrypting any content.
  Stream<Map<String, int>> watchNodeCounts() => _db
      .select(_db.contents)
      .watch()
      .map((rows) => {for (final r in rows) r.configurationId: r.nodeCount});

  Future<Configuration?> get(String id) async {
    final row = await _row(id);
    return row == null ? null : _toModel(row);
  }

  Future<ConfigurationRow?> _row(String id) => (_db.select(
    _db.configurations,
  )..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<StoredContent?> content(String id) async {
    final row = await (_db.select(
      _db.contents,
    )..where((c) => c.configurationId.equals(id))).getSingleOrNull();
    return row == null ? null : _decodeContent(row);
  }

  /// The content of one configuration, again whenever it is replaced; null
  /// while there is none (a subscription not downloaded yet).
  Stream<StoredContent?> watchContent(String id) =>
      (_db.select(_db.contents)..where((c) => c.configurationId.equals(id)))
          .watchSingleOrNull()
          .asyncMap((row) async => row == null ? null : _decodeContent(row));

  Future<StoredContent> _decodeContent(ContentRow row) async {
    final secrets = await _secrets.get(row.secretId);
    final json = ContentSecrets.join(jsonDecode(row.modelJson), secrets);
    return StoredContent(
      format: ContentFormat.values.byName(row.format),
      content: ConfigContent.fromJson(json! as Map<String, dynamic>),
      digest: row.digest,
    );
  }

  Future<SubscriptionSource?> source(String id) async {
    final secretId = (await _row(id))?.sourceSecretId;
    if (secretId == null) return null;
    final entry = await _secrets.get(secretId);
    final json = SecretCodec.join(jsonDecode(entry['model']!), entry);
    return SubscriptionSource.fromJson(json! as Map<String, dynamic>);
  }

  Future<bool> isCloudOrigin(String id) async {
    final documents =
        await (_db.select(_db.syncDocuments)..where(
              (d) => d.type.equals('configuration') & d.localId.equals(id),
            ))
            .get();
    for (final document in documents) {
      final provenance =
          await (_db.select(_db.sourceProvenance)
                ..where((p) => p.documentId.equals(document.documentId)))
              .getSingleOrNull();
      if (provenance?.origin == 'cloud') return true;
    }
    return false;
  }

  /// The URL, its generation and trust are read from the same transaction.
  Future<
    ({SubscriptionSource source, String sourceSecretId, bool cloudSource})?
  >
  sourceSnapshot(String id) => _db.transaction(() async {
    final row = await _row(id);
    if (row?.sourceSecretId == null) return null;
    final entry = await _secrets.get(row!.sourceSecretId!);
    final json = SecretCodec.join(jsonDecode(entry['model']!), entry);
    return (
      source: SubscriptionSource.fromJson(json! as Map<String, dynamic>),
      sourceSecretId: row.sourceSecretId!,
      cloudSource: await isCloudOrigin(id),
    );
  });

  /// Saves a new subscription or file import; returns its id.
  Future<String> add({
    required ConfigurationKind kind,
    required String name,
    required ParsedContent parsed,
    required String digest,
    SubscriptionSource? source,
    Usage? usage,
    bool autoUpdate = true,
  }) {
    assert(kind != ConfigurationKind.self);
    return _db.transaction(() async {
      final id = newId();
      final now = nowMs();
      await _db
          .into(_db.configurations)
          .insert(
            ConfigurationsCompanion.insert(
              id: id,
              kind: kind.name,
              name: name,
              sourceSecretId: Value(
                source == null ? null : await _putSource(source),
              ),
              sourceDisplay: Value(
                source == null ? null : Uri.tryParse(source.url.value)?.host,
              ),
              autoUpdate: Value(autoUpdate && source != null),
              createdAt: now,
              editedAt: now,
              lastSuccessAt: Value(now),
              lastAttemptAt: Value(now),
              usageUpload: Value(usage?.upload),
              usageDownload: Value(usage?.download),
              usageTotal: Value(usage?.total),
              expireAt: Value(_ms(usage?.expireAt)),
            ),
          );
      final contentId = await _insertContent(id, parsed, digest);
      await (_db.update(_db.configurations)..where((c) => c.id.equals(id)))
          .write(ConfigurationsCompanion(contentId: Value(contentId)));
      await onSyncEdit?.call('configuration', id, false);
      return id;
    });
  }

  /// Replaces a subscription's content after a refresh. Returns false and
  /// writes nothing when the configuration is gone or its source changed
  /// while downloading (DATA_MODEL §4).
  Future<bool> replaceContent(
    String id, {
    required String? expectedSourceSecretId,
    required ParsedContent parsed,
    required String digest,
    Usage? usage,
  }) {
    return _db.transaction(() async {
      final row = await _row(id);
      if (row == null || row.sourceSecretId != expectedSourceSecretId) {
        return false;
      }
      final old = await (_db.select(
        _db.contents,
      )..where((c) => c.configurationId.equals(id))).getSingleOrNull();
      final contentId = await _insertContent(id, parsed, digest);
      final now = nowMs();
      await (_db.update(
        _db.configurations,
      )..where((c) => c.id.equals(id))).write(
        ConfigurationsCompanion(
          contentId: Value(contentId),
          lastSuccessAt: Value(now),
          lastAttemptAt: Value(now),
          lastError: const Value(null),
          // Without usage headers the previous figures stay.
          usageUpload: usage == null
              ? const Value.absent()
              : Value(usage.upload),
          usageDownload: usage == null
              ? const Value.absent()
              : Value(usage.download),
          usageTotal: usage == null ? const Value.absent() : Value(usage.total),
          expireAt: usage == null
              ? const Value.absent()
              : Value(_ms(usage.expireAt)),
        ),
      );
      if (old != null) {
        await (_db.delete(
          _db.contents,
        )..where((c) => c.id.equals(old.id))).go();
        await _secrets.delete(old.secretId);
      }
      return true;
    });
  }

  /// The secrets entry id of a configuration's source, to detect edits
  /// during a refresh.
  Future<String?> sourceSecretId(String id) async =>
      (await _row(id))?.sourceSecretId;

  /// A refresh that downloaded the same content: only times and usage change.
  Future<bool> markRefreshed(
    String id, {
    Usage? usage,
    String? expectedSourceSecretId,
    bool checkSource = false,
  }) async {
    final count =
        await (_db.update(_db.configurations)..where(
              (c) =>
                  c.id.equals(id) &
                  (checkSource
                      ? (expectedSourceSecretId == null
                            ? c.sourceSecretId.isNull()
                            : c.sourceSecretId.equals(expectedSourceSecretId))
                      : const Constant(true)),
            ))
            .write(
              ConfigurationsCompanion(
                lastSuccessAt: Value(nowMs()),
                lastAttemptAt: Value(nowMs()),
                lastError: const Value(null),
                usageUpload: usage == null
                    ? const Value.absent()
                    : Value(usage.upload),
                usageDownload: usage == null
                    ? const Value.absent()
                    : Value(usage.download),
                usageTotal: usage == null
                    ? const Value.absent()
                    : Value(usage.total),
                expireAt: usage == null
                    ? const Value.absent()
                    : Value(_ms(usage.expireAt)),
              ),
            );
    return count > 0;
  }

  /// Records a failed refresh; the old content stays (CONFIG_PIPELINE §2).
  Future<void> recordFailure(
    String id,
    String redactedError, {
    String? expectedSourceSecretId,
    bool checkSource = false,
  }) async {
    await (_db.update(_db.configurations)..where(
          (c) =>
              c.id.equals(id) &
              (checkSource
                  ? (expectedSourceSecretId == null
                        ? c.sourceSecretId.isNull()
                        : c.sourceSecretId.equals(expectedSourceSecretId))
                  : const Constant(true)),
        ))
        .write(
          ConfigurationsCompanion(
            lastAttemptAt: Value(nowMs()),
            lastError: Value(redactedError),
          ),
        );
  }

  /// Edits name, auto-update or source (PRODUCT_SPEC §3.4).
  /// Edits a configuration's own fields. With [ifEditedAt] the edit is
  /// refused ([EditConflictException]) when it changed since then.
  Future<void> update(
    String id, {
    String? name,
    bool? autoUpdate,
    SubscriptionSource? source,
    DateTime? ifEditedAt,
  }) {
    return _db.transaction(() async {
      final row = await _row(id);
      if (row == null) return;
      checkUnchanged(row.editedAt, ifEditedAt);
      String? newSecret;
      if (source != null) newSecret = await _putSource(source);
      await (_db.update(
        _db.configurations,
      )..where((c) => c.id.equals(id))).write(
        ConfigurationsCompanion(
          name: name == null ? const Value.absent() : Value(name),
          autoUpdate: autoUpdate == null
              ? const Value.absent()
              : Value(autoUpdate),
          sourceSecretId: newSecret == null
              ? const Value.absent()
              : Value(newSecret),
          sourceDisplay: source == null
              ? const Value.absent()
              : Value(Uri.tryParse(source.url.value)?.host),
          editedAt: Value(nowMs()),
        ),
      );
      if (newSecret != null) {
        await _secrets.delete(row.sourceSecretId);
      }
      await onSyncEdit?.call('configuration', id, false);
    });
  }

  /// Deletes an imported configuration with its content, selections and
  /// memberships (cascade) and their secrets. The built-in 「自建节点」
  /// configuration cannot be deleted.
  Future<void> delete(String id) {
    if (id == AppDatabase.selfConfigurationId) {
      throw ArgumentError.value(id, 'id', 'built-in configuration');
    }
    return _db.transaction(() async {
      final row = await _row(id);
      if (row == null) return;
      final content = await (_db.select(
        _db.contents,
      )..where((c) => c.configurationId.equals(id))).getSingleOrNull();
      await onSyncEdit?.call('configuration', id, true);
      await (_db.delete(
        _db.configurations,
      )..where((c) => c.id.equals(id))).go();
      await _secrets.delete(content?.secretId);
      await _secrets.delete(row.sourceSecretId);
    });
  }

  Future<String> _insertContent(
    String configurationId,
    ParsedContent parsed,
    String digest,
  ) async {
    final (:public, :secrets) = ContentSecrets.split(parsed.content.toJson());
    final id = newId();
    await _db
        .into(_db.contents)
        .insert(
          ContentsCompanion.insert(
            id: id,
            configurationId: configurationId,
            format: parsed.format.name,
            modelJson: jsonEncode(public),
            secretId: await _secrets.put(secrets),
            nodeCount: parsed.content.nodes.length,
            digest: digest,
            warningsJson: jsonEncode([
              for (final w in parsed.content.warnings) w.toJson(),
            ]),
            createdAt: nowMs(),
          ),
        );
    return id;
  }

  /// The source model and its secrets share one entry: `model` holds the
  /// public JSON, the rest are the lifted values.
  Future<String> _putSource(SubscriptionSource source) {
    final (:public, :secrets) = SecretCodec.split(source.toJson());
    return _secrets.put({...secrets, 'model': jsonEncode(public)});
  }

  static int? _ms(DateTime? t) => t?.toUtc().millisecondsSinceEpoch;

  static Configuration _toModel(ConfigurationRow r) => Configuration(
    id: r.id,
    kind: ConfigurationKind.values.byName(r.kind),
    name: r.name,
    sourceDisplay: r.sourceDisplay,
    autoUpdate: r.autoUpdate,
    usage: r.usageUpload == null && r.usageTotal == null
        ? null
        : Usage(
            upload: r.usageUpload ?? 0,
            download: r.usageDownload ?? 0,
            total: r.usageTotal,
            expireAt: fromMs(r.expireAt),
          ),
    lastSuccessAt: fromMs(r.lastSuccessAt),
    lastAttemptAt: fromMs(r.lastAttemptAt),
    lastError: r.lastError,
    createdAt: fromMs(r.createdAt)!,
    editedAt: fromMs(r.editedAt)!,
  );
}
