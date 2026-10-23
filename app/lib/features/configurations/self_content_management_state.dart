import 'package:av_core/av_core.dart';

import '../../app/app_error.dart';

/// A saved node or chain that can be opened in the existing edit form.
final class SelfContentManagementItem {
  const SelfContentManagementItem({
    required this.ref,
    required this.name,
    this.protocol,
    this.hops = 0,
  });

  final MemberRef ref;
  final String name;
  final Protocol? protocol;
  final int hops;
}

/// Only names and public summaries enter the management list.
final class SelfContentManagementState {
  const SelfContentManagementState({
    this.loading = false,
    this.nodes = const [],
    this.chains = const [],
    this.error,
  });

  final bool loading;
  final List<SelfContentManagementItem> nodes;
  final List<SelfContentManagementItem> chains;
  final AppError? error;
}
