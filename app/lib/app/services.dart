import 'dart:io';
import 'dart:ui';

import 'package:av_core/av_core.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../cloud/api_client.dart';
import '../cloud/auth_service.dart';
import '../cloud/cloud_development_config.dart';
import '../cloud/cloud_models.dart';
import '../cloud/cloud_revocation_retry.dart';
import '../cloud/sync_engine.dart';
import '../data/backup/backup_repository.dart';
import '../data/database/database.dart';
import '../data/repositories/cloud_session_repository.dart';
import '../data/repositories/configuration_repository.dart';
import '../data/repositories/plan_snapshot_repository.dart';
import '../data/repositories/rule_resource_repository.dart';
import '../data/repositories/selection_repository.dart';
import '../data/repositories/self_content_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../data/repositories/sync_projection.dart';
import '../data/repositories/sync_repository.dart';
import '../data/vault/secret_store.dart';
import '../data/vault/vault.dart';
import '../platform/linux_key_store.dart';
import '../runtime/runtime_host.dart';
import '../services/backup_service.dart';
import '../services/download/fetcher.dart';
import '../services/exit_ip.dart';
import '../services/import_service.dart';
import '../services/plan_service.dart';
import '../services/resource_service.dart';
import '../services/self_content_service.dart';
import 'app_info.dart';
import 'log.dart';

/// Everything built once at start-up: the composition root.
/// The UI entry and the headless entry (D75) share it.
final class AppServices {
  AppServices._({
    required this.db,
    required this.secrets,
    required this.cloudSessions,
    required this.cloudApi,
    required this.cloudAuth,
    required this.cloudRevocations,
    required this.cloudSync,
    required this.configurations,
    required this.selfContent,
    required this.selections,
    required this.settings,
    required this.imports,
    required this.selfService,
    required this.plans,
    required this.backups,
    required this.ruleResources,
    required this.resources,
    required this.exitIp,
    required this.masterKeyInFile,
    required this.runtimeHost,
  });

  final AppDatabase db;
  final SecretStore secrets;
  final CloudSessionRepository cloudSessions;
  final ApiClient? cloudApi;
  final AuthService? cloudAuth;
  final CloudRevocationRetryController? cloudRevocations;
  final SyncEngine? cloudSync;
  final ConfigurationRepository configurations;
  final SelfContentRepository selfContent;
  final SelectionRepository selections;
  final SettingsRepository settings;
  final ImportService imports;
  final SelfContentService selfService;
  final PlanService plans;
  final BackupService backups;
  final RuleResourceRepository ruleResources;
  final ResourceService resources;
  final ExitIpService exitIp;
  final RuntimeHost? runtimeHost;

  /// The master key lives in a 0600 file rather than the system's secure
  /// storage (D23, D77); the About page says so.
  final bool masterKeyInFile;

  static const userAgent = 'Avalon/$appVersion clash.meta';

  /// The exit IP probe service, or null for none (an empty setting).
  static Uri? _probeUrl(String text) {
    final uri = Uri.tryParse(text.trim());
    return uri != null && uri.hasScheme && uri.host.isNotEmpty ? uri : null;
  }

  /// Opens the database and vault and prepares defaults.
  /// Throws [DatabaseTooNewException] for a database from a newer version.
  static Future<AppServices> open({
    AppDatabase? database,
    MasterKeyStore? keyStore,
    Locale? systemLocale,
    Future<HostInfo> Function()? host,
    RuntimeHost? runtimeHost,
    // The exit IP probe service: null for the build's, empty for none.
    String? exitIpUrl,
    // Explicit preview/testing configuration; full C1's release gate remains.
    CloudDevelopmentConfig? cloudConfig,
    CloudTransport? cloudTransport,
  }) async {
    final db = database ?? AppDatabase.open();
    try {
      // The first query runs the migration (or refuses a newer schema).
      await db.select(db.configurations).get();
      final store = keyStore ?? await _platformKeyStore();
      // A missing OS key on an occupied vault is a recovery condition, not
      // another first launch. Do not replace the key needed by old ciphertext.
      final occupied = (await (db.select(
        db.secrets,
      )..limit(1)).get()).isNotEmpty;
      final vault = await Vault.open(store, allowCreate: !occupied);
      final secrets = SecretStore(db, vault);
      final cloudSessions = CloudSessionRepository(db, secrets);
      await cloudSessions.installationId();
      final cloud = kReleaseMode
          ? null
          : (cloudConfig ?? CloudDevelopmentConfig.fromBuild());
      final cloudApi = cloud == null
          ? null
          : ApiClient(
              baseUri: cloud.baseUri,
              allowLoopbackHttp: !kReleaseMode,
              transport: cloudTransport,
            );
      final cloudAuth = cloudApi == null
          ? null
          : AuthService(
              api: cloudApi,
              sessions: cloudSessions,
              deviceName: Platform.localHostname,
              os: _cloudOs,
            );
      final cloudRevocations = cloudAuth == null
          ? null
          : CloudRevocationRetryController(
              readPendingCount: () async =>
                  (await cloudSessions.pendingRevocations()).length,
              retryPendingRevocations: cloudAuth.retryPendingRevocations,
            );
      final syncRepository = SyncRepository(db, secrets);
      final projection = SyncProjection(db, secrets, syncRepository);
      await projection.resealCredentials();
      final cloudSync = cloudAuth == null
          ? null
          : SyncEngine(
              auth: cloudAuth,
              repository: syncRepository,
              projection: projection,
              db: db,
              lifecycleEnabled: cloud!.syncProtocolVersion == 2,
            );
      final settings = SettingsRepository(
        db,
        secrets,
        onSyncEdit: projection.edited,
      );
      final configurations = ConfigurationRepository(
        db,
        secrets,
        onSyncEdit: projection.edited,
      );
      final selfContent = SelfContentRepository(
        db,
        secrets,
        onSyncEdit: projection.edited,
      );
      final selections = SelectionRepository(db, onSyncEdit: projection.edited);
      final nativeHost = runtimeHost ?? RuntimeHost.ofThisPlatform();
      final hostInfo = host ?? () => _hostInfo(nativeHost);
      final ruleResources = RuleResourceRepository(db);
      await ruleResources.obscureLegacyAddresses();
      final resources = ResourceService(
        ruleResources,
        Fetcher(userAgent: userAgent, maxBytes: ResourceService.maxBytes),
        stateDir: () async => (await hostInfo()).stateDir,
        // Before the iOS host, resources lived beside the app's database.
        // Only verified rule-set files move to the shared host directory.
        legacyStateDir:
            host == null && defaultTargetPlatform == TargetPlatform.iOS
            ? () async => (await getApplicationSupportDirectory()).path
            : null,
      );
      final services = AppServices._(
        db: db,
        secrets: secrets,
        cloudSessions: cloudSessions,
        cloudApi: cloudApi,
        cloudAuth: cloudAuth,
        cloudRevocations: cloudRevocations,
        cloudSync: cloudSync,
        configurations: configurations,
        selfContent: selfContent,
        selfService: SelfContentService(selfContent, configurations, settings),
        plans: PlanService(
          PlanSnapshotRepository(
            db,
            configurations,
            selfContent,
            selections,
            settings,
          ),
          host: hostInfo,
          hashKey: () => vault.deriveKey('avalon.plan-hash'),
          ruleSets: resources.cachedPaths,
        ),
        ruleResources: ruleResources,
        resources: resources,
        exitIp: ExitIpService(
          Fetcher(userAgent: userAgent, maxBytes: ExitIpService.maxBytes),
          url: _probeUrl(exitIpUrl ?? exitIpUrlSetting),
        ),
        selections: selections,
        settings: settings,
        masterKeyInFile: store is FileKeyStore,
        runtimeHost: nativeHost,
        backups: BackupService(
          BackupRepository(db, secrets, onSyncEdit: projection.edited),
          secrets,
          appVersion: appVersion,
          platform: defaultTargetPlatform.name.toLowerCase(),
        ),
        imports: ImportService(configurations, Fetcher(userAgent: userAgent)),
      );
      // Language: the system's on first launch, then the user's choice.
      final current = await settings.device();
      if (current.locale == null) {
        final code = systemLocale?.languageCode == 'en' ? 'en' : 'zh';
        await settings.updateDevice((s) => s.copyWith(locale: code));
      }
      final orphans = await secrets.deleteOrphans();
      if (orphans > 0) Log.info('removed $orphans orphaned secret entries');
      return services;
    } on Object {
      await db.close();
      rethrow;
    }
  }

  /// The system's secure storage (DATA_MODEL §3). macOS debug builds are
  /// ad-hoc signed and may not use the keychain (it needs an entitlement
  /// only a signing team can grant), so they keep the key in a 0600 file
  /// inside the app's sandbox container instead (D77).
  static Future<MasterKeyStore> _platformKeyStore() async {
    if (Platform.isLinux) return linuxKeyStore();
    if (kDebugMode && Platform.isMacOS) {
      final dir = await getApplicationSupportDirectory();
      return FileKeyStore(File('${dir.path}/master.key'));
    }
    return const SecureStorageKeyStore();
  }

  /// Facts about the host the plan runs on: asked from the host itself
  /// where there is one, so that the files a plan names are where the
  /// host looks for them.
  static Future<HostInfo> _hostInfo(RuntimeHost? runtimeHost) async {
    final system = runtimeHost?.system;
    if (system == null) return _previewHost();
    final facts = await system.facts();
    return HostInfo(
      platform: _hostPlatform,
      stateDir: facts.stateDir,
      deviceName: facts.deviceName,
    );
  }

  static Future<HostInfo> _previewHost() async => HostInfo(
    platform: _hostPlatform,
    stateDir: (await getApplicationSupportDirectory()).path,
    deviceName: Platform.localHostname,
  );

  static HostPlatform get _hostPlatform => switch (defaultTargetPlatform) {
    TargetPlatform.android => HostPlatform.android,
    TargetPlatform.iOS => HostPlatform.ios,
    TargetPlatform.windows => HostPlatform.windows,
    TargetPlatform.linux => HostPlatform.linux,
    _ => HostPlatform.macos,
  };

  static DeviceOs get _cloudOs => switch (defaultTargetPlatform) {
    TargetPlatform.android => DeviceOs.android,
    TargetPlatform.iOS => DeviceOs.ios,
    TargetPlatform.windows => DeviceOs.windows,
    TargetPlatform.linux => DeviceOs.linux,
    _ => DeviceOs.macos,
  };

  Future<void> close() async {
    await cloudSync?.dispose();
    cloudRevocations?.dispose();
    cloudApi?.close();
    await cloudRevocations?.idle;
    await db.close();
  }
}
