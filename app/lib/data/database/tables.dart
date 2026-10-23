import 'package:drift/drift.dart';

// Tables of DATA_MODEL §2. Times are UTC milliseconds; secrets live only in
// [Secrets], encrypted (DATA_MODEL §3).

@DataClassName('ConfigurationRow')
class Configurations extends Table {
  TextColumn get id => text()();

  /// `subscription`, `file` or `self`.
  TextColumn get kind => text()();
  TextColumn get name => text()();

  /// Subscription URL and headers (a secrets entry).
  TextColumn get sourceSecretId => text().nullable()();

  /// Host of the subscription URL, shown in the UI.
  TextColumn get sourceDisplay => text().nullable()();
  BoolColumn get autoUpdate => boolean().withDefault(const Constant(true))();
  TextColumn get contentId => text().nullable()();
  IntColumn get usageUpload => integer().nullable()();
  IntColumn get usageDownload => integer().nullable()();
  IntColumn get usageTotal => integer().nullable()();
  IntColumn get expireAt => integer().nullable()();
  IntColumn get lastSuccessAt => integer().nullable()();
  IntColumn get lastAttemptAt => integer().nullable()();
  TextColumn get lastError => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get editedAt => integer()();
  TextColumn get cloudAccountId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ContentRow')
class Contents extends Table {
  TextColumn get id => text()();
  TextColumn get configurationId => text().references(
    Configurations,
    #id,
    onDelete: KeyAction.cascade,
    onUpdate: KeyAction.cascade,
  )();

  /// `singBox`, `clash` or `linkList`.
  TextColumn get format => text()();

  /// `ConfigContent` JSON with secrets lifted out (`SecretCodec`).
  TextColumn get modelJson => text()();
  TextColumn get secretId => text()();

  /// Shown on the card without decrypting the content.
  IntColumn get nodeCount => integer()();

  /// SHA-256 of the downloaded text; unchanged downloads skip the update.
  TextColumn get digest => text()();
  TextColumn get warningsJson => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SelfNodeRow')
class SelfNodes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get protocol => text()();
  TextColumn get server => text()();
  IntColumn get port => integer()();
  TextColumn get paramsJson => text()();
  TextColumn get secretId => text()();
  IntColumn get createdAt => integer()();
  IntColumn get editedAt => integer()();
  TextColumn get cloudAccountId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ChainRow')
class Chains extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().nullable()();
  TextColumn get hopsJson => text()();
  IntColumn get createdAt => integer()();
  IntColumn get editedAt => integer()();
  TextColumn get cloudAccountId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Owner has no foreign key: deleting a node or chain removes its
/// memberships in the same transaction (DATA_MODEL §2).
@DataClassName('MembershipRow')
class Memberships extends Table {
  /// `node` or `chain`.
  TextColumn get ownerKind => text()();
  TextColumn get ownerId => text()();
  TextColumn get configurationId => text().references(
    Configurations,
    #id,
    onDelete: KeyAction.cascade,
    onUpdate: KeyAction.cascade,
  )();
  TextColumn get groupKey => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {ownerKind, ownerId, configurationId, groupKey};
}

@DataClassName('SelectionRow')
class Selections extends Table {
  TextColumn get configurationId => text().references(
    Configurations,
    #id,
    onDelete: KeyAction.cascade,
    onUpdate: KeyAction.cascade,
  )();
  TextColumn get groupKey => text()();
  TextColumn get memberJson => text()();

  /// Only manual choices are synced (DATA_MODEL §1.2).
  BoolColumn get manual => boolean()();
  IntColumn get editedAt => integer()();
  TextColumn get cloudAccountId => text().nullable()();
  TextColumn get documentId => text().nullable()();

  @override
  Set<Column> get primaryKey => {configurationId, groupKey};
}

/// Single row (id = 1).
@DataClassName('DeviceSettingsRow')
class DeviceSettingsTable extends Table {
  @override
  String get tableName => 'device_settings';

  IntColumn get id => integer()();
  TextColumn get json => text()();

  /// Secrets inside the settings (the Clash API key).
  TextColumn get secretId => text().nullable()();
  IntColumn get editedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Single row (id = 1).
@DataClassName('PolicyRow')
class PolicyTable extends Table {
  @override
  String get tableName => 'policy';

  IntColumn get id => integer()();
  TextColumn get overrideSecretId => text().nullable()();
  BoolColumn get geoAutoUpdate => boolean()();
  TextColumn get geoInterval => text()();
  TextColumn get geoVia => text()();

  /// Null: never edited, so not uploaded (DATA_MODEL §1.2).
  IntColumn get editedAt => integer().nullable()();
  TextColumn get cloudAccountId => text().nullable()();
  TextColumn get documentId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Downloaded rule sets (CONFIG_PIPELINE §8): a cache, known by what is
/// fetched and how it is read (D86). Which rule sets exist, under which
/// names and for whom, comes from the configurations; nothing here is
/// backed up or synced, a restored device downloads again. Schema v2.
@DataClassName('RuleResourceRow')
class RuleResources extends Table {
  TextColumn get url => text()();

  /// A `RuleSetFormat` name.
  TextColumn get format => text()();

  /// The file under the host's `rulesets/` directory, named after its
  /// SHA-256; null until downloaded.
  TextColumn get file => text().nullable()();
  TextColumn get sha256 => text().nullable()();
  IntColumn get size => integer().nullable()();

  /// When the file was last replaced (milliseconds, UTC).
  IntColumn get updatedAt => integer().nullable()();

  /// When a download was last attempted, successful or not.
  IntColumn get checkedAt => integer().nullable()();

  /// The last attempt's error code; null when it succeeded.
  TextColumn get lastError => text().nullable()();

  /// Lines of a Clash provider that sing-box cannot express.
  IntColumn get skipped => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {url, format};
}

/// XChaCha20-Poly1305 entries; the AAD is the entry id (DATA_MODEL §3).
@DataClassName('SecretRow')
class Secrets extends Table {
  TextColumn get id => text()();
  BlobColumn get nonce => blob()();
  BlobColumn get ciphertext => blob()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// C1 ownership rows: id = 1 is the active session/installation sentinel;
/// id = 2 owns the encrypted pending-revocation queue via refreshSecretId.
@DataClassName('CloudSessionRow')
class CloudSession extends Table {
  IntColumn get id => integer()();
  TextColumn get accountId => text()();
  TextColumn get email => text()();
  TextColumn get displayName => text()();
  TextColumn get deviceId => text()();
  TextColumn get installationId => text()();
  TextColumn get accessSecretId => text()();
  TextColumn get refreshSecretId => text()();
  TextColumn get entitlementJson => text()();
  BoolColumn get loggedIn => boolean()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Used from C2.
@DataClassName('SyncMetaRow')
class SyncMeta extends Table {
  TextColumn get recordId => text()();
  TextColumn get type => text()();
  TextColumn get accountId => text()();
  TextColumn get documentId => text()();
  IntColumn get remoteRevision => integer().nullable()();
  BoolColumn get dirty => boolean()();
  BoolColumn get deleted => boolean()();
  IntColumn get editedAt => integer()();
  TextColumn get mutationId => text().nullable()();
  TextColumn get pendingEnvelopeSecretId => text().nullable()();
  TextColumn get inFlightMutationId => text().nullable()();
  TextColumn get inFlightEnvelopeSecretId => text().nullable()();
  TextColumn get syncGeneration => text().nullable()();

  @override
  Set<Column> get primaryKey => {accountId, recordId};
}

/// Canonical owners survive deletion of projections and account detachment.
/// Both complete payloads are encrypted entries, including unresolved refs.
@DataClassName('SyncDocumentRow')
class SyncDocuments extends Table {
  TextColumn get documentId => text()();
  TextColumn get accountId => text().nullable()();
  TextColumn get recordId => text()();
  TextColumn get type => text()();
  TextColumn get localId => text().nullable()();
  IntColumn get remoteRevision => integer().nullable()();
  IntColumn get remoteEditedAt => integer().nullable()();
  BoolColumn get remoteDeleted => boolean().nullable()();
  IntColumn get remoteSchemaVersion => integer().nullable()();
  TextColumn get remotePayloadSecretId => text().nullable()();
  TextColumn get localPayloadSecretId => text().nullable()();
  IntColumn get localEditedAt => integer()();
  BoolColumn get localDeleted => boolean()();
  IntColumn get localSchemaVersion =>
      integer().withDefault(const Constant(1))();
  TextColumn get syncGeneration => text().nullable()();

  /// A genuine local change retained across Cloud generations. An unchanged
  /// old mirror never becomes an upload merely because its generation ended.
  BoolColumn get pendingMerge => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {documentId};

  @override
  List<Set<Column>> get uniqueKeys => [
    {accountId, recordId},
  ];
}

/// Local authorisation is tied to one exact source generation. Cloud payloads
/// cannot grant private-network consent.
@DataClassName('SourceProvenanceRow')
class SourceProvenance extends Table {
  TextColumn get documentId => text()();
  TextColumn get origin => text()();
  TextColumn get originAccountId => text().nullable()();
  TextColumn get sourceGeneration => text()();
  TextColumn get privateConsentGeneration => text().nullable()();

  @override
  Set<Column> get primaryKey => {documentId};
}

/// Used from C2.
@DataClassName('SyncStateRow')
class SyncState extends Table {
  TextColumn get accountId => text()();
  IntColumn get cursor => integer()();
  IntColumn get lastSyncAt => integer().nullable()();
  TextColumn get blockedReason => text().nullable()();
  BoolColumn get bootstrapCompleted =>
      boolean().withDefault(const Constant(false))();
  TextColumn get syncGeneration => text().nullable()();
  TextColumn get backupState => text().withDefault(const Constant('legacy'))();
  TextColumn get rebuildAttemptId => text().nullable()();
  TextColumn get rebuildLocalAttemptId => text().nullable()();
  TextColumn get rebuildManifestSecretId => text().nullable()();
  TextColumn get rebuildControlSecretId => text().nullable()();

  @override
  Set<Column> get primaryKey => {accountId};
}

/// Retired mirrors/outboxes retain their exact encrypted material. The
/// metadata snapshot is also encrypted; no archive is eligible for upload.
@DataClassName('SyncArchiveRow')
class SyncArchives extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text()();
  TextColumn get syncGeneration => text().nullable()();
  TextColumn get payloadSecretId => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Ownership stays queryable without decrypting an archived snapshot, even
/// while the vault is unavailable. Orphan cleanup must retain these entries.
@DataClassName('SyncArchiveReferenceRow')
class SyncArchiveReferences extends Table {
  TextColumn get archiveId =>
      text().references(SyncArchives, #id, onDelete: KeyAction.cascade)();
  TextColumn get secretId => text()();

  @override
  Set<Column> get primaryKey => {archiveId, secretId};
}

/// One immutable manifest's envelopes and durable staging progress. Business
/// rows are not replaced until the server publishes the complete attempt.
@DataClassName('SyncRebuildEntryRow')
class SyncRebuildEntries extends Table {
  TextColumn get accountId => text()();
  TextColumn get syncGeneration => text()();
  TextColumn get attemptId => text()();
  IntColumn get ordinal => integer()();
  TextColumn get documentId => text()();
  TextColumn get recordId => text()();
  TextColumn get type => text()();
  TextColumn get mutationId => text()();
  TextColumn get envelopeSecretId => text()();
  BoolColumn get acknowledged => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {
    accountId,
    syncGeneration,
    attemptId,
    recordId,
  };

  @override
  List<Set<Column>> get uniqueKeys => [
    {accountId, syncGeneration, attemptId, ordinal},
    {accountId, syncGeneration, attemptId, mutationId},
  ];
}

/// A new generation is downloaded completely at a stable server head before
/// it can replace visible projections. The live account cursor stays separate.
@DataClassName('SyncPullStageRow')
class SyncPullStages extends Table {
  TextColumn get accountId => text()();
  TextColumn get syncGeneration => text()();
  IntColumn get headRevision => integer()();
  IntColumn get cursor => integer()();
  BoolColumn get complete => boolean()();

  @override
  Set<Column> get primaryKey => {accountId};
}

@DataClassName('SyncPullStageEntryRow')
class SyncPullStageEntries extends Table {
  TextColumn get accountId => text()();
  TextColumn get recordId => text()();
  IntColumn get revision => integer()();
  TextColumn get recordSecretId => text()();

  @override
  Set<Column> get primaryKey => {accountId, recordId};
}
