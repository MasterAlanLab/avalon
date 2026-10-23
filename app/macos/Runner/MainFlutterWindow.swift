import Carbon
import Cocoa
import FlutterMacOS
import ServiceManagement
import window_manager

/// The V3 3p window: no visible title bar, content drawn underneath it, and
/// the system traffic lights moved into the sidebar header (the close button
/// centred 24 pt from the top-left corner, buttons 20 pt apart). Flutter talks
/// to the window over the `avalon/window` channel (`AvWindow` in Dart).
class MainFlutterWindow: NSWindow {
  private static let trafficLightCenter = NSPoint(x: 24, y: 24)
  private static let trafficLightSpacing: CGFloat = 20
  private var windowChannel: FlutterMethodChannel?
  private var loginItemChannel: FlutterMethodChannel?
  private var hotkeysChannel: FlutterMethodChannel?
  private var hotkeyRefs: [String: EventHotKeyRef] = [:]
  private static weak var hotkeyWindow: MainFlutterWindow?
  private static var hotkeyHandlerInstalled = false
  private static let hotkeyActions = ["toggle", "mode", "show"]

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    contentViewController = flutterViewController

    titleVisibility = .hidden
    titlebarAppearsTransparent = true
    styleMask.insert(.fullSizeContentView)
    // V3 draws the desktop window at 1280 × 820.
    setContentSize(NSSize(width: 1280, height: 820))
    // Narrowest window that keeps the dashboard's four columns on one line.
    contentMinSize = NSSize(width: 1080, height: 640)
    center()
    // D71: AppKit persists the user's window frame after the default
    // layout has been established, and restores it on later launches.
    setFrameAutosaveName("AvalonMainWindow")
    setFrameUsingName("AvalonMainWindow")

    RegisterGeneratedPlugins(registry: flutterViewController)
    MacHost.register(with: flutterViewController.registrar(forPlugin: "AvalonMacHost"))
    registerWindowChannel(flutterViewController.engine.binaryMessenger)
    registerLoginItemChannel(flutterViewController.engine.binaryMessenger)
    registerHotkeysChannel(flutterViewController.engine.binaryMessenger)

    super.awakeFromNib()

    // AppKit lays the title bar out again on these; put the buttons back.
    for name in [
      NSWindow.didResizeNotification,
      NSWindow.didEndLiveResizeNotification,
      NSWindow.didExitFullScreenNotification,
      NSWindow.didBecomeKeyNotification,
      NSWindow.didResignKeyNotification,
    ] {
      NotificationCenter.default.addObserver(
        self, selector: #selector(placeTrafficLights), name: name, object: self)
    }
    placeTrafficLights()
  }

  // Hidden until Dart shows it: «静默启动» may keep it in the menu bar
  // (window_manager).
  override public func order(_ place: NSWindow.OrderingMode, relativeTo otherWin: Int) {
    super.order(place, relativeTo: otherWin)
    hiddenWindowAtLaunch()
  }

  // AppKit lays the title bar out again when the window is shown, resized or
  // restyled; this runs after each pass.
  override func layoutIfNeeded() {
    super.layoutIfNeeded()
    placeTrafficLights()
  }

  @objc private func placeTrafficLights() {
    guard !styleMask.contains(.fullScreen),
      let close = standardWindowButton(.closeButton),
      let container = close.superview?.superview
    else { return }
    let center = Self.trafficLightCenter
    // Grow the title-bar container so the buttons can sit lower than in the
    // standard 28 pt bar, then centre them on the V3 positions.
    let height = center.y * 2
    var frame = container.frame
    frame.size.height = height
    frame.origin.y = self.frame.height - height
    container.frame = frame
    let kinds: [NSWindow.ButtonType] = [.closeButton, .miniaturizeButton, .zoomButton]
    for (i, kind) in kinds.enumerated() {
      guard let button = standardWindowButton(kind) else { continue }
      let size = button.frame.size
      button.setFrameOrigin(
        NSPoint(
          x: center.x + CGFloat(i) * Self.trafficLightSpacing - size.width / 2,
          y: (height - size.height) / 2))
    }
  }

  private func registerWindowChannel(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "avalon/window", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return result(nil) }
      switch call.method {
      case "startDrag":
        if let event = self.currentEvent { self.performDrag(with: event) }
        result(nil)
      case "titleDoubleClick":
        self.titleDoubleClick()
        result(nil)
      case "setNativeControlsVisible":
        let visible = call.arguments as? Bool ?? true
        for kind in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
          self.standardWindowButton(kind)?.isHidden = !visible
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    windowChannel = channel
  }

  /// «开机自动启动»: the app as a login item (SMAppService, macOS 13 and
  /// later; `LoginItem` in Dart).
  private func registerLoginItemChannel(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "avalon/login-item", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "set", let enabled = call.arguments as? Bool else {
        return result(FlutterMethodNotImplemented)
      }
      guard #available(macOS 13.0, *) else {
        return result(
          FlutterError(code: "unsupported", message: "login items need macOS 13", details: nil))
      }
      do {
        let service = SMAppService.mainApp
        if enabled, service.status != .enabled && service.status != .requiresApproval {
          try service.register()
        } else if !enabled,
          service.status == .enabled || service.status == .requiresApproval
        {
          try service.unregister()
        }
        if enabled, service.status != .enabled {
          let approvalRequired = service.status == .requiresApproval
          return result(
            FlutterError(
              code: approvalRequired ? "approvalRequired" : "refused",
              message: approvalRequired
                ? "Approve Avalon in System Settings > General > Login Items."
                : "The login item is not enabled.",
              details: nil))
        }
        result(nil)
      } catch {
        result(
          FlutterError(code: "refused", message: error.localizedDescription, details: nil))
      }
    }
    loginItemChannel = channel
  }

  /// The global shortcuts ⌥⌘P, ⌥⌘M, ⌥⌘A (PRODUCT_SPEC §7) through Carbon's
  /// hotkeys, which work in the sandbox; `MacHotkeys` in Dart. Registering
  /// answers false when another app holds the combination.
  private func registerHotkeysChannel(_ messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "avalon/hotkeys", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self else { return result(nil) }
      switch call.method {
      case "register":
        guard let action = call.arguments as? String else { return result(false) }
        result(self.registerHotkey(action))
      case "unregisterAll":
        for ref in self.hotkeyRefs.values { UnregisterEventHotKey(ref) }
        self.hotkeyRefs.removeAll()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    hotkeysChannel = channel
    Self.hotkeyWindow = self
  }

  private func registerHotkey(_ action: String) -> Bool {
    let keyCode: Int
    switch action {
    case "toggle": keyCode = kVK_ANSI_P
    case "mode": keyCode = kVK_ANSI_M
    case "show": keyCode = kVK_ANSI_A
    default: return false
    }
    guard let index = Self.hotkeyActions.firstIndex(of: action) else { return false }
    installHotkeyHandler()
    if let old = hotkeyRefs.removeValue(forKey: action) { UnregisterEventHotKey(old) }
    // 'AVLN' and the action's index identify the hotkey in the event.
    let id = EventHotKeyID(signature: OSType(0x4156_4C4E), id: UInt32(index))
    var ref: EventHotKeyRef?
    let status = RegisterEventHotKey(
      UInt32(keyCode), UInt32(cmdKey | optionKey), id, GetApplicationEventTarget(), 0, &ref)
    guard status == noErr, let ref else { return false }
    hotkeyRefs[action] = ref
    return true
  }

  private func installHotkeyHandler() {
    guard !Self.hotkeyHandlerInstalled else { return }
    Self.hotkeyHandlerInstalled = true
    var spec = EventTypeSpec(
      eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
    InstallEventHandler(
      GetApplicationEventTarget(),
      { _, event, _ in
        var id = EventHotKeyID()
        GetEventParameter(
          event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID),
          nil, MemoryLayout<EventHotKeyID>.size, nil, &id)
        let actions = MainFlutterWindow.hotkeyActions
        if Int(id.id) < actions.count {
          MainFlutterWindow.hotkeyWindow?.hotkeysChannel?.invokeMethod(
            "pressed", arguments: actions[Int(id.id)])
        }
        return noErr
      }, 1, &spec, nil, nil)
  }

  /// What a title-bar double click does, per System Settings › Desktop & Dock.
  private func titleDoubleClick() {
    switch UserDefaults.standard.string(forKey: "AppleActionOnDoubleClick") {
    case "Minimize": performMiniaturize(nil)
    case "None": break
    default: performZoom(nil)
    }
  }
}
