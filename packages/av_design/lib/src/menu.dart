import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'density.dart';
import 'dialogs.dart';
import 'effects.dart';
import 'icon.dart';
import 'pressable.dart';
import 'theme.dart';
import 'tokens.dart';

class AvMenuItem<T> {
  const AvMenuItem(this.value, this.label, {this.subtitle});

  final T value;
  final String label;
  final String? subtitle;
}

/// Pull-down menu anchored to [child] (protocol picker): radius 14, hairline
/// ring + `0 12px 40px rgba(0,0,0,.22)`, zooms in from the anchor corner
/// (`ios-zoom .32s`). Tapping outside closes it.
class AvPullDownMenu<T> extends StatefulWidget {
  const AvPullDownMenu({
    super.key,
    required this.items,
    required this.selected,
    required this.onSelected,
    required this.builder,
    this.width = 260,
    this.alignRight = true,
    this.itemHeight = 44,
    this.labelSize = 16,
  });

  final List<AvMenuItem<T>> items;
  final T selected;
  final ValueChanged<T> onSelected;
  final Widget Function(BuildContext context, VoidCallback toggle) builder;
  final double width;
  final bool alignRight;
  final double itemHeight;
  final double labelSize;

  @override
  State<AvPullDownMenu<T>> createState() => _AvPullDownMenuState<T>();
}

class _AvPullDownMenuState<T> extends State<AvPullDownMenu<T>> {
  final _link = LayerLink();
  final _portal = OverlayPortalController();

  void _toggle() => _portal.isShowing ? _portal.hide() : _portal.show();

  @override
  Widget build(BuildContext context) {
    final anchor = widget.alignRight
        ? Alignment.bottomRight
        : Alignment.bottomLeft;
    final follower = widget.alignRight ? Alignment.topRight : Alignment.topLeft;
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _portal,
        overlayChildBuilder: (context) {
          final c = context.av;
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _portal.hide,
                ),
              ),
              CompositedTransformFollower(
                link: _link,
                targetAnchor: anchor,
                followerAnchor: follower,
                offset: const Offset(0, 6),
                child: Align(
                  alignment: follower,
                  child: AvZoomIn(
                    alignment: follower,
                    child: Container(
                      width: widget.width,
                      decoration: BoxDecoration(
                        color: c.cell,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: AvShadows.menu(c),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < widget.items.length; i++)
                            _item(
                              context,
                              widget.items[i],
                              i == widget.items.length - 1,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        child: widget.builder(context, _toggle),
      ),
    );
  }

  Widget _item(BuildContext context, AvMenuItem<T> item, bool last) {
    final c = context.av;
    final on = item.value == widget.selected;
    return AvPressable(
      highlight: true,
      highlightOut: const Duration(milliseconds: 200),
      onTap: () {
        _portal.hide();
        widget.onSelected(item.value);
      },
      child: Container(
        constraints: BoxConstraints(
          minHeight: widget.itemHeight + (last ? 0 : AvBorder.hairline),
        ),
        padding: const EdgeInsets.fromLTRB(10, 0, 14, 0),
        decoration: BoxDecoration(
          border: last
              ? null
              : Border(bottom: BorderSide(color: c.sep, width: 0.5)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              child: Opacity(
                opacity: on ? 1 : 0,
                child: AvIcon(Symbols.check_rounded, size: 18, color: c.tint),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.label,
                style: AvType.s(
                  widget.labelSize,
                  weight: on ? FontWeight.w600 : FontWeight.w400,
                ).copyWith(color: c.l1),
              ),
            ),
            if (item.subtitle != null)
              Text(item.subtitle!, style: AvType.caption.copyWith(color: c.l2)),
          ],
        ),
      ),
    );
  }
}

/// An object's menu (PRODUCT_SPEC §3.4): a context menu at [position] when
/// it was opened by right-clicking on desktop, the action sheet otherwise
/// (long press). Resolves to the chosen index, or null when dismissed.
Future<int?> showAvItemMenu(
  BuildContext context, {
  required List<AvAction> actions,
  required String cancel,
  String? title,
  Offset? position,
}) => position != null && AvDensity.isDesktop(context)
    ? showAvContextMenu(context, position: position, actions: actions)
    : showAvActions(context, actions: actions, cancel: cancel, title: title);

/// A context menu at [position] (global), as right-clicking opens on
/// desktop (PRODUCT_SPEC §3.4). It uses the pull-down menu's surface; the
/// item under the pointer is highlighted in the accent colour, as desktop
/// menus are. Resolves to the chosen index, or null when dismissed.
Future<int?> showAvContextMenu(
  BuildContext context, {
  required Offset position,
  required List<AvAction> actions,
}) => Navigator.of(
  context,
  rootNavigator: true,
).push(_ContextMenuRoute(position: position, actions: actions));

class _ContextMenuRoute extends PopupRoute<int> {
  _ContextMenuRoute({required this.position, required this.actions});

  final Offset position;
  final List<AvAction> actions;

  static const double _width = 200;
  static const double _itemHeight = 28;
  static const double _padding = 5;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 120);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final c = context.av;
    final screen = MediaQuery.sizeOf(context);
    final height = actions.length * _itemHeight + _padding * 2;
    // Opens below and right of the pointer, flipped where it would not fit.
    final left = position.dx + _width > screen.width - 8
        ? position.dx - _width
        : position.dx;
    final top = position.dy + height > screen.height - 8
        ? position.dy - height
        : position.dy;
    return Stack(
      children: [
        Positioned(
          left: left.clamp(8, screen.width - _width - 8),
          top: top.clamp(8, screen.height - height - 8),
          width: _width,
          child: FadeTransition(
            opacity: animation,
            child: Container(
              padding: const EdgeInsets.all(_padding),
              decoration: BoxDecoration(
                color: c.cell,
                borderRadius: BorderRadius.circular(10),
                boxShadow: AvShadows.menu(c),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (i, a) in actions.indexed)
                    _ContextMenuItem(
                      action: a,
                      height: _itemHeight,
                      onTap: () => Navigator.of(context).pop(i),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContextMenuItem extends StatefulWidget {
  const _ContextMenuItem({
    required this.action,
    required this.height,
    required this.onTap,
  });

  final AvAction action;
  final double height;
  final VoidCallback onTap;

  @override
  State<_ContextMenuItem> createState() => _ContextMenuItemState();
}

class _ContextMenuItemState extends State<_ContextMenuItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    final color = _hover
        ? const Color(0xFFFFFFFF)
        : (widget.action.destructive ? c.bad : c.l1);
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: _hover ? (widget.action.destructive ? c.bad : c.tint) : null,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            widget.action.label,
            style: AvType.s(13).copyWith(color: color),
          ),
        ),
      ),
    );
  }
}
