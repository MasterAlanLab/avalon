import 'package:av_core/av_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../runtime/runtime_coordinator.dart';
import 'web_panel.dart';

/// Commands of the settings pages. Their state is the device settings
/// themselves (`deviceSettingsProvider`); every change is saved at once
/// (PRODUCT_SPEC §1).
///
/// Not auto-disposed: pages read it while building and call it when a
/// control is used later, and nothing watches it in between.
final settingsViewModelProvider = Provider<SettingsViewModel>(
  SettingsViewModel.new,
);

final class SettingsViewModel {
  SettingsViewModel(this._ref);

  final Ref _ref;

  Future<void> change(DeviceSettings Function(DeviceSettings s) edit) =>
      _ref.read(settingsRepositoryProvider).updateDevice(edit);

  /// Saves a typed value. Throws [SettingException] when it is not valid
  /// (the prompt checks first, so this is the last line of defence).
  Future<void> edit(SettingField field, String text) =>
      change((s) => SettingsRules.apply(s, field, text));

  /// «恢复默认设置» of the advanced page (D20).
  Future<void> resetAdvanced() => change(SettingsRules.resetAdvanced);

  Future<void> regenerateClashSecret() =>
      _ref.read(settingsRepositoryProvider).regenerateClashSecret();

  /// Opens the controller the host actually runs, with a reason when it
  /// cannot be opened (PRODUCT_SPEC §3.10).
  Future<WebPanelProblem?> openWebPanel() async {
    if (!_ref.read(runtimeProvider).available) {
      return WebPanelProblem.unavailable;
    }
    if (!await _ref.read(runtimeProvider.notifier).refresh()) {
      return WebPanelProblem.unknown;
    }
    final target = webPanelTarget(_ref.read(runtimeProvider).snapshot);
    final url = target.url;
    if (url == null) return target.problem;
    try {
      return await _ref.read(browserProvider).open(url)
          ? null
          : WebPanelProblem.browserFailed;
    } on Exception {
      return WebPanelProblem.browserFailed;
    }
  }
}
