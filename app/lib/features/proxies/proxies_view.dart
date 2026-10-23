import 'package:av_design/av_design.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/latency_label.dart';
import '../../l10n/app_localizations.dart';
import 'proxies_state.dart';

/// The proxies page (V3 3b; desktop 3p «代理»). Pure: it draws [state] and
/// reports gestures.
class ProxiesView extends StatelessWidget {
  const ProxiesView({
    super.key,
    required this.state,
    required this.onGroup,
    required this.onMember,
    required this.onMemberMenu,
    required this.onTest,
    required this.onOpenConfigurations,
  });

  final ProxiesState state;
  final ValueChanged<ProxyGroup> onGroup;
  final void Function(ProxyGroup group, ProxyMember member) onMember;

  /// Long press (touch) or right click (desktop, with where it happened) on
  /// a self node or chain in 「自定义」 (PRODUCT_SPEC §3.4).
  final void Function(ProxyMember member, Offset? position) onMemberMenu;
  final VoidCallback onTest;
  final VoidCallback onOpenConfigurations;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.av;
    final desktop = AvDensity.isDesktop(context);
    final group = state.group;
    final chipScale = _textHeightScale(context, AvType.calloutStrong);

    final Widget? notice = switch (state) {
      ProxiesState(loading: true) => null,
      ProxiesState(:final error?) => _Notice(
        icon: Symbols.error_rounded,
        title: error.message(l),
      ),
      ProxiesState(hasConfiguration: false) => _Notice(
        icon: Symbols.folder_open_rounded,
        title: l.noConfigurationSelected,
        note: l.noConfigurationSelectedNote,
        action: l.goToConfigurations,
        onAction: onOpenConfigurations,
      ),
      ProxiesState(downloaded: false) => _Notice(
        icon: Symbols.cloud_download_rounded,
        title: l.contentNotDownloaded,
        action: l.goToConfigurations,
        onAction: onOpenConfigurations,
      ),
      _ => null,
    };

    final direct = Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: c.cell,
        borderRadius: BorderRadius.circular(desktop ? 10 : 12),
      ),
      child: Row(
        children: [
          AvIcon(Symbols.info_rounded, size: 18, color: c.warn),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l.directModeNote,
              style: AvType.footnote.copyWith(color: c.l2),
            ),
          ),
        ],
      ),
    );

    String nameOf(ProxyGroup g) => g.name ?? l.customGroup;
    ValueChanged<Offset?>? menuFor(ProxyGroup g, ProxyMember m) =>
        g.isCustom && m.isSelfContent
        ? (position) => onMemberMenu(m, position)
        : null;
    final current = group?.current == null
        ? null
        : group!.members[group.current!].name;

    if (desktop) {
      return ColoredBox(
        color: c.bg,
        child: AvDesktopPage(
          child: notice != null || group == null
              ? notice ?? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final g in state.groups)
                          _Chip(
                            label: nameOf(g),
                            selected: g.key == group.key,
                            desktop: true,
                            onTap: () => onGroup(g),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (state.directMode) ...[
                      direct,
                      const SizedBox(height: 14),
                    ],
                    Text(
                      [
                        l.groupSummary(group.displayType, group.members.length),
                        if (current != null) l.groupCurrent(current),
                        if (!group.selectable) l.autoGroupNote,
                      ].join(' · '),
                      style: AvType.footnote.copyWith(color: c.l2),
                    ),
                    const SizedBox(height: 10),
                    if (group.members.isEmpty)
                      Text(
                        l.customEmpty,
                        style: AvType.footnote.copyWith(color: c.l3),
                      )
                    else
                      AvGrid(
                        columns: 4,
                        gap: 12,
                        rows: [
                          for (var i = 0; i < group.members.length; i += 4)
                            [
                              for (
                                var j = i;
                                j < i + 4 && j < group.members.length;
                                j++
                              )
                                (
                                  1,
                                  _MemberCard(
                                    member: group.members[j],
                                    selected: j == group.current,
                                    onTap: () =>
                                        onMember(group, group.members[j]),
                                    onMenu: menuFor(group, group.members[j]),
                                  ),
                                ),
                            ],
                        ],
                      ),
                  ],
                ),
        ),
      );
    }

    return AvRootPage.slivers(
      semanticChildCount: notice == null ? group?.members.length ?? 0 : 0,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AvLargeTitle(
                l.tabProxies,
                actions: [
                  if (notice == null && group != null)
                    AvPillButton(
                      label: l.testLatency,
                      height: 34 * chipScale,
                      icon: group.testing
                          ? Symbols.progress_activity_rounded
                          : Symbols.bolt_rounded,
                      iconSpin: group.testing,
                      onTap: group.testing ? null : onTest,
                    ),
                ],
              ),
              if (notice != null)
                notice
              else if (group != null) ...[
                SizedBox(
                  height: 38 * chipScale,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                    itemCount: state.groups.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, i) => _Chip(
                      label: nameOf(state.groups[i]),
                      selected: state.groups[i].key == group.key,
                      desktop: false,
                      onTap: () => onGroup(state.groups[i]),
                    ),
                  ),
                ),
                if (state.directMode)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: direct,
                  ),
                AvSectionHeader(
                  l.groupSummary(group.displayType, group.members.length),
                  top: 20,
                  trailing: current,
                ),
              ],
            ],
          ),
        ),
        if (notice == null && group != null)
          if (group.members.isEmpty)
            SliverToBoxAdapter(child: AvSectionFooter(l.customEmpty))
          else
            AvSliverGroup(
              itemCount: group.members.length,
              itemBuilder: (context, i) {
                final m = group.members[i];
                return AvRow(
                  insetSeparator: true,
                  minHeight: 56,
                  padding: const EdgeInsets.only(right: 14),
                  titleWidget: Text(
                    m.name,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: AvType.body.copyWith(color: c.l1),
                  ),
                  subtitle: _kindLabel(l, m),
                  onTap: () => onMember(group, m),
                  onLongPress: menuFor(group, m) == null
                      ? null
                      : () => menuFor(group, m)!(null),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Latency(member: m, size: 15),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 22,
                        child: AvPopIcon(
                          Symbols.check_rounded,
                          visible: i == group.current,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        if (notice == null && group != null && !group.selectable)
          SliverToBoxAdapter(child: AvSectionFooter(l.autoGroupNote)),
      ],
    );
  }
}

String _kindLabel(AppLocalizations l, ProxyMember m) => switch (m.kind) {
  ProxyMemberKind.node => m.protocol?.label ?? l.unavailable,
  ProxyMemberKind.group => l.memberGroup(m.groupType ?? ''),
  ProxyMemberKind.chain => l.memberChain(m.hops),
  ProxyMemberKind.direct => l.memberDirect,
  ProxyMemberKind.reject => l.memberReject,
  ProxyMemberKind.tailnet => 'Tailscale',
};

/// Latency column: 「不可用」 for a member that cannot be used, otherwise
/// its last test (PRODUCT_SPEC §3.2).
class _Latency extends StatelessWidget {
  const _Latency({required this.member, required this.size});

  final ProxyMember member;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    final l = AppLocalizations.of(context);
    final (:text, :color) = member.unavailable != null
        ? (text: l.unavailable, color: c.bad)
        : latencyLabel(l, c, member.latency);
    return Text(
      text,
      style: AvType.s(
        size,
        weight: size > 13 ? FontWeight.w500 : FontWeight.w600,
        tabular: true,
      ).copyWith(color: color),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.desktop,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool desktop;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    final type = desktop ? AvType.footnoteStrong : AvType.calloutStrong;
    final height = (desktop ? 30 : 34) * _textHeightScale(context, type);
    return AvPressable(
      onTap: onTap,
      scale: desktop ? 0.94 : 0.92,
      scaleDuration: const Duration(milliseconds: 300),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: AvMotion.ease,
        height: height,
        padding: EdgeInsets.symmetric(horizontal: desktop ? 14 : 16),
        decoration: BoxDecoration(
          color: selected ? c.tint : c.cell,
          borderRadius: BorderRadius.circular(height / 2),
        ),
        // Center(widthFactor: 1) keeps the chip as wide as its label.
        child: Center(
          widthFactor: 1,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: DefaultTextStyle.of(context).style.merge(
              type.copyWith(color: selected ? const Color(0xFFFFFFFF) : c.l1),
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

double _textHeightScale(BuildContext context, TextStyle type) {
  final fontSize = type.fontSize!;
  return (MediaQuery.textScalerOf(context).scale(fontSize) / fontSize)
      .clamp(1.0, double.infinity)
      .toDouble();
}

/// Desktop member card (V3 3p): name, kind and latency, with the check in
/// the corner.
class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.selected,
    required this.onTap,
    required this.onMenu,
  });

  final ProxyMember member;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<Offset?>? onMenu;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.av;
    final card = AvCard(
      radius: 12,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      selected: selected,
      pressScale: 0.96,
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 24),
                child: Text(
                  member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AvType.calloutStrong.copyWith(color: c.l1),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _kindLabel(l, member),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AvType.footnote.copyWith(color: c.l2),
                    ),
                  ),
                  _Latency(member: member, size: 13),
                ],
              ),
            ],
          ),
          Positioned(
            top: -2,
            right: -4,
            child: AvPopIcon(
              Symbols.check_circle_rounded,
              visible: selected,
              size: 20,
            ),
          ),
        ],
      ),
    );
    final menu = onMenu;
    if (menu == null) return card;
    return GestureDetector(
      onSecondaryTapUp: (details) => menu(details.globalPosition),
      child: card,
    );
  }
}

/// Shown instead of the groups: what is missing and where to go.
class _Notice extends StatelessWidget {
  const _Notice({
    required this.icon,
    required this.title,
    this.note,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? note;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 72, 32, 0),
      child: Column(
        children: [
          AvIcon(icon, size: 48, color: c.l3),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AvType.bodyStrong.copyWith(color: c.l1),
          ),
          if (note != null) ...[
            const SizedBox(height: 6),
            Text(
              note!,
              textAlign: TextAlign.center,
              style: AvType.callout.copyWith(color: c.l2),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 20),
            AvPillButton(label: action!, filled: true, onTap: onAction),
          ],
        ],
      ),
    );
  }
}
