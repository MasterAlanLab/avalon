import 'package:av_core/av_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_error.dart';
import 'providers.dart';

/// The selected configuration as the pages that show its groups need it:
/// everything read, or why not yet.
sealed class SelectedConfiguration {
  const SelectedConfiguration();
}

/// Still reading from the database.
final class SelectionLoading extends SelectedConfiguration {
  const SelectionLoading();
}

final class NothingSelected extends SelectedConfiguration {
  const NothingSelected();
}

/// A subscription whose content is not on this device yet.
final class NotDownloaded extends SelectedConfiguration {
  const NotDownloaded(this.configuration);

  final Configuration configuration;
}

/// The content could not be read (e.g. the secure storage was reset).
final class SelectionFailed extends SelectedConfiguration {
  const SelectionFailed(this.error);

  final AppError error;
}

final class SelectionReady extends SelectedConfiguration {
  const SelectionReady({
    required this.configuration,
    required this.catalog,
    required this.selections,
    required this.settings,
  });

  final Configuration configuration;
  final MemberCatalog catalog;

  /// Saved choices, by group key.
  final Map<String, MemberRef> selections;
  final DeviceSettings settings;
}

/// Shared by the dashboard and the proxies page, so both show the same
/// groups, members and choices.
final selectedConfigurationProvider =
    Provider.autoDispose<SelectedConfiguration>((ref) {
      final settings = ref.watch(deviceSettingsProvider).value;
      final configurations = ref.watch(configurationsProvider).value;
      if (settings == null || configurations == null) {
        return const SelectionLoading();
      }
      final id = settings.selectedConfigurationId;
      final configuration = configurations.where((c) => c.id == id).firstOrNull;
      if (configuration == null) return const NothingSelected();

      final ConfigContent content;
      if (configuration.kind == ConfigurationKind.self) {
        content = const ConfigContent(finalTarget: ContentKeys.custom);
      } else {
        final stored = ref.watch(contentProvider(configuration.id));
        if (stored.hasError) {
          return SelectionFailed(AppError.from(stored.error!));
        }
        if (!stored.hasValue) return const SelectionLoading();
        final value = stored.value;
        if (value == null) return NotDownloaded(configuration);
        content = value.content;
      }

      final nodes = ref.watch(selfNodesProvider).value;
      final chains = ref.watch(chainsProvider).value;
      final memberships = ref.watch(membershipsProvider).value;
      final selections = ref.watch(selectionsProvider(configuration.id)).value;
      // Wait for all of it, so a group never shows half its members.
      if (nodes == null ||
          chains == null ||
          memberships == null ||
          selections == null) {
        return const SelectionLoading();
      }
      // Chains may pass through nodes of other configurations.
      final others = <String, ConfigContent>{};
      for (final chain in chains) {
        for (final hop in chain.hops) {
          if (hop case SourceMember(
            :final configurationId,
          ) when configurationId != configuration.id) {
            final other = ref.watch(contentProvider(configurationId)).value;
            if (other != null) others[configurationId] = other.content;
          }
        }
      }
      return SelectionReady(
        configuration: configuration,
        settings: settings,
        selections: selections,
        catalog: MemberCatalog(
          configurationId: configuration.id,
          content: content,
          otherContents: others,
          selfNodes: nodes,
          chains: chains,
          memberships: memberships,
          tailnetExit: settings.tailnet.enabled ? settings.tailnet.exit : null,
        ),
      );
    });
