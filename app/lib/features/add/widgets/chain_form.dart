import 'package:av_core/av_core.dart';
import 'package:av_design/av_design.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../app/latency_label.dart';
import '../../../l10n/app_localizations.dart';
import '../../../runtime/latency.dart';
import '../add_state.dart';
import '../chain_options.dart';

/// V3 3f: name, the hops from this device to the destination, and the
/// groups the chain joins.
class ChainForm extends StatelessWidget {
  const ChainForm({
    super.key,
    required this.state,
    required this.options,
    required this.nameController,
    required this.onTogglePicker,
    required this.onAddHop,
    required this.onRemoveHop,
    required this.onMoveHop,
    required this.onToggleGroup,
  });

  final AddState state;
  final ChainOptions options;
  final TextEditingController nameController;
  final VoidCallback onTogglePicker;
  final ValueChanged<MemberRef> onAddHop;
  final ValueChanged<int> onRemoveHop;
  final void Function(int index, int delta) onMoveHop;
  final ValueChanged<String> onToggleGroup;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.av;
    final desktop = AvDensity.isDesktop(context);
    final draft = state.chain;
    final hops = draft.hops;
    final estimate = options.estimate(hops);
    final summary = l.chainSummary(
      hops.length,
      estimate?.status == LatencyStatus.measured
          ? l.chainLatencyEstimate(estimate!.ms!)
          : latencyLabel(l, c, estimate).text,
    );
    final picks = [
      for (final o in options.hops)
        if (!hops.contains(o.ref)) o,
    ];
    final joined = draft.groupsOr(options.defaultGroups);
    final saveError = state.error;

    String meta(int index) {
      final option = options.hop(hops[index]);
      return [
        switch (draft.role(index)) {
          HopRole.entry => l.roleEntry,
          HopRole.relay => l.roleRelay,
          HopRole.exit => l.roleExit,
        },
        if (option == null)
          l.unavailable
        else
          option.protocol?.label ?? 'Tailscale',
      ].join(' · ');
    }

    String nameOf(int index) => options.hop(hops[index])?.name ?? l.unavailable;

    final hopRows = [
      for (var i = 0; i < hops.length; i++)
        AvDropIn(
          key: ValueKey(hops[i]),
          duration: desktop ? const Duration(milliseconds: 300) : AvMotion.drop,
          child: _HopRow(
            index: i,
            name: nameOf(i),
            meta: meta(i),
            latency: options.hop(hops[i])?.latency,
            desktop: desktop,
            canUp: i > 0,
            canDown: i < hops.length - 1,
            onRemove: () => onRemoveHop(i),
            onMove: (d) => onMoveHop(i, d),
          ),
        ),
    ];

    final picker = AvDropIn(
      duration: const Duration(milliseconds: 300),
      child: ColoredBox(
        color: c.bg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (picks.isEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(desktop ? 42 : 50, 10, 16, 10),
                child: Text(
                  l.noHopCandidates,
                  style: (desktop ? AvType.caption : AvType.footnote).copyWith(
                    color: c.l2,
                  ),
                ),
              ),
            for (final o in picks)
              _PickRow(
                option: o,
                desktop: desktop,
                onTap: () => onAddHop(o.ref),
              ),
          ],
        ),
      ),
    );

    final tooShort = hops.length < 2
        ? AvFormNote(l.chainTooShort, color: c.bad)
        : null;
    final nameField = AvGroup(
      children: [
        AvFieldRow(
          label: l.name,
          placeholder: l.chainNameHint,
          inputSize: desktop ? 14 : 17,
          controller: nameController,
        ),
      ],
    );

    if (desktop) {
      Widget label(String text, {String? trailing}) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 6),
        child: Row(
          children: [
            Expanded(
              child: Text(text, style: AvType.caption.copyWith(color: c.l2)),
            ),
            if (trailing != null)
              Text(
                trailing,
                style: AvType.s(12, tabular: true).copyWith(color: c.l2),
              ),
          ],
        ),
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          nameField,
          label(l.sectionChainDesktop, trailing: summary),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ColoredBox(
              color: c.cell,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...hopRows,
                  AvPressable(
                    highlight: true,
                    onTap: onTogglePicker,
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
                            l.addHop,
                            style: AvType.s(14).copyWith(color: c.tint),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (state.hopPicker) picker,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
            child: Text(
              l.chainNote,
              style: AvType.caption.copyWith(color: c.l2),
            ),
          ),
          if (options.groups.isNotEmpty) ...[
            label(l.sectionJoinGroups),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final g in options.groups)
                  _GroupChip(
                    label: g.name,
                    on: joined.contains(g.key),
                    onTap: () => onToggleGroup(g.key),
                  ),
              ],
            ),
          ],
          ?tooShort,
          if (saveError != null) AvFormNote(saveError.message(l), color: c.bad),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        nameField,
        AvSectionHeader(l.sectionChain, trailing: summary),
        AvGroup(
          children: [
            AvRow(
              leading: const AvIconTile(
                Symbols.smartphone_rounded,
                AvHues.gray,
              ),
              title: l.hopLocal,
              titleColor: c.l2,
            ),
            ...hopRows,
            AvRow(
              leading: AvIcon(
                Symbols.add_circle_rounded,
                size: 24,
                color: c.ok,
              ),
              leadingGap: 10,
              title: l.addHop,
              titleColor: c.tint,
              onTap: onTogglePicker,
            ),
            if (state.hopPicker) picker,
            AvRow(
              leading: const AvIconTile(Symbols.public_rounded, AvHues.teal),
              title: l.hopTarget,
              titleColor: c.l2,
            ),
          ],
        ),
        AvSectionFooter(l.chainNote),
        if (options.groups.isNotEmpty) ...[
          AvSectionHeader(l.sectionJoinGroups),
          AvGroup(
            children: [
              for (final g in options.groups)
                AvRow(
                  insetSeparator: true,
                  title: g.name,
                  onTap: () => onToggleGroup(g.key),
                  trailing: AvPopIcon(
                    Symbols.check_rounded,
                    visible: joined.contains(g.key),
                  ),
                ),
            ],
          ),
        ],
        ?tooShort,
        if (saveError != null) AvFormNote(saveError.message(l), color: c.bad),
      ],
    );
  }
}

/// One hop: remove, number, name with role · protocol · latency, and the
/// up/down arrows.
class _HopRow extends StatelessWidget {
  const _HopRow({
    required this.index,
    required this.name,
    required this.meta,
    required this.latency,
    required this.desktop,
    required this.canUp,
    required this.canDown,
    required this.onRemove,
    required this.onMove,
  });

  final int index;
  final String name;
  final String meta;
  final Latency? latency;
  final bool desktop;
  final bool canUp;
  final bool canDown;
  final VoidCallback onRemove;
  final ValueChanged<int> onMove;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    final result = latencyLabel(AppLocalizations.of(context), c, latency);
    Widget arrow(IconData icon, bool enabled, int delta) => Opacity(
      opacity: enabled ? 1 : 0.3,
      child: AvPressable(
        onTap: enabled ? () => onMove(delta) : null,
        pressedOpacity: 0.5,
        child: SizedBox.square(
          dimension: desktop ? 28 : 30,
          child: Center(
            child: AvIcon(
              icon,
              size: desktop ? 20 : 22,
              color: desktop ? c.l2 : c.l3,
            ),
          ),
        ),
      ),
    );
    final remove = AvPressable(
      onTap: onRemove,
      scale: 0.8,
      scaleDuration: const Duration(milliseconds: 300),
      child: AvIcon(
        Symbols.do_not_disturb_on_rounded,
        size: desktop ? 20 : 24,
        color: c.bad,
      ),
    );
    final number = Container(
      width: desktop ? 22 : 24,
      height: desktop ? 22 : 24,
      decoration: BoxDecoration(color: c.tint, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        '${index + 1}',
        style: AvType.s(
          desktop ? 12 : 13,
          weight: FontWeight.w700,
        ).copyWith(color: const Color(0xFFFFFFFF)),
      ),
    );
    final text = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (desktop ? AvType.s(14) : AvType.body).copyWith(color: c.l1),
          ),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: '$meta · '),
                TextSpan(
                  text: result.text,
                  style: TextStyle(
                    color: latency == null ? c.l2 : result.color,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (desktop ? AvType.caption : AvType.footnote).copyWith(
              color: c.l2,
            ),
          ),
        ],
      ),
    );
    final arrows = [
      arrow(Symbols.keyboard_arrow_up_rounded, canUp, -1),
      arrow(Symbols.keyboard_arrow_down_rounded, canDown, 1),
    ];
    final line = Border(bottom: BorderSide(color: c.sep, width: 0.5));
    if (desktop) {
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 8, 6),
        decoration: BoxDecoration(border: line),
        child: Row(
          children: [
            remove,
            const SizedBox(width: 10),
            number,
            const SizedBox(width: 10),
            text,
            ...arrows,
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Row(
        children: [
          remove,
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
              decoration: BoxDecoration(border: line),
              child: Row(
                children: [number, const SizedBox(width: 8), text, ...arrows],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A node offered by «添加一跳».
class _PickRow extends StatelessWidget {
  const _PickRow({
    required this.option,
    required this.desktop,
    required this.onTap,
  });

  final HopOption option;
  final bool desktop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    final side = BorderSide(color: c.sep, width: 0.5);
    Widget row() => AvPressable(
      highlight: true,
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(
          minHeight: (desktop ? 34 : 40) + AvBorder.hairline,
        ),
        padding: EdgeInsets.fromLTRB(desktop ? 42 : 50, 0, 16, 0),
        decoration: BoxDecoration(
          border: desktop ? Border(top: side) : Border(bottom: side),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (desktop ? AvType.footnote : AvType.callout).copyWith(
                  color: c.l1,
                ),
              ),
            ),
            Text(
              option.protocol?.label ?? 'Tailscale',
              style: (desktop ? AvType.caption : AvType.footnote).copyWith(
                color: c.l2,
              ),
            ),
            const SizedBox(width: 12),
            AvIcon(Symbols.add_rounded, size: desktop ? 18 : 20, color: c.tint),
          ],
        ),
      ),
    );
    // V3 `style-hover` on the desktop chain picker rows (D70).
    return desktop ? AvHover(hover: c.fill, builder: (_) => row()) : row();
  }
}

/// Desktop: a group as a toggle chip.
class _GroupChip extends StatelessWidget {
  const _GroupChip({
    required this.label,
    required this.on,
    required this.onTap,
  });

  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    final color = on ? const Color(0xFFFFFFFF) : c.l1;
    return AvPressable(
      onTap: onTap,
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
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AvType.s(
                13,
                weight: FontWeight.w500,
              ).copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
