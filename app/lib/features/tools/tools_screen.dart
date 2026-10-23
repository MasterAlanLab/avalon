import 'package:av_design/av_design.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../app/layout.dart';
import '../../app/routes.dart';
import '../../l10n/app_localizations.dart';
import 'tool_entries.dart';

/// The tools tab on phones (V3 3g): a list of pages.
class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key, this.platform, this.cloudEnabled = false});

  /// Overrides the host platform (golden tests).
  final AppPlatform? platform;
  final bool cloudEnabled;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final groups = toolGroups(
      l,
      platform ?? AppPlatform.host,
      desktop: false,
      cloudEnabled: cloudEnabled,
    );
    return AvRootPage(
      children: [
        AvLargeTitle(l.tabTools),
        for (final (i, group) in groups.indexed) ...[
          if (group.header != null)
            AvSectionHeader(group.header!, top: i == 0 ? 8 : null)
          else
            const SizedBox(height: 24),
          AvGroup(
            children: [
              for (final e in group.entries)
                AvRow(
                  leading: AvIconTile(e.icon, e.hue),
                  title: e.label,
                  value: e.value,
                  chevron: true,
                  onTap: () => context.push(Routes.tool(e.tool)),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
