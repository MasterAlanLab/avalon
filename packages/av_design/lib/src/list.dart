import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'controls.dart';
import 'density.dart';
import 'icon.dart';
import 'pressable.dart';
import 'theme.dart';
import 'tokens.dart';

/// Section header. Touch: `margin:24px 32px 6px; 13px --l2`.
/// Desktop: `margin:22px 4px 6px; 12px/600 --l2`.
class AvSectionHeader extends StatelessWidget {
  const AvSectionHeader(this.text, {super.key, this.top, this.trailing});

  final String text;
  final double? top;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final desktop = AvDensity.isDesktop(context);
    final style =
        (desktop ? AvType.s(12, weight: FontWeight.w600) : AvType.footnote)
            .copyWith(color: context.av.l2);
    final trailingStyle = style.copyWith(
      fontFeatures: AvType.numeric(13).fontFeatures,
    );
    final h = desktop ? 4.0 : 32.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(h, top ?? (desktop ? 22 : 24), h, 6),
      child: trailing == null
          ? Row(
              children: [Expanded(child: Text(text, style: style))],
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                // The summary keeps its natural width; a long current value
                // uses the remainder instead of squeezing the summary into
                // a column. Leave room for its first character and ellipsis
                // at large text sizes.
                TextStyle effectiveStyle(TextStyle explicitStyle) {
                  final inheritedStyle = DefaultTextStyle.of(
                    context,
                  ).style.merge(explicitStyle);
                  return MediaQuery.boldTextOf(context)
                      ? inheritedStyle.copyWith(fontWeight: FontWeight.bold)
                      : inheritedStyle;
                }

                final painter = TextPainter(
                  text: TextSpan(text: text, style: effectiveStyle(style)),
                  textDirection: Directionality.of(context),
                  textScaler: MediaQuery.textScalerOf(context),
                  locale: Localizations.maybeLocaleOf(context),
                  maxLines: 1,
                )..layout();
                final summaryWidth = painter.width;
                painter.text = TextSpan(
                  text: trailing!.isEmpty
                      ? '…'
                      : '${trailing!.characters.first}…',
                  style: effectiveStyle(trailingStyle),
                );
                painter.layout();
                final gap = (AvType.caption.fontSize! / 2)
                    .clamp(0.0, constraints.maxWidth)
                    .toDouble();
                final summaryMax =
                    (constraints.maxWidth -
                            gap -
                            painter.width.ceilToDouble() -
                            gap)
                        .clamp(0.0, constraints.maxWidth)
                        .toDouble();
                painter.dispose();
                return Row(
                  children: [
                    SizedBox(
                      width: summaryWidth.clamp(0.0, summaryMax).toDouble(),
                      child: Text(
                        text,
                        style: style,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: gap),
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerEnd,
                        heightFactor: 1,
                        child: Text(
                          trailing!,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.ellipsis,
                          style: trailingStyle,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

/// Section footer. Touch: `margin:8px 32px 0; 13px; line-height:1.45`.
/// Desktop: `margin:8px 4px 0; 12px`.
class AvSectionFooter extends StatelessWidget {
  const AvSectionFooter(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final desktop = AvDensity.isDesktop(context);
    return Padding(
      padding: desktop
          ? const EdgeInsets.fromLTRB(4, 8, 4, 0)
          : const EdgeInsets.fromLTRB(32, 8, 32, 0),
      child: Text(
        text,
        style: (desktop ? AvType.caption : AvType.s(13, height: 1.45)).copyWith(
          color: color ?? context.av.l2,
        ),
      ),
    );
  }
}

/// Grouped container (`background:--cell; border-radius:12px;
/// overflow:hidden`). Touch adds the 16 px side inset; desktop sits flush in
/// the content padding. Tells each row whether it is last so rows can omit
/// their bottom hairline.
class AvGroup extends StatelessWidget {
  const AvGroup({super.key, required this.children, this.margin});

  final List<Widget> children;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    final m =
        margin ??
        (AvDensity.isDesktop(context)
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 16));
    return Padding(
      padding: m,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ColoredBox(
          color: context.av.cell,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++)
                AvRowPosition(
                  last: i == children.length - 1,
                  child: children[i],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A long group with one continuous background and lazily built rows.
class AvSliverGroup extends StatelessWidget {
  const AvSliverGroup({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    const radius = Radius.circular(12);
    return SliverPadding(
      padding: AvDensity.isDesktop(context)
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 16),
      sliver: DecoratedSliver(
        decoration: BoxDecoration(
          color: context.av.cell,
          borderRadius: const BorderRadius.all(radius),
        ),
        sliver: SliverList.builder(
          itemCount: itemCount,
          itemBuilder: (context, index) {
            final first = index == 0;
            final last = index == itemCount - 1;
            final row = AvRowPosition(
              last: last,
              child: itemBuilder(context, index),
            );
            return first || last
                ? ClipRRect(
                    clipper: _GroupEndClipper(first: first, last: last),
                    child: row,
                  )
                : row;
          },
        ),
      ),
    );
  }
}

class _GroupEndClipper extends CustomClipper<RRect> {
  const _GroupEndClipper({required this.first, required this.last});

  final bool first;
  final bool last;

  @override
  RRect getClip(Size size) =>
      BorderRadius.vertical(
        top: first ? const Radius.circular(12) : Radius.zero,
        bottom: last ? const Radius.circular(12) : Radius.zero,
      ).toRRect(
        // Keep the shared edge outside the clip so its separator retains its AA.
        Rect.fromLTRB(
          0,
          first ? 0 : -1,
          size.width,
          size.height + (last ? 0 : 1),
        ),
      );

  @override
  bool shouldReclip(_GroupEndClipper oldClipper) =>
      first != oldClipper.first || last != oldClipper.last;
}

/// One row of a group drawn on its own, so that a long group can be the
/// children of a lazily built list: the first and last rows carry the
/// group's corners. Looks exactly like the same row inside an [AvGroup].
class AvGroupItem extends StatelessWidget {
  const AvGroupItem({
    super.key,
    required this.first,
    required this.last,
    required this.child,
  });

  final bool first;
  final bool last;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    const radius = Radius.circular(12);
    final row = ColoredBox(
      color: context.av.cell,
      child: AvRowPosition(last: last, child: child),
    );
    return Padding(
      padding: AvDensity.isDesktop(context)
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 16),
      child: first || last
          ? ClipRRect(
              borderRadius: BorderRadius.vertical(
                top: first ? radius : Radius.zero,
                bottom: last ? radius : Radius.zero,
              ),
              child: row,
            )
          : row,
    );
  }
}

class AvRowPosition extends InheritedWidget {
  const AvRowPosition({super.key, required this.last, required super.child});

  final bool last;

  static bool isLast(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AvRowPosition>()?.last ?? true;

  @override
  bool updateShouldNotify(AvRowPosition oldWidget) => oldWidget.last != last;
}

/// Colored icon tile: touch 29×29 radius 7 with an 18 px glyph; desktop
/// lists use 24×24 radius 6 with 15 px (pass the sizes).
class AvIconTile extends StatelessWidget {
  const AvIconTile(
    this.icon,
    this.color, {
    super.key,
    this.size = 29,
    this.radius = 7,
    this.iconSize = 18,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double radius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: AvIcon(icon, size: iconSize, color: const Color(0xFFFFFFFF)),
    );
  }
}

class AvChevron extends StatelessWidget {
  const AvChevron({super.key});

  @override
  Widget build(BuildContext context) => AvIcon(
    Symbols.chevron_right_rounded,
    size: 22,
    weight: 600,
    color: context.av.l3,
  );
}

/// One list row.
///
/// V3 has two row shapes, reproduced here:
/// * with [leading] (or [insetSeparator]): the outer box has
///   `padding-left:16px`, the inner box carries the hairline, so the separator
///   starts at the text.
/// * plain settings/form rows: the row itself carries the hairline, which
///   therefore runs edge to edge.
///
/// Desktop density uses 14 px titles, 12 px subtitles, 13 px values, 40/42
/// minimum height and no chevron, as in V3 3p/3q/3r.
class AvRow extends StatelessWidget {
  const AvRow({
    super.key,
    this.title,
    this.titleWidget,
    this.subtitle,
    this.leading,
    this.leadingGap = 12,
    this.value,
    this.valueStyle,
    this.trailing,
    this.chevron = false,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
    this.minHeight,
    this.titleColor,
    this.insetSeparator = false,
    this.padding,
    this.centered = false,
    this.titleStyle,
  });

  final String? title;
  final Widget? titleWidget;
  final String? subtitle;
  final Widget? leading;
  final double leadingGap;
  final String? value;
  final TextStyle? valueStyle;
  final Widget? trailing;
  final bool chevron;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap;
  final double? minHeight;
  final Color? titleColor;
  final bool insetSeparator;
  final EdgeInsets? padding;
  final bool centered;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    final desktop = AvDensity.isDesktop(context);
    final last = AvRowPosition.isLast(context);
    final border = last
        ? null
        : Border(
            bottom: BorderSide(color: c.sep, width: AvBorder.hairline),
          );

    final baseTitle = titleStyle ?? (desktop ? AvType.s(14) : AvType.body);
    final titleText =
        titleWidget ??
        Text(
          title ?? '',
          style: baseTitle.copyWith(color: titleColor ?? c.l1),
          textAlign: centered ? TextAlign.center : TextAlign.start,
        );
    final label = subtitle == null
        ? titleText
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              titleText,
              Text(
                subtitle!,
                style: (desktop ? AvType.caption : AvType.footnote).copyWith(
                  color: c.l2,
                ),
              ),
            ],
          );

    final hasChevron = chevron && !desktop;
    final content = Row(
      children: [
        // With a value, the title keeps its natural width (up to 220) and the
        // value takes the rest, truncating long ones such as URLs.
        if (value == null)
          Expanded(child: centered ? Center(child: label) : label)
        else ...[
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: label,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value!,
              style:
                  valueStyle ??
                  (desktop ? AvType.footnote : AvType.body).copyWith(
                    color: c.l2,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
        ],
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        if (hasChevron) ...[const SizedBox(width: 6), const AvChevron()],
      ],
    );

    final inset = leading != null || insetSeparator;
    final rightPad = hasChevron ? 12.0 : 16.0;
    final tall = subtitle != null || trailing != null;
    final vPad = tall ? 6.0 : 0.0;
    // V3 rows are content-box (the hairline adds 0.5), except the setting
    // rows with a subtitle or control at the default height, which are
    // `padding:6px 16px;box-sizing:border-box`.
    final borderBox = tall && minHeight == null;
    final minH =
        (minHeight ?? (desktop ? (tall ? 42.0 : 40.0) : 44.0)) +
        (border == null || borderBox ? 0 : AvBorder.hairline);

    Widget row;
    if (inset) {
      row = Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Row(
          children: [
            if (leading != null) ...[leading!, SizedBox(width: leadingGap)],
            Expanded(
              child: Container(
                constraints: BoxConstraints(minHeight: minH),
                padding:
                    padding ?? EdgeInsets.fromLTRB(0, vPad, rightPad, vPad),
                decoration: BoxDecoration(border: border),
                alignment: Alignment.centerLeft,
                child: content,
              ),
            ),
          ],
        ),
      );
    } else {
      row = Container(
        constraints: BoxConstraints(minHeight: minH),
        padding: padding ?? EdgeInsets.fromLTRB(16, vPad, rightPad, vPad),
        decoration: BoxDecoration(border: border),
        alignment: Alignment.centerLeft,
        child: content,
      );
    }

    if (onSecondaryTap != null) {
      row = GestureDetector(onSecondaryTap: onSecondaryTap, child: row);
    }
    if (onTap == null && onLongPress == null) return row;
    return AvPressable(
      onTap: onTap,
      onLongPress: onLongPress,
      highlight: true,
      child: row,
    );
  }
}

/// A list row with a segmented control (V3 settings pages). On phones the
/// control sits to the right of the label ([width] wide) or, when
/// [stacked], below it at full width; on desktop it is always to the right
/// ([desktopWidth] wide).
class AvSegmentRow<T> extends StatelessWidget {
  const AvSegmentRow({
    super.key,
    required this.title,
    required this.values,
    required this.labelOf,
    required this.selected,
    required this.onChanged,
    this.stacked = false,
    this.width = 150,
    this.desktopWidth = 140,
  });

  final String title;
  final List<T> values;
  final String Function(T) labelOf;
  final T selected;
  final ValueChanged<T> onChanged;
  final bool stacked;
  final double width;
  final double desktopWidth;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    final desktop = AvDensity.isDesktop(context);
    final border = AvRowPosition.isLast(context)
        ? null
        : Border(bottom: BorderSide(color: c.sep, width: 0.5));

    if (desktop) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 16),
        decoration: BoxDecoration(border: border),
        child: Row(
          children: [
            Expanded(
              child: Text(title, style: AvType.s(14).copyWith(color: c.l1)),
            ),
            AvSegmented<T>(
              values: values,
              labelOf: labelOf,
              selected: selected,
              onChanged: onChanged,
              width: desktopWidth,
            ),
          ],
        ),
      );
    }
    final label = Text(title, style: AvType.body.copyWith(color: c.l1));
    if (stacked) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(border: border),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            label,
            const SizedBox(height: 8),
            AvSegmented<T>(
              values: values,
              labelOf: labelOf,
              selected: selected,
              onChanged: onChanged,
              style: AvSegmentStyle.inline,
              height: 32,
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(border: border),
      child: Row(
        children: [
          Expanded(child: label),
          AvSegmented<T>(
            values: values,
            labelOf: labelOf,
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
