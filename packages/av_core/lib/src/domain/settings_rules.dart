import 'settings.dart';

/// The settings typed as text (PRODUCT_SPEC §3.9–3.10).
enum SettingField {
  mixedPort,
  testUrl,
  testTimeoutMs,
  mtu,
  remoteDns,
  directDns,
  clashApiListen,
}

enum SettingError {
  /// Not a number, a URL or an address at all.
  invalid,

  /// A number outside the allowed range.
  outOfRange,
}

final class SettingException implements Exception {
  const SettingException(this.field, this.error);

  final SettingField field;
  final SettingError error;

  @override
  String toString() => 'SettingException(${field.name}, ${error.name})';
}

/// Reading, checking and resetting the device settings. The settings pages
/// and the backup restore share these, so a value is valid everywhere or
/// nowhere.
abstract final class SettingsRules {
  static const mixedPortRange = (min: 1024, max: 65535);
  static const testTimeoutRange = (min: 1000, max: 30000);
  static const mtuRange = (min: 1280, max: 9000);

  /// FakeIP ranges handed out by the DNS server (PRODUCT_SPEC §4).
  static const fakeIpRange = '198.18.0.0/15';

  /// The value as the edit field shows it.
  static String text(DeviceSettings s, SettingField field) => switch (field) {
    SettingField.mixedPort => '${s.mixedPort}',
    SettingField.testUrl => s.testUrl,
    SettingField.testTimeoutMs => '${s.testTimeoutMs}',
    SettingField.mtu => '${s.mtu}',
    SettingField.remoteDns => s.remoteDns,
    SettingField.directDns => s.directDns,
    SettingField.clashApiListen => s.clashApiListen,
  };

  /// [s] with [field] set from what was typed. Throws [SettingException]
  /// when the value cannot be used; nothing is adjusted silently.
  static DeviceSettings apply(
    DeviceSettings s,
    SettingField field,
    String input,
  ) {
    final text = input.trim();
    Never fail(SettingError error) => throw SettingException(field, error);
    int number(({int min, int max}) range) {
      final n = int.tryParse(text);
      if (n == null) fail(SettingError.invalid);
      if (n < range.min || n > range.max) fail(SettingError.outOfRange);
      return n;
    }

    switch (field) {
      case SettingField.mixedPort:
        return s.copyWith(mixedPort: number(mixedPortRange));
      case SettingField.testTimeoutMs:
        return s.copyWith(testTimeoutMs: number(testTimeoutRange));
      case SettingField.mtu:
        return s.copyWith(mtu: number(mtuRange));
      case SettingField.testUrl:
        final uri = Uri.tryParse(text);
        if (uri == null ||
            !(uri.isScheme('http') || uri.isScheme('https')) ||
            uri.host.isEmpty) {
          fail(SettingError.invalid);
        }
        return s.copyWith(testUrl: text);
      case SettingField.remoteDns:
        final uri = Uri.tryParse(text);
        if (uri == null ||
            !(uri.isScheme('https') || uri.isScheme('tls')) ||
            uri.host.isEmpty) {
          fail(SettingError.invalid);
        }
        return s.copyWith(remoteDns: text);
      case SettingField.directDns:
        if (!_isDirectDns(text)) fail(SettingError.invalid);
        return s.copyWith(directDns: text);
      case SettingField.clashApiListen:
        final listen = _listen(text);
        if (listen == null) fail(SettingError.invalid);
        if (listen.port < 1 || listen.port > 65535) {
          fail(SettingError.outOfRange);
        }
        return s.copyWith(clashApiListen: text);
    }
  }

  static final _ipv4 = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$');
  static final _ipv6 = RegExp(r'^[0-9a-fA-F:]+$');

  static bool _isIp(String host) {
    final m = _ipv4.firstMatch(host);
    if (m != null) {
      return [1, 2, 3, 4].every((i) => int.parse(m[i]!) <= 255);
    }
    return host.contains(':') && _ipv6.hasMatch(host);
  }

  /// An IP address, or `udp://` followed by one (optionally with a port).
  static bool _isDirectDns(String text) {
    if (_isIp(text)) return true;
    if (!text.startsWith('udp://')) return false;
    final uri = Uri.tryParse(text);
    return uri != null && _isIp(uri.host);
  }

  static ({String host, int port})? _listen(String text) {
    final i = text.lastIndexOf(':');
    if (i <= 0 || i == text.length - 1) return null;
    var host = text.substring(0, i);
    final port = int.tryParse(text.substring(i + 1));
    if (port == null) return null;
    if (host.startsWith('[') && host.endsWith(']')) {
      host = host.substring(1, host.length - 1);
    }
    if (host != 'localhost' && !_isIp(host)) return null;
    return (host: host, port: port);
  }

  /// False when the external controller would be reachable from other
  /// machines; the page then warns (PRODUCT_SPEC §3.10).
  static bool listensOnLoopback(String listen) {
    final parsed = _listen(listen.trim());
    if (parsed == null) return false;
    final host = parsed.host;
    return host == 'localhost' || host == '::1' || host.startsWith('127.');
  }

  /// With IPv6 off, names resolve as «仅 IPv4» whatever is chosen.
  static DnsStrategy effectiveDnsStrategy(DeviceSettings s) =>
      s.ipv6 ? s.dnsStrategy : DnsStrategy.ipv4Only;

  /// «恢复默认设置» of the advanced page (D20): its items return to their
  /// defaults; the Clash API key (and everything on other pages) stays.
  static DeviceSettings resetAdvanced(DeviceSettings s) {
    const d = DeviceSettings();
    return s.copyWith(
      tunEnabled: d.tunEnabled,
      tunStack: d.tunStack,
      mtu: d.mtu,
      autoRoute: d.autoRoute,
      strictRoute: d.strictRoute,
      remoteDns: d.remoteDns,
      directDns: d.directDns,
      fakeIp: d.fakeIp,
      dnsStrategy: d.dnsStrategy,
      sniff: d.sniff,
      sniffOverrideDestination: d.sniffOverrideDestination,
      bypassLan: d.bypassLan,
      ipv6: d.ipv6,
      findProcess: d.findProcess,
      clashApi: d.clashApi,
      clashApiListen: d.clashApiListen,
      logLevel: d.logLevel,
    );
  }
}
