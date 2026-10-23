import 'package:av_design/av_design.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/app_localizations.dart';
import '../../runtime/host_protocol.dart';
import 'logs_state.dart';

/// 日志 (PRODUCT_SPEC §3.8; V3 3i and the desktop pane): the core's lines,
/// newest first, by level.
class LogsView extends StatelessWidget {
  const LogsView({
    super.key,
    required this.state,
    required this.onFilter,
    required this.onShare,
  });

  final LogsState state;
  final ValueChanged<LogFilter> onFilter;
  final VoidCallback onShare;

  static final _time = DateFormat('HH:mm:ss');

  Color _levelColor(AvColors c, String level) => switch (level) {
    'error' || 'fatal' || 'panic' => c.bad,
    'warn' => c.warn,
    'info' => c.tint,
    _ => c.l2,
  };

  Widget _filter(AppLocalizations l, {double? width, double? height}) =>
      AvSegmented<LogFilter>(
        values: LogFilter.values,
        labelOf: (f) => f == LogFilter.all ? l.logsAll : f.name.toUpperCase(),
        selected: state.filter,
        fontSize: 12,
        width: width,
        height: height,
        onChanged: onFilter,
      );

  Widget _line(
    BuildContext context,
    HostLogEntry entry, {
    required bool desktop,
  }) {
    final c = context.av;
    final time = Text(
      entry.time == null ? '—' : _time.format(entry.time!),
      style: AvType.s(12, tabular: true).copyWith(color: c.l2),
    );
    final level = Text(
      entry.level.toUpperCase(),
      style: AvType.s(
        12,
        weight: FontWeight.w700,
      ).copyWith(color: _levelColor(c, entry.level)),
    );
    final message = Text(
      AvType.breakAll(entry.message),
      style: AvType.mono(12, height: 1.45).copyWith(color: c.l1),
    );
    return Container(
      padding: EdgeInsets.symmetric(vertical: desktop ? 8 : 9, horizontal: 16),
      decoration: BoxDecoration(
        border: AvRowPosition.isLast(context)
            ? null
            : Border(
                bottom: BorderSide(color: c.sep, width: AvBorder.hairline),
              ),
      ),
      child: desktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 70, child: time),
                const SizedBox(width: 10),
                SizedBox(width: 56, child: level),
                const SizedBox(width: 10),
                Expanded(child: message),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [level, const SizedBox(width: 8), time]),
                const SizedBox(height: 2),
                message,
              ],
            ),
    );
  }

  List<Widget> _body(BuildContext context, {required bool desktop}) {
    final c = context.av;
    final l = AppLocalizations.of(context);
    final shown = state.shown;
    if (!state.available || state.entries.isEmpty) {
      return [
        Padding(
          padding: EdgeInsets.fromLTRB(40, desktop ? 60 : 120, 40, 0),
          child: Column(
            children: [
              AvIcon(Symbols.article_rounded, size: 52, color: c.l3),
              const SizedBox(height: 14),
              Text(l.noLogs, style: AvType.title2.copyWith(color: c.l1)),
              const SizedBox(height: 6),
              Text(
                state.available ? l.noLogsNote : l.coreNotConnectedNote,
                textAlign: TextAlign.center,
                style: AvType.callout.copyWith(color: c.l2),
              ),
            ],
          ),
        ),
      ];
    }
    return [
      if (state.dropped)
        Padding(
          padding: EdgeInsets.fromLTRB(
            desktop ? 0 : 16,
            0,
            desktop ? 0 : 16,
            12,
          ),
          child: AvBanner(
            title: l.logsDropped,
            icon: Symbols.history_rounded,
            color: c.l2,
          ),
        ),
      for (final (i, entry) in shown.indexed)
        AvGroupItem(
          key: ValueKey(entry.seq),
          first: i == 0,
          last: i == shown.length - 1,
          // Its own context: the line asks AvGroupItem whether it is last.
          child: Builder(
            builder: (context) => _line(context, entry, desktop: desktop),
          ),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    final l = AppLocalizations.of(context);
    final canShare = state.available && state.entries.isNotEmpty;
    if (AvDensity.isDesktop(context)) {
      return ColoredBox(
        color: c.bg,
        child: AvDesktopPage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _filter(l, width: 424, height: 32),
                  const Spacer(),
                  AvDesktopButton(
                    label: l.exportLogs,
                    icon: Symbols.ios_share_rounded,
                    onTap: canShare ? onShare : null,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ..._body(context, desktop: true),
            ],
          ),
        ),
      );
    }
    return AvPushedPage(
      title: l.toolLogs,
      backLabel: l.tabTools,
      trailing: AvPressable(
        onTap: canShare ? onShare : null,
        pressedOpacity: 0.4,
        child: Semantics(
          label: l.shareLogs,
          button: true,
          child: AvIcon(
            Symbols.ios_share_rounded,
            size: 24,
            fill: 0,
            weight: 400,
            color: canShare ? c.tint : c.l3,
          ),
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _filter(l),
        ),
        const SizedBox(height: 16),
        ..._body(context, desktop: false),
      ],
    );
  }
}
