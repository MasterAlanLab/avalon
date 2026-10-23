import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/app_info.dart';
import '../../app/log.dart';
import '../../runtime/host_protocol.dart';
import '../../runtime/runtime_coordinator.dart';
import 'logs_state.dart';

/// As many lines as the host keeps (RUNTIME_HOST §6).
const _kept = 2000;

/// The logs page: reads the host's buffer once on opening and then every
/// second while the proxy runs.
final logsViewModelProvider =
    NotifierProvider.autoDispose<LogsViewModel, LogsState>(LogsViewModel.new);

final class LogsViewModel extends Notifier<LogsState> {
  Timer? _poll;
  var _nextSeq = 0;
  var _reading = false;

  @override
  LogsState build() {
    final coordinator = ref.read(runtimeProvider.notifier);
    if (!ref.read(runtimeProvider).available) {
      return const LogsState(available: false);
    }
    void schedule(bool connected) {
      _poll?.cancel();
      _poll = connected
          ? Timer.periodic(
              ref.read(runtimePollIntervalProvider),
              (_) => unawaited(read()),
            )
          : null;
    }

    ref
      ..listen(runtimeProvider.select((s) => s.connected), (_, connected) {
        schedule(connected);
        unawaited(read());
      })
      ..onDispose(() {
        _poll?.cancel();
        // Not from inside the dispose callback: providers may not be read
        // there.
        unawaited(Future.microtask(coordinator.rest));
      });
    schedule(ref.read(runtimeProvider).connected);
    unawaited(Future.microtask(read));
    return const LogsState();
  }

  void setFilter(LogFilter filter) => state = state.copyWith(filter: filter);

  /// Reads what came since the last read.
  Future<void> read() async {
    if (_reading || !ref.mounted) return;
    _reading = true;
    try {
      final page = await ref
          .read(runtimeProvider.notifier)
          .readLogs(afterSeq: _nextSeq);
      if (!ref.mounted) return;
      // A host that restarted counts from one again.
      final restarted = page.nextSeq < _nextSeq;
      _nextSeq = page.nextSeq;
      if (page.entries.isEmpty && !restarted) return;
      final entries = [if (!restarted) ...state.entries, ...page.entries];
      state = state.copyWith(
        entries: entries.length > _kept
            ? entries.sublist(entries.length - _kept)
            : entries,
        dropped: state.dropped || page.dropped > 0,
      );
    } on HostException catch (e) {
      Log.warn('logs: the host did not answer: ${e.error.message}');
    } finally {
      _reading = false;
    }
  }

  /// The buffer as a text file to share, redacted (PRODUCT_SPEC §3.8):
  /// credentials in URLs and headers are masked line by line.
  ({String name, Uint8List bytes}) export({
    required String platform,
    DateTime? now,
  }) {
    final at = now ?? DateTime.now();
    final time = DateFormat('yyyy-MM-dd HH:mm:ss');
    final runtime = ref.read(runtimeProvider);
    final lines = [
      'Avalon $appVersion ($appBuild) · sing-box '
          '${runtime.coreVersion.isEmpty ? '—' : runtime.coreVersion} · $platform',
      'Exported ${time.format(at)}',
      '',
      for (final entry in state.entries)
        redact(
          '${entry.time == null ? '—' : time.format(entry.time!)} '
          '${entry.level.toUpperCase().padRight(5)} ${entry.message}',
        ),
    ];
    return (
      name: 'avalon-log-${DateFormat('yyyyMMdd-HHmmss').format(at)}.txt',
      bytes: Uint8List.fromList(utf8.encode('${lines.join('\n')}\n')),
    );
  }
}
