import 'dart:async';

import 'package:av_core/av_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/import_service.dart';
import 'app_error.dart';
import 'background.dart';
import 'log.dart';
import 'providers.dart';

/// Keeps subscriptions up to date (CONFIG_PIPELINE §2): what the
/// configurations page asks for, and automatic updates every 12 hours for
/// those that have them on (PRODUCT_SPEC §3.2). Its state is the
/// subscriptions being downloaded now, by id; one download per
/// subscription at a time, whoever asked.
final subscriptionUpdaterProvider =
    NotifierProvider<SubscriptionUpdater, Set<String>>(SubscriptionUpdater.new);

/// How often automatic updates look for something due.
final subscriptionCheckIntervalProvider = Provider<Duration>(
  (ref) => const Duration(hours: 1),
);

final class SubscriptionUpdater extends Notifier<Set<String>> {
  /// How old a subscription may get before it is downloaded again.
  static const interval = Duration(hours: 12);
  static const initialRetryInterval = Duration(hours: 1);

  final _background = Background();
  Timer? _timer;

  @override
  Set<String> build() {
    final every = ref.read(subscriptionCheckIntervalProvider);
    _timer = Timer.periodic(
      every,
      (_) => _background.run('subscriptions: scheduled update', updateDue),
    );
    // What fell due while the app was closed.
    _background.run('subscriptions: update at launch', updateDue);
    ref.listen(configurationsProvider, (_, next) {
      if (next.value?.any(
            (c) =>
                c.kind == ConfigurationKind.subscription &&
                c.lastSuccessAt == null,
          ) ??
          false) {
        _background.run('subscriptions: first Cloud download', updateDue);
      }
    });
    ref.onDispose(() => _timer?.cancel());
    return const {};
  }

  /// Completes once work started in the background is done (tests wait
  /// for it before closing the database).
  Future<void> idle() => _background.done();

  /// Downloads and replaces one subscription; a failure keeps the previous
  /// content and is recorded on its card. Asked again while it runs, it
  /// does not start a second download.
  Future<Result<RefreshOutcome>> refresh(String id) async {
    if (state.contains(id)) return const Ok(RefreshOutcome.unchanged);
    state = {...state, id};
    try {
      return await attempt(() => ref.read(importServiceProvider).refresh(id));
    } finally {
      if (ref.mounted) state = {...state}..remove(id);
    }
  }

  /// Downloads, one after another, the subscriptions with automatic
  /// updates whose last success is older than [interval]. One that failed
  /// is tried again at the next check.
  Future<void> updateDue({DateTime? now}) async {
    final at = (now ?? DateTime.now()).toUtc();
    final all = await ref
        .read(configurationRepositoryProvider)
        .watchAll()
        .first;
    final due = <String>[];
    for (final c in all) {
      if (c.kind != ConfigurationKind.subscription) continue;
      final firstCloudDownload =
          c.lastSuccessAt == null &&
          await ref.read(configurationRepositoryProvider).isCloudOrigin(c.id);
      if (firstCloudDownload) {
        final attempt = c.lastAttemptAt;
        if (attempt == null || at.difference(attempt) >= initialRetryInterval) {
          due.add(c.id);
        }
      } else if (c.autoUpdate &&
          (c.lastSuccessAt == null ||
              at.difference(c.lastSuccessAt!) >= interval)) {
        due.add(c.id);
      }
    }
    for (final id in due) {
      if (!ref.mounted) return;
      final result = await refresh(id);
      if (result case Err(:final error)) {
        Log.warn('subscription $id: ${error.code}');
      }
    }
  }
}
