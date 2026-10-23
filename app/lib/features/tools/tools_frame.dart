import 'package:av_design/av_design.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../app/layout.dart';
import '../../app/routes.dart';
import '../../l10n/app_localizations.dart';
import 'tool_entries.dart';

/// The tool shown for a location of the tools tab; the bare tab is the
/// basic settings on desktop.
Tool toolAt(String path) {
  final segments = Uri.parse(path).pathSegments;
  if (segments.length < 2) return Tool.basic;
  return Tool.values.asNameMap()[segments[1]] ?? Tool.basic;
}

/// Wraps the pages of the tools tab. On desktop it adds the list on the
/// left (V3 3p «工具»); on phones the pages stand alone.
class ToolsFrame extends StatelessWidget {
  const ToolsFrame({
    super.key,
    required this.location,
    required this.child,
    this.platform,
    this.cloudEnabled = false,
  });

  /// The current path, e.g. `/tools/advanced`.
  final String location;
  final Widget child;

  /// Overrides the host platform (golden tests).
  final AppPlatform? platform;
  final bool cloudEnabled;

  @override
  Widget build(BuildContext context) {
    if (!AvDensity.isDesktop(context)) return child;
    final l = AppLocalizations.of(context);
    final c = context.av;
    final selected = toolAt(location);
    final groups = toolGroups(
      l,
      platform ?? AppPlatform.host,
      desktop: true,
      cloudEnabled: cloudEnabled,
    );
    return ColoredBox(
      color: c.bg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            // V3 `width:250px;padding:6px 12px 16px` plus the border is
            // content-box: 274.5 overall.
            width: 274 + AvBorder.hairline,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: c.sep, width: 0.5)),
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
              children: [
                for (final group in groups) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
                    child: Text(
                      group.header ?? '',
                      style: AvType.s(
                        12,
                        weight: FontWeight.w600,
                      ).copyWith(color: c.l2),
                    ),
                  ),
                  for (final e in group.entries)
                    _Entry(
                      entry: e,
                      selected: e.tool == selected,
                      // The basic settings are the tab itself.
                      onTap: () => context.go(
                        e.tool == Tool.basic
                            ? Routes.tools
                            : Routes.tool(e.tool),
                      ),
                    ),
                ],
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final ToolEntry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    final value = entry.value;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? c.tintBg : c.tintBg.withValues(alpha: 0),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            AvIconTile(
              entry.icon,
              entry.hue,
              size: 24,
              radius: 6,
              iconSize: 15,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                entry.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AvType.s(14).copyWith(color: selected ? c.tint : c.l1),
              ),
            ),
            if (value != null)
              Text(value, style: AvType.footnote.copyWith(color: c.l2)),
          ],
        ),
      ),
    );
  }
}
