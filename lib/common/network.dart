import 'dart:async';
import 'dart:io';

/// Detects whether the host can actually use IPv6 for an outbound connection.
///
/// An IPv6 address on an interface is not sufficient: VPNs and stale network
/// services can leave a global address behind without a working default route.
class Ipv6CapabilityService {
  Ipv6CapabilityService._();

  static final instance = Ipv6CapabilityService._();

  bool? _cached;
  DateTime? _cachedAt;
  Future<bool>? _inFlight;

  /// Result and address set of the last probe made while no Avalon TUN was
  /// capturing IPv6.  Only such a probe observes the physical route.
  bool? _verified;
  String? _verifiedKey;

  bool? get available => _cached;

  /// [tunCapturesIpv6] must be true while Avalon's own TUN owns the IPv6
  /// default route.  In that state a socket probe is answered by the TUN
  /// stack itself, so it would always succeed and lock the result to true.
  Future<bool> detect({bool force = false, bool tunCapturesIpv6 = false}) {
    if (_inFlight != null) return _inFlight!;
    final now = DateTime.now();
    if (!force &&
        _cached != null &&
        _cachedAt != null &&
        now.difference(_cachedAt!) < const Duration(seconds: 30)) {
      return Future.value(_cached!);
    }
    final future = _detect(tunCapturesIpv6: tunCapturesIpv6);
    _inFlight = future;
    unawaited(
      future.then<void>(
        (_) {
          if (identical(_inFlight, future)) _inFlight = null;
        },
        onError: (Object _, StackTrace __) {
          if (identical(_inFlight, future)) _inFlight = null;
        },
      ),
    );
    return future;
  }

  Future<bool> _detect({required bool tunCapturesIpv6}) async {
    List<InternetAddress> addresses;
    try {
      final interfaces = await NetworkInterface.list(
        includeLoopback: false,
        includeLinkLocal: false,
      );
      addresses = [
        for (final networkInterface in interfaces)
          for (final address in networkInterface.addresses)
            if (address.type == InternetAddressType.IPv6 &&
                !address.isLoopback &&
                !address.isLinkLocal &&
                !address.isMulticast &&
                address.isGlobalIpv6)
              address,
      ];
    } on Object {
      return _remember(false);
    }

    // No global address is a reliable negative even with the TUN up: the TUN
    // itself only carries a ULA.
    if (addresses.isEmpty) return _remember(false);

    final key = (addresses.map((item) => item.address).toList()..sort()).join(
      ',',
    );
    if (tunCapturesIpv6) {
      // The probe cannot see past the TUN.  Reuse the physical result while
      // the address set is unchanged; after a network switch fall back to the
      // address heuristic and let the core's dual-stack racing absorb a
      // stale address.
      return _remember(_verifiedKey == key ? _verified ?? true : true);
    }

    final result = await _defaultProbe(addresses);
    _verified = result;
    _verifiedKey = key;
    return _remember(result);
  }

  Future<bool> _defaultProbe(List<InternetAddress> addresses) async {
    // Bootstrap destinations only, domestic ones first so the probe is not
    // defeated by cross-border filtering.  Failure is treated as IPv4-only
    // so a dead v6 route cannot make every DNS lookup wait for a timeout.
    const destinations = [
      '2400:3200::1', // AliDNS
      '2402:4e00::', // DNSPod
      '2606:4700:4700::1111', // Cloudflare
    ];
    Future<bool> probe(String destination) async {
      Socket? socket;
      try {
        socket = await Socket.connect(
          InternetAddress(destination),
          443,
          sourceAddress: addresses.first,
          timeout: const Duration(milliseconds: 1500),
        );
        return true;
      } on Object {
        return false;
      } finally {
        socket?.destroy();
      }
    }

    final completer = Completer<bool>();
    var pending = destinations.length;
    for (final destination in destinations) {
      unawaited(
        probe(destination).then((ok) {
          pending--;
          if (completer.isCompleted) return;
          if (ok) {
            completer.complete(true);
          } else if (pending == 0) {
            completer.complete(false);
          }
        }),
      );
    }
    return completer.future;
  }

  bool _remember(bool value) {
    _cached = value;
    _cachedAt = DateTime.now();
    return value;
  }
}

extension NetworkInterfaceExt on NetworkInterface {
  bool get isWifi {
    final nameLowCase = name.toLowerCase();
    if (nameLowCase.contains('wlan') ||
        nameLowCase.contains('wi-fi') ||
        nameLowCase == 'en0' ||
        nameLowCase == 'eth0') {
      return true;
    }

    return false;
  }

  bool get includesIPv4 {
    return addresses.any((addr) => addr.isIPv4);
  }
}

extension InternetAddressExt on InternetAddress {
  bool get isIPv4 {
    return type == InternetAddressType.IPv4;
  }

  /// Returns true only for globally routable IPv6 unicast addresses.
  ///
  /// A TUN interface commonly exposes a ULA such as `fdfe:...` so that the
  /// virtual stack can build an IPv6 fake-IP pool.  That address proves only
  /// that the virtual interface exists; it says nothing about whether the
  /// host has an IPv6 route to the Internet.  Restricting capability detection
  /// to 2000::/3 prevents the TUN itself from satisfying the probe.
  bool get isGlobalIpv6 {
    if (type != InternetAddressType.IPv6 || rawAddress.length != 16) {
      return false;
    }
    final firstByte = rawAddress.first;
    return firstByte >= 0x20 && firstByte <= 0x3f;
  }
}
