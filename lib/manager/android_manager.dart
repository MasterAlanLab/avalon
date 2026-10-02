import 'package:avalon/common/common.dart';
import 'package:avalon/core/core.dart';
import 'package:avalon/enum/enum.dart';
import 'package:avalon/models/models.dart';
import 'package:avalon/plugins/app.dart';
import 'package:avalon/plugins/service.dart';
import 'package:avalon/providers/providers.dart';
import 'package:avalon/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AndroidManager extends ConsumerStatefulWidget {
  final Widget child;

  const AndroidManager({super.key, required this.child});

  @override
  ConsumerState<AndroidManager> createState() => _AndroidContainerState();
}

class _AndroidContainerState extends ConsumerState<AndroidManager>
    with ServiceListener {
  @override
  void initState() {
    super.initState();
    ref.listenManual(appSettingProvider.select((state) => state.hidden), (
      prev,
      next,
    ) {
      app?.updateExcludeFromRecents(next);
    }, fireImmediately: true);
    ref.listenManual(sharedStateProvider, (prev, next) {
      if (prev != next) {
        debouncer.call(FunctionTag.saveSharedFile, () async {
          preferences.saveShareState(next);
        }, duration: const Duration(seconds: 1));
        if (prev?.needSyncSharedState != next.needSyncSharedState) {
          service?.syncState(next.needSyncSharedState).then((error) {
            if (error.isNotEmpty) {
              globalState.showNotifier(currentAppLocalizations.tsCaptureFailed);
            }
          });
        }
      }
    });
    service?.addListener(this);
  }

  @override
  Future<void> dispose() async {
    service?.removeListener(this);
    super.dispose();
  }

  @override
  void onServiceEvent(CoreEvent event) {
    coreEventManager.sendEvent(event);
    super.onServiceEvent(event);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
