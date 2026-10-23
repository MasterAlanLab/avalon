import 'package:av_core/av_core.dart';

/// One configuration card (PRODUCT_SPEC §3.3).
final class ConfigurationCard {
  const ConfigurationCard({
    required this.id,
    required this.kind,
    required this.name,
    required this.nodeCount,
    this.chainCount = 0,
    this.updatedAt,
    this.usage,
    this.errorCode,
    this.lastSuccessAt,
    this.refreshing = false,
  });

  final String id;
  final ConfigurationKind kind;
  final String name;

  /// Null while a subscription's content has not been downloaded.
  final int? nodeCount;

  /// 「自建节点」 only.
  final int chainCount;
  final DateTime? updatedAt;
  final Usage? usage;

  /// The last refresh failure (`services/error_code.dart`).
  final String? errorCode;
  final DateTime? lastSuccessAt;
  final bool refreshing;

  /// Only subscriptions refresh (D32).
  bool get canRefresh => kind == ConfigurationKind.subscription;

  /// 「自建节点」 has no edit/delete menu (PRODUCT_SPEC §3.4).
  bool get hasMenu => kind != ConfigurationKind.self;
}

final class ConfigurationsState {
  const ConfigurationsState({
    this.loading = false,
    this.cards = const [],
    this.selectedId,
    this.refreshingAll = false,
    this.warnings = const [],
  });

  /// True until the first read from the database arrives.
  final bool loading;
  final List<ConfigurationCard> cards;
  final String? selectedId;
  final bool refreshingAll;

  /// Diagnostics from the last import. The view omits routine handling
  /// notices (D122) and shows other warnings until dismissed.
  final List<ImportWarning> warnings;

  bool get canRefreshAll => cards.any((c) => c.canRefresh);
}
