import 'package:av_core/av_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'self_content_management_view.dart';
import 'self_content_management_view_model.dart';

class SelfContentManagementScreen extends ConsumerWidget {
  const SelfContentManagementScreen({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      SelfContentManagementView(
        state: ref.watch(selfContentManagementStateProvider),
        scrollController: scrollController,
        onClose: () => Navigator.of(context).pop(),
        onEdit: (item) => Navigator.of(context).pop<MemberRef>(item.ref),
      );
}
