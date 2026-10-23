// DEVELOPMENT ONLY: V3 replica of 3k apps, 3t GEO, 3s Tailscale, 3l Cloud,
// 3m subscription, 3n login and 3o about, with the approved deviations from
// docs/DECISIONS.md (D02 copy, D13 hint, D14/D16 entries, D24 credit, D65 logos).
import 'package:av_design/av_design.dart';
import 'package:flutter/cupertino.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'gallery_app.dart';
import 'gallery_state.dart';

/// Card-style header used by GEO and Tailscale (`padding:14px 16px; gap:14px`,
/// 46 px tile, radius 11).
class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.icon,
    required this.hue,
    required this.title,
    required this.subtitle,
    this.subtitleColor,
    required this.trailing,
  });

  final IconData icon;
  final Color hue;
  final String title;
  final String subtitle;
  final Color? subtitleColor;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: c.cell,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            AvIconTile(icon, hue, size: 46, radius: 11, iconSize: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AvType.bodyStrong.copyWith(color: c.l1)),
                  Text(
                    subtitle,
                    style: AvType.footnote.copyWith(
                      color: subtitleColor ?? c.l2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            trailing,
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────── 3k 分应用代理 ─────────────────────────────

class AppsPage extends StatefulWidget {
  const AppsPage({super.key});

  @override
  State<AppsPage> createState() => _AppsPageState();
}

class _AppsPageState extends State<AppsPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final s = GalleryScope.of(context);
    final c = context.av;
    final q = _query.trim().toLowerCase();
    final apps = demoApps
        .where(
          (a) =>
              q.isEmpty || a.$1.toLowerCase().contains(q) || a.$2.contains(q),
        )
        .toList();
    final anySelected = demoApps.any((a) => s.apps[a.$1] ?? false);
    final hint = !anySelected
        ? '未选择应用时，全部应用按规则代理。'
        : (s.appMode == '白名单' ? '仅开启的应用走代理，其余直连。' : '开启的应用直连，其余走代理。');

    return AvPushedPage(
      title: '分应用代理',
      backLabel: '工具',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AvSearchField(
            icon: AvIcon(Symbols.search_rounded, size: 20, color: c.l2),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: AvSegmented<String>(
            values: const ['白名单', '黑名单'],
            labelOf: (v) => v,
            selected: s.appMode,
            onChanged: (v) => s.set(() => s.appMode = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 8, 32, 6),
          child: Text(hint, style: AvType.footnote.copyWith(color: c.l2)),
        ),
        const SizedBox(height: 2),
        AvGroup(
          children: [
            for (final a in apps)
              AvRow(
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Color(a.$3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    a.$1.characters.first,
                    style: AvType.s(
                      15,
                      weight: FontWeight.w600,
                    ).copyWith(color: const Color(0xFFFFFFFF)),
                  ),
                ),
                minHeight: 52,
                titleWidget: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(a.$1, style: AvType.body.copyWith(color: c.l1)),
                    Text(
                      a.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AvType.caption.copyWith(color: c.l2),
                    ),
                  ],
                ),
                trailing: AvSwitch(
                  value: s.apps[a.$1] ?? false,
                  onChanged: (v) => s.set(() => s.apps[a.$1] = v),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ───────────────────────────── 3t GEO 规则集 ─────────────────────────────

class GeoPage extends StatelessWidget {
  const GeoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = GalleryScope.of(context);
    final c = context.av;
    final busy = s.geoBusy.isNotEmpty;
    return AvPushedPage(
      title: 'GEO 规则集',
      backLabel: '工具',
      children: [
        _HeaderCard(
          icon: Symbols.travel_explore_rounded,
          hue: AvHues.teal,
          title: 'GEO 规则集',
          subtitle:
              '${s.geo.length} 个规则集 · ${s.toggles['geoAuto']! ? '${s.geoInt}自动更新' : '自动更新已关闭'}',
          trailing: AvPillButton(
            label: busy ? '更新中' : '全部更新',
            icon: busy
                ? Symbols.progress_activity_rounded
                : Symbols.refresh_rounded,
            iconSpin: busy,
            filled: true,
            height: 32,
            pressScale: 0.92,
            onTap: () => s.updateGeo(s.geo.map((g) => g.name)),
          ),
        ),
        const AvSectionHeader('规则集'),
        AvGroup(
          children: [
            for (final g in s.geo)
              Builder(
                builder: (context) {
                  final b = s.geoBusy.contains(g.name);
                  final ip = g.type == 'GeoIP';
                  return AvRow(
                    leading: AvIconTile(
                      ip ? Symbols.lan_rounded : Symbols.language_rounded,
                      ip ? AvHues.orange : AvHues.teal,
                    ),
                    minHeight: 56,
                    padding: const EdgeInsets.only(right: 12),
                    titleWidget: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          g.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AvType.mono(16).copyWith(color: c.l1),
                        ),
                        Text(
                          b ? '下载中…' : '${g.type} · ${g.size} · ${g.when}更新',
                          style: AvType.footnote.copyWith(
                            color: b ? c.tint : (g.when == '刚刚' ? c.ok : c.l2),
                          ),
                        ),
                      ],
                    ),
                    trailing: AvCircleButton(
                      icon: b
                          ? Symbols.progress_activity_rounded
                          : Symbols.refresh_rounded,
                      spin: b,
                      size: 32,
                      iconSize: 18,
                      pressScale: 0.85,
                      onTap: b ? null : () => s.updateGeo([g.name]),
                    ),
                  );
                },
              ),
          ],
        ),
        const AvSectionHeader('更新设置'),
        AvGroup(
          children: [
            AvRow(
              title: '自动更新',
              trailing: AvSwitch(
                value: s.toggles['geoAuto']!,
                onChanged: (v) => s.set(() => s.toggles['geoAuto'] = v),
              ),
            ),
            _InlineSegmentRow(
              title: '更新间隔',
              values: const ['每天', '每周'],
              selected: s.geoInt,
              onChanged: (v) => s.set(() => s.geoInt = v),
            ),
            _InlineSegmentRow(
              title: '下载方式',
              values: const ['经代理', '直连'],
              selected: s.geoVia,
              onChanged: (v) => s.set(() => s.geoVia = v),
            ),
          ],
        ),
        const AvSectionFooter(
          'sing-box 使用 .srs 规则集代替旧的 geoip.db / geosite.db。默认从 SagerNet/sing-geosite 和 sing-geoip 下载，订阅里引用的规则集也会显示在这里。',
        ),
      ],
    );
  }
}

class _InlineSegmentRow extends StatelessWidget {
  const _InlineSegmentRow({
    required this.title,
    required this.values,
    required this.selected,
    required this.onChanged,
  });

  final String title;
  final List<String> values;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    final last = AvRowPosition.isLast(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: c.sep, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: AvType.body.copyWith(color: c.l1)),
          ),
          AvSegmented<String>(
            values: values,
            labelOf: (v) => v,
            selected: selected,
            onChanged: onChanged,
            style: AvSegmentStyle.inline,
            width: 150,
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── 3s Tailscale ─────────────────────────────

class TailscalePage extends StatelessWidget {
  const TailscalePage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = GalleryScope.of(context);
    final c = context.av;
    final exits = [
      (name: null as String?, label: '不使用', sub: '直接访问互联网', online: true),
      for (final p in demoPeers.where((p) => p.exit))
        (
          name: p.name,
          label: p.name,
          sub: p.online ? p.ip : '离线',
          online: p.online,
        ),
    ];
    return AvPushedPage(
      title: 'Tailscale',
      backLabel: '工具',
      children: [
        _HeaderCard(
          icon: Symbols.hub_rounded,
          hue: AvHues.graphite,
          title: 'Tailscale',
          subtitle: s.tsOn ? '已连接 · lin-wei.github' : '未启用',
          subtitleColor: s.tsOn ? c.ok : c.l2,
          trailing: AvSwitch(
            value: s.tsOn,
            onChanged: (v) => s.set(() => s.tsOn = v),
          ),
        ),
        const AvSectionFooter('基于 sing-box 内置的 Tailscale endpoint，与代理同时运行。'),
        if (s.tsOn) ...[
          const AvSectionHeader('本机'),
          AvGroup(
            children: [
              const AvRow(title: '主机名', value: 'avalon-iphone'),
              AvRow(
                title: 'Tailscale IP',
                trailing: Text(
                  '100.92.10.5',
                  style: AvType.s(17, tabular: true).copyWith(color: c.l2),
                ),
              ),
              const AvRow(title: 'Tailnet', value: 'lin-wei.github'),
            ],
          ),
          const AvSectionHeader('出口节点'),
          AvGroup(
            children: [
              for (final e in exits)
                Opacity(
                  opacity: e.online ? 1 : 0.4,
                  child: AvRow(
                    insetSeparator: true,
                    minHeight: 52,
                    title: e.label,
                    subtitle: e.sub,
                    onTap: e.online
                        ? () => s.set(() => s.tsExit = e.name)
                        : null,
                    trailing: AvPopIcon(
                      Symbols.check_rounded,
                      visible: s.tsExit == e.name,
                    ),
                  ),
                ),
            ],
          ),
          const AvSectionFooter(
            '选中后，出口节点会以「Tailscale · 设备名」出现在代理页的「自定义」组，可单独选用，也可作为代理链中的一跳。',
          ),
          const AvSectionHeader('选项'),
          AvGroup(
            children: [
              AvRow(
                title: '接受子网路由',
                subtitle: '访问 tailnet 中其他设备公布的局域网',
                trailing: AvSwitch(
                  value: s.tsRoutes,
                  onChanged: (v) => s.set(() => s.tsRoutes = v),
                ),
              ),
              AvRow(
                title: 'MagicDNS',
                subtitle: '用设备名访问，如 home-nas',
                trailing: AvSwitch(
                  value: s.tsDns,
                  onChanged: (v) => s.set(() => s.tsDns = v),
                ),
              ),
              AvRow(
                title: '作为出口节点',
                subtitle: '允许 tailnet 中的设备经本机上网',
                trailing: AvSwitch(
                  value: s.tsAdvertise,
                  onChanged: (v) => s.set(() => s.tsAdvertise = v),
                ),
              ),
            ],
          ),
          AvSectionHeader(
            '设备 · ${demoPeers.where((p) => p.online).length} 台在线',
          ),
          AvGroup(
            children: [
              for (final p in demoPeers)
                AvRow(
                  leading: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: p.online ? c.ok : c.l3,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  minHeight: 52,
                  title: p.name,
                  subtitle: '${p.os} · ${p.online ? '在线' : '离线'}',
                  trailing: Text(
                    p.ip,
                    style: AvType.s(15, tabular: true).copyWith(color: c.l2),
                  ),
                ),
            ],
          ),
          const AvSectionFooter(
            '访问 100.64.0.0/10 和 *.ts.net 的流量固定走 Tailscale，不受出站模式影响。',
          ),
          const SizedBox(height: 24),
          AvGroup(
            children: [
              AvRow(
                title: '退出 Tailscale 账户',
                titleColor: c.bad,
                centered: true,
                onTap: () {},
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ───────────────────────────── 3l Avalon Cloud ─────────────────────────────

IconData _deviceIcon(String name) => switch (name) {
  'laptop_mac' => Symbols.laptop_mac_rounded,
  'desktop_windows' => Symbols.desktop_windows_rounded,
  'phone_android' => Symbols.phone_android_rounded,
  _ => Symbols.smartphone_rounded,
};

Future<bool> _confirm(
  BuildContext context,
  String title,
  String message,
  String action,
) async {
  final ok = await showCupertinoDialog<bool>(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('取消'),
        ),
        CupertinoDialogAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return ok ?? false;
}

class CloudPage extends StatelessWidget {
  const CloudPage({super.key, this.backLabel = '工具'});

  final String backLabel;

  @override
  Widget build(BuildContext context) {
    final s = GalleryScope.of(context);
    final c = context.av;
    final loggedIn = s.account != 'loggedOut';
    final paid = s.account == 'paid';

    if (!loggedIn) {
      return AvPushedPage(
        title: 'Avalon Cloud',
        backLabel: backLabel,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 40, 32, 0),
            child: Column(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: c.tint,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: const AvIcon(
                    Symbols.cloud_sync_rounded,
                    size: 48,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Avalon Cloud',
                  style: AvType.title1.copyWith(color: c.l1),
                ),
                const SizedBox(height: 10),
                Text(
                  '在所有设备上同步订阅、自建节点与代理链。',
                  textAlign: TextAlign.center,
                  style: AvType.s(15, height: 1.5).copyWith(color: c.l2),
                ),
                const SizedBox(height: 26),
                AvPrimaryButton(
                  '登录',
                  onTap: () => pushPage(context, const LoginPage()),
                ),
              ],
            ),
          ),
        ],
      );
    }

    Widget syncRow(IconData icon, Color hue, String label) => AvRow(
      leading: AvIconTile(icon, hue),
      title: label,
      trailing: AvIcon(Symbols.check_circle_rounded, size: 20, color: c.ok),
    );

    return AvPushedPage(
      title: 'Avalon Cloud',
      backLabel: backLabel,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Column(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: c.tint,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  'L',
                  style: AvType.s(
                    30,
                    weight: FontWeight.w600,
                  ).copyWith(color: const Color(0xFFFFFFFF)),
                ),
              ),
              const SizedBox(height: 10),
              Text('林伟', style: AvType.title2.copyWith(color: c.l1)),
              const SizedBox(height: 2),
              Text(
                'lin.wei@outlook.com',
                style: AvType.callout.copyWith(color: c.l2),
              ),
            ],
          ),
        ),
        if (paid) ...[
          const SizedBox(height: 20),
          AvGroup(
            children: [
              AvRow(title: '上次同步', value: s.syncing ? '同步中…' : s.lastSync),
              AvRow(
                title: '立即同步',
                titleColor: c.tint,
                onTap: s.syncNow,
                trailing: s.syncing
                    ? AvSpin(
                        child: AvIcon(
                          Symbols.progress_activity_rounded,
                          size: 20,
                          color: c.l2,
                        ),
                      )
                    : null,
              ),
            ],
          ),
          const AvSectionHeader('自动同步的内容'),
          AvGroup(
            children: [
              syncRow(Symbols.link_rounded, AvHues.blue, '订阅'),
              syncRow(Symbols.dns_rounded, AvHues.green, '自建节点与代理链'),
              syncRow(Symbols.rule_rounded, AvHues.orange, '规则与覆写'),
              syncRow(Symbols.touch_app_rounded, AvHues.gray, '节点选择记录'),
            ],
          ),
          const AvSectionFooter('数据通过安全连接传输，并在云端加密存储。'),
        ],
        if (!paid)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.cell,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AvIcon(Symbols.cloud_off_rounded, size: 26, color: c.l2),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '免费账户 · 不同步',
                              style: AvType.bodyStrong.copyWith(color: c.l1),
                            ),
                            Text(
                              '所有配置仅保存在本机。升级到 Cloud 后，订阅、节点和代理链会自动同步到你的其他设备。',
                              style: AvType.s(
                                13,
                                height: 1.45,
                              ).copyWith(color: c.l2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AvPressable(
                    onTap: () => pushPage(context, const ProPage()),
                    scale: 0.97,
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: c.tint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '升级到 Cloud',
                        style: AvType.bodyStrong.copyWith(
                          color: const Color(0xFFFFFFFF),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        AvSectionHeader('设备 · ${paid ? s.devices.length : 0} / 10'),
        AvGroup(
          children: [
            for (final d in s.devices)
              Builder(
                builder: (context) {
                  final row = AvRow(
                    leading: AvIcon(
                      _deviceIcon(d.icon),
                      size: 26,
                      fill: 0,
                      weight: 400,
                      color: c.l2,
                    ),
                    minHeight: 52,
                    title: d.name,
                    subtitle: d.os,
                    trailing: Text(
                      paid ? d.last : (d.me ? d.last : '未同步'),
                      style: AvType.callout.copyWith(
                        color: d.me ? c.tint : c.l2,
                      ),
                    ),
                  );
                  if (d.me) return row;
                  // D14: remove another device by swiping left.
                  return Dismissible(
                    key: ValueKey(d.name),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      color: c.bad,
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: Text(
                        '移除',
                        style: AvType.bodyStrong.copyWith(
                          color: const Color(0xFFFFFFFF),
                        ),
                      ),
                    ),
                    confirmDismiss: (_) => _confirm(
                      context,
                      '移除「${d.name}」？',
                      '该设备会退出登录并释放同步名额，设备上的本地数据保留。',
                      '移除',
                    ),
                    onDismissed: (_) => s.set(() => s.devices.remove(d)),
                    child: row,
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 24),
        AvGroup(
          children: [
            AvRow(
              title: '订阅方案',
              value: paid ? '年付' : '免费',
              chevron: true,
              onTap: () => pushPage(context, const ProPage()),
            ),
            AvRow(
              title: '退出登录',
              titleColor: c.bad,
              centered: true,
              onTap: () => s.set(() => s.account = 'loggedOut'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // D16: account deletion, confirmed twice.
        AvGroup(
          children: [
            AvRow(
              title: '删除账号',
              titleColor: c.bad,
              centered: true,
              onTap: () async {
                final first = await _confirm(
                  context,
                  '删除 Avalon 账号？',
                  '云端同步数据与账号将被永久删除，本机内容保留。',
                  '继续',
                );
                if (!first || !context.mounted) return;
                final second = await _confirm(
                  context,
                  '确认删除账号',
                  '此操作不可撤销。请另行到购买渠道取消订阅。',
                  '删除账号',
                );
                if (!second) return;
                s.set(() => s.account = 'loggedOut');
              },
            ),
          ],
        ),
      ],
    );
  }
}

// ───────────────────────────── 3m 订阅 Cloud ─────────────────────────────

class ProPage extends StatelessWidget {
  const ProPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = GalleryScope.of(context);
    final c = context.av;
    Widget feature(IconData icon, String title, String sub) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AvIcon(icon, size: 28, color: c.tint),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AvType.calloutStrong.copyWith(color: c.l1)),
              Text(sub, style: AvType.footnote.copyWith(color: c.l2)),
            ],
          ),
        ),
      ],
    );
    Widget plan(
      String key,
      String name,
      String price,
      String per,
      String note,
    ) {
      final on = s.plan == key;
      return Expanded(
        child: AvCard(
          radius: 16,
          padding: const EdgeInsets.all(14),
          selected: on,
          pressScale: 0.96,
          onTap: () => s.set(() => s.plan = key),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AvType.calloutStrong.copyWith(color: c.l1)),
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: price,
                          style: AvType.numeric(
                            26,
                            weight: FontWeight.w700,
                          ).copyWith(color: c.l1),
                        ),
                        TextSpan(
                          text: per,
                          style: AvType.s(
                            13,
                            weight: FontWeight.w500,
                          ).copyWith(color: c.l2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(note, style: AvType.caption.copyWith(color: c.l2)),
                ],
              ),
              Positioned(
                top: -2,
                right: -2,
                child: AvPopIcon(Symbols.check_circle_rounded, visible: on),
              ),
            ],
          ),
        ),
      );
    }

    return AvPushedPage(
      title: '订阅',
      backLabel: 'Avalon Cloud',
      topPadding: 4,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: c.tint,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AvShadows.glow(c, y: 10),
                ),
                alignment: Alignment.center,
                child: const AvIcon(
                  Symbols.cloud_sync_rounded,
                  size: 48,
                  color: Color(0xFFFFFFFF),
                ),
              ),
              const SizedBox(height: 14),
              Text('Avalon Cloud', style: AvType.title1.copyWith(color: c.l1)),
              const SizedBox(height: 4),
              Text(
                '在每台设备上保持同步。',
                style: AvType.s(15, height: 1.45).copyWith(color: c.l2),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 22, 24, 0),
          child: Column(
            children: [
              feature(
                Symbols.devices_rounded,
                '最多 10 台设备',
                'iPhone、Android、Mac、Windows、Linux',
              ),
              const SizedBox(height: 14),
              feature(Symbols.sync_alt_rounded, '订阅、节点与代理链', '一处修改，处处生效'),
              const SizedBox(height: 14),
              feature(Symbols.lock_rounded, '安全云同步', '加密传输与存储'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          child: Row(
            children: [
              plan('month', '月付', '¥8', ' /月', '随时取消'),
              const SizedBox(width: 12),
              plan('year', '年付', '¥68', ' /年', '约 ¥5.7/月 · 省 29%'),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: AvPrimaryButton(
            s.plan == 'year' ? '订阅 · ¥68/年' : '订阅 · ¥8/月',
            onTap: () => s.set(() => s.account = 'paid'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 12, 32, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final l in const ['恢复购买', '条款', '隐私']) ...[
                if (l != '恢复购买') const SizedBox(width: 16),
                AvPressable(
                  onTap: () {},
                  pressedOpacity: 0.4,
                  child: Text(
                    l,
                    style: AvType.footnote.copyWith(color: c.tint),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────── 3n 登录 ─────────────────────────────

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = GalleryScope.of(context);
    final c = context.av;
    void done() {
      s.set(() => s.account = 'paid');
      Navigator.of(context).maybePop();
    }

    return AvPushedPage(
      title: '登录',
      backLabel: 'Avalon Cloud',
      topPadding: 16,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: c.tint,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'A',
                        style: AvType.s(
                          36,
                          weight: FontWeight.w700,
                        ).copyWith(color: const Color(0xFFFFFFFF)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '登录 Avalon',
                      style: AvType.title1.copyWith(color: c.l1),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '登录后即可在设备间同步',
                      style: AvType.callout.copyWith(color: c.l2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AvPrimaryButton(
                '通过 Apple 登录',
                background: c.l1,
                foreground: c.bg,
                leading: AvBrandMark.apple(size: 19, color: c.bg),
                onTap: done,
              ),
              const SizedBox(height: 12),
              AvPrimaryButton(
                '通过 Google 登录',
                background: c.cell,
                foreground: c.l1,
                leading: const AvBrandMark.google(size: 19),
                onTap: done,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: Container(height: 0.5, color: c.sep)),
                  const SizedBox(width: 12),
                  Text('或使用邮箱', style: AvType.footnote.copyWith(color: c.l2)),
                  const SizedBox(width: 12),
                  Expanded(child: Container(height: 0.5, color: c.sep)),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                constraints: const BoxConstraints(minHeight: 50),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: c.cell,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const AvInput(
                  placeholder: '邮箱地址',
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              const SizedBox(height: 12),
              AvPrimaryButton('发送验证码', onTap: done),
              const SizedBox(height: 12),
              Center(
                child: AvPressable(
                  onTap: () => Navigator.of(context).maybePop(),
                  pressedOpacity: 0.4,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      '稍后',
                      style: AvType.callout.copyWith(color: c.tint),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────── 3o 关于 ─────────────────────────────

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    // Only the source-code link carries the external-link glyph in V3.
    AvRow link(String label, {bool external = false}) => AvRow(
      title: label,
      titleColor: c.tint,
      onTap: () {},
      padding: const EdgeInsets.fromLTRB(16, 0, 12, 0),
      trailing: external
          ? AvIcon(Symbols.open_in_new_rounded, size: 18, color: c.l3)
          : null,
    );
    return AvPushedPage(
      title: '关于',
      backLabel: '工具',
      topPadding: 12,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: c.tint,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: AvShadows.glow(c, y: 10),
                ),
                alignment: Alignment.center,
                child: Text(
                  'A',
                  style: AvType.s(
                    48,
                    weight: FontWeight.w700,
                  ).copyWith(color: const Color(0xFFFFFFFF)),
                ),
              ),
              const SizedBox(height: 14),
              Text('Avalon', style: AvType.title2.copyWith(color: c.l1)),
              const SizedBox(height: 4),
              Text(
                '版本 0.1.0 (1)',
                style: AvType.footnote.copyWith(color: c.l2),
              ),
            ],
          ),
        ),
        const AvGroup(
          children: [
            AvRow(title: '内核', value: 'sing-box 1.14.2'),
            AvRow(title: '许可证', value: 'AGPL-3.0'),
            AvRow(title: '检查更新', value: '已是最新'),
          ],
        ),
        const SizedBox(height: 24),
        AvGroup(
          children: [
            link('GitHub 源代码', external: true),
            link('更新日志'),
            link('隐私政策'),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
          child: Text(
            '致谢 sing-box 与开源社区',
            textAlign: TextAlign.center,
            style: AvType.footnote.copyWith(color: c.l2),
          ),
        ),
      ],
    );
  }
}
