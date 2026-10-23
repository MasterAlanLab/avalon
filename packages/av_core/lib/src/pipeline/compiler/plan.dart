import '../../domain/refs.dart';
import '../../domain/secret.dart';
import 'plan_choices.dart';

/// Why a plan could not be compiled. Nothing is dropped to make it work
/// (CONFIG_PIPELINE §6).
enum CompileErrorCode {
  /// A member the plan needs cannot be used; [CompileException.subject] is
  /// its display name, [CompileException.detail] the reason.
  memberUnavailable,

  /// A group the plan needs has no usable member.
  emptyGroup,

  /// A rule set in Clash format has not been downloaded and converted yet.
  ruleSetMissing,

  /// Desktop per-app proxy needs 「查找进程」 (CONFIG_PIPELINE §6).
  perAppNeedsFindProcess,

  /// The JSON override is malformed; [CompileException.subject] is the path.
  overrideInvalid,

  /// The JSON override names an outbound that does not exist.
  overrideReference,

  /// A tag in the JSON override collides with a generated one.
  overrideConflict,

  /// A setting value the plan cannot use (e.g. a DNS address).
  invalidSetting,

  /// Neither proxy nor Tailscale is wanted.
  nothingToRun,
}

final class CompileException implements Exception {
  const CompileException(this.code, {this.subject = '', this.detail = ''});

  final CompileErrorCode code;
  final String subject;
  final String detail;

  @override
  String toString() => 'CompileException(${code.name}, $subject, $detail)';
}

/// What a generated tag stands for: maps actual selections and connection
/// chains in host snapshots back to the UI (CONFIG_PIPELINE §7).
final class PlanTag {
  const PlanTag(this.ref, this.name);

  final MemberRef ref;
  final String name;
}

/// A compiled sing-box configuration. The tree holds [Secret]s until it is
/// serialized for the host ([toJson]) or for display ([redacted]).
final class CompiledPlan {
  const CompiledPlan({
    required this.tree,
    required this.planHash,
    required this.tags,
    required this.primaryTag,
  });

  final Map<String, Object?> tree;
  final String planHash;
  final Map<String, PlanTag> tags;

  /// Tag of the main selector (or the final target without one); used for
  /// downloads through the proxy and exit-IP probing.
  final String primaryTag;

  /// The configuration the host runs, secrets included.
  Map<String, Object?> toJson() => _map(tree, (s) => s.value);

  /// For 「查看生成的配置」: secrets replaced by `••••`.
  Map<String, Object?> redacted() => _map(tree, (_) => '••••');

  /// The outbound that stands for [member] in this plan: what a group
  /// names as its member and what a latency test dials. A chain is its
  /// last hop, which carries the whole path. Null when the plan has no
  /// outbound for it (it could not be built).
  String? tagOf(MemberRef member) {
    String? found;
    var hop = -1;
    for (final MapEntry(key: tag, value: info) in tags.entries) {
      if (info.ref != member) continue;
      if (member is! ChainRef) return tag;
      final index = int.tryParse(tag.substring(tag.lastIndexOf(':') + 1)) ?? 0;
      if (index > hop) {
        hop = index;
        found = tag;
      }
    }
    return found;
  }

  /// What can be switched while this plan runs. Two plans that differ
  /// only in these have the same [planHash].
  PlanChoices get choices => PlanChoices.of(toJson());

  static Map<String, Object?> _map(
    Map<String, Object?> m,
    String Function(Secret) secret,
  ) {
    Object? walk(Object? v) => switch (v) {
      final Secret s => secret(s),
      final Map<String, Object?> m => {
        for (final e in m.entries) e.key: walk(e.value),
      },
      final List<Object?> l => [for (final e in l) walk(e)],
      _ => v,
    };
    return walk(m)! as Map<String, Object?>;
  }
}
