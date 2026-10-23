import 'package:av_design/av_design.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/app_localizations.dart';

/// Four tabs, each with its own navigator so pushed pages keep the tab bar,
/// and V3's fade when switching tabs (`ios-fade .32s`).
class MobileShell extends StatelessWidget {
  const MobileShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return ColoredBox(
      color: context.av.bg,
      child: Stack(
        children: [
          Positioned.fill(
            child: AvFadeSwap(
              token: shell.currentIndex,
              cacheDuringTransition:
                  defaultTargetPlatform == TargetPlatform.android,
              child: shell,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AvTabBar(
              items: [
                AvTabItem(Symbols.speed_rounded, l.tabDashboard),
                AvTabItem(Symbols.public_rounded, l.tabProxies),
                AvTabItem(Symbols.folder_rounded, l.tabConfigurations),
                AvTabItem(Symbols.handyman_rounded, l.tabTools),
              ],
              index: shell.currentIndex,
              // Tapping the current tab returns to its root page.
              onTap: (i) =>
                  shell.goBranch(i, initialLocation: i == shell.currentIndex),
            ),
          ),
        ],
      ),
    );
  }
}
