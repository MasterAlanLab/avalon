import 'package:flutter/cupertino.dart';

import 'surfaces.dart';
import 'tab_bar.dart';
import 'theme.dart';

/// Space below scroll content for the tab bar (V3 `padding-bottom: 110px` =
/// 83 bar + 27). Desktop layouts have no tab bar and pass `tabBar: false`.
double avTabBarClearance(BuildContext context, {bool tabBar = true}) => tabBar
    ? AvTabBar.barHeight + MediaQuery.paddingOf(context).bottom + 27
    : 24;

/// Root tab page: background, status-bar inset, bouncing scroll.
class AvRootPage extends StatelessWidget {
  const AvRootPage({super.key, required this.children, this.tabBar = true})
    : slivers = null,
      semanticChildCount = null;

  const AvRootPage.slivers({
    super.key,
    required List<Widget> this.slivers,
    this.tabBar = true,
    this.semanticChildCount,
  }) : children = const [];

  final List<Widget> children;
  final bool tabBar;
  final int? semanticChildCount;
  final List<Widget>? slivers;

  @override
  Widget build(BuildContext context) {
    const physics = BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
    final padding = EdgeInsets.only(
      top: MediaQuery.paddingOf(context).top,
      bottom: avTabBarClearance(context, tabBar: tabBar),
    );
    return ColoredBox(
      color: context.av.bg,
      child: slivers == null
          ? ListView(physics: physics, padding: padding, children: children)
          : CustomScrollView(
              physics: physics,
              semanticChildCount: semanticChildCount,
              slivers: [
                SliverPadding(
                  padding: padding,
                  sliver: SliverMainAxisGroup(slivers: slivers!),
                ),
              ],
            ),
    );
  }
}

/// Pushed page: nav bar with a back button, then scrolling content.
class AvPushedPage extends StatelessWidget {
  const AvPushedPage({
    super.key,
    required this.title,
    required this.backLabel,
    required this.children,
    this.trailing,
    this.topPadding = 8,
    this.tabBar = true,
  });

  final String title;
  final String backLabel;
  final List<Widget> children;
  final Widget? trailing;
  final double topPadding;
  final bool tabBar;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.av.bg,
      child: Column(
        children: [
          SizedBox(height: MediaQuery.paddingOf(context).top),
          AvNavBar(title: title, backLabel: backLabel, trailing: trailing),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: EdgeInsets.only(
                top: topPadding,
                bottom: avTabBarClearance(context, tabBar: tabBar),
              ),
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
