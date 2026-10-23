// S1 spike: the Core Bridge driven from Swift through the xcframework, as
// the Apple network extension will. No TUN here (that needs a signed
// Packet Tunnel on a device): a mixed inbound on the loopback, the same
// commands, and a probe through it across reloads. Deleted once the
// findings are written down.
//
//   swiftc -O main.swift -F ../../out/AvalonCore.xcframework/macos-arm64_x86_64 \
//     -framework AvalonCore -lresolv -o ../../out/s1-apple && ../../out/s1-apple
import AvalonCore
import Foundation
import Network

final class Strings: NSObject, LibboxStringIteratorProtocol {
  private let values: [String]
  private var at = 0
  init(_ values: [String]) { self.values = values }
  func hasNext() -> Bool { at < values.count }
  func len() -> Int32 { Int32(values.count) }
  func next() -> String {
    defer { at += 1 }
    return values[at]
  }
}

final class Interfaces: NSObject, LibboxNetworkInterfaceIteratorProtocol {
  private var rest: [LibboxNetworkInterface]
  init(_ all: [LibboxNetworkInterface]) { rest = all }
  func hasNext() -> Bool { !rest.isEmpty }
  func next() -> LibboxNetworkInterface? { rest.removeFirst() }
}

/// What sing-box asks of an Apple host.
final class Platform: NSObject, LibboxPlatformInterfaceProtocol {
  private let queue = DispatchQueue(label: "avalon.spike.network")
  private var monitor: NWPathMonitor?
  private var path: NWPath?

  func usePlatformAutoDetectControl() -> Bool { false }
  func autoDetectControl(_ fd: Int32) throws {}

  func openTun(_ options: LibboxTunOptionsProtocol?, ret0_: UnsafeMutablePointer<Int32>?) throws {
    throw NSError(domain: "spike", code: 1, userInfo: [NSLocalizedDescriptionKey: "no TUN outside a network extension"])
  }

  func startDefaultInterfaceMonitor(_ listener: LibboxInterfaceUpdateListenerProtocol?) throws {
    guard let listener else { return }
    let monitor = NWPathMonitor()
    let first = DispatchSemaphore(value: 0)
    var reported = false
    monitor.pathUpdateHandler = { [weak self] path in
      self?.path = path
      if let interface = path.availableInterfaces.first, path.status != .unsatisfied {
        print("default interface: \(interface.name) (\(interface.index))")
        listener.updateDefaultInterface(
          interface.name, interfaceIndex: Int32(interface.index),
          isExpensive: path.isExpensive, isConstrained: path.isConstrained)
      } else {
        listener.updateDefaultInterface("", interfaceIndex: -1, isExpensive: false, isConstrained: false)
      }
      if !reported {
        reported = true
        first.signal()
      }
    }
    monitor.start(queue: queue)
    self.monitor = monitor
    // The core starts dialling right after this returns.
    _ = first.wait(timeout: .now() + 2)
  }

  func closeDefaultInterfaceMonitor(_ listener: LibboxInterfaceUpdateListenerProtocol?) throws {
    monitor?.cancel()
    monitor = nil
  }

  func getInterfaces() throws -> LibboxNetworkInterfaceIteratorProtocol {
    // Addresses and flags by name, from the system's interface list.
    var addresses: [String: [String]] = [:]
    var flags: [String: UInt32] = [:]
    var list: UnsafeMutablePointer<ifaddrs>?
    if getifaddrs(&list) == 0 {
      var entry = list
      while let current = entry {
        let name = String(cString: current.pointee.ifa_name)
        flags[name] = current.pointee.ifa_flags
        if let address = current.pointee.ifa_addr, let mask = current.pointee.ifa_netmask,
          let text = Platform.prefix(address, mask)
        {
          addresses[name, default: []].append(text)
        }
        entry = current.pointee.ifa_next
      }
      freeifaddrs(list)
    }
    var found: [LibboxNetworkInterface] = []
    for interface in path?.availableInterfaces ?? [] {
      let item = LibboxNetworkInterface()
      item.name = interface.name
      item.index = Int32(interface.index)
      item.mtu = 1500
      item.addresses = Strings(addresses[interface.name] ?? [])
      item.flags = Int32(bitPattern: flags[interface.name] ?? 0)
      switch interface.type {
      case .wifi: item.type = LibboxInterfaceTypeWIFI
      case .cellular: item.type = LibboxInterfaceTypeCellular
      case .wiredEthernet: item.type = LibboxInterfaceTypeEthernet
      default: item.type = LibboxInterfaceTypeOther
      }
      found.append(item)
    }
    return Interfaces(found)
  }

  /// "address/prefix" of one interface address, IPv4 or IPv6.
  private static func prefix(_ address: UnsafeMutablePointer<sockaddr>, _ mask: UnsafeMutablePointer<sockaddr>) -> String? {
    let family = Int32(address.pointee.sa_family)
    guard family == AF_INET || family == AF_INET6 else { return nil }
    var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
    guard getnameinfo(address, socklen_t(address.pointee.sa_len), &host, socklen_t(host.count), nil, 0, NI_NUMERICHOST) == 0
    else { return nil }
    var bits = 0
    if family == AF_INET {
      mask.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { bits = $0.pointee.sin_addr.s_addr.nonzeroBitCount }
    } else {
      mask.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) { pointer in
        withUnsafeBytes(of: pointer.pointee.sin6_addr) { bits = $0.reduce(0) { $0 + $1.nonzeroBitCount } }
      }
    }
    let text = String(cString: host).split(separator: "%")[0]
    return "\(text)/\(bits)"
  }

  func useProcFS() -> Bool { false }
  func findConnectionOwner(
    _ ipProtocol: Int32, sourceAddress: String?, sourcePort: Int32, destinationAddress: String?, destinationPort: Int32
  ) throws -> LibboxConnectionOwner { throw unsupported }
  func localDNSTransport() -> LibboxLocalDNSTransportProtocol? { nil }
  func underNetworkExtension() -> Bool { false }
  func includeAllNetworks() -> Bool { false }
  func readWIFIState() -> LibboxWIFIState? { nil }
  func clearDNSCache() {}
  func registerMyInterface(_ name: String?) {}
  func tailscaleHostname() -> String { Host.current().localizedName ?? "mac" }
  func send(_ notification: LibboxNotification?) throws {}
  func cancelNotification(_ identifier: String?, typeID: Int32) throws {}
  func startNeighborMonitor(_ listener: LibboxNeighborUpdateListenerProtocol?) throws {}
  func closeNeighborMonitor(_ listener: LibboxNeighborUpdateListenerProtocol?) throws {}
  func usePlatformShell() -> Bool { false }
  func checkPlatformShell() throws { throw unsupported }
  func openShellSession(
    _ user: LibboxPlatformUser?, command: String?, environ: LibboxStringIteratorProtocol?, term: String?, rows: Int32,
    cols: Int32
  ) throws -> LibboxShellSessionProtocol { throw unsupported }
  func lookupUser(_ username: String?) throws -> LibboxPlatformUser { throw unsupported }
  func lookupSFTPServer(_ error: NSErrorPointer) -> String { "" }
  func readSystemSSHHostKey(_ error: NSErrorPointer) -> String { "" }
  func usePlatformBridge() -> Bool { false }
  func createBridge(_ options: LibboxBridgeOptions?) throws -> LibboxBridgeSessionProtocol { throw unsupported }

  private var unsupported: NSError {
    NSError(domain: "spike", code: 2, userInfo: [NSLocalizedDescriptionKey: "not supported"])
  }
}

func plan(_ port: Int) -> [String: Any] {
  [
    "log": ["level": "info"],
    "dns": ["servers": [["type": "local", "tag": "direct"]]],
    "inbounds": [["type": "mixed", "tag": "mixed-in", "listen": "127.0.0.1", "listen_port": port]],
    "outbounds": [
      ["type": "selector", "tag": "proxy", "outbounds": ["a", "b"], "default": "a"],
      ["type": "direct", "tag": "a"], ["type": "direct", "tag": "b"], ["type": "direct", "tag": "direct"],
    ],
    "route": [
      "rules": [
        ["action": "sniff"],
        ["clash_mode": "direct", "outbound": "direct"],
        ["clash_mode": "global", "outbound": "proxy"],
      ],
      "final": "proxy", "auto_detect_interface": true, "default_domain_resolver": "direct",
    ],
    "experimental": ["clash_api": ["default_mode": "rule"]],
  ]
}

func json(_ value: Any) -> String {
  String(data: try! JSONSerialization.data(withJSONObject: value), encoding: .utf8)!
}

let state = FileManager.default.temporaryDirectory.appendingPathComponent("avalon-s1-\(getpid())")
try FileManager.default.createDirectory(at: state, withIntermediateDirectories: true)
var setupError: NSError?
MobileSetup(state.path, state.path, state.path, &setupError)
if let setupError { fatalError("setup: \(setupError)") }
var hostError: NSError?
guard let host = MobileNewHost(Platform(), "macos", &hostError) else { fatalError("host: \(String(describing: hostError))") }

@discardableResult
func call(_ command: String, _ request: [String: Any] = [:]) -> [String: Any] {
  let began = DispatchTime.now()
  let raw = host.call(command, request: json(request))
  let ms = (DispatchTime.now().uptimeNanoseconds - began.uptimeNanoseconds) / 1_000_000
  print("\(command) (\(ms)ms) -> \(raw.prefix(420))")
  return (try? JSONSerialization.jsonObject(with: Data(raw.utf8))) as? [String: Any] ?? [:]
}

let port = 17890
let target = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "http://127.0.0.1:8799/"

call("capabilities")
var session = (call("start", ["requestId": "start", "plan": plan(port), "planHash": "h0"])["result"] as? [String: Any])?["sessionId"] as? String ?? ""
call("snapshot")

// Probe through the mixed inbound while reloading.
let configuration = URLSessionConfiguration.ephemeral
configuration.connectionProxyDictionary = [
  kCFNetworkProxiesHTTPEnable: true, kCFNetworkProxiesHTTPProxy: "127.0.0.1", kCFNetworkProxiesHTTPPort: port,
]
configuration.timeoutIntervalForRequest = 2
configuration.httpShouldUsePipelining = false
configuration.httpMaximumConnectionsPerHost = 1
var probing = true
var answered = 0
var total = 0
var worst = 0.0
let probe = Thread {
  var lastOk = 0.0
  var failures = 0
  while probing {
    // A fresh session each time: no connection is reused.
    let client = URLSession(configuration: configuration)
    let done = DispatchSemaphore(value: 0)
    var ok = false
    var request = URLRequest(url: URL(string: target)!)
    request.setValue("close", forHTTPHeaderField: "Connection")
    client.dataTask(with: request) { data, response, _ in
      ok = (response as? HTTPURLResponse)?.statusCode == 200 && data != nil
      done.signal()
    }.resume()
    done.wait()
    client.invalidateAndCancel()
    let now = ProcessInfo.processInfo.systemUptime
    total += 1
    if ok {
      answered += 1
      if failures > 0 && lastOk > 0 {
        let gap = (now - lastOk) * 1000
        worst = max(worst, gap)
        print(String(format: "probe: back after %.0fms without an answer (%d failed)", gap, failures))
      }
      failures = 0
      lastOk = now
    } else {
      failures += 1
    }
    Thread.sleep(forTimeInterval: 0.002)
  }
}
probe.start()
Thread.sleep(forTimeInterval: 0.5)

call("select", ["requestId": "s", "sessionId": session, "groupTag": "proxy", "memberTag": "b"])
call("setMode", ["requestId": "m", "sessionId": session, "mode": "global"])
call("snapshot")
for i in 1...5 {
  let result = call("reload", ["requestId": "r\(i)", "sessionId": session, "plan": plan(port), "planHash": "h\(i)"])
  session = (result["result"] as? [String: Any])?["sessionId"] as? String ?? session
  Thread.sleep(forTimeInterval: 0.6)
}
call("snapshot")
probing = false
Thread.sleep(forTimeInterval: 0.3)
print(String(format: "probe: %d of %d answered, worst outage %.0fms", answered, total, worst))

let page = call("logs", ["afterSeq": 0, "limit": 5])
_ = page
call("stop", ["requestId": "stop"])
call("snapshot")
host.close()
try? FileManager.default.removeItem(at: state)
