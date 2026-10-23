import 'dart:async';

import 'package:av_core/av_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_error.dart';
import '../../app/providers.dart';
import '../../app/subscription_updates.dart';
import '../../runtime/runtime_coordinator.dart';
import '../../runtime/runtime_state.dart';
import '../../services/import_service.dart';
import 'configurations_state.dart';

/// What the page is doing right now; everything else comes from the database.
/// (Downloads under way, the page's own or scheduled, are the updater's.)
final class ConfigurationsActivity {
  const ConfigurationsActivity({
    this.refreshingAll = false,
    this.warnings = const [],
  });

  final bool refreshingAll;
  final List<ImportWarning> warnings;

  ConfigurationsActivity copyWith({
    bool? refreshingAll,
    List<ImportWarning>? warnings,
  }) => ConfigurationsActivity(
    refreshingAll: refreshingAll ?? this.refreshingAll,
    warnings: warnings ?? this.warnings,
  );
}

/// The page state: database rows combined with the page's activity.
final configurationsStateProvider = Provider.autoDispose<ConfigurationsState>((
  ref,
) {
  final configurations = ref.watch(configurationsProvider).value;
  final counts = ref.watch(nodeCountsProvider).value ?? const {};
  final nodes = ref.watch(selfNodesProvider).value ?? const [];
  final chains = ref.watch(chainsProvider).value ?? const [];
  final selected = ref.watch(
    deviceSettingsProvider.select((s) => s.value?.selectedConfigurationId),
  );
  final activity = ref.watch(configurationsViewModelProvider);
  final refreshing = ref.watch(subscriptionUpdaterProvider);
  if (configurations == null) return const ConfigurationsState(loading: true);

  final cards = <ConfigurationCard>[];
  ConfigurationCard? self;
  for (final c in configurations) {
    if (c.kind == ConfigurationKind.self) {
      // Shown once there is something in it (PRODUCT_SPEC §3.3).
      if (nodes.isEmpty && chains.isEmpty) continue;
      self = ConfigurationCard(
        id: c.id,
        kind: c.kind,
        name: c.name,
        nodeCount: nodes.length,
        chainCount: chains.length,
      );
      continue;
    }
    cards.add(
      ConfigurationCard(
        id: c.id,
        kind: c.kind,
        name: c.name,
        nodeCount: counts[c.id],
        updatedAt: c.lastSuccessAt,
        usage: c.usage,
        errorCode: c.lastError,
        lastSuccessAt: c.lastSuccessAt,
        refreshing: refreshing.contains(c.id),
      ),
    );
  }
  // Imported configurations in the order they were added; 「自建节点」,
  // which exists from the start, goes last.
  if (self != null) cards.add(self);
  return ConfigurationsState(
    cards: cards,
    // A selection whose configuration is gone counts as none.
    selectedId: configurations.any((c) => c.id == selected) ? selected : null,
    refreshingAll: activity.refreshingAll,
    warnings: activity.warnings,
  );
});

final configurationsViewModelProvider =
    NotifierProvider.autoDispose<
      ConfigurationsViewModel,
      ConfigurationsActivity
    >(ConfigurationsViewModel.new);

/// Commands of the configurations page.
class ConfigurationsViewModel extends Notifier<ConfigurationsActivity> {
  static const _parallelRefreshes = 3;

  @override
  ConfigurationsActivity build() => const ConfigurationsActivity();

  /// Selecting saves at once (D10).
  Future<void> select(String id) => ref
      .read(settingsRepositoryProvider)
      .updateDevice((s) => s.copyWith(selectedConfigurationId: id));

  /// Downloads and replaces one subscription. A failure keeps the previous
  /// content and is recorded on the card.
  Future<Result<RefreshOutcome>> refresh(String id) =>
      ref.read(subscriptionUpdaterProvider.notifier).refresh(id);

  /// Refreshes every subscription, a few at a time.
  Future<void> refreshAll() async {
    if (state.refreshingAll) return;
    final all = await ref
        .read(configurationRepositoryProvider)
        .watchAll()
        .first;
    final queue = [
      for (final c in all)
        if (c.kind == ConfigurationKind.subscription) c.id,
    ];
    if (queue.isEmpty || !ref.mounted) return;
    state = state.copyWith(refreshingAll: true);
    Future<void> worker() async {
      while (queue.isNotEmpty && ref.mounted) {
        await refresh(queue.removeAt(0));
      }
    }

    await Future.wait([for (var i = 0; i < _parallelRefreshes; i++) worker()]);
    if (ref.mounted) state = state.copyWith(refreshingAll: false);
  }

  /// Deletes an imported configuration. The selection is cleared first, so
  /// an interruption never leaves it pointing at something deleted. The
  /// configuration the running proxy uses is not deleted from under it
  /// (PRODUCT_SPEC §3.4).
  Future<Result<void>> delete(String id) async {
    final settings = ref.read(settingsRepositoryProvider);
    final runtime = ref.read(runtimeProvider);
    final inUse = runtime.connected || runtime.phase == RuntimePhase.starting;
    if (inUse && (await settings.device()).selectedConfigurationId == id) {
      return const Err(AppError('configuration.inUse'));
    }
    return attempt(() => _delete(id));
  }

  Future<void> _delete(String id) async {
    final settings = ref.read(settingsRepositoryProvider);
    final configurations = ref.read(configurationRepositoryProvider);
    await settings.updateDevice(
      (s) => s.selectedConfigurationId == id
          ? s.copyWith(selectedConfigurationId: null)
          : s,
    );
    await configurations.delete(id);
  }

  void showWarnings(List<ImportWarning> warnings) =>
      state = state.copyWith(warnings: warnings);

  void dismissWarnings() => state = state.copyWith(warnings: const []);
}
