import Cocoa
import FlutterMacOS
import Foundation
import NetworkExtension
import Security
import SystemExtensions

/// Only the system extension owns the core. This app forwards the existing
/// bridge protocol over Apple's provider messaging, and never loads AvalonCore.
@MainActor final class MacHost: NSObject, @preconcurrency OSSystemExtensionRequestDelegate {
  private var manager: NETunnelProviderManager?
  private var revision: Int64 = 0
  private var activation: CheckedContinuation<Void, Error>?
  private var activationRequest: OSSystemExtensionRequest?
  private var activated = false
  private var responses: [String: String] = [:]
  private var responseOrder: [String] = []
  private var pending: Set<String> = []
  private var starting = false
  private var stopGeneration: UInt64 = 0
  private var lastStartID = ""

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = MacHost()
    let channel = FlutterMethodChannel(
      name: "dev.avalon/host", binaryMessenger: registrar.messenger)
    channel.setMethodCallHandler { call, result in
      Task { @MainActor in
        do { result(try await instance.handle(call)) } catch let error as Failure {
          result(FlutterError(code: error.code, message: error.message, details: nil))
        } catch {
          result(
            FlutterError(
              code: "HOST_UNREACHABLE",
              message: "The macOS VPN host could not complete the request", details: nil))
        }
      }
    }
  }

  private func handle(_ call: FlutterMethodCall) async throws -> Any? {
    switch call.method {
    case "facts":
      return ["stateDir": try planStorage().state.path, "deviceName": deviceName]
    case "prepare":
      try await prepare()
      return true
    case "release":
      return nil
    case "configure":
      guard let options = call.arguments as? String, Self.object(options) != nil else {
        throw Failure("PLAN_INVALID", "Invalid host options")
      }
      let storage = try planStorage()
      try storage.writeProtected(
        Data(options.utf8),
        to: storage.state.appendingPathComponent("host-options.json"))
      if let session = try await existingManager()?.connection as? NETunnelProviderSession,
        session.status == .connected || session.status == .reasserting
      {
        let response = try await send("configureHost", request: "{}", session: session)
        if let error = Self.object(response)?["error"] as? [String: Any] {
          throw Failure(
            error["code"] as? String ?? "CORE_FAILED",
            error["message"] as? String ?? "The proxy settings could not be applied")
        }
      }
      return nil
    case "call":
      guard let args = call.arguments as? [String: Any],
        let command = args["command"] as? String,
        let request = args["request"] as? String,
        Self.commands.contains(command), let object = Self.object(request)
      else {
        throw Failure("UNSUPPORTED", "Invalid host command")
      }
      var response = try await callBridge(command, request: request, object: object)
      if command == "snapshot", var envelope = Self.object(response),
        var snapshot = envelope["result"] as? [String: Any]
      {
        revision += 1
        snapshot["revision"] = revision
        envelope["result"] = snapshot
        response = try Self.encode(envelope)
      }
      return response
    default:
      return FlutterMethodNotImplemented
    }
  }

  private var deviceName: String { Host.current().localizedName ?? "Mac" }

  private func planStorage() throws -> HostStorage {
    do { return try HostStorage() } catch {
      #if DEBUG
        // Unsigned local UI builds can compile plans, but this directory can
        // never be used by prepare/start or substituted for the signed group.
        let directory = try FileManager.default.url(
          for: .applicationSupportDirectory,
          in: .userDomainMask, appropriateFor: nil, create: true)
        return try HostStorage(
          privateBase: directory.appendingPathComponent("AvalonHost", isDirectory: true))
      #else
        throw Failure("PERMISSION_DENIED", "The signed App Group container is unavailable")
      #endif
    }
  }

  private func callBridge(_ command: String, request: String, object: [String: Any]) async throws
    -> String
  {
    let id = object["requestId"] as? String ?? ""
    if command == "queryCommand" {
      if pending.contains(id) { return try Self.encode(["result": ["status": "pending"]]) }
      if let response = responses[id], let envelope = Self.object(response) {
        var status: [String: Any] = ["status": envelope["error"] == nil ? "done" : "failed"]
        if let result = envelope["result"] { status["result"] = result }
        if let error = envelope["error"] { status["error"] = error }
        return try Self.encode(["result": status])
      }
      if id == lastStartID, let storage = try? HostStorage(),
        let response = try storage.startResponse(requestID: id),
        let error = Self.object(response)?["error"]
      {
        return try Self.encode(["result": ["status": "failed", "error": error]])
      }
    }
    let mutation = Self.mutations.contains(command)
    if mutation {
      guard !id.isEmpty else { throw Failure("PLAN_INVALID", "A command identifier is required") }
      if let response = responses[id] { return response }
      guard !pending.contains(id) else {
        throw Failure("TIMEOUT", "The command is still in progress")
      }
      pending.insert(id)
    }
    do {
      let response = try await dispatch(command, request: request, object: object)
      if mutation { remember(id, response: response) }
      return response
    } catch {
      if mutation {
        let failure =
          error as? Failure ?? Failure("HOST_UNREACHABLE", "The VPN host is unavailable")
        if failure.code == "TIMEOUT" || failure.code == "HOST_UNREACHABLE" {
          pending.remove(id)
        } else {
          remember(
            id,
            response: try Self.encode(["error": ["code": failure.code, "message": failure.message]])
          )
        }
      }
      throw error
    }
  }

  private func dispatch(_ command: String, request: String, object: [String: Any]) async throws
    -> String
  {
    if command == "start" { return try await start(request: request, object: object) }
    if command == "stop" { stopGeneration &+= 1 }
    if let session = try await existingManager()?.connection as? NETunnelProviderSession {
      if command == "stop", session.status == .connecting || session.status == .disconnecting {
        session.stopTunnel()
        try await waitUntilStopped(session)
        return try Self.encode(["result": [:]])
      }
      if session.status == .connected || session.status == .reasserting {
        let response = try await send(command, request: request, session: session)
        if command == "stop", Self.object(response)?["error"] == nil {
          session.stopTunnel()
          try await waitUntilStopped(session)
        }
        return response
      }
    }
    switch command {
    case "capabilities":
      // Version comes from the framework build metadata, not an app engine.
      let info = Bundle.main.object(forInfoDictionaryKey: "AvalonCoreVersion") as? String ?? ""
      let publicNetwork =
        (Bundle.main.object(forInfoDictionaryKey: "AvalonPublicNetworkVersion") as? String)
        .flatMap(Int.init) ?? 0
      return try Self.encode([
        "result": [
          "protocolVersion": 1, "coreVersion": info, "platform": "macos",
          "publicNetworkVersion": publicNetwork,
        ]
      ])
    case "snapshot":
      return try Self.encode([
        "result": [
          "state": "stopped", "revision": revision,
          "sessionId": "", "planHash": "", "mode": "rule", "selections": [:],
          "upTotal": 0, "downTotal": 0, "todayUp": 0, "todayDown": 0,
          "upBps": 0, "downBps": 0,
          "proxyActive": false, "tailnetActive": false,
          "tunActive": false, "systemProxyActive": false,
        ]
      ])
    case "logs": return try Self.encode(["result": ["entries": [], "nextSeq": 0]])
    case "connections": return try Self.encode(["result": ["connections": []]])
    case "stop", "closeAllConnections", "closeConnection": return try Self.encode(["result": [:]])
    case "queryCommand": return try Self.encode(["result": ["status": "unknown"]])
    case "urlTest":
      throw Failure("UNSUPPORTED", "Connect the macOS VPN host before testing latency")
    case "fetch":
      throw Failure("SESSION_MISMATCH", "There is no running VPN host for this download")
    case "tailnetStatus": return try Self.encode(["result": ["state": "disabled", "peers": []]])
    default: throw Failure("SESSION_MISMATCH", "There is no running VPN host")
    }
  }

  private func requireSignedHost() throws {
    var code: SecCode?
    var staticCode: SecStaticCode?
    var information: CFDictionary?
    guard SecCodeCopySelf([], &code) == errSecSuccess, let code,
      SecCodeCopyStaticCode(code, [], &staticCode) == errSecSuccess, let staticCode,
      SecCodeCopySigningInformation(
        staticCode, SecCSFlags(rawValue: kSecCSSigningInformation), &information) == errSecSuccess,
      let info = information as? [String: Any],
      let team = info[kSecCodeInfoTeamIdentifier as String] as? String, !team.isEmpty,
      let entitlements = info[kSecCodeInfoEntitlementsDict as String] as? [String: Any],
      entitlements["com.apple.developer.system-extension.install"] as? Bool == true,
      (entitlements["com.apple.security.application-groups"] as? [String])?.contains(
        HostStorage.appGroupIdentifier) == true
    else {
      throw Failure(
        "PERMISSION_DENIED",
        "A signed developer team and VPN entitlements are required for the macOS host")
    }
    do { _ = try HostStorage() } catch {
      throw Failure("PERMISSION_DENIED", "The signed App Group container is unavailable")
    }
    let path = Bundle.main.bundleURL.path
    guard path.hasPrefix("/Applications/") || path.hasPrefix(NSHomeDirectory() + "/Applications/")
    else {
      throw Failure(
        "PERMISSION_DENIED",
        "Install the signed Avalon app in Applications before enabling its system extension")
    }
  }

  private func prepare() async throws {
    try requireSignedHost()
    try await activate()
    let selected = try await existingManager() ?? NETunnelProviderManager()
    let configuration = NETunnelProviderProtocol()
    configuration.providerBundleIdentifier = HostStorage.tunnelBundleIdentifier
    configuration.serverAddress = "Avalon"
    configuration.providerConfiguration = ["deviceName": deviceName]
    selected.protocolConfiguration = configuration
    selected.localizedDescription = "Avalon"
    selected.isEnabled = true
    do {
      try await withCheckedThrowingContinuation {
        (continuation: CheckedContinuation<Void, Error>) in
        selected.saveToPreferences { error in
          if let error { continuation.resume(throwing: error) } else { continuation.resume() }
        }
      }
      try await withCheckedThrowingContinuation {
        (continuation: CheckedContinuation<Void, Error>) in
        selected.loadFromPreferences { error in
          if let error { continuation.resume(throwing: error) } else { continuation.resume() }
        }
      }
      manager = selected
    } catch {
      throw Failure("PERMISSION_DENIED", "The system did not authorize the VPN configuration")
    }
  }

  private func existingManager() async throws -> NETunnelProviderManager? {
    if let manager { return manager }
    // Unsigned local builds have no permitted VPN configurations. Do not
    // turn their read-only startup observations into a system authorization.
    do { try requireSignedHost() } catch { return nil }
    do {
      let values = try await withCheckedThrowingContinuation {
        (continuation: CheckedContinuation<[NETunnelProviderManager], Error>) in
        NETunnelProviderManager.loadAllFromPreferences { values, error in
          if let error {
            continuation.resume(throwing: error)
          } else {
            continuation.resume(returning: values ?? [])
          }
        }
      }
      manager = values.first {
        ($0.protocolConfiguration as? NETunnelProviderProtocol)?.providerBundleIdentifier
          == HostStorage.tunnelBundleIdentifier
      }
      return manager
    } catch { throw Failure("PERMISSION_DENIED", "The system VPN configuration could not be read") }
  }

  private func activate() async throws {
    if activated { return }
    guard activationRequest == nil else {
      throw Failure(
        "PERMISSION_DENIED", "Approve the pending Avalon system extension in System Settings")
    }
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      let request = OSSystemExtensionRequest.activationRequest(
        forExtensionWithIdentifier: HostStorage.tunnelBundleIdentifier, queue: .main)
      activation = continuation
      activationRequest = request
      request.delegate = self
      OSSystemExtensionManager.shared.submitRequest(request)
    }
  }

  func requestNeedsUserApproval(_ request: OSSystemExtensionRequest) {
    guard activationRequest === request else { return }
    finishActivation(
      .failure(
        Failure(
          "PERMISSION_DENIED",
          "Approve the Avalon network extension in System Settings, then connect again")))
    // Keep the delegated request alive: the user may approve it later.
  }
  func request(
    _ request: OSSystemExtensionRequest, didFinishWithResult result: OSSystemExtensionRequest.Result
  ) {
    guard activationRequest === request else { return }
    activated = result == .completed
    finishActivation(
      activated
        ? .success(())
        : .failure(
          Failure("PERMISSION_DENIED", "Restart macOS to complete network extension activation")))
    activationRequest = nil
  }
  func request(_ request: OSSystemExtensionRequest, didFailWithError error: Error) {
    guard activationRequest === request else { return }
    finishActivation(
      .failure(
        Failure(
          "PERMISSION_DENIED", "The system could not activate the signed Avalon network extension"))
    )
    activationRequest = nil
  }
  func request(
    _ request: OSSystemExtensionRequest,
    actionForReplacingExtension existing: OSSystemExtensionProperties,
    withExtension replacement: OSSystemExtensionProperties
  ) -> OSSystemExtensionRequest.ReplacementAction { .replace }

  private func finishActivation(_ result: Result<Void, Error>) {
    let continuation = activation
    activation = nil
    continuation?.resume(with: result)
  }

  private func start(request: String, object: [String: Any]) async throws -> String {
    guard !starting else { throw Failure("SESSION_MISMATCH", "A VPN start is already in progress") }
    starting = true
    defer { starting = false }
    let generation = stopGeneration
    try requireSignedHost()
    let storage = try HostStorage()
    if try await existingManager() == nil { try await prepare() }
    guard let session = manager?.connection as? NETunnelProviderSession else {
      throw Failure("HOST_UNREACHABLE", "The packet tunnel session is unavailable")
    }
    guard generation == stopGeneration else {
      throw Failure("SESSION_MISMATCH", "The VPN start was cancelled by a stop request")
    }
    if session.status == .connected || session.status == .reasserting {
      return try await send("start", request: request, session: session)
    }
    guard let path = object["planPath"] as? String else {
      throw Failure("PLAN_INVALID", "A protected runtime plan path is required")
    }
    _ = try storage.validatePlanPath(path)
    do { try session.startTunnel(options: ["request": request as NSString]) } catch {
      throw Failure("PERMISSION_DENIED", "The system could not start the packet tunnel")
    }
    let id = object["requestId"] as? String ?? ""
    lastStartID = id
    let deadline = Date().addingTimeInterval(28)
    while Date() < deadline {
      guard generation == stopGeneration else {
        session.stopTunnel()
        throw Failure("SESSION_MISMATCH", "The VPN start was cancelled by a stop request")
      }
      if let original = try storage.startResponse(requestID: id),
        Self.object(original)?["error"] != nil
      {
        return original
      }
      if session.status == .connected || session.status == .reasserting {
        let response = try await send(
          "queryCommand", request: Self.encode(["requestId": id]), session: session)
        if let status = Self.object(response)?["result"] as? [String: Any] {
          if status["status"] as? String == "done", let result = status["result"] {
            return try Self.encode(["result": result])
          }
          if status["status"] as? String == "failed", let error = status["error"] {
            return try Self.encode(["error": error])
          }
        }
      }
      try await Task.sleep(nanoseconds: 100_000_000)
    }
    throw Failure("TIMEOUT", "The packet tunnel did not acknowledge its start")
  }

  private func waitUntilStopped(_ session: NETunnelProviderSession) async throws {
    let deadline = Date().addingTimeInterval(4)
    while Date() < deadline {
      if session.status == .disconnected || session.status == .invalid { return }
      try await Task.sleep(nanoseconds: 100_000_000)
    }
    throw Failure("TIMEOUT", "The system is still stopping the packet tunnel")
  }

  private func send(_ command: String, request: String, session: NETunnelProviderSession)
    async throws -> String
  {
    let data = try JSONSerialization.data(withJSONObject: ["command": command, "request": request])
    guard data.count <= 1_048_576 else {
      throw Failure("PLAN_INVALID", "The host command is too large for IPC")
    }
    return try await withCheckedThrowingContinuation {
      (continuation: CheckedContinuation<String, Error>) in
      let reply = ProviderReply(continuation)
      let object = Self.object(request) ?? [:]
      let milliseconds = (object["timeoutMs"] as? NSNumber)?.doubleValue ?? 0
      var timeout: TimeInterval = command == "reload" ? 28 : 4
      if command == "urlTest" {
        timeout =
          (milliseconds <= 0 ? 5 : min(milliseconds / 1000, 30))
          * max(1, ceil(Double((object["tags"] as? [String])?.count ?? 0) / 8)) + 28
      } else if command == "fetch" {
        timeout = (milliseconds <= 0 ? 30 : min(milliseconds / 1000, 300)) + 4
      }
      let deadline = DispatchWorkItem {
        reply.finish(
          .failure(Failure("TIMEOUT", "The packet tunnel host did not acknowledge the command")))
      }
      DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: deadline)
      do {
        try session.sendProviderMessage(data) { response in
          deadline.cancel()
          guard let response, let text = String(data: response, encoding: .utf8),
            Self.object(text) != nil
          else {
            reply.finish(
              .failure(Failure("HOST_UNREACHABLE", "The packet tunnel host did not answer")))
            return
          }
          reply.finish(.success(text))
        }
      } catch {
        deadline.cancel()
        reply.finish(.failure(Failure("HOST_UNREACHABLE", "The packet tunnel host is unavailable")))
      }
    }
  }

  private func remember(_ id: String, response: String) {
    pending.remove(id)
    if responses[id] == nil { responseOrder.append(id) }
    responses[id] = response
    while responseOrder.count > 64 { responses.removeValue(forKey: responseOrder.removeFirst()) }
  }
  private static func object(_ text: String) -> [String: Any]? {
    (try? JSONSerialization.jsonObject(with: Data(text.utf8))) as? [String: Any]
  }
  private static func encode(_ value: [String: Any]) throws -> String {
    String(decoding: try JSONSerialization.data(withJSONObject: value), as: UTF8.self)
  }
  private struct Failure: Error {
    let code: String
    let message: String
    init(_ code: String, _ message: String) {
      self.code = code
      self.message = message
    }
  }
  private final class ProviderReply: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<String, Error>?
    init(_ continuation: CheckedContinuation<String, Error>) { self.continuation = continuation }
    func finish(_ result: Result<String, Error>) {
      lock.lock()
      let current = continuation
      continuation = nil
      lock.unlock()
      current?.resume(with: result)
    }
  }
  private static let mutations: Set<String> = [
    "start", "reload", "stop", "setMode", "select",
    "urlTest", "fetch", "closeConnection", "closeAllConnections", "tailnetLogin", "tailnetLogout",
  ]
  private static let commands: Set<String> = mutations.union([
    "capabilities", "queryCommand", "snapshot",
    "logs", "connections", "tailnetStatus",
  ])
}
