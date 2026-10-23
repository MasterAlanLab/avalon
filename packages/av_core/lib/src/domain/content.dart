import 'package:freezed_annotation/freezed_annotation.dart';

import 'node.dart';

part 'content.freezed.dart';
part 'content.g.dart';

/// Keys inside imported content (DATA_MODEL §1.3). Node and group keys are
/// opaque strings unique within one configuration; these two stand for the
/// built-in outbounds.
abstract final class ContentKeys {
  static const direct = 'builtin:direct';
  static const reject = 'builtin:reject';

  /// The injected 「自定义」 group present in every configuration.
  static const custom = 'custom';
}

enum GroupType { selector, urltest }

/// URL test settings of an `urltest` group.
@freezed
abstract class GroupTest with _$GroupTest {
  const factory GroupTest({
    required String url,
    @Default(180) int intervalSeconds,
    @Default(50) int toleranceMs,
  }) = _GroupTest;

  factory GroupTest.fromJson(Map<String, dynamic> json) =>
      _$GroupTestFromJson(json);
}

@freezed
abstract class GroupDef with _$GroupDef {
  const factory GroupDef({
    required String key,
    required String name,
    required GroupType type,

    /// Type shown to the user: Selector, URLTest, Fallback or LoadBalance.
    /// Fallback and LoadBalance run as `urltest` (D28).
    required String displayType,

    /// Node keys, group keys or [ContentKeys] built-ins, in source order.
    @Default(<String>[]) List<String> members,
    GroupTest? test,
  }) = _GroupDef;

  factory GroupDef.fromJson(Map<String, dynamic> json) =>
      _$GroupDefFromJson(json);
}

/// A routing rule. Match fields follow sing-box: values within a field are
/// alternatives; different fields must all match.
@freezed
abstract class RuleDef with _$RuleDef {
  const factory RuleDef({
    @Default(<String>[]) List<String> domain,
    @Default(<String>[]) List<String> domainSuffix,
    @Default(<String>[]) List<String> domainKeyword,
    @Default(<String>[]) List<String> domainRegex,
    @Default(<String>[]) List<String> ipCidr,
    @Default(<String>[]) List<String> sourceIpCidr,
    @Default(<String>[]) List<String> ruleSet,
    @Default(<String>[]) List<String> processName,
    @Default(<String>[]) List<String> processPath,
    @Default(<int>[]) List<int> port,

    /// Ranges such as `1000:2000`.
    @Default(<String>[]) List<String> portRange,

    /// `tcp` or `udp`.
    @Default(<String>[]) List<String> network,
    @Default(false) bool invert,

    /// Node key, group key or a [ContentKeys] built-in.
    required String target,
  }) = _RuleDef;

  factory RuleDef.fromJson(Map<String, dynamic> json) =>
      _$RuleDefFromJson(json);
}

/// How a rule set's file is read. Clash rule providers are converted to
/// sing-box source format after download (CONFIG_PIPELINE §4).
enum RuleSetFormat {
  /// sing-box binary (`.srs`).
  binary,

  /// sing-box source JSON.
  source,
  clashDomainYaml,
  clashDomainText,
  clashIpcidrYaml,
  clashIpcidrText,
  clashClassicalYaml,
  clashClassicalText,
}

/// A rule set used by the content; resolved through `rule_resources`.
@freezed
abstract class RuleSetRef with _$RuleSetRef {
  const factory RuleSetRef({
    required String tag,
    required String url,
    required RuleSetFormat format,
  }) = _RuleSetRef;

  factory RuleSetRef.fromJson(Map<String, dynamic> json) =>
      _$RuleSetRefFromJson(json);
}

/// Why part of an import was skipped or approximated. Shown after saving
/// (PRODUCT_SPEC §3.5); the app maps [kind] to localized text.
enum WarningKind {
  /// A node type outside the nine protocols; [ImportWarning.subject] is the
  /// type, [ImportWarning.count] the number of nodes.
  unsupportedNodeType,

  /// A transport or option Avalon cannot express; the node was skipped.
  unsupportedNodeOption,

  /// A node option without effect on where traffic goes (e.g. multiplex);
  /// the node was kept without it.
  ignoredNodeOption,

  /// A link line or provider that could not be read; it was skipped.
  unreadableEntry,

  /// A rule set Avalon cannot load (local file, inline, `.mrs`); rules
  /// using it were skipped.
  unsupportedRuleSet,

  /// A group type that cannot run (Clash `relay`).
  unsupportedGroupType,

  /// Fallback or LoadBalance imported as URLTest (D28).
  approximatedGroupType,

  /// A rule type Avalon does not support; the rule was skipped.
  unsupportedRule,

  /// A section the import ignores (D29): DNS, inbounds, TUN, ports, mode…
  ignoredSection,

  /// Nodes with certificate verification turned off.
  insecureTls,

  /// No MATCH or `route.final`; traffic falls through to direct.
  missingFinal,

  /// A group member that was skipped or does not exist.
  droppedMember,
}

@freezed
abstract class ImportWarning with _$ImportWarning {
  const factory ImportWarning({
    required WarningKind kind,
    @Default('') String subject,
    @Default(1) int count,
  }) = _ImportWarning;

  factory ImportWarning.fromJson(Map<String, dynamic> json) =>
      _$ImportWarningFromJson(json);
}

/// Typed content of an imported configuration (DATA_MODEL §1.1).
@freezed
abstract class ConfigContent with _$ConfigContent {
  const ConfigContent._();

  const factory ConfigContent({
    @Default(<NodeDef>[]) List<NodeDef> nodes,
    @Default(<GroupDef>[]) List<GroupDef> groups,
    @Default(<RuleDef>[]) List<RuleDef> rules,
    @Default(<RuleSetRef>[]) List<RuleSetRef> ruleSets,

    /// Where unmatched traffic goes: a node key, group key or built-in.
    required String finalTarget,

    /// Route with the default template instead of [rules] (link lists,
    /// CONFIG_PIPELINE §4). Imported configurations without rules route
    /// everything to [finalTarget].
    @Default(false) bool defaultRules,
    @Default(<ImportWarning>[]) List<ImportWarning> warnings,
  }) = _ConfigContent;

  factory ConfigContent.fromJson(Map<String, dynamic> json) =>
      _$ConfigContentFromJson(json);

  GroupDef? group(String key) {
    for (final g in groups) {
      if (g.key == key) return g;
    }
    return null;
  }

  NodeDef? node(String key) {
    for (final n in nodes) {
      if (n.key == key) return n;
    }
    return null;
  }

  /// The main selector (CONFIG_PIPELINE §4): [finalTarget] when it is a
  /// selector, else the first selector; null when there is none.
  GroupDef? get primaryGroup {
    final last = group(finalTarget);
    if (last?.type == GroupType.selector) return last;
    for (final g in groups) {
      if (g.type == GroupType.selector && g.key != ContentKeys.custom) {
        return g;
      }
    }
    return null;
  }
}
