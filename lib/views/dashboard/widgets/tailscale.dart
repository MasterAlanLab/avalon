import 'package:avalon/common/common.dart';
import 'package:avalon/features/tailscale/provider.dart';
import 'package:avalon/state.dart';
import 'package:avalon/views/tailscale.dart';
import 'package:avalon/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TailscaleCard extends ConsumerWidget {
  const TailscaleCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(tailscaleProvider);
    final s = view.snapshot;
    final l = context.appLocalizations;
    final address = s.session == 'running' && !s.cached
        ? s.self?.ips.firstOrNull
        : null;
    return SizedBox(
      height: getWidgetHeight(1),
      child: CommonCard(
        info: Info(label: l.tailscale, iconData: Icons.hub_outlined),
        onPressed: () => Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const TailscalePage())),
        child: Padding(
          padding: baseInfoEdgeInsets.copyWith(top: 0),
          child: Align(
            alignment: Alignment.bottomLeft,
            child: SizedBox(
              height: globalState.measure.bodyMediumHeight + 2,
              child: FadeThroughBox(
                child: view.loading
                    ? Container(
                        padding: const EdgeInsets.all(2),
                        child: const AspectRatio(
                          aspectRatio: 1,
                          child: CommonCircleLoading(),
                        ),
                      )
                    : TooltipText(
                        text: Text(
                          !s.supported
                              ? l.tsUnsupported
                              : address ?? tailscaleText(l, s.session),
                          style: context.textTheme.bodyMedium?.toLight
                              .adjustSize(1),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
