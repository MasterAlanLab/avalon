// HostStorage's filesystem invariants, exercised without signing, an App
// Group or a VPN. Run app/tool/check_ios_storage.sh on a macOS host.
import Darwin
import Foundation

@main
struct HostStorageChecks {
  private static let files = FileManager.default

  static func main() {
    do { try runChecks() } catch {
      let message = "HostStorage checks failed: \((error as NSError).localizedDescription)\n"
      FileHandle.standardError.write(Data(message.utf8))
      exit(1)
    }
  }

  private static func runChecks() throws {
    let root =
      ProcessInfo.processInfo.environment["AVALON_STORAGE_CHECK_DIR"]
      .map { URL(fileURLWithPath: $0, isDirectory: true) } ?? files.temporaryDirectory
    let temporary = root.resolvingSymlinksInPath()
      .appendingPathComponent("avalon-host-storage-" + UUID().uuidString, isDirectory: true)
    try files.createDirectory(at: temporary, withIntermediateDirectories: true)
    defer { try? files.removeItem(at: temporary) }
    let storage = try HostStorage(privateBase: temporary.appendingPathComponent("host"))

    for directory in [storage.base, storage.state, storage.cache] {
      try require(permissions(directory) == 0o700, "private directory permissions")
      try require(excluded(directory), "host directory excluded from backup")
    }
    try require(storage.restoredStartRequest() == nil, "no invented initial plan")
    try require(storage.startResponse(requestID: "missing") == nil, "no invented initial response")

    let submitted = storage.state.appendingPathComponent("submitted.json")
    let original: [String: Any] = ["outbounds": [["type": "direct", "tag": "original"]]]
    try storage.writeProtected(JSONSerialization.data(withJSONObject: original), to: submitted)
    try require(permissions(submitted) == 0o600, "private file permissions")
    try require(excluded(submitted), "runtime plan excluded from backup")
    try require(
      storage.validatePlanPath(submitted.path) == submitted, "protected regular plan accepted")

    let outside = temporary.appendingPathComponent("outside.json")
    try Data("{}".utf8).write(to: outside)
    try rejected("outside plan") { _ = try storage.validatePlanPath(outside.path) }
    try rejected("path traversal") {
      _ = try storage.validatePlanPath(storage.state.path + "/../../outside.json")
    }
    try rejected("directory in place of plan") {
      _ = try storage.validatePlanPath(storage.cache.path)
    }
    try rejected("outside protected write") { try storage.writeProtected(Data(), to: outside) }

    let link = storage.state.appendingPathComponent("linked.json")
    try files.createSymbolicLink(at: link, withDestinationURL: outside)
    try rejected("symbolic link plan") { _ = try storage.validatePlanPath(link.path) }
    try rejected("symbolic link in protected tree") { try storage.ensureProtectedFiles() }
    try files.removeItem(at: link)
    let parentLink = storage.state.appendingPathComponent("linked-directory")
    try files.createSymbolicLink(at: parentLink, withDestinationURL: temporary)
    try rejected("symbolic link parent read") {
      _ = try storage.validatePlanPath(parentLink.appendingPathComponent("outside.json").path)
    }
    try rejected("symbolic link parent write") {
      try storage.writeProtected(Data(), to: parentLink.appendingPathComponent("outside.json"))
    }
    try files.removeItem(at: parentLink)

    let oversized = storage.state.appendingPathComponent("oversized.json")
    files.createFile(atPath: oversized.path, contents: nil)
    let handle = try FileHandle(forWritingTo: oversized)
    try handle.truncate(atOffset: 64 * 1024 * 1024 + 1)
    try handle.close()
    try rejected("oversized runtime plan") { _ = try storage.validatePlanPath(oversized.path) }
    try files.removeItem(at: oversized)

    try rejected("accepted plan without hash") {
      try storage.recordAcceptedPlan(json(["planPath": submitted.path]))
    }
    try rejected("accepted plan without content") {
      try storage.recordAcceptedPlan(json(["planHash": "hash-only"]))
    }
    try storage.recordAcceptedPlan(json(["planPath": submitted.path, "planHash": "original-hash"]))
    // Flutter may overwrite or rename its mutable submitted path after the
    // acknowledgement. The saved plan and hash must remain one envelope.
    try storage.writeProtected(Data("{\"changed\":true}".utf8), to: submitted)
    try files.removeItem(at: submitted)
    let restored = try decode(storage.restoredStartRequest())
    try require(restored["planHash"] as? String == "original-hash", "accepted hash preserved")
    try require(
      try JSONSerialization.data(withJSONObject: restored["plan"]!, options: .sortedKeys)
        == JSONSerialization.data(withJSONObject: original, options: .sortedKeys),
      "accepted plan is independent of the submitted file")
    try require(restored["planPath"] == nil, "restoration uses immutable saved contents")
    try require(
      restored["utcOffsetSeconds"] as? Int == TimeZone.current.secondsFromGMT(),
      "restored time zone")
    let again = try decode(storage.restoredStartRequest())
    try require(
      restored["requestId"] as? String != again["requestId"] as? String,
      "restoration gets a fresh request identifier")
    let envelope = storage.state.appendingPathComponent("accepted-plan.json")
    try require(permissions(envelope) == 0o600 && excluded(envelope), "accepted envelope protected")

    let response = try json(["result": ["sessionId": "test-session"]])
    try storage.recordStartResponse(requestID: "start-one", response: response)
    try require(
      storage.startResponse(requestID: "start-one") == response, "start response matches request")
    try require(
      storage.startResponse(requestID: "start-two") == nil, "old start response is not reused")
    try storage.recordStartResponse(requestID: "start-two", response: "{\"result\":{}}")
    try require(
      storage.startResponse(requestID: "start-one") == nil,
      "replacement is bound to the new request")
    try require(
      try files.contentsOfDirectory(atPath: storage.state.path).allSatisfy {
        !$0.hasPrefix(".write-")
      },
      "atomic replacement leaves no temporary contents")

    // Files created by the engine are tightened before being retained.
    let looseDirectory = storage.cache.appendingPathComponent("engine", isDirectory: true)
    try files.createDirectory(
      at: looseDirectory, withIntermediateDirectories: true,
      attributes: [.posixPermissions: 0o755])
    let looseFile = looseDirectory.appendingPathComponent("engine-state")
    files.createFile(
      atPath: looseFile.path, contents: Data("test".utf8), attributes: [.posixPermissions: 0o644])
    try storage.ensureProtectedFiles()
    try require(
      permissions(looseDirectory) == 0o700 && permissions(looseFile) == 0o600,
      "engine files regain private permissions")
    try require(
      excluded(looseDirectory) && excluded(looseFile), "engine files excluded from backup")

    try checkAcceptedChoices(in: temporary)
    try checkCanonicalRoot(in: temporary)

    print(
      "HostStorage: filesystem boundaries, canonical root, accepted choices/hash restoration, request binding and protection checks passed"
    )
  }

  private static func checkAcceptedChoices(in temporary: URL) throws {
    let storage = try HostStorage(privateBase: temporary.appendingPathComponent("choices"))
    let envelope = storage.state.appendingPathComponent("accepted-plan.json")
    try require(storage.acceptedPlanHash() == nil, "no invented initial accepted hash")
    try rejected("choices without accepted envelope") {
      try storage.recordAcceptedChoices(mode: "global", selections: ["proxy": "b"])
    }
    try require(!files.fileExists(atPath: envelope.path), "choices do not invent an accepted plan")

    // Storage must preserve all JSON value types while replacing only
    // selector/mode strings; equality must also keep repeated choices a no-op.
    let untouched: [String: Any] = [
      "bool": true, "integer": 1, "number": 1.5, "string": "true", "null": NSNull(),
      "array": [true, 1, 1.5, "value", NSNull(), ["nested": false]],
    ]
    let original: [String: Any] = [
      "unmodified": untouched,
      "outbounds": [
        ["type": "direct", "tag": "a"],
        ["type": "direct", "tag": "b"],
        ["type": "selector", "tag": "proxy", "outbounds": ["a", "b"], "default": "a"],
        ["type": "selector", "tag": "backup", "outbounds": ["a", "b"], "default": "b"],
      ],
      "route": ["final": "proxy"],
      "experimental": [
        "clash_api": ["default_mode": "rule", "external_controller": "127.0.0.1:9090"]
      ],
    ]
    try storage.recordAcceptedPlan(json(["plan": original, "planHash": "structural-hash"]))
    try storage.recordAcceptedChoices(
      mode: "global", selections: ["proxy": "b", "backup": "a", "a": "b", "missing": "a"])
    let updated = try decode(storage.restoredStartRequest())
    let plan = updated["plan"] as? [String: Any] ?? [:]
    let outbounds = plan["outbounds"] as? [[String: Any]] ?? []
    try require(outbounds.count == 4, "accepted outbound structure is preserved")
    try require(outbounds[2]["default"] as? String == "b", "proxy selector choice updated")
    try require(outbounds[3]["default"] as? String == "a", "second selector choice updated")
    try require(outbounds[0]["default"] == nil, "choices never alter non-selector outbounds")
    let controller = (plan["experimental"] as? [String: Any])?["clash_api"] as? [String: Any]
    try require(controller?["default_mode"] as? String == "global", "accepted mode updated")
    try require(
      controller?["external_controller"] as? String == "127.0.0.1:9090",
      "mode update preserves controller settings")
    try require(
      storage.acceptedPlanHash() == "structural-hash"
        && updated["planHash"] as? String == "structural-hash",
      "mode and selector updates keep the structural plan hash")
    try require(
      (plan["route"] as? [String: String])?["final"] == "proxy",
      "choices preserve route structure")
    try require(
      JSONSerialization.data(withJSONObject: plan["unmodified"]!, options: [.sortedKeys])
        == JSONSerialization.data(withJSONObject: untouched, options: [.sortedKeys]),
      "choice equality preserves booleans, numbers, arrays, strings and null")
    try require(permissions(envelope) == 0o600 && excluded(envelope), "updated choices protected")

    // Checking the actual inode and modification date distinguishes a no-op
    // from unnecessarily replacing the accepted envelope with equal JSON.
    let oldDate = Date(timeIntervalSince1970: 100)
    try files.setAttributes([.modificationDate: oldDate], ofItemAtPath: envelope.path)
    let oldAttributes = try files.attributesOfItem(atPath: envelope.path)
    let oldContents = try Data(contentsOf: envelope)
    try storage.recordAcceptedChoices(mode: "global", selections: ["proxy": "b", "backup": "a"])
    try storage.recordAcceptedChoices(mode: "", selections: ["missing": "b", "a": "b"])
    let unchangedAttributes = try files.attributesOfItem(atPath: envelope.path)
    try require(
      oldAttributes[.systemFileNumber] as? NSNumber
        == unchangedAttributes[.systemFileNumber] as? NSNumber,
      "identical choices keep the accepted envelope inode")
    try require(
      unchangedAttributes[.modificationDate] as? Date == oldDate,
      "identical choices do not rewrite the accepted envelope")
    try require(
      Data(contentsOf: envelope) == oldContents, "no-op choices preserve accepted contents")

    // A rejected plan must leave the already accepted mode, choices and
    // structural hash available for restoration.
    try rejected("invalid replacement leaves accepted choices") {
      try storage.recordAcceptedPlan(json(["plan": original, "planHash": ""]))
    }
    try require(
      Data(contentsOf: envelope) == oldContents, "failed replacement keeps accepted choices")

    let corruptEnvelopes: [Data] = [
      Data("not-json".utf8),
      try JSONSerialization.data(withJSONObject: ["planHash": "no-plan"]),
      try JSONSerialization.data(withJSONObject: ["plan": original]),
      try JSONSerialization.data(withJSONObject: ["plan": original, "planHash": ""]),
    ]
    for corrupt in corruptEnvelopes {
      try storage.writeProtected(corrupt, to: envelope)
      try rejected("choices on a malformed accepted envelope") {
        try storage.recordAcceptedChoices(mode: "rule", selections: ["proxy": "a"])
      }
      try require(
        Data(contentsOf: envelope) == corrupt, "choices never repair an invalid envelope silently")
      try rejected("invalid accepted envelope cannot restore") {
        _ = try storage.restoredStartRequest()
      }
    }

    // Mode updates do not invent a controller for plans without one.
    let directOnly: [String: Any] = ["outbounds": [["type": "direct", "tag": "a"]]]
    try storage.recordAcceptedPlan(json(["plan": directOnly, "planHash": "direct-only-hash"]))
    let directContents = try Data(contentsOf: envelope)
    try storage.recordAcceptedChoices(mode: "global", selections: ["a": "b"])
    try require(
      Data(contentsOf: envelope) == directContents,
      "choices do not invent selectors or a controller")
    try require(
      storage.acceptedPlanHash() == "direct-only-hash", "direct-only structure hash preserved")
  }

  private static func checkCanonicalRoot(in temporary: URL) throws {
    let realParent = temporary.appendingPathComponent("canonical-real", isDirectory: true)
    try files.createDirectory(at: realParent, withIntermediateDirectories: true)
    let linkedParent = temporary.appendingPathComponent("canonical-linked", isDirectory: true)
    try files.createSymbolicLink(at: linkedParent, withDestinationURL: realParent)
    let storage = try HostStorage(privateBase: linkedParent.appendingPathComponent("host"))
    try require(
      storage.base.path == realParent.appendingPathComponent("host").path,
      "legitimate parent alias is resolved once at initialization")
    let plan = storage.state.appendingPathComponent("probe.json")
    try storage.writeProtected(Data("{}".utf8), to: plan)
    try require(
      storage.validatePlanPath(plan.path) == plan, "canonical storage accepts its protected files")
    let outside = realParent.appendingPathComponent("outside.json")
    try Data("{}".utf8).write(to: outside)
    let internalLink = storage.state.appendingPathComponent("linked.json")
    try files.createSymbolicLink(at: internalLink, withDestinationURL: outside)
    try rejected("internal aliases are still rejected after root normalization") {
      _ = try storage.validatePlanPath(internalLink.path)
    }
    try rejected("internal aliases are never retained") { try storage.ensureProtectedFiles() }

    for name in ["state", "cache"] {
      let untrustedBase = temporary.appendingPathComponent("aliased-" + name, isDirectory: true)
      let external = temporary.appendingPathComponent("external-" + name, isDirectory: true)
      try files.createDirectory(at: untrustedBase, withIntermediateDirectories: true)
      try files.createDirectory(at: external, withIntermediateDirectories: true)
      try files.setAttributes([.posixPermissions: 0o755], ofItemAtPath: external.path)
      let sentinel = external.appendingPathComponent("sentinel")
      try Data("unchanged".utf8).write(to: sentinel)
      try files.createSymbolicLink(
        at: untrustedBase.appendingPathComponent(name), withDestinationURL: external)
      try rejected("initial aliased engine directory") {
        _ = try HostStorage(privateBase: untrustedBase)
      }
      try require(permissions(external) == 0o755, "initial alias never changes outside permissions")
      try require(
        Data(contentsOf: sentinel) == Data("unchanged".utf8),
        "initial alias never writes outside engine storage")
      try require(
        files.contentsOfDirectory(atPath: external.path) == ["sentinel"],
        "initial alias never creates outside engine state")
    }
  }

  private static func permissions(_ url: URL) throws -> Int {
    (try files.attributesOfItem(atPath: url.path)[.posixPermissions] as? NSNumber)?.intValue ?? -1
  }

  private static func excluded(_ url: URL) throws -> Bool {
    try url.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup == true
  }

  private static func json(_ object: [String: Any]) throws -> String {
    String(decoding: try JSONSerialization.data(withJSONObject: object), as: UTF8.self)
  }

  private static func decode(_ encoded: String?) throws -> [String: Any] {
    guard let encoded,
      let object = try JSONSerialization.jsonObject(with: Data(encoded.utf8)) as? [String: Any]
    else { throw failed("restored request is missing or malformed") }
    return object
  }

  private static func require(_ condition: @autoclosure () throws -> Bool, _ label: String) throws {
    if try !condition() { throw failed(label) }
  }

  private static func rejected(_ label: String, _ operation: () throws -> Void) throws {
    do { try operation() } catch { return }
    throw failed("expected rejection: " + label)
  }

  private static func failed(_ label: String) -> NSError {
    NSError(
      domain: "dev.avalon.storage-check", code: 1, userInfo: [NSLocalizedDescriptionKey: label])
  }
}
