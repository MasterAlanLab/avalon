import 'dart:async';

import 'package:flutter/cupertino.dart';

import 'tokens.dart';

/// A confirmation alert in the iOS style V3 follows. Resolves to true when
/// confirmed.
Future<bool> showAvConfirm(
  BuildContext context, {
  required String title,
  String? message,
  required String confirm,
  required String cancel,
  bool destructive = false,
}) async {
  final result = await showCupertinoDialog<bool>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(title),
      content: message == null ? null : Text(message),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancel),
        ),
        CupertinoDialogAction(
          isDestructiveAction: destructive,
          isDefaultAction: !destructive,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirm),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// A one-button alert for something the user only needs to read.
Future<void> showAvNotice(
  BuildContext context, {
  required String title,
  String? message,
  required String ok,
}) => showCupertinoDialog<void>(
  context: context,
  builder: (context) => CupertinoAlertDialog(
    title: Text(title),
    content: message == null ? null : Text(message),
    actions: [
      CupertinoDialogAction(
        isDefaultAction: true,
        onPressed: () => Navigator.of(context).pop(),
        child: Text(ok),
      ),
    ],
  ),
);

final class AvAction {
  const AvAction(this.label, {this.destructive = false});

  final String label;
  final bool destructive;
}

/// An action sheet (the long-press / right-click menu of PRODUCT_SPEC
/// §3.4). Resolves to the chosen index, or null when cancelled.
Future<int?> showAvActions(
  BuildContext context, {
  required List<AvAction> actions,
  required String cancel,
  String? title,
}) => showCupertinoModalPopup<int>(
  context: context,
  builder: (context) => CupertinoActionSheet(
    title: title == null ? null : Text(title),
    actions: [
      for (final (i, a) in actions.indexed)
        CupertinoActionSheetAction(
          isDestructiveAction: a.destructive,
          onPressed: () => Navigator.of(context).pop(i),
          child: Text(a.label),
        ),
    ],
    cancelButton: CupertinoActionSheetAction(
      onPressed: () => Navigator.of(context).pop(),
      child: Text(cancel),
    ),
  ),
);

/// Asks for one line of text (editing a port, an address…). [validate]
/// returns what is wrong with the value, shown under the field, or null to
/// accept it. Resolves to the accepted text, or null when cancelled.
Future<String?> showAvPrompt(
  BuildContext context, {
  required String title,
  String? message,
  String initial = '',
  String? placeholder,
  required String save,
  required String cancel,
  TextInputType? keyboardType,
  String? Function(String value)? validate,
}) => showCupertinoDialog<String>(
  context: context,
  builder: (context) => _Prompt(
    title: title,
    message: message,
    initial: initial,
    placeholder: placeholder,
    save: save,
    cancel: cancel,
    keyboardType: keyboardType,
    validate: validate == null ? null : (value, _) => validate(value),
  ),
);

/// Asks for a password, hidden as it is typed. With [confirmPlaceholder] a
/// second field asks for it again; [validate] gets both (the second is
/// null without that field). Resolves to the password, or null when
/// cancelled.
Future<String?> showAvPasswordPrompt(
  BuildContext context, {
  required String title,
  String? message,
  String? placeholder,
  String? confirmPlaceholder,
  required String save,
  required String cancel,
  String? Function(String password, String? again)? validate,
}) => showCupertinoDialog<String>(
  context: context,
  builder: (context) => _Prompt(
    title: title,
    message: message,
    initial: '',
    placeholder: placeholder,
    confirmPlaceholder: confirmPlaceholder,
    obscure: true,
    save: save,
    cancel: cancel,
    keyboardType: TextInputType.visiblePassword,
    validate: validate,
  ),
);

class _Prompt extends StatefulWidget {
  const _Prompt({
    required this.title,
    required this.message,
    required this.initial,
    required this.placeholder,
    required this.save,
    required this.cancel,
    required this.keyboardType,
    required this.validate,
    this.confirmPlaceholder,
    this.obscure = false,
  });

  final String title;
  final String? message;
  final String initial;
  final String? placeholder;

  /// Shows a second field with this placeholder.
  final String? confirmPlaceholder;
  final bool obscure;
  final String save;
  final String cancel;
  final TextInputType? keyboardType;
  final String? Function(String value, String? again)? validate;

  @override
  State<_Prompt> createState() => _PromptState();
}

class _PromptState extends State<_Prompt> {
  late final _text = TextEditingController(text: widget.initial)
    ..selection = TextSelection(
      baseOffset: 0,
      extentOffset: widget.initial.length,
    );
  final _again = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    _again.dispose();
    super.dispose();
  }

  void _submit() {
    final error = widget.validate?.call(
      _text.text,
      widget.confirmPlaceholder == null ? null : _again.text,
    );
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(_text.text);
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final error = _error;
    return CupertinoAlertDialog(
      title: Text(widget.title),
      content: Column(
        children: [
          if (message != null) Text(message),
          const SizedBox(height: 12),
          CupertinoTextField(
            controller: _text,
            autofocus: true,
            placeholder: widget.placeholder,
            keyboardType: widget.keyboardType,
            obscureText: widget.obscure,
            autocorrect: false,
            enableSuggestions: false,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) {
              if (widget.confirmPlaceholder == null) _submit();
            },
          ),
          if (widget.confirmPlaceholder != null) ...[
            const SizedBox(height: 8),
            CupertinoTextField(
              controller: _again,
              placeholder: widget.confirmPlaceholder,
              keyboardType: widget.keyboardType,
              obscureText: widget.obscure,
              autocorrect: false,
              enableSuggestions: false,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _submit(),
            ),
          ],
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                error,
                style: const TextStyle(
                  color: CupertinoColors.systemRed,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(widget.cancel),
        ),
        CupertinoDialogAction(
          isDefaultAction: true,
          onPressed: _submit,
          child: Text(widget.save),
        ),
      ],
    );
  }
}

OverlayEntry? _toast;

/// A short line that appears above the tab bar and fades away by itself,
/// for feedback that needs no answer (PRODUCT_SPEC §8). A new toast
/// replaces the one showing.
void showAvToast(
  BuildContext context,
  String text, {
  Duration duration = const Duration(milliseconds: 1800),
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  _toast?.remove();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _Toast(
      text: text,
      duration: duration,
      onDone: () {
        if (_toast == entry) {
          entry.remove();
          _toast = null;
        }
      },
    ),
  );
  _toast = entry;
  overlay.insert(entry);
}

class _Toast extends StatefulWidget {
  const _Toast({
    required this.text,
    required this.duration,
    required this.onDone,
  });

  final String text;
  final Duration duration;
  final VoidCallback onDone;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  Timer? _hold;

  @override
  void initState() {
    super.initState();
    unawaited(_fade.forward());
    _hold = Timer(widget.duration, () async {
      await _fade.reverse();
      widget.onDone();
    });
  }

  @override
  void dispose() {
    _hold?.cancel();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 24,
      right: 24,
      bottom: MediaQuery.paddingOf(context).bottom + 110,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
              decoration: BoxDecoration(
                color: const Color(0xD9333333),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.text,
                textAlign: TextAlign.center,
                style: AvType.subheadStrong.copyWith(
                  color: const Color(0xFFFFFFFF),
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
