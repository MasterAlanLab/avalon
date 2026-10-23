// DEVELOPMENT ONLY: V3 desktop add dialog (580×680, ios-zoom .4s).
import 'package:av_design/av_design.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../gallery_state.dart';
import '../pages_main.dart' show latencyOf;
import 'desktop_shell.dart';

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

const _security = {
  'VLESS': ['无', 'TLS', 'Reality'],
  'VMess': ['无', 'TLS'],
  'HTTP': ['无', 'TLS'],
  'SOCKS5': ['无', 'TLS'],
};

class DesktopAddDialog extends StatefulWidget {
  const DesktopAddDialog({
    super.key,
    required this.initial,
    required this.spec,
  });

  final int initial;
  final AvDesktopSpec spec;

  @override
  State<DesktopAddDialog> createState() => _DesktopAddDialogState();
}

class _DesktopAddDialogState extends State<DesktopAddDialog>
    with SingleTickerProviderStateMixin {
  late int _seg = widget.initial;
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  )..forward();

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = GalleryScope.of(context);
    final c = context.av;
    final shell = DesktopShellState.of(context);
    final canSave = _seg != 2 || s.hops.length >= 2;
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: shell.closeAdd,
              child: FadeTransition(
                opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),
                child: const ColoredBox(color: Color(0x4D000000)),
              ),
            ),
          ),
          Center(
            child: AvZoomIn(
              duration: const Duration(milliseconds: 400),
              child: LayoutBuilder(
                builder: (context, _) {
                  final size = MediaQuery.sizeOf(context);
                  return Container(
                    width: 580,
                    height: (size.height - 80).clamp(400, 680).toDouble(),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: c.bg,
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
                    child: Column(
                      children: [
                        SizedBox(
                          height: 52,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: AvPressable(
                                      onTap: shell.closeAdd,
                                      pressedOpacity: 0.4,
                                      child: Text(
                                        '取消',
                                        style: AvType.s(
                                          14,
                                        ).copyWith(color: c.tint),
                                      ),
                                    ),
                                  ),
                                ),
                                Text(
                                  '添加配置',
                                  style: AvType.s(
                                    14,
                                    weight: FontWeight.w700,
                                  ).copyWith(color: c.l1),
                                ),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Opacity(
                                      opacity: canSave ? 1 : 0.4,
                                      child: AvDesktopButton(
                                        label: '保存',
                                        filled: true,
                                        height: 28,
                                        radius: 7,
                                        onTap: canSave
                                            ? () => shell.closeAdd(
                                                toProxies: _seg != 0,
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                          child: AvSegmented<int>(
                            values: const [0, 1, 2],
                            labelOf: (v) => const ['订阅', '独立节点', '代理链'][v],
                            selected: _seg,
                            height: 34,
                            fontSize: 13,
                            onChanged: (v) => setState(() => _seg = v),
                          ),
                        ),
                        Expanded(
                          child: AvFadeSwap(
                            token: _seg,
                            duration: AvMotion.swap,
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                              children: [
                                switch (_seg) {
                                  0 => const _Subscription(),
                                  1 => const _Node(),
                                  _ => const _Chain(),
                                },
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _label(BuildContext context, String text, {String? trailing}) => Padding(
  padding: const EdgeInsets.fromLTRB(4, 18, 4, 6),
  child: Row(
    children: [
      Expanded(
        child: Text(text, style: AvType.caption.copyWith(color: context.av.l2)),
      ),
      if (trailing != null)
        Text(
          trailing,
          style: AvType.s(12, tabular: true).copyWith(color: context.av.l2),
        ),
    ],
  ),
);

class _Subscription extends StatelessWidget {
  const _Subscription();

  @override
  Widget build(BuildContext context) {
    final s = GalleryScope.of(context);
    final c = context.av;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AvGroup(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.sep, width: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('订阅链接', style: AvType.caption.copyWith(color: c.l2)),
                  const SizedBox(height: 4),
                  // V3 `min-height:60px` inline-block textarea plus the
                  // line's descent below it (3), as on mobile.
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 63),
                    child: AvInput(
                      placeholder: 'https://… 支持 sing-box / Clash 订阅',
                      maxLines: null,
                      textAlignVertical: TextAlignVertical.top,
                      style: AvType.s(14),
                    ),
                  ),
                ],
              ),
            ),
            const AvFieldRow(label: '名称', placeholder: '自动读取', inputSize: 14),
          ],
        ),
        const SizedBox(height: 12),
        CustomPaint(
          painter: AvDashedBorder(color: c.l3, radius: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                AvIcon(Symbols.upload_file_rounded, size: 28, color: c.tint),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '或拖入配置文件',
                      style: AvType.subheadStrong.copyWith(color: c.l1),
                    ),
                    Text(
                      '.json（sing-box）/ .yaml（Clash）',
                      style: AvType.caption.copyWith(color: c.l2),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        AvGroup(
          children: [
            AvRow(
              title: '自动更新',
              subtitle: '每 12 小时自动更新',
              trailing: AvSwitch(
                value: s.toggles['addAuto']!,
                onChanged: (v) => s.set(() => s.toggles['addAuto'] = v),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
          child: Text(
            '已登录 Avalon Cloud，保存后自动同步到你的其他设备。',
            style: AvType.caption.copyWith(color: c.l2),
          ),
        ),
      ],
    );
  }
}

class _Node extends StatelessWidget {
  const _Node();

  @override
  Widget build(BuildContext context) {
    final s = GalleryScope.of(context);
    final c = context.av;
    final p = s.nodeProto;
    final hasTransport = const ['VLESS', 'VMess', 'Trojan'].contains(p);
    final secOpts = _security[p];
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
    Widget labeled(String label, Widget child) => Row(
      children: [
        SizedBox(
          width: 84,
          child: Text(label, style: AvType.caption.copyWith(color: c.l2)),
        ),
        const SizedBox(width: 12),
        Expanded(child: child),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
          decoration: BoxDecoration(
            color: c.cell,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              AvIcon(Symbols.content_paste_rounded, size: 18, color: c.l2),
              const SizedBox(width: 10),
              Expanded(
                child: AvInput(
                  placeholder: '粘贴 vless:// vmess:// ss:// hy2:// 分享链接',
                  style: AvType.s(14),
                ),
              ),
              const SizedBox(width: 10),
              AvDesktopButton(
                label: '解析',
                tinted: true,
                height: 28,
                radius: 7,
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        labeled(
          '协议',
          Align(
            alignment: Alignment.centerLeft,
            child: AvPullDownMenu<String>(
              items: _protocols,
              selected: p,
              width: 280,
              alignRight: false,
              itemHeight: 32,
              labelSize: 13,
              onSelected: (v) => s.set(() => s.nodeProto = v),
              builder: (context, toggle) => AvPressable(
                onTap: toggle,
                pressedOpacity: 0.7,
                child: Container(
                  height: 28,
                  constraints: const BoxConstraints(minWidth: 200),
                  padding: const EdgeInsets.fromLTRB(12, 0, 6, 0),
                  decoration: BoxDecoration(
                    color: c.cell,
                    borderRadius: BorderRadius.circular(7),
                    boxShadow: [
                      BoxShadow(color: c.sep, spreadRadius: 0.5),
                      const BoxShadow(
                        color: Color(0x14000000),
                        offset: Offset(0, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        p,
                        style: AvType.footnoteStrong.copyWith(color: c.l1),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _protocols.firstWhere((m) => m.value == p).subtitle!,
                        style: AvType.caption.copyWith(color: c.l2),
                      ),
                      const SizedBox(width: 6),
                      AvIcon(
                        Symbols.unfold_more_rounded,
                        size: 16,
                        color: c.l2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        _label(context, '服务器'),
        AvGroup(
          children: [
            const AvFieldRow(label: '名称', placeholder: '东京 VPS', inputSize: 14),
            for (final f in _fields[p]!)
              AvFieldRow(
                label: f.$1,
                placeholder: f.$2,
                mono: f.$3,
                initialValue: f.$1 == '端口' ? '443' : null,
              ),
          ],
        ),
        if (hasTransport) ...[
          const SizedBox(height: 14),
          labeled(
            '传输方式',
            AvSegmented<String>(
              values: const ['TCP', 'WebSocket', 'gRPC', 'HTTP/2'],
              labelOf: (v) => v,
              selected: s.transport,
              height: 32,
              onChanged: (v) => s.set(() => s.transport = v),
            ),
          ),
        ],
        if (secOpts != null) ...[
          const SizedBox(height: 10),
          labeled(
            '传输层安全',
            AvSegmented<String>(
              values: secOpts,
              labelOf: (v) => v,
              selected: sec!,
              height: 32,
              onChanged: (v) => s.set(() => s.security = v),
            ),
          ),
        ],
        if (extra.isNotEmpty)
          AvDropIn(
            key: ValueKey('x-$p-${s.transport}-$sec'),
            child: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: AvGroup(
                children: [
                  for (final f in extra)
                    AvFieldRow(label: f.$1, placeholder: f.$2, mono: f.$3),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
          child: Text(
            '保存到「自建节点」。已登录 Avalon Cloud，保存后自动同步到你的其他设备。',
            style: AvType.caption.copyWith(color: c.l2),
          ),
        ),
      ],
    );
  }
}

class _Chain extends StatelessWidget {
  const _Chain();

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
            AvFieldRow(label: '名称', placeholder: '默认用节点名拼接', inputSize: 14),
          ],
        ),
        _label(context, '链路 · 本机 → … → 目标网站', trailing: summary),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ColoredBox(
            color: c.cell,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var j = 0; j < hl; j++)
                  Builder(
                    builder: (context) {
                      final name = s.hops[j];
                      final node = all.firstWhere(
                        (n) => n.name == name,
                        orElse: () => DemoNode(name, ''),
                      );
                      final l = latencyOf(context, s, name);
                      Widget arrow(IconData icon, bool enabled, int d) =>
                          Opacity(
                            opacity: enabled ? 1 : 0.3,
                            child: AvPressable(
                              onTap: enabled
                                  ? () => s.set(() {
                                      final t = s.hops[j];
                                      s.hops[j] = s.hops[j + d];
                                      s.hops[j + d] = t;
                                    })
                                  : null,
                              pressedOpacity: 0.5,
                              child: SizedBox.square(
                                dimension: 28,
                                child: Center(
                                  child: AvIcon(icon, size: 20, color: c.l2),
                                ),
                              ),
                            ),
                          );
                      return AvDropIn(
                        key: ValueKey('h-$name'),
                        duration: const Duration(milliseconds: 300),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: c.sep, width: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              AvPressable(
                                onTap: () => s.set(() => s.hops.removeAt(j)),
                                scale: 0.8,
                                child: AvIcon(
                                  Symbols.do_not_disturb_on_rounded,
                                  size: 20,
                                  color: c.bad,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: c.tint,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '${j + 1}',
                                  style: AvType.s(
                                    12,
                                    weight: FontWeight.w700,
                                  ).copyWith(color: const Color(0xFFFFFFFF)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AvType.s(14).copyWith(color: c.l1),
                                    ),
                                    Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text:
                                                '${role(j)} · ${node.proto} · ',
                                          ),
                                          TextSpan(
                                            text: l.text,
                                            style: TextStyle(color: l.color),
                                          ),
                                        ],
                                      ),
                                      style: AvType.caption.copyWith(
                                        color: c.l2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              arrow(
                                Symbols.keyboard_arrow_up_rounded,
                                j > 0,
                                -1,
                              ),
                              arrow(
                                Symbols.keyboard_arrow_down_rounded,
                                j < hl - 1,
                                1,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                AvPressable(
                  highlight: true,
                  onTap: () => s.set(() => s.picker = !s.picker),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 40),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        AvIcon(
                          Symbols.add_circle_rounded,
                          size: 20,
                          color: c.ok,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '添加一跳',
                          style: AvType.s(14).copyWith(color: c.tint),
                        ),
                      ],
                    ),
                  ),
                ),
                if (s.picker)
                  AvDropIn(
                    duration: const Duration(milliseconds: 300),
                    child: ColoredBox(
                      color: c.bg,
                      child: Column(
                        children: [
                          for (final n in picks)
                            AvHover(
                              hover: c.fill,
                              builder: (_) => AvPressable(
                                highlight: true,
                                onTap: () => s.set(() => s.hops.add(n.name)),
                                child: Container(
                                  constraints: const BoxConstraints(
                                    minHeight: 34 + AvBorder.hairline,
                                  ),
                                  padding: const EdgeInsets.fromLTRB(
                                    42,
                                    0,
                                    16,
                                    0,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: c.sep, width: 0.5),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          n.name,
                                          style: AvType.footnote.copyWith(
                                            color: c.l1,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        n.proto,
                                        style: AvType.caption.copyWith(
                                          color: c.l2,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      AvIcon(
                                        Symbols.add_rounded,
                                        size: 18,
                                        color: c.tint,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        _label(context, '加入代理组'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final g in const ['节点选择', '流媒体', 'AI 服务', '漏网之鱼'])
              Builder(
                builder: (context) {
                  final on = s.chainGroups.contains(g);
                  return AvPressable(
                    onTap: () => s.set(
                      () => on ? s.chainGroups.remove(g) : s.chainGroups.add(g),
                    ),
                    scale: 0.94,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 28,
                      padding: const EdgeInsets.fromLTRB(8, 0, 12, 0),
                      decoration: BoxDecoration(
                        color: on ? c.tint : c.cell,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AvIcon(
                            on ? Symbols.check_rounded : Symbols.add_rounded,
                            size: 16,
                            color: on ? const Color(0xFFFFFFFF) : c.l1,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            g,
                            style: AvType.s(13, weight: FontWeight.w500)
                                .copyWith(
                                  color: on ? const Color(0xFFFFFFFF) : c.l1,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
        if (hl < 2)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
            child: Text(
              '代理链至少需要 2 跳',
              style: AvType.caption.copyWith(color: c.bad),
            ),
          ),
      ],
    );
  }
}
