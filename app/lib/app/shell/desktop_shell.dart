import 'package:av_core/av_core.dart';
import 'package:av_design/av_design.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../features/configurations/configurations_toolbar.dart';
import '../../features/proxies/proxies_toolbar.dart';
import '../../l10n/app_localizations.dart';
import '../../runtime/runtime_coordinator.dart';
import '../layout.dart';
import '../providers.dart';

/// The desktop frame (V3 3p/3q/3r): title bar, sidebar, and a toolbar with
/// the page's actions, the outbound mode and the connection button
/// (PRODUCT_SPEC §2).
class DesktopShell extends ConsumerWidget {
  const DesktopShell({super.key, required this.shell, this.platform});

  final StatefulNavigationShell shell;

  /// Overrides the host's window frame (golden tests draw all three).
  final AvDesktopPlatform? platform;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final spec = AvDesktopSpec.of(platform ?? hostDesktopPlatform());
    final index = shell.currentIndex;
    final titles = [
      l.tabDashboard,
      l.tabProxies,
      l.tabConfigurations,
      l.tabTools,
    ];
    const icons = [
      Symbols.speed_rounded,
      Symbols.public_rounded,
      Symbols.folder_rounded,
      Symbols.handyman_rounded,
    ];
    final mode = ref.watch(outboundModeProvider);
    final runtime = ref.watch(runtimeProvider);

    return AvDensity.desktop(
      child: ColoredBox(
        color: context.av.bg,
        child: Padding(
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
          child: Column(
            children: [
              AvWindowTitleBar(platform: spec.platform),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AvSidebar(
                      spec: spec,
                      showTrafficLights: !AvWindow.hasNativeControls,
                      items: [
                        for (var i = 0; i < titles.length; i++)
                          AvSidebarItem(icons[i], titles[i]),
                      ],
                      index: index,
                      onSelect: (i) =>
                          shell.goBranch(i, initialLocation: i == index),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          AvDesktopToolbar(
                            title: titles[index],
                            actions: switch (index) {
                              1 => const [TestLatencyButton()],
                              2 => const [
                                RefreshAllConfigurationsButton(),
                                AddConfigurationButton(),
                              ],
                              _ => const [],
                            },
                            trailing: [
                              AvSegmented<OutboundMode>(
                                values: OutboundMode.values,
                                labelOf: (m) => switch (m) {
                                  OutboundMode.rule => l.modeRule,
                                  OutboundMode.global => l.modeGlobal,
                                  OutboundMode.direct => l.modeDirect,
                                },
                                selected: mode,
                                width: 204,
                                height: 32,
                                onChanged: (m) => ref
                                    .read(outboundModeProvider.notifier)
                                    .set(m),
                              ),
                              // Where this platform has no host yet the
                              // button says so instead of pretending.
                              AvConnectionStatus(
                                connected: runtime.connected,
                                label: runtime.connected
                                    ? l.statusConnected
                                    : l.statusDisconnected,
                                onToggle: () => runtime.available
                                    ? ref
                                          .read(runtimeProvider.notifier)
                                          .toggle()
                                    : showAvNotice(
                                        context,
                                        title: l.coreNotConnected,
                                        message: l.coreNotConnectedNote,
                                        ok: l.ok,
                                      ),
                              ),
                            ],
                          ),
                          Expanded(
                            child: AvFadeSwap(
                              token: index,
                              duration: const Duration(milliseconds: 300),
                              child: shell,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
