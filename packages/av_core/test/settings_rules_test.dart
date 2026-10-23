// Editing and resetting device settings (PRODUCT_SPEC §3.9–3.10, D20).
import 'package:av_core/av_core.dart';
import 'package:test/test.dart';

Matcher _fails(SettingField field, SettingError error) => throwsA(
  isA<SettingException>()
      .having((e) => e.field, 'field', field)
      .having((e) => e.error, 'error', error),
);

void main() {
  const s = DeviceSettings();
  DeviceSettings set(SettingField f, String text) =>
      SettingsRules.apply(s, f, text);

  test('numbers must be in range', () {
    expect(set(SettingField.mixedPort, ' 1080 ').mixedPort, 1080);
    expect(
      () => set(SettingField.mixedPort, '80'),
      _fails(SettingField.mixedPort, SettingError.outOfRange),
    );
    expect(
      () => set(SettingField.mixedPort, '70000'),
      _fails(SettingField.mixedPort, SettingError.outOfRange),
    );
    expect(
      () => set(SettingField.mixedPort, 'abc'),
      _fails(SettingField.mixedPort, SettingError.invalid),
    );
    expect(set(SettingField.testTimeoutMs, '1000').testTimeoutMs, 1000);
    expect(
      () => set(SettingField.testTimeoutMs, '999'),
      _fails(SettingField.testTimeoutMs, SettingError.outOfRange),
    );
    expect(set(SettingField.mtu, '1500').mtu, 1500);
    expect(
      () => set(SettingField.mtu, '9001'),
      _fails(SettingField.mtu, SettingError.outOfRange),
    );
  });

  test('addresses must have the right form', () {
    expect(
      set(SettingField.testUrl, 'http://cp.cloudflare.com').testUrl,
      'http://cp.cloudflare.com',
    );
    expect(
      () => set(SettingField.testUrl, 'cp.cloudflare.com'),
      _fails(SettingField.testUrl, SettingError.invalid),
    );

    expect(
      set(SettingField.remoteDns, 'tls://8.8.8.8').remoteDns,
      'tls://8.8.8.8',
    );
    expect(
      () => set(SettingField.remoteDns, '8.8.8.8'),
      _fails(SettingField.remoteDns, SettingError.invalid),
    );

    for (final ok in ['223.5.5.5', 'udp://119.29.29.29', '2400:3200::1']) {
      expect(set(SettingField.directDns, ok).directDns, ok);
    }
    for (final bad in ['dns.alidns.com', 'https://223.5.5.5/dns-query', '']) {
      expect(
        () => set(SettingField.directDns, bad),
        _fails(SettingField.directDns, SettingError.invalid),
        reason: bad,
      );
    }

    expect(
      set(SettingField.clashApiListen, '0.0.0.0:9090').clashApiListen,
      '0.0.0.0:9090',
    );
    expect(
      () => set(SettingField.clashApiListen, '127.0.0.1'),
      _fails(SettingField.clashApiListen, SettingError.invalid),
    );
    expect(
      () => set(SettingField.clashApiListen, '127.0.0.1:0'),
      _fails(SettingField.clashApiListen, SettingError.outOfRange),
    );
  });

  test('a controller on anything but loopback is flagged', () {
    expect(SettingsRules.listensOnLoopback('127.0.0.1:9090'), isTrue);
    expect(SettingsRules.listensOnLoopback('localhost:9090'), isTrue);
    expect(SettingsRules.listensOnLoopback('[::1]:9090'), isTrue);
    expect(SettingsRules.listensOnLoopback('0.0.0.0:9090'), isFalse);
    expect(SettingsRules.listensOnLoopback('192.168.1.2:9090'), isFalse);
  });

  test('IPv6 off resolves as IPv4 only', () {
    expect(SettingsRules.effectiveDnsStrategy(s), DnsStrategy.ipv4Only);
    expect(
      SettingsRules.effectiveDnsStrategy(
        s.copyWith(ipv6: true, dnsStrategy: DnsStrategy.preferIpv6),
      ),
      DnsStrategy.preferIpv6,
    );
  });

  test('reset restores the advanced page and nothing else', () {
    final changed = s.copyWith(
      // advanced
      tunEnabled: false,
      mtu: 1400,
      remoteDns: 'tls://8.8.8.8',
      ipv6: true,
      clashApiListen: '0.0.0.0:9090',
      logLevel: LogLevel.debug,
      clashApiSecret: const Secret('fake-key'),
      // elsewhere
      mixedPort: 1080,
      appearance: Appearance.dark,
      locale: 'en',
      selectedConfigurationId: 'cfg',
      mode: OutboundMode.global,
    );
    final reset = SettingsRules.resetAdvanced(changed);
    expect(
      reset,
      s.copyWith(
        clashApiSecret: const Secret('fake-key'),
        mixedPort: 1080,
        appearance: Appearance.dark,
        locale: 'en',
        selectedConfigurationId: 'cfg',
        mode: OutboundMode.global,
      ),
    );
  });
}
