import 'dart:typed_data';

import '../../domain/content.dart';
import '../../domain/refs.dart';
import '../../domain/settings.dart';
import '../../domain/user_content.dart';

enum HostPlatform { android, ios, macos, windows, linux }

/// Facts about the host the plan runs in.
final class HostInfo {
  const HostInfo({
    required this.platform,
    required this.stateDir,
    required this.deviceName,
    this.bridgeVersion = '',
    this.coreVersion = '',
  });

  final HostPlatform platform;

  /// Host state directory (RUNTIME_HOST §8): cache.db, Tailscale state.
  final String stateDir;

  /// Tailscale host name.
  final String deviceName;

  /// Included in the plan hash (CONFIG_PIPELINE §7).
  final String bridgeVersion;
  final String coreVersion;

  bool get isMobile =>
      platform == HostPlatform.android || platform == HostPlatform.ios;

  bool get isApple =>
      platform == HostPlatform.ios || platform == HostPlatform.macos;
}

/// What is being compiled: an imported configuration or the built-in
/// 「自建节点」 configuration.
sealed class CompileSource {
  const CompileSource();
}

final class ImportedSource extends CompileSource {
  const ImportedSource({required this.id, required this.content});

  final String id;
  final ConfigContent content;
}

final class SelfSource extends CompileSource {
  const SelfSource();

  /// Fixed id of the built-in configuration (DATA_MODEL §1.1).
  static const id = 'self';
}

/// One consistent read of everything a plan depends on
/// (CONFIG_PIPELINE §1).
final class CompileInput {
  const CompileInput({
    required this.source,
    required this.settings,
    required this.host,
    required this.hashKey,
    this.policy = const Policy(),
    this.selfNodes = const [],
    this.chains = const [],
    this.memberships = const [],
    this.selections = const {},
    this.otherContents = const {},
    this.ruleSetCache = const {},
    this.proxy = true,
    this.tailnet = false,
  });

  final CompileSource source;
  final DeviceSettings settings;
  final Policy policy;
  final HostInfo host;

  /// Per-installation key: secrets enter the plan hash as HMACs.
  final Uint8List hashKey;

  final List<SelfNode> selfNodes;
  final List<Chain> chains;

  /// All memberships; those of other configurations are ignored.
  final List<Membership> memberships;

  /// This configuration's choices, by group key.
  final Map<String, MemberRef> selections;

  /// Contents of other configurations that chain hops refer to.
  final Map<String, ConfigContent> otherContents;

  /// Rule-set files already downloaded (and converted to sing-box format),
  /// by [ruleSetKey]: address and format, not tag (D86).
  final Map<String, String> ruleSetCache;

  /// The run intents (RUNTIME_HOST §4). Both off means nothing to run.
  final bool proxy;
  final bool tailnet;
}
