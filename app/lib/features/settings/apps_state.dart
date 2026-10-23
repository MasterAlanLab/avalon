import 'package:av_core/av_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../platform/installed_apps.dart';
import 'apps_view_model.dart';

/// One row of the per-app page (PRODUCT_SPEC §3.11).
final class AppRow {
  const AppRow({
    required this.id,
    required this.name,
    required this.on,
    this.missing = false,
  });

  /// The package name (Android) or the program's path (desktop); shown
  /// under the name.
  final String id;
  final String name;
  final bool on;

  /// An Android package of the saved list that is not installed. It stays
  /// listed so it can be turned off: a list of absent apps still counts as
  /// a list (D13).
  final bool missing;
}

final class AppsState {
  const AppsState({
    this.loading = false,
    this.listFailed = false,
    this.mode = PerAppMode.whitelist,
    this.rows = const [],
    this.anyOn = false,
    this.findProcess = true,
  });

  final bool loading;

  /// The device's apps could not be read; only the saved list is shown.
  final bool listFailed;
  final PerAppMode mode;
  final List<AppRow> rows;

  /// The list is in effect only when something is on (D13).
  final bool anyOn;
  final bool findProcess;

  /// Desktop rules match the process, which «查找进程» provides
  /// (CONFIG_PIPELINE §6); without it the plan does not compile.
  bool needsFindProcess({required bool desktop}) =>
      desktop && anyOn && !findProcess;

  /// Only the listed apps may use the proxy and none of them is installed
  /// (Android): the proxy refuses to start rather than take every app.
  bool get noneInstalled =>
      mode == PerAppMode.whitelist &&
      anyOn &&
      !listFailed &&
      rows.where((r) => r.on).every((r) => r.missing);

  /// The rows whose name or id contains [query].
  List<AppRow> matching(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return [
      for (final row in rows)
        if (row.name.toLowerCase().contains(q) ||
            row.id.toLowerCase().contains(q))
          row,
    ];
  }

  /// [installed] with the saved list folded in. Rows keep their place
  /// while the page is open: what was on when it opened ([pinned]) and the
  /// programs added since ([added], newest first) come first, and stay
  /// listed when turned off.
  factory AppsState.of({
    required List<InstalledApp> installed,
    required List<String> pinned,
    required List<String> added,
    required DeviceSettings settings,
    bool listFailed = false,
  }) {
    final byId = {for (final app in installed) app.id: app};
    final on = settings.perAppList.toSet();
    AppRow row(String id) {
      final app = byId[id];
      return AppRow(
        id: id,
        name: app?.name ?? _nameOf(id),
        on: on.contains(id),
        missing: app == null && !_isPath(id),
      );
    }

    int byName(String a, String b) {
      final x = (byId[a]?.name ?? _nameOf(a)).toLowerCase();
      final y = (byId[b]?.name ?? _nameOf(b)).toLowerCase();
      final order = x.compareTo(y);
      return order != 0 ? order : a.compareTo(b);
    }

    // The order depends only on what the page opened with, so a row does
    // not move when it is switched.
    final first = <String>{...added, ...pinned.toList()..sort(byName)};
    final rest = [
      for (final app in installed)
        if (!first.contains(app.id)) app.id,
    ];
    final user = rest.where((id) => !byId[id]!.system).toList()..sort(byName);
    final system = rest.where((id) => byId[id]!.system).toList()..sort(byName);
    // Saved from elsewhere meanwhile (a restored backup): anything saved is
    // listed, whether or not the device has it.
    final strays =
        on.where((id) => !first.contains(id) && !byId.containsKey(id)).toList()
          ..sort(byName);
    return AppsState(
      listFailed: listFailed,
      mode: settings.perAppMode,
      rows: [
        for (final id in [...first, ...strays, ...user, ...system]) row(id),
      ],
      anyOn: on.isNotEmpty,
      findProcess: settings.findProcess,
    );
  }

  static bool _isPath(String id) => id.contains('/') || id.contains(r'\');

  /// A program not found by listing is named after its file.
  static String _nameOf(String id) {
    if (!_isPath(id)) return id;
    final trimmed = id.endsWith('/') ? id.substring(0, id.length - 1) : id;
    final cut = trimmed.lastIndexOf(RegExp(r'[/\\]'));
    final name = trimmed.substring(cut + 1);
    return name.endsWith('.app')
        ? name.substring(0, name.length - '.app'.length)
        : name;
  }
}

/// What the device offers, read once per visit, with the list as it was
/// saved then.
typedef AppsCatalog = ({
  List<InstalledApp> installed,
  List<String> pinned,
  bool failed,
});

final appsCatalogProvider = FutureProvider.autoDispose<AppsCatalog>((
  ref,
) async {
  final pinned = (await ref.read(deviceSettingsProvider.future)).perAppList;
  try {
    final installed = await ref.watch(installedAppsProvider).list();
    return (installed: installed, pinned: pinned, failed: false);
  } on Exception {
    return (installed: const <InstalledApp>[], pinned: pinned, failed: true);
  }
});

final appsStateProvider = Provider.autoDispose<AppsState>((ref) {
  // Watched first: while the list loads nothing else keeps it alive.
  final added = ref.watch(appsViewModelProvider);
  final settings = ref.watch(deviceSettingsProvider).value;
  final catalog = ref.watch(appsCatalogProvider).value;
  if (settings == null || catalog == null) {
    return const AppsState(loading: true);
  }
  return AppsState.of(
    installed: catalog.installed,
    pinned: catalog.pinned,
    added: added,
    settings: settings,
    listFailed: catalog.failed,
  );
});
