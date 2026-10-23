import 'dart:async';

import 'auth_service.dart';

/// Safe, runtime-only state. It contains no account identities or credentials.
final class CloudRevocationRetryStatus {
  const CloudRevocationRetryStatus({
    this.queuedCount = 0,
    this.remoteRevocationUnconfirmed = false,
  });

  final int queuedCount;

  /// A proof was unusable before the server confirmed revocation. This stays
  /// visible for the controller's lifetime even after other tasks succeed.
  final bool remoteRevocationUnconfirmed;
}

/// Foreground retry scheduling around the existing encrypted proof queue.
/// Startup never waits for this worker; only AuthService handles credentials
/// and decides whether a proof succeeded, remains retryable, or is terminal.
final class CloudRevocationRetryController {
  CloudRevocationRetryController({
    required this._readPendingCount,
    required this._retryPendingRevocations,
    Duration initialRetryDelay = const Duration(seconds: 5),
    Duration maxRetryDelay = const Duration(minutes: 5),
    Timer Function(Duration, void Function())? scheduler,
  }) : _initialRetryDelay = initialRetryDelay,
       _maxRetryDelay = maxRetryDelay,
       _scheduler = scheduler ?? Timer.new,
       _retryDelay = initialRetryDelay {
    if (initialRetryDelay <= Duration.zero ||
        maxRetryDelay < initialRetryDelay) {
      throw ArgumentError('Invalid Cloud revocation retry interval.');
    }
  }

  final Future<int> Function() _readPendingCount;
  final Future<void> Function() _retryPendingRevocations;
  final Duration _initialRetryDelay;
  final Duration _maxRetryDelay;
  final Timer Function(Duration, void Function()) _scheduler;
  final _statuses = StreamController<CloudRevocationRetryStatus>.broadcast();
  CloudRevocationRetryStatus _status = const CloudRevocationRetryStatus();
  Duration _retryDelay;
  Timer? _timer;
  Future<void>? _drain;
  bool _foreground = false;
  bool _disposed = false;

  CloudRevocationRetryStatus get status => _status;

  /// Subscribe for changes and read [status] for the initial snapshot.
  Stream<CloudRevocationRetryStatus> get statuses => _statuses.stream;

  /// Completion of the current tick only; a future polling timer is not work
  /// already in flight and does not prevent the application becoming idle.
  Future<void> get idle => _drain ?? Future<void>.value();

  void resume() {
    if (_disposed) return;
    _foreground = true;
    _retryDelay = _initialRetryDelay;
    unawaited(trigger());
  }

  void pause() {
    _foreground = false;
    _cancelTimer();
  }

  /// Explicit retry coalesces with a lifecycle or timer tick. Failures never
  /// escape into local startup; the queue and safe status describe the result.
  /// A paused or disposed controller dispatches no new network work.
  Future<void> trigger() {
    if (_disposed || !_foreground) return Future<void>.value();
    _cancelTimer();
    final current = _drain;
    if (current != null) return current;
    final completion = Completer<void>();
    _drain = completion.future;
    unawaited(_run(completion));
    return completion.future;
  }

  /// Also records terminal failures from an explicit AuthService.logout()
  /// action, which happens outside this worker's own drain callback.
  void noteUnconfirmed() {
    _publish(unconfirmed: true);
  }

  Future<void> _run(Completer<void> completion) async {
    try {
      var failed = false;
      var countKnown = false;
      var count = _status.queuedCount;
      try {
        count = await _count();
        countKnown = true;
        _publish(queuedCount: count);
        if (!_disposed && _foreground && count > 0) {
          try {
            await _retryPendingRevocations();
          } on CloudRevocationUnavailableException {
            failed = true;
            noteUnconfirmed();
          } on Object {
            failed = true;
          }
          // A terminal proof may have been removed while other proofs still
          // need retry. Never use failure kind as a replacement for queue state.
          count = await _count();
          _publish(queuedCount: count);
        }
      } on Object {
        failed = true;
        countKnown = false;
      }

      if (_disposed || !_foreground) return;
      if (countKnown && count == 0) {
        _retryDelay = _initialRetryDelay;
        return;
      }
      final delay = failed ? _retryDelay : _initialRetryDelay;
      if (failed) {
        final doubled = _retryDelay.inMicroseconds * 2;
        _retryDelay = Duration(
          microseconds: doubled < _maxRetryDelay.inMicroseconds
              ? doubled
              : _maxRetryDelay.inMicroseconds,
        );
      } else {
        _retryDelay = _initialRetryDelay;
      }
      _timer = _scheduler(delay, () {
        _timer = null;
        unawaited(trigger());
      });
    } finally {
      if (identical(_drain, completion.future)) _drain = null;
      completion.complete();
    }
  }

  Future<int> _count() async {
    final count = await _readPendingCount();
    if (count < 0) throw StateError('Invalid Cloud revocation queue count.');
    return count;
  }

  void _publish({int? queuedCount, bool unconfirmed = false}) {
    if (_disposed) return;
    final next = CloudRevocationRetryStatus(
      queuedCount: queuedCount ?? _status.queuedCount,
      remoteRevocationUnconfirmed:
          unconfirmed || _status.remoteRevocationUnconfirmed,
    );
    if (next.queuedCount == _status.queuedCount &&
        next.remoteRevocationUnconfirmed ==
            _status.remoteRevocationUnconfirmed) {
      return;
    }
    _status = next;
    _statuses.add(next);
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _foreground = false;
    _cancelTimer();
    unawaited(_statuses.close());
  }
}
