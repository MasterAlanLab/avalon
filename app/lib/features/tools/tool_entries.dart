import 'package:av_design/av_design.dart';
import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../app/app_info.dart';
import '../../app/layout.dart';
import '../../app/routes.dart';
import '../../l10n/app_localizations.dart';

/// One entry of the tools list: the same data draws the phone's list and
/// the desktop's left column.
final class ToolEntry {
  const ToolEntry(this.tool, this.icon, this.hue, this.label, {this.value});

  final Tool tool;
  final IconData icon;
  final Color hue;
  final String label;

  /// A short status beside the label.
  final String? value;
}

/// The tools in their groups (PRODUCT_SPEC §2); a null header is the last,
/// untitled group on phones.
List<({String? header, List<ToolEntry> entries})> toolGroups(
  AppLocalizations l,
  AppPlatform platform, {
  required bool desktop,
  bool cloudEnabled = false,
}) => [
  (
    header: l.sectionSettings,
    entries: [
      if (cloudEnabled)
        ToolEntry(
          Tool.cloud,
          Symbols.cloud_rounded,
          AvHues.blue,
          l.toolLoginSync,
        ),
      ToolEntry(Tool.basic, Symbols.settings_rounded, AvHues.gray, l.toolBasic),
      ToolEntry(
        Tool.advanced,
        Symbols.tune_rounded,
        AvHues.blue,
        l.toolAdvanced,
        value: 'TUN · DNS',
      ),
      // iOS has no per-app proxy (PRODUCT_SPEC §6).
      if (platform != AppPlatform.ios)
        ToolEntry(Tool.apps, Symbols.apps_rounded, AvHues.indigo, l.toolApps),
      ToolEntry(
        Tool.geo,
        Symbols.travel_explore_rounded,
        AvHues.teal,
        l.toolGeo,
      ),
      ToolEntry(
        Tool.tailscale,
        Symbols.hub_rounded,
        AvHues.graphite,
        'Tailscale',
      ),
    ],
  ),
  (
    header: l.sectionView,
    entries: [
      ToolEntry(
        Tool.connections,
        Symbols.lan_rounded,
        AvHues.green,
        l.toolConnections,
      ),
      ToolEntry(Tool.logs, Symbols.article_rounded, AvHues.gray, l.toolLogs),
    ],
  ),
  (
    header: desktop ? l.sectionOther : null,
    entries: [
      ToolEntry(
        Tool.about,
        Symbols.info_rounded,
        AvHues.gray,
        l.toolAbout,
        value: desktop ? null : appVersion,
      ),
    ],
  ),
];
