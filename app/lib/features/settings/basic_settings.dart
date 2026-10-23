import 'package:av_core/av_core.dart';
import 'package:av_design/av_design.dart';

import '../../app/layout.dart';
import '../../l10n/app_localizations.dart';

/// What the basic settings page can do; the screen wires these to the view
/// model and its dialogs.
final class BasicSettingsActions {
  const BasicSettingsActions({
    required this.change,
    required this.edit,
    required this.chooseLanguage,
    required this.exportBackup,
    required this.restoreBackup,
  });

  final void Function(DeviceSettings Function(DeviceSettings s) edit) change;
  final void Function(SettingField field) edit;
  final void Function() chooseLanguage;
  final void Function() exportBackup;
  final void Function() restoreBackup;
}

/// Basic settings (PRODUCT_SPEC §3.9), with the rows each platform has
/// (§6).
List<AvSettingsSection> basicSettingsSections({
  required AppLocalizations l,
  required DeviceSettings s,
  required AppPlatform platform,
  required BasicSettingsActions on,
  // Per shortcut row, what to say instead of the combination («已被占用»,
  // «暂不支持»); null keeps the combination.
  List<String?> hotkeyNotes = const [null, null, null],
  String? loginItemNote,
}) {
  final desktop = platform.isDesktop;
  final tray = platform == AppPlatform.mac ? l.trayMenuBar : l.traySystemTray;
  final hotkeys = hotkeysOf(platform);
  // Android routes the system proxy through the tunnel.
  final proxyNeedsTun = platform == AppPlatform.android && !s.tunEnabled;

  return [
    AvSettingsSection(
      header: l.sectionGeneral,
      rows: [
        avValueRow(
          l.language,
          s.locale == 'en' ? 'English' : l.languageZh,
          onTap: on.chooseLanguage,
        ),
        AvSegmentRow<Appearance>(
          title: l.appearance,
          values: Appearance.values,
          labelOf: (a) => switch (a) {
            Appearance.light => l.appearanceLight,
            Appearance.dark => l.appearanceDark,
          },
          selected: s.appearance,
          onChanged: (a) => on.change((s) => s.copyWith(appearance: a)),
        ),
      ],
    ),
    AvSettingsSection(
      header: l.sectionStartup,
      rows: [
        // iOS cannot launch at startup; the footer says what to do instead.
        if (platform != AppPlatform.ios)
          avSwitchRow(
            l.launchAtStartup,
            subtitle: desktop
                ? loginItemNote ?? l.launchAtStartupNoteDesktop
                : l.launchAtStartupNoteAndroid,
            value: s.launchAtStartup,
            onChanged: (v) => on.change((s) => s.copyWith(launchAtStartup: v)),
          ),
        if (desktop)
          avSwitchRow(
            l.silentStart,
            subtitle: l.silentStartNote(tray),
            value: s.silentStart,
            onChanged: (v) => on.change((s) => s.copyWith(silentStart: v)),
          ),
        avSwitchRow(
          l.autoConnect,
          subtitle: l.autoConnectNote,
          value: s.autoConnect,
          onChanged: (v) => on.change((s) => s.copyWith(autoConnect: v)),
        ),
        if (desktop)
          avSwitchRow(
            l.keepOnClose(tray),
            value: s.keepOnClose,
            onChanged: (v) => on.change((s) => s.copyWith(keepOnClose: v)),
          ),
      ],
      footer: platform == AppPlatform.ios ? l.launchAtStartupNoteIos : null,
    ),
    AvSettingsSection(
      header: l.sectionProxy,
      rows: [
        avSwitchRow(
          l.systemProxy,
          subtitle: switch (platform) {
            AppPlatform.mac => l.systemProxyNoteMac,
            AppPlatform.windows => l.systemProxyNoteWindows,
            AppPlatform.linux => l.systemProxyNoteLinux,
            _ => proxyNeedsTun ? l.systemProxyNeedsTun : null,
          },
          value: s.systemProxy && !proxyNeedsTun,
          onChanged: proxyNeedsTun
              ? null
              : (v) => on.change((s) => s.copyWith(systemProxy: v)),
        ),
        avSwitchRow(
          l.allowLan,
          subtitle: l.allowLanNote,
          value: s.allowLan,
          onChanged: (v) => on.change((s) => s.copyWith(allowLan: v)),
        ),
        avValueRow(
          l.mixedPort,
          '${s.mixedPort}',
          onTap: () => on.edit(SettingField.mixedPort),
        ),
      ],
    ),
    if (desktop)
      AvSettingsSection(
        header: l.sectionHotkeys,
        rows: [
          avValueRow(l.hotkeyToggle, hotkeyNotes[0] ?? hotkeys[0]),
          avValueRow(l.hotkeyMode, hotkeyNotes[1] ?? hotkeys[1]),
          avValueRow(l.hotkeyShow, hotkeyNotes[2] ?? hotkeys[2]),
        ],
      ),
    if (platform == AppPlatform.android)
      AvSettingsSection(
        header: l.sectionNotification,
        rows: [
          avSwitchRow(
            l.speedNotification,
            value: s.speedNotification,
            onChanged: (v) =>
                on.change((s) => s.copyWith(speedNotification: v)),
          ),
        ],
      ),
    AvSettingsSection(
      header: l.sectionLatency,
      right: true,
      rows: [
        avValueRow(
          l.testUrl,
          // Phones have room for the address without its scheme.
          desktop
              ? s.testUrl
              : s.testUrl.replaceFirst(RegExp('^https?://'), ''),
          onTap: () => on.edit(SettingField.testUrl),
        ),
        avValueRow(
          l.testTimeout,
          l.milliseconds(s.testTimeoutMs),
          onTap: () => on.edit(SettingField.testTimeoutMs),
        ),
      ],
    ),
    AvSettingsSection(
      header: l.sectionData,
      right: true,
      rows: [
        avActionRow(l.exportBackup, onTap: on.exportBackup),
        avActionRow(l.restoreBackup, onTap: on.restoreBackup),
      ],
      footer: l.backupNote,
    ),
  ];
}
