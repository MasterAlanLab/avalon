/// What a plan lets change while it runs: the outbound mode and each
/// selector's member (RUNTIME_HOST §5). The host switches these in place
/// and they are left out of the plan hash; everything else in a plan
/// takes a reload, which restarts the core.
final class PlanChoices {
  const PlanChoices({required this.mode, required this.selections});

  /// Reads the choices out of a plan as the host runs it (the compiler's
  /// output or the plan file).
  factory PlanChoices.of(Map<String, Object?> plan) {
    final experimental = plan['experimental'];
    final clashApi = experimental is Map ? experimental['clash_api'] : null;
    return PlanChoices(
      mode: clashApi is Map ? clashApi['default_mode'] as String? : null,
      selections: {
        for (final outbound
            in (plan['outbounds'] as List? ?? const [])
                .whereType<Map<Object?, Object?>>())
          if (outbound['type'] == 'selector' && outbound['default'] is String)
            outbound['tag']! as String: outbound['default']! as String,
      },
    );
  }

  /// `default_mode`; null when the plan has no modes (Tailnet only).
  final String? mode;

  /// Selector tag to the member it starts on.
  final Map<String, String> selections;
}
