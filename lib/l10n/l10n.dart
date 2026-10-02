// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class AppLocalizations {
  AppLocalizations();

  static AppLocalizations? _current;

  static AppLocalizations get current {
    assert(
      _current != null,
      'No instance of AppLocalizations was loaded. Try to initialize the AppLocalizations delegate before accessing AppLocalizations.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<AppLocalizations> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = AppLocalizations();
      AppLocalizations._current = instance;

      return instance;
    });
  }

  static AppLocalizations of(BuildContext context) {
    final instance = AppLocalizations.maybeOf(context);
    assert(
      instance != null,
      'No instance of AppLocalizations present in the widget tree. Did you add AppLocalizations.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static AppLocalizations? maybeOf(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  /// `Rule`
  String get rule {
    return Intl.message('Rule', name: 'rule', desc: '', args: []);
  }

  /// `Global`
  String get global {
    return Intl.message('Global', name: 'global', desc: '', args: []);
  }

  /// `Direct`
  String get direct {
    return Intl.message('Direct', name: 'direct', desc: '', args: []);
  }

  /// `Dashboard`
  String get dashboard {
    return Intl.message('Dashboard', name: 'dashboard', desc: '', args: []);
  }

  /// `Proxies`
  String get proxies {
    return Intl.message('Proxies', name: 'proxies', desc: '', args: []);
  }

  /// `Profile`
  String get profile {
    return Intl.message('Profile', name: 'profile', desc: '', args: []);
  }

  /// `Profiles`
  String get profiles {
    return Intl.message('Profiles', name: 'profiles', desc: '', args: []);
  }

  /// `Tools`
  String get tools {
    return Intl.message('Tools', name: 'tools', desc: '', args: []);
  }

  /// `Logs`
  String get logs {
    return Intl.message('Logs', name: 'logs', desc: '', args: []);
  }

  /// `Log capture records`
  String get logsDesc {
    return Intl.message(
      'Log capture records',
      name: 'logsDesc',
      desc: '',
      args: [],
    );
  }

  /// `Resources`
  String get resources {
    return Intl.message('Resources', name: 'resources', desc: '', args: []);
  }

  /// `External resource related info`
  String get resourcesDesc {
    return Intl.message(
      'External resource related info',
      name: 'resourcesDesc',
      desc: '',
      args: [],
    );
  }

  /// `Traffic usage`
  String get trafficUsage {
    return Intl.message(
      'Traffic usage',
      name: 'trafficUsage',
      desc: '',
      args: [],
    );
  }

  /// `Network speed`
  String get networkSpeed {
    return Intl.message(
      'Network speed',
      name: 'networkSpeed',
      desc: '',
      args: [],
    );
  }

  /// `Outbound mode`
  String get outboundMode {
    return Intl.message(
      'Outbound mode',
      name: 'outboundMode',
      desc: '',
      args: [],
    );
  }

  /// `Network detection`
  String get networkDetection {
    return Intl.message(
      'Network detection',
      name: 'networkDetection',
      desc: '',
      args: [],
    );
  }

  /// `Upload`
  String get upload {
    return Intl.message('Upload', name: 'upload', desc: '', args: []);
  }

  /// `Download`
  String get download {
    return Intl.message('Download', name: 'download', desc: '', args: []);
  }

  /// `No profile, Please add a profile`
  String get nullProfileDesc {
    return Intl.message(
      'No profile, Please add a profile',
      name: 'nullProfileDesc',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get settings {
    return Intl.message('Settings', name: 'settings', desc: '', args: []);
  }

  /// `Language`
  String get language {
    return Intl.message('Language', name: 'language', desc: '', args: []);
  }

  /// `Default`
  String get defaultText {
    return Intl.message('Default', name: 'defaultText', desc: '', args: []);
  }

  /// `More`
  String get more {
    return Intl.message('More', name: 'more', desc: '', args: []);
  }

  /// `Other`
  String get other {
    return Intl.message('Other', name: 'other', desc: '', args: []);
  }

  /// `About`
  String get about {
    return Intl.message('About', name: 'about', desc: '', args: []);
  }

  /// `English`
  String get en {
    return Intl.message('English', name: 'en', desc: '', args: []);
  }

  /// `Japanese`
  String get ja {
    return Intl.message('Japanese', name: 'ja', desc: '', args: []);
  }

  /// `Russian`
  String get ru {
    return Intl.message('Russian', name: 'ru', desc: '', args: []);
  }

  /// `Simplified Chinese`
  String get zh_CN {
    return Intl.message(
      'Simplified Chinese',
      name: 'zh_CN',
      desc: '',
      args: [],
    );
  }

  /// `Theme`
  String get theme {
    return Intl.message('Theme', name: 'theme', desc: '', args: []);
  }

  /// `Set dark mode,adjust the color`
  String get themeDesc {
    return Intl.message(
      'Set dark mode,adjust the color',
      name: 'themeDesc',
      desc: '',
      args: [],
    );
  }

  /// `Override`
  String get override {
    return Intl.message('Override', name: 'override', desc: '', args: []);
  }

  /// `AllowLan`
  String get allowLan {
    return Intl.message('AllowLan', name: 'allowLan', desc: '', args: []);
  }

  /// `Allow access proxy through the LAN`
  String get allowLanDesc {
    return Intl.message(
      'Allow access proxy through the LAN',
      name: 'allowLanDesc',
      desc: '',
      args: [],
    );
  }

  /// `TUN`
  String get tun {
    return Intl.message('TUN', name: 'tun', desc: '', args: []);
  }

  /// `only effective in administrator mode`
  String get tunDesc {
    return Intl.message(
      'only effective in administrator mode',
      name: 'tunDesc',
      desc: '',
      args: [],
    );
  }

  /// `Strict route`
  String get strictRoute {
    return Intl.message(
      'Strict route',
      name: 'strictRoute',
      desc: '',
      args: [],
    );
  }

  /// `Block traffic that bypasses the virtual adapter to prevent DNS and WebRTC leaks. May break virtual machines and LAN access`
  String get strictRouteDesc {
    return Intl.message(
      'Block traffic that bypasses the virtual adapter to prevent DNS and WebRTC leaks. May break virtual machines and LAN access',
      name: 'strictRouteDesc',
      desc: '',
      args: [],
    );
  }

  /// `TUN IPv6`
  String get tunIpv6 {
    return Intl.message('TUN IPv6', name: 'tunIpv6', desc: '', args: []);
  }

  /// `Let the virtual adapter carry IPv6. Keeps IPv6 inside the tunnel, but direct traffic then depends on the host having a working IPv6 uplink`
  String get tunIpv6Desc {
    return Intl.message(
      'Let the virtual adapter carry IPv6. Keeps IPv6 inside the tunnel, but direct traffic then depends on the host having a working IPv6 uplink',
      name: 'tunIpv6Desc',
      desc: '',
      args: [],
    );
  }

  /// `Minimize on exit`
  String get minimizeOnExit {
    return Intl.message(
      'Minimize on exit',
      name: 'minimizeOnExit',
      desc: '',
      args: [],
    );
  }

  /// `Modify the default system exit event`
  String get minimizeOnExitDesc {
    return Intl.message(
      'Modify the default system exit event',
      name: 'minimizeOnExitDesc',
      desc: '',
      args: [],
    );
  }

  /// `Auto launch`
  String get autoLaunch {
    return Intl.message('Auto launch', name: 'autoLaunch', desc: '', args: []);
  }

  /// `Follow the system self startup`
  String get autoLaunchDesc {
    return Intl.message(
      'Follow the system self startup',
      name: 'autoLaunchDesc',
      desc: '',
      args: [],
    );
  }

  /// `SilentLaunch`
  String get silentLaunch {
    return Intl.message(
      'SilentLaunch',
      name: 'silentLaunch',
      desc: '',
      args: [],
    );
  }

  /// `Start in the background`
  String get silentLaunchDesc {
    return Intl.message(
      'Start in the background',
      name: 'silentLaunchDesc',
      desc: '',
      args: [],
    );
  }

  /// `AutoRun`
  String get autoRun {
    return Intl.message('AutoRun', name: 'autoRun', desc: '', args: []);
  }

  /// `Auto run when the application is opened`
  String get autoRunDesc {
    return Intl.message(
      'Auto run when the application is opened',
      name: 'autoRunDesc',
      desc: '',
      args: [],
    );
  }

  /// `Logcat`
  String get logcat {
    return Intl.message('Logcat', name: 'logcat', desc: '', args: []);
  }

  /// `Disabling will hide the log entry`
  String get logcatDesc {
    return Intl.message(
      'Disabling will hide the log entry',
      name: 'logcatDesc',
      desc: '',
      args: [],
    );
  }

  /// `Auto check updates`
  String get autoCheckUpdate {
    return Intl.message(
      'Auto check updates',
      name: 'autoCheckUpdate',
      desc: '',
      args: [],
    );
  }

  /// `Auto check for updates when the app starts`
  String get autoCheckUpdateDesc {
    return Intl.message(
      'Auto check for updates when the app starts',
      name: 'autoCheckUpdateDesc',
      desc: '',
      args: [],
    );
  }

  /// `AccessControl`
  String get accessControl {
    return Intl.message(
      'AccessControl',
      name: 'accessControl',
      desc: '',
      args: [],
    );
  }

  /// `Configure application access proxy`
  String get accessControlDesc {
    return Intl.message(
      'Configure application access proxy',
      name: 'accessControlDesc',
      desc: '',
      args: [],
    );
  }

  /// `Application`
  String get application {
    return Intl.message('Application', name: 'application', desc: '', args: []);
  }

  /// `Modify application related settings`
  String get applicationDesc {
    return Intl.message(
      'Modify application related settings',
      name: 'applicationDesc',
      desc: '',
      args: [],
    );
  }

  /// `Edit`
  String get edit {
    return Intl.message('Edit', name: 'edit', desc: '', args: []);
  }

  /// `Confirm`
  String get confirm {
    return Intl.message('Confirm', name: 'confirm', desc: '', args: []);
  }

  /// `Update`
  String get update {
    return Intl.message('Update', name: 'update', desc: '', args: []);
  }

  /// `Add`
  String get add {
    return Intl.message('Add', name: 'add', desc: '', args: []);
  }

  /// `Save`
  String get save {
    return Intl.message('Save', name: 'save', desc: '', args: []);
  }

  /// `Delete`
  String get delete {
    return Intl.message('Delete', name: 'delete', desc: '', args: []);
  }

  /// `Seconds`
  String get seconds {
    return Intl.message('Seconds', name: 'seconds', desc: '', args: []);
  }

  /// `QR code`
  String get qrcode {
    return Intl.message('QR code', name: 'qrcode', desc: '', args: []);
  }

  /// `Scan QR code to obtain profile`
  String get qrcodeDesc {
    return Intl.message(
      'Scan QR code to obtain profile',
      name: 'qrcodeDesc',
      desc: '',
      args: [],
    );
  }

  /// `URL`
  String get url {
    return Intl.message('URL', name: 'url', desc: '', args: []);
  }

  /// `Obtain profile through URL`
  String get urlDesc {
    return Intl.message(
      'Obtain profile through URL',
      name: 'urlDesc',
      desc: '',
      args: [],
    );
  }

  /// `File`
  String get file {
    return Intl.message('File', name: 'file', desc: '', args: []);
  }

  /// `Directly upload profile`
  String get fileDesc {
    return Intl.message(
      'Directly upload profile',
      name: 'fileDesc',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get name {
    return Intl.message('Name', name: 'name', desc: '', args: []);
  }

  /// `Please input the profile name`
  String get profileNameNullValidationDesc {
    return Intl.message(
      'Please input the profile name',
      name: 'profileNameNullValidationDesc',
      desc: '',
      args: [],
    );
  }

  /// `Please input the profile URL`
  String get profileUrlNullValidationDesc {
    return Intl.message(
      'Please input the profile URL',
      name: 'profileUrlNullValidationDesc',
      desc: '',
      args: [],
    );
  }

  /// `Please input a valid profile URL`
  String get profileUrlInvalidValidationDesc {
    return Intl.message(
      'Please input a valid profile URL',
      name: 'profileUrlInvalidValidationDesc',
      desc: '',
      args: [],
    );
  }

  /// `Auto update`
  String get autoUpdate {
    return Intl.message('Auto update', name: 'autoUpdate', desc: '', args: []);
  }

  /// `Auto update interval (minutes)`
  String get autoUpdateInterval {
    return Intl.message(
      'Auto update interval (minutes)',
      name: 'autoUpdateInterval',
      desc: '',
      args: [],
    );
  }

  /// `Please enter the auto update interval time`
  String get profileAutoUpdateIntervalNullValidationDesc {
    return Intl.message(
      'Please enter the auto update interval time',
      name: 'profileAutoUpdateIntervalNullValidationDesc',
      desc: '',
      args: [],
    );
  }

  /// `Please input a valid interval time format`
  String get profileAutoUpdateIntervalInvalidValidationDesc {
    return Intl.message(
      'Please input a valid interval time format',
      name: 'profileAutoUpdateIntervalInvalidValidationDesc',
      desc: '',
      args: [],
    );
  }

  /// `Theme mode`
  String get themeMode {
    return Intl.message('Theme mode', name: 'themeMode', desc: '', args: []);
  }

  /// `Theme color`
  String get themeColor {
    return Intl.message('Theme color', name: 'themeColor', desc: '', args: []);
  }

  /// `Preview`
  String get preview {
    return Intl.message('Preview', name: 'preview', desc: '', args: []);
  }

  /// `Auto`
  String get auto {
    return Intl.message('Auto', name: 'auto', desc: '', args: []);
  }

  /// `Light`
  String get light {
    return Intl.message('Light', name: 'light', desc: '', args: []);
  }

  /// `Dark`
  String get dark {
    return Intl.message('Dark', name: 'dark', desc: '', args: []);
  }

  /// `Import from URL`
  String get importFromURL {
    return Intl.message(
      'Import from URL',
      name: 'importFromURL',
      desc: '',
      args: [],
    );
  }

  /// `Submit`
  String get submit {
    return Intl.message('Submit', name: 'submit', desc: '', args: []);
  }

  /// `Do you want to pass`
  String get doYouWantToPass {
    return Intl.message(
      'Do you want to pass',
      name: 'doYouWantToPass',
      desc: '',
      args: [],
    );
  }

  /// `Create`
  String get create {
    return Intl.message('Create', name: 'create', desc: '', args: []);
  }

  /// `Please upload a valid QR code`
  String get pleaseUploadValidQrcode {
    return Intl.message(
      'Please upload a valid QR code',
      name: 'pleaseUploadValidQrcode',
      desc: '',
      args: [],
    );
  }

  /// `Blacklist mode`
  String get blacklistMode {
    return Intl.message(
      'Blacklist mode',
      name: 'blacklistMode',
      desc: '',
      args: [],
    );
  }

  /// `Whitelist mode`
  String get whitelistMode {
    return Intl.message(
      'Whitelist mode',
      name: 'whitelistMode',
      desc: '',
      args: [],
    );
  }

  /// `Select all`
  String get selectAll {
    return Intl.message('Select all', name: 'selectAll', desc: '', args: []);
  }

  /// `Cancel select all`
  String get cancelSelectAll {
    return Intl.message(
      'Cancel select all',
      name: 'cancelSelectAll',
      desc: '',
      args: [],
    );
  }

  /// `App access control`
  String get appAccessControl {
    return Intl.message(
      'App access control',
      name: 'appAccessControl',
      desc: '',
      args: [],
    );
  }

  /// `Only allow selected app to enter VPN`
  String get accessControlAllowDesc {
    return Intl.message(
      'Only allow selected app to enter VPN',
      name: 'accessControlAllowDesc',
      desc: '',
      args: [],
    );
  }

  /// `The selected application will be excluded from VPN`
  String get accessControlNotAllowDesc {
    return Intl.message(
      'The selected application will be excluded from VPN',
      name: 'accessControlNotAllowDesc',
      desc: '',
      args: [],
    );
  }

  /// `Selected`
  String get selected {
    return Intl.message('Selected', name: 'selected', desc: '', args: []);
  }

  /// `ProxyPort`
  String get proxyPort {
    return Intl.message('ProxyPort', name: 'proxyPort', desc: '', args: []);
  }

  /// `Port`
  String get port {
    return Intl.message('Port', name: 'port', desc: '', args: []);
  }

  /// `LogLevel`
  String get logLevel {
    return Intl.message('LogLevel', name: 'logLevel', desc: '', args: []);
  }

  /// `Show`
  String get show {
    return Intl.message('Show', name: 'show', desc: '', args: []);
  }

  /// `Exit`
  String get exit {
    return Intl.message('Exit', name: 'exit', desc: '', args: []);
  }

  /// `System proxy`
  String get systemProxy {
    return Intl.message(
      'System proxy',
      name: 'systemProxy',
      desc: '',
      args: [],
    );
  }

  /// `Project`
  String get project {
    return Intl.message('Project', name: 'project', desc: '', args: []);
  }

  /// `Core`
  String get core {
    return Intl.message('Core', name: 'core', desc: '', args: []);
  }

  /// `Tab animation`
  String get tabAnimation {
    return Intl.message(
      'Tab animation',
      name: 'tabAnimation',
      desc: '',
      args: [],
    );
  }

  /// `A multi-platform proxy client based on ClashMeta, simple and easy to use, open-source and ad-free.`
  String get desc {
    return Intl.message(
      'A multi-platform proxy client based on ClashMeta, simple and easy to use, open-source and ad-free.',
      name: 'desc',
      desc: '',
      args: [],
    );
  }

  /// `Starting VPN...`
  String get startVpn {
    return Intl.message(
      'Starting VPN...',
      name: 'startVpn',
      desc: '',
      args: [],
    );
  }

  /// `Stopping VPN...`
  String get stopVpn {
    return Intl.message('Stopping VPN...', name: 'stopVpn', desc: '', args: []);
  }

  /// `Compatibility mode`
  String get compatible {
    return Intl.message(
      'Compatibility mode',
      name: 'compatible',
      desc: '',
      args: [],
    );
  }

  /// `The current proxy group cannot be selected.`
  String get notSelectedTip {
    return Intl.message(
      'The current proxy group cannot be selected.',
      name: 'notSelectedTip',
      desc: '',
      args: [],
    );
  }

  /// `tip`
  String get tip {
    return Intl.message('tip', name: 'tip', desc: '', args: []);
  }

  /// `Account`
  String get account {
    return Intl.message('Account', name: 'account', desc: '', args: []);
  }

  /// `Backup`
  String get backup {
    return Intl.message('Backup', name: 'backup', desc: '', args: []);
  }

  /// `Backup success`
  String get backupSuccess {
    return Intl.message(
      'Backup success',
      name: 'backupSuccess',
      desc: '',
      args: [],
    );
  }

  /// `No info`
  String get noInfo {
    return Intl.message('No info', name: 'noInfo', desc: '', args: []);
  }

  /// `Please bind WebDAV`
  String get pleaseBindWebDAV {
    return Intl.message(
      'Please bind WebDAV',
      name: 'pleaseBindWebDAV',
      desc: '',
      args: [],
    );
  }

  /// `Bind`
  String get bind {
    return Intl.message('Bind', name: 'bind', desc: '', args: []);
  }

  /// `Connectivity：`
  String get connectivity {
    return Intl.message(
      'Connectivity：',
      name: 'connectivity',
      desc: '',
      args: [],
    );
  }

  /// `WebDAV configuration`
  String get webDAVConfiguration {
    return Intl.message(
      'WebDAV configuration',
      name: 'webDAVConfiguration',
      desc: '',
      args: [],
    );
  }

  /// `Address`
  String get address {
    return Intl.message('Address', name: 'address', desc: '', args: []);
  }

  /// `WebDAV server address`
  String get addressHelp {
    return Intl.message(
      'WebDAV server address',
      name: 'addressHelp',
      desc: '',
      args: [],
    );
  }

  /// `Please enter a valid WebDAV address`
  String get addressTip {
    return Intl.message(
      'Please enter a valid WebDAV address',
      name: 'addressTip',
      desc: '',
      args: [],
    );
  }

  /// `Password`
  String get password {
    return Intl.message('Password', name: 'password', desc: '', args: []);
  }

  /// `Check for updates`
  String get checkUpdate {
    return Intl.message(
      'Check for updates',
      name: 'checkUpdate',
      desc: '',
      args: [],
    );
  }

  /// `Discover the new version`
  String get discoverNewVersion {
    return Intl.message(
      'Discover the new version',
      name: 'discoverNewVersion',
      desc: '',
      args: [],
    );
  }

  /// `The current application is already the latest version`
  String get checkUpdateError {
    return Intl.message(
      'The current application is already the latest version',
      name: 'checkUpdateError',
      desc: '',
      args: [],
    );
  }

  /// `Go to download`
  String get goDownload {
    return Intl.message(
      'Go to download',
      name: 'goDownload',
      desc: '',
      args: [],
    );
  }

  /// `Unknown`
  String get unknown {
    return Intl.message('Unknown', name: 'unknown', desc: '', args: []);
  }

  /// `Country`
  String get country {
    return Intl.message('Country', name: 'country', desc: '', args: []);
  }

  /// `Search`
  String get search {
    return Intl.message('Search', name: 'search', desc: '', args: []);
  }

  /// `Allow applications to bypass VPN`
  String get allowBypass {
    return Intl.message(
      'Allow applications to bypass VPN',
      name: 'allowBypass',
      desc: '',
      args: [],
    );
  }

  /// `Some apps can bypass VPN when turned on`
  String get allowBypassDesc {
    return Intl.message(
      'Some apps can bypass VPN when turned on',
      name: 'allowBypassDesc',
      desc: '',
      args: [],
    );
  }

  /// `ExternalController`
  String get externalController {
    return Intl.message(
      'ExternalController',
      name: 'externalController',
      desc: '',
      args: [],
    );
  }

  /// `Once enabled, the Clash kernel can be controlled on port 9090`
  String get externalControllerDesc {
    return Intl.message(
      'Once enabled, the Clash kernel can be controlled on port 9090',
      name: 'externalControllerDesc',
      desc: '',
      args: [],
    );
  }

  /// `When turned on it will be able to receive IPv6 traffic`
  String get ipv6Desc {
    return Intl.message(
      'When turned on it will be able to receive IPv6 traffic',
      name: 'ipv6Desc',
      desc: '',
      args: [],
    );
  }

  /// `App`
  String get app {
    return Intl.message('App', name: 'app', desc: '', args: []);
  }

  /// `General`
  String get general {
    return Intl.message('General', name: 'general', desc: '', args: []);
  }

  /// `Attach HTTP proxy to VpnService`
  String get systemProxyDesc {
    return Intl.message(
      'Attach HTTP proxy to VpnService',
      name: 'systemProxyDesc',
      desc: '',
      args: [],
    );
  }

  /// `User-Agent`
  String get userAgent {
    return Intl.message('User-Agent', name: 'userAgent', desc: '', args: []);
  }

  /// `Unified delay`
  String get unifiedDelay {
    return Intl.message(
      'Unified delay',
      name: 'unifiedDelay',
      desc: '',
      args: [],
    );
  }

  /// `Remove extra delays such as handshaking`
  String get unifiedDelayDesc {
    return Intl.message(
      'Remove extra delays such as handshaking',
      name: 'unifiedDelayDesc',
      desc: '',
      args: [],
    );
  }

  /// `TCP concurrent`
  String get tcpConcurrent {
    return Intl.message(
      'TCP concurrent',
      name: 'tcpConcurrent',
      desc: '',
      args: [],
    );
  }

  /// `Enabling it will allow TCP concurrency`
  String get tcpConcurrentDesc {
    return Intl.message(
      'Enabling it will allow TCP concurrency',
      name: 'tcpConcurrentDesc',
      desc: '',
      args: [],
    );
  }

  /// `Geo Low Memory Mode`
  String get geodataLoader {
    return Intl.message(
      'Geo Low Memory Mode',
      name: 'geodataLoader',
      desc: '',
      args: [],
    );
  }

  /// `Enabling will use the Geo low memory loader`
  String get geodataLoaderDesc {
    return Intl.message(
      'Enabling will use the Geo low memory loader',
      name: 'geodataLoaderDesc',
      desc: '',
      args: [],
    );
  }

  /// `Requests`
  String get requests {
    return Intl.message('Requests', name: 'requests', desc: '', args: []);
  }

  /// `View recently request records`
  String get requestsDesc {
    return Intl.message(
      'View recently request records',
      name: 'requestsDesc',
      desc: '',
      args: [],
    );
  }

  /// `Find process`
  String get findProcessMode {
    return Intl.message(
      'Find process',
      name: 'findProcessMode',
      desc: '',
      args: [],
    );
  }

  /// `Init`
  String get init {
    return Intl.message('Init', name: 'init', desc: '', args: []);
  }

  /// `Long term effective`
  String get infiniteTime {
    return Intl.message(
      'Long term effective',
      name: 'infiniteTime',
      desc: '',
      args: [],
    );
  }

  /// `Connections`
  String get connections {
    return Intl.message('Connections', name: 'connections', desc: '', args: []);
  }

  /// `View current connections data`
  String get connectionsDesc {
    return Intl.message(
      'View current connections data',
      name: 'connectionsDesc',
      desc: '',
      args: [],
    );
  }

  /// `Intranet IP`
  String get intranetIP {
    return Intl.message('Intranet IP', name: 'intranetIP', desc: '', args: []);
  }

  /// `View`
  String get view {
    return Intl.message('View', name: 'view', desc: '', args: []);
  }

  /// `Cut`
  String get cut {
    return Intl.message('Cut', name: 'cut', desc: '', args: []);
  }

  /// `Copy`
  String get copy {
    return Intl.message('Copy', name: 'copy', desc: '', args: []);
  }

  /// `Paste`
  String get paste {
    return Intl.message('Paste', name: 'paste', desc: '', args: []);
  }

  /// `Test url`
  String get testUrl {
    return Intl.message('Test url', name: 'testUrl', desc: '', args: []);
  }

  /// `Sync`
  String get sync {
    return Intl.message('Sync', name: 'sync', desc: '', args: []);
  }

  /// `Hidden from recent tasks`
  String get exclude {
    return Intl.message(
      'Hidden from recent tasks',
      name: 'exclude',
      desc: '',
      args: [],
    );
  }

  /// `When the app is in the background, the app is hidden from the recent task`
  String get excludeDesc {
    return Intl.message(
      'When the app is in the background, the app is hidden from the recent task',
      name: 'excludeDesc',
      desc: '',
      args: [],
    );
  }

  /// `Standard`
  String get expand {
    return Intl.message('Standard', name: 'expand', desc: '', args: []);
  }

  /// `Shrink`
  String get shrink {
    return Intl.message('Shrink', name: 'shrink', desc: '', args: []);
  }

  /// `Min`
  String get min {
    return Intl.message('Min', name: 'min', desc: '', args: []);
  }

  /// `Tab`
  String get tab {
    return Intl.message('Tab', name: 'tab', desc: '', args: []);
  }

  /// `List`
  String get list {
    return Intl.message('List', name: 'list', desc: '', args: []);
  }

  /// `Delay`
  String get delay {
    return Intl.message('Delay', name: 'delay', desc: '', args: []);
  }

  /// `Style`
  String get style {
    return Intl.message('Style', name: 'style', desc: '', args: []);
  }

  /// `Size`
  String get size {
    return Intl.message('Size', name: 'size', desc: '', args: []);
  }

  /// `Sort`
  String get sort {
    return Intl.message('Sort', name: 'sort', desc: '', args: []);
  }

  /// `Columns`
  String get columns {
    return Intl.message('Columns', name: 'columns', desc: '', args: []);
  }

  /// `Proxy group`
  String get proxyGroup {
    return Intl.message('Proxy group', name: 'proxyGroup', desc: '', args: []);
  }

  /// `Go`
  String get go {
    return Intl.message('Go', name: 'go', desc: '', args: []);
  }

  /// `External link`
  String get externalLink {
    return Intl.message(
      'External link',
      name: 'externalLink',
      desc: '',
      args: [],
    );
  }

  /// `Contributors`
  String get contributors {
    return Intl.message(
      'Contributors',
      name: 'contributors',
      desc: '',
      args: [],
    );
  }

  /// `Auto close connections`
  String get autoCloseConnections {
    return Intl.message(
      'Auto close connections',
      name: 'autoCloseConnections',
      desc: '',
      args: [],
    );
  }

  /// `Auto close connections after change node`
  String get autoCloseConnectionsDesc {
    return Intl.message(
      'Auto close connections after change node',
      name: 'autoCloseConnectionsDesc',
      desc: '',
      args: [],
    );
  }

  /// `Only statistics proxy`
  String get onlyStatisticsProxy {
    return Intl.message(
      'Only statistics proxy',
      name: 'onlyStatisticsProxy',
      desc: '',
      args: [],
    );
  }

  /// `When turned on, only statistics proxy traffic`
  String get onlyStatisticsProxyDesc {
    return Intl.message(
      'When turned on, only statistics proxy traffic',
      name: 'onlyStatisticsProxyDesc',
      desc: '',
      args: [],
    );
  }

  /// `Pure black mode`
  String get pureBlackMode {
    return Intl.message(
      'Pure black mode',
      name: 'pureBlackMode',
      desc: '',
      args: [],
    );
  }

  /// `Tcp keep alive interval`
  String get keepAliveIntervalDesc {
    return Intl.message(
      'Tcp keep alive interval',
      name: 'keepAliveIntervalDesc',
      desc: '',
      args: [],
    );
  }

  /// ` entries`
  String get entries {
    return Intl.message(' entries', name: 'entries', desc: '', args: []);
  }

  /// `Local`
  String get local {
    return Intl.message('Local', name: 'local', desc: '', args: []);
  }

  /// `Remote`
  String get remote {
    return Intl.message('Remote', name: 'remote', desc: '', args: []);
  }

  /// `Backup local data to WebDAV`
  String get remoteBackupDesc {
    return Intl.message(
      'Backup local data to WebDAV',
      name: 'remoteBackupDesc',
      desc: '',
      args: [],
    );
  }

  /// `Backup local data to local`
  String get localBackupDesc {
    return Intl.message(
      'Backup local data to local',
      name: 'localBackupDesc',
      desc: '',
      args: [],
    );
  }

  /// `Mode`
  String get mode {
    return Intl.message('Mode', name: 'mode', desc: '', args: []);
  }

  /// `Time`
  String get time {
    return Intl.message('Time', name: 'time', desc: '', args: []);
  }

  /// `Source`
  String get source {
    return Intl.message('Source', name: 'source', desc: '', args: []);
  }

  /// `Action`
  String get action {
    return Intl.message('Action', name: 'action', desc: '', args: []);
  }

  /// `Intelligent selection`
  String get intelligentSelected {
    return Intl.message(
      'Intelligent selection',
      name: 'intelligentSelected',
      desc: '',
      args: [],
    );
  }

  /// `Clipboard import`
  String get clipboardImport {
    return Intl.message(
      'Clipboard import',
      name: 'clipboardImport',
      desc: '',
      args: [],
    );
  }

  /// `Export clipboard`
  String get clipboardExport {
    return Intl.message(
      'Export clipboard',
      name: 'clipboardExport',
      desc: '',
      args: [],
    );
  }

  /// `Layout`
  String get layout {
    return Intl.message('Layout', name: 'layout', desc: '', args: []);
  }

  /// `Tight`
  String get tight {
    return Intl.message('Tight', name: 'tight', desc: '', args: []);
  }

  /// `Standard`
  String get standard {
    return Intl.message('Standard', name: 'standard', desc: '', args: []);
  }

  /// `Loose`
  String get loose {
    return Intl.message('Loose', name: 'loose', desc: '', args: []);
  }

  /// `Profiles sort`
  String get profilesSort {
    return Intl.message(
      'Profiles sort',
      name: 'profilesSort',
      desc: '',
      args: [],
    );
  }

  /// `Start`
  String get start {
    return Intl.message('Start', name: 'start', desc: '', args: []);
  }

  /// `Stop`
  String get stop {
    return Intl.message('Stop', name: 'stop', desc: '', args: []);
  }

  /// `Update DNS related settings`
  String get dnsDesc {
    return Intl.message(
      'Update DNS related settings',
      name: 'dnsDesc',
      desc: '',
      args: [],
    );
  }

  /// `Key`
  String get key {
    return Intl.message('Key', name: 'key', desc: '', args: []);
  }

  /// `Value`
  String get value {
    return Intl.message('Value', name: 'value', desc: '', args: []);
  }

  /// `Add Hosts`
  String get hostsDesc {
    return Intl.message('Add Hosts', name: 'hostsDesc', desc: '', args: []);
  }

  /// `Changes take effect after restarting the VPN`
  String get vpnTip {
    return Intl.message(
      'Changes take effect after restarting the VPN',
      name: 'vpnTip',
      desc: '',
      args: [],
    );
  }

  /// `Auto routes all system traffic through VpnService`
  String get vpnEnableDesc {
    return Intl.message(
      'Auto routes all system traffic through VpnService',
      name: 'vpnEnableDesc',
      desc: '',
      args: [],
    );
  }

  /// `Options`
  String get options {
    return Intl.message('Options', name: 'options', desc: '', args: []);
  }

  /// `Loopback unlock tool`
  String get loopback {
    return Intl.message(
      'Loopback unlock tool',
      name: 'loopback',
      desc: '',
      args: [],
    );
  }

  /// `Used for UWP loopback unlocking`
  String get loopbackDesc {
    return Intl.message(
      'Used for UWP loopback unlocking',
      name: 'loopbackDesc',
      desc: '',
      args: [],
    );
  }

  /// `Providers`
  String get providers {
    return Intl.message('Providers', name: 'providers', desc: '', args: []);
  }

  /// `Proxy providers`
  String get proxyProviders {
    return Intl.message(
      'Proxy providers',
      name: 'proxyProviders',
      desc: '',
      args: [],
    );
  }

  /// `Rule providers`
  String get ruleProviders {
    return Intl.message(
      'Rule providers',
      name: 'ruleProviders',
      desc: '',
      args: [],
    );
  }

  /// `Override Dns`
  String get overrideDns {
    return Intl.message(
      'Override Dns',
      name: 'overrideDns',
      desc: '',
      args: [],
    );
  }

  /// `Turning it on will override the DNS options in the profile`
  String get overrideDnsDesc {
    return Intl.message(
      'Turning it on will override the DNS options in the profile',
      name: 'overrideDnsDesc',
      desc: '',
      args: [],
    );
  }

  /// `Status`
  String get status {
    return Intl.message('Status', name: 'status', desc: '', args: []);
  }

  /// `System DNS will be used when turned off`
  String get statusDesc {
    return Intl.message(
      'System DNS will be used when turned off',
      name: 'statusDesc',
      desc: '',
      args: [],
    );
  }

  /// `Prioritize the use of DOH's http/3`
  String get preferH3Desc {
    return Intl.message(
      'Prioritize the use of DOH\'s http/3',
      name: 'preferH3Desc',
      desc: '',
      args: [],
    );
  }

  /// `Respect rules`
  String get respectRules {
    return Intl.message(
      'Respect rules',
      name: 'respectRules',
      desc: '',
      args: [],
    );
  }

  /// `DNS connection following rules, need to configure proxy-server-nameserver`
  String get respectRulesDesc {
    return Intl.message(
      'DNS connection following rules, need to configure proxy-server-nameserver',
      name: 'respectRulesDesc',
      desc: '',
      args: [],
    );
  }

  /// `DNS mode`
  String get dnsMode {
    return Intl.message('DNS mode', name: 'dnsMode', desc: '', args: []);
  }

  /// `Fakeip range`
  String get fakeipRange {
    return Intl.message(
      'Fakeip range',
      name: 'fakeipRange',
      desc: '',
      args: [],
    );
  }

  /// `Fakeip range (IPv6)`
  String get fakeipRange6 {
    return Intl.message(
      'Fakeip range (IPv6)',
      name: 'fakeipRange6',
      desc: '',
      args: [],
    );
  }

  /// `Fakeip filter`
  String get fakeipFilter {
    return Intl.message(
      'Fakeip filter',
      name: 'fakeipFilter',
      desc: '',
      args: [],
    );
  }

  /// `Default nameserver`
  String get defaultNameserver {
    return Intl.message(
      'Default nameserver',
      name: 'defaultNameserver',
      desc: '',
      args: [],
    );
  }

  /// `For resolving DNS server`
  String get defaultNameserverDesc {
    return Intl.message(
      'For resolving DNS server',
      name: 'defaultNameserverDesc',
      desc: '',
      args: [],
    );
  }

  /// `Nameserver`
  String get nameserver {
    return Intl.message('Nameserver', name: 'nameserver', desc: '', args: []);
  }

  /// `For resolving domain`
  String get nameserverDesc {
    return Intl.message(
      'For resolving domain',
      name: 'nameserverDesc',
      desc: '',
      args: [],
    );
  }

  /// `Use hosts`
  String get useHosts {
    return Intl.message('Use hosts', name: 'useHosts', desc: '', args: []);
  }

  /// `Use system hosts`
  String get useSystemHosts {
    return Intl.message(
      'Use system hosts',
      name: 'useSystemHosts',
      desc: '',
      args: [],
    );
  }

  /// `Nameserver policy`
  String get nameserverPolicy {
    return Intl.message(
      'Nameserver policy',
      name: 'nameserverPolicy',
      desc: '',
      args: [],
    );
  }

  /// `Specify the corresponding nameserver policy`
  String get nameserverPolicyDesc {
    return Intl.message(
      'Specify the corresponding nameserver policy',
      name: 'nameserverPolicyDesc',
      desc: '',
      args: [],
    );
  }

  /// `Proxy nameserver`
  String get proxyNameserver {
    return Intl.message(
      'Proxy nameserver',
      name: 'proxyNameserver',
      desc: '',
      args: [],
    );
  }

  /// `Domain for resolving proxy nodes`
  String get proxyNameserverDesc {
    return Intl.message(
      'Domain for resolving proxy nodes',
      name: 'proxyNameserverDesc',
      desc: '',
      args: [],
    );
  }

  /// `Fallback`
  String get fallback {
    return Intl.message('Fallback', name: 'fallback', desc: '', args: []);
  }

  /// `Generally use offshore DNS`
  String get fallbackDesc {
    return Intl.message(
      'Generally use offshore DNS',
      name: 'fallbackDesc',
      desc: '',
      args: [],
    );
  }

  /// `Fallback filter`
  String get fallbackFilter {
    return Intl.message(
      'Fallback filter',
      name: 'fallbackFilter',
      desc: '',
      args: [],
    );
  }

  /// `Geoip code`
  String get geoipCode {
    return Intl.message('Geoip code', name: 'geoipCode', desc: '', args: []);
  }

  /// `Ipcidr`
  String get ipcidr {
    return Intl.message('Ipcidr', name: 'ipcidr', desc: '', args: []);
  }

  /// `Domain`
  String get domain {
    return Intl.message('Domain', name: 'domain', desc: '', args: []);
  }

  /// `Reset`
  String get reset {
    return Intl.message('Reset', name: 'reset', desc: '', args: []);
  }

  /// `Show/Hide`
  String get action_view {
    return Intl.message('Show/Hide', name: 'action_view', desc: '', args: []);
  }

  /// `Start/Stop`
  String get action_start {
    return Intl.message('Start/Stop', name: 'action_start', desc: '', args: []);
  }

  /// `Switch mode`
  String get action_mode {
    return Intl.message('Switch mode', name: 'action_mode', desc: '', args: []);
  }

  /// `System proxy`
  String get action_proxy {
    return Intl.message(
      'System proxy',
      name: 'action_proxy',
      desc: '',
      args: [],
    );
  }

  /// `TUN`
  String get action_tun {
    return Intl.message('TUN', name: 'action_tun', desc: '', args: []);
  }

  /// `Disclaimer`
  String get disclaimer {
    return Intl.message('Disclaimer', name: 'disclaimer', desc: '', args: []);
  }

  /// `This software is only used for non-commercial purposes such as learning exchanges and scientific research. It is strictly prohibited to use this software for commercial purposes. Any commercial activity, if any, has nothing to do with this software.`
  String get disclaimerDesc {
    return Intl.message(
      'This software is only used for non-commercial purposes such as learning exchanges and scientific research. It is strictly prohibited to use this software for commercial purposes. Any commercial activity, if any, has nothing to do with this software.',
      name: 'disclaimerDesc',
      desc: '',
      args: [],
    );
  }

  /// `Agree`
  String get agree {
    return Intl.message('Agree', name: 'agree', desc: '', args: []);
  }

  /// `Hotkey Management`
  String get hotkeyManagement {
    return Intl.message(
      'Hotkey Management',
      name: 'hotkeyManagement',
      desc: '',
      args: [],
    );
  }

  /// `Use keyboard to control applications`
  String get hotkeyManagementDesc {
    return Intl.message(
      'Use keyboard to control applications',
      name: 'hotkeyManagementDesc',
      desc: '',
      args: [],
    );
  }

  /// `Please press the keyboard.`
  String get pressKeyboard {
    return Intl.message(
      'Please press the keyboard.',
      name: 'pressKeyboard',
      desc: '',
      args: [],
    );
  }

  /// `Please enter the correct hotkey`
  String get inputCorrectHotkey {
    return Intl.message(
      'Please enter the correct hotkey',
      name: 'inputCorrectHotkey',
      desc: '',
      args: [],
    );
  }

  /// `Hotkey conflict`
  String get hotkeyConflict {
    return Intl.message(
      'Hotkey conflict',
      name: 'hotkeyConflict',
      desc: '',
      args: [],
    );
  }

  /// `Remove`
  String get remove {
    return Intl.message('Remove', name: 'remove', desc: '', args: []);
  }

  /// `No HotKey`
  String get noHotKey {
    return Intl.message('No HotKey', name: 'noHotKey', desc: '', args: []);
  }

  /// `No network`
  String get noNetwork {
    return Intl.message('No network', name: 'noNetwork', desc: '', args: []);
  }

  /// `Allow IPv6 inbound`
  String get ipv6InboundDesc {
    return Intl.message(
      'Allow IPv6 inbound',
      name: 'ipv6InboundDesc',
      desc: '',
      args: [],
    );
  }

  /// `Export logs`
  String get exportLogs {
    return Intl.message('Export logs', name: 'exportLogs', desc: '', args: []);
  }

  /// `Export Success`
  String get exportSuccess {
    return Intl.message(
      'Export Success',
      name: 'exportSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Icon style`
  String get iconStyle {
    return Intl.message('Icon style', name: 'iconStyle', desc: '', args: []);
  }

  /// `Icon`
  String get onlyIcon {
    return Intl.message('Icon', name: 'onlyIcon', desc: '', args: []);
  }

  /// `Stack mode`
  String get stackMode {
    return Intl.message('Stack mode', name: 'stackMode', desc: '', args: []);
  }

  /// `Network`
  String get network {
    return Intl.message('Network', name: 'network', desc: '', args: []);
  }

  /// `Modify network-related settings`
  String get networkDesc {
    return Intl.message(
      'Modify network-related settings',
      name: 'networkDesc',
      desc: '',
      args: [],
    );
  }

  /// `Bypass domain`
  String get bypassDomain {
    return Intl.message(
      'Bypass domain',
      name: 'bypassDomain',
      desc: '',
      args: [],
    );
  }

  /// `Only takes effect when the system proxy is enabled`
  String get bypassDomainDesc {
    return Intl.message(
      'Only takes effect when the system proxy is enabled',
      name: 'bypassDomainDesc',
      desc: '',
      args: [],
    );
  }

  /// `Make sure to reset`
  String get resetTip {
    return Intl.message(
      'Make sure to reset',
      name: 'resetTip',
      desc: '',
      args: [],
    );
  }

  /// `Icon`
  String get icon {
    return Intl.message('Icon', name: 'icon', desc: '', args: []);
  }

  /// `No data`
  String get noData {
    return Intl.message('No data', name: 'noData', desc: '', args: []);
  }

  /// `FontFamily`
  String get fontFamily {
    return Intl.message('FontFamily', name: 'fontFamily', desc: '', args: []);
  }

  /// `Toggle`
  String get toggle {
    return Intl.message('Toggle', name: 'toggle', desc: '', args: []);
  }

  /// `System`
  String get system {
    return Intl.message('System', name: 'system', desc: '', args: []);
  }

  /// `Route mode`
  String get routeMode {
    return Intl.message('Route mode', name: 'routeMode', desc: '', args: []);
  }

  /// `Bypass private route address`
  String get routeMode_bypassPrivate {
    return Intl.message(
      'Bypass private route address',
      name: 'routeMode_bypassPrivate',
      desc: '',
      args: [],
    );
  }

  /// `Use config`
  String get routeMode_config {
    return Intl.message(
      'Use config',
      name: 'routeMode_config',
      desc: '',
      args: [],
    );
  }

  /// `Route address`
  String get routeAddress {
    return Intl.message(
      'Route address',
      name: 'routeAddress',
      desc: '',
      args: [],
    );
  }

  /// `Config listen route address`
  String get routeAddressDesc {
    return Intl.message(
      'Config listen route address',
      name: 'routeAddressDesc',
      desc: '',
      args: [],
    );
  }

  /// `Please enter the admin password`
  String get pleaseInputAdminPassword {
    return Intl.message(
      'Please enter the admin password',
      name: 'pleaseInputAdminPassword',
      desc: '',
      args: [],
    );
  }

  /// `Copying environment variables`
  String get copyEnvVar {
    return Intl.message(
      'Copying environment variables',
      name: 'copyEnvVar',
      desc: '',
      args: [],
    );
  }

  /// `Memory info`
  String get memoryInfo {
    return Intl.message('Memory info', name: 'memoryInfo', desc: '', args: []);
  }

  /// `Cancel`
  String get cancel {
    return Intl.message('Cancel', name: 'cancel', desc: '', args: []);
  }

  /// `The file has been modified. Do you want to save the changes?`
  String get fileIsUpdate {
    return Intl.message(
      'The file has been modified. Do you want to save the changes?',
      name: 'fileIsUpdate',
      desc: '',
      args: [],
    );
  }

  /// `The profile has been modified. Do you want to disable auto update?`
  String get profileHasUpdate {
    return Intl.message(
      'The profile has been modified. Do you want to disable auto update?',
      name: 'profileHasUpdate',
      desc: '',
      args: [],
    );
  }

  /// `Do you want to cache the changes?`
  String get hasCacheChange {
    return Intl.message(
      'Do you want to cache the changes?',
      name: 'hasCacheChange',
      desc: '',
      args: [],
    );
  }

  /// `Copy success`
  String get copySuccess {
    return Intl.message(
      'Copy success',
      name: 'copySuccess',
      desc: '',
      args: [],
    );
  }

  /// `Copy link`
  String get copyLink {
    return Intl.message('Copy link', name: 'copyLink', desc: '', args: []);
  }

  /// `Export file`
  String get exportFile {
    return Intl.message('Export file', name: 'exportFile', desc: '', args: []);
  }

  /// `The cache is corrupt. Do you want to clear it?`
  String get cacheCorrupt {
    return Intl.message(
      'The cache is corrupt. Do you want to clear it?',
      name: 'cacheCorrupt',
      desc: '',
      args: [],
    );
  }

  /// `Relying on third-party api is for reference only`
  String get detectionTip {
    return Intl.message(
      'Relying on third-party api is for reference only',
      name: 'detectionTip',
      desc: '',
      args: [],
    );
  }

  /// `Listen`
  String get listen {
    return Intl.message('Listen', name: 'listen', desc: '', args: []);
  }

  /// `undo`
  String get undo {
    return Intl.message('undo', name: 'undo', desc: '', args: []);
  }

  /// `redo`
  String get redo {
    return Intl.message('redo', name: 'redo', desc: '', args: []);
  }

  /// `none`
  String get none {
    return Intl.message('none', name: 'none', desc: '', args: []);
  }

  /// `Basic configuration`
  String get basicConfig {
    return Intl.message(
      'Basic configuration',
      name: 'basicConfig',
      desc: '',
      args: [],
    );
  }

  /// `Modify the basic configuration globally`
  String get basicConfigDesc {
    return Intl.message(
      'Modify the basic configuration globally',
      name: 'basicConfigDesc',
      desc: '',
      args: [],
    );
  }

  /// `Advanced configuration`
  String get advancedConfig {
    return Intl.message(
      'Advanced configuration',
      name: 'advancedConfig',
      desc: '',
      args: [],
    );
  }

  /// `Provide diverse configuration options`
  String get advancedConfigDesc {
    return Intl.message(
      'Provide diverse configuration options',
      name: 'advancedConfigDesc',
      desc: '',
      args: [],
    );
  }

  /// `{count} items have been selected`
  String selectedCountTitle(Object count) {
    return Intl.message(
      '$count items have been selected',
      name: 'selectedCountTitle',
      desc: '',
      args: [count],
    );
  }

  /// `Add rule`
  String get addRule {
    return Intl.message('Add rule', name: 'addRule', desc: '', args: []);
  }

  /// `Rule name`
  String get ruleName {
    return Intl.message('Rule name', name: 'ruleName', desc: '', args: []);
  }

  /// `Content`
  String get content {
    return Intl.message('Content', name: 'content', desc: '', args: []);
  }

  /// `Sub rule`
  String get subRule {
    return Intl.message('Sub rule', name: 'subRule', desc: '', args: []);
  }

  /// `Rule target`
  String get ruleTarget {
    return Intl.message('Rule target', name: 'ruleTarget', desc: '', args: []);
  }

  /// `Source IP`
  String get sourceIp {
    return Intl.message('Source IP', name: 'sourceIp', desc: '', args: []);
  }

  /// `No resolve IP`
  String get noResolve {
    return Intl.message('No resolve IP', name: 'noResolve', desc: '', args: []);
  }

  /// `Do you want to save the changes?`
  String get saveChanges {
    return Intl.message(
      'Do you want to save the changes?',
      name: 'saveChanges',
      desc: '',
      args: [],
    );
  }

  /// `There is a certain performance loss after opening`
  String get findProcessModeDesc {
    return Intl.message(
      'There is a certain performance loss after opening',
      name: 'findProcessModeDesc',
      desc: '',
      args: [],
    );
  }

  /// `Effective only in mobile view`
  String get tabAnimationDesc {
    return Intl.message(
      'Effective only in mobile view',
      name: 'tabAnimationDesc',
      desc: '',
      args: [],
    );
  }

  /// `Color schemes`
  String get colorSchemes {
    return Intl.message(
      'Color schemes',
      name: 'colorSchemes',
      desc: '',
      args: [],
    );
  }

  /// `Palette`
  String get palette {
    return Intl.message('Palette', name: 'palette', desc: '', args: []);
  }

  /// `TonalSpot`
  String get tonalSpotScheme {
    return Intl.message(
      'TonalSpot',
      name: 'tonalSpotScheme',
      desc: '',
      args: [],
    );
  }

  /// `Fidelity`
  String get fidelityScheme {
    return Intl.message('Fidelity', name: 'fidelityScheme', desc: '', args: []);
  }

  /// `Monochrome`
  String get monochromeScheme {
    return Intl.message(
      'Monochrome',
      name: 'monochromeScheme',
      desc: '',
      args: [],
    );
  }

  /// `Neutral`
  String get neutralScheme {
    return Intl.message('Neutral', name: 'neutralScheme', desc: '', args: []);
  }

  /// `Vibrant`
  String get vibrantScheme {
    return Intl.message('Vibrant', name: 'vibrantScheme', desc: '', args: []);
  }

  /// `Expressive`
  String get expressiveScheme {
    return Intl.message(
      'Expressive',
      name: 'expressiveScheme',
      desc: '',
      args: [],
    );
  }

  /// `Content`
  String get contentScheme {
    return Intl.message('Content', name: 'contentScheme', desc: '', args: []);
  }

  /// `Rainbow`
  String get rainbowScheme {
    return Intl.message('Rainbow', name: 'rainbowScheme', desc: '', args: []);
  }

  /// `FruitSalad`
  String get fruitSaladScheme {
    return Intl.message(
      'FruitSalad',
      name: 'fruitSaladScheme',
      desc: '',
      args: [],
    );
  }

  /// `Developer mode`
  String get developerMode {
    return Intl.message(
      'Developer mode',
      name: 'developerMode',
      desc: '',
      args: [],
    );
  }

  /// `Developer mode is enabled.`
  String get developerModeEnableTip {
    return Intl.message(
      'Developer mode is enabled.',
      name: 'developerModeEnableTip',
      desc: '',
      args: [],
    );
  }

  /// `Message test`
  String get messageTest {
    return Intl.message(
      'Message test',
      name: 'messageTest',
      desc: '',
      args: [],
    );
  }

  /// `This is a message.`
  String get messageTestTip {
    return Intl.message(
      'This is a message.',
      name: 'messageTestTip',
      desc: '',
      args: [],
    );
  }

  /// `Crash test`
  String get crashTest {
    return Intl.message('Crash test', name: 'crashTest', desc: '', args: []);
  }

  /// `Crash detected`
  String get crashDetected {
    return Intl.message(
      'Crash detected',
      name: 'crashDetected',
      desc: '',
      args: [],
    );
  }

  /// `The app crashed during the previous run. To prevent repeated crashes, the current profile has been cleared and automatic configuration setup was skipped.`
  String get crashDetectedTip {
    return Intl.message(
      'The app crashed during the previous run. To prevent repeated crashes, the current profile has been cleared and automatic configuration setup was skipped.',
      name: 'crashDetectedTip',
      desc: '',
      args: [],
    );
  }

  /// `Clear Data`
  String get clearData {
    return Intl.message('Clear Data', name: 'clearData', desc: '', args: []);
  }

  /// `Text Scaling`
  String get textScale {
    return Intl.message('Text Scaling', name: 'textScale', desc: '', args: []);
  }

  /// `Internet`
  String get internet {
    return Intl.message('Internet', name: 'internet', desc: '', args: []);
  }

  /// `System APP`
  String get systemApp {
    return Intl.message('System APP', name: 'systemApp', desc: '', args: []);
  }

  /// `No network APP`
  String get noNetworkApp {
    return Intl.message(
      'No network APP',
      name: 'noNetworkApp',
      desc: '',
      args: [],
    );
  }

  /// `Restore strategy`
  String get restoreStrategy {
    return Intl.message(
      'Restore strategy',
      name: 'restoreStrategy',
      desc: '',
      args: [],
    );
  }

  /// `Override`
  String get restoreStrategy_override {
    return Intl.message(
      'Override',
      name: 'restoreStrategy_override',
      desc: '',
      args: [],
    );
  }

  /// `Compatible`
  String get restoreStrategy_compatible {
    return Intl.message(
      'Compatible',
      name: 'restoreStrategy_compatible',
      desc: '',
      args: [],
    );
  }

  /// `Logs test`
  String get logsTest {
    return Intl.message('Logs test', name: 'logsTest', desc: '', args: []);
  }

  /// `{label} cannot be empty`
  String emptyTip(Object label) {
    return Intl.message(
      '$label cannot be empty',
      name: 'emptyTip',
      desc: '',
      args: [label],
    );
  }

  /// `{label} must be a url`
  String urlTip(Object label) {
    return Intl.message(
      '$label must be a url',
      name: 'urlTip',
      desc: '',
      args: [label],
    );
  }

  /// `{label} must be a number`
  String numberTip(Object label) {
    return Intl.message(
      '$label must be a number',
      name: 'numberTip',
      desc: '',
      args: [label],
    );
  }

  /// `Interval`
  String get interval {
    return Intl.message('Interval', name: 'interval', desc: '', args: []);
  }

  /// `Current {label} already exists`
  String existsTip(Object label) {
    return Intl.message(
      'Current $label already exists',
      name: 'existsTip',
      desc: '',
      args: [label],
    );
  }

  /// `Are you sure you want to delete the current {label}?`
  String deleteTip(Object label) {
    return Intl.message(
      'Are you sure you want to delete the current $label?',
      name: 'deleteTip',
      desc: '',
      args: [label],
    );
  }

  /// `Are you sure you want to delete the selected {label}?`
  String deleteMultipTip(Object label) {
    return Intl.message(
      'Are you sure you want to delete the selected $label?',
      name: 'deleteMultipTip',
      desc: '',
      args: [label],
    );
  }

  /// `No {label} yet`
  String nullTip(Object label) {
    return Intl.message(
      'No $label yet',
      name: 'nullTip',
      desc: '',
      args: [label],
    );
  }

  /// `Script`
  String get script {
    return Intl.message('Script', name: 'script', desc: '', args: []);
  }

  /// `Color`
  String get color {
    return Intl.message('Color', name: 'color', desc: '', args: []);
  }

  /// `Rename`
  String get rename {
    return Intl.message('Rename', name: 'rename', desc: '', args: []);
  }

  /// `Unnamed`
  String get unnamed {
    return Intl.message('Unnamed', name: 'unnamed', desc: '', args: []);
  }

  /// `Please enter a script name`
  String get pleaseEnterScriptName {
    return Intl.message(
      'Please enter a script name',
      name: 'pleaseEnterScriptName',
      desc: '',
      args: [],
    );
  }

  /// `Mixed Port`
  String get mixedPort {
    return Intl.message('Mixed Port', name: 'mixedPort', desc: '', args: []);
  }

  /// `Socks Port`
  String get socksPort {
    return Intl.message('Socks Port', name: 'socksPort', desc: '', args: []);
  }

  /// `Redir Port`
  String get redirPort {
    return Intl.message('Redir Port', name: 'redirPort', desc: '', args: []);
  }

  /// `Tproxy Port`
  String get tproxyPort {
    return Intl.message('Tproxy Port', name: 'tproxyPort', desc: '', args: []);
  }

  /// `{label} must be between 1024 and 49151`
  String portTip(Object label) {
    return Intl.message(
      '$label must be between 1024 and 49151',
      name: 'portTip',
      desc: '',
      args: [label],
    );
  }

  /// `Please enter a different port`
  String get portConflictTip {
    return Intl.message(
      'Please enter a different port',
      name: 'portConflictTip',
      desc: '',
      args: [],
    );
  }

  /// `Import`
  String get import {
    return Intl.message('Import', name: 'import', desc: '', args: []);
  }

  /// `Import from file`
  String get importFile {
    return Intl.message(
      'Import from file',
      name: 'importFile',
      desc: '',
      args: [],
    );
  }

  /// `Import from URL`
  String get importUrl {
    return Intl.message(
      'Import from URL',
      name: 'importUrl',
      desc: '',
      args: [],
    );
  }

  /// `Auto set system DNS`
  String get autoSetSystemDns {
    return Intl.message(
      'Auto set system DNS',
      name: 'autoSetSystemDns',
      desc: '',
      args: [],
    );
  }

  /// `{label} details`
  String details(Object label) {
    return Intl.message(
      '$label details',
      name: 'details',
      desc: '',
      args: [label],
    );
  }

  /// `Creation time`
  String get creationTime {
    return Intl.message(
      'Creation time',
      name: 'creationTime',
      desc: '',
      args: [],
    );
  }

  /// `Process`
  String get process {
    return Intl.message('Process', name: 'process', desc: '', args: []);
  }

  /// `Host`
  String get host {
    return Intl.message('Host', name: 'host', desc: '', args: []);
  }

  /// `Destination`
  String get destination {
    return Intl.message('Destination', name: 'destination', desc: '', args: []);
  }

  /// `Destination GeoIP`
  String get destinationGeoIP {
    return Intl.message(
      'Destination GeoIP',
      name: 'destinationGeoIP',
      desc: '',
      args: [],
    );
  }

  /// `Destination IPASN`
  String get destinationIPASN {
    return Intl.message(
      'Destination IPASN',
      name: 'destinationIPASN',
      desc: '',
      args: [],
    );
  }

  /// `Special proxy`
  String get specialProxy {
    return Intl.message(
      'Special proxy',
      name: 'specialProxy',
      desc: '',
      args: [],
    );
  }

  /// `special rules`
  String get specialRules {
    return Intl.message(
      'special rules',
      name: 'specialRules',
      desc: '',
      args: [],
    );
  }

  /// `Remote destination`
  String get remoteDestination {
    return Intl.message(
      'Remote destination',
      name: 'remoteDestination',
      desc: '',
      args: [],
    );
  }

  /// `Network type`
  String get networkType {
    return Intl.message(
      'Network type',
      name: 'networkType',
      desc: '',
      args: [],
    );
  }

  /// `Proxy chains`
  String get proxyChains {
    return Intl.message(
      'Proxy chains',
      name: 'proxyChains',
      desc: '',
      args: [],
    );
  }

  /// `Log`
  String get log {
    return Intl.message('Log', name: 'log', desc: '', args: []);
  }

  /// `Connection`
  String get connection {
    return Intl.message('Connection', name: 'connection', desc: '', args: []);
  }

  /// `Request`
  String get request {
    return Intl.message('Request', name: 'request', desc: '', args: []);
  }

  /// `Connected`
  String get connected {
    return Intl.message('Connected', name: 'connected', desc: '', args: []);
  }

  /// `Disconnected`
  String get disconnected {
    return Intl.message(
      'Disconnected',
      name: 'disconnected',
      desc: '',
      args: [],
    );
  }

  /// `Connecting...`
  String get connecting {
    return Intl.message(
      'Connecting...',
      name: 'connecting',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to restart the core?`
  String get restartCoreTip {
    return Intl.message(
      'Are you sure you want to restart the core?',
      name: 'restartCoreTip',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to force restart the core?`
  String get forceRestartCoreTip {
    return Intl.message(
      'Are you sure you want to force restart the core?',
      name: 'forceRestartCoreTip',
      desc: '',
      args: [],
    );
  }

  /// `DNS hijacking`
  String get dnsHijacking {
    return Intl.message(
      'DNS hijacking',
      name: 'dnsHijacking',
      desc: '',
      args: [],
    );
  }

  /// `Core status`
  String get coreStatus {
    return Intl.message('Core status', name: 'coreStatus', desc: '', args: []);
  }

  /// `Append System DNS`
  String get appendSystemDns {
    return Intl.message(
      'Append System DNS',
      name: 'appendSystemDns',
      desc: '',
      args: [],
    );
  }

  /// `Forcefully append system DNS to the configuration`
  String get appendSystemDnsTip {
    return Intl.message(
      'Forcefully append system DNS to the configuration',
      name: 'appendSystemDnsTip',
      desc: '',
      args: [],
    );
  }

  /// `Edit rule`
  String get editRule {
    return Intl.message('Edit rule', name: 'editRule', desc: '', args: []);
  }

  /// `Override mode`
  String get overrideMode {
    return Intl.message(
      'Override mode',
      name: 'overrideMode',
      desc: '',
      args: [],
    );
  }

  /// `Standard mode, override basic configuration, provide simple rule addition capability`
  String get standardModeDesc {
    return Intl.message(
      'Standard mode, override basic configuration, provide simple rule addition capability',
      name: 'standardModeDesc',
      desc: '',
      args: [],
    );
  }

  /// `Script mode, use external extension scripts, provide one-click override configuration capability`
  String get scriptModeDesc {
    return Intl.message(
      'Script mode, use external extension scripts, provide one-click override configuration capability',
      name: 'scriptModeDesc',
      desc: '',
      args: [],
    );
  }

  /// `Added rules`
  String get addedRules {
    return Intl.message('Added rules', name: 'addedRules', desc: '', args: []);
  }

  /// `Control global added rules`
  String get controlGlobalAddedRules {
    return Intl.message(
      'Control global added rules',
      name: 'controlGlobalAddedRules',
      desc: '',
      args: [],
    );
  }

  /// `Override script`
  String get overrideScript {
    return Intl.message(
      'Override script',
      name: 'overrideScript',
      desc: '',
      args: [],
    );
  }

  /// `Go to configure script`
  String get goToConfigureScript {
    return Intl.message(
      'Go to configure script',
      name: 'goToConfigureScript',
      desc: '',
      args: [],
    );
  }

  /// `Edit global rules`
  String get editGlobalRules {
    return Intl.message(
      'Edit global rules',
      name: 'editGlobalRules',
      desc: '',
      args: [],
    );
  }

  /// `External fetch`
  String get externalFetch {
    return Intl.message(
      'External fetch',
      name: 'externalFetch',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to force crash the core?`
  String get confirmForceCrashCore {
    return Intl.message(
      'Are you sure you want to force crash the core?',
      name: 'confirmForceCrashCore',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to clear all data?`
  String get confirmClearAllData {
    return Intl.message(
      'Are you sure you want to clear all data?',
      name: 'confirmClearAllData',
      desc: '',
      args: [],
    );
  }

  /// `Loading...`
  String get loading {
    return Intl.message('Loading...', name: 'loading', desc: '', args: []);
  }

  /// `Load test`
  String get loadTest {
    return Intl.message('Load test', name: 'loadTest', desc: '', args: []);
  }

  /// `{count, plural, =1{1 year ago} other{{count} years ago}}`
  String yearsAgo(num count) {
    return Intl.plural(
      count,
      one: '1 year ago',
      other: '$count years ago',
      name: 'yearsAgo',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, =1{1 month ago} other{{count} months ago}}`
  String monthsAgo(num count) {
    return Intl.plural(
      count,
      one: '1 month ago',
      other: '$count months ago',
      name: 'monthsAgo',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, =1{1 day ago} other{{count} days ago}}`
  String daysAgo(num count) {
    return Intl.plural(
      count,
      one: '1 day ago',
      other: '$count days ago',
      name: 'daysAgo',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, =1{1 hour ago} other{{count} hours ago}}`
  String hoursAgo(num count) {
    return Intl.plural(
      count,
      one: '1 hour ago',
      other: '$count hours ago',
      name: 'hoursAgo',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, =1{1 minute ago} other{{count} minutes ago}}`
  String minutesAgo(num count) {
    return Intl.plural(
      count,
      one: '1 minute ago',
      other: '$count minutes ago',
      name: 'minutesAgo',
      desc: '',
      args: [count],
    );
  }

  /// `Just now`
  String get justNow {
    return Intl.message('Just now', name: 'justNow', desc: '', args: []);
  }

  /// `Don't remind again`
  String get noLongerRemind {
    return Intl.message(
      'Don\'t remind again',
      name: 'noLongerRemind',
      desc: '',
      args: [],
    );
  }

  /// `Access Control Settings`
  String get accessControlSettings {
    return Intl.message(
      'Access Control Settings',
      name: 'accessControlSettings',
      desc: '',
      args: [],
    );
  }

  /// `Turn On`
  String get turnOn {
    return Intl.message('Turn On', name: 'turnOn', desc: '', args: []);
  }

  /// `Turn Off`
  String get turnOff {
    return Intl.message('Turn Off', name: 'turnOff', desc: '', args: []);
  }

  /// `VPN configuration change detected`
  String get vpnConfigChangeDetected {
    return Intl.message(
      'VPN configuration change detected',
      name: 'vpnConfigChangeDetected',
      desc: '',
      args: [],
    );
  }

  /// `Restart`
  String get restart {
    return Intl.message('Restart', name: 'restart', desc: '', args: []);
  }

  /// `Speed statistics`
  String get speedStatistics {
    return Intl.message(
      'Speed statistics',
      name: 'speedStatistics',
      desc: '',
      args: [],
    );
  }

  /// `The current page has changes. Are you sure you want to reset?`
  String get resetPageChangesTip {
    return Intl.message(
      'The current page has changes. Are you sure you want to reset?',
      name: 'resetPageChangesTip',
      desc: '',
      args: [],
    );
  }

  /// `Custom`
  String get overwriteTypeCustom {
    return Intl.message(
      'Custom',
      name: 'overwriteTypeCustom',
      desc: '',
      args: [],
    );
  }

  /// `Custom mode, fully customize proxy groups and rules`
  String get overwriteTypeCustomDesc {
    return Intl.message(
      'Custom mode, fully customize proxy groups and rules',
      name: 'overwriteTypeCustomDesc',
      desc: '',
      args: [],
    );
  }

  /// `Unknown network error`
  String get unknownNetworkError {
    return Intl.message(
      'Unknown network error',
      name: 'unknownNetworkError',
      desc: '',
      args: [],
    );
  }

  /// `Recovery exception`
  String get restoreException {
    return Intl.message(
      'Recovery exception',
      name: 'restoreException',
      desc: '',
      args: [],
    );
  }

  /// `Network exception, please check your connection and try again`
  String get networkException {
    return Intl.message(
      'Network exception, please check your connection and try again',
      name: 'networkException',
      desc: '',
      args: [],
    );
  }

  /// `Invalid backup file`
  String get invalidBackupFile {
    return Intl.message(
      'Invalid backup file',
      name: 'invalidBackupFile',
      desc: '',
      args: [],
    );
  }

  /// `Prune cache`
  String get pruneCache {
    return Intl.message('Prune cache', name: 'pruneCache', desc: '', args: []);
  }

  /// `Backup and Restore`
  String get backupAndRestore {
    return Intl.message(
      'Backup and Restore',
      name: 'backupAndRestore',
      desc: '',
      args: [],
    );
  }

  /// `Sync data via WebDAV or files`
  String get backupAndRestoreDesc {
    return Intl.message(
      'Sync data via WebDAV or files',
      name: 'backupAndRestoreDesc',
      desc: '',
      args: [],
    );
  }

  /// `Restore`
  String get restore {
    return Intl.message('Restore', name: 'restore', desc: '', args: []);
  }

  /// `Restore success`
  String get restoreSuccess {
    return Intl.message(
      'Restore success',
      name: 'restoreSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Restore data via WebDAV`
  String get restoreFromWebDAVDesc {
    return Intl.message(
      'Restore data via WebDAV',
      name: 'restoreFromWebDAVDesc',
      desc: '',
      args: [],
    );
  }

  /// `Restore data via file`
  String get restoreFromFileDesc {
    return Intl.message(
      'Restore data via file',
      name: 'restoreFromFileDesc',
      desc: '',
      args: [],
    );
  }

  /// `Restore configuration files only`
  String get restoreOnlyConfig {
    return Intl.message(
      'Restore configuration files only',
      name: 'restoreOnlyConfig',
      desc: '',
      args: [],
    );
  }

  /// `Restore all data`
  String get restoreAllData {
    return Intl.message(
      'Restore all data',
      name: 'restoreAllData',
      desc: '',
      args: [],
    );
  }

  /// `Add Profile`
  String get addProfile {
    return Intl.message('Add Profile', name: 'addProfile', desc: '', args: []);
  }

  /// `Delay Test`
  String get delayTest {
    return Intl.message('Delay Test', name: 'delayTest', desc: '', args: []);
  }

  /// `Proxy group is empty`
  String get proxyGroupEmpty {
    return Intl.message(
      'Proxy group is empty',
      name: 'proxyGroupEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Proxy group name cannot be empty`
  String get proxyGroupNameEmpty {
    return Intl.message(
      'Proxy group name cannot be empty',
      name: 'proxyGroupNameEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Proxy group name is duplicate`
  String get proxyGroupNameDuplicate {
    return Intl.message(
      'Proxy group name is duplicate',
      name: 'proxyGroupNameDuplicate',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to exit the current window?`
  String get confirmExitWindow {
    return Intl.message(
      'Are you sure you want to exit the current window?',
      name: 'confirmExitWindow',
      desc: '',
      args: [],
    );
  }

  /// `Data changes detected, do you want to save?`
  String get dataChangedSave {
    return Intl.message(
      'Data changes detected, do you want to save?',
      name: 'dataChangedSave',
      desc: '',
      args: [],
    );
  }

  /// `Select proxy providers`
  String get selectProxyProviders {
    return Intl.message(
      'Select proxy providers',
      name: 'selectProxyProviders',
      desc: '',
      args: [],
    );
  }

  /// `Proxy filter`
  String get proxyFilter {
    return Intl.message(
      'Proxy filter',
      name: 'proxyFilter',
      desc: '',
      args: [],
    );
  }

  /// `Optional`
  String get optional {
    return Intl.message('Optional', name: 'optional', desc: '', args: []);
  }

  /// `Max failed times`
  String get maxFailedTimes {
    return Intl.message(
      'Max failed times',
      name: 'maxFailedTimes',
      desc: '',
      args: [],
    );
  }

  /// `Test interval`
  String get testInterval {
    return Intl.message(
      'Test interval',
      name: 'testInterval',
      desc: '',
      args: [],
    );
  }

  /// `Exclude proxy filter`
  String get excludeProxyFilter {
    return Intl.message(
      'Exclude proxy filter',
      name: 'excludeProxyFilter',
      desc: '',
      args: [],
    );
  }

  /// `Exclude type`
  String get excludeType {
    return Intl.message(
      'Exclude type',
      name: 'excludeType',
      desc: '',
      args: [],
    );
  }

  /// `Expected status`
  String get expectedStatus {
    return Intl.message(
      'Expected status',
      name: 'expectedStatus',
      desc: '',
      args: [],
    );
  }

  /// `Select proxies`
  String get selectProxies {
    return Intl.message(
      'Select proxies',
      name: 'selectProxies',
      desc: '',
      args: [],
    );
  }

  /// `Input proxy group name`
  String get inputProxyGroupName {
    return Intl.message(
      'Input proxy group name',
      name: 'inputProxyGroupName',
      desc: '',
      args: [],
    );
  }

  /// `Helper service unavailable; TUN mode cannot be enabled. Reinstall Avalon to restore it.`
  String get helperCorruptTip {
    return Intl.message(
      'Helper service unavailable; TUN mode cannot be enabled. Reinstall Avalon to restore it.',
      name: 'helperCorruptTip',
      desc: '',
      args: [],
    );
  }

  /// `Hide from list`
  String get hideFromList {
    return Intl.message(
      'Hide from list',
      name: 'hideFromList',
      desc: '',
      args: [],
    );
  }

  /// `Test when used`
  String get testWhenUsed {
    return Intl.message(
      'Test when used',
      name: 'testWhenUsed',
      desc: '',
      args: [],
    );
  }

  /// `Disable UDP`
  String get disableUDP {
    return Intl.message('Disable UDP', name: 'disableUDP', desc: '', args: []);
  }

  /// `Are you sure you want to delete the current proxy group?`
  String get confirmDeleteProxyGroup {
    return Intl.message(
      'Are you sure you want to delete the current proxy group?',
      name: 'confirmDeleteProxyGroup',
      desc: '',
      args: [],
    );
  }

  /// `Rule is empty`
  String get ruleEmpty {
    return Intl.message('Rule is empty', name: 'ruleEmpty', desc: '', args: []);
  }

  /// `Input rule content`
  String get inputRuleContent {
    return Intl.message(
      'Input rule content',
      name: 'inputRuleContent',
      desc: '',
      args: [],
    );
  }

  /// `Rule set`
  String get ruleSet {
    return Intl.message('Rule set', name: 'ruleSet', desc: '', args: []);
  }

  /// `Please select rule set`
  String get selectRuleSet {
    return Intl.message(
      'Please select rule set',
      name: 'selectRuleSet',
      desc: '',
      args: [],
    );
  }

  /// `Split strategy`
  String get splitStrategy {
    return Intl.message(
      'Split strategy',
      name: 'splitStrategy',
      desc: '',
      args: [],
    );
  }

  /// `Please select split strategy`
  String get selectSplitStrategy {
    return Intl.message(
      'Please select split strategy',
      name: 'selectSplitStrategy',
      desc: '',
      args: [],
    );
  }

  /// `Please select sub rule`
  String get selectSubRule {
    return Intl.message(
      'Please select sub rule',
      name: 'selectSubRule',
      desc: '',
      args: [],
    );
  }

  /// `No resolve hostname`
  String get noResolveHostname {
    return Intl.message(
      'No resolve hostname',
      name: 'noResolveHostname',
      desc: '',
      args: [],
    );
  }

  /// `Match source IP`
  String get matchSourceIp {
    return Intl.message(
      'Match source IP',
      name: 'matchSourceIp',
      desc: '',
      args: [],
    );
  }

  /// `Basic info`
  String get basicInfo {
    return Intl.message('Basic info', name: 'basicInfo', desc: '', args: []);
  }

  /// `Additional parameters`
  String get additionalParameters {
    return Intl.message(
      'Additional parameters',
      name: 'additionalParameters',
      desc: '',
      args: [],
    );
  }

  /// `Proxy type`
  String get proxyType {
    return Intl.message('Proxy type', name: 'proxyType', desc: '', args: []);
  }

  /// `Basic strategy`
  String get basicStrategy {
    return Intl.message(
      'Basic strategy',
      name: 'basicStrategy',
      desc: '',
      args: [],
    );
  }

  /// `Edit proxy`
  String get editProxy {
    return Intl.message('Edit proxy', name: 'editProxy', desc: '', args: []);
  }

  /// `Include all proxy providers`
  String get includeAllProxyProviders {
    return Intl.message(
      'Include all proxy providers',
      name: 'includeAllProxyProviders',
      desc: '',
      args: [],
    );
  }

  /// `When enabled, it will override the imported proxy providers`
  String get includeAllProxyProvidersTip {
    return Intl.message(
      'When enabled, it will override the imported proxy providers',
      name: 'includeAllProxyProvidersTip',
      desc: '',
      args: [],
    );
  }

  /// `Add proxy providers`
  String get addProxyProviders {
    return Intl.message(
      'Add proxy providers',
      name: 'addProxyProviders',
      desc: '',
      args: [],
    );
  }

  /// `Include all proxies`
  String get includeAllProxies {
    return Intl.message(
      'Include all proxies',
      name: 'includeAllProxies',
      desc: '',
      args: [],
    );
  }

  /// `Import all proxies not containing proxy groups, additional proxy groups can be added below`
  String get includeAllProxiesTip {
    return Intl.message(
      'Import all proxies not containing proxy groups, additional proxy groups can be added below',
      name: 'includeAllProxiesTip',
      desc: '',
      args: [],
    );
  }

  /// `Proxies is empty`
  String get proxiesEmpty {
    return Intl.message(
      'Proxies is empty',
      name: 'proxiesEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Add proxies`
  String get addProxies {
    return Intl.message('Add proxies', name: 'addProxies', desc: '', args: []);
  }

  /// `Add proxy group`
  String get addProxyGroup {
    return Intl.message(
      'Add proxy group',
      name: 'addProxyGroup',
      desc: '',
      args: [],
    );
  }

  /// `Edit proxy group`
  String get editProxyGroup {
    return Intl.message(
      'Edit proxy group',
      name: 'editProxyGroup',
      desc: '',
      args: [],
    );
  }

  /// `Existing data will be overwritten after confirmation`
  String get confirmOverwriteTip {
    return Intl.message(
      'Existing data will be overwritten after confirmation',
      name: 'confirmOverwriteTip',
      desc: '',
      args: [],
    );
  }

  /// `Data detected in configuration`
  String get configDataDetected {
    return Intl.message(
      'Data detected in configuration',
      name: 'configDataDetected',
      desc: '',
      args: [],
    );
  }

  /// `Quick fill`
  String get quickFill {
    return Intl.message('Quick fill', name: 'quickFill', desc: '', args: []);
  }

  /// `Icon URL`
  String get iconUrl {
    return Intl.message('Icon URL', name: 'iconUrl', desc: '', args: []);
  }

  /// `Icon records`
  String get iconRecords {
    return Intl.message(
      'Icon records',
      name: 'iconRecords',
      desc: '',
      args: [],
    );
  }

  /// `No records`
  String get noRecords {
    return Intl.message('No records', name: 'noRecords', desc: '', args: []);
  }

  /// `Custom`
  String get custom {
    return Intl.message('Custom', name: 'custom', desc: '', args: []);
  }

  /// `Match full domain`
  String get ruleActionDomainDesc {
    return Intl.message(
      'Match full domain',
      name: 'ruleActionDomainDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match domain suffix`
  String get ruleActionDomainSuffixDesc {
    return Intl.message(
      'Match domain suffix',
      name: 'ruleActionDomainSuffixDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match domain keyword`
  String get ruleActionDomainKeywordDesc {
    return Intl.message(
      'Match domain keyword',
      name: 'ruleActionDomainKeywordDesc',
      desc: '',
      args: [],
    );
  }

  /// `Wildcard match, only supports * and ? wildcards`
  String get ruleActionDomainRegexDesc {
    return Intl.message(
      'Wildcard match, only supports * and ? wildcards',
      name: 'ruleActionDomainRegexDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match domains within Geosite`
  String get ruleActionGeositeDesc {
    return Intl.message(
      'Match domains within Geosite',
      name: 'ruleActionGeositeDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match IP address range`
  String get ruleActionIpCidrDesc {
    return Intl.message(
      'Match IP address range',
      name: 'ruleActionIpCidrDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match IP address range, IP-CIDR6 is just an alias`
  String get ruleActionIpCidr6Desc {
    return Intl.message(
      'Match IP address range, IP-CIDR6 is just an alias',
      name: 'ruleActionIpCidr6Desc',
      desc: '',
      args: [],
    );
  }

  /// `Match IP suffix range`
  String get ruleActionIpSuffixDesc {
    return Intl.message(
      'Match IP suffix range',
      name: 'ruleActionIpSuffixDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match IP's ASN`
  String get ruleActionIpAsnDesc {
    return Intl.message(
      'Match IP\'s ASN',
      name: 'ruleActionIpAsnDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match IP's country code`
  String get ruleActionGeoipDesc {
    return Intl.message(
      'Match IP\'s country code',
      name: 'ruleActionGeoipDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match source IP's country code`
  String get ruleActionSrcGeoipDesc {
    return Intl.message(
      'Match source IP\'s country code',
      name: 'ruleActionSrcGeoipDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match source IP's ASN`
  String get ruleActionSrcIpAsnDesc {
    return Intl.message(
      'Match source IP\'s ASN',
      name: 'ruleActionSrcIpAsnDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match source IP address range`
  String get ruleActionSrcIpCidrDesc {
    return Intl.message(
      'Match source IP address range',
      name: 'ruleActionSrcIpCidrDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match source IP suffix range`
  String get ruleActionSrcIpSuffixDesc {
    return Intl.message(
      'Match source IP suffix range',
      name: 'ruleActionSrcIpSuffixDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match request target port range`
  String get ruleActionDstPortDesc {
    return Intl.message(
      'Match request target port range',
      name: 'ruleActionDstPortDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match request source port range`
  String get ruleActionSrcPortDesc {
    return Intl.message(
      'Match request source port range',
      name: 'ruleActionSrcPortDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match inbound port`
  String get ruleActionInPortDesc {
    return Intl.message(
      'Match inbound port',
      name: 'ruleActionInPortDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match inbound type`
  String get ruleActionInTypeDesc {
    return Intl.message(
      'Match inbound type',
      name: 'ruleActionInTypeDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match inbound username, supports multiple usernames separated by /`
  String get ruleActionInUserDesc {
    return Intl.message(
      'Match inbound username, supports multiple usernames separated by /',
      name: 'ruleActionInUserDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match inbound name`
  String get ruleActionInNameDesc {
    return Intl.message(
      'Match inbound name',
      name: 'ruleActionInNameDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match using full process path`
  String get ruleActionProcessPathDesc {
    return Intl.message(
      'Match using full process path',
      name: 'ruleActionProcessPathDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match using process path regex`
  String get ruleActionProcessPathRegexDesc {
    return Intl.message(
      'Match using process path regex',
      name: 'ruleActionProcessPathRegexDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match using process name, matches package name on Android`
  String get ruleActionProcessNameDesc {
    return Intl.message(
      'Match using process name, matches package name on Android',
      name: 'ruleActionProcessNameDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match using process name regex, matches package name on Android`
  String get ruleActionProcessNameRegexDesc {
    return Intl.message(
      'Match using process name regex, matches package name on Android',
      name: 'ruleActionProcessNameRegexDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match Linux USER ID`
  String get ruleActionUidDesc {
    return Intl.message(
      'Match Linux USER ID',
      name: 'ruleActionUidDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match TCP or UDP`
  String get ruleActionNetworkDesc {
    return Intl.message(
      'Match TCP or UDP',
      name: 'ruleActionNetworkDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match DSCP mark (tproxy udp inbound only)`
  String get ruleActionDscpDesc {
    return Intl.message(
      'Match DSCP mark (tproxy udp inbound only)',
      name: 'ruleActionDscpDesc',
      desc: '',
      args: [],
    );
  }

  /// `Reference rule set, requires rule-providers configuration`
  String get ruleActionRuleSetDesc {
    return Intl.message(
      'Reference rule set, requires rule-providers configuration',
      name: 'ruleActionRuleSetDesc',
      desc: '',
      args: [],
    );
  }

  /// `Logical rule AND`
  String get ruleActionAndDesc {
    return Intl.message(
      'Logical rule AND',
      name: 'ruleActionAndDesc',
      desc: '',
      args: [],
    );
  }

  /// `Logical rule OR`
  String get ruleActionOrDesc {
    return Intl.message(
      'Logical rule OR',
      name: 'ruleActionOrDesc',
      desc: '',
      args: [],
    );
  }

  /// `Logical rule NOT`
  String get ruleActionNotDesc {
    return Intl.message(
      'Logical rule NOT',
      name: 'ruleActionNotDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match to sub-rule, pay attention to the use of parentheses`
  String get ruleActionSubRuleDesc {
    return Intl.message(
      'Match to sub-rule, pay attention to the use of parentheses',
      name: 'ruleActionSubRuleDesc',
      desc: '',
      args: [],
    );
  }

  /// `Match all requests, no conditions needed`
  String get ruleActionMatchDesc {
    return Intl.message(
      'Match all requests, no conditions needed',
      name: 'ruleActionMatchDesc',
      desc: '',
      args: [],
    );
  }

  /// `Sub rule is empty`
  String get subRuleEmpty {
    return Intl.message(
      'Sub rule is empty',
      name: 'subRuleEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Proxy providers cannot be empty`
  String get proxyProvidersNotEmpty {
    return Intl.message(
      'Proxy providers cannot be empty',
      name: 'proxyProvidersNotEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Content cannot be empty`
  String get contentNotEmpty {
    return Intl.message(
      'Content cannot be empty',
      name: 'contentNotEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Sub rule cannot be empty`
  String get subRuleNotEmpty {
    return Intl.message(
      'Sub rule cannot be empty',
      name: 'subRuleNotEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Split strategy cannot be empty`
  String get splitStrategyNotEmpty {
    return Intl.message(
      'Split strategy cannot be empty',
      name: 'splitStrategyNotEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Proxy providers is empty`
  String get proxyProvidersEmpty {
    return Intl.message(
      'Proxy providers is empty',
      name: 'proxyProvidersEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Timeout`
  String get timeout {
    return Intl.message('Timeout', name: 'timeout', desc: '', args: []);
  }

  /// `{subRule} is an invalid SUB_RULE`
  String invalidSubRule(Object subRule) {
    return Intl.message(
      '$subRule is an invalid SUB_RULE',
      name: 'invalidSubRule',
      desc: '',
      args: [subRule],
    );
  }

  /// `{target} is an invalid policy`
  String invalidPolicy(Object target) {
    return Intl.message(
      '$target is an invalid policy',
      name: 'invalidPolicy',
      desc: '',
      args: [target],
    );
  }

  /// `{providerName} is an invalid proxy provider`
  String invalidProxyProvider(Object providerName) {
    return Intl.message(
      '$providerName is an invalid proxy provider',
      name: 'invalidProxyProvider',
      desc: '',
      args: [providerName],
    );
  }

  /// `{proxyName} is an invalid proxy`
  String invalidProxy(Object proxyName) {
    return Intl.message(
      '$proxyName is an invalid proxy',
      name: 'invalidProxy',
      desc: '',
      args: [proxyName],
    );
  }

  /// `Detected current proxy group is abnormal`
  String get proxyGroupDetectedAbnormal {
    return Intl.message(
      'Detected current proxy group is abnormal',
      name: 'proxyGroupDetectedAbnormal',
      desc: '',
      args: [],
    );
  }

  /// `Detected selected proxy providers are abnormal`
  String get proxyProviderDetectedAbnormal {
    return Intl.message(
      'Detected selected proxy providers are abnormal',
      name: 'proxyProviderDetectedAbnormal',
      desc: '',
      args: [],
    );
  }

  /// `Detected selected proxies are abnormal`
  String get proxyDetectedAbnormal {
    return Intl.message(
      'Detected selected proxies are abnormal',
      name: 'proxyDetectedAbnormal',
      desc: '',
      args: [],
    );
  }

  /// `Create Profile`
  String get createProfile {
    return Intl.message(
      'Create Profile',
      name: 'createProfile',
      desc: '',
      args: [],
    );
  }

  /// `Location Permission Required`
  String get locationPermissionRequired {
    return Intl.message(
      'Location Permission Required',
      name: 'locationPermissionRequired',
      desc: '',
      args: [],
    );
  }

  /// `1. Open System Settings > Privacy & Security\n2. Choose Location Services\n3. Find and check {appName} in the right list\n\nAfter completing the setup, return to the app and use it normally. Thank you for your cooperation.`
  String locationPermissionGuide(Object appName) {
    return Intl.message(
      '1. Open System Settings > Privacy & Security\n2. Choose Location Services\n3. Find and check $appName in the right list\n\nAfter completing the setup, return to the app and use it normally. Thank you for your cooperation.',
      name: 'locationPermissionGuide',
      desc: '',
      args: [appName],
    );
  }

  /// `Prerequisites`
  String get prerequisites {
    return Intl.message(
      'Prerequisites',
      name: 'prerequisites',
      desc: '',
      args: [],
    );
  }

  /// `Ignore Battery Optimization`
  String get ignoreBatteryOptimization {
    return Intl.message(
      'Ignore Battery Optimization',
      name: 'ignoreBatteryOptimization',
      desc: '',
      args: [],
    );
  }

  /// `To ensure background operation, please disable battery optimization for this app. Tap to go to settings.`
  String get batteryOptimizationDesc {
    return Intl.message(
      'To ensure background operation, please disable battery optimization for this app. Tap to go to settings.',
      name: 'batteryOptimizationDesc',
      desc: '',
      args: [],
    );
  }

  /// `Affected by the system, this status may not always be accurate.`
  String get batteryOptimizationStatusTip {
    return Intl.message(
      'Affected by the system, this status may not always be accurate.',
      name: 'batteryOptimizationStatusTip',
      desc: '',
      args: [],
    );
  }

  /// `Location Permission`
  String get locationPermission {
    return Intl.message(
      'Location Permission',
      name: 'locationPermission',
      desc: '',
      args: [],
    );
  }

  /// `According to system requirements, obtaining the Wi-Fi name requires you to grant location permission.`
  String get locationPermissionDesc {
    return Intl.message(
      'According to system requirements, obtaining the Wi-Fi name requires you to grant location permission.',
      name: 'locationPermissionDesc',
      desc: '',
      args: [],
    );
  }

  /// `Exclude SSIDs`
  String get excludeSsids {
    return Intl.message(
      'Exclude SSIDs',
      name: 'excludeSsids',
      desc: '',
      args: [],
    );
  }

  /// `When connected to an excluded SSID Wi-Fi, the app running state will be automatically switched.`
  String get excludeSsidsDesc {
    return Intl.message(
      'When connected to an excluded SSID Wi-Fi, the app running state will be automatically switched.',
      name: 'excludeSsidsDesc',
      desc: '',
      args: [],
    );
  }

  /// `SSIDs is empty`
  String get ssidsEmpty {
    return Intl.message(
      'SSIDs is empty',
      name: 'ssidsEmpty',
      desc: '',
      args: [],
    );
  }

  /// `On Demand`
  String get onDemand {
    return Intl.message('On Demand', name: 'onDemand', desc: '', args: []);
  }

  /// `Configure the program running state for specific scenarios`
  String get onDemandDesc {
    return Intl.message(
      'Configure the program running state for specific scenarios',
      name: 'onDemandDesc',
      desc: '',
      args: [],
    );
  }

  /// `Location permission was denied, so the current Wi-Fi name cannot be obtained. Please open location permission manually in system settings.`
  String get locationPermissionDeniedMessage {
    return Intl.message(
      'Location permission was denied, so the current Wi-Fi name cannot be obtained. Please open location permission manually in system settings.',
      name: 'locationPermissionDeniedMessage',
      desc: '',
      args: [],
    );
  }

  /// `Add SSID`
  String get addSsid {
    return Intl.message('Add SSID', name: 'addSsid', desc: '', args: []);
  }

  /// `Edit SSID`
  String get editSsid {
    return Intl.message('Edit SSID', name: 'editSsid', desc: '', args: []);
  }

  /// `Authorized`
  String get authorized {
    return Intl.message('Authorized', name: 'authorized', desc: '', args: []);
  }

  /// `Tap to authorize`
  String get tapToAuthorize {
    return Intl.message(
      'Tap to authorize',
      name: 'tapToAuthorize',
      desc: '',
      args: [],
    );
  }

  /// `Suspended...`
  String get suspended {
    return Intl.message('Suspended...', name: 'suspended', desc: '', args: []);
  }

  /// `Geo Options`
  String get geoOptions {
    return Intl.message('Geo Options', name: 'geoOptions', desc: '', args: []);
  }

  /// `Auto Update`
  String get geoAutoUpdate {
    return Intl.message(
      'Auto Update',
      name: 'geoAutoUpdate',
      desc: '',
      args: [],
    );
  }

  /// `Auto Update Interval`
  String get geoAutoUpdateInterval {
    return Intl.message(
      'Auto Update Interval',
      name: 'geoAutoUpdateInterval',
      desc: '',
      args: [],
    );
  }

  /// `Auto update interval must be greater than 0`
  String get geoAutoUpdateIntervalTip {
    return Intl.message(
      'Auto update interval must be greater than 0',
      name: 'geoAutoUpdateIntervalTip',
      desc: '',
      args: [],
    );
  }

  /// `hours`
  String get hours {
    return Intl.message('hours', name: 'hours', desc: '', args: []);
  }

  /// `{count} hours`
  String hoursCount(Object count) {
    return Intl.message(
      '$count hours',
      name: 'hoursCount',
      desc: '',
      args: [count],
    );
  }

  /// `Geo Resources`
  String get geoResources {
    return Intl.message(
      'Geo Resources',
      name: 'geoResources',
      desc: '',
      args: [],
    );
  }

  /// `Updating {name}...`
  String geoUpdating(Object name) {
    return Intl.message(
      'Updating $name...',
      name: 'geoUpdating',
      desc: '',
      args: [name],
    );
  }

  /// `{name} is already up to date`
  String geoSkipped(Object name) {
    return Intl.message(
      '$name is already up to date',
      name: 'geoSkipped',
      desc: '',
      args: [name],
    );
  }

  /// `{name} updated`
  String geoUpdated(Object name) {
    return Intl.message(
      '$name updated',
      name: 'geoUpdated',
      desc: '',
      args: [name],
    );
  }

  /// `{count} seconds`
  String secondsCount(Object count) {
    return Intl.message(
      '$count seconds',
      name: 'secondsCount',
      desc: '',
      args: [count],
    );
  }

  /// `{count} entries`
  String entriesCount(Object count) {
    return Intl.message(
      '$count entries',
      name: 'entriesCount',
      desc: '',
      args: [count],
    );
  }

  /// `Nodes`
  String get nodes {
    return Intl.message('Nodes', name: 'nodes', desc: '', args: []);
  }

  /// `Chains`
  String get chains {
    return Intl.message('Chains', name: 'chains', desc: '', args: []);
  }

  /// `Node`
  String get node {
    return Intl.message('Node', name: 'node', desc: '', args: []);
  }

  /// `Chain`
  String get chain {
    return Intl.message('Chain', name: 'chain', desc: '', args: []);
  }

  /// `Node library`
  String get nodeLibrary {
    return Intl.message(
      'Node library',
      name: 'nodeLibrary',
      desc: '',
      args: [],
    );
  }

  /// `Import node`
  String get importNode {
    return Intl.message('Import node', name: 'importNode', desc: '', args: []);
  }

  /// `Create from chain`
  String get createFromChain {
    return Intl.message(
      'Create from chain',
      name: 'createFromChain',
      desc: '',
      args: [],
    );
  }

  /// `Build a runnable profile from a chain in the chain library`
  String get createFromChainDesc {
    return Intl.message(
      'Build a runnable profile from a chain in the chain library',
      name: 'createFromChainDesc',
      desc: '',
      args: [],
    );
  }

  /// `The chain becomes this profile’s default outbound.`
  String get createFromChainTip {
    return Intl.message(
      'The chain becomes this profile’s default outbound.',
      name: 'createFromChainTip',
      desc: '',
      args: [],
    );
  }

  /// `No chain yet. Create one on the Chains tab first.`
  String get createFromChainEmpty {
    return Intl.message(
      'No chain yet. Create one on the Chains tab first.',
      name: 'createFromChainEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Node data`
  String get nodeInput {
    return Intl.message('Node data', name: 'nodeInput', desc: '', args: []);
  }

  /// `Paste a node URI, multiple URIs, Base64, or Mihomo YAML/JSON`
  String get nodeInputHint {
    return Intl.message(
      'Paste a node URI, multiple URIs, Base64, or Mihomo YAML/JSON',
      name: 'nodeInputHint',
      desc: '',
      args: [],
    );
  }

  /// `Node imported`
  String get importSuccess {
    return Intl.message(
      'Node imported',
      name: 'importSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Raw Mihomo config`
  String get rawConfig {
    return Intl.message(
      'Raw Mihomo config',
      name: 'rawConfig',
      desc: '',
      args: [],
    );
  }

  /// `Manual`
  String get manual {
    return Intl.message('Manual', name: 'manual', desc: '', args: []);
  }

  /// `Export`
  String get export {
    return Intl.message('Export', name: 'export', desc: '', args: []);
  }

  /// `Create chain`
  String get createChain {
    return Intl.message(
      'Create chain',
      name: 'createChain',
      desc: '',
      args: [],
    );
  }

  /// `Chain hops`
  String get chainHop {
    return Intl.message('Chain hops', name: 'chainHop', desc: '', args: []);
  }

  /// `Branch limit`
  String get branchLimit {
    return Intl.message(
      'Branch limit',
      name: 'branchLimit',
      desc: '',
      args: [],
    );
  }

  /// `Stale`
  String get stale {
    return Intl.message('Stale', name: 'stale', desc: '', args: []);
  }

  /// `Unbind`
  String get unbind {
    return Intl.message('Unbind', name: 'unbind', desc: '', args: []);
  }

  /// `Set as default`
  String get setDefault {
    return Intl.message(
      'Set as default',
      name: 'setDefault',
      desc: '',
      args: [],
    );
  }

  /// `URI`
  String get exportUri {
    return Intl.message('URI', name: 'exportUri', desc: '', args: []);
  }

  /// `Base64`
  String get exportBase64 {
    return Intl.message('Base64', name: 'exportBase64', desc: '', args: []);
  }

  /// `YAML`
  String get exportYaml {
    return Intl.message('YAML', name: 'exportYaml', desc: '', args: []);
  }

  /// `JSON`
  String get exportJson {
    return Intl.message('JSON', name: 'exportJson', desc: '', args: []);
  }

  /// `Select chain target`
  String get selectChainTarget {
    return Intl.message(
      'Select chain target',
      name: 'selectChainTarget',
      desc: '',
      args: [],
    );
  }

  /// `Global group`
  String get globalGroup {
    return Intl.message(
      'Global group',
      name: 'globalGroup',
      desc: '',
      args: [],
    );
  }

  /// `Profile group`
  String get profileGroup {
    return Intl.message(
      'Profile group',
      name: 'profileGroup',
      desc: '',
      args: [],
    );
  }

  /// `Local endpoint`
  String get localEndpoint {
    return Intl.message(
      'Local endpoint',
      name: 'localEndpoint',
      desc: '',
      args: [],
    );
  }

  /// `Add hop`
  String get addChainHop {
    return Intl.message('Add hop', name: 'addChainHop', desc: '', args: []);
  }

  /// `Add a hop to build this chain`
  String get chainEmpty {
    return Intl.message(
      'Add a hop to build this chain',
      name: 'chainEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Client`
  String get chainClient {
    return Intl.message('Client', name: 'chainClient', desc: '', args: []);
  }

  /// `Target`
  String get chainTarget {
    return Intl.message('Target', name: 'chainTarget', desc: '', args: []);
  }

  /// `Endpoint type`
  String get endpointType {
    return Intl.message(
      'Endpoint type',
      name: 'endpointType',
      desc: '',
      args: [],
    );
  }

  /// `Enter a valid endpoint`
  String get invalidEndpoint {
    return Intl.message(
      'Enter a valid endpoint',
      name: 'invalidEndpoint',
      desc: '',
      args: [],
    );
  }

  /// `Username`
  String get username {
    return Intl.message('Username', name: 'username', desc: '', args: []);
  }

  /// `No node could be detected`
  String get nodeImportNoDraft {
    return Intl.message(
      'No node could be detected',
      name: 'nodeImportNoDraft',
      desc: '',
      args: [],
    );
  }

  /// `{count} nodes imported`
  String nodeImportCount(Object count) {
    return Intl.message(
      '$count nodes imported',
      name: 'nodeImportCount',
      desc: '',
      args: [count],
    );
  }

  /// `Protocol`
  String get protocol {
    return Intl.message('Protocol', name: 'protocol', desc: '', args: []);
  }

  /// `Active`
  String get active {
    return Intl.message('Active', name: 'active', desc: '', args: []);
  }

  /// `Local override`
  String get localOverride {
    return Intl.message(
      'Local override',
      name: 'localOverride',
      desc: '',
      args: [],
    );
  }

  /// `Create node`
  String get createNode {
    return Intl.message('Create node', name: 'createNode', desc: '', args: []);
  }

  /// `All`
  String get all {
    return Intl.message('All', name: 'all', desc: '', args: []);
  }

  /// `Local override cleared`
  String get localOverrideCleared {
    return Intl.message(
      'Local override cleared',
      name: 'localOverrideCleared',
      desc: '',
      args: [],
    );
  }

  /// `Clear local override`
  String get clearLocalOverride {
    return Intl.message(
      'Clear local override',
      name: 'clearLocalOverride',
      desc: '',
      args: [],
    );
  }

  /// `Node assets`
  String get nodeAssets {
    return Intl.message('Node assets', name: 'nodeAssets', desc: '', args: []);
  }

  /// `ZIP`
  String get exportZip {
    return Intl.message('ZIP', name: 'exportZip', desc: '', args: []);
  }

  /// `Diagnostics`
  String get exportDiagnostics {
    return Intl.message(
      'Diagnostics',
      name: 'exportDiagnostics',
      desc: '',
      args: [],
    );
  }

  /// `Create copy`
  String get createCopy {
    return Intl.message('Create copy', name: 'createCopy', desc: '', args: []);
  }

  /// `Attach asset`
  String get attachAsset {
    return Intl.message(
      'Attach asset',
      name: 'attachAsset',
      desc: '',
      args: [],
    );
  }

  /// `Asset field path`
  String get assetFieldPath {
    return Intl.message(
      'Asset field path',
      name: 'assetFieldPath',
      desc: '',
      args: [],
    );
  }

  /// `No node assets`
  String get noNodeAssets {
    return Intl.message(
      'No node assets',
      name: 'noNodeAssets',
      desc: '',
      args: [],
    );
  }

  /// `Server`
  String get server {
    return Intl.message('Server', name: 'server', desc: '', args: []);
  }

  /// `Chain entry groups`
  String get chainEntryGroups {
    return Intl.message(
      'Chain entry groups',
      name: 'chainEntryGroups',
      desc: '',
      args: [],
    );
  }

  /// `Add this chain to the selected groups, then select it on the proxies page.`
  String get chainEntryGroupsTip {
    return Intl.message(
      'Add this chain to the selected groups, then select it on the proxies page.',
      name: 'chainEntryGroupsTip',
      desc: '',
      args: [],
    );
  }

  /// `This profile has no group to add the chain to`
  String get chainEntryGroupsEmpty {
    return Intl.message(
      'This profile has no group to add the chain to',
      name: 'chainEntryGroupsEmpty',
      desc: '',
      args: [],
    );
  }

  /// `Paths: {count}`
  String chainPathCount(Object count) {
    return Intl.message(
      'Paths: $count',
      name: 'chainPathCount',
      desc: '',
      args: [count],
    );
  }

  /// `Chain diagnostics`
  String get chainDiagnostics {
    return Intl.message(
      'Chain diagnostics',
      name: 'chainDiagnostics',
      desc: '',
      args: [],
    );
  }

  /// `This chain reports warnings. Save it anyway?`
  String get chainWarningConfirm {
    return Intl.message(
      'This chain reports warnings. Save it anyway?',
      name: 'chainWarningConfirm',
      desc: '',
      args: [],
    );
  }

  /// `Tailscale`
  String get tailscale {
    return Intl.message('Tailscale', name: 'tailscale', desc: '', args: []);
  }

  /// `Configure Tailscale network`
  String get tailscaleDesc {
    return Intl.message(
      'Configure Tailscale network',
      name: 'tailscaleDesc',
      desc: '',
      args: [],
    );
  }

  /// `Connect to your Tailscale network`
  String get tsIntro {
    return Intl.message(
      'Connect to your Tailscale network',
      name: 'tsIntro',
      desc: '',
      args: [],
    );
  }

  /// `Loading`
  String get tsLoading {
    return Intl.message('Loading', name: 'tsLoading', desc: '', args: []);
  }

  /// `Not signed in`
  String get tsLoggedOut {
    return Intl.message(
      'Not signed in',
      name: 'tsLoggedOut',
      desc: '',
      args: [],
    );
  }

  /// `Awaiting authorization`
  String get tsAuthorizing {
    return Intl.message(
      'Awaiting authorization',
      name: 'tsAuthorizing',
      desc: '',
      args: [],
    );
  }

  /// `Awaiting approval`
  String get tsWaitingApproval {
    return Intl.message(
      'Awaiting approval',
      name: 'tsWaitingApproval',
      desc: '',
      args: [],
    );
  }

  /// `Connecting`
  String get tsConnecting {
    return Intl.message('Connecting', name: 'tsConnecting', desc: '', args: []);
  }

  /// `Signed in`
  String get tsLoggedIn {
    return Intl.message('Signed in', name: 'tsLoggedIn', desc: '', args: []);
  }

  /// `Paused`
  String get tsPaused {
    return Intl.message('Paused', name: 'tsPaused', desc: '', args: []);
  }

  /// `Stopping`
  String get tsStopping {
    return Intl.message('Stopping', name: 'tsStopping', desc: '', args: []);
  }

  /// `Sign in again`
  String get tsNeedsLogin {
    return Intl.message(
      'Sign in again',
      name: 'tsNeedsLogin',
      desc: '',
      args: [],
    );
  }

  /// `Disconnected`
  String get tsBackendDisconnected {
    return Intl.message(
      'Disconnected',
      name: 'tsBackendDisconnected',
      desc: '',
      args: [],
    );
  }

  /// `Service stopped`
  String get tsServiceStopped {
    return Intl.message(
      'Service stopped',
      name: 'tsServiceStopped',
      desc: '',
      args: [],
    );
  }

  /// `No profile selected`
  String get tsNoProfile {
    return Intl.message(
      'No profile selected',
      name: 'tsNoProfile',
      desc: '',
      args: [],
    );
  }

  /// `Rule mode only`
  String get tsRuleRequired {
    return Intl.message(
      'Rule mode only',
      name: 'tsRuleRequired',
      desc: '',
      args: [],
    );
  }

  /// `Applies to proxy traffic only`
  String get tsProxyOnly {
    return Intl.message(
      'Applies to proxy traffic only',
      name: 'tsProxyOnly',
      desc: '',
      args: [],
    );
  }

  /// `IPv6 inactive`
  String get tsIPv6Missing {
    return Intl.message(
      'IPv6 inactive',
      name: 'tsIPv6Missing',
      desc: '',
      args: [],
    );
  }

  /// `Subnet overlaps the local network`
  String get tsSubnetConflict {
    return Intl.message(
      'Subnet overlaps the local network',
      name: 'tsSubnetConflict',
      desc: '',
      args: [],
    );
  }

  /// `Server connection interrupted`
  String get tsControlWarning {
    return Intl.message(
      'Server connection interrupted',
      name: 'tsControlWarning',
      desc: '',
      args: [],
    );
  }

  /// `Active`
  String get tsActive {
    return Intl.message('Active', name: 'tsActive', desc: '', args: []);
  }

  /// `Inactive`
  String get tsInactive {
    return Intl.message('Inactive', name: 'tsInactive', desc: '', args: []);
  }

  /// `Partially active`
  String get tsPartial {
    return Intl.message(
      'Partially active',
      name: 'tsPartial',
      desc: '',
      args: [],
    );
  }

  /// `Pending`
  String get tsPending {
    return Intl.message('Pending', name: 'tsPending', desc: '', args: []);
  }

  /// `Off`
  String get tsOff {
    return Intl.message('Off', name: 'tsOff', desc: '', args: []);
  }

  /// `Related connections stopped`
  String get tsBlocked {
    return Intl.message(
      'Related connections stopped',
      name: 'tsBlocked',
      desc: '',
      args: [],
    );
  }

  /// `Using original routing`
  String get tsFallback {
    return Intl.message(
      'Using original routing',
      name: 'tsFallback',
      desc: '',
      args: [],
    );
  }

  /// `Testing`
  String get tsTesting {
    return Intl.message('Testing', name: 'tsTesting', desc: '', args: []);
  }

  /// `Test passed`
  String get tsProbeSuccess {
    return Intl.message(
      'Test passed',
      name: 'tsProbeSuccess',
      desc: '',
      args: [],
    );
  }

  /// `Test failed`
  String get tsProbeFailed {
    return Intl.message(
      'Test failed',
      name: 'tsProbeFailed',
      desc: '',
      args: [],
    );
  }

  /// `Cancelled`
  String get tsCancelled {
    return Intl.message('Cancelled', name: 'tsCancelled', desc: '', args: []);
  }

  /// `Result expired`
  String get tsProbeExpired {
    return Intl.message(
      'Result expired',
      name: 'tsProbeExpired',
      desc: '',
      args: [],
    );
  }

  /// `Direct`
  String get tsDirectPath {
    return Intl.message('Direct', name: 'tsDirectPath', desc: '', args: []);
  }

  /// `Relay`
  String get tsDerpPath {
    return Intl.message('Relay', name: 'tsDerpPath', desc: '', args: []);
  }

  /// `Peer relay`
  String get tsPeerRelay {
    return Intl.message('Peer relay', name: 'tsPeerRelay', desc: '', args: []);
  }

  /// `Exit node not approved`
  String get tsUnapprovedExit {
    return Intl.message(
      'Exit node not approved',
      name: 'tsUnapprovedExit',
      desc: '',
      args: [],
    );
  }

  /// `Tailscale is not enabled in this version`
  String get tsUnsupported {
    return Intl.message(
      'Tailscale is not enabled in this version',
      name: 'tsUnsupported',
      desc: '',
      args: [],
    );
  }

  /// `Profile update failed; previous settings kept`
  String get tsApplyFailed {
    return Intl.message(
      'Profile update failed; previous settings kept',
      name: 'tsApplyFailed',
      desc: '',
      args: [],
    );
  }

  /// `Auth key rejected as invalid`
  String get tsAuthInvalid {
    return Intl.message(
      'Auth key rejected as invalid',
      name: 'tsAuthInvalid',
      desc: '',
      args: [],
    );
  }

  /// `Auth key expired`
  String get tsAuthExpired {
    return Intl.message(
      'Auth key expired',
      name: 'tsAuthExpired',
      desc: '',
      args: [],
    );
  }

  /// `Auth key already used`
  String get tsAuthUsed {
    return Intl.message(
      'Auth key already used',
      name: 'tsAuthUsed',
      desc: '',
      args: [],
    );
  }

  /// `Sign-in rejected by server`
  String get tsAuthRejected {
    return Intl.message(
      'Sign-in rejected by server',
      name: 'tsAuthRejected',
      desc: '',
      args: [],
    );
  }

  /// `Server connection failed`
  String get tsServerUnreachable {
    return Intl.message(
      'Server connection failed',
      name: 'tsServerUnreachable',
      desc: '',
      args: [],
    );
  }

  /// `Sign-out incomplete; try again`
  String get tsLogoutFailed {
    return Intl.message(
      'Sign-out incomplete; try again',
      name: 'tsLogoutFailed',
      desc: '',
      args: [],
    );
  }

  /// `Use a valid address; remote servers require HTTPS`
  String get tsInvalidServer {
    return Intl.message(
      'Use a valid address; remote servers require HTTPS',
      name: 'tsInvalidServer',
      desc: '',
      args: [],
    );
  }

  /// `Unknown`
  String get tsUnknown {
    return Intl.message('Unknown', name: 'tsUnknown', desc: '', args: []);
  }

  /// `Routing`
  String get tsSplit {
    return Intl.message('Routing', name: 'tsSplit', desc: '', args: []);
  }

  /// `Exit node`
  String get tsExit {
    return Intl.message('Exit node', name: 'tsExit', desc: '', args: []);
  }

  /// `This device`
  String get tsThisDevice {
    return Intl.message(
      'This device',
      name: 'tsThisDevice',
      desc: '',
      args: [],
    );
  }

  /// `Key expiry`
  String get tsKeyExpiry {
    return Intl.message('Key expiry', name: 'tsKeyExpiry', desc: '', args: []);
  }

  /// `Not provided`
  String get tsNotProvided {
    return Intl.message(
      'Not provided',
      name: 'tsNotProvided',
      desc: '',
      args: [],
    );
  }

  /// `Showing cached information`
  String get tsCachedWarning {
    return Intl.message(
      'Showing cached information',
      name: 'tsCachedWarning',
      desc: '',
      args: [],
    );
  }

  /// `Resume`
  String get tsResume {
    return Intl.message('Resume', name: 'tsResume', desc: '', args: []);
  }

  /// `Pause`
  String get tsPause {
    return Intl.message('Pause', name: 'tsPause', desc: '', args: []);
  }

  /// `Sign out`
  String get tsLogout {
    return Intl.message('Sign out', name: 'tsLogout', desc: '', args: []);
  }

  /// `Sign out and clear local sign-in data?`
  String get tsLogoutConfirm {
    return Intl.message(
      'Sign out and clear local sign-in data?',
      name: 'tsLogoutConfirm',
      desc: '',
      args: [],
    );
  }

  /// `Retry`
  String get tsRetry {
    return Intl.message('Retry', name: 'tsRetry', desc: '', args: []);
  }

  /// `Custom server`
  String get tsCustomServer {
    return Intl.message(
      'Custom server',
      name: 'tsCustomServer',
      desc: '',
      args: [],
    );
  }

  /// `Server URL`
  String get tsControlServer {
    return Intl.message(
      'Server URL',
      name: 'tsControlServer',
      desc: '',
      args: [],
    );
  }

  /// `Auth key`
  String get tsAuthKey {
    return Intl.message('Auth key', name: 'tsAuthKey', desc: '', args: []);
  }

  /// `Browser sign-in`
  String get tsBrowserLogin {
    return Intl.message(
      'Browser sign-in',
      name: 'tsBrowserLogin',
      desc: '',
      args: [],
    );
  }

  /// `Key sign-in`
  String get tsKeyLogin {
    return Intl.message('Key sign-in', name: 'tsKeyLogin', desc: '', args: []);
  }

  /// `Open browser`
  String get tsOpenBrowser {
    return Intl.message(
      'Open browser',
      name: 'tsOpenBrowser',
      desc: '',
      args: [],
    );
  }

  /// `Authorization QR code`
  String get tsQRCode {
    return Intl.message(
      'Authorization QR code',
      name: 'tsQRCode',
      desc: '',
      args: [],
    );
  }

  /// `Cancel authorization`
  String get tsCancelLogin {
    return Intl.message(
      'Cancel authorization',
      name: 'tsCancelLogin',
      desc: '',
      args: [],
    );
  }

  /// `Not tested`
  String get tsNotTested {
    return Intl.message('Not tested', name: 'tsNotTested', desc: '', args: []);
  }

  /// `OS`
  String get tsOS {
    return Intl.message('OS', name: 'tsOS', desc: '', args: []);
  }

  /// `Online`
  String get tsOnline {
    return Intl.message('Online', name: 'tsOnline', desc: '', args: []);
  }

  /// `Offline`
  String get tsOffline {
    return Intl.message('Offline', name: 'tsOffline', desc: '', args: []);
  }

  /// `Last online`
  String get tsLastSeen {
    return Intl.message('Last online', name: 'tsLastSeen', desc: '', args: []);
  }

  /// `Check device connectivity`
  String get tsProbeExplanation {
    return Intl.message(
      'Check device connectivity',
      name: 'tsProbeExplanation',
      desc: '',
      args: [],
    );
  }

  /// `Subnet routes`
  String get tsApprovedRoutes {
    return Intl.message(
      'Subnet routes',
      name: 'tsApprovedRoutes',
      desc: '',
      args: [],
    );
  }

  /// `Test connection`
  String get tsTest {
    return Intl.message('Test connection', name: 'tsTest', desc: '', args: []);
  }

  /// `Use as exit`
  String get tsUseExit {
    return Intl.message('Use as exit', name: 'tsUseExit', desc: '', args: []);
  }

  /// `Search devices`
  String get tsSearch {
    return Intl.message('Search devices', name: 'tsSearch', desc: '', args: []);
  }

  /// `All`
  String get tsAll {
    return Intl.message('All', name: 'tsAll', desc: '', args: []);
  }

  /// `Test listed devices`
  String get tsTestAll {
    return Intl.message(
      'Test listed devices',
      name: 'tsTestAll',
      desc: '',
      args: [],
    );
  }

  /// `Cancel tests`
  String get tsStopTests {
    return Intl.message(
      'Cancel tests',
      name: 'tsStopTests',
      desc: '',
      args: [],
    );
  }

  /// `Refresh devices`
  String get tsRefreshDevices {
    return Intl.message(
      'Refresh devices',
      name: 'tsRefreshDevices',
      desc: '',
      args: [],
    );
  }

  /// `No other devices visible`
  String get tsNoDevices {
    return Intl.message(
      'No other devices visible',
      name: 'tsNoDevices',
      desc: '',
      args: [],
    );
  }

  /// `No matching devices`
  String get tsNoSearchResults {
    return Intl.message(
      'No matching devices',
      name: 'tsNoSearchResults',
      desc: '',
      args: [],
    );
  }

  /// `View device details`
  String get tsSelectDevice {
    return Intl.message(
      'View device details',
      name: 'tsSelectDevice',
      desc: '',
      args: [],
    );
  }

  /// `Automatic routing`
  String get tsAutoRoute {
    return Intl.message(
      'Automatic routing',
      name: 'tsAutoRoute',
      desc: '',
      args: [],
    );
  }

  /// `Access Tailscale devices in Rule mode`
  String get tsAutoRouteDesc {
    return Intl.message(
      'Access Tailscale devices in Rule mode',
      name: 'tsAutoRouteDesc',
      desc: '',
      args: [],
    );
  }

  /// `Accept subnet routes`
  String get tsAcceptRoutes {
    return Intl.message(
      'Accept subnet routes',
      name: 'tsAcceptRoutes',
      desc: '',
      args: [],
    );
  }

  /// `Access shared subnets through TUN`
  String get tsAcceptRoutesDesc {
    return Intl.message(
      'Access shared subnets through TUN',
      name: 'tsAcceptRoutesDesc',
      desc: '',
      args: [],
    );
  }

  /// `Signing in does not expose local services`
  String get tsEmbeddedNote {
    return Intl.message(
      'Signing in does not expose local services',
      name: 'tsEmbeddedNote',
      desc: '',
      args: [],
    );
  }

  /// `Active`
  String get tsAccepted {
    return Intl.message('Active', name: 'tsAccepted', desc: '', args: []);
  }

  /// `Available`
  String get tsAvailable {
    return Intl.message('Available', name: 'tsAvailable', desc: '', args: []);
  }

  /// `Keep local`
  String get tsKeepLocal {
    return Intl.message('Keep local', name: 'tsKeepLocal', desc: '', args: []);
  }

  /// `Use remote`
  String get tsUseRemote {
    return Intl.message('Use remote', name: 'tsUseRemote', desc: '', args: []);
  }

  /// `Use the remote route? Local access to this subnet will be affected`
  String get tsRemoteWarning {
    return Intl.message(
      'Use the remote route? Local access to this subnet will be affected',
      name: 'tsRemoteWarning',
      desc: '',
      args: [],
    );
  }

  /// `Access the Internet through an exit node`
  String get tsExitDesc {
    return Intl.message(
      'Access the Internet through an exit node',
      name: 'tsExitDesc',
      desc: '',
      args: [],
    );
  }

  /// `Exit node`
  String get tsExitDevice {
    return Intl.message('Exit node', name: 'tsExitDevice', desc: '', args: []);
  }

  /// `Exit node unavailable`
  String get tsMissingExit {
    return Intl.message(
      'Exit node unavailable',
      name: 'tsMissingExit',
      desc: '',
      args: [],
    );
  }

  /// `Selected groups`
  String get tsSelectedGroups {
    return Intl.message(
      'Selected groups',
      name: 'tsSelectedGroups',
      desc: '',
      args: [],
    );
  }

  /// `All Internet traffic`
  String get tsAllPublic {
    return Intl.message(
      'All Internet traffic',
      name: 'tsAllPublic',
      desc: '',
      args: [],
    );
  }

  /// `Closes related connections when switching`
  String get tsOriginalRouting {
    return Intl.message(
      'Closes related connections when switching',
      name: 'tsOriginalRouting',
      desc: '',
      args: [],
    );
  }

  /// `Applies to groups matched directly by rules`
  String get tsGroupSemantics {
    return Intl.message(
      'Applies to groups matched directly by rules',
      name: 'tsGroupSemantics',
      desc: '',
      args: [],
    );
  }

  /// `No groups available`
  String get tsNoGroups {
    return Intl.message(
      'No groups available',
      name: 'tsNoGroups',
      desc: '',
      args: [],
    );
  }

  /// `Group not found`
  String get tsMissingGroup {
    return Intl.message(
      'Group not found',
      name: 'tsMissingGroup',
      desc: '',
      args: [],
    );
  }

  /// `When the exit is unavailable`
  String get tsWhenUnavailable {
    return Intl.message(
      'When the exit is unavailable',
      name: 'tsWhenUnavailable',
      desc: '',
      args: [],
    );
  }

  /// `Stop related connections`
  String get tsStopConnections {
    return Intl.message(
      'Stop related connections',
      name: 'tsStopConnections',
      desc: '',
      args: [],
    );
  }

  /// `Use original routing`
  String get tsReturnOriginal {
    return Intl.message(
      'Use original routing',
      name: 'tsReturnOriginal',
      desc: '',
      args: [],
    );
  }

  /// `Devices`
  String get tsDevices {
    return Intl.message('Devices', name: 'tsDevices', desc: '', args: []);
  }

  /// `Routing`
  String get tsRouting {
    return Intl.message('Routing', name: 'tsRouting', desc: '', args: []);
  }

  /// `No groups selected`
  String get tsNoBinding {
    return Intl.message(
      'No groups selected',
      name: 'tsNoBinding',
      desc: '',
      args: [],
    );
  }

  /// `Some groups are missing`
  String get tsMissingBinding {
    return Intl.message(
      'Some groups are missing',
      name: 'tsMissingBinding',
      desc: '',
      args: [],
    );
  }

  /// `Waiting for routing to apply`
  String get tsCapturePending {
    return Intl.message(
      'Waiting for routing to apply',
      name: 'tsCapturePending',
      desc: '',
      args: [],
    );
  }

  /// `Routing failed; check network settings`
  String get tsCaptureFailed {
    return Intl.message(
      'Routing failed; check network settings',
      name: 'tsCaptureFailed',
      desc: '',
      args: [],
    );
  }

  /// `Invalid sign-in link; try again`
  String get tsInvalidAuthURL {
    return Intl.message(
      'Invalid sign-in link; try again',
      name: 'tsInvalidAuthURL',
      desc: '',
      args: [],
    );
  }

  /// `Operation failed; try again`
  String get tsBackendError {
    return Intl.message(
      'Operation failed; try again',
      name: 'tsBackendError',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'ja'),
      Locale.fromSubtags(languageCode: 'ru'),
      Locale.fromSubtags(languageCode: 'zh', countryCode: 'CN'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<AppLocalizations> load(Locale locale) => AppLocalizations.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
