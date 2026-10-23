import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'density.dart';
import 'desktop.dart';
import 'icon.dart';
import 'list.dart';
import 'pressable.dart';
import 'surfaces.dart';
import 'theme.dart';
import 'tokens.dart';

/// The bar at the top of a sheet or dialog (V3 3d; desktop 3p): an action
/// on the left, the title, and the main action on the right.
class AvFormHeader extends StatelessWidget {
  const AvFormHeader({
    super.key,
    required this.title,
    required this.leading,
    required this.onLeading,
    this.trailing,
    this.onTrailing,
    this.busy = false,
  });

  final String title;
  final String leading;
  final VoidCallback onLeading;

  /// The main action; omitted when there is none.
  final String? trailing;

  /// Null shows the main action disabled.
  final VoidCallback? onTrailing;

  /// The main action is running: a spinner takes its place.
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    final desktop = AvDensity.isDesktop(context);
    final label = trailing;
    final Widget left;
    final Widget middle;
    Widget? right;
    if (desktop) {
      left = AvPressable(
        onTap: onLeading,
        pressedOpacity: 0.4,
        child: Text(leading, style: AvType.s(14).copyWith(color: c.tint)),
      );
      middle = Text(
        title,
        style: AvType.s(14, weight: FontWeight.w700).copyWith(color: c.l1),
      );
      if (label != null) {
        right = Opacity(
          opacity: onTrailing != null || busy ? 1 : 0.4,
          child: AvDesktopButton(
            label: label,
            icon: busy ? Symbols.progress_activity_rounded : null,
            spin: busy,
            filled: true,
            height: 28,
            radius: 7,
            onTap: busy ? null : onTrailing,
          ),
        );
      }
    } else {
      left = AvTextAction(leading, onTap: onLeading);
      middle = Text(title, style: AvType.bodyStrong.copyWith(color: c.l1));
      if (label != null) {
        right = busy
            ? AvSpin(
                child: AvIcon(
                  Symbols.progress_activity_rounded,
                  size: 22,
                  color: c.tint,
                ),
              )
            : AvTextAction(
                label,
                strong: true,
                enabled: onTrailing != null,
                onTap: onTrailing,
              );
      }
    }
    return SizedBox(
      height: desktop ? 52 : 56,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: desktop ? 18 : 16),
        child: Row(
          children: [
            Expanded(
              child: Align(alignment: Alignment.centerLeft, child: left),
            ),
            middle,
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: right ?? const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A line under a group of a form: the section footer on phones, V3's
/// 12 px caption in desktop dialogs. Errors pass their colour.
class AvFormNote extends StatelessWidget {
  const AvFormNote(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (!AvDensity.isDesktop(context)) {
      return AvSectionFooter(text, color: color);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
      child: Text(
        text,
        style: AvType.caption.copyWith(color: color ?? context.av.l2),
      ),
    );
  }
}
