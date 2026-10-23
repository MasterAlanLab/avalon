// DEVELOPMENT ONLY: V3 desktop dashboard, proxies and profiles.
import 'package:av_design/av_design.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../gallery_state.dart';
import '../pages_main.dart' show latencyOf;
import 'desktop_shell.dart';

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
      Text(text, style: AvType.footnoteStrong.copyWith(color: color)),
    ],
  );
}

// ───────────────────────────── 仪表盘 ─────────────────────────────

class DesktopDashboard extends StatelessWidget {
  const DesktopDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final s = GalleryScope.of(context);
    final c = context.av;
    final direct = s.mode == '直连';
    final node = s.allNodes[s.sel[0]];
    final lat = latencyOf(context, s, node.name);
    const pad = EdgeInsets.symmetric(vertical: 16, horizontal: 20);

    final hero = AvCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
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
                      style: AvType.footnoteStrong.copyWith(
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
                    40,
                    weight: FontWeight.w700,
                  ).copyWith(color: c.l1),
                ),
                Text(
                  s.connected
                      ? '${s.mode}模式 · ${direct ? 'DIRECT' : node.name}'
                      : 'sing-box 1.14.2 已就绪',
                  style: AvType.footnote.copyWith(color: c.l2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox.square(
            dimension: 76,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                if (s.connected) const _SingleRing(size: 76),
                AvPressable(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    s.set(() => s.connected = !s.connected);
                  },
                  scale: 0.88,
                  scaleDuration: const Duration(milliseconds: 500),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 450),
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: s.connected ? c.tint : c.fill,
                      shape: BoxShape.circle,
                      boxShadow: s.connected ? AvShadows.glow(c) : null,
                    ),
                    alignment: Alignment.center,
                    child: AvIcon(
                      Symbols.power_settings_new_rounded,
                      size: 36,
                      color: s.connected ? const Color(0xFFFFFFFF) : c.l2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
              const Expanded(
                child: _Label(Symbols.speed_rounded, '网络速度', AvHues.blue),
              ),
              Text(
                '↑ ${s.connected ? fmtSpeed(s.up) : '0 KB/s'} ↓ ${s.connected ? fmtSpeed(s.hist.last) : '0 KB/s'}',
                style: AvType.s(
                  15,
                  weight: FontWeight.w600,
                  tabular: true,
                ).copyWith(color: c.l1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 84,
            child: AvSpeedChart(
              samples: s.hist,
              active: s.connected,
              strokeWidth: 2,
            ),
          ),
        ],
      ),
    );

    final nodeCard = AvCard(
      radius: 16,
      padding: pad,
      onTap: () => DesktopShellState.of(context).go(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Label(Symbols.location_on_rounded, '当前节点', AvHues.orange),
          const SizedBox(height: 8),
          Text(
            direct ? 'DIRECT' : node.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AvType.s(20, weight: FontWeight.w600).copyWith(color: c.l1),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  direct ? '直连模式' : node.proto,
                  style: AvType.footnote.copyWith(color: c.l2),
                ),
              ),
              if (!direct)
                Text(
                  lat.text,
                  style: AvType.footnoteStrong.copyWith(color: lat.color),
                ),
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
          const _Label(Symbols.language_rounded, '出口 IP', AvHues.teal),
          const SizedBox(height: 8),
          Text(
            s.connected && !direct ? '中国香港' : '中国上海',
            style: AvType.s(20, weight: FontWeight.w600).copyWith(color: c.l1),
          ),
          Text(
            s.connected && !direct ? '203.0.113.24' : '198.51.100.7',
            style: AvType.s(13, tabular: true).copyWith(color: c.l2),
          ),
        ],
      ),
    );

    Widget toggle(String label, String key) => Row(
      children: [
        Expanded(
          child: Text(label, style: AvType.s(14).copyWith(color: c.l1)),
        ),
        AvSwitch(
          value: s.toggles[key]!,
          onChanged: (v) => s.set(() => s.toggles[key] = v),
        ),
      ],
    );
    final toggles = AvCard(
      radius: 16,
      padding: pad,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          toggle('虚拟网卡 TUN', 'tun'),
          const SizedBox(height: 12),
          toggle('系统代理', 'sys'),
        ],
      ),
    );

    final traffic = AvCard(
      radius: 16,
      padding: pad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Label(Symbols.data_usage_rounded, '今日流量', AvHues.pink),
          const SizedBox(height: 8),
          Text(
            '↑ ${fmtBytes(s.totU)}\n↓ ${fmtBytes(s.totD)}',
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

    return AvDesktopPage(
      child: AvGrid(
        columns: 4,
        gap: 14,
        rows: [
          [(2, hero), (2, speed)],
          [(1, nodeCard), (1, ipCard), (1, toggles), (1, traffic)],
        ],
      ),
    );
  }
}

/// Desktop power button has a single pulse ring.
class _SingleRing extends StatefulWidget {
  const _SingleRing({required this.size});

  final double size;

  @override
  State<_SingleRing> createState() => _SingleRingState();
}

class _SingleRingState extends State<_SingleRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: AvMotion.pulsePeriod,
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tint = context.av.tint;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = AvMotion.pulse.transform(_c.value);
        return Transform.scale(
          scale: 1 + 0.7 * t,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: tint.withValues(alpha: 0.45 * (1 - t)),
            ),
          ),
        );
      },
    );
  }
}

// ───────────────────────────── 代理 ─────────────────────────────

class DesktopProxies extends StatelessWidget {
  const DesktopProxies({super.key});

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

    return AvDesktopPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < groups.length; i++)
                AvPressable(
                  onTap: () => s.set(() => s.group = i),
                  scale: 0.94,
                  scaleDuration: const Duration(milliseconds: 300),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: i == s.group ? c.tint : c.cell,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    // Center(widthFactor: 1) keeps the chip as wide as its label.
                    child: Center(
                      widthFactor: 1,
                      child: Text(
                        groups[i].name,
                        style: AvType.footnoteStrong.copyWith(
                          color: i == s.group ? const Color(0xFFFFFFFF) : c.l1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (s.mode == '直连') ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: c.cell,
                borderRadius: BorderRadius.circular(10),
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
            const SizedBox(height: 14),
          ],
          Text(
            '${g.type} · ${g.members.length} 个节点 · 当前 ${all[selected].name}',
            style: AvType.footnote.copyWith(color: c.l2),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, box) {
              final w = (box.maxWidth - 12 * 3) / 4;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final i in g.members)
                    SizedBox(
                      width: w,
                      child: Builder(
                        builder: (context) {
                          final n = all[i];
                          final l = latencyOf(context, s, n.name);
                          final on = i == selected;
                          return AvCard(
                            radius: 12,
                            padding: const EdgeInsets.symmetric(
                              vertical: 14,
                              horizontal: 16,
                            ),
                            selected: on,
                            pressScale: 0.96,
                            onTap: () => s.set(() => s.sel[s.group] = i),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(right: 24),
                                      child: Text(
                                        n.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AvType.calloutStrong.copyWith(
                                          color: c.l1,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            n.proto,
                                            style: AvType.footnote.copyWith(
                                              color: c.l2,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          l.text,
                                          style: AvType.s(
                                            13,
                                            weight: FontWeight.w600,
                                            tabular: true,
                                          ).copyWith(color: l.color),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Positioned(
                                  top: -2,
                                  right: -4,
                                  child: AvPopIcon(
                                    Symbols.check_circle_rounded,
                                    visible: on,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── 配置 ─────────────────────────────

class DesktopProfiles extends StatelessWidget {
  const DesktopProfiles({super.key});

  @override
  Widget build(BuildContext context) {
    final s = GalleryScope.of(context);
    final c = context.av;
    return AvDesktopPage(
      child: LayoutBuilder(
        builder: (context, box) {
          final w = (box.maxWidth - 14) / 2;
          return Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              for (final p in s.profiles)
                SizedBox(
                  width: w,
                  child: _DesktopProfileCard(p: p),
                ),
              SizedBox(
                width: w,
                child: AvPressable(
                  onTap: () => DesktopShellState.of(context).openAdd(),
                  scale: 0.98,
                  child: CustomPaint(
                    painter: AvDashedBorder(color: c.l3, radius: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AvIcon(
                            Symbols.add_circle_rounded,
                            size: 22,
                            color: c.tint,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '添加订阅、独立节点或代理链',
                            style: AvType.subheadStrong.copyWith(color: c.tint),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DesktopProfileCard extends StatelessWidget {
  const _DesktopProfileCard({required this.p});

  final DemoProfile p;

  @override
  Widget build(BuildContext context) {
    final s = GalleryScope.of(context);
    final c = context.av;
    final on = s.active == p.id;
    final src = p.local
        ? '本地 · ${s.custom.where((n) => n.chain).length} 条代理链'
        : p.src;
    final nodes = p.local ? s.custom.where((n) => !n.chain).length : p.nodes;
    final pct = p.used == null ? 0.0 : p.used! / p.total!;
    return AvCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      selected: on,
      pressScale: 0.98,
      onTap: () => s.set(() => s.active = p.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AvIcon(
                on
                    ? Symbols.check_circle_rounded
                    : Symbols.radio_button_unchecked_rounded,
                size: 24,
                color: on ? c.tint : c.l3,
                fill: on ? 1 : 0,
                weight: on ? 500 : 300,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.name,
                      style: AvType.s(
                        16,
                        weight: FontWeight.w600,
                      ).copyWith(color: c.l1),
                    ),
                    Text(
                      '$src · $nodes 个节点 · ${p.updated}更新',
                      style: AvType.footnote.copyWith(color: c.l2),
                    ),
                  ],
                ),
              ),
              AvPressable(
                onTap: () => s.set(() => p.updated = '刚刚'),
                pressedOpacity: 0.5,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: c.fill,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: AvIcon(
                    Symbols.refresh_rounded,
                    size: 17,
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
