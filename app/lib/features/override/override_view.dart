import 'package:av_design/av_design.dart';
import 'package:flutter/widgets.dart';

import '../../app/app_error.dart';
import '../../l10n/app_localizations.dart';
import 'override_state.dart';

/// What an override looks like; shown while the editor is empty.
const _example = '''
{
  "route": {
    "rules": [
      { "domain_suffix": ["example.com"], "outbound": "DIRECT" }
    ]
  }
}''';

/// The JSON override editor: a monospace text area, what is wrong with it
/// when saving refused, and which keys it may contain. Pure.
class OverrideView extends StatelessWidget {
  const OverrideView({
    super.key,
    required this.state,
    required this.controller,
    required this.onCancel,
    required this.onSave,
    this.scrollController,
  });

  final OverrideState state;
  final TextEditingController controller;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  /// The sheet's scroll controller (phones).
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.av;
    final desktop = AvDensity.isDesktop(context);
    final invalid = state.invalid;
    final error = state.error;
    final inset = EdgeInsets.symmetric(horizontal: desktop ? 0 : 16);
    return ColoredBox(
      color: c.bg,
      child: DefaultTextStyle.merge(
        style: AvType.body.copyWith(color: c.l1),
        child: Column(
          children: [
            AvFormHeader(
              title: l.configOverride,
              leading: l.cancel,
              onLeading: onCancel,
              trailing: l.save,
              onTrailing: state.canSave ? onSave : null,
              busy: state.saving,
            ),
            Expanded(
              child: ListView(
                controller: scrollController,
                physics: desktop
                    ? null
                    : const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                padding: desktop
                    ? const EdgeInsets.fromLTRB(20, 0, 20, 24)
                    : EdgeInsets.fromLTRB(
                        0,
                        8,
                        0,
                        40 + MediaQuery.paddingOf(context).bottom,
                      ),
                children: [
                  if (!state.loading)
                    Padding(
                      padding: inset,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 14,
                        ),
                        decoration: BoxDecoration(
                          color: c.cell,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 220),
                          child: AvInput(
                            controller: controller,
                            placeholder: _example,
                            maxLines: null,
                            textAlignVertical: TextAlignVertical.top,
                            keyboardType: TextInputType.multiline,
                            style: AvType.mono(desktop ? 12 : 13, height: 1.45),
                          ),
                        ),
                      ),
                    ),
                  if (invalid != null)
                    AvFormNote(
                      compileErrorText(l, invalid, source: state.text),
                      color: c.bad,
                    ),
                  if (error != null) AvFormNote(error.message(l), color: c.bad),
                  AvFormNote('${l.overrideNote}${l.overrideKeysNote}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
