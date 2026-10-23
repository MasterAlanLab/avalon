import 'dart:async';

import 'log.dart';

/// Work started without the caller waiting for it, kept track of so that
/// its owner can wait until it is done (e.g. before the database closes).
final class Background {
  final _running = <Future<void>>{};

  /// Starts [work]; a failure is logged with [what].
  void run(String what, Future<void> Function() work) {
    late final Future<void> running;
    running = Future.sync(work)
        .catchError((Object e) => Log.warn('$what failed: $e'))
        .whenComplete(() => _running.remove(running));
    _running.add(running);
  }

  /// Completes once nothing runs, including work started meanwhile.
  Future<void> done() async {
    while (_running.isNotEmpty) {
      await Future.wait(_running.toList());
    }
  }
}
