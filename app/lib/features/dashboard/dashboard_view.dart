import 'package:av_core/av_core.dart';
import 'package:av_design/av_design.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/format.dart';
import '../../app/latency_label.dart';
import '../../app/layout.dart';
import '../../l10n/app_localizations.dart';
import 'dashboard_state.dart';

/// Seconds across the speed chart.
const _chartSamples = 30;

/// The dashboard (V3 3a; desktop 3p «仪表盘»). Pure: it draws [state] and
/// reports gestures. What is not known is «—» (PRODUCT_SPEC §1).
class DashboardView extends StatelessWidget {
  const DashboardView({
    super.key,
    required this.state,
    required this.platform,
    required this.onPower,
    required this.onMode,
    required this.onTun,
    required this.onSystemProxy,
    required this.onExit,
  });

  final DashboardState state;
  final AppPlatform platform;
  final VoidCallback onPower;
  final ValueChanged<OutboundMode> onMode;
  final ValueChanged<bool> onTun;
  final ValueChanged<bool> onSystemProxy;

  /// The current node card: to the proxies page.
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.av;
    final desktop = AvDensity.isDesktop(context);
    final direct = state.mode == OutboundMode.direct;
    // iOS always tunnels; Android's system proxy lives inside the tunnel.
    final showTun = platform != AppPlatform.ios;
    final proxyNeedsTun =
        platform == AppPlatform.android && state.tunKnown && !state.tunEnabled;

    final exit = state.exit;
    final exitName = direct
        ? 'DIRECT'
        : !state.hasConfiguration
        ? l.noConfigurationSelected
        : exit?.name ?? '—';
    final exitKind = direct
        ? l.modeDirectFull
        : exit == null
        ? '—'
        : exit.unavailable
        ? l.unavailable
        : switch (exit.kind) {
            ExitKind.node => exit.protocol?.label ?? l.unavailable,
            ExitKind.chain => l.memberChain(exit.hops),
            ExitKind.group => l.memberGroup(exit.groupType ?? ''),
            ExitKind.direct => l.memberDirect,
            ExitKind.reject => l.memberReject,
            ExitKind.tailnet => 'Tailscale',
          };
    // The exit's last latency test; direct traffic has none to show.
    final measured = latencyLabel(l, c, direct ? null : exit?.latency);
    final latency = Text(
      measured.text,
      style:
          (desktop
                  ? AvType.footnoteStrong
                  : AvType.s(12, weight: FontWeight.w600))
              .copyWith(color: measured.color),
    );

    final connected = state.connected;
    final statusColor = state.status == ConnectionStatus.connected
        ? c.ok
        : c.l2;
    final status = Row(
      children: [
        AvBlinkDot(
          color: statusColor,
          active: state.status == ConnectionStatus.connected,
        ),
        const SizedBox(width: 6),
        Text(
          switch (state.status) {
            ConnectionStatus.connected => l.statusConnected,
            ConnectionStatus.connecting => l.statusConnecting,
            ConnectionStatus.reconnecting => l.statusReconnecting,
            ConnectionStatus.disconnecting => l.statusDisconnecting,
            ConnectionStatus.disconnected ||
            ConnectionStatus.unavailable => l.statusDisconnected,
          },
          style: (desktop ? AvType.footnoteStrong : AvType.subheadStrong)
              .copyWith(color: statusColor),
        ),
      ],
    );
    final failure = _failureText(l, state.failure);
    // Under the title: what went wrong, else what is running, else what
    // is ready.
    final summary =
        failure ??
        (connected
            ? l.connectedSummary(switch (state.mode) {
                OutboundMode.rule => l.modeRuleFull,
                OutboundMode.global => l.modeGlobalFull,
                OutboundMode.direct => l.modeDirectFull,
              }, exitName)
            : state.status == ConnectionStatus.unavailable
            ? l.coreNotConnected
            : state.coreVersion.isEmpty
            ? ''
            : l.coreReady(state.coreVersion));
    final heroText = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        status,
        Text(
          connected
              ? formatElapsed(state.connectedFor ?? Duration.zero)
              : 'Avalon',
          style: desktop
              ? AvType.numeric(
                  40,
                  weight: FontWeight.w700,
                ).copyWith(color: c.l1)
              : AvType.numeric(
                  32,
                  weight: FontWeight.w700,
                  tracking: -0.02,
                ).copyWith(height: 1.15, color: c.l1),
        ),
        Text(
          summary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AvType.footnote.copyWith(
            color: failure == null ? c.l2 : c.bad,
          ),
        ),
      ],
    );
    final hero = AvCard(
      radius: desktop ? 16 : 22,
      padding: desktop
          ? const EdgeInsets.symmetric(vertical: 18, horizontal: 20)
          : const EdgeInsets.fromLTRB(18, 14, 16, 14),
      child: Row(
        children: [
          Expanded(child: heroText),
          SizedBox(width: desktop ? 16 : 14),
          _PowerButton(
            size: desktop ? 76 : 68,
            connected: connected,
            onTap: onPower,
          ),
        ],
      ),
    );

    final up = formatSpeed(state.upBps);
    final down = formatSpeed(state.downBps);
    final speedChart = AvSpeedChart(
      // Oldest first, the newest at the right edge; flat before any data.
      samples: [
        for (var i = state.speeds.length; i < _chartSamples; i++) 0.0,
        for (final speed in state.speeds) speed / 1024,
      ],
      active: connected,
      strokeWidth: desktop ? 2 : 2.2,
    );
    String total(int? bytes) => bytes == null ? '—' : formatBytes(bytes);

    if (desktop) {
      const pad = EdgeInsets.symmetric(vertical: 16, horizontal: 20);
      Widget toggle(String label, bool? value, ValueChanged<bool>? onChanged) =>
          Row(
            children: [
              Expanded(
                child: Text(label, style: AvType.s(14).copyWith(color: c.l1)),
              ),
              value == null
                  ? Text('—', style: AvType.subheadStrong.copyWith(color: c.l2))
                  : AvSwitch(value: value, onChanged: onChanged),
            ],
          );
      final speed = AvCard(
        radius: 16,
        padding: pad,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: _Label(
                    Symbols.speed_rounded,
                    l.networkSpeed,
                    AvHues.blue,
                  ),
                ),
                Text(
                  '↑ $up ↓ $down',
                  style: AvType.s(
                    15,
                    weight: FontWeight.w600,
                    tabular: true,
                  ).copyWith(color: c.l1),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(height: 84, child: speedChart),
          ],
        ),
      );
      final nodeCard = AvCard(
        radius: 16,
        padding: pad,
        onTap: onExit,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Label(Symbols.location_on_rounded, l.currentNode, AvHues.orange),
            const SizedBox(height: 8),
            Text(
              exitName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AvType.s(
                20,
                weight: FontWeight.w600,
              ).copyWith(color: c.l1),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    exitKind,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AvType.footnote.copyWith(color: c.l2),
                  ),
                ),
                if (!direct) latency,
              ],
            ),
          ],
        ),
      );
      final ipCard = AvCard(
        radius: 16,
        padding: pad,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Label(Symbols.language_rounded, l.exitIp, AvHues.teal),
            const SizedBox(height: 8),
            Text(
              state.exitLocation ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AvType.s(
                20,
                weight: FontWeight.w600,
              ).copyWith(color: c.l1),
            ),
            Text(
              state.exitAddress ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AvType.s(13, tabular: true).copyWith(color: c.l2),
            ),
          ],
        ),
      );
      final toggles = AvCard(
        radius: 16,
        padding: pad,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            toggle(
              l.sectionTun,
              state.tunKnown ? state.tunEnabled : null,
              onTun,
            ),
            const SizedBox(height: 12),
            toggle(
              l.systemProxy,
              state.systemProxyKnown
                  ? state.systemProxy && !proxyNeedsTun
                  : null,
              proxyNeedsTun ? null : onSystemProxy,
            ),
            if (proxyNeedsTun) AvFormNote(l.systemProxyNeedsTun),
          ],
        ),
      );
      final traffic = AvCard(
        radius: 16,
        padding: pad,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Label(Symbols.data_usage_rounded, l.todayTraffic, AvHues.pink),
            const SizedBox(height: 8),
            Text(
              '↑ ${total(state.todayUp)}\n↓ ${total(state.todayDown)}',
              style: AvType.s(
                15,
                weight: FontWeight.w600,
                height: 1.6,
                tabular: true,
              ).copyWith(color: c.l1),
            ),
          ],
        ),
      );
      return ColoredBox(
        color: c.bg,
        child: AvDesktopPage(
          child: AvGrid(
            columns: 4,
            gap: 14,
            rows: [
              [(2, hero), (2, speed)],
              [(1, nodeCard), (1, ipCard), (1, toggles), (1, traffic)],
            ],
          ),
        ),
      );
    }

    final mq = MediaQuery.of(context);
    final header = Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(
        l.tabDashboard,
        style: AvType.largeTitle.copyWith(color: c.l1, height: 1.15),
      ),
    );
    final mode = AvSegmented<OutboundMode>(
      values: OutboundMode.values,
      labelOf: (m) => switch (m) {
        OutboundMode.rule => l.modeRuleFull,
        OutboundMode.global => l.modeGlobalFull,
        OutboundMode.direct => l.modeDirectFull,
      },
      selected: state.mode,
      onChanged: onMode,
    );
    final speed = AvCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label(Symbols.speed_rounded, l.networkSpeed, AvHues.blue),
          const SizedBox(height: 2),
          Row(
            children: [
              _SpeedValue('↑', up),
              const SizedBox(width: 18),
              _SpeedValue('↓', down),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(child: speedChart),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.sep, width: 0.5)),
            ),
            child: Row(
              children: [
                _Total('${l.todayUpload} ', total(state.todayUp)),
                const Spacer(),
                _Total('${l.todayDownload} ', total(state.todayDown)),
              ],
            ),
          ),
        ],
      ),
    );
    final cards = Row(
      children: [
        Expanded(
          child: AvCard(
            radius: 20,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            pressScale: 0.96,
            onTap: onExit,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label(
                  Symbols.location_on_rounded,
                  l.currentNode,
                  AvHues.orange,
                ),
                const SizedBox(height: 6),
                Text(
                  exitName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AvType.bodyStrong.copyWith(color: c.l1),
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        exitKind,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AvType.caption.copyWith(color: c.l2),
                      ),
                    ),
                    if (!direct) latency,
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AvCard(
            radius: 20,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label(Symbols.language_rounded, l.exitIp, AvHues.teal),
                const SizedBox(height: 6),
                Text(
                  state.exitLocation ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AvType.bodyStrong.copyWith(color: c.l1),
                ),
                const SizedBox(height: 1),
                Text(
                  state.exitAddress ?? '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AvType.s(12, tabular: true).copyWith(color: c.l2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    Widget toggleCard(
      IconData icon,
      Color hue,
      String label,
      bool? value,
      ValueChanged<bool>? onChanged,
    ) => AvCard(
      radius: 20,
      padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
      child: Row(
        children: [
          AvIcon(icon, size: 17, color: hue),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              style: AvType.subheadStrong.copyWith(color: c.l1),
            ),
          ),
          const SizedBox(width: 8),
          value == null
              ? Text('—', style: AvType.subheadStrong.copyWith(color: c.l2))
              : AvSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
    final systemProxy = toggleCard(
      Symbols.settings_ethernet_rounded,
      AvHues.purple,
      l.systemProxy,
      state.systemProxyKnown ? state.systemProxy && !proxyNeedsTun : null,
      proxyNeedsTun ? null : onSystemProxy,
    );
    final toggles = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (showTun) ...[
              Expanded(
                child: toggleCard(
                  Symbols.layers_rounded,
                  AvHues.indigo,
                  'TUN',
                  state.tunKnown ? state.tunEnabled : null,
                  onTun,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(child: systemProxy),
          ],
        ),
        if (proxyNeedsTun) AvFormNote(l.systemProxyNeedsTun),
      ],
    );

    // Laid out for one hand (D92, PRODUCT_SPEC §3.1): what is read at the
    // top, what is touched towards the bottom, the start/stop button
    // lowest, within the thumb's reach. The speed card takes the remaining
    // height; short screens scroll with a fixed chart height.
    final bottom = AvTabBar.barHeight + mq.padding.bottom + 14;
    return ColoredBox(
      color: c.bg,
      child: LayoutBuilder(
        builder: (context, box) {
          final fits = box.maxHeight - mq.padding.top - bottom >= 560;
          final children = [
            header,
            cards,
            if (fits)
              Expanded(child: speed)
            else
              SizedBox(height: 220, child: speed),
            mode,
            toggles,
            hero,
          ];
          final padded = Padding(
            padding: EdgeInsets.fromLTRB(16, mq.padding.top, 16, bottom),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  children[i],
                ],
              ],
            ),
          );
          return fits
              ? padded
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: padded,
                );
        },
      ),
    );
  }
}

/// The start/stop button, at rest until the core can be started (L2).
/// What went wrong, in a line; the screen shows the detail.
String? _failureText(AppLocalizations l, ConnectionFailure? failure) =>
    switch (failure) {
      null => null,
      ConnectionFailure.systemProxy => l.systemProxyFailed,
      ConnectionFailure.permissionRefused => l.runtimePermissionRefused,
      ConnectionFailure.noListedAppInstalled => l.runtimeNoListedAppInstalled,
      ConnectionFailure.nothingSelected => l.addConfigurationFirst,
      ConnectionFailure.notDownloaded => l.runtimeNotDownloaded,
      ConnectionFailure.planFailed => l.runtimePlanFailed,
      ConnectionFailure.hostUnreachable => l.runtimeHostUnreachable,
      ConnectionFailure.portInUse => l.runtimePortInUse,
      ConnectionFailure.planRefused => l.runtimePlanRefused,
      ConnectionFailure.coreFailed => l.runtimeCoreFailed,
      ConnectionFailure.timeout => l.runtimeTimeout,
    };

/// The failure as the dashboard words it, for the screen's notice.
String? dashboardFailureText(AppLocalizations l, ConnectionFailure? failure) =>
    _failureText(l, failure);

class _PowerButton extends StatelessWidget {
  const _PowerButton({
    required this.size,
    required this.connected,
    required this.onTap,
  });

  final double size;
  final bool connected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    return SizedBox.square(
      dimension: size,
      child: AvPressable(
        onTap: onTap,
        scale: size > 70 ? 0.88 : 0.86,
        scaleDuration: const Duration(milliseconds: 500),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 450),
          curve: AvMotion.ease,
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: connected ? c.tint : c.fill,
            shape: BoxShape.circle,
            boxShadow: connected
                ? AvShadows.glow(c)
                : [
                    BoxShadow(
                      color: c.tintBg.withValues(alpha: 0),
                      offset: const Offset(0, 8),
                      blurRadius: 24,
                    ),
                  ],
          ),
          alignment: Alignment.center,
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: connected ? const Color(0xFFFFFFFF) : c.l2),
            duration: const Duration(milliseconds: 450),
            builder: (context, color, _) => AvIcon(
              Symbols.power_settings_new_rounded,
              size: size > 70 ? 36 : 34,
              weight: 600,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.icon, this.text, this.color);

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      AvIcon(icon, size: 16, color: color),
      const SizedBox(width: 5),
      Flexible(
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AvType.footnoteStrong.copyWith(color: color),
        ),
      ),
    ],
  );
}

class _SpeedValue extends StatelessWidget {
  const _SpeedValue(this.arrow, this.value);

  final String arrow;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$arrow ',
            style: AvType.s(15).copyWith(color: c.l2),
          ),
          TextSpan(
            text: value,
            style: AvType.numeric(22).copyWith(color: c.l1),
          ),
        ],
      ),
    );
  }
}

class _Total extends StatelessWidget {
  const _Total(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: label,
            style: AvType.footnote.copyWith(color: c.l2),
          ),
          TextSpan(
            text: value,
            style: AvType.s(
              13,
              weight: FontWeight.w600,
              tabular: true,
            ).copyWith(color: c.l1),
          ),
        ],
      ),
    );
  }
}
