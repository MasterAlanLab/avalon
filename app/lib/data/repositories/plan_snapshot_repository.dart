import 'package:av_core/av_core.dart';

import '../database/database.dart';
import 'configuration_repository.dart';
import 'selection_repository.dart';
import 'self_content_repository.dart';
import 'settings_repository.dart';

/// Everything the selected configuration's plan depends on, read at one
/// moment (CONFIG_PIPELINE §1).
final class PlanSnapshot {
  const PlanSnapshot({
    required this.settings,
    required this.policy,
    this.configuration,
    this.content,
    this.selfNodes = const [],
    this.chains = const [],
    this.memberships = const [],
    this.selections = const {},
    this.otherContents = const {},
    this.cloudConfigurationIds = const {},
    this.cloudNodeIds = const {},
    this.cloudChainIds = const {},
    this.cloudPolicy = false,
  });

  final DeviceSettings settings;
  final Policy policy;

  /// The selected configuration; null when none is.
  final Configuration? configuration;

  /// Its content; null for 「自建节点」 and for a subscription that has not
  /// been downloaded.
  final ConfigContent? content;
  final List<SelfNode> selfNodes;
  final List<Chain> chains;
  final List<Membership> memberships;
  final Map<String, MemberRef> selections;

  /// Contents of other configurations that chain hops point into.
  final Map<String, ConfigContent> otherContents;

  /// Persistent provenance, including content detached from a Cloud account.
  /// It is read in the same transaction as the content it constrains.
  final Set<String> cloudConfigurationIds;
  final Set<String> cloudNodeIds;
  final Set<String> cloudChainIds;
  final bool cloudPolicy;
}

/// Reads a [PlanSnapshot] in one transaction, so a plan is never compiled
/// from a mix of old and new rows.
final class PlanSnapshotRepository {
  PlanSnapshotRepository(
    this._db,
    this._configurations,
    this._self,
    this._selections,
    this._settings,
  );

  final AppDatabase _db;
  final ConfigurationRepository _configurations;
  final SelfContentRepository _self;
  final SelectionRepository _selections;
  final SettingsRepository _settings;

  Future<PlanSnapshot> read() => _db.transaction(() async {
    final settings = await _settings.device();
    final policy = await _settings.policy();
    final provenance = {
      for (final p in await _db.select(_db.sourceProvenance).get())
        if (p.origin == 'cloud') p.documentId,
    };
    final documents = await _db.select(_db.syncDocuments).get();
    Set<String> cloudIds(String type) => {
      for (final d in documents)
        if (d.type == type &&
            d.localId != null &&
            provenance.contains(d.documentId))
          d.localId!,
    };
    final policyRow = await (_db.select(
      _db.policyTable,
    )..where((p) => p.id.equals(1))).getSingleOrNull();
    final cloudPolicy = provenance.contains(policyRow?.documentId);
    final id = settings.selectedConfigurationId;
    final configuration = id == null ? null : await _configurations.get(id);
    if (configuration == null) {
      return PlanSnapshot(
        settings: settings,
        policy: policy,
        cloudPolicy: cloudPolicy,
      );
    }
    final chains = await _self.chains();
    final others = <String, ConfigContent>{};
    for (final chain in chains) {
      for (final hop in chain.hops) {
        if (hop case SourceMember(:final configurationId)
            when configurationId != configuration.id &&
                !others.containsKey(configurationId)) {
          final other = await _configurations.content(configurationId);
          if (other != null) others[configurationId] = other.content;
        }
      }
    }
    return PlanSnapshot(
      settings: settings,
      policy: policy,
      configuration: configuration,
      content: configuration.kind == ConfigurationKind.self
          ? null
          : (await _configurations.content(configuration.id))?.content,
      selfNodes: await _self.nodes(),
      chains: chains,
      memberships: await _self.watchMemberships().first,
      selections: await _selections.get(configuration.id),
      otherContents: others,
      cloudConfigurationIds: cloudIds('configuration'),
      cloudNodeIds: cloudIds('node'),
      cloudChainIds: cloudIds('chain'),
      cloudPolicy: cloudPolicy,
    );
  });
}
