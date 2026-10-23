import 'package:flutter/cupertino.dart';

import 'density.dart';
import 'list.dart';
import 'theme.dart';
import 'tokens.dart';

/// Borderless text input styled like V3 `<input>`: no chrome, `--l3`
/// placeholder, tint caret.
class AvInput extends StatelessWidget {
  const AvInput({
    super.key,
    this.controller,
    this.placeholder,
    this.textAlign = TextAlign.start,
    this.style,
    this.maxLines = 1,
    this.minLines,
    this.textAlignVertical,
    this.onChanged,
    this.keyboardType,
    this.obscure = false,
  });

  final TextEditingController? controller;
  final String? placeholder;
  final TextAlign textAlign;
  final TextStyle? style;
  final int? maxLines;
  final int? minLines;

  /// Multi-line fields taller than their text (V3 `<textarea>`) pass
  /// [TextAlignVertical.top].
  final TextAlignVertical? textAlignVertical;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final bool obscure;

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    final base = style ?? AvType.body;
    final ambient = DefaultTextStyle.of(context).style;
    // Text fields style through CupertinoTheme, not DefaultTextStyle; take
    // an ambient family the way Text does (the app sets none, D62).
    final s = base.copyWith(
      color: c.l1,
      fontFamily: base.fontFamily ?? ambient.fontFamily,
      fontFamilyFallback: base.fontFamilyFallback ?? ambient.fontFamilyFallback,
    );
    return CupertinoTextField.borderless(
      controller: controller,
      placeholder: placeholder,
      placeholderStyle: s.copyWith(color: c.l3),
      style: s,
      textAlign: textAlign,
      padding: EdgeInsets.zero,
      maxLines: maxLines,
      minLines: minLines,
      textAlignVertical: textAlignVertical,
      onChanged: onChanged,
      keyboardType: keyboardType,
      // Addresses, keys and JSON are typed here: the keyboard must not
      // "correct" them or swap in typographic quotes and dashes.
      autocorrect: false,
      enableSuggestions: false,
      smartQuotesType: SmartQuotesType.disabled,
      smartDashesType: SmartDashesType.disabled,
      obscureText: obscure,
      cursorColor: c.tint,
    );
  }
}

/// Form row: label left, right-aligned input
/// (`min-height:44px; padding:0 16px; gap:12px`).
class AvFieldRow extends StatefulWidget {
  const AvFieldRow({
    super.key,
    required this.label,
    this.placeholder,
    this.controller,
    this.initialValue,
    this.mono = false,
    this.inputSize,
  });

  final String label;
  final String? placeholder;
  final TextEditingController? controller;
  final String? initialValue;
  final bool mono;

  /// Defaults to 16 (touch) or 13 (desktop), as in V3.
  final double? inputSize;

  @override
  State<AvFieldRow> createState() => _AvFieldRowState();
}

class _AvFieldRowState extends State<AvFieldRow> {
  late final TextEditingController _own = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _own.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.av;
    final last = AvRowPosition.isLast(context);
    final desktop = AvDensity.isDesktop(context);
    final size = widget.inputSize ?? (desktop ? 13.0 : 16.0);
    return Container(
      constraints: BoxConstraints(
        minHeight: (desktop ? 40 : 44) + (last ? 0 : AvBorder.hairline),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: c.sep, width: 0.5)),
      ),
      child: Row(
        children: [
          Text(
            widget.label,
            style: (desktop ? AvType.s(14) : AvType.body).copyWith(color: c.l1),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AvInput(
              controller: widget.controller ?? _own,
              placeholder: widget.placeholder,
              textAlign: TextAlign.right,
              style: widget.mono ? AvType.mono(size) : AvType.s(size),
            ),
          ),
        ],
      ),
    );
  }
}

/// Search field: 36 high, radius 10, `--fill`, 20 px search glyph.
class AvSearchField extends StatelessWidget {
  const AvSearchField({
    super.key,
    required this.icon,
    this.placeholder = '搜索',
    this.onChanged,
  });

  final Widget icon;
  final String placeholder;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: context.av.fill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 6),
          Expanded(
            child: AvInput(placeholder: placeholder, onChanged: onChanged),
          ),
        ],
      ),
    );
  }
}
