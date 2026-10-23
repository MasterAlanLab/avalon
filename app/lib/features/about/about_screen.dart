import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/app_info.dart';
import '../../app/layout.dart';
import '../../app/providers.dart';
import '../../app/routes.dart';
import '../../runtime/runtime_coordinator.dart';
import '../../services/release_updates.dart';
import 'about_view.dart';
import 'about_view_model.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final build = ref.watch(installedBuildProvider).value;
    final vm = ref.read(aboutProvider.notifier);
    final channel = build == null
        ? null
        : updateChannel(build, AppPlatform.host);
    return AboutView(
      platform: AppPlatform.host,
      masterKeyInFile: ref.watch(masterKeyInFileProvider),
      coreVersion: ref.watch(runtimeProvider.select((s) => s.coreVersion)),
      installedVersion: build == null
          ? '—'
          : '${build.version} (${build.buildNumber})',
      state: ref.watch(aboutProvider),
      onLicenses: () => context.push(Routes.licenses),
      onCheckUpdates: vm.checkUpdates,
      showCheckUpdates:
          channel != null && (channel.direct || channel.store != null),
      onSource: () => vm.open(projectSource),
      onReleases: () => vm.open(projectReleases),
      onPrivacy: () => vm.open(projectPrivacy),
      onOpenUpdate: () {
        final page = ref.read(aboutProvider).update?.page;
        if (page != null) vm.open(page);
      },
    );
  }
}
