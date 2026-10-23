import 'package:av_design/av_design.dart';
import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';

/// The compiled configuration, read-only (PRODUCT_SPEC §3.10): the text
/// with secrets masked, or why there is none. Pure.
class GeneratedView extends StatelessWidget {
  const GeneratedView({
    super.key,
    required this.text,
    required this.message,
    required this.onDone,
    required this.onCopy,
    this.scrollController,
  });

  /// The configuration as indented JSON; null while compiling or when it
  /// could not be compiled.
  final String? text;

  /// Why there is no text; null while compiling.
  final String? message;
  final VoidCallback onDone;
  final VoidCallback onCopy;

  /// The sheet's scroll controller (phones).
  final ScrollController? scrollController;

  /// Lines per text block: a long configuration is laid out a block at a
  /// time as it scrolls into view.
  static const _block = 120;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.av;
    final desktop = AvDensity.isDesktop(context);
    final text = this.text;
    final message = this.message;
    final lines = text?.split('\n') ?? const <String>[];
    final blocks = (lines.length / _block).ceil();
    final side = desktop ? 20.0 : 16.0;
    final mono = AvType.mono(desktop ? 12 : 12.5, height: 1.45);

    return ColoredBox(
      color: c.bg,
      child: DefaultTextStyle.merge(
        style: AvType.body.copyWith(color: c.l1),
        child: Column(
          children: [
            AvFormHeader(
              title: l.generatedConfig,
              leading: l.done,
              onLeading: onDone,
              trailing: l.copyAll,
              onTrailing: text == null ? null : onCopy,
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                physics: desktop
                    ? null
                    : const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                padding: EdgeInsets.fromLTRB(
                  0,
                  desktop ? 0 : 8,
                  0,
                  24 + MediaQuery.paddingOf(context).bottom,
                ),
                // The note, then the text blocks (or the message).
                itemCount: text == null ? 1 : blocks + 1,
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        desktop ? side : 0,
                        0,
                        desktop ? side : 0,
                        desktop ? 12 : 4,
                      ),
                      child: text != null
                          ? Padding(
                              padding: EdgeInsets.only(bottom: desktop ? 0 : 8),
                              child: desktop
                                  ? Text(
                                      l.generatedNote,
                                      style: AvType.caption.copyWith(
                                        color: c.l2,
                                      ),
                                    )
                                  : AvSectionFooter(l.generatedNote),
                            )
                          : message == null
                          ? const SizedBox.shrink()
                          : Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: desktop ? 0 : 16,
                              ),
                              child: AvBanner(title: message),
                            ),
                    );
                  }
                  final b = i - 1;
                  final first = b == 0;
                  final last = b == blocks - 1;
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: side),
                    child: Container(
                      padding: EdgeInsets.fromLTRB(
                        14,
                        first ? 12 : 0,
                        14,
                        last ? 12 : 0,
                      ),
                      decoration: BoxDecoration(
                        color: c.cell,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(first ? 12 : 0),
                          bottom: Radius.circular(last ? 12 : 0),
                        ),
                      ),
                      child: Text(
                        lines.skip(b * _block).take(_block).join('\n'),
                        style: mono.copyWith(color: c.l1),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
