import 'package:av_core/av_core.dart';
import 'package:av_design/av_design.dart';
import 'package:flutter/cupertino.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/layout.dart';
import '../../l10n/app_localizations.dart';
import 'apps_state.dart';

/// 分应用代理 (PRODUCT_SPEC §3.11; V3 3k, and D67 on desktop): the mode,
/// and the device's apps or programs with a switch each.
class AppsView extends StatefulWidget {
  const AppsView({
    super.key,
    required this.state,
    required this.platform,
    required this.onMode,
    required this.onToggle,
    required this.onAdd,
    required this.onEnableFindProcess,
  });

  final AppsState state;
  final AppPlatform platform;
  final ValueChanged<PerAppMode> onMode;
  final void Function(String id, bool on) onToggle;

  /// «添加程序» (desktop).
  final VoidCallback onAdd;
  final VoidCallback onEnableFindProcess;

  @override
  State<AppsView> createState() => _AppsViewState();
}

class _AppsViewState extends State<AppsView> {
  String _query = '';

  // Stand-ins for the apps' own icons, as V3 draws them.
  static const _hues = [
    AvHues.blue,
    AvHues.green,
    AvHues.indigo,
    AvHues.orange,
    AvHues.teal,
    AvHues.pink,
    AvHues.purple,
    AvHues.cyan,
    AvHues.graphite,
  ];

  /// The same colour for an app every time (FNV-1a), spread evenly even
  /// over ids that share a long prefix.
  static Color _hueOf(String id) {
    var hash = 0x811c9dc5;
    for (final unit in id.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
    }
    return _hues[(hash >> 7) % _hues.length];
  }

  String _hint(AppLocalizations l, bool desktop) {
    final state = widget.state;
    if (!state.anyOn) return l.appsHintEmpty;
    return switch (state.mode) {
      PerAppMode.whitelist =>
        desktop ? l.appsHintWhitelistDesktop : l.appsHintWhitelist,
      PerAppMode.blacklist =>
        desktop ? l.appsHintBlacklistDesktop : l.appsHintBlacklist,
    };
  }

  Widget _mode(AppLocalizations l, {double? width}) => AvSegmented<PerAppMode>(
    values: PerAppMode.values,
    labelOf: (mode) => switch (mode) {
      PerAppMode.whitelist => l.perAppWhitelist,
      PerAppMode.blacklist => l.perAppBlacklist,
    },
    selected: widget.state.mode,
    width: width,
    onChanged: widget.onMode,
  );

  Widget _search(BuildContext context, AppLocalizations l, double icon) =>
      AvSearchField(
        icon: AvIcon(Symbols.search_rounded, size: icon, color: context.av.l2),
        placeholder: l.search,
        onChanged: (text) => setState(() => _query = text),
      );

  Widget _tile(String id, String name, {required bool desktop}) => Container(
    width: desktop ? 28 : 32,
    height: desktop ? 28 : 32,
    decoration: BoxDecoration(
      color: _hueOf(id),
      borderRadius: BorderRadius.circular(desktop ? 7 : 8),
    ),
    alignment: Alignment.center,
    child: Text(
      name.isEmpty ? '' : name.characters.first.toUpperCase(),
      style: AvType.s(
        desktop ? 13 : 15,
        weight: FontWeight.w600,
      ).copyWith(color: const Color(0xFFFFFFFF)),
    ),
  );

  Widget _row(BuildContext context, AppRow row, {required bool desktop}) {
    final c = context.av;
    final l = AppLocalizations.of(context);
    final detail = row.missing ? l.appNotInstalled : row.id;
    final toggle = AvSwitch(
      value: row.on,
      onChanged: (on) => widget.onToggle(row.id, on),
    );
    final tile = _tile(row.id, row.name, desktop: desktop);
    if (desktop) {
      return AvRow(
        leading: tile,
        title: row.name,
        subtitle: detail,
        trailing: toggle,
      );
    }
    return AvRow(
      leading: tile,
      minHeight: 52,
      titleWidget: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            row.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AvType.body.copyWith(color: c.l1),
          ),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AvType.caption.copyWith(color: c.l2),
          ),
        ],
      ),
      trailing: toggle,
    );
  }

  /// What follows the hint: notices, then the rows, each its own child so
  /// that a phone's long list is built as it scrolls.
  List<Widget> _body(BuildContext context, {required bool desktop}) {
    final c = context.av;
    final l = AppLocalizations.of(context);
    final state = widget.state;
    Widget notice(Widget banner) => Padding(
      padding: EdgeInsets.fromLTRB(desktop ? 0 : 16, 0, desktop ? 0 : 16, 12),
      child: banner,
    );
    Widget note(String text) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 32),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AvType.footnote.copyWith(color: c.l2),
      ),
    );

    if (state.loading) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: CupertinoActivityIndicator(),
        ),
      ];
    }
    final rows = state.matching(_query);
    return [
      if (state.needsFindProcess(desktop: desktop))
        notice(
          AvBanner(
            title: l.compilePerAppNeedsFindProcess,
            lines: [l.appsNeedFindProcessNote],
            icon: Symbols.warning_rounded,
            color: c.warn,
            action: l.turnOn,
            onAction: widget.onEnableFindProcess,
          ),
        ),
      if (state.noneInstalled)
        notice(
          AvBanner(
            title: l.appsNoneInstalled,
            lines: [l.appsNoneInstalledNote],
            icon: Symbols.warning_rounded,
            color: c.warn,
          ),
        ),
      if (state.listFailed)
        notice(
          AvBanner(
            title: l.appsListFailed,
            lines: [l.appsListFailedNote],
            icon: Symbols.warning_rounded,
            color: c.warn,
          ),
        ),
      for (final (i, row) in rows.indexed)
        AvGroupItem(
          key: ValueKey(row.id),
          first: i == 0,
          last: i == rows.length - 1,
          child: _row(context, row, desktop: desktop),
        ),
      if (rows.isEmpty && state.rows.isNotEmpty)
        note(desktop ? l.appsNoMatchDesktop : l.appsNoMatch)
      else if (rows.isEmpty && desktop)
        note(l.appsNoPrograms),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    final l = AppLocalizations.of(context);
    final desktop = widget.platform.isDesktop;
    if (AvDensity.isDesktop(context)) {
      return ColoredBox(
        color: c.bg,
        child: AvDesktopPage(
          maxWidth: 640,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: _search(context, l, 18)),
                  const SizedBox(width: 12),
                  _mode(l, width: 160),
                  if (desktop) ...[
                    const SizedBox(width: 12),
                    AvDesktopButton(
                      label: l.addProgram,
                      icon: Symbols.add_rounded,
                      onTap: widget.onAdd,
                    ),
                  ],
                ],
              ),
              AvSectionFooter(_hint(l, desktop)),
              const SizedBox(height: 10),
              ..._body(context, desktop: desktop),
            ],
          ),
        ),
      );
    }
    return AvPushedPage(
      title: l.toolApps,
      backLabel: l.tabTools,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _search(context, l, 20),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: _mode(l),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 8, 32, 6),
          child: Text(
            _hint(l, desktop),
            style: AvType.footnote.copyWith(color: c.l2),
          ),
        ),
        const SizedBox(height: 2),
        ..._body(context, desktop: desktop),
        // A desktop build in a narrow window still needs a way to add.
        if (desktop && !widget.state.loading)
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: AvGroup(
              children: [avActionRow(l.addProgram, onTap: widget.onAdd)],
            ),
          ),
      ],
    );
  }
}
