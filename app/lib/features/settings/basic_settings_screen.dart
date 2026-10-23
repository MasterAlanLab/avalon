import 'package:av_design/av_design.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/desktop_shell.dart';
import '../../app/layout.dart';
import '../../app/providers.dart';
import '../../l10n/app_localizations.dart';
import '../../platform/desktop/global_hotkeys.dart';
import 'backup_flow.dart';
import 'basic_settings.dart';
import 'settings_dialogs.dart';
import 'settings_view_model.dart';

class BasicSettingsScreen extends ConsumerWidget {
  const BasicSettingsScreen({super.key});

  Future<void> _chooseLanguage(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final choice = await showAvActions(
      context,
      title: l.language,
      actions: [AvAction(l.languageZh), const AvAction('English')],
      cancel: l.cancel,
    );
    if (choice == null) return;
    await ref
        .read(settingsViewModelProvider)
        .change((s) => s.copyWith(locale: choice == 1 ? 'en' : 'zh'));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final settings = ref.watch(deviceSettingsProvider).value;
    final model = ref.read(settingsViewModelProvider);
    final hotkeys = ref.watch(hotkeyResultsProvider);
    final loginItemProblem = ref.watch(loginItemProblemProvider);
    String? note(HotkeyAction action) => switch (hotkeys[action]) {
      HotkeyResult.taken => l.hotkeyTaken,
      HotkeyResult.unsupported => l.hotkeyUnsupported,
      HotkeyResult.registered || null => null,
    };
    return AvSettingsPage(
      title: l.toolBasic,
      backLabel: l.tabTools,
      sections: settings == null
          ? const []
          : basicSettingsSections(
              l: l,
              s: settings,
              platform: AppPlatform.host,
              hotkeyNotes: [for (final a in HotkeyAction.values) note(a)],
              loginItemNote: switch (loginItemProblem) {
                LoginItemProblem.failed => l.launchAtStartupFailed,
                LoginItemProblem.approvalRequired =>
                  l.launchAtStartupNeedsApproval,
                null => null,
              },
              on: BasicSettingsActions(
                change: model.change,
                edit: (field) => editSetting(context, ref, field),
                chooseLanguage: () => _chooseLanguage(context, ref),
                exportBackup: () => exportBackup(context, ref),
                restoreBackup: () => restoreBackup(context, ref),
              ),
            ),
    );
  }
}
