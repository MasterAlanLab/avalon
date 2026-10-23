import 'package:av_design/av_design.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/format.dart';
import '../../l10n/app_localizations.dart';
import 'connections_state.dart';

/// 连接 (PRODUCT_SPEC §3.8; V3 3h and the desktop table).
class ConnectionsView extends StatelessWidget {
  const ConnectionsView({
    super.key,
    required this.state,
    required this.onClose,
    required this.onCloseAll,
  });

  final ConnectionsState state;
  final ValueChanged<ConnectionRow> onClose;
  final VoidCallback onCloseAll;

  // Desktop columns: host, process, rule, route, upload, download.
  static const _flex = [20, 10, 16, 16, 8, 8];

  String _rule(AppLocalizations l, ConnectionRow row) =>
      row.rule.isEmpty ? l.ruleFinal : row.rule;

  String _empty(AppLocalizations l) => !state.available
      ? l.coreNotConnectedNote
      : state.connected
      ? l.connectionsAllClosed
      : l.connectionsWhenRunning;

  Widget _closeButton(BuildContext context, ConnectionRow row, double size) =>
      AvPressable(
        onTap: () => onClose(row),
        scale: 0.8,
        scaleDuration: const Duration(milliseconds: 300),
        child: AvIcon(Symbols.cancel_rounded, size: size, color: context.av.l3),
      );

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    final l = AppLocalizations.of(context);
    final rows = state.rows;
    if (AvDensity.isDesktop(context)) return _desktop(context, l, c, rows);
    return AvPushedPage(
      title: l.toolConnections,
      backLabel: l.tabTools,
      trailing: rows.isEmpty
          ? null
          : AvTextAction(l.closeAll, color: c.bad, onTap: onCloseAll),
      children: [
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 150, 40, 0),
            child: Column(
              children: [
                AvIcon(Symbols.lan_rounded, size: 52, color: c.l3),
                const SizedBox(height: 14),
                Text(
                  l.noConnections,
                  style: AvType.title2.copyWith(color: c.l1),
                ),
                const SizedBox(height: 6),
                Text(
                  _empty(l),
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
              l.activeConnections(rows.length),
              style: AvType.footnote.copyWith(color: c.l2),
            ),
          ),
          for (final (i, row) in rows.indexed)
            AvGroupItem(
              key: ValueKey(row.id),
              first: i == 0,
              last: i == rows.length - 1,
              // Its own context: the row asks AvGroupItem whether it is last.
              child: Builder(builder: (context) => _phoneRow(context, l, row)),
            ),
        ],
      ],
    );
  }

  Widget _phoneRow(
    BuildContext context,
    AppLocalizations l,
    ConnectionRow row,
  ) {
    final c = context.av;
    final last = AvRowPosition.isLast(context);
    final detail = [if (row.app.isNotEmpty) row.app, _rule(l, row)].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(0, 10, 12, 10),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(
                  bottom: BorderSide(color: c.sep, width: AvBorder.hairline),
                ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.host,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AvType.calloutStrong.copyWith(color: c.l1),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AvType.footnote.copyWith(color: c.l2),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          row.route.join(' → '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AvType.footnote.copyWith(color: c.tint),
                        ),
                      ),
                      Text(
                        '↑${formatBytes(row.upload)} ↓${formatBytes(row.download)}',
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
            _closeButton(context, row, 22),
          ],
        ),
      ),
    );
  }

  Widget _desktop(
    BuildContext context,
    AppLocalizations l,
    AvColors c,
    List<ConnectionRow> rows,
  ) {
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
          for (final (i, item) in items.indexed) ...[
            if (i > 0) const SizedBox(width: 10),
            if (i < _flex.length)
              Expanded(flex: _flex[i], child: item)
            else
              SizedBox(width: 30, child: item),
          ],
        ],
      ),
    );
    Text cell(
      String value, {
      Color? color,
      bool right = false,
      FontWeight? weight,
    }) => Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: right ? TextAlign.right : TextAlign.left,
      style: AvType.s(
        13,
        weight: weight ?? FontWeight.w400,
        tabular: right,
      ).copyWith(color: color ?? c.l1),
    );
    final head = AvType.s(11, weight: FontWeight.w600).copyWith(color: c.l2);
    return ColoredBox(
      color: c.bg,
      child: AvDesktopPage(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.activeConnections(rows.length),
                    style: AvType.footnote.copyWith(color: c.l2),
                  ),
                ),
                if (rows.isNotEmpty)
                  AvPressable(
                    onTap: onCloseAll,
                    pressedOpacity: 0.5,
                    child: Text(
                      l.closeAll,
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
                        bottom: BorderSide(
                          color: c.sep,
                          width: AvBorder.hairline,
                        ),
                      ),
                      [
                        Text(l.columnHost, style: head),
                        Text(l.columnProcess, style: head),
                        Text(l.columnRule, style: head),
                        Text(l.columnChain, style: head),
                        Text(
                          l.columnUpload,
                          style: head,
                          textAlign: TextAlign.right,
                        ),
                        Text(
                          l.columnDownload,
                          style: head,
                          textAlign: TextAlign.right,
                        ),
                        const SizedBox(),
                      ],
                    ),
                    if (rows.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 40,
                          horizontal: 20,
                        ),
                        child: Text(
                          _empty(l),
                          style: AvType.s(14).copyWith(color: c.l2),
                        ),
                      ),
                    for (final (j, row) in rows.indexed)
                      cells(bg: j.isOdd ? c.fill : null, [
                        cell(row.host, weight: FontWeight.w500),
                        cell(row.app.isEmpty ? '—' : row.app),
                        cell(_rule(l, row), color: c.l2),
                        cell(row.route.join(' → '), color: c.tint),
                        cell(formatBytes(row.upload), right: true),
                        cell(formatBytes(row.download), right: true),
                        Center(child: _closeButton(context, row, 18)),
                      ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
