import 'package:av_core/av_core.dart';
import 'package:av_design/av_design.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/app_error.dart';
import '../../app/format.dart';
import '../../l10n/app_localizations.dart';
import 'configurations_state.dart';

/// The configurations page (V3 3c; desktop 3p «配置»). Pure: it draws
/// [state] and reports gestures.
class ConfigurationsView extends StatelessWidget {
  const ConfigurationsView({
    super.key,
    required this.state,
    required this.now,
    required this.onSelect,
    required this.onRefresh,
    required this.onRefreshAll,
    required this.onAdd,
    required this.onManageSelfContent,
    required this.onMenu,
    required this.onDismissWarnings,
  });

  final ConfigurationsState state;

  /// The clock for relative times.
  final DateTime now;
  final ValueChanged<ConfigurationCard> onSelect;
  final ValueChanged<ConfigurationCard> onRefresh;
  final VoidCallback onRefreshAll;
  final VoidCallback onAdd;
  final VoidCallback onManageSelfContent;

  /// Long press (touch) or right click (desktop, with where it happened)
  /// on a card with a menu.
  final void Function(ConfigurationCard card, Offset? position) onMenu;
  final VoidCallback onDismissWarnings;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.av;
    final desktop = AvDensity.isDesktop(context);

    Widget card(ConfigurationCard data) => _Card(
      data: data,
      selected: data.id == state.selectedId,
      now: now,
      desktop: desktop,
      onTap: () => onSelect(data),
      onRefresh: () => onRefresh(data),
      onManage: data.kind == ConfigurationKind.self
          ? onManageSelfContent
          : null,
      onMenu: data.hasMenu ? (position) => onMenu(data, position) : null,
    );

    final warningLines = state.warnings
        .map((w) => warningText(l, w))
        .nonNulls
        .toList(growable: false);
    final warnings = warningLines.isEmpty
        ? null
        : AvBanner(
            title: l.savedWithWarnings,
            lines: warningLines,
            icon: Symbols.warning_rounded,
            color: c.warn,
            onClose: onDismissWarnings,
          );

    if (desktop) {
      // Two columns; the dashed «add» tile closes the grid (V3 3p).
      final tiles = [
        for (final data in state.cards) card(data),
        _AddTile(onTap: onAdd),
      ];
      return ColoredBox(
        color: c.bg,
        child: AvDesktopPage(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (warnings != null) ...[warnings, const SizedBox(height: 14)],
              if (!state.loading)
                AvGrid(
                  columns: 2,
                  gap: 14,
                  rows: [
                    for (var i = 0; i < tiles.length; i += 2)
                      [for (final tile in tiles.skip(i).take(2)) (1, tile)],
                  ],
                ),
            ],
          ),
        ),
      );
    }

    return AvRootPage(
      children: [
        AvLargeTitle(
          l.configurationsTitle,
          actions: [
            if (state.canRefreshAll)
              AvCircleButton(
                icon: Symbols.refresh_rounded,
                spin: state.refreshingAll,
                onTap: onRefreshAll,
              ),
            AvCircleButton(
              icon: Symbols.add_rounded,
              primary: true,
              iconSize: 22,
              iconWeight: 600,
              onTap: onAdd,
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (warnings != null) ...[warnings, const SizedBox(height: 12)],
              for (final (i, data) in state.cards.indexed) ...[
                if (i > 0) const SizedBox(height: 12),
                card(data),
              ],
              if (!state.loading && state.cards.isEmpty) _Empty(onAdd: onAdd),
            ],
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.data,
    required this.selected,
    required this.now,
    required this.desktop,
    required this.onTap,
    required this.onRefresh,
    required this.onManage,
    required this.onMenu,
  });

  final ConfigurationCard data;
  final bool selected;
  final DateTime now;
  final bool desktop;
  final VoidCallback onTap;
  final VoidCallback onRefresh;
  final VoidCallback? onManage;
  final ValueChanged<Offset?>? onMenu;

  String _subtitle(AppLocalizations l) {
    final source = switch (data.kind) {
      ConfigurationKind.subscription => l.sourceSubscription,
      ConfigurationKind.file => l.sourceFile,
      ConfigurationKind.self => l.sourceLocal(data.chainCount),
    };
    final count = data.nodeCount;
    final updated = data.updatedAt;
    return [
      source,
      if (count == null) l.nodeCountUnknown else l.nodeCount(count),
      if (count == null)
        l.notDownloaded
      else if (updated != null)
        l.updatedAt(relativeTime(l, updated, now)),
    ].join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.av;
    final usage = data.usage;
    final error = data.errorCode;
    final success = data.lastSuccessAt;
    final small = AvType.s(12, tabular: true).copyWith(color: c.l2);

    final check = TweenAnimationBuilder<Color?>(
      tween: ColorTween(end: selected ? c.tint : c.l3),
      duration: const Duration(milliseconds: 300),
      builder: (context, color, _) => AvIcon(
        selected
            ? Symbols.check_circle_rounded
            : Symbols.radio_button_unchecked_rounded,
        size: 24,
        color: color,
        fill: selected ? 1 : 0,
        weight: selected ? 500 : 300,
      ),
    );

    final refresh = AvIcon(
      Symbols.refresh_rounded,
      size: desktop ? 17 : 18,
      color: c.tint,
    );

    final card = AvCard(
      radius: 16,
      padding: desktop
          ? const EdgeInsets.symmetric(vertical: 16, horizontal: 18)
          : const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      selected: selected,
      pressScale: desktop ? 0.98 : 0.97,
      onTap: onTap,
      onLongPress: desktop || onMenu == null ? null : () => onMenu!(null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              check,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (desktop
                                  ? AvType.s(16, weight: FontWeight.w600)
                                  : AvType.bodyStrong)
                              .copyWith(color: c.l1),
                    ),
                    Text(
                      _subtitle(l),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AvType.footnote.copyWith(color: c.l2),
                    ),
                  ],
                ),
              ),
              if (data.canRefresh) ...[
                SizedBox(width: desktop ? 0 : 12),
                AvPressable(
                  onTap: data.refreshing ? null : onRefresh,
                  pressedOpacity: 0.5,
                  child: Container(
                    width: desktop ? 30 : 32,
                    height: desktop ? 30 : 32,
                    decoration: BoxDecoration(
                      color: c.fill,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: data.refreshing ? AvSpin(child: refresh) : refresh,
                  ),
                ),
              ],
              if (onManage != null) ...[
                const SizedBox(width: 12),
                AvTextAction(l.manageSelfContent, onTap: onManage!),
              ],
            ],
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(left: 36, top: 8),
              child: Text(
                [
                  l.refreshFailed(errorText(l, error)),
                  if (success != null)
                    l.lastSuccess(relativeTime(l, success, now)),
                ].join(' '),
                style: AvType.caption.copyWith(color: c.bad),
              ),
            ),
          if (usage != null) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: _Usage(usage: usage, style: small),
            ),
          ],
        ],
      ),
    );
    final menu = onMenu;
    if (!desktop || menu == null) return card;
    return GestureDetector(
      onSecondaryTapUp: (details) => menu(details.globalPosition),
      child: card,
    );
  }
}

/// Usage bar (red above 80%) with the amounts and the expiry date; the bar
/// needs a known total.
class _Usage extends StatelessWidget {
  const _Usage({required this.usage, required this.style});

  final Usage usage;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.av;
    final used = usage.upload + usage.download;
    final total = usage.total;
    final expire = usage.expireAt;
    final hasTotal = total != null && total > 0;
    final ratio = hasTotal ? (used / total).clamp(0.0, 1.0) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasTotal) ...[
          Container(
            height: 4,
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              color: c.fill,
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              widthFactor: ratio,
              heightFactor: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: ratio > 0.8 ? c.bad : c.tint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
        Row(
          children: [
            Text(
              hasTotal
                  ? '${formatBytes(used)} / ${formatBytes(total)}'
                  : l.usedOnly(formatBytes(used)),
              style: style,
            ),
            const Spacer(),
            if (expire != null)
              Text(l.expiresOn(formatDate(expire)), style: style),
          ],
        ),
      ],
    );
  }
}

/// Desktop: the dashed «add» tile at the end of the grid.
class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    return AvPressable(
      onTap: onTap,
      scale: 0.98,
      child: CustomPaint(
        painter: AvDashedBorder(color: c.l3, radius: 16),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AvIcon(Symbols.add_circle_rounded, size: 22, color: c.tint),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  AppLocalizations.of(context).addPrompt,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AvType.subheadStrong.copyWith(color: c.tint),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Phone: nothing added yet.
class _Empty extends StatelessWidget {
  const _Empty({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.av;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 72, 16, 0),
      child: Column(
        children: [
          AvIcon(Symbols.folder_open_rounded, size: 48, color: c.l3),
          const SizedBox(height: 12),
          Text(
            l.configurationsEmpty,
            textAlign: TextAlign.center,
            style: AvType.callout.copyWith(color: c.l2),
          ),
          const SizedBox(height: 20),
          AvPillButton(
            label: l.add,
            icon: Symbols.add_rounded,
            filled: true,
            onTap: onAdd,
          ),
        ],
      ),
    );
  }
}
