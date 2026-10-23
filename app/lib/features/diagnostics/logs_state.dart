import 'package:flutter/foundation.dart';

import '../../runtime/host_protocol.dart';

/// The level segments of the logs page (PRODUCT_SPEC §3.8).
enum LogFilter {
  all,
  info,
  warn,
  error,
  debug;

  bool matches(String level) => switch (this) {
    LogFilter.all => true,
    LogFilter.info => level == 'info',
    LogFilter.warn => level == 'warn',
    LogFilter.error => level == 'error' || level == 'fatal' || level == 'panic',
    LogFilter.debug => level == 'debug' || level == 'trace',
  };
}

@immutable
final class LogsState {
  const LogsState({
    this.available = true,
    this.entries = const [],
    this.dropped = false,
    this.filter = LogFilter.all,
  });

  /// False where this platform has no host yet.
  final bool available;

  /// Oldest first, as the host keeps them.
  final List<HostLogEntry> entries;

  /// Lines the host had to drop before they were read.
  final bool dropped;
  final LogFilter filter;

  /// What the page shows: newest first, of the chosen level.
  List<HostLogEntry> get shown => [
    for (final entry in entries.reversed)
      if (filter.matches(entry.level)) entry,
  ];

  LogsState copyWith({
    List<HostLogEntry>? entries,
    bool? dropped,
    LogFilter? filter,
  }) => LogsState(
    available: available,
    entries: entries ?? this.entries,
    dropped: dropped ?? this.dropped,
    filter: filter ?? this.filter,
  );
}
