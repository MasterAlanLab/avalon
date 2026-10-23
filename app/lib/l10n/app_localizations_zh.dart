// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get tabDashboard => '仪表盘';

  @override
  String get tabProxies => '代理';

  @override
  String get tabConfigurations => '配置';

  @override
  String get tabTools => '工具';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get add => '添加';

  @override
  String get edit => '编辑';

  @override
  String get delete => '删除';

  @override
  String get done => '完成';

  @override
  String get retry => '重试';

  @override
  String get justNow => '刚刚';

  @override
  String minutesAgo(int n) {
    return '$n 分钟前';
  }

  @override
  String hoursAgo(int n) {
    return '$n 小时前';
  }

  @override
  String daysAgo(int n) {
    return '$n 天前';
  }

  @override
  String get configurationsTitle => '配置';

  @override
  String get refreshAll => '全部更新';

  @override
  String get selfConfigurationName => '自建节点';

  @override
  String get sourceSubscription => '订阅';

  @override
  String get sourceFile => '本地文件';

  @override
  String sourceLocal(int chains) {
    return '本地 · $chains 条代理链';
  }

  @override
  String nodeCount(int n) {
    return '$n 个节点';
  }

  @override
  String updatedAt(String when) {
    return '$when更新';
  }

  @override
  String get notDownloaded => '尚未下载';

  @override
  String expiresOn(String date) {
    return '$date 到期';
  }

  @override
  String lastSuccess(String when) {
    return '上次成功：$when';
  }

  @override
  String get configurationsEmpty => '添加订阅链接、配置文件或独立节点即可开始。';

  @override
  String deleteConfigurationTitle(String name) {
    return '删除「$name」？';
  }

  @override
  String get deleteConfigurationBody =>
      '该配置的选择记录和加入其中的节点会一并移除，引用其节点的代理链将显示「不可用」。';

  @override
  String get addTitle => '添加';

  @override
  String get addSegmentSubscription => '订阅';

  @override
  String get addSegmentNode => '独立节点';

  @override
  String get addSegmentChain => '代理链';

  @override
  String get subscriptionUrl => '订阅链接';

  @override
  String get subscriptionUrlHint => 'https://… 支持 sing-box / Clash 订阅';

  @override
  String get name => '名称';

  @override
  String get nameAuto => '自动读取';

  @override
  String get scanQr => '扫描二维码';

  @override
  String get importFile => '从文件导入';

  @override
  String get dropFileHint => '或拖入配置文件 .json（sing-box）/ .yaml（Clash）';

  @override
  String get autoUpdate => '自动更新';

  @override
  String get localOnlyNote => '保存在本机。';

  @override
  String get defaultSubscriptionName => '新订阅';

  @override
  String get comingSoon => '该功能将在后续版本提供。';

  @override
  String get coreNotConnected => '内核未接入';

  @override
  String get coreNotConnectedNote => '连接、测速与实时数据将在接入内核后可用。';

  @override
  String get currentConfiguration => '当前配置';

  @override
  String get noConfigurationSelected => '未选择配置';

  @override
  String get errorInvalidUrl => '链接无效，请填写 http:// 或 https:// 开头的订阅链接。';

  @override
  String get errorBlockedAddress => '内容指向了本机或局域网地址，已阻止。';

  @override
  String get errorTimeout => '连接超时，请检查网络后重试。';

  @override
  String get errorTooLarge => '内容超过 16 MiB 上限。';

  @override
  String get errorTooManyRedirects => '重定向次数过多。';

  @override
  String errorHttpStatus(int status) {
    return '服务器返回错误（HTTP $status）。';
  }

  @override
  String get errorTls => '安全连接失败，证书无效或握手失败。';

  @override
  String get errorNetwork => '网络错误，无法连接服务器。';

  @override
  String get errorUnknownFormat =>
      '无法识别内容格式：支持 sing-box JSON、Clash YAML 与分享链接列表。';

  @override
  String get errorMalformed => '内容格式错误。';

  @override
  String errorUnknownParameter(String field) {
    return '不支持的参数：$field。';
  }

  @override
  String errorUnsupportedValue(String field) {
    return '不支持的取值：$field。';
  }

  @override
  String errorMissingField(String field) {
    return '缺少必填项：$field。';
  }

  @override
  String errorInvalidField(String field) {
    return '字段无效：$field。';
  }

  @override
  String errorTooLargeContent(String field) {
    return '内容超出上限（$field）。';
  }

  @override
  String get errorUnsupportedScheme => '无法识别的分享链接协议。';

  @override
  String get errorVaultLocked => '本机安全存储已重置，请重新输入凭据或从备份恢复。';

  @override
  String get errorUnknown => '操作失败，请重试。';

  @override
  String get savedWithWarnings => '已保存，部分内容未导入：';

  @override
  String warnUnsupportedNodeType(int count, String subject) {
    return '跳过 $count 个 $subject 节点：Avalon 不支持该协议';
  }

  @override
  String warnUnsupportedNodeOption(int count, String subject) {
    return '跳过 $count 个节点：不支持选项 $subject';
  }

  @override
  String warnIgnoredNodeOption(int count, String subject) {
    return '$count 个节点的选项 $subject 未生效';
  }

  @override
  String warnUnreadableEntry(int count, String subject) {
    return '跳过 $count 项无法读取的内容（$subject）';
  }

  @override
  String warnUnsupportedGroupType(String subject) {
    return '跳过 $subject 类型的组';
  }

  @override
  String warnUnsupportedRule(int count, String subject) {
    return '跳过 $count 条 $subject 规则';
  }

  @override
  String warnUnsupportedRuleSet(String subject) {
    return '规则集 $subject 无法使用，相关规则已跳过';
  }

  @override
  String warnInsecureTls(int count) {
    return '$count 个节点关闭了证书验证';
  }

  @override
  String get warnMissingFinal => '未指定兜底规则，未匹配的流量将直连';

  @override
  String warnDroppedMember(String subject) {
    return '组成员 $subject 不存在或已跳过';
  }

  @override
  String get databaseTooNew => '请更新 Avalon';

  @override
  String get databaseTooNewNote => '本机数据来自更新版本的 Avalon，请更新应用后打开。';

  @override
  String get startupFailed => '无法打开本机数据';

  @override
  String get ok => '好';

  @override
  String get modeRule => '规则';

  @override
  String get modeGlobal => '全局';

  @override
  String get modeDirect => '直连';

  @override
  String get statusConnected => '已连接';

  @override
  String get statusDisconnected => '未连接';

  @override
  String get addConfigurationTitle => '添加配置';

  @override
  String get addPrompt => '添加订阅、独立节点或代理链';

  @override
  String get nodeCountUnknown => '— 个节点';

  @override
  String usedOnly(String used) {
    return '已用 $used';
  }

  @override
  String refreshFailed(String reason) {
    return '更新失败：$reason';
  }

  @override
  String get autoUpdateSubtitle => '每 12 小时自动更新';

  @override
  String get testLatency => '测速';

  @override
  String get directModeNote => '直连模式下直接访问目标地址';

  @override
  String groupSummary(String type, int n) {
    return '$type · $n 个节点';
  }

  @override
  String groupCurrent(String name) {
    return '当前 $name';
  }

  @override
  String get customGroup => '自定义';

  @override
  String get autoGroupNote => '此组按延迟自动选择';

  @override
  String get unavailable => '不可用';

  @override
  String memberChain(int n) {
    return '代理链 · $n 跳';
  }

  @override
  String memberGroup(String type) {
    return '$type 组';
  }

  @override
  String get memberDirect => '直连';

  @override
  String get memberReject => '拒绝';

  @override
  String get noConfigurationSelectedNote => '在「配置」中添加或选择一个配置后，这里会显示它的代理组。';

  @override
  String get goToConfigurations => '前往配置';

  @override
  String get customEmpty => '添加独立节点或代理链，管理自建连接。';

  @override
  String get contentNotDownloaded => '订阅尚未下载';

  @override
  String get pasteLinkHint => '粘贴 vless:// vmess:// hy2:// …';

  @override
  String get pasteLinkHintDesktop => '粘贴 vless:// vmess:// ss:// hy2:// 分享链接';

  @override
  String get parse => '解析';

  @override
  String get protocol => '协议';

  @override
  String get sectionServer => '服务器';

  @override
  String get sectionTransport => '传输方式';

  @override
  String get sectionSecurity => '传输层安全';

  @override
  String get securityNone => '无';

  @override
  String get nodeNameHint => '东京 VPS';

  @override
  String get fieldServer => '地址';

  @override
  String get fieldPort => '端口';

  @override
  String get fieldPassword => '密码';

  @override
  String get fieldObfsPassword => '混淆密码';

  @override
  String get fieldUsername => '用户名';

  @override
  String get fieldUpMbps => '上行 Mbps';

  @override
  String get fieldDownMbps => '下行 Mbps';

  @override
  String get fieldCongestion => '拥塞控制';

  @override
  String get fieldMethod => '加密';

  @override
  String get fieldIdleCheck => '空闲会话检查';

  @override
  String get fieldPath => '路径';

  @override
  String get fieldPublicKey => '公钥';

  @override
  String get fieldRequiredHint => '必填';

  @override
  String get fieldOptionalHint => '可选';

  @override
  String get nodeSavedNote => '保存到「自建节点」。';

  @override
  String fieldRequired(String field) {
    return '请填写$field。';
  }

  @override
  String fieldInvalid(String field) {
    return '$field格式不正确。';
  }

  @override
  String fieldUnsupported(String field) {
    return '不支持的$field取值。';
  }

  @override
  String get chainNameHint => '默认用节点名拼接';

  @override
  String get sectionChain => '链路';

  @override
  String get sectionChainDesktop => '链路 · 本机 → … → 目标网站';

  @override
  String chainSummary(int n, String latency) {
    return '$n 跳 · $latency';
  }

  @override
  String chainLatencyEstimate(int ms) {
    return '≈ $ms ms';
  }

  @override
  String get hopLocal => '本机';

  @override
  String get hopTarget => '目标网站';

  @override
  String get addHop => '添加一跳';

  @override
  String get roleEntry => '入口';

  @override
  String get roleRelay => '中转';

  @override
  String get roleExit => '出口';

  @override
  String get chainNote => '流量依次经过每一跳，最后一跳为出口，可组合不同协议。';

  @override
  String get sectionJoinGroups => '加入代理组';

  @override
  String get chainTooShort => '代理链至少需要 2 跳';

  @override
  String get noHopCandidates => '先添加订阅或独立节点，再选择代理链中的节点。';

  @override
  String get editTitle => '编辑';

  @override
  String get savedSecretHint => '已保存';

  @override
  String get errorEditConflict => '内容已在其他设备或窗口修改，已重新载入，请再检查一遍。';

  @override
  String get errorNotFound => '该项目已不存在。';

  @override
  String deleteItemTitle(String name) {
    return '删除「$name」？';
  }

  @override
  String get deleteNodeBody => '节点会从它加入的所有代理组中移除。';

  @override
  String get deleteChainBody => '代理链会从它加入的所有代理组中移除，链上的节点保留。';

  @override
  String get nodeInUseTitle => '无法删除';

  @override
  String nodeInUseBody(String name, String chains) {
    return '「$name」正被以下代理链使用，请先修改或删除它们：$chains';
  }

  @override
  String get sectionView => '查看';

  @override
  String get sectionSettings => '设置';

  @override
  String get sectionOther => '其他';

  @override
  String get toolConnections => '连接';

  @override
  String get toolLogs => '日志';

  @override
  String get toolLoginSync => '登录与同步';

  @override
  String get toolBasic => '基础设置';

  @override
  String get toolAdvanced => '高级设置';

  @override
  String get toolApps => '分应用代理';

  @override
  String get toolGeo => 'GEO 规则集';

  @override
  String get toolAbout => '关于 Avalon';

  @override
  String get toolAboutShort => '关于';

  @override
  String get sectionGeneral => '通用';

  @override
  String get language => '语言';

  @override
  String get languageZh => '简体中文';

  @override
  String get appearance => '外观';

  @override
  String get appearanceLight => '浅色';

  @override
  String get appearanceDark => '深色';

  @override
  String get sectionStartup => '启动';

  @override
  String get launchAtStartup => '开机自动启动';

  @override
  String get launchAtStartupNoteAndroid => 'Android 开机后在后台运行';

  @override
  String get launchAtStartupNoteDesktop => '登录系统后自动运行 Avalon';

  @override
  String get launchAtStartupFailed => '登录启动设置失败，请重新切换此开关重试。';

  @override
  String get launchAtStartupNeedsApproval => '请在系统设置 → 通用 → 登录项中允许 Avalon。';

  @override
  String get launchAtStartupNoteIos => '在系统设置中开启 VPN「按需连接」。';

  @override
  String get silentStart => '静默启动';

  @override
  String silentStartNote(String tray) {
    return '启动后收起主窗口，在$tray显示图标';
  }

  @override
  String get trayMenuBar => '菜单栏';

  @override
  String get traySystemTray => '系统托盘';

  @override
  String get autoConnect => '启动后自动连接';

  @override
  String get autoConnectNote => '打开应用时自动启动代理';

  @override
  String keepOnClose(String tray) {
    return '关闭窗口时保留在$tray';
  }

  @override
  String get sectionProxy => '代理';

  @override
  String get systemProxy => '系统代理';

  @override
  String get systemProxyNoteMac => '设置 macOS 网络代理';

  @override
  String get systemProxyNoteWindows => '设置 Windows 系统代理（WinINet）';

  @override
  String get systemProxyNoteLinux => '写入 GNOME / KDE 代理设置';

  @override
  String get systemProxyNeedsTun => '需要先启用 TUN';

  @override
  String get allowLan => '允许局域网连接';

  @override
  String get allowLanNote => '其他设备可连接本机代理端口';

  @override
  String get mixedPort => '混合端口';

  @override
  String get sectionHotkeys => '快捷键';

  @override
  String get hotkeyToggle => '启动 / 停止代理';

  @override
  String get hotkeyMode => '切换出站模式';

  @override
  String get hotkeyShow => '显示主窗口';

  @override
  String get hotkeyTaken => '已被占用';

  @override
  String get hotkeyUnsupported => '暂不支持';

  @override
  String get trayStart => '启动代理';

  @override
  String get trayStop => '停止代理';

  @override
  String get trayMode => '出站模式';

  @override
  String get trayQuit => '退出 Avalon';

  @override
  String get sectionNotification => '通知';

  @override
  String get speedNotification => '通知栏显示实时速度';

  @override
  String get sectionLatency => '延迟测试';

  @override
  String get testUrl => '测速地址';

  @override
  String get testTimeout => '超时';

  @override
  String milliseconds(int n) {
    return '$n ms';
  }

  @override
  String get sectionData => '数据';

  @override
  String get exportBackup => '导出备份…';

  @override
  String get restoreBackup => '从文件恢复…';

  @override
  String get backupNote => '备份包含订阅、自建节点、代理链和全部设置。';

  @override
  String get sectionTun => '虚拟网卡 TUN';

  @override
  String get tunEnabled => '启用 TUN';

  @override
  String get tunNote => '接管设备全部流量';

  @override
  String get tunNoteMac => 'utun · 需要授权网络扩展';

  @override
  String get tunNoteWindows => 'WinTUN · 需要管理员权限';

  @override
  String get tunNoteLinux => 'tun0 · 需要 CAP_NET_ADMIN';

  @override
  String get tunStack => '协议栈';

  @override
  String get autoRoute => '自动路由';

  @override
  String get strictRoute => '严格路由';

  @override
  String get strictRouteNote => '严格执行隧道路由规则';

  @override
  String get remoteDns => '远程 DNS';

  @override
  String get directDns => '直连 DNS';

  @override
  String get dnsStrategy => '解析策略';

  @override
  String get dnsPreferIpv4 => '优先 IPv4';

  @override
  String get dnsIpv4Only => '仅 IPv4';

  @override
  String get dnsPreferIpv6 => '优先 IPv6';

  @override
  String get dnsIpv6OffNote => 'IPv6 已关闭，解析按「仅 IPv4」生效。';

  @override
  String get sectionRouting => '路由';

  @override
  String get sniff => '流量嗅探';

  @override
  String get sniffNote => '识别 TLS / HTTP / QUIC 域名';

  @override
  String get bypassLan => '绕过局域网与保留地址';

  @override
  String get findProcess => '查找进程';

  @override
  String get findProcessNote => '用于分应用代理和连接页显示应用';

  @override
  String get findProcessNoteDesktop => '用于分应用代理和连接页显示程序';

  @override
  String get clashApi => '外部控制器';

  @override
  String get clashApiNote => '供 Web 面板或第三方客户端控制';

  @override
  String get clashListen => '监听地址';

  @override
  String get clashListenRisk => '同一网络中的其他设备可通过此监听地址控制代理。';

  @override
  String get clashSecret => '密钥';

  @override
  String get secretView => '查看';

  @override
  String get secretCopy => '复制';

  @override
  String get secretRegenerate => '重新生成';

  @override
  String get secretRegenerateConfirm => '重新生成后，使用旧密钥的面板和客户端需要改用新密钥。';

  @override
  String get copied => '已复制';

  @override
  String get webPanel => 'Web 面板';

  @override
  String get openWebPanel => '打开 metacubexd';

  @override
  String get webPanelNotRunning => '代理尚未运行，请先连接后再打开 Web 面板。';

  @override
  String get webPanelControllerOff => '运行中的外部控制器已关闭，请在高级设置中启用并生效后再打开 Web 面板。';

  @override
  String get webPanelStateUnknown => '暂时无法读取外部控制器当前状态，请检查代理连接后重试。';

  @override
  String get webPanelBrowserFailed => '系统浏览器未能打开 Web 面板，请检查浏览器后重试。';

  @override
  String get sectionCore => '内核';

  @override
  String get logLevel => '日志等级';

  @override
  String get configOverride => '配置覆写';

  @override
  String get editJson => '编辑 JSON…';

  @override
  String get viewGeneratedConfig => '查看生成的配置';

  @override
  String get generatedConfig => '生成的配置';

  @override
  String get viewAction => '查看…';

  @override
  String get overrideNote => '配置覆写会合并到每个订阅生成的 sing-box 配置中，适合自定义路由规则或出站。';

  @override
  String get resetDefaults => '恢复默认设置';

  @override
  String get resetDefaultsConfirm => '恢复本页所有设置为默认值？配置覆写和 Clash API 密钥会保留。';

  @override
  String get reset => '恢复';

  @override
  String get settingInvalid => '格式不正确。';

  @override
  String settingOutOfRange(int min, int max) {
    return '请输入 $min–$max 之间的数字。';
  }

  @override
  String get remoteDnsHint => '以 https:// 或 tls:// 开头';

  @override
  String get directDnsHint => 'IP 地址，或以 udp:// 开头';

  @override
  String get testUrlHint => '以 http:// 或 https:// 开头';

  @override
  String get clashListenHint => '地址:端口，如 127.0.0.1:9090';

  @override
  String get aboutVersion => '版本';

  @override
  String get aboutCore => '内核';

  @override
  String get aboutLicense => '许可证';

  @override
  String get aboutThanks => '致谢 sing-box 与开源社区';

  @override
  String get overrideKeysNote =>
      '支持 outbounds、route.rules、route.rule_set、route.final、dns.servers、dns.rules。引用节点或代理组时使用显示名称。覆写应用于导入的配置。';

  @override
  String overrideSyntax(int line, int column) {
    return 'JSON 语法错误：第 $line 行第 $column 列。';
  }

  @override
  String get overrideNotObject => '最外层应为一个 JSON 对象。';

  @override
  String overrideNotAllowed(String path) {
    return '不允许的键：$path';
  }

  @override
  String overrideWrongType(String path, String type) {
    return '$path 的类型不对，应为$type。';
  }

  @override
  String get jsonObject => '对象';

  @override
  String get jsonArray => '数组';

  @override
  String get jsonString => '字符串';

  @override
  String get jsonTaggedObject => '带 tag 的对象';

  @override
  String overrideReference(String name, String path) {
    return '找不到名为「$name」的节点或代理组（$path）。';
  }

  @override
  String overrideConflict(String name, String path) {
    return '标签「$name」与生成的配置冲突（$path），请换一个名称。';
  }

  @override
  String get compileNothingSelected => '请先在「配置」中选择一个配置。';

  @override
  String compileMemberUnavailable(String name) {
    return '「$name」不可用，无法生成配置。';
  }

  @override
  String compileEmptyGroup(String name) {
    return '代理组「$name」没有可用的成员。';
  }

  @override
  String compileRuleSetMissing(String name) {
    return '规则集「$name」尚未下载或无法使用。';
  }

  @override
  String get compilePerAppNeedsFindProcess => '分应用代理需要开启「查找进程」。';

  @override
  String compileInvalidSetting(String name) {
    return '设置项无效：$name。';
  }

  @override
  String get generatedNote => '秘密已替换为 ••••。这是按当前选中的配置和设置生成的内容。';

  @override
  String get copyAll => '复制';

  @override
  String get backupPassword => '备份密码';

  @override
  String get backupPasswordNote => '密码至少 8 位，请妥善保管，恢复备份时使用。';

  @override
  String get passwordHint => '密码';

  @override
  String get passwordAgainHint => '再次输入密码';

  @override
  String get passwordTooShort => '密码至少需要 8 位。';

  @override
  String get passwordMismatch => '两次输入的密码不一致。';

  @override
  String get backupEncrypting => '正在加密备份…';

  @override
  String get backupExported => '备份已导出';

  @override
  String get restorePassword => '输入备份密码';

  @override
  String get restoreConfirmTitle => '从备份恢复？';

  @override
  String get restoreConfirmBody => '恢复会覆盖同名设置和相同对象，本机其他内容保留。';

  @override
  String get restoring => '正在恢复…';

  @override
  String get restoreDoneTitle => '恢复完成';

  @override
  String restoreDoneBody(int configs, int nodes, int chains) {
    return '已恢复 $configs 个配置、$nodes 个自建节点、$chains 条代理链，以及全部设置。';
  }

  @override
  String get backupWrongPassword => '密码错误，或文件已损坏。';

  @override
  String get backupNotABackup => '这不是 Avalon 备份文件。';

  @override
  String get backupUnsupportedVersion => '此备份来自更新版本的 Avalon，请先更新应用。';

  @override
  String get backupTooLarge => '文件超出备份的大小上限。';

  @override
  String get backupMalformed => '备份内容无法识别。';

  @override
  String get exportBackupAction => '导出';

  @override
  String get fileChoose => '选择 .json 或 .yaml';

  @override
  String get fileChooseNote => 'sing-box 配置或 Clash 配置';

  @override
  String get dropFile => '或拖入配置文件';

  @override
  String get dropFileNote => '.json（sing-box）/ .yaml（Clash）';

  @override
  String get fileReplace => '点击更换';

  @override
  String get fileImportNote => '将文件内容保存为本机配置。';

  @override
  String get scanPrompt => '将订阅二维码放入框内';

  @override
  String get scanDenied => '需要相机权限才能扫码。可在系统设置中允许 Avalon 使用相机，或直接粘贴订阅链接。';

  @override
  String get scanUnavailable => '此设备上的相机不可用，请直接粘贴订阅链接。';

  @override
  String get scanNotSubscription => '二维码内容不是订阅链接（需以 http:// 或 https:// 开头）。';

  @override
  String get scanned => '已识别订阅链接';

  @override
  String get networkSpeed => '网络速度';

  @override
  String get todayUpload => '今日上传';

  @override
  String get todayDownload => '下载';

  @override
  String get todayTraffic => '今日流量';

  @override
  String get currentNode => '当前节点';

  @override
  String get exitIp => '出口 IP';

  @override
  String get modeRuleFull => '规则模式';

  @override
  String get modeGlobalFull => '全局模式';

  @override
  String get modeDirectFull => '直连模式';

  @override
  String get addConfigurationFirst => '请先添加配置';

  @override
  String aboutVersionLine(String version) {
    return '版本 $version';
  }

  @override
  String get keyStorage => '安全存储';

  @override
  String get keyStorageFile => '本机文件（权限 0600）';

  @override
  String get licensesTitle => '许可与第三方声明';

  @override
  String licenseCount(int n) {
    return '$n 份许可';
  }

  @override
  String get licensesNote => 'Avalon 以 AGPL-3.0 发布。以下是随应用分发的开源组件及其许可。';

  @override
  String get search => '搜索';

  @override
  String get turnOn => '开启';

  @override
  String get perAppWhitelist => '白名单';

  @override
  String get perAppBlacklist => '黑名单';

  @override
  String get appsHintEmpty => '未选择应用时，全部应用按规则代理。';

  @override
  String get appsHintWhitelist => '仅开启的应用走代理，其余直连。';

  @override
  String get appsHintBlacklist => '开启的应用直连，其余走代理。';

  @override
  String get appsHintWhitelistDesktop => '仅开启的程序走代理，其余直连。';

  @override
  String get appsHintBlacklistDesktop => '开启的程序直连，其余走代理。';

  @override
  String get appNotInstalled => '未安装';

  @override
  String get addProgram => '添加程序';

  @override
  String get appsListFailed => '无法读取应用列表';

  @override
  String get appsListFailedNote => '下面只显示已保存的名单。';

  @override
  String get appsNoMatch => '没有匹配的应用';

  @override
  String get appsNoMatchDesktop => '没有匹配的程序';

  @override
  String get appsNoPrograms => '还没有程序。点「添加程序」选择要单独处理的程序。';

  @override
  String get appsNeedFindProcessNote => '开启「查找进程」，按程序应用代理规则。';

  @override
  String rulesCount(int n) {
    return '$n 个规则集';
  }

  @override
  String get rulesAutoDaily => '每天自动更新';

  @override
  String get rulesAutoWeekly => '每周自动更新';

  @override
  String get rulesAutoOff => '自动更新已关闭';

  @override
  String get rulesUpdating => '更新中';

  @override
  String get sectionRuleSets => '规则集';

  @override
  String get sectionUpdateSettings => '更新设置';

  @override
  String get geoInterval => '更新间隔';

  @override
  String get geoDaily => '每天';

  @override
  String get geoWeekly => '每周';

  @override
  String get geoVia => '下载方式';

  @override
  String get geoViaProxy => '经代理';

  @override
  String get geoViaDirect => '直连';

  @override
  String get rulesNote => '管理和更新 GeoSite、GeoIP 及订阅引用的规则集。';

  @override
  String get ruleKindSet => '规则集';

  @override
  String get ruleNotDownloaded => '未下载';

  @override
  String ruleUpdatedAgo(String when) {
    return '$when更新';
  }

  @override
  String get ruleDownloading => '下载中…';

  @override
  String get columnType => '类型';

  @override
  String get columnSize => '大小';

  @override
  String get columnUpdated => '更新时间';

  @override
  String get rulesNeedProxy => '请先启动代理，或改用直连下载';

  @override
  String get statusConnecting => '正在连接…';

  @override
  String get statusReconnecting => '正在重新连接';

  @override
  String get statusDisconnecting => '正在断开…';

  @override
  String coreReady(String version) {
    return 'sing-box $version 已就绪';
  }

  @override
  String connectedSummary(String mode, String exit) {
    return '$mode · $exit';
  }

  @override
  String get runtimePermissionRefused => '需要 VPN 授权才能连接';

  @override
  String get runtimePermissionRefusedNote => '再次点击连接，并在系统弹窗中允许。';

  @override
  String get runtimeNotDownloaded => '所选配置尚未下载，请先更新';

  @override
  String get runtimePlanFailed => '无法生成配置';

  @override
  String get runtimeHostUnreachable => '无法连接到 Avalon 服务';

  @override
  String get runtimePortInUse => '端口被占用，请更换混合端口';

  @override
  String get runtimeNoListedAppInstalled => '白名单里的应用都未安装';

  @override
  String get runtimeNoListedAppInstalledNote =>
      '请在「分应用代理」的白名单中选择本机已安装的应用，或改用黑名单、清空名单。';

  @override
  String get appsNoneInstalled => '名单里的应用都未安装';

  @override
  String get appsNoneInstalledNote => '请在白名单中选择本机已安装的应用后启动代理。';

  @override
  String get runtimePlanRefused => '内核不接受这份配置';

  @override
  String get runtimeCoreFailed => '内核启动失败';

  @override
  String get runtimeTimeout => 'Avalon 服务没有及时响应';

  @override
  String get errorConfigurationInUse => '请先断开或切换到其他配置';

  @override
  String get autoUpdateLocalOnlyNote => '每 12 小时自动更新，保存在本机。';

  @override
  String get latencyTimeout => '超时';

  @override
  String get latencyFailed => '失败';

  @override
  String get closeAll => '全部关闭';

  @override
  String activeConnections(int n) {
    return '$n 个活动连接';
  }

  @override
  String get noConnections => '暂无连接';

  @override
  String get connectionsWhenRunning => '启动代理后，这里会实时显示连接';

  @override
  String get connectionsAllClosed => '所有连接已关闭';

  @override
  String get columnHost => '主机';

  @override
  String get columnProcess => '进程';

  @override
  String get columnRule => '规则';

  @override
  String get columnChain => '链路';

  @override
  String get columnUpload => '上传';

  @override
  String get columnDownload => '下载';

  @override
  String get ruleFinal => '默认';

  @override
  String get logsAll => '全部';

  @override
  String get logsDropped => '较早日志已丢弃';

  @override
  String get noLogs => '暂无日志';

  @override
  String get noLogsNote => '代理运行时，内核的日志会显示在这里';

  @override
  String get shareLogs => '分享日志';

  @override
  String get exportLogs => '导出日志';

  @override
  String get ruleDownloadFailed => '下载失败';

  @override
  String get cloudTitle => 'Avalon Cloud';

  @override
  String get cloudLoginTitle => '登录 Avalon';

  @override
  String get cloudLoginNote => '使用邮箱验证码登录 Avalon。';

  @override
  String get cloudLoginIntro => '用邮箱登录，\n在你的设备间同步配置。';

  @override
  String get cloudEmailAddress => '邮箱地址';

  @override
  String get cloudCheckInbox => '查看你的邮箱';

  @override
  String get cloudCodeSentTo => '验证码已发送至';

  @override
  String get cloudSixDigitCode => '6 位验证码';

  @override
  String get cloudCodeHelper => '输入邮件中的验证码完成登录。';

  @override
  String get cloudClearEmail => '清空邮箱';

  @override
  String get cloudEmail => '邮箱';

  @override
  String get cloudEmailPlaceholder => 'name@example.com';

  @override
  String get cloudCode => '验证码';

  @override
  String get cloudCodePlaceholder => '六位验证码';

  @override
  String get cloudSendCode => '发送验证码';

  @override
  String get cloudResendCode => '重新发送';

  @override
  String get cloudVerifyCode => '登录';

  @override
  String get cloudChangeEmail => '更换邮箱';

  @override
  String get cloudCodeSent => '验证码已发送，请查收邮箱。';

  @override
  String cloudResendWait(int seconds) {
    return '$seconds 秒后可重新发送';
  }

  @override
  String get cloudLoading => '正在恢复登录…';

  @override
  String get cloudWorking => '正在处理…';

  @override
  String get cloudAccount => '账号';

  @override
  String get cloudSignedIn => '已登录';

  @override
  String get cloudReload => '更新账号信息';

  @override
  String get cloudFreeAccount => '免费账户';

  @override
  String get cloudFreeAccountNote => '在本机管理和使用全部配置。';

  @override
  String get cloudSyncFreeAccountNote => '配置保存在本机。有效订阅可启用云同步。';

  @override
  String get cloudSyncTitle => '云同步';

  @override
  String get cloudLastSync => '上次同步';

  @override
  String get cloudNeverSynced => '从未同步';

  @override
  String get cloudSyncNow => '立即同步';

  @override
  String get cloudSyncing => '正在同步…';

  @override
  String get cloudSyncNoEntitlement => '当前没有有效同步权益，请更新账号信息。';

  @override
  String get cloudSyncDeviceLimit => '同步设备名额已满，请先移除其他设备后重试。';

  @override
  String get cloudSyncSchemaUnsupported => '云端数据版本暂不受支持，请更新客户端后重试。';

  @override
  String get cloudSyncQuotaExceeded => '云端同步容量不足，请减少同步内容后重试。';

  @override
  String get cloudSyncValidation => '部分本机内容不符合云端同步要求，请检查后重试。本机内容保留。';

  @override
  String get cloudSyncOwnership => '同步内容属于其他账号，请使用对应账号。本机内容保留。';

  @override
  String cloudPendingMerge(int count) {
    return '保留 $count 项待合并的本机修改';
  }

  @override
  String get cloudSyncLegacyUnverified => '旧版同步资料来源待确认，上传和下载已暂停。本机内容保留。';

  @override
  String get cloudRebuildIncomplete => '备份尚不完整，请继续重建。';

  @override
  String get cloudRebuildChanged => '重建状态已变化，请更新账号信息后重试。';

  @override
  String get cloudBackupTitle => '云端备份';

  @override
  String get cloudBackupReady => '完整备份已就绪';

  @override
  String get cloudBackupRebuildRequired => '云端需要完整备份，请选择来源设备。';

  @override
  String get cloudBackupRebuilding => '正在重建云端备份，完成后发布。';

  @override
  String get cloudBackupRetained => '同步权益已到期，云端备份暂时保留。';

  @override
  String get cloudBackupRetired => '原云端备份已停止提供。';

  @override
  String get cloudBackupNone => '尚无云端备份';

  @override
  String cloudBackupRetentionUntil(String time) {
    return '备份保留至：$time';
  }

  @override
  String get cloudBackupLocalNote => '本机配置与代理凭据保留，仍可编辑和使用。';

  @override
  String get cloudSyncGenerationChanged => '云端空间已更新，请重新获取状态后同步。本机内容保留。';

  @override
  String get cloudSyncSnapshotChanged => '完整下载期间云端内容发生变化，请重试。本机内容保留。';

  @override
  String get cloudSyncVerificationPending => '同步权益待核实，上传和下载已暂停。';

  @override
  String get cloudRebuildStart => '从此设备重建';

  @override
  String get cloudRebuildStartTitle => '从此设备重建云端备份？';

  @override
  String get cloudRebuildStartNote =>
      '完整备份仅包含此设备上该账号的当前可同步内容。请先核对其他设备上的待上传修改。其他设备在备份发布后恢复同步，本机内容保留。';

  @override
  String get cloudRebuildClaim => '由此设备接管重建';

  @override
  String get cloudRebuildClaimTitle => '由此设备接管重建？';

  @override
  String get cloudRebuildClaimNote =>
      '当前重建将停止，原尝试中尚未发布的内容将舍弃。新备份仅包含此设备上该账号的当前可同步内容。其他设备在完整备份发布后恢复同步，本机内容保留。';

  @override
  String get cloudRebuildCancel => '取消重建';

  @override
  String get cloudRebuildCancelTitle => '取消本次重建？';

  @override
  String get cloudRebuildCancelNote => '结束本次重建，舍弃尚未发布的备份。再次重建时请选择来源设备。本机内容保留。';

  @override
  String get cloudRebuildResume => '继续重建';

  @override
  String get cloudRebuildThisDevice => '此设备正在重建，完整备份发布后完成同步。';

  @override
  String get cloudRebuildWaiting => '其他设备正在重建；等待完整备份发布。';

  @override
  String cloudRebuildProgress(int received, int total) {
    return '已上传 $received / $total 条';
  }

  @override
  String cloudCleanupOnline(String status) {
    return '历史云端内容清理：$status';
  }

  @override
  String cloudCleanupKey(String status) {
    return '历史在线密钥状态：$status';
  }

  @override
  String get cloudCleanupPending => '待处理';

  @override
  String get cloudCleanupRunning => '正在处理';

  @override
  String get cloudCleanupFailed => '处理未完成';

  @override
  String get cloudCleanupComplete => '已完成';

  @override
  String get cloudCleanupNone => '尚无结果';

  @override
  String get cloudCleanupWaiting => '等待密钥清理确认';

  @override
  String get cloudCleanupKeyDeleted => '在线密钥已移除';

  @override
  String get cloudCleanupKeyDeletedNote => '在线密钥已移除。灾备副本自原创建时间起最多保留 30 天。';

  @override
  String get cloudCleanupKeyDestroyed => '旧密钥已停用';

  @override
  String get cloudNetworkGuard => '该云端内容包含当前宿主无法安全处理的网络路径，请使用兼容版本或本机节点。';

  @override
  String get cloudEntitlement => '订阅权益';

  @override
  String get cloudMonthly => '月付';

  @override
  String get cloudYearly => '年付';

  @override
  String get cloudEntitlementActive => '有效';

  @override
  String get cloudEntitlementExpired => '已到期';

  @override
  String get cloudEntitlementRevoked => '已撤销';

  @override
  String get cloudEntitlementUnknown => '状态待确认';

  @override
  String cloudEntitlementUntil(String status, String date) {
    return '$status · 到期日 $date';
  }

  @override
  String get cloudAppleSource => 'App Store';

  @override
  String get cloudGoogleSource => 'Google Play';

  @override
  String get cloudWebSource => '网页购买渠道';

  @override
  String cloudDevices(int count, int limit) {
    return '设备 · $count / $limit';
  }

  @override
  String get cloudThisDevice => '此设备';

  @override
  String get cloudNotSyncing => '未同步';

  @override
  String get cloudSyncSlotActive => '占用同步名额';

  @override
  String cloudLastSeen(String time) {
    return '最近活动：$time';
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
  String get cloudDeviceRemoveHint => '左滑或右键移除其他设备。此设备请使用「退出登录」。';

  @override
  String get cloudRemoveDevice => '移除';

  @override
  String cloudRemoveDeviceTitle(String name) {
    return '移除「$name」？';
  }

  @override
  String get cloudRemoveDeviceNote => '该设备将退出登录并释放同步名额；设备上的本地内容保留。';

  @override
  String get cloudLogout => '退出登录';

  @override
  String get cloudLogoutTitle => '退出 Avalon 账号？';

  @override
  String get cloudLogoutNote => '本机的配置、节点和代理凭据全部保留。离线时会在联网后自动撤销原会话。';

  @override
  String get cloudDeleteAccount => '删除账号';

  @override
  String get cloudDeleteFirstTitle => '删除 Avalon 账号？';

  @override
  String get cloudDeleteFirstNote => '将删除账号和云端内容；本机配置和代理凭据全部保留。';

  @override
  String get cloudDeleteContinue => '继续';

  @override
  String get cloudDeleteFinalTitle => '确认永久删除账号？';

  @override
  String get cloudDeleteFinalNote => '账号将永久删除。订阅及自动续费请前往原购买渠道另行取消。';

  @override
  String get cloudAccountDeleted => '账号已删除，本机内容已保留。';

  @override
  String cloudCancelSubscription(String sources) {
    return '请前往 $sources 取消订阅续费。';
  }

  @override
  String cloudPendingRevocations(int count) {
    return '$count 个原会话等待撤销';
  }

  @override
  String get cloudPendingRevocationsNote => '本机已退出，联网后会自动重试撤销原会话。';

  @override
  String get cloudRetryRevocations => '立即重试撤销';

  @override
  String get cloudRevocationUnconfirmed => '原会话凭据已失效，无法确认远端已撤销；本机仍保持退出。';

  @override
  String get cloudErrorDisabled => '账号与同步入口已关闭，请返回本机功能。';

  @override
  String get cloudErrorInvalidEmail => '请输入有效邮箱。';

  @override
  String get cloudErrorInvalidCode => '请输入六位数字验证码。';

  @override
  String get cloudErrorValidation => '请求未被接受，请检查输入后重试。';

  @override
  String get cloudErrorChallengeInvalid => '验证码或登录请求无效，请检查验证码或重新发送。';

  @override
  String get cloudErrorChallengeExpired => '验证码已过期，请重新发送。';

  @override
  String get cloudErrorChallengeExhausted => '验证码尝试次数已用尽，请重新发送。';

  @override
  String get cloudErrorChallengeEnded => '登录请求已结束或不存在，请重新发送验证码。';

  @override
  String get cloudErrorRateLimited => '请求过于频繁，请稍后重试。';

  @override
  String cloudErrorRateLimitedWait(int seconds) {
    return '请求过于频繁，请在 $seconds 秒后重试。';
  }

  @override
  String get cloudErrorOffline => '无法连接 Cloud，请检查网络后重试。本机功能仍可使用。';

  @override
  String get cloudErrorTimeout => 'Cloud 没有及时响应，请稍后重试。';

  @override
  String get cloudErrorProtocol => 'Cloud 返回的数据无法读取，请更新应用或稍后重试。';

  @override
  String get cloudErrorReauthenticate => '请重新登录，或退出原会话。本机内容保留。';

  @override
  String get cloudErrorSessionRevoked => '登录已失效，请重新登录。';

  @override
  String get cloudErrorDeviceNotFound => '该设备已不存在，请更新账号信息。';

  @override
  String get cloudErrorCurrentDevice => '移除此设备请使用「退出登录」。';

  @override
  String get cloudErrorDeleteUnconfirmed => '删除结果未能确认。请更新账号信息或重新登录核对，再决定是否重试。';

  @override
  String get cloudErrorServer => 'Cloud 暂时无法完成请求，请稍后重试。';

  @override
  String get cloudErrorUnknown => '操作未完成，请重试或重新登录。';

  @override
  String cloudCodeExpires(String time) {
    return '验证码有效至 $time';
  }

  @override
  String get tailnetTitle => 'Tailscale';

  @override
  String get tailnetEnable => '启用 Tailscale';

  @override
  String get tailnetDisabled => '未启用';

  @override
  String get tailnetNeedsLogin => '需要登录';

  @override
  String tailnetConnected(String tailnet) {
    return '已连接 · $tailnet';
  }

  @override
  String get tailnetOffline => '离线';

  @override
  String get tailnetThisDevice => '本机';

  @override
  String get tailnetHostname => '设备名称';

  @override
  String get tailnetAddresses => 'IP 地址';

  @override
  String get tailnetNetwork => 'Tailnet';

  @override
  String get tailnetExitNodes => '出口节点';

  @override
  String get tailnetNoExit => '无';

  @override
  String get tailnetNoExitNote => '互联网流量使用当前网络与代理设置。';

  @override
  String get tailnetExitOffline => '该出口节点离线，无法连接。';

  @override
  String get tailnetAcceptRoutes => '接受子网路由';

  @override
  String get tailnetAcceptRoutesNote => '访问 Tailnet 中设备发布的子网。';

  @override
  String get tailnetMagicDns => 'MagicDNS';

  @override
  String get tailnetMagicDnsNote => '通过 Tailnet 设备名称访问设备。';

  @override
  String get tailnetAdvertiseExit => '将本机作为出口节点';

  @override
  String get tailnetAdvertiseExitNote => '允许 Tailnet 中的其他设备通过本机访问互联网。';

  @override
  String get tailnetLogout => '退出 Tailnet';

  @override
  String get tailnetLogin => '登录 Tailscale';

  @override
  String get tailnetUnavailable => '当前宿主无法运行 Tailscale。';

  @override
  String tailnetError(String message) {
    return '连接失败：$message';
  }

  @override
  String get tailnetBrowserFailed => '无法打开登录页面，请检查浏览器设置后重试。';

  @override
  String tailnetDevicesOnline(int count) {
    return '在线设备 · $count';
  }

  @override
  String get tailnetOnline => '在线';

  @override
  String get tailnetOptions => '选项';

  @override
  String get tailnetFixedRoutesNote => '通过 Tailscale 地址和设备名称访问 Tailnet 设备。';

  @override
  String get tailnetExitUseNote => '已选择的出口也可在自定义组中使用。';

  @override
  String get tailnetExitConflict => '请在使用其他出口和将本机作为出口之间选择一项。';

  @override
  String get tailnetWaiting => '等待登录…';

  @override
  String get tailnetPermissionRefused => '需要系统网络授权才能启用 Tailscale。';

  @override
  String get aboutCheckUpdates => '检查更新';

  @override
  String get aboutCheckingUpdates => '检查中…';

  @override
  String aboutUpdateAvailable(String version) {
    return '新版本 $version';
  }

  @override
  String get aboutUpToDate => '已是最新版本';

  @override
  String get aboutNoRelease => '暂无兼容版本发布';

  @override
  String get aboutSource => 'GitHub 源代码';

  @override
  String get aboutChangelog => '更新日志';

  @override
  String get aboutPrivacy => '隐私政策';

  @override
  String get aboutUpdateFailed => '检查更新失败，请检查网络后重试。';

  @override
  String get aboutBrowserFailed => '无法打开网页，请检查浏览器设置。';

  @override
  String get tailnetExitNotReady => '出口节点功能待开放。当前可访问 Tailnet 内的设备。';

  @override
  String get tailnetAdvertiseNotReady => '本机出口功能待开放。';

  @override
  String get systemProxyFailed => '系统代理设置或恢复失败，请检查系统权限后重试。';

  @override
  String get manageSelfContent => '管理';
}
