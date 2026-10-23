import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'download/fetcher.dart';

/// Where the exit IP is asked for (CONFIG_PIPELINE §9, D89): Cloudflare's
/// trace, named in the privacy policy. A build may name another with
/// `--dart-define=AVALON_EXIT_IP_URL=…`; empty means none, and the
/// dashboard shows «—».
const exitIpUrlSetting = String.fromEnvironment(
  'AVALON_EXIT_IP_URL',
  defaultValue: 'https://www.cloudflare.com/cdn-cgi/trace',
);

/// The address traffic leaves from, and where that is, as a probe service
/// reported it.
@immutable
final class ExitIp {
  const ExitIp({required this.ip, this.countryCode, this.country, this.city});

  /// Reads the common answers of such services: JSON with `ip` (or
  /// `query`) and the country and city under their usual names, or
  /// `key=value` lines with `ip=` and `loc=` (a country code). Throws
  /// [FormatException] when no address is in it.
  factory ExitIp.parse(String body) {
    final text = body.trim();
    if (text.startsWith('{')) {
      final json = jsonDecode(text);
      if (json is! Map) throw const FormatException('not an object');
      String? field(List<String> names) {
        for (final name in names) {
          final value = json[name];
          if (value is String && value.trim().isNotEmpty) return value.trim();
        }
        return null;
      }

      final ip = field(['ip', 'query', 'ip_addr', 'address']);
      if (ip == null) throw const FormatException('no address');
      final country = field(['country_name', 'country']);
      final code =
          field(['country_code', 'countryCode', 'country_iso']) ??
          (country != null && country.length == 2 ? country : null);
      return ExitIp(
        ip: ip,
        countryCode: code?.toUpperCase(),
        country: country != null && country.length > 2 ? country : null,
        city: field(['city']),
      );
    }
    final lines = <String, String>{
      for (final line in const LineSplitter().convert(text))
        if (line.contains('='))
          line.substring(0, line.indexOf('=')).trim(): line
              .substring(line.indexOf('=') + 1)
              .trim(),
    };
    final ip = lines['ip'];
    if (ip == null || ip.isEmpty) throw const FormatException('no address');
    final code = lines['loc'];
    return ExitIp(
      ip: ip,
      countryCode: code == null || code.isEmpty ? null : code.toUpperCase(),
    );
  }

  final String ip;

  /// ISO 3166 alpha-2, upper case.
  final String? countryCode;
  final String? country;
  final String? city;

  /// What the card shows above the address: a flag, then the city and
  /// country as far as known; null when nothing is.
  String? get location {
    final flag = _flag(countryCode);
    final place = [?city, ?(country ?? countryCode)].join(', ');
    final text = [?flag, if (place.isNotEmpty) place].join(' ');
    return text.isEmpty ? null : text;
  }

  static String? _flag(String? code) {
    if (code == null || !RegExp(r'^[A-Z]{2}$').hasMatch(code)) return null;
    return String.fromCharCodes(code.codeUnits.map((c) => 0x1F1E6 + c - 0x41));
  }

  @override
  bool operator ==(Object other) =>
      other is ExitIp &&
      other.ip == ip &&
      other.countryCode == countryCode &&
      other.country == country &&
      other.city == city;

  @override
  int get hashCode => Object.hash(ip, countryCode, country, city);
}

/// Asks the probe service for the exit IP, directly or through the proxy
/// (CONFIG_PIPELINE §9).
final class ExitIpService {
  ExitIpService(this._fetcher, {this.url});

  /// The answers are small; anything bigger is not what was asked for.
  static const maxBytes = 64 * 1024;

  final Fetcher _fetcher;

  /// Null when the build names no service.
  final Uri? url;

  /// The device's own exit, from this app's network. The address is the
  /// build's, so it may be on this machine or a private network.
  Future<ExitIp> direct() async {
    final target = url!;
    final fetched = await _fetcher.get(target, allowPrivate: true);
    return ExitIp.parse(fetched.text);
  }
}
