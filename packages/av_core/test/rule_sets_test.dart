// Which rule sets a configuration uses (CONFIG_PIPELINE §8), shared by the
// compiler and the GEO page.
import 'package:av_core/av_core.dart';
import 'package:test/test.dart';

void main() {
  const provider = RuleSetRef(
    tag: 'provider-ads',
    url: 'https://example.com/ads.yaml',
    format: RuleSetFormat.clashDomainYaml,
  );

  test('a tag resolves to the configuration\'s own definition first', () {
    const mirror = RuleSetRef(
      tag: 'geosite-cn',
      url: 'https://mirror.example.com/geosite-cn.srs',
      format: RuleSetFormat.binary,
    );
    const content = ConfigContent(
      finalTarget: ContentKeys.direct,
      ruleSets: [mirror, provider],
    );
    expect(RuleSetCatalog.resolve('geosite-cn', content), mirror);
    expect(RuleSetCatalog.resolve('provider-ads', content), provider);
    expect(
      RuleSetCatalog.resolve('geoip-telegram', content)!.url,
      endsWith('/sing-geoip/rule-set/geoip-telegram.srs'),
    );
    expect(RuleSetCatalog.resolve('unknown', content), isNull);
  });

  test('imported rules: the DNS rule\'s set, then theirs, once each', () {
    const content = ConfigContent(
      finalTarget: ContentKeys.direct,
      ruleSets: [provider],
      rules: [
        RuleDef(ruleSet: ['provider-ads'], target: ContentKeys.reject),
        RuleDef(
          ruleSet: ['geosite-openai', 'geosite-cn'],
          target: ContentKeys.direct,
        ),
        RuleDef(ruleSet: ['nowhere'], target: ContentKeys.direct),
        RuleDef(domainSuffix: ['example.com'], target: ContentKeys.direct),
      ],
    );
    expect(
      [for (final r in RuleSetCatalog.usedBy(content)) r.tag],
      ['geosite-cn', 'provider-ads', 'geosite-openai'],
    );
  });

  test('link lists and the self configuration use the default template', () {
    const links = ConfigContent(
      finalTarget: ContentKeys.direct,
      defaultRules: true,
    );
    const empty = ConfigContent(finalTarget: ContentKeys.direct);
    expect(
      [for (final r in RuleSetCatalog.usedBy(links)) r.tag],
      ['geosite-cn', 'geoip-cn'],
    );
    expect(
      [for (final r in RuleSetCatalog.usedBy(empty, self: true)) r.tag],
      ['geosite-cn', 'geoip-cn'],
    );
    // Without rules everything goes to the final target.
    expect(
      [for (final r in RuleSetCatalog.usedBy(empty)) r.tag],
      ['geosite-cn'],
    );
  });
}
