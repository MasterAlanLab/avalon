import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../runtime/host_protocol.dart';
import '../../runtime/runtime_coordinator.dart';
import 'connections_view_model.dart';

/// One row of the connections page (PRODUCT_SPEC §3.8).
@immutable
final class ConnectionRow {
  const ConnectionRow({
    required this.id,
    required this.host,
    required this.app,
    required this.rule,
    required this.route,
    required this.upload,
    required this.download,
  });

  final String id;
  final String host;

  /// The app's name where the device knows it, else its package or file
  /// name; empty when the core could not tell.
  final String app;

  /// The rule as the core writes it; empty for the final target.
  final String rule;

  /// From the rule's target to the exit, as the user names them.
  final List<String> route;
  final int upload;
  final int download;
}

@immutable
final class ConnectionsState {
  const ConnectionsState({
    this.available = true,
    this.connected = false,
    this.rows = const [],
  });

  final bool available;
  final bool connected;
  final List<ConnectionRow> rows;
}

/// App names by package (Android), read once per visit.
final _appNamesProvider = FutureProvider.autoDispose<Map<String, String>>((
  ref,
) async {
  try {
    final apps = await ref.read(installedAppsProvider).list();
    return {for (final app in apps) app.id: app.name};
  } on Exception {
    return const {};
  }
});

final connectionsStateProvider = Provider.autoDispose<ConnectionsState>((ref) {
  final list = ref.watch(connectionsViewModelProvider);
  final runtime = ref.watch(runtimeProvider);
  if (!runtime.available) return const ConnectionsState(available: false);
  if (!runtime.connected) return const ConnectionsState();
  final names = ref.watch(_appNamesProvider).value ?? const {};
  String name(String tag) => runtime.tags[tag]?.name ?? tag;
  return ConnectionsState(
    connected: true,
    rows: [
      for (final HostConnection c in list)
        ConnectionRow(
          id: c.id,
          host: c.host,
          app: names[c.process] ?? c.process,
          rule: c.rule,
          route: [for (final tag in c.chain) name(tag)],
          upload: c.upload,
          download: c.download,
        ),
    ],
  );
});
