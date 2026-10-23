// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ConfigurationsTable extends Configurations
    with TableInfo<$ConfigurationsTable, ConfigurationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ConfigurationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceSecretIdMeta = const VerificationMeta(
    'sourceSecretId',
  );
  @override
  late final GeneratedColumn<String> sourceSecretId = GeneratedColumn<String>(
    'source_secret_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceDisplayMeta = const VerificationMeta(
    'sourceDisplay',
  );
  @override
  late final GeneratedColumn<String> sourceDisplay = GeneratedColumn<String>(
    'source_display',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _autoUpdateMeta = const VerificationMeta(
    'autoUpdate',
  );
  @override
  late final GeneratedColumn<bool> autoUpdate = GeneratedColumn<bool>(
    'auto_update',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("auto_update" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _contentIdMeta = const VerificationMeta(
    'contentId',
  );
  @override
  late final GeneratedColumn<String> contentId = GeneratedColumn<String>(
    'content_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _usageUploadMeta = const VerificationMeta(
    'usageUpload',
  );
  @override
  late final GeneratedColumn<int> usageUpload = GeneratedColumn<int>(
    'usage_upload',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _usageDownloadMeta = const VerificationMeta(
    'usageDownload',
  );
  @override
  late final GeneratedColumn<int> usageDownload = GeneratedColumn<int>(
    'usage_download',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _usageTotalMeta = const VerificationMeta(
    'usageTotal',
  );
  @override
  late final GeneratedColumn<int> usageTotal = GeneratedColumn<int>(
    'usage_total',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _expireAtMeta = const VerificationMeta(
    'expireAt',
  );
  @override
  late final GeneratedColumn<int> expireAt = GeneratedColumn<int>(
    'expire_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastSuccessAtMeta = const VerificationMeta(
    'lastSuccessAt',
  );
  @override
  late final GeneratedColumn<int> lastSuccessAt = GeneratedColumn<int>(
    'last_success_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastAttemptAtMeta = const VerificationMeta(
    'lastAttemptAt',
  );
  @override
  late final GeneratedColumn<int> lastAttemptAt = GeneratedColumn<int>(
    'last_attempt_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _editedAtMeta = const VerificationMeta(
    'editedAt',
  );
  @override
  late final GeneratedColumn<int> editedAt = GeneratedColumn<int>(
    'edited_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cloudAccountIdMeta = const VerificationMeta(
    'cloudAccountId',
  );
  @override
  late final GeneratedColumn<String> cloudAccountId = GeneratedColumn<String>(
    'cloud_account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    name,
    sourceSecretId,
    sourceDisplay,
    autoUpdate,
    contentId,
    usageUpload,
    usageDownload,
    usageTotal,
    expireAt,
    lastSuccessAt,
    lastAttemptAt,
    lastError,
    createdAt,
    editedAt,
    cloudAccountId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'configurations';
  @override
  VerificationContext validateIntegrity(
    Insertable<ConfigurationRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('source_secret_id')) {
      context.handle(
        _sourceSecretIdMeta,
        sourceSecretId.isAcceptableOrUnknown(
          data['source_secret_id']!,
          _sourceSecretIdMeta,
        ),
      );
    }
    if (data.containsKey('source_display')) {
      context.handle(
        _sourceDisplayMeta,
        sourceDisplay.isAcceptableOrUnknown(
          data['source_display']!,
          _sourceDisplayMeta,
        ),
      );
    }
    if (data.containsKey('auto_update')) {
      context.handle(
        _autoUpdateMeta,
        autoUpdate.isAcceptableOrUnknown(data['auto_update']!, _autoUpdateMeta),
      );
    }
    if (data.containsKey('content_id')) {
      context.handle(
        _contentIdMeta,
        contentId.isAcceptableOrUnknown(data['content_id']!, _contentIdMeta),
      );
    }
    if (data.containsKey('usage_upload')) {
      context.handle(
        _usageUploadMeta,
        usageUpload.isAcceptableOrUnknown(
          data['usage_upload']!,
          _usageUploadMeta,
        ),
      );
    }
    if (data.containsKey('usage_download')) {
      context.handle(
        _usageDownloadMeta,
        usageDownload.isAcceptableOrUnknown(
          data['usage_download']!,
          _usageDownloadMeta,
        ),
      );
    }
    if (data.containsKey('usage_total')) {
      context.handle(
        _usageTotalMeta,
        usageTotal.isAcceptableOrUnknown(data['usage_total']!, _usageTotalMeta),
      );
    }
    if (data.containsKey('expire_at')) {
      context.handle(
        _expireAtMeta,
        expireAt.isAcceptableOrUnknown(data['expire_at']!, _expireAtMeta),
      );
    }
    if (data.containsKey('last_success_at')) {
      context.handle(
        _lastSuccessAtMeta,
        lastSuccessAt.isAcceptableOrUnknown(
          data['last_success_at']!,
          _lastSuccessAtMeta,
        ),
      );
    }
    if (data.containsKey('last_attempt_at')) {
      context.handle(
        _lastAttemptAtMeta,
        lastAttemptAt.isAcceptableOrUnknown(
          data['last_attempt_at']!,
          _lastAttemptAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('edited_at')) {
      context.handle(
        _editedAtMeta,
        editedAt.isAcceptableOrUnknown(data['edited_at']!, _editedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_editedAtMeta);
    }
    if (data.containsKey('cloud_account_id')) {
      context.handle(
        _cloudAccountIdMeta,
        cloudAccountId.isAcceptableOrUnknown(
          data['cloud_account_id']!,
          _cloudAccountIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ConfigurationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ConfigurationRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      sourceSecretId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_secret_id'],
      ),
      sourceDisplay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_display'],
      ),
      autoUpdate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}auto_update'],
      )!,
      contentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_id'],
      ),
      usageUpload: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}usage_upload'],
      ),
      usageDownload: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}usage_download'],
      ),
      usageTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}usage_total'],
      ),
      expireAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expire_at'],
      ),
      lastSuccessAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_success_at'],
      ),
      lastAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_attempt_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      editedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}edited_at'],
      )!,
      cloudAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cloud_account_id'],
      ),
    );
  }

  @override
  $ConfigurationsTable createAlias(String alias) {
    return $ConfigurationsTable(attachedDatabase, alias);
  }
}

class ConfigurationRow extends DataClass
    implements Insertable<ConfigurationRow> {
  final String id;

  /// `subscription`, `file` or `self`.
  final String kind;
  final String name;

  /// Subscription URL and headers (a secrets entry).
  final String? sourceSecretId;

  /// Host of the subscription URL, shown in the UI.
  final String? sourceDisplay;
  final bool autoUpdate;
  final String? contentId;
  final int? usageUpload;
  final int? usageDownload;
  final int? usageTotal;
  final int? expireAt;
  final int? lastSuccessAt;
  final int? lastAttemptAt;
  final String? lastError;
  final int createdAt;
  final int editedAt;
  final String? cloudAccountId;
  const ConfigurationRow({
    required this.id,
    required this.kind,
    required this.name,
    this.sourceSecretId,
    this.sourceDisplay,
    required this.autoUpdate,
    this.contentId,
    this.usageUpload,
    this.usageDownload,
    this.usageTotal,
    this.expireAt,
    this.lastSuccessAt,
    this.lastAttemptAt,
    this.lastError,
    required this.createdAt,
    required this.editedAt,
    this.cloudAccountId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || sourceSecretId != null) {
      map['source_secret_id'] = Variable<String>(sourceSecretId);
    }
    if (!nullToAbsent || sourceDisplay != null) {
      map['source_display'] = Variable<String>(sourceDisplay);
    }
    map['auto_update'] = Variable<bool>(autoUpdate);
    if (!nullToAbsent || contentId != null) {
      map['content_id'] = Variable<String>(contentId);
    }
    if (!nullToAbsent || usageUpload != null) {
      map['usage_upload'] = Variable<int>(usageUpload);
    }
    if (!nullToAbsent || usageDownload != null) {
      map['usage_download'] = Variable<int>(usageDownload);
    }
    if (!nullToAbsent || usageTotal != null) {
      map['usage_total'] = Variable<int>(usageTotal);
    }
    if (!nullToAbsent || expireAt != null) {
      map['expire_at'] = Variable<int>(expireAt);
    }
    if (!nullToAbsent || lastSuccessAt != null) {
      map['last_success_at'] = Variable<int>(lastSuccessAt);
    }
    if (!nullToAbsent || lastAttemptAt != null) {
      map['last_attempt_at'] = Variable<int>(lastAttemptAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['edited_at'] = Variable<int>(editedAt);
    if (!nullToAbsent || cloudAccountId != null) {
      map['cloud_account_id'] = Variable<String>(cloudAccountId);
    }
    return map;
  }

  ConfigurationsCompanion toCompanion(bool nullToAbsent) {
    return ConfigurationsCompanion(
      id: Value(id),
      kind: Value(kind),
      name: Value(name),
      sourceSecretId: sourceSecretId == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceSecretId),
      sourceDisplay: sourceDisplay == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceDisplay),
      autoUpdate: Value(autoUpdate),
      contentId: contentId == null && nullToAbsent
          ? const Value.absent()
          : Value(contentId),
      usageUpload: usageUpload == null && nullToAbsent
          ? const Value.absent()
          : Value(usageUpload),
      usageDownload: usageDownload == null && nullToAbsent
          ? const Value.absent()
          : Value(usageDownload),
      usageTotal: usageTotal == null && nullToAbsent
          ? const Value.absent()
          : Value(usageTotal),
      expireAt: expireAt == null && nullToAbsent
          ? const Value.absent()
          : Value(expireAt),
      lastSuccessAt: lastSuccessAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSuccessAt),
      lastAttemptAt: lastAttemptAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAttemptAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAt: Value(createdAt),
      editedAt: Value(editedAt),
      cloudAccountId: cloudAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudAccountId),
    );
  }

  factory ConfigurationRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ConfigurationRow(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      name: serializer.fromJson<String>(json['name']),
      sourceSecretId: serializer.fromJson<String?>(json['sourceSecretId']),
      sourceDisplay: serializer.fromJson<String?>(json['sourceDisplay']),
      autoUpdate: serializer.fromJson<bool>(json['autoUpdate']),
      contentId: serializer.fromJson<String?>(json['contentId']),
      usageUpload: serializer.fromJson<int?>(json['usageUpload']),
      usageDownload: serializer.fromJson<int?>(json['usageDownload']),
      usageTotal: serializer.fromJson<int?>(json['usageTotal']),
      expireAt: serializer.fromJson<int?>(json['expireAt']),
      lastSuccessAt: serializer.fromJson<int?>(json['lastSuccessAt']),
      lastAttemptAt: serializer.fromJson<int?>(json['lastAttemptAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      editedAt: serializer.fromJson<int>(json['editedAt']),
      cloudAccountId: serializer.fromJson<String?>(json['cloudAccountId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'name': serializer.toJson<String>(name),
      'sourceSecretId': serializer.toJson<String?>(sourceSecretId),
      'sourceDisplay': serializer.toJson<String?>(sourceDisplay),
      'autoUpdate': serializer.toJson<bool>(autoUpdate),
      'contentId': serializer.toJson<String?>(contentId),
      'usageUpload': serializer.toJson<int?>(usageUpload),
      'usageDownload': serializer.toJson<int?>(usageDownload),
      'usageTotal': serializer.toJson<int?>(usageTotal),
      'expireAt': serializer.toJson<int?>(expireAt),
      'lastSuccessAt': serializer.toJson<int?>(lastSuccessAt),
      'lastAttemptAt': serializer.toJson<int?>(lastAttemptAt),
      'lastError': serializer.toJson<String?>(lastError),
      'createdAt': serializer.toJson<int>(createdAt),
      'editedAt': serializer.toJson<int>(editedAt),
      'cloudAccountId': serializer.toJson<String?>(cloudAccountId),
    };
  }

  ConfigurationRow copyWith({
    String? id,
    String? kind,
    String? name,
    Value<String?> sourceSecretId = const Value.absent(),
    Value<String?> sourceDisplay = const Value.absent(),
    bool? autoUpdate,
    Value<String?> contentId = const Value.absent(),
    Value<int?> usageUpload = const Value.absent(),
    Value<int?> usageDownload = const Value.absent(),
    Value<int?> usageTotal = const Value.absent(),
    Value<int?> expireAt = const Value.absent(),
    Value<int?> lastSuccessAt = const Value.absent(),
    Value<int?> lastAttemptAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    int? createdAt,
    int? editedAt,
    Value<String?> cloudAccountId = const Value.absent(),
  }) => ConfigurationRow(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    name: name ?? this.name,
    sourceSecretId: sourceSecretId.present
        ? sourceSecretId.value
        : this.sourceSecretId,
    sourceDisplay: sourceDisplay.present
        ? sourceDisplay.value
        : this.sourceDisplay,
    autoUpdate: autoUpdate ?? this.autoUpdate,
    contentId: contentId.present ? contentId.value : this.contentId,
    usageUpload: usageUpload.present ? usageUpload.value : this.usageUpload,
    usageDownload: usageDownload.present
        ? usageDownload.value
        : this.usageDownload,
    usageTotal: usageTotal.present ? usageTotal.value : this.usageTotal,
    expireAt: expireAt.present ? expireAt.value : this.expireAt,
    lastSuccessAt: lastSuccessAt.present
        ? lastSuccessAt.value
        : this.lastSuccessAt,
    lastAttemptAt: lastAttemptAt.present
        ? lastAttemptAt.value
        : this.lastAttemptAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAt: createdAt ?? this.createdAt,
    editedAt: editedAt ?? this.editedAt,
    cloudAccountId: cloudAccountId.present
        ? cloudAccountId.value
        : this.cloudAccountId,
  );
  ConfigurationRow copyWithCompanion(ConfigurationsCompanion data) {
    return ConfigurationRow(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      name: data.name.present ? data.name.value : this.name,
      sourceSecretId: data.sourceSecretId.present
          ? data.sourceSecretId.value
          : this.sourceSecretId,
      sourceDisplay: data.sourceDisplay.present
          ? data.sourceDisplay.value
          : this.sourceDisplay,
      autoUpdate: data.autoUpdate.present
          ? data.autoUpdate.value
          : this.autoUpdate,
      contentId: data.contentId.present ? data.contentId.value : this.contentId,
      usageUpload: data.usageUpload.present
          ? data.usageUpload.value
          : this.usageUpload,
      usageDownload: data.usageDownload.present
          ? data.usageDownload.value
          : this.usageDownload,
      usageTotal: data.usageTotal.present
          ? data.usageTotal.value
          : this.usageTotal,
      expireAt: data.expireAt.present ? data.expireAt.value : this.expireAt,
      lastSuccessAt: data.lastSuccessAt.present
          ? data.lastSuccessAt.value
          : this.lastSuccessAt,
      lastAttemptAt: data.lastAttemptAt.present
          ? data.lastAttemptAt.value
          : this.lastAttemptAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      editedAt: data.editedAt.present ? data.editedAt.value : this.editedAt,
      cloudAccountId: data.cloudAccountId.present
          ? data.cloudAccountId.value
          : this.cloudAccountId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ConfigurationRow(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('sourceSecretId: $sourceSecretId, ')
          ..write('sourceDisplay: $sourceDisplay, ')
          ..write('autoUpdate: $autoUpdate, ')
          ..write('contentId: $contentId, ')
          ..write('usageUpload: $usageUpload, ')
          ..write('usageDownload: $usageDownload, ')
          ..write('usageTotal: $usageTotal, ')
          ..write('expireAt: $expireAt, ')
          ..write('lastSuccessAt: $lastSuccessAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('editedAt: $editedAt, ')
          ..write('cloudAccountId: $cloudAccountId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    name,
    sourceSecretId,
    sourceDisplay,
    autoUpdate,
    contentId,
    usageUpload,
    usageDownload,
    usageTotal,
    expireAt,
    lastSuccessAt,
    lastAttemptAt,
    lastError,
    createdAt,
    editedAt,
    cloudAccountId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ConfigurationRow &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.name == this.name &&
          other.sourceSecretId == this.sourceSecretId &&
          other.sourceDisplay == this.sourceDisplay &&
          other.autoUpdate == this.autoUpdate &&
          other.contentId == this.contentId &&
          other.usageUpload == this.usageUpload &&
          other.usageDownload == this.usageDownload &&
          other.usageTotal == this.usageTotal &&
          other.expireAt == this.expireAt &&
          other.lastSuccessAt == this.lastSuccessAt &&
          other.lastAttemptAt == this.lastAttemptAt &&
          other.lastError == this.lastError &&
          other.createdAt == this.createdAt &&
          other.editedAt == this.editedAt &&
          other.cloudAccountId == this.cloudAccountId);
}

class ConfigurationsCompanion extends UpdateCompanion<ConfigurationRow> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String> name;
  final Value<String?> sourceSecretId;
  final Value<String?> sourceDisplay;
  final Value<bool> autoUpdate;
  final Value<String?> contentId;
  final Value<int?> usageUpload;
  final Value<int?> usageDownload;
  final Value<int?> usageTotal;
  final Value<int?> expireAt;
  final Value<int?> lastSuccessAt;
  final Value<int?> lastAttemptAt;
  final Value<String?> lastError;
  final Value<int> createdAt;
  final Value<int> editedAt;
  final Value<String?> cloudAccountId;
  final Value<int> rowid;
  const ConfigurationsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.name = const Value.absent(),
    this.sourceSecretId = const Value.absent(),
    this.sourceDisplay = const Value.absent(),
    this.autoUpdate = const Value.absent(),
    this.contentId = const Value.absent(),
    this.usageUpload = const Value.absent(),
    this.usageDownload = const Value.absent(),
    this.usageTotal = const Value.absent(),
    this.expireAt = const Value.absent(),
    this.lastSuccessAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.cloudAccountId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConfigurationsCompanion.insert({
    required String id,
    required String kind,
    required String name,
    this.sourceSecretId = const Value.absent(),
    this.sourceDisplay = const Value.absent(),
    this.autoUpdate = const Value.absent(),
    this.contentId = const Value.absent(),
    this.usageUpload = const Value.absent(),
    this.usageDownload = const Value.absent(),
    this.usageTotal = const Value.absent(),
    this.expireAt = const Value.absent(),
    this.lastSuccessAt = const Value.absent(),
    this.lastAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    required int createdAt,
    required int editedAt,
    this.cloudAccountId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       name = Value(name),
       createdAt = Value(createdAt),
       editedAt = Value(editedAt);
  static Insertable<ConfigurationRow> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? name,
    Expression<String>? sourceSecretId,
    Expression<String>? sourceDisplay,
    Expression<bool>? autoUpdate,
    Expression<String>? contentId,
    Expression<int>? usageUpload,
    Expression<int>? usageDownload,
    Expression<int>? usageTotal,
    Expression<int>? expireAt,
    Expression<int>? lastSuccessAt,
    Expression<int>? lastAttemptAt,
    Expression<String>? lastError,
    Expression<int>? createdAt,
    Expression<int>? editedAt,
    Expression<String>? cloudAccountId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (name != null) 'name': name,
      if (sourceSecretId != null) 'source_secret_id': sourceSecretId,
      if (sourceDisplay != null) 'source_display': sourceDisplay,
      if (autoUpdate != null) 'auto_update': autoUpdate,
      if (contentId != null) 'content_id': contentId,
      if (usageUpload != null) 'usage_upload': usageUpload,
      if (usageDownload != null) 'usage_download': usageDownload,
      if (usageTotal != null) 'usage_total': usageTotal,
      if (expireAt != null) 'expire_at': expireAt,
      if (lastSuccessAt != null) 'last_success_at': lastSuccessAt,
      if (lastAttemptAt != null) 'last_attempt_at': lastAttemptAt,
      if (lastError != null) 'last_error': lastError,
      if (createdAt != null) 'created_at': createdAt,
      if (editedAt != null) 'edited_at': editedAt,
      if (cloudAccountId != null) 'cloud_account_id': cloudAccountId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConfigurationsCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<String>? name,
    Value<String?>? sourceSecretId,
    Value<String?>? sourceDisplay,
    Value<bool>? autoUpdate,
    Value<String?>? contentId,
    Value<int?>? usageUpload,
    Value<int?>? usageDownload,
    Value<int?>? usageTotal,
    Value<int?>? expireAt,
    Value<int?>? lastSuccessAt,
    Value<int?>? lastAttemptAt,
    Value<String?>? lastError,
    Value<int>? createdAt,
    Value<int>? editedAt,
    Value<String?>? cloudAccountId,
    Value<int>? rowid,
  }) {
    return ConfigurationsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      name: name ?? this.name,
      sourceSecretId: sourceSecretId ?? this.sourceSecretId,
      sourceDisplay: sourceDisplay ?? this.sourceDisplay,
      autoUpdate: autoUpdate ?? this.autoUpdate,
      contentId: contentId ?? this.contentId,
      usageUpload: usageUpload ?? this.usageUpload,
      usageDownload: usageDownload ?? this.usageDownload,
      usageTotal: usageTotal ?? this.usageTotal,
      expireAt: expireAt ?? this.expireAt,
      lastSuccessAt: lastSuccessAt ?? this.lastSuccessAt,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      cloudAccountId: cloudAccountId ?? this.cloudAccountId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (sourceSecretId.present) {
      map['source_secret_id'] = Variable<String>(sourceSecretId.value);
    }
    if (sourceDisplay.present) {
      map['source_display'] = Variable<String>(sourceDisplay.value);
    }
    if (autoUpdate.present) {
      map['auto_update'] = Variable<bool>(autoUpdate.value);
    }
    if (contentId.present) {
      map['content_id'] = Variable<String>(contentId.value);
    }
    if (usageUpload.present) {
      map['usage_upload'] = Variable<int>(usageUpload.value);
    }
    if (usageDownload.present) {
      map['usage_download'] = Variable<int>(usageDownload.value);
    }
    if (usageTotal.present) {
      map['usage_total'] = Variable<int>(usageTotal.value);
    }
    if (expireAt.present) {
      map['expire_at'] = Variable<int>(expireAt.value);
    }
    if (lastSuccessAt.present) {
      map['last_success_at'] = Variable<int>(lastSuccessAt.value);
    }
    if (lastAttemptAt.present) {
      map['last_attempt_at'] = Variable<int>(lastAttemptAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (editedAt.present) {
      map['edited_at'] = Variable<int>(editedAt.value);
    }
    if (cloudAccountId.present) {
      map['cloud_account_id'] = Variable<String>(cloudAccountId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConfigurationsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('name: $name, ')
          ..write('sourceSecretId: $sourceSecretId, ')
          ..write('sourceDisplay: $sourceDisplay, ')
          ..write('autoUpdate: $autoUpdate, ')
          ..write('contentId: $contentId, ')
          ..write('usageUpload: $usageUpload, ')
          ..write('usageDownload: $usageDownload, ')
          ..write('usageTotal: $usageTotal, ')
          ..write('expireAt: $expireAt, ')
          ..write('lastSuccessAt: $lastSuccessAt, ')
          ..write('lastAttemptAt: $lastAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('createdAt: $createdAt, ')
          ..write('editedAt: $editedAt, ')
          ..write('cloudAccountId: $cloudAccountId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContentsTable extends Contents
    with TableInfo<$ContentsTable, ContentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _configurationIdMeta = const VerificationMeta(
    'configurationId',
  );
  @override
  late final GeneratedColumn<String> configurationId = GeneratedColumn<String>(
    'configuration_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES configurations (id) ON UPDATE CASCADE ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _modelJsonMeta = const VerificationMeta(
    'modelJson',
  );
  @override
  late final GeneratedColumn<String> modelJson = GeneratedColumn<String>(
    'model_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _secretIdMeta = const VerificationMeta(
    'secretId',
  );
  @override
  late final GeneratedColumn<String> secretId = GeneratedColumn<String>(
    'secret_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nodeCountMeta = const VerificationMeta(
    'nodeCount',
  );
  @override
  late final GeneratedColumn<int> nodeCount = GeneratedColumn<int>(
    'node_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _digestMeta = const VerificationMeta('digest');
  @override
  late final GeneratedColumn<String> digest = GeneratedColumn<String>(
    'digest',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _warningsJsonMeta = const VerificationMeta(
    'warningsJson',
  );
  @override
  late final GeneratedColumn<String> warningsJson = GeneratedColumn<String>(
    'warnings_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    configurationId,
    format,
    modelJson,
    secretId,
    nodeCount,
    digest,
    warningsJson,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'contents';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('configuration_id')) {
      context.handle(
        _configurationIdMeta,
        configurationId.isAcceptableOrUnknown(
          data['configuration_id']!,
          _configurationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_configurationIdMeta);
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    } else if (isInserting) {
      context.missing(_formatMeta);
    }
    if (data.containsKey('model_json')) {
      context.handle(
        _modelJsonMeta,
        modelJson.isAcceptableOrUnknown(data['model_json']!, _modelJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_modelJsonMeta);
    }
    if (data.containsKey('secret_id')) {
      context.handle(
        _secretIdMeta,
        secretId.isAcceptableOrUnknown(data['secret_id']!, _secretIdMeta),
      );
    } else if (isInserting) {
      context.missing(_secretIdMeta);
    }
    if (data.containsKey('node_count')) {
      context.handle(
        _nodeCountMeta,
        nodeCount.isAcceptableOrUnknown(data['node_count']!, _nodeCountMeta),
      );
    } else if (isInserting) {
      context.missing(_nodeCountMeta);
    }
    if (data.containsKey('digest')) {
      context.handle(
        _digestMeta,
        digest.isAcceptableOrUnknown(data['digest']!, _digestMeta),
      );
    } else if (isInserting) {
      context.missing(_digestMeta);
    }
    if (data.containsKey('warnings_json')) {
      context.handle(
        _warningsJsonMeta,
        warningsJson.isAcceptableOrUnknown(
          data['warnings_json']!,
          _warningsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_warningsJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ContentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      configurationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}configuration_id'],
      )!,
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      )!,
      modelJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}model_json'],
      )!,
      secretId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}secret_id'],
      )!,
      nodeCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}node_count'],
      )!,
      digest: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}digest'],
      )!,
      warningsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}warnings_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ContentsTable createAlias(String alias) {
    return $ContentsTable(attachedDatabase, alias);
  }
}

class ContentRow extends DataClass implements Insertable<ContentRow> {
  final String id;
  final String configurationId;

  /// `singBox`, `clash` or `linkList`.
  final String format;

  /// `ConfigContent` JSON with secrets lifted out (`SecretCodec`).
  final String modelJson;
  final String secretId;

  /// Shown on the card without decrypting the content.
  final int nodeCount;

  /// SHA-256 of the downloaded text; unchanged downloads skip the update.
  final String digest;
  final String warningsJson;
  final int createdAt;
  const ContentRow({
    required this.id,
    required this.configurationId,
    required this.format,
    required this.modelJson,
    required this.secretId,
    required this.nodeCount,
    required this.digest,
    required this.warningsJson,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['configuration_id'] = Variable<String>(configurationId);
    map['format'] = Variable<String>(format);
    map['model_json'] = Variable<String>(modelJson);
    map['secret_id'] = Variable<String>(secretId);
    map['node_count'] = Variable<int>(nodeCount);
    map['digest'] = Variable<String>(digest);
    map['warnings_json'] = Variable<String>(warningsJson);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  ContentsCompanion toCompanion(bool nullToAbsent) {
    return ContentsCompanion(
      id: Value(id),
      configurationId: Value(configurationId),
      format: Value(format),
      modelJson: Value(modelJson),
      secretId: Value(secretId),
      nodeCount: Value(nodeCount),
      digest: Value(digest),
      warningsJson: Value(warningsJson),
      createdAt: Value(createdAt),
    );
  }

  factory ContentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContentRow(
      id: serializer.fromJson<String>(json['id']),
      configurationId: serializer.fromJson<String>(json['configurationId']),
      format: serializer.fromJson<String>(json['format']),
      modelJson: serializer.fromJson<String>(json['modelJson']),
      secretId: serializer.fromJson<String>(json['secretId']),
      nodeCount: serializer.fromJson<int>(json['nodeCount']),
      digest: serializer.fromJson<String>(json['digest']),
      warningsJson: serializer.fromJson<String>(json['warningsJson']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'configurationId': serializer.toJson<String>(configurationId),
      'format': serializer.toJson<String>(format),
      'modelJson': serializer.toJson<String>(modelJson),
      'secretId': serializer.toJson<String>(secretId),
      'nodeCount': serializer.toJson<int>(nodeCount),
      'digest': serializer.toJson<String>(digest),
      'warningsJson': serializer.toJson<String>(warningsJson),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  ContentRow copyWith({
    String? id,
    String? configurationId,
    String? format,
    String? modelJson,
    String? secretId,
    int? nodeCount,
    String? digest,
    String? warningsJson,
    int? createdAt,
  }) => ContentRow(
    id: id ?? this.id,
    configurationId: configurationId ?? this.configurationId,
    format: format ?? this.format,
    modelJson: modelJson ?? this.modelJson,
    secretId: secretId ?? this.secretId,
    nodeCount: nodeCount ?? this.nodeCount,
    digest: digest ?? this.digest,
    warningsJson: warningsJson ?? this.warningsJson,
    createdAt: createdAt ?? this.createdAt,
  );
  ContentRow copyWithCompanion(ContentsCompanion data) {
    return ContentRow(
      id: data.id.present ? data.id.value : this.id,
      configurationId: data.configurationId.present
          ? data.configurationId.value
          : this.configurationId,
      format: data.format.present ? data.format.value : this.format,
      modelJson: data.modelJson.present ? data.modelJson.value : this.modelJson,
      secretId: data.secretId.present ? data.secretId.value : this.secretId,
      nodeCount: data.nodeCount.present ? data.nodeCount.value : this.nodeCount,
      digest: data.digest.present ? data.digest.value : this.digest,
      warningsJson: data.warningsJson.present
          ? data.warningsJson.value
          : this.warningsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContentRow(')
          ..write('id: $id, ')
          ..write('configurationId: $configurationId, ')
          ..write('format: $format, ')
          ..write('modelJson: $modelJson, ')
          ..write('secretId: $secretId, ')
          ..write('nodeCount: $nodeCount, ')
          ..write('digest: $digest, ')
          ..write('warningsJson: $warningsJson, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    configurationId,
    format,
    modelJson,
    secretId,
    nodeCount,
    digest,
    warningsJson,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContentRow &&
          other.id == this.id &&
          other.configurationId == this.configurationId &&
          other.format == this.format &&
          other.modelJson == this.modelJson &&
          other.secretId == this.secretId &&
          other.nodeCount == this.nodeCount &&
          other.digest == this.digest &&
          other.warningsJson == this.warningsJson &&
          other.createdAt == this.createdAt);
}

class ContentsCompanion extends UpdateCompanion<ContentRow> {
  final Value<String> id;
  final Value<String> configurationId;
  final Value<String> format;
  final Value<String> modelJson;
  final Value<String> secretId;
  final Value<int> nodeCount;
  final Value<String> digest;
  final Value<String> warningsJson;
  final Value<int> createdAt;
  final Value<int> rowid;
  const ContentsCompanion({
    this.id = const Value.absent(),
    this.configurationId = const Value.absent(),
    this.format = const Value.absent(),
    this.modelJson = const Value.absent(),
    this.secretId = const Value.absent(),
    this.nodeCount = const Value.absent(),
    this.digest = const Value.absent(),
    this.warningsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContentsCompanion.insert({
    required String id,
    required String configurationId,
    required String format,
    required String modelJson,
    required String secretId,
    required int nodeCount,
    required String digest,
    required String warningsJson,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       configurationId = Value(configurationId),
       format = Value(format),
       modelJson = Value(modelJson),
       secretId = Value(secretId),
       nodeCount = Value(nodeCount),
       digest = Value(digest),
       warningsJson = Value(warningsJson),
       createdAt = Value(createdAt);
  static Insertable<ContentRow> custom({
    Expression<String>? id,
    Expression<String>? configurationId,
    Expression<String>? format,
    Expression<String>? modelJson,
    Expression<String>? secretId,
    Expression<int>? nodeCount,
    Expression<String>? digest,
    Expression<String>? warningsJson,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (configurationId != null) 'configuration_id': configurationId,
      if (format != null) 'format': format,
      if (modelJson != null) 'model_json': modelJson,
      if (secretId != null) 'secret_id': secretId,
      if (nodeCount != null) 'node_count': nodeCount,
      if (digest != null) 'digest': digest,
      if (warningsJson != null) 'warnings_json': warningsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContentsCompanion copyWith({
    Value<String>? id,
    Value<String>? configurationId,
    Value<String>? format,
    Value<String>? modelJson,
    Value<String>? secretId,
    Value<int>? nodeCount,
    Value<String>? digest,
    Value<String>? warningsJson,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return ContentsCompanion(
      id: id ?? this.id,
      configurationId: configurationId ?? this.configurationId,
      format: format ?? this.format,
      modelJson: modelJson ?? this.modelJson,
      secretId: secretId ?? this.secretId,
      nodeCount: nodeCount ?? this.nodeCount,
      digest: digest ?? this.digest,
      warningsJson: warningsJson ?? this.warningsJson,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (configurationId.present) {
      map['configuration_id'] = Variable<String>(configurationId.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (modelJson.present) {
      map['model_json'] = Variable<String>(modelJson.value);
    }
    if (secretId.present) {
      map['secret_id'] = Variable<String>(secretId.value);
    }
    if (nodeCount.present) {
      map['node_count'] = Variable<int>(nodeCount.value);
    }
    if (digest.present) {
      map['digest'] = Variable<String>(digest.value);
    }
    if (warningsJson.present) {
      map['warnings_json'] = Variable<String>(warningsJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContentsCompanion(')
          ..write('id: $id, ')
          ..write('configurationId: $configurationId, ')
          ..write('format: $format, ')
          ..write('modelJson: $modelJson, ')
          ..write('secretId: $secretId, ')
          ..write('nodeCount: $nodeCount, ')
          ..write('digest: $digest, ')
          ..write('warningsJson: $warningsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SelfNodesTable extends SelfNodes
    with TableInfo<$SelfNodesTable, SelfNodeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SelfNodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _protocolMeta = const VerificationMeta(
    'protocol',
  );
  @override
  late final GeneratedColumn<String> protocol = GeneratedColumn<String>(
    'protocol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverMeta = const VerificationMeta('server');
  @override
  late final GeneratedColumn<String> server = GeneratedColumn<String>(
    'server',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _portMeta = const VerificationMeta('port');
  @override
  late final GeneratedColumn<int> port = GeneratedColumn<int>(
    'port',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _paramsJsonMeta = const VerificationMeta(
    'paramsJson',
  );
  @override
  late final GeneratedColumn<String> paramsJson = GeneratedColumn<String>(
    'params_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _secretIdMeta = const VerificationMeta(
    'secretId',
  );
  @override
  late final GeneratedColumn<String> secretId = GeneratedColumn<String>(
    'secret_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _editedAtMeta = const VerificationMeta(
    'editedAt',
  );
  @override
  late final GeneratedColumn<int> editedAt = GeneratedColumn<int>(
    'edited_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cloudAccountIdMeta = const VerificationMeta(
    'cloudAccountId',
  );
  @override
  late final GeneratedColumn<String> cloudAccountId = GeneratedColumn<String>(
    'cloud_account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    protocol,
    server,
    port,
    paramsJson,
    secretId,
    createdAt,
    editedAt,
    cloudAccountId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'self_nodes';
  @override
  VerificationContext validateIntegrity(
    Insertable<SelfNodeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('protocol')) {
      context.handle(
        _protocolMeta,
        protocol.isAcceptableOrUnknown(data['protocol']!, _protocolMeta),
      );
    } else if (isInserting) {
      context.missing(_protocolMeta);
    }
    if (data.containsKey('server')) {
      context.handle(
        _serverMeta,
        server.isAcceptableOrUnknown(data['server']!, _serverMeta),
      );
    } else if (isInserting) {
      context.missing(_serverMeta);
    }
    if (data.containsKey('port')) {
      context.handle(
        _portMeta,
        port.isAcceptableOrUnknown(data['port']!, _portMeta),
      );
    } else if (isInserting) {
      context.missing(_portMeta);
    }
    if (data.containsKey('params_json')) {
      context.handle(
        _paramsJsonMeta,
        paramsJson.isAcceptableOrUnknown(data['params_json']!, _paramsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_paramsJsonMeta);
    }
    if (data.containsKey('secret_id')) {
      context.handle(
        _secretIdMeta,
        secretId.isAcceptableOrUnknown(data['secret_id']!, _secretIdMeta),
      );
    } else if (isInserting) {
      context.missing(_secretIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('edited_at')) {
      context.handle(
        _editedAtMeta,
        editedAt.isAcceptableOrUnknown(data['edited_at']!, _editedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_editedAtMeta);
    }
    if (data.containsKey('cloud_account_id')) {
      context.handle(
        _cloudAccountIdMeta,
        cloudAccountId.isAcceptableOrUnknown(
          data['cloud_account_id']!,
          _cloudAccountIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SelfNodeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SelfNodeRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      protocol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}protocol'],
      )!,
      server: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}server'],
      )!,
      port: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}port'],
      )!,
      paramsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}params_json'],
      )!,
      secretId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}secret_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      editedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}edited_at'],
      )!,
      cloudAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cloud_account_id'],
      ),
    );
  }

  @override
  $SelfNodesTable createAlias(String alias) {
    return $SelfNodesTable(attachedDatabase, alias);
  }
}

class SelfNodeRow extends DataClass implements Insertable<SelfNodeRow> {
  final String id;
  final String name;
  final String protocol;
  final String server;
  final int port;
  final String paramsJson;
  final String secretId;
  final int createdAt;
  final int editedAt;
  final String? cloudAccountId;
  const SelfNodeRow({
    required this.id,
    required this.name,
    required this.protocol,
    required this.server,
    required this.port,
    required this.paramsJson,
    required this.secretId,
    required this.createdAt,
    required this.editedAt,
    this.cloudAccountId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['protocol'] = Variable<String>(protocol);
    map['server'] = Variable<String>(server);
    map['port'] = Variable<int>(port);
    map['params_json'] = Variable<String>(paramsJson);
    map['secret_id'] = Variable<String>(secretId);
    map['created_at'] = Variable<int>(createdAt);
    map['edited_at'] = Variable<int>(editedAt);
    if (!nullToAbsent || cloudAccountId != null) {
      map['cloud_account_id'] = Variable<String>(cloudAccountId);
    }
    return map;
  }

  SelfNodesCompanion toCompanion(bool nullToAbsent) {
    return SelfNodesCompanion(
      id: Value(id),
      name: Value(name),
      protocol: Value(protocol),
      server: Value(server),
      port: Value(port),
      paramsJson: Value(paramsJson),
      secretId: Value(secretId),
      createdAt: Value(createdAt),
      editedAt: Value(editedAt),
      cloudAccountId: cloudAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudAccountId),
    );
  }

  factory SelfNodeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SelfNodeRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      protocol: serializer.fromJson<String>(json['protocol']),
      server: serializer.fromJson<String>(json['server']),
      port: serializer.fromJson<int>(json['port']),
      paramsJson: serializer.fromJson<String>(json['paramsJson']),
      secretId: serializer.fromJson<String>(json['secretId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      editedAt: serializer.fromJson<int>(json['editedAt']),
      cloudAccountId: serializer.fromJson<String?>(json['cloudAccountId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'protocol': serializer.toJson<String>(protocol),
      'server': serializer.toJson<String>(server),
      'port': serializer.toJson<int>(port),
      'paramsJson': serializer.toJson<String>(paramsJson),
      'secretId': serializer.toJson<String>(secretId),
      'createdAt': serializer.toJson<int>(createdAt),
      'editedAt': serializer.toJson<int>(editedAt),
      'cloudAccountId': serializer.toJson<String?>(cloudAccountId),
    };
  }

  SelfNodeRow copyWith({
    String? id,
    String? name,
    String? protocol,
    String? server,
    int? port,
    String? paramsJson,
    String? secretId,
    int? createdAt,
    int? editedAt,
    Value<String?> cloudAccountId = const Value.absent(),
  }) => SelfNodeRow(
    id: id ?? this.id,
    name: name ?? this.name,
    protocol: protocol ?? this.protocol,
    server: server ?? this.server,
    port: port ?? this.port,
    paramsJson: paramsJson ?? this.paramsJson,
    secretId: secretId ?? this.secretId,
    createdAt: createdAt ?? this.createdAt,
    editedAt: editedAt ?? this.editedAt,
    cloudAccountId: cloudAccountId.present
        ? cloudAccountId.value
        : this.cloudAccountId,
  );
  SelfNodeRow copyWithCompanion(SelfNodesCompanion data) {
    return SelfNodeRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      protocol: data.protocol.present ? data.protocol.value : this.protocol,
      server: data.server.present ? data.server.value : this.server,
      port: data.port.present ? data.port.value : this.port,
      paramsJson: data.paramsJson.present
          ? data.paramsJson.value
          : this.paramsJson,
      secretId: data.secretId.present ? data.secretId.value : this.secretId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      editedAt: data.editedAt.present ? data.editedAt.value : this.editedAt,
      cloudAccountId: data.cloudAccountId.present
          ? data.cloudAccountId.value
          : this.cloudAccountId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SelfNodeRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('protocol: $protocol, ')
          ..write('server: $server, ')
          ..write('port: $port, ')
          ..write('paramsJson: $paramsJson, ')
          ..write('secretId: $secretId, ')
          ..write('createdAt: $createdAt, ')
          ..write('editedAt: $editedAt, ')
          ..write('cloudAccountId: $cloudAccountId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    protocol,
    server,
    port,
    paramsJson,
    secretId,
    createdAt,
    editedAt,
    cloudAccountId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SelfNodeRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.protocol == this.protocol &&
          other.server == this.server &&
          other.port == this.port &&
          other.paramsJson == this.paramsJson &&
          other.secretId == this.secretId &&
          other.createdAt == this.createdAt &&
          other.editedAt == this.editedAt &&
          other.cloudAccountId == this.cloudAccountId);
}

class SelfNodesCompanion extends UpdateCompanion<SelfNodeRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> protocol;
  final Value<String> server;
  final Value<int> port;
  final Value<String> paramsJson;
  final Value<String> secretId;
  final Value<int> createdAt;
  final Value<int> editedAt;
  final Value<String?> cloudAccountId;
  final Value<int> rowid;
  const SelfNodesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.protocol = const Value.absent(),
    this.server = const Value.absent(),
    this.port = const Value.absent(),
    this.paramsJson = const Value.absent(),
    this.secretId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.cloudAccountId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SelfNodesCompanion.insert({
    required String id,
    required String name,
    required String protocol,
    required String server,
    required int port,
    required String paramsJson,
    required String secretId,
    required int createdAt,
    required int editedAt,
    this.cloudAccountId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       protocol = Value(protocol),
       server = Value(server),
       port = Value(port),
       paramsJson = Value(paramsJson),
       secretId = Value(secretId),
       createdAt = Value(createdAt),
       editedAt = Value(editedAt);
  static Insertable<SelfNodeRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? protocol,
    Expression<String>? server,
    Expression<int>? port,
    Expression<String>? paramsJson,
    Expression<String>? secretId,
    Expression<int>? createdAt,
    Expression<int>? editedAt,
    Expression<String>? cloudAccountId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (protocol != null) 'protocol': protocol,
      if (server != null) 'server': server,
      if (port != null) 'port': port,
      if (paramsJson != null) 'params_json': paramsJson,
      if (secretId != null) 'secret_id': secretId,
      if (createdAt != null) 'created_at': createdAt,
      if (editedAt != null) 'edited_at': editedAt,
      if (cloudAccountId != null) 'cloud_account_id': cloudAccountId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SelfNodesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? protocol,
    Value<String>? server,
    Value<int>? port,
    Value<String>? paramsJson,
    Value<String>? secretId,
    Value<int>? createdAt,
    Value<int>? editedAt,
    Value<String?>? cloudAccountId,
    Value<int>? rowid,
  }) {
    return SelfNodesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      protocol: protocol ?? this.protocol,
      server: server ?? this.server,
      port: port ?? this.port,
      paramsJson: paramsJson ?? this.paramsJson,
      secretId: secretId ?? this.secretId,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      cloudAccountId: cloudAccountId ?? this.cloudAccountId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (protocol.present) {
      map['protocol'] = Variable<String>(protocol.value);
    }
    if (server.present) {
      map['server'] = Variable<String>(server.value);
    }
    if (port.present) {
      map['port'] = Variable<int>(port.value);
    }
    if (paramsJson.present) {
      map['params_json'] = Variable<String>(paramsJson.value);
    }
    if (secretId.present) {
      map['secret_id'] = Variable<String>(secretId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (editedAt.present) {
      map['edited_at'] = Variable<int>(editedAt.value);
    }
    if (cloudAccountId.present) {
      map['cloud_account_id'] = Variable<String>(cloudAccountId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SelfNodesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('protocol: $protocol, ')
          ..write('server: $server, ')
          ..write('port: $port, ')
          ..write('paramsJson: $paramsJson, ')
          ..write('secretId: $secretId, ')
          ..write('createdAt: $createdAt, ')
          ..write('editedAt: $editedAt, ')
          ..write('cloudAccountId: $cloudAccountId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChainsTable extends Chains with TableInfo<$ChainsTable, ChainRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChainsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hopsJsonMeta = const VerificationMeta(
    'hopsJson',
  );
  @override
  late final GeneratedColumn<String> hopsJson = GeneratedColumn<String>(
    'hops_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _editedAtMeta = const VerificationMeta(
    'editedAt',
  );
  @override
  late final GeneratedColumn<int> editedAt = GeneratedColumn<int>(
    'edited_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cloudAccountIdMeta = const VerificationMeta(
    'cloudAccountId',
  );
  @override
  late final GeneratedColumn<String> cloudAccountId = GeneratedColumn<String>(
    'cloud_account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    hopsJson,
    createdAt,
    editedAt,
    cloudAccountId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'chains';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChainRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    }
    if (data.containsKey('hops_json')) {
      context.handle(
        _hopsJsonMeta,
        hopsJson.isAcceptableOrUnknown(data['hops_json']!, _hopsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_hopsJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('edited_at')) {
      context.handle(
        _editedAtMeta,
        editedAt.isAcceptableOrUnknown(data['edited_at']!, _editedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_editedAtMeta);
    }
    if (data.containsKey('cloud_account_id')) {
      context.handle(
        _cloudAccountIdMeta,
        cloudAccountId.isAcceptableOrUnknown(
          data['cloud_account_id']!,
          _cloudAccountIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ChainRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChainRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      ),
      hopsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}hops_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      editedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}edited_at'],
      )!,
      cloudAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cloud_account_id'],
      ),
    );
  }

  @override
  $ChainsTable createAlias(String alias) {
    return $ChainsTable(attachedDatabase, alias);
  }
}

class ChainRow extends DataClass implements Insertable<ChainRow> {
  final String id;
  final String? name;
  final String hopsJson;
  final int createdAt;
  final int editedAt;
  final String? cloudAccountId;
  const ChainRow({
    required this.id,
    this.name,
    required this.hopsJson,
    required this.createdAt,
    required this.editedAt,
    this.cloudAccountId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || name != null) {
      map['name'] = Variable<String>(name);
    }
    map['hops_json'] = Variable<String>(hopsJson);
    map['created_at'] = Variable<int>(createdAt);
    map['edited_at'] = Variable<int>(editedAt);
    if (!nullToAbsent || cloudAccountId != null) {
      map['cloud_account_id'] = Variable<String>(cloudAccountId);
    }
    return map;
  }

  ChainsCompanion toCompanion(bool nullToAbsent) {
    return ChainsCompanion(
      id: Value(id),
      name: name == null && nullToAbsent ? const Value.absent() : Value(name),
      hopsJson: Value(hopsJson),
      createdAt: Value(createdAt),
      editedAt: Value(editedAt),
      cloudAccountId: cloudAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudAccountId),
    );
  }

  factory ChainRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChainRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String?>(json['name']),
      hopsJson: serializer.fromJson<String>(json['hopsJson']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      editedAt: serializer.fromJson<int>(json['editedAt']),
      cloudAccountId: serializer.fromJson<String?>(json['cloudAccountId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String?>(name),
      'hopsJson': serializer.toJson<String>(hopsJson),
      'createdAt': serializer.toJson<int>(createdAt),
      'editedAt': serializer.toJson<int>(editedAt),
      'cloudAccountId': serializer.toJson<String?>(cloudAccountId),
    };
  }

  ChainRow copyWith({
    String? id,
    Value<String?> name = const Value.absent(),
    String? hopsJson,
    int? createdAt,
    int? editedAt,
    Value<String?> cloudAccountId = const Value.absent(),
  }) => ChainRow(
    id: id ?? this.id,
    name: name.present ? name.value : this.name,
    hopsJson: hopsJson ?? this.hopsJson,
    createdAt: createdAt ?? this.createdAt,
    editedAt: editedAt ?? this.editedAt,
    cloudAccountId: cloudAccountId.present
        ? cloudAccountId.value
        : this.cloudAccountId,
  );
  ChainRow copyWithCompanion(ChainsCompanion data) {
    return ChainRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      hopsJson: data.hopsJson.present ? data.hopsJson.value : this.hopsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      editedAt: data.editedAt.present ? data.editedAt.value : this.editedAt,
      cloudAccountId: data.cloudAccountId.present
          ? data.cloudAccountId.value
          : this.cloudAccountId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChainRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('hopsJson: $hopsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('editedAt: $editedAt, ')
          ..write('cloudAccountId: $cloudAccountId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, hopsJson, createdAt, editedAt, cloudAccountId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChainRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.hopsJson == this.hopsJson &&
          other.createdAt == this.createdAt &&
          other.editedAt == this.editedAt &&
          other.cloudAccountId == this.cloudAccountId);
}

class ChainsCompanion extends UpdateCompanion<ChainRow> {
  final Value<String> id;
  final Value<String?> name;
  final Value<String> hopsJson;
  final Value<int> createdAt;
  final Value<int> editedAt;
  final Value<String?> cloudAccountId;
  final Value<int> rowid;
  const ChainsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.hopsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.cloudAccountId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChainsCompanion.insert({
    required String id,
    this.name = const Value.absent(),
    required String hopsJson,
    required int createdAt,
    required int editedAt,
    this.cloudAccountId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       hopsJson = Value(hopsJson),
       createdAt = Value(createdAt),
       editedAt = Value(editedAt);
  static Insertable<ChainRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? hopsJson,
    Expression<int>? createdAt,
    Expression<int>? editedAt,
    Expression<String>? cloudAccountId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (hopsJson != null) 'hops_json': hopsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (editedAt != null) 'edited_at': editedAt,
      if (cloudAccountId != null) 'cloud_account_id': cloudAccountId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChainsCompanion copyWith({
    Value<String>? id,
    Value<String?>? name,
    Value<String>? hopsJson,
    Value<int>? createdAt,
    Value<int>? editedAt,
    Value<String?>? cloudAccountId,
    Value<int>? rowid,
  }) {
    return ChainsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      hopsJson: hopsJson ?? this.hopsJson,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      cloudAccountId: cloudAccountId ?? this.cloudAccountId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (hopsJson.present) {
      map['hops_json'] = Variable<String>(hopsJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (editedAt.present) {
      map['edited_at'] = Variable<int>(editedAt.value);
    }
    if (cloudAccountId.present) {
      map['cloud_account_id'] = Variable<String>(cloudAccountId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChainsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('hopsJson: $hopsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('editedAt: $editedAt, ')
          ..write('cloudAccountId: $cloudAccountId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MembershipsTable extends Memberships
    with TableInfo<$MembershipsTable, MembershipRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MembershipsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ownerKindMeta = const VerificationMeta(
    'ownerKind',
  );
  @override
  late final GeneratedColumn<String> ownerKind = GeneratedColumn<String>(
    'owner_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _configurationIdMeta = const VerificationMeta(
    'configurationId',
  );
  @override
  late final GeneratedColumn<String> configurationId = GeneratedColumn<String>(
    'configuration_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES configurations (id) ON UPDATE CASCADE ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _groupKeyMeta = const VerificationMeta(
    'groupKey',
  );
  @override
  late final GeneratedColumn<String> groupKey = GeneratedColumn<String>(
    'group_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    ownerKind,
    ownerId,
    configurationId,
    groupKey,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'memberships';
  @override
  VerificationContext validateIntegrity(
    Insertable<MembershipRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('owner_kind')) {
      context.handle(
        _ownerKindMeta,
        ownerKind.isAcceptableOrUnknown(data['owner_kind']!, _ownerKindMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerKindMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('configuration_id')) {
      context.handle(
        _configurationIdMeta,
        configurationId.isAcceptableOrUnknown(
          data['configuration_id']!,
          _configurationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_configurationIdMeta);
    }
    if (data.containsKey('group_key')) {
      context.handle(
        _groupKeyMeta,
        groupKey.isAcceptableOrUnknown(data['group_key']!, _groupKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_groupKeyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    ownerKind,
    ownerId,
    configurationId,
    groupKey,
  };
  @override
  MembershipRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MembershipRow(
      ownerKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_kind'],
      )!,
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      configurationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}configuration_id'],
      )!,
      groupKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_key'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MembershipsTable createAlias(String alias) {
    return $MembershipsTable(attachedDatabase, alias);
  }
}

class MembershipRow extends DataClass implements Insertable<MembershipRow> {
  /// `node` or `chain`.
  final String ownerKind;
  final String ownerId;
  final String configurationId;
  final String groupKey;
  final int createdAt;
  const MembershipRow({
    required this.ownerKind,
    required this.ownerId,
    required this.configurationId,
    required this.groupKey,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['owner_kind'] = Variable<String>(ownerKind);
    map['owner_id'] = Variable<String>(ownerId);
    map['configuration_id'] = Variable<String>(configurationId);
    map['group_key'] = Variable<String>(groupKey);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  MembershipsCompanion toCompanion(bool nullToAbsent) {
    return MembershipsCompanion(
      ownerKind: Value(ownerKind),
      ownerId: Value(ownerId),
      configurationId: Value(configurationId),
      groupKey: Value(groupKey),
      createdAt: Value(createdAt),
    );
  }

  factory MembershipRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MembershipRow(
      ownerKind: serializer.fromJson<String>(json['ownerKind']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      configurationId: serializer.fromJson<String>(json['configurationId']),
      groupKey: serializer.fromJson<String>(json['groupKey']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ownerKind': serializer.toJson<String>(ownerKind),
      'ownerId': serializer.toJson<String>(ownerId),
      'configurationId': serializer.toJson<String>(configurationId),
      'groupKey': serializer.toJson<String>(groupKey),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  MembershipRow copyWith({
    String? ownerKind,
    String? ownerId,
    String? configurationId,
    String? groupKey,
    int? createdAt,
  }) => MembershipRow(
    ownerKind: ownerKind ?? this.ownerKind,
    ownerId: ownerId ?? this.ownerId,
    configurationId: configurationId ?? this.configurationId,
    groupKey: groupKey ?? this.groupKey,
    createdAt: createdAt ?? this.createdAt,
  );
  MembershipRow copyWithCompanion(MembershipsCompanion data) {
    return MembershipRow(
      ownerKind: data.ownerKind.present ? data.ownerKind.value : this.ownerKind,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      configurationId: data.configurationId.present
          ? data.configurationId.value
          : this.configurationId,
      groupKey: data.groupKey.present ? data.groupKey.value : this.groupKey,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MembershipRow(')
          ..write('ownerKind: $ownerKind, ')
          ..write('ownerId: $ownerId, ')
          ..write('configurationId: $configurationId, ')
          ..write('groupKey: $groupKey, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(ownerKind, ownerId, configurationId, groupKey, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MembershipRow &&
          other.ownerKind == this.ownerKind &&
          other.ownerId == this.ownerId &&
          other.configurationId == this.configurationId &&
          other.groupKey == this.groupKey &&
          other.createdAt == this.createdAt);
}

class MembershipsCompanion extends UpdateCompanion<MembershipRow> {
  final Value<String> ownerKind;
  final Value<String> ownerId;
  final Value<String> configurationId;
  final Value<String> groupKey;
  final Value<int> createdAt;
  final Value<int> rowid;
  const MembershipsCompanion({
    this.ownerKind = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.configurationId = const Value.absent(),
    this.groupKey = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MembershipsCompanion.insert({
    required String ownerKind,
    required String ownerId,
    required String configurationId,
    required String groupKey,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : ownerKind = Value(ownerKind),
       ownerId = Value(ownerId),
       configurationId = Value(configurationId),
       groupKey = Value(groupKey),
       createdAt = Value(createdAt);
  static Insertable<MembershipRow> custom({
    Expression<String>? ownerKind,
    Expression<String>? ownerId,
    Expression<String>? configurationId,
    Expression<String>? groupKey,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ownerKind != null) 'owner_kind': ownerKind,
      if (ownerId != null) 'owner_id': ownerId,
      if (configurationId != null) 'configuration_id': configurationId,
      if (groupKey != null) 'group_key': groupKey,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MembershipsCompanion copyWith({
    Value<String>? ownerKind,
    Value<String>? ownerId,
    Value<String>? configurationId,
    Value<String>? groupKey,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return MembershipsCompanion(
      ownerKind: ownerKind ?? this.ownerKind,
      ownerId: ownerId ?? this.ownerId,
      configurationId: configurationId ?? this.configurationId,
      groupKey: groupKey ?? this.groupKey,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ownerKind.present) {
      map['owner_kind'] = Variable<String>(ownerKind.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (configurationId.present) {
      map['configuration_id'] = Variable<String>(configurationId.value);
    }
    if (groupKey.present) {
      map['group_key'] = Variable<String>(groupKey.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MembershipsCompanion(')
          ..write('ownerKind: $ownerKind, ')
          ..write('ownerId: $ownerId, ')
          ..write('configurationId: $configurationId, ')
          ..write('groupKey: $groupKey, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SelectionsTable extends Selections
    with TableInfo<$SelectionsTable, SelectionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SelectionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _configurationIdMeta = const VerificationMeta(
    'configurationId',
  );
  @override
  late final GeneratedColumn<String> configurationId = GeneratedColumn<String>(
    'configuration_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES configurations (id) ON UPDATE CASCADE ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _groupKeyMeta = const VerificationMeta(
    'groupKey',
  );
  @override
  late final GeneratedColumn<String> groupKey = GeneratedColumn<String>(
    'group_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _memberJsonMeta = const VerificationMeta(
    'memberJson',
  );
  @override
  late final GeneratedColumn<String> memberJson = GeneratedColumn<String>(
    'member_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _manualMeta = const VerificationMeta('manual');
  @override
  late final GeneratedColumn<bool> manual = GeneratedColumn<bool>(
    'manual',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("manual" IN (0, 1))',
    ),
  );
  static const VerificationMeta _editedAtMeta = const VerificationMeta(
    'editedAt',
  );
  @override
  late final GeneratedColumn<int> editedAt = GeneratedColumn<int>(
    'edited_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cloudAccountIdMeta = const VerificationMeta(
    'cloudAccountId',
  );
  @override
  late final GeneratedColumn<String> cloudAccountId = GeneratedColumn<String>(
    'cloud_account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    configurationId,
    groupKey,
    memberJson,
    manual,
    editedAt,
    cloudAccountId,
    documentId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'selections';
  @override
  VerificationContext validateIntegrity(
    Insertable<SelectionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('configuration_id')) {
      context.handle(
        _configurationIdMeta,
        configurationId.isAcceptableOrUnknown(
          data['configuration_id']!,
          _configurationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_configurationIdMeta);
    }
    if (data.containsKey('group_key')) {
      context.handle(
        _groupKeyMeta,
        groupKey.isAcceptableOrUnknown(data['group_key']!, _groupKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_groupKeyMeta);
    }
    if (data.containsKey('member_json')) {
      context.handle(
        _memberJsonMeta,
        memberJson.isAcceptableOrUnknown(data['member_json']!, _memberJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_memberJsonMeta);
    }
    if (data.containsKey('manual')) {
      context.handle(
        _manualMeta,
        manual.isAcceptableOrUnknown(data['manual']!, _manualMeta),
      );
    } else if (isInserting) {
      context.missing(_manualMeta);
    }
    if (data.containsKey('edited_at')) {
      context.handle(
        _editedAtMeta,
        editedAt.isAcceptableOrUnknown(data['edited_at']!, _editedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_editedAtMeta);
    }
    if (data.containsKey('cloud_account_id')) {
      context.handle(
        _cloudAccountIdMeta,
        cloudAccountId.isAcceptableOrUnknown(
          data['cloud_account_id']!,
          _cloudAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {configurationId, groupKey};
  @override
  SelectionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SelectionRow(
      configurationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}configuration_id'],
      )!,
      groupKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_key'],
      )!,
      memberJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}member_json'],
      )!,
      manual: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}manual'],
      )!,
      editedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}edited_at'],
      )!,
      cloudAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cloud_account_id'],
      ),
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      ),
    );
  }

  @override
  $SelectionsTable createAlias(String alias) {
    return $SelectionsTable(attachedDatabase, alias);
  }
}

class SelectionRow extends DataClass implements Insertable<SelectionRow> {
  final String configurationId;
  final String groupKey;
  final String memberJson;

  /// Only manual choices are synced (DATA_MODEL §1.2).
  final bool manual;
  final int editedAt;
  final String? cloudAccountId;
  final String? documentId;
  const SelectionRow({
    required this.configurationId,
    required this.groupKey,
    required this.memberJson,
    required this.manual,
    required this.editedAt,
    this.cloudAccountId,
    this.documentId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['configuration_id'] = Variable<String>(configurationId);
    map['group_key'] = Variable<String>(groupKey);
    map['member_json'] = Variable<String>(memberJson);
    map['manual'] = Variable<bool>(manual);
    map['edited_at'] = Variable<int>(editedAt);
    if (!nullToAbsent || cloudAccountId != null) {
      map['cloud_account_id'] = Variable<String>(cloudAccountId);
    }
    if (!nullToAbsent || documentId != null) {
      map['document_id'] = Variable<String>(documentId);
    }
    return map;
  }

  SelectionsCompanion toCompanion(bool nullToAbsent) {
    return SelectionsCompanion(
      configurationId: Value(configurationId),
      groupKey: Value(groupKey),
      memberJson: Value(memberJson),
      manual: Value(manual),
      editedAt: Value(editedAt),
      cloudAccountId: cloudAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudAccountId),
      documentId: documentId == null && nullToAbsent
          ? const Value.absent()
          : Value(documentId),
    );
  }

  factory SelectionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SelectionRow(
      configurationId: serializer.fromJson<String>(json['configurationId']),
      groupKey: serializer.fromJson<String>(json['groupKey']),
      memberJson: serializer.fromJson<String>(json['memberJson']),
      manual: serializer.fromJson<bool>(json['manual']),
      editedAt: serializer.fromJson<int>(json['editedAt']),
      cloudAccountId: serializer.fromJson<String?>(json['cloudAccountId']),
      documentId: serializer.fromJson<String?>(json['documentId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'configurationId': serializer.toJson<String>(configurationId),
      'groupKey': serializer.toJson<String>(groupKey),
      'memberJson': serializer.toJson<String>(memberJson),
      'manual': serializer.toJson<bool>(manual),
      'editedAt': serializer.toJson<int>(editedAt),
      'cloudAccountId': serializer.toJson<String?>(cloudAccountId),
      'documentId': serializer.toJson<String?>(documentId),
    };
  }

  SelectionRow copyWith({
    String? configurationId,
    String? groupKey,
    String? memberJson,
    bool? manual,
    int? editedAt,
    Value<String?> cloudAccountId = const Value.absent(),
    Value<String?> documentId = const Value.absent(),
  }) => SelectionRow(
    configurationId: configurationId ?? this.configurationId,
    groupKey: groupKey ?? this.groupKey,
    memberJson: memberJson ?? this.memberJson,
    manual: manual ?? this.manual,
    editedAt: editedAt ?? this.editedAt,
    cloudAccountId: cloudAccountId.present
        ? cloudAccountId.value
        : this.cloudAccountId,
    documentId: documentId.present ? documentId.value : this.documentId,
  );
  SelectionRow copyWithCompanion(SelectionsCompanion data) {
    return SelectionRow(
      configurationId: data.configurationId.present
          ? data.configurationId.value
          : this.configurationId,
      groupKey: data.groupKey.present ? data.groupKey.value : this.groupKey,
      memberJson: data.memberJson.present
          ? data.memberJson.value
          : this.memberJson,
      manual: data.manual.present ? data.manual.value : this.manual,
      editedAt: data.editedAt.present ? data.editedAt.value : this.editedAt,
      cloudAccountId: data.cloudAccountId.present
          ? data.cloudAccountId.value
          : this.cloudAccountId,
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SelectionRow(')
          ..write('configurationId: $configurationId, ')
          ..write('groupKey: $groupKey, ')
          ..write('memberJson: $memberJson, ')
          ..write('manual: $manual, ')
          ..write('editedAt: $editedAt, ')
          ..write('cloudAccountId: $cloudAccountId, ')
          ..write('documentId: $documentId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    configurationId,
    groupKey,
    memberJson,
    manual,
    editedAt,
    cloudAccountId,
    documentId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SelectionRow &&
          other.configurationId == this.configurationId &&
          other.groupKey == this.groupKey &&
          other.memberJson == this.memberJson &&
          other.manual == this.manual &&
          other.editedAt == this.editedAt &&
          other.cloudAccountId == this.cloudAccountId &&
          other.documentId == this.documentId);
}

class SelectionsCompanion extends UpdateCompanion<SelectionRow> {
  final Value<String> configurationId;
  final Value<String> groupKey;
  final Value<String> memberJson;
  final Value<bool> manual;
  final Value<int> editedAt;
  final Value<String?> cloudAccountId;
  final Value<String?> documentId;
  final Value<int> rowid;
  const SelectionsCompanion({
    this.configurationId = const Value.absent(),
    this.groupKey = const Value.absent(),
    this.memberJson = const Value.absent(),
    this.manual = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.cloudAccountId = const Value.absent(),
    this.documentId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SelectionsCompanion.insert({
    required String configurationId,
    required String groupKey,
    required String memberJson,
    required bool manual,
    required int editedAt,
    this.cloudAccountId = const Value.absent(),
    this.documentId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : configurationId = Value(configurationId),
       groupKey = Value(groupKey),
       memberJson = Value(memberJson),
       manual = Value(manual),
       editedAt = Value(editedAt);
  static Insertable<SelectionRow> custom({
    Expression<String>? configurationId,
    Expression<String>? groupKey,
    Expression<String>? memberJson,
    Expression<bool>? manual,
    Expression<int>? editedAt,
    Expression<String>? cloudAccountId,
    Expression<String>? documentId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (configurationId != null) 'configuration_id': configurationId,
      if (groupKey != null) 'group_key': groupKey,
      if (memberJson != null) 'member_json': memberJson,
      if (manual != null) 'manual': manual,
      if (editedAt != null) 'edited_at': editedAt,
      if (cloudAccountId != null) 'cloud_account_id': cloudAccountId,
      if (documentId != null) 'document_id': documentId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SelectionsCompanion copyWith({
    Value<String>? configurationId,
    Value<String>? groupKey,
    Value<String>? memberJson,
    Value<bool>? manual,
    Value<int>? editedAt,
    Value<String?>? cloudAccountId,
    Value<String?>? documentId,
    Value<int>? rowid,
  }) {
    return SelectionsCompanion(
      configurationId: configurationId ?? this.configurationId,
      groupKey: groupKey ?? this.groupKey,
      memberJson: memberJson ?? this.memberJson,
      manual: manual ?? this.manual,
      editedAt: editedAt ?? this.editedAt,
      cloudAccountId: cloudAccountId ?? this.cloudAccountId,
      documentId: documentId ?? this.documentId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (configurationId.present) {
      map['configuration_id'] = Variable<String>(configurationId.value);
    }
    if (groupKey.present) {
      map['group_key'] = Variable<String>(groupKey.value);
    }
    if (memberJson.present) {
      map['member_json'] = Variable<String>(memberJson.value);
    }
    if (manual.present) {
      map['manual'] = Variable<bool>(manual.value);
    }
    if (editedAt.present) {
      map['edited_at'] = Variable<int>(editedAt.value);
    }
    if (cloudAccountId.present) {
      map['cloud_account_id'] = Variable<String>(cloudAccountId.value);
    }
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SelectionsCompanion(')
          ..write('configurationId: $configurationId, ')
          ..write('groupKey: $groupKey, ')
          ..write('memberJson: $memberJson, ')
          ..write('manual: $manual, ')
          ..write('editedAt: $editedAt, ')
          ..write('cloudAccountId: $cloudAccountId, ')
          ..write('documentId: $documentId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeviceSettingsTableTable extends DeviceSettingsTable
    with TableInfo<$DeviceSettingsTableTable, DeviceSettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeviceSettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _secretIdMeta = const VerificationMeta(
    'secretId',
  );
  @override
  late final GeneratedColumn<String> secretId = GeneratedColumn<String>(
    'secret_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _editedAtMeta = const VerificationMeta(
    'editedAt',
  );
  @override
  late final GeneratedColumn<int> editedAt = GeneratedColumn<int>(
    'edited_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, json, secretId, editedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'device_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeviceSettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('json')) {
      context.handle(
        _jsonMeta,
        json.isAcceptableOrUnknown(data['json']!, _jsonMeta),
      );
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('secret_id')) {
      context.handle(
        _secretIdMeta,
        secretId.isAcceptableOrUnknown(data['secret_id']!, _secretIdMeta),
      );
    }
    if (data.containsKey('edited_at')) {
      context.handle(
        _editedAtMeta,
        editedAt.isAcceptableOrUnknown(data['edited_at']!, _editedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_editedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DeviceSettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeviceSettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      json: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}json'],
      )!,
      secretId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}secret_id'],
      ),
      editedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}edited_at'],
      )!,
    );
  }

  @override
  $DeviceSettingsTableTable createAlias(String alias) {
    return $DeviceSettingsTableTable(attachedDatabase, alias);
  }
}

class DeviceSettingsRow extends DataClass
    implements Insertable<DeviceSettingsRow> {
  final int id;
  final String json;

  /// Secrets inside the settings (the Clash API key).
  final String? secretId;
  final int editedAt;
  const DeviceSettingsRow({
    required this.id,
    required this.json,
    this.secretId,
    required this.editedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['json'] = Variable<String>(json);
    if (!nullToAbsent || secretId != null) {
      map['secret_id'] = Variable<String>(secretId);
    }
    map['edited_at'] = Variable<int>(editedAt);
    return map;
  }

  DeviceSettingsTableCompanion toCompanion(bool nullToAbsent) {
    return DeviceSettingsTableCompanion(
      id: Value(id),
      json: Value(json),
      secretId: secretId == null && nullToAbsent
          ? const Value.absent()
          : Value(secretId),
      editedAt: Value(editedAt),
    );
  }

  factory DeviceSettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeviceSettingsRow(
      id: serializer.fromJson<int>(json['id']),
      json: serializer.fromJson<String>(json['json']),
      secretId: serializer.fromJson<String?>(json['secretId']),
      editedAt: serializer.fromJson<int>(json['editedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'json': serializer.toJson<String>(json),
      'secretId': serializer.toJson<String?>(secretId),
      'editedAt': serializer.toJson<int>(editedAt),
    };
  }

  DeviceSettingsRow copyWith({
    int? id,
    String? json,
    Value<String?> secretId = const Value.absent(),
    int? editedAt,
  }) => DeviceSettingsRow(
    id: id ?? this.id,
    json: json ?? this.json,
    secretId: secretId.present ? secretId.value : this.secretId,
    editedAt: editedAt ?? this.editedAt,
  );
  DeviceSettingsRow copyWithCompanion(DeviceSettingsTableCompanion data) {
    return DeviceSettingsRow(
      id: data.id.present ? data.id.value : this.id,
      json: data.json.present ? data.json.value : this.json,
      secretId: data.secretId.present ? data.secretId.value : this.secretId,
      editedAt: data.editedAt.present ? data.editedAt.value : this.editedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeviceSettingsRow(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('secretId: $secretId, ')
          ..write('editedAt: $editedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, json, secretId, editedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeviceSettingsRow &&
          other.id == this.id &&
          other.json == this.json &&
          other.secretId == this.secretId &&
          other.editedAt == this.editedAt);
}

class DeviceSettingsTableCompanion extends UpdateCompanion<DeviceSettingsRow> {
  final Value<int> id;
  final Value<String> json;
  final Value<String?> secretId;
  final Value<int> editedAt;
  const DeviceSettingsTableCompanion({
    this.id = const Value.absent(),
    this.json = const Value.absent(),
    this.secretId = const Value.absent(),
    this.editedAt = const Value.absent(),
  });
  DeviceSettingsTableCompanion.insert({
    this.id = const Value.absent(),
    required String json,
    this.secretId = const Value.absent(),
    required int editedAt,
  }) : json = Value(json),
       editedAt = Value(editedAt);
  static Insertable<DeviceSettingsRow> custom({
    Expression<int>? id,
    Expression<String>? json,
    Expression<String>? secretId,
    Expression<int>? editedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (json != null) 'json': json,
      if (secretId != null) 'secret_id': secretId,
      if (editedAt != null) 'edited_at': editedAt,
    });
  }

  DeviceSettingsTableCompanion copyWith({
    Value<int>? id,
    Value<String>? json,
    Value<String?>? secretId,
    Value<int>? editedAt,
  }) {
    return DeviceSettingsTableCompanion(
      id: id ?? this.id,
      json: json ?? this.json,
      secretId: secretId ?? this.secretId,
      editedAt: editedAt ?? this.editedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (secretId.present) {
      map['secret_id'] = Variable<String>(secretId.value);
    }
    if (editedAt.present) {
      map['edited_at'] = Variable<int>(editedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeviceSettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('json: $json, ')
          ..write('secretId: $secretId, ')
          ..write('editedAt: $editedAt')
          ..write(')'))
        .toString();
  }
}

class $PolicyTableTable extends PolicyTable
    with TableInfo<$PolicyTableTable, PolicyRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PolicyTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overrideSecretIdMeta = const VerificationMeta(
    'overrideSecretId',
  );
  @override
  late final GeneratedColumn<String> overrideSecretId = GeneratedColumn<String>(
    'override_secret_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _geoAutoUpdateMeta = const VerificationMeta(
    'geoAutoUpdate',
  );
  @override
  late final GeneratedColumn<bool> geoAutoUpdate = GeneratedColumn<bool>(
    'geo_auto_update',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("geo_auto_update" IN (0, 1))',
    ),
  );
  static const VerificationMeta _geoIntervalMeta = const VerificationMeta(
    'geoInterval',
  );
  @override
  late final GeneratedColumn<String> geoInterval = GeneratedColumn<String>(
    'geo_interval',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _geoViaMeta = const VerificationMeta('geoVia');
  @override
  late final GeneratedColumn<String> geoVia = GeneratedColumn<String>(
    'geo_via',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _editedAtMeta = const VerificationMeta(
    'editedAt',
  );
  @override
  late final GeneratedColumn<int> editedAt = GeneratedColumn<int>(
    'edited_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _cloudAccountIdMeta = const VerificationMeta(
    'cloudAccountId',
  );
  @override
  late final GeneratedColumn<String> cloudAccountId = GeneratedColumn<String>(
    'cloud_account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    overrideSecretId,
    geoAutoUpdate,
    geoInterval,
    geoVia,
    editedAt,
    cloudAccountId,
    documentId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'policy';
  @override
  VerificationContext validateIntegrity(
    Insertable<PolicyRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('override_secret_id')) {
      context.handle(
        _overrideSecretIdMeta,
        overrideSecretId.isAcceptableOrUnknown(
          data['override_secret_id']!,
          _overrideSecretIdMeta,
        ),
      );
    }
    if (data.containsKey('geo_auto_update')) {
      context.handle(
        _geoAutoUpdateMeta,
        geoAutoUpdate.isAcceptableOrUnknown(
          data['geo_auto_update']!,
          _geoAutoUpdateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_geoAutoUpdateMeta);
    }
    if (data.containsKey('geo_interval')) {
      context.handle(
        _geoIntervalMeta,
        geoInterval.isAcceptableOrUnknown(
          data['geo_interval']!,
          _geoIntervalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_geoIntervalMeta);
    }
    if (data.containsKey('geo_via')) {
      context.handle(
        _geoViaMeta,
        geoVia.isAcceptableOrUnknown(data['geo_via']!, _geoViaMeta),
      );
    } else if (isInserting) {
      context.missing(_geoViaMeta);
    }
    if (data.containsKey('edited_at')) {
      context.handle(
        _editedAtMeta,
        editedAt.isAcceptableOrUnknown(data['edited_at']!, _editedAtMeta),
      );
    }
    if (data.containsKey('cloud_account_id')) {
      context.handle(
        _cloudAccountIdMeta,
        cloudAccountId.isAcceptableOrUnknown(
          data['cloud_account_id']!,
          _cloudAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PolicyRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PolicyRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      overrideSecretId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}override_secret_id'],
      ),
      geoAutoUpdate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}geo_auto_update'],
      )!,
      geoInterval: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}geo_interval'],
      )!,
      geoVia: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}geo_via'],
      )!,
      editedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}edited_at'],
      ),
      cloudAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cloud_account_id'],
      ),
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      ),
    );
  }

  @override
  $PolicyTableTable createAlias(String alias) {
    return $PolicyTableTable(attachedDatabase, alias);
  }
}

class PolicyRow extends DataClass implements Insertable<PolicyRow> {
  final int id;
  final String? overrideSecretId;
  final bool geoAutoUpdate;
  final String geoInterval;
  final String geoVia;

  /// Null: never edited, so not uploaded (DATA_MODEL §1.2).
  final int? editedAt;
  final String? cloudAccountId;
  final String? documentId;
  const PolicyRow({
    required this.id,
    this.overrideSecretId,
    required this.geoAutoUpdate,
    required this.geoInterval,
    required this.geoVia,
    this.editedAt,
    this.cloudAccountId,
    this.documentId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || overrideSecretId != null) {
      map['override_secret_id'] = Variable<String>(overrideSecretId);
    }
    map['geo_auto_update'] = Variable<bool>(geoAutoUpdate);
    map['geo_interval'] = Variable<String>(geoInterval);
    map['geo_via'] = Variable<String>(geoVia);
    if (!nullToAbsent || editedAt != null) {
      map['edited_at'] = Variable<int>(editedAt);
    }
    if (!nullToAbsent || cloudAccountId != null) {
      map['cloud_account_id'] = Variable<String>(cloudAccountId);
    }
    if (!nullToAbsent || documentId != null) {
      map['document_id'] = Variable<String>(documentId);
    }
    return map;
  }

  PolicyTableCompanion toCompanion(bool nullToAbsent) {
    return PolicyTableCompanion(
      id: Value(id),
      overrideSecretId: overrideSecretId == null && nullToAbsent
          ? const Value.absent()
          : Value(overrideSecretId),
      geoAutoUpdate: Value(geoAutoUpdate),
      geoInterval: Value(geoInterval),
      geoVia: Value(geoVia),
      editedAt: editedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(editedAt),
      cloudAccountId: cloudAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(cloudAccountId),
      documentId: documentId == null && nullToAbsent
          ? const Value.absent()
          : Value(documentId),
    );
  }

  factory PolicyRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PolicyRow(
      id: serializer.fromJson<int>(json['id']),
      overrideSecretId: serializer.fromJson<String?>(json['overrideSecretId']),
      geoAutoUpdate: serializer.fromJson<bool>(json['geoAutoUpdate']),
      geoInterval: serializer.fromJson<String>(json['geoInterval']),
      geoVia: serializer.fromJson<String>(json['geoVia']),
      editedAt: serializer.fromJson<int?>(json['editedAt']),
      cloudAccountId: serializer.fromJson<String?>(json['cloudAccountId']),
      documentId: serializer.fromJson<String?>(json['documentId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'overrideSecretId': serializer.toJson<String?>(overrideSecretId),
      'geoAutoUpdate': serializer.toJson<bool>(geoAutoUpdate),
      'geoInterval': serializer.toJson<String>(geoInterval),
      'geoVia': serializer.toJson<String>(geoVia),
      'editedAt': serializer.toJson<int?>(editedAt),
      'cloudAccountId': serializer.toJson<String?>(cloudAccountId),
      'documentId': serializer.toJson<String?>(documentId),
    };
  }

  PolicyRow copyWith({
    int? id,
    Value<String?> overrideSecretId = const Value.absent(),
    bool? geoAutoUpdate,
    String? geoInterval,
    String? geoVia,
    Value<int?> editedAt = const Value.absent(),
    Value<String?> cloudAccountId = const Value.absent(),
    Value<String?> documentId = const Value.absent(),
  }) => PolicyRow(
    id: id ?? this.id,
    overrideSecretId: overrideSecretId.present
        ? overrideSecretId.value
        : this.overrideSecretId,
    geoAutoUpdate: geoAutoUpdate ?? this.geoAutoUpdate,
    geoInterval: geoInterval ?? this.geoInterval,
    geoVia: geoVia ?? this.geoVia,
    editedAt: editedAt.present ? editedAt.value : this.editedAt,
    cloudAccountId: cloudAccountId.present
        ? cloudAccountId.value
        : this.cloudAccountId,
    documentId: documentId.present ? documentId.value : this.documentId,
  );
  PolicyRow copyWithCompanion(PolicyTableCompanion data) {
    return PolicyRow(
      id: data.id.present ? data.id.value : this.id,
      overrideSecretId: data.overrideSecretId.present
          ? data.overrideSecretId.value
          : this.overrideSecretId,
      geoAutoUpdate: data.geoAutoUpdate.present
          ? data.geoAutoUpdate.value
          : this.geoAutoUpdate,
      geoInterval: data.geoInterval.present
          ? data.geoInterval.value
          : this.geoInterval,
      geoVia: data.geoVia.present ? data.geoVia.value : this.geoVia,
      editedAt: data.editedAt.present ? data.editedAt.value : this.editedAt,
      cloudAccountId: data.cloudAccountId.present
          ? data.cloudAccountId.value
          : this.cloudAccountId,
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PolicyRow(')
          ..write('id: $id, ')
          ..write('overrideSecretId: $overrideSecretId, ')
          ..write('geoAutoUpdate: $geoAutoUpdate, ')
          ..write('geoInterval: $geoInterval, ')
          ..write('geoVia: $geoVia, ')
          ..write('editedAt: $editedAt, ')
          ..write('cloudAccountId: $cloudAccountId, ')
          ..write('documentId: $documentId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    overrideSecretId,
    geoAutoUpdate,
    geoInterval,
    geoVia,
    editedAt,
    cloudAccountId,
    documentId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PolicyRow &&
          other.id == this.id &&
          other.overrideSecretId == this.overrideSecretId &&
          other.geoAutoUpdate == this.geoAutoUpdate &&
          other.geoInterval == this.geoInterval &&
          other.geoVia == this.geoVia &&
          other.editedAt == this.editedAt &&
          other.cloudAccountId == this.cloudAccountId &&
          other.documentId == this.documentId);
}

class PolicyTableCompanion extends UpdateCompanion<PolicyRow> {
  final Value<int> id;
  final Value<String?> overrideSecretId;
  final Value<bool> geoAutoUpdate;
  final Value<String> geoInterval;
  final Value<String> geoVia;
  final Value<int?> editedAt;
  final Value<String?> cloudAccountId;
  final Value<String?> documentId;
  const PolicyTableCompanion({
    this.id = const Value.absent(),
    this.overrideSecretId = const Value.absent(),
    this.geoAutoUpdate = const Value.absent(),
    this.geoInterval = const Value.absent(),
    this.geoVia = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.cloudAccountId = const Value.absent(),
    this.documentId = const Value.absent(),
  });
  PolicyTableCompanion.insert({
    this.id = const Value.absent(),
    this.overrideSecretId = const Value.absent(),
    required bool geoAutoUpdate,
    required String geoInterval,
    required String geoVia,
    this.editedAt = const Value.absent(),
    this.cloudAccountId = const Value.absent(),
    this.documentId = const Value.absent(),
  }) : geoAutoUpdate = Value(geoAutoUpdate),
       geoInterval = Value(geoInterval),
       geoVia = Value(geoVia);
  static Insertable<PolicyRow> custom({
    Expression<int>? id,
    Expression<String>? overrideSecretId,
    Expression<bool>? geoAutoUpdate,
    Expression<String>? geoInterval,
    Expression<String>? geoVia,
    Expression<int>? editedAt,
    Expression<String>? cloudAccountId,
    Expression<String>? documentId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (overrideSecretId != null) 'override_secret_id': overrideSecretId,
      if (geoAutoUpdate != null) 'geo_auto_update': geoAutoUpdate,
      if (geoInterval != null) 'geo_interval': geoInterval,
      if (geoVia != null) 'geo_via': geoVia,
      if (editedAt != null) 'edited_at': editedAt,
      if (cloudAccountId != null) 'cloud_account_id': cloudAccountId,
      if (documentId != null) 'document_id': documentId,
    });
  }

  PolicyTableCompanion copyWith({
    Value<int>? id,
    Value<String?>? overrideSecretId,
    Value<bool>? geoAutoUpdate,
    Value<String>? geoInterval,
    Value<String>? geoVia,
    Value<int?>? editedAt,
    Value<String?>? cloudAccountId,
    Value<String?>? documentId,
  }) {
    return PolicyTableCompanion(
      id: id ?? this.id,
      overrideSecretId: overrideSecretId ?? this.overrideSecretId,
      geoAutoUpdate: geoAutoUpdate ?? this.geoAutoUpdate,
      geoInterval: geoInterval ?? this.geoInterval,
      geoVia: geoVia ?? this.geoVia,
      editedAt: editedAt ?? this.editedAt,
      cloudAccountId: cloudAccountId ?? this.cloudAccountId,
      documentId: documentId ?? this.documentId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (overrideSecretId.present) {
      map['override_secret_id'] = Variable<String>(overrideSecretId.value);
    }
    if (geoAutoUpdate.present) {
      map['geo_auto_update'] = Variable<bool>(geoAutoUpdate.value);
    }
    if (geoInterval.present) {
      map['geo_interval'] = Variable<String>(geoInterval.value);
    }
    if (geoVia.present) {
      map['geo_via'] = Variable<String>(geoVia.value);
    }
    if (editedAt.present) {
      map['edited_at'] = Variable<int>(editedAt.value);
    }
    if (cloudAccountId.present) {
      map['cloud_account_id'] = Variable<String>(cloudAccountId.value);
    }
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PolicyTableCompanion(')
          ..write('id: $id, ')
          ..write('overrideSecretId: $overrideSecretId, ')
          ..write('geoAutoUpdate: $geoAutoUpdate, ')
          ..write('geoInterval: $geoInterval, ')
          ..write('geoVia: $geoVia, ')
          ..write('editedAt: $editedAt, ')
          ..write('cloudAccountId: $cloudAccountId, ')
          ..write('documentId: $documentId')
          ..write(')'))
        .toString();
  }
}

class $RuleResourcesTable extends RuleResources
    with TableInfo<$RuleResourcesTable, RuleResourceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RuleResourcesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _urlMeta = const VerificationMeta('url');
  @override
  late final GeneratedColumn<String> url = GeneratedColumn<String>(
    'url',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  @override
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileMeta = const VerificationMeta('file');
  @override
  late final GeneratedColumn<String> file = GeneratedColumn<String>(
    'file',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sha256Meta = const VerificationMeta('sha256');
  @override
  late final GeneratedColumn<String> sha256 = GeneratedColumn<String>(
    'sha256',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sizeMeta = const VerificationMeta('size');
  @override
  late final GeneratedColumn<int> size = GeneratedColumn<int>(
    'size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _checkedAtMeta = const VerificationMeta(
    'checkedAt',
  );
  @override
  late final GeneratedColumn<int> checkedAt = GeneratedColumn<int>(
    'checked_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _skippedMeta = const VerificationMeta(
    'skipped',
  );
  @override
  late final GeneratedColumn<int> skipped = GeneratedColumn<int>(
    'skipped',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    url,
    format,
    file,
    sha256,
    size,
    updatedAt,
    checkedAt,
    lastError,
    skipped,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'rule_resources';
  @override
  VerificationContext validateIntegrity(
    Insertable<RuleResourceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('url')) {
      context.handle(
        _urlMeta,
        url.isAcceptableOrUnknown(data['url']!, _urlMeta),
      );
    } else if (isInserting) {
      context.missing(_urlMeta);
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    } else if (isInserting) {
      context.missing(_formatMeta);
    }
    if (data.containsKey('file')) {
      context.handle(
        _fileMeta,
        file.isAcceptableOrUnknown(data['file']!, _fileMeta),
      );
    }
    if (data.containsKey('sha256')) {
      context.handle(
        _sha256Meta,
        sha256.isAcceptableOrUnknown(data['sha256']!, _sha256Meta),
      );
    }
    if (data.containsKey('size')) {
      context.handle(
        _sizeMeta,
        size.isAcceptableOrUnknown(data['size']!, _sizeMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('checked_at')) {
      context.handle(
        _checkedAtMeta,
        checkedAt.isAcceptableOrUnknown(data['checked_at']!, _checkedAtMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('skipped')) {
      context.handle(
        _skippedMeta,
        skipped.isAcceptableOrUnknown(data['skipped']!, _skippedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {url, format};
  @override
  RuleResourceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RuleResourceRow(
      url: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}url'],
      )!,
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      )!,
      file: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file'],
      ),
      sha256: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256'],
      ),
      size: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}size'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
      checkedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}checked_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      skipped: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}skipped'],
      )!,
    );
  }

  @override
  $RuleResourcesTable createAlias(String alias) {
    return $RuleResourcesTable(attachedDatabase, alias);
  }
}

class RuleResourceRow extends DataClass implements Insertable<RuleResourceRow> {
  final String url;

  /// A `RuleSetFormat` name.
  final String format;

  /// The file under the host's `rulesets/` directory, named after its
  /// SHA-256; null until downloaded.
  final String? file;
  final String? sha256;
  final int? size;

  /// When the file was last replaced (milliseconds, UTC).
  final int? updatedAt;

  /// When a download was last attempted, successful or not.
  final int? checkedAt;

  /// The last attempt's error code; null when it succeeded.
  final String? lastError;

  /// Lines of a Clash provider that sing-box cannot express.
  final int skipped;
  const RuleResourceRow({
    required this.url,
    required this.format,
    this.file,
    this.sha256,
    this.size,
    this.updatedAt,
    this.checkedAt,
    this.lastError,
    required this.skipped,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['url'] = Variable<String>(url);
    map['format'] = Variable<String>(format);
    if (!nullToAbsent || file != null) {
      map['file'] = Variable<String>(file);
    }
    if (!nullToAbsent || sha256 != null) {
      map['sha256'] = Variable<String>(sha256);
    }
    if (!nullToAbsent || size != null) {
      map['size'] = Variable<int>(size);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    if (!nullToAbsent || checkedAt != null) {
      map['checked_at'] = Variable<int>(checkedAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['skipped'] = Variable<int>(skipped);
    return map;
  }

  RuleResourcesCompanion toCompanion(bool nullToAbsent) {
    return RuleResourcesCompanion(
      url: Value(url),
      format: Value(format),
      file: file == null && nullToAbsent ? const Value.absent() : Value(file),
      sha256: sha256 == null && nullToAbsent
          ? const Value.absent()
          : Value(sha256),
      size: size == null && nullToAbsent ? const Value.absent() : Value(size),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      checkedAt: checkedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(checkedAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      skipped: Value(skipped),
    );
  }

  factory RuleResourceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RuleResourceRow(
      url: serializer.fromJson<String>(json['url']),
      format: serializer.fromJson<String>(json['format']),
      file: serializer.fromJson<String?>(json['file']),
      sha256: serializer.fromJson<String?>(json['sha256']),
      size: serializer.fromJson<int?>(json['size']),
      updatedAt: serializer.fromJson<int?>(json['updatedAt']),
      checkedAt: serializer.fromJson<int?>(json['checkedAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      skipped: serializer.fromJson<int>(json['skipped']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'url': serializer.toJson<String>(url),
      'format': serializer.toJson<String>(format),
      'file': serializer.toJson<String?>(file),
      'sha256': serializer.toJson<String?>(sha256),
      'size': serializer.toJson<int?>(size),
      'updatedAt': serializer.toJson<int?>(updatedAt),
      'checkedAt': serializer.toJson<int?>(checkedAt),
      'lastError': serializer.toJson<String?>(lastError),
      'skipped': serializer.toJson<int>(skipped),
    };
  }

  RuleResourceRow copyWith({
    String? url,
    String? format,
    Value<String?> file = const Value.absent(),
    Value<String?> sha256 = const Value.absent(),
    Value<int?> size = const Value.absent(),
    Value<int?> updatedAt = const Value.absent(),
    Value<int?> checkedAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    int? skipped,
  }) => RuleResourceRow(
    url: url ?? this.url,
    format: format ?? this.format,
    file: file.present ? file.value : this.file,
    sha256: sha256.present ? sha256.value : this.sha256,
    size: size.present ? size.value : this.size,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    checkedAt: checkedAt.present ? checkedAt.value : this.checkedAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    skipped: skipped ?? this.skipped,
  );
  RuleResourceRow copyWithCompanion(RuleResourcesCompanion data) {
    return RuleResourceRow(
      url: data.url.present ? data.url.value : this.url,
      format: data.format.present ? data.format.value : this.format,
      file: data.file.present ? data.file.value : this.file,
      sha256: data.sha256.present ? data.sha256.value : this.sha256,
      size: data.size.present ? data.size.value : this.size,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      checkedAt: data.checkedAt.present ? data.checkedAt.value : this.checkedAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      skipped: data.skipped.present ? data.skipped.value : this.skipped,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RuleResourceRow(')
          ..write('url: $url, ')
          ..write('format: $format, ')
          ..write('file: $file, ')
          ..write('sha256: $sha256, ')
          ..write('size: $size, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('checkedAt: $checkedAt, ')
          ..write('lastError: $lastError, ')
          ..write('skipped: $skipped')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    url,
    format,
    file,
    sha256,
    size,
    updatedAt,
    checkedAt,
    lastError,
    skipped,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RuleResourceRow &&
          other.url == this.url &&
          other.format == this.format &&
          other.file == this.file &&
          other.sha256 == this.sha256 &&
          other.size == this.size &&
          other.updatedAt == this.updatedAt &&
          other.checkedAt == this.checkedAt &&
          other.lastError == this.lastError &&
          other.skipped == this.skipped);
}

class RuleResourcesCompanion extends UpdateCompanion<RuleResourceRow> {
  final Value<String> url;
  final Value<String> format;
  final Value<String?> file;
  final Value<String?> sha256;
  final Value<int?> size;
  final Value<int?> updatedAt;
  final Value<int?> checkedAt;
  final Value<String?> lastError;
  final Value<int> skipped;
  final Value<int> rowid;
  const RuleResourcesCompanion({
    this.url = const Value.absent(),
    this.format = const Value.absent(),
    this.file = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.size = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.checkedAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.skipped = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RuleResourcesCompanion.insert({
    required String url,
    required String format,
    this.file = const Value.absent(),
    this.sha256 = const Value.absent(),
    this.size = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.checkedAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.skipped = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : url = Value(url),
       format = Value(format);
  static Insertable<RuleResourceRow> custom({
    Expression<String>? url,
    Expression<String>? format,
    Expression<String>? file,
    Expression<String>? sha256,
    Expression<int>? size,
    Expression<int>? updatedAt,
    Expression<int>? checkedAt,
    Expression<String>? lastError,
    Expression<int>? skipped,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (url != null) 'url': url,
      if (format != null) 'format': format,
      if (file != null) 'file': file,
      if (sha256 != null) 'sha256': sha256,
      if (size != null) 'size': size,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (checkedAt != null) 'checked_at': checkedAt,
      if (lastError != null) 'last_error': lastError,
      if (skipped != null) 'skipped': skipped,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RuleResourcesCompanion copyWith({
    Value<String>? url,
    Value<String>? format,
    Value<String?>? file,
    Value<String?>? sha256,
    Value<int?>? size,
    Value<int?>? updatedAt,
    Value<int?>? checkedAt,
    Value<String?>? lastError,
    Value<int>? skipped,
    Value<int>? rowid,
  }) {
    return RuleResourcesCompanion(
      url: url ?? this.url,
      format: format ?? this.format,
      file: file ?? this.file,
      sha256: sha256 ?? this.sha256,
      size: size ?? this.size,
      updatedAt: updatedAt ?? this.updatedAt,
      checkedAt: checkedAt ?? this.checkedAt,
      lastError: lastError ?? this.lastError,
      skipped: skipped ?? this.skipped,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (url.present) {
      map['url'] = Variable<String>(url.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (file.present) {
      map['file'] = Variable<String>(file.value);
    }
    if (sha256.present) {
      map['sha256'] = Variable<String>(sha256.value);
    }
    if (size.present) {
      map['size'] = Variable<int>(size.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (checkedAt.present) {
      map['checked_at'] = Variable<int>(checkedAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (skipped.present) {
      map['skipped'] = Variable<int>(skipped.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RuleResourcesCompanion(')
          ..write('url: $url, ')
          ..write('format: $format, ')
          ..write('file: $file, ')
          ..write('sha256: $sha256, ')
          ..write('size: $size, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('checkedAt: $checkedAt, ')
          ..write('lastError: $lastError, ')
          ..write('skipped: $skipped, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SecretsTable extends Secrets with TableInfo<$SecretsTable, SecretRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SecretsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nonceMeta = const VerificationMeta('nonce');
  @override
  late final GeneratedColumn<Uint8List> nonce = GeneratedColumn<Uint8List>(
    'nonce',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ciphertextMeta = const VerificationMeta(
    'ciphertext',
  );
  @override
  late final GeneratedColumn<Uint8List> ciphertext = GeneratedColumn<Uint8List>(
    'ciphertext',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, nonce, ciphertext, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'secrets';
  @override
  VerificationContext validateIntegrity(
    Insertable<SecretRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('nonce')) {
      context.handle(
        _nonceMeta,
        nonce.isAcceptableOrUnknown(data['nonce']!, _nonceMeta),
      );
    } else if (isInserting) {
      context.missing(_nonceMeta);
    }
    if (data.containsKey('ciphertext')) {
      context.handle(
        _ciphertextMeta,
        ciphertext.isAcceptableOrUnknown(data['ciphertext']!, _ciphertextMeta),
      );
    } else if (isInserting) {
      context.missing(_ciphertextMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SecretRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SecretRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nonce: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}nonce'],
      )!,
      ciphertext: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}ciphertext'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SecretsTable createAlias(String alias) {
    return $SecretsTable(attachedDatabase, alias);
  }
}

class SecretRow extends DataClass implements Insertable<SecretRow> {
  final String id;
  final Uint8List nonce;
  final Uint8List ciphertext;
  final int createdAt;
  const SecretRow({
    required this.id,
    required this.nonce,
    required this.ciphertext,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['nonce'] = Variable<Uint8List>(nonce);
    map['ciphertext'] = Variable<Uint8List>(ciphertext);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  SecretsCompanion toCompanion(bool nullToAbsent) {
    return SecretsCompanion(
      id: Value(id),
      nonce: Value(nonce),
      ciphertext: Value(ciphertext),
      createdAt: Value(createdAt),
    );
  }

  factory SecretRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SecretRow(
      id: serializer.fromJson<String>(json['id']),
      nonce: serializer.fromJson<Uint8List>(json['nonce']),
      ciphertext: serializer.fromJson<Uint8List>(json['ciphertext']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nonce': serializer.toJson<Uint8List>(nonce),
      'ciphertext': serializer.toJson<Uint8List>(ciphertext),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  SecretRow copyWith({
    String? id,
    Uint8List? nonce,
    Uint8List? ciphertext,
    int? createdAt,
  }) => SecretRow(
    id: id ?? this.id,
    nonce: nonce ?? this.nonce,
    ciphertext: ciphertext ?? this.ciphertext,
    createdAt: createdAt ?? this.createdAt,
  );
  SecretRow copyWithCompanion(SecretsCompanion data) {
    return SecretRow(
      id: data.id.present ? data.id.value : this.id,
      nonce: data.nonce.present ? data.nonce.value : this.nonce,
      ciphertext: data.ciphertext.present
          ? data.ciphertext.value
          : this.ciphertext,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SecretRow(')
          ..write('id: $id, ')
          ..write('nonce: $nonce, ')
          ..write('ciphertext: $ciphertext, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    $driftBlobEquality.hash(nonce),
    $driftBlobEquality.hash(ciphertext),
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SecretRow &&
          other.id == this.id &&
          $driftBlobEquality.equals(other.nonce, this.nonce) &&
          $driftBlobEquality.equals(other.ciphertext, this.ciphertext) &&
          other.createdAt == this.createdAt);
}

class SecretsCompanion extends UpdateCompanion<SecretRow> {
  final Value<String> id;
  final Value<Uint8List> nonce;
  final Value<Uint8List> ciphertext;
  final Value<int> createdAt;
  final Value<int> rowid;
  const SecretsCompanion({
    this.id = const Value.absent(),
    this.nonce = const Value.absent(),
    this.ciphertext = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SecretsCompanion.insert({
    required String id,
    required Uint8List nonce,
    required Uint8List ciphertext,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nonce = Value(nonce),
       ciphertext = Value(ciphertext),
       createdAt = Value(createdAt);
  static Insertable<SecretRow> custom({
    Expression<String>? id,
    Expression<Uint8List>? nonce,
    Expression<Uint8List>? ciphertext,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nonce != null) 'nonce': nonce,
      if (ciphertext != null) 'ciphertext': ciphertext,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SecretsCompanion copyWith({
    Value<String>? id,
    Value<Uint8List>? nonce,
    Value<Uint8List>? ciphertext,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return SecretsCompanion(
      id: id ?? this.id,
      nonce: nonce ?? this.nonce,
      ciphertext: ciphertext ?? this.ciphertext,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nonce.present) {
      map['nonce'] = Variable<Uint8List>(nonce.value);
    }
    if (ciphertext.present) {
      map['ciphertext'] = Variable<Uint8List>(ciphertext.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SecretsCompanion(')
          ..write('id: $id, ')
          ..write('nonce: $nonce, ')
          ..write('ciphertext: $ciphertext, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CloudSessionTable extends CloudSession
    with TableInfo<$CloudSessionTable, CloudSessionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CloudSessionTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _installationIdMeta = const VerificationMeta(
    'installationId',
  );
  @override
  late final GeneratedColumn<String> installationId = GeneratedColumn<String>(
    'installation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accessSecretIdMeta = const VerificationMeta(
    'accessSecretId',
  );
  @override
  late final GeneratedColumn<String> accessSecretId = GeneratedColumn<String>(
    'access_secret_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _refreshSecretIdMeta = const VerificationMeta(
    'refreshSecretId',
  );
  @override
  late final GeneratedColumn<String> refreshSecretId = GeneratedColumn<String>(
    'refresh_secret_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entitlementJsonMeta = const VerificationMeta(
    'entitlementJson',
  );
  @override
  late final GeneratedColumn<String> entitlementJson = GeneratedColumn<String>(
    'entitlement_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _loggedInMeta = const VerificationMeta(
    'loggedIn',
  );
  @override
  late final GeneratedColumn<bool> loggedIn = GeneratedColumn<bool>(
    'logged_in',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("logged_in" IN (0, 1))',
    ),
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    email,
    displayName,
    deviceId,
    installationId,
    accessSecretId,
    refreshSecretId,
    entitlementJson,
    loggedIn,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cloud_session';
  @override
  VerificationContext validateIntegrity(
    Insertable<CloudSessionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('installation_id')) {
      context.handle(
        _installationIdMeta,
        installationId.isAcceptableOrUnknown(
          data['installation_id']!,
          _installationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_installationIdMeta);
    }
    if (data.containsKey('access_secret_id')) {
      context.handle(
        _accessSecretIdMeta,
        accessSecretId.isAcceptableOrUnknown(
          data['access_secret_id']!,
          _accessSecretIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_accessSecretIdMeta);
    }
    if (data.containsKey('refresh_secret_id')) {
      context.handle(
        _refreshSecretIdMeta,
        refreshSecretId.isAcceptableOrUnknown(
          data['refresh_secret_id']!,
          _refreshSecretIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_refreshSecretIdMeta);
    }
    if (data.containsKey('entitlement_json')) {
      context.handle(
        _entitlementJsonMeta,
        entitlementJson.isAcceptableOrUnknown(
          data['entitlement_json']!,
          _entitlementJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_entitlementJsonMeta);
    }
    if (data.containsKey('logged_in')) {
      context.handle(
        _loggedInMeta,
        loggedIn.isAcceptableOrUnknown(data['logged_in']!, _loggedInMeta),
      );
    } else if (isInserting) {
      context.missing(_loggedInMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CloudSessionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CloudSessionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      installationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}installation_id'],
      )!,
      accessSecretId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}access_secret_id'],
      )!,
      refreshSecretId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}refresh_secret_id'],
      )!,
      entitlementJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entitlement_json'],
      )!,
      loggedIn: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}logged_in'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CloudSessionTable createAlias(String alias) {
    return $CloudSessionTable(attachedDatabase, alias);
  }
}

class CloudSessionRow extends DataClass implements Insertable<CloudSessionRow> {
  final int id;
  final String accountId;
  final String email;
  final String displayName;
  final String deviceId;
  final String installationId;
  final String accessSecretId;
  final String refreshSecretId;
  final String entitlementJson;
  final bool loggedIn;
  final int updatedAt;
  const CloudSessionRow({
    required this.id,
    required this.accountId,
    required this.email,
    required this.displayName,
    required this.deviceId,
    required this.installationId,
    required this.accessSecretId,
    required this.refreshSecretId,
    required this.entitlementJson,
    required this.loggedIn,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['account_id'] = Variable<String>(accountId);
    map['email'] = Variable<String>(email);
    map['display_name'] = Variable<String>(displayName);
    map['device_id'] = Variable<String>(deviceId);
    map['installation_id'] = Variable<String>(installationId);
    map['access_secret_id'] = Variable<String>(accessSecretId);
    map['refresh_secret_id'] = Variable<String>(refreshSecretId);
    map['entitlement_json'] = Variable<String>(entitlementJson);
    map['logged_in'] = Variable<bool>(loggedIn);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  CloudSessionCompanion toCompanion(bool nullToAbsent) {
    return CloudSessionCompanion(
      id: Value(id),
      accountId: Value(accountId),
      email: Value(email),
      displayName: Value(displayName),
      deviceId: Value(deviceId),
      installationId: Value(installationId),
      accessSecretId: Value(accessSecretId),
      refreshSecretId: Value(refreshSecretId),
      entitlementJson: Value(entitlementJson),
      loggedIn: Value(loggedIn),
      updatedAt: Value(updatedAt),
    );
  }

  factory CloudSessionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CloudSessionRow(
      id: serializer.fromJson<int>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      email: serializer.fromJson<String>(json['email']),
      displayName: serializer.fromJson<String>(json['displayName']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      installationId: serializer.fromJson<String>(json['installationId']),
      accessSecretId: serializer.fromJson<String>(json['accessSecretId']),
      refreshSecretId: serializer.fromJson<String>(json['refreshSecretId']),
      entitlementJson: serializer.fromJson<String>(json['entitlementJson']),
      loggedIn: serializer.fromJson<bool>(json['loggedIn']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'accountId': serializer.toJson<String>(accountId),
      'email': serializer.toJson<String>(email),
      'displayName': serializer.toJson<String>(displayName),
      'deviceId': serializer.toJson<String>(deviceId),
      'installationId': serializer.toJson<String>(installationId),
      'accessSecretId': serializer.toJson<String>(accessSecretId),
      'refreshSecretId': serializer.toJson<String>(refreshSecretId),
      'entitlementJson': serializer.toJson<String>(entitlementJson),
      'loggedIn': serializer.toJson<bool>(loggedIn),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  CloudSessionRow copyWith({
    int? id,
    String? accountId,
    String? email,
    String? displayName,
    String? deviceId,
    String? installationId,
    String? accessSecretId,
    String? refreshSecretId,
    String? entitlementJson,
    bool? loggedIn,
    int? updatedAt,
  }) => CloudSessionRow(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    email: email ?? this.email,
    displayName: displayName ?? this.displayName,
    deviceId: deviceId ?? this.deviceId,
    installationId: installationId ?? this.installationId,
    accessSecretId: accessSecretId ?? this.accessSecretId,
    refreshSecretId: refreshSecretId ?? this.refreshSecretId,
    entitlementJson: entitlementJson ?? this.entitlementJson,
    loggedIn: loggedIn ?? this.loggedIn,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CloudSessionRow copyWithCompanion(CloudSessionCompanion data) {
    return CloudSessionRow(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      email: data.email.present ? data.email.value : this.email,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      installationId: data.installationId.present
          ? data.installationId.value
          : this.installationId,
      accessSecretId: data.accessSecretId.present
          ? data.accessSecretId.value
          : this.accessSecretId,
      refreshSecretId: data.refreshSecretId.present
          ? data.refreshSecretId.value
          : this.refreshSecretId,
      entitlementJson: data.entitlementJson.present
          ? data.entitlementJson.value
          : this.entitlementJson,
      loggedIn: data.loggedIn.present ? data.loggedIn.value : this.loggedIn,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CloudSessionRow(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('email: $email, ')
          ..write('displayName: $displayName, ')
          ..write('deviceId: $deviceId, ')
          ..write('installationId: $installationId, ')
          ..write('accessSecretId: $accessSecretId, ')
          ..write('refreshSecretId: $refreshSecretId, ')
          ..write('entitlementJson: $entitlementJson, ')
          ..write('loggedIn: $loggedIn, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    accountId,
    email,
    displayName,
    deviceId,
    installationId,
    accessSecretId,
    refreshSecretId,
    entitlementJson,
    loggedIn,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CloudSessionRow &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.email == this.email &&
          other.displayName == this.displayName &&
          other.deviceId == this.deviceId &&
          other.installationId == this.installationId &&
          other.accessSecretId == this.accessSecretId &&
          other.refreshSecretId == this.refreshSecretId &&
          other.entitlementJson == this.entitlementJson &&
          other.loggedIn == this.loggedIn &&
          other.updatedAt == this.updatedAt);
}

class CloudSessionCompanion extends UpdateCompanion<CloudSessionRow> {
  final Value<int> id;
  final Value<String> accountId;
  final Value<String> email;
  final Value<String> displayName;
  final Value<String> deviceId;
  final Value<String> installationId;
  final Value<String> accessSecretId;
  final Value<String> refreshSecretId;
  final Value<String> entitlementJson;
  final Value<bool> loggedIn;
  final Value<int> updatedAt;
  const CloudSessionCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.email = const Value.absent(),
    this.displayName = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.installationId = const Value.absent(),
    this.accessSecretId = const Value.absent(),
    this.refreshSecretId = const Value.absent(),
    this.entitlementJson = const Value.absent(),
    this.loggedIn = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  CloudSessionCompanion.insert({
    this.id = const Value.absent(),
    required String accountId,
    required String email,
    required String displayName,
    required String deviceId,
    required String installationId,
    required String accessSecretId,
    required String refreshSecretId,
    required String entitlementJson,
    required bool loggedIn,
    required int updatedAt,
  }) : accountId = Value(accountId),
       email = Value(email),
       displayName = Value(displayName),
       deviceId = Value(deviceId),
       installationId = Value(installationId),
       accessSecretId = Value(accessSecretId),
       refreshSecretId = Value(refreshSecretId),
       entitlementJson = Value(entitlementJson),
       loggedIn = Value(loggedIn),
       updatedAt = Value(updatedAt);
  static Insertable<CloudSessionRow> custom({
    Expression<int>? id,
    Expression<String>? accountId,
    Expression<String>? email,
    Expression<String>? displayName,
    Expression<String>? deviceId,
    Expression<String>? installationId,
    Expression<String>? accessSecretId,
    Expression<String>? refreshSecretId,
    Expression<String>? entitlementJson,
    Expression<bool>? loggedIn,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (email != null) 'email': email,
      if (displayName != null) 'display_name': displayName,
      if (deviceId != null) 'device_id': deviceId,
      if (installationId != null) 'installation_id': installationId,
      if (accessSecretId != null) 'access_secret_id': accessSecretId,
      if (refreshSecretId != null) 'refresh_secret_id': refreshSecretId,
      if (entitlementJson != null) 'entitlement_json': entitlementJson,
      if (loggedIn != null) 'logged_in': loggedIn,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  CloudSessionCompanion copyWith({
    Value<int>? id,
    Value<String>? accountId,
    Value<String>? email,
    Value<String>? displayName,
    Value<String>? deviceId,
    Value<String>? installationId,
    Value<String>? accessSecretId,
    Value<String>? refreshSecretId,
    Value<String>? entitlementJson,
    Value<bool>? loggedIn,
    Value<int>? updatedAt,
  }) {
    return CloudSessionCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      deviceId: deviceId ?? this.deviceId,
      installationId: installationId ?? this.installationId,
      accessSecretId: accessSecretId ?? this.accessSecretId,
      refreshSecretId: refreshSecretId ?? this.refreshSecretId,
      entitlementJson: entitlementJson ?? this.entitlementJson,
      loggedIn: loggedIn ?? this.loggedIn,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (installationId.present) {
      map['installation_id'] = Variable<String>(installationId.value);
    }
    if (accessSecretId.present) {
      map['access_secret_id'] = Variable<String>(accessSecretId.value);
    }
    if (refreshSecretId.present) {
      map['refresh_secret_id'] = Variable<String>(refreshSecretId.value);
    }
    if (entitlementJson.present) {
      map['entitlement_json'] = Variable<String>(entitlementJson.value);
    }
    if (loggedIn.present) {
      map['logged_in'] = Variable<bool>(loggedIn.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CloudSessionCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('email: $email, ')
          ..write('displayName: $displayName, ')
          ..write('deviceId: $deviceId, ')
          ..write('installationId: $installationId, ')
          ..write('accessSecretId: $accessSecretId, ')
          ..write('refreshSecretId: $refreshSecretId, ')
          ..write('entitlementJson: $entitlementJson, ')
          ..write('loggedIn: $loggedIn, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $SyncMetaTable extends SyncMeta
    with TableInfo<$SyncMetaTable, SyncMetaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncMetaTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remoteRevisionMeta = const VerificationMeta(
    'remoteRevision',
  );
  @override
  late final GeneratedColumn<int> remoteRevision = GeneratedColumn<int>(
    'remote_revision',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  @override
  late final GeneratedColumn<bool> dirty = GeneratedColumn<bool>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dirty" IN (0, 1))',
    ),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  @override
  late final GeneratedColumn<bool> deleted = GeneratedColumn<bool>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("deleted" IN (0, 1))',
    ),
  );
  static const VerificationMeta _editedAtMeta = const VerificationMeta(
    'editedAt',
  );
  @override
  late final GeneratedColumn<int> editedAt = GeneratedColumn<int>(
    'edited_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mutationIdMeta = const VerificationMeta(
    'mutationId',
  );
  @override
  late final GeneratedColumn<String> mutationId = GeneratedColumn<String>(
    'mutation_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pendingEnvelopeSecretIdMeta =
      const VerificationMeta('pendingEnvelopeSecretId');
  @override
  late final GeneratedColumn<String> pendingEnvelopeSecretId =
      GeneratedColumn<String>(
        'pending_envelope_secret_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _inFlightMutationIdMeta =
      const VerificationMeta('inFlightMutationId');
  @override
  late final GeneratedColumn<String> inFlightMutationId =
      GeneratedColumn<String>(
        'in_flight_mutation_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _inFlightEnvelopeSecretIdMeta =
      const VerificationMeta('inFlightEnvelopeSecretId');
  @override
  late final GeneratedColumn<String> inFlightEnvelopeSecretId =
      GeneratedColumn<String>(
        'in_flight_envelope_secret_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncGenerationMeta = const VerificationMeta(
    'syncGeneration',
  );
  @override
  late final GeneratedColumn<String> syncGeneration = GeneratedColumn<String>(
    'sync_generation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    recordId,
    type,
    accountId,
    documentId,
    remoteRevision,
    dirty,
    deleted,
    editedAt,
    mutationId,
    pendingEnvelopeSecretId,
    inFlightMutationId,
    inFlightEnvelopeSecretId,
    syncGeneration,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncMetaRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('remote_revision')) {
      context.handle(
        _remoteRevisionMeta,
        remoteRevision.isAcceptableOrUnknown(
          data['remote_revision']!,
          _remoteRevisionMeta,
        ),
      );
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    } else if (isInserting) {
      context.missing(_dirtyMeta);
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    } else if (isInserting) {
      context.missing(_deletedMeta);
    }
    if (data.containsKey('edited_at')) {
      context.handle(
        _editedAtMeta,
        editedAt.isAcceptableOrUnknown(data['edited_at']!, _editedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_editedAtMeta);
    }
    if (data.containsKey('mutation_id')) {
      context.handle(
        _mutationIdMeta,
        mutationId.isAcceptableOrUnknown(data['mutation_id']!, _mutationIdMeta),
      );
    }
    if (data.containsKey('pending_envelope_secret_id')) {
      context.handle(
        _pendingEnvelopeSecretIdMeta,
        pendingEnvelopeSecretId.isAcceptableOrUnknown(
          data['pending_envelope_secret_id']!,
          _pendingEnvelopeSecretIdMeta,
        ),
      );
    }
    if (data.containsKey('in_flight_mutation_id')) {
      context.handle(
        _inFlightMutationIdMeta,
        inFlightMutationId.isAcceptableOrUnknown(
          data['in_flight_mutation_id']!,
          _inFlightMutationIdMeta,
        ),
      );
    }
    if (data.containsKey('in_flight_envelope_secret_id')) {
      context.handle(
        _inFlightEnvelopeSecretIdMeta,
        inFlightEnvelopeSecretId.isAcceptableOrUnknown(
          data['in_flight_envelope_secret_id']!,
          _inFlightEnvelopeSecretIdMeta,
        ),
      );
    }
    if (data.containsKey('sync_generation')) {
      context.handle(
        _syncGenerationMeta,
        syncGeneration.isAcceptableOrUnknown(
          data['sync_generation']!,
          _syncGenerationMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, recordId};
  @override
  SyncMetaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncMetaRow(
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      remoteRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remote_revision'],
      ),
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dirty'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}deleted'],
      )!,
      editedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}edited_at'],
      )!,
      mutationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mutation_id'],
      ),
      pendingEnvelopeSecretId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pending_envelope_secret_id'],
      ),
      inFlightMutationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}in_flight_mutation_id'],
      ),
      inFlightEnvelopeSecretId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}in_flight_envelope_secret_id'],
      ),
      syncGeneration: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_generation'],
      ),
    );
  }

  @override
  $SyncMetaTable createAlias(String alias) {
    return $SyncMetaTable(attachedDatabase, alias);
  }
}

class SyncMetaRow extends DataClass implements Insertable<SyncMetaRow> {
  final String recordId;
  final String type;
  final String accountId;
  final String documentId;
  final int? remoteRevision;
  final bool dirty;
  final bool deleted;
  final int editedAt;
  final String? mutationId;
  final String? pendingEnvelopeSecretId;
  final String? inFlightMutationId;
  final String? inFlightEnvelopeSecretId;
  final String? syncGeneration;
  const SyncMetaRow({
    required this.recordId,
    required this.type,
    required this.accountId,
    required this.documentId,
    this.remoteRevision,
    required this.dirty,
    required this.deleted,
    required this.editedAt,
    this.mutationId,
    this.pendingEnvelopeSecretId,
    this.inFlightMutationId,
    this.inFlightEnvelopeSecretId,
    this.syncGeneration,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['record_id'] = Variable<String>(recordId);
    map['type'] = Variable<String>(type);
    map['account_id'] = Variable<String>(accountId);
    map['document_id'] = Variable<String>(documentId);
    if (!nullToAbsent || remoteRevision != null) {
      map['remote_revision'] = Variable<int>(remoteRevision);
    }
    map['dirty'] = Variable<bool>(dirty);
    map['deleted'] = Variable<bool>(deleted);
    map['edited_at'] = Variable<int>(editedAt);
    if (!nullToAbsent || mutationId != null) {
      map['mutation_id'] = Variable<String>(mutationId);
    }
    if (!nullToAbsent || pendingEnvelopeSecretId != null) {
      map['pending_envelope_secret_id'] = Variable<String>(
        pendingEnvelopeSecretId,
      );
    }
    if (!nullToAbsent || inFlightMutationId != null) {
      map['in_flight_mutation_id'] = Variable<String>(inFlightMutationId);
    }
    if (!nullToAbsent || inFlightEnvelopeSecretId != null) {
      map['in_flight_envelope_secret_id'] = Variable<String>(
        inFlightEnvelopeSecretId,
      );
    }
    if (!nullToAbsent || syncGeneration != null) {
      map['sync_generation'] = Variable<String>(syncGeneration);
    }
    return map;
  }

  SyncMetaCompanion toCompanion(bool nullToAbsent) {
    return SyncMetaCompanion(
      recordId: Value(recordId),
      type: Value(type),
      accountId: Value(accountId),
      documentId: Value(documentId),
      remoteRevision: remoteRevision == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteRevision),
      dirty: Value(dirty),
      deleted: Value(deleted),
      editedAt: Value(editedAt),
      mutationId: mutationId == null && nullToAbsent
          ? const Value.absent()
          : Value(mutationId),
      pendingEnvelopeSecretId: pendingEnvelopeSecretId == null && nullToAbsent
          ? const Value.absent()
          : Value(pendingEnvelopeSecretId),
      inFlightMutationId: inFlightMutationId == null && nullToAbsent
          ? const Value.absent()
          : Value(inFlightMutationId),
      inFlightEnvelopeSecretId: inFlightEnvelopeSecretId == null && nullToAbsent
          ? const Value.absent()
          : Value(inFlightEnvelopeSecretId),
      syncGeneration: syncGeneration == null && nullToAbsent
          ? const Value.absent()
          : Value(syncGeneration),
    );
  }

  factory SyncMetaRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncMetaRow(
      recordId: serializer.fromJson<String>(json['recordId']),
      type: serializer.fromJson<String>(json['type']),
      accountId: serializer.fromJson<String>(json['accountId']),
      documentId: serializer.fromJson<String>(json['documentId']),
      remoteRevision: serializer.fromJson<int?>(json['remoteRevision']),
      dirty: serializer.fromJson<bool>(json['dirty']),
      deleted: serializer.fromJson<bool>(json['deleted']),
      editedAt: serializer.fromJson<int>(json['editedAt']),
      mutationId: serializer.fromJson<String?>(json['mutationId']),
      pendingEnvelopeSecretId: serializer.fromJson<String?>(
        json['pendingEnvelopeSecretId'],
      ),
      inFlightMutationId: serializer.fromJson<String?>(
        json['inFlightMutationId'],
      ),
      inFlightEnvelopeSecretId: serializer.fromJson<String?>(
        json['inFlightEnvelopeSecretId'],
      ),
      syncGeneration: serializer.fromJson<String?>(json['syncGeneration']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'recordId': serializer.toJson<String>(recordId),
      'type': serializer.toJson<String>(type),
      'accountId': serializer.toJson<String>(accountId),
      'documentId': serializer.toJson<String>(documentId),
      'remoteRevision': serializer.toJson<int?>(remoteRevision),
      'dirty': serializer.toJson<bool>(dirty),
      'deleted': serializer.toJson<bool>(deleted),
      'editedAt': serializer.toJson<int>(editedAt),
      'mutationId': serializer.toJson<String?>(mutationId),
      'pendingEnvelopeSecretId': serializer.toJson<String?>(
        pendingEnvelopeSecretId,
      ),
      'inFlightMutationId': serializer.toJson<String?>(inFlightMutationId),
      'inFlightEnvelopeSecretId': serializer.toJson<String?>(
        inFlightEnvelopeSecretId,
      ),
      'syncGeneration': serializer.toJson<String?>(syncGeneration),
    };
  }

  SyncMetaRow copyWith({
    String? recordId,
    String? type,
    String? accountId,
    String? documentId,
    Value<int?> remoteRevision = const Value.absent(),
    bool? dirty,
    bool? deleted,
    int? editedAt,
    Value<String?> mutationId = const Value.absent(),
    Value<String?> pendingEnvelopeSecretId = const Value.absent(),
    Value<String?> inFlightMutationId = const Value.absent(),
    Value<String?> inFlightEnvelopeSecretId = const Value.absent(),
    Value<String?> syncGeneration = const Value.absent(),
  }) => SyncMetaRow(
    recordId: recordId ?? this.recordId,
    type: type ?? this.type,
    accountId: accountId ?? this.accountId,
    documentId: documentId ?? this.documentId,
    remoteRevision: remoteRevision.present
        ? remoteRevision.value
        : this.remoteRevision,
    dirty: dirty ?? this.dirty,
    deleted: deleted ?? this.deleted,
    editedAt: editedAt ?? this.editedAt,
    mutationId: mutationId.present ? mutationId.value : this.mutationId,
    pendingEnvelopeSecretId: pendingEnvelopeSecretId.present
        ? pendingEnvelopeSecretId.value
        : this.pendingEnvelopeSecretId,
    inFlightMutationId: inFlightMutationId.present
        ? inFlightMutationId.value
        : this.inFlightMutationId,
    inFlightEnvelopeSecretId: inFlightEnvelopeSecretId.present
        ? inFlightEnvelopeSecretId.value
        : this.inFlightEnvelopeSecretId,
    syncGeneration: syncGeneration.present
        ? syncGeneration.value
        : this.syncGeneration,
  );
  SyncMetaRow copyWithCompanion(SyncMetaCompanion data) {
    return SyncMetaRow(
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      type: data.type.present ? data.type.value : this.type,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      remoteRevision: data.remoteRevision.present
          ? data.remoteRevision.value
          : this.remoteRevision,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      editedAt: data.editedAt.present ? data.editedAt.value : this.editedAt,
      mutationId: data.mutationId.present
          ? data.mutationId.value
          : this.mutationId,
      pendingEnvelopeSecretId: data.pendingEnvelopeSecretId.present
          ? data.pendingEnvelopeSecretId.value
          : this.pendingEnvelopeSecretId,
      inFlightMutationId: data.inFlightMutationId.present
          ? data.inFlightMutationId.value
          : this.inFlightMutationId,
      inFlightEnvelopeSecretId: data.inFlightEnvelopeSecretId.present
          ? data.inFlightEnvelopeSecretId.value
          : this.inFlightEnvelopeSecretId,
      syncGeneration: data.syncGeneration.present
          ? data.syncGeneration.value
          : this.syncGeneration,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaRow(')
          ..write('recordId: $recordId, ')
          ..write('type: $type, ')
          ..write('accountId: $accountId, ')
          ..write('documentId: $documentId, ')
          ..write('remoteRevision: $remoteRevision, ')
          ..write('dirty: $dirty, ')
          ..write('deleted: $deleted, ')
          ..write('editedAt: $editedAt, ')
          ..write('mutationId: $mutationId, ')
          ..write('pendingEnvelopeSecretId: $pendingEnvelopeSecretId, ')
          ..write('inFlightMutationId: $inFlightMutationId, ')
          ..write('inFlightEnvelopeSecretId: $inFlightEnvelopeSecretId, ')
          ..write('syncGeneration: $syncGeneration')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    recordId,
    type,
    accountId,
    documentId,
    remoteRevision,
    dirty,
    deleted,
    editedAt,
    mutationId,
    pendingEnvelopeSecretId,
    inFlightMutationId,
    inFlightEnvelopeSecretId,
    syncGeneration,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncMetaRow &&
          other.recordId == this.recordId &&
          other.type == this.type &&
          other.accountId == this.accountId &&
          other.documentId == this.documentId &&
          other.remoteRevision == this.remoteRevision &&
          other.dirty == this.dirty &&
          other.deleted == this.deleted &&
          other.editedAt == this.editedAt &&
          other.mutationId == this.mutationId &&
          other.pendingEnvelopeSecretId == this.pendingEnvelopeSecretId &&
          other.inFlightMutationId == this.inFlightMutationId &&
          other.inFlightEnvelopeSecretId == this.inFlightEnvelopeSecretId &&
          other.syncGeneration == this.syncGeneration);
}

class SyncMetaCompanion extends UpdateCompanion<SyncMetaRow> {
  final Value<String> recordId;
  final Value<String> type;
  final Value<String> accountId;
  final Value<String> documentId;
  final Value<int?> remoteRevision;
  final Value<bool> dirty;
  final Value<bool> deleted;
  final Value<int> editedAt;
  final Value<String?> mutationId;
  final Value<String?> pendingEnvelopeSecretId;
  final Value<String?> inFlightMutationId;
  final Value<String?> inFlightEnvelopeSecretId;
  final Value<String?> syncGeneration;
  final Value<int> rowid;
  const SyncMetaCompanion({
    this.recordId = const Value.absent(),
    this.type = const Value.absent(),
    this.accountId = const Value.absent(),
    this.documentId = const Value.absent(),
    this.remoteRevision = const Value.absent(),
    this.dirty = const Value.absent(),
    this.deleted = const Value.absent(),
    this.editedAt = const Value.absent(),
    this.mutationId = const Value.absent(),
    this.pendingEnvelopeSecretId = const Value.absent(),
    this.inFlightMutationId = const Value.absent(),
    this.inFlightEnvelopeSecretId = const Value.absent(),
    this.syncGeneration = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncMetaCompanion.insert({
    required String recordId,
    required String type,
    required String accountId,
    required String documentId,
    this.remoteRevision = const Value.absent(),
    required bool dirty,
    required bool deleted,
    required int editedAt,
    this.mutationId = const Value.absent(),
    this.pendingEnvelopeSecretId = const Value.absent(),
    this.inFlightMutationId = const Value.absent(),
    this.inFlightEnvelopeSecretId = const Value.absent(),
    this.syncGeneration = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : recordId = Value(recordId),
       type = Value(type),
       accountId = Value(accountId),
       documentId = Value(documentId),
       dirty = Value(dirty),
       deleted = Value(deleted),
       editedAt = Value(editedAt);
  static Insertable<SyncMetaRow> custom({
    Expression<String>? recordId,
    Expression<String>? type,
    Expression<String>? accountId,
    Expression<String>? documentId,
    Expression<int>? remoteRevision,
    Expression<bool>? dirty,
    Expression<bool>? deleted,
    Expression<int>? editedAt,
    Expression<String>? mutationId,
    Expression<String>? pendingEnvelopeSecretId,
    Expression<String>? inFlightMutationId,
    Expression<String>? inFlightEnvelopeSecretId,
    Expression<String>? syncGeneration,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (recordId != null) 'record_id': recordId,
      if (type != null) 'type': type,
      if (accountId != null) 'account_id': accountId,
      if (documentId != null) 'document_id': documentId,
      if (remoteRevision != null) 'remote_revision': remoteRevision,
      if (dirty != null) 'dirty': dirty,
      if (deleted != null) 'deleted': deleted,
      if (editedAt != null) 'edited_at': editedAt,
      if (mutationId != null) 'mutation_id': mutationId,
      if (pendingEnvelopeSecretId != null)
        'pending_envelope_secret_id': pendingEnvelopeSecretId,
      if (inFlightMutationId != null)
        'in_flight_mutation_id': inFlightMutationId,
      if (inFlightEnvelopeSecretId != null)
        'in_flight_envelope_secret_id': inFlightEnvelopeSecretId,
      if (syncGeneration != null) 'sync_generation': syncGeneration,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncMetaCompanion copyWith({
    Value<String>? recordId,
    Value<String>? type,
    Value<String>? accountId,
    Value<String>? documentId,
    Value<int?>? remoteRevision,
    Value<bool>? dirty,
    Value<bool>? deleted,
    Value<int>? editedAt,
    Value<String?>? mutationId,
    Value<String?>? pendingEnvelopeSecretId,
    Value<String?>? inFlightMutationId,
    Value<String?>? inFlightEnvelopeSecretId,
    Value<String?>? syncGeneration,
    Value<int>? rowid,
  }) {
    return SyncMetaCompanion(
      recordId: recordId ?? this.recordId,
      type: type ?? this.type,
      accountId: accountId ?? this.accountId,
      documentId: documentId ?? this.documentId,
      remoteRevision: remoteRevision ?? this.remoteRevision,
      dirty: dirty ?? this.dirty,
      deleted: deleted ?? this.deleted,
      editedAt: editedAt ?? this.editedAt,
      mutationId: mutationId ?? this.mutationId,
      pendingEnvelopeSecretId:
          pendingEnvelopeSecretId ?? this.pendingEnvelopeSecretId,
      inFlightMutationId: inFlightMutationId ?? this.inFlightMutationId,
      inFlightEnvelopeSecretId:
          inFlightEnvelopeSecretId ?? this.inFlightEnvelopeSecretId,
      syncGeneration: syncGeneration ?? this.syncGeneration,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (remoteRevision.present) {
      map['remote_revision'] = Variable<int>(remoteRevision.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<bool>(dirty.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<bool>(deleted.value);
    }
    if (editedAt.present) {
      map['edited_at'] = Variable<int>(editedAt.value);
    }
    if (mutationId.present) {
      map['mutation_id'] = Variable<String>(mutationId.value);
    }
    if (pendingEnvelopeSecretId.present) {
      map['pending_envelope_secret_id'] = Variable<String>(
        pendingEnvelopeSecretId.value,
      );
    }
    if (inFlightMutationId.present) {
      map['in_flight_mutation_id'] = Variable<String>(inFlightMutationId.value);
    }
    if (inFlightEnvelopeSecretId.present) {
      map['in_flight_envelope_secret_id'] = Variable<String>(
        inFlightEnvelopeSecretId.value,
      );
    }
    if (syncGeneration.present) {
      map['sync_generation'] = Variable<String>(syncGeneration.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncMetaCompanion(')
          ..write('recordId: $recordId, ')
          ..write('type: $type, ')
          ..write('accountId: $accountId, ')
          ..write('documentId: $documentId, ')
          ..write('remoteRevision: $remoteRevision, ')
          ..write('dirty: $dirty, ')
          ..write('deleted: $deleted, ')
          ..write('editedAt: $editedAt, ')
          ..write('mutationId: $mutationId, ')
          ..write('pendingEnvelopeSecretId: $pendingEnvelopeSecretId, ')
          ..write('inFlightMutationId: $inFlightMutationId, ')
          ..write('inFlightEnvelopeSecretId: $inFlightEnvelopeSecretId, ')
          ..write('syncGeneration: $syncGeneration, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncDocumentsTable extends SyncDocuments
    with TableInfo<$SyncDocumentsTable, SyncDocumentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncDocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localIdMeta = const VerificationMeta(
    'localId',
  );
  @override
  late final GeneratedColumn<String> localId = GeneratedColumn<String>(
    'local_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteRevisionMeta = const VerificationMeta(
    'remoteRevision',
  );
  @override
  late final GeneratedColumn<int> remoteRevision = GeneratedColumn<int>(
    'remote_revision',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteEditedAtMeta = const VerificationMeta(
    'remoteEditedAt',
  );
  @override
  late final GeneratedColumn<int> remoteEditedAt = GeneratedColumn<int>(
    'remote_edited_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteDeletedMeta = const VerificationMeta(
    'remoteDeleted',
  );
  @override
  late final GeneratedColumn<bool> remoteDeleted = GeneratedColumn<bool>(
    'remote_deleted',
    aliasedName,
    true,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("remote_deleted" IN (0, 1))',
    ),
  );
  static const VerificationMeta _remoteSchemaVersionMeta =
      const VerificationMeta('remoteSchemaVersion');
  @override
  late final GeneratedColumn<int> remoteSchemaVersion = GeneratedColumn<int>(
    'remote_schema_version',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remotePayloadSecretIdMeta =
      const VerificationMeta('remotePayloadSecretId');
  @override
  late final GeneratedColumn<String> remotePayloadSecretId =
      GeneratedColumn<String>(
        'remote_payload_secret_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _localPayloadSecretIdMeta =
      const VerificationMeta('localPayloadSecretId');
  @override
  late final GeneratedColumn<String> localPayloadSecretId =
      GeneratedColumn<String>(
        'local_payload_secret_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _localEditedAtMeta = const VerificationMeta(
    'localEditedAt',
  );
  @override
  late final GeneratedColumn<int> localEditedAt = GeneratedColumn<int>(
    'local_edited_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localDeletedMeta = const VerificationMeta(
    'localDeleted',
  );
  @override
  late final GeneratedColumn<bool> localDeleted = GeneratedColumn<bool>(
    'local_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("local_deleted" IN (0, 1))',
    ),
  );
  static const VerificationMeta _localSchemaVersionMeta =
      const VerificationMeta('localSchemaVersion');
  @override
  late final GeneratedColumn<int> localSchemaVersion = GeneratedColumn<int>(
    'local_schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _syncGenerationMeta = const VerificationMeta(
    'syncGeneration',
  );
  @override
  late final GeneratedColumn<String> syncGeneration = GeneratedColumn<String>(
    'sync_generation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pendingMergeMeta = const VerificationMeta(
    'pendingMerge',
  );
  @override
  late final GeneratedColumn<bool> pendingMerge = GeneratedColumn<bool>(
    'pending_merge',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pending_merge" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    documentId,
    accountId,
    recordId,
    type,
    localId,
    remoteRevision,
    remoteEditedAt,
    remoteDeleted,
    remoteSchemaVersion,
    remotePayloadSecretId,
    localPayloadSecretId,
    localEditedAt,
    localDeleted,
    localSchemaVersion,
    syncGeneration,
    pendingMerge,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncDocumentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('local_id')) {
      context.handle(
        _localIdMeta,
        localId.isAcceptableOrUnknown(data['local_id']!, _localIdMeta),
      );
    }
    if (data.containsKey('remote_revision')) {
      context.handle(
        _remoteRevisionMeta,
        remoteRevision.isAcceptableOrUnknown(
          data['remote_revision']!,
          _remoteRevisionMeta,
        ),
      );
    }
    if (data.containsKey('remote_edited_at')) {
      context.handle(
        _remoteEditedAtMeta,
        remoteEditedAt.isAcceptableOrUnknown(
          data['remote_edited_at']!,
          _remoteEditedAtMeta,
        ),
      );
    }
    if (data.containsKey('remote_deleted')) {
      context.handle(
        _remoteDeletedMeta,
        remoteDeleted.isAcceptableOrUnknown(
          data['remote_deleted']!,
          _remoteDeletedMeta,
        ),
      );
    }
    if (data.containsKey('remote_schema_version')) {
      context.handle(
        _remoteSchemaVersionMeta,
        remoteSchemaVersion.isAcceptableOrUnknown(
          data['remote_schema_version']!,
          _remoteSchemaVersionMeta,
        ),
      );
    }
    if (data.containsKey('remote_payload_secret_id')) {
      context.handle(
        _remotePayloadSecretIdMeta,
        remotePayloadSecretId.isAcceptableOrUnknown(
          data['remote_payload_secret_id']!,
          _remotePayloadSecretIdMeta,
        ),
      );
    }
    if (data.containsKey('local_payload_secret_id')) {
      context.handle(
        _localPayloadSecretIdMeta,
        localPayloadSecretId.isAcceptableOrUnknown(
          data['local_payload_secret_id']!,
          _localPayloadSecretIdMeta,
        ),
      );
    }
    if (data.containsKey('local_edited_at')) {
      context.handle(
        _localEditedAtMeta,
        localEditedAt.isAcceptableOrUnknown(
          data['local_edited_at']!,
          _localEditedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localEditedAtMeta);
    }
    if (data.containsKey('local_deleted')) {
      context.handle(
        _localDeletedMeta,
        localDeleted.isAcceptableOrUnknown(
          data['local_deleted']!,
          _localDeletedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localDeletedMeta);
    }
    if (data.containsKey('local_schema_version')) {
      context.handle(
        _localSchemaVersionMeta,
        localSchemaVersion.isAcceptableOrUnknown(
          data['local_schema_version']!,
          _localSchemaVersionMeta,
        ),
      );
    }
    if (data.containsKey('sync_generation')) {
      context.handle(
        _syncGenerationMeta,
        syncGeneration.isAcceptableOrUnknown(
          data['sync_generation']!,
          _syncGenerationMeta,
        ),
      );
    }
    if (data.containsKey('pending_merge')) {
      context.handle(
        _pendingMergeMeta,
        pendingMerge.isAcceptableOrUnknown(
          data['pending_merge']!,
          _pendingMergeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {documentId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {accountId, recordId},
  ];
  @override
  SyncDocumentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncDocumentRow(
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      ),
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      localId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_id'],
      ),
      remoteRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remote_revision'],
      ),
      remoteEditedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remote_edited_at'],
      ),
      remoteDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}remote_deleted'],
      ),
      remoteSchemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}remote_schema_version'],
      ),
      remotePayloadSecretId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_payload_secret_id'],
      ),
      localPayloadSecretId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_payload_secret_id'],
      ),
      localEditedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_edited_at'],
      )!,
      localDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}local_deleted'],
      )!,
      localSchemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}local_schema_version'],
      )!,
      syncGeneration: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_generation'],
      ),
      pendingMerge: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pending_merge'],
      )!,
    );
  }

  @override
  $SyncDocumentsTable createAlias(String alias) {
    return $SyncDocumentsTable(attachedDatabase, alias);
  }
}

class SyncDocumentRow extends DataClass implements Insertable<SyncDocumentRow> {
  final String documentId;
  final String? accountId;
  final String recordId;
  final String type;
  final String? localId;
  final int? remoteRevision;
  final int? remoteEditedAt;
  final bool? remoteDeleted;
  final int? remoteSchemaVersion;
  final String? remotePayloadSecretId;
  final String? localPayloadSecretId;
  final int localEditedAt;
  final bool localDeleted;
  final int localSchemaVersion;
  final String? syncGeneration;

  /// A genuine local change retained across Cloud generations. An unchanged
  /// old mirror never becomes an upload merely because its generation ended.
  final bool pendingMerge;
  const SyncDocumentRow({
    required this.documentId,
    this.accountId,
    required this.recordId,
    required this.type,
    this.localId,
    this.remoteRevision,
    this.remoteEditedAt,
    this.remoteDeleted,
    this.remoteSchemaVersion,
    this.remotePayloadSecretId,
    this.localPayloadSecretId,
    required this.localEditedAt,
    required this.localDeleted,
    required this.localSchemaVersion,
    this.syncGeneration,
    required this.pendingMerge,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['document_id'] = Variable<String>(documentId);
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<String>(accountId);
    }
    map['record_id'] = Variable<String>(recordId);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || localId != null) {
      map['local_id'] = Variable<String>(localId);
    }
    if (!nullToAbsent || remoteRevision != null) {
      map['remote_revision'] = Variable<int>(remoteRevision);
    }
    if (!nullToAbsent || remoteEditedAt != null) {
      map['remote_edited_at'] = Variable<int>(remoteEditedAt);
    }
    if (!nullToAbsent || remoteDeleted != null) {
      map['remote_deleted'] = Variable<bool>(remoteDeleted);
    }
    if (!nullToAbsent || remoteSchemaVersion != null) {
      map['remote_schema_version'] = Variable<int>(remoteSchemaVersion);
    }
    if (!nullToAbsent || remotePayloadSecretId != null) {
      map['remote_payload_secret_id'] = Variable<String>(remotePayloadSecretId);
    }
    if (!nullToAbsent || localPayloadSecretId != null) {
      map['local_payload_secret_id'] = Variable<String>(localPayloadSecretId);
    }
    map['local_edited_at'] = Variable<int>(localEditedAt);
    map['local_deleted'] = Variable<bool>(localDeleted);
    map['local_schema_version'] = Variable<int>(localSchemaVersion);
    if (!nullToAbsent || syncGeneration != null) {
      map['sync_generation'] = Variable<String>(syncGeneration);
    }
    map['pending_merge'] = Variable<bool>(pendingMerge);
    return map;
  }

  SyncDocumentsCompanion toCompanion(bool nullToAbsent) {
    return SyncDocumentsCompanion(
      documentId: Value(documentId),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      recordId: Value(recordId),
      type: Value(type),
      localId: localId == null && nullToAbsent
          ? const Value.absent()
          : Value(localId),
      remoteRevision: remoteRevision == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteRevision),
      remoteEditedAt: remoteEditedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteEditedAt),
      remoteDeleted: remoteDeleted == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteDeleted),
      remoteSchemaVersion: remoteSchemaVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteSchemaVersion),
      remotePayloadSecretId: remotePayloadSecretId == null && nullToAbsent
          ? const Value.absent()
          : Value(remotePayloadSecretId),
      localPayloadSecretId: localPayloadSecretId == null && nullToAbsent
          ? const Value.absent()
          : Value(localPayloadSecretId),
      localEditedAt: Value(localEditedAt),
      localDeleted: Value(localDeleted),
      localSchemaVersion: Value(localSchemaVersion),
      syncGeneration: syncGeneration == null && nullToAbsent
          ? const Value.absent()
          : Value(syncGeneration),
      pendingMerge: Value(pendingMerge),
    );
  }

  factory SyncDocumentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncDocumentRow(
      documentId: serializer.fromJson<String>(json['documentId']),
      accountId: serializer.fromJson<String?>(json['accountId']),
      recordId: serializer.fromJson<String>(json['recordId']),
      type: serializer.fromJson<String>(json['type']),
      localId: serializer.fromJson<String?>(json['localId']),
      remoteRevision: serializer.fromJson<int?>(json['remoteRevision']),
      remoteEditedAt: serializer.fromJson<int?>(json['remoteEditedAt']),
      remoteDeleted: serializer.fromJson<bool?>(json['remoteDeleted']),
      remoteSchemaVersion: serializer.fromJson<int?>(
        json['remoteSchemaVersion'],
      ),
      remotePayloadSecretId: serializer.fromJson<String?>(
        json['remotePayloadSecretId'],
      ),
      localPayloadSecretId: serializer.fromJson<String?>(
        json['localPayloadSecretId'],
      ),
      localEditedAt: serializer.fromJson<int>(json['localEditedAt']),
      localDeleted: serializer.fromJson<bool>(json['localDeleted']),
      localSchemaVersion: serializer.fromJson<int>(json['localSchemaVersion']),
      syncGeneration: serializer.fromJson<String?>(json['syncGeneration']),
      pendingMerge: serializer.fromJson<bool>(json['pendingMerge']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'documentId': serializer.toJson<String>(documentId),
      'accountId': serializer.toJson<String?>(accountId),
      'recordId': serializer.toJson<String>(recordId),
      'type': serializer.toJson<String>(type),
      'localId': serializer.toJson<String?>(localId),
      'remoteRevision': serializer.toJson<int?>(remoteRevision),
      'remoteEditedAt': serializer.toJson<int?>(remoteEditedAt),
      'remoteDeleted': serializer.toJson<bool?>(remoteDeleted),
      'remoteSchemaVersion': serializer.toJson<int?>(remoteSchemaVersion),
      'remotePayloadSecretId': serializer.toJson<String?>(
        remotePayloadSecretId,
      ),
      'localPayloadSecretId': serializer.toJson<String?>(localPayloadSecretId),
      'localEditedAt': serializer.toJson<int>(localEditedAt),
      'localDeleted': serializer.toJson<bool>(localDeleted),
      'localSchemaVersion': serializer.toJson<int>(localSchemaVersion),
      'syncGeneration': serializer.toJson<String?>(syncGeneration),
      'pendingMerge': serializer.toJson<bool>(pendingMerge),
    };
  }

  SyncDocumentRow copyWith({
    String? documentId,
    Value<String?> accountId = const Value.absent(),
    String? recordId,
    String? type,
    Value<String?> localId = const Value.absent(),
    Value<int?> remoteRevision = const Value.absent(),
    Value<int?> remoteEditedAt = const Value.absent(),
    Value<bool?> remoteDeleted = const Value.absent(),
    Value<int?> remoteSchemaVersion = const Value.absent(),
    Value<String?> remotePayloadSecretId = const Value.absent(),
    Value<String?> localPayloadSecretId = const Value.absent(),
    int? localEditedAt,
    bool? localDeleted,
    int? localSchemaVersion,
    Value<String?> syncGeneration = const Value.absent(),
    bool? pendingMerge,
  }) => SyncDocumentRow(
    documentId: documentId ?? this.documentId,
    accountId: accountId.present ? accountId.value : this.accountId,
    recordId: recordId ?? this.recordId,
    type: type ?? this.type,
    localId: localId.present ? localId.value : this.localId,
    remoteRevision: remoteRevision.present
        ? remoteRevision.value
        : this.remoteRevision,
    remoteEditedAt: remoteEditedAt.present
        ? remoteEditedAt.value
        : this.remoteEditedAt,
    remoteDeleted: remoteDeleted.present
        ? remoteDeleted.value
        : this.remoteDeleted,
    remoteSchemaVersion: remoteSchemaVersion.present
        ? remoteSchemaVersion.value
        : this.remoteSchemaVersion,
    remotePayloadSecretId: remotePayloadSecretId.present
        ? remotePayloadSecretId.value
        : this.remotePayloadSecretId,
    localPayloadSecretId: localPayloadSecretId.present
        ? localPayloadSecretId.value
        : this.localPayloadSecretId,
    localEditedAt: localEditedAt ?? this.localEditedAt,
    localDeleted: localDeleted ?? this.localDeleted,
    localSchemaVersion: localSchemaVersion ?? this.localSchemaVersion,
    syncGeneration: syncGeneration.present
        ? syncGeneration.value
        : this.syncGeneration,
    pendingMerge: pendingMerge ?? this.pendingMerge,
  );
  SyncDocumentRow copyWithCompanion(SyncDocumentsCompanion data) {
    return SyncDocumentRow(
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      type: data.type.present ? data.type.value : this.type,
      localId: data.localId.present ? data.localId.value : this.localId,
      remoteRevision: data.remoteRevision.present
          ? data.remoteRevision.value
          : this.remoteRevision,
      remoteEditedAt: data.remoteEditedAt.present
          ? data.remoteEditedAt.value
          : this.remoteEditedAt,
      remoteDeleted: data.remoteDeleted.present
          ? data.remoteDeleted.value
          : this.remoteDeleted,
      remoteSchemaVersion: data.remoteSchemaVersion.present
          ? data.remoteSchemaVersion.value
          : this.remoteSchemaVersion,
      remotePayloadSecretId: data.remotePayloadSecretId.present
          ? data.remotePayloadSecretId.value
          : this.remotePayloadSecretId,
      localPayloadSecretId: data.localPayloadSecretId.present
          ? data.localPayloadSecretId.value
          : this.localPayloadSecretId,
      localEditedAt: data.localEditedAt.present
          ? data.localEditedAt.value
          : this.localEditedAt,
      localDeleted: data.localDeleted.present
          ? data.localDeleted.value
          : this.localDeleted,
      localSchemaVersion: data.localSchemaVersion.present
          ? data.localSchemaVersion.value
          : this.localSchemaVersion,
      syncGeneration: data.syncGeneration.present
          ? data.syncGeneration.value
          : this.syncGeneration,
      pendingMerge: data.pendingMerge.present
          ? data.pendingMerge.value
          : this.pendingMerge,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncDocumentRow(')
          ..write('documentId: $documentId, ')
          ..write('accountId: $accountId, ')
          ..write('recordId: $recordId, ')
          ..write('type: $type, ')
          ..write('localId: $localId, ')
          ..write('remoteRevision: $remoteRevision, ')
          ..write('remoteEditedAt: $remoteEditedAt, ')
          ..write('remoteDeleted: $remoteDeleted, ')
          ..write('remoteSchemaVersion: $remoteSchemaVersion, ')
          ..write('remotePayloadSecretId: $remotePayloadSecretId, ')
          ..write('localPayloadSecretId: $localPayloadSecretId, ')
          ..write('localEditedAt: $localEditedAt, ')
          ..write('localDeleted: $localDeleted, ')
          ..write('localSchemaVersion: $localSchemaVersion, ')
          ..write('syncGeneration: $syncGeneration, ')
          ..write('pendingMerge: $pendingMerge')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    documentId,
    accountId,
    recordId,
    type,
    localId,
    remoteRevision,
    remoteEditedAt,
    remoteDeleted,
    remoteSchemaVersion,
    remotePayloadSecretId,
    localPayloadSecretId,
    localEditedAt,
    localDeleted,
    localSchemaVersion,
    syncGeneration,
    pendingMerge,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncDocumentRow &&
          other.documentId == this.documentId &&
          other.accountId == this.accountId &&
          other.recordId == this.recordId &&
          other.type == this.type &&
          other.localId == this.localId &&
          other.remoteRevision == this.remoteRevision &&
          other.remoteEditedAt == this.remoteEditedAt &&
          other.remoteDeleted == this.remoteDeleted &&
          other.remoteSchemaVersion == this.remoteSchemaVersion &&
          other.remotePayloadSecretId == this.remotePayloadSecretId &&
          other.localPayloadSecretId == this.localPayloadSecretId &&
          other.localEditedAt == this.localEditedAt &&
          other.localDeleted == this.localDeleted &&
          other.localSchemaVersion == this.localSchemaVersion &&
          other.syncGeneration == this.syncGeneration &&
          other.pendingMerge == this.pendingMerge);
}

class SyncDocumentsCompanion extends UpdateCompanion<SyncDocumentRow> {
  final Value<String> documentId;
  final Value<String?> accountId;
  final Value<String> recordId;
  final Value<String> type;
  final Value<String?> localId;
  final Value<int?> remoteRevision;
  final Value<int?> remoteEditedAt;
  final Value<bool?> remoteDeleted;
  final Value<int?> remoteSchemaVersion;
  final Value<String?> remotePayloadSecretId;
  final Value<String?> localPayloadSecretId;
  final Value<int> localEditedAt;
  final Value<bool> localDeleted;
  final Value<int> localSchemaVersion;
  final Value<String?> syncGeneration;
  final Value<bool> pendingMerge;
  final Value<int> rowid;
  const SyncDocumentsCompanion({
    this.documentId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.recordId = const Value.absent(),
    this.type = const Value.absent(),
    this.localId = const Value.absent(),
    this.remoteRevision = const Value.absent(),
    this.remoteEditedAt = const Value.absent(),
    this.remoteDeleted = const Value.absent(),
    this.remoteSchemaVersion = const Value.absent(),
    this.remotePayloadSecretId = const Value.absent(),
    this.localPayloadSecretId = const Value.absent(),
    this.localEditedAt = const Value.absent(),
    this.localDeleted = const Value.absent(),
    this.localSchemaVersion = const Value.absent(),
    this.syncGeneration = const Value.absent(),
    this.pendingMerge = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncDocumentsCompanion.insert({
    required String documentId,
    this.accountId = const Value.absent(),
    required String recordId,
    required String type,
    this.localId = const Value.absent(),
    this.remoteRevision = const Value.absent(),
    this.remoteEditedAt = const Value.absent(),
    this.remoteDeleted = const Value.absent(),
    this.remoteSchemaVersion = const Value.absent(),
    this.remotePayloadSecretId = const Value.absent(),
    this.localPayloadSecretId = const Value.absent(),
    required int localEditedAt,
    required bool localDeleted,
    this.localSchemaVersion = const Value.absent(),
    this.syncGeneration = const Value.absent(),
    this.pendingMerge = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : documentId = Value(documentId),
       recordId = Value(recordId),
       type = Value(type),
       localEditedAt = Value(localEditedAt),
       localDeleted = Value(localDeleted);
  static Insertable<SyncDocumentRow> custom({
    Expression<String>? documentId,
    Expression<String>? accountId,
    Expression<String>? recordId,
    Expression<String>? type,
    Expression<String>? localId,
    Expression<int>? remoteRevision,
    Expression<int>? remoteEditedAt,
    Expression<bool>? remoteDeleted,
    Expression<int>? remoteSchemaVersion,
    Expression<String>? remotePayloadSecretId,
    Expression<String>? localPayloadSecretId,
    Expression<int>? localEditedAt,
    Expression<bool>? localDeleted,
    Expression<int>? localSchemaVersion,
    Expression<String>? syncGeneration,
    Expression<bool>? pendingMerge,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (documentId != null) 'document_id': documentId,
      if (accountId != null) 'account_id': accountId,
      if (recordId != null) 'record_id': recordId,
      if (type != null) 'type': type,
      if (localId != null) 'local_id': localId,
      if (remoteRevision != null) 'remote_revision': remoteRevision,
      if (remoteEditedAt != null) 'remote_edited_at': remoteEditedAt,
      if (remoteDeleted != null) 'remote_deleted': remoteDeleted,
      if (remoteSchemaVersion != null)
        'remote_schema_version': remoteSchemaVersion,
      if (remotePayloadSecretId != null)
        'remote_payload_secret_id': remotePayloadSecretId,
      if (localPayloadSecretId != null)
        'local_payload_secret_id': localPayloadSecretId,
      if (localEditedAt != null) 'local_edited_at': localEditedAt,
      if (localDeleted != null) 'local_deleted': localDeleted,
      if (localSchemaVersion != null)
        'local_schema_version': localSchemaVersion,
      if (syncGeneration != null) 'sync_generation': syncGeneration,
      if (pendingMerge != null) 'pending_merge': pendingMerge,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncDocumentsCompanion copyWith({
    Value<String>? documentId,
    Value<String?>? accountId,
    Value<String>? recordId,
    Value<String>? type,
    Value<String?>? localId,
    Value<int?>? remoteRevision,
    Value<int?>? remoteEditedAt,
    Value<bool?>? remoteDeleted,
    Value<int?>? remoteSchemaVersion,
    Value<String?>? remotePayloadSecretId,
    Value<String?>? localPayloadSecretId,
    Value<int>? localEditedAt,
    Value<bool>? localDeleted,
    Value<int>? localSchemaVersion,
    Value<String?>? syncGeneration,
    Value<bool>? pendingMerge,
    Value<int>? rowid,
  }) {
    return SyncDocumentsCompanion(
      documentId: documentId ?? this.documentId,
      accountId: accountId ?? this.accountId,
      recordId: recordId ?? this.recordId,
      type: type ?? this.type,
      localId: localId ?? this.localId,
      remoteRevision: remoteRevision ?? this.remoteRevision,
      remoteEditedAt: remoteEditedAt ?? this.remoteEditedAt,
      remoteDeleted: remoteDeleted ?? this.remoteDeleted,
      remoteSchemaVersion: remoteSchemaVersion ?? this.remoteSchemaVersion,
      remotePayloadSecretId:
          remotePayloadSecretId ?? this.remotePayloadSecretId,
      localPayloadSecretId: localPayloadSecretId ?? this.localPayloadSecretId,
      localEditedAt: localEditedAt ?? this.localEditedAt,
      localDeleted: localDeleted ?? this.localDeleted,
      localSchemaVersion: localSchemaVersion ?? this.localSchemaVersion,
      syncGeneration: syncGeneration ?? this.syncGeneration,
      pendingMerge: pendingMerge ?? this.pendingMerge,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (localId.present) {
      map['local_id'] = Variable<String>(localId.value);
    }
    if (remoteRevision.present) {
      map['remote_revision'] = Variable<int>(remoteRevision.value);
    }
    if (remoteEditedAt.present) {
      map['remote_edited_at'] = Variable<int>(remoteEditedAt.value);
    }
    if (remoteDeleted.present) {
      map['remote_deleted'] = Variable<bool>(remoteDeleted.value);
    }
    if (remoteSchemaVersion.present) {
      map['remote_schema_version'] = Variable<int>(remoteSchemaVersion.value);
    }
    if (remotePayloadSecretId.present) {
      map['remote_payload_secret_id'] = Variable<String>(
        remotePayloadSecretId.value,
      );
    }
    if (localPayloadSecretId.present) {
      map['local_payload_secret_id'] = Variable<String>(
        localPayloadSecretId.value,
      );
    }
    if (localEditedAt.present) {
      map['local_edited_at'] = Variable<int>(localEditedAt.value);
    }
    if (localDeleted.present) {
      map['local_deleted'] = Variable<bool>(localDeleted.value);
    }
    if (localSchemaVersion.present) {
      map['local_schema_version'] = Variable<int>(localSchemaVersion.value);
    }
    if (syncGeneration.present) {
      map['sync_generation'] = Variable<String>(syncGeneration.value);
    }
    if (pendingMerge.present) {
      map['pending_merge'] = Variable<bool>(pendingMerge.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncDocumentsCompanion(')
          ..write('documentId: $documentId, ')
          ..write('accountId: $accountId, ')
          ..write('recordId: $recordId, ')
          ..write('type: $type, ')
          ..write('localId: $localId, ')
          ..write('remoteRevision: $remoteRevision, ')
          ..write('remoteEditedAt: $remoteEditedAt, ')
          ..write('remoteDeleted: $remoteDeleted, ')
          ..write('remoteSchemaVersion: $remoteSchemaVersion, ')
          ..write('remotePayloadSecretId: $remotePayloadSecretId, ')
          ..write('localPayloadSecretId: $localPayloadSecretId, ')
          ..write('localEditedAt: $localEditedAt, ')
          ..write('localDeleted: $localDeleted, ')
          ..write('localSchemaVersion: $localSchemaVersion, ')
          ..write('syncGeneration: $syncGeneration, ')
          ..write('pendingMerge: $pendingMerge, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SourceProvenanceTable extends SourceProvenance
    with TableInfo<$SourceProvenanceTable, SourceProvenanceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SourceProvenanceTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originMeta = const VerificationMeta('origin');
  @override
  late final GeneratedColumn<String> origin = GeneratedColumn<String>(
    'origin',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originAccountIdMeta = const VerificationMeta(
    'originAccountId',
  );
  @override
  late final GeneratedColumn<String> originAccountId = GeneratedColumn<String>(
    'origin_account_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceGenerationMeta = const VerificationMeta(
    'sourceGeneration',
  );
  @override
  late final GeneratedColumn<String> sourceGeneration = GeneratedColumn<String>(
    'source_generation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _privateConsentGenerationMeta =
      const VerificationMeta('privateConsentGeneration');
  @override
  late final GeneratedColumn<String> privateConsentGeneration =
      GeneratedColumn<String>(
        'private_consent_generation',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    documentId,
    origin,
    originAccountId,
    sourceGeneration,
    privateConsentGeneration,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'source_provenance';
  @override
  VerificationContext validateIntegrity(
    Insertable<SourceProvenanceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('origin')) {
      context.handle(
        _originMeta,
        origin.isAcceptableOrUnknown(data['origin']!, _originMeta),
      );
    } else if (isInserting) {
      context.missing(_originMeta);
    }
    if (data.containsKey('origin_account_id')) {
      context.handle(
        _originAccountIdMeta,
        originAccountId.isAcceptableOrUnknown(
          data['origin_account_id']!,
          _originAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('source_generation')) {
      context.handle(
        _sourceGenerationMeta,
        sourceGeneration.isAcceptableOrUnknown(
          data['source_generation']!,
          _sourceGenerationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceGenerationMeta);
    }
    if (data.containsKey('private_consent_generation')) {
      context.handle(
        _privateConsentGenerationMeta,
        privateConsentGeneration.isAcceptableOrUnknown(
          data['private_consent_generation']!,
          _privateConsentGenerationMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {documentId};
  @override
  SourceProvenanceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SourceProvenanceRow(
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      origin: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin'],
      )!,
      originAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}origin_account_id'],
      ),
      sourceGeneration: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_generation'],
      )!,
      privateConsentGeneration: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}private_consent_generation'],
      ),
    );
  }

  @override
  $SourceProvenanceTable createAlias(String alias) {
    return $SourceProvenanceTable(attachedDatabase, alias);
  }
}

class SourceProvenanceRow extends DataClass
    implements Insertable<SourceProvenanceRow> {
  final String documentId;
  final String origin;
  final String? originAccountId;
  final String sourceGeneration;
  final String? privateConsentGeneration;
  const SourceProvenanceRow({
    required this.documentId,
    required this.origin,
    this.originAccountId,
    required this.sourceGeneration,
    this.privateConsentGeneration,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['document_id'] = Variable<String>(documentId);
    map['origin'] = Variable<String>(origin);
    if (!nullToAbsent || originAccountId != null) {
      map['origin_account_id'] = Variable<String>(originAccountId);
    }
    map['source_generation'] = Variable<String>(sourceGeneration);
    if (!nullToAbsent || privateConsentGeneration != null) {
      map['private_consent_generation'] = Variable<String>(
        privateConsentGeneration,
      );
    }
    return map;
  }

  SourceProvenanceCompanion toCompanion(bool nullToAbsent) {
    return SourceProvenanceCompanion(
      documentId: Value(documentId),
      origin: Value(origin),
      originAccountId: originAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(originAccountId),
      sourceGeneration: Value(sourceGeneration),
      privateConsentGeneration: privateConsentGeneration == null && nullToAbsent
          ? const Value.absent()
          : Value(privateConsentGeneration),
    );
  }

  factory SourceProvenanceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SourceProvenanceRow(
      documentId: serializer.fromJson<String>(json['documentId']),
      origin: serializer.fromJson<String>(json['origin']),
      originAccountId: serializer.fromJson<String?>(json['originAccountId']),
      sourceGeneration: serializer.fromJson<String>(json['sourceGeneration']),
      privateConsentGeneration: serializer.fromJson<String?>(
        json['privateConsentGeneration'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'documentId': serializer.toJson<String>(documentId),
      'origin': serializer.toJson<String>(origin),
      'originAccountId': serializer.toJson<String?>(originAccountId),
      'sourceGeneration': serializer.toJson<String>(sourceGeneration),
      'privateConsentGeneration': serializer.toJson<String?>(
        privateConsentGeneration,
      ),
    };
  }

  SourceProvenanceRow copyWith({
    String? documentId,
    String? origin,
    Value<String?> originAccountId = const Value.absent(),
    String? sourceGeneration,
    Value<String?> privateConsentGeneration = const Value.absent(),
  }) => SourceProvenanceRow(
    documentId: documentId ?? this.documentId,
    origin: origin ?? this.origin,
    originAccountId: originAccountId.present
        ? originAccountId.value
        : this.originAccountId,
    sourceGeneration: sourceGeneration ?? this.sourceGeneration,
    privateConsentGeneration: privateConsentGeneration.present
        ? privateConsentGeneration.value
        : this.privateConsentGeneration,
  );
  SourceProvenanceRow copyWithCompanion(SourceProvenanceCompanion data) {
    return SourceProvenanceRow(
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      origin: data.origin.present ? data.origin.value : this.origin,
      originAccountId: data.originAccountId.present
          ? data.originAccountId.value
          : this.originAccountId,
      sourceGeneration: data.sourceGeneration.present
          ? data.sourceGeneration.value
          : this.sourceGeneration,
      privateConsentGeneration: data.privateConsentGeneration.present
          ? data.privateConsentGeneration.value
          : this.privateConsentGeneration,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SourceProvenanceRow(')
          ..write('documentId: $documentId, ')
          ..write('origin: $origin, ')
          ..write('originAccountId: $originAccountId, ')
          ..write('sourceGeneration: $sourceGeneration, ')
          ..write('privateConsentGeneration: $privateConsentGeneration')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    documentId,
    origin,
    originAccountId,
    sourceGeneration,
    privateConsentGeneration,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SourceProvenanceRow &&
          other.documentId == this.documentId &&
          other.origin == this.origin &&
          other.originAccountId == this.originAccountId &&
          other.sourceGeneration == this.sourceGeneration &&
          other.privateConsentGeneration == this.privateConsentGeneration);
}

class SourceProvenanceCompanion extends UpdateCompanion<SourceProvenanceRow> {
  final Value<String> documentId;
  final Value<String> origin;
  final Value<String?> originAccountId;
  final Value<String> sourceGeneration;
  final Value<String?> privateConsentGeneration;
  final Value<int> rowid;
  const SourceProvenanceCompanion({
    this.documentId = const Value.absent(),
    this.origin = const Value.absent(),
    this.originAccountId = const Value.absent(),
    this.sourceGeneration = const Value.absent(),
    this.privateConsentGeneration = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SourceProvenanceCompanion.insert({
    required String documentId,
    required String origin,
    this.originAccountId = const Value.absent(),
    required String sourceGeneration,
    this.privateConsentGeneration = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : documentId = Value(documentId),
       origin = Value(origin),
       sourceGeneration = Value(sourceGeneration);
  static Insertable<SourceProvenanceRow> custom({
    Expression<String>? documentId,
    Expression<String>? origin,
    Expression<String>? originAccountId,
    Expression<String>? sourceGeneration,
    Expression<String>? privateConsentGeneration,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (documentId != null) 'document_id': documentId,
      if (origin != null) 'origin': origin,
      if (originAccountId != null) 'origin_account_id': originAccountId,
      if (sourceGeneration != null) 'source_generation': sourceGeneration,
      if (privateConsentGeneration != null)
        'private_consent_generation': privateConsentGeneration,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SourceProvenanceCompanion copyWith({
    Value<String>? documentId,
    Value<String>? origin,
    Value<String?>? originAccountId,
    Value<String>? sourceGeneration,
    Value<String?>? privateConsentGeneration,
    Value<int>? rowid,
  }) {
    return SourceProvenanceCompanion(
      documentId: documentId ?? this.documentId,
      origin: origin ?? this.origin,
      originAccountId: originAccountId ?? this.originAccountId,
      sourceGeneration: sourceGeneration ?? this.sourceGeneration,
      privateConsentGeneration:
          privateConsentGeneration ?? this.privateConsentGeneration,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (origin.present) {
      map['origin'] = Variable<String>(origin.value);
    }
    if (originAccountId.present) {
      map['origin_account_id'] = Variable<String>(originAccountId.value);
    }
    if (sourceGeneration.present) {
      map['source_generation'] = Variable<String>(sourceGeneration.value);
    }
    if (privateConsentGeneration.present) {
      map['private_consent_generation'] = Variable<String>(
        privateConsentGeneration.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SourceProvenanceCompanion(')
          ..write('documentId: $documentId, ')
          ..write('origin: $origin, ')
          ..write('originAccountId: $originAccountId, ')
          ..write('sourceGeneration: $sourceGeneration, ')
          ..write('privateConsentGeneration: $privateConsentGeneration, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, SyncStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cursorMeta = const VerificationMeta('cursor');
  @override
  late final GeneratedColumn<int> cursor = GeneratedColumn<int>(
    'cursor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastSyncAtMeta = const VerificationMeta(
    'lastSyncAt',
  );
  @override
  late final GeneratedColumn<int> lastSyncAt = GeneratedColumn<int>(
    'last_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _blockedReasonMeta = const VerificationMeta(
    'blockedReason',
  );
  @override
  late final GeneratedColumn<String> blockedReason = GeneratedColumn<String>(
    'blocked_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bootstrapCompletedMeta =
      const VerificationMeta('bootstrapCompleted');
  @override
  late final GeneratedColumn<bool> bootstrapCompleted = GeneratedColumn<bool>(
    'bootstrap_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("bootstrap_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncGenerationMeta = const VerificationMeta(
    'syncGeneration',
  );
  @override
  late final GeneratedColumn<String> syncGeneration = GeneratedColumn<String>(
    'sync_generation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _backupStateMeta = const VerificationMeta(
    'backupState',
  );
  @override
  late final GeneratedColumn<String> backupState = GeneratedColumn<String>(
    'backup_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('legacy'),
  );
  static const VerificationMeta _rebuildAttemptIdMeta = const VerificationMeta(
    'rebuildAttemptId',
  );
  @override
  late final GeneratedColumn<String> rebuildAttemptId = GeneratedColumn<String>(
    'rebuild_attempt_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rebuildLocalAttemptIdMeta =
      const VerificationMeta('rebuildLocalAttemptId');
  @override
  late final GeneratedColumn<String> rebuildLocalAttemptId =
      GeneratedColumn<String>(
        'rebuild_local_attempt_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _rebuildManifestSecretIdMeta =
      const VerificationMeta('rebuildManifestSecretId');
  @override
  late final GeneratedColumn<String> rebuildManifestSecretId =
      GeneratedColumn<String>(
        'rebuild_manifest_secret_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _rebuildControlSecretIdMeta =
      const VerificationMeta('rebuildControlSecretId');
  @override
  late final GeneratedColumn<String> rebuildControlSecretId =
      GeneratedColumn<String>(
        'rebuild_control_secret_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    cursor,
    lastSyncAt,
    blockedReason,
    bootstrapCompleted,
    syncGeneration,
    backupState,
    rebuildAttemptId,
    rebuildLocalAttemptId,
    rebuildManifestSecretId,
    rebuildControlSecretId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('cursor')) {
      context.handle(
        _cursorMeta,
        cursor.isAcceptableOrUnknown(data['cursor']!, _cursorMeta),
      );
    } else if (isInserting) {
      context.missing(_cursorMeta);
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
        _lastSyncAtMeta,
        lastSyncAt.isAcceptableOrUnknown(
          data['last_sync_at']!,
          _lastSyncAtMeta,
        ),
      );
    }
    if (data.containsKey('blocked_reason')) {
      context.handle(
        _blockedReasonMeta,
        blockedReason.isAcceptableOrUnknown(
          data['blocked_reason']!,
          _blockedReasonMeta,
        ),
      );
    }
    if (data.containsKey('bootstrap_completed')) {
      context.handle(
        _bootstrapCompletedMeta,
        bootstrapCompleted.isAcceptableOrUnknown(
          data['bootstrap_completed']!,
          _bootstrapCompletedMeta,
        ),
      );
    }
    if (data.containsKey('sync_generation')) {
      context.handle(
        _syncGenerationMeta,
        syncGeneration.isAcceptableOrUnknown(
          data['sync_generation']!,
          _syncGenerationMeta,
        ),
      );
    }
    if (data.containsKey('backup_state')) {
      context.handle(
        _backupStateMeta,
        backupState.isAcceptableOrUnknown(
          data['backup_state']!,
          _backupStateMeta,
        ),
      );
    }
    if (data.containsKey('rebuild_attempt_id')) {
      context.handle(
        _rebuildAttemptIdMeta,
        rebuildAttemptId.isAcceptableOrUnknown(
          data['rebuild_attempt_id']!,
          _rebuildAttemptIdMeta,
        ),
      );
    }
    if (data.containsKey('rebuild_local_attempt_id')) {
      context.handle(
        _rebuildLocalAttemptIdMeta,
        rebuildLocalAttemptId.isAcceptableOrUnknown(
          data['rebuild_local_attempt_id']!,
          _rebuildLocalAttemptIdMeta,
        ),
      );
    }
    if (data.containsKey('rebuild_manifest_secret_id')) {
      context.handle(
        _rebuildManifestSecretIdMeta,
        rebuildManifestSecretId.isAcceptableOrUnknown(
          data['rebuild_manifest_secret_id']!,
          _rebuildManifestSecretIdMeta,
        ),
      );
    }
    if (data.containsKey('rebuild_control_secret_id')) {
      context.handle(
        _rebuildControlSecretIdMeta,
        rebuildControlSecretId.isAcceptableOrUnknown(
          data['rebuild_control_secret_id']!,
          _rebuildControlSecretIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId};
  @override
  SyncStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateRow(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      cursor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cursor'],
      )!,
      lastSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_sync_at'],
      ),
      blockedReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}blocked_reason'],
      ),
      bootstrapCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}bootstrap_completed'],
      )!,
      syncGeneration: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_generation'],
      ),
      backupState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}backup_state'],
      )!,
      rebuildAttemptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rebuild_attempt_id'],
      ),
      rebuildLocalAttemptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rebuild_local_attempt_id'],
      ),
      rebuildManifestSecretId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rebuild_manifest_secret_id'],
      ),
      rebuildControlSecretId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rebuild_control_secret_id'],
      ),
    );
  }

  @override
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class SyncStateRow extends DataClass implements Insertable<SyncStateRow> {
  final String accountId;
  final int cursor;
  final int? lastSyncAt;
  final String? blockedReason;
  final bool bootstrapCompleted;
  final String? syncGeneration;
  final String backupState;
  final String? rebuildAttemptId;
  final String? rebuildLocalAttemptId;
  final String? rebuildManifestSecretId;
  final String? rebuildControlSecretId;
  const SyncStateRow({
    required this.accountId,
    required this.cursor,
    this.lastSyncAt,
    this.blockedReason,
    required this.bootstrapCompleted,
    this.syncGeneration,
    required this.backupState,
    this.rebuildAttemptId,
    this.rebuildLocalAttemptId,
    this.rebuildManifestSecretId,
    this.rebuildControlSecretId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['cursor'] = Variable<int>(cursor);
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<int>(lastSyncAt);
    }
    if (!nullToAbsent || blockedReason != null) {
      map['blocked_reason'] = Variable<String>(blockedReason);
    }
    map['bootstrap_completed'] = Variable<bool>(bootstrapCompleted);
    if (!nullToAbsent || syncGeneration != null) {
      map['sync_generation'] = Variable<String>(syncGeneration);
    }
    map['backup_state'] = Variable<String>(backupState);
    if (!nullToAbsent || rebuildAttemptId != null) {
      map['rebuild_attempt_id'] = Variable<String>(rebuildAttemptId);
    }
    if (!nullToAbsent || rebuildLocalAttemptId != null) {
      map['rebuild_local_attempt_id'] = Variable<String>(rebuildLocalAttemptId);
    }
    if (!nullToAbsent || rebuildManifestSecretId != null) {
      map['rebuild_manifest_secret_id'] = Variable<String>(
        rebuildManifestSecretId,
      );
    }
    if (!nullToAbsent || rebuildControlSecretId != null) {
      map['rebuild_control_secret_id'] = Variable<String>(
        rebuildControlSecretId,
      );
    }
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(
      accountId: Value(accountId),
      cursor: Value(cursor),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
      blockedReason: blockedReason == null && nullToAbsent
          ? const Value.absent()
          : Value(blockedReason),
      bootstrapCompleted: Value(bootstrapCompleted),
      syncGeneration: syncGeneration == null && nullToAbsent
          ? const Value.absent()
          : Value(syncGeneration),
      backupState: Value(backupState),
      rebuildAttemptId: rebuildAttemptId == null && nullToAbsent
          ? const Value.absent()
          : Value(rebuildAttemptId),
      rebuildLocalAttemptId: rebuildLocalAttemptId == null && nullToAbsent
          ? const Value.absent()
          : Value(rebuildLocalAttemptId),
      rebuildManifestSecretId: rebuildManifestSecretId == null && nullToAbsent
          ? const Value.absent()
          : Value(rebuildManifestSecretId),
      rebuildControlSecretId: rebuildControlSecretId == null && nullToAbsent
          ? const Value.absent()
          : Value(rebuildControlSecretId),
    );
  }

  factory SyncStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateRow(
      accountId: serializer.fromJson<String>(json['accountId']),
      cursor: serializer.fromJson<int>(json['cursor']),
      lastSyncAt: serializer.fromJson<int?>(json['lastSyncAt']),
      blockedReason: serializer.fromJson<String?>(json['blockedReason']),
      bootstrapCompleted: serializer.fromJson<bool>(json['bootstrapCompleted']),
      syncGeneration: serializer.fromJson<String?>(json['syncGeneration']),
      backupState: serializer.fromJson<String>(json['backupState']),
      rebuildAttemptId: serializer.fromJson<String?>(json['rebuildAttemptId']),
      rebuildLocalAttemptId: serializer.fromJson<String?>(
        json['rebuildLocalAttemptId'],
      ),
      rebuildManifestSecretId: serializer.fromJson<String?>(
        json['rebuildManifestSecretId'],
      ),
      rebuildControlSecretId: serializer.fromJson<String?>(
        json['rebuildControlSecretId'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'cursor': serializer.toJson<int>(cursor),
      'lastSyncAt': serializer.toJson<int?>(lastSyncAt),
      'blockedReason': serializer.toJson<String?>(blockedReason),
      'bootstrapCompleted': serializer.toJson<bool>(bootstrapCompleted),
      'syncGeneration': serializer.toJson<String?>(syncGeneration),
      'backupState': serializer.toJson<String>(backupState),
      'rebuildAttemptId': serializer.toJson<String?>(rebuildAttemptId),
      'rebuildLocalAttemptId': serializer.toJson<String?>(
        rebuildLocalAttemptId,
      ),
      'rebuildManifestSecretId': serializer.toJson<String?>(
        rebuildManifestSecretId,
      ),
      'rebuildControlSecretId': serializer.toJson<String?>(
        rebuildControlSecretId,
      ),
    };
  }

  SyncStateRow copyWith({
    String? accountId,
    int? cursor,
    Value<int?> lastSyncAt = const Value.absent(),
    Value<String?> blockedReason = const Value.absent(),
    bool? bootstrapCompleted,
    Value<String?> syncGeneration = const Value.absent(),
    String? backupState,
    Value<String?> rebuildAttemptId = const Value.absent(),
    Value<String?> rebuildLocalAttemptId = const Value.absent(),
    Value<String?> rebuildManifestSecretId = const Value.absent(),
    Value<String?> rebuildControlSecretId = const Value.absent(),
  }) => SyncStateRow(
    accountId: accountId ?? this.accountId,
    cursor: cursor ?? this.cursor,
    lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
    blockedReason: blockedReason.present
        ? blockedReason.value
        : this.blockedReason,
    bootstrapCompleted: bootstrapCompleted ?? this.bootstrapCompleted,
    syncGeneration: syncGeneration.present
        ? syncGeneration.value
        : this.syncGeneration,
    backupState: backupState ?? this.backupState,
    rebuildAttemptId: rebuildAttemptId.present
        ? rebuildAttemptId.value
        : this.rebuildAttemptId,
    rebuildLocalAttemptId: rebuildLocalAttemptId.present
        ? rebuildLocalAttemptId.value
        : this.rebuildLocalAttemptId,
    rebuildManifestSecretId: rebuildManifestSecretId.present
        ? rebuildManifestSecretId.value
        : this.rebuildManifestSecretId,
    rebuildControlSecretId: rebuildControlSecretId.present
        ? rebuildControlSecretId.value
        : this.rebuildControlSecretId,
  );
  SyncStateRow copyWithCompanion(SyncStateCompanion data) {
    return SyncStateRow(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      cursor: data.cursor.present ? data.cursor.value : this.cursor,
      lastSyncAt: data.lastSyncAt.present
          ? data.lastSyncAt.value
          : this.lastSyncAt,
      blockedReason: data.blockedReason.present
          ? data.blockedReason.value
          : this.blockedReason,
      bootstrapCompleted: data.bootstrapCompleted.present
          ? data.bootstrapCompleted.value
          : this.bootstrapCompleted,
      syncGeneration: data.syncGeneration.present
          ? data.syncGeneration.value
          : this.syncGeneration,
      backupState: data.backupState.present
          ? data.backupState.value
          : this.backupState,
      rebuildAttemptId: data.rebuildAttemptId.present
          ? data.rebuildAttemptId.value
          : this.rebuildAttemptId,
      rebuildLocalAttemptId: data.rebuildLocalAttemptId.present
          ? data.rebuildLocalAttemptId.value
          : this.rebuildLocalAttemptId,
      rebuildManifestSecretId: data.rebuildManifestSecretId.present
          ? data.rebuildManifestSecretId.value
          : this.rebuildManifestSecretId,
      rebuildControlSecretId: data.rebuildControlSecretId.present
          ? data.rebuildControlSecretId.value
          : this.rebuildControlSecretId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateRow(')
          ..write('accountId: $accountId, ')
          ..write('cursor: $cursor, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('blockedReason: $blockedReason, ')
          ..write('bootstrapCompleted: $bootstrapCompleted, ')
          ..write('syncGeneration: $syncGeneration, ')
          ..write('backupState: $backupState, ')
          ..write('rebuildAttemptId: $rebuildAttemptId, ')
          ..write('rebuildLocalAttemptId: $rebuildLocalAttemptId, ')
          ..write('rebuildManifestSecretId: $rebuildManifestSecretId, ')
          ..write('rebuildControlSecretId: $rebuildControlSecretId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    accountId,
    cursor,
    lastSyncAt,
    blockedReason,
    bootstrapCompleted,
    syncGeneration,
    backupState,
    rebuildAttemptId,
    rebuildLocalAttemptId,
    rebuildManifestSecretId,
    rebuildControlSecretId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateRow &&
          other.accountId == this.accountId &&
          other.cursor == this.cursor &&
          other.lastSyncAt == this.lastSyncAt &&
          other.blockedReason == this.blockedReason &&
          other.bootstrapCompleted == this.bootstrapCompleted &&
          other.syncGeneration == this.syncGeneration &&
          other.backupState == this.backupState &&
          other.rebuildAttemptId == this.rebuildAttemptId &&
          other.rebuildLocalAttemptId == this.rebuildLocalAttemptId &&
          other.rebuildManifestSecretId == this.rebuildManifestSecretId &&
          other.rebuildControlSecretId == this.rebuildControlSecretId);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateRow> {
  final Value<String> accountId;
  final Value<int> cursor;
  final Value<int?> lastSyncAt;
  final Value<String?> blockedReason;
  final Value<bool> bootstrapCompleted;
  final Value<String?> syncGeneration;
  final Value<String> backupState;
  final Value<String?> rebuildAttemptId;
  final Value<String?> rebuildLocalAttemptId;
  final Value<String?> rebuildManifestSecretId;
  final Value<String?> rebuildControlSecretId;
  final Value<int> rowid;
  const SyncStateCompanion({
    this.accountId = const Value.absent(),
    this.cursor = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.blockedReason = const Value.absent(),
    this.bootstrapCompleted = const Value.absent(),
    this.syncGeneration = const Value.absent(),
    this.backupState = const Value.absent(),
    this.rebuildAttemptId = const Value.absent(),
    this.rebuildLocalAttemptId = const Value.absent(),
    this.rebuildManifestSecretId = const Value.absent(),
    this.rebuildControlSecretId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateCompanion.insert({
    required String accountId,
    required int cursor,
    this.lastSyncAt = const Value.absent(),
    this.blockedReason = const Value.absent(),
    this.bootstrapCompleted = const Value.absent(),
    this.syncGeneration = const Value.absent(),
    this.backupState = const Value.absent(),
    this.rebuildAttemptId = const Value.absent(),
    this.rebuildLocalAttemptId = const Value.absent(),
    this.rebuildManifestSecretId = const Value.absent(),
    this.rebuildControlSecretId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       cursor = Value(cursor);
  static Insertable<SyncStateRow> custom({
    Expression<String>? accountId,
    Expression<int>? cursor,
    Expression<int>? lastSyncAt,
    Expression<String>? blockedReason,
    Expression<bool>? bootstrapCompleted,
    Expression<String>? syncGeneration,
    Expression<String>? backupState,
    Expression<String>? rebuildAttemptId,
    Expression<String>? rebuildLocalAttemptId,
    Expression<String>? rebuildManifestSecretId,
    Expression<String>? rebuildControlSecretId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (cursor != null) 'cursor': cursor,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (blockedReason != null) 'blocked_reason': blockedReason,
      if (bootstrapCompleted != null) 'bootstrap_completed': bootstrapCompleted,
      if (syncGeneration != null) 'sync_generation': syncGeneration,
      if (backupState != null) 'backup_state': backupState,
      if (rebuildAttemptId != null) 'rebuild_attempt_id': rebuildAttemptId,
      if (rebuildLocalAttemptId != null)
        'rebuild_local_attempt_id': rebuildLocalAttemptId,
      if (rebuildManifestSecretId != null)
        'rebuild_manifest_secret_id': rebuildManifestSecretId,
      if (rebuildControlSecretId != null)
        'rebuild_control_secret_id': rebuildControlSecretId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateCompanion copyWith({
    Value<String>? accountId,
    Value<int>? cursor,
    Value<int?>? lastSyncAt,
    Value<String?>? blockedReason,
    Value<bool>? bootstrapCompleted,
    Value<String?>? syncGeneration,
    Value<String>? backupState,
    Value<String?>? rebuildAttemptId,
    Value<String?>? rebuildLocalAttemptId,
    Value<String?>? rebuildManifestSecretId,
    Value<String?>? rebuildControlSecretId,
    Value<int>? rowid,
  }) {
    return SyncStateCompanion(
      accountId: accountId ?? this.accountId,
      cursor: cursor ?? this.cursor,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      blockedReason: blockedReason ?? this.blockedReason,
      bootstrapCompleted: bootstrapCompleted ?? this.bootstrapCompleted,
      syncGeneration: syncGeneration ?? this.syncGeneration,
      backupState: backupState ?? this.backupState,
      rebuildAttemptId: rebuildAttemptId ?? this.rebuildAttemptId,
      rebuildLocalAttemptId:
          rebuildLocalAttemptId ?? this.rebuildLocalAttemptId,
      rebuildManifestSecretId:
          rebuildManifestSecretId ?? this.rebuildManifestSecretId,
      rebuildControlSecretId:
          rebuildControlSecretId ?? this.rebuildControlSecretId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (cursor.present) {
      map['cursor'] = Variable<int>(cursor.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<int>(lastSyncAt.value);
    }
    if (blockedReason.present) {
      map['blocked_reason'] = Variable<String>(blockedReason.value);
    }
    if (bootstrapCompleted.present) {
      map['bootstrap_completed'] = Variable<bool>(bootstrapCompleted.value);
    }
    if (syncGeneration.present) {
      map['sync_generation'] = Variable<String>(syncGeneration.value);
    }
    if (backupState.present) {
      map['backup_state'] = Variable<String>(backupState.value);
    }
    if (rebuildAttemptId.present) {
      map['rebuild_attempt_id'] = Variable<String>(rebuildAttemptId.value);
    }
    if (rebuildLocalAttemptId.present) {
      map['rebuild_local_attempt_id'] = Variable<String>(
        rebuildLocalAttemptId.value,
      );
    }
    if (rebuildManifestSecretId.present) {
      map['rebuild_manifest_secret_id'] = Variable<String>(
        rebuildManifestSecretId.value,
      );
    }
    if (rebuildControlSecretId.present) {
      map['rebuild_control_secret_id'] = Variable<String>(
        rebuildControlSecretId.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateCompanion(')
          ..write('accountId: $accountId, ')
          ..write('cursor: $cursor, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('blockedReason: $blockedReason, ')
          ..write('bootstrapCompleted: $bootstrapCompleted, ')
          ..write('syncGeneration: $syncGeneration, ')
          ..write('backupState: $backupState, ')
          ..write('rebuildAttemptId: $rebuildAttemptId, ')
          ..write('rebuildLocalAttemptId: $rebuildLocalAttemptId, ')
          ..write('rebuildManifestSecretId: $rebuildManifestSecretId, ')
          ..write('rebuildControlSecretId: $rebuildControlSecretId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncArchivesTable extends SyncArchives
    with TableInfo<$SyncArchivesTable, SyncArchiveRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncArchivesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncGenerationMeta = const VerificationMeta(
    'syncGeneration',
  );
  @override
  late final GeneratedColumn<String> syncGeneration = GeneratedColumn<String>(
    'sync_generation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadSecretIdMeta = const VerificationMeta(
    'payloadSecretId',
  );
  @override
  late final GeneratedColumn<String> payloadSecretId = GeneratedColumn<String>(
    'payload_secret_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    accountId,
    syncGeneration,
    payloadSecretId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_archives';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncArchiveRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('sync_generation')) {
      context.handle(
        _syncGenerationMeta,
        syncGeneration.isAcceptableOrUnknown(
          data['sync_generation']!,
          _syncGenerationMeta,
        ),
      );
    }
    if (data.containsKey('payload_secret_id')) {
      context.handle(
        _payloadSecretIdMeta,
        payloadSecretId.isAcceptableOrUnknown(
          data['payload_secret_id']!,
          _payloadSecretIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadSecretIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncArchiveRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncArchiveRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      syncGeneration: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_generation'],
      ),
      payloadSecretId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_secret_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SyncArchivesTable createAlias(String alias) {
    return $SyncArchivesTable(attachedDatabase, alias);
  }
}

class SyncArchiveRow extends DataClass implements Insertable<SyncArchiveRow> {
  final String id;
  final String accountId;
  final String? syncGeneration;
  final String payloadSecretId;
  final int createdAt;
  const SyncArchiveRow({
    required this.id,
    required this.accountId,
    this.syncGeneration,
    required this.payloadSecretId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['account_id'] = Variable<String>(accountId);
    if (!nullToAbsent || syncGeneration != null) {
      map['sync_generation'] = Variable<String>(syncGeneration);
    }
    map['payload_secret_id'] = Variable<String>(payloadSecretId);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  SyncArchivesCompanion toCompanion(bool nullToAbsent) {
    return SyncArchivesCompanion(
      id: Value(id),
      accountId: Value(accountId),
      syncGeneration: syncGeneration == null && nullToAbsent
          ? const Value.absent()
          : Value(syncGeneration),
      payloadSecretId: Value(payloadSecretId),
      createdAt: Value(createdAt),
    );
  }

  factory SyncArchiveRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncArchiveRow(
      id: serializer.fromJson<String>(json['id']),
      accountId: serializer.fromJson<String>(json['accountId']),
      syncGeneration: serializer.fromJson<String?>(json['syncGeneration']),
      payloadSecretId: serializer.fromJson<String>(json['payloadSecretId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'accountId': serializer.toJson<String>(accountId),
      'syncGeneration': serializer.toJson<String?>(syncGeneration),
      'payloadSecretId': serializer.toJson<String>(payloadSecretId),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  SyncArchiveRow copyWith({
    String? id,
    String? accountId,
    Value<String?> syncGeneration = const Value.absent(),
    String? payloadSecretId,
    int? createdAt,
  }) => SyncArchiveRow(
    id: id ?? this.id,
    accountId: accountId ?? this.accountId,
    syncGeneration: syncGeneration.present
        ? syncGeneration.value
        : this.syncGeneration,
    payloadSecretId: payloadSecretId ?? this.payloadSecretId,
    createdAt: createdAt ?? this.createdAt,
  );
  SyncArchiveRow copyWithCompanion(SyncArchivesCompanion data) {
    return SyncArchiveRow(
      id: data.id.present ? data.id.value : this.id,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      syncGeneration: data.syncGeneration.present
          ? data.syncGeneration.value
          : this.syncGeneration,
      payloadSecretId: data.payloadSecretId.present
          ? data.payloadSecretId.value
          : this.payloadSecretId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncArchiveRow(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('syncGeneration: $syncGeneration, ')
          ..write('payloadSecretId: $payloadSecretId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, accountId, syncGeneration, payloadSecretId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncArchiveRow &&
          other.id == this.id &&
          other.accountId == this.accountId &&
          other.syncGeneration == this.syncGeneration &&
          other.payloadSecretId == this.payloadSecretId &&
          other.createdAt == this.createdAt);
}

class SyncArchivesCompanion extends UpdateCompanion<SyncArchiveRow> {
  final Value<String> id;
  final Value<String> accountId;
  final Value<String?> syncGeneration;
  final Value<String> payloadSecretId;
  final Value<int> createdAt;
  final Value<int> rowid;
  const SyncArchivesCompanion({
    this.id = const Value.absent(),
    this.accountId = const Value.absent(),
    this.syncGeneration = const Value.absent(),
    this.payloadSecretId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncArchivesCompanion.insert({
    required String id,
    required String accountId,
    this.syncGeneration = const Value.absent(),
    required String payloadSecretId,
    required int createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       accountId = Value(accountId),
       payloadSecretId = Value(payloadSecretId),
       createdAt = Value(createdAt);
  static Insertable<SyncArchiveRow> custom({
    Expression<String>? id,
    Expression<String>? accountId,
    Expression<String>? syncGeneration,
    Expression<String>? payloadSecretId,
    Expression<int>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (accountId != null) 'account_id': accountId,
      if (syncGeneration != null) 'sync_generation': syncGeneration,
      if (payloadSecretId != null) 'payload_secret_id': payloadSecretId,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncArchivesCompanion copyWith({
    Value<String>? id,
    Value<String>? accountId,
    Value<String?>? syncGeneration,
    Value<String>? payloadSecretId,
    Value<int>? createdAt,
    Value<int>? rowid,
  }) {
    return SyncArchivesCompanion(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      syncGeneration: syncGeneration ?? this.syncGeneration,
      payloadSecretId: payloadSecretId ?? this.payloadSecretId,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (syncGeneration.present) {
      map['sync_generation'] = Variable<String>(syncGeneration.value);
    }
    if (payloadSecretId.present) {
      map['payload_secret_id'] = Variable<String>(payloadSecretId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncArchivesCompanion(')
          ..write('id: $id, ')
          ..write('accountId: $accountId, ')
          ..write('syncGeneration: $syncGeneration, ')
          ..write('payloadSecretId: $payloadSecretId, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncArchiveReferencesTable extends SyncArchiveReferences
    with TableInfo<$SyncArchiveReferencesTable, SyncArchiveReferenceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncArchiveReferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _archiveIdMeta = const VerificationMeta(
    'archiveId',
  );
  @override
  late final GeneratedColumn<String> archiveId = GeneratedColumn<String>(
    'archive_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sync_archives (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _secretIdMeta = const VerificationMeta(
    'secretId',
  );
  @override
  late final GeneratedColumn<String> secretId = GeneratedColumn<String>(
    'secret_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [archiveId, secretId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_archive_references';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncArchiveReferenceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('archive_id')) {
      context.handle(
        _archiveIdMeta,
        archiveId.isAcceptableOrUnknown(data['archive_id']!, _archiveIdMeta),
      );
    } else if (isInserting) {
      context.missing(_archiveIdMeta);
    }
    if (data.containsKey('secret_id')) {
      context.handle(
        _secretIdMeta,
        secretId.isAcceptableOrUnknown(data['secret_id']!, _secretIdMeta),
      );
    } else if (isInserting) {
      context.missing(_secretIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {archiveId, secretId};
  @override
  SyncArchiveReferenceRow map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncArchiveReferenceRow(
      archiveId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}archive_id'],
      )!,
      secretId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}secret_id'],
      )!,
    );
  }

  @override
  $SyncArchiveReferencesTable createAlias(String alias) {
    return $SyncArchiveReferencesTable(attachedDatabase, alias);
  }
}

class SyncArchiveReferenceRow extends DataClass
    implements Insertable<SyncArchiveReferenceRow> {
  final String archiveId;
  final String secretId;
  const SyncArchiveReferenceRow({
    required this.archiveId,
    required this.secretId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['archive_id'] = Variable<String>(archiveId);
    map['secret_id'] = Variable<String>(secretId);
    return map;
  }

  SyncArchiveReferencesCompanion toCompanion(bool nullToAbsent) {
    return SyncArchiveReferencesCompanion(
      archiveId: Value(archiveId),
      secretId: Value(secretId),
    );
  }

  factory SyncArchiveReferenceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncArchiveReferenceRow(
      archiveId: serializer.fromJson<String>(json['archiveId']),
      secretId: serializer.fromJson<String>(json['secretId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'archiveId': serializer.toJson<String>(archiveId),
      'secretId': serializer.toJson<String>(secretId),
    };
  }

  SyncArchiveReferenceRow copyWith({String? archiveId, String? secretId}) =>
      SyncArchiveReferenceRow(
        archiveId: archiveId ?? this.archiveId,
        secretId: secretId ?? this.secretId,
      );
  SyncArchiveReferenceRow copyWithCompanion(
    SyncArchiveReferencesCompanion data,
  ) {
    return SyncArchiveReferenceRow(
      archiveId: data.archiveId.present ? data.archiveId.value : this.archiveId,
      secretId: data.secretId.present ? data.secretId.value : this.secretId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncArchiveReferenceRow(')
          ..write('archiveId: $archiveId, ')
          ..write('secretId: $secretId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(archiveId, secretId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncArchiveReferenceRow &&
          other.archiveId == this.archiveId &&
          other.secretId == this.secretId);
}

class SyncArchiveReferencesCompanion
    extends UpdateCompanion<SyncArchiveReferenceRow> {
  final Value<String> archiveId;
  final Value<String> secretId;
  final Value<int> rowid;
  const SyncArchiveReferencesCompanion({
    this.archiveId = const Value.absent(),
    this.secretId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncArchiveReferencesCompanion.insert({
    required String archiveId,
    required String secretId,
    this.rowid = const Value.absent(),
  }) : archiveId = Value(archiveId),
       secretId = Value(secretId);
  static Insertable<SyncArchiveReferenceRow> custom({
    Expression<String>? archiveId,
    Expression<String>? secretId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (archiveId != null) 'archive_id': archiveId,
      if (secretId != null) 'secret_id': secretId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncArchiveReferencesCompanion copyWith({
    Value<String>? archiveId,
    Value<String>? secretId,
    Value<int>? rowid,
  }) {
    return SyncArchiveReferencesCompanion(
      archiveId: archiveId ?? this.archiveId,
      secretId: secretId ?? this.secretId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (archiveId.present) {
      map['archive_id'] = Variable<String>(archiveId.value);
    }
    if (secretId.present) {
      map['secret_id'] = Variable<String>(secretId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncArchiveReferencesCompanion(')
          ..write('archiveId: $archiveId, ')
          ..write('secretId: $secretId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncRebuildEntriesTable extends SyncRebuildEntries
    with TableInfo<$SyncRebuildEntriesTable, SyncRebuildEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncRebuildEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncGenerationMeta = const VerificationMeta(
    'syncGeneration',
  );
  @override
  late final GeneratedColumn<String> syncGeneration = GeneratedColumn<String>(
    'sync_generation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptIdMeta = const VerificationMeta(
    'attemptId',
  );
  @override
  late final GeneratedColumn<String> attemptId = GeneratedColumn<String>(
    'attempt_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ordinalMeta = const VerificationMeta(
    'ordinal',
  );
  @override
  late final GeneratedColumn<int> ordinal = GeneratedColumn<int>(
    'ordinal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mutationIdMeta = const VerificationMeta(
    'mutationId',
  );
  @override
  late final GeneratedColumn<String> mutationId = GeneratedColumn<String>(
    'mutation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _envelopeSecretIdMeta = const VerificationMeta(
    'envelopeSecretId',
  );
  @override
  late final GeneratedColumn<String> envelopeSecretId = GeneratedColumn<String>(
    'envelope_secret_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _acknowledgedMeta = const VerificationMeta(
    'acknowledged',
  );
  @override
  late final GeneratedColumn<bool> acknowledged = GeneratedColumn<bool>(
    'acknowledged',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("acknowledged" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    syncGeneration,
    attemptId,
    ordinal,
    documentId,
    recordId,
    type,
    mutationId,
    envelopeSecretId,
    acknowledged,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_rebuild_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncRebuildEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('sync_generation')) {
      context.handle(
        _syncGenerationMeta,
        syncGeneration.isAcceptableOrUnknown(
          data['sync_generation']!,
          _syncGenerationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_syncGenerationMeta);
    }
    if (data.containsKey('attempt_id')) {
      context.handle(
        _attemptIdMeta,
        attemptId.isAcceptableOrUnknown(data['attempt_id']!, _attemptIdMeta),
      );
    } else if (isInserting) {
      context.missing(_attemptIdMeta);
    }
    if (data.containsKey('ordinal')) {
      context.handle(
        _ordinalMeta,
        ordinal.isAcceptableOrUnknown(data['ordinal']!, _ordinalMeta),
      );
    } else if (isInserting) {
      context.missing(_ordinalMeta);
    }
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('mutation_id')) {
      context.handle(
        _mutationIdMeta,
        mutationId.isAcceptableOrUnknown(data['mutation_id']!, _mutationIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mutationIdMeta);
    }
    if (data.containsKey('envelope_secret_id')) {
      context.handle(
        _envelopeSecretIdMeta,
        envelopeSecretId.isAcceptableOrUnknown(
          data['envelope_secret_id']!,
          _envelopeSecretIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_envelopeSecretIdMeta);
    }
    if (data.containsKey('acknowledged')) {
      context.handle(
        _acknowledgedMeta,
        acknowledged.isAcceptableOrUnknown(
          data['acknowledged']!,
          _acknowledgedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    accountId,
    syncGeneration,
    attemptId,
    recordId,
  };
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {accountId, syncGeneration, attemptId, ordinal},
    {accountId, syncGeneration, attemptId, mutationId},
  ];
  @override
  SyncRebuildEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncRebuildEntryRow(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      syncGeneration: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_generation'],
      )!,
      attemptId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attempt_id'],
      )!,
      ordinal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordinal'],
      )!,
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      mutationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mutation_id'],
      )!,
      envelopeSecretId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}envelope_secret_id'],
      )!,
      acknowledged: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}acknowledged'],
      )!,
    );
  }

  @override
  $SyncRebuildEntriesTable createAlias(String alias) {
    return $SyncRebuildEntriesTable(attachedDatabase, alias);
  }
}

class SyncRebuildEntryRow extends DataClass
    implements Insertable<SyncRebuildEntryRow> {
  final String accountId;
  final String syncGeneration;
  final String attemptId;
  final int ordinal;
  final String documentId;
  final String recordId;
  final String type;
  final String mutationId;
  final String envelopeSecretId;
  final bool acknowledged;
  const SyncRebuildEntryRow({
    required this.accountId,
    required this.syncGeneration,
    required this.attemptId,
    required this.ordinal,
    required this.documentId,
    required this.recordId,
    required this.type,
    required this.mutationId,
    required this.envelopeSecretId,
    required this.acknowledged,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['sync_generation'] = Variable<String>(syncGeneration);
    map['attempt_id'] = Variable<String>(attemptId);
    map['ordinal'] = Variable<int>(ordinal);
    map['document_id'] = Variable<String>(documentId);
    map['record_id'] = Variable<String>(recordId);
    map['type'] = Variable<String>(type);
    map['mutation_id'] = Variable<String>(mutationId);
    map['envelope_secret_id'] = Variable<String>(envelopeSecretId);
    map['acknowledged'] = Variable<bool>(acknowledged);
    return map;
  }

  SyncRebuildEntriesCompanion toCompanion(bool nullToAbsent) {
    return SyncRebuildEntriesCompanion(
      accountId: Value(accountId),
      syncGeneration: Value(syncGeneration),
      attemptId: Value(attemptId),
      ordinal: Value(ordinal),
      documentId: Value(documentId),
      recordId: Value(recordId),
      type: Value(type),
      mutationId: Value(mutationId),
      envelopeSecretId: Value(envelopeSecretId),
      acknowledged: Value(acknowledged),
    );
  }

  factory SyncRebuildEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncRebuildEntryRow(
      accountId: serializer.fromJson<String>(json['accountId']),
      syncGeneration: serializer.fromJson<String>(json['syncGeneration']),
      attemptId: serializer.fromJson<String>(json['attemptId']),
      ordinal: serializer.fromJson<int>(json['ordinal']),
      documentId: serializer.fromJson<String>(json['documentId']),
      recordId: serializer.fromJson<String>(json['recordId']),
      type: serializer.fromJson<String>(json['type']),
      mutationId: serializer.fromJson<String>(json['mutationId']),
      envelopeSecretId: serializer.fromJson<String>(json['envelopeSecretId']),
      acknowledged: serializer.fromJson<bool>(json['acknowledged']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'syncGeneration': serializer.toJson<String>(syncGeneration),
      'attemptId': serializer.toJson<String>(attemptId),
      'ordinal': serializer.toJson<int>(ordinal),
      'documentId': serializer.toJson<String>(documentId),
      'recordId': serializer.toJson<String>(recordId),
      'type': serializer.toJson<String>(type),
      'mutationId': serializer.toJson<String>(mutationId),
      'envelopeSecretId': serializer.toJson<String>(envelopeSecretId),
      'acknowledged': serializer.toJson<bool>(acknowledged),
    };
  }

  SyncRebuildEntryRow copyWith({
    String? accountId,
    String? syncGeneration,
    String? attemptId,
    int? ordinal,
    String? documentId,
    String? recordId,
    String? type,
    String? mutationId,
    String? envelopeSecretId,
    bool? acknowledged,
  }) => SyncRebuildEntryRow(
    accountId: accountId ?? this.accountId,
    syncGeneration: syncGeneration ?? this.syncGeneration,
    attemptId: attemptId ?? this.attemptId,
    ordinal: ordinal ?? this.ordinal,
    documentId: documentId ?? this.documentId,
    recordId: recordId ?? this.recordId,
    type: type ?? this.type,
    mutationId: mutationId ?? this.mutationId,
    envelopeSecretId: envelopeSecretId ?? this.envelopeSecretId,
    acknowledged: acknowledged ?? this.acknowledged,
  );
  SyncRebuildEntryRow copyWithCompanion(SyncRebuildEntriesCompanion data) {
    return SyncRebuildEntryRow(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      syncGeneration: data.syncGeneration.present
          ? data.syncGeneration.value
          : this.syncGeneration,
      attemptId: data.attemptId.present ? data.attemptId.value : this.attemptId,
      ordinal: data.ordinal.present ? data.ordinal.value : this.ordinal,
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      type: data.type.present ? data.type.value : this.type,
      mutationId: data.mutationId.present
          ? data.mutationId.value
          : this.mutationId,
      envelopeSecretId: data.envelopeSecretId.present
          ? data.envelopeSecretId.value
          : this.envelopeSecretId,
      acknowledged: data.acknowledged.present
          ? data.acknowledged.value
          : this.acknowledged,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncRebuildEntryRow(')
          ..write('accountId: $accountId, ')
          ..write('syncGeneration: $syncGeneration, ')
          ..write('attemptId: $attemptId, ')
          ..write('ordinal: $ordinal, ')
          ..write('documentId: $documentId, ')
          ..write('recordId: $recordId, ')
          ..write('type: $type, ')
          ..write('mutationId: $mutationId, ')
          ..write('envelopeSecretId: $envelopeSecretId, ')
          ..write('acknowledged: $acknowledged')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    accountId,
    syncGeneration,
    attemptId,
    ordinal,
    documentId,
    recordId,
    type,
    mutationId,
    envelopeSecretId,
    acknowledged,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncRebuildEntryRow &&
          other.accountId == this.accountId &&
          other.syncGeneration == this.syncGeneration &&
          other.attemptId == this.attemptId &&
          other.ordinal == this.ordinal &&
          other.documentId == this.documentId &&
          other.recordId == this.recordId &&
          other.type == this.type &&
          other.mutationId == this.mutationId &&
          other.envelopeSecretId == this.envelopeSecretId &&
          other.acknowledged == this.acknowledged);
}

class SyncRebuildEntriesCompanion extends UpdateCompanion<SyncRebuildEntryRow> {
  final Value<String> accountId;
  final Value<String> syncGeneration;
  final Value<String> attemptId;
  final Value<int> ordinal;
  final Value<String> documentId;
  final Value<String> recordId;
  final Value<String> type;
  final Value<String> mutationId;
  final Value<String> envelopeSecretId;
  final Value<bool> acknowledged;
  final Value<int> rowid;
  const SyncRebuildEntriesCompanion({
    this.accountId = const Value.absent(),
    this.syncGeneration = const Value.absent(),
    this.attemptId = const Value.absent(),
    this.ordinal = const Value.absent(),
    this.documentId = const Value.absent(),
    this.recordId = const Value.absent(),
    this.type = const Value.absent(),
    this.mutationId = const Value.absent(),
    this.envelopeSecretId = const Value.absent(),
    this.acknowledged = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncRebuildEntriesCompanion.insert({
    required String accountId,
    required String syncGeneration,
    required String attemptId,
    required int ordinal,
    required String documentId,
    required String recordId,
    required String type,
    required String mutationId,
    required String envelopeSecretId,
    this.acknowledged = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       syncGeneration = Value(syncGeneration),
       attemptId = Value(attemptId),
       ordinal = Value(ordinal),
       documentId = Value(documentId),
       recordId = Value(recordId),
       type = Value(type),
       mutationId = Value(mutationId),
       envelopeSecretId = Value(envelopeSecretId);
  static Insertable<SyncRebuildEntryRow> custom({
    Expression<String>? accountId,
    Expression<String>? syncGeneration,
    Expression<String>? attemptId,
    Expression<int>? ordinal,
    Expression<String>? documentId,
    Expression<String>? recordId,
    Expression<String>? type,
    Expression<String>? mutationId,
    Expression<String>? envelopeSecretId,
    Expression<bool>? acknowledged,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (syncGeneration != null) 'sync_generation': syncGeneration,
      if (attemptId != null) 'attempt_id': attemptId,
      if (ordinal != null) 'ordinal': ordinal,
      if (documentId != null) 'document_id': documentId,
      if (recordId != null) 'record_id': recordId,
      if (type != null) 'type': type,
      if (mutationId != null) 'mutation_id': mutationId,
      if (envelopeSecretId != null) 'envelope_secret_id': envelopeSecretId,
      if (acknowledged != null) 'acknowledged': acknowledged,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncRebuildEntriesCompanion copyWith({
    Value<String>? accountId,
    Value<String>? syncGeneration,
    Value<String>? attemptId,
    Value<int>? ordinal,
    Value<String>? documentId,
    Value<String>? recordId,
    Value<String>? type,
    Value<String>? mutationId,
    Value<String>? envelopeSecretId,
    Value<bool>? acknowledged,
    Value<int>? rowid,
  }) {
    return SyncRebuildEntriesCompanion(
      accountId: accountId ?? this.accountId,
      syncGeneration: syncGeneration ?? this.syncGeneration,
      attemptId: attemptId ?? this.attemptId,
      ordinal: ordinal ?? this.ordinal,
      documentId: documentId ?? this.documentId,
      recordId: recordId ?? this.recordId,
      type: type ?? this.type,
      mutationId: mutationId ?? this.mutationId,
      envelopeSecretId: envelopeSecretId ?? this.envelopeSecretId,
      acknowledged: acknowledged ?? this.acknowledged,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (syncGeneration.present) {
      map['sync_generation'] = Variable<String>(syncGeneration.value);
    }
    if (attemptId.present) {
      map['attempt_id'] = Variable<String>(attemptId.value);
    }
    if (ordinal.present) {
      map['ordinal'] = Variable<int>(ordinal.value);
    }
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (mutationId.present) {
      map['mutation_id'] = Variable<String>(mutationId.value);
    }
    if (envelopeSecretId.present) {
      map['envelope_secret_id'] = Variable<String>(envelopeSecretId.value);
    }
    if (acknowledged.present) {
      map['acknowledged'] = Variable<bool>(acknowledged.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncRebuildEntriesCompanion(')
          ..write('accountId: $accountId, ')
          ..write('syncGeneration: $syncGeneration, ')
          ..write('attemptId: $attemptId, ')
          ..write('ordinal: $ordinal, ')
          ..write('documentId: $documentId, ')
          ..write('recordId: $recordId, ')
          ..write('type: $type, ')
          ..write('mutationId: $mutationId, ')
          ..write('envelopeSecretId: $envelopeSecretId, ')
          ..write('acknowledged: $acknowledged, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncPullStagesTable extends SyncPullStages
    with TableInfo<$SyncPullStagesTable, SyncPullStageRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncPullStagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncGenerationMeta = const VerificationMeta(
    'syncGeneration',
  );
  @override
  late final GeneratedColumn<String> syncGeneration = GeneratedColumn<String>(
    'sync_generation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _headRevisionMeta = const VerificationMeta(
    'headRevision',
  );
  @override
  late final GeneratedColumn<int> headRevision = GeneratedColumn<int>(
    'head_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cursorMeta = const VerificationMeta('cursor');
  @override
  late final GeneratedColumn<int> cursor = GeneratedColumn<int>(
    'cursor',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completeMeta = const VerificationMeta(
    'complete',
  );
  @override
  late final GeneratedColumn<bool> complete = GeneratedColumn<bool>(
    'complete',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("complete" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    syncGeneration,
    headRevision,
    cursor,
    complete,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_pull_stages';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncPullStageRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('sync_generation')) {
      context.handle(
        _syncGenerationMeta,
        syncGeneration.isAcceptableOrUnknown(
          data['sync_generation']!,
          _syncGenerationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_syncGenerationMeta);
    }
    if (data.containsKey('head_revision')) {
      context.handle(
        _headRevisionMeta,
        headRevision.isAcceptableOrUnknown(
          data['head_revision']!,
          _headRevisionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_headRevisionMeta);
    }
    if (data.containsKey('cursor')) {
      context.handle(
        _cursorMeta,
        cursor.isAcceptableOrUnknown(data['cursor']!, _cursorMeta),
      );
    } else if (isInserting) {
      context.missing(_cursorMeta);
    }
    if (data.containsKey('complete')) {
      context.handle(
        _completeMeta,
        complete.isAcceptableOrUnknown(data['complete']!, _completeMeta),
      );
    } else if (isInserting) {
      context.missing(_completeMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId};
  @override
  SyncPullStageRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncPullStageRow(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      syncGeneration: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_generation'],
      )!,
      headRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}head_revision'],
      )!,
      cursor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cursor'],
      )!,
      complete: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}complete'],
      )!,
    );
  }

  @override
  $SyncPullStagesTable createAlias(String alias) {
    return $SyncPullStagesTable(attachedDatabase, alias);
  }
}

class SyncPullStageRow extends DataClass
    implements Insertable<SyncPullStageRow> {
  final String accountId;
  final String syncGeneration;
  final int headRevision;
  final int cursor;
  final bool complete;
  const SyncPullStageRow({
    required this.accountId,
    required this.syncGeneration,
    required this.headRevision,
    required this.cursor,
    required this.complete,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['sync_generation'] = Variable<String>(syncGeneration);
    map['head_revision'] = Variable<int>(headRevision);
    map['cursor'] = Variable<int>(cursor);
    map['complete'] = Variable<bool>(complete);
    return map;
  }

  SyncPullStagesCompanion toCompanion(bool nullToAbsent) {
    return SyncPullStagesCompanion(
      accountId: Value(accountId),
      syncGeneration: Value(syncGeneration),
      headRevision: Value(headRevision),
      cursor: Value(cursor),
      complete: Value(complete),
    );
  }

  factory SyncPullStageRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncPullStageRow(
      accountId: serializer.fromJson<String>(json['accountId']),
      syncGeneration: serializer.fromJson<String>(json['syncGeneration']),
      headRevision: serializer.fromJson<int>(json['headRevision']),
      cursor: serializer.fromJson<int>(json['cursor']),
      complete: serializer.fromJson<bool>(json['complete']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'syncGeneration': serializer.toJson<String>(syncGeneration),
      'headRevision': serializer.toJson<int>(headRevision),
      'cursor': serializer.toJson<int>(cursor),
      'complete': serializer.toJson<bool>(complete),
    };
  }

  SyncPullStageRow copyWith({
    String? accountId,
    String? syncGeneration,
    int? headRevision,
    int? cursor,
    bool? complete,
  }) => SyncPullStageRow(
    accountId: accountId ?? this.accountId,
    syncGeneration: syncGeneration ?? this.syncGeneration,
    headRevision: headRevision ?? this.headRevision,
    cursor: cursor ?? this.cursor,
    complete: complete ?? this.complete,
  );
  SyncPullStageRow copyWithCompanion(SyncPullStagesCompanion data) {
    return SyncPullStageRow(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      syncGeneration: data.syncGeneration.present
          ? data.syncGeneration.value
          : this.syncGeneration,
      headRevision: data.headRevision.present
          ? data.headRevision.value
          : this.headRevision,
      cursor: data.cursor.present ? data.cursor.value : this.cursor,
      complete: data.complete.present ? data.complete.value : this.complete,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncPullStageRow(')
          ..write('accountId: $accountId, ')
          ..write('syncGeneration: $syncGeneration, ')
          ..write('headRevision: $headRevision, ')
          ..write('cursor: $cursor, ')
          ..write('complete: $complete')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(accountId, syncGeneration, headRevision, cursor, complete);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncPullStageRow &&
          other.accountId == this.accountId &&
          other.syncGeneration == this.syncGeneration &&
          other.headRevision == this.headRevision &&
          other.cursor == this.cursor &&
          other.complete == this.complete);
}

class SyncPullStagesCompanion extends UpdateCompanion<SyncPullStageRow> {
  final Value<String> accountId;
  final Value<String> syncGeneration;
  final Value<int> headRevision;
  final Value<int> cursor;
  final Value<bool> complete;
  final Value<int> rowid;
  const SyncPullStagesCompanion({
    this.accountId = const Value.absent(),
    this.syncGeneration = const Value.absent(),
    this.headRevision = const Value.absent(),
    this.cursor = const Value.absent(),
    this.complete = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncPullStagesCompanion.insert({
    required String accountId,
    required String syncGeneration,
    required int headRevision,
    required int cursor,
    required bool complete,
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       syncGeneration = Value(syncGeneration),
       headRevision = Value(headRevision),
       cursor = Value(cursor),
       complete = Value(complete);
  static Insertable<SyncPullStageRow> custom({
    Expression<String>? accountId,
    Expression<String>? syncGeneration,
    Expression<int>? headRevision,
    Expression<int>? cursor,
    Expression<bool>? complete,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (syncGeneration != null) 'sync_generation': syncGeneration,
      if (headRevision != null) 'head_revision': headRevision,
      if (cursor != null) 'cursor': cursor,
      if (complete != null) 'complete': complete,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncPullStagesCompanion copyWith({
    Value<String>? accountId,
    Value<String>? syncGeneration,
    Value<int>? headRevision,
    Value<int>? cursor,
    Value<bool>? complete,
    Value<int>? rowid,
  }) {
    return SyncPullStagesCompanion(
      accountId: accountId ?? this.accountId,
      syncGeneration: syncGeneration ?? this.syncGeneration,
      headRevision: headRevision ?? this.headRevision,
      cursor: cursor ?? this.cursor,
      complete: complete ?? this.complete,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (syncGeneration.present) {
      map['sync_generation'] = Variable<String>(syncGeneration.value);
    }
    if (headRevision.present) {
      map['head_revision'] = Variable<int>(headRevision.value);
    }
    if (cursor.present) {
      map['cursor'] = Variable<int>(cursor.value);
    }
    if (complete.present) {
      map['complete'] = Variable<bool>(complete.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncPullStagesCompanion(')
          ..write('accountId: $accountId, ')
          ..write('syncGeneration: $syncGeneration, ')
          ..write('headRevision: $headRevision, ')
          ..write('cursor: $cursor, ')
          ..write('complete: $complete, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncPullStageEntriesTable extends SyncPullStageEntries
    with TableInfo<$SyncPullStageEntriesTable, SyncPullStageEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncPullStageEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<String> accountId = GeneratedColumn<String>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  @override
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordSecretIdMeta = const VerificationMeta(
    'recordSecretId',
  );
  @override
  late final GeneratedColumn<String> recordSecretId = GeneratedColumn<String>(
    'record_secret_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    accountId,
    recordId,
    revision,
    recordSecretId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_pull_stage_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncPullStageEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionMeta);
    }
    if (data.containsKey('record_secret_id')) {
      context.handle(
        _recordSecretIdMeta,
        recordSecretId.isAcceptableOrUnknown(
          data['record_secret_id']!,
          _recordSecretIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_recordSecretIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {accountId, recordId};
  @override
  SyncPullStageEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncPullStageEntryRow(
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}account_id'],
      )!,
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      recordSecretId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_secret_id'],
      )!,
    );
  }

  @override
  $SyncPullStageEntriesTable createAlias(String alias) {
    return $SyncPullStageEntriesTable(attachedDatabase, alias);
  }
}

class SyncPullStageEntryRow extends DataClass
    implements Insertable<SyncPullStageEntryRow> {
  final String accountId;
  final String recordId;
  final int revision;
  final String recordSecretId;
  const SyncPullStageEntryRow({
    required this.accountId,
    required this.recordId,
    required this.revision,
    required this.recordSecretId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['account_id'] = Variable<String>(accountId);
    map['record_id'] = Variable<String>(recordId);
    map['revision'] = Variable<int>(revision);
    map['record_secret_id'] = Variable<String>(recordSecretId);
    return map;
  }

  SyncPullStageEntriesCompanion toCompanion(bool nullToAbsent) {
    return SyncPullStageEntriesCompanion(
      accountId: Value(accountId),
      recordId: Value(recordId),
      revision: Value(revision),
      recordSecretId: Value(recordSecretId),
    );
  }

  factory SyncPullStageEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncPullStageEntryRow(
      accountId: serializer.fromJson<String>(json['accountId']),
      recordId: serializer.fromJson<String>(json['recordId']),
      revision: serializer.fromJson<int>(json['revision']),
      recordSecretId: serializer.fromJson<String>(json['recordSecretId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'accountId': serializer.toJson<String>(accountId),
      'recordId': serializer.toJson<String>(recordId),
      'revision': serializer.toJson<int>(revision),
      'recordSecretId': serializer.toJson<String>(recordSecretId),
    };
  }

  SyncPullStageEntryRow copyWith({
    String? accountId,
    String? recordId,
    int? revision,
    String? recordSecretId,
  }) => SyncPullStageEntryRow(
    accountId: accountId ?? this.accountId,
    recordId: recordId ?? this.recordId,
    revision: revision ?? this.revision,
    recordSecretId: recordSecretId ?? this.recordSecretId,
  );
  SyncPullStageEntryRow copyWithCompanion(SyncPullStageEntriesCompanion data) {
    return SyncPullStageEntryRow(
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      revision: data.revision.present ? data.revision.value : this.revision,
      recordSecretId: data.recordSecretId.present
          ? data.recordSecretId.value
          : this.recordSecretId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncPullStageEntryRow(')
          ..write('accountId: $accountId, ')
          ..write('recordId: $recordId, ')
          ..write('revision: $revision, ')
          ..write('recordSecretId: $recordSecretId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(accountId, recordId, revision, recordSecretId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncPullStageEntryRow &&
          other.accountId == this.accountId &&
          other.recordId == this.recordId &&
          other.revision == this.revision &&
          other.recordSecretId == this.recordSecretId);
}

class SyncPullStageEntriesCompanion
    extends UpdateCompanion<SyncPullStageEntryRow> {
  final Value<String> accountId;
  final Value<String> recordId;
  final Value<int> revision;
  final Value<String> recordSecretId;
  final Value<int> rowid;
  const SyncPullStageEntriesCompanion({
    this.accountId = const Value.absent(),
    this.recordId = const Value.absent(),
    this.revision = const Value.absent(),
    this.recordSecretId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncPullStageEntriesCompanion.insert({
    required String accountId,
    required String recordId,
    required int revision,
    required String recordSecretId,
    this.rowid = const Value.absent(),
  }) : accountId = Value(accountId),
       recordId = Value(recordId),
       revision = Value(revision),
       recordSecretId = Value(recordSecretId);
  static Insertable<SyncPullStageEntryRow> custom({
    Expression<String>? accountId,
    Expression<String>? recordId,
    Expression<int>? revision,
    Expression<String>? recordSecretId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (accountId != null) 'account_id': accountId,
      if (recordId != null) 'record_id': recordId,
      if (revision != null) 'revision': revision,
      if (recordSecretId != null) 'record_secret_id': recordSecretId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncPullStageEntriesCompanion copyWith({
    Value<String>? accountId,
    Value<String>? recordId,
    Value<int>? revision,
    Value<String>? recordSecretId,
    Value<int>? rowid,
  }) {
    return SyncPullStageEntriesCompanion(
      accountId: accountId ?? this.accountId,
      recordId: recordId ?? this.recordId,
      revision: revision ?? this.revision,
      recordSecretId: recordSecretId ?? this.recordSecretId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (accountId.present) {
      map['account_id'] = Variable<String>(accountId.value);
    }
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (recordSecretId.present) {
      map['record_secret_id'] = Variable<String>(recordSecretId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncPullStageEntriesCompanion(')
          ..write('accountId: $accountId, ')
          ..write('recordId: $recordId, ')
          ..write('revision: $revision, ')
          ..write('recordSecretId: $recordSecretId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ConfigurationsTable configurations = $ConfigurationsTable(this);
  late final $ContentsTable contents = $ContentsTable(this);
  late final $SelfNodesTable selfNodes = $SelfNodesTable(this);
  late final $ChainsTable chains = $ChainsTable(this);
  late final $MembershipsTable memberships = $MembershipsTable(this);
  late final $SelectionsTable selections = $SelectionsTable(this);
  late final $DeviceSettingsTableTable deviceSettingsTable =
      $DeviceSettingsTableTable(this);
  late final $PolicyTableTable policyTable = $PolicyTableTable(this);
  late final $RuleResourcesTable ruleResources = $RuleResourcesTable(this);
  late final $SecretsTable secrets = $SecretsTable(this);
  late final $CloudSessionTable cloudSession = $CloudSessionTable(this);
  late final $SyncMetaTable syncMeta = $SyncMetaTable(this);
  late final $SyncDocumentsTable syncDocuments = $SyncDocumentsTable(this);
  late final $SourceProvenanceTable sourceProvenance = $SourceProvenanceTable(
    this,
  );
  late final $SyncStateTable syncState = $SyncStateTable(this);
  late final $SyncArchivesTable syncArchives = $SyncArchivesTable(this);
  late final $SyncArchiveReferencesTable syncArchiveReferences =
      $SyncArchiveReferencesTable(this);
  late final $SyncRebuildEntriesTable syncRebuildEntries =
      $SyncRebuildEntriesTable(this);
  late final $SyncPullStagesTable syncPullStages = $SyncPullStagesTable(this);
  late final $SyncPullStageEntriesTable syncPullStageEntries =
      $SyncPullStageEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    configurations,
    contents,
    selfNodes,
    chains,
    memberships,
    selections,
    deviceSettingsTable,
    policyTable,
    ruleResources,
    secrets,
    cloudSession,
    syncMeta,
    syncDocuments,
    sourceProvenance,
    syncState,
    syncArchives,
    syncArchiveReferences,
    syncRebuildEntries,
    syncPullStages,
    syncPullStageEntries,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'configurations',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('contents', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'configurations',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('contents', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'configurations',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('memberships', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'configurations',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('memberships', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'configurations',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('selections', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'configurations',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('selections', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'sync_archives',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('sync_archive_references', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$ConfigurationsTableCreateCompanionBuilder =
    ConfigurationsCompanion Function({
      required String id,
      required String kind,
      required String name,
      Value<String?> sourceSecretId,
      Value<String?> sourceDisplay,
      Value<bool> autoUpdate,
      Value<String?> contentId,
      Value<int?> usageUpload,
      Value<int?> usageDownload,
      Value<int?> usageTotal,
      Value<int?> expireAt,
      Value<int?> lastSuccessAt,
      Value<int?> lastAttemptAt,
      Value<String?> lastError,
      required int createdAt,
      required int editedAt,
      Value<String?> cloudAccountId,
      Value<int> rowid,
    });
typedef $$ConfigurationsTableUpdateCompanionBuilder =
    ConfigurationsCompanion Function({
      Value<String> id,
      Value<String> kind,
      Value<String> name,
      Value<String?> sourceSecretId,
      Value<String?> sourceDisplay,
      Value<bool> autoUpdate,
      Value<String?> contentId,
      Value<int?> usageUpload,
      Value<int?> usageDownload,
      Value<int?> usageTotal,
      Value<int?> expireAt,
      Value<int?> lastSuccessAt,
      Value<int?> lastAttemptAt,
      Value<String?> lastError,
      Value<int> createdAt,
      Value<int> editedAt,
      Value<String?> cloudAccountId,
      Value<int> rowid,
    });

final class $$ConfigurationsTableReferences
    extends
        BaseReferences<_$AppDatabase, $ConfigurationsTable, ConfigurationRow> {
  $$ConfigurationsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$ContentsTable, List<ContentRow>>
  _contentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.contents,
    aliasName: 'configurations__id__contents__configuration_id',
  );

  $$ContentsTableProcessedTableManager get contentsRefs {
    final manager = $$ContentsTableTableManager($_db, $_db.contents).filter(
      (f) => f.configurationId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_contentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MembershipsTable, List<MembershipRow>>
  _membershipsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.memberships,
    aliasName: 'configurations__id__memberships__configuration_id',
  );

  $$MembershipsTableProcessedTableManager get membershipsRefs {
    final manager = $$MembershipsTableTableManager($_db, $_db.memberships)
        .filter(
          (f) => f.configurationId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(_membershipsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SelectionsTable, List<SelectionRow>>
  _selectionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.selections,
    aliasName: 'configurations__id__selections__configuration_id',
  );

  $$SelectionsTableProcessedTableManager get selectionsRefs {
    final manager = $$SelectionsTableTableManager($_db, $_db.selections).filter(
      (f) => f.configurationId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_selectionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ConfigurationsTableFilterComposer
    extends Composer<_$AppDatabase, $ConfigurationsTable> {
  $$ConfigurationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceSecretId => $composableBuilder(
    column: $table.sourceSecretId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceDisplay => $composableBuilder(
    column: $table.sourceDisplay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get autoUpdate => $composableBuilder(
    column: $table.autoUpdate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentId => $composableBuilder(
    column: $table.contentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get usageUpload => $composableBuilder(
    column: $table.usageUpload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get usageDownload => $composableBuilder(
    column: $table.usageDownload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get usageTotal => $composableBuilder(
    column: $table.usageTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get expireAt => $composableBuilder(
    column: $table.expireAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSuccessAt => $composableBuilder(
    column: $table.lastSuccessAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cloudAccountId => $composableBuilder(
    column: $table.cloudAccountId,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> contentsRefs(
    Expression<bool> Function($$ContentsTableFilterComposer f) f,
  ) {
    final $$ContentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.contents,
      getReferencedColumn: (t) => t.configurationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContentsTableFilterComposer(
            $db: $db,
            $table: $db.contents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> membershipsRefs(
    Expression<bool> Function($$MembershipsTableFilterComposer f) f,
  ) {
    final $$MembershipsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.memberships,
      getReferencedColumn: (t) => t.configurationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembershipsTableFilterComposer(
            $db: $db,
            $table: $db.memberships,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> selectionsRefs(
    Expression<bool> Function($$SelectionsTableFilterComposer f) f,
  ) {
    final $$SelectionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.selections,
      getReferencedColumn: (t) => t.configurationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SelectionsTableFilterComposer(
            $db: $db,
            $table: $db.selections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ConfigurationsTableOrderingComposer
    extends Composer<_$AppDatabase, $ConfigurationsTable> {
  $$ConfigurationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceSecretId => $composableBuilder(
    column: $table.sourceSecretId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceDisplay => $composableBuilder(
    column: $table.sourceDisplay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get autoUpdate => $composableBuilder(
    column: $table.autoUpdate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentId => $composableBuilder(
    column: $table.contentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get usageUpload => $composableBuilder(
    column: $table.usageUpload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get usageDownload => $composableBuilder(
    column: $table.usageDownload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get usageTotal => $composableBuilder(
    column: $table.usageTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get expireAt => $composableBuilder(
    column: $table.expireAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSuccessAt => $composableBuilder(
    column: $table.lastSuccessAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cloudAccountId => $composableBuilder(
    column: $table.cloudAccountId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ConfigurationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ConfigurationsTable> {
  $$ConfigurationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get sourceSecretId => $composableBuilder(
    column: $table.sourceSecretId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceDisplay => $composableBuilder(
    column: $table.sourceDisplay,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get autoUpdate => $composableBuilder(
    column: $table.autoUpdate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentId =>
      $composableBuilder(column: $table.contentId, builder: (column) => column);

  GeneratedColumn<int> get usageUpload => $composableBuilder(
    column: $table.usageUpload,
    builder: (column) => column,
  );

  GeneratedColumn<int> get usageDownload => $composableBuilder(
    column: $table.usageDownload,
    builder: (column) => column,
  );

  GeneratedColumn<int> get usageTotal => $composableBuilder(
    column: $table.usageTotal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get expireAt =>
      $composableBuilder(column: $table.expireAt, builder: (column) => column);

  GeneratedColumn<int> get lastSuccessAt => $composableBuilder(
    column: $table.lastSuccessAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastAttemptAt => $composableBuilder(
    column: $table.lastAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get editedAt =>
      $composableBuilder(column: $table.editedAt, builder: (column) => column);

  GeneratedColumn<String> get cloudAccountId => $composableBuilder(
    column: $table.cloudAccountId,
    builder: (column) => column,
  );

  Expression<T> contentsRefs<T extends Object>(
    Expression<T> Function($$ContentsTableAnnotationComposer a) f,
  ) {
    final $$ContentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.contents,
      getReferencedColumn: (t) => t.configurationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ContentsTableAnnotationComposer(
            $db: $db,
            $table: $db.contents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> membershipsRefs<T extends Object>(
    Expression<T> Function($$MembershipsTableAnnotationComposer a) f,
  ) {
    final $$MembershipsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.memberships,
      getReferencedColumn: (t) => t.configurationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MembershipsTableAnnotationComposer(
            $db: $db,
            $table: $db.memberships,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> selectionsRefs<T extends Object>(
    Expression<T> Function($$SelectionsTableAnnotationComposer a) f,
  ) {
    final $$SelectionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.selections,
      getReferencedColumn: (t) => t.configurationId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SelectionsTableAnnotationComposer(
            $db: $db,
            $table: $db.selections,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ConfigurationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ConfigurationsTable,
          ConfigurationRow,
          $$ConfigurationsTableFilterComposer,
          $$ConfigurationsTableOrderingComposer,
          $$ConfigurationsTableAnnotationComposer,
          $$ConfigurationsTableCreateCompanionBuilder,
          $$ConfigurationsTableUpdateCompanionBuilder,
          (ConfigurationRow, $$ConfigurationsTableReferences),
          ConfigurationRow,
          PrefetchHooks Function({
            bool contentsRefs,
            bool membershipsRefs,
            bool selectionsRefs,
          })
        > {
  $$ConfigurationsTableTableManager(
    _$AppDatabase db,
    $ConfigurationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ConfigurationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ConfigurationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ConfigurationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> sourceSecretId = const Value.absent(),
                Value<String?> sourceDisplay = const Value.absent(),
                Value<bool> autoUpdate = const Value.absent(),
                Value<String?> contentId = const Value.absent(),
                Value<int?> usageUpload = const Value.absent(),
                Value<int?> usageDownload = const Value.absent(),
                Value<int?> usageTotal = const Value.absent(),
                Value<int?> expireAt = const Value.absent(),
                Value<int?> lastSuccessAt = const Value.absent(),
                Value<int?> lastAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> editedAt = const Value.absent(),
                Value<String?> cloudAccountId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConfigurationsCompanion(
                id: id,
                kind: kind,
                name: name,
                sourceSecretId: sourceSecretId,
                sourceDisplay: sourceDisplay,
                autoUpdate: autoUpdate,
                contentId: contentId,
                usageUpload: usageUpload,
                usageDownload: usageDownload,
                usageTotal: usageTotal,
                expireAt: expireAt,
                lastSuccessAt: lastSuccessAt,
                lastAttemptAt: lastAttemptAt,
                lastError: lastError,
                createdAt: createdAt,
                editedAt: editedAt,
                cloudAccountId: cloudAccountId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                required String name,
                Value<String?> sourceSecretId = const Value.absent(),
                Value<String?> sourceDisplay = const Value.absent(),
                Value<bool> autoUpdate = const Value.absent(),
                Value<String?> contentId = const Value.absent(),
                Value<int?> usageUpload = const Value.absent(),
                Value<int?> usageDownload = const Value.absent(),
                Value<int?> usageTotal = const Value.absent(),
                Value<int?> expireAt = const Value.absent(),
                Value<int?> lastSuccessAt = const Value.absent(),
                Value<int?> lastAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                required int createdAt,
                required int editedAt,
                Value<String?> cloudAccountId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ConfigurationsCompanion.insert(
                id: id,
                kind: kind,
                name: name,
                sourceSecretId: sourceSecretId,
                sourceDisplay: sourceDisplay,
                autoUpdate: autoUpdate,
                contentId: contentId,
                usageUpload: usageUpload,
                usageDownload: usageDownload,
                usageTotal: usageTotal,
                expireAt: expireAt,
                lastSuccessAt: lastSuccessAt,
                lastAttemptAt: lastAttemptAt,
                lastError: lastError,
                createdAt: createdAt,
                editedAt: editedAt,
                cloudAccountId: cloudAccountId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ConfigurationsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                contentsRefs = false,
                membershipsRefs = false,
                selectionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (contentsRefs) db.contents,
                    if (membershipsRefs) db.memberships,
                    if (selectionsRefs) db.selections,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (contentsRefs)
                        await $_getPrefetchedData<
                          ConfigurationRow,
                          $ConfigurationsTable,
                          ContentRow
                        >(
                          currentTable: table,
                          referencedTable: $$ConfigurationsTableReferences
                              ._contentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ConfigurationsTableReferences(
                                db,
                                table,
                                p0,
                              ).contentsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.configurationId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (membershipsRefs)
                        await $_getPrefetchedData<
                          ConfigurationRow,
                          $ConfigurationsTable,
                          MembershipRow
                        >(
                          currentTable: table,
                          referencedTable: $$ConfigurationsTableReferences
                              ._membershipsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ConfigurationsTableReferences(
                                db,
                                table,
                                p0,
                              ).membershipsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.configurationId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (selectionsRefs)
                        await $_getPrefetchedData<
                          ConfigurationRow,
                          $ConfigurationsTable,
                          SelectionRow
                        >(
                          currentTable: table,
                          referencedTable: $$ConfigurationsTableReferences
                              ._selectionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ConfigurationsTableReferences(
                                db,
                                table,
                                p0,
                              ).selectionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.configurationId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$ConfigurationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ConfigurationsTable,
      ConfigurationRow,
      $$ConfigurationsTableFilterComposer,
      $$ConfigurationsTableOrderingComposer,
      $$ConfigurationsTableAnnotationComposer,
      $$ConfigurationsTableCreateCompanionBuilder,
      $$ConfigurationsTableUpdateCompanionBuilder,
      (ConfigurationRow, $$ConfigurationsTableReferences),
      ConfigurationRow,
      PrefetchHooks Function({
        bool contentsRefs,
        bool membershipsRefs,
        bool selectionsRefs,
      })
    >;
typedef $$ContentsTableCreateCompanionBuilder =
    ContentsCompanion Function({
      required String id,
      required String configurationId,
      required String format,
      required String modelJson,
      required String secretId,
      required int nodeCount,
      required String digest,
      required String warningsJson,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$ContentsTableUpdateCompanionBuilder =
    ContentsCompanion Function({
      Value<String> id,
      Value<String> configurationId,
      Value<String> format,
      Value<String> modelJson,
      Value<String> secretId,
      Value<int> nodeCount,
      Value<String> digest,
      Value<String> warningsJson,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $$ContentsTableReferences
    extends BaseReferences<_$AppDatabase, $ContentsTable, ContentRow> {
  $$ContentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ConfigurationsTable _configurationIdTable(_$AppDatabase db) => db
      .configurations
      .createAlias('contents__configuration_id__configurations__id');

  $$ConfigurationsTableProcessedTableManager get configurationId {
    final $_column = $_itemColumn<String>('configuration_id')!;

    final manager = $$ConfigurationsTableTableManager(
      $_db,
      $_db.configurations,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_configurationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ContentsTableFilterComposer
    extends Composer<_$AppDatabase, $ContentsTable> {
  $$ContentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modelJson => $composableBuilder(
    column: $table.modelJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get secretId => $composableBuilder(
    column: $table.secretId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nodeCount => $composableBuilder(
    column: $table.nodeCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get digest => $composableBuilder(
    column: $table.digest,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get warningsJson => $composableBuilder(
    column: $table.warningsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ConfigurationsTableFilterComposer get configurationId {
    final $$ConfigurationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.configurationId,
      referencedTable: $db.configurations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConfigurationsTableFilterComposer(
            $db: $db,
            $table: $db.configurations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContentsTableOrderingComposer
    extends Composer<_$AppDatabase, $ContentsTable> {
  $$ContentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modelJson => $composableBuilder(
    column: $table.modelJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get secretId => $composableBuilder(
    column: $table.secretId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nodeCount => $composableBuilder(
    column: $table.nodeCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get digest => $composableBuilder(
    column: $table.digest,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get warningsJson => $composableBuilder(
    column: $table.warningsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ConfigurationsTableOrderingComposer get configurationId {
    final $$ConfigurationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.configurationId,
      referencedTable: $db.configurations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConfigurationsTableOrderingComposer(
            $db: $db,
            $table: $db.configurations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ContentsTable> {
  $$ContentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<String> get modelJson =>
      $composableBuilder(column: $table.modelJson, builder: (column) => column);

  GeneratedColumn<String> get secretId =>
      $composableBuilder(column: $table.secretId, builder: (column) => column);

  GeneratedColumn<int> get nodeCount =>
      $composableBuilder(column: $table.nodeCount, builder: (column) => column);

  GeneratedColumn<String> get digest =>
      $composableBuilder(column: $table.digest, builder: (column) => column);

  GeneratedColumn<String> get warningsJson => $composableBuilder(
    column: $table.warningsJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ConfigurationsTableAnnotationComposer get configurationId {
    final $$ConfigurationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.configurationId,
      referencedTable: $db.configurations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConfigurationsTableAnnotationComposer(
            $db: $db,
            $table: $db.configurations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ContentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ContentsTable,
          ContentRow,
          $$ContentsTableFilterComposer,
          $$ContentsTableOrderingComposer,
          $$ContentsTableAnnotationComposer,
          $$ContentsTableCreateCompanionBuilder,
          $$ContentsTableUpdateCompanionBuilder,
          (ContentRow, $$ContentsTableReferences),
          ContentRow,
          PrefetchHooks Function({bool configurationId})
        > {
  $$ContentsTableTableManager(_$AppDatabase db, $ContentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> configurationId = const Value.absent(),
                Value<String> format = const Value.absent(),
                Value<String> modelJson = const Value.absent(),
                Value<String> secretId = const Value.absent(),
                Value<int> nodeCount = const Value.absent(),
                Value<String> digest = const Value.absent(),
                Value<String> warningsJson = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContentsCompanion(
                id: id,
                configurationId: configurationId,
                format: format,
                modelJson: modelJson,
                secretId: secretId,
                nodeCount: nodeCount,
                digest: digest,
                warningsJson: warningsJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String configurationId,
                required String format,
                required String modelJson,
                required String secretId,
                required int nodeCount,
                required String digest,
                required String warningsJson,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => ContentsCompanion.insert(
                id: id,
                configurationId: configurationId,
                format: format,
                modelJson: modelJson,
                secretId: secretId,
                nodeCount: nodeCount,
                digest: digest,
                warningsJson: warningsJson,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ContentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({configurationId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (configurationId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.configurationId,
                                referencedTable: $$ContentsTableReferences
                                    ._configurationIdTable(db),
                                referencedColumn: $$ContentsTableReferences
                                    ._configurationIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ContentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ContentsTable,
      ContentRow,
      $$ContentsTableFilterComposer,
      $$ContentsTableOrderingComposer,
      $$ContentsTableAnnotationComposer,
      $$ContentsTableCreateCompanionBuilder,
      $$ContentsTableUpdateCompanionBuilder,
      (ContentRow, $$ContentsTableReferences),
      ContentRow,
      PrefetchHooks Function({bool configurationId})
    >;
typedef $$SelfNodesTableCreateCompanionBuilder =
    SelfNodesCompanion Function({
      required String id,
      required String name,
      required String protocol,
      required String server,
      required int port,
      required String paramsJson,
      required String secretId,
      required int createdAt,
      required int editedAt,
      Value<String?> cloudAccountId,
      Value<int> rowid,
    });
typedef $$SelfNodesTableUpdateCompanionBuilder =
    SelfNodesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> protocol,
      Value<String> server,
      Value<int> port,
      Value<String> paramsJson,
      Value<String> secretId,
      Value<int> createdAt,
      Value<int> editedAt,
      Value<String?> cloudAccountId,
      Value<int> rowid,
    });

class $$SelfNodesTableFilterComposer
    extends Composer<_$AppDatabase, $SelfNodesTable> {
  $$SelfNodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get protocol => $composableBuilder(
    column: $table.protocol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get server => $composableBuilder(
    column: $table.server,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get paramsJson => $composableBuilder(
    column: $table.paramsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get secretId => $composableBuilder(
    column: $table.secretId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cloudAccountId => $composableBuilder(
    column: $table.cloudAccountId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SelfNodesTableOrderingComposer
    extends Composer<_$AppDatabase, $SelfNodesTable> {
  $$SelfNodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get protocol => $composableBuilder(
    column: $table.protocol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get server => $composableBuilder(
    column: $table.server,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get port => $composableBuilder(
    column: $table.port,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get paramsJson => $composableBuilder(
    column: $table.paramsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get secretId => $composableBuilder(
    column: $table.secretId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cloudAccountId => $composableBuilder(
    column: $table.cloudAccountId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SelfNodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SelfNodesTable> {
  $$SelfNodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get protocol =>
      $composableBuilder(column: $table.protocol, builder: (column) => column);

  GeneratedColumn<String> get server =>
      $composableBuilder(column: $table.server, builder: (column) => column);

  GeneratedColumn<int> get port =>
      $composableBuilder(column: $table.port, builder: (column) => column);

  GeneratedColumn<String> get paramsJson => $composableBuilder(
    column: $table.paramsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get secretId =>
      $composableBuilder(column: $table.secretId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get editedAt =>
      $composableBuilder(column: $table.editedAt, builder: (column) => column);

  GeneratedColumn<String> get cloudAccountId => $composableBuilder(
    column: $table.cloudAccountId,
    builder: (column) => column,
  );
}

class $$SelfNodesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SelfNodesTable,
          SelfNodeRow,
          $$SelfNodesTableFilterComposer,
          $$SelfNodesTableOrderingComposer,
          $$SelfNodesTableAnnotationComposer,
          $$SelfNodesTableCreateCompanionBuilder,
          $$SelfNodesTableUpdateCompanionBuilder,
          (
            SelfNodeRow,
            BaseReferences<_$AppDatabase, $SelfNodesTable, SelfNodeRow>,
          ),
          SelfNodeRow,
          PrefetchHooks Function()
        > {
  $$SelfNodesTableTableManager(_$AppDatabase db, $SelfNodesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SelfNodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SelfNodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SelfNodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> protocol = const Value.absent(),
                Value<String> server = const Value.absent(),
                Value<int> port = const Value.absent(),
                Value<String> paramsJson = const Value.absent(),
                Value<String> secretId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> editedAt = const Value.absent(),
                Value<String?> cloudAccountId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SelfNodesCompanion(
                id: id,
                name: name,
                protocol: protocol,
                server: server,
                port: port,
                paramsJson: paramsJson,
                secretId: secretId,
                createdAt: createdAt,
                editedAt: editedAt,
                cloudAccountId: cloudAccountId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String protocol,
                required String server,
                required int port,
                required String paramsJson,
                required String secretId,
                required int createdAt,
                required int editedAt,
                Value<String?> cloudAccountId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SelfNodesCompanion.insert(
                id: id,
                name: name,
                protocol: protocol,
                server: server,
                port: port,
                paramsJson: paramsJson,
                secretId: secretId,
                createdAt: createdAt,
                editedAt: editedAt,
                cloudAccountId: cloudAccountId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SelfNodesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SelfNodesTable,
      SelfNodeRow,
      $$SelfNodesTableFilterComposer,
      $$SelfNodesTableOrderingComposer,
      $$SelfNodesTableAnnotationComposer,
      $$SelfNodesTableCreateCompanionBuilder,
      $$SelfNodesTableUpdateCompanionBuilder,
      (
        SelfNodeRow,
        BaseReferences<_$AppDatabase, $SelfNodesTable, SelfNodeRow>,
      ),
      SelfNodeRow,
      PrefetchHooks Function()
    >;
typedef $$ChainsTableCreateCompanionBuilder =
    ChainsCompanion Function({
      required String id,
      Value<String?> name,
      required String hopsJson,
      required int createdAt,
      required int editedAt,
      Value<String?> cloudAccountId,
      Value<int> rowid,
    });
typedef $$ChainsTableUpdateCompanionBuilder =
    ChainsCompanion Function({
      Value<String> id,
      Value<String?> name,
      Value<String> hopsJson,
      Value<int> createdAt,
      Value<int> editedAt,
      Value<String?> cloudAccountId,
      Value<int> rowid,
    });

class $$ChainsTableFilterComposer
    extends Composer<_$AppDatabase, $ChainsTable> {
  $$ChainsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get hopsJson => $composableBuilder(
    column: $table.hopsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cloudAccountId => $composableBuilder(
    column: $table.cloudAccountId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChainsTableOrderingComposer
    extends Composer<_$AppDatabase, $ChainsTable> {
  $$ChainsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get hopsJson => $composableBuilder(
    column: $table.hopsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cloudAccountId => $composableBuilder(
    column: $table.cloudAccountId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChainsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChainsTable> {
  $$ChainsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get hopsJson =>
      $composableBuilder(column: $table.hopsJson, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get editedAt =>
      $composableBuilder(column: $table.editedAt, builder: (column) => column);

  GeneratedColumn<String> get cloudAccountId => $composableBuilder(
    column: $table.cloudAccountId,
    builder: (column) => column,
  );
}

class $$ChainsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChainsTable,
          ChainRow,
          $$ChainsTableFilterComposer,
          $$ChainsTableOrderingComposer,
          $$ChainsTableAnnotationComposer,
          $$ChainsTableCreateCompanionBuilder,
          $$ChainsTableUpdateCompanionBuilder,
          (ChainRow, BaseReferences<_$AppDatabase, $ChainsTable, ChainRow>),
          ChainRow,
          PrefetchHooks Function()
        > {
  $$ChainsTableTableManager(_$AppDatabase db, $ChainsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChainsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChainsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChainsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> name = const Value.absent(),
                Value<String> hopsJson = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> editedAt = const Value.absent(),
                Value<String?> cloudAccountId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChainsCompanion(
                id: id,
                name: name,
                hopsJson: hopsJson,
                createdAt: createdAt,
                editedAt: editedAt,
                cloudAccountId: cloudAccountId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> name = const Value.absent(),
                required String hopsJson,
                required int createdAt,
                required int editedAt,
                Value<String?> cloudAccountId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChainsCompanion.insert(
                id: id,
                name: name,
                hopsJson: hopsJson,
                createdAt: createdAt,
                editedAt: editedAt,
                cloudAccountId: cloudAccountId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChainsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChainsTable,
      ChainRow,
      $$ChainsTableFilterComposer,
      $$ChainsTableOrderingComposer,
      $$ChainsTableAnnotationComposer,
      $$ChainsTableCreateCompanionBuilder,
      $$ChainsTableUpdateCompanionBuilder,
      (ChainRow, BaseReferences<_$AppDatabase, $ChainsTable, ChainRow>),
      ChainRow,
      PrefetchHooks Function()
    >;
typedef $$MembershipsTableCreateCompanionBuilder =
    MembershipsCompanion Function({
      required String ownerKind,
      required String ownerId,
      required String configurationId,
      required String groupKey,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$MembershipsTableUpdateCompanionBuilder =
    MembershipsCompanion Function({
      Value<String> ownerKind,
      Value<String> ownerId,
      Value<String> configurationId,
      Value<String> groupKey,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $$MembershipsTableReferences
    extends BaseReferences<_$AppDatabase, $MembershipsTable, MembershipRow> {
  $$MembershipsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ConfigurationsTable _configurationIdTable(_$AppDatabase db) => db
      .configurations
      .createAlias('memberships__configuration_id__configurations__id');

  $$ConfigurationsTableProcessedTableManager get configurationId {
    final $_column = $_itemColumn<String>('configuration_id')!;

    final manager = $$ConfigurationsTableTableManager(
      $_db,
      $_db.configurations,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_configurationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MembershipsTableFilterComposer
    extends Composer<_$AppDatabase, $MembershipsTable> {
  $$MembershipsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ownerKind => $composableBuilder(
    column: $table.ownerKind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupKey => $composableBuilder(
    column: $table.groupKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$ConfigurationsTableFilterComposer get configurationId {
    final $$ConfigurationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.configurationId,
      referencedTable: $db.configurations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConfigurationsTableFilterComposer(
            $db: $db,
            $table: $db.configurations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MembershipsTableOrderingComposer
    extends Composer<_$AppDatabase, $MembershipsTable> {
  $$MembershipsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ownerKind => $composableBuilder(
    column: $table.ownerKind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupKey => $composableBuilder(
    column: $table.groupKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$ConfigurationsTableOrderingComposer get configurationId {
    final $$ConfigurationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.configurationId,
      referencedTable: $db.configurations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConfigurationsTableOrderingComposer(
            $db: $db,
            $table: $db.configurations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MembershipsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MembershipsTable> {
  $$MembershipsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ownerKind =>
      $composableBuilder(column: $table.ownerKind, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get groupKey =>
      $composableBuilder(column: $table.groupKey, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$ConfigurationsTableAnnotationComposer get configurationId {
    final $$ConfigurationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.configurationId,
      referencedTable: $db.configurations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConfigurationsTableAnnotationComposer(
            $db: $db,
            $table: $db.configurations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MembershipsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MembershipsTable,
          MembershipRow,
          $$MembershipsTableFilterComposer,
          $$MembershipsTableOrderingComposer,
          $$MembershipsTableAnnotationComposer,
          $$MembershipsTableCreateCompanionBuilder,
          $$MembershipsTableUpdateCompanionBuilder,
          (MembershipRow, $$MembershipsTableReferences),
          MembershipRow,
          PrefetchHooks Function({bool configurationId})
        > {
  $$MembershipsTableTableManager(_$AppDatabase db, $MembershipsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MembershipsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MembershipsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MembershipsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> ownerKind = const Value.absent(),
                Value<String> ownerId = const Value.absent(),
                Value<String> configurationId = const Value.absent(),
                Value<String> groupKey = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MembershipsCompanion(
                ownerKind: ownerKind,
                ownerId: ownerId,
                configurationId: configurationId,
                groupKey: groupKey,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String ownerKind,
                required String ownerId,
                required String configurationId,
                required String groupKey,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => MembershipsCompanion.insert(
                ownerKind: ownerKind,
                ownerId: ownerId,
                configurationId: configurationId,
                groupKey: groupKey,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MembershipsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({configurationId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (configurationId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.configurationId,
                                referencedTable: $$MembershipsTableReferences
                                    ._configurationIdTable(db),
                                referencedColumn: $$MembershipsTableReferences
                                    ._configurationIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MembershipsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MembershipsTable,
      MembershipRow,
      $$MembershipsTableFilterComposer,
      $$MembershipsTableOrderingComposer,
      $$MembershipsTableAnnotationComposer,
      $$MembershipsTableCreateCompanionBuilder,
      $$MembershipsTableUpdateCompanionBuilder,
      (MembershipRow, $$MembershipsTableReferences),
      MembershipRow,
      PrefetchHooks Function({bool configurationId})
    >;
typedef $$SelectionsTableCreateCompanionBuilder =
    SelectionsCompanion Function({
      required String configurationId,
      required String groupKey,
      required String memberJson,
      required bool manual,
      required int editedAt,
      Value<String?> cloudAccountId,
      Value<String?> documentId,
      Value<int> rowid,
    });
typedef $$SelectionsTableUpdateCompanionBuilder =
    SelectionsCompanion Function({
      Value<String> configurationId,
      Value<String> groupKey,
      Value<String> memberJson,
      Value<bool> manual,
      Value<int> editedAt,
      Value<String?> cloudAccountId,
      Value<String?> documentId,
      Value<int> rowid,
    });

final class $$SelectionsTableReferences
    extends BaseReferences<_$AppDatabase, $SelectionsTable, SelectionRow> {
  $$SelectionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ConfigurationsTable _configurationIdTable(_$AppDatabase db) => db
      .configurations
      .createAlias('selections__configuration_id__configurations__id');

  $$ConfigurationsTableProcessedTableManager get configurationId {
    final $_column = $_itemColumn<String>('configuration_id')!;

    final manager = $$ConfigurationsTableTableManager(
      $_db,
      $_db.configurations,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_configurationIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SelectionsTableFilterComposer
    extends Composer<_$AppDatabase, $SelectionsTable> {
  $$SelectionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get groupKey => $composableBuilder(
    column: $table.groupKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get memberJson => $composableBuilder(
    column: $table.memberJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get manual => $composableBuilder(
    column: $table.manual,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cloudAccountId => $composableBuilder(
    column: $table.cloudAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );

  $$ConfigurationsTableFilterComposer get configurationId {
    final $$ConfigurationsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.configurationId,
      referencedTable: $db.configurations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConfigurationsTableFilterComposer(
            $db: $db,
            $table: $db.configurations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SelectionsTableOrderingComposer
    extends Composer<_$AppDatabase, $SelectionsTable> {
  $$SelectionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get groupKey => $composableBuilder(
    column: $table.groupKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get memberJson => $composableBuilder(
    column: $table.memberJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get manual => $composableBuilder(
    column: $table.manual,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cloudAccountId => $composableBuilder(
    column: $table.cloudAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );

  $$ConfigurationsTableOrderingComposer get configurationId {
    final $$ConfigurationsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.configurationId,
      referencedTable: $db.configurations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConfigurationsTableOrderingComposer(
            $db: $db,
            $table: $db.configurations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SelectionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SelectionsTable> {
  $$SelectionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get groupKey =>
      $composableBuilder(column: $table.groupKey, builder: (column) => column);

  GeneratedColumn<String> get memberJson => $composableBuilder(
    column: $table.memberJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get manual =>
      $composableBuilder(column: $table.manual, builder: (column) => column);

  GeneratedColumn<int> get editedAt =>
      $composableBuilder(column: $table.editedAt, builder: (column) => column);

  GeneratedColumn<String> get cloudAccountId => $composableBuilder(
    column: $table.cloudAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );

  $$ConfigurationsTableAnnotationComposer get configurationId {
    final $$ConfigurationsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.configurationId,
      referencedTable: $db.configurations,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ConfigurationsTableAnnotationComposer(
            $db: $db,
            $table: $db.configurations,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SelectionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SelectionsTable,
          SelectionRow,
          $$SelectionsTableFilterComposer,
          $$SelectionsTableOrderingComposer,
          $$SelectionsTableAnnotationComposer,
          $$SelectionsTableCreateCompanionBuilder,
          $$SelectionsTableUpdateCompanionBuilder,
          (SelectionRow, $$SelectionsTableReferences),
          SelectionRow,
          PrefetchHooks Function({bool configurationId})
        > {
  $$SelectionsTableTableManager(_$AppDatabase db, $SelectionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SelectionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SelectionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SelectionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> configurationId = const Value.absent(),
                Value<String> groupKey = const Value.absent(),
                Value<String> memberJson = const Value.absent(),
                Value<bool> manual = const Value.absent(),
                Value<int> editedAt = const Value.absent(),
                Value<String?> cloudAccountId = const Value.absent(),
                Value<String?> documentId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SelectionsCompanion(
                configurationId: configurationId,
                groupKey: groupKey,
                memberJson: memberJson,
                manual: manual,
                editedAt: editedAt,
                cloudAccountId: cloudAccountId,
                documentId: documentId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String configurationId,
                required String groupKey,
                required String memberJson,
                required bool manual,
                required int editedAt,
                Value<String?> cloudAccountId = const Value.absent(),
                Value<String?> documentId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SelectionsCompanion.insert(
                configurationId: configurationId,
                groupKey: groupKey,
                memberJson: memberJson,
                manual: manual,
                editedAt: editedAt,
                cloudAccountId: cloudAccountId,
                documentId: documentId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SelectionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({configurationId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (configurationId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.configurationId,
                                referencedTable: $$SelectionsTableReferences
                                    ._configurationIdTable(db),
                                referencedColumn: $$SelectionsTableReferences
                                    ._configurationIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SelectionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SelectionsTable,
      SelectionRow,
      $$SelectionsTableFilterComposer,
      $$SelectionsTableOrderingComposer,
      $$SelectionsTableAnnotationComposer,
      $$SelectionsTableCreateCompanionBuilder,
      $$SelectionsTableUpdateCompanionBuilder,
      (SelectionRow, $$SelectionsTableReferences),
      SelectionRow,
      PrefetchHooks Function({bool configurationId})
    >;
typedef $$DeviceSettingsTableTableCreateCompanionBuilder =
    DeviceSettingsTableCompanion Function({
      Value<int> id,
      required String json,
      Value<String?> secretId,
      required int editedAt,
    });
typedef $$DeviceSettingsTableTableUpdateCompanionBuilder =
    DeviceSettingsTableCompanion Function({
      Value<int> id,
      Value<String> json,
      Value<String?> secretId,
      Value<int> editedAt,
    });

class $$DeviceSettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $DeviceSettingsTableTable> {
  $$DeviceSettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get secretId => $composableBuilder(
    column: $table.secretId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$DeviceSettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DeviceSettingsTableTable> {
  $$DeviceSettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get json => $composableBuilder(
    column: $table.json,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get secretId => $composableBuilder(
    column: $table.secretId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DeviceSettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeviceSettingsTableTable> {
  $$DeviceSettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<String> get secretId =>
      $composableBuilder(column: $table.secretId, builder: (column) => column);

  GeneratedColumn<int> get editedAt =>
      $composableBuilder(column: $table.editedAt, builder: (column) => column);
}

class $$DeviceSettingsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DeviceSettingsTableTable,
          DeviceSettingsRow,
          $$DeviceSettingsTableTableFilterComposer,
          $$DeviceSettingsTableTableOrderingComposer,
          $$DeviceSettingsTableTableAnnotationComposer,
          $$DeviceSettingsTableTableCreateCompanionBuilder,
          $$DeviceSettingsTableTableUpdateCompanionBuilder,
          (
            DeviceSettingsRow,
            BaseReferences<
              _$AppDatabase,
              $DeviceSettingsTableTable,
              DeviceSettingsRow
            >,
          ),
          DeviceSettingsRow,
          PrefetchHooks Function()
        > {
  $$DeviceSettingsTableTableTableManager(
    _$AppDatabase db,
    $DeviceSettingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeviceSettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeviceSettingsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$DeviceSettingsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<String?> secretId = const Value.absent(),
                Value<int> editedAt = const Value.absent(),
              }) => DeviceSettingsTableCompanion(
                id: id,
                json: json,
                secretId: secretId,
                editedAt: editedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String json,
                Value<String?> secretId = const Value.absent(),
                required int editedAt,
              }) => DeviceSettingsTableCompanion.insert(
                id: id,
                json: json,
                secretId: secretId,
                editedAt: editedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DeviceSettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DeviceSettingsTableTable,
      DeviceSettingsRow,
      $$DeviceSettingsTableTableFilterComposer,
      $$DeviceSettingsTableTableOrderingComposer,
      $$DeviceSettingsTableTableAnnotationComposer,
      $$DeviceSettingsTableTableCreateCompanionBuilder,
      $$DeviceSettingsTableTableUpdateCompanionBuilder,
      (
        DeviceSettingsRow,
        BaseReferences<
          _$AppDatabase,
          $DeviceSettingsTableTable,
          DeviceSettingsRow
        >,
      ),
      DeviceSettingsRow,
      PrefetchHooks Function()
    >;
typedef $$PolicyTableTableCreateCompanionBuilder =
    PolicyTableCompanion Function({
      Value<int> id,
      Value<String?> overrideSecretId,
      required bool geoAutoUpdate,
      required String geoInterval,
      required String geoVia,
      Value<int?> editedAt,
      Value<String?> cloudAccountId,
      Value<String?> documentId,
    });
typedef $$PolicyTableTableUpdateCompanionBuilder =
    PolicyTableCompanion Function({
      Value<int> id,
      Value<String?> overrideSecretId,
      Value<bool> geoAutoUpdate,
      Value<String> geoInterval,
      Value<String> geoVia,
      Value<int?> editedAt,
      Value<String?> cloudAccountId,
      Value<String?> documentId,
    });

class $$PolicyTableTableFilterComposer
    extends Composer<_$AppDatabase, $PolicyTableTable> {
  $$PolicyTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get overrideSecretId => $composableBuilder(
    column: $table.overrideSecretId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get geoAutoUpdate => $composableBuilder(
    column: $table.geoAutoUpdate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get geoInterval => $composableBuilder(
    column: $table.geoInterval,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get geoVia => $composableBuilder(
    column: $table.geoVia,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cloudAccountId => $composableBuilder(
    column: $table.cloudAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PolicyTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PolicyTableTable> {
  $$PolicyTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get overrideSecretId => $composableBuilder(
    column: $table.overrideSecretId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get geoAutoUpdate => $composableBuilder(
    column: $table.geoAutoUpdate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get geoInterval => $composableBuilder(
    column: $table.geoInterval,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get geoVia => $composableBuilder(
    column: $table.geoVia,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cloudAccountId => $composableBuilder(
    column: $table.cloudAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PolicyTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PolicyTableTable> {
  $$PolicyTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get overrideSecretId => $composableBuilder(
    column: $table.overrideSecretId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get geoAutoUpdate => $composableBuilder(
    column: $table.geoAutoUpdate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get geoInterval => $composableBuilder(
    column: $table.geoInterval,
    builder: (column) => column,
  );

  GeneratedColumn<String> get geoVia =>
      $composableBuilder(column: $table.geoVia, builder: (column) => column);

  GeneratedColumn<int> get editedAt =>
      $composableBuilder(column: $table.editedAt, builder: (column) => column);

  GeneratedColumn<String> get cloudAccountId => $composableBuilder(
    column: $table.cloudAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );
}

class $$PolicyTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PolicyTableTable,
          PolicyRow,
          $$PolicyTableTableFilterComposer,
          $$PolicyTableTableOrderingComposer,
          $$PolicyTableTableAnnotationComposer,
          $$PolicyTableTableCreateCompanionBuilder,
          $$PolicyTableTableUpdateCompanionBuilder,
          (
            PolicyRow,
            BaseReferences<_$AppDatabase, $PolicyTableTable, PolicyRow>,
          ),
          PolicyRow,
          PrefetchHooks Function()
        > {
  $$PolicyTableTableTableManager(_$AppDatabase db, $PolicyTableTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PolicyTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PolicyTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PolicyTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> overrideSecretId = const Value.absent(),
                Value<bool> geoAutoUpdate = const Value.absent(),
                Value<String> geoInterval = const Value.absent(),
                Value<String> geoVia = const Value.absent(),
                Value<int?> editedAt = const Value.absent(),
                Value<String?> cloudAccountId = const Value.absent(),
                Value<String?> documentId = const Value.absent(),
              }) => PolicyTableCompanion(
                id: id,
                overrideSecretId: overrideSecretId,
                geoAutoUpdate: geoAutoUpdate,
                geoInterval: geoInterval,
                geoVia: geoVia,
                editedAt: editedAt,
                cloudAccountId: cloudAccountId,
                documentId: documentId,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String?> overrideSecretId = const Value.absent(),
                required bool geoAutoUpdate,
                required String geoInterval,
                required String geoVia,
                Value<int?> editedAt = const Value.absent(),
                Value<String?> cloudAccountId = const Value.absent(),
                Value<String?> documentId = const Value.absent(),
              }) => PolicyTableCompanion.insert(
                id: id,
                overrideSecretId: overrideSecretId,
                geoAutoUpdate: geoAutoUpdate,
                geoInterval: geoInterval,
                geoVia: geoVia,
                editedAt: editedAt,
                cloudAccountId: cloudAccountId,
                documentId: documentId,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PolicyTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PolicyTableTable,
      PolicyRow,
      $$PolicyTableTableFilterComposer,
      $$PolicyTableTableOrderingComposer,
      $$PolicyTableTableAnnotationComposer,
      $$PolicyTableTableCreateCompanionBuilder,
      $$PolicyTableTableUpdateCompanionBuilder,
      (PolicyRow, BaseReferences<_$AppDatabase, $PolicyTableTable, PolicyRow>),
      PolicyRow,
      PrefetchHooks Function()
    >;
typedef $$RuleResourcesTableCreateCompanionBuilder =
    RuleResourcesCompanion Function({
      required String url,
      required String format,
      Value<String?> file,
      Value<String?> sha256,
      Value<int?> size,
      Value<int?> updatedAt,
      Value<int?> checkedAt,
      Value<String?> lastError,
      Value<int> skipped,
      Value<int> rowid,
    });
typedef $$RuleResourcesTableUpdateCompanionBuilder =
    RuleResourcesCompanion Function({
      Value<String> url,
      Value<String> format,
      Value<String?> file,
      Value<String?> sha256,
      Value<int?> size,
      Value<int?> updatedAt,
      Value<int?> checkedAt,
      Value<String?> lastError,
      Value<int> skipped,
      Value<int> rowid,
    });

class $$RuleResourcesTableFilterComposer
    extends Composer<_$AppDatabase, $RuleResourcesTable> {
  $$RuleResourcesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get file => $composableBuilder(
    column: $table.file,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get checkedAt => $composableBuilder(
    column: $table.checkedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get skipped => $composableBuilder(
    column: $table.skipped,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RuleResourcesTableOrderingComposer
    extends Composer<_$AppDatabase, $RuleResourcesTable> {
  $$RuleResourcesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get url => $composableBuilder(
    column: $table.url,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get file => $composableBuilder(
    column: $table.file,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sha256 => $composableBuilder(
    column: $table.sha256,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get size => $composableBuilder(
    column: $table.size,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get checkedAt => $composableBuilder(
    column: $table.checkedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get skipped => $composableBuilder(
    column: $table.skipped,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RuleResourcesTableAnnotationComposer
    extends Composer<_$AppDatabase, $RuleResourcesTable> {
  $$RuleResourcesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get url =>
      $composableBuilder(column: $table.url, builder: (column) => column);

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<String> get file =>
      $composableBuilder(column: $table.file, builder: (column) => column);

  GeneratedColumn<String> get sha256 =>
      $composableBuilder(column: $table.sha256, builder: (column) => column);

  GeneratedColumn<int> get size =>
      $composableBuilder(column: $table.size, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get checkedAt =>
      $composableBuilder(column: $table.checkedAt, builder: (column) => column);

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<int> get skipped =>
      $composableBuilder(column: $table.skipped, builder: (column) => column);
}

class $$RuleResourcesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RuleResourcesTable,
          RuleResourceRow,
          $$RuleResourcesTableFilterComposer,
          $$RuleResourcesTableOrderingComposer,
          $$RuleResourcesTableAnnotationComposer,
          $$RuleResourcesTableCreateCompanionBuilder,
          $$RuleResourcesTableUpdateCompanionBuilder,
          (
            RuleResourceRow,
            BaseReferences<_$AppDatabase, $RuleResourcesTable, RuleResourceRow>,
          ),
          RuleResourceRow,
          PrefetchHooks Function()
        > {
  $$RuleResourcesTableTableManager(_$AppDatabase db, $RuleResourcesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RuleResourcesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RuleResourcesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RuleResourcesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> url = const Value.absent(),
                Value<String> format = const Value.absent(),
                Value<String?> file = const Value.absent(),
                Value<String?> sha256 = const Value.absent(),
                Value<int?> size = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> checkedAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> skipped = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RuleResourcesCompanion(
                url: url,
                format: format,
                file: file,
                sha256: sha256,
                size: size,
                updatedAt: updatedAt,
                checkedAt: checkedAt,
                lastError: lastError,
                skipped: skipped,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String url,
                required String format,
                Value<String?> file = const Value.absent(),
                Value<String?> sha256 = const Value.absent(),
                Value<int?> size = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> checkedAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> skipped = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RuleResourcesCompanion.insert(
                url: url,
                format: format,
                file: file,
                sha256: sha256,
                size: size,
                updatedAt: updatedAt,
                checkedAt: checkedAt,
                lastError: lastError,
                skipped: skipped,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RuleResourcesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RuleResourcesTable,
      RuleResourceRow,
      $$RuleResourcesTableFilterComposer,
      $$RuleResourcesTableOrderingComposer,
      $$RuleResourcesTableAnnotationComposer,
      $$RuleResourcesTableCreateCompanionBuilder,
      $$RuleResourcesTableUpdateCompanionBuilder,
      (
        RuleResourceRow,
        BaseReferences<_$AppDatabase, $RuleResourcesTable, RuleResourceRow>,
      ),
      RuleResourceRow,
      PrefetchHooks Function()
    >;
typedef $$SecretsTableCreateCompanionBuilder =
    SecretsCompanion Function({
      required String id,
      required Uint8List nonce,
      required Uint8List ciphertext,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$SecretsTableUpdateCompanionBuilder =
    SecretsCompanion Function({
      Value<String> id,
      Value<Uint8List> nonce,
      Value<Uint8List> ciphertext,
      Value<int> createdAt,
      Value<int> rowid,
    });

class $$SecretsTableFilterComposer
    extends Composer<_$AppDatabase, $SecretsTable> {
  $$SecretsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get nonce => $composableBuilder(
    column: $table.nonce,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get ciphertext => $composableBuilder(
    column: $table.ciphertext,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SecretsTableOrderingComposer
    extends Composer<_$AppDatabase, $SecretsTable> {
  $$SecretsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get nonce => $composableBuilder(
    column: $table.nonce,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get ciphertext => $composableBuilder(
    column: $table.ciphertext,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SecretsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SecretsTable> {
  $$SecretsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<Uint8List> get nonce =>
      $composableBuilder(column: $table.nonce, builder: (column) => column);

  GeneratedColumn<Uint8List> get ciphertext => $composableBuilder(
    column: $table.ciphertext,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SecretsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SecretsTable,
          SecretRow,
          $$SecretsTableFilterComposer,
          $$SecretsTableOrderingComposer,
          $$SecretsTableAnnotationComposer,
          $$SecretsTableCreateCompanionBuilder,
          $$SecretsTableUpdateCompanionBuilder,
          (SecretRow, BaseReferences<_$AppDatabase, $SecretsTable, SecretRow>),
          SecretRow,
          PrefetchHooks Function()
        > {
  $$SecretsTableTableManager(_$AppDatabase db, $SecretsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SecretsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SecretsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SecretsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<Uint8List> nonce = const Value.absent(),
                Value<Uint8List> ciphertext = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SecretsCompanion(
                id: id,
                nonce: nonce,
                ciphertext: ciphertext,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required Uint8List nonce,
                required Uint8List ciphertext,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => SecretsCompanion.insert(
                id: id,
                nonce: nonce,
                ciphertext: ciphertext,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SecretsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SecretsTable,
      SecretRow,
      $$SecretsTableFilterComposer,
      $$SecretsTableOrderingComposer,
      $$SecretsTableAnnotationComposer,
      $$SecretsTableCreateCompanionBuilder,
      $$SecretsTableUpdateCompanionBuilder,
      (SecretRow, BaseReferences<_$AppDatabase, $SecretsTable, SecretRow>),
      SecretRow,
      PrefetchHooks Function()
    >;
typedef $$CloudSessionTableCreateCompanionBuilder =
    CloudSessionCompanion Function({
      Value<int> id,
      required String accountId,
      required String email,
      required String displayName,
      required String deviceId,
      required String installationId,
      required String accessSecretId,
      required String refreshSecretId,
      required String entitlementJson,
      required bool loggedIn,
      required int updatedAt,
    });
typedef $$CloudSessionTableUpdateCompanionBuilder =
    CloudSessionCompanion Function({
      Value<int> id,
      Value<String> accountId,
      Value<String> email,
      Value<String> displayName,
      Value<String> deviceId,
      Value<String> installationId,
      Value<String> accessSecretId,
      Value<String> refreshSecretId,
      Value<String> entitlementJson,
      Value<bool> loggedIn,
      Value<int> updatedAt,
    });

class $$CloudSessionTableFilterComposer
    extends Composer<_$AppDatabase, $CloudSessionTable> {
  $$CloudSessionTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get installationId => $composableBuilder(
    column: $table.installationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accessSecretId => $composableBuilder(
    column: $table.accessSecretId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get refreshSecretId => $composableBuilder(
    column: $table.refreshSecretId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entitlementJson => $composableBuilder(
    column: $table.entitlementJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get loggedIn => $composableBuilder(
    column: $table.loggedIn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CloudSessionTableOrderingComposer
    extends Composer<_$AppDatabase, $CloudSessionTable> {
  $$CloudSessionTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deviceId => $composableBuilder(
    column: $table.deviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get installationId => $composableBuilder(
    column: $table.installationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accessSecretId => $composableBuilder(
    column: $table.accessSecretId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get refreshSecretId => $composableBuilder(
    column: $table.refreshSecretId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entitlementJson => $composableBuilder(
    column: $table.entitlementJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get loggedIn => $composableBuilder(
    column: $table.loggedIn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CloudSessionTableAnnotationComposer
    extends Composer<_$AppDatabase, $CloudSessionTable> {
  $$CloudSessionTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<String> get installationId => $composableBuilder(
    column: $table.installationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accessSecretId => $composableBuilder(
    column: $table.accessSecretId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get refreshSecretId => $composableBuilder(
    column: $table.refreshSecretId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entitlementJson => $composableBuilder(
    column: $table.entitlementJson,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get loggedIn =>
      $composableBuilder(column: $table.loggedIn, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CloudSessionTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CloudSessionTable,
          CloudSessionRow,
          $$CloudSessionTableFilterComposer,
          $$CloudSessionTableOrderingComposer,
          $$CloudSessionTableAnnotationComposer,
          $$CloudSessionTableCreateCompanionBuilder,
          $$CloudSessionTableUpdateCompanionBuilder,
          (
            CloudSessionRow,
            BaseReferences<_$AppDatabase, $CloudSessionTable, CloudSessionRow>,
          ),
          CloudSessionRow,
          PrefetchHooks Function()
        > {
  $$CloudSessionTableTableManager(_$AppDatabase db, $CloudSessionTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CloudSessionTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CloudSessionTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CloudSessionTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<String> installationId = const Value.absent(),
                Value<String> accessSecretId = const Value.absent(),
                Value<String> refreshSecretId = const Value.absent(),
                Value<String> entitlementJson = const Value.absent(),
                Value<bool> loggedIn = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => CloudSessionCompanion(
                id: id,
                accountId: accountId,
                email: email,
                displayName: displayName,
                deviceId: deviceId,
                installationId: installationId,
                accessSecretId: accessSecretId,
                refreshSecretId: refreshSecretId,
                entitlementJson: entitlementJson,
                loggedIn: loggedIn,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String accountId,
                required String email,
                required String displayName,
                required String deviceId,
                required String installationId,
                required String accessSecretId,
                required String refreshSecretId,
                required String entitlementJson,
                required bool loggedIn,
                required int updatedAt,
              }) => CloudSessionCompanion.insert(
                id: id,
                accountId: accountId,
                email: email,
                displayName: displayName,
                deviceId: deviceId,
                installationId: installationId,
                accessSecretId: accessSecretId,
                refreshSecretId: refreshSecretId,
                entitlementJson: entitlementJson,
                loggedIn: loggedIn,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CloudSessionTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CloudSessionTable,
      CloudSessionRow,
      $$CloudSessionTableFilterComposer,
      $$CloudSessionTableOrderingComposer,
      $$CloudSessionTableAnnotationComposer,
      $$CloudSessionTableCreateCompanionBuilder,
      $$CloudSessionTableUpdateCompanionBuilder,
      (
        CloudSessionRow,
        BaseReferences<_$AppDatabase, $CloudSessionTable, CloudSessionRow>,
      ),
      CloudSessionRow,
      PrefetchHooks Function()
    >;
typedef $$SyncMetaTableCreateCompanionBuilder =
    SyncMetaCompanion Function({
      required String recordId,
      required String type,
      required String accountId,
      required String documentId,
      Value<int?> remoteRevision,
      required bool dirty,
      required bool deleted,
      required int editedAt,
      Value<String?> mutationId,
      Value<String?> pendingEnvelopeSecretId,
      Value<String?> inFlightMutationId,
      Value<String?> inFlightEnvelopeSecretId,
      Value<String?> syncGeneration,
      Value<int> rowid,
    });
typedef $$SyncMetaTableUpdateCompanionBuilder =
    SyncMetaCompanion Function({
      Value<String> recordId,
      Value<String> type,
      Value<String> accountId,
      Value<String> documentId,
      Value<int?> remoteRevision,
      Value<bool> dirty,
      Value<bool> deleted,
      Value<int> editedAt,
      Value<String?> mutationId,
      Value<String?> pendingEnvelopeSecretId,
      Value<String?> inFlightMutationId,
      Value<String?> inFlightEnvelopeSecretId,
      Value<String?> syncGeneration,
      Value<int> rowid,
    });

class $$SyncMetaTableFilterComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remoteRevision => $composableBuilder(
    column: $table.remoteRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mutationId => $composableBuilder(
    column: $table.mutationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pendingEnvelopeSecretId => $composableBuilder(
    column: $table.pendingEnvelopeSecretId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inFlightMutationId => $composableBuilder(
    column: $table.inFlightMutationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get inFlightEnvelopeSecretId => $composableBuilder(
    column: $table.inFlightEnvelopeSecretId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncGeneration => $composableBuilder(
    column: $table.syncGeneration,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncMetaTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remoteRevision => $composableBuilder(
    column: $table.remoteRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get editedAt => $composableBuilder(
    column: $table.editedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mutationId => $composableBuilder(
    column: $table.mutationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pendingEnvelopeSecretId => $composableBuilder(
    column: $table.pendingEnvelopeSecretId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inFlightMutationId => $composableBuilder(
    column: $table.inFlightMutationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get inFlightEnvelopeSecretId => $composableBuilder(
    column: $table.inFlightEnvelopeSecretId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncGeneration => $composableBuilder(
    column: $table.syncGeneration,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncMetaTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncMetaTable> {
  $$SyncMetaTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get remoteRevision => $composableBuilder(
    column: $table.remoteRevision,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);

  GeneratedColumn<bool> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<int> get editedAt =>
      $composableBuilder(column: $table.editedAt, builder: (column) => column);

  GeneratedColumn<String> get mutationId => $composableBuilder(
    column: $table.mutationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pendingEnvelopeSecretId => $composableBuilder(
    column: $table.pendingEnvelopeSecretId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get inFlightMutationId => $composableBuilder(
    column: $table.inFlightMutationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get inFlightEnvelopeSecretId => $composableBuilder(
    column: $table.inFlightEnvelopeSecretId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncGeneration => $composableBuilder(
    column: $table.syncGeneration,
    builder: (column) => column,
  );
}

class $$SyncMetaTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncMetaTable,
          SyncMetaRow,
          $$SyncMetaTableFilterComposer,
          $$SyncMetaTableOrderingComposer,
          $$SyncMetaTableAnnotationComposer,
          $$SyncMetaTableCreateCompanionBuilder,
          $$SyncMetaTableUpdateCompanionBuilder,
          (
            SyncMetaRow,
            BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaRow>,
          ),
          SyncMetaRow,
          PrefetchHooks Function()
        > {
  $$SyncMetaTableTableManager(_$AppDatabase db, $SyncMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> recordId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String> documentId = const Value.absent(),
                Value<int?> remoteRevision = const Value.absent(),
                Value<bool> dirty = const Value.absent(),
                Value<bool> deleted = const Value.absent(),
                Value<int> editedAt = const Value.absent(),
                Value<String?> mutationId = const Value.absent(),
                Value<String?> pendingEnvelopeSecretId = const Value.absent(),
                Value<String?> inFlightMutationId = const Value.absent(),
                Value<String?> inFlightEnvelopeSecretId = const Value.absent(),
                Value<String?> syncGeneration = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetaCompanion(
                recordId: recordId,
                type: type,
                accountId: accountId,
                documentId: documentId,
                remoteRevision: remoteRevision,
                dirty: dirty,
                deleted: deleted,
                editedAt: editedAt,
                mutationId: mutationId,
                pendingEnvelopeSecretId: pendingEnvelopeSecretId,
                inFlightMutationId: inFlightMutationId,
                inFlightEnvelopeSecretId: inFlightEnvelopeSecretId,
                syncGeneration: syncGeneration,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String recordId,
                required String type,
                required String accountId,
                required String documentId,
                Value<int?> remoteRevision = const Value.absent(),
                required bool dirty,
                required bool deleted,
                required int editedAt,
                Value<String?> mutationId = const Value.absent(),
                Value<String?> pendingEnvelopeSecretId = const Value.absent(),
                Value<String?> inFlightMutationId = const Value.absent(),
                Value<String?> inFlightEnvelopeSecretId = const Value.absent(),
                Value<String?> syncGeneration = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncMetaCompanion.insert(
                recordId: recordId,
                type: type,
                accountId: accountId,
                documentId: documentId,
                remoteRevision: remoteRevision,
                dirty: dirty,
                deleted: deleted,
                editedAt: editedAt,
                mutationId: mutationId,
                pendingEnvelopeSecretId: pendingEnvelopeSecretId,
                inFlightMutationId: inFlightMutationId,
                inFlightEnvelopeSecretId: inFlightEnvelopeSecretId,
                syncGeneration: syncGeneration,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncMetaTable,
      SyncMetaRow,
      $$SyncMetaTableFilterComposer,
      $$SyncMetaTableOrderingComposer,
      $$SyncMetaTableAnnotationComposer,
      $$SyncMetaTableCreateCompanionBuilder,
      $$SyncMetaTableUpdateCompanionBuilder,
      (SyncMetaRow, BaseReferences<_$AppDatabase, $SyncMetaTable, SyncMetaRow>),
      SyncMetaRow,
      PrefetchHooks Function()
    >;
typedef $$SyncDocumentsTableCreateCompanionBuilder =
    SyncDocumentsCompanion Function({
      required String documentId,
      Value<String?> accountId,
      required String recordId,
      required String type,
      Value<String?> localId,
      Value<int?> remoteRevision,
      Value<int?> remoteEditedAt,
      Value<bool?> remoteDeleted,
      Value<int?> remoteSchemaVersion,
      Value<String?> remotePayloadSecretId,
      Value<String?> localPayloadSecretId,
      required int localEditedAt,
      required bool localDeleted,
      Value<int> localSchemaVersion,
      Value<String?> syncGeneration,
      Value<bool> pendingMerge,
      Value<int> rowid,
    });
typedef $$SyncDocumentsTableUpdateCompanionBuilder =
    SyncDocumentsCompanion Function({
      Value<String> documentId,
      Value<String?> accountId,
      Value<String> recordId,
      Value<String> type,
      Value<String?> localId,
      Value<int?> remoteRevision,
      Value<int?> remoteEditedAt,
      Value<bool?> remoteDeleted,
      Value<int?> remoteSchemaVersion,
      Value<String?> remotePayloadSecretId,
      Value<String?> localPayloadSecretId,
      Value<int> localEditedAt,
      Value<bool> localDeleted,
      Value<int> localSchemaVersion,
      Value<String?> syncGeneration,
      Value<bool> pendingMerge,
      Value<int> rowid,
    });

class $$SyncDocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncDocumentsTable> {
  $$SyncDocumentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remoteRevision => $composableBuilder(
    column: $table.remoteRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remoteEditedAt => $composableBuilder(
    column: $table.remoteEditedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get remoteDeleted => $composableBuilder(
    column: $table.remoteDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get remoteSchemaVersion => $composableBuilder(
    column: $table.remoteSchemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remotePayloadSecretId => $composableBuilder(
    column: $table.remotePayloadSecretId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPayloadSecretId => $composableBuilder(
    column: $table.localPayloadSecretId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get localEditedAt => $composableBuilder(
    column: $table.localEditedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get localDeleted => $composableBuilder(
    column: $table.localDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get localSchemaVersion => $composableBuilder(
    column: $table.localSchemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncGeneration => $composableBuilder(
    column: $table.syncGeneration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get pendingMerge => $composableBuilder(
    column: $table.pendingMerge,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncDocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncDocumentsTable> {
  $$SyncDocumentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localId => $composableBuilder(
    column: $table.localId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remoteRevision => $composableBuilder(
    column: $table.remoteRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remoteEditedAt => $composableBuilder(
    column: $table.remoteEditedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get remoteDeleted => $composableBuilder(
    column: $table.remoteDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get remoteSchemaVersion => $composableBuilder(
    column: $table.remoteSchemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remotePayloadSecretId => $composableBuilder(
    column: $table.remotePayloadSecretId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPayloadSecretId => $composableBuilder(
    column: $table.localPayloadSecretId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get localEditedAt => $composableBuilder(
    column: $table.localEditedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get localDeleted => $composableBuilder(
    column: $table.localDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get localSchemaVersion => $composableBuilder(
    column: $table.localSchemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncGeneration => $composableBuilder(
    column: $table.syncGeneration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get pendingMerge => $composableBuilder(
    column: $table.pendingMerge,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncDocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncDocumentsTable> {
  $$SyncDocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get localId =>
      $composableBuilder(column: $table.localId, builder: (column) => column);

  GeneratedColumn<int> get remoteRevision => $composableBuilder(
    column: $table.remoteRevision,
    builder: (column) => column,
  );

  GeneratedColumn<int> get remoteEditedAt => $composableBuilder(
    column: $table.remoteEditedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get remoteDeleted => $composableBuilder(
    column: $table.remoteDeleted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get remoteSchemaVersion => $composableBuilder(
    column: $table.remoteSchemaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remotePayloadSecretId => $composableBuilder(
    column: $table.remotePayloadSecretId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localPayloadSecretId => $composableBuilder(
    column: $table.localPayloadSecretId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get localEditedAt => $composableBuilder(
    column: $table.localEditedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get localDeleted => $composableBuilder(
    column: $table.localDeleted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get localSchemaVersion => $composableBuilder(
    column: $table.localSchemaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncGeneration => $composableBuilder(
    column: $table.syncGeneration,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get pendingMerge => $composableBuilder(
    column: $table.pendingMerge,
    builder: (column) => column,
  );
}

class $$SyncDocumentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncDocumentsTable,
          SyncDocumentRow,
          $$SyncDocumentsTableFilterComposer,
          $$SyncDocumentsTableOrderingComposer,
          $$SyncDocumentsTableAnnotationComposer,
          $$SyncDocumentsTableCreateCompanionBuilder,
          $$SyncDocumentsTableUpdateCompanionBuilder,
          (
            SyncDocumentRow,
            BaseReferences<_$AppDatabase, $SyncDocumentsTable, SyncDocumentRow>,
          ),
          SyncDocumentRow,
          PrefetchHooks Function()
        > {
  $$SyncDocumentsTableTableManager(_$AppDatabase db, $SyncDocumentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncDocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncDocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncDocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> documentId = const Value.absent(),
                Value<String?> accountId = const Value.absent(),
                Value<String> recordId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String?> localId = const Value.absent(),
                Value<int?> remoteRevision = const Value.absent(),
                Value<int?> remoteEditedAt = const Value.absent(),
                Value<bool?> remoteDeleted = const Value.absent(),
                Value<int?> remoteSchemaVersion = const Value.absent(),
                Value<String?> remotePayloadSecretId = const Value.absent(),
                Value<String?> localPayloadSecretId = const Value.absent(),
                Value<int> localEditedAt = const Value.absent(),
                Value<bool> localDeleted = const Value.absent(),
                Value<int> localSchemaVersion = const Value.absent(),
                Value<String?> syncGeneration = const Value.absent(),
                Value<bool> pendingMerge = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncDocumentsCompanion(
                documentId: documentId,
                accountId: accountId,
                recordId: recordId,
                type: type,
                localId: localId,
                remoteRevision: remoteRevision,
                remoteEditedAt: remoteEditedAt,
                remoteDeleted: remoteDeleted,
                remoteSchemaVersion: remoteSchemaVersion,
                remotePayloadSecretId: remotePayloadSecretId,
                localPayloadSecretId: localPayloadSecretId,
                localEditedAt: localEditedAt,
                localDeleted: localDeleted,
                localSchemaVersion: localSchemaVersion,
                syncGeneration: syncGeneration,
                pendingMerge: pendingMerge,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String documentId,
                Value<String?> accountId = const Value.absent(),
                required String recordId,
                required String type,
                Value<String?> localId = const Value.absent(),
                Value<int?> remoteRevision = const Value.absent(),
                Value<int?> remoteEditedAt = const Value.absent(),
                Value<bool?> remoteDeleted = const Value.absent(),
                Value<int?> remoteSchemaVersion = const Value.absent(),
                Value<String?> remotePayloadSecretId = const Value.absent(),
                Value<String?> localPayloadSecretId = const Value.absent(),
                required int localEditedAt,
                required bool localDeleted,
                Value<int> localSchemaVersion = const Value.absent(),
                Value<String?> syncGeneration = const Value.absent(),
                Value<bool> pendingMerge = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncDocumentsCompanion.insert(
                documentId: documentId,
                accountId: accountId,
                recordId: recordId,
                type: type,
                localId: localId,
                remoteRevision: remoteRevision,
                remoteEditedAt: remoteEditedAt,
                remoteDeleted: remoteDeleted,
                remoteSchemaVersion: remoteSchemaVersion,
                remotePayloadSecretId: remotePayloadSecretId,
                localPayloadSecretId: localPayloadSecretId,
                localEditedAt: localEditedAt,
                localDeleted: localDeleted,
                localSchemaVersion: localSchemaVersion,
                syncGeneration: syncGeneration,
                pendingMerge: pendingMerge,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncDocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncDocumentsTable,
      SyncDocumentRow,
      $$SyncDocumentsTableFilterComposer,
      $$SyncDocumentsTableOrderingComposer,
      $$SyncDocumentsTableAnnotationComposer,
      $$SyncDocumentsTableCreateCompanionBuilder,
      $$SyncDocumentsTableUpdateCompanionBuilder,
      (
        SyncDocumentRow,
        BaseReferences<_$AppDatabase, $SyncDocumentsTable, SyncDocumentRow>,
      ),
      SyncDocumentRow,
      PrefetchHooks Function()
    >;
typedef $$SourceProvenanceTableCreateCompanionBuilder =
    SourceProvenanceCompanion Function({
      required String documentId,
      required String origin,
      Value<String?> originAccountId,
      required String sourceGeneration,
      Value<String?> privateConsentGeneration,
      Value<int> rowid,
    });
typedef $$SourceProvenanceTableUpdateCompanionBuilder =
    SourceProvenanceCompanion Function({
      Value<String> documentId,
      Value<String> origin,
      Value<String?> originAccountId,
      Value<String> sourceGeneration,
      Value<String?> privateConsentGeneration,
      Value<int> rowid,
    });

class $$SourceProvenanceTableFilterComposer
    extends Composer<_$AppDatabase, $SourceProvenanceTable> {
  $$SourceProvenanceTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originAccountId => $composableBuilder(
    column: $table.originAccountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceGeneration => $composableBuilder(
    column: $table.sourceGeneration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get privateConsentGeneration => $composableBuilder(
    column: $table.privateConsentGeneration,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SourceProvenanceTableOrderingComposer
    extends Composer<_$AppDatabase, $SourceProvenanceTable> {
  $$SourceProvenanceTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get origin => $composableBuilder(
    column: $table.origin,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originAccountId => $composableBuilder(
    column: $table.originAccountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceGeneration => $composableBuilder(
    column: $table.sourceGeneration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get privateConsentGeneration => $composableBuilder(
    column: $table.privateConsentGeneration,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SourceProvenanceTableAnnotationComposer
    extends Composer<_$AppDatabase, $SourceProvenanceTable> {
  $$SourceProvenanceTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get origin =>
      $composableBuilder(column: $table.origin, builder: (column) => column);

  GeneratedColumn<String> get originAccountId => $composableBuilder(
    column: $table.originAccountId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceGeneration => $composableBuilder(
    column: $table.sourceGeneration,
    builder: (column) => column,
  );

  GeneratedColumn<String> get privateConsentGeneration => $composableBuilder(
    column: $table.privateConsentGeneration,
    builder: (column) => column,
  );
}

class $$SourceProvenanceTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SourceProvenanceTable,
          SourceProvenanceRow,
          $$SourceProvenanceTableFilterComposer,
          $$SourceProvenanceTableOrderingComposer,
          $$SourceProvenanceTableAnnotationComposer,
          $$SourceProvenanceTableCreateCompanionBuilder,
          $$SourceProvenanceTableUpdateCompanionBuilder,
          (
            SourceProvenanceRow,
            BaseReferences<
              _$AppDatabase,
              $SourceProvenanceTable,
              SourceProvenanceRow
            >,
          ),
          SourceProvenanceRow,
          PrefetchHooks Function()
        > {
  $$SourceProvenanceTableTableManager(
    _$AppDatabase db,
    $SourceProvenanceTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SourceProvenanceTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SourceProvenanceTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SourceProvenanceTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> documentId = const Value.absent(),
                Value<String> origin = const Value.absent(),
                Value<String?> originAccountId = const Value.absent(),
                Value<String> sourceGeneration = const Value.absent(),
                Value<String?> privateConsentGeneration = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SourceProvenanceCompanion(
                documentId: documentId,
                origin: origin,
                originAccountId: originAccountId,
                sourceGeneration: sourceGeneration,
                privateConsentGeneration: privateConsentGeneration,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String documentId,
                required String origin,
                Value<String?> originAccountId = const Value.absent(),
                required String sourceGeneration,
                Value<String?> privateConsentGeneration = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SourceProvenanceCompanion.insert(
                documentId: documentId,
                origin: origin,
                originAccountId: originAccountId,
                sourceGeneration: sourceGeneration,
                privateConsentGeneration: privateConsentGeneration,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SourceProvenanceTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SourceProvenanceTable,
      SourceProvenanceRow,
      $$SourceProvenanceTableFilterComposer,
      $$SourceProvenanceTableOrderingComposer,
      $$SourceProvenanceTableAnnotationComposer,
      $$SourceProvenanceTableCreateCompanionBuilder,
      $$SourceProvenanceTableUpdateCompanionBuilder,
      (
        SourceProvenanceRow,
        BaseReferences<
          _$AppDatabase,
          $SourceProvenanceTable,
          SourceProvenanceRow
        >,
      ),
      SourceProvenanceRow,
      PrefetchHooks Function()
    >;
typedef $$SyncStateTableCreateCompanionBuilder =
    SyncStateCompanion Function({
      required String accountId,
      required int cursor,
      Value<int?> lastSyncAt,
      Value<String?> blockedReason,
      Value<bool> bootstrapCompleted,
      Value<String?> syncGeneration,
      Value<String> backupState,
      Value<String?> rebuildAttemptId,
      Value<String?> rebuildLocalAttemptId,
      Value<String?> rebuildManifestSecretId,
      Value<String?> rebuildControlSecretId,
      Value<int> rowid,
    });
typedef $$SyncStateTableUpdateCompanionBuilder =
    SyncStateCompanion Function({
      Value<String> accountId,
      Value<int> cursor,
      Value<int?> lastSyncAt,
      Value<String?> blockedReason,
      Value<bool> bootstrapCompleted,
      Value<String?> syncGeneration,
      Value<String> backupState,
      Value<String?> rebuildAttemptId,
      Value<String?> rebuildLocalAttemptId,
      Value<String?> rebuildManifestSecretId,
      Value<String?> rebuildControlSecretId,
      Value<int> rowid,
    });

class $$SyncStateTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get blockedReason => $composableBuilder(
    column: $table.blockedReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get bootstrapCompleted => $composableBuilder(
    column: $table.bootstrapCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncGeneration => $composableBuilder(
    column: $table.syncGeneration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get backupState => $composableBuilder(
    column: $table.backupState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rebuildAttemptId => $composableBuilder(
    column: $table.rebuildAttemptId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rebuildLocalAttemptId => $composableBuilder(
    column: $table.rebuildLocalAttemptId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rebuildManifestSecretId => $composableBuilder(
    column: $table.rebuildManifestSecretId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rebuildControlSecretId => $composableBuilder(
    column: $table.rebuildControlSecretId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStateTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get blockedReason => $composableBuilder(
    column: $table.blockedReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get bootstrapCompleted => $composableBuilder(
    column: $table.bootstrapCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncGeneration => $composableBuilder(
    column: $table.syncGeneration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get backupState => $composableBuilder(
    column: $table.backupState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rebuildAttemptId => $composableBuilder(
    column: $table.rebuildAttemptId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rebuildLocalAttemptId => $composableBuilder(
    column: $table.rebuildLocalAttemptId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rebuildManifestSecretId => $composableBuilder(
    column: $table.rebuildManifestSecretId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rebuildControlSecretId => $composableBuilder(
    column: $table.rebuildControlSecretId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<int> get cursor =>
      $composableBuilder(column: $table.cursor, builder: (column) => column);

  GeneratedColumn<int> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get blockedReason => $composableBuilder(
    column: $table.blockedReason,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get bootstrapCompleted => $composableBuilder(
    column: $table.bootstrapCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncGeneration => $composableBuilder(
    column: $table.syncGeneration,
    builder: (column) => column,
  );

  GeneratedColumn<String> get backupState => $composableBuilder(
    column: $table.backupState,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rebuildAttemptId => $composableBuilder(
    column: $table.rebuildAttemptId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rebuildLocalAttemptId => $composableBuilder(
    column: $table.rebuildLocalAttemptId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rebuildManifestSecretId => $composableBuilder(
    column: $table.rebuildManifestSecretId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rebuildControlSecretId => $composableBuilder(
    column: $table.rebuildControlSecretId,
    builder: (column) => column,
  );
}

class $$SyncStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStateTable,
          SyncStateRow,
          $$SyncStateTableFilterComposer,
          $$SyncStateTableOrderingComposer,
          $$SyncStateTableAnnotationComposer,
          $$SyncStateTableCreateCompanionBuilder,
          $$SyncStateTableUpdateCompanionBuilder,
          (
            SyncStateRow,
            BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateRow>,
          ),
          SyncStateRow,
          PrefetchHooks Function()
        > {
  $$SyncStateTableTableManager(_$AppDatabase db, $SyncStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<int> cursor = const Value.absent(),
                Value<int?> lastSyncAt = const Value.absent(),
                Value<String?> blockedReason = const Value.absent(),
                Value<bool> bootstrapCompleted = const Value.absent(),
                Value<String?> syncGeneration = const Value.absent(),
                Value<String> backupState = const Value.absent(),
                Value<String?> rebuildAttemptId = const Value.absent(),
                Value<String?> rebuildLocalAttemptId = const Value.absent(),
                Value<String?> rebuildManifestSecretId = const Value.absent(),
                Value<String?> rebuildControlSecretId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateCompanion(
                accountId: accountId,
                cursor: cursor,
                lastSyncAt: lastSyncAt,
                blockedReason: blockedReason,
                bootstrapCompleted: bootstrapCompleted,
                syncGeneration: syncGeneration,
                backupState: backupState,
                rebuildAttemptId: rebuildAttemptId,
                rebuildLocalAttemptId: rebuildLocalAttemptId,
                rebuildManifestSecretId: rebuildManifestSecretId,
                rebuildControlSecretId: rebuildControlSecretId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required int cursor,
                Value<int?> lastSyncAt = const Value.absent(),
                Value<String?> blockedReason = const Value.absent(),
                Value<bool> bootstrapCompleted = const Value.absent(),
                Value<String?> syncGeneration = const Value.absent(),
                Value<String> backupState = const Value.absent(),
                Value<String?> rebuildAttemptId = const Value.absent(),
                Value<String?> rebuildLocalAttemptId = const Value.absent(),
                Value<String?> rebuildManifestSecretId = const Value.absent(),
                Value<String?> rebuildControlSecretId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateCompanion.insert(
                accountId: accountId,
                cursor: cursor,
                lastSyncAt: lastSyncAt,
                blockedReason: blockedReason,
                bootstrapCompleted: bootstrapCompleted,
                syncGeneration: syncGeneration,
                backupState: backupState,
                rebuildAttemptId: rebuildAttemptId,
                rebuildLocalAttemptId: rebuildLocalAttemptId,
                rebuildManifestSecretId: rebuildManifestSecretId,
                rebuildControlSecretId: rebuildControlSecretId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStateTable,
      SyncStateRow,
      $$SyncStateTableFilterComposer,
      $$SyncStateTableOrderingComposer,
      $$SyncStateTableAnnotationComposer,
      $$SyncStateTableCreateCompanionBuilder,
      $$SyncStateTableUpdateCompanionBuilder,
      (
        SyncStateRow,
        BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateRow>,
      ),
      SyncStateRow,
      PrefetchHooks Function()
    >;
typedef $$SyncArchivesTableCreateCompanionBuilder =
    SyncArchivesCompanion Function({
      required String id,
      required String accountId,
      Value<String?> syncGeneration,
      required String payloadSecretId,
      required int createdAt,
      Value<int> rowid,
    });
typedef $$SyncArchivesTableUpdateCompanionBuilder =
    SyncArchivesCompanion Function({
      Value<String> id,
      Value<String> accountId,
      Value<String?> syncGeneration,
      Value<String> payloadSecretId,
      Value<int> createdAt,
      Value<int> rowid,
    });

final class $$SyncArchivesTableReferences
    extends BaseReferences<_$AppDatabase, $SyncArchivesTable, SyncArchiveRow> {
  $$SyncArchivesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $SyncArchiveReferencesTable,
    List<SyncArchiveReferenceRow>
  >
  _syncArchiveReferencesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.syncArchiveReferences,
        aliasName: 'sync_archives__id__sync_archive_references__archive_id',
      );

  $$SyncArchiveReferencesTableProcessedTableManager
  get syncArchiveReferencesRefs {
    final manager = $$SyncArchiveReferencesTableTableManager(
      $_db,
      $_db.syncArchiveReferences,
    ).filter((f) => f.archiveId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _syncArchiveReferencesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SyncArchivesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncArchivesTable> {
  $$SyncArchivesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncGeneration => $composableBuilder(
    column: $table.syncGeneration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadSecretId => $composableBuilder(
    column: $table.payloadSecretId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> syncArchiveReferencesRefs(
    Expression<bool> Function($$SyncArchiveReferencesTableFilterComposer f) f,
  ) {
    final $$SyncArchiveReferencesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.syncArchiveReferences,
          getReferencedColumn: (t) => t.archiveId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SyncArchiveReferencesTableFilterComposer(
                $db: $db,
                $table: $db.syncArchiveReferences,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$SyncArchivesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncArchivesTable> {
  $$SyncArchivesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncGeneration => $composableBuilder(
    column: $table.syncGeneration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadSecretId => $composableBuilder(
    column: $table.payloadSecretId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncArchivesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncArchivesTable> {
  $$SyncArchivesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get syncGeneration => $composableBuilder(
    column: $table.syncGeneration,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadSecretId => $composableBuilder(
    column: $table.payloadSecretId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> syncArchiveReferencesRefs<T extends Object>(
    Expression<T> Function($$SyncArchiveReferencesTableAnnotationComposer a) f,
  ) {
    final $$SyncArchiveReferencesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.syncArchiveReferences,
          getReferencedColumn: (t) => t.archiveId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SyncArchiveReferencesTableAnnotationComposer(
                $db: $db,
                $table: $db.syncArchiveReferences,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$SyncArchivesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncArchivesTable,
          SyncArchiveRow,
          $$SyncArchivesTableFilterComposer,
          $$SyncArchivesTableOrderingComposer,
          $$SyncArchivesTableAnnotationComposer,
          $$SyncArchivesTableCreateCompanionBuilder,
          $$SyncArchivesTableUpdateCompanionBuilder,
          (SyncArchiveRow, $$SyncArchivesTableReferences),
          SyncArchiveRow,
          PrefetchHooks Function({bool syncArchiveReferencesRefs})
        > {
  $$SyncArchivesTableTableManager(_$AppDatabase db, $SyncArchivesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncArchivesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncArchivesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncArchivesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> accountId = const Value.absent(),
                Value<String?> syncGeneration = const Value.absent(),
                Value<String> payloadSecretId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncArchivesCompanion(
                id: id,
                accountId: accountId,
                syncGeneration: syncGeneration,
                payloadSecretId: payloadSecretId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String accountId,
                Value<String?> syncGeneration = const Value.absent(),
                required String payloadSecretId,
                required int createdAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncArchivesCompanion.insert(
                id: id,
                accountId: accountId,
                syncGeneration: syncGeneration,
                payloadSecretId: payloadSecretId,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SyncArchivesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({syncArchiveReferencesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (syncArchiveReferencesRefs) db.syncArchiveReferences,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (syncArchiveReferencesRefs)
                    await $_getPrefetchedData<
                      SyncArchiveRow,
                      $SyncArchivesTable,
                      SyncArchiveReferenceRow
                    >(
                      currentTable: table,
                      referencedTable: $$SyncArchivesTableReferences
                          ._syncArchiveReferencesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$SyncArchivesTableReferences(
                            db,
                            table,
                            p0,
                          ).syncArchiveReferencesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.archiveId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SyncArchivesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncArchivesTable,
      SyncArchiveRow,
      $$SyncArchivesTableFilterComposer,
      $$SyncArchivesTableOrderingComposer,
      $$SyncArchivesTableAnnotationComposer,
      $$SyncArchivesTableCreateCompanionBuilder,
      $$SyncArchivesTableUpdateCompanionBuilder,
      (SyncArchiveRow, $$SyncArchivesTableReferences),
      SyncArchiveRow,
      PrefetchHooks Function({bool syncArchiveReferencesRefs})
    >;
typedef $$SyncArchiveReferencesTableCreateCompanionBuilder =
    SyncArchiveReferencesCompanion Function({
      required String archiveId,
      required String secretId,
      Value<int> rowid,
    });
typedef $$SyncArchiveReferencesTableUpdateCompanionBuilder =
    SyncArchiveReferencesCompanion Function({
      Value<String> archiveId,
      Value<String> secretId,
      Value<int> rowid,
    });

final class $$SyncArchiveReferencesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $SyncArchiveReferencesTable,
          SyncArchiveReferenceRow
        > {
  $$SyncArchiveReferencesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SyncArchivesTable _archiveIdTable(_$AppDatabase db) => db.syncArchives
      .createAlias('sync_archive_references__archive_id__sync_archives__id');

  $$SyncArchivesTableProcessedTableManager get archiveId {
    final $_column = $_itemColumn<String>('archive_id')!;

    final manager = $$SyncArchivesTableTableManager(
      $_db,
      $_db.syncArchives,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_archiveIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SyncArchiveReferencesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncArchiveReferencesTable> {
  $$SyncArchiveReferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get secretId => $composableBuilder(
    column: $table.secretId,
    builder: (column) => ColumnFilters(column),
  );

  $$SyncArchivesTableFilterComposer get archiveId {
    final $$SyncArchivesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.archiveId,
      referencedTable: $db.syncArchives,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncArchivesTableFilterComposer(
            $db: $db,
            $table: $db.syncArchives,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncArchiveReferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncArchiveReferencesTable> {
  $$SyncArchiveReferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get secretId => $composableBuilder(
    column: $table.secretId,
    builder: (column) => ColumnOrderings(column),
  );

  $$SyncArchivesTableOrderingComposer get archiveId {
    final $$SyncArchivesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.archiveId,
      referencedTable: $db.syncArchives,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncArchivesTableOrderingComposer(
            $db: $db,
            $table: $db.syncArchives,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncArchiveReferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncArchiveReferencesTable> {
  $$SyncArchiveReferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get secretId =>
      $composableBuilder(column: $table.secretId, builder: (column) => column);

  $$SyncArchivesTableAnnotationComposer get archiveId {
    final $$SyncArchivesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.archiveId,
      referencedTable: $db.syncArchives,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SyncArchivesTableAnnotationComposer(
            $db: $db,
            $table: $db.syncArchives,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SyncArchiveReferencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncArchiveReferencesTable,
          SyncArchiveReferenceRow,
          $$SyncArchiveReferencesTableFilterComposer,
          $$SyncArchiveReferencesTableOrderingComposer,
          $$SyncArchiveReferencesTableAnnotationComposer,
          $$SyncArchiveReferencesTableCreateCompanionBuilder,
          $$SyncArchiveReferencesTableUpdateCompanionBuilder,
          (SyncArchiveReferenceRow, $$SyncArchiveReferencesTableReferences),
          SyncArchiveReferenceRow,
          PrefetchHooks Function({bool archiveId})
        > {
  $$SyncArchiveReferencesTableTableManager(
    _$AppDatabase db,
    $SyncArchiveReferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncArchiveReferencesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$SyncArchiveReferencesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SyncArchiveReferencesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> archiveId = const Value.absent(),
                Value<String> secretId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncArchiveReferencesCompanion(
                archiveId: archiveId,
                secretId: secretId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String archiveId,
                required String secretId,
                Value<int> rowid = const Value.absent(),
              }) => SyncArchiveReferencesCompanion.insert(
                archiveId: archiveId,
                secretId: secretId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SyncArchiveReferencesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({archiveId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (archiveId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.archiveId,
                                referencedTable:
                                    $$SyncArchiveReferencesTableReferences
                                        ._archiveIdTable(db),
                                referencedColumn:
                                    $$SyncArchiveReferencesTableReferences
                                        ._archiveIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SyncArchiveReferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncArchiveReferencesTable,
      SyncArchiveReferenceRow,
      $$SyncArchiveReferencesTableFilterComposer,
      $$SyncArchiveReferencesTableOrderingComposer,
      $$SyncArchiveReferencesTableAnnotationComposer,
      $$SyncArchiveReferencesTableCreateCompanionBuilder,
      $$SyncArchiveReferencesTableUpdateCompanionBuilder,
      (SyncArchiveReferenceRow, $$SyncArchiveReferencesTableReferences),
      SyncArchiveReferenceRow,
      PrefetchHooks Function({bool archiveId})
    >;
typedef $$SyncRebuildEntriesTableCreateCompanionBuilder =
    SyncRebuildEntriesCompanion Function({
      required String accountId,
      required String syncGeneration,
      required String attemptId,
      required int ordinal,
      required String documentId,
      required String recordId,
      required String type,
      required String mutationId,
      required String envelopeSecretId,
      Value<bool> acknowledged,
      Value<int> rowid,
    });
typedef $$SyncRebuildEntriesTableUpdateCompanionBuilder =
    SyncRebuildEntriesCompanion Function({
      Value<String> accountId,
      Value<String> syncGeneration,
      Value<String> attemptId,
      Value<int> ordinal,
      Value<String> documentId,
      Value<String> recordId,
      Value<String> type,
      Value<String> mutationId,
      Value<String> envelopeSecretId,
      Value<bool> acknowledged,
      Value<int> rowid,
    });

class $$SyncRebuildEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncRebuildEntriesTable> {
  $$SyncRebuildEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncGeneration => $composableBuilder(
    column: $table.syncGeneration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get attemptId => $composableBuilder(
    column: $table.attemptId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ordinal => $composableBuilder(
    column: $table.ordinal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mutationId => $composableBuilder(
    column: $table.mutationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get envelopeSecretId => $composableBuilder(
    column: $table.envelopeSecretId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get acknowledged => $composableBuilder(
    column: $table.acknowledged,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncRebuildEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncRebuildEntriesTable> {
  $$SyncRebuildEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncGeneration => $composableBuilder(
    column: $table.syncGeneration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get attemptId => $composableBuilder(
    column: $table.attemptId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ordinal => $composableBuilder(
    column: $table.ordinal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mutationId => $composableBuilder(
    column: $table.mutationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get envelopeSecretId => $composableBuilder(
    column: $table.envelopeSecretId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get acknowledged => $composableBuilder(
    column: $table.acknowledged,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncRebuildEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncRebuildEntriesTable> {
  $$SyncRebuildEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get syncGeneration => $composableBuilder(
    column: $table.syncGeneration,
    builder: (column) => column,
  );

  GeneratedColumn<String> get attemptId =>
      $composableBuilder(column: $table.attemptId, builder: (column) => column);

  GeneratedColumn<int> get ordinal =>
      $composableBuilder(column: $table.ordinal, builder: (column) => column);

  GeneratedColumn<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get mutationId => $composableBuilder(
    column: $table.mutationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get envelopeSecretId => $composableBuilder(
    column: $table.envelopeSecretId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get acknowledged => $composableBuilder(
    column: $table.acknowledged,
    builder: (column) => column,
  );
}

class $$SyncRebuildEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncRebuildEntriesTable,
          SyncRebuildEntryRow,
          $$SyncRebuildEntriesTableFilterComposer,
          $$SyncRebuildEntriesTableOrderingComposer,
          $$SyncRebuildEntriesTableAnnotationComposer,
          $$SyncRebuildEntriesTableCreateCompanionBuilder,
          $$SyncRebuildEntriesTableUpdateCompanionBuilder,
          (
            SyncRebuildEntryRow,
            BaseReferences<
              _$AppDatabase,
              $SyncRebuildEntriesTable,
              SyncRebuildEntryRow
            >,
          ),
          SyncRebuildEntryRow,
          PrefetchHooks Function()
        > {
  $$SyncRebuildEntriesTableTableManager(
    _$AppDatabase db,
    $SyncRebuildEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncRebuildEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncRebuildEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncRebuildEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> syncGeneration = const Value.absent(),
                Value<String> attemptId = const Value.absent(),
                Value<int> ordinal = const Value.absent(),
                Value<String> documentId = const Value.absent(),
                Value<String> recordId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> mutationId = const Value.absent(),
                Value<String> envelopeSecretId = const Value.absent(),
                Value<bool> acknowledged = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncRebuildEntriesCompanion(
                accountId: accountId,
                syncGeneration: syncGeneration,
                attemptId: attemptId,
                ordinal: ordinal,
                documentId: documentId,
                recordId: recordId,
                type: type,
                mutationId: mutationId,
                envelopeSecretId: envelopeSecretId,
                acknowledged: acknowledged,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String syncGeneration,
                required String attemptId,
                required int ordinal,
                required String documentId,
                required String recordId,
                required String type,
                required String mutationId,
                required String envelopeSecretId,
                Value<bool> acknowledged = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncRebuildEntriesCompanion.insert(
                accountId: accountId,
                syncGeneration: syncGeneration,
                attemptId: attemptId,
                ordinal: ordinal,
                documentId: documentId,
                recordId: recordId,
                type: type,
                mutationId: mutationId,
                envelopeSecretId: envelopeSecretId,
                acknowledged: acknowledged,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncRebuildEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncRebuildEntriesTable,
      SyncRebuildEntryRow,
      $$SyncRebuildEntriesTableFilterComposer,
      $$SyncRebuildEntriesTableOrderingComposer,
      $$SyncRebuildEntriesTableAnnotationComposer,
      $$SyncRebuildEntriesTableCreateCompanionBuilder,
      $$SyncRebuildEntriesTableUpdateCompanionBuilder,
      (
        SyncRebuildEntryRow,
        BaseReferences<
          _$AppDatabase,
          $SyncRebuildEntriesTable,
          SyncRebuildEntryRow
        >,
      ),
      SyncRebuildEntryRow,
      PrefetchHooks Function()
    >;
typedef $$SyncPullStagesTableCreateCompanionBuilder =
    SyncPullStagesCompanion Function({
      required String accountId,
      required String syncGeneration,
      required int headRevision,
      required int cursor,
      required bool complete,
      Value<int> rowid,
    });
typedef $$SyncPullStagesTableUpdateCompanionBuilder =
    SyncPullStagesCompanion Function({
      Value<String> accountId,
      Value<String> syncGeneration,
      Value<int> headRevision,
      Value<int> cursor,
      Value<bool> complete,
      Value<int> rowid,
    });

class $$SyncPullStagesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncPullStagesTable> {
  $$SyncPullStagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncGeneration => $composableBuilder(
    column: $table.syncGeneration,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get headRevision => $composableBuilder(
    column: $table.headRevision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get complete => $composableBuilder(
    column: $table.complete,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncPullStagesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncPullStagesTable> {
  $$SyncPullStagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncGeneration => $composableBuilder(
    column: $table.syncGeneration,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get headRevision => $composableBuilder(
    column: $table.headRevision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get complete => $composableBuilder(
    column: $table.complete,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncPullStagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncPullStagesTable> {
  $$SyncPullStagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get syncGeneration => $composableBuilder(
    column: $table.syncGeneration,
    builder: (column) => column,
  );

  GeneratedColumn<int> get headRevision => $composableBuilder(
    column: $table.headRevision,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cursor =>
      $composableBuilder(column: $table.cursor, builder: (column) => column);

  GeneratedColumn<bool> get complete =>
      $composableBuilder(column: $table.complete, builder: (column) => column);
}

class $$SyncPullStagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncPullStagesTable,
          SyncPullStageRow,
          $$SyncPullStagesTableFilterComposer,
          $$SyncPullStagesTableOrderingComposer,
          $$SyncPullStagesTableAnnotationComposer,
          $$SyncPullStagesTableCreateCompanionBuilder,
          $$SyncPullStagesTableUpdateCompanionBuilder,
          (
            SyncPullStageRow,
            BaseReferences<
              _$AppDatabase,
              $SyncPullStagesTable,
              SyncPullStageRow
            >,
          ),
          SyncPullStageRow,
          PrefetchHooks Function()
        > {
  $$SyncPullStagesTableTableManager(
    _$AppDatabase db,
    $SyncPullStagesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncPullStagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncPullStagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncPullStagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> syncGeneration = const Value.absent(),
                Value<int> headRevision = const Value.absent(),
                Value<int> cursor = const Value.absent(),
                Value<bool> complete = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncPullStagesCompanion(
                accountId: accountId,
                syncGeneration: syncGeneration,
                headRevision: headRevision,
                cursor: cursor,
                complete: complete,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String syncGeneration,
                required int headRevision,
                required int cursor,
                required bool complete,
                Value<int> rowid = const Value.absent(),
              }) => SyncPullStagesCompanion.insert(
                accountId: accountId,
                syncGeneration: syncGeneration,
                headRevision: headRevision,
                cursor: cursor,
                complete: complete,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncPullStagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncPullStagesTable,
      SyncPullStageRow,
      $$SyncPullStagesTableFilterComposer,
      $$SyncPullStagesTableOrderingComposer,
      $$SyncPullStagesTableAnnotationComposer,
      $$SyncPullStagesTableCreateCompanionBuilder,
      $$SyncPullStagesTableUpdateCompanionBuilder,
      (
        SyncPullStageRow,
        BaseReferences<_$AppDatabase, $SyncPullStagesTable, SyncPullStageRow>,
      ),
      SyncPullStageRow,
      PrefetchHooks Function()
    >;
typedef $$SyncPullStageEntriesTableCreateCompanionBuilder =
    SyncPullStageEntriesCompanion Function({
      required String accountId,
      required String recordId,
      required int revision,
      required String recordSecretId,
      Value<int> rowid,
    });
typedef $$SyncPullStageEntriesTableUpdateCompanionBuilder =
    SyncPullStageEntriesCompanion Function({
      Value<String> accountId,
      Value<String> recordId,
      Value<int> revision,
      Value<String> recordSecretId,
      Value<int> rowid,
    });

class $$SyncPullStageEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SyncPullStageEntriesTable> {
  $$SyncPullStageEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recordSecretId => $composableBuilder(
    column: $table.recordSecretId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncPullStageEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncPullStageEntriesTable> {
  $$SyncPullStageEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get accountId => $composableBuilder(
    column: $table.accountId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recordSecretId => $composableBuilder(
    column: $table.recordSecretId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncPullStageEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncPullStageEntriesTable> {
  $$SyncPullStageEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get accountId =>
      $composableBuilder(column: $table.accountId, builder: (column) => column);

  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<String> get recordSecretId => $composableBuilder(
    column: $table.recordSecretId,
    builder: (column) => column,
  );
}

class $$SyncPullStageEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncPullStageEntriesTable,
          SyncPullStageEntryRow,
          $$SyncPullStageEntriesTableFilterComposer,
          $$SyncPullStageEntriesTableOrderingComposer,
          $$SyncPullStageEntriesTableAnnotationComposer,
          $$SyncPullStageEntriesTableCreateCompanionBuilder,
          $$SyncPullStageEntriesTableUpdateCompanionBuilder,
          (
            SyncPullStageEntryRow,
            BaseReferences<
              _$AppDatabase,
              $SyncPullStageEntriesTable,
              SyncPullStageEntryRow
            >,
          ),
          SyncPullStageEntryRow,
          PrefetchHooks Function()
        > {
  $$SyncPullStageEntriesTableTableManager(
    _$AppDatabase db,
    $SyncPullStageEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncPullStageEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncPullStageEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SyncPullStageEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> accountId = const Value.absent(),
                Value<String> recordId = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<String> recordSecretId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncPullStageEntriesCompanion(
                accountId: accountId,
                recordId: recordId,
                revision: revision,
                recordSecretId: recordSecretId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String accountId,
                required String recordId,
                required int revision,
                required String recordSecretId,
                Value<int> rowid = const Value.absent(),
              }) => SyncPullStageEntriesCompanion.insert(
                accountId: accountId,
                recordId: recordId,
                revision: revision,
                recordSecretId: recordSecretId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncPullStageEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncPullStageEntriesTable,
      SyncPullStageEntryRow,
      $$SyncPullStageEntriesTableFilterComposer,
      $$SyncPullStageEntriesTableOrderingComposer,
      $$SyncPullStageEntriesTableAnnotationComposer,
      $$SyncPullStageEntriesTableCreateCompanionBuilder,
      $$SyncPullStageEntriesTableUpdateCompanionBuilder,
      (
        SyncPullStageEntryRow,
        BaseReferences<
          _$AppDatabase,
          $SyncPullStageEntriesTable,
          SyncPullStageEntryRow
        >,
      ),
      SyncPullStageEntryRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ConfigurationsTableTableManager get configurations =>
      $$ConfigurationsTableTableManager(_db, _db.configurations);
  $$ContentsTableTableManager get contents =>
      $$ContentsTableTableManager(_db, _db.contents);
  $$SelfNodesTableTableManager get selfNodes =>
      $$SelfNodesTableTableManager(_db, _db.selfNodes);
  $$ChainsTableTableManager get chains =>
      $$ChainsTableTableManager(_db, _db.chains);
  $$MembershipsTableTableManager get memberships =>
      $$MembershipsTableTableManager(_db, _db.memberships);
  $$SelectionsTableTableManager get selections =>
      $$SelectionsTableTableManager(_db, _db.selections);
  $$DeviceSettingsTableTableTableManager get deviceSettingsTable =>
      $$DeviceSettingsTableTableTableManager(_db, _db.deviceSettingsTable);
  $$PolicyTableTableTableManager get policyTable =>
      $$PolicyTableTableTableManager(_db, _db.policyTable);
  $$RuleResourcesTableTableManager get ruleResources =>
      $$RuleResourcesTableTableManager(_db, _db.ruleResources);
  $$SecretsTableTableManager get secrets =>
      $$SecretsTableTableManager(_db, _db.secrets);
  $$CloudSessionTableTableManager get cloudSession =>
      $$CloudSessionTableTableManager(_db, _db.cloudSession);
  $$SyncMetaTableTableManager get syncMeta =>
      $$SyncMetaTableTableManager(_db, _db.syncMeta);
  $$SyncDocumentsTableTableManager get syncDocuments =>
      $$SyncDocumentsTableTableManager(_db, _db.syncDocuments);
  $$SourceProvenanceTableTableManager get sourceProvenance =>
      $$SourceProvenanceTableTableManager(_db, _db.sourceProvenance);
  $$SyncStateTableTableManager get syncState =>
      $$SyncStateTableTableManager(_db, _db.syncState);
  $$SyncArchivesTableTableManager get syncArchives =>
      $$SyncArchivesTableTableManager(_db, _db.syncArchives);
  $$SyncArchiveReferencesTableTableManager get syncArchiveReferences =>
      $$SyncArchiveReferencesTableTableManager(_db, _db.syncArchiveReferences);
  $$SyncRebuildEntriesTableTableManager get syncRebuildEntries =>
      $$SyncRebuildEntriesTableTableManager(_db, _db.syncRebuildEntries);
  $$SyncPullStagesTableTableManager get syncPullStages =>
      $$SyncPullStagesTableTableManager(_db, _db.syncPullStages);
  $$SyncPullStageEntriesTableTableManager get syncPullStageEntries =>
      $$SyncPullStageEntriesTableTableManager(_db, _db.syncPullStageEntries);
}
