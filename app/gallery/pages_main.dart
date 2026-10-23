// DEVELOPMENT ONLY: V3 replica of 3a dashboard, 3b proxies, 3c profiles, 3g tools.
import 'package:av_design/av_design.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'add_sheet.dart';
import 'gallery_app.dart';
import 'gallery_state.dart';
import 'pages_more.dart';
import 'pages_tools.dart';

({String text, Color color}) latencyOf(
  BuildContext context,
  GalleryState s,
  String name,
) {
  final c = context.av;
  if (s.testing) return (text: '···', color: c.l3);
  final v = s.lat[name];
  if (v == null) return (text: '—', color: c.l3);
  if (v == 0) return (text: '超时', color: c.bad);
  return (text: '$v ms', color: v < 150 ? c.ok : (v < 300 ? c.warn : c.bad));
}

// ───────────────────────────── 3a 仪表盘 ─────────────────────────────

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = GalleryScope.of(context);
    final c = context.av;
    final mq = MediaQuery.of(context);
    final direct = s.mode == '直连';
    final g0 = s.allNodes[s.sel[0]];
    final lat = latencyOf(context, s, g0.name);

    final header = Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '仪表盘',
              style: AvType.largeTitle.copyWith(color: c.l1, height: 1.15),
            ),
          ),
          AvCircleButton(
            icon: switch (s.account) {
              'paid' =>
                s.syncing
                    ? Symbols.cloud_sync_rounded
                    : Symbols.cloud_done_rounded,
              _ => Symbols.cloud_off_rounded,
            },
            onTap: () =>
                GalleryShellState.of(context).openInTools(const CloudPage()),
          ),
        ],
      ),
    );

    final hero = AvCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(18, 14, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AvBlinkDot(
                      color: s.connected ? c.ok : c.l2,
                      active: s.connected,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      s.connected ? '已连接' : '未连接',
                      style: AvType.subheadStrong.copyWith(
                        color: s.connected ? c.ok : c.l2,
                      ),
                    ),
                  ],
                ),
                Text(
                  s.connected
                      ? '${two(s.seconds ~/ 3600)}:${two(s.seconds ~/ 60 % 60)}:${two(s.seconds % 60)}'
                      : 'Avalon',
                  style: AvType.numeric(
                    32,
                    weight: FontWeight.w700,
                    tracking: -0.02,
                  ).copyWith(height: 1.15, color: c.l1),
                ),
                Text(
                  s.connected
                      ? '${s.mode}模式 · ${direct ? 'DIRECT' : g0.name}'
                      : 'sing-box 1.12.4 已就绪',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AvType.footnote.copyWith(color: c.l2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          _PowerButton(
            connected: s.connected,
            onTap: () {
              HapticFeedback.lightImpact();
              s.set(() => s.connected = !s.connected);
            },
          ),
        ],
      ),
    );

    final mode = AvSegmented<String>(
      values: const ['规则', '全局', '直连'],
      labelOf: (v) => '$v模式',
      selected: s.mode,
      onChanged: (v) => s.set(() => s.mode = v),
    );

    final speed = AvCard(
      radius: 22,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardLabel(Symbols.speed_rounded, '网络速度', AvHues.blue),
          const SizedBox(height: 2),
          Row(
            children: [
              _SpeedValue('↑', s.connected ? fmtSpeed(s.up) : '0 KB/s'),
              const SizedBox(width: 18),
              _SpeedValue('↓', s.connected ? fmtSpeed(s.hist.last) : '0 KB/s'),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: AvSpeedChart(samples: s.hist, active: s.connected),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: c.sep, width: 0.5)),
            ),
            child: Row(
              children: [
                _Total('今日上传 ', fmtBytes(s.totU)),
                const Spacer(),
                _Total('下载 ', fmtBytes(s.totD)),
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
            onTap: () => GalleryShellState.of(context).select(1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardLabel(Symbols.location_on_rounded, '当前节点', AvHues.orange),
                const SizedBox(height: 6),
                Text(
                  direct ? 'DIRECT' : g0.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AvType.bodyStrong.copyWith(color: c.l1),
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        direct ? '直连模式' : g0.proto,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AvType.caption.copyWith(color: c.l2),
                      ),
                    ),
                    if (!direct)
                      Text(
                        lat.text,
                        style: AvType.s(
                          12,
                          weight: FontWeight.w600,
                        ).copyWith(color: lat.color),
                      ),
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
                _CardLabel(Symbols.language_rounded, '出口 IP', AvHues.teal),
                const SizedBox(height: 6),
                Text(
                  s.connected && !direct ? '中国香港' : '中国上海',
                  style: AvType.bodyStrong.copyWith(color: c.l1),
                ),
                const SizedBox(height: 1),
                Text(
                  s.connected && !direct ? '203.0.113.24' : '198.51.100.7',
                  style: AvType.s(12, tabular: true).copyWith(color: c.l2),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    Widget toggleCard(IconData icon, Color hue, String label, String key) =>
        AvCard(
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
              AvSwitch(
                value: s.toggles[key]!,
                onChanged: (v) => s.set(() => s.toggles[key] = v),
              ),
            ],
          ),
        );

    final toggles = Row(
      children: [
        Expanded(
          child: toggleCard(
            Symbols.layers_rounded,
            AvHues.indigo,
            'TUN',
            'tun',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: toggleCard(
            Symbols.settings_ethernet_rounded,
            AvHues.purple,
            '系统代理',
            'sys',
          ),
        ),
      ],
    );

    // V3 fits the dashboard to the screen (`height:100%; overflow:hidden`) and
    // lets the speed card absorb the remaining height. On short screens we
    // fall back to scrolling with a fixed chart height.
    final bottom = AvTabBar.barHeight + mq.padding.bottom + 14;
    return ColoredBox(
      color: c.bg,
      child: LayoutBuilder(
        builder: (context, box) {
          final fits = box.maxHeight - mq.padding.top - bottom >= 560;
          final children = [
            header,
            hero,
            mode,
            if (fits)
              Expanded(child: speed)
            else
              SizedBox(height: 220, child: speed),
            cards,
            toggles,
          ];
          final column = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                children[i],
              ],
            ],
          );
          final padded = Padding(
            padding: EdgeInsets.fromLTRB(16, mq.padding.top, 16, bottom),
            child: column,
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

class _PowerButton extends StatelessWidget {
  const _PowerButton({required this.connected, required this.onTap});

  final bool connected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    return SizedBox.square(
      dimension: 68,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AvPulseRings(size: 68, active: connected),
          AvPressable(
            onTap: onTap,
            scale: 0.86,
            scaleDuration: const Duration(milliseconds: 500),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 450),
              curve: AvMotion.ease,
              width: 68,
              height: 68,
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
                tween: ColorTween(
                  end: connected ? const Color(0xFFFFFFFF) : c.l2,
                ),
                duration: const Duration(milliseconds: 450),
                builder: (context, col, _) => AvIcon(
                  Symbols.power_settings_new_rounded,
                  size: 34,
                  weight: 600,
                  color: col,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardLabel extends StatelessWidget {
  const _CardLabel(this.icon, this.text, this.color);

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      AvIcon(icon, size: 16, color: color),
      const SizedBox(width: 5),
      Text(text, style: AvType.footnoteStrong.copyWith(color: color)),
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

// ───────────────────────────── 3b 代理 ─────────────────────────────

class ProxiesPage extends StatelessWidget {
  const ProxiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = GalleryScope.of(context);
    final c = context.av;
    final groups = s.groups;
    final g = groups[s.group];
    final all = s.allNodes;
    final selected = g.members.contains(s.sel[s.group])
        ? s.sel[s.group]
        : g.members.first;

    return AvRootPage(
      children: [
        AvLargeTitle(
          '代理',
          actions: [
            AvPillButton(
              label: '测速',
              icon: s.testing
                  ? Symbols.progress_activity_rounded
                  : Symbols.bolt_rounded,
              iconSpin: s.testing,
              onTap: s.testAll,
            ),
          ],
        ),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            itemCount: groups.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) => _GroupChip(
              label: groups[i].name,
              selected: i == s.group,
              onTap: () => s.set(() => s.group = i),
            ),
          ),
        ),
        if (s.mode == '直连')
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: c.cell,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  AvIcon(Symbols.info_rounded, size: 18, color: c.warn),
                  const SizedBox(width: 8),
                  Text(
                    '直连模式下代理组不生效',
                    style: AvType.footnote.copyWith(color: c.l2),
                  ),
                ],
              ),
            ),
          ),
        AvSectionHeader(
          '${g.type} · ${g.members.length} 个节点',
          top: 20,
          trailing: all[selected].name,
        ),
        AvGroup(
          children: [
            for (final i in g.members)
              Builder(
                builder: (context) {
                  final n = all[i];
                  final l = latencyOf(context, s, n.name);
                  return AvRow(
                    insetSeparator: true,
                    minHeight: 56,
                    padding: const EdgeInsets.only(right: 14),
                    title: n.name,
                    subtitle: n.proto,
                    onTap: () => s.set(() => s.sel[s.group] = i),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l.text,
                          style: AvType.numeric(
                            15,
                            weight: FontWeight.w500,
                          ).copyWith(color: l.color),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 22,
                          child: AvPopIcon(
                            Symbols.check_rounded,
                            visible: i == selected,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _GroupChip extends StatelessWidget {
  const _GroupChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    return AvPressable(
      onTap: onTap,
      scale: 0.92,
      scaleDuration: const Duration(milliseconds: 300),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: AvMotion.ease,
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? c.tint : c.cell,
          borderRadius: BorderRadius.circular(17),
        ),
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: DefaultTextStyle.of(context).style.merge(
            AvType.calloutStrong.copyWith(
              color: selected ? const Color(0xFFFFFFFF) : c.l1,
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}

// ───────────────────────────── 3c 配置 ─────────────────────────────

class ProfilesPage extends StatelessWidget {
  const ProfilesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = GalleryScope.of(context);
    return AvRootPage(
      children: [
        AvLargeTitle(
          '配置',
          actions: [
            AvCircleButton(
              icon: Symbols.refresh_rounded,
              onTap: () => s.set(() {
                for (final p in s.profiles) {
                  p.updated = '刚刚';
                }
              }),
            ),
            AvCircleButton(
              icon: Symbols.add_rounded,
              primary: true,
              iconSize: 22,
              iconWeight: 600,
              onTap: () => showAddSheet(context, 0),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              for (final p in s.profiles) ...[
                if (p != s.profiles.first) const SizedBox(height: 12),
                _ProfileCard(p: p),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.p});

  final DemoProfile p;

  @override
  Widget build(BuildContext context) {
    final s = GalleryScope.of(context);
    final c = context.av;
    final on = s.active == p.id;
    final localNodes = s.custom.where((n) => !n.chain).length;
    final localChains = s.custom.where((n) => n.chain).length;
    final src = p.local ? '本地 · $localChains 条代理链' : p.src;
    final nodes = p.local ? localNodes : p.nodes;
    final pct = p.used == null ? 0.0 : p.used! / p.total!;

    return AvCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      selected: on,
      onTap: () => s.set(() => s.active = p.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: on ? c.tint : c.l3),
                duration: const Duration(milliseconds: 300),
                builder: (context, col, _) => AvIcon(
                  on
                      ? Symbols.check_circle_rounded
                      : Symbols.radio_button_unchecked_rounded,
                  size: 24,
                  color: col,
                  fill: on ? 1 : 0,
                  weight: on ? 500 : 300,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: AvType.bodyStrong.copyWith(color: c.l1),
                    ),
                    Text(
                      '$src · $nodes 个节点 · ${p.updated}更新',
                      style: AvType.footnote.copyWith(color: c.l2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              AvPressable(
                onTap: () => s.set(() => p.updated = '刚刚'),
                pressedOpacity: 0.5,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: c.fill,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: AvIcon(
                    Symbols.refresh_rounded,
                    size: 18,
                    color: c.tint,
                  ),
                ),
              ),
            ],
          ),
          if (p.used != null) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 4,
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: c.fill,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: pct,
                      heightFactor: 1,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: pct > 0.8 ? c.bad : c.tint,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '${p.used} GB / ${p.total!.round()} GB',
                        style: AvType.s(
                          12,
                          tabular: true,
                        ).copyWith(color: c.l2),
                      ),
                      const Spacer(),
                      Text(
                        '${p.expire} 到期',
                        style: AvType.s(
                          12,
                          tabular: true,
                        ).copyWith(color: c.l2),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ───────────────────────────── 3g 工具 ─────────────────────────────

class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = GalleryScope.of(context);
    final c = context.av;

    AvRow tool(
      IconData icon,
      Color hue,
      String title, {
      String? value,
      VoidCallback? onTap,
    }) => AvRow(
      leading: AvIconTile(icon, hue),
      title: title,
      value: value,
      chevron: true,
      onTap: onTap ?? () {},
    );

    return AvRootPage(
      children: [
        const AvLargeTitle('工具'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ColoredBox(
              color: c.cell,
              child: AvPressable(
                highlight: true,
                onTap: () => pushPage(context, const CloudPage()),
                // Gallery only: long-press cycles paid → free → logged out.
                onLongPress: () => s.set(
                  () => s.account = switch (s.account) {
                    'paid' => 'free',
                    'free' => 'loggedOut',
                    _ => 'paid',
                  },
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: c.tint,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: s.account == 'loggedOut'
                            ? const AvIcon(
                                Symbols.person_rounded,
                                size: 30,
                                color: Color(0xFFFFFFFF),
                              )
                            : Text(
                                'L',
                                style: AvType.s(
                                  22,
                                  weight: FontWeight.w600,
                                ).copyWith(color: const Color(0xFFFFFFFF)),
                              ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.account == 'loggedOut'
                                  ? '登录 Avalon Cloud'
                                  : '林伟',
                              style: AvType.title3.copyWith(color: c.l1),
                            ),
                            Text(switch (s.account) {
                              'paid' => 'Avalon Cloud · 已同步 ${s.lastSync}',
                              'free' => '免费账户 · 不同步',
                              _ => '在所有设备间同步节点',
                            }, style: AvType.footnote.copyWith(color: c.l2)),
                          ],
                        ),
                      ),
                      const AvChevron(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const AvSectionHeader('查看'),
        AvGroup(
          children: [
            tool(
              Symbols.lan_rounded,
              AvHues.green,
              '连接',
              value: '${s.connected ? s.conns.length : 0}',
              onTap: () => pushPage(context, const ConnectionsPage()),
            ),
            tool(
              Symbols.article_rounded,
              AvHues.gray,
              '日志',
              onTap: () => pushPage(context, const LogsPage()),
            ),
          ],
        ),
        const AvSectionHeader('设置'),
        AvGroup(
          children: [
            tool(
              Symbols.settings_rounded,
              AvHues.gray,
              '基础设置',
              onTap: () => pushPage(context, const BasicSettingsPage()),
            ),
            tool(
              Symbols.tune_rounded,
              AvHues.blue,
              '高级设置',
              value: 'TUN · DNS',
              onTap: () => pushPage(context, const AdvancedSettingsPage()),
            ),
            tool(
              Symbols.apps_rounded,
              AvHues.indigo,
              '分应用代理',
              value: s.appMode,
              onTap: () => pushPage(context, const AppsPage()),
            ),
            tool(
              Symbols.travel_explore_rounded,
              AvHues.teal,
              'GEO 规则集',
              value: s.geoBusy.isNotEmpty ? '更新中…' : s.geo.first.when,
              onTap: () => pushPage(context, const GeoPage()),
            ),
            tool(
              Symbols.hub_rounded,
              AvHues.graphite,
              'Tailscale',
              value: s.tsOn ? '已连接' : '关闭',
              onTap: () => pushPage(context, const TailscalePage()),
            ),
          ],
        ),
        const SizedBox(height: 24),
        AvGroup(
          children: [
            tool(
              Symbols.info_rounded,
              AvHues.gray,
              '关于 Avalon',
              value: '0.1.0',
              onTap: () => pushPage(context, const AboutPage()),
            ),
          ],
        ),
      ],
    );
  }
}
