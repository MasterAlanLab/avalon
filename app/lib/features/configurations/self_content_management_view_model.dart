import 'package:av_core/av_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_error.dart';
import '../../app/providers.dart';
import 'self_content_management_state.dart';

/// Watches saved content independently of the currently selected configuration.
final selfContentManagementStateProvider =
    Provider.autoDispose<SelfContentManagementState>((ref) {
      final nodes = ref.watch(selfNodesProvider);
      final chains = ref.watch(chainsProvider);
      final error = nodes.error ?? chains.error;
      if (error != null) {
        return SelfContentManagementState(error: AppError.from(error));
      }
      final savedNodes = nodes.value;
      final savedChains = chains.value;
      if (savedNodes == null || savedChains == null) {
        return const SelfContentManagementState(loading: true);
      }
      final sources = {
        for (final chain in savedChains)
          for (final hop in chain.hops)
            if (hop case SourceMember(:final configurationId)) configurationId,
      };
      final catalog = MemberCatalog(
        configurationId: '',
        content: const ConfigContent(finalTarget: ContentKeys.custom),
        selfNodes: savedNodes,
        chains: savedChains,
        otherContents: {
          for (final id in sources)
            if (ref.watch(contentProvider(id)).value case final content?)
              id: content.content,
        },
      );
      return SelfContentManagementState(
        nodes: [
          for (final node in savedNodes)
            SelfContentManagementItem(
              ref: MemberRef.selfNode(id: node.id),
              name: node.name,
              protocol: node.params.protocol,
            ),
        ],
        chains: [
          for (final chain in savedChains)
            SelfContentManagementItem(
              ref: MemberRef.chain(id: chain.id),
              name: catalog.chainName(chain)!,
              hops: chain.hops.length,
            ),
        ],
      );
    });
