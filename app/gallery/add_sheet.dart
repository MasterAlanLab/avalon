// DEVELOPMENT ONLY: V3 replica of the add sheet (3d subscription, 3e node,
// 3f chain).
import 'package:av_design/av_design.dart';
import 'package:flutter/cupertino.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'gallery_state.dart';
import 'pages_main.dart' show latencyOf;

/// Presents the add form as an iOS page sheet: the screen behind scales back
/// with rounded corners over black, the sheet slides up and can be dragged
/// down to dismiss (V3 `ios-sheet .55s`).
Future<void> showAddSheet(BuildContext context, int segment) {
  final state = GalleryScope.of(context);
  final colors = context.av;
  return Navigator.of(context, rootNavigator: true).push(
    AvSheetRoute<void>(
      scrollableBuilder: (_, controller) => GalleryScope(
        state: state,
        child: AvTheme(
          colors: colors,
          child: _AddSheet(initial: segment, controller: controller),
        ),
      ),
    ),
  );
}

class _AddSheet extends StatefulWidget {
  const _AddSheet({required this.initial, required this.controller});

  final int initial;
  final ScrollController controller;

  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  late int _seg = widget.initial;

  @override
  Widget build(BuildContext context) {
    final s = GalleryScope.of(context);
    final c = context.av;
    final canSave = _seg != 2 || s.hops.length >= 2;
    return ColoredBox(
      color: c.bg,
      child: DefaultTextStyle.merge(
        style: AvType.body.copyWith(color: c.l1),
        child: Column(
          children: [
            SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: AvTextAction(
                          '取消',
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                    Text('添加', style: AvType.bodyStrong.copyWith(color: c.l1)),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: AvTextAction(
                          '保存',
                          strong: true,
                          enabled: canSave,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: AvSegmented<int>(
                values: const [0, 1, 2],
                labelOf: (v) => const ['订阅', '独立节点', '代理链'][v],
                selected: _seg,
                onChanged: (v) => setState(() => _seg = v),
              ),
            ),
            Expanded(
              child: AvFadeSwap(
                token: _seg,
                duration: AvMotion.swap,
                child: ListView(
                  controller: widget.controller,
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: EdgeInsets.fromLTRB(
                    0,
                    8,
                    0,
                    40 + MediaQuery.paddingOf(context).bottom,
                  ),
                  children: switch (_seg) {
                    0 => const [_SubscriptionForm()],
                    1 => const [_NodeForm()],
                    _ => const [_ChainForm()],
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────── 3d 订阅 ─────────────────────────────

class _SubscriptionForm extends StatefulWidget {
  const _SubscriptionForm();

  @override
  State<_SubscriptionForm> createState() => _SubscriptionFormState();
}

class _SubscriptionFormState extends State<_SubscriptionForm> {
  String _method = '链接';

  @override
  Widget build(BuildContext context) {
    final s = GalleryScope.of(context);
    final c = context.av;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AvGroup(
          children: [
            Builder(
              builder: (context) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 11,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: c.sep, width: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '订阅链接',
                        style: AvType.footnote.copyWith(color: c.l2),
                      ),
                      const SizedBox(height: 4),
                      // V3 `<textarea style="min-height:64px">` is
                      // inline-block, so it also sits on the 17 px line's
                      // baseline: the strut's descent (4) adds below it.
                      ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 68),
                        child: AvInput(
                          placeholder: 'https://… 支持 sing-box / Clash 订阅',
                          maxLines: null,
                          textAlignVertical: TextAlignVertical.top,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const AvFieldRow(label: '名称', placeholder: '自动读取', inputSize: 17),
          ],
        ),
        const SizedBox(height: 24),
        AvGroup(
          children: [
            _MethodRow(
              icon: Symbols.qr_code_scanner_rounded,
              label: '扫描二维码',
              on: _method == '扫码',
              onTap: () =>
                  setState(() => _method = _method == '扫码' ? '链接' : '扫码'),
            ),
            _MethodRow(
              icon: Symbols.folder_open_rounded,
              label: '从文件导入',
              on: _method == '文件',
              onTap: () =>
                  setState(() => _method = _method == '文件' ? '链接' : '文件'),
            ),
          ],
        ),
        if (_method == '扫码')
          AvDropIn(
            key: const ValueKey('scan'),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 1.2,
                  child: ColoredBox(
                    color: const Color(0xFF111111),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        FractionallySizedBox(
                          widthFactor: 0.52,
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: const Color(0xE6FFFFFF),
                                  width: 3,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x66000000),
                                    spreadRadius: 999,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 16,
                          child: Text(
                            '将订阅二维码放入框内',
                            textAlign: TextAlign.center,
                            style: AvType.s(
                              14,
                            ).copyWith(color: const Color(0xFFFFFFFF)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (_method == '文件')
          AvDropIn(
            key: const ValueKey('file'),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: CustomPaint(
                painter: _DashedRRect(color: c.l3, radius: 16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 16,
                  ),
                  child: Column(
                    children: [
                      AvIcon(
                        Symbols.description_rounded,
                        size: 36,
                        color: c.tint,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '选择 .json 或 .yaml',
                        style: AvType.calloutStrong.copyWith(color: c.l1),
                      ),
                      Text(
                        'sing-box 配置或 Clash 配置',
                        style: AvType.footnote.copyWith(color: c.l2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 24),
        AvGroup(
          children: [
            AvRow(
              title: '自动更新',
              trailing: AvSwitch(
                value: s.toggles['addAuto']!,
                onChanged: (v) => s.set(() => s.toggles['addAuto'] = v),
              ),
            ),
          ],
        ),
        const AvSectionFooter('每 12 小时自动更新。已登录 Avalon Cloud，保存后自动同步到你的其他设备。'),
      ],
    );
  }
}

class _MethodRow extends StatelessWidget {
  const _MethodRow({
    required this.icon,
    required this.label,
    required this.on,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    return AvRow(
      leading: AvIcon(icon, size: 22, color: c.tint),
      title: label,
      titleColor: c.tint,
      onTap: onTap,
      trailing: AnimatedOpacity(
        opacity: on ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: AvIcon(Symbols.check_rounded, size: 20, color: c.tint),
      ),
    );
  }
}

class _DashedRRect extends CustomPainter {
  _DashedRRect({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final m in path.computeMetrics()) {
      for (double d = 0; d < m.length; d += 9) {
        canvas.drawPath(m.extractPath(d, d + 5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRect old) => old.color != color;
}

// ───────────────────────────── 3e 独立节点 ─────────────────────────────

const _protocols = [
  AvMenuItem('Hysteria2', 'Hysteria2', subtitle: 'QUIC'),
  AvMenuItem('TUIC', 'TUIC', subtitle: 'QUIC v5'),
  AvMenuItem('VLESS', 'VLESS', subtitle: 'Reality / TLS'),
  AvMenuItem('VMess', 'VMess', subtitle: 'TCP / WS'),
  AvMenuItem('Trojan', 'Trojan', subtitle: 'TLS'),
  AvMenuItem('Shadowsocks', 'Shadowsocks', subtitle: 'AEAD / 2022'),
  AvMenuItem('SOCKS5', 'SOCKS5', subtitle: 'SOCKS'),
  AvMenuItem('AnyTLS', 'AnyTLS', subtitle: 'TLS'),
  AvMenuItem('HTTP', 'HTTP', subtitle: 'HTTP / HTTPS'),
];

/// (label, placeholder, monospace) per protocol, from V3 `PF`.
const _fields = <String, List<(String, String, bool)>>{
  'VLESS': [
    ('地址', 'example.com', false),
    ('端口', '443', false),
    ('UUID', '必填', true),
    ('Flow', 'xtls-rprx-vision', true),
  ],
  'VMess': [
    ('地址', 'example.com', false),
    ('端口', '443', false),
    ('UUID', '必填', true),
    ('Alter ID', '0', false),
  ],
  'Trojan': [
    ('地址', 'example.com', false),
    ('端口', '443', false),
    ('密码', '必填', true),
  ],
  'Shadowsocks': [
    ('地址', 'example.com', false),
    ('端口', '8388', false),
    ('加密', '2022-blake3-aes-128-gcm', true),
    ('密码', '必填', true),
  ],
  'Hysteria2': [
    ('地址', 'example.com', false),
    ('端口', '443', false),
    ('密码', '必填', true),
    ('混淆密码', '可选', true),
    ('上行 Mbps', '50', false),
    ('下行 Mbps', '200', false),
  ],
  'TUIC': [
    ('地址', 'example.com', false),
    ('端口', '443', false),
    ('UUID', '必填', true),
    ('密码', '必填', true),
    ('拥塞控制', 'bbr', false),
  ],
  'AnyTLS': [
    ('地址', 'example.com', false),
    ('端口', '443', false),
    ('密码', '必填', true),
    ('空闲会话检查', '30s', false),
  ],
  'SOCKS5': [
    ('地址', '127.0.0.1', false),
    ('端口', '1080', false),
    ('用户名', '可选', false),
    ('密码', '可选', true),
  ],
  'HTTP': [
    ('地址', 'example.com', false),
    ('端口', '8080', false),
    ('用户名', '可选', false),
    ('密码', '可选', true),
  ],
};

const _securityOptions = {
  'VLESS': ['无', 'TLS', 'Reality'],
  'VMess': ['无', 'TLS'],
  'HTTP': ['无', 'TLS'],
  'SOCKS5': ['无', 'TLS'],
};

class _NodeForm extends StatelessWidget {
  const _NodeForm();

  @override
  Widget build(BuildContext context) {
    final s = GalleryScope.of(context);
    final c = context.av;
    final p = s.nodeProto;
    final hasTransport = const ['VLESS', 'VMess', 'Trojan'].contains(p);
    final secOpts = _securityOptions[p];
    final sec = secOpts == null
        ? null
        : (secOpts.contains(s.security) ? s.security : secOpts[1]);

    final extra = <(String, String, bool)>[
      if (hasTransport && s.transport == 'WebSocket') ...[
        ('路径', '/ws', true),
        ('Host', '可选', true),
      ],
      if (hasTransport && s.transport == 'gRPC') ('Service', 'grpc', true),
      if (hasTransport && s.transport == 'HTTP/2') ('路径', '/', true),
      if (sec == 'TLS' ||
          const ['Trojan', 'Hysteria2', 'TUIC', 'AnyTLS'].contains(p))
        ('SNI', 'example.com', true),
      if (sec == 'Reality') ...[
        ('SNI', 'www.apple.com', true),
        ('公钥', 'Public Key', true),
        ('Short ID', '可选', true),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
            decoration: BoxDecoration(
              color: c.cell,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                AvIcon(Symbols.content_paste_rounded, size: 20, color: c.l2),
                const SizedBox(width: 10),
                Expanded(
                  child: AvInput(
                    placeholder: '粘贴 vless:// vmess:// hy2:// …',
                    style: AvType.input,
                  ),
                ),
                const SizedBox(width: 10),
                AvPillButton(
                  label: '解析',
                  tinted: true,
                  height: 32,
                  pressScale: 0.92,
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AvPullDownMenu<String>(
            items: _protocols,
            selected: p,
            onSelected: (v) => s.set(() => s.nodeProto = v),
            builder: (context, toggle) => ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ColoredBox(
                color: c.cell,
                child: AvPressable(
                  highlight: true,
                  onTap: toggle,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    padding: const EdgeInsets.fromLTRB(16, 0, 10, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '协议',
                            style: AvType.body.copyWith(color: c.l1),
                          ),
                        ),
                        Text(p, style: AvType.body.copyWith(color: c.l2)),
                        const SizedBox(width: 6),
                        AvIcon(
                          Symbols.unfold_more_rounded,
                          size: 20,
                          color: c.l2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const AvSectionHeader('服务器'),
        AvGroup(
          children: [
            const AvFieldRow(label: '名称', placeholder: '东京 VPS', inputSize: 17),
            for (final f in _fields[p]!)
              AvFieldRow(
                label: f.$1,
                placeholder: f.$2,
                mono: f.$3,
                // V3 shares `nf.port = '443'` across protocols.
                initialValue: f.$1 == '端口' ? '443' : null,
              ),
          ],
        ),
        if (hasTransport) ...[
          const AvSectionHeader('传输方式'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AvSegmented<String>(
              values: const ['TCP', 'WebSocket', 'gRPC', 'HTTP/2'],
              labelOf: (v) => v,
              selected: s.transport,
              onChanged: (v) => s.set(() => s.transport = v),
            ),
          ),
        ],
        if (secOpts != null) ...[
          const AvSectionHeader('传输层安全', top: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AvSegmented<String>(
              values: secOpts,
              labelOf: (v) => v,
              selected: sec!,
              onChanged: (v) => s.set(() => s.security = v),
            ),
          ),
        ],
        if (extra.isNotEmpty)
          AvDropIn(
            key: ValueKey('extra-$p-${s.transport}-$sec'),
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: AvGroup(
                children: [
                  for (final f in extra)
                    AvFieldRow(label: f.$1, placeholder: f.$2, mono: f.$3),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        const AvSectionFooter('保存到「自建节点」。已登录 Avalon Cloud，保存后自动同步到你的其他设备。'),
      ],
    );
  }
}

// ───────────────────────────── 3f 代理链 ─────────────────────────────

class _ChainForm extends StatelessWidget {
  const _ChainForm();

  @override
  Widget build(BuildContext context) {
    final s = GalleryScope.of(context);
    final c = context.av;
    final all = s.allNodes;
    final hl = s.hops.length;
    final lats = s.hops.map((h) => s.lat[h]).toList();
    final total = lats.any((v) => v == 0)
        ? null
        : lats.fold<int>(0, (a, b) => a + (b ?? 0));
    final summary =
        '$hl 跳 · ${total == null ? '超时' : (total > 0 ? '≈ $total ms' : '—')}';
    final picks = all
        .where((n) => !n.chain && !s.hops.contains(n.name))
        .toList();

    String role(int j) =>
        hl == 1 ? '出口' : (j == 0 ? '入口' : (j == hl - 1 ? '出口' : '中转'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AvGroup(
          children: [
            AvFieldRow(label: '名称', placeholder: '默认用节点名拼接', inputSize: 17),
          ],
        ),
        AvSectionHeader('链路', trailing: summary),
        AvGroup(
          children: [
            AvRow(
              leading: const AvIconTile(
                Symbols.smartphone_rounded,
                AvHues.gray,
              ),
              title: '本机',
              titleColor: c.l2,
            ),
            for (var j = 0; j < hl; j++)
              Builder(
                builder: (context) {
                  final name = s.hops[j];
                  final node = all.firstWhere(
                    (n) => n.name == name,
                    orElse: () => DemoNode(name, ''),
                  );
                  final l = latencyOf(context, s, name);
                  return AvDropIn(
                    key: ValueKey('hop-$name'),
                    child: _HopRow(
                      index: j,
                      name: name,
                      meta: '${role(j)} · ${node.proto} · ',
                      latency: l,
                      canUp: j > 0,
                      canDown: j < hl - 1,
                      onRemove: () => s.set(() => s.hops.removeAt(j)),
                      onMove: (d) => s.set(() {
                        final t = j + d;
                        final tmp = s.hops[j];
                        s.hops[j] = s.hops[t];
                        s.hops[t] = tmp;
                      }),
                    ),
                  );
                },
              ),
            AvRow(
              leading: AvIcon(
                Symbols.add_circle_rounded,
                size: 24,
                color: c.ok,
              ),
              leadingGap: 10,
              title: '添加一跳',
              titleColor: c.tint,
              onTap: () => s.set(() => s.picker = !s.picker),
            ),
            if (s.picker)
              AvDropIn(
                duration: const Duration(milliseconds: 300),
                child: ColoredBox(
                  color: c.bg,
                  child: Column(
                    children: [
                      for (final n in picks)
                        AvPressable(
                          highlight: true,
                          onTap: () => s.set(() => s.hops.add(n.name)),
                          child: Container(
                            constraints: const BoxConstraints(
                              minHeight: 40 + AvBorder.hairline,
                            ),
                            padding: const EdgeInsets.fromLTRB(50, 0, 16, 0),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: c.sep, width: 0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    n.name,
                                    style: AvType.callout.copyWith(color: c.l1),
                                  ),
                                ),
                                Text(
                                  n.proto,
                                  style: AvType.footnote.copyWith(color: c.l2),
                                ),
                                const SizedBox(width: 12),
                                AvIcon(
                                  Symbols.add_rounded,
                                  size: 20,
                                  color: c.tint,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            AvRow(
              leading: const AvIconTile(Symbols.public_rounded, AvHues.teal),
              title: '目标网站',
              titleColor: c.l2,
            ),
          ],
        ),
        const AvSectionFooter(
          '流量依次经过每一跳，最后一跳为出口。由 sing-box 的 detour 串联，可混用不同协议。',
        ),
        const AvSectionHeader('加入代理组'),
        AvGroup(
          children: [
            for (final g in const ['节点选择', '流媒体', 'AI 服务', '漏网之鱼'])
              AvRow(
                insetSeparator: true,
                title: g,
                onTap: () => s.set(
                  () => s.chainGroups.contains(g)
                      ? s.chainGroups.remove(g)
                      : s.chainGroups.add(g),
                ),
                trailing: AvPopIcon(
                  Symbols.check_rounded,
                  visible: s.chainGroups.contains(g),
                ),
              ),
          ],
        ),
        if (hl < 2) AvSectionFooter('代理链至少需要 2 跳', color: c.bad),
      ],
    );
  }
}

class _HopRow extends StatelessWidget {
  const _HopRow({
    required this.index,
    required this.name,
    required this.meta,
    required this.latency,
    required this.canUp,
    required this.canDown,
    required this.onRemove,
    required this.onMove,
  });

  final int index;
  final String name;
  final String meta;
  final ({String text, Color color}) latency;
  final bool canUp;
  final bool canDown;
  final VoidCallback onRemove;
  final ValueChanged<int> onMove;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    Widget arrow(IconData icon, bool enabled, int d) => Opacity(
      opacity: enabled ? 1 : 0.3,
      child: AvPressable(
        onTap: enabled ? () => onMove(d) : null,
        pressedOpacity: 0.5,
        child: SizedBox.square(
          dimension: 30,
          child: Center(child: AvIcon(icon, size: 22, color: c.l3)),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Row(
        children: [
          AvPressable(
            onTap: onRemove,
            scale: 0.8,
            scaleDuration: const Duration(milliseconds: 300),
            child: AvIcon(
              Symbols.do_not_disturb_on_rounded,
              size: 24,
              color: c.bad,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.sep, width: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: c.tint,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: AvType.s(
                        13,
                        weight: FontWeight.w700,
                      ).copyWith(color: const Color(0xFFFFFFFF)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AvType.body.copyWith(color: c.l1),
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: meta),
                              TextSpan(
                                text: latency.text,
                                style: TextStyle(color: latency.color),
                              ),
                            ],
                          ),
                          style: AvType.footnote.copyWith(color: c.l2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  arrow(Symbols.keyboard_arrow_up_rounded, canUp, -1),
                  arrow(Symbols.keyboard_arrow_down_rounded, canDown, 1),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
