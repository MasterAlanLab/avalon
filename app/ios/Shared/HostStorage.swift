import Darwin
import Foundation

/// Only runtime plans and engine state cross the App Group boundary. The
/// application's database, vault and secure-storage key remain app-private.
final class HostStorage {
  static var appGroupIdentifier: String {
    Bundle.main.object(forInfoDictionaryKey: "AvalonAppGroup") as? String ?? ""
  }
  static var tunnelBundleIdentifier: String {
    Bundle.main.object(forInfoDictionaryKey: "AvalonTunnelBundleIdentifier") as? String ?? ""
  }

  let base: URL
  let state: URL
  let cache: URL
  private let files = FileManager.default
  private let maximumPlanSize = 64 * 1024 * 1024

  convenience init(groupIdentifier: String = HostStorage.appGroupIdentifier) throws {
    guard !groupIdentifier.isEmpty,
      let container = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: groupIdentifier)
    else { throw Self.failure("The shared VPN storage is unavailable") }
    try self.init(privateBase: container.appendingPathComponent("Avalon", isDirectory: true))
  }

  /// Used exclusively by the app's outbound-only test instance. It cannot
  /// substitute for the shared container when starting a packet tunnel.
  init(privateBase: URL) throws {
    // Apple can spell its legitimate container through /var, a system
    // alias for /private/var. Publish one canonical root; submitted paths
    // still cannot introduce symbolic links beneath that root.
    // Foundation resolves an aliased parent reliably only after the final
    // directory exists. Set restrictive attributes at creation, then
    // canonicalize before publishing any paths to Dart or the engine.
    let requested = privateBase.standardizedFileURL
    try FileManager.default.createDirectory(
      at: requested, withIntermediateDirectories: true, attributes: Self.attributes(directory: true)
    )
    base = requested.resolvingSymlinksInPath()
    state = base.appendingPathComponent("state", isDirectory: true)
    cache = base.appendingPathComponent("cache", isDirectory: true)
    try protect(base, directory: true)
    for directory in [state, cache] {
      try files.createDirectory(
        at: directory, withIntermediateDirectories: true,
        attributes: Self.attributes(directory: true))
      guard directory.resolvingSymlinksInPath().path == directory.path else {
        throw Self.failure("The engine storage contains an aliased directory")
      }
      try protect(directory, directory: true)
    }
  }

  func validatePlanPath(_ path: String) throws -> URL {
    let url = URL(fileURLWithPath: path).standardizedFileURL
    let root = state.resolvingSymlinksInPath().path + "/"
    guard url.path.hasPrefix(root), url.resolvingSymlinksInPath().path == url.path else {
      throw Self.failure("The plan is outside protected host storage")
    }
    let attributes = try files.attributesOfItem(atPath: url.path)
    guard attributes[.type] as? FileAttributeType == .typeRegular,
      let size = attributes[.size] as? NSNumber, size.intValue <= maximumPlanSize
    else { throw Self.failure("The runtime plan is not a regular protected file") }
    try protect(url, directory: false)
    return url
  }

  /// Persist the accepted plan and its hash together. Flutter may rename the
  /// submitted file after acknowledgement; restoration never follows that
  /// mutable path or pairs a new plan with an old hash.
  func recordAcceptedPlan(_ request: String) throws {
    guard let object = try JSONSerialization.jsonObject(with: Data(request.utf8)) as? [String: Any],
      let hash = object["planHash"] as? String, !hash.isEmpty
    else { throw Self.failure("The accepted plan has no hash") }
    let accepted: Any
    if let path = object["planPath"] as? String {
      accepted = try JSONSerialization.jsonObject(with: Data(contentsOf: validatePlanPath(path)))
    } else if let inline = object["plan"] as? [String: Any] {
      accepted = inline
    } else {
      throw Self.failure("The accepted plan is missing")
    }
    guard accepted is [String: Any] else { throw Self.failure("The accepted plan is invalid") }
    let envelope: [String: Any] = ["plan": accepted, "planHash": hash]
    try writeProtected(
      JSONSerialization.data(withJSONObject: envelope),
      to: state.appendingPathComponent("accepted-plan.json"))
  }

  func restoredStartRequest() throws -> String? {
    let url = state.appendingPathComponent("accepted-plan.json")
    guard files.fileExists(atPath: url.path) else { return nil }
    guard
      var object = try JSONSerialization.jsonObject(
        with: Data(contentsOf: validatePlanPath(url.path))) as? [String: Any],
      object["plan"] is [String: Any], let hash = object["planHash"] as? String, !hash.isEmpty
    else { throw Self.failure("The saved runtime plan is invalid") }
    object["requestId"] = UUID().uuidString
    object["utcOffsetSeconds"] = TimeZone.current.secondsFromGMT()
    return String(decoding: try JSONSerialization.data(withJSONObject: object), as: UTF8.self)
  }

  func recordAcceptedChoices(mode: String, selections: [String: String]) throws {
    let url = state.appendingPathComponent("accepted-plan.json")
    guard
      var envelope = try JSONSerialization.jsonObject(
        with: Data(contentsOf: validatePlanPath(url.path))) as? [String: Any],
      var accepted = envelope["plan"] as? [String: Any],
      let hash = envelope["planHash"] as? String, !hash.isEmpty
    else { throw Self.failure("The accepted runtime plan is missing") }
    let previous = accepted as NSDictionary
    if var outbounds = accepted["outbounds"] as? [[String: Any]] {
      for index in outbounds.indices {
        if outbounds[index]["type"] as? String == "selector",
          let tag = outbounds[index]["tag"] as? String,
          let member = selections[tag]
        {
          outbounds[index]["default"] = member
        }
      }
      accepted["outbounds"] = outbounds
    }
    if !mode.isEmpty, var experimental = accepted["experimental"] as? [String: Any],
      var controller = experimental["clash_api"] as? [String: Any]
    {
      controller["default_mode"] = mode
      experimental["clash_api"] = controller
      accepted["experimental"] = experimental
    }
    guard !previous.isEqual(to: accepted) else { return }
    envelope["plan"] = accepted
    try writeProtected(JSONSerialization.data(withJSONObject: envelope), to: url)
  }

  func acceptedPlanHash() throws -> String? {
    let url = state.appendingPathComponent("accepted-plan.json")
    guard files.fileExists(atPath: url.path) else { return nil }
    guard
      let envelope = try JSONSerialization.jsonObject(
        with: Data(contentsOf: validatePlanPath(url.path))) as? [String: Any],
      let hash = envelope["planHash"] as? String, !hash.isEmpty
    else { throw Self.failure("The saved runtime plan has no hash") }
    return hash
  }

  func recordStartResponse(requestID: String, response: String) throws {
    // The bridge already sanitizes its public error response. Do not persist
    // the request or an NSError's possibly sensitive userInfo.
    let value: [String: Any] = ["requestId": requestID, "response": response]
    try writeProtected(
      JSONSerialization.data(withJSONObject: value),
      to: state.appendingPathComponent("start-result.json"))
  }

  func startResponse(requestID: String) throws -> String? {
    let url = state.appendingPathComponent("start-result.json")
    guard files.fileExists(atPath: url.path) else { return nil }
    guard
      let object = try JSONSerialization.jsonObject(
        with: Data(contentsOf: validatePlanPath(url.path))) as? [String: Any],
      object["requestId"] as? String == requestID
    else { return nil }
    return object["response"] as? String
  }

  func ensureProtectedFiles() throws {
    guard
      let items = files.enumerator(
        at: base, includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey])
    else {
      throw Self.failure("The engine storage could not be protected")
    }
    for case let url as URL in items {
      let values = try url.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
      guard values.isSymbolicLink != true else {
        throw Self.failure("Engine storage contains a symbolic link")
      }
      try protect(url, directory: values.isDirectory == true)
    }
  }

  func writeProtected(_ data: Data, to url: URL) throws {
    guard data.count <= maximumPlanSize,
      url.standardizedFileURL.path.hasPrefix(base.path + "/"),
      url.deletingLastPathComponent().resolvingSymlinksInPath().path
        == url.deletingLastPathComponent().path
    else { throw Self.failure("The protected host file is invalid") }
    let temporary = url.deletingLastPathComponent().appendingPathComponent(
      ".write-" + UUID().uuidString)
    defer { try? files.removeItem(at: temporary) }
    guard
      files.createFile(
        atPath: temporary.path, contents: data, attributes: Self.attributes(directory: false))
    else {
      throw Self.failure("The protected host file could not be written")
    }
    try protect(temporary, directory: false)
    guard rename(temporary.path, url.path) == 0 else {
      throw Self.failure("The protected host file could not be replaced")
    }
  }

  private func protect(_ url: URL, directory: Bool) throws {
    try files.setAttributes(Self.attributes(directory: directory), ofItemAtPath: url.path)
    var protected = url
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    try protected.setResourceValues(values)
  }

  private static func attributes(directory: Bool) -> [FileAttributeKey: Any] {
    var attributes: [FileAttributeKey: Any] = [.posixPermissions: directory ? 0o700 : 0o600]
    #if os(iOS)
      attributes[.protectionKey] = FileProtectionType.completeUntilFirstUserAuthentication
    #endif
    return attributes
  }

  private static func failure(_ message: String) -> NSError {
    NSError(domain: "dev.avalon.storage", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
  }
}
