import 'package:av_core/av_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';

/// Commands of the per-app page. Its state is the programs added during
/// this visit, newest first; everything else is the saved settings, and
/// every change is saved at once (PRODUCT_SPEC §3.11).
final appsViewModelProvider =
    NotifierProvider.autoDispose<AppsViewModel, List<String>>(
      AppsViewModel.new,
    );

final class AppsViewModel extends Notifier<List<String>> {
  @override
  List<String> build() => const [];

  Future<void> _change(DeviceSettings Function(DeviceSettings s) edit) =>
      ref.read(settingsRepositoryProvider).updateDevice(edit);

  Future<void> setMode(PerAppMode mode) =>
      _change((s) => s.copyWith(perAppMode: mode));

  Future<void> toggle(String id, {required bool on}) => _change(
    (s) => s.copyWith(
      perAppList: [
        for (final other in s.perAppList)
          if (other != id) other,
        if (on) id,
      ],
    ),
  );

  /// «添加程序» on desktop: picks a program and turns it on. False when
  /// the dialog was cancelled.
  Future<bool> addProgram() async {
    final path = await ref.read(fileDialogsProvider).pickProgram();
    if (path == null || !ref.mounted) return false;
    state = [
      path,
      for (final other in state)
        if (other != path) other,
    ];
    await toggle(path, on: true);
    return true;
  }

  Future<void> enableFindProcess() =>
      _change((s) => s.copyWith(findProcess: true));
}
