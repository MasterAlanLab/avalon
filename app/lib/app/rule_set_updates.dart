import 'dart:async';

import 'package:av_core/av_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../runtime/runtime_coordinator.dart';
import '../services/resource_service.dart';
import 'background.dart';
import 'log.dart';
import 'providers.dart';
import 'services.dart';

/// The rule sets in use: the default catalog, then what each configuration
/// uses, each address once (CONFIG_PIPELINE §8). [configurations] are the
/// contents ([self] for 「自建节点」, which uses the default template).
List<RuleSetRef> collectRuleSets(
  Iterable<({ConfigContent content, bool self})> configurations,
) {
  final seen = <String>{};
  return [
    for (final ref in [
      ...RuleSetCatalog.defaults,
      for (final c in configurations)
        ...RuleSetCatalog.usedBy(c.content, self: c.self),
    ])
      if (seen.add(ruleSetKey(ref))) ref,
  ];
}

/// [collectRuleSets] over what is stored now.
Future<List<RuleSetRef>> storedRuleSets(AppServices services) async {
  final used = <({ConfigContent content, bool self})>[];
  for (final configuration in await services.configurations.watchAll().first) {
    if (configuration.kind == ConfigurationKind.self) {
      used.add((
        content: const ConfigContent(finalTarget: ContentKeys.custom),
        self: true,
      ));
      continue;
    }
    final content = (await services.configurations.content(
      configuration.id,
    ))?.content;
    if (content != null) used.add((content: content, self: false));
  }
  return collectRuleSets(used);
}

/// Provenance is permanent, rather than inferred from the current session.
/// A URL shared with a local configuration keeps the stricter Cloud policy.
Future<Set<String>> cloudRuleSetUrls(AppServices services) async {
  final urls = <String>{};
  for (final configuration in await services.configurations.watchAll().first) {
    if (!await services.configurations.isCloudOrigin(configuration.id)) {
      continue;
    }
    final content = (await services.configurations.content(
      configuration.id,
    ))?.content;
    if (content != null) {
      urls.addAll(RuleSetCatalog.usedBy(content).map((r) => r.url));
    }
  }
  if (await services.settings.isCloudOrigin()) {
    final policy = await services.settings.policy();
    for (final rule in parseOverride(
      policy.jsonOverride?.value ?? '',
    ).ruleSets) {
      if (rule['url'] case final String url) urls.add(url);
    }
  }
  return urls;
}

/// Why a manual update did not start (PRODUCT_SPEC §3.12).
enum RulesUpdateRefusal {
  /// Downloads go through the proxy and it is not running.
  needsProxy,
}

/// Keeps rule sets up to date (CONFIG_PIPELINE §8): what the GEO page asks
/// for now, and automatic updates by the interval of the settings. Its
/// state is the rule sets being downloaded, by `ruleSetKey`.
final ruleSetUpdaterProvider = NotifierProvider<RuleSetUpdater, Set<String>>(
  RuleSetUpdater.new,
);

/// How often automatic updates look for something due.
final ruleSetCheckIntervalProvider = Provider<Duration>(
  (ref) => const Duration(hours: 1),
);

final class RuleSetUpdater extends Notifier<Set<String>> {
  Timer? _timer;
  final _background = Background();

  @override
  Set<String> build() {
    final every = ref.read(ruleSetCheckIntervalProvider);
    _timer = Timer.periodic(
      every,
      (_) => _background.run('rule sets: scheduled update', updateDue),
    );
    // Each start or reload runs a new session: keep what it downloaded
    // itself; updates «经代理» waited for it too.
    ref
      ..listen(
        runtimeProvider.select((s) => s.connected ? s.snapshot.sessionId : ''),
        (_, session) {
          if (session.isNotEmpty) {
            _background.run('rule sets: after start', _sessionStarted);
          }
        },
      )
      ..onDispose(() => _timer?.cancel());
    return const {};
  }

  /// Completes once work started in the background is done (tests wait
  /// for it before closing the database).
  Future<void> idle() => _background.done();

  /// Updates [refs] now, the way the settings say. Null when it ran.
  Future<RulesUpdateRefusal?> update(List<RuleSetRef> refs) async {
    final policy = await ref.read(settingsRepositoryProvider).policy();
    ProxyDownload? download;
    if (policy.geoVia == DownloadVia.proxy) {
      download = ref.read(runtimeProvider.notifier).proxyDownload;
      if (download == null) return RulesUpdateRefusal.needsProxy;
    }
    await _run(refs, download);
    return null;
  }

  /// Updates what is due by the settings' interval. «经代理» with nothing
  /// running waits for the next start; a failure waits an hour.
  Future<void> updateDue({DateTime? now}) async {
    final policy = await ref.read(settingsRepositoryProvider).policy();
    if (!policy.geoAutoUpdate || !ref.mounted) return;
    ProxyDownload? download;
    if (policy.geoVia == DownloadVia.proxy) {
      download = ref.read(runtimeProvider.notifier).proxyDownload;
      if (download == null) return;
    }
    final at = (now ?? DateTime.now()).toUtc();
    final age = switch (policy.geoInterval) {
      GeoInterval.daily => const Duration(days: 1),
      GeoInterval.weekly => const Duration(days: 7),
    };
    final services = ref.read(servicesProvider);
    final cached = await services.ruleResources.all();
    bool isDue(RuleSetRef rule) {
      final item = cached[ruleSetKey(rule)];
      final checked = item?.checkedAt;
      // A failure waits an hour before the next try.
      if (item?.lastError != null &&
          checked != null &&
          at.difference(checked) < const Duration(hours: 1)) {
        return false;
      }
      final updated = item?.updatedAt;
      return updated == null || at.difference(updated) >= age;
    }

    final due = [
      for (final rule in await storedRuleSets(services))
        if (isDue(rule)) rule,
    ];
    if (due.isNotEmpty && ref.mounted) await _run(due, download);
  }

  /// A session started: the rule sets of its configuration not kept yet
  /// were downloaded by the core itself; kept now through the session for
  /// next time (CONFIG_PIPELINE §8). The running plan is not reloaded for
  /// them: it already has their rules. Then what is due.
  Future<void> _sessionStarted() async {
    final download = ref.read(runtimeProvider.notifier).proxyDownload;
    if (download == null) return;
    final services = ref.read(servicesProvider);
    final missing = await ref
        .read(resourceServiceProvider)
        .missing(await _selectedRuleSets(services));
    if (!ref.mounted) return;
    if (missing.isNotEmpty) await _run(missing, download);
    if (ref.mounted) await updateDue();
  }

  /// The rule sets of the selected configuration.
  static Future<List<RuleSetRef>> _selectedRuleSets(
    AppServices services,
  ) async {
    final id = (await services.settings.device()).selectedConfigurationId;
    final configuration = id == null
        ? null
        : await services.configurations.get(id);
    if (configuration == null) return const [];
    if (configuration.kind == ConfigurationKind.self) {
      return RuleSetCatalog.usedBy(
        const ConfigContent(finalTarget: ContentKeys.custom),
        self: true,
      );
    }
    final content = (await services.configurations.content(
      configuration.id,
    ))?.content;
    return content == null ? const [] : RuleSetCatalog.usedBy(content);
  }

  Future<void> _run(List<RuleSetRef> refs, ProxyDownload? download) async {
    final keys = {for (final r in refs) ruleSetKey(r)}..removeAll(state);
    final todo = [
      for (final r in refs)
        if (keys.contains(ruleSetKey(r))) r,
    ];
    if (todo.isEmpty) return;
    state = {...state, ...keys};
    var replaced = false;
    try {
      final resources = ref.read(resourceServiceProvider);
      for (final rule in todo) {
        final cloudUrls = await cloudRuleSetUrls(ref.read(servicesProvider));
        final result = await resources.update(
          rule,
          throughProxy: download,
          cloudSource: cloudUrls.contains(rule.url),
        );
        replaced |= result.replaced;
        if (result.error != null) {
          Log.warn('rule set ${rule.tag}: ${result.error}');
        }
        if (!ref.mounted) return;
        state = {...state}..remove(ruleSetKey(rule));
      }
    } finally {
      if (ref.mounted) state = {...state}..removeAll(keys);
    }
    // New content for files the running plan reads: reload (D10).
    if (replaced && ref.mounted) {
      await ref.read(runtimeProvider.notifier).sync();
    }
  }
}
