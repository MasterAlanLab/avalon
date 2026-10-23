import AvalonCore
import Foundation
import NetworkExtension

/// Owns sing-box and the tunnel independently of the Flutter process.
final class PacketTunnelProvider: NEPacketTunnelProvider {
  private let lifecycle = DispatchQueue(label: "dev.avalon.tunnel.lifecycle", qos: .userInitiated)
  private let observations = DispatchQueue(
    label: "dev.avalon.tunnel.commands", qos: .userInitiated, attributes: .concurrent)
  private let hostLock = NSLock()
  private var host: MobileHost?
  private var platform: ApplePlatform?
  private var storage: HostStorage?
  private var stopping = false
  // Native bookkeeping can fail after the bridge accepted a command.
  // Keep those failures authoritative over the bridge's success cache.
  private var nativeFailures: [String: String] = [:]
  private var failureOrder: [String] = []
  private var choiceSyncPending = false

  override func startTunnel(
    options: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void
  ) {
    lifecycle.async {
      self.hostLock.lock()
      self.stopping = false
      self.hostLock.unlock()
      do {
        let (host, storage) = try self.ensureHost()
        let request: String
        if let supplied = options?["request"] as? String {
          request = supplied
        } else if let restored = try storage.restoredStartRequest() {
          request = restored
        } else {
          throw self.nativeError("There is no accepted tunnel plan to restore")
        }
        guard let object = self.object(request), let identifier = object["requestId"] as? String
        else {
          throw self.nativeError("Invalid tunnel start request")
        }
        let cached = self.cachedLifecycleResponse("start", request: request, host: host)
        let response: String
        do {
          if let cached {
            response = cached
          } else {
            try self.validate(object, storage: storage)
            response = host.call("start", request: request)
          }
        } catch {
          try storage.recordStartResponse(
            requestID: identifier,
            response: self.errorResponse("PLAN_INVALID", "Invalid protected tunnel plan path"))
          throw self.nativeError("Invalid tunnel plan path")
        }
        // Record before following bookkeeping can fail, so the app can
        // recover a rejected plan's precise, already-redacted bridge error.
        try storage.recordStartResponse(requestID: identifier, response: response)
        if cached == nil {
          do { try self.finishLifecycle("start", request: request, response: response) } catch {
            let failure = self.errorResponse(
              "CORE_FAILED", "The accepted tunnel plan could not be protected")
            self.rememberNativeFailure(request: request, response: failure)
            try storage.recordStartResponse(requestID: identifier, response: failure)
            throw error
          }
        }
        if self.object(response)?["error"] != nil {
          throw self.nativeError("The core could not start the tunnel")
        }
        completionHandler(nil)
      } catch {
        self.closeHost()
        completionHandler(self.nativeError("The VPN host could not start the tunnel"))
      }
    }
  }

  override func stopTunnel(
    with reason: NEProviderStopReason, completionHandler: @escaping () -> Void
  ) {
    lifecycle.async {
      self.closeHost()
      completionHandler()
    }
  }

  override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)? = nil) {
    guard messageData.count <= 1_048_576,
      let envelope = try? JSONSerialization.jsonObject(with: messageData) as? [String: Any],
      let command = envelope["command"] as? String,
      let request = envelope["request"] as? String,
      Self.commands.contains(command)
    else {
      completionHandler?(Data(errorResponse("UNSUPPORTED", "Invalid host command").utf8))
      return
    }
    let queue = Self.lifecycleCommands.contains(command) ? lifecycle : observations
    queue.async {
      let response: String
      do {
        let (host, storage) = try self.ensureHost()
        #if os(macOS)
          if command == "configureHost" {
            try self.applyMacOptions(host: host, storage: storage)
            completionHandler?(Data("{\"result\":{}}".utf8))
            return
          }
        #endif
        if let cached = self.cachedLifecycleResponse(command, request: request, host: host) {
          // The app has already renamed plan.next.json after acceptance.
          // Replaying a request must not reread that vanished candidate.
          response = cached
        } else {
          do {
            guard let object = self.object(request) else {
              throw self.nativeError("Invalid host request")
            }
            try self.validate(object, storage: storage)
          } catch {
            let failure = self.errorResponse("PLAN_INVALID", "Invalid protected host path")
            if Self.lifecycleCommands.contains(command) {
              self.rememberNativeFailure(request: request, response: failure)
            }
            completionHandler?(Data(failure.utf8))
            return
          }
          let raw =
            command == "queryCommand"
            ? (self.nativeQueryResponse(request) ?? host.call(command, request: request))
            : host.call(command, request: request)
          if Self.lifecycleCommands.contains(command) {
            try self.finishLifecycle(command, request: request, response: raw)
          }
          response = command == "snapshot" ? self.withTunnelFacts(raw) : raw
        }
      } catch {
        response = self.errorResponse("CORE_FAILED", "The host could not complete the command")
        if Self.lifecycleCommands.contains(command) {
          self.rememberNativeFailure(request: request, response: response)
        }
      }
      completionHandler?(Data(response.utf8))
      if command == "snapshot" { self.scheduleChoiceSync() }
      if command != "stop", Self.lifecycleCommands.contains(command), self.sessionHasEnded() {
        // Send the command's real error first. The system session must not
        // remain "connected" after a restart or protection failure stopped
        // the core. Delaying until the next turn lets NE forward the reply.
        self.lifecycle.async {
          if self.sessionHasEnded() {
            self.cancelTunnelWithError(self.nativeError("The VPN core is no longer running"))
          }
        }
      }
    }
  }

  private func ensureHost() throws -> (MobileHost, HostStorage) {
    hostLock.lock()
    defer { hostLock.unlock() }
    guard !stopping else { throw nativeError("The tunnel host is stopping") }
    if let host, let storage { return (host, storage) }
    let shared = try HostStorage()
    var error: NSError?
    MobileSetup(shared.base.path, shared.state.path, shared.cache.path, &error)
    if error != nil { throw nativeError("The core could not initialize its protected storage") }
    let adapter = ApplePlatform(
      provider: self,
      deviceName: (protocolConfiguration as? NETunnelProviderProtocol)?
        .providerConfiguration?["deviceName"] as? String ?? "Avalon")
    #if os(macOS)
      let platformName = "macos"
    #else
      let platformName = "ios"
    #endif
    guard let created = MobileNewHost(adapter, platformName, &error), error == nil else {
      throw nativeError("The core could not initialize")
    }
    platform = adapter
    storage = shared
    host = created
    return (created, shared)
  }

  private func closeHost() {
    hostLock.lock()
    let current = host
    let adapter = platform
    let shared = storage
    stopping = true
    host = nil
    platform = nil
    storage = nil
    hostLock.unlock()
    current?.close()
    try? adapter?.clearTunnel()
    try? shared?.ensureProtectedFiles()
  }

  private func finishLifecycle(_ command: String, request: String, response: String) throws {
    hostLock.lock()
    let current = host
    let adapter = platform
    let shared = storage
    hostLock.unlock()
    guard let current, let adapter, let shared else {
      throw nativeError("The host is not available")
    }
    let snapshot = object(current.call("snapshot", request: "{}"))?["result"] as? [String: Any]
    let running = snapshot?["state"] as? String == "running"
    // A rejected reload still has the old accepted session and native
    // settings. Never clear them based on the new plan's requested flags.
    #if os(macOS)
      // Proxy-only sessions have no TUN. Preserve their applied settings
      // across mode/selection commands and rejected reloads.
      if !running { try adapter.clearTunnel() }
    #else
      if !running || snapshot?["tunActive"] as? Bool != true { try adapter.clearTunnel() }
    #endif
    do {
      if command == "start" || command == "reload", object(response)?["error"] == nil, running {
        #if os(macOS)
          try applyMacOptions(host: current, storage: shared)
        #endif
        try shared.recordAcceptedPlan(request)
      }
      if command == "select" || command == "setMode", object(response)?["error"] == nil, running,
        let mode = snapshot?["mode"] as? String
      {
        try shared.recordAcceptedChoices(
          mode: mode, selections: snapshot?["selections"] as? [String: String] ?? [:])
      }
      try shared.ensureProtectedFiles()
    } catch {
      if running {
        _ = current.call("stop", request: "{\"requestId\":\"\(UUID().uuidString)\"}")
        try? adapter.clearTunnel()
      }
      throw nativeError("The accepted tunnel plan could not be protected")
    }
  }

  private func withTunnelFacts(_ response: String) -> String {
    guard var envelope = object(response), var snapshot = envelope["result"] as? [String: Any]
    else { return response }
    hostLock.lock()
    let facts = platform?.snapshotFacts()
    hostLock.unlock()
    let running = snapshot["state"] as? String == "running"
    snapshot["tunActive"] =
      running && snapshot["tunActive"] as? Bool == true && facts?.tunActive == true
    #if os(macOS)
      snapshot["systemProxyActive"] = running && facts?.systemProxyActive == true
    #else
      snapshot["systemProxyActive"] =
        running && facts?.systemProxyActive == true && snapshot["tunActive"] as? Bool == true
    #endif
    envelope["result"] = snapshot
    guard let data = try? JSONSerialization.data(withJSONObject: envelope),
      let text = String(data: data, encoding: .utf8)
    else {
      return errorResponse("CORE_FAILED", "The host snapshot could not be encoded")
    }
    return text
  }

  #if os(macOS)
    private func applyMacOptions(host: MobileHost, storage: HostStorage) throws {
      guard
        let snapshot = object(host.call("snapshot", request: "{}"))?["result"] as? [String: Any],
        snapshot["state"] as? String == "running", snapshot["tunActive"] as? Bool != true
      else { return }
      let path = storage.state.appendingPathComponent("host-options.json")
      var options: [String: Any] = [:]
      if FileManager.default.fileExists(atPath: path.path) {
        options =
          (try JSONSerialization.jsonObject(
            with: Data(contentsOf: storage.validatePlanPath(path.path)))) as? [String: Any] ?? [:]
      }
      hostLock.lock()
      let adapter = platform
      hostLock.unlock()
      guard let adapter else { throw nativeError("The native proxy adapter is unavailable") }
      try adapter.applyProxyOnly(
        enabled: options["systemProxy"] as? Bool == true
          && snapshot["proxyActive"] as? Bool == true,
        port: options["mixedPort"] as? Int ?? 7890)
    }
  #endif

  private func cachedLifecycleResponse(_ command: String, request: String, host: MobileHost)
    -> String?
  {
    guard Self.lifecycleCommands.contains(command),
      let identifier = object(request)?["requestId"] as? String
    else { return nil }
    hostLock.lock()
    let native = nativeFailures[identifier]
    hostLock.unlock()
    if let native { return native }
    guard
      let data = try? JSONSerialization.data(withJSONObject: ["requestId": identifier]),
      let query = String(data: data, encoding: .utf8),
      let status = object(host.call("queryCommand", request: query))?["result"] as? [String: Any],
      let state = status["status"] as? String,
      state == "done" || state == "failed"
    else { return nil }
    let key = state == "done" ? "result" : "error"
    guard let result = status[key],
      let encoded = try? JSONSerialization.data(withJSONObject: [key: result])
    else { return nil }
    return String(data: encoded, encoding: .utf8)
  }

  private func rememberNativeFailure(request: String, response: String) {
    guard let identifier = object(request)?["requestId"] as? String else { return }
    hostLock.lock()
    if nativeFailures[identifier] == nil { failureOrder.append(identifier) }
    nativeFailures[identifier] = response
    while failureOrder.count > 64 { nativeFailures.removeValue(forKey: failureOrder.removeFirst()) }
    hostLock.unlock()
  }

  private func nativeQueryResponse(_ request: String) -> String? {
    guard let identifier = object(request)?["requestId"] as? String else { return nil }
    hostLock.lock()
    let failure = nativeFailures[identifier]
    hostLock.unlock()
    guard let failure, let error = object(failure)?["error"],
      let data = try? JSONSerialization.data(withJSONObject: [
        "result": ["status": "failed", "error": error]
      ])
    else { return nil }
    return String(data: data, encoding: .utf8)
  }

  private func sessionHasEnded() -> Bool {
    hostLock.lock()
    let current = host
    hostLock.unlock()
    guard let current,
      let snapshot = object(current.call("snapshot", request: "{}"))?["result"] as? [String: Any],
      let state = snapshot["state"] as? String
    else { return false }
    return state == "failed" || state == "stopped"
  }

  private func scheduleChoiceSync() {
    hostLock.lock()
    guard !stopping, !choiceSyncPending else {
      hostLock.unlock()
      return
    }
    choiceSyncPending = true
    hostLock.unlock()
    lifecycle.async {
      defer {
        self.hostLock.lock()
        self.choiceSyncPending = false
        self.hostLock.unlock()
      }
      self.hostLock.lock()
      let current = self.host
      let shared = self.storage
      let adapter = self.platform
      self.hostLock.unlock()
      guard let current, let shared,
        let snapshot = self.object(current.call("snapshot", request: "{}"))?["result"]
          as? [String: Any],
        snapshot["state"] as? String == "running", let hash = snapshot["planHash"] as? String,
        let mode = snapshot["mode"] as? String
      else { return }
      do {
        // Read inside the lifecycle queue, rather than persisting the
        // observer's older snapshot across a concurrent reload.
        guard try shared.acceptedPlanHash() == hash else { return }
        try shared.recordAcceptedChoices(
          mode: mode, selections: snapshot["selections"] as? [String: String] ?? [:])
      } catch {
        _ = current.call("stop", request: "{\"requestId\":\"\(UUID().uuidString)\"}")
        try? adapter?.clearTunnel()
        self.cancelTunnelWithError(
          self.nativeError("The active tunnel choices could not be protected"))
      }
    }
  }

  private func validate(_ object: [String: Any], storage: HostStorage) throws {
    if let path = object["planPath"] as? String { _ = try storage.validatePlanPath(path) }
    if let destination = object["destPath"] as? String {
      let url = URL(fileURLWithPath: destination).standardizedFileURL
      let root = storage.state.appendingPathComponent("rulesets", isDirectory: true)
        .standardizedFileURL
      let parent = url.deletingLastPathComponent()
      let files = FileManager.default
      guard destination.hasPrefix("/"), url.path.hasPrefix(root.path + "/"),
        root.resolvingSymlinksInPath().path == root.path,
        parent.resolvingSymlinksInPath().path == parent.path,
        url.resolvingSymlinksInPath().path == url.path,
        try files.attributesOfItem(atPath: parent.path)[.type] as? FileAttributeType
          == .typeDirectory
      else {
        throw nativeError("The destination is outside protected rule-set storage")
      }
      if let attributes = try? files.attributesOfItem(atPath: url.path),
        attributes[.type] as? FileAttributeType != .typeRegular
      {
        throw nativeError("The rule-set destination is not a regular protected file")
      }
    }
  }

  private func object(_ text: String) -> [String: Any]? {
    (try? JSONSerialization.jsonObject(with: Data(text.utf8))) as? [String: Any]
  }
  private func nativeError(_ message: String) -> NSError {
    NSError(domain: "dev.avalon.host", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
  }
  private func errorResponse(_ code: String, _ message: String) -> String {
    let value = ["error": ["code": code, "message": message]]
    return String(data: try! JSONSerialization.data(withJSONObject: value), encoding: .utf8)!
  }
  private static let lifecycleCommands: Set<String> = Set([
    "start", "reload", "stop", "select", "setMode",
  ]).union(platformCommands)
  private static let commands: Set<String> = Set([
    "capabilities", "start", "reload", "stop", "setMode", "select", "urlTest", "fetch",
    "queryCommand",
    "snapshot", "connections", "closeConnection", "closeAllConnections", "logs", "tailnetStatus",
    "tailnetLogin", "tailnetLogout",
  ]).union(platformCommands)
  #if os(macOS)
    private static let platformCommands: Set<String> = ["configureHost"]
  #else
    private static let platformCommands: Set<String> = []
  #endif
}
