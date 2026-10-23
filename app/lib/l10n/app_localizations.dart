import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @tabDashboard.
  ///
  /// In zh, this message translates to:
  /// **'仪表盘'**
  String get tabDashboard;

  /// No description provided for @tabProxies.
  ///
  /// In zh, this message translates to:
  /// **'代理'**
  String get tabProxies;

  /// No description provided for @tabConfigurations.
  ///
  /// In zh, this message translates to:
  /// **'配置'**
  String get tabConfigurations;

  /// No description provided for @tabTools.
  ///
  /// In zh, this message translates to:
  /// **'工具'**
  String get tabTools;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @add.
  ///
  /// In zh, this message translates to:
  /// **'添加'**
  String get add;

  /// No description provided for @edit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @done.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get done;

  /// No description provided for @retry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get retry;

  /// No description provided for @justNow.
  ///
  /// In zh, this message translates to:
  /// **'刚刚'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In zh, this message translates to:
  /// **'{n} 分钟前'**
  String minutesAgo(int n);

  /// No description provided for @hoursAgo.
  ///
  /// In zh, this message translates to:
  /// **'{n} 小时前'**
  String hoursAgo(int n);

  /// No description provided for @daysAgo.
  ///
  /// In zh, this message translates to:
  /// **'{n} 天前'**
  String daysAgo(int n);

  /// No description provided for @configurationsTitle.
  ///
  /// In zh, this message translates to:
  /// **'配置'**
  String get configurationsTitle;

  /// No description provided for @refreshAll.
  ///
  /// In zh, this message translates to:
  /// **'全部更新'**
  String get refreshAll;

  /// No description provided for @selfConfigurationName.
  ///
  /// In zh, this message translates to:
  /// **'自建节点'**
  String get selfConfigurationName;

  /// No description provided for @sourceSubscription.
  ///
  /// In zh, this message translates to:
  /// **'订阅'**
  String get sourceSubscription;

  /// No description provided for @sourceFile.
  ///
  /// In zh, this message translates to:
  /// **'本地文件'**
  String get sourceFile;

  /// No description provided for @sourceLocal.
  ///
  /// In zh, this message translates to:
  /// **'本地 · {chains} 条代理链'**
  String sourceLocal(int chains);

  /// No description provided for @nodeCount.
  ///
  /// In zh, this message translates to:
  /// **'{n} 个节点'**
  String nodeCount(int n);

  /// No description provided for @updatedAt.
  ///
  /// In zh, this message translates to:
  /// **'{when}更新'**
  String updatedAt(String when);

  /// No description provided for @notDownloaded.
  ///
  /// In zh, this message translates to:
  /// **'尚未下载'**
  String get notDownloaded;

  /// No description provided for @expiresOn.
  ///
  /// In zh, this message translates to:
  /// **'{date} 到期'**
  String expiresOn(String date);

  /// No description provided for @lastSuccess.
  ///
  /// In zh, this message translates to:
  /// **'上次成功：{when}'**
  String lastSuccess(String when);

  /// No description provided for @configurationsEmpty.
  ///
  /// In zh, this message translates to:
  /// **'添加订阅链接、配置文件或独立节点即可开始。'**
  String get configurationsEmpty;

  /// No description provided for @deleteConfigurationTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除「{name}」？'**
  String deleteConfigurationTitle(String name);

  /// No description provided for @deleteConfigurationBody.
  ///
  /// In zh, this message translates to:
  /// **'该配置的选择记录和加入其中的节点会一并移除，引用其节点的代理链将显示「不可用」。'**
  String get deleteConfigurationBody;

  /// No description provided for @addTitle.
  ///
  /// In zh, this message translates to:
  /// **'添加'**
  String get addTitle;

  /// No description provided for @addSegmentSubscription.
  ///
  /// In zh, this message translates to:
  /// **'订阅'**
  String get addSegmentSubscription;

  /// No description provided for @addSegmentNode.
  ///
  /// In zh, this message translates to:
  /// **'独立节点'**
  String get addSegmentNode;

  /// No description provided for @addSegmentChain.
  ///
  /// In zh, this message translates to:
  /// **'代理链'**
  String get addSegmentChain;

  /// No description provided for @subscriptionUrl.
  ///
  /// In zh, this message translates to:
  /// **'订阅链接'**
  String get subscriptionUrl;

  /// No description provided for @subscriptionUrlHint.
  ///
  /// In zh, this message translates to:
  /// **'https://… 支持 sing-box / Clash 订阅'**
  String get subscriptionUrlHint;

  /// No description provided for @name.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get name;

  /// No description provided for @nameAuto.
  ///
  /// In zh, this message translates to:
  /// **'自动读取'**
  String get nameAuto;

  /// No description provided for @scanQr.
  ///
  /// In zh, this message translates to:
  /// **'扫描二维码'**
  String get scanQr;

  /// No description provided for @importFile.
  ///
  /// In zh, this message translates to:
  /// **'从文件导入'**
  String get importFile;

  /// No description provided for @dropFileHint.
  ///
  /// In zh, this message translates to:
  /// **'或拖入配置文件 .json（sing-box）/ .yaml（Clash）'**
  String get dropFileHint;

  /// No description provided for @autoUpdate.
  ///
  /// In zh, this message translates to:
  /// **'自动更新'**
  String get autoUpdate;

  /// No description provided for @localOnlyNote.
  ///
  /// In zh, this message translates to:
  /// **'保存在本机。'**
  String get localOnlyNote;

  /// No description provided for @defaultSubscriptionName.
  ///
  /// In zh, this message translates to:
  /// **'新订阅'**
  String get defaultSubscriptionName;

  /// No description provided for @comingSoon.
  ///
  /// In zh, this message translates to:
  /// **'该功能将在后续版本提供。'**
  String get comingSoon;

  /// No description provided for @coreNotConnected.
  ///
  /// In zh, this message translates to:
  /// **'内核未接入'**
  String get coreNotConnected;

  /// No description provided for @coreNotConnectedNote.
  ///
  /// In zh, this message translates to:
  /// **'连接、测速与实时数据将在接入内核后可用。'**
  String get coreNotConnectedNote;

  /// No description provided for @currentConfiguration.
  ///
  /// In zh, this message translates to:
  /// **'当前配置'**
  String get currentConfiguration;

  /// No description provided for @noConfigurationSelected.
  ///
  /// In zh, this message translates to:
  /// **'未选择配置'**
  String get noConfigurationSelected;

  /// No description provided for @errorInvalidUrl.
  ///
  /// In zh, this message translates to:
  /// **'链接无效，请填写 http:// 或 https:// 开头的订阅链接。'**
  String get errorInvalidUrl;

  /// No description provided for @errorBlockedAddress.
  ///
  /// In zh, this message translates to:
  /// **'内容指向了本机或局域网地址，已阻止。'**
  String get errorBlockedAddress;

  /// No description provided for @errorTimeout.
  ///
  /// In zh, this message translates to:
  /// **'连接超时，请检查网络后重试。'**
  String get errorTimeout;

  /// No description provided for @errorTooLarge.
  ///
  /// In zh, this message translates to:
  /// **'内容超过 16 MiB 上限。'**
  String get errorTooLarge;

  /// No description provided for @errorTooManyRedirects.
  ///
  /// In zh, this message translates to:
  /// **'重定向次数过多。'**
  String get errorTooManyRedirects;

  /// No description provided for @errorHttpStatus.
  ///
  /// In zh, this message translates to:
  /// **'服务器返回错误（HTTP {status}）。'**
  String errorHttpStatus(int status);

  /// No description provided for @errorTls.
  ///
  /// In zh, this message translates to:
  /// **'安全连接失败，证书无效或握手失败。'**
  String get errorTls;

  /// No description provided for @errorNetwork.
  ///
  /// In zh, this message translates to:
  /// **'网络错误，无法连接服务器。'**
  String get errorNetwork;

  /// No description provided for @errorUnknownFormat.
  ///
  /// In zh, this message translates to:
  /// **'无法识别内容格式：支持 sing-box JSON、Clash YAML 与分享链接列表。'**
  String get errorUnknownFormat;

  /// No description provided for @errorMalformed.
  ///
  /// In zh, this message translates to:
  /// **'内容格式错误。'**
  String get errorMalformed;

  /// No description provided for @errorUnknownParameter.
  ///
  /// In zh, this message translates to:
  /// **'不支持的参数：{field}。'**
  String errorUnknownParameter(String field);

  /// No description provided for @errorUnsupportedValue.
  ///
  /// In zh, this message translates to:
  /// **'不支持的取值：{field}。'**
  String errorUnsupportedValue(String field);

  /// No description provided for @errorMissingField.
  ///
  /// In zh, this message translates to:
  /// **'缺少必填项：{field}。'**
  String errorMissingField(String field);

  /// No description provided for @errorInvalidField.
  ///
  /// In zh, this message translates to:
  /// **'字段无效：{field}。'**
  String errorInvalidField(String field);

  /// No description provided for @errorTooLargeContent.
  ///
  /// In zh, this message translates to:
  /// **'内容超出上限（{field}）。'**
  String errorTooLargeContent(String field);

  /// No description provided for @errorUnsupportedScheme.
  ///
  /// In zh, this message translates to:
  /// **'无法识别的分享链接协议。'**
  String get errorUnsupportedScheme;

  /// No description provided for @errorVaultLocked.
  ///
  /// In zh, this message translates to:
  /// **'本机安全存储已重置，请重新输入凭据或从备份恢复。'**
  String get errorVaultLocked;

  /// No description provided for @errorUnknown.
  ///
  /// In zh, this message translates to:
  /// **'操作失败，请重试。'**
  String get errorUnknown;

  /// No description provided for @savedWithWarnings.
  ///
  /// In zh, this message translates to:
  /// **'已保存，部分内容未导入：'**
  String get savedWithWarnings;

  /// No description provided for @warnUnsupportedNodeType.
  ///
  /// In zh, this message translates to:
  /// **'跳过 {count} 个 {subject} 节点：Avalon 不支持该协议'**
  String warnUnsupportedNodeType(int count, String subject);

  /// No description provided for @warnUnsupportedNodeOption.
  ///
  /// In zh, this message translates to:
  /// **'跳过 {count} 个节点：不支持选项 {subject}'**
  String warnUnsupportedNodeOption(int count, String subject);

  /// No description provided for @warnIgnoredNodeOption.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个节点的选项 {subject} 未生效'**
  String warnIgnoredNodeOption(int count, String subject);

  /// No description provided for @warnUnreadableEntry.
  ///
  /// In zh, this message translates to:
  /// **'跳过 {count} 项无法读取的内容（{subject}）'**
  String warnUnreadableEntry(int count, String subject);

  /// No description provided for @warnUnsupportedGroupType.
  ///
  /// In zh, this message translates to:
  /// **'跳过 {subject} 类型的组'**
  String warnUnsupportedGroupType(String subject);

  /// No description provided for @warnUnsupportedRule.
  ///
  /// In zh, this message translates to:
  /// **'跳过 {count} 条 {subject} 规则'**
  String warnUnsupportedRule(int count, String subject);

  /// No description provided for @warnUnsupportedRuleSet.
  ///
  /// In zh, this message translates to:
  /// **'规则集 {subject} 无法使用，相关规则已跳过'**
  String warnUnsupportedRuleSet(String subject);

  /// No description provided for @warnInsecureTls.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个节点关闭了证书验证'**
  String warnInsecureTls(int count);

  /// No description provided for @warnMissingFinal.
  ///
  /// In zh, this message translates to:
  /// **'未指定兜底规则，未匹配的流量将直连'**
  String get warnMissingFinal;

  /// No description provided for @warnDroppedMember.
  ///
  /// In zh, this message translates to:
  /// **'组成员 {subject} 不存在或已跳过'**
  String warnDroppedMember(String subject);

  /// No description provided for @databaseTooNew.
  ///
  /// In zh, this message translates to:
  /// **'请更新 Avalon'**
  String get databaseTooNew;

  /// No description provided for @databaseTooNewNote.
  ///
  /// In zh, this message translates to:
  /// **'本机数据来自更新版本的 Avalon，请更新应用后打开。'**
  String get databaseTooNewNote;

  /// No description provided for @startupFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法打开本机数据'**
  String get startupFailed;

  /// No description provided for @ok.
  ///
  /// In zh, this message translates to:
  /// **'好'**
  String get ok;

  /// No description provided for @modeRule.
  ///
  /// In zh, this message translates to:
  /// **'规则'**
  String get modeRule;

  /// No description provided for @modeGlobal.
  ///
  /// In zh, this message translates to:
  /// **'全局'**
  String get modeGlobal;

  /// No description provided for @modeDirect.
  ///
  /// In zh, this message translates to:
  /// **'直连'**
  String get modeDirect;

  /// No description provided for @statusConnected.
  ///
  /// In zh, this message translates to:
  /// **'已连接'**
  String get statusConnected;

  /// No description provided for @statusDisconnected.
  ///
  /// In zh, this message translates to:
  /// **'未连接'**
  String get statusDisconnected;

  /// No description provided for @addConfigurationTitle.
  ///
  /// In zh, this message translates to:
  /// **'添加配置'**
  String get addConfigurationTitle;

  /// No description provided for @addPrompt.
  ///
  /// In zh, this message translates to:
  /// **'添加订阅、独立节点或代理链'**
  String get addPrompt;

  /// No description provided for @nodeCountUnknown.
  ///
  /// In zh, this message translates to:
  /// **'— 个节点'**
  String get nodeCountUnknown;

  /// No description provided for @usedOnly.
  ///
  /// In zh, this message translates to:
  /// **'已用 {used}'**
  String usedOnly(String used);

  /// No description provided for @refreshFailed.
  ///
  /// In zh, this message translates to:
  /// **'更新失败：{reason}'**
  String refreshFailed(String reason);

  /// No description provided for @autoUpdateSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'每 12 小时自动更新'**
  String get autoUpdateSubtitle;

  /// No description provided for @testLatency.
  ///
  /// In zh, this message translates to:
  /// **'测速'**
  String get testLatency;

  /// No description provided for @directModeNote.
  ///
  /// In zh, this message translates to:
  /// **'直连模式下直接访问目标地址'**
  String get directModeNote;

  /// No description provided for @groupSummary.
  ///
  /// In zh, this message translates to:
  /// **'{type} · {n} 个节点'**
  String groupSummary(String type, int n);

  /// No description provided for @groupCurrent.
  ///
  /// In zh, this message translates to:
  /// **'当前 {name}'**
  String groupCurrent(String name);

  /// No description provided for @customGroup.
  ///
  /// In zh, this message translates to:
  /// **'自定义'**
  String get customGroup;

  /// No description provided for @autoGroupNote.
  ///
  /// In zh, this message translates to:
  /// **'此组按延迟自动选择'**
  String get autoGroupNote;

  /// No description provided for @unavailable.
  ///
  /// In zh, this message translates to:
  /// **'不可用'**
  String get unavailable;

  /// No description provided for @memberChain.
  ///
  /// In zh, this message translates to:
  /// **'代理链 · {n} 跳'**
  String memberChain(int n);

  /// No description provided for @memberGroup.
  ///
  /// In zh, this message translates to:
  /// **'{type} 组'**
  String memberGroup(String type);

  /// No description provided for @memberDirect.
  ///
  /// In zh, this message translates to:
  /// **'直连'**
  String get memberDirect;

  /// No description provided for @memberReject.
  ///
  /// In zh, this message translates to:
  /// **'拒绝'**
  String get memberReject;

  /// No description provided for @noConfigurationSelectedNote.
  ///
  /// In zh, this message translates to:
  /// **'在「配置」中添加或选择一个配置后，这里会显示它的代理组。'**
  String get noConfigurationSelectedNote;

  /// No description provided for @goToConfigurations.
  ///
  /// In zh, this message translates to:
  /// **'前往配置'**
  String get goToConfigurations;

  /// No description provided for @customEmpty.
  ///
  /// In zh, this message translates to:
  /// **'添加独立节点或代理链，管理自建连接。'**
  String get customEmpty;

  /// No description provided for @contentNotDownloaded.
  ///
  /// In zh, this message translates to:
  /// **'订阅尚未下载'**
  String get contentNotDownloaded;

  /// No description provided for @pasteLinkHint.
  ///
  /// In zh, this message translates to:
  /// **'粘贴 vless:// vmess:// hy2:// …'**
  String get pasteLinkHint;

  /// No description provided for @pasteLinkHintDesktop.
  ///
  /// In zh, this message translates to:
  /// **'粘贴 vless:// vmess:// ss:// hy2:// 分享链接'**
  String get pasteLinkHintDesktop;

  /// No description provided for @parse.
  ///
  /// In zh, this message translates to:
  /// **'解析'**
  String get parse;

  /// No description provided for @protocol.
  ///
  /// In zh, this message translates to:
  /// **'协议'**
  String get protocol;

  /// No description provided for @sectionServer.
  ///
  /// In zh, this message translates to:
  /// **'服务器'**
  String get sectionServer;

  /// No description provided for @sectionTransport.
  ///
  /// In zh, this message translates to:
  /// **'传输方式'**
  String get sectionTransport;

  /// No description provided for @sectionSecurity.
  ///
  /// In zh, this message translates to:
  /// **'传输层安全'**
  String get sectionSecurity;

  /// No description provided for @securityNone.
  ///
  /// In zh, this message translates to:
  /// **'无'**
  String get securityNone;

  /// No description provided for @nodeNameHint.
  ///
  /// In zh, this message translates to:
  /// **'东京 VPS'**
  String get nodeNameHint;

  /// No description provided for @fieldServer.
  ///
  /// In zh, this message translates to:
  /// **'地址'**
  String get fieldServer;

  /// No description provided for @fieldPort.
  ///
  /// In zh, this message translates to:
  /// **'端口'**
  String get fieldPort;

  /// No description provided for @fieldPassword.
  ///
  /// In zh, this message translates to:
  /// **'密码'**
  String get fieldPassword;

  /// No description provided for @fieldObfsPassword.
  ///
  /// In zh, this message translates to:
  /// **'混淆密码'**
  String get fieldObfsPassword;

  /// No description provided for @fieldUsername.
  ///
  /// In zh, this message translates to:
  /// **'用户名'**
  String get fieldUsername;

  /// No description provided for @fieldUpMbps.
  ///
  /// In zh, this message translates to:
  /// **'上行 Mbps'**
  String get fieldUpMbps;

  /// No description provided for @fieldDownMbps.
  ///
  /// In zh, this message translates to:
  /// **'下行 Mbps'**
  String get fieldDownMbps;

  /// No description provided for @fieldCongestion.
  ///
  /// In zh, this message translates to:
  /// **'拥塞控制'**
  String get fieldCongestion;

  /// No description provided for @fieldMethod.
  ///
  /// In zh, this message translates to:
  /// **'加密'**
  String get fieldMethod;

  /// No description provided for @fieldIdleCheck.
  ///
  /// In zh, this message translates to:
  /// **'空闲会话检查'**
  String get fieldIdleCheck;

  /// No description provided for @fieldPath.
  ///
  /// In zh, this message translates to:
  /// **'路径'**
  String get fieldPath;

  /// No description provided for @fieldPublicKey.
  ///
  /// In zh, this message translates to:
  /// **'公钥'**
  String get fieldPublicKey;

  /// No description provided for @fieldRequiredHint.
  ///
  /// In zh, this message translates to:
  /// **'必填'**
  String get fieldRequiredHint;

  /// No description provided for @fieldOptionalHint.
  ///
  /// In zh, this message translates to:
  /// **'可选'**
  String get fieldOptionalHint;

  /// No description provided for @nodeSavedNote.
  ///
  /// In zh, this message translates to:
  /// **'保存到「自建节点」。'**
  String get nodeSavedNote;

  /// No description provided for @fieldRequired.
  ///
  /// In zh, this message translates to:
  /// **'请填写{field}。'**
  String fieldRequired(String field);

  /// No description provided for @fieldInvalid.
  ///
  /// In zh, this message translates to:
  /// **'{field}格式不正确。'**
  String fieldInvalid(String field);

  /// No description provided for @fieldUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'不支持的{field}取值。'**
  String fieldUnsupported(String field);

  /// No description provided for @chainNameHint.
  ///
  /// In zh, this message translates to:
  /// **'默认用节点名拼接'**
  String get chainNameHint;

  /// No description provided for @sectionChain.
  ///
  /// In zh, this message translates to:
  /// **'链路'**
  String get sectionChain;

  /// No description provided for @sectionChainDesktop.
  ///
  /// In zh, this message translates to:
  /// **'链路 · 本机 → … → 目标网站'**
  String get sectionChainDesktop;

  /// No description provided for @chainSummary.
  ///
  /// In zh, this message translates to:
  /// **'{n} 跳 · {latency}'**
  String chainSummary(int n, String latency);

  /// No description provided for @chainLatencyEstimate.
  ///
  /// In zh, this message translates to:
  /// **'≈ {ms} ms'**
  String chainLatencyEstimate(int ms);

  /// No description provided for @hopLocal.
  ///
  /// In zh, this message translates to:
  /// **'本机'**
  String get hopLocal;

  /// No description provided for @hopTarget.
  ///
  /// In zh, this message translates to:
  /// **'目标网站'**
  String get hopTarget;

  /// No description provided for @addHop.
  ///
  /// In zh, this message translates to:
  /// **'添加一跳'**
  String get addHop;

  /// No description provided for @roleEntry.
  ///
  /// In zh, this message translates to:
  /// **'入口'**
  String get roleEntry;

  /// No description provided for @roleRelay.
  ///
  /// In zh, this message translates to:
  /// **'中转'**
  String get roleRelay;

  /// No description provided for @roleExit.
  ///
  /// In zh, this message translates to:
  /// **'出口'**
  String get roleExit;

  /// No description provided for @chainNote.
  ///
  /// In zh, this message translates to:
  /// **'流量依次经过每一跳，最后一跳为出口，可组合不同协议。'**
  String get chainNote;

  /// No description provided for @sectionJoinGroups.
  ///
  /// In zh, this message translates to:
  /// **'加入代理组'**
  String get sectionJoinGroups;

  /// No description provided for @chainTooShort.
  ///
  /// In zh, this message translates to:
  /// **'代理链至少需要 2 跳'**
  String get chainTooShort;

  /// No description provided for @noHopCandidates.
  ///
  /// In zh, this message translates to:
  /// **'先添加订阅或独立节点，再选择代理链中的节点。'**
  String get noHopCandidates;

  /// No description provided for @editTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get editTitle;

  /// No description provided for @savedSecretHint.
  ///
  /// In zh, this message translates to:
  /// **'已保存'**
  String get savedSecretHint;

  /// No description provided for @errorEditConflict.
  ///
  /// In zh, this message translates to:
  /// **'内容已在其他设备或窗口修改，已重新载入，请再检查一遍。'**
  String get errorEditConflict;

  /// No description provided for @errorNotFound.
  ///
  /// In zh, this message translates to:
  /// **'该项目已不存在。'**
  String get errorNotFound;

  /// No description provided for @deleteItemTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除「{name}」？'**
  String deleteItemTitle(String name);

  /// No description provided for @deleteNodeBody.
  ///
  /// In zh, this message translates to:
  /// **'节点会从它加入的所有代理组中移除。'**
  String get deleteNodeBody;

  /// No description provided for @deleteChainBody.
  ///
  /// In zh, this message translates to:
  /// **'代理链会从它加入的所有代理组中移除，链上的节点保留。'**
  String get deleteChainBody;

  /// No description provided for @nodeInUseTitle.
  ///
  /// In zh, this message translates to:
  /// **'无法删除'**
  String get nodeInUseTitle;

  /// No description provided for @nodeInUseBody.
  ///
  /// In zh, this message translates to:
  /// **'「{name}」正被以下代理链使用，请先修改或删除它们：{chains}'**
  String nodeInUseBody(String name, String chains);

  /// No description provided for @sectionView.
  ///
  /// In zh, this message translates to:
  /// **'查看'**
  String get sectionView;

  /// No description provided for @sectionSettings.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get sectionSettings;

  /// No description provided for @sectionOther.
  ///
  /// In zh, this message translates to:
  /// **'其他'**
  String get sectionOther;

  /// No description provided for @toolConnections.
  ///
  /// In zh, this message translates to:
  /// **'连接'**
  String get toolConnections;

  /// No description provided for @toolLogs.
  ///
  /// In zh, this message translates to:
  /// **'日志'**
  String get toolLogs;

  /// No description provided for @toolLoginSync.
  ///
  /// In zh, this message translates to:
  /// **'登录与同步'**
  String get toolLoginSync;

  /// No description provided for @toolBasic.
  ///
  /// In zh, this message translates to:
  /// **'基础设置'**
  String get toolBasic;

  /// No description provided for @toolAdvanced.
  ///
  /// In zh, this message translates to:
  /// **'高级设置'**
  String get toolAdvanced;

  /// No description provided for @toolApps.
  ///
  /// In zh, this message translates to:
  /// **'分应用代理'**
  String get toolApps;

  /// No description provided for @toolGeo.
  ///
  /// In zh, this message translates to:
  /// **'GEO 规则集'**
  String get toolGeo;

  /// No description provided for @toolAbout.
  ///
  /// In zh, this message translates to:
  /// **'关于 Avalon'**
  String get toolAbout;

  /// No description provided for @toolAboutShort.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get toolAboutShort;

  /// No description provided for @sectionGeneral.
  ///
  /// In zh, this message translates to:
  /// **'通用'**
  String get sectionGeneral;

  /// No description provided for @language.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get language;

  /// No description provided for @languageZh.
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get languageZh;

  /// No description provided for @appearance.
  ///
  /// In zh, this message translates to:
  /// **'外观'**
  String get appearance;

  /// No description provided for @appearanceLight.
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get appearanceLight;

  /// No description provided for @appearanceDark.
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get appearanceDark;

  /// No description provided for @sectionStartup.
  ///
  /// In zh, this message translates to:
  /// **'启动'**
  String get sectionStartup;

  /// No description provided for @launchAtStartup.
  ///
  /// In zh, this message translates to:
  /// **'开机自动启动'**
  String get launchAtStartup;

  /// No description provided for @launchAtStartupNoteAndroid.
  ///
  /// In zh, this message translates to:
  /// **'Android 开机后在后台运行'**
  String get launchAtStartupNoteAndroid;

  /// No description provided for @launchAtStartupNoteDesktop.
  ///
  /// In zh, this message translates to:
  /// **'登录系统后自动运行 Avalon'**
  String get launchAtStartupNoteDesktop;

  /// No description provided for @launchAtStartupFailed.
  ///
  /// In zh, this message translates to:
  /// **'登录启动设置失败，请重新切换此开关重试。'**
  String get launchAtStartupFailed;

  /// No description provided for @launchAtStartupNeedsApproval.
  ///
  /// In zh, this message translates to:
  /// **'请在系统设置 → 通用 → 登录项中允许 Avalon。'**
  String get launchAtStartupNeedsApproval;

  /// No description provided for @launchAtStartupNoteIos.
  ///
  /// In zh, this message translates to:
  /// **'在系统设置中开启 VPN「按需连接」。'**
  String get launchAtStartupNoteIos;

  /// No description provided for @silentStart.
  ///
  /// In zh, this message translates to:
  /// **'静默启动'**
  String get silentStart;

  /// No description provided for @silentStartNote.
  ///
  /// In zh, this message translates to:
  /// **'启动后收起主窗口，在{tray}显示图标'**
  String silentStartNote(String tray);

  /// No description provided for @trayMenuBar.
  ///
  /// In zh, this message translates to:
  /// **'菜单栏'**
  String get trayMenuBar;

  /// No description provided for @traySystemTray.
  ///
  /// In zh, this message translates to:
  /// **'系统托盘'**
  String get traySystemTray;

  /// No description provided for @autoConnect.
  ///
  /// In zh, this message translates to:
  /// **'启动后自动连接'**
  String get autoConnect;

  /// No description provided for @autoConnectNote.
  ///
  /// In zh, this message translates to:
  /// **'打开应用时自动启动代理'**
  String get autoConnectNote;

  /// No description provided for @keepOnClose.
  ///
  /// In zh, this message translates to:
  /// **'关闭窗口时保留在{tray}'**
  String keepOnClose(String tray);

  /// No description provided for @sectionProxy.
  ///
  /// In zh, this message translates to:
  /// **'代理'**
  String get sectionProxy;

  /// No description provided for @systemProxy.
  ///
  /// In zh, this message translates to:
  /// **'系统代理'**
  String get systemProxy;

  /// No description provided for @systemProxyNoteMac.
  ///
  /// In zh, this message translates to:
  /// **'设置 macOS 网络代理'**
  String get systemProxyNoteMac;

  /// No description provided for @systemProxyNoteWindows.
  ///
  /// In zh, this message translates to:
  /// **'设置 Windows 系统代理（WinINet）'**
  String get systemProxyNoteWindows;

  /// No description provided for @systemProxyNoteLinux.
  ///
  /// In zh, this message translates to:
  /// **'写入 GNOME / KDE 代理设置'**
  String get systemProxyNoteLinux;

  /// No description provided for @systemProxyNeedsTun.
  ///
  /// In zh, this message translates to:
  /// **'需要先启用 TUN'**
  String get systemProxyNeedsTun;

  /// No description provided for @allowLan.
  ///
  /// In zh, this message translates to:
  /// **'允许局域网连接'**
  String get allowLan;

  /// No description provided for @allowLanNote.
  ///
  /// In zh, this message translates to:
  /// **'其他设备可连接本机代理端口'**
  String get allowLanNote;

  /// No description provided for @mixedPort.
  ///
  /// In zh, this message translates to:
  /// **'混合端口'**
  String get mixedPort;

  /// No description provided for @sectionHotkeys.
  ///
  /// In zh, this message translates to:
  /// **'快捷键'**
  String get sectionHotkeys;

  /// No description provided for @hotkeyToggle.
  ///
  /// In zh, this message translates to:
  /// **'启动 / 停止代理'**
  String get hotkeyToggle;

  /// No description provided for @hotkeyMode.
  ///
  /// In zh, this message translates to:
  /// **'切换出站模式'**
  String get hotkeyMode;

  /// No description provided for @hotkeyShow.
  ///
  /// In zh, this message translates to:
  /// **'显示主窗口'**
  String get hotkeyShow;

  /// No description provided for @hotkeyTaken.
  ///
  /// In zh, this message translates to:
  /// **'已被占用'**
  String get hotkeyTaken;

  /// No description provided for @hotkeyUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'暂不支持'**
  String get hotkeyUnsupported;

  /// No description provided for @trayStart.
  ///
  /// In zh, this message translates to:
  /// **'启动代理'**
  String get trayStart;

  /// No description provided for @trayStop.
  ///
  /// In zh, this message translates to:
  /// **'停止代理'**
  String get trayStop;

  /// No description provided for @trayMode.
  ///
  /// In zh, this message translates to:
  /// **'出站模式'**
  String get trayMode;

  /// No description provided for @trayQuit.
  ///
  /// In zh, this message translates to:
  /// **'退出 Avalon'**
  String get trayQuit;

  /// No description provided for @sectionNotification.
  ///
  /// In zh, this message translates to:
  /// **'通知'**
  String get sectionNotification;

  /// No description provided for @speedNotification.
  ///
  /// In zh, this message translates to:
  /// **'通知栏显示实时速度'**
  String get speedNotification;

  /// No description provided for @sectionLatency.
  ///
  /// In zh, this message translates to:
  /// **'延迟测试'**
  String get sectionLatency;

  /// No description provided for @testUrl.
  ///
  /// In zh, this message translates to:
  /// **'测速地址'**
  String get testUrl;

  /// No description provided for @testTimeout.
  ///
  /// In zh, this message translates to:
  /// **'超时'**
  String get testTimeout;

  /// No description provided for @milliseconds.
  ///
  /// In zh, this message translates to:
  /// **'{n} ms'**
  String milliseconds(int n);

  /// No description provided for @sectionData.
  ///
  /// In zh, this message translates to:
  /// **'数据'**
  String get sectionData;

  /// No description provided for @exportBackup.
  ///
  /// In zh, this message translates to:
  /// **'导出备份…'**
  String get exportBackup;

  /// No description provided for @restoreBackup.
  ///
  /// In zh, this message translates to:
  /// **'从文件恢复…'**
  String get restoreBackup;

  /// No description provided for @backupNote.
  ///
  /// In zh, this message translates to:
  /// **'备份包含订阅、自建节点、代理链和全部设置。'**
  String get backupNote;

  /// No description provided for @sectionTun.
  ///
  /// In zh, this message translates to:
  /// **'虚拟网卡 TUN'**
  String get sectionTun;

  /// No description provided for @tunEnabled.
  ///
  /// In zh, this message translates to:
  /// **'启用 TUN'**
  String get tunEnabled;

  /// No description provided for @tunNote.
  ///
  /// In zh, this message translates to:
  /// **'接管设备全部流量'**
  String get tunNote;

  /// No description provided for @tunNoteMac.
  ///
  /// In zh, this message translates to:
  /// **'utun · 需要授权网络扩展'**
  String get tunNoteMac;

  /// No description provided for @tunNoteWindows.
  ///
  /// In zh, this message translates to:
  /// **'WinTUN · 需要管理员权限'**
  String get tunNoteWindows;

  /// No description provided for @tunNoteLinux.
  ///
  /// In zh, this message translates to:
  /// **'tun0 · 需要 CAP_NET_ADMIN'**
  String get tunNoteLinux;

  /// No description provided for @tunStack.
  ///
  /// In zh, this message translates to:
  /// **'协议栈'**
  String get tunStack;

  /// No description provided for @autoRoute.
  ///
  /// In zh, this message translates to:
  /// **'自动路由'**
  String get autoRoute;

  /// No description provided for @strictRoute.
  ///
  /// In zh, this message translates to:
  /// **'严格路由'**
  String get strictRoute;

  /// No description provided for @strictRouteNote.
  ///
  /// In zh, this message translates to:
  /// **'严格执行隧道路由规则'**
  String get strictRouteNote;

  /// No description provided for @remoteDns.
  ///
  /// In zh, this message translates to:
  /// **'远程 DNS'**
  String get remoteDns;

  /// No description provided for @directDns.
  ///
  /// In zh, this message translates to:
  /// **'直连 DNS'**
  String get directDns;

  /// No description provided for @dnsStrategy.
  ///
  /// In zh, this message translates to:
  /// **'解析策略'**
  String get dnsStrategy;

  /// No description provided for @dnsPreferIpv4.
  ///
  /// In zh, this message translates to:
  /// **'优先 IPv4'**
  String get dnsPreferIpv4;

  /// No description provided for @dnsIpv4Only.
  ///
  /// In zh, this message translates to:
  /// **'仅 IPv4'**
  String get dnsIpv4Only;

  /// No description provided for @dnsPreferIpv6.
  ///
  /// In zh, this message translates to:
  /// **'优先 IPv6'**
  String get dnsPreferIpv6;

  /// No description provided for @dnsIpv6OffNote.
  ///
  /// In zh, this message translates to:
  /// **'IPv6 已关闭，解析按「仅 IPv4」生效。'**
  String get dnsIpv6OffNote;

  /// No description provided for @sectionRouting.
  ///
  /// In zh, this message translates to:
  /// **'路由'**
  String get sectionRouting;

  /// No description provided for @sniff.
  ///
  /// In zh, this message translates to:
  /// **'流量嗅探'**
  String get sniff;

  /// No description provided for @sniffNote.
  ///
  /// In zh, this message translates to:
  /// **'识别 TLS / HTTP / QUIC 域名'**
  String get sniffNote;

  /// No description provided for @bypassLan.
  ///
  /// In zh, this message translates to:
  /// **'绕过局域网与保留地址'**
  String get bypassLan;

  /// No description provided for @findProcess.
  ///
  /// In zh, this message translates to:
  /// **'查找进程'**
  String get findProcess;

  /// No description provided for @findProcessNote.
  ///
  /// In zh, this message translates to:
  /// **'用于分应用代理和连接页显示应用'**
  String get findProcessNote;

  /// No description provided for @findProcessNoteDesktop.
  ///
  /// In zh, this message translates to:
  /// **'用于分应用代理和连接页显示程序'**
  String get findProcessNoteDesktop;

  /// No description provided for @clashApi.
  ///
  /// In zh, this message translates to:
  /// **'外部控制器'**
  String get clashApi;

  /// No description provided for @clashApiNote.
  ///
  /// In zh, this message translates to:
  /// **'供 Web 面板或第三方客户端控制'**
  String get clashApiNote;

  /// No description provided for @clashListen.
  ///
  /// In zh, this message translates to:
  /// **'监听地址'**
  String get clashListen;

  /// No description provided for @clashListenRisk.
  ///
  /// In zh, this message translates to:
  /// **'同一网络中的其他设备可通过此监听地址控制代理。'**
  String get clashListenRisk;

  /// No description provided for @clashSecret.
  ///
  /// In zh, this message translates to:
  /// **'密钥'**
  String get clashSecret;

  /// No description provided for @secretView.
  ///
  /// In zh, this message translates to:
  /// **'查看'**
  String get secretView;

  /// No description provided for @secretCopy.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get secretCopy;

  /// No description provided for @secretRegenerate.
  ///
  /// In zh, this message translates to:
  /// **'重新生成'**
  String get secretRegenerate;

  /// No description provided for @secretRegenerateConfirm.
  ///
  /// In zh, this message translates to:
  /// **'重新生成后，使用旧密钥的面板和客户端需要改用新密钥。'**
  String get secretRegenerateConfirm;

  /// No description provided for @copied.
  ///
  /// In zh, this message translates to:
  /// **'已复制'**
  String get copied;

  /// No description provided for @webPanel.
  ///
  /// In zh, this message translates to:
  /// **'Web 面板'**
  String get webPanel;

  /// No description provided for @openWebPanel.
  ///
  /// In zh, this message translates to:
  /// **'打开 metacubexd'**
  String get openWebPanel;

  /// No description provided for @webPanelNotRunning.
  ///
  /// In zh, this message translates to:
  /// **'代理尚未运行，请先连接后再打开 Web 面板。'**
  String get webPanelNotRunning;

  /// No description provided for @webPanelControllerOff.
  ///
  /// In zh, this message translates to:
  /// **'运行中的外部控制器已关闭，请在高级设置中启用并生效后再打开 Web 面板。'**
  String get webPanelControllerOff;

  /// No description provided for @webPanelStateUnknown.
  ///
  /// In zh, this message translates to:
  /// **'暂时无法读取外部控制器当前状态，请检查代理连接后重试。'**
  String get webPanelStateUnknown;

  /// No description provided for @webPanelBrowserFailed.
  ///
  /// In zh, this message translates to:
  /// **'系统浏览器未能打开 Web 面板，请检查浏览器后重试。'**
  String get webPanelBrowserFailed;

  /// No description provided for @sectionCore.
  ///
  /// In zh, this message translates to:
  /// **'内核'**
  String get sectionCore;

  /// No description provided for @logLevel.
  ///
  /// In zh, this message translates to:
  /// **'日志等级'**
  String get logLevel;

  /// No description provided for @configOverride.
  ///
  /// In zh, this message translates to:
  /// **'配置覆写'**
  String get configOverride;

  /// No description provided for @editJson.
  ///
  /// In zh, this message translates to:
  /// **'编辑 JSON…'**
  String get editJson;

  /// No description provided for @viewGeneratedConfig.
  ///
  /// In zh, this message translates to:
  /// **'查看生成的配置'**
  String get viewGeneratedConfig;

  /// No description provided for @generatedConfig.
  ///
  /// In zh, this message translates to:
  /// **'生成的配置'**
  String get generatedConfig;

  /// No description provided for @viewAction.
  ///
  /// In zh, this message translates to:
  /// **'查看…'**
  String get viewAction;

  /// No description provided for @overrideNote.
  ///
  /// In zh, this message translates to:
  /// **'配置覆写会合并到每个订阅生成的 sing-box 配置中，适合自定义路由规则或出站。'**
  String get overrideNote;

  /// No description provided for @resetDefaults.
  ///
  /// In zh, this message translates to:
  /// **'恢复默认设置'**
  String get resetDefaults;

  /// No description provided for @resetDefaultsConfirm.
  ///
  /// In zh, this message translates to:
  /// **'恢复本页所有设置为默认值？配置覆写和 Clash API 密钥会保留。'**
  String get resetDefaultsConfirm;

  /// No description provided for @reset.
  ///
  /// In zh, this message translates to:
  /// **'恢复'**
  String get reset;

  /// No description provided for @settingInvalid.
  ///
  /// In zh, this message translates to:
  /// **'格式不正确。'**
  String get settingInvalid;

  /// No description provided for @settingOutOfRange.
  ///
  /// In zh, this message translates to:
  /// **'请输入 {min}–{max} 之间的数字。'**
  String settingOutOfRange(int min, int max);

  /// No description provided for @remoteDnsHint.
  ///
  /// In zh, this message translates to:
  /// **'以 https:// 或 tls:// 开头'**
  String get remoteDnsHint;

  /// No description provided for @directDnsHint.
  ///
  /// In zh, this message translates to:
  /// **'IP 地址，或以 udp:// 开头'**
  String get directDnsHint;

  /// No description provided for @testUrlHint.
  ///
  /// In zh, this message translates to:
  /// **'以 http:// 或 https:// 开头'**
  String get testUrlHint;

  /// No description provided for @clashListenHint.
  ///
  /// In zh, this message translates to:
  /// **'地址:端口，如 127.0.0.1:9090'**
  String get clashListenHint;

  /// No description provided for @aboutVersion.
  ///
  /// In zh, this message translates to:
  /// **'版本'**
  String get aboutVersion;

  /// No description provided for @aboutCore.
  ///
  /// In zh, this message translates to:
  /// **'内核'**
  String get aboutCore;

  /// No description provided for @aboutLicense.
  ///
  /// In zh, this message translates to:
  /// **'许可证'**
  String get aboutLicense;

  /// No description provided for @aboutThanks.
  ///
  /// In zh, this message translates to:
  /// **'致谢 sing-box 与开源社区'**
  String get aboutThanks;

  /// No description provided for @overrideKeysNote.
  ///
  /// In zh, this message translates to:
  /// **'支持 outbounds、route.rules、route.rule_set、route.final、dns.servers、dns.rules。引用节点或代理组时使用显示名称。覆写应用于导入的配置。'**
  String get overrideKeysNote;

  /// No description provided for @overrideSyntax.
  ///
  /// In zh, this message translates to:
  /// **'JSON 语法错误：第 {line} 行第 {column} 列。'**
  String overrideSyntax(int line, int column);

  /// No description provided for @overrideNotObject.
  ///
  /// In zh, this message translates to:
  /// **'最外层应为一个 JSON 对象。'**
  String get overrideNotObject;

  /// No description provided for @overrideNotAllowed.
  ///
  /// In zh, this message translates to:
  /// **'不允许的键：{path}'**
  String overrideNotAllowed(String path);

  /// No description provided for @overrideWrongType.
  ///
  /// In zh, this message translates to:
  /// **'{path} 的类型不对，应为{type}。'**
  String overrideWrongType(String path, String type);

  /// No description provided for @jsonObject.
  ///
  /// In zh, this message translates to:
  /// **'对象'**
  String get jsonObject;

  /// No description provided for @jsonArray.
  ///
  /// In zh, this message translates to:
  /// **'数组'**
  String get jsonArray;

  /// No description provided for @jsonString.
  ///
  /// In zh, this message translates to:
  /// **'字符串'**
  String get jsonString;

  /// No description provided for @jsonTaggedObject.
  ///
  /// In zh, this message translates to:
  /// **'带 tag 的对象'**
  String get jsonTaggedObject;

  /// No description provided for @overrideReference.
  ///
  /// In zh, this message translates to:
  /// **'找不到名为「{name}」的节点或代理组（{path}）。'**
  String overrideReference(String name, String path);

  /// No description provided for @overrideConflict.
  ///
  /// In zh, this message translates to:
  /// **'标签「{name}」与生成的配置冲突（{path}），请换一个名称。'**
  String overrideConflict(String name, String path);

  /// No description provided for @compileNothingSelected.
  ///
  /// In zh, this message translates to:
  /// **'请先在「配置」中选择一个配置。'**
  String get compileNothingSelected;

  /// No description provided for @compileMemberUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'「{name}」不可用，无法生成配置。'**
  String compileMemberUnavailable(String name);

  /// No description provided for @compileEmptyGroup.
  ///
  /// In zh, this message translates to:
  /// **'代理组「{name}」没有可用的成员。'**
  String compileEmptyGroup(String name);

  /// No description provided for @compileRuleSetMissing.
  ///
  /// In zh, this message translates to:
  /// **'规则集「{name}」尚未下载或无法使用。'**
  String compileRuleSetMissing(String name);

  /// No description provided for @compilePerAppNeedsFindProcess.
  ///
  /// In zh, this message translates to:
  /// **'分应用代理需要开启「查找进程」。'**
  String get compilePerAppNeedsFindProcess;

  /// No description provided for @compileInvalidSetting.
  ///
  /// In zh, this message translates to:
  /// **'设置项无效：{name}。'**
  String compileInvalidSetting(String name);

  /// No description provided for @generatedNote.
  ///
  /// In zh, this message translates to:
  /// **'秘密已替换为 ••••。这是按当前选中的配置和设置生成的内容。'**
  String get generatedNote;

  /// No description provided for @copyAll.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get copyAll;

  /// No description provided for @backupPassword.
  ///
  /// In zh, this message translates to:
  /// **'备份密码'**
  String get backupPassword;

  /// No description provided for @backupPasswordNote.
  ///
  /// In zh, this message translates to:
  /// **'密码至少 8 位，请妥善保管，恢复备份时使用。'**
  String get backupPasswordNote;

  /// No description provided for @passwordHint.
  ///
  /// In zh, this message translates to:
  /// **'密码'**
  String get passwordHint;

  /// No description provided for @passwordAgainHint.
  ///
  /// In zh, this message translates to:
  /// **'再次输入密码'**
  String get passwordAgainHint;

  /// No description provided for @passwordTooShort.
  ///
  /// In zh, this message translates to:
  /// **'密码至少需要 8 位。'**
  String get passwordTooShort;

  /// No description provided for @passwordMismatch.
  ///
  /// In zh, this message translates to:
  /// **'两次输入的密码不一致。'**
  String get passwordMismatch;

  /// No description provided for @backupEncrypting.
  ///
  /// In zh, this message translates to:
  /// **'正在加密备份…'**
  String get backupEncrypting;

  /// No description provided for @backupExported.
  ///
  /// In zh, this message translates to:
  /// **'备份已导出'**
  String get backupExported;

  /// No description provided for @restorePassword.
  ///
  /// In zh, this message translates to:
  /// **'输入备份密码'**
  String get restorePassword;

  /// No description provided for @restoreConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'从备份恢复？'**
  String get restoreConfirmTitle;

  /// No description provided for @restoreConfirmBody.
  ///
  /// In zh, this message translates to:
  /// **'恢复会覆盖同名设置和相同对象，本机其他内容保留。'**
  String get restoreConfirmBody;

  /// No description provided for @restoring.
  ///
  /// In zh, this message translates to:
  /// **'正在恢复…'**
  String get restoring;

  /// No description provided for @restoreDoneTitle.
  ///
  /// In zh, this message translates to:
  /// **'恢复完成'**
  String get restoreDoneTitle;

  /// No description provided for @restoreDoneBody.
  ///
  /// In zh, this message translates to:
  /// **'已恢复 {configs} 个配置、{nodes} 个自建节点、{chains} 条代理链，以及全部设置。'**
  String restoreDoneBody(int configs, int nodes, int chains);

  /// No description provided for @backupWrongPassword.
  ///
  /// In zh, this message translates to:
  /// **'密码错误，或文件已损坏。'**
  String get backupWrongPassword;

  /// No description provided for @backupNotABackup.
  ///
  /// In zh, this message translates to:
  /// **'这不是 Avalon 备份文件。'**
  String get backupNotABackup;

  /// No description provided for @backupUnsupportedVersion.
  ///
  /// In zh, this message translates to:
  /// **'此备份来自更新版本的 Avalon，请先更新应用。'**
  String get backupUnsupportedVersion;

  /// No description provided for @backupTooLarge.
  ///
  /// In zh, this message translates to:
  /// **'文件超出备份的大小上限。'**
  String get backupTooLarge;

  /// No description provided for @backupMalformed.
  ///
  /// In zh, this message translates to:
  /// **'备份内容无法识别。'**
  String get backupMalformed;

  /// No description provided for @exportBackupAction.
  ///
  /// In zh, this message translates to:
  /// **'导出'**
  String get exportBackupAction;

  /// No description provided for @fileChoose.
  ///
  /// In zh, this message translates to:
  /// **'选择 .json 或 .yaml'**
  String get fileChoose;

  /// No description provided for @fileChooseNote.
  ///
  /// In zh, this message translates to:
  /// **'sing-box 配置或 Clash 配置'**
  String get fileChooseNote;

  /// No description provided for @dropFile.
  ///
  /// In zh, this message translates to:
  /// **'或拖入配置文件'**
  String get dropFile;

  /// No description provided for @dropFileNote.
  ///
  /// In zh, this message translates to:
  /// **'.json（sing-box）/ .yaml（Clash）'**
  String get dropFileNote;

  /// No description provided for @fileReplace.
  ///
  /// In zh, this message translates to:
  /// **'点击更换'**
  String get fileReplace;

  /// No description provided for @fileImportNote.
  ///
  /// In zh, this message translates to:
  /// **'将文件内容保存为本机配置。'**
  String get fileImportNote;

  /// No description provided for @scanPrompt.
  ///
  /// In zh, this message translates to:
  /// **'将订阅二维码放入框内'**
  String get scanPrompt;

  /// No description provided for @scanDenied.
  ///
  /// In zh, this message translates to:
  /// **'需要相机权限才能扫码。可在系统设置中允许 Avalon 使用相机，或直接粘贴订阅链接。'**
  String get scanDenied;

  /// No description provided for @scanUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'此设备上的相机不可用，请直接粘贴订阅链接。'**
  String get scanUnavailable;

  /// No description provided for @scanNotSubscription.
  ///
  /// In zh, this message translates to:
  /// **'二维码内容不是订阅链接（需以 http:// 或 https:// 开头）。'**
  String get scanNotSubscription;

  /// No description provided for @scanned.
  ///
  /// In zh, this message translates to:
  /// **'已识别订阅链接'**
  String get scanned;

  /// No description provided for @networkSpeed.
  ///
  /// In zh, this message translates to:
  /// **'网络速度'**
  String get networkSpeed;

  /// No description provided for @todayUpload.
  ///
  /// In zh, this message translates to:
  /// **'今日上传'**
  String get todayUpload;

  /// No description provided for @todayDownload.
  ///
  /// In zh, this message translates to:
  /// **'下载'**
  String get todayDownload;

  /// No description provided for @todayTraffic.
  ///
  /// In zh, this message translates to:
  /// **'今日流量'**
  String get todayTraffic;

  /// No description provided for @currentNode.
  ///
  /// In zh, this message translates to:
  /// **'当前节点'**
  String get currentNode;

  /// No description provided for @exitIp.
  ///
  /// In zh, this message translates to:
  /// **'出口 IP'**
  String get exitIp;

  /// No description provided for @modeRuleFull.
  ///
  /// In zh, this message translates to:
  /// **'规则模式'**
  String get modeRuleFull;

  /// No description provided for @modeGlobalFull.
  ///
  /// In zh, this message translates to:
  /// **'全局模式'**
  String get modeGlobalFull;

  /// No description provided for @modeDirectFull.
  ///
  /// In zh, this message translates to:
  /// **'直连模式'**
  String get modeDirectFull;

  /// No description provided for @addConfigurationFirst.
  ///
  /// In zh, this message translates to:
  /// **'请先添加配置'**
  String get addConfigurationFirst;

  /// No description provided for @aboutVersionLine.
  ///
  /// In zh, this message translates to:
  /// **'版本 {version}'**
  String aboutVersionLine(String version);

  /// No description provided for @keyStorage.
  ///
  /// In zh, this message translates to:
  /// **'安全存储'**
  String get keyStorage;

  /// No description provided for @keyStorageFile.
  ///
  /// In zh, this message translates to:
  /// **'本机文件（权限 0600）'**
  String get keyStorageFile;

  /// No description provided for @licensesTitle.
  ///
  /// In zh, this message translates to:
  /// **'许可与第三方声明'**
  String get licensesTitle;

  /// No description provided for @licenseCount.
  ///
  /// In zh, this message translates to:
  /// **'{n} 份许可'**
  String licenseCount(int n);

  /// No description provided for @licensesNote.
  ///
  /// In zh, this message translates to:
  /// **'Avalon 以 AGPL-3.0 发布。以下是随应用分发的开源组件及其许可。'**
  String get licensesNote;

  /// No description provided for @search.
  ///
  /// In zh, this message translates to:
  /// **'搜索'**
  String get search;

  /// No description provided for @turnOn.
  ///
  /// In zh, this message translates to:
  /// **'开启'**
  String get turnOn;

  /// No description provided for @perAppWhitelist.
  ///
  /// In zh, this message translates to:
  /// **'白名单'**
  String get perAppWhitelist;

  /// No description provided for @perAppBlacklist.
  ///
  /// In zh, this message translates to:
  /// **'黑名单'**
  String get perAppBlacklist;

  /// No description provided for @appsHintEmpty.
  ///
  /// In zh, this message translates to:
  /// **'未选择应用时，全部应用按规则代理。'**
  String get appsHintEmpty;

  /// No description provided for @appsHintWhitelist.
  ///
  /// In zh, this message translates to:
  /// **'仅开启的应用走代理，其余直连。'**
  String get appsHintWhitelist;

  /// No description provided for @appsHintBlacklist.
  ///
  /// In zh, this message translates to:
  /// **'开启的应用直连，其余走代理。'**
  String get appsHintBlacklist;

  /// No description provided for @appsHintWhitelistDesktop.
  ///
  /// In zh, this message translates to:
  /// **'仅开启的程序走代理，其余直连。'**
  String get appsHintWhitelistDesktop;

  /// No description provided for @appsHintBlacklistDesktop.
  ///
  /// In zh, this message translates to:
  /// **'开启的程序直连，其余走代理。'**
  String get appsHintBlacklistDesktop;

  /// No description provided for @appNotInstalled.
  ///
  /// In zh, this message translates to:
  /// **'未安装'**
  String get appNotInstalled;

  /// No description provided for @addProgram.
  ///
  /// In zh, this message translates to:
  /// **'添加程序'**
  String get addProgram;

  /// No description provided for @appsListFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法读取应用列表'**
  String get appsListFailed;

  /// No description provided for @appsListFailedNote.
  ///
  /// In zh, this message translates to:
  /// **'下面只显示已保存的名单。'**
  String get appsListFailedNote;

  /// No description provided for @appsNoMatch.
  ///
  /// In zh, this message translates to:
  /// **'没有匹配的应用'**
  String get appsNoMatch;

  /// No description provided for @appsNoMatchDesktop.
  ///
  /// In zh, this message translates to:
  /// **'没有匹配的程序'**
  String get appsNoMatchDesktop;

  /// No description provided for @appsNoPrograms.
  ///
  /// In zh, this message translates to:
  /// **'还没有程序。点「添加程序」选择要单独处理的程序。'**
  String get appsNoPrograms;

  /// No description provided for @appsNeedFindProcessNote.
  ///
  /// In zh, this message translates to:
  /// **'开启「查找进程」，按程序应用代理规则。'**
  String get appsNeedFindProcessNote;

  /// No description provided for @rulesCount.
  ///
  /// In zh, this message translates to:
  /// **'{n} 个规则集'**
  String rulesCount(int n);

  /// No description provided for @rulesAutoDaily.
  ///
  /// In zh, this message translates to:
  /// **'每天自动更新'**
  String get rulesAutoDaily;

  /// No description provided for @rulesAutoWeekly.
  ///
  /// In zh, this message translates to:
  /// **'每周自动更新'**
  String get rulesAutoWeekly;

  /// No description provided for @rulesAutoOff.
  ///
  /// In zh, this message translates to:
  /// **'自动更新已关闭'**
  String get rulesAutoOff;

  /// No description provided for @rulesUpdating.
  ///
  /// In zh, this message translates to:
  /// **'更新中'**
  String get rulesUpdating;

  /// No description provided for @sectionRuleSets.
  ///
  /// In zh, this message translates to:
  /// **'规则集'**
  String get sectionRuleSets;

  /// No description provided for @sectionUpdateSettings.
  ///
  /// In zh, this message translates to:
  /// **'更新设置'**
  String get sectionUpdateSettings;

  /// No description provided for @geoInterval.
  ///
  /// In zh, this message translates to:
  /// **'更新间隔'**
  String get geoInterval;

  /// No description provided for @geoDaily.
  ///
  /// In zh, this message translates to:
  /// **'每天'**
  String get geoDaily;

  /// No description provided for @geoWeekly.
  ///
  /// In zh, this message translates to:
  /// **'每周'**
  String get geoWeekly;

  /// No description provided for @geoVia.
  ///
  /// In zh, this message translates to:
  /// **'下载方式'**
  String get geoVia;

  /// No description provided for @geoViaProxy.
  ///
  /// In zh, this message translates to:
  /// **'经代理'**
  String get geoViaProxy;

  /// No description provided for @geoViaDirect.
  ///
  /// In zh, this message translates to:
  /// **'直连'**
  String get geoViaDirect;

  /// No description provided for @rulesNote.
  ///
  /// In zh, this message translates to:
  /// **'管理和更新 GeoSite、GeoIP 及订阅引用的规则集。'**
  String get rulesNote;

  /// No description provided for @ruleKindSet.
  ///
  /// In zh, this message translates to:
  /// **'规则集'**
  String get ruleKindSet;

  /// No description provided for @ruleNotDownloaded.
  ///
  /// In zh, this message translates to:
  /// **'未下载'**
  String get ruleNotDownloaded;

  /// No description provided for @ruleUpdatedAgo.
  ///
  /// In zh, this message translates to:
  /// **'{when}更新'**
  String ruleUpdatedAgo(String when);

  /// No description provided for @ruleDownloading.
  ///
  /// In zh, this message translates to:
  /// **'下载中…'**
  String get ruleDownloading;

  /// No description provided for @columnType.
  ///
  /// In zh, this message translates to:
  /// **'类型'**
  String get columnType;

  /// No description provided for @columnSize.
  ///
  /// In zh, this message translates to:
  /// **'大小'**
  String get columnSize;

  /// No description provided for @columnUpdated.
  ///
  /// In zh, this message translates to:
  /// **'更新时间'**
  String get columnUpdated;

  /// No description provided for @rulesNeedProxy.
  ///
  /// In zh, this message translates to:
  /// **'请先启动代理，或改用直连下载'**
  String get rulesNeedProxy;

  /// No description provided for @statusConnecting.
  ///
  /// In zh, this message translates to:
  /// **'正在连接…'**
  String get statusConnecting;

  /// No description provided for @statusReconnecting.
  ///
  /// In zh, this message translates to:
  /// **'正在重新连接'**
  String get statusReconnecting;

  /// No description provided for @statusDisconnecting.
  ///
  /// In zh, this message translates to:
  /// **'正在断开…'**
  String get statusDisconnecting;

  /// No description provided for @coreReady.
  ///
  /// In zh, this message translates to:
  /// **'sing-box {version} 已就绪'**
  String coreReady(String version);

  /// No description provided for @connectedSummary.
  ///
  /// In zh, this message translates to:
  /// **'{mode} · {exit}'**
  String connectedSummary(String mode, String exit);

  /// No description provided for @runtimePermissionRefused.
  ///
  /// In zh, this message translates to:
  /// **'需要 VPN 授权才能连接'**
  String get runtimePermissionRefused;

  /// No description provided for @runtimePermissionRefusedNote.
  ///
  /// In zh, this message translates to:
  /// **'再次点击连接，并在系统弹窗中允许。'**
  String get runtimePermissionRefusedNote;

  /// No description provided for @runtimeNotDownloaded.
  ///
  /// In zh, this message translates to:
  /// **'所选配置尚未下载，请先更新'**
  String get runtimeNotDownloaded;

  /// No description provided for @runtimePlanFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法生成配置'**
  String get runtimePlanFailed;

  /// No description provided for @runtimeHostUnreachable.
  ///
  /// In zh, this message translates to:
  /// **'无法连接到 Avalon 服务'**
  String get runtimeHostUnreachable;

  /// No description provided for @runtimePortInUse.
  ///
  /// In zh, this message translates to:
  /// **'端口被占用，请更换混合端口'**
  String get runtimePortInUse;

  /// No description provided for @runtimeNoListedAppInstalled.
  ///
  /// In zh, this message translates to:
  /// **'白名单里的应用都未安装'**
  String get runtimeNoListedAppInstalled;

  /// No description provided for @runtimeNoListedAppInstalledNote.
  ///
  /// In zh, this message translates to:
  /// **'请在「分应用代理」的白名单中选择本机已安装的应用，或改用黑名单、清空名单。'**
  String get runtimeNoListedAppInstalledNote;

  /// No description provided for @appsNoneInstalled.
  ///
  /// In zh, this message translates to:
  /// **'名单里的应用都未安装'**
  String get appsNoneInstalled;

  /// No description provided for @appsNoneInstalledNote.
  ///
  /// In zh, this message translates to:
  /// **'请在白名单中选择本机已安装的应用后启动代理。'**
  String get appsNoneInstalledNote;

  /// No description provided for @runtimePlanRefused.
  ///
  /// In zh, this message translates to:
  /// **'内核不接受这份配置'**
  String get runtimePlanRefused;

  /// No description provided for @runtimeCoreFailed.
  ///
  /// In zh, this message translates to:
  /// **'内核启动失败'**
  String get runtimeCoreFailed;

  /// No description provided for @runtimeTimeout.
  ///
  /// In zh, this message translates to:
  /// **'Avalon 服务没有及时响应'**
  String get runtimeTimeout;

  /// No description provided for @errorConfigurationInUse.
  ///
  /// In zh, this message translates to:
  /// **'请先断开或切换到其他配置'**
  String get errorConfigurationInUse;

  /// No description provided for @autoUpdateLocalOnlyNote.
  ///
  /// In zh, this message translates to:
  /// **'每 12 小时自动更新，保存在本机。'**
  String get autoUpdateLocalOnlyNote;

  /// No description provided for @latencyTimeout.
  ///
  /// In zh, this message translates to:
  /// **'超时'**
  String get latencyTimeout;

  /// No description provided for @latencyFailed.
  ///
  /// In zh, this message translates to:
  /// **'失败'**
  String get latencyFailed;

  /// No description provided for @closeAll.
  ///
  /// In zh, this message translates to:
  /// **'全部关闭'**
  String get closeAll;

  /// No description provided for @activeConnections.
  ///
  /// In zh, this message translates to:
  /// **'{n} 个活动连接'**
  String activeConnections(int n);

  /// No description provided for @noConnections.
  ///
  /// In zh, this message translates to:
  /// **'暂无连接'**
  String get noConnections;

  /// No description provided for @connectionsWhenRunning.
  ///
  /// In zh, this message translates to:
  /// **'启动代理后，这里会实时显示连接'**
  String get connectionsWhenRunning;

  /// No description provided for @connectionsAllClosed.
  ///
  /// In zh, this message translates to:
  /// **'所有连接已关闭'**
  String get connectionsAllClosed;

  /// No description provided for @columnHost.
  ///
  /// In zh, this message translates to:
  /// **'主机'**
  String get columnHost;

  /// No description provided for @columnProcess.
  ///
  /// In zh, this message translates to:
  /// **'进程'**
  String get columnProcess;

  /// No description provided for @columnRule.
  ///
  /// In zh, this message translates to:
  /// **'规则'**
  String get columnRule;

  /// No description provided for @columnChain.
  ///
  /// In zh, this message translates to:
  /// **'链路'**
  String get columnChain;

  /// No description provided for @columnUpload.
  ///
  /// In zh, this message translates to:
  /// **'上传'**
  String get columnUpload;

  /// No description provided for @columnDownload.
  ///
  /// In zh, this message translates to:
  /// **'下载'**
  String get columnDownload;

  /// No description provided for @ruleFinal.
  ///
  /// In zh, this message translates to:
  /// **'默认'**
  String get ruleFinal;

  /// No description provided for @logsAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get logsAll;

  /// No description provided for @logsDropped.
  ///
  /// In zh, this message translates to:
  /// **'较早日志已丢弃'**
  String get logsDropped;

  /// No description provided for @noLogs.
  ///
  /// In zh, this message translates to:
  /// **'暂无日志'**
  String get noLogs;

  /// No description provided for @noLogsNote.
  ///
  /// In zh, this message translates to:
  /// **'代理运行时，内核的日志会显示在这里'**
  String get noLogsNote;

  /// No description provided for @shareLogs.
  ///
  /// In zh, this message translates to:
  /// **'分享日志'**
  String get shareLogs;

  /// No description provided for @exportLogs.
  ///
  /// In zh, this message translates to:
  /// **'导出日志'**
  String get exportLogs;

  /// No description provided for @ruleDownloadFailed.
  ///
  /// In zh, this message translates to:
  /// **'下载失败'**
  String get ruleDownloadFailed;

  /// No description provided for @cloudTitle.
  ///
  /// In zh, this message translates to:
  /// **'Avalon Cloud'**
  String get cloudTitle;

  /// No description provided for @cloudLoginTitle.
  ///
  /// In zh, this message translates to:
  /// **'登录 Avalon'**
  String get cloudLoginTitle;

  /// No description provided for @cloudLoginNote.
  ///
  /// In zh, this message translates to:
  /// **'使用邮箱验证码登录 Avalon。'**
  String get cloudLoginNote;

  /// No description provided for @cloudLoginIntro.
  ///
  /// In zh, this message translates to:
  /// **'用邮箱登录，\n在你的设备间同步配置。'**
  String get cloudLoginIntro;

  /// No description provided for @cloudEmailAddress.
  ///
  /// In zh, this message translates to:
  /// **'邮箱地址'**
  String get cloudEmailAddress;

  /// No description provided for @cloudCheckInbox.
  ///
  /// In zh, this message translates to:
  /// **'查看你的邮箱'**
  String get cloudCheckInbox;

  /// No description provided for @cloudCodeSentTo.
  ///
  /// In zh, this message translates to:
  /// **'验证码已发送至'**
  String get cloudCodeSentTo;

  /// No description provided for @cloudSixDigitCode.
  ///
  /// In zh, this message translates to:
  /// **'6 位验证码'**
  String get cloudSixDigitCode;

  /// No description provided for @cloudCodeHelper.
  ///
  /// In zh, this message translates to:
  /// **'输入邮件中的验证码完成登录。'**
  String get cloudCodeHelper;

  /// No description provided for @cloudClearEmail.
  ///
  /// In zh, this message translates to:
  /// **'清空邮箱'**
  String get cloudClearEmail;

  /// No description provided for @cloudEmail.
  ///
  /// In zh, this message translates to:
  /// **'邮箱'**
  String get cloudEmail;

  /// No description provided for @cloudEmailPlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'name@example.com'**
  String get cloudEmailPlaceholder;

  /// No description provided for @cloudCode.
  ///
  /// In zh, this message translates to:
  /// **'验证码'**
  String get cloudCode;

  /// No description provided for @cloudCodePlaceholder.
  ///
  /// In zh, this message translates to:
  /// **'六位验证码'**
  String get cloudCodePlaceholder;

  /// No description provided for @cloudSendCode.
  ///
  /// In zh, this message translates to:
  /// **'发送验证码'**
  String get cloudSendCode;

  /// No description provided for @cloudResendCode.
  ///
  /// In zh, this message translates to:
  /// **'重新发送'**
  String get cloudResendCode;

  /// No description provided for @cloudVerifyCode.
  ///
  /// In zh, this message translates to:
  /// **'登录'**
  String get cloudVerifyCode;

  /// No description provided for @cloudChangeEmail.
  ///
  /// In zh, this message translates to:
  /// **'更换邮箱'**
  String get cloudChangeEmail;

  /// No description provided for @cloudCodeSent.
  ///
  /// In zh, this message translates to:
  /// **'验证码已发送，请查收邮箱。'**
  String get cloudCodeSent;

  /// No description provided for @cloudResendWait.
  ///
  /// In zh, this message translates to:
  /// **'{seconds} 秒后可重新发送'**
  String cloudResendWait(int seconds);

  /// No description provided for @cloudLoading.
  ///
  /// In zh, this message translates to:
  /// **'正在恢复登录…'**
  String get cloudLoading;

  /// No description provided for @cloudWorking.
  ///
  /// In zh, this message translates to:
  /// **'正在处理…'**
  String get cloudWorking;

  /// No description provided for @cloudAccount.
  ///
  /// In zh, this message translates to:
  /// **'账号'**
  String get cloudAccount;

  /// No description provided for @cloudSignedIn.
  ///
  /// In zh, this message translates to:
  /// **'已登录'**
  String get cloudSignedIn;

  /// No description provided for @cloudReload.
  ///
  /// In zh, this message translates to:
  /// **'更新账号信息'**
  String get cloudReload;

  /// No description provided for @cloudFreeAccount.
  ///
  /// In zh, this message translates to:
  /// **'免费账户'**
  String get cloudFreeAccount;

  /// No description provided for @cloudFreeAccountNote.
  ///
  /// In zh, this message translates to:
  /// **'在本机管理和使用全部配置。'**
  String get cloudFreeAccountNote;

  /// No description provided for @cloudSyncFreeAccountNote.
  ///
  /// In zh, this message translates to:
  /// **'配置保存在本机。有效订阅可启用云同步。'**
  String get cloudSyncFreeAccountNote;

  /// No description provided for @cloudSyncTitle.
  ///
  /// In zh, this message translates to:
  /// **'云同步'**
  String get cloudSyncTitle;

  /// No description provided for @cloudLastSync.
  ///
  /// In zh, this message translates to:
  /// **'上次同步'**
  String get cloudLastSync;

  /// No description provided for @cloudNeverSynced.
  ///
  /// In zh, this message translates to:
  /// **'从未同步'**
  String get cloudNeverSynced;

  /// No description provided for @cloudSyncNow.
  ///
  /// In zh, this message translates to:
  /// **'立即同步'**
  String get cloudSyncNow;

  /// No description provided for @cloudSyncing.
  ///
  /// In zh, this message translates to:
  /// **'正在同步…'**
  String get cloudSyncing;

  /// No description provided for @cloudSyncNoEntitlement.
  ///
  /// In zh, this message translates to:
  /// **'当前没有有效同步权益，请更新账号信息。'**
  String get cloudSyncNoEntitlement;

  /// No description provided for @cloudSyncDeviceLimit.
  ///
  /// In zh, this message translates to:
  /// **'同步设备名额已满，请先移除其他设备后重试。'**
  String get cloudSyncDeviceLimit;

  /// No description provided for @cloudSyncSchemaUnsupported.
  ///
  /// In zh, this message translates to:
  /// **'云端数据版本暂不受支持，请更新客户端后重试。'**
  String get cloudSyncSchemaUnsupported;

  /// No description provided for @cloudSyncQuotaExceeded.
  ///
  /// In zh, this message translates to:
  /// **'云端同步容量不足，请减少同步内容后重试。'**
  String get cloudSyncQuotaExceeded;

  /// No description provided for @cloudSyncValidation.
  ///
  /// In zh, this message translates to:
  /// **'部分本机内容不符合云端同步要求，请检查后重试。本机内容保留。'**
  String get cloudSyncValidation;

  /// No description provided for @cloudSyncOwnership.
  ///
  /// In zh, this message translates to:
  /// **'同步内容属于其他账号，请使用对应账号。本机内容保留。'**
  String get cloudSyncOwnership;

  /// No description provided for @cloudPendingMerge.
  ///
  /// In zh, this message translates to:
  /// **'保留 {count} 项待合并的本机修改'**
  String cloudPendingMerge(int count);

  /// No description provided for @cloudSyncLegacyUnverified.
  ///
  /// In zh, this message translates to:
  /// **'旧版同步资料来源待确认，上传和下载已暂停。本机内容保留。'**
  String get cloudSyncLegacyUnverified;

  /// No description provided for @cloudRebuildIncomplete.
  ///
  /// In zh, this message translates to:
  /// **'备份尚不完整，请继续重建。'**
  String get cloudRebuildIncomplete;

  /// No description provided for @cloudRebuildChanged.
  ///
  /// In zh, this message translates to:
  /// **'重建状态已变化，请更新账号信息后重试。'**
  String get cloudRebuildChanged;

  /// No description provided for @cloudBackupTitle.
  ///
  /// In zh, this message translates to:
  /// **'云端备份'**
  String get cloudBackupTitle;

  /// No description provided for @cloudBackupReady.
  ///
  /// In zh, this message translates to:
  /// **'完整备份已就绪'**
  String get cloudBackupReady;

  /// No description provided for @cloudBackupRebuildRequired.
  ///
  /// In zh, this message translates to:
  /// **'云端需要完整备份，请选择来源设备。'**
  String get cloudBackupRebuildRequired;

  /// No description provided for @cloudBackupRebuilding.
  ///
  /// In zh, this message translates to:
  /// **'正在重建云端备份，完成后发布。'**
  String get cloudBackupRebuilding;

  /// No description provided for @cloudBackupRetained.
  ///
  /// In zh, this message translates to:
  /// **'同步权益已到期，云端备份暂时保留。'**
  String get cloudBackupRetained;

  /// No description provided for @cloudBackupRetired.
  ///
  /// In zh, this message translates to:
  /// **'原云端备份已停止提供。'**
  String get cloudBackupRetired;

  /// No description provided for @cloudBackupNone.
  ///
  /// In zh, this message translates to:
  /// **'尚无云端备份'**
  String get cloudBackupNone;

  /// No description provided for @cloudBackupRetentionUntil.
  ///
  /// In zh, this message translates to:
  /// **'备份保留至：{time}'**
  String cloudBackupRetentionUntil(String time);

  /// No description provided for @cloudBackupLocalNote.
  ///
  /// In zh, this message translates to:
  /// **'本机配置与代理凭据保留，仍可编辑和使用。'**
  String get cloudBackupLocalNote;

  /// No description provided for @cloudSyncGenerationChanged.
  ///
  /// In zh, this message translates to:
  /// **'云端空间已更新，请重新获取状态后同步。本机内容保留。'**
  String get cloudSyncGenerationChanged;

  /// No description provided for @cloudSyncSnapshotChanged.
  ///
  /// In zh, this message translates to:
  /// **'完整下载期间云端内容发生变化，请重试。本机内容保留。'**
  String get cloudSyncSnapshotChanged;

  /// No description provided for @cloudSyncVerificationPending.
  ///
  /// In zh, this message translates to:
  /// **'同步权益待核实，上传和下载已暂停。'**
  String get cloudSyncVerificationPending;

  /// No description provided for @cloudRebuildStart.
  ///
  /// In zh, this message translates to:
  /// **'从此设备重建'**
  String get cloudRebuildStart;

  /// No description provided for @cloudRebuildStartTitle.
  ///
  /// In zh, this message translates to:
  /// **'从此设备重建云端备份？'**
  String get cloudRebuildStartTitle;

  /// No description provided for @cloudRebuildStartNote.
  ///
  /// In zh, this message translates to:
  /// **'完整备份仅包含此设备上该账号的当前可同步内容。请先核对其他设备上的待上传修改。其他设备在备份发布后恢复同步，本机内容保留。'**
  String get cloudRebuildStartNote;

  /// No description provided for @cloudRebuildClaim.
  ///
  /// In zh, this message translates to:
  /// **'由此设备接管重建'**
  String get cloudRebuildClaim;

  /// No description provided for @cloudRebuildClaimTitle.
  ///
  /// In zh, this message translates to:
  /// **'由此设备接管重建？'**
  String get cloudRebuildClaimTitle;

  /// No description provided for @cloudRebuildClaimNote.
  ///
  /// In zh, this message translates to:
  /// **'当前重建将停止，原尝试中尚未发布的内容将舍弃。新备份仅包含此设备上该账号的当前可同步内容。其他设备在完整备份发布后恢复同步，本机内容保留。'**
  String get cloudRebuildClaimNote;

  /// No description provided for @cloudRebuildCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消重建'**
  String get cloudRebuildCancel;

  /// No description provided for @cloudRebuildCancelTitle.
  ///
  /// In zh, this message translates to:
  /// **'取消本次重建？'**
  String get cloudRebuildCancelTitle;

  /// No description provided for @cloudRebuildCancelNote.
  ///
  /// In zh, this message translates to:
  /// **'结束本次重建，舍弃尚未发布的备份。再次重建时请选择来源设备。本机内容保留。'**
  String get cloudRebuildCancelNote;

  /// No description provided for @cloudRebuildResume.
  ///
  /// In zh, this message translates to:
  /// **'继续重建'**
  String get cloudRebuildResume;

  /// No description provided for @cloudRebuildThisDevice.
  ///
  /// In zh, this message translates to:
  /// **'此设备正在重建，完整备份发布后完成同步。'**
  String get cloudRebuildThisDevice;

  /// No description provided for @cloudRebuildWaiting.
  ///
  /// In zh, this message translates to:
  /// **'其他设备正在重建；等待完整备份发布。'**
  String get cloudRebuildWaiting;

  /// No description provided for @cloudRebuildProgress.
  ///
  /// In zh, this message translates to:
  /// **'已上传 {received} / {total} 条'**
  String cloudRebuildProgress(int received, int total);

  /// No description provided for @cloudCleanupOnline.
  ///
  /// In zh, this message translates to:
  /// **'历史云端内容清理：{status}'**
  String cloudCleanupOnline(String status);

  /// No description provided for @cloudCleanupKey.
  ///
  /// In zh, this message translates to:
  /// **'历史在线密钥状态：{status}'**
  String cloudCleanupKey(String status);

  /// No description provided for @cloudCleanupPending.
  ///
  /// In zh, this message translates to:
  /// **'待处理'**
  String get cloudCleanupPending;

  /// No description provided for @cloudCleanupRunning.
  ///
  /// In zh, this message translates to:
  /// **'正在处理'**
  String get cloudCleanupRunning;

  /// No description provided for @cloudCleanupFailed.
  ///
  /// In zh, this message translates to:
  /// **'处理未完成'**
  String get cloudCleanupFailed;

  /// No description provided for @cloudCleanupComplete.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get cloudCleanupComplete;

  /// No description provided for @cloudCleanupNone.
  ///
  /// In zh, this message translates to:
  /// **'尚无结果'**
  String get cloudCleanupNone;

  /// No description provided for @cloudCleanupWaiting.
  ///
  /// In zh, this message translates to:
  /// **'等待密钥清理确认'**
  String get cloudCleanupWaiting;

  /// No description provided for @cloudCleanupKeyDeleted.
  ///
  /// In zh, this message translates to:
  /// **'在线密钥已移除'**
  String get cloudCleanupKeyDeleted;

  /// No description provided for @cloudCleanupKeyDeletedNote.
  ///
  /// In zh, this message translates to:
  /// **'在线密钥已移除。灾备副本自原创建时间起最多保留 30 天。'**
  String get cloudCleanupKeyDeletedNote;

  /// No description provided for @cloudCleanupKeyDestroyed.
  ///
  /// In zh, this message translates to:
  /// **'旧密钥已停用'**
  String get cloudCleanupKeyDestroyed;

  /// No description provided for @cloudNetworkGuard.
  ///
  /// In zh, this message translates to:
  /// **'该云端内容包含当前宿主无法安全处理的网络路径，请使用兼容版本或本机节点。'**
  String get cloudNetworkGuard;

  /// No description provided for @cloudEntitlement.
  ///
  /// In zh, this message translates to:
  /// **'订阅权益'**
  String get cloudEntitlement;

  /// No description provided for @cloudMonthly.
  ///
  /// In zh, this message translates to:
  /// **'月付'**
  String get cloudMonthly;

  /// No description provided for @cloudYearly.
  ///
  /// In zh, this message translates to:
  /// **'年付'**
  String get cloudYearly;

  /// No description provided for @cloudEntitlementActive.
  ///
  /// In zh, this message translates to:
  /// **'有效'**
  String get cloudEntitlementActive;

  /// No description provided for @cloudEntitlementExpired.
  ///
  /// In zh, this message translates to:
  /// **'已到期'**
  String get cloudEntitlementExpired;

  /// No description provided for @cloudEntitlementRevoked.
  ///
  /// In zh, this message translates to:
  /// **'已撤销'**
  String get cloudEntitlementRevoked;

  /// No description provided for @cloudEntitlementUnknown.
  ///
  /// In zh, this message translates to:
  /// **'状态待确认'**
  String get cloudEntitlementUnknown;

  /// No description provided for @cloudEntitlementUntil.
  ///
  /// In zh, this message translates to:
  /// **'{status} · 到期日 {date}'**
  String cloudEntitlementUntil(String status, String date);

  /// No description provided for @cloudAppleSource.
  ///
  /// In zh, this message translates to:
  /// **'App Store'**
  String get cloudAppleSource;

  /// No description provided for @cloudGoogleSource.
  ///
  /// In zh, this message translates to:
  /// **'Google Play'**
  String get cloudGoogleSource;

  /// No description provided for @cloudWebSource.
  ///
  /// In zh, this message translates to:
  /// **'网页购买渠道'**
  String get cloudWebSource;

  /// No description provided for @cloudDevices.
  ///
  /// In zh, this message translates to:
  /// **'设备 · {count} / {limit}'**
  String cloudDevices(int count, int limit);

  /// No description provided for @cloudThisDevice.
  ///
  /// In zh, this message translates to:
  /// **'此设备'**
  String get cloudThisDevice;

  /// No description provided for @cloudNotSyncing.
  ///
  /// In zh, this message translates to:
  /// **'未同步'**
  String get cloudNotSyncing;

  /// No description provided for @cloudSyncSlotActive.
  ///
  /// In zh, this message translates to:
  /// **'占用同步名额'**
  String get cloudSyncSlotActive;

  /// No description provided for @cloudLastSeen.
  ///
  /// In zh, this message translates to:
  /// **'最近活动：{time}'**
  String cloudLastSeen(String time);

  /// No description provided for @cloudDeviceIos.
  ///
  /// In zh, this message translates to:
  /// **'iOS'**
  String get cloudDeviceIos;

  /// No description provided for @cloudDeviceAndroid.
  ///
  /// In zh, this message translates to:
  /// **'Android'**
  String get cloudDeviceAndroid;

  /// No description provided for @cloudDeviceMacos.
  ///
  /// In zh, this message translates to:
  /// **'macOS'**
  String get cloudDeviceMacos;

  /// No description provided for @cloudDeviceWindows.
  ///
  /// In zh, this message translates to:
  /// **'Windows'**
  String get cloudDeviceWindows;

  /// No description provided for @cloudDeviceLinux.
  ///
  /// In zh, this message translates to:
  /// **'Linux'**
  String get cloudDeviceLinux;

  /// No description provided for @cloudDeviceRemoveHint.
  ///
  /// In zh, this message translates to:
  /// **'左滑或右键移除其他设备。此设备请使用「退出登录」。'**
  String get cloudDeviceRemoveHint;

  /// No description provided for @cloudRemoveDevice.
  ///
  /// In zh, this message translates to:
  /// **'移除'**
  String get cloudRemoveDevice;

  /// No description provided for @cloudRemoveDeviceTitle.
  ///
  /// In zh, this message translates to:
  /// **'移除「{name}」？'**
  String cloudRemoveDeviceTitle(String name);

  /// No description provided for @cloudRemoveDeviceNote.
  ///
  /// In zh, this message translates to:
  /// **'该设备将退出登录并释放同步名额；设备上的本地内容保留。'**
  String get cloudRemoveDeviceNote;

  /// No description provided for @cloudLogout.
  ///
  /// In zh, this message translates to:
  /// **'退出登录'**
  String get cloudLogout;

  /// No description provided for @cloudLogoutTitle.
  ///
  /// In zh, this message translates to:
  /// **'退出 Avalon 账号？'**
  String get cloudLogoutTitle;

  /// No description provided for @cloudLogoutNote.
  ///
  /// In zh, this message translates to:
  /// **'本机的配置、节点和代理凭据全部保留。离线时会在联网后自动撤销原会话。'**
  String get cloudLogoutNote;

  /// No description provided for @cloudDeleteAccount.
  ///
  /// In zh, this message translates to:
  /// **'删除账号'**
  String get cloudDeleteAccount;

  /// No description provided for @cloudDeleteFirstTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除 Avalon 账号？'**
  String get cloudDeleteFirstTitle;

  /// No description provided for @cloudDeleteFirstNote.
  ///
  /// In zh, this message translates to:
  /// **'将删除账号和云端内容；本机配置和代理凭据全部保留。'**
  String get cloudDeleteFirstNote;

  /// No description provided for @cloudDeleteContinue.
  ///
  /// In zh, this message translates to:
  /// **'继续'**
  String get cloudDeleteContinue;

  /// No description provided for @cloudDeleteFinalTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认永久删除账号？'**
  String get cloudDeleteFinalTitle;

  /// No description provided for @cloudDeleteFinalNote.
  ///
  /// In zh, this message translates to:
  /// **'账号将永久删除。订阅及自动续费请前往原购买渠道另行取消。'**
  String get cloudDeleteFinalNote;

  /// No description provided for @cloudAccountDeleted.
  ///
  /// In zh, this message translates to:
  /// **'账号已删除，本机内容已保留。'**
  String get cloudAccountDeleted;

  /// No description provided for @cloudCancelSubscription.
  ///
  /// In zh, this message translates to:
  /// **'请前往 {sources} 取消订阅续费。'**
  String cloudCancelSubscription(String sources);

  /// No description provided for @cloudPendingRevocations.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个原会话等待撤销'**
  String cloudPendingRevocations(int count);

  /// No description provided for @cloudPendingRevocationsNote.
  ///
  /// In zh, this message translates to:
  /// **'本机已退出，联网后会自动重试撤销原会话。'**
  String get cloudPendingRevocationsNote;

  /// No description provided for @cloudRetryRevocations.
  ///
  /// In zh, this message translates to:
  /// **'立即重试撤销'**
  String get cloudRetryRevocations;

  /// No description provided for @cloudRevocationUnconfirmed.
  ///
  /// In zh, this message translates to:
  /// **'原会话凭据已失效，无法确认远端已撤销；本机仍保持退出。'**
  String get cloudRevocationUnconfirmed;

  /// No description provided for @cloudErrorDisabled.
  ///
  /// In zh, this message translates to:
  /// **'账号与同步入口已关闭，请返回本机功能。'**
  String get cloudErrorDisabled;

  /// No description provided for @cloudErrorInvalidEmail.
  ///
  /// In zh, this message translates to:
  /// **'请输入有效邮箱。'**
  String get cloudErrorInvalidEmail;

  /// No description provided for @cloudErrorInvalidCode.
  ///
  /// In zh, this message translates to:
  /// **'请输入六位数字验证码。'**
  String get cloudErrorInvalidCode;

  /// No description provided for @cloudErrorValidation.
  ///
  /// In zh, this message translates to:
  /// **'请求未被接受，请检查输入后重试。'**
  String get cloudErrorValidation;

  /// No description provided for @cloudErrorChallengeInvalid.
  ///
  /// In zh, this message translates to:
  /// **'验证码或登录请求无效，请检查验证码或重新发送。'**
  String get cloudErrorChallengeInvalid;

  /// No description provided for @cloudErrorChallengeExpired.
  ///
  /// In zh, this message translates to:
  /// **'验证码已过期，请重新发送。'**
  String get cloudErrorChallengeExpired;

  /// No description provided for @cloudErrorChallengeExhausted.
  ///
  /// In zh, this message translates to:
  /// **'验证码尝试次数已用尽，请重新发送。'**
  String get cloudErrorChallengeExhausted;

  /// No description provided for @cloudErrorChallengeEnded.
  ///
  /// In zh, this message translates to:
  /// **'登录请求已结束或不存在，请重新发送验证码。'**
  String get cloudErrorChallengeEnded;

  /// No description provided for @cloudErrorRateLimited.
  ///
  /// In zh, this message translates to:
  /// **'请求过于频繁，请稍后重试。'**
  String get cloudErrorRateLimited;

  /// No description provided for @cloudErrorRateLimitedWait.
  ///
  /// In zh, this message translates to:
  /// **'请求过于频繁，请在 {seconds} 秒后重试。'**
  String cloudErrorRateLimitedWait(int seconds);

  /// No description provided for @cloudErrorOffline.
  ///
  /// In zh, this message translates to:
  /// **'无法连接 Cloud，请检查网络后重试。本机功能仍可使用。'**
  String get cloudErrorOffline;

  /// No description provided for @cloudErrorTimeout.
  ///
  /// In zh, this message translates to:
  /// **'Cloud 没有及时响应，请稍后重试。'**
  String get cloudErrorTimeout;

  /// No description provided for @cloudErrorProtocol.
  ///
  /// In zh, this message translates to:
  /// **'Cloud 返回的数据无法读取，请更新应用或稍后重试。'**
  String get cloudErrorProtocol;

  /// No description provided for @cloudErrorReauthenticate.
  ///
  /// In zh, this message translates to:
  /// **'请重新登录，或退出原会话。本机内容保留。'**
  String get cloudErrorReauthenticate;

  /// No description provided for @cloudErrorSessionRevoked.
  ///
  /// In zh, this message translates to:
  /// **'登录已失效，请重新登录。'**
  String get cloudErrorSessionRevoked;

  /// No description provided for @cloudErrorDeviceNotFound.
  ///
  /// In zh, this message translates to:
  /// **'该设备已不存在，请更新账号信息。'**
  String get cloudErrorDeviceNotFound;

  /// No description provided for @cloudErrorCurrentDevice.
  ///
  /// In zh, this message translates to:
  /// **'移除此设备请使用「退出登录」。'**
  String get cloudErrorCurrentDevice;

  /// No description provided for @cloudErrorDeleteUnconfirmed.
  ///
  /// In zh, this message translates to:
  /// **'删除结果未能确认。请更新账号信息或重新登录核对，再决定是否重试。'**
  String get cloudErrorDeleteUnconfirmed;

  /// No description provided for @cloudErrorServer.
  ///
  /// In zh, this message translates to:
  /// **'Cloud 暂时无法完成请求，请稍后重试。'**
  String get cloudErrorServer;

  /// No description provided for @cloudErrorUnknown.
  ///
  /// In zh, this message translates to:
  /// **'操作未完成，请重试或重新登录。'**
  String get cloudErrorUnknown;

  /// No description provided for @cloudCodeExpires.
  ///
  /// In zh, this message translates to:
  /// **'验证码有效至 {time}'**
  String cloudCodeExpires(String time);

  /// No description provided for @tailnetTitle.
  ///
  /// In zh, this message translates to:
  /// **'Tailscale'**
  String get tailnetTitle;

  /// No description provided for @tailnetEnable.
  ///
  /// In zh, this message translates to:
  /// **'启用 Tailscale'**
  String get tailnetEnable;

  /// No description provided for @tailnetDisabled.
  ///
  /// In zh, this message translates to:
  /// **'未启用'**
  String get tailnetDisabled;

  /// No description provided for @tailnetNeedsLogin.
  ///
  /// In zh, this message translates to:
  /// **'需要登录'**
  String get tailnetNeedsLogin;

  /// No description provided for @tailnetConnected.
  ///
  /// In zh, this message translates to:
  /// **'已连接 · {tailnet}'**
  String tailnetConnected(String tailnet);

  /// No description provided for @tailnetOffline.
  ///
  /// In zh, this message translates to:
  /// **'离线'**
  String get tailnetOffline;

  /// No description provided for @tailnetThisDevice.
  ///
  /// In zh, this message translates to:
  /// **'本机'**
  String get tailnetThisDevice;

  /// No description provided for @tailnetHostname.
  ///
  /// In zh, this message translates to:
  /// **'设备名称'**
  String get tailnetHostname;

  /// No description provided for @tailnetAddresses.
  ///
  /// In zh, this message translates to:
  /// **'IP 地址'**
  String get tailnetAddresses;

  /// No description provided for @tailnetNetwork.
  ///
  /// In zh, this message translates to:
  /// **'Tailnet'**
  String get tailnetNetwork;

  /// No description provided for @tailnetExitNodes.
  ///
  /// In zh, this message translates to:
  /// **'出口节点'**
  String get tailnetExitNodes;

  /// No description provided for @tailnetNoExit.
  ///
  /// In zh, this message translates to:
  /// **'无'**
  String get tailnetNoExit;

  /// No description provided for @tailnetNoExitNote.
  ///
  /// In zh, this message translates to:
  /// **'互联网流量使用当前网络与代理设置。'**
  String get tailnetNoExitNote;

  /// No description provided for @tailnetExitOffline.
  ///
  /// In zh, this message translates to:
  /// **'该出口节点离线，无法连接。'**
  String get tailnetExitOffline;

  /// No description provided for @tailnetAcceptRoutes.
  ///
  /// In zh, this message translates to:
  /// **'接受子网路由'**
  String get tailnetAcceptRoutes;

  /// No description provided for @tailnetAcceptRoutesNote.
  ///
  /// In zh, this message translates to:
  /// **'访问 Tailnet 中设备发布的子网。'**
  String get tailnetAcceptRoutesNote;

  /// No description provided for @tailnetMagicDns.
  ///
  /// In zh, this message translates to:
  /// **'MagicDNS'**
  String get tailnetMagicDns;

  /// No description provided for @tailnetMagicDnsNote.
  ///
  /// In zh, this message translates to:
  /// **'通过 Tailnet 设备名称访问设备。'**
  String get tailnetMagicDnsNote;

  /// No description provided for @tailnetAdvertiseExit.
  ///
  /// In zh, this message translates to:
  /// **'将本机作为出口节点'**
  String get tailnetAdvertiseExit;

  /// No description provided for @tailnetAdvertiseExitNote.
  ///
  /// In zh, this message translates to:
  /// **'允许 Tailnet 中的其他设备通过本机访问互联网。'**
  String get tailnetAdvertiseExitNote;

  /// No description provided for @tailnetLogout.
  ///
  /// In zh, this message translates to:
  /// **'退出 Tailnet'**
  String get tailnetLogout;

  /// No description provided for @tailnetLogin.
  ///
  /// In zh, this message translates to:
  /// **'登录 Tailscale'**
  String get tailnetLogin;

  /// No description provided for @tailnetUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'当前宿主无法运行 Tailscale。'**
  String get tailnetUnavailable;

  /// No description provided for @tailnetError.
  ///
  /// In zh, this message translates to:
  /// **'连接失败：{message}'**
  String tailnetError(String message);

  /// No description provided for @tailnetBrowserFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法打开登录页面，请检查浏览器设置后重试。'**
  String get tailnetBrowserFailed;

  /// No description provided for @tailnetDevicesOnline.
  ///
  /// In zh, this message translates to:
  /// **'在线设备 · {count}'**
  String tailnetDevicesOnline(int count);

  /// No description provided for @tailnetOnline.
  ///
  /// In zh, this message translates to:
  /// **'在线'**
  String get tailnetOnline;

  /// No description provided for @tailnetOptions.
  ///
  /// In zh, this message translates to:
  /// **'选项'**
  String get tailnetOptions;

  /// No description provided for @tailnetFixedRoutesNote.
  ///
  /// In zh, this message translates to:
  /// **'通过 Tailscale 地址和设备名称访问 Tailnet 设备。'**
  String get tailnetFixedRoutesNote;

  /// No description provided for @tailnetExitUseNote.
  ///
  /// In zh, this message translates to:
  /// **'已选择的出口也可在自定义组中使用。'**
  String get tailnetExitUseNote;

  /// No description provided for @tailnetExitConflict.
  ///
  /// In zh, this message translates to:
  /// **'请在使用其他出口和将本机作为出口之间选择一项。'**
  String get tailnetExitConflict;

  /// No description provided for @tailnetWaiting.
  ///
  /// In zh, this message translates to:
  /// **'等待登录…'**
  String get tailnetWaiting;

  /// No description provided for @tailnetPermissionRefused.
  ///
  /// In zh, this message translates to:
  /// **'需要系统网络授权才能启用 Tailscale。'**
  String get tailnetPermissionRefused;

  /// No description provided for @aboutCheckUpdates.
  ///
  /// In zh, this message translates to:
  /// **'检查更新'**
  String get aboutCheckUpdates;

  /// No description provided for @aboutCheckingUpdates.
  ///
  /// In zh, this message translates to:
  /// **'检查中…'**
  String get aboutCheckingUpdates;

  /// No description provided for @aboutUpdateAvailable.
  ///
  /// In zh, this message translates to:
  /// **'新版本 {version}'**
  String aboutUpdateAvailable(String version);

  /// No description provided for @aboutUpToDate.
  ///
  /// In zh, this message translates to:
  /// **'已是最新版本'**
  String get aboutUpToDate;

  /// No description provided for @aboutNoRelease.
  ///
  /// In zh, this message translates to:
  /// **'暂无兼容版本发布'**
  String get aboutNoRelease;

  /// No description provided for @aboutSource.
  ///
  /// In zh, this message translates to:
  /// **'GitHub 源代码'**
  String get aboutSource;

  /// No description provided for @aboutChangelog.
  ///
  /// In zh, this message translates to:
  /// **'更新日志'**
  String get aboutChangelog;

  /// No description provided for @aboutPrivacy.
  ///
  /// In zh, this message translates to:
  /// **'隐私政策'**
  String get aboutPrivacy;

  /// No description provided for @aboutUpdateFailed.
  ///
  /// In zh, this message translates to:
  /// **'检查更新失败，请检查网络后重试。'**
  String get aboutUpdateFailed;

  /// No description provided for @aboutBrowserFailed.
  ///
  /// In zh, this message translates to:
  /// **'无法打开网页，请检查浏览器设置。'**
  String get aboutBrowserFailed;

  /// No description provided for @tailnetExitNotReady.
  ///
  /// In zh, this message translates to:
  /// **'出口节点功能待开放。当前可访问 Tailnet 内的设备。'**
  String get tailnetExitNotReady;

  /// No description provided for @tailnetAdvertiseNotReady.
  ///
  /// In zh, this message translates to:
  /// **'本机出口功能待开放。'**
  String get tailnetAdvertiseNotReady;

  /// No description provided for @systemProxyFailed.
  ///
  /// In zh, this message translates to:
  /// **'系统代理设置或恢复失败，请检查系统权限后重试。'**
  String get systemProxyFailed;

  /// No description provided for @manageSelfContent.
  ///
  /// In zh, this message translates to:
  /// **'管理'**
  String get manageSelfContent;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
