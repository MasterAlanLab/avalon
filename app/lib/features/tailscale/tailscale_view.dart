import 'package:av_design/av_design.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/app_error.dart';
import '../../l10n/app_localizations.dart';
import '../../runtime/host_protocol.dart';
import '../../runtime/runtime_state.dart';
import 'tailscale_state.dart';

class TailscaleView extends StatelessWidget {
  const TailscaleView({
    super.key,
    required this.state,
    this.onEnabled,
    this.onLogin,
    this.onLogout,
    this.onExit,
    this.onAcceptRoutes,
    this.onMagicDns,
    this.onAdvertiseExit,
  });
  final TailscaleState state;
  final ValueChanged<bool>? onEnabled,
      onAcceptRoutes,
      onMagicDns,
      onAdvertiseExit;
  final ValueChanged<HostTailnetPeer?>? onExit;
  final VoidCallback? onLogin, onLogout;

  String? _runtimeError(AppLocalizations l) => switch (state.runtimeFailure) {
    null => null,
    PermissionRefused() => l.runtimePermissionRefusedNote,
    HostFailed(:final error)
        when error.message == 'Tailscale exit routing has not been verified' =>
      l.tailnetExitNotReady,
    HostFailed(:final error) => l.tailnetError(error.message),
    PlanFailed(:final error) => compileErrorText(l, error),
    _ => l.tailnetUnavailable,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final s = state.settings;
    final status = state.status;
    final enabled = state.available && !state.busy;
    final error = !state.available
        ? l.tailnetUnavailable
        : state.browserFailed
        ? l.tailnetBrowserFailed
        : state.error != null
        ? l.tailnetError(state.error!)
        : _runtimeError(l);
    final description = !s.enabled
        ? l.tailnetDisabled
        : status.connected
        ? l.tailnetConnected(status.tailnet)
        : status.needsLogin
        ? l.tailnetNeedsLogin
        : l.tailnetWaiting;
    final self = status.self;
    final exits = status.peers.where((p) => p.exitCapable);
    final selected = s.exit;
    return AvSettingsPage(
      title: l.tailnetTitle,
      backLabel: l.tabTools,
      sections: [
        AvSettingsSection(
          rows: [
            AvHeaderCard(
              icon: Symbols.hub_rounded,
              hue: AvHues.graphite,
              title: l.tailnetTitle,
              subtitle: error ?? description,
              subtitleColor: error != null
                  ? context.av.bad
                  : status.connected
                  ? context.av.ok
                  : null,
              trailing: AvSwitch(
                value: s.enabled,
                onChanged: enabled ? onEnabled : null,
              ),
            ),
            if (s.enabled && !status.connected)
              AvRow(
                title: l.tailnetLogin,
                titleColor: context.av.tint,
                onTap: enabled ? onLogin : null,
              ),
          ],
        ),
        if (s.enabled) ...[
          if (self != null)
            AvSettingsSection(
              header: l.tailnetThisDevice,
              rows: [
                avValueRow(l.tailnetHostname, self.name),
                avValueRow(l.tailnetAddresses, self.ips.join(', ')),
                avValueRow(l.tailnetNetwork, status.tailnet),
              ],
            ),
          AvSettingsSection(
            header: l.tailnetExitNodes,
            footer: l.tailnetExitNotReady,
            rows: [
              AvRow(
                title: l.tailnetNoExit,
                subtitle: l.tailnetNoExitNote,
                trailing: selected == null
                    ? AvIcon(Symbols.check, color: context.av.tint)
                    : null,
                onTap: enabled ? () => onExit?.call(null) : null,
              ),
              for (final peer in exits)
                AvRow(
                  title: peer.name,
                  subtitle: peer.online
                      ? peer.ips.join(', ')
                      : l.tailnetExitOffline,
                  titleColor: context.av.l3,
                  trailing: selected?.nodeStableId == peer.id
                      ? AvIcon(Symbols.check, color: context.av.tint)
                      : null,
                ),
              if (selected != null &&
                  !exits.any((p) => p.id == selected.nodeStableId))
                AvRow(
                  title: selected.name,
                  subtitle: l.tailnetExitOffline,
                  titleColor: context.av.l3,
                  trailing: AvIcon(Symbols.check, color: context.av.tint),
                ),
            ],
          ),
          AvSettingsSection(
            header: l.tailnetOptions,
            right: true,
            rows: [
              avSwitchRow(
                l.tailnetAcceptRoutes,
                subtitle: l.tailnetAcceptRoutesNote,
                value: s.acceptRoutes,
                onChanged: enabled ? onAcceptRoutes : null,
              ),
              avSwitchRow(
                l.tailnetMagicDns,
                subtitle: l.tailnetMagicDnsNote,
                value: s.magicDns,
                onChanged: enabled ? onMagicDns : null,
              ),
              avSwitchRow(
                l.tailnetAdvertiseExit,
                subtitle: l.tailnetAdvertiseNotReady,
                value: s.advertiseExit,
                onChanged: enabled && s.advertiseExit ? onAdvertiseExit : null,
              ),
            ],
          ),
          if (status.peers.isNotEmpty)
            AvSettingsSection(
              header: l.tailnetDevicesOnline(
                status.peers.where((p) => p.online).length,
              ),
              footer: l.tailnetFixedRoutesNote,
              right: true,
              rows: [
                for (final peer in status.peers)
                  AvRow(
                    title: peer.name,
                    subtitle:
                        '${peer.os} · ${peer.online ? l.tailnetOnline : l.tailnetOffline}',
                    value: peer.ips.join(', '),
                  ),
              ],
            ),
          AvSettingsSection(
            right: true,
            rows: [
              AvRow(
                title: l.tailnetLogout,
                titleColor: context.av.bad,
                onTap: enabled && status.connected ? onLogout : null,
              ),
            ],
          ),
        ],
      ],
    );
  }
}
