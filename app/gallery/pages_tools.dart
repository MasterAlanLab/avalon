// DEVELOPMENT ONLY: V3 replica of 3h connections, 3i logs, 3u basic and
// 3j advanced settings.
import 'package:av_design/av_design.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'gallery_state.dart';

// ───────────────────────────── 3h 连接 ─────────────────────────────

class ConnectionsPage extends StatelessWidget {
  const ConnectionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = GalleryScope.of(context);
    final c = context.av;
    final conns = s.connected ? s.conns : const <DemoConn>[];
    final direct = s.mode == '直连';

    return AvPushedPage(
      title: '连接',
      backLabel: '工具',
      trailing: AvTextAction(
        '全部关闭',
        color: c.bad,
        onTap: () => s.set(() => s.conns = []),
      ),
      children: [
        if (conns.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 150, 40, 0),
            child: Column(
              children: [
                AvIcon(Symbols.lan_rounded, size: 52, color: c.l3),
                const SizedBox(height: 14),
                Text('暂无连接', style: AvType.title2.copyWith(color: c.l1)),
                const SizedBox(height: 6),
                Text(
                  s.connected ? '所有连接已关闭' : '启动代理后，这里会实时显示连接',
                  textAlign: TextAlign.center,
                  style: AvType.callout.copyWith(color: c.l2),
                ),
              ],
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 6),
            child: Text(
              '${conns.length} 个活动连接',
              style: AvType.footnote.copyWith(color: c.l2),
            ),
          ),
          AvGroup(
            children: [
              for (final cn in conns)
                _ConnRow(
                  cn: cn,
                  chain: direct ? 'DIRECT' : cn.chain,
                  onClose: () =>
                      s.set(() => s.conns = [...s.conns]..remove(cn)),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ConnRow extends StatelessWidget {
  const _ConnRow({
    required this.cn,
    required this.chain,
    required this.onClose,
  });

  final DemoConn cn;
  final String chain;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    final last = AvRowPosition.isLast(context);
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 10, 12, 10),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(bottom: BorderSide(color: c.sep, width: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cn.host,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AvType.calloutStrong.copyWith(color: c.l1),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${cn.app} · ${cn.rule}',
                    style: AvType.footnote.copyWith(color: c.l2),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chain,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AvType.footnote.copyWith(color: c.tint),
                        ),
                      ),
                      Text(
                        '↑${cn.up} ↓${cn.down}',
                        style: AvType.s(
                          13,
                          tabular: true,
                        ).copyWith(color: c.l2),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AvPressable(
              onTap: onClose,
              scale: 0.8,
              scaleDuration: const Duration(milliseconds: 300),
              child: AvIcon(Symbols.cancel_rounded, size: 22, color: c.l3),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────── 3i 日志 ─────────────────────────────

class LogsPage extends StatelessWidget {
  const LogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = GalleryScope.of(context);
    final c = context.av;
    final levelColor = {
      'ERROR': c.bad,
      'WARN': c.warn,
      'INFO': c.tint,
      'DEBUG': c.l2,
    };
    final logs = demoLogs
        .where((l) => s.logLevel == '全部' || l[1] == s.logLevel)
        .toList();

    return AvPushedPage(
      title: '日志',
      backLabel: '工具',
      trailing: AvPressable(
        onTap: () {},
        pressedOpacity: 0.4,
        child: AvIcon(
          Symbols.ios_share_rounded,
          size: 24,
          fill: 0,
          weight: 400,
          color: c.tint,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AvSegmented<String>(
            values: const ['全部', 'INFO', 'WARN', 'ERROR', 'DEBUG'],
            labelOf: (v) => v,
            selected: s.logLevel,
            fontSize: 12,
            onChanged: (v) => s.set(() => s.logLevel = v),
          ),
        ),
        const SizedBox(height: 16),
        AvGroup(
          children: [
            for (final l in logs)
              Builder(
                builder: (context) {
                  final last = AvRowPosition.isLast(context);
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 9,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      border: last
                          ? null
                          : Border(
                              bottom: BorderSide(color: c.sep, width: 0.5),
                            ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              l[1],
                              style: AvType.s(
                                12,
                                weight: FontWeight.w700,
                              ).copyWith(color: levelColor[l[1]]),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l[0],
                              style: AvType.s(
                                12,
                                tabular: true,
                              ).copyWith(color: c.l2),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AvType.breakAll(l[2]),
                          style: AvType.mono(
                            12,
                            height: 1.45,
                          ).copyWith(color: c.l1),
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

// ───────────────────────────── 3u 基础设置 ─────────────────────────────

AvRow switchRow(GalleryState s, String key, String title, {String? subtitle}) =>
    AvRow(
      title: title,
      subtitle: subtitle,
      trailing: AvSwitch(
        value: s.toggles[key]!,
        onChanged: (v) => s.set(() => s.toggles[key] = v),
      ),
    );

/// Row holding a segmented control to the right of its label
/// (`padding:8px 16px`, control 150×30).
class SegmentRow<T> extends StatelessWidget {
  const SegmentRow({
    super.key,
    required this.title,
    required this.values,
    required this.selected,
    required this.onChanged,
    this.width = 150,
  });

  final String title;
  final List<T> values;
  final T selected;
  final ValueChanged<T> onChanged;
  final double width;

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
          AvSegmented<T>(
            values: values,
            labelOf: (v) => '$v',
            selected: selected,
            onChanged: onChanged,
            style: AvSegmentStyle.inline,
            width: width,
          ),
        ],
      ),
    );
  }
}

/// Row with the label above a full-width segmented control
/// (`padding:10px 16px 12px`).
class StackedSegmentRow<T> extends StatelessWidget {
  const StackedSegmentRow({
    super.key,
    required this.title,
    required this.values,
    required this.selected,
    required this.onChanged,
  });

  final String title;
  final List<T> values;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    final last = AvRowPosition.isLast(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: c.sep, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AvType.body.copyWith(color: c.l1)),
          const SizedBox(height: 8),
          AvSegmented<T>(
            values: values,
            labelOf: (v) => '$v',
            selected: selected,
            onChanged: onChanged,
            style: AvSegmentStyle.inline,
            height: 32,
          ),
        ],
      ),
    );
  }
}

class BasicSettingsPage extends StatelessWidget {
  const BasicSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = GalleryScope.of(context);
    final c = context.av;
    return AvPushedPage(
      title: '基础设置',
      backLabel: '工具',
      topPadding: 0,
      children: [
        const AvSectionHeader('通用', top: 8),
        AvGroup(
          children: [
            AvRow(title: '语言', value: '简体中文', chevron: true, onTap: () {}),
            SegmentRow<String>(
              title: '外观',
              values: const ['浅色', '深色'],
              selected: s.dark ? '深色' : '浅色',
              onChanged: (v) => s.set(() => s.dark = v == '深色'),
            ),
          ],
        ),
        const AvSectionHeader('启动'),
        AvGroup(
          children: [
            switchRow(s, 'autostart', '开机自动启动', subtitle: 'Android 开机后在后台运行'),
            switchRow(s, 'autoConnect', '启动后自动连接', subtitle: '打开应用时自动启动代理'),
          ],
        ),
        const AvSectionFooter('iOS 不支持开机自启，可在系统设置中开启 VPN「按需连接」。'),
        const AvSectionHeader('代理'),
        AvGroup(
          children: [
            switchRow(s, 'sys', '系统代理'),
            switchRow(s, 'lan', '允许局域网连接', subtitle: '其他设备可连接本机代理端口'),
            AvRow(title: '混合端口', value: '7890', chevron: true, onTap: () {}),
          ],
        ),
        const AvSectionHeader('通知'),
        AvGroup(children: [switchRow(s, 'speedNotif', '通知栏显示实时速度')]),
        const AvSectionHeader('延迟测试'),
        AvGroup(
          children: [
            AvRow(
              title: '测速地址',
              value: 'gstatic.com/generate_204',
              chevron: true,
              onTap: () {},
            ),
            AvRow(title: '超时', value: '5000 ms', chevron: true, onTap: () {}),
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

// ───────────────────────────── 3j 高级设置 ─────────────────────────────

class AdvancedSettingsPage extends StatelessWidget {
  const AdvancedSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = GalleryScope.of(context);
    final c = context.av;
    return AvPushedPage(
      title: '高级设置',
      backLabel: '工具',
      topPadding: 0,
      children: [
        const AvSectionHeader('虚拟网卡 TUN', top: 8),
        AvGroup(
          children: [
            switchRow(s, 'tun', '启用 TUN', subtitle: '接管设备全部流量'),
            StackedSegmentRow<String>(
              title: '协议栈',
              values: const ['gVisor', 'System', 'Mixed'],
              selected: s.stack,
              onChanged: (v) => s.set(() => s.stack = v),
            ),
            AvRow(title: 'MTU', value: '9000', chevron: true, onTap: () {}),
            switchRow(s, 'autoRoute', '自动路由', subtitle: 'auto_route'),
            switchRow(
              s,
              'strictRoute',
              '严格路由',
              subtitle: 'strict_route · 防止流量泄漏',
            ),
          ],
        ),
        const AvSectionHeader('DNS'),
        AvGroup(
          children: [
            AvRow(
              title: '远程 DNS',
              value: 'https://1.1.1.1/dns-query',
              chevron: true,
              onTap: () {},
            ),
            AvRow(
              title: '直连 DNS',
              value: '223.5.5.5',
              chevron: true,
              onTap: () {},
            ),
            switchRow(s, 'fakeip', 'FakeIP', subtitle: '198.18.0.0/15'),
            StackedSegmentRow<String>(
              title: '解析策略',
              values: const ['优先 IPv4', '仅 IPv4', '优先 IPv6'],
              selected: s.dnsStrat,
              onChanged: (v) => s.set(() => s.dnsStrat = v),
            ),
          ],
        ),
        const AvSectionHeader('路由'),
        AvGroup(
          children: [
            switchRow(s, 'sniff', '流量嗅探', subtitle: '识别 TLS / HTTP / QUIC 域名'),
            switchRow(
              s,
              'sniffOverride',
              '用嗅探结果覆盖目标',
              subtitle: 'sniff_override_destination',
            ),
            switchRow(s, 'bypassLan', '绕过局域网与保留地址'),
            switchRow(s, 'ipv6', 'IPv6'),
            switchRow(s, 'findProc', '查找进程', subtitle: '用于分应用代理和连接页显示应用'),
          ],
        ),
        const AvSectionHeader('Clash API'),
        AvGroup(
          children: [
            switchRow(s, 'clashApi', '外部控制器', subtitle: '供 Web 面板或第三方客户端控制'),
            AvRow(
              title: '监听地址',
              value: '127.0.0.1:9090',
              chevron: true,
              onTap: () {},
            ),
            AvRow(title: '密钥', value: '••••••••', chevron: true, onTap: () {}),
            AvRow(
              title: 'Web 面板',
              value: 'metacubexd',
              chevron: true,
              onTap: () {},
            ),
          ],
        ),
        const AvSectionHeader('内核'),
        AvGroup(
          children: [
            StackedSegmentRow<String>(
              title: '日志等级',
              values: const ['debug', 'info', 'warn', 'error'],
              selected: s.coreLog,
              onChanged: (v) => s.set(() => s.coreLog = v),
            ),
            AvRow(title: '配置覆写', value: 'JSON', chevron: true, onTap: () {}),
            AvRow(title: '查看生成的配置', chevron: true, onTap: () {}),
          ],
        ),
        const AvSectionFooter('配置覆写会合并到每个订阅生成的 sing-box 配置中，适合自定义路由规则或出站。'),
        const SizedBox(height: 24),
        AvGroup(
          children: [AvRow(title: '恢复默认设置', titleColor: c.bad, onTap: () {})],
        ),
      ],
    );
  }
}
