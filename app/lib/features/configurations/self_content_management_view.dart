import 'package:av_design/av_design.dart';
import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import 'self_content_management_state.dart';

/// The nodes and chains saved in the self-content configuration. Pure.
class SelfContentManagementView extends StatelessWidget {
  const SelfContentManagementView({
    super.key,
    required this.state,
    required this.onClose,
    required this.onEdit,
    this.scrollController,
  });

  final SelfContentManagementState state;
  final VoidCallback onClose;
  final ValueChanged<SelfContentManagementItem> onEdit;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = context.av;
    final desktop = AvDensity.isDesktop(context);

    Widget item(List<SelfContentManagementItem> items, int index) {
      final data = items[index];
      return AvGroupItem(
        first: index == 0,
        last: index == items.length - 1,
        child: AvRow(
          titleWidget: Text(
            data.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (desktop ? AvType.s(14) : AvType.body).copyWith(color: c.l1),
          ),
          subtitle: data.protocol?.label ?? l.memberChain(data.hops),
          trailing: AvTextAction(l.edit, onTap: () => onEdit(data)),
          onTap: () => onEdit(data),
          insetSeparator: true,
        ),
      );
    }

    final empty = state.nodes.isEmpty && state.chains.isEmpty;
    final itemCount = state.error != null
        ? 1
        : state.loading
        ? 0
        : empty
        ? 1
        : state.nodes.length +
              state.chains.length +
              (state.nodes.isEmpty ? 0 : 1) +
              (state.chains.isEmpty ? 0 : 1);

    Widget row(BuildContext context, int index) {
      if (state.error case final error?) {
        return AvBanner(title: error.message(l));
      }
      if (empty) return AvSectionFooter(l.customEmpty);
      if (state.nodes.isNotEmpty) {
        if (index == 0) {
          return AvSectionHeader(l.addSegmentNode, top: 12);
        }
        if (index <= state.nodes.length) return item(state.nodes, index - 1);
        index -= state.nodes.length + 1;
      }
      if (index == 0) return AvSectionHeader(l.addSegmentChain);
      return item(state.chains, index - 1);
    }

    return ColoredBox(
      color: c.bg,
      child: Column(
        children: [
          AvFormHeader(
            title: l.selfConfigurationName,
            leading: l.done,
            onLeading: onClose,
          ),
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              physics: desktop
                  ? null
                  : const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
              padding: desktop
                  ? const EdgeInsets.fromLTRB(20, 0, 20, 24)
                  : EdgeInsets.only(
                      bottom: 40 + MediaQuery.paddingOf(context).bottom,
                    ),
              itemCount: itemCount,
              itemBuilder: row,
            ),
          ),
        ],
      ),
    );
  }
}
