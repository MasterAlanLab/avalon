import 'dart:async';

import 'package:avalon/cloud/api_client.dart';
import 'package:avalon/cloud/auth_service.dart';
import 'package:avalon/cloud/cloud_revocation_retry.dart';
import 'package:flutter_test/flutter_test.dart';

final class _ManualTimer implements Timer {
  _ManualTimer(this.callback);

  final void Function() callback;
  bool _active = true;
  int _tick = 0;

  @override
  bool get isActive => _active;

  @override
  int get tick => _tick;

  @override
  void cancel() => _active = false;

  void fire() {
    if (!_active) return;
    _active = false;
    ++_tick;
    callback();
  }
}

final class _Scheduler {
  final scheduled = <({Duration delay, _ManualTimer timer})>[];

  Timer schedule(Duration delay, void Function() callback) {
    final timer = _ManualTimer(callback);
    scheduled.add((delay: delay, timer: timer));
    return timer;
  }

  List<({Duration delay, _ManualTimer timer})> get active =>
      scheduled.where((entry) => entry.timer.isActive).toList();

  void fire() => active.single.timer.fire();
}

void main() {
  late _Scheduler scheduler;
  late CloudRevocationRetryController controller;
  late Future<void> Function() drain;
  var pending = 0;
  var attempts = 0;

  setUp(() {
    scheduler = _Scheduler();
    pending = 0;
    attempts = 0;
    drain = () async => pending = 0;
    controller = CloudRevocationRetryController(
      readPendingCount: () async => pending,
      retryPendingRevocations: () async {
        ++attempts;
        await drain();
      },
      initialRetryDelay: const Duration(seconds: 1),
      maxRetryDelay: const Duration(seconds: 4),
      scheduler: scheduler.schedule,
    );
  });

  tearDown(() => controller.dispose());

  test('network failures back off to a bound and retry on recovery', () async {
    pending = 1;
    drain = () async => throw const CloudNetworkException();
    controller.resume();
    await controller.idle;
    expect(controller.status.queuedCount, 1);
    expect(scheduler.active.single.delay, const Duration(seconds: 1));

    scheduler.fire();
    await controller.idle;
    expect(scheduler.active.single.delay, const Duration(seconds: 2));
    scheduler.fire();
    await controller.idle;
    expect(scheduler.active.single.delay, const Duration(seconds: 4));
    scheduler.fire();
    await controller.idle;
    expect(scheduler.active.single.delay, const Duration(seconds: 4));
    expect(controller.status.remoteRevocationUnconfirmed, isFalse);

    drain = () async => pending = 0;
    scheduler.fire();
    await controller.idle;
    expect(attempts, 5);
    expect(controller.status.queuedCount, 0);
    expect(scheduler.active, isEmpty);
  });

  test('overlapping startup, resume, and manual trigger coalesce', () async {
    pending = 1;
    final finish = Completer<void>();
    drain = () async {
      await finish.future;
      pending = 0;
    };
    controller.resume();
    final first = controller.trigger();
    controller.resume();
    final second = controller.trigger();
    expect(identical(first, second), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(attempts, 1);
    finish.complete();
    await Future.wait([first, second]);
    expect(attempts, 1);
    expect(scheduler.active, isEmpty);
  });

  test(
    'pausing an in-flight attempt does not reschedule its failure',
    () async {
      pending = 1;
      final finish = Completer<void>();
      drain = () async {
        await finish.future;
        throw const CloudNetworkException();
      };
      controller.resume();
      await Future<void>.delayed(Duration.zero);
      controller.pause();
      finish.complete();
      await controller.idle;
      expect(controller.status.queuedCount, 1);
      expect(scheduler.active, isEmpty);
    },
  );

  test(
    'dispose cancels polling, closes status, and ignores lifecycle',
    () async {
      pending = 1;
      drain = () async => throw const CloudNetworkException();
      final states = <CloudRevocationRetryStatus>[];
      final done = Completer<void>();
      final subscription = controller.statuses.listen(
        states.add,
        onDone: done.complete,
      );
      controller.resume();
      await controller.idle;
      controller.dispose();
      await done.future;
      controller.resume();
      controller.noteUnconfirmed();
      await controller.trigger();
      expect(attempts, 1);
      expect(states.last.queuedCount, 1);
      expect(controller.status.remoteRevocationUnconfirmed, isFalse);
      expect(scheduler.active, isEmpty);
      await subscription.cancel();
    },
  );

  test(
    'terminal proof stops polling and unconfirmed notice remains visible',
    () async {
      pending = 1;
      drain = () async {
        pending = 0;
        throw const CloudRevocationUnavailableException();
      };
      controller.resume();
      await controller.idle;
      expect(controller.status.queuedCount, 0);
      expect(controller.status.remoteRevocationUnconfirmed, isTrue);
      expect(scheduler.active, isEmpty);
      controller.resume();
      await controller.idle;
      expect(attempts, 1);
      expect(controller.status.remoteRevocationUnconfirmed, isTrue);
    },
  );

  test('terminal failure still retries other retained proofs', () async {
    pending = 2;
    drain = () async {
      pending = 1;
      throw const CloudRevocationUnavailableException();
    };
    controller.resume();
    await controller.idle;
    expect(controller.status.queuedCount, 1);
    expect(controller.status.remoteRevocationUnconfirmed, isTrue);
    expect(scheduler.active.single.delay, const Duration(seconds: 1));
    drain = () async => pending = 0;
    scheduler.fire();
    await controller.idle;
    expect(attempts, 2);
    expect(controller.status.queuedCount, 0);
    expect(controller.status.remoteRevocationUnconfirmed, isTrue);
    expect(scheduler.active, isEmpty);
  });

  test('an unreadable queue retries without throwing into startup', () async {
    controller.dispose();
    var unreadable = true;
    controller = CloudRevocationRetryController(
      readPendingCount: () async {
        if (unreadable) throw StateError('Encrypted storage unavailable.');
        return 0;
      },
      retryPendingRevocations: () async => ++attempts,
      scheduler: scheduler.schedule,
    );
    controller.resume();
    await controller.idle;
    expect(scheduler.active.single.delay, const Duration(seconds: 5));
    expect(attempts, 0);
    unreadable = false;
    scheduler.fire();
    await controller.idle;
    expect(scheduler.active, isEmpty);
    expect(controller.status.remoteRevocationUnconfirmed, isFalse);
  });
}
