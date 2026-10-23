import AvalonCore
import Darwin
import Foundation
import Network
import NetworkExtension

private final class AppleStrings: NSObject, LibboxStringIteratorProtocol {
  private let values: [String]
  private var index = 0
  init(_ values: [String]) { self.values = values }
  func hasNext() -> Bool { index < values.count }
  func len() -> Int32 { Int32(values.count) }
  func next() -> String {
    guard hasNext() else { return "" }
    defer { index += 1 }
    return values[index]
  }
}

private final class AppleInterfaces: NSObject, LibboxNetworkInterfaceIteratorProtocol {
  private let values: [LibboxNetworkInterface]
  private var index = 0
  init(_ values: [LibboxNetworkInterface]) { self.values = values }
  func hasNext() -> Bool { index < values.count }
  func next() -> LibboxNetworkInterface? {
    guard hasNext() else { return nil }
    defer { index += 1 }
    return values[index]
  }
}

/// The Network Extension owns the interface. The app's outbound-only
/// measurement instance shares the network adapter but cannot create a TUN.
final class ApplePlatform: NSObject, LibboxPlatformInterfaceProtocol {
  private weak var provider: NEPacketTunnelProvider?
  private let deviceName: String
  private let lock = NSLock()
  private let networkQueue = DispatchQueue(label: "dev.avalon.network-path")
  private var monitor: NWPathMonitor?
  private var path: Network.NWPath?
  private var tunActive = false
  private var systemProxyActive = false
  private var networkSettingsActive = false

  init(provider: NEPacketTunnelProvider?, deviceName: String) {
    self.provider = provider
    self.deviceName = deviceName
  }

  func snapshotFacts() -> (tunActive: Bool, systemProxyActive: Bool) {
    lock.lock()
    defer { lock.unlock() }
    return (tunActive, systemProxyActive)
  }

  func clearTunnel() throws {
    guard let provider else { return }
    lock.lock()
    let applied = networkSettingsActive
    lock.unlock()
    guard applied else { return }
    try apply(nil, to: provider)
    lock.lock()
    tunActive = false
    systemProxyActive = false
    networkSettingsActive = false
    lock.unlock()
  }

  // The argument label is fixed by gomobile's imported protocol.
  // swift-format-ignore: AlwaysUseLowerCamelCase
  func openTun(
    _ options: LibboxTunOptionsProtocol?, ret0_ descriptorOut: UnsafeMutablePointer<Int32>?
  ) throws {
    guard let provider, let options, let descriptorOut else {
      throw platformError("A packet tunnel requires a Network Extension")
    }
    // iOS has no Android-style package routing. Refuse a mismatched plan.
    guard !((options.getIncludePackage()?.hasNext()) ?? false),
      !((options.getExcludePackage()?.hasNext()) ?? false)
    else { throw platformError("Per-application routing is not supported on iOS") }

    let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
    settings.mtu = NSNumber(value: options.getMTU())
    let inet4 = prefixes(options.getInet4Address())
    let inet6 = prefixes(options.getInet6Address())
    guard !inet4.isEmpty || !inet6.isEmpty else {
      throw platformError("The tunnel plan has no interface address")
    }
    if !inet4.isEmpty {
      let ipv4 = NEIPv4Settings(
        addresses: inet4.map { $0.address() }, subnetMasks: inet4.map { $0.mask() })
      if options.getAutoRoute() {
        let included = prefixes(options.getInet4RouteAddress())
        ipv4.includedRoutes =
          included.isEmpty
          ? [.default()]
          : included.map {
            NEIPv4Route(destinationAddress: $0.address(), subnetMask: $0.mask())
          }
        ipv4.excludedRoutes = prefixes(options.getInet4RouteExcludeAddress()).map {
          NEIPv4Route(destinationAddress: $0.address(), subnetMask: $0.mask())
        }
      }
      settings.ipv4Settings = ipv4
    }
    if !inet6.isEmpty {
      let ipv6 = NEIPv6Settings(
        addresses: inet6.map { $0.address() },
        networkPrefixLengths: inet6.map {
          NSNumber(value: $0.prefix())
        })
      if options.getAutoRoute() {
        let included = prefixes(options.getInet6RouteAddress())
        ipv6.includedRoutes =
          included.isEmpty
          ? [.default()]
          : included.map {
            NEIPv6Route(
              destinationAddress: $0.address(), networkPrefixLength: NSNumber(value: $0.prefix()))
          }
        ipv6.excludedRoutes = prefixes(options.getInet6RouteExcludeAddress()).map {
          NEIPv6Route(
            destinationAddress: $0.address(), networkPrefixLength: NSNumber(value: $0.prefix()))
        }
      }
      settings.ipv6Settings = ipv6
    }
    if options.getAutoRoute() {
      let servers = strings(try options.getDNSServerAddress())
      if !servers.isEmpty {
        let dns = NEDNSSettings(servers: servers)
        dns.matchDomains = [""]
        dns.matchDomainsNoSearch = true
        settings.dnsSettings = dns
      }
    }
    if options.isHTTPProxyEnabled() {
      let proxy = NEProxySettings()
      proxy.httpEnabled = true
      proxy.httpsEnabled = true
      let server = NEProxyServer(
        address: options.getHTTPProxyServer(), port: Int(options.getHTTPProxyServerPort()))
      proxy.httpServer = server
      proxy.httpsServer = server
      proxy.exceptionList = strings(options.getHTTPProxyBypassDomain())
      let domains = strings(options.getHTTPProxyMatchDomain())
      proxy.matchDomains = domains.isEmpty ? [""] : domains
      settings.proxySettings = proxy
    }
    try apply(settings, to: provider)
    // Official libbox's Darwin adapter finds the provider-owned utun;
    // no private packetFlow KVC or copying packets through Flutter.
    let descriptor = LibboxGetTunnelFileDescriptor()
    guard descriptor >= 0 else {
      try? apply(nil, to: provider)
      throw platformError("The system did not provide a tunnel descriptor")
    }
    descriptorOut.pointee = descriptor
    lock.lock()
    tunActive = true
    networkSettingsActive = true
    systemProxyActive = settings.proxySettings != nil
    lock.unlock()
  }

  #if os(macOS)
    /// A connected extension can own local listeners and the system proxy
    /// without installing default routes or a DNS override (D34).
    func applyProxyOnly(enabled: Bool, port: Int) throws {
      guard let provider, (1024...65535).contains(port) else {
        throw platformError("The proxy-only host options are invalid")
      }
      let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: "127.0.0.1")
      let ipv4 = NEIPv4Settings(addresses: ["172.19.0.1"], subnetMasks: ["255.255.255.252"])
      ipv4.includedRoutes = []
      ipv4.excludedRoutes = []
      settings.ipv4Settings = ipv4
      if enabled {
        let proxy = NEProxySettings()
        let server = NEProxyServer(address: "127.0.0.1", port: port)
        proxy.httpEnabled = true
        proxy.httpsEnabled = true
        proxy.httpServer = server
        proxy.httpsServer = server
        proxy.matchDomains = [""]
        settings.proxySettings = proxy
      }
      try apply(settings, to: provider)
      lock.lock()
      tunActive = false
      systemProxyActive = enabled
      networkSettingsActive = true
      lock.unlock()
    }
  #endif

  private func apply(
    _ settings: NEPacketTunnelNetworkSettings?, to provider: NEPacketTunnelProvider
  ) throws {
    let finished = DispatchSemaphore(value: 0)
    var failure: Error?
    provider.setTunnelNetworkSettings(settings) { error in
      failure = error
      finished.signal()
    }
    // Called only from the host's worker, never the provider callback queue.
    // Wait for Apple's completed application: reporting requested settings
    // before this completion would manufacture active-state facts.
    finished.wait()
    if failure != nil { throw platformError("The system could not apply the tunnel settings") }
  }

  func usePlatformAutoDetectControl() -> Bool { false }
  func autoDetectControl(_ fd: Int32) throws {}
  func underNetworkExtension() -> Bool { provider != nil }
  func includeAllNetworks() -> Bool { false }

  func startDefaultInterfaceMonitor(_ listener: LibboxInterfaceUpdateListenerProtocol?) throws {
    guard let listener else { return }
    let first = DispatchSemaphore(value: 0)
    let next = NWPathMonitor()
    var reported = false
    next.pathUpdateHandler = { [weak self] path in
      guard let self else { return }
      self.lock.lock()
      self.path = path
      self.lock.unlock()
      // availableInterfaces includes alternatives. Use the interface the
      // current path actually uses, and never select the provider's utun.
      let selected = path.availableInterfaces.first {
        !$0.name.hasPrefix("utun") && path.usesInterfaceType($0.type)
      }
      if path.status == .satisfied, let selected {
        listener.updateDefaultInterface(
          selected.name, interfaceIndex: Int32(selected.index),
          isExpensive: path.isExpensive, isConstrained: path.isConstrained)
      } else {
        listener.updateDefaultInterface(
          "", interfaceIndex: -1, isExpensive: false, isConstrained: false)
      }
      listener.updateNetworkPath(String(describing: path))
      if !reported {
        reported = true
        first.signal()
      }
    }
    lock.lock()
    let previous = monitor
    monitor = next
    lock.unlock()
    previous?.cancel()
    next.start(queue: networkQueue)
    // sing-box can dial immediately after this method returns.
    guard first.wait(timeout: .now() + 5) == .success else {
      next.cancel()
      throw platformError("The system did not report a network path")
    }
  }

  func closeDefaultInterfaceMonitor(_ listener: LibboxInterfaceUpdateListenerProtocol?) throws {
    lock.lock()
    let previous = monitor
    monitor = nil
    path = nil
    lock.unlock()
    previous?.cancel()
  }

  func getInterfaces() throws -> LibboxNetworkInterfaceIteratorProtocol {
    var list: UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&list) == 0 else {
      throw platformError("The system could not enumerate network interfaces")
    }
    defer { freeifaddrs(list) }
    var addresses: [String: [String]] = [:]
    var flags: [String: UInt32] = [:]
    var entry = list
    while let current = entry {
      let name = String(cString: current.pointee.ifa_name)
      flags[name] = current.pointee.ifa_flags
      if let address = current.pointee.ifa_addr, let mask = current.pointee.ifa_netmask,
        let prefix = Self.addressPrefix(address, mask)
      {
        addresses[name, default: []].append(prefix)
      }
      entry = current.pointee.ifa_next
    }
    lock.lock()
    let currentPath = path
    lock.unlock()
    let types = Dictionary(
      uniqueKeysWithValues: (currentPath?.availableInterfaces ?? []).map { ($0.name, $0.type) })
    let interfaces = flags.keys.sorted().map { name in
      let item = LibboxNetworkInterface()
      item.name = name
      item.index = Int32(if_nametoindex(name))
      item.mtu = Self.interfaceMTU(name)
      item.addresses = AppleStrings(addresses[name] ?? [])
      item.flags = Int32(bitPattern: flags[name] ?? 0)
      item.dnsServer = AppleStrings([])
      item.gateway = AppleStrings([])
      item.metered =
        currentPath?.isExpensive == true
        && currentPath?.availableInterfaces.contains { $0.name == name } == true
      switch types[name] {
      case .wifi: item.type = LibboxInterfaceTypeWIFI
      case .cellular: item.type = LibboxInterfaceTypeCellular
      case .wiredEthernet: item.type = LibboxInterfaceTypeEthernet
      default: item.type = LibboxInterfaceTypeOther
      }
      return item
    }
    return AppleInterfaces(interfaces)
  }

  private static func interfaceMTU(_ name: String) -> Int32 {
    let descriptor = socket(AF_INET, SOCK_DGRAM, 0)
    guard descriptor >= 0 else { return 0 }
    defer { Darwin.close(descriptor) }
    var request = ifreq()
    withUnsafeMutableBytes(of: &request.ifr_name) { bytes in
      for (index, byte) in name.utf8.prefix(Int(IFNAMSIZ) - 1).enumerated() { bytes[index] = byte }
    }
    // Darwin's public _IOWR('i', 51, struct ifreq). Swift cannot import
    // SIOCGIFMTU because the C macro takes a structure type argument.
    let getMTU = UInt(0xc000_0000) | (UInt(MemoryLayout<ifreq>.size) << 16) | (UInt(0x69) << 8) | 51
    guard ioctl(descriptor, getMTU, &request) == 0 else { return 0 }
    return request.ifr_ifru.ifru_mtu
  }

  private static func addressPrefix(
    _ address: UnsafeMutablePointer<sockaddr>, _ mask: UnsafeMutablePointer<sockaddr>
  ) -> String? {
    let family = Int32(address.pointee.sa_family)
    guard family == AF_INET || family == AF_INET6 else { return nil }
    var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
    guard
      getnameinfo(
        address, socklen_t(address.pointee.sa_len), &host, socklen_t(host.count), nil, 0,
        NI_NUMERICHOST) == 0
    else {
      return nil
    }
    let bits: Int
    if family == AF_INET {
      bits = mask.withMemoryRebound(to: sockaddr_in.self, capacity: 1) {
        $0.pointee.sin_addr.s_addr.nonzeroBitCount
      }
    } else {
      bits = mask.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) {
        withUnsafeBytes(of: $0.pointee.sin6_addr) { bytes in
          bytes.reduce(0) { $0 + $1.nonzeroBitCount }
        }
      }
    }
    return "\(String(cString: host).split(separator: "%")[0])/\(bits)"
  }

  private func prefixes(_ iterator: LibboxRoutePrefixIteratorProtocol?) -> [LibboxRoutePrefix] {
    guard let iterator else { return [] }
    var values: [LibboxRoutePrefix] = []
    while iterator.hasNext() { if let next = iterator.next() { values.append(next) } }
    return values
  }

  private func strings(_ iterator: LibboxStringIteratorProtocol?) -> [String] {
    guard let iterator else { return [] }
    var values: [String] = []
    while iterator.hasNext() { values.append(iterator.next()) }
    return values
  }

  private func platformError(_ message: String) -> NSError {
    NSError(domain: "dev.avalon.host", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
  }
  private var unsupported: NSError { platformError("This platform operation is not supported") }

  func useProcFS() -> Bool { false }
  func findConnectionOwner(
    _ ipProtocol: Int32, sourceAddress: String?, sourcePort: Int32,
    destinationAddress: String?, destinationPort: Int32
  ) throws -> LibboxConnectionOwner {
    #if os(macOS)
      var failure: NSError?
      guard
        let owner = LibboxFindConnectionOwner(
          ipProtocol, sourceAddress, sourcePort,
          destinationAddress, destinationPort, &failure), failure == nil
      else {
        throw platformError("The connection's process could not be identified")
      }
      return owner
    #else
      throw unsupported
    #endif
  }
  func localDNSTransport() -> LibboxLocalDNSTransportProtocol? { nil }
  func readWIFIState() -> LibboxWIFIState? { nil }
  func clearDNSCache() {}
  func registerMyInterface(_ name: String?) {}
  func tailscaleHostname() -> String { deviceName }
  func send(_ notification: LibboxNotification?) throws {}
  func cancelNotification(_ identifier: String?, typeID: Int32) throws {}
  func startNeighborMonitor(_ listener: LibboxNeighborUpdateListenerProtocol?) throws {}
  func closeNeighborMonitor(_ listener: LibboxNeighborUpdateListenerProtocol?) throws {}
  func usePlatformShell() -> Bool { false }
  func checkPlatformShell() throws { throw unsupported }
  func openShellSession(
    _ user: LibboxPlatformUser?, command: String?, environ: LibboxStringIteratorProtocol?,
    term: String?, rows: Int32, cols: Int32
  ) throws -> LibboxShellSessionProtocol { throw unsupported }
  func lookupUser(_ username: String?) throws -> LibboxPlatformUser { throw unsupported }
  func lookupSFTPServer(_ error: NSErrorPointer) -> String {
    error?.pointee = unsupported
    return ""
  }
  func readSystemSSHHostKey(_ error: NSErrorPointer) -> String {
    error?.pointee = unsupported
    return ""
  }
  func usePlatformBridge() -> Bool { false }
  func createBridge(_ options: LibboxBridgeOptions?) throws -> LibboxBridgeSessionProtocol {
    throw unsupported
  }
}
