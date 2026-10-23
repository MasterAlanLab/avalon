import 'package:av_design/av_design.dart';
import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';
import '../runtime/latency.dart';

/// A latency as pages word and colour it (PRODUCT_SPEC §3.2): under
/// 150 ms green, under 300 ms orange, otherwise red; «超时» and «失败» in
/// red; «···» while testing; «—» when never tested. A result from a
/// session that has ended is grey.
({String text, Color color}) latencyLabel(
  AppLocalizations l,
  AvColors c,
  Latency? latency,
) {
  if (latency == null) return (text: '—', color: c.l3);
  Color fresh(Color color) => latency.stale ? c.l3 : color;
  final ms = latency.ms ?? 0;
  return switch (latency.status) {
    LatencyStatus.testing => (text: '···', color: c.l3),
    LatencyStatus.timedOut => (text: l.latencyTimeout, color: fresh(c.bad)),
    LatencyStatus.failed => (text: l.latencyFailed, color: fresh(c.bad)),
    LatencyStatus.measured => (
      text: '$ms ms',
      color: fresh(
        ms < 150
            ? c.ok
            : ms < 300
            ? c.warn
            : c.bad,
      ),
    ),
  };
}
