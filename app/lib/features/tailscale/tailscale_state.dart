import 'package:av_core/av_core.dart';
import 'package:flutter/foundation.dart';

import '../../runtime/host_protocol.dart';
import '../../runtime/runtime_state.dart';

@immutable
final class TailscaleState {
  const TailscaleState({
    this.settings = const TailnetSettings(),
    this.status = const HostTailnetStatus(),
    this.available = true,
    this.busy = false,
    this.error,
    this.runtimeFailure,
    this.browserFailed = false,
  });

  final TailnetSettings settings;
  final HostTailnetStatus status;
  final bool available, busy, browserFailed;
  final String? error;
  final RuntimeFailure? runtimeFailure;

  TailscaleState copyWith({
    TailnetSettings? settings,
    HostTailnetStatus? status,
    bool? busy,
    String? Function()? error,
    RuntimeFailure? Function()? runtimeFailure,
    bool? browserFailed,
  }) => TailscaleState(
    settings: settings ?? this.settings,
    status: status ?? this.status,
    available: available,
    busy: busy ?? this.busy,
    error: error == null ? this.error : error(),
    runtimeFailure: runtimeFailure == null
        ? this.runtimeFailure
        : runtimeFailure(),
    browserFailed: browserFailed ?? this.browserFailed,
  );
}
