import 'package:flutter/widgets.dart';

import 'controls.dart';
import 'density.dart';
import 'desktop.dart';
import 'list.dart';
import 'scaffolds.dart';
import 'theme.dart';
import 'tokens.dart';

/// One titled group of a settings page.
final class AvSettingsSection {
  const AvSettingsSection({
    this.header,
    required this.rows,
    this.footer,
    this.footerColor,
    this.right = false,
  });

  final String? header;
  final List<Widget> rows;
  final String? footer;
  final Color? footerColor;

  /// Desktop: placed in the right column (V3 3p lays settings out in two).
  final bool right;
}

/// A settings page drawn from its sections: one scrolling column with a
/// back bar on phones, two columns in the desktop tools pane. The same
/// description serves both, so the layouts cannot drift apart.
class AvSettingsPage extends StatelessWidget {
  const AvSettingsPage({
    super.key,
    required this.title,
    required this.backLabel,
    required this.sections,
    this.bottom,
  });

  final String title;
  final String backLabel;
  final List<AvSettingsSection> sections;

  /// Below everything, full width (e.g. «恢复默认设置»).
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    if (!AvDensity.isDesktop(context)) {
      return AvPushedPage(
        title: title,
        backLabel: backLabel,
        topPadding: 0,
        children: [
          for (final (i, s) in sections.indexed) ..._section(s, first: i == 0),
          if (bottom != null) ...[const SizedBox(height: 24), bottom!],
        ],
      );
    }

    Widget column(List<AvSettingsSection> sections) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, s) in sections.indexed) ..._section(s, first: i == 0),
      ],
    );
    final left = [
      for (final s in sections)
        if (!s.right) s,
    ];
    final right = [
      for (final s in sections)
        if (s.right) s,
    ];
    return ColoredBox(
      color: context.av.bg,
      child: AvDesktopPage(
        maxWidth: 900,
        child: LayoutBuilder(
          builder: (context, box) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Narrow panes stack the columns (D71).
              if (box.maxWidth < 620 || right.isEmpty)
                column([...left, ...right])
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: column(left)),
                    const SizedBox(width: 16),
                    Expanded(child: column(right)),
                  ],
                ),
              if (bottom != null)
                Padding(padding: const EdgeInsets.only(top: 20), child: bottom),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _section(AvSettingsSection s, {required bool first}) => [
    if (s.header != null)
      Builder(
        builder: (context) => AvSectionHeader(
          s.header!,
          // The first header sits closer to the top (V3: 8 on phones, 0 in
          // the desktop pane).
          top: first ? (AvDensity.isDesktop(context) ? 0 : 8) : null,
        ),
      )
    else if (!first)
      const SizedBox(height: 24),
    AvGroup(children: s.rows),
    if (s.footer != null) AvSectionFooter(s.footer!, color: s.footerColor),
  ];
}

/// A switch row. A null [onChanged] shows the switch disabled.
AvRow avSwitchRow(
  String title, {
  String? subtitle,
  required bool value,
  required ValueChanged<bool>? onChanged,
}) => AvRow(
  title: title,
  subtitle: subtitle,
  trailing: AvSwitch(value: value, onChanged: onChanged),
);

/// A row showing a value; tapping edits it.
AvRow avValueRow(String title, String value, {VoidCallback? onTap}) =>
    AvRow(title: title, value: value, chevron: onTap != null, onTap: onTap);

/// A row that does something, titled in the accent (or the warning) colour.
Widget avActionRow(String title, {required VoidCallback onTap, Color? color}) =>
    Builder(
      builder: (context) => AvRow(
        title: title,
        titleColor: color ?? context.av.tint,
        onTap: onTap,
      ),
    );

/// A row that opens something: a value with a chevron on phones, an action
/// label on desktop (V3 3p «编辑 JSON…»).
Widget avLinkRow(
  String title, {
  String? value,
  required String action,
  required VoidCallback onTap,
}) => Builder(
  builder: (context) => AvDensity.isDesktop(context)
      ? AvRow(
          title: title,
          onTap: onTap,
          trailing: Text(
            action,
            style: AvType.footnoteStrong.copyWith(color: context.av.tint),
          ),
        )
      : AvRow(title: title, value: value, chevron: true, onTap: onTap),
);
