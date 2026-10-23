import 'package:av_core/av_core.dart';

import '../../app/app_error.dart';

/// State of the JSON override editor (PRODUCT_SPEC §3.10, D19).
final class OverrideState {
  const OverrideState({
    this.loading = true,
    this.text = '',
    this.saved = '',
    this.saving = false,
    this.invalid,
    this.error,
  });

  /// The saved override is being read.
  final bool loading;

  /// What the editor holds.
  final String text;

  /// What is saved; saving is offered once [text] differs.
  final String saved;
  final bool saving;

  /// What is wrong with [text], found when saving.
  final CompileException? invalid;

  /// Reading or writing failed.
  final AppError? error;

  bool get canSave => !loading && !saving && text != saved;

  OverrideState copyWith({
    bool? loading,
    String? text,
    String? saved,
    bool? saving,
    CompileException? Function()? invalid,
    AppError? Function()? error,
  }) => OverrideState(
    loading: loading ?? this.loading,
    text: text ?? this.text,
    saved: saved ?? this.saved,
    saving: saving ?? this.saving,
    invalid: invalid == null ? this.invalid : invalid(),
    error: error == null ? this.error : error(),
  );
}
