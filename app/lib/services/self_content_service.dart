import 'package:av_core/av_core.dart';

import '../data/repositories/configuration_repository.dart';
import '../data/repositories/self_content_repository.dart';
import '../data/repositories/settings_repository.dart';

/// Saving self nodes and chains with the rules around them
/// (PRODUCT_SPEC §3.6–3.7): which group they join and what becomes selected.
final class SelfContentService {
  SelfContentService(this._self, this._configurations, this._settings);

  final SelfContentRepository _self;
  final ConfigurationRepository _configurations;
  final SettingsRepository _settings;

  /// Saves a node into 「自建节点」. When the selected configuration is an
  /// imported one, the node also joins its main selector; with nothing
  /// selected, 「自建节点」 becomes the selected configuration (D26).
  Future<SelfNode> addNode(SelfNode node) async {
    final selected = (await _settings.device()).selectedConfigurationId;
    ({String configurationId, String groupKey})? join;
    if (selected != null && selected != SelfSource.id) {
      final main = (await _configurations.content(
        selected,
      ))?.content.primaryGroup;
      if (main != null) join = (configurationId: selected, groupKey: main.key);
    }
    final saved = await _self.addNode(node, joinGroup: join);
    await _selectSelfIfNone();
    return saved;
  }

  /// Saves a chain into 「自建节点」 and adds it to [groupKeys], selector
  /// groups of the selected (imported) configuration.
  Future<Chain> addChain(
    Chain chain, {
    Set<String> groupKeys = const {},
  }) async {
    final selected = (await _settings.device()).selectedConfigurationId;
    final saved = await _self.addChain(
      chain,
      joinGroups: [
        if (selected != null && selected != SelfSource.id)
          for (final key in groupKeys)
            (configurationId: selected, groupKey: key),
      ],
    );
    await _selectSelfIfNone();
    return saved;
  }

  /// Saves an edited chain. [groupKeys] are the groups of the selected
  /// (imported) configuration it should be in afterwards.
  Future<void> updateChain(
    Chain chain, {
    required Set<String> groupKeys,
    DateTime? ifEditedAt,
  }) async {
    final selected = (await _settings.device()).selectedConfigurationId;
    await _self.updateChain(
      chain,
      groups: selected == null || selected == SelfSource.id
          ? null
          : (configurationId: selected, groupKeys: groupKeys),
      ifEditedAt: ifEditedAt,
    );
  }

  Future<void> _selectSelfIfNone() => _settings.updateDevice(
    (s) => s.selectedConfigurationId == null
        ? s.copyWith(selectedConfigurationId: SelfSource.id)
        : s,
  );
}
