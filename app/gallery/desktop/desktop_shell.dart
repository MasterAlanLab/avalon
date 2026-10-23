// DEVELOPMENT ONLY: V3 desktop replica (3p macOS / 3q Windows / 3r Linux).
import 'package:av_design/av_design.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../gallery_state.dart';
import 'desktop_add.dart';
import 'desktop_pages.dart';
import 'desktop_tools.dart';

/// Which desktop family to draw: `--dart-define=AV_DESKTOP=mac|windows|linux`,
/// otherwise the host platform.
AvDesktopPlatform galleryDesktopPlatform() {
  const forced = String.fromEnvironment('AV_DESKTOP');
  switch (forced) {
    case 'mac':
      return AvDesktopPlatform.mac;
    case 'windows':
      return AvDesktopPlatform.windows;
    case 'linux':
      return AvDesktopPlatform.linux;
  }
  return switch (defaultTargetPlatform) {
    TargetPlatform.windows => AvDesktopPlatform.windows,
    TargetPlatform.linux => AvDesktopPlatform.linux,
    _ => AvDesktopPlatform.mac,
  };
}

const _navs = [
  AvSidebarItem(Symbols.speed_rounded, '仪表盘'),
  AvSidebarItem(Symbols.public_rounded, '代理'),
  AvSidebarItem(Symbols.folder_rounded, '配置'),
  AvSidebarItem(Symbols.handyman_rounded, '工具'),
];

class DesktopShell extends StatefulWidget {
  const DesktopShell({super.key, required this.spec});

  final AvDesktopSpec spec;

  @override
  State<DesktopShell> createState() => DesktopShellState();
}

class DesktopShellState extends State<DesktopShell> {
  int page = 0;
  String tool = 'basic';
  int? addSegment;

  static DesktopShellState of(BuildContext context) =>
      context.findAncestorStateOfType<DesktopShellState>()!;

  @override
  void initState() {
    super.initState();
    // Previewing the Windows or Linux frame on a Mac: hide the traffic lights.
    AvWindow.setNativeControlsVisible(
      widget.spec.platform == AvDesktopPlatform.mac,
    );
  }

  void go(int p) => setState(() => page = p);
  void openTool(String t) => setState(() {
    page = 3;
    tool = t;
  });
  void openAdd([int segment = 0]) => setState(() => addSegment = segment);
  void closeAdd({bool toProxies = false}) => setState(() {
    addSegment = null;
    if (toProxies) page = 1;
  });

  @override
  Widget build(BuildContext context) {
    final s = GalleryScope.of(context);
    final c = context.av;
    final spec = widget.spec;
    final title = const ['仪表盘', '代理', '配置', '工具'][page];

    final actions = <Widget>[
      if (page == 1)
        AvDesktopButton(
          label: '测速',
          icon: s.testing
              ? Symbols.progress_activity_rounded
              : Symbols.bolt_rounded,
          spin: s.testing,
          onTap: s.testAll,
        ),
      if (page == 2) ...[
        AvDesktopButton(
          label: '全部更新',
          icon: Symbols.refresh_rounded,
          onTap: () => s.set(() {
            for (final p in s.profiles) {
              p.updated = '刚刚';
            }
          }),
        ),
        AvDesktopButton(
          label: '添加',
          icon: Symbols.add_rounded,
          filled: true,
          onTap: openAdd,
        ),
      ],
    ];

    final content = switch (page) {
      0 => const DesktopDashboard(),
      1 => const DesktopProxies(),
      2 => const DesktopProfiles(),
      _ => DesktopTools(tool: tool, onSelect: (t) => setState(() => tool = t)),
    };

    final account = s.account;
    final footer = AvPressable(
      onTap: () => openTool('cloud'),
      scale: 0.97,
      scaleDuration: const Duration(milliseconds: 300),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: c.fill,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: account == 'loggedOut' ? c.fill2 : c.tint,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: account == 'loggedOut'
                  ? AvIcon(Symbols.person_rounded, size: 18, color: c.l2)
                  : Text(
                      'L',
                      style: AvType.footnoteStrong.copyWith(
                        color: const Color(0xFFFFFFFF),
                      ),
                    ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account == 'loggedOut' ? '登录 Avalon Cloud' : '林伟',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AvType.footnoteStrong.copyWith(color: c.l1),
                  ),
                  Row(
                    children: [
                      AvIcon(
                        account != 'paid'
                            ? Symbols.cloud_off_rounded
                            : (s.syncing
                                  ? Symbols.cloud_sync_rounded
                                  : Symbols.cloud_done_rounded),
                        size: 13,
                        color: c.l2,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          switch (account) {
                            'loggedOut' => '未登录 · 不同步',
                            'free' => '免费账户 · 不同步',
                            _ => s.syncing ? '正在同步…' : '已同步 · ${s.lastSync}',
                          },
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AvType.s(11).copyWith(color: c.l2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return AvDensity.desktop(
      child: ColoredBox(
        color: c.bg,
        child: Padding(
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
          child: Stack(
            children: [
              Column(
                children: [
                  AvWindowTitleBar(platform: spec.platform),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AvSidebar(
                          spec: spec,
                          version: 'sing-box 1.14.2',
                          showTrafficLights: !AvWindow.hasNativeControls,
                          items: _navs,
                          index: page,
                          onSelect: go,
                          footer: footer,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              AvDesktopToolbar(
                                title: title,
                                actions: actions,
                                trailing: [
                                  AvSegmented<String>(
                                    values: const ['规则', '全局', '直连'],
                                    labelOf: (v) => v,
                                    selected: s.mode,
                                    width: 204,
                                    height: 32,
                                    onChanged: (v) => s.set(() => s.mode = v),
                                  ),
                                  AvConnectionStatus(
                                    connected: s.connected,
                                    label: s.connected ? '已连接' : '未连接',
                                    onToggle: () =>
                                        s.set(() => s.connected = !s.connected),
                                  ),
                                ],
                              ),
                              Expanded(
                                child: AvFadeSwap(
                                  token: page == 3 ? 'tools' : page,
                                  duration: const Duration(milliseconds: 300),
                                  child: content,
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
              if (addSegment != null)
                DesktopAddDialog(initial: addSegment!, spec: spec),
            ],
          ),
        ),
      ),
    );
  }
}
