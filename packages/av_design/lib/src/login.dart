import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import 'brand.dart';
import 'density.dart';
import 'desktop.dart';
import 'icon.dart';
import 'pressable.dart';
import 'scaffolds.dart';
import 'theme.dart';
import 'tokens.dart';

/// The focused, two-step email sign-in layout approved in D115.
/// Controllers and account operations belong to the application.
class AvLoginForm extends StatefulWidget {
  const AvLoginForm({
    super.key,
    required this.title,
    required this.subtitle,
    required this.emailLabel,
    required this.emailPlaceholder,
    required this.codeLabel,
    required this.submitLabel,
    required this.helper,
    required this.emailController,
    required this.codeController,
    required this.showCode,
    required this.submitEnabled,
    required this.busy,
    required this.onSubmit,
    required this.onChanged,
    this.recipient,
    this.error,
    this.clearEmailLabel,
    this.resendLabel,
    this.onResend,
    this.changeEmailLabel,
    this.onChangeEmail,
    this.logoutLabel,
    this.onLogout,
    this.emailKey,
    this.codeKey,
    this.submitKey,
    this.resendKey,
    this.logoutKey,
  });

  final String title;
  final String subtitle;
  final String emailLabel;
  final String emailPlaceholder;
  final String codeLabel;
  final String submitLabel;
  final String helper;
  final TextEditingController emailController;
  final TextEditingController codeController;
  final bool showCode;
  final bool submitEnabled;
  final bool busy;
  final VoidCallback onSubmit;
  final VoidCallback onChanged;
  final String? recipient;
  final String? error;
  final String? clearEmailLabel;
  final String? resendLabel;
  final VoidCallback? onResend;
  final String? changeEmailLabel;
  final VoidCallback? onChangeEmail;
  final String? logoutLabel;
  final VoidCallback? onLogout;
  final Key? emailKey;
  final Key? codeKey;
  final Key? submitKey;
  final Key? resendKey;
  final Key? logoutKey;

  @override
  State<AvLoginForm> createState() => _AvLoginFormState();
}

class _AvLoginFormState extends State<AvLoginForm> {
  final _emailFocus = FocusNode();
  final _codeFocus = FocusNode();
  int? _codeTapIndex;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(_focusChanged);
    _codeFocus.addListener(_focusChanged);
  }

  void _focusChanged() => setState(() {});

  @override
  void didUpdateWidget(AvLoginForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showCode != oldWidget.showCode) {
      // Only a completed step change summons the keyboard. Merely opening
      // this page, or refreshing an error, leaves focus with the user.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          (widget.showCode ? _codeFocus : _emailFocus).requestFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  void _submit() {
    if (widget.submitEnabled && !widget.busy) widget.onSubmit();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    final error = widget.error;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 444),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(27, 32, 27, 20),
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: AvBrandMark.avalon(size: 55),
                ),
                const SizedBox(height: 26),
                Semantics(
                  header: true,
                  child: Text(
                    widget.title,
                    style: AvType.title1.copyWith(color: c.l1, height: 1.25),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.subtitle,
                  style: AvType.callout.copyWith(color: c.l2, height: 1.65),
                ),
                if (widget.showCode && widget.recipient != null)
                  Semantics(
                    label: widget.recipient,
                    excludeSemantics: true,
                    child: Text(
                      AvType.breakAll(widget.recipient!),
                      style: AvType.calloutStrong.copyWith(
                        color: c.l1,
                        height: 1.65,
                      ),
                    ),
                  ),
                const SizedBox(height: 34),
                Text(
                  widget.showCode ? widget.codeLabel : widget.emailLabel,
                  style: AvType.footnoteStrong.copyWith(color: c.l1),
                ),
                const SizedBox(height: 10),
                if (widget.showCode) _code(context) else _email(context),
                const SizedBox(height: 18),
                _submitButton(context),
                const SizedBox(height: 16),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    error ?? widget.helper,
                    style: AvType.caption.copyWith(
                      color: error == null ? c.l2 : c.bad,
                      height: 1.7,
                    ),
                  ),
                ),
                if (widget.showCode || widget.logoutLabel != null) ...[
                  const SizedBox(height: 22),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 15,
                    runSpacing: 0,
                    children: [
                      if (widget.showCode && widget.resendLabel != null)
                        _secondary(
                          context,
                          widget.resendLabel!,
                          widget.onResend,
                          key: widget.resendKey,
                        ),
                      if (widget.showCode && widget.changeEmailLabel != null)
                        _secondary(
                          context,
                          widget.changeEmailLabel!,
                          widget.onChangeEmail,
                        ),
                      if (widget.logoutLabel != null)
                        _secondary(
                          context,
                          widget.logoutLabel!,
                          widget.onLogout,
                          key: widget.logoutKey,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _email(BuildContext context) {
    final c = context.av;
    final focused = _emailFocus.hasFocus;
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.emailController,
      builder: (context, value, _) => Container(
        key: widget.emailKey,
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(
          color: c.isDark ? c.fill : c.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: focused ? c.tint : c.tint.withValues(alpha: 0),
          ),
          boxShadow: focused ? AvShadows.ring(c.tintBg) : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            AvIcon(Symbols.mail_rounded, size: 20, color: c.l2, fill: 0),
            const SizedBox(width: 12),
            Expanded(
              child: Semantics(
                label: widget.emailLabel,
                child: CupertinoTextField.borderless(
                  controller: widget.emailController,
                  focusNode: _emailFocus,
                  readOnly: widget.busy,
                  showCursor: !widget.busy,
                  padding: EdgeInsets.zero,
                  placeholder: widget.emailPlaceholder,
                  placeholderStyle: AvType.input.copyWith(color: c.l3),
                  style: AvType.input.copyWith(color: c.l1, height: 1.35),
                  cursorColor: c.tint,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  enableSuggestions: false,
                  smartQuotesType: SmartQuotesType.disabled,
                  smartDashesType: SmartDashesType.disabled,
                  onChanged: (_) => widget.onChanged(),
                  onEditingComplete: () {},
                  onSubmitted: (_) => _submit(),
                ),
              ),
            ),
            if (value.text.isNotEmpty && widget.clearEmailLabel != null) ...[
              const SizedBox(width: 8),
              Semantics(
                button: true,
                enabled: !widget.busy,
                label: widget.clearEmailLabel,
                child: AvPressable(
                  onTap: widget.busy
                      ? null
                      : () {
                          widget.emailController.clear();
                          widget.onChanged();
                          _emailFocus.requestFocus();
                        },
                  pressedOpacity: 0.4,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: AvIcon(
                      Symbols.cancel_rounded,
                      size: 19,
                      color: c.l2,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _code(BuildContext context) {
    final c = context.av;
    final height = math.max(
      58.0,
      MediaQuery.textScalerOf(context).scale(27) * 1.25 + 20,
    );
    return SizedBox(
      key: widget.codeKey,
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          fit: StackFit.expand,
          children: [
            ExcludeSemantics(
              child: ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.codeController,
                builder: (context, value, _) {
                  final active = math.min(
                    value.selection.isValid
                        ? value.selection.start
                        : value.text.length,
                    5,
                  );
                  return Row(
                    children: [
                      for (var i = 0; i < 6; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: c.isDark ? c.fill : c.cell,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _codeFocus.hasFocus && active == i
                                    ? c.tint
                                    : c.sep,
                              ),
                              boxShadow: _codeFocus.hasFocus && active == i
                                  ? AvShadows.ring(c.tintBg)
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: i < value.text.length
                                ? Text(
                                    value.text[i],
                                    style: AvType.numeric(
                                      27,
                                    ).copyWith(color: c.l1),
                                  )
                                : _codeFocus.hasFocus && active == i
                                ? SizedBox(
                                    width: 2,
                                    height: 24,
                                    child: ColoredBox(color: c.tint),
                                  )
                                : null,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            DefaultSelectionStyle(
              // The visible boxes render the selected digit; the single
              // editable field retains native paste and AutoFill behavior.
              selectionColor: c.tint.withValues(alpha: 0),
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (event) {
                  _codeTapIndex =
                      (event.localPosition.dx /
                              ((constraints.maxWidth + 8) / 6))
                          .floor()
                          .clamp(0, 5);
                },
                child: Semantics(
                  label: widget.codeLabel,
                  child: CupertinoTextField.borderless(
                    controller: widget.codeController,
                    focusNode: _codeFocus,
                    readOnly: widget.busy,
                    padding: EdgeInsets.zero,
                    style: AvType.numeric(
                      27,
                    ).copyWith(color: c.l1.withValues(alpha: 0)),
                    showCursor: false,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    autocorrect: false,
                    enableSuggestions: false,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _WholeCodePasteFormatter(),
                      LengthLimitingTextInputFormatter(6),
                    ],
                    onChanged: (_) => widget.onChanged(),
                    onEditingComplete: () {},
                    onSubmitted: (_) => _submit(),
                    onTap: () {
                      final index = _codeTapIndex;
                      _codeTapIndex = null;
                      if (index == null || widget.busy) return;
                      final length = widget.codeController.text.length;
                      widget.codeController.selection = TextSelection(
                        baseOffset: math.min(index, length),
                        extentOffset: math.min(index + 1, length),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _submitButton(BuildContext context) {
    final c = context.av;
    final enabled = widget.submitEnabled && !widget.busy;
    return Semantics(
      key: widget.submitKey,
      button: true,
      enabled: enabled,
      child: AvPressable(
        onTap: enabled ? _submit : null,
        pressedOpacity: 0.75,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: enabled || widget.busy ? c.tint : c.fill,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                widget.submitLabel,
                textAlign: TextAlign.center,
                style: AvType.s(16, weight: FontWeight.w600).copyWith(
                  color: enabled || widget.busy ? AvColors.light.cell : c.l3,
                ),
              ),
              if (widget.busy)
                Align(
                  alignment: Alignment.centerLeft,
                  child: CupertinoActivityIndicator(color: AvColors.light.cell),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _secondary(
    BuildContext context,
    String label,
    VoidCallback? onTap, {
    Key? key,
  }) {
    final enabled = !widget.busy && onTap != null;
    return Semantics(
      key: key,
      button: true,
      enabled: enabled,
      child: AvPressable(
        onTap: enabled ? onTap : null,
        pressedOpacity: 0.4,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
            child: Text(
              label,
              style: AvType.footnote.copyWith(
                color: enabled ? context.av.tint : context.av.l3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A complete pasted code replaces the code even after tapping one digit.
/// Ordinary edits continue to use the real field's selection and deletion.
class _WholeCodePasteFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final selection = oldValue.selection;
    if (!selection.isValid) return newValue;
    final before = selection.textBefore(oldValue.text);
    final after = selection.textAfter(oldValue.text);
    if (!newValue.text.startsWith(before) || !newValue.text.endsWith(after)) {
      return newValue;
    }
    final end = newValue.text.length - after.length;
    if (end - before.length != 6) return newValue;
    final code = newValue.text.substring(before.length, end);
    return TextEditingValue(
      text: code,
      selection: const TextSelection.collapsed(offset: 6),
    );
  }
}

/// Sign-in uses a plain surface rather than the account settings groups.
/// Notices stay above the form, and scrolling reserves keyboard space.
class AvLoginPage extends StatelessWidget {
  const AvLoginPage({
    super.key,
    required this.backLabel,
    required this.form,
    this.notices,
    this.tabBar = true,
  });

  final String backLabel;
  final Widget form;
  final Widget? notices;
  final bool tabBar;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [?notices, form],
    );
    return ColoredBox(
      color: c.cell,
      child: AvDensity.isDesktop(context)
          ? AvDesktopPage(maxWidth: 444, child: content)
          : Column(
              children: [
                SizedBox(height: MediaQuery.paddingOf(context).top),
                Container(
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      AvPressable(
                        onTap: () => Navigator.of(context).maybePop(),
                        pressedOpacity: 0.4,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AvIcon(
                              Symbols.chevron_left_rounded,
                              size: 28,
                              color: c.tint,
                            ),
                            Text(
                              backLabel,
                              style: AvType.s(16).copyWith(color: c.tint),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.only(
                      bottom: math.max(
                        avTabBarClearance(context, tabBar: tabBar),
                        MediaQuery.viewInsetsOf(context).bottom + 24,
                      ),
                    ),
                    children: [content],
                  ),
                ),
              ],
            ),
    );
  }
}
