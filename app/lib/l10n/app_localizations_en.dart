// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tabDashboard => 'Dashboard';

  @override
  String get tabProxies => 'Proxies';

  @override
  String get tabConfigurations => 'Profiles';

  @override
  String get tabTools => 'Tools';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get done => 'Done';

  @override
  String get retry => 'Retry';

  @override
  String get justNow => 'just now';

  @override
  String minutesAgo(int n) {
    return '$n min ago';
  }

  @override
  String hoursAgo(int n) {
    return '$n h ago';
  }

  @override
  String daysAgo(int n) {
    return '$n d ago';
  }

  @override
  String get configurationsTitle => 'Profiles';

  @override
  String get refreshAll => 'Update All';

  @override
  String get selfConfigurationName => 'My Nodes';

  @override
  String get sourceSubscription => 'Subscription';

  @override
  String get sourceFile => 'Local file';

  @override
  String sourceLocal(int chains) {
    return 'Local · $chains chains';
  }

  @override
  String nodeCount(int n) {
    return '$n nodes';
  }

  @override
  String updatedAt(String when) {
    return 'updated $when';
  }

  @override
  String get notDownloaded => 'Not downloaded';

  @override
  String expiresOn(String date) {
    return 'expires $date';
  }

  @override
  String lastSuccess(String when) {
    return 'Last success: $when';
  }

  @override
  String get configurationsEmpty =>
      'Add a subscription link, a configuration file or a node to get started.';

  @override
  String deleteConfigurationTitle(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get deleteConfigurationBody =>
      'Its selections and the nodes added to it are removed; chains using its nodes become unavailable.';

  @override
  String get addTitle => 'Add';

  @override
  String get addSegmentSubscription => 'Subscription';

  @override
  String get addSegmentNode => 'Node';

  @override
  String get addSegmentChain => 'Chain';

  @override
  String get subscriptionUrl => 'Subscription link';

  @override
  String get subscriptionUrlHint => 'https://… sing-box or Clash subscription';

  @override
  String get name => 'Name';

  @override
  String get nameAuto => 'Automatic';

  @override
  String get scanQr => 'Scan QR Code';

  @override
  String get importFile => 'Import from File';

  @override
  String get dropFileHint => 'or drop a .json (sing-box) or .yaml (Clash) file';

  @override
  String get autoUpdate => 'Auto Update';

  @override
  String get localOnlyNote => 'Saved on this device.';

  @override
  String get defaultSubscriptionName => 'New Subscription';

  @override
  String get comingSoon => 'Coming in a later version.';

  @override
  String get coreNotConnected => 'Core not connected';

  @override
  String get coreNotConnectedNote =>
      'Connecting, latency tests and live data arrive with the core.';

  @override
  String get currentConfiguration => 'Current profile';

  @override
  String get noConfigurationSelected => 'No profile selected';

  @override
  String get errorInvalidUrl =>
      'Invalid link. Use a subscription link starting with http:// or https://.';

  @override
  String get errorBlockedAddress =>
      'The content points at this device or the local network and was blocked.';

  @override
  String get errorTimeout =>
      'Connection timed out. Check the network and retry.';

  @override
  String get errorTooLarge => 'The content exceeds the 16 MiB limit.';

  @override
  String get errorTooManyRedirects => 'Too many redirects.';

  @override
  String errorHttpStatus(int status) {
    return 'The server returned an error (HTTP $status).';
  }

  @override
  String get errorTls =>
      'Secure connection failed: invalid certificate or handshake.';

  @override
  String get errorNetwork => 'Network error: the server could not be reached.';

  @override
  String get errorUnknownFormat =>
      'Unrecognized content: sing-box JSON, Clash YAML and share-link lists are supported.';

  @override
  String get errorMalformed => 'The content is malformed.';

  @override
  String errorUnknownParameter(String field) {
    return 'Unsupported parameter: $field.';
  }

  @override
  String errorUnsupportedValue(String field) {
    return 'Unsupported value: $field.';
  }

  @override
  String errorMissingField(String field) {
    return 'Missing required field: $field.';
  }

  @override
  String errorInvalidField(String field) {
    return 'Invalid field: $field.';
  }

  @override
  String errorTooLargeContent(String field) {
    return 'The content exceeds a limit ($field).';
  }

  @override
  String get errorUnsupportedScheme => 'Unrecognized share link protocol.';

  @override
  String get errorVaultLocked =>
      'Secure storage on this device was reset. Enter the credentials again or restore a backup.';

  @override
  String get errorUnknown => 'Something went wrong. Please retry.';

  @override
  String get savedWithWarnings => 'Saved. Some content was not imported:';

  @override
  String warnUnsupportedNodeType(int count, String subject) {
    return 'Skipped $count $subject nodes: protocol not supported';
  }

  @override
  String warnUnsupportedNodeOption(int count, String subject) {
    return 'Skipped $count nodes: option $subject not supported';
  }

  @override
  String warnIgnoredNodeOption(int count, String subject) {
    return 'Option $subject has no effect on $count nodes';
  }

  @override
  String warnUnreadableEntry(int count, String subject) {
    return 'Skipped $count unreadable entries ($subject)';
  }

  @override
  String warnUnsupportedGroupType(String subject) {
    return 'Skipped $subject groups';
  }

  @override
  String warnUnsupportedRule(int count, String subject) {
    return 'Skipped $count $subject rules';
  }

  @override
  String warnUnsupportedRuleSet(String subject) {
    return 'Rule set $subject cannot be used; its rules were skipped';
  }

  @override
  String warnInsecureTls(int count) {
    return '$count nodes skip certificate verification';
  }

  @override
  String get warnMissingFinal => 'No final rule: unmatched traffic goes direct';

  @override
  String warnDroppedMember(String subject) {
    return 'Group member $subject does not exist or was skipped';
  }

  @override
  String get databaseTooNew => 'Please update Avalon';

  @override
  String get databaseTooNewNote =>
      'The data on this device comes from a newer version of Avalon. Update the app to open it.';

  @override
  String get startupFailed => 'Could not open local data';

  @override
  String get ok => 'OK';

  @override
  String get modeRule => 'Rule';

  @override
  String get modeGlobal => 'Global';

  @override
  String get modeDirect => 'Direct';

  @override
  String get statusConnected => 'Connected';

  @override
  String get statusDisconnected => 'Not connected';

  @override
  String get addConfigurationTitle => 'Add Configuration';

  @override
  String get addPrompt => 'Add a subscription, node or chain';

  @override
  String get nodeCountUnknown => '— nodes';

  @override
  String usedOnly(String used) {
    return '$used used';
  }

  @override
  String refreshFailed(String reason) {
    return 'Update failed: $reason';
  }

  @override
  String get autoUpdateSubtitle => 'Every 12 hours';

  @override
  String get testLatency => 'Test';

  @override
  String get directModeNote =>
      'Connect directly to destinations in direct mode';

  @override
  String groupSummary(String type, int n) {
    return '$type · $n nodes';
  }

  @override
  String groupCurrent(String name) {
    return 'Current: $name';
  }

  @override
  String get customGroup => 'Custom';

  @override
  String get autoGroupNote => 'This group picks by latency automatically';

  @override
  String get unavailable => 'Unavailable';

  @override
  String memberChain(int n) {
    return 'Chain · $n hops';
  }

  @override
  String memberGroup(String type) {
    return '$type group';
  }

  @override
  String get memberDirect => 'Direct';

  @override
  String get memberReject => 'Reject';

  @override
  String get noConfigurationSelectedNote =>
      'Add or select a configuration under Configurations to see its proxy groups here.';

  @override
  String get goToConfigurations => 'Open Configurations';

  @override
  String get customEmpty =>
      'Add nodes or proxy chains to manage your own connections.';

  @override
  String get contentNotDownloaded => 'Subscription not downloaded yet';

  @override
  String get pasteLinkHint => 'Paste vless:// vmess:// hy2:// …';

  @override
  String get pasteLinkHintDesktop =>
      'Paste a vless:// vmess:// ss:// hy2:// share link';

  @override
  String get parse => 'Parse';

  @override
  String get protocol => 'Protocol';

  @override
  String get sectionServer => 'Server';

  @override
  String get sectionTransport => 'Transport';

  @override
  String get sectionSecurity => 'Transport security';

  @override
  String get securityNone => 'None';

  @override
  String get nodeNameHint => 'Tokyo VPS';

  @override
  String get fieldServer => 'Address';

  @override
  String get fieldPort => 'Port';

  @override
  String get fieldPassword => 'Password';

  @override
  String get fieldObfsPassword => 'Obfs password';

  @override
  String get fieldUsername => 'Username';

  @override
  String get fieldUpMbps => 'Up Mbps';

  @override
  String get fieldDownMbps => 'Down Mbps';

  @override
  String get fieldCongestion => 'Congestion control';

  @override
  String get fieldMethod => 'Method';

  @override
  String get fieldIdleCheck => 'Idle session check';

  @override
  String get fieldPath => 'Path';

  @override
  String get fieldPublicKey => 'Public key';

  @override
  String get fieldRequiredHint => 'Required';

  @override
  String get fieldOptionalHint => 'Optional';

  @override
  String get nodeSavedNote => 'Saved to My Nodes. ';

  @override
  String fieldRequired(String field) {
    return 'Enter the $field.';
  }

  @override
  String fieldInvalid(String field) {
    return 'The $field is not valid.';
  }

  @override
  String fieldUnsupported(String field) {
    return 'That $field value is not supported.';
  }

  @override
  String get chainNameHint => 'Node names joined by default';

  @override
  String get sectionChain => 'Path';

  @override
  String get sectionChainDesktop => 'Path · this device → … → destination';

  @override
  String chainSummary(int n, String latency) {
    return '$n hops · $latency';
  }

  @override
  String chainLatencyEstimate(int ms) {
    return '≈ $ms ms';
  }

  @override
  String get hopLocal => 'This device';

  @override
  String get hopTarget => 'Destination';

  @override
  String get addHop => 'Add a hop';

  @override
  String get roleEntry => 'Entry';

  @override
  String get roleRelay => 'Relay';

  @override
  String get roleExit => 'Exit';

  @override
  String get chainNote =>
      'Traffic passes through each hop in order; the last hop is the exit. Different protocols can be combined.';

  @override
  String get sectionJoinGroups => 'Add to groups';

  @override
  String get chainTooShort => 'A chain needs at least 2 hops';

  @override
  String get noHopCandidates =>
      'Add a subscription or a node, then choose nodes for the chain.';

  @override
  String get editTitle => 'Edit';

  @override
  String get savedSecretHint => 'Saved';

  @override
  String get errorEditConflict =>
      'This was changed in another window or on another device. It has been reloaded; please check it again.';

  @override
  String get errorNotFound => 'This item no longer exists.';

  @override
  String deleteItemTitle(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get deleteNodeBody =>
      'The node is removed from every group it joined.';

  @override
  String get deleteChainBody =>
      'The chain is removed from every group it joined. Its nodes are kept.';

  @override
  String get nodeInUseTitle => 'Cannot delete';

  @override
  String nodeInUseBody(String name, String chains) {
    return '“$name” is used by these chains. Change or delete them first: $chains';
  }

  @override
  String get sectionView => 'View';

  @override
  String get sectionSettings => 'Settings';

  @override
  String get sectionOther => 'Other';

  @override
  String get toolConnections => 'Connections';

  @override
  String get toolLogs => 'Logs';

  @override
  String get toolLoginSync => 'Sign in & sync';

  @override
  String get toolBasic => 'Basic Settings';

  @override
  String get toolAdvanced => 'Advanced Settings';

  @override
  String get toolApps => 'Per-App Proxy';

  @override
  String get toolGeo => 'GEO Rule Sets';

  @override
  String get toolAbout => 'About Avalon';

  @override
  String get toolAboutShort => 'About';

  @override
  String get sectionGeneral => 'General';

  @override
  String get language => 'Language';

  @override
  String get languageZh => '简体中文';

  @override
  String get appearance => 'Appearance';

  @override
  String get appearanceLight => 'Light';

  @override
  String get appearanceDark => 'Dark';

  @override
  String get sectionStartup => 'Start-up';

  @override
  String get launchAtStartup => 'Launch at startup';

  @override
  String get launchAtStartupNoteAndroid =>
      'Runs in the background after Android boots';

  @override
  String get launchAtStartupNoteDesktop => 'Runs Avalon when you log in';

  @override
  String get launchAtStartupFailed =>
      'Could not update login startup. Toggle this switch again to retry.';

  @override
  String get launchAtStartupNeedsApproval =>
      'Allow Avalon in System Settings → General → Login Items.';

  @override
  String get launchAtStartupNoteIos =>
      'Turn on “Connect On Demand” for the VPN in system settings.';

  @override
  String get silentStart => 'Start silently';

  @override
  String silentStartNote(String tray) {
    return 'Starts with the main window hidden and an icon in the $tray';
  }

  @override
  String get trayMenuBar => 'menu bar';

  @override
  String get traySystemTray => 'system tray';

  @override
  String get autoConnect => 'Connect on launch';

  @override
  String get autoConnectNote => 'Starts the proxy when the app opens';

  @override
  String keepOnClose(String tray) {
    return 'Keep in the $tray when the window closes';
  }

  @override
  String get sectionProxy => 'Proxy';

  @override
  String get systemProxy => 'System proxy';

  @override
  String get systemProxyNoteMac => 'Sets the macOS network proxy';

  @override
  String get systemProxyNoteWindows =>
      'Sets the Windows system proxy (WinINet)';

  @override
  String get systemProxyNoteLinux => 'Writes the GNOME / KDE proxy settings';

  @override
  String get systemProxyNeedsTun => 'Enable TUN first';

  @override
  String get allowLan => 'Allow LAN connections';

  @override
  String get allowLanNote => 'Other devices can use this device’s proxy port';

  @override
  String get mixedPort => 'Mixed port';

  @override
  String get sectionHotkeys => 'Shortcuts';

  @override
  String get hotkeyToggle => 'Start / stop proxy';

  @override
  String get hotkeyMode => 'Switch outbound mode';

  @override
  String get hotkeyShow => 'Show main window';

  @override
  String get hotkeyTaken => 'In use';

  @override
  String get hotkeyUnsupported => 'Not yet supported';

  @override
  String get trayStart => 'Start proxy';

  @override
  String get trayStop => 'Stop proxy';

  @override
  String get trayMode => 'Outbound mode';

  @override
  String get trayQuit => 'Quit Avalon';

  @override
  String get sectionNotification => 'Notification';

  @override
  String get speedNotification => 'Show live speed in the notification';

  @override
  String get sectionLatency => 'Latency test';

  @override
  String get testUrl => 'Test URL';

  @override
  String get testTimeout => 'Timeout';

  @override
  String milliseconds(int n) {
    return '$n ms';
  }

  @override
  String get sectionData => 'Data';

  @override
  String get exportBackup => 'Export Backup…';

  @override
  String get restoreBackup => 'Restore from File…';

  @override
  String get backupNote =>
      'A backup holds subscriptions, self-built nodes, chains and all settings.';

  @override
  String get sectionTun => 'Virtual interface (TUN)';

  @override
  String get tunEnabled => 'Enable TUN';

  @override
  String get tunNote => 'Takes over all traffic of the device';

  @override
  String get tunNoteMac => 'utun · needs the network extension';

  @override
  String get tunNoteWindows => 'WinTUN · needs administrator rights';

  @override
  String get tunNoteLinux => 'tun0 · needs CAP_NET_ADMIN';

  @override
  String get tunStack => 'Stack';

  @override
  String get autoRoute => 'Auto route';

  @override
  String get strictRoute => 'Strict route';

  @override
  String get strictRouteNote => 'Enforces tunnel routing rules';

  @override
  String get remoteDns => 'Remote DNS';

  @override
  String get directDns => 'Direct DNS';

  @override
  String get dnsStrategy => 'Resolution';

  @override
  String get dnsPreferIpv4 => 'Prefer IPv4';

  @override
  String get dnsIpv4Only => 'IPv4 only';

  @override
  String get dnsPreferIpv6 => 'Prefer IPv6';

  @override
  String get dnsIpv6OffNote => 'IPv6 is off, so names resolve as “IPv4 only”.';

  @override
  String get sectionRouting => 'Routing';

  @override
  String get sniff => 'Sniffing';

  @override
  String get sniffNote => 'Detects TLS / HTTP / QUIC domains';

  @override
  String get bypassLan => 'Bypass LAN and reserved addresses';

  @override
  String get findProcess => 'Find process';

  @override
  String get findProcessNote =>
      'For per-app proxy and the app shown on Connections';

  @override
  String get findProcessNoteDesktop =>
      'For per-app proxy and the program shown on Connections';

  @override
  String get clashApi => 'External controller';

  @override
  String get clashApiNote =>
      'Lets a web panel or another client control the proxy';

  @override
  String get clashListen => 'Listen address';

  @override
  String get clashListenRisk =>
      'Other devices on the same network can control the proxy through this listen address.';

  @override
  String get clashSecret => 'Secret';

  @override
  String get secretView => 'View';

  @override
  String get secretCopy => 'Copy';

  @override
  String get secretRegenerate => 'Regenerate';

  @override
  String get secretRegenerateConfirm =>
      'Panels and clients using the old secret will need the new one.';

  @override
  String get copied => 'Copied';

  @override
  String get webPanel => 'Web panel';

  @override
  String get openWebPanel => 'Open metacubexd';

  @override
  String get webPanelNotRunning =>
      'The proxy is not running. Connect before opening the web panel.';

  @override
  String get webPanelControllerOff =>
      'The running external controller is disabled. Enable it in advanced settings and apply the change before opening the web panel.';

  @override
  String get webPanelStateUnknown =>
      'The current controller state is unavailable. Check the proxy connection and try again.';

  @override
  String get webPanelBrowserFailed =>
      'The system browser could not open the web panel. Check the browser and try again.';

  @override
  String get sectionCore => 'Core';

  @override
  String get logLevel => 'Log level';

  @override
  String get configOverride => 'Config override';

  @override
  String get editJson => 'Edit JSON…';

  @override
  String get viewGeneratedConfig => 'View generated config';

  @override
  String get generatedConfig => 'Generated config';

  @override
  String get viewAction => 'View…';

  @override
  String get overrideNote =>
      'The override is merged into the sing-box config generated for every subscription; use it for custom rules or outbounds.';

  @override
  String get resetDefaults => 'Restore Defaults';

  @override
  String get resetDefaultsConfirm =>
      'Restore every setting on this page to its default? The config override and the Clash API secret are kept.';

  @override
  String get reset => 'Restore';

  @override
  String get settingInvalid => 'That value is not valid.';

  @override
  String settingOutOfRange(int min, int max) {
    return 'Enter a number from $min to $max.';
  }

  @override
  String get remoteDnsHint => 'Starts with https:// or tls://';

  @override
  String get directDnsHint => 'An IP address, or starting with udp://';

  @override
  String get testUrlHint => 'Starts with http:// or https://';

  @override
  String get clashListenHint => 'address:port, e.g. 127.0.0.1:9090';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutCore => 'Core';

  @override
  String get aboutLicense => 'License';

  @override
  String get aboutThanks => 'Thanks to sing-box and the open-source community';

  @override
  String get overrideKeysNote =>
      'Supported keys: outbounds, route.rules, route.rule_set, route.final, dns.servers, dns.rules. Refer to nodes and groups by their display names. Overrides apply to imported configurations.';

  @override
  String overrideSyntax(int line, int column) {
    return 'JSON syntax error at line $line, column $column.';
  }

  @override
  String get overrideNotObject => 'The outermost value must be a JSON object.';

  @override
  String overrideNotAllowed(String path) {
    return 'Key not allowed: $path';
  }

  @override
  String overrideWrongType(String path, String type) {
    return '$path has the wrong type; it must be $type.';
  }

  @override
  String get jsonObject => 'an object';

  @override
  String get jsonArray => 'an array';

  @override
  String get jsonString => 'a string';

  @override
  String get jsonTaggedObject => 'an object with a tag';

  @override
  String overrideReference(String name, String path) {
    return 'No node or group is named “$name” ($path).';
  }

  @override
  String overrideConflict(String name, String path) {
    return 'The tag “$name” collides with the generated config ($path); pick another name.';
  }

  @override
  String get compileNothingSelected =>
      'Select a configuration under Configurations first.';

  @override
  String compileMemberUnavailable(String name) {
    return '“$name” is unavailable, so the config cannot be generated.';
  }

  @override
  String compileEmptyGroup(String name) {
    return 'The group “$name” has no usable member.';
  }

  @override
  String compileRuleSetMissing(String name) {
    return 'The rule set “$name” has not been downloaded or cannot be used.';
  }

  @override
  String get compilePerAppNeedsFindProcess =>
      'Per-app proxy needs “Find process” turned on.';

  @override
  String compileInvalidSetting(String name) {
    return 'A setting is not valid: $name.';
  }

  @override
  String get generatedNote =>
      'Secrets are replaced by ••••. This is generated from the selected configuration and the current settings.';

  @override
  String get copyAll => 'Copy';

  @override
  String get backupPassword => 'Backup password';

  @override
  String get backupPasswordNote =>
      'Use at least 8 characters. Keep this password safe for restoring the backup.';

  @override
  String get passwordHint => 'Password';

  @override
  String get passwordAgainHint => 'Password again';

  @override
  String get passwordTooShort => 'The password needs at least 8 characters.';

  @override
  String get passwordMismatch => 'The two passwords do not match.';

  @override
  String get backupEncrypting => 'Encrypting the backup…';

  @override
  String get backupExported => 'Backup exported';

  @override
  String get restorePassword => 'Enter the backup password';

  @override
  String get restoreConfirmTitle => 'Restore from the backup?';

  @override
  String get restoreConfirmBody =>
      'Restoring replaces settings and objects that are in the backup; everything else on this device is kept.';

  @override
  String get restoring => 'Restoring…';

  @override
  String get restoreDoneTitle => 'Restore complete';

  @override
  String restoreDoneBody(int configs, int nodes, int chains) {
    return 'Restored $configs configurations, $nodes self-built nodes, $chains chains and all settings.';
  }

  @override
  String get backupWrongPassword => 'Wrong password, or the file is damaged.';

  @override
  String get backupNotABackup => 'This is not an Avalon backup file.';

  @override
  String get backupUnsupportedVersion =>
      'This backup comes from a newer Avalon. Update the app first.';

  @override
  String get backupTooLarge => 'The file is larger than a backup may be.';

  @override
  String get backupMalformed => 'The backup content could not be read.';

  @override
  String get exportBackupAction => 'Export';

  @override
  String get fileChoose => 'Choose a .json or .yaml file';

  @override
  String get fileChooseNote => 'A sing-box or Clash configuration';

  @override
  String get dropFile => 'Or drop a configuration file';

  @override
  String get dropFileNote => '.json (sing-box) / .yaml (Clash)';

  @override
  String get fileReplace => 'Tap to replace';

  @override
  String get fileImportNote =>
      'Save the file’s contents as a local configuration.';

  @override
  String get scanPrompt => 'Fit the subscription QR code in the frame';

  @override
  String get scanDenied =>
      'Scanning needs camera access. Allow Avalon to use the camera in system settings, or paste the subscription link instead.';

  @override
  String get scanUnavailable =>
      'The camera is not available on this device. Paste the subscription link instead.';

  @override
  String get scanNotSubscription =>
      'The QR code is not a subscription link (it must start with http:// or https://).';

  @override
  String get scanned => 'Subscription link recognized';

  @override
  String get networkSpeed => 'Network speed';

  @override
  String get todayUpload => 'Today up';

  @override
  String get todayDownload => 'down';

  @override
  String get todayTraffic => 'Today’s traffic';

  @override
  String get currentNode => 'Current node';

  @override
  String get exitIp => 'Exit IP';

  @override
  String get modeRuleFull => 'Rule';

  @override
  String get modeGlobalFull => 'Global';

  @override
  String get modeDirectFull => 'Direct';

  @override
  String get addConfigurationFirst => 'Add a configuration first';

  @override
  String aboutVersionLine(String version) {
    return 'Version $version';
  }

  @override
  String get keyStorage => 'Secure storage';

  @override
  String get keyStorageFile => 'A local file (mode 0600)';

  @override
  String get licensesTitle => 'Licenses and Notices';

  @override
  String licenseCount(int n) {
    return '$n licenses';
  }

  @override
  String get licensesNote =>
      'Avalon is released under AGPL-3.0. These are the open-source components distributed with the app and their licenses.';

  @override
  String get search => 'Search';

  @override
  String get turnOn => 'Turn On';

  @override
  String get perAppWhitelist => 'Allowlist';

  @override
  String get perAppBlacklist => 'Blocklist';

  @override
  String get appsHintEmpty =>
      'With no app selected, all apps follow the rules.';

  @override
  String get appsHintWhitelist =>
      'Only the apps turned on use the proxy; the rest connect directly.';

  @override
  String get appsHintBlacklist =>
      'The apps turned on connect directly; the rest use the proxy.';

  @override
  String get appsHintWhitelistDesktop =>
      'Only the programs turned on use the proxy; the rest connect directly.';

  @override
  String get appsHintBlacklistDesktop =>
      'The programs turned on connect directly; the rest use the proxy.';

  @override
  String get appNotInstalled => 'Not installed';

  @override
  String get addProgram => 'Add Program';

  @override
  String get appsListFailed => 'Could not read the list of apps';

  @override
  String get appsListFailedNote => 'Only the saved list is shown below.';

  @override
  String get appsNoMatch => 'No matching apps';

  @override
  String get appsNoMatchDesktop => 'No matching programs';

  @override
  String get appsNoPrograms =>
      'No programs yet. Use Add Program to choose one to treat separately.';

  @override
  String get appsNeedFindProcessNote =>
      'Turn on “Find process” to apply proxy rules by program.';

  @override
  String rulesCount(int n) {
    return '$n rule sets';
  }

  @override
  String get rulesAutoDaily => 'updated daily';

  @override
  String get rulesAutoWeekly => 'updated weekly';

  @override
  String get rulesAutoOff => 'automatic updates off';

  @override
  String get rulesUpdating => 'Updating';

  @override
  String get sectionRuleSets => 'Rule Sets';

  @override
  String get sectionUpdateSettings => 'Updates';

  @override
  String get geoInterval => 'Update Interval';

  @override
  String get geoDaily => 'Daily';

  @override
  String get geoWeekly => 'Weekly';

  @override
  String get geoVia => 'Download';

  @override
  String get geoViaProxy => 'Via Proxy';

  @override
  String get geoViaDirect => 'Direct';

  @override
  String get rulesNote =>
      'Manage and update GeoSite, GeoIP and rule sets used by subscriptions.';

  @override
  String get ruleKindSet => 'Rule set';

  @override
  String get ruleNotDownloaded => 'Not downloaded';

  @override
  String ruleUpdatedAgo(String when) {
    return 'updated $when';
  }

  @override
  String get ruleDownloading => 'Downloading…';

  @override
  String get columnType => 'Type';

  @override
  String get columnSize => 'Size';

  @override
  String get columnUpdated => 'Updated';

  @override
  String get rulesNeedProxy =>
      'Start the proxy first, or switch to direct download';

  @override
  String get statusConnecting => 'Connecting…';

  @override
  String get statusReconnecting => 'Reconnecting';

  @override
  String get statusDisconnecting => 'Disconnecting…';

  @override
  String coreReady(String version) {
    return 'sing-box $version ready';
  }

  @override
  String connectedSummary(String mode, String exit) {
    return '$mode · $exit';
  }

  @override
  String get runtimePermissionRefused => 'VPN permission is needed to connect';

  @override
  String get runtimePermissionRefusedNote =>
      'Connect again and allow it in the system dialog.';

  @override
  String get runtimeNotDownloaded =>
      'The selected profile has not been downloaded yet; update it first';

  @override
  String get runtimePlanFailed => 'Could not generate the configuration';

  @override
  String get runtimeHostUnreachable => 'Cannot reach the Avalon service';

  @override
  String get runtimePortInUse => 'The port is in use; change the mixed port';

  @override
  String get runtimeNoListedAppInstalled =>
      'None of the allowed apps is installed';

  @override
  String get runtimeNoListedAppInstalledNote =>
      'Select an installed app in the Per-App Proxy allow list, switch to the block list, or clear the list.';

  @override
  String get appsNoneInstalled => 'None of the listed apps is installed';

  @override
  String get appsNoneInstalledNote =>
      'Select an app installed on this device in the allow list before starting the proxy.';

  @override
  String get runtimePlanRefused =>
      'The core does not accept this configuration';

  @override
  String get runtimeCoreFailed => 'The core failed to start';

  @override
  String get runtimeTimeout => 'The Avalon service did not answer in time';

  @override
  String get errorConfigurationInUse =>
      'Disconnect or switch to another profile first';

  @override
  String get autoUpdateLocalOnlyNote =>
      'Updates every 12 hours and is saved on this device.';

  @override
  String get latencyTimeout => 'Timeout';

  @override
  String get latencyFailed => 'Failed';

  @override
  String get closeAll => 'Close All';

  @override
  String activeConnections(int n) {
    return '$n active connections';
  }

  @override
  String get noConnections => 'No Connections';

  @override
  String get connectionsWhenRunning =>
      'Start the proxy to see connections here as they happen';

  @override
  String get connectionsAllClosed => 'All connections are closed';

  @override
  String get columnHost => 'Host';

  @override
  String get columnProcess => 'Process';

  @override
  String get columnRule => 'Rule';

  @override
  String get columnChain => 'Route';

  @override
  String get columnUpload => 'Upload';

  @override
  String get columnDownload => 'Download';

  @override
  String get ruleFinal => 'Default';

  @override
  String get logsAll => 'All';

  @override
  String get logsDropped => 'Earlier lines were dropped';

  @override
  String get noLogs => 'No Logs';

  @override
  String get noLogsNote => 'The core\'s log appears here while the proxy runs';

  @override
  String get shareLogs => 'Share Logs';

  @override
  String get exportLogs => 'Export Logs';

  @override
  String get ruleDownloadFailed => 'Download failed';

  @override
  String get cloudTitle => 'Avalon Cloud';

  @override
  String get cloudLoginTitle => 'Sign in to Avalon';

  @override
  String get cloudLoginNote =>
      'Sign in to Avalon with an email verification code.';

  @override
  String get cloudLoginIntro =>
      'Sign in with your email\nto sync across your devices.';

  @override
  String get cloudEmailAddress => 'Email address';

  @override
  String get cloudCheckInbox => 'Check your inbox';

  @override
  String get cloudCodeSentTo => 'We sent a verification code to';

  @override
  String get cloudSixDigitCode => '6-digit code';

  @override
  String get cloudCodeHelper => 'Enter the code from your email to sign in.';

  @override
  String get cloudClearEmail => 'Clear email';

  @override
  String get cloudEmail => 'Email';

  @override
  String get cloudEmailPlaceholder => 'name@example.com';

  @override
  String get cloudCode => 'Verification code';

  @override
  String get cloudCodePlaceholder => 'Six-digit code';

  @override
  String get cloudSendCode => 'Send code';

  @override
  String get cloudResendCode => 'Send again';

  @override
  String get cloudVerifyCode => 'Sign in';

  @override
  String get cloudChangeEmail => 'Use another email';

  @override
  String get cloudCodeSent => 'Code sent. Please check your inbox.';

  @override
  String cloudResendWait(int seconds) {
    return 'Send again in $seconds seconds';
  }

  @override
  String get cloudLoading => 'Restoring sign-in…';

  @override
  String get cloudWorking => 'Working…';

  @override
  String get cloudAccount => 'Account';

  @override
  String get cloudSignedIn => 'Signed in';

  @override
  String get cloudReload => 'Refresh account details';

  @override
  String get cloudFreeAccount => 'Free account';

  @override
  String get cloudFreeAccountNote =>
      'Manage and use all configurations on this device.';

  @override
  String get cloudSyncFreeAccountNote =>
      'Configurations are saved on this device. An active subscription enables cloud sync.';

  @override
  String get cloudSyncTitle => 'Cloud sync';

  @override
  String get cloudLastSync => 'Last sync';

  @override
  String get cloudNeverSynced => 'Never synced';

  @override
  String get cloudSyncNow => 'Sync now';

  @override
  String get cloudSyncing => 'Syncing…';

  @override
  String get cloudSyncNoEntitlement =>
      'No active sync entitlement. Reload your account information.';

  @override
  String get cloudSyncDeviceLimit =>
      'All sync device slots are in use. Remove another device and retry.';

  @override
  String get cloudSyncSchemaUnsupported =>
      'This cloud data version is not supported. Update the client and retry.';

  @override
  String get cloudSyncQuotaExceeded =>
      'Cloud sync storage is full. Reduce synced content and retry.';

  @override
  String get cloudSyncValidation =>
      'Some local content does not meet cloud sync requirements. Check it and retry. Local content is preserved.';

  @override
  String get cloudSyncOwnership =>
      'This synced content belongs to another account. Use that account. Local content is preserved.';

  @override
  String cloudPendingMerge(int count) {
    return '$count local changes preserved for merging';
  }

  @override
  String get cloudSyncLegacyUnverified =>
      'The source of legacy sync data is awaiting confirmation. Uploads and downloads are paused. Local content is preserved.';

  @override
  String get cloudRebuildIncomplete =>
      'The backup is incomplete. Continue rebuilding.';

  @override
  String get cloudRebuildChanged =>
      'The rebuild state has changed. Reload your account information and retry.';

  @override
  String get cloudBackupTitle => 'Cloud backup';

  @override
  String get cloudBackupReady => 'Complete backup ready';

  @override
  String get cloudBackupRebuildRequired =>
      'A complete cloud backup is needed. Choose a source device.';

  @override
  String get cloudBackupRebuilding =>
      'Rebuilding the cloud backup for publication.';

  @override
  String get cloudBackupRetained =>
      'Sync entitlement has expired. The cloud backup is temporarily retained.';

  @override
  String get cloudBackupRetired =>
      'The previous cloud backup is no longer available.';

  @override
  String get cloudBackupNone => 'No cloud backup yet';

  @override
  String cloudBackupRetentionUntil(String time) {
    return 'Backup retained until: $time';
  }

  @override
  String get cloudBackupLocalNote =>
      'Local configurations and proxy credentials are preserved and remain usable.';

  @override
  String get cloudSyncGenerationChanged =>
      'The cloud space has changed. Reload its status before syncing. Local content is preserved.';

  @override
  String get cloudSyncSnapshotChanged =>
      'Cloud content changed during the full download. Retry; local content is preserved.';

  @override
  String get cloudSyncVerificationPending =>
      'Sync entitlement is awaiting verification. Uploads and downloads are paused.';

  @override
  String get cloudRebuildStart => 'Rebuild from this device';

  @override
  String get cloudRebuildStartTitle =>
      'Rebuild the cloud backup from this device?';

  @override
  String get cloudRebuildStartNote =>
      'The complete backup includes only this device’s current syncable content for this account. Review pending uploads on other devices first. Other devices can sync after publication. Local content is preserved.';

  @override
  String get cloudRebuildClaim => 'Take over rebuilding on this device';

  @override
  String get cloudRebuildClaimTitle => 'Take over rebuilding on this device?';

  @override
  String get cloudRebuildClaimNote =>
      'The current rebuild will stop and its unpublished content will be discarded. The new backup includes only this device’s current syncable content for this account. Other devices can sync after publication. Local content is preserved.';

  @override
  String get cloudRebuildCancel => 'Cancel rebuilding';

  @override
  String get cloudRebuildCancelTitle => 'Cancel this rebuild attempt?';

  @override
  String get cloudRebuildCancelNote =>
      'End this rebuild and discard the unpublished backup. Choose a source device again to rebuild. Local content is preserved.';

  @override
  String get cloudRebuildResume => 'Continue rebuilding';

  @override
  String get cloudRebuildThisDevice =>
      'This device is rebuilding. Sync completes when the full backup is published.';

  @override
  String get cloudRebuildWaiting =>
      'Another device is rebuilding. Wait for the complete backup to be published.';

  @override
  String cloudRebuildProgress(int received, int total) {
    return 'Uploaded $received / $total records';
  }

  @override
  String cloudCleanupOnline(String status) {
    return 'Previous cloud content cleanup: $status';
  }

  @override
  String cloudCleanupKey(String status) {
    return 'Previous online key status: $status';
  }

  @override
  String get cloudCleanupPending => 'Pending';

  @override
  String get cloudCleanupRunning => 'In progress';

  @override
  String get cloudCleanupFailed => 'Incomplete';

  @override
  String get cloudCleanupComplete => 'Complete';

  @override
  String get cloudCleanupNone => 'No result yet';

  @override
  String get cloudCleanupWaiting => 'Awaiting key cleanup confirmation';

  @override
  String get cloudCleanupKeyDeleted => 'Online keys removed';

  @override
  String get cloudCleanupKeyDeletedNote =>
      'Online keys have been removed. Recovery copies are retained for up to 30 days from their original creation time.';

  @override
  String get cloudCleanupKeyDestroyed => 'Old keys disabled';

  @override
  String get cloudNetworkGuard =>
      'This cloud content includes a network path this host cannot safely handle. Use a compatible version or local nodes.';

  @override
  String get cloudEntitlement => 'Subscription entitlement';

  @override
  String get cloudMonthly => 'Monthly';

  @override
  String get cloudYearly => 'Yearly';

  @override
  String get cloudEntitlementActive => 'Active';

  @override
  String get cloudEntitlementExpired => 'Expired';

  @override
  String get cloudEntitlementRevoked => 'Revoked';

  @override
  String get cloudEntitlementUnknown => 'Status unconfirmed';

  @override
  String cloudEntitlementUntil(String status, String date) {
    return '$status · Expires $date';
  }

  @override
  String get cloudAppleSource => 'App Store';

  @override
  String get cloudGoogleSource => 'Google Play';

  @override
  String get cloudWebSource => 'the web purchase provider';

  @override
  String cloudDevices(int count, int limit) {
    return 'Devices · $count / $limit';
  }

  @override
  String get cloudThisDevice => 'This device';

  @override
  String get cloudNotSyncing => 'Not syncing';

  @override
  String get cloudSyncSlotActive => 'Using a sync slot';

  @override
  String cloudLastSeen(String time) {
    return 'Last active: $time';
  }

  @override
  String get cloudDeviceIos => 'iOS';

  @override
  String get cloudDeviceAndroid => 'Android';

  @override
  String get cloudDeviceMacos => 'macOS';

  @override
  String get cloudDeviceWindows => 'Windows';

  @override
  String get cloudDeviceLinux => 'Linux';

  @override
  String get cloudDeviceRemoveHint =>
      'Swipe left or right-click to remove other devices. Use Sign out for this device.';

  @override
  String get cloudRemoveDevice => 'Remove';

  @override
  String cloudRemoveDeviceTitle(String name) {
    return 'Remove “$name”?';
  }

  @override
  String get cloudRemoveDeviceNote =>
      'This device will be signed out and its sync slot released. Its local content will be kept.';

  @override
  String get cloudLogout => 'Sign out';

  @override
  String get cloudLogoutTitle => 'Sign out of Avalon?';

  @override
  String get cloudLogoutNote =>
      'All local configurations, nodes and proxy credentials will be kept. If offline, the original session will be revoked automatically when online.';

  @override
  String get cloudDeleteAccount => 'Delete account';

  @override
  String get cloudDeleteFirstTitle => 'Delete your Avalon account?';

  @override
  String get cloudDeleteFirstNote =>
      'Your account and cloud content will be deleted. Local configurations and proxy credentials will be kept.';

  @override
  String get cloudDeleteContinue => 'Continue';

  @override
  String get cloudDeleteFinalTitle => 'Permanently delete your account?';

  @override
  String get cloudDeleteFinalNote =>
      'Your account will be permanently deleted. Cancel your subscription and automatic renewal separately with your purchase provider.';

  @override
  String get cloudAccountDeleted =>
      'Account deleted. Your local content has been kept.';

  @override
  String cloudCancelSubscription(String sources) {
    return 'Cancel subscription renewal at $sources.';
  }

  @override
  String cloudPendingRevocations(int count) {
    return '$count original sessions waiting for revocation';
  }

  @override
  String get cloudPendingRevocationsNote =>
      'Signed out locally. Revocation of the original sessions will retry automatically when online.';

  @override
  String get cloudRetryRevocations => 'Retry revocation now';

  @override
  String get cloudRevocationUnconfirmed =>
      'The original session proof has expired, so remote revocation could not be confirmed. This device remains signed out.';

  @override
  String get cloudErrorDisabled =>
      'Account and sync access is disabled. Return to local features.';

  @override
  String get cloudErrorInvalidEmail => 'Enter a valid email address.';

  @override
  String get cloudErrorInvalidCode => 'Enter the six-digit numeric code.';

  @override
  String get cloudErrorValidation =>
      'The request was not accepted. Check your input and retry.';

  @override
  String get cloudErrorChallengeInvalid =>
      'The code or sign-in request is invalid. Check the code or send it again.';

  @override
  String get cloudErrorChallengeExpired =>
      'The code has expired. Send it again.';

  @override
  String get cloudErrorChallengeExhausted =>
      'Too many code attempts. Send a new code.';

  @override
  String get cloudErrorChallengeEnded =>
      'This sign-in request has ended or is unavailable. Send a new code.';

  @override
  String get cloudErrorRateLimited =>
      'Too many requests. Please try again later.';

  @override
  String cloudErrorRateLimitedWait(int seconds) {
    return 'Too many requests. Try again in $seconds seconds.';
  }

  @override
  String get cloudErrorOffline =>
      'Cannot connect to Cloud. Check your network and retry. Local features remain available.';

  @override
  String get cloudErrorTimeout =>
      'Cloud did not respond in time. Please try again later.';

  @override
  String get cloudErrorProtocol =>
      'The Cloud response could not be read. Update the app or try again later.';

  @override
  String get cloudErrorReauthenticate =>
      'Sign in again, or sign out of the original session. Local content is preserved.';

  @override
  String get cloudErrorSessionRevoked =>
      'Your sign-in is no longer valid. Please sign in again.';

  @override
  String get cloudErrorDeviceNotFound =>
      'This device no longer exists. Refresh account details.';

  @override
  String get cloudErrorCurrentDevice => 'Use Sign out to remove this device.';

  @override
  String get cloudErrorDeleteUnconfirmed =>
      'The deletion result could not be confirmed. Refresh account details or sign in again to check before retrying.';

  @override
  String get cloudErrorServer =>
      'Cloud cannot complete the request right now. Please try again later.';

  @override
  String get cloudErrorUnknown =>
      'The action was not completed. Retry or sign in again.';

  @override
  String cloudCodeExpires(String time) {
    return 'Code valid until $time';
  }

  @override
  String get tailnetTitle => 'Tailscale';

  @override
  String get tailnetEnable => 'Enable Tailscale';

  @override
  String get tailnetDisabled => 'Disabled';

  @override
  String get tailnetNeedsLogin => 'Sign in required';

  @override
  String tailnetConnected(String tailnet) {
    return 'Connected · $tailnet';
  }

  @override
  String get tailnetOffline => 'Offline';

  @override
  String get tailnetThisDevice => 'This device';

  @override
  String get tailnetHostname => 'Device name';

  @override
  String get tailnetAddresses => 'IP addresses';

  @override
  String get tailnetNetwork => 'Tailnet';

  @override
  String get tailnetExitNodes => 'Exit node';

  @override
  String get tailnetNoExit => 'None';

  @override
  String get tailnetNoExitNote =>
      'Internet traffic uses your current network and proxy settings.';

  @override
  String get tailnetExitOffline =>
      'This exit node is offline and cannot be used.';

  @override
  String get tailnetAcceptRoutes => 'Accept subnet routes';

  @override
  String get tailnetAcceptRoutesNote =>
      'Access subnets advertised by devices in your Tailnet.';

  @override
  String get tailnetMagicDns => 'MagicDNS';

  @override
  String get tailnetMagicDnsNote => 'Reach Tailnet devices by their names.';

  @override
  String get tailnetAdvertiseExit => 'Advertise this device as an exit node';

  @override
  String get tailnetAdvertiseExitNote =>
      'Allow other Tailnet devices to access the internet through this device.';

  @override
  String get tailnetLogout => 'Sign out of Tailnet';

  @override
  String get tailnetLogin => 'Sign in to Tailscale';

  @override
  String get tailnetUnavailable => 'This host cannot run Tailscale.';

  @override
  String tailnetError(String message) {
    return 'Connection failed: $message';
  }

  @override
  String get tailnetBrowserFailed =>
      'Could not open the sign-in page. Check your browser settings and retry.';

  @override
  String tailnetDevicesOnline(int count) {
    return 'Online devices · $count';
  }

  @override
  String get tailnetOnline => 'Online';

  @override
  String get tailnetOptions => 'Options';

  @override
  String get tailnetFixedRoutesNote =>
      'Reach Tailnet devices using their Tailscale addresses and device names.';

  @override
  String get tailnetExitUseNote =>
      'The selected exit node is also available in the Custom group.';

  @override
  String get tailnetExitConflict =>
      'Choose either to use another exit node or to share this device as an exit node.';

  @override
  String get tailnetWaiting => 'Waiting for sign-in…';

  @override
  String get tailnetPermissionRefused =>
      'System network permission is required to enable Tailscale.';

  @override
  String get aboutCheckUpdates => 'Check for updates';

  @override
  String get aboutCheckingUpdates => 'Checking…';

  @override
  String aboutUpdateAvailable(String version) {
    return 'Version $version available';
  }

  @override
  String get aboutUpToDate => 'Up to date';

  @override
  String get aboutNoRelease => 'No compatible release available';

  @override
  String get aboutSource => 'Source on GitHub';

  @override
  String get aboutChangelog => 'Release notes';

  @override
  String get aboutPrivacy => 'Privacy policy';

  @override
  String get aboutUpdateFailed =>
      'Could not check for updates. Check your connection and retry.';

  @override
  String get aboutBrowserFailed =>
      'Could not open the page. Check your browser settings.';

  @override
  String get tailnetExitNotReady =>
      'Exit node support is planned. Access to devices within your Tailnet is available.';

  @override
  String get tailnetAdvertiseNotReady =>
      'Sharing this device as an exit node is planned.';

  @override
  String get systemProxyFailed =>
      'Could not set or restore the system proxy. Check system permissions and retry.';

  @override
  String get manageSelfContent => 'Manage';
}
