import 'package:av_core/av_core.dart';
import 'package:av_design/av_design.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/format.dart';
import '../../l10n/app_localizations.dart';
import 'rules_state.dart';

/// GEO 规则集 (PRODUCT_SPEC §3.12; V3 3t and the desktop pane): the rule
/// sets in use, and when and how they are updated.
class RulesView extends StatelessWidget {
  const RulesView({
    super.key,
    required this.state,
    required this.now,
    required this.onUpdateAll,
    required this.onUpdate,
    required this.onAutoUpdate,
    required this.onInterval,
    required this.onVia,
  });

  final RulesState state;

  /// For «2 天前».
  final DateTime now;
  final VoidCallback onUpdateAll;
  final ValueChanged<RuleSetItem> onUpdate;
  final ValueChanged<bool> onAutoUpdate;
  final ValueChanged<GeoInterval> onInterval;
  final ValueChanged<DownloadVia> onVia;

  String _summary(AppLocalizations l) {
    final auto = !state.autoUpdate
        ? l.rulesAutoOff
        : switch (state.interval) {
            GeoInterval.daily => l.rulesAutoDaily,
            GeoInterval.weekly => l.rulesAutoWeekly,
          };
    return '${l.rulesCount(state.items.length)} · $auto';
  }

  static String _kind(AppLocalizations l, RuleSetKind kind) => switch (kind) {
    RuleSetKind.geosite => 'GeoSite',
    RuleSetKind.geoip => 'GeoIP',
    RuleSetKind.ruleset => l.ruleKindSet,
  };

  static (IconData, Color) _tile(RuleSetKind kind) => switch (kind) {
    RuleSetKind.geosite => (Symbols.language_rounded, AvHues.teal),
    RuleSetKind.geoip => (Symbols.lan_rounded, AvHues.orange),
    RuleSetKind.ruleset => (Symbols.rule_rounded, AvHues.indigo),
  };

  /// «下载中…», «2 天前» or «未下载», and its colour.
  (String, Color) _when(BuildContext context, RuleSetItem item) {
    final c = context.av;
    final l = AppLocalizations.of(context);
    if (item.busy) return (l.ruleDownloading, c.tint);
    final updated = item.updatedAt;
    if (updated == null) {
      return item.failed
          ? (l.ruleDownloadFailed, c.bad)
          : (l.ruleNotDownloaded, c.l2);
    }
    final fresh = now.difference(updated).inMinutes < 1;
    return (relativeTime(l, updated, now), fresh ? c.ok : c.l2);
  }

  List<Widget> _settings(AppLocalizations l) => [
    AvSectionHeader(l.sectionUpdateSettings),
    AvGroup(
      children: [
        AvRow(
          title: l.autoUpdate,
          minHeight: 44,
          trailing: AvSwitch(value: state.autoUpdate, onChanged: onAutoUpdate),
        ),
        AvSegmentRow<GeoInterval>(
          title: l.geoInterval,
          values: GeoInterval.values,
          labelOf: (v) => switch (v) {
            GeoInterval.daily => l.geoDaily,
            GeoInterval.weekly => l.geoWeekly,
          },
          selected: state.interval,
          desktopWidth: 150,
          onChanged: onInterval,
        ),
        AvSegmentRow<DownloadVia>(
          title: l.geoVia,
          values: DownloadVia.values,
          labelOf: (v) => switch (v) {
            DownloadVia.proxy => l.geoViaProxy,
            DownloadVia.direct => l.geoViaDirect,
          },
          selected: state.via,
          desktopWidth: 150,
          onChanged: onVia,
        ),
      ],
    ),
    AvSectionFooter(l.rulesNote),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    final l = AppLocalizations.of(context);
    final busy = state.busy;
    if (AvDensity.isDesktop(context)) {
      return ColoredBox(
        color: c.bg,
        child: AvDesktopPage(
          maxWidth: 760,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      state.loading ? '' : _summary(l),
                      style: AvType.footnote.copyWith(color: c.l2),
                    ),
                  ),
                  AvDesktopButton(
                    label: busy ? l.rulesUpdating : l.refreshAll,
                    icon: busy
                        ? Symbols.progress_activity_rounded
                        : Symbols.refresh_rounded,
                    spin: busy,
                    filled: true,
                    radius: 7,
                    onTap: busy || state.loading ? null : onUpdateAll,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _Table(state: state, view: this),
              ..._settings(l),
            ],
          ),
        ),
      );
    }
    return AvPushedPage(
      title: l.toolGeo,
      backLabel: l.tabTools,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AvHeaderCard(
            icon: Symbols.travel_explore_rounded,
            hue: AvHues.teal,
            title: l.toolGeo,
            subtitle: state.loading ? '' : _summary(l),
            trailing: AvPillButton(
              label: busy ? l.rulesUpdating : l.refreshAll,
              icon: busy
                  ? Symbols.progress_activity_rounded
                  : Symbols.refresh_rounded,
              iconSpin: busy,
              filled: true,
              height: 32,
              pressScale: 0.92,
              onTap: busy || state.loading ? null : onUpdateAll,
            ),
          ),
        ),
        AvSectionHeader(l.sectionRuleSets),
        AvGroup(
          children: [for (final item in state.items) _phoneRow(context, item)],
        ),
        ..._settings(l),
      ],
    );
  }

  Widget _phoneRow(BuildContext context, RuleSetItem item) {
    final c = context.av;
    final l = AppLocalizations.of(context);
    final (icon, hue) = _tile(item.kind);
    final (time, color) = _when(context, item);
    final size = item.size;
    final detail = item.busy
        ? time
        : [
            _kind(l, item.kind),
            if (size != null) formatBytes(size),
            item.downloaded ? l.ruleUpdatedAgo(time) : time,
            ?item.host,
          ].join(' · ');
    return AvRow(
      leading: AvIconTile(icon, hue),
      minHeight: 56,
      padding: const EdgeInsets.only(right: 12),
      titleWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.tag,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AvType.mono(16).copyWith(color: c.l1),
          ),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AvType.footnote.copyWith(color: color),
          ),
        ],
      ),
      trailing: AvCircleButton(
        icon: item.busy
            ? Symbols.progress_activity_rounded
            : Symbols.refresh_rounded,
        spin: item.busy,
        size: 32,
        iconSize: 18,
        pressScale: 0.85,
        onTap: item.busy ? null : () => onUpdate(item),
      ),
    );
  }
}

/// The desktop table: icon, name, type, size, updated, refresh.
class _Table extends StatelessWidget {
  const _Table({required this.state, required this.view});

  final RulesState state;
  final RulesView view;

  // Fixed width, or a flex share when the width is zero.
  static const _columns = [
    (28.0, 0),
    (0.0, 16),
    (90.0, 0),
    (80.0, 0),
    (0.0, 10),
    (32.0, 0),
  ];

  Widget _cells(List<Widget> cells, {double height = 42, Border? border}) =>
      Container(
        // V3 `height:42px;border-bottom:…` is content-box.
        height: height + (border == null ? 0 : AvBorder.hairline),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(border: border),
        child: Row(
          children: [
            for (final (i, cell) in cells.indexed) ...[
              if (i > 0) const SizedBox(width: 10),
              if (_columns[i].$1 > 0)
                SizedBox(width: _columns[i].$1, child: cell)
              else
                Expanded(flex: _columns[i].$2, child: cell),
            ],
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    final l = AppLocalizations.of(context);
    final head = AvType.s(11, weight: FontWeight.w600).copyWith(color: c.l2);
    final line = Border(
      bottom: BorderSide(color: c.sep, width: AvBorder.hairline),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: ColoredBox(
        color: c.cell,
        child: Column(
          children: [
            _cells(height: 30, border: state.items.isEmpty ? null : line, [
              const SizedBox(),
              Text(l.name, style: head),
              Text(l.columnType, style: head),
              Text(l.columnSize, style: head, textAlign: TextAlign.right),
              Text(l.columnUpdated, style: head, textAlign: TextAlign.right),
              const SizedBox(),
            ]),
            for (final (i, item) in state.items.indexed)
              _cells(border: i == state.items.length - 1 ? null : line, [
                Align(
                  alignment: Alignment.centerLeft,
                  child: AvIconTile(
                    RulesView._tile(item.kind).$1,
                    RulesView._tile(item.kind).$2,
                    size: 22,
                    radius: 6,
                    iconSize: 14,
                  ),
                ),
                Text.rich(
                  TextSpan(
                    text: item.tag,
                    children: [
                      if (item.host case final host?)
                        TextSpan(
                          text: '  $host',
                          style: AvType.footnote.copyWith(color: c.l3),
                        ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AvType.mono(13).copyWith(color: c.l1),
                ),
                Text(
                  RulesView._kind(l, item.kind),
                  style: AvType.footnote.copyWith(color: c.l2),
                ),
                Text(
                  item.size == null ? '—' : formatBytes(item.size!),
                  textAlign: TextAlign.right,
                  style: AvType.s(13, tabular: true).copyWith(color: c.l2),
                ),
                Text(
                  view._when(context, item).$1,
                  textAlign: TextAlign.right,
                  style: AvType.footnote.copyWith(
                    color: view._when(context, item).$2,
                  ),
                ),
                AvHover(
                  hover: c.fill,
                  radius: 13,
                  builder: (_) => AvPressable(
                    onTap: item.busy ? null : () => view.onUpdate(item),
                    pressedOpacity: 0.5,
                    child: SizedBox.square(
                      dimension: 26,
                      child: Center(
                        child: item.busy
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
              ]),
          ],
        ),
      ),
    );
  }
}
