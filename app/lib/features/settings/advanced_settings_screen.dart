import 'package:av_design/av_design.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/layout.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../l10n/app_localizations.dart';
import 'advanced_settings.dart';
import 'settings_dialogs.dart';
import 'settings_view_model.dart';
import 'web_panel.dart';

class AdvancedSettingsScreen extends ConsumerWidget {
  const AdvancedSettingsScreen({super.key});

  /// The key is never on screen until asked for: view, copy or replace it.
  Future<void> _secret(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final choice = await showAvActions(
      context,
      title: l.clashSecret,
      actions: [
        AvAction(l.secretView),
        AvAction(l.secretCopy),
        AvAction(l.secretRegenerate, destructive: true),
      ],
      cancel: l.cancel,
    );
    if (choice == null || !context.mounted) return;
    final secret =
        ref.read(deviceSettingsProvider).value?.clashApiSecret?.value ?? '';
    switch (choice) {
      case 0:
        await showAvNotice(
          context,
          title: l.clashSecret,
          message: secret,
          ok: l.ok,
        );
      case 1:
        await Clipboard.setData(ClipboardData(text: secret));
        if (context.mounted) showAvToast(context, l.copied);
      case 2:
        final confirmed = await showAvConfirm(
          context,
          title: l.secretRegenerate,
          message: l.secretRegenerateConfirm,
          confirm: l.secretRegenerate,
          cancel: l.cancel,
          destructive: true,
        );
        if (confirmed) {
          await ref.read(settingsViewModelProvider).regenerateClashSecret();
        }
    }
  }

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showAvConfirm(
      context,
      title: l.resetDefaults,
      message: l.resetDefaultsConfirm,
      confirm: l.reset,
      cancel: l.cancel,
      destructive: true,
    );
    if (confirmed) await ref.read(settingsViewModelProvider).resetAdvanced();
  }

  Future<void> _webPanel(BuildContext context, WidgetRef ref) async {
    final problem = await ref.read(settingsViewModelProvider).openWebPanel();
    if (problem == null || !context.mounted) return;
    final l = AppLocalizations.of(context);
    await showAvNotice(
      context,
      title: problem == WebPanelProblem.unavailable
          ? l.coreNotConnected
          : l.webPanel,
      message: switch (problem) {
        WebPanelProblem.unavailable => l.coreNotConnectedNote,
        WebPanelProblem.notRunning => l.webPanelNotRunning,
        WebPanelProblem.disabled => l.webPanelControllerOff,
        WebPanelProblem.unknown => l.webPanelStateUnknown,
        WebPanelProblem.browserFailed => l.webPanelBrowserFailed,
      },
      ok: l.ok,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final c = context.av;
    final settings = ref.watch(deviceSettingsProvider).value;
    final model = ref.read(settingsViewModelProvider);
    return AvSettingsPage(
      title: l.toolAdvanced,
      backLabel: l.tabTools,
      sections: settings == null
          ? const []
          : advancedSettingsSections(
              l: l,
              s: settings,
              platform: AppPlatform.host,
              warning: c.warn,
              on: AdvancedSettingsActions(
                change: model.change,
                edit: (field) => editSetting(context, ref, field),
                secret: () => _secret(context, ref),
                webPanel: () => _webPanel(context, ref),
                editOverride: () => context.push(Routes.override),
                viewGenerated: () => context.push(Routes.generated),
              ),
            ),
      bottom: settings == null
          ? null
          : AvGroup(
              children: [
                avActionRow(
                  l.resetDefaults,
                  color: c.bad,
                  onTap: () => _reset(context, ref),
                ),
              ],
            ),
    );
  }
}
