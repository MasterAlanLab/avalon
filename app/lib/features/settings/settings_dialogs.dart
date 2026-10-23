import 'package:av_core/av_core.dart';
import 'package:av_design/av_design.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';
import 'settings_view_model.dart';

String settingErrorText(AppLocalizations l, SettingException e) {
  final range = switch (e.field) {
    SettingField.mixedPort => SettingsRules.mixedPortRange,
    SettingField.testTimeoutMs => SettingsRules.testTimeoutRange,
    SettingField.mtu => SettingsRules.mtuRange,
    SettingField.clashApiListen => (min: 1, max: 65535),
    _ => null,
  };
  return e.error == SettingError.outOfRange && range != null
      ? l.settingOutOfRange(range.min, range.max)
      : l.settingInvalid;
}

/// Asks for a new value of [field], refusing invalid ones in the prompt
/// itself, and saves it.
Future<void> editSetting(
  BuildContext context,
  WidgetRef ref,
  SettingField field,
) async {
  final l = AppLocalizations.of(context);
  final current = ref.read(deviceSettingsProvider).value;
  if (current == null) return;
  final (title, hint, numeric) = switch (field) {
    SettingField.mixedPort => (
      l.mixedPort,
      l.settingOutOfRange(
        SettingsRules.mixedPortRange.min,
        SettingsRules.mixedPortRange.max,
      ),
      true,
    ),
    SettingField.testUrl => (l.testUrl, l.testUrlHint, false),
    SettingField.testTimeoutMs => (
      l.testTimeout,
      l.settingOutOfRange(
        SettingsRules.testTimeoutRange.min,
        SettingsRules.testTimeoutRange.max,
      ),
      true,
    ),
    SettingField.mtu => (
      'MTU',
      l.settingOutOfRange(
        SettingsRules.mtuRange.min,
        SettingsRules.mtuRange.max,
      ),
      true,
    ),
    SettingField.remoteDns => (l.remoteDns, l.remoteDnsHint, false),
    SettingField.directDns => (l.directDns, l.directDnsHint, false),
    SettingField.clashApiListen => (l.clashListen, l.clashListenHint, false),
  };
  final text = await showAvPrompt(
    context,
    title: title,
    message: hint,
    initial: SettingsRules.text(current, field),
    keyboardType: numeric ? TextInputType.number : TextInputType.url,
    save: l.save,
    cancel: l.cancel,
    validate: (value) {
      try {
        SettingsRules.apply(current, field, value);
        return null;
      } on SettingException catch (e) {
        return settingErrorText(l, e);
      }
    },
  );
  if (text == null) return;
  await ref.read(settingsViewModelProvider).edit(field, text);
}
