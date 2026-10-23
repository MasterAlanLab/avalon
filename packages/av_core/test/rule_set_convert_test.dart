// Clash rule providers as sing-box source rule sets (CONFIG_PIPELINE §8).
import 'package:av_core/av_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'cache identity hides URL credentials and remains stable after persistence',
    () {
      const address = 'https://rules.example.com/list?auth=private-query-token';
      final key = ruleSetAddressKey(address);
      expect(key, matches(r'^sha256:[a-f0-9]{64}$'));
      expect(key, isNot(contains('private-query-token')));
      expect(ruleSetAddressKey(key), key);
      expect(
        ruleSetKeyOf(key, RuleSetFormat.binary),
        ruleSetKeyOf(address, RuleSetFormat.binary),
      );
      expect(
        ruleSetKeyOf(address, RuleSetFormat.source),
        isNot(ruleSetKeyOf(address, RuleSetFormat.binary)),
      );
      // Exact addresses retain their identity: query tokens are never normalized.
      expect(ruleSetAddressKey('$address&another=1'), isNot(key));
    },
  );

  test('domain lists, in YAML and text', () {
    const yaml = '''
payload:
  - '+.google.com'
  - '.example.org'
  - 'exact.example.net'
  - '*.one-level.com'
  - 'bad*.example.com'
''';
    final (:ruleSet, :skipped) = convertClashRuleSet(
      yaml,
      RuleSetFormat.clashDomainYaml,
    );
    expect(ruleSet, {
      'version': 2,
      'rules': [
        {
          'domain': ['exact.example.net'],
          'domain_suffix': ['google.com', '.example.org'],
          'domain_regex': [r'^[^.]+\.one-level\.com$'],
        },
      ],
    });
    expect(skipped, 1);

    final text = convertClashRuleSet(
      '# comment\n+.a.com\n\nb.com\n',
      RuleSetFormat.clashDomainText,
    );
    expect(text.ruleSet['rules'], [
      {
        'domain': ['b.com'],
        'domain_suffix': ['a.com'],
      },
    ]);
  });

  test('address lists keep IPv4 and IPv6 ranges', () {
    final (:ruleSet, :skipped) = convertClashRuleSet(
      '1.2.3.0/24\n2001:db8::/32\nnot-an-address\n',
      RuleSetFormat.clashIpcidrText,
    );
    expect(ruleSet['rules'], [
      {
        'ip_cidr': ['1.2.3.0/24', '2001:db8::/32'],
      },
    ]);
    expect(skipped, 1);
  });

  test('classical rules: each kind is an alternative of its own', () {
    const yaml = '''
payload:
  - DOMAIN-SUFFIX,openai.com
  - DOMAIN,chat.example.com
  - DOMAIN-KEYWORD,openai
  - IP-CIDR,104.18.0.0/16,no-resolve
  - IP-CIDR6,2606:4700::/32
  - PROCESS-NAME,ChatGPT
  - DST-PORT,8000-9000
  - DST-PORT,443
  - GEOIP,CN
  - AND,((DOMAIN,a.com),(NETWORK,UDP))
''';
    final (:ruleSet, :skipped) = convertClashRuleSet(
      yaml,
      RuleSetFormat.clashClassicalYaml,
    );
    expect(ruleSet['rules'], [
      {
        'domain': ['chat.example.com'],
        'domain_suffix': ['openai.com'],
        'domain_keyword': ['openai'],
      },
      {
        'ip_cidr': ['104.18.0.0/16', '2606:4700::/32'],
      },
      {
        'process_name': ['ChatGPT'],
      },
      {
        'port': [443],
      },
      {
        'port_range': ['8000:9000'],
      },
    ]);
    // GEOIP needs a rule set of its own; AND cannot be split into one.
    expect(skipped, 2);
  });

  test('something that is not a provider is refused', () {
    expect(
      () => convertClashRuleSet('not: [valid', RuleSetFormat.clashDomainYaml),
      throwsA(isA<RuleSetFormatException>()),
    );
    expect(
      () => convertClashRuleSet('rules: []', RuleSetFormat.clashClassicalYaml),
      throwsA(isA<RuleSetFormatException>()),
    );
  });
}
