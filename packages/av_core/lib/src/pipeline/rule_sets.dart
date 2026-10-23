import '../domain/content.dart';

/// Default rule-set catalog (CONFIG_PIPELINE §8). Imported `GEOSITE,x` and
/// `GEOIP,x` rules use the same source.
abstract final class RuleSetCatalog {
  static const _site =
      'https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set';
  static const _ip =
      'https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set';

  static String geositeTag(String name) => 'geosite-${name.toLowerCase()}';
  static String geoipTag(String name) => 'geoip-${name.toLowerCase()}';

  static RuleSetRef geosite(String name) {
    final tag = geositeTag(name);
    return RuleSetRef(
      tag: tag,
      url: '$_site/$tag.srs',
      format: RuleSetFormat.binary,
    );
  }

  static RuleSetRef geoip(String name) {
    final tag = geoipTag(name);
    return RuleSetRef(
      tag: tag,
      url: '$_ip/$tag.srs',
      format: RuleSetFormat.binary,
    );
  }

  /// Rules of the default template: mainland China sites and addresses go
  /// direct (used by link lists and the 「自建节点」 configuration).
  static const defaultTags = ['geosite-cn', 'geoip-cn'];

  /// The tag every plan uses: the DNS rule for mainland China sites
  /// (CONFIG_PIPELINE §7).
  static const dnsTag = 'geosite-cn';

  /// The default catalog (CONFIG_PIPELINE §8), always listed on the GEO
  /// page.
  static final List<RuleSetRef> defaults = [
    geosite('cn'),
    geosite('geolocation-!cn'),
    geoip('cn'),
  ];

  /// The definition of [tag] for [content]: its own, or the catalog's for
  /// `geosite-`/`geoip-` names. Null when nothing defines it.
  static RuleSetRef? resolve(String tag, ConfigContent content) {
    for (final own in content.ruleSets) {
      if (own.tag == tag) return own;
    }
    if (tag.startsWith('geosite-')) return geosite(tag.substring(8));
    if (tag.startsWith('geoip-')) return geoip(tag.substring(6));
    return null;
  }

  /// The rule sets a configuration uses once compiled, before any override:
  /// the DNS rule's, then those of its rules (the default template's for
  /// link lists and 「自建节点」, [self]). Tags nothing defines are left to
  /// the compiler to report.
  static List<RuleSetRef> usedBy(ConfigContent content, {bool self = false}) {
    final tags = <String>{
      dnsTag,
      if (self || content.defaultRules)
        ...defaultTags
      else
        for (final rule in content.rules) ...rule.ruleSet,
    };
    return [for (final tag in tags) ?resolve(tag, content)];
  }

  static RuleSetKind kindOf(RuleSetRef ref) => ref.tag.startsWith('geosite-')
      ? RuleSetKind.geosite
      : ref.tag.startsWith('geoip-')
      ? RuleSetKind.geoip
      : RuleSetKind.ruleset;
}

/// What a rule set matches, as the GEO page labels it (PRODUCT_SPEC §3.12).
enum RuleSetKind { geosite, geoip, ruleset }
