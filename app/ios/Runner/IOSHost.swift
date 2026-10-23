import AvalonCore
import Flutter
import Foundation
import NetworkExtension
import UIKit

/// Flutter speaks the bridge protocol; only the Network Extension can own
/// a connected engine. The app's instance is limited to disconnected tests.
final class IOSHost: NSObject {
  private let probeHost = ProbeHost(deviceName: UIDevice.current.name)
  private var manager: NETunnelProviderManager?
  private var snapshotRevision: Int64 = 0
  private var responses: [String: String] = [:]
  private var responseOrder: [String] = []
  private var pending: Set<String> = []
  private var lastStartID = ""
  private var startingRequestID: String?
  private var stopGeneration: UInt64 = 0

  static func register(with registrar: FlutterPluginRegistrar) {
    let instance = IOSHost()
    let channel = FlutterMethodChannel(
      name: "dev.avalon/host", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      Task { @MainActor in
        do { result(try await instance.handle(call)) } catch let failure as Failure {
          result(FlutterError(code: failure.code, message: failure.message, details: nil))
        } catch {
          result(
            FlutterError(
              code: "HOST_UNREACHABLE", message: "The iOS host could not complete the request",
              details: nil))
        }
      }
    }
  }

  @MainActor private func handle(_ call: FlutterMethodCall) async throws -> Any? {
    switch call.method {
    case "facts":
      let storage = try planStorage()
      return ["stateDir": storage.state.path, "deviceName": UIDevice.current.name]
    case "prepare":
      try await prepare()
      return true
    case "release":
      await probeHost.close()
      return nil
    case "configure":
      guard let options = call.arguments as? String,
        Self.object(options) != nil
      else { throw Failure("PLAN_INVALID", "Invalid host options") }
      let storage = try Self.privateStorage()
      try storage.writeProtected(
        Data(options.utf8), to: storage.state.appendingPathComponent("host-options.json"))
      return nil
    case "call":
      guard let arguments = call.arguments as? [String: Any],
        let command = arguments["command"] as? String,
        let request = arguments["request"] as? String,
        Self.commands.contains(command), let object = Self.object(request)
      else { throw Failure("UNSUPPORTED", "Invalid host command") }
      var response = try await callBridge(command, request: request, object: object)
      if command == "snapshot", var envelope = Self.object(response),
        var snapshot = envelope["result"] as? [String: Any]
      {
        // The app and extension are different bridge instances. Revisions
        // at this transport boundary stay ordered across their lifetimes.
        snapshotRevision += 1
        snapshot["revision"] = snapshotRevision
        envelope["result"] = snapshot
        response = try Self.encode(envelope)
      }
      return response
    default: return FlutterMethodNotImplemented
    }
  }

  @MainActor private func callBridge(_ command: String, request: String, object: [String: Any])
    async throws -> String
  {
    let identifier = object["requestId"] as? String ?? ""
    if command == "queryCommand" {
      if pending.contains(identifier) { return try Self.encode(["result": ["status": "pending"]]) }
      if let response = responses[identifier], let envelope = Self.object(response) {
        var status: [String: Any] = ["status": envelope["error"] == nil ? "done" : "failed"]
        if let result = envelope["result"] { status["result"] = result }
        if let error = envelope["error"] { status["error"] = error }
        return try Self.encode(["result": status])
      }
      if identifier == lastStartID, let storage = try? HostStorage(),
        let response = try storage.startResponse(requestID: identifier),
        let error = Self.object(response)?["error"]
      {
        return try Self.encode(["result": ["status": "failed", "error": error]])
      }
    }
    let mutation = Self.mutations.contains(command)
    if mutation {
      guard !identifier.isEmpty else {
        throw Failure("PLAN_INVALID", "A command identifier is required")
      }
      if let response = responses[identifier] { return response }
      guard !pending.contains(identifier) else {
        throw Failure("TIMEOUT", "The command is still in progress")
      }
      pending.insert(identifier)
    }
    do {
      let response = try await dispatch(command, request: request, object: object)
      if mutation { remember(identifier, response: response) }
      return response
    } catch {
      if mutation {
        let failure =
          error as? Failure
          ?? Failure("HOST_UNREACHABLE", "The iOS host could not complete the command")
        // A transport timeout does not prove that the extension rejected
        // the command. Let queryCommand read the extension's own outcome.
        if failure.code == "TIMEOUT" || failure.code == "HOST_UNREACHABLE" {
          pending.remove(identifier)
        } else {
          remember(
            identifier,
            response: try Self.encode(["error": ["code": failure.code, "message": failure.message]])
          )
        }
      }
      throw error
    }
  }

  @MainActor private func dispatch(_ command: String, request: String, object: [String: Any])
    async throws -> String
  {
    if command == "capabilities" { return try await probeHost.call(command, request: request) }
    if command == "start" { return try await start(request: request, object: object) }
    // A stop arriving after Dart timed out must also cancel a start that
    // is still waiting for an outbound test to release the app instance.
    if command == "stop" { stopGeneration &+= 1 }
    let existing = try await existingManager()
    if command == "stop", let session = existing?.connection as? NETunnelProviderSession,
      session.status == .connecting || session.status == .disconnecting
    {
      session.stopTunnel()
      try await waitUntilStopped(session)
      return try await probeHost.call(command, request: request)
    }
    if let session = existing?.connection as? NETunnelProviderSession,
      session.status == .connected || session.status == .reasserting
    {
      let response = try await send(command, request: request, session: session)
      if command == "stop", Self.object(response)?["error"] == nil {
        session.stopTunnel()
        try await waitUntilStopped(session)
      }
      return response
    }
    if command == "reload" {
      throw Failure("SESSION_MISMATCH", "There is no running packet tunnel")
    }
    if command == "urlTest", let session = existing?.connection,
      session.status == .connecting || session.status == .disconnecting
    {
      throw Failure("SESSION_MISMATCH", "The packet tunnel is changing state")
    }
    if command == "urlTest" { try validatePlan(object, storage: planStorage()) }
    // Bridge observations of the disconnected test instance are real. It
    // never receives start/reload and its platform adapter refuses openTun.
    return try await probeHost.call(command, request: request)
  }

  @MainActor private func prepare() async throws {
    #if targetEnvironment(simulator)
      throw Failure(
        "UNSUPPORTED", "Packet Tunnel VPN is unavailable in the iOS Simulator; use an iPhone")
    #else
      do { _ = try HostStorage() } catch {
        throw Failure("PERMISSION_DENIED", "The signed App Group container is unavailable")
      }
      guard !HostStorage.tunnelBundleIdentifier.isEmpty else {
        throw Failure("PERMISSION_DENIED", "The packet tunnel extension is not configured")
      }
      let selected = try await existingManager() ?? NETunnelProviderManager()
      let configuration = NETunnelProviderProtocol()
      configuration.providerBundleIdentifier = HostStorage.tunnelBundleIdentifier
      configuration.serverAddress = "Avalon"
      configuration.providerConfiguration = ["deviceName": UIDevice.current.name]
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
    #endif
  }

  @MainActor private func existingManager() async throws -> NETunnelProviderManager? {
    #if targetEnvironment(simulator)
      return nil
    #else
      if let manager { return manager }
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
      } catch {
        throw Failure("PERMISSION_DENIED", "The system VPN configuration could not be read")
      }
    #endif
  }

  @MainActor private func start(request: String, object: [String: Any]) async throws -> String {
    #if targetEnvironment(simulator)
      throw Failure(
        "UNSUPPORTED", "Packet Tunnel VPN is unavailable in the iOS Simulator; use an iPhone")
    #else
      guard startingRequestID == nil else {
        throw Failure("SESSION_MISMATCH", "A packet tunnel start is already in progress")
      }
      startingRequestID = object["requestId"] as? String
      let generation = stopGeneration
      defer { startingRequestID = nil }
      let storage: HostStorage
      do { storage = try HostStorage() } catch {
        throw Failure("PERMISSION_DENIED", "The signed App Group container is unavailable")
      }
      if try await existingManager() == nil { try await prepare() }
      guard let session = manager?.connection as? NETunnelProviderSession else {
        throw Failure("HOST_UNREACHABLE", "The packet tunnel session is unavailable")
      }
      if session.status == .connected || session.status == .reasserting {
        return try await send("start", request: request, session: session)
      }
      try validatePlan(object, storage: storage)
      await probeHost.close()
      guard stopGeneration == generation else {
        throw Failure("SESSION_MISMATCH", "The packet tunnel start was cancelled by a stop request")
      }
      do { try session.startTunnel(options: ["request": request as NSString]) } catch {
        throw Failure("PERMISSION_DENIED", "The system could not start the packet tunnel")
      }
      let identifier = object["requestId"] as? String ?? ""
      lastStartID = identifier
      let deadline = Date().addingTimeInterval(28)
      while Date() < deadline {
        guard stopGeneration == generation else {
          throw Failure(
            "SESSION_MISMATCH", "The packet tunnel start was cancelled by a stop request")
        }
        if let original = try storage.startResponse(requestID: identifier),
          Self.object(original)?["error"] != nil
        {
          return original
        }
        if session.status == .connected || session.status == .reasserting {
          let query = try Self.encode(["requestId": identifier])
          let response = try await send("queryCommand", request: query, session: session)
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
      // Do not cancel a command just because Flutter's request timed out:
      // queryCommand must still be able to observe its eventual result.
      throw Failure("TIMEOUT", "The packet tunnel did not acknowledge its start")
    #endif
  }

  @MainActor private func waitUntilStopped(_ session: NETunnelProviderSession) async throws {
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
      let timeout = Self.messageTimeout(command, request: request)
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

  private static func messageTimeout(_ command: String, request: String) -> TimeInterval {
    if command == "start" || command == "reload" { return 28 }
    let object = Self.object(request) ?? [:]
    let milliseconds = (object["timeoutMs"] as? NSNumber)?.doubleValue ?? 0
    if command == "urlTest" {
      let perTest = milliseconds <= 0 ? 5 : min(milliseconds / 1000, 30)
      let count = (object["tags"] as? [String])?.count ?? 0
      return perTest * max(1, ceil(Double(count) / 8)) + 28
    }
    if command == "fetch" {
      return (milliseconds <= 0 ? 30 : min(milliseconds / 1000, 300)) + 4
    }
    return 4
  }

  private final class ProviderReply {
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

  /// Only these worker-owned fields cross threads. Go serializes its
  /// lifecycle; the lock protects instance initialization and shutdown.
  private final class ProbeHost: @unchecked Sendable {
    private let probeQueue = DispatchQueue(label: "dev.avalon.probe", qos: .userInitiated)
    private let observationQueue = DispatchQueue(
      label: "dev.avalon.probe.observations", qos: .userInitiated, attributes: .concurrent)
    private let probeLock = NSLock()
    private var probe: MobileHost?
    private let deviceName: String
    init(deviceName: String) { self.deviceName = deviceName }
    func call(_ command: String, request: String) async throws -> String {
      let queue = IOSHost.observations.contains(command) ? observationQueue : probeQueue
      return try await withCheckedThrowingContinuation { continuation in
        queue.async {
          do {
            let host = try self.ensureProbe()
            continuation.resume(returning: host.call(command, request: request))
          } catch {
            continuation.resume(
              throwing: Failure("CORE_FAILED", "The disconnected test core could not initialize"))
          }
        }
      }
    }

    private func ensureProbe() throws -> MobileHost {
      probeLock.lock()
      defer { probeLock.unlock() }
      if let probe { return probe }
      let storage = try IOSHost.privateStorage()
      var error: NSError?
      MobileSetup(storage.base.path, storage.state.path, storage.cache.path, &error)
      guard error == nil,
        let host = MobileNewHost(
          ApplePlatform(provider: nil, deviceName: deviceName), "ios", &error),
        error == nil
      else { throw Failure("CORE_FAILED", "The disconnected test core could not initialize") }
      probe = host
      return host
    }

    func close() async {
      await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
        probeQueue.async {
          self.probeLock.lock()
          self.probe?.close()
          self.probe = nil
          self.probeLock.unlock()
          continuation.resume()
        }
      }
    }

  }

  private static func privateStorage() throws -> HostStorage {
    let support = try FileManager.default.url(
      for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    return try HostStorage(
      privateBase: support.appendingPathComponent("Avalon/ios-probe", isDirectory: true))
  }

  private func planStorage() throws -> HostStorage {
    // Unsigned simulator builds have no registered App Group. Local features
    // and the test instance still work; prepare/start strictly require it.
    if let shared = try? HostStorage() { return shared }
    return try Self.privateStorage()
  }

  private func validatePlan(_ object: [String: Any], storage: HostStorage) throws {
    do {
      if let path = object["planPath"] as? String { _ = try storage.validatePlanPath(path) }
    } catch { throw Failure("PLAN_INVALID", "The runtime plan is outside protected host storage") }
  }

  @MainActor private func remember(_ identifier: String, response: String) {
    pending.remove(identifier)
    responses[identifier] = response
    responseOrder.removeAll { $0 == identifier }
    responseOrder.append(identifier)
    while responseOrder.count > 64 { responses.removeValue(forKey: responseOrder.removeFirst()) }
  }

  private static func object(_ text: String) -> [String: Any]? {
    (try? JSONSerialization.jsonObject(with: Data(text.utf8))) as? [String: Any]
  }
  private static func encode(_ object: [String: Any]) throws -> String {
    String(decoding: try JSONSerialization.data(withJSONObject: object), as: UTF8.self)
  }
  private struct Failure: Error {
    let code: String
    let message: String
    init(_ code: String, _ message: String) {
      self.code = code
      self.message = message
    }
  }
  private static let observations: Set<String> = [
    "capabilities", "snapshot", "logs", "queryCommand", "connections", "tailnetStatus",
  ]
  private static let mutations: Set<String> = [
    "start", "reload", "stop", "setMode", "select", "closeConnection", "closeAllConnections",
    "tailnetLogin", "tailnetLogout",
  ]
  private static let commands: Set<String> = observations.union(mutations).union([
    "urlTest", "fetch",
  ])
}
