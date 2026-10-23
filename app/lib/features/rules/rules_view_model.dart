import 'package:av_core/av_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/rule_set_updates.dart';

/// Commands of the GEO page. The settings are the synced policy, saved at
/// once (D25); downloads go to the app's rule-set updater, which also
/// keeps the page's busy marks.
final rulesViewModelProvider = Provider.autoDispose<RulesViewModel>(
  RulesViewModel.new,
);

final class RulesViewModel {
  RulesViewModel(this._ref);

  final Ref _ref;

  Future<void> _change(Policy Function(Policy p) edit) =>
      _ref.read(settingsRepositoryProvider).updatePolicy(edit);

  Future<void> setAutoUpdate(bool on) =>
      _change((p) => p.copyWith(geoAutoUpdate: on));

  Future<void> setInterval(GeoInterval interval) =>
      _change((p) => p.copyWith(geoInterval: interval));

  Future<void> setVia(DownloadVia via) =>
      _change((p) => p.copyWith(geoVia: via));

  /// Downloads [refs] now. Null when it ran (each failure is recorded and
  /// shown on its row).
  Future<RulesUpdateRefusal?> update(List<RuleSetRef> refs) =>
      _ref.read(ruleSetUpdaterProvider.notifier).update(refs);
}
