import 'package:av_core/av_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/rule_set_updates.dart';
import 'rules_view_model.dart';

/// One rule set of the GEO page (PRODUCT_SPEC §3.12).
final class RuleSetItem {
  const RuleSetItem({
    required this.tag,
    required this.kind,
    required this.url,
    this.format = RuleSetFormat.binary,
    this.host,
    this.size,
    this.updatedAt,
    this.failed = false,
    this.busy = false,
  });

  final String tag;
  final RuleSetKind kind;
  final String url;
  final RuleSetFormat format;

  RuleSetRef get ref => RuleSetRef(tag: tag, url: url, format: format);

  /// Where it comes from, set when another rule set has the same name
  /// (configurations may define one name at different addresses).
  final String? host;

  /// Of the downloaded copy; null until there is one.
  final int? size;
  final DateTime? updatedAt;

  /// The last download failed (what was downloaded before stays).
  final bool failed;

  /// Being downloaded now.
  final bool busy;

  bool get downloaded => updatedAt != null;
}

final class RulesState {
  const RulesState({
    this.loading = false,
    this.items = const [],
    this.autoUpdate = true,
    this.interval = GeoInterval.daily,
    this.via = DownloadVia.proxy,
  });

  final bool loading;
  final List<RuleSetItem> items;
  final bool autoUpdate;
  final GeoInterval interval;
  final DownloadVia via;

  bool get busy => items.any((item) => item.busy);
}

final rulesStateProvider = Provider.autoDispose<RulesState>((ref) {
  // Watched first: while the data loads nothing else keeps it alive.
  final busy = ref.watch(ruleSetUpdaterProvider);
  ref.watch(rulesViewModelProvider);
  final cached = ref.watch(cachedRuleSetsProvider).value ?? const {};
  final policy = ref.watch(policyProvider).value;
  final configurations = ref.watch(configurationsProvider).value;
  if (policy == null || configurations == null) {
    return const RulesState(loading: true);
  }
  final used = <({ConfigContent content, bool self})>[];
  for (final configuration in configurations) {
    if (configuration.kind == ConfigurationKind.self) {
      const content = ConfigContent(finalTarget: ContentKeys.custom);
      used.add((content: content, self: true));
      continue;
    }
    final stored = ref.watch(contentProvider(configuration.id));
    if (stored.isLoading && !stored.hasValue) {
      return const RulesState(loading: true);
    }
    // Not downloaded yet, or unreadable: it names no rule sets.
    final content = stored.value?.content;
    if (content != null) used.add((content: content, self: false));
  }
  final rules = collectRuleSets(used);
  final named = <String, int>{};
  for (final rule in rules) {
    named[rule.tag] = (named[rule.tag] ?? 0) + 1;
  }
  return RulesState(
    items: [
      for (final rule in rules)
        RuleSetItem(
          tag: rule.tag,
          kind: RuleSetCatalog.kindOf(rule),
          url: rule.url,
          format: rule.format,
          host: named[rule.tag]! > 1 ? Uri.tryParse(rule.url)?.host : null,
          size: cached[ruleSetKey(rule)]?.size,
          updatedAt: cached[ruleSetKey(rule)]?.updatedAt?.toLocal(),
          failed: cached[ruleSetKey(rule)]?.lastError != null,
          busy: busy.contains(ruleSetKey(rule)),
        ),
    ],
    autoUpdate: policy.geoAutoUpdate,
    interval: policy.geoInterval,
    via: policy.geoVia,
  );
});
