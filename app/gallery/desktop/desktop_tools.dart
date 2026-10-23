// DEVELOPMENT ONLY: V3 desktop tools (master list + content). V3 draws no
// desktop content for 分应用代理, login or subscription; those follow the
// product spec using the same components (see docs/UI_DESIGN_SYSTEM.md).
import 'package:av_design/av_design.dart';
import 'package:flutter/cupertino.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../gallery_state.dart';
import '../pages_more.dart';
import 'desktop_shell.dart';

const _toolRows = <(String? key, String label, IconData? icon, Color? hue)>[
  (null, '查看', null, null),
  ('conns', '连接', Symbols.lan_rounded, AvHues.green),
  ('logs', '日志', Symbols.article_rounded, AvHues.gray),
  (null, '设置', null, null),
  ('basic', '基础设置', Symbols.settings_rounded, AvHues.gray),
  ('network', '高级设置', Symbols.tune_rounded, AvHues.blue),
  ('apps', '分应用代理', Symbols.apps_rounded, AvHues.indigo),
  ('geo', 'GEO 规则集', Symbols.travel_explore_rounded, AvHues.teal),
  ('tailscale', 'Tailscale', Symbols.hub_rounded, AvHues.graphite),
  (null, '同步', null, null),
  ('cloud', 'Avalon Cloud', Symbols.cloud_sync_rounded, AvHues.cyan),
  (null, '其他', null, null),
  ('about', '关于', Symbols.info_rounded, AvHues.gray),
];

class DesktopTools extends StatelessWidget {
  const DesktopTools({super.key, required this.tool, required this.onSelect});

  final String tool;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final s = GalleryScope.of(context);
    final c = context.av;
    String sub(String key) => switch (key) {
      'conns' => '${s.connected ? s.conns.length : 0}',
      'network' => 'TUN · DNS',
      'apps' => s.appMode,
      'geo' => s.geoBusy.isNotEmpty ? '更新中…' : s.geo.first.when,
      'tailscale' => s.tsOn ? '已连接' : '关闭',
      'cloud' => switch (s.account) {
        'loggedOut' => '未登录',
        'free' => '免费',
        _ => '已同步',
      },
      _ => '',
    };

    final content = switch (tool) {
      'conns' => const _Conns(),
      'logs' => const _Logs(),
      'network' => const _Network(),
      'apps' => const _Apps(),
      'geo' => const _Geo(),
      'tailscale' => const _Tailscale(),
      'cloud' => const _Cloud(),
      'about' => const _About(),
      _ => const _Basic(),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          // V3 `width:250px;padding:6px 12px 16px` plus the border is
          // content-box: 274.5 overall.
          width: 274 + AvBorder.hairline,
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: c.sep, width: 0.5)),
          ),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
            children: [
              for (final r in _toolRows)
                if (r.$1 == null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
                    child: Text(
                      r.$2,
                      style: AvType.s(
                        12,
                        weight: FontWeight.w600,
                      ).copyWith(color: c.l2),
                    ),
                  )
                else
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onSelect(r.$1!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: tool == r.$1
                            ? c.tintBg
                            : c.tintBg.withValues(alpha: 0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          AvIconTile(
                            r.$3!,
                            r.$4!,
                            size: 24,
                            radius: 6,
                            iconSize: 15,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              r.$2,
                              style: AvType.s(
                                14,
                              ).copyWith(color: tool == r.$1 ? c.tint : c.l1),
                            ),
                          ),
                          Text(
                            sub(r.$1!),
                            style: AvType.footnote.copyWith(color: c.l2),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
        Expanded(
          child: AvFadeSwap(
            token: tool,
            duration: const Duration(milliseconds: 300),
            child: content,
          ),
        ),
      ],
    );
  }
}

/// Two-column settings layout (`max-width:900px; gap:16px`); the first
/// header of each column sits at the top (V3 `margin-top:-22px`).
class _TwoColumns extends StatelessWidget {
  const _TwoColumns({required this.left, required this.right, this.bottom});

  final List<Widget> left;
  final List<Widget> right;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    Widget column(List<Widget> children) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
    return AvDesktopPage(
      maxWidth: 900,
      child: LayoutBuilder(
        builder: (context, box) => column([
          // V3 draws only the 1280 window; narrower panes stack the columns.
          if (box.maxWidth < 620)
            column([...left, ...right])
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: column(left)),
                const SizedBox(width: 16),
                Expanded(child: column(right)),
              ],
            ),
          ?bottom,
        ]),
      ),
    );
  }
}

class _SegRow extends StatelessWidget {
  const _SegRow({
    required this.title,
    required this.values,
    required this.selected,
    required this.onChanged,
    required this.width,
  });

  final String title;
  final List<String> values;
  final String selected;
  final ValueChanged<String> onChanged;
  final double width;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    final last = AvRowPosition.isLast(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: c.sep, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: AvType.s(14).copyWith(color: c.l1)),
          ),
          AvSegmented<String>(
            values: values,
            labelOf: (v) => v,
            selected: selected,
            onChanged: onChanged,
            width: width,
          ),
        ],
      ),
    );
  }
}

AvRow _sw(GalleryState s, String key, String title, {String? subtitle}) =>
    AvRow(
      title: title,
      subtitle: subtitle,
      trailing: AvSwitch(
        value: s.toggles[key]!,
        onChanged: (v) => s.set(() => s.toggles[key] = v),
      ),
    );

Widget _link(BuildContext context, String title, String action) => AvRow(
  title: title,
  onTap: () {},
  trailing: Text(
    action,
    style: AvType.footnoteStrong.copyWith(color: context.av.tint),
  ),
);

// ───────────────────────────── 连接 ─────────────────────────────

class _Conns extends StatelessWidget {
  const _Conns();

  static const _flex = [20, 10, 16, 16, 8, 8];

  @override
  Widget build(BuildContext context) {
    final s = GalleryScope.of(context);
    final c = context.av;
    final conns = s.connected ? s.conns : const <DemoConn>[];
    final direct = s.mode == '直连';
    Widget cells(
      List<Widget> items, {
      double height = 36,
      Color? bg,
      Border? border,
    }) => Container(
      // Content-box like V3: a bottom hairline adds to the height.
      height: height + (border == null ? 0 : AvBorder.hairline),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: bg, border: border),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            i < _flex.length
                ? Expanded(flex: _flex[i], child: items[i])
                : SizedBox(width: 30, child: items[i]),
          ],
        ],
      ),
    );
    Text t(String v, {Color? color, bool right = false, FontWeight? w}) => Text(
      v,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: right ? TextAlign.right : TextAlign.left,
      style: AvType.s(
        13,
        weight: w ?? FontWeight.w400,
        tabular: right,
      ).copyWith(color: color ?? c.l1),
    );
    final head = AvType.s(11, weight: FontWeight.w600).copyWith(color: c.l2);

    return AvDesktopPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${conns.length} 个活动连接',
                  style: AvType.footnote.copyWith(color: c.l2),
                ),
              ),
              AvPressable(
                onTap: () => s.set(() => s.conns = []),
                pressedOpacity: 0.5,
                child: Text(
                  '全部关闭',
                  style: AvType.footnoteStrong.copyWith(color: c.bad),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ColoredBox(
              color: c.cell,
              child: Column(
                children: [
                  cells(
                    height: 30,
                    border: Border(
                      bottom: BorderSide(color: c.sep, width: 0.5),
                    ),
                    [
                      Text('主机', style: head),
                      Text('进程', style: head),
                      Text('规则', style: head),
                      Text('链路', style: head),
                      Text('上传', style: head, textAlign: TextAlign.right),
                      Text('下载', style: head, textAlign: TextAlign.right),
                      const SizedBox(),
                    ],
                  ),
                  if (conns.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 40,
                        horizontal: 20,
                      ),
                      child: Text(
                        s.connected ? '所有连接已关闭' : '启动代理后，这里会实时显示连接',
                        style: AvType.s(14).copyWith(color: c.l2),
                      ),
                    ),
                  for (var j = 0; j < conns.length; j++)
                    AvDropIn(
                      key: ValueKey(conns[j].host),
                      duration: const Duration(milliseconds: 300),
                      child: cells(bg: j.isOdd ? c.fill : null, [
                        t(conns[j].host, w: FontWeight.w500),
                        t(conns[j].app),
                        t(conns[j].rule, color: c.l2),
                        t(direct ? 'DIRECT' : conns[j].chain, color: c.tint),
                        t(conns[j].up, right: true),
                        t(conns[j].down, right: true),
                        AvPressable(
                          onTap: () => s.set(
                            () => s.conns = [...s.conns]..remove(conns[j]),
                          ),
                          pressedOpacity: 0.5,
                          child: Center(
                            child: AvIcon(
                              Symbols.cancel_rounded,
                              size: 18,
                              color: c.l3,
                            ),
                          ),
                        ),
                      ]),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── 日志 ─────────────────────────────

class _Logs extends StatelessWidget {
  const _Logs();

  @override
  Widget build(BuildContext context) {
    final s = GalleryScope.of(context);
    final c = context.av;
    final colors = {
      'ERROR': c.bad,
      'WARN': c.warn,
      'INFO': c.tint,
      'DEBUG': c.l2,
    };
    final logs = demoLogs
        .where((l) => s.logLevel == '全部' || l[1] == s.logLevel)
        .toList();
    return AvDesktopPage(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AvSegmented<String>(
            values: const ['全部', 'INFO', 'WARN', 'ERROR', 'DEBUG'],
            labelOf: (v) => v,
            selected: s.logLevel,
            width: 424,
            height: 32,
            onChanged: (v) => s.set(() => s.logLevel = v),
          ),
          const SizedBox(height: 14),
          AvGroup(
            children: [
              for (final l in logs)
                Builder(
                  builder: (context) {
                    final last = AvRowPosition.isLast(context);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        border: last
                            ? null
                            : Border(
                                bottom: BorderSide(color: c.sep, width: 0.5),
                              ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 70,
                            child: Text(
                              l[0],
                              style: AvType.s(
                                12,
                                tabular: true,
                              ).copyWith(color: c.l2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            width: 56,
                            child: Text(
                              l[1],
                              style: AvType.s(
                                12,
                                weight: FontWeight.w700,
                              ).copyWith(color: colors[l[1]]),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              AvType.breakAll(l[2]),
                              style: AvType.mono(12).copyWith(color: c.l1),
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
      ),
    );
  }
}

// ───────────────────────────── 基础设置 ─────────────────────────────

class _Basic extends StatelessWidget {
  const _Basic();

  @override
  Widget build(BuildContext context) {
    final s = GalleryScope.of(context);
    final c = context.av;
    final spec = AvDesktopSpec.of(galleryDesktopPlatform());
    return _TwoColumns(
      left: [
        const AvSectionHeader('通用', top: 0),
        AvGroup(
          children: [
            const AvRow(title: '语言', value: '简体中文'),
            _SegRow(
              title: '外观',
              values: const ['浅色', '深色'],
              selected: s.dark ? '深色' : '浅色',
              width: 140,
              onChanged: (v) => s.set(() => s.dark = v == '深色'),
            ),
          ],
        ),
        const AvSectionHeader('启动'),
        AvGroup(
          children: [
            _sw(s, 'autostart', '开机自动启动', subtitle: '登录系统后自动运行 Avalon'),
            _sw(
              s,
              'silentStart',
              '静默启动',
              subtitle: '启动时不显示主窗口，只在${spec.trayName}显示图标',
            ),
            _sw(s, 'autoConnect', '启动后自动连接'),
            _sw(s, 'tray', '关闭窗口时保留在${spec.trayName}'),
          ],
        ),
        const AvSectionHeader('代理'),
        AvGroup(
          children: [
            _sw(s, 'sys', '系统代理', subtitle: spec.sysNote),
            _sw(s, 'lan', '允许局域网连接'),
            const AvRow(title: '混合端口', value: '7890'),
          ],
        ),
        const AvSectionHeader('快捷键'),
        AvGroup(
          children: [
            AvRow(title: '启动 / 停止代理', value: spec.hotkeys[0]),
            AvRow(title: '切换出站模式', value: spec.hotkeys[1]),
            AvRow(title: '显示主窗口', value: spec.hotkeys[2]),
          ],
        ),
      ],
      right: [
        const AvSectionHeader('延迟测试', top: 0),
        const AvGroup(
          children: [
            AvRow(title: '测速地址', value: 'https://www.gstatic.com/generate_204'),
            AvRow(title: '超时', value: '5000 ms'),
          ],
        ),
        const AvSectionHeader('数据'),
        AvGroup(
          children: [
            AvRow(title: '导出备份…', titleColor: c.tint, onTap: () {}),
            AvRow(title: '从文件恢复…', titleColor: c.tint, onTap: () {}),
          ],
        ),
        const AvSectionFooter('备份包含订阅、自建节点、代理链和全部设置。'),
      ],
    );
  }
}

// ───────────────────────────── 高级设置 ─────────────────────────────

class _Network extends StatelessWidget {
  const _Network();

  @override
  Widget build(BuildContext context) {
    final s = GalleryScope.of(context);
    final c = context.av;
    final spec = AvDesktopSpec.of(galleryDesktopPlatform());
    return _TwoColumns(
      bottom: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: AvGroup(
          children: [AvRow(title: '恢复默认设置', titleColor: c.bad, onTap: () {})],
        ),
      ),
      left: [
        const AvSectionHeader('虚拟网卡 TUN', top: 0),
        AvGroup(
          children: [
            _sw(s, 'tun', '启用 TUN', subtitle: spec.tunNote),
            _SegRow(
              title: '协议栈',
              values: const ['gVisor', 'System', 'Mixed'],
              selected: s.stack,
              width: 210,
              onChanged: (v) => s.set(() => s.stack = v),
            ),
            const AvRow(title: 'MTU', value: '9000'),
            _sw(s, 'autoRoute', '自动路由', subtitle: 'auto_route'),
            _sw(s, 'strictRoute', '严格路由', subtitle: 'strict_route · 防止流量泄漏'),
          ],
        ),
        const AvSectionHeader('DNS'),
        AvGroup(
          children: [
            const AvRow(title: '远程 DNS', value: 'https://1.1.1.1/dns-query'),
            const AvRow(title: '直连 DNS', value: '223.5.5.5'),
            _sw(s, 'fakeip', 'FakeIP', subtitle: '198.18.0.0/15'),
            _SegRow(
              title: '解析策略',
              values: const ['优先 IPv4', '仅 IPv4', '优先 IPv6'],
              selected: s.dnsStrat,
              width: 240,
              onChanged: (v) => s.set(() => s.dnsStrat = v),
            ),
          ],
        ),
      ],
      right: [
        const AvSectionHeader('路由', top: 0),
        AvGroup(
          children: [
            _sw(s, 'sniff', '流量嗅探', subtitle: '识别 TLS / HTTP / QUIC 域名'),
            _sw(
              s,
              'sniffOverride',
              '用嗅探结果覆盖目标',
              subtitle: 'sniff_override_destination',
            ),
            _sw(s, 'bypassLan', '绕过局域网与保留地址'),
            _sw(s, 'ipv6', 'IPv6'),
            _sw(s, 'findProc', '查找进程', subtitle: '用于分应用代理和连接页显示程序'),
          ],
        ),
        const AvSectionHeader('Clash API'),
        AvGroup(
          children: [
            _sw(s, 'clashApi', '外部控制器', subtitle: '供 Web 面板或第三方客户端控制'),
            const AvRow(title: '监听地址', value: '127.0.0.1:9090'),
            const AvRow(title: '密钥', value: '••••••••'),
            _link(context, 'Web 面板', '打开 metacubexd'),
          ],
        ),
        const AvSectionHeader('内核'),
        AvGroup(
          children: [
            _SegRow(
              title: '日志等级',
              values: const ['debug', 'info', 'warn', 'error'],
              selected: s.coreLog,
              width: 240,
              onChanged: (v) => s.set(() => s.coreLog = v),
            ),
            _link(context, '配置覆写', '编辑 JSON…'),
            _link(context, '生成的配置', '查看…'),
          ],
        ),
      ],
    );
  }
}

// ───────────────────────────── 分应用（V3 未绘桌面版） ─────────────────────────────

const _desktopApps = {
  AvDesktopPlatform.mac: [
    ('Safari', '/Applications/Safari.app', 0xFF007AFF),
    ('Google Chrome', '/Applications/Google Chrome.app', 0xFFEA4335),
    ('Telegram', '/Applications/Telegram.app', 0xFF2AABEE),
    ('Visual Studio Code', '/Applications/Visual Studio Code.app', 0xFF0078D4),
    ('Slack', '/Applications/Slack.app', 0xFF4A154B),
    ('Spotify', '/Applications/Spotify.app', 0xFF1DB954),
    ('微信', '/Applications/WeChat.app', 0xFF07C160),
  ],
  AvDesktopPlatform.windows: [
    ('chrome.exe', r'C:\Program Files\Google\Chrome\Application', 0xFFEA4335),
    (
      'msedge.exe',
      r'C:\Program Files (x86)\Microsoft\Edge\Application',
      0xFF0078D4,
    ),
    ('Telegram.exe', r'%APPDATA%\Telegram Desktop', 0xFF2AABEE),
    ('Code.exe', r'%LOCALAPPDATA%\Programs\Microsoft VS Code', 0xFF0078D4),
    ('steam.exe', r'C:\Program Files (x86)\Steam', 0xFF1B2838),
    ('WeChat.exe', r'C:\Program Files\Tencent\WeChat', 0xFF07C160),
  ],
  AvDesktopPlatform.linux: [
    ('firefox', '/usr/lib/firefox/firefox', 0xFFFF7139),
    ('chrome', '/opt/google/chrome/chrome', 0xFFEA4335),
    ('telegram-desktop', '/usr/bin/telegram-desktop', 0xFF2AABEE),
    ('code', '/usr/share/code/code', 0xFF0078D4),
    ('steam', '/usr/bin/steam', 0xFF1B2838),
    ('git', '/usr/bin/git', 0xFFF05032),
  ],
};

class _Apps extends StatefulWidget {
  const _Apps();

  @override
  State<_Apps> createState() => _AppsState();
}

class _AppsState extends State<_Apps> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final s = GalleryScope.of(context);
    final c = context.av;
    final list = _desktopApps[galleryDesktopPlatform()]!
        .where(
          (a) => _q.isEmpty || a.$1.toLowerCase().contains(_q.toLowerCase()),
        )
        .toList();
    final any = _desktopApps[galleryDesktopPlatform()]!.any(
      (a) => s.apps[a.$1] ?? false,
    );
    return AvDesktopPage(
      maxWidth: 640,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AvSearchField(
                  icon: AvIcon(Symbols.search_rounded, size: 18, color: c.l2),
                  onChanged: (v) => setState(() => _q = v),
                ),
              ),
              const SizedBox(width: 12),
              AvSegmented<String>(
                values: const ['白名单', '黑名单'],
                labelOf: (v) => v,
                selected: s.appMode,
                width: 160,
                onChanged: (v) => s.set(() => s.appMode = v),
              ),
            ],
          ),
          AvSectionFooter(
            !any
                ? '未选择应用时，全部应用按规则代理。'
                : (s.appMode == '白名单' ? '仅开启的程序走代理，其余直连。' : '开启的程序直连，其余走代理。'),
          ),
          const SizedBox(height: 10),
          AvGroup(
            children: [
              for (final a in list)
                AvRow(
                  leading: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Color(a.$3),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      a.$1.characters.first.toUpperCase(),
                      style: AvType.s(
                        13,
                        weight: FontWeight.w600,
                      ).copyWith(color: const Color(0xFFFFFFFF)),
                    ),
                  ),
                  title: a.$1,
                  subtitle: a.$2,
                  trailing: AvSwitch(
                    value: s.apps[a.$1] ?? false,
                    onChanged: (v) => s.set(() => s.apps[a.$1] = v),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── GEO ─────────────────────────────

class _Geo extends StatelessWidget {
  const _Geo();

  static const _cols = [
    (28.0, 0),
    (0.0, 16),
    (90.0, 0),
    (80.0, 0),
    (0.0, 10),
    (32.0, 0),
  ];

  @override
  Widget build(BuildContext context) {
    final s = GalleryScope.of(context);
    final c = context.av;
    final busy = s.geoBusy.isNotEmpty;
    Widget cells(List<Widget> items, {double height = 42, Border? border}) =>
        Container(
          // V3 `height:42px;border-bottom:…` is content-box.
          height: height + (border == null ? 0 : AvBorder.hairline),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(border: border),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                _cols[i].$1 > 0
                    ? SizedBox(width: _cols[i].$1, child: items[i])
                    : Expanded(flex: _cols[i].$2, child: items[i]),
              ],
            ],
          ),
        );
    final head = AvType.s(11, weight: FontWeight.w600).copyWith(color: c.l2);
    return AvDesktopPage(
      maxWidth: 760,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${s.geo.length} 个规则集 · ${s.toggles['geoAuto']! ? '${s.geoInt}自动更新' : '自动更新已关闭'}',
                  style: AvType.footnote.copyWith(color: c.l2),
                ),
              ),
              AvDesktopButton(
                label: busy ? '更新中' : '全部更新',
                icon: busy
                    ? Symbols.progress_activity_rounded
                    : Symbols.refresh_rounded,
                spin: busy,
                filled: true,
                radius: 7,
                onTap: () => s.updateGeo(s.geo.map((g) => g.name)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ColoredBox(
              color: c.cell,
              child: Column(
                children: [
                  cells(
                    height: 30,
                    border: Border(
                      bottom: BorderSide(color: c.sep, width: 0.5),
                    ),
                    [
                      const SizedBox(),
                      Text('名称', style: head),
                      Text('类型', style: head),
                      Text('大小', style: head, textAlign: TextAlign.right),
                      Text('更新时间', style: head, textAlign: TextAlign.right),
                      const SizedBox(),
                    ],
                  ),
                  for (var j = 0; j < s.geo.length; j++)
                    Builder(
                      builder: (context) {
                        final g = s.geo[j];
                        final b = s.geoBusy.contains(g.name);
                        final ip = g.type == 'GeoIP';
                        return cells(
                          border: j == s.geo.length - 1
                              ? null
                              : Border(
                                  bottom: BorderSide(color: c.sep, width: 0.5),
                                ),
                          [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: AvIconTile(
                                ip
                                    ? Symbols.lan_rounded
                                    : Symbols.language_rounded,
                                ip ? AvHues.orange : AvHues.teal,
                                size: 22,
                                radius: 6,
                                iconSize: 14,
                              ),
                            ),
                            Text(
                              g.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AvType.mono(13).copyWith(color: c.l1),
                            ),
                            Text(
                              g.type,
                              style: AvType.footnote.copyWith(color: c.l2),
                            ),
                            Text(
                              g.size,
                              textAlign: TextAlign.right,
                              style: AvType.s(
                                13,
                                tabular: true,
                              ).copyWith(color: c.l2),
                            ),
                            Text(
                              b ? '下载中…' : g.when,
                              textAlign: TextAlign.right,
                              style: AvType.footnote.copyWith(
                                color: b
                                    ? c.tint
                                    : (g.when == '刚刚' ? c.ok : c.l2),
                              ),
                            ),
                            AvHover(
                              hover: c.fill,
                              radius: 13,
                              builder: (_) => AvPressable(
                                onTap: b ? null : () => s.updateGeo([g.name]),
                                pressedOpacity: 0.5,
                                child: SizedBox.square(
                                  dimension: 26,
                                  child: Center(
                                    child: b
                                        ? AvSpin(
                                            child: AvIcon(
                                              Symbols.progress_activity_rounded,
                                              size: 17,
                                              color: c.tint,
                                            ),
                                          )
                                        : AvIcon(
                                            Symbols.refresh_rounded,
                                            size: 17,
                                            color: c.tint,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          const AvSectionHeader('更新设置'),
          AvGroup(
            children: [
              AvRow(
                title: '自动更新',
                minHeight: 44,
                trailing: AvSwitch(
                  value: s.toggles['geoAuto']!,
                  onChanged: (v) => s.set(() => s.toggles['geoAuto'] = v),
                ),
              ),
              _SegRow(
                title: '更新间隔',
                values: const ['每天', '每周'],
                selected: s.geoInt,
                width: 150,
                onChanged: (v) => s.set(() => s.geoInt = v),
              ),
              _SegRow(
                title: '下载方式',
                values: const ['经代理', '直连'],
                selected: s.geoVia,
                width: 150,
                onChanged: (v) => s.set(() => s.geoVia = v),
              ),
            ],
          ),
          const AvSectionFooter(
            'sing-box 使用 .srs 规则集代替旧的 geoip.db / geosite.db。默认从 SagerNet/sing-geosite 和 sing-geoip 下载，订阅里引用的规则集也会显示在这里。',
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── Tailscale ─────────────────────────────

class _Tailscale extends StatelessWidget {
  const _Tailscale();

  @override
  Widget build(BuildContext context) {
    final s = GalleryScope.of(context);
    final c = context.av;
    final host = switch (galleryDesktopPlatform()) {
      AvDesktopPlatform.mac => ('avalon-mac', '100.92.10.6'),
      AvDesktopPlatform.windows => ('avalon-win', '100.92.10.7'),
      AvDesktopPlatform.linux => ('avalon-linux', '100.92.10.8'),
    };
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
    final value14 = AvType.s(14).copyWith(color: c.l2);
    return AvDesktopPage(
      maxWidth: 680,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: c.cell,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const AvIconTile(
                  Symbols.hub_rounded,
                  AvHues.graphite,
                  size: 44,
                  radius: 10,
                  iconSize: 26,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tailscale',
                        style: AvType.s(
                          16,
                          weight: FontWeight.w600,
                        ).copyWith(color: c.l1),
                      ),
                      Text(
                        s.tsOn ? '已连接 · lin-wei.github' : '未启用',
                        style: AvType.footnote.copyWith(
                          color: s.tsOn ? c.ok : c.l2,
                        ),
                      ),
                    ],
                  ),
                ),
                AvSwitch(
                  value: s.tsOn,
                  onChanged: (v) => s.set(() => s.tsOn = v),
                ),
              ],
            ),
          ),
          const AvSectionFooter('基于 sing-box 内置的 Tailscale endpoint，与代理同时运行。'),
          if (s.tsOn) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AvSectionHeader('本机'),
                      AvGroup(
                        children: [
                          AvRow(
                            title: '主机名',
                            value: host.$1,
                            valueStyle: value14,
                          ),
                          AvRow(
                            title: 'Tailscale IP',
                            value: host.$2,
                            valueStyle: value14,
                          ),
                          AvRow(
                            title: 'Tailnet',
                            value: 'lin-wei.github',
                            valueStyle: value14,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const AvSectionHeader('出口节点'),
                      AvGroup(
                        children: [
                          for (final e in exits)
                            Opacity(
                              opacity: e.online ? 1 : 0.4,
                              child: AvRow(
                                title: e.label,
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  14,
                                  0,
                                ),
                                onTap: e.online
                                    ? () => s.set(() => s.tsExit = e.name)
                                    : null,
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      e.sub,
                                      style: AvType.caption.copyWith(
                                        color: c.l2,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    AvPopIcon(
                                      Symbols.check_rounded,
                                      visible: s.tsExit == e.name,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const AvSectionHeader('选项'),
            AvGroup(
              children: [
                AvRow(
                  title: '接受子网路由',
                  subtitle: '访问 tailnet 中其他设备公布的局域网',
                  minHeight: 44,
                  trailing: AvSwitch(
                    value: s.tsRoutes,
                    onChanged: (v) => s.set(() => s.tsRoutes = v),
                  ),
                ),
                AvRow(
                  title: 'MagicDNS',
                  subtitle: '用设备名访问，如 home-nas',
                  minHeight: 44,
                  trailing: AvSwitch(
                    value: s.tsDns,
                    onChanged: (v) => s.set(() => s.tsDns = v),
                  ),
                ),
                AvRow(
                  title: '作为出口节点',
                  subtitle: '允许 tailnet 中的设备经本机上网',
                  minHeight: 44,
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
                    minHeight: 44,
                    titleWidget: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: p.online ? c.ok : c.l3,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            p.name,
                            style: AvType.s(14).copyWith(color: c.l1),
                          ),
                        ),
                        SizedBox(
                          width: 90,
                          child: Text(
                            p.os,
                            style: AvType.footnote.copyWith(color: c.l2),
                          ),
                        ),
                        SizedBox(
                          width: 60,
                          child: Text(
                            p.online ? '在线' : '离线',
                            style: AvType.footnote.copyWith(color: c.l2),
                          ),
                        ),
                        SizedBox(
                          width: 110,
                          child: Text(
                            p.ip,
                            textAlign: TextAlign.right,
                            style: AvType.s(
                              13,
                              tabular: true,
                            ).copyWith(color: c.l2),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const AvSectionFooter(
              '访问 100.64.0.0/10 和 *.ts.net 的流量固定走 Tailscale，不受出站模式影响。出口节点会出现在代理页的「自定义」组，可作为代理链中的一跳。',
            ),
            const SizedBox(height: 20),
            AvGroup(
              children: [
                AvRow(
                  title: '退出 Tailscale 账户',
                  titleColor: c.bad,
                  onTap: () {},
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ───────────────────────────── Avalon Cloud ─────────────────────────────

IconData _deviceIcon(String name) => switch (name) {
  'laptop_mac' => Symbols.laptop_mac_rounded,
  'desktop_windows' => Symbols.desktop_windows_rounded,
  'phone_android' => Symbols.phone_android_rounded,
  _ => Symbols.smartphone_rounded,
};

/// Opens a mobile Cloud page (login / subscription) as a desktop dialog.
void openCloudDialog(BuildContext context, Widget page) {
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: const Color(0x4D000000),
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, _, _) => Center(
        child: AvZoomIn(
          duration: const Duration(milliseconds: 400),
          child: Container(
            width: 420,
            height: 640,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: context.av.bg,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Color(0x33000000), spreadRadius: 0.5),
                BoxShadow(
                  color: Color(0x59000000),
                  offset: Offset(0, 24),
                  blurRadius: 60,
                ),
              ],
            ),
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: AvDensity(mode: AvDensityMode.touch, child: page),
            ),
          ),
        ),
      ),
    ),
  );
}

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

class _Cloud extends StatelessWidget {
  const _Cloud();

  @override
  Widget build(BuildContext context) {
    final s = GalleryScope.of(context);
    final c = context.av;
    final paid = s.account == 'paid';
    if (s.account == 'loggedOut') {
      return AvDesktopPage(
        maxWidth: 640,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: c.cell,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              AvIcon(Symbols.cloud_sync_rounded, size: 40, color: c.tint),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '登录 Avalon Cloud',
                      style: AvType.s(
                        16,
                        weight: FontWeight.w600,
                      ).copyWith(color: c.l1),
                    ),
                    Text(
                      '同步订阅、自建节点与代理链。',
                      style: AvType.footnote.copyWith(color: c.l2),
                    ),
                  ],
                ),
              ),
              AvDesktopButton(
                label: '登录',
                filled: true,
                height: 32,
                onTap: () => openCloudDialog(context, const LoginPage()),
              ),
            ],
          ),
        ),
      );
    }
    return AvDesktopPage(
      maxWidth: 640,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.cell,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: c.tint,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'L',
                    style: AvType.s(
                      20,
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
                        '林伟',
                        style: AvType.s(
                          16,
                          weight: FontWeight.w600,
                        ).copyWith(color: c.l1),
                      ),
                      Text(
                        'lin.wei@outlook.com · ${paid ? '年付，2027-08-14 到期' : '免费账户'}',
                        style: AvType.footnote.copyWith(color: c.l2),
                      ),
                    ],
                  ),
                ),
                if (paid)
                  AvDesktopButton(
                    label: s.syncing ? '同步中…' : s.lastSync,
                    icon: Symbols.sync_rounded,
                    spin: s.syncing,
                    tinted: true,
                    height: 32,
                    onTap: s.syncNow,
                  ),
              ],
            ),
          ),
          if (paid) ...[
            const AvSectionHeader('自动同步的内容'),
            AvGroup(
              children: [
                for (final l in const ['订阅', '自建节点与代理链', '规则与覆写', '节点选择记录'])
                  AvRow(
                    title: l,
                    trailing: AvIcon(
                      Symbols.check_circle_rounded,
                      size: 18,
                      color: c.ok,
                    ),
                  ),
              ],
            ),
            const AvSectionFooter('数据通过安全连接传输，并在云端加密存储。'),
          ] else
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.cell,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    AvIcon(Symbols.cloud_off_rounded, size: 28, color: c.l2),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '免费账户 · 不同步',
                            style: AvType.subheadStrong.copyWith(color: c.l1),
                          ),
                          Text(
                            '所有配置仅保存在本机。升级后自动同步到你的其他设备。',
                            style: AvType.caption.copyWith(color: c.l2),
                          ),
                        ],
                      ),
                    ),
                    AvDesktopButton(
                      label: '升级到 Cloud',
                      filled: true,
                      radius: 7,
                      onTap: () => openCloudDialog(context, const ProPage()),
                    ),
                  ],
                ),
              ),
            ),
          AvSectionHeader('设备 · ${paid ? s.devices.length : 0} / 10'),
          AvGroup(
            children: [
              for (final d in s.devices)
                AvRow(
                  leading: AvIcon(
                    _deviceIcon(d.icon),
                    size: 22,
                    fill: 0,
                    weight: 400,
                    color: c.l2,
                  ),
                  minHeight: 48,
                  title: d.name,
                  subtitle: d.os,
                  // D14: right-click to remove another device.
                  onSecondaryTap: d.me
                      ? null
                      : () async {
                          if (await _confirm(
                            context,
                            '移除「${d.name}」？',
                            '该设备会退出登录并释放同步名额，设备上的本地数据保留。',
                            '移除',
                          )) {
                            s.set(() => s.devices.remove(d));
                          }
                        },
                  trailing: Text(
                    paid || d.me ? d.last : '未同步',
                    style: AvType.footnote.copyWith(
                      color: d.me ? c.tint : c.l2,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              AvPressable(
                onTap: () => s.set(() => s.account = 'loggedOut'),
                pressedOpacity: 0.5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '退出登录',
                    style: AvType.footnoteStrong.copyWith(color: c.bad),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // D16: two-step account deletion.
              AvPressable(
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
                  if (second) s.set(() => s.account = 'loggedOut');
                },
                pressedOpacity: 0.5,
                child: Text(
                  '删除账号',
                  style: AvType.footnote.copyWith(color: c.l2),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────── 关于 ─────────────────────────────

class _About extends StatelessWidget {
  const _About();

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    final spec = AvDesktopSpec.of(galleryDesktopPlatform());
    final value14 = AvType.s(14).copyWith(color: c.l2);
    return AvDesktopPage(
      maxWidth: 640,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 20),
            child: Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: c.tint,
                    borderRadius: BorderRadius.circular(17),
                    boxShadow: AvShadows.glow(c, y: 10),
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
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Avalon', style: AvType.title2.copyWith(color: c.l1)),
                    Text(
                      '版本 0.1.0 (1) · ${spec.osName}',
                      style: AvType.footnote.copyWith(color: c.l2),
                    ),
                  ],
                ),
              ],
            ),
          ),
          AvGroup(
            children: [
              AvRow(
                title: '内核',
                value: 'sing-box 1.14.2',
                valueStyle: value14,
                minHeight: 44,
              ),
              AvRow(
                title: '许可证',
                value: 'AGPL-3.0',
                valueStyle: value14,
                minHeight: 44,
              ),
              AvRow(
                title: '检查更新',
                value: '已是最新',
                valueStyle: value14,
                minHeight: 44,
              ),
            ],
          ),
          const SizedBox(height: 20),
          AvGroup(
            children: [
              AvRow(
                title: 'GitHub 源代码',
                titleColor: c.tint,
                minHeight: 44,
                onTap: () {},
                trailing: AvIcon(
                  Symbols.open_in_new_rounded,
                  size: 16,
                  color: c.l3,
                ),
              ),
            ],
          ),
          const AvSectionFooter('致谢 sing-box 与开源社区'),
        ],
      ),
    );
  }
}
