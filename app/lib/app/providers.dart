import 'package:av_core/av_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cloud/auth_service.dart';
import '../cloud/cloud_revocation_retry.dart';
import '../cloud/sync_engine.dart';
import '../data/repositories/cloud_session_repository.dart';
import '../data/repositories/configuration_repository.dart';
import '../data/repositories/rule_resource_repository.dart';
import '../data/repositories/selection_repository.dart';
import '../data/repositories/self_content_repository.dart';
import '../data/repositories/settings_repository.dart';
import '../platform/browser.dart';
import '../platform/file_dialogs.dart';
import '../platform/installed_apps.dart';
import '../platform/share_sheet.dart';
import '../services/backup_service.dart';
import '../services/exit_ip.dart';
import '../services/import_service.dart';
import '../services/plan_service.dart';
import '../services/resource_service.dart';
import '../services/self_content_service.dart';
import 'services.dart';

/// Overridden by the entry point with the opened [AppServices].
final servicesProvider = Provider<AppServices>(
  (ref) => throw StateError('AppServices not provided'),
);

/// AuthService uses this data boundary; HTTP DTOs never reach Drift directly.
final cloudSessionRepositoryProvider = Provider<CloudSessionRepository>(
  (ref) => ref.watch(servicesProvider).cloudSessions,
);

final cloudAuthServiceProvider = Provider<AuthService?>(
  (ref) => ref.watch(servicesProvider).cloudAuth,
);
final cloudRevocationRetryProvider = Provider<CloudRevocationRetryController?>(
  (ref) => ref.watch(servicesProvider).cloudRevocations,
);

final cloudSyncEngineProvider = Provider<SyncEngine?>(
  (ref) => ref.watch(servicesProvider).cloudSync,
);

final configurationRepositoryProvider = Provider<ConfigurationRepository>(
  (ref) => ref.watch(servicesProvider).configurations,
);
final selfContentRepositoryProvider = Provider<SelfContentRepository>(
  (ref) => ref.watch(servicesProvider).selfContent,
);
final selectionRepositoryProvider = Provider<SelectionRepository>(
  (ref) => ref.watch(servicesProvider).selections,
);
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => ref.watch(servicesProvider).settings,
);
final importServiceProvider = Provider<ImportService>(
  (ref) => ref.watch(servicesProvider).imports,
);

final selfContentServiceProvider = Provider<SelfContentService>(
  (ref) => ref.watch(servicesProvider).selfService,
);

/// The system's file dialogs; tests override it.
final fileDialogsProvider = Provider<FileDialogs>(
  (ref) => const SystemFileDialogs(),
);

final browserProvider = Provider<Browser>((ref) => const SystemBrowser());

final resourceServiceProvider = Provider<ResourceService>(
  (ref) => ref.watch(servicesProvider).resources,
);

final exitIpServiceProvider = Provider<ExitIpService>(
  (ref) => ref.watch(servicesProvider).exitIp,
);

/// The rule-set download cache, by `ruleSetKey`.
final cachedRuleSetsProvider = StreamProvider<Map<String, CachedRuleSet>>(
  (ref) => ref.watch(servicesProvider).ruleResources.watch(),
);

/// The system's share sheet.
final shareSheetProvider = Provider<ShareSheet>(
  (ref) => const SystemShareSheet(),
);

/// The apps or programs of this device (per-app proxy).
final installedAppsProvider = Provider<InstalledApps>(
  (ref) => InstalledApps.host(),
);

/// The master key is kept in a file (shown on the About page).
final masterKeyInFileProvider = Provider<bool>(
  (ref) => ref.watch(servicesProvider).masterKeyInFile,
);

final backupServiceProvider = Provider<BackupService>(
  (ref) => ref.watch(servicesProvider).backups,
);

final planServiceProvider = Provider<PlanService>(
  (ref) => ref.watch(servicesProvider).plans,
);

final deviceSettingsProvider = StreamProvider<DeviceSettings>(
  (ref) => ref.watch(settingsRepositoryProvider).watchDevice(),
);

// Data shared by several pages. Each is a database watch, so pages update
// when anything writes.

final configurationsProvider = StreamProvider.autoDispose<List<Configuration>>(
  (ref) => ref.watch(configurationRepositoryProvider).watchAll(),
);
final nodeCountsProvider = StreamProvider.autoDispose<Map<String, int>>(
  (ref) => ref.watch(configurationRepositoryProvider).watchNodeCounts(),
);

/// Decrypted content of one configuration; null while not downloaded.
final contentProvider = StreamProvider.autoDispose
    .family<StoredContent?, String>(
      (ref, id) => ref.watch(configurationRepositoryProvider).watchContent(id),
    );
final selfNodesProvider = StreamProvider.autoDispose<List<SelfNode>>(
  (ref) => ref.watch(selfContentRepositoryProvider).watchNodes(),
);
final chainsProvider = StreamProvider.autoDispose<List<Chain>>(
  (ref) => ref.watch(selfContentRepositoryProvider).watchChains(),
);
final membershipsProvider = StreamProvider.autoDispose<List<Membership>>(
  (ref) => ref.watch(selfContentRepositoryProvider).watchMemberships(),
);

/// Saved selector choices of one configuration, by group key.
final selectionsProvider = StreamProvider.autoDispose
    .family<Map<String, MemberRef>, String>(
      (ref, id) => ref.watch(selectionRepositoryProvider).watch(id),
    );

/// Settings synced through Cloud, including the JSON override.
final policyProvider = StreamProvider<Policy>(
  (ref) => ref.watch(settingsRepositoryProvider).watchPolicy(),
);

/// The outbound mode (PRODUCT_SPEC §3.1), switched from the dashboard and the
/// desktop toolbar; saved at once (D10).
final outboundModeProvider =
    NotifierProvider<OutboundModeController, OutboundMode>(
      OutboundModeController.new,
    );

class OutboundModeController extends Notifier<OutboundMode> {
  @override
  OutboundMode build() => ref.watch(
    deviceSettingsProvider.select((s) => s.value?.mode ?? OutboundMode.rule),
  );

  Future<void> set(OutboundMode mode) => ref
      .read(settingsRepositoryProvider)
      .updateDevice((s) => s.copyWith(mode: mode));
}
