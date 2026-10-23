import 'package:av_core/av_core.dart';
import 'package:av_design/av_design.dart';
import 'package:flutter/widgets.dart';

import '../../app/layout.dart';
import '../../l10n/app_localizations.dart';

/// What the advanced settings page can do; the screen wires these to the
/// view model, its dialogs and the routes.
final class AdvancedSettingsActions {
  const AdvancedSettingsActions({
    required this.change,
    required this.edit,
    required this.secret,
    required this.webPanel,
    required this.editOverride,
    required this.viewGenerated,
  });

  final void Function(DeviceSettings Function(DeviceSettings s) edit) change;
  final void Function(SettingField field) edit;
  final void Function() secret;
  final void Function() webPanel;
  final void Function() editOverride;
  final void Function() viewGenerated;
}

/// Advanced settings (PRODUCT_SPEC §3.10), with the rows each platform has
/// (§6).
List<AvSettingsSection> advancedSettingsSections({
  required AppLocalizations l,
  required DeviceSettings s,
  required AppPlatform platform,
  required AdvancedSettingsActions on,
  required Color warning,
}) {
  final desktop = platform.isDesktop;
  final loopback = SettingsRules.listensOnLoopback(s.clashApiListen);
  // With IPv6 off every choice resolves as «仅 IPv4»; the row keeps showing
  // the choice and the footer explains.
  final strategyOverridden =
      SettingsRules.effectiveDnsStrategy(s) != s.dnsStrategy;

  return [
    AvSettingsSection(
      header: l.sectionTun,
      rows: [
        // The tunnel is always on under iOS.
        if (platform != AppPlatform.ios)
          avSwitchRow(
            l.tunEnabled,
            subtitle: switch (platform) {
              AppPlatform.mac => l.tunNoteMac,
              AppPlatform.windows => l.tunNoteWindows,
              AppPlatform.linux => l.tunNoteLinux,
              _ => l.tunNote,
            },
            value: s.tunEnabled,
            onChanged: (v) => on.change((s) => s.copyWith(tunEnabled: v)),
          ),
        AvSegmentRow<TunStack>(
          title: l.tunStack,
          values: TunStack.values,
          labelOf: (t) => switch (t) {
            TunStack.gvisor => 'gVisor',
            TunStack.system => 'System',
            TunStack.mixed => 'Mixed',
          },
          selected: s.tunStack,
          stacked: true,
          desktopWidth: 210,
          onChanged: (t) => on.change((s) => s.copyWith(tunStack: t)),
        ),
        avValueRow('MTU', '${s.mtu}', onTap: () => on.edit(SettingField.mtu)),
        avSwitchRow(
          l.autoRoute,
          subtitle: 'auto_route',
          value: s.autoRoute,
          onChanged: (v) => on.change((s) => s.copyWith(autoRoute: v)),
        ),
        avSwitchRow(
          l.strictRoute,
          subtitle: l.strictRouteNote,
          value: s.strictRoute,
          onChanged: (v) => on.change((s) => s.copyWith(strictRoute: v)),
        ),
      ],
    ),
    AvSettingsSection(
      header: 'DNS',
      rows: [
        avValueRow(
          l.remoteDns,
          s.remoteDns,
          onTap: () => on.edit(SettingField.remoteDns),
        ),
        avValueRow(
          l.directDns,
          s.directDns,
          onTap: () => on.edit(SettingField.directDns),
        ),
        avSwitchRow(
          'FakeIP',
          subtitle: SettingsRules.fakeIpRange,
          value: s.fakeIp,
          onChanged: (v) => on.change((s) => s.copyWith(fakeIp: v)),
        ),
        AvSegmentRow<DnsStrategy>(
          title: l.dnsStrategy,
          values: DnsStrategy.values,
          labelOf: (d) => switch (d) {
            DnsStrategy.preferIpv4 => l.dnsPreferIpv4,
            DnsStrategy.ipv4Only => l.dnsIpv4Only,
            DnsStrategy.preferIpv6 => l.dnsPreferIpv6,
          },
          selected: s.dnsStrategy,
          stacked: true,
          desktopWidth: 240,
          onChanged: (d) => on.change((s) => s.copyWith(dnsStrategy: d)),
        ),
      ],
      footer: strategyOverridden ? l.dnsIpv6OffNote : null,
    ),
    AvSettingsSection(
      header: l.sectionRouting,
      right: true,
      rows: [
        avSwitchRow(
          l.sniff,
          subtitle: l.sniffNote,
          value: s.sniff,
          onChanged: (v) => on.change((s) => s.copyWith(sniff: v)),
        ),
        // No «用嗅探结果覆盖目标» row: sing-box 1.14 cannot be told to do
        // it (D84). The stored value is kept for backups.
        avSwitchRow(
          l.bypassLan,
          value: s.bypassLan,
          onChanged: (v) => on.change((s) => s.copyWith(bypassLan: v)),
        ),
        avSwitchRow(
          'IPv6',
          value: s.ipv6,
          onChanged: (v) => on.change((s) => s.copyWith(ipv6: v)),
        ),
        avSwitchRow(
          l.findProcess,
          subtitle: desktop ? l.findProcessNoteDesktop : l.findProcessNote,
          value: s.findProcess,
          onChanged: (v) => on.change((s) => s.copyWith(findProcess: v)),
        ),
      ],
    ),
    AvSettingsSection(
      header: 'Clash API',
      right: true,
      rows: [
        avSwitchRow(
          l.clashApi,
          subtitle: l.clashApiNote,
          value: s.clashApi,
          onChanged: (v) => on.change((s) => s.copyWith(clashApi: v)),
        ),
        avValueRow(
          l.clashListen,
          s.clashApiListen,
          onTap: () => on.edit(SettingField.clashApiListen),
        ),
        // Never shown in the row; tapping offers to view or copy it.
        avValueRow(l.clashSecret, '••••••••', onTap: on.secret),
        avLinkRow(
          l.webPanel,
          value: 'metacubexd',
          action: l.openWebPanel,
          onTap: on.webPanel,
        ),
      ],
      footer: loopback ? null : l.clashListenRisk,
      footerColor: loopback ? null : warning,
    ),
    AvSettingsSection(
      header: l.sectionCore,
      right: true,
      rows: [
        AvSegmentRow<LogLevel>(
          title: l.logLevel,
          values: LogLevel.values,
          labelOf: (v) => v.name,
          selected: s.logLevel,
          stacked: true,
          desktopWidth: 240,
          onChanged: (v) => on.change((s) => s.copyWith(logLevel: v)),
        ),
        avLinkRow(
          l.configOverride,
          value: 'JSON',
          action: l.editJson,
          onTap: on.editOverride,
        ),
        avLinkRow(
          desktop ? l.generatedConfig : l.viewGeneratedConfig,
          action: l.viewAction,
          onTap: on.viewGenerated,
        ),
      ],
      footer: l.overrideNote,
    ),
  ];
}
