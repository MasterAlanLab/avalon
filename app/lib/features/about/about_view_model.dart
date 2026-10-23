import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_info.dart';
import '../../app/layout.dart';
import '../../app/providers.dart';
import '../../services/release_updates.dart';
import 'about_state.dart';

final releaseUpdatesProvider = Provider<ReleaseUpdates>(
  (ref) => ReleaseUpdates(
    platform: AppPlatform.host == AppPlatform.mac
        ? 'macos'
        : AppPlatform.host.name,
  ),
);
final aboutProvider = NotifierProvider.autoDispose<AboutViewModel, AboutState>(
  AboutViewModel.new,
);

class AboutViewModel extends Notifier<AboutState> {
  @override
  AboutState build() => const AboutState();

  Future<void> checkUpdates() async {
    if (state.checking) return;
    state = const AboutState(checking: true);
    try {
      final build = await ref.read(installedBuildProvider.future);
      final channel = updateChannel(build, AppPlatform.host);
      if (channel.store case final store?) {
        final opened = await ref.read(browserProvider).open(store);
        if (ref.mounted) {
          state = AboutState(failure: opened ? null : AboutFailure.browser);
        }
        return;
      }
      if (!channel.direct) {
        throw const FormatException('Update channel is not configured');
      }
      final update = await ref
          .read(releaseUpdatesProvider)
          .check(build.version);
      if (ref.mounted) state = AboutState(update: update);
    } on Object {
      if (ref.mounted) state = const AboutState(failure: AboutFailure.check);
    }
  }

  Future<void> open(Uri uri) async {
    try {
      if (!await ref.read(browserProvider).open(uri)) {
        if (ref.mounted) {
          state = AboutState(
            update: state.update,
            failure: AboutFailure.browser,
          );
        }
      }
    } on Object {
      if (ref.mounted) {
        state = AboutState(update: state.update, failure: AboutFailure.browser);
      }
    }
  }
}
