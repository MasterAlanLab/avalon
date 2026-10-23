import 'package:av_core/av_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_error.dart';
import '../../app/providers.dart';
import 'override_state.dart';

final overrideViewModelProvider =
    NotifierProvider.autoDispose<OverrideViewModel, OverrideState>(
      OverrideViewModel.new,
    );

class OverrideViewModel extends Notifier<OverrideState> {
  @override
  OverrideState build() => const OverrideState();

  /// Reads the saved override into the editor.
  Future<void> load() async {
    final policy = await attempt(
      () => ref.read(settingsRepositoryProvider).policy(),
    );
    if (!ref.mounted) return;
    state = switch (policy) {
      Ok(:final value) => OverrideState(
        loading: false,
        text: value.jsonOverride?.value ?? '',
        saved: value.jsonOverride?.value ?? '',
      ),
      Err(:final error) => OverrideState(loading: false, error: error),
    };
  }

  void setText(String text) {
    if (text == state.text) return;
    state = state.copyWith(text: text, invalid: () => null, error: () => null);
  }

  /// Checks the text (syntax, allowed keys, types, and the names it uses
  /// against the selected configuration), then saves it. False when it is
  /// not valid (see [OverrideState.invalid]) or saving failed.
  Future<bool> save() async {
    if (!state.canSave) return false;
    final text = state.text;
    state = state.copyWith(
      saving: true,
      invalid: () => null,
      error: () => null,
    );
    final plans = ref.read(planServiceProvider);
    final settings = ref.read(settingsRepositoryProvider);
    try {
      await plans.checkOverride(text);
    } on CompileException catch (e) {
      if (ref.mounted) state = state.copyWith(saving: false, invalid: () => e);
      return false;
    }
    final result = await attempt(
      () => settings.updatePolicy(
        (p) => p.copyWith(
          // The whole text is a secret (CONFIG_PIPELINE §5); empty clears it.
          jsonOverride: text.trim().isEmpty ? null : Secret(text),
        ),
      ),
    );
    if (!ref.mounted) return false;
    switch (result) {
      case Ok():
        state = state.copyWith(saving: false, saved: text);
        return true;
      case Err(:final error):
        state = state.copyWith(saving: false, error: () => error);
        return false;
    }
  }
}
