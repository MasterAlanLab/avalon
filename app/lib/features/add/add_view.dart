import 'package:av_core/av_core.dart';
import 'package:av_design/av_design.dart';
import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import 'add_state.dart';
import 'chain_options.dart';
import 'widgets/chain_form.dart';
import 'widgets/node_form.dart';
import 'widgets/subscription_form.dart';

/// The add form (V3 3d–3f; desktop dialog 3p): header, segments and the
/// form of the chosen segment. Pure: it draws [state] and reports edits.
class AddView extends StatelessWidget {
  const AddView({
    super.key,
    required this.state,
    required this.urlController,
    required this.nameController,
    required this.onCancel,
    required this.onSave,
    required this.onSegment,
    required this.onAutoUpdate,
    required this.onMethod,
    required this.onPickFile,
    required this.onClearFile,
    required this.linkController,
    required this.nodeController,
    required this.onParseLink,
    required this.onProtocol,
    required this.onTransport,
    required this.onSecurity,
    required this.chainOptions,
    required this.chainNameController,
    required this.onToggleHopPicker,
    required this.onAddHop,
    required this.onRemoveHop,
    required this.onMoveHop,
    required this.onToggleChainGroup,
    this.scanAvailable = false,
    this.scanner,
    this.scrollController,
  });

  final AddState state;
  final TextEditingController urlController;
  final TextEditingController nameController;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final ValueChanged<AddSegment> onSegment;
  final ValueChanged<bool> onAutoUpdate;
  final ValueChanged<SubscriptionMethod> onMethod;
  final VoidCallback onPickFile;
  final VoidCallback onClearFile;

  /// Phones with a camera offer «扫描二维码».
  final bool scanAvailable;

  /// The camera view while scanning.
  final Widget? scanner;

  // 独立节点
  final TextEditingController linkController;
  final TextEditingController Function(NodeField field) nodeController;
  final VoidCallback onParseLink;
  final ValueChanged<Protocol> onProtocol;
  final ValueChanged<TransportKind> onTransport;
  final ValueChanged<NodeSecurity> onSecurity;

  // 代理链
  final ChainOptions chainOptions;
  final TextEditingController chainNameController;
  final VoidCallback onToggleHopPicker;
  final ValueChanged<MemberRef> onAddHop;
  final ValueChanged<int> onRemoveHop;
  final void Function(int index, int delta) onMoveHop;
  final ValueChanged<String> onToggleChainGroup;

  /// The sheet's scroll controller (phones).
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.av;
    final desktop = AvDensity.isDesktop(context);

    final segments = AvSegmented<AddSegment>(
      values: AddSegment.values,
      labelOf: (s) => switch (s) {
        AddSegment.subscription => l.addSegmentSubscription,
        AddSegment.node => l.addSegmentNode,
        AddSegment.chain => l.addSegmentChain,
      },
      selected: state.segment,
      height: desktop ? 34 : null,
      fontSize: desktop ? 13 : null,
      onChanged: onSegment,
    );

    final form = switch (state.segment) {
      AddSegment.subscription => SubscriptionForm(
        state: state,
        urlController: urlController,
        nameController: nameController,
        onAutoUpdate: onAutoUpdate,
        onMethod: onMethod,
        onPickFile: onPickFile,
        onClearFile: onClearFile,
        scanAvailable: scanAvailable,
        scanner: scanner,
      ),
      AddSegment.node => NodeForm(
        state: state,
        linkController: linkController,
        controllerOf: nodeController,
        onParseLink: onParseLink,
        onProtocol: onProtocol,
        onTransport: onTransport,
        onSecurity: onSecurity,
      ),
      AddSegment.chain => ChainForm(
        state: state,
        options: chainOptions,
        nameController: chainNameController,
        onTogglePicker: onToggleHopPicker,
        onAddHop: onAddHop,
        onRemoveHop: onRemoveHop,
        onMoveHop: onMoveHop,
        onToggleGroup: onToggleChainGroup,
      ),
    };

    return ColoredBox(
      color: c.bg,
      child: DefaultTextStyle.merge(
        style: AvType.body.copyWith(color: c.l1),
        child: Column(
          children: [
            AvFormHeader(
              title: state.editing != null
                  ? l.editTitle
                  : (desktop ? l.addConfigurationTitle : l.addTitle),
              leading: l.cancel,
              onLeading: onCancel,
              trailing: l.save,
              onTrailing: state.canSave ? onSave : null,
              busy: state.saving,
            ),
            // Editing shows one object; there is nothing to switch to.
            if (state.editing == null)
              Padding(
                padding: desktop
                    ? const EdgeInsets.fromLTRB(20, 0, 20, 14)
                    : const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: segments,
              ),
            Expanded(
              child: AvFadeSwap(
                token: state.segment,
                duration: AvMotion.swap,
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
                  children: [if (!state.loading) form],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
