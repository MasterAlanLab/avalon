// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ja locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'ja';

  static String m0(count) => "パス数: ${count}";

  static String m1(count) => "${count}日前";

  static String m2(label) => "選択された${label}を削除してもよろしいですか？";

  static String m3(label) => "現在の${label}を削除してもよろしいですか？";

  static String m4(label) => "${label}詳細";

  static String m5(label) => "${label}は空欄にできません";

  static String m6(count) => "${count} エントリ";

  static String m7(label) => "現在の${label}は既に存在しています";

  static String m8(name) => "${name} はすでに最新です";

  static String m9(name) => "${name} 更新済み";

  static String m10(name) => "${name}を更新中...";

  static String m11(count) => "${count}時間前";

  static String m12(count) => "${count} 時間";

  static String m13(target) => "${target} は無効なポリシーです";

  static String m14(proxyName) => "${proxyName} は無効なプロキシです";

  static String m15(providerName) => "${providerName} は無効なプロキシプロバイダーです";

  static String m16(subRule) => "${subRule} は無効なSUB_RULEです";

  static String m17(appName) =>
      "1. Open System Settings > Privacy & Security\n2. Choose Location Services\n3. Find and check ${appName} in the right list\n\nAfter completing the setup, return to the app and use it normally. Thank you for your cooperation.";

  static String m18(count) => "${count}分前";

  static String m19(count) => "${count}ヶ月前";

  static String m20(count) => "${count} 個のノードをインポートしました";

  static String m21(label) => "まだ${label}はありません";

  static String m22(label) => "${label}は数字でなければなりません";

  static String m23(label) => "${label} は 1024 から 49151 の間でなければなりません";

  static String m24(count) => "${count} 秒";

  static String m25(count) => "${count} 項目が選択されています";

  static String m26(label) => "${label}はURLである必要があります";

  static String m27(count) => "${count}年前";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "about": MessageLookupByLibrary.simpleMessage("について"),
    "accessControl": MessageLookupByLibrary.simpleMessage("アクセス制御"),
    "accessControlAllowDesc": MessageLookupByLibrary.simpleMessage(
      "選択したアプリのみVPNを許可",
    ),
    "accessControlDesc": MessageLookupByLibrary.simpleMessage(
      "アプリケーションのプロキシアクセスを設定",
    ),
    "accessControlNotAllowDesc": MessageLookupByLibrary.simpleMessage(
      "選択したアプリをVPNから除外",
    ),
    "accessControlSettings": MessageLookupByLibrary.simpleMessage("アクセス制御設定"),
    "account": MessageLookupByLibrary.simpleMessage("アカウント"),
    "action": MessageLookupByLibrary.simpleMessage("アクション"),
    "action_mode": MessageLookupByLibrary.simpleMessage("モード切替"),
    "action_proxy": MessageLookupByLibrary.simpleMessage("システムプロキシ"),
    "action_start": MessageLookupByLibrary.simpleMessage("開始/停止"),
    "action_tun": MessageLookupByLibrary.simpleMessage("TUN"),
    "action_view": MessageLookupByLibrary.simpleMessage("表示/非表示"),
    "active": MessageLookupByLibrary.simpleMessage("有効"),
    "add": MessageLookupByLibrary.simpleMessage("追加"),
    "addChainHop": MessageLookupByLibrary.simpleMessage("ホップを追加"),
    "addProfile": MessageLookupByLibrary.simpleMessage("プロファイルを追加"),
    "addProxies": MessageLookupByLibrary.simpleMessage("プロキシを追加"),
    "addProxyGroup": MessageLookupByLibrary.simpleMessage("プロキシグループを追加"),
    "addProxyProviders": MessageLookupByLibrary.simpleMessage("プロキシプロバイダーを追加"),
    "addRule": MessageLookupByLibrary.simpleMessage("ルールを追加"),
    "addSsid": MessageLookupByLibrary.simpleMessage("SSIDを追加"),
    "addedRules": MessageLookupByLibrary.simpleMessage("追加ルール"),
    "additionalParameters": MessageLookupByLibrary.simpleMessage("追加パラメータ"),
    "address": MessageLookupByLibrary.simpleMessage("アドレス"),
    "addressHelp": MessageLookupByLibrary.simpleMessage("WebDAVサーバーアドレス"),
    "addressTip": MessageLookupByLibrary.simpleMessage("有効なWebDAVアドレスを入力"),
    "advancedConfig": MessageLookupByLibrary.simpleMessage("高度な設定"),
    "advancedConfigDesc": MessageLookupByLibrary.simpleMessage("多様な設定を提供"),
    "agree": MessageLookupByLibrary.simpleMessage("同意"),
    "all": MessageLookupByLibrary.simpleMessage("すべて"),
    "allowBypass": MessageLookupByLibrary.simpleMessage("アプリがVPNをバイパスすることを許可"),
    "allowBypassDesc": MessageLookupByLibrary.simpleMessage(
      "有効化すると一部アプリがVPNをバイパス",
    ),
    "allowLan": MessageLookupByLibrary.simpleMessage("LANを許可"),
    "allowLanDesc": MessageLookupByLibrary.simpleMessage("LAN経由でのプロキシアクセスを許可"),
    "app": MessageLookupByLibrary.simpleMessage("アプリ"),
    "appAccessControl": MessageLookupByLibrary.simpleMessage("アプリアクセス制御"),
    "appendSystemDns": MessageLookupByLibrary.simpleMessage("システムDNSを追加"),
    "appendSystemDnsTip": MessageLookupByLibrary.simpleMessage(
      "設定にシステムDNSを強制的に追加します",
    ),
    "application": MessageLookupByLibrary.simpleMessage("アプリケーション"),
    "applicationDesc": MessageLookupByLibrary.simpleMessage("アプリ関連設定を変更"),
    "assetFieldPath": MessageLookupByLibrary.simpleMessage("アセットフィールドパス"),
    "attachAsset": MessageLookupByLibrary.simpleMessage("アセットを添付"),
    "authorized": MessageLookupByLibrary.simpleMessage("許可済み"),
    "auto": MessageLookupByLibrary.simpleMessage("自動"),
    "autoCheckUpdate": MessageLookupByLibrary.simpleMessage("自動更新チェック"),
    "autoCheckUpdateDesc": MessageLookupByLibrary.simpleMessage(
      "起動時に更新を自動チェック",
    ),
    "autoCloseConnections": MessageLookupByLibrary.simpleMessage("接続を自動閉じる"),
    "autoCloseConnectionsDesc": MessageLookupByLibrary.simpleMessage(
      "ノード変更後に接続を自動閉じる",
    ),
    "autoLaunch": MessageLookupByLibrary.simpleMessage("自動起動"),
    "autoLaunchDesc": MessageLookupByLibrary.simpleMessage("システムの自動起動に従う"),
    "autoRun": MessageLookupByLibrary.simpleMessage("自動実行"),
    "autoRunDesc": MessageLookupByLibrary.simpleMessage("アプリ起動時に自動実行"),
    "autoSetSystemDns": MessageLookupByLibrary.simpleMessage("オートセットシステムDNS"),
    "autoUpdate": MessageLookupByLibrary.simpleMessage("自動更新"),
    "autoUpdateInterval": MessageLookupByLibrary.simpleMessage("自動更新間隔（分）"),
    "backup": MessageLookupByLibrary.simpleMessage("バックアップ"),
    "backupAndRestore": MessageLookupByLibrary.simpleMessage("バックアップと復元"),
    "backupAndRestoreDesc": MessageLookupByLibrary.simpleMessage(
      "WebDAVまたはファイルを介してデータを同期する",
    ),
    "backupSuccess": MessageLookupByLibrary.simpleMessage("バックアップ成功"),
    "basicConfig": MessageLookupByLibrary.simpleMessage("基本設定"),
    "basicConfigDesc": MessageLookupByLibrary.simpleMessage("基本設定をグローバルに変更"),
    "basicInfo": MessageLookupByLibrary.simpleMessage("基本情報"),
    "basicStrategy": MessageLookupByLibrary.simpleMessage("基本戦略"),
    "batteryOptimizationDesc": MessageLookupByLibrary.simpleMessage(
      "To ensure background operation, please disable battery optimization for this app. Tap to go to settings.",
    ),
    "batteryOptimizationStatusTip": MessageLookupByLibrary.simpleMessage(
      "システムの影響により、この状態は必ずしも正確とは限りません。",
    ),
    "bind": MessageLookupByLibrary.simpleMessage("バインド"),
    "blacklistMode": MessageLookupByLibrary.simpleMessage("ブラックリストモード"),
    "branchLimit": MessageLookupByLibrary.simpleMessage("分岐上限"),
    "bypassDomain": MessageLookupByLibrary.simpleMessage("バイパスドメイン"),
    "bypassDomainDesc": MessageLookupByLibrary.simpleMessage("システムプロキシ有効時のみ適用"),
    "cacheCorrupt": MessageLookupByLibrary.simpleMessage(
      "キャッシュが破損しています。クリアしますか？",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("キャンセル"),
    "cancelSelectAll": MessageLookupByLibrary.simpleMessage("全選択解除"),
    "chain": MessageLookupByLibrary.simpleMessage("チェーン"),
    "chainClient": MessageLookupByLibrary.simpleMessage("クライアント"),
    "chainDiagnostics": MessageLookupByLibrary.simpleMessage("チェーン診断"),
    "chainEmpty": MessageLookupByLibrary.simpleMessage("ホップを追加してチェーンを構築"),
    "chainEntryGroups": MessageLookupByLibrary.simpleMessage("チェーン入口グループ"),
    "chainEntryGroupsEmpty": MessageLookupByLibrary.simpleMessage(
      "このプロファイルには追加できるグループがありません",
    ),
    "chainEntryGroupsTip": MessageLookupByLibrary.simpleMessage(
      "選択したグループにチェーンを追加し、プロキシページで選択してください。",
    ),
    "chainHop": MessageLookupByLibrary.simpleMessage("チェーンホップ"),
    "chainPathCount": m0,
    "chainTarget": MessageLookupByLibrary.simpleMessage("ターゲット"),
    "chainWarningConfirm": MessageLookupByLibrary.simpleMessage(
      "チェーンに警告があります。保存しますか？",
    ),
    "chains": MessageLookupByLibrary.simpleMessage("チェーン"),
    "checkUpdate": MessageLookupByLibrary.simpleMessage("更新を確認"),
    "checkUpdateError": MessageLookupByLibrary.simpleMessage("アプリは最新版です"),
    "clearData": MessageLookupByLibrary.simpleMessage("データを消去"),
    "clearLocalOverride": MessageLookupByLibrary.simpleMessage("ローカル上書きを解除"),
    "clipboardExport": MessageLookupByLibrary.simpleMessage("クリップボードにエクスポート"),
    "clipboardImport": MessageLookupByLibrary.simpleMessage("クリップボードからインポート"),
    "color": MessageLookupByLibrary.simpleMessage("カラー"),
    "colorSchemes": MessageLookupByLibrary.simpleMessage("カラースキーム"),
    "columns": MessageLookupByLibrary.simpleMessage("列"),
    "compatible": MessageLookupByLibrary.simpleMessage("互換モード"),
    "configDataDetected": MessageLookupByLibrary.simpleMessage(
      "設定内にデータが検出されました",
    ),
    "confirm": MessageLookupByLibrary.simpleMessage("確認"),
    "confirmClearAllData": MessageLookupByLibrary.simpleMessage(
      "すべてのデータをクリアしてもよろしいですか？",
    ),
    "confirmDeleteProxyGroup": MessageLookupByLibrary.simpleMessage(
      "現在のプロキシグループを削除してもよろしいですか？",
    ),
    "confirmExitWindow": MessageLookupByLibrary.simpleMessage(
      "現在のウィンドウを閉じてもよろしいですか？",
    ),
    "confirmForceCrashCore": MessageLookupByLibrary.simpleMessage(
      "コアを強制的にクラッシュさせてもよろしいですか？",
    ),
    "confirmOverwriteTip": MessageLookupByLibrary.simpleMessage(
      "確認後、既存のデータは上書きされます",
    ),
    "connected": MessageLookupByLibrary.simpleMessage("接続済み"),
    "connecting": MessageLookupByLibrary.simpleMessage("接続中..."),
    "connection": MessageLookupByLibrary.simpleMessage("接続"),
    "connections": MessageLookupByLibrary.simpleMessage("接続"),
    "connectionsDesc": MessageLookupByLibrary.simpleMessage("現在の接続データを表示"),
    "connectivity": MessageLookupByLibrary.simpleMessage("接続性："),
    "content": MessageLookupByLibrary.simpleMessage("内容"),
    "contentNotEmpty": MessageLookupByLibrary.simpleMessage("内容は空にできません"),
    "contentScheme": MessageLookupByLibrary.simpleMessage("コンテンツテーマ"),
    "contributors": MessageLookupByLibrary.simpleMessage("貢献者"),
    "controlGlobalAddedRules": MessageLookupByLibrary.simpleMessage(
      "グローバル追加ルールを制御",
    ),
    "copy": MessageLookupByLibrary.simpleMessage("コピー"),
    "copyEnvVar": MessageLookupByLibrary.simpleMessage("環境変数をコピー"),
    "copyLink": MessageLookupByLibrary.simpleMessage("リンクをコピー"),
    "copySuccess": MessageLookupByLibrary.simpleMessage("コピー成功"),
    "core": MessageLookupByLibrary.simpleMessage("コア"),
    "coreStatus": MessageLookupByLibrary.simpleMessage("コアステータス"),
    "country": MessageLookupByLibrary.simpleMessage("国"),
    "crashDetected": MessageLookupByLibrary.simpleMessage("クラッシュを検出しました"),
    "crashDetectedTip": MessageLookupByLibrary.simpleMessage(
      "前回の実行中にアプリがクラッシュしました。クラッシュの繰り返しを防ぐため、現在のプロファイルを解除し、設定の自動セットアップをスキップしました。",
    ),
    "crashTest": MessageLookupByLibrary.simpleMessage("クラッシュテスト"),
    "create": MessageLookupByLibrary.simpleMessage("作成"),
    "createChain": MessageLookupByLibrary.simpleMessage("チェーンを作成"),
    "createCopy": MessageLookupByLibrary.simpleMessage("コピーを作成"),
    "createFromChain": MessageLookupByLibrary.simpleMessage(
      "Create from chain",
    ),
    "createFromChainDesc": MessageLookupByLibrary.simpleMessage(
      "Build a runnable profile from a chain in the chain library",
    ),
    "createFromChainEmpty": MessageLookupByLibrary.simpleMessage(
      "No chain yet. Create one on the Chains tab first.",
    ),
    "createFromChainTip": MessageLookupByLibrary.simpleMessage(
      "The chain becomes this profile’s default outbound.",
    ),
    "createNode": MessageLookupByLibrary.simpleMessage("ノードを作成"),
    "createProfile": MessageLookupByLibrary.simpleMessage("Create Profile"),
    "creationTime": MessageLookupByLibrary.simpleMessage("作成時間"),
    "custom": MessageLookupByLibrary.simpleMessage("カスタム"),
    "cut": MessageLookupByLibrary.simpleMessage("切り取り"),
    "dark": MessageLookupByLibrary.simpleMessage("ダーク"),
    "dashboard": MessageLookupByLibrary.simpleMessage("ダッシュボード"),
    "dataChangedSave": MessageLookupByLibrary.simpleMessage(
      "データの変更が検出されました。保存しますか？",
    ),
    "daysAgo": m1,
    "defaultNameserver": MessageLookupByLibrary.simpleMessage("デフォルトネームサーバー"),
    "defaultNameserverDesc": MessageLookupByLibrary.simpleMessage(
      "DNSサーバーの解決用",
    ),
    "defaultText": MessageLookupByLibrary.simpleMessage("デフォルト"),
    "delay": MessageLookupByLibrary.simpleMessage("遅延"),
    "delayTest": MessageLookupByLibrary.simpleMessage("遅延テスト"),
    "delete": MessageLookupByLibrary.simpleMessage("削除"),
    "deleteMultipTip": m2,
    "deleteTip": m3,
    "desc": MessageLookupByLibrary.simpleMessage(
      "ClashMetaベースのマルチプラットフォームプロキシクライアント。シンプルで使いやすく、オープンソースで広告なし。",
    ),
    "destination": MessageLookupByLibrary.simpleMessage("宛先"),
    "destinationGeoIP": MessageLookupByLibrary.simpleMessage("宛先地理情報"),
    "destinationIPASN": MessageLookupByLibrary.simpleMessage("宛先IP ASN"),
    "details": m4,
    "detectionTip": MessageLookupByLibrary.simpleMessage("サードパーティAPIに依存（参考値）"),
    "developerMode": MessageLookupByLibrary.simpleMessage("デベロッパーモード"),
    "developerModeEnableTip": MessageLookupByLibrary.simpleMessage(
      "デベロッパーモードが有効になりました。",
    ),
    "direct": MessageLookupByLibrary.simpleMessage("ダイレクト"),
    "disableUDP": MessageLookupByLibrary.simpleMessage("UDPを無効化"),
    "disclaimer": MessageLookupByLibrary.simpleMessage("免責事項"),
    "disclaimerDesc": MessageLookupByLibrary.simpleMessage(
      "本ソフトウェアは学習交流や科学研究などの非営利目的でのみ使用されます。商用利用は厳禁です。いかなる商用活動も本ソフトウェアとは無関係です。",
    ),
    "disconnected": MessageLookupByLibrary.simpleMessage("切断済み"),
    "discoverNewVersion": MessageLookupByLibrary.simpleMessage("新バージョンを発見"),
    "dnsDesc": MessageLookupByLibrary.simpleMessage("DNS関連設定の更新"),
    "dnsHijacking": MessageLookupByLibrary.simpleMessage("DNSハイジャッキング"),
    "dnsMode": MessageLookupByLibrary.simpleMessage("DNSモード"),
    "doYouWantToPass": MessageLookupByLibrary.simpleMessage("通過させますか？"),
    "domain": MessageLookupByLibrary.simpleMessage("ドメイン"),
    "download": MessageLookupByLibrary.simpleMessage("ダウンロード"),
    "edit": MessageLookupByLibrary.simpleMessage("編集"),
    "editGlobalRules": MessageLookupByLibrary.simpleMessage("グローバルルールを編集"),
    "editProxy": MessageLookupByLibrary.simpleMessage("プロキシを編集"),
    "editProxyGroup": MessageLookupByLibrary.simpleMessage("プロキシグループを編集"),
    "editRule": MessageLookupByLibrary.simpleMessage("ルールを編集"),
    "editSsid": MessageLookupByLibrary.simpleMessage("SSIDを編集"),
    "emptyTip": m5,
    "en": MessageLookupByLibrary.simpleMessage("英語"),
    "endpointType": MessageLookupByLibrary.simpleMessage("エンドポイントタイプ"),
    "entries": MessageLookupByLibrary.simpleMessage(" エントリ"),
    "entriesCount": m6,
    "exclude": MessageLookupByLibrary.simpleMessage("最近のタスクから非表示"),
    "excludeDesc": MessageLookupByLibrary.simpleMessage(
      "アプリがバックグラウンド時に最近のタスクから非表示",
    ),
    "excludeProxyFilter": MessageLookupByLibrary.simpleMessage("除外プロキシフィルター"),
    "excludeSsids": MessageLookupByLibrary.simpleMessage("Exclude SSIDs"),
    "excludeSsidsDesc": MessageLookupByLibrary.simpleMessage(
      "When connected to an excluded SSID Wi-Fi, the app running state will be automatically switched.",
    ),
    "excludeType": MessageLookupByLibrary.simpleMessage("除外タイプ"),
    "existsTip": m7,
    "exit": MessageLookupByLibrary.simpleMessage("終了"),
    "expand": MessageLookupByLibrary.simpleMessage("標準"),
    "expectedStatus": MessageLookupByLibrary.simpleMessage("期待されるステータス"),
    "export": MessageLookupByLibrary.simpleMessage("エクスポート"),
    "exportBase64": MessageLookupByLibrary.simpleMessage("Base64"),
    "exportDiagnostics": MessageLookupByLibrary.simpleMessage("診断"),
    "exportFile": MessageLookupByLibrary.simpleMessage("ファイルをエクスポート"),
    "exportJson": MessageLookupByLibrary.simpleMessage("JSON"),
    "exportLogs": MessageLookupByLibrary.simpleMessage("ログをエクスポート"),
    "exportSuccess": MessageLookupByLibrary.simpleMessage("エクスポート成功"),
    "exportUri": MessageLookupByLibrary.simpleMessage("URI"),
    "exportYaml": MessageLookupByLibrary.simpleMessage("YAML"),
    "exportZip": MessageLookupByLibrary.simpleMessage("ZIP"),
    "expressiveScheme": MessageLookupByLibrary.simpleMessage("エクスプレッシブ"),
    "externalController": MessageLookupByLibrary.simpleMessage("外部コントローラー"),
    "externalControllerDesc": MessageLookupByLibrary.simpleMessage(
      "有効化するとClashコアをポート9090で制御可能",
    ),
    "externalFetch": MessageLookupByLibrary.simpleMessage("外部取得"),
    "externalLink": MessageLookupByLibrary.simpleMessage("外部リンク"),
    "fakeipFilter": MessageLookupByLibrary.simpleMessage("Fakeipフィルター"),
    "fakeipRange": MessageLookupByLibrary.simpleMessage("Fakeip範囲"),
    "fakeipRange6": MessageLookupByLibrary.simpleMessage("Fakeip範囲（IPv6）"),
    "fallback": MessageLookupByLibrary.simpleMessage("フォールバック"),
    "fallbackDesc": MessageLookupByLibrary.simpleMessage("通常はオフショアDNSを使用"),
    "fallbackFilter": MessageLookupByLibrary.simpleMessage("フォールバックフィルター"),
    "fidelityScheme": MessageLookupByLibrary.simpleMessage("ハイファイデリティー"),
    "file": MessageLookupByLibrary.simpleMessage("ファイル"),
    "fileDesc": MessageLookupByLibrary.simpleMessage("プロファイルを直接アップロード"),
    "fileIsUpdate": MessageLookupByLibrary.simpleMessage(
      "ファイルが変更されました。保存しますか？",
    ),
    "findProcessMode": MessageLookupByLibrary.simpleMessage("プロセス検出"),
    "findProcessModeDesc": MessageLookupByLibrary.simpleMessage(
      "有効化するとパフォーマンスが若干低下します",
    ),
    "fontFamily": MessageLookupByLibrary.simpleMessage("フォントファミリー"),
    "forceRestartCoreTip": MessageLookupByLibrary.simpleMessage(
      "コアを強制再起動してもよろしいですか？",
    ),
    "fruitSaladScheme": MessageLookupByLibrary.simpleMessage("フルーツサラダ"),
    "general": MessageLookupByLibrary.simpleMessage("一般"),
    "geoAutoUpdate": MessageLookupByLibrary.simpleMessage("自動更新"),
    "geoAutoUpdateInterval": MessageLookupByLibrary.simpleMessage("自動更新間隔"),
    "geoAutoUpdateIntervalTip": MessageLookupByLibrary.simpleMessage(
      "自動更新間隔は0より大きくなければなりません",
    ),
    "geoOptions": MessageLookupByLibrary.simpleMessage("Geoオプション"),
    "geoResources": MessageLookupByLibrary.simpleMessage("Geoリソース"),
    "geoSkipped": m8,
    "geoUpdated": m9,
    "geoUpdating": m10,
    "geodataLoader": MessageLookupByLibrary.simpleMessage("Geo低メモリモード"),
    "geodataLoaderDesc": MessageLookupByLibrary.simpleMessage(
      "有効化するとGeo低メモリローダーを使用",
    ),
    "geoipCode": MessageLookupByLibrary.simpleMessage("GeoIPコード"),
    "global": MessageLookupByLibrary.simpleMessage("グローバル"),
    "globalGroup": MessageLookupByLibrary.simpleMessage("グローバルグループ"),
    "go": MessageLookupByLibrary.simpleMessage("移動"),
    "goDownload": MessageLookupByLibrary.simpleMessage("ダウンロードへ"),
    "goToConfigureScript": MessageLookupByLibrary.simpleMessage("スクリプト設定に移動"),
    "hasCacheChange": MessageLookupByLibrary.simpleMessage("変更をキャッシュしますか？"),
    "helperCorruptTip": MessageLookupByLibrary.simpleMessage(
      "Helper サービスが利用できないため、TUN モードを有効にできません。再インストールしてください。",
    ),
    "hideFromList": MessageLookupByLibrary.simpleMessage("リストから隠す"),
    "host": MessageLookupByLibrary.simpleMessage("ホスト"),
    "hostsDesc": MessageLookupByLibrary.simpleMessage("ホストを追加"),
    "hotkeyConflict": MessageLookupByLibrary.simpleMessage("ホットキー競合"),
    "hotkeyManagement": MessageLookupByLibrary.simpleMessage("ホットキー管理"),
    "hotkeyManagementDesc": MessageLookupByLibrary.simpleMessage(
      "キーボードでアプリを制御",
    ),
    "hours": MessageLookupByLibrary.simpleMessage("時間"),
    "hoursAgo": m11,
    "hoursCount": m12,
    "icon": MessageLookupByLibrary.simpleMessage("アイコン"),
    "iconRecords": MessageLookupByLibrary.simpleMessage("アイコン履歴"),
    "iconStyle": MessageLookupByLibrary.simpleMessage("アイコンスタイル"),
    "iconUrl": MessageLookupByLibrary.simpleMessage("アイコンURL"),
    "ignoreBatteryOptimization": MessageLookupByLibrary.simpleMessage(
      "Ignore Battery Optimization",
    ),
    "import": MessageLookupByLibrary.simpleMessage("インポート"),
    "importFile": MessageLookupByLibrary.simpleMessage("ファイルからインポート"),
    "importFromURL": MessageLookupByLibrary.simpleMessage("URLからインポート"),
    "importNode": MessageLookupByLibrary.simpleMessage("ノードをインポート"),
    "importSuccess": MessageLookupByLibrary.simpleMessage("ノードをインポートしました"),
    "importUrl": MessageLookupByLibrary.simpleMessage("URLからインポート"),
    "includeAllProxies": MessageLookupByLibrary.simpleMessage("すべてのプロキシを含める"),
    "includeAllProxiesTip": MessageLookupByLibrary.simpleMessage(
      "プロキシグループに含まれないすべてのプロキシをインポートします。下でさらにプロキシグループを追加できます",
    ),
    "includeAllProxyProviders": MessageLookupByLibrary.simpleMessage(
      "すべてのプロキシプロバイダーを含める",
    ),
    "includeAllProxyProvidersTip": MessageLookupByLibrary.simpleMessage(
      "有効にすると、インポートされたプロキシプロバイダーを上書きします",
    ),
    "infiniteTime": MessageLookupByLibrary.simpleMessage("長期有効"),
    "init": MessageLookupByLibrary.simpleMessage("初期化"),
    "inputCorrectHotkey": MessageLookupByLibrary.simpleMessage("正しいホットキーを入力"),
    "inputProxyGroupName": MessageLookupByLibrary.simpleMessage("プロキシグループ名を入力"),
    "inputRuleContent": MessageLookupByLibrary.simpleMessage("ルール内容を入力"),
    "intelligentSelected": MessageLookupByLibrary.simpleMessage("インテリジェント選択"),
    "internet": MessageLookupByLibrary.simpleMessage("インターネット"),
    "interval": MessageLookupByLibrary.simpleMessage("インターバル"),
    "intranetIP": MessageLookupByLibrary.simpleMessage("イントラネットIP"),
    "invalidBackupFile": MessageLookupByLibrary.simpleMessage("無効なバックアップファイル"),
    "invalidEndpoint": MessageLookupByLibrary.simpleMessage(
      "有効なエンドポイントを入力してください",
    ),
    "invalidPolicy": m13,
    "invalidProxy": m14,
    "invalidProxyProvider": m15,
    "invalidSubRule": m16,
    "ipcidr": MessageLookupByLibrary.simpleMessage("IPCIDR"),
    "ipv6Desc": MessageLookupByLibrary.simpleMessage("有効化するとIPv6トラフィックを受信可能"),
    "ipv6InboundDesc": MessageLookupByLibrary.simpleMessage("IPv6インバウンドを許可"),
    "ja": MessageLookupByLibrary.simpleMessage("日本語"),
    "justNow": MessageLookupByLibrary.simpleMessage("たった今"),
    "keepAliveIntervalDesc": MessageLookupByLibrary.simpleMessage(
      "TCPキープアライブ間隔",
    ),
    "key": MessageLookupByLibrary.simpleMessage("キー"),
    "language": MessageLookupByLibrary.simpleMessage("言語"),
    "layout": MessageLookupByLibrary.simpleMessage("レイアウト"),
    "light": MessageLookupByLibrary.simpleMessage("ライト"),
    "list": MessageLookupByLibrary.simpleMessage("リスト"),
    "listen": MessageLookupByLibrary.simpleMessage("リスン"),
    "loadTest": MessageLookupByLibrary.simpleMessage("読み込みテスト"),
    "loading": MessageLookupByLibrary.simpleMessage("読み込み中..."),
    "local": MessageLookupByLibrary.simpleMessage("ローカル"),
    "localBackupDesc": MessageLookupByLibrary.simpleMessage("ローカルにデータをバックアップ"),
    "localEndpoint": MessageLookupByLibrary.simpleMessage("ローカルエンドポイント"),
    "localOverride": MessageLookupByLibrary.simpleMessage("ローカル上書き"),
    "localOverrideCleared": MessageLookupByLibrary.simpleMessage(
      "ローカル上書きを解除しました",
    ),
    "locationPermission": MessageLookupByLibrary.simpleMessage(
      "Location Permission",
    ),
    "locationPermissionDeniedMessage": MessageLookupByLibrary.simpleMessage(
      "位置情報の権限が拒否されたため、現在の Wi-Fi 名を取得できません。システム設定で位置情報の権限を手動で有効にしてください。",
    ),
    "locationPermissionDesc": MessageLookupByLibrary.simpleMessage(
      "According to system requirements, obtaining the Wi-Fi name requires you to grant location permission.",
    ),
    "locationPermissionGuide": m17,
    "locationPermissionRequired": MessageLookupByLibrary.simpleMessage(
      "Location Permission Required",
    ),
    "log": MessageLookupByLibrary.simpleMessage("ログ"),
    "logLevel": MessageLookupByLibrary.simpleMessage("ログレベル"),
    "logcat": MessageLookupByLibrary.simpleMessage("ログキャット"),
    "logcatDesc": MessageLookupByLibrary.simpleMessage("無効化するとログエントリを非表示"),
    "logs": MessageLookupByLibrary.simpleMessage("ログ"),
    "logsDesc": MessageLookupByLibrary.simpleMessage("ログキャプチャ記録"),
    "logsTest": MessageLookupByLibrary.simpleMessage("ログテスト"),
    "loopback": MessageLookupByLibrary.simpleMessage("ループバック解除ツール"),
    "loopbackDesc": MessageLookupByLibrary.simpleMessage("UWPループバック解除用"),
    "loose": MessageLookupByLibrary.simpleMessage("疎"),
    "manual": MessageLookupByLibrary.simpleMessage("手動"),
    "matchSourceIp": MessageLookupByLibrary.simpleMessage("送信元IPをマッチング"),
    "maxFailedTimes": MessageLookupByLibrary.simpleMessage("最大失敗回数"),
    "memoryInfo": MessageLookupByLibrary.simpleMessage("メモリ情報"),
    "messageTest": MessageLookupByLibrary.simpleMessage("メッセージテスト"),
    "messageTestTip": MessageLookupByLibrary.simpleMessage("これはメッセージです。"),
    "min": MessageLookupByLibrary.simpleMessage("最小化"),
    "minimizeOnExit": MessageLookupByLibrary.simpleMessage("終了時に最小化"),
    "minimizeOnExitDesc": MessageLookupByLibrary.simpleMessage(
      "システムの終了イベントを変更",
    ),
    "minutesAgo": m18,
    "mixedPort": MessageLookupByLibrary.simpleMessage("混合ポート"),
    "mode": MessageLookupByLibrary.simpleMessage("モード"),
    "monochromeScheme": MessageLookupByLibrary.simpleMessage("モノクローム"),
    "monthsAgo": m19,
    "more": MessageLookupByLibrary.simpleMessage("詳細"),
    "name": MessageLookupByLibrary.simpleMessage("名前"),
    "nameserver": MessageLookupByLibrary.simpleMessage("ネームサーバー"),
    "nameserverDesc": MessageLookupByLibrary.simpleMessage("ドメイン解決用"),
    "nameserverPolicy": MessageLookupByLibrary.simpleMessage("ネームサーバーポリシー"),
    "nameserverPolicyDesc": MessageLookupByLibrary.simpleMessage(
      "対応するネームサーバーポリシーを指定",
    ),
    "network": MessageLookupByLibrary.simpleMessage("ネットワーク"),
    "networkDesc": MessageLookupByLibrary.simpleMessage("ネットワーク関連設定の変更"),
    "networkDetection": MessageLookupByLibrary.simpleMessage("ネットワーク検出"),
    "networkException": MessageLookupByLibrary.simpleMessage(
      "ネットワーク例外、接続を確認してもう一度お試しください",
    ),
    "networkSpeed": MessageLookupByLibrary.simpleMessage("ネットワーク速度"),
    "networkType": MessageLookupByLibrary.simpleMessage("ネットワーク種別"),
    "neutralScheme": MessageLookupByLibrary.simpleMessage("ニュートラル"),
    "noData": MessageLookupByLibrary.simpleMessage("データなし"),
    "noHotKey": MessageLookupByLibrary.simpleMessage("ホットキーなし"),
    "noInfo": MessageLookupByLibrary.simpleMessage("情報なし"),
    "noLongerRemind": MessageLookupByLibrary.simpleMessage("今後表示しない"),
    "noNetwork": MessageLookupByLibrary.simpleMessage("ネットワークなし"),
    "noNetworkApp": MessageLookupByLibrary.simpleMessage("ネットワークなしアプリ"),
    "noNodeAssets": MessageLookupByLibrary.simpleMessage("ノードアセットなし"),
    "noRecords": MessageLookupByLibrary.simpleMessage("履歴なし"),
    "noResolve": MessageLookupByLibrary.simpleMessage("IPを解決しない"),
    "noResolveHostname": MessageLookupByLibrary.simpleMessage("ホスト名を解決しない"),
    "node": MessageLookupByLibrary.simpleMessage("ノード"),
    "nodeAssets": MessageLookupByLibrary.simpleMessage("ノードアセット"),
    "nodeImportCount": m20,
    "nodeImportNoDraft": MessageLookupByLibrary.simpleMessage("ノードを検出できません"),
    "nodeInput": MessageLookupByLibrary.simpleMessage("ノードデータ"),
    "nodeInputHint": MessageLookupByLibrary.simpleMessage(
      "ノード URI または Mihomo YAML/JSON を貼り付け",
    ),
    "nodeLibrary": MessageLookupByLibrary.simpleMessage("ノードライブラリ"),
    "nodes": MessageLookupByLibrary.simpleMessage("ノード"),
    "none": MessageLookupByLibrary.simpleMessage("なし"),
    "notSelectedTip": MessageLookupByLibrary.simpleMessage(
      "現在のプロキシグループは選択できません",
    ),
    "nullProfileDesc": MessageLookupByLibrary.simpleMessage(
      "プロファイルがありません。追加してください",
    ),
    "nullTip": m21,
    "numberTip": m22,
    "onDemand": MessageLookupByLibrary.simpleMessage("On Demand"),
    "onDemandDesc": MessageLookupByLibrary.simpleMessage(
      "Configure the program running state for specific scenarios",
    ),
    "onlyIcon": MessageLookupByLibrary.simpleMessage("アイコンのみ"),
    "onlyStatisticsProxy": MessageLookupByLibrary.simpleMessage("プロキシのみ統計"),
    "onlyStatisticsProxyDesc": MessageLookupByLibrary.simpleMessage(
      "有効化するとプロキシトラフィックのみ統計",
    ),
    "optional": MessageLookupByLibrary.simpleMessage("オプション"),
    "options": MessageLookupByLibrary.simpleMessage("オプション"),
    "other": MessageLookupByLibrary.simpleMessage("その他"),
    "outboundMode": MessageLookupByLibrary.simpleMessage("アウトバウンドモード"),
    "override": MessageLookupByLibrary.simpleMessage("上書き"),
    "overrideDns": MessageLookupByLibrary.simpleMessage("DNS上書き"),
    "overrideDnsDesc": MessageLookupByLibrary.simpleMessage(
      "有効化するとプロファイルのDNS設定を上書き",
    ),
    "overrideMode": MessageLookupByLibrary.simpleMessage("上書きモード"),
    "overrideScript": MessageLookupByLibrary.simpleMessage("上書きスクリプト"),
    "overwriteTypeCustom": MessageLookupByLibrary.simpleMessage("カスタム"),
    "overwriteTypeCustomDesc": MessageLookupByLibrary.simpleMessage(
      "カスタムモード、プロキシグループとルールを完全にカスタマイズ可能",
    ),
    "palette": MessageLookupByLibrary.simpleMessage("パレット"),
    "password": MessageLookupByLibrary.simpleMessage("パスワード"),
    "paste": MessageLookupByLibrary.simpleMessage("貼り付け"),
    "pleaseBindWebDAV": MessageLookupByLibrary.simpleMessage(
      "WebDAVをバインドしてください",
    ),
    "pleaseEnterScriptName": MessageLookupByLibrary.simpleMessage(
      "スクリプト名を入力してください",
    ),
    "pleaseInputAdminPassword": MessageLookupByLibrary.simpleMessage(
      "管理者パスワードを入力",
    ),
    "pleaseUploadValidQrcode": MessageLookupByLibrary.simpleMessage(
      "有効なQRコードをアップロードしてください",
    ),
    "port": MessageLookupByLibrary.simpleMessage("ポート"),
    "portConflictTip": MessageLookupByLibrary.simpleMessage("別のポートを入力してください"),
    "portTip": m23,
    "preferH3Desc": MessageLookupByLibrary.simpleMessage("DOHのHTTP/3を優先使用"),
    "prerequisites": MessageLookupByLibrary.simpleMessage("Prerequisites"),
    "pressKeyboard": MessageLookupByLibrary.simpleMessage("キーボードを押してください"),
    "preview": MessageLookupByLibrary.simpleMessage("プレビュー"),
    "process": MessageLookupByLibrary.simpleMessage("プロセス"),
    "profile": MessageLookupByLibrary.simpleMessage("プロファイル"),
    "profileAutoUpdateIntervalInvalidValidationDesc":
        MessageLookupByLibrary.simpleMessage("有効な間隔形式を入力してください"),
    "profileAutoUpdateIntervalNullValidationDesc":
        MessageLookupByLibrary.simpleMessage("自動更新間隔を入力してください"),
    "profileGroup": MessageLookupByLibrary.simpleMessage("プロファイルグループ"),
    "profileHasUpdate": MessageLookupByLibrary.simpleMessage(
      "プロファイルが変更されました。自動更新を無効化しますか？",
    ),
    "profileNameNullValidationDesc": MessageLookupByLibrary.simpleMessage(
      "プロファイル名を入力してください",
    ),
    "profileUrlInvalidValidationDesc": MessageLookupByLibrary.simpleMessage(
      "有効なプロファイルURLを入力してください",
    ),
    "profileUrlNullValidationDesc": MessageLookupByLibrary.simpleMessage(
      "プロファイルURLを入力してください",
    ),
    "profiles": MessageLookupByLibrary.simpleMessage("プロファイル一覧"),
    "profilesSort": MessageLookupByLibrary.simpleMessage("プロファイルの並び替え"),
    "project": MessageLookupByLibrary.simpleMessage("プロジェクト"),
    "protocol": MessageLookupByLibrary.simpleMessage("プロトコル"),
    "providers": MessageLookupByLibrary.simpleMessage("プロバイダー"),
    "proxies": MessageLookupByLibrary.simpleMessage("プロキシ"),
    "proxiesEmpty": MessageLookupByLibrary.simpleMessage("プロキシが空です"),
    "proxyChains": MessageLookupByLibrary.simpleMessage("プロキシチェーン"),
    "proxyDetectedAbnormal": MessageLookupByLibrary.simpleMessage(
      "選択されたプロキシに異常があることを検出しました",
    ),
    "proxyFilter": MessageLookupByLibrary.simpleMessage("プロキシフィルター"),
    "proxyGroup": MessageLookupByLibrary.simpleMessage("プロキシグループ"),
    "proxyGroupDetectedAbnormal": MessageLookupByLibrary.simpleMessage(
      "現在のプロキシグループが異常であることを検出しました",
    ),
    "proxyGroupEmpty": MessageLookupByLibrary.simpleMessage("プロキシグループが空です"),
    "proxyGroupNameDuplicate": MessageLookupByLibrary.simpleMessage(
      "プロキシグループ名が重複しています",
    ),
    "proxyGroupNameEmpty": MessageLookupByLibrary.simpleMessage(
      "プロキシグループ名は空にできません",
    ),
    "proxyNameserver": MessageLookupByLibrary.simpleMessage("プロキシネームサーバー"),
    "proxyNameserverDesc": MessageLookupByLibrary.simpleMessage(
      "プロキシノード解決用ドメイン",
    ),
    "proxyPort": MessageLookupByLibrary.simpleMessage("プロキシポート"),
    "proxyProviderDetectedAbnormal": MessageLookupByLibrary.simpleMessage(
      "選択されたプロキシプロバイダーに異常があることを検出しました",
    ),
    "proxyProviders": MessageLookupByLibrary.simpleMessage("プロキシプロバイダー"),
    "proxyProvidersEmpty": MessageLookupByLibrary.simpleMessage(
      "プロキシプロバイダーが空です",
    ),
    "proxyProvidersNotEmpty": MessageLookupByLibrary.simpleMessage(
      "プロキシプロバイダーは空にできません",
    ),
    "proxyType": MessageLookupByLibrary.simpleMessage("プロキシタイプ"),
    "pruneCache": MessageLookupByLibrary.simpleMessage("キャッシュの削除"),
    "pureBlackMode": MessageLookupByLibrary.simpleMessage("純黒モード"),
    "qrcode": MessageLookupByLibrary.simpleMessage("QRコード"),
    "qrcodeDesc": MessageLookupByLibrary.simpleMessage("QRコードをスキャンしてプロファイルを取得"),
    "quickFill": MessageLookupByLibrary.simpleMessage("クイック入力"),
    "rainbowScheme": MessageLookupByLibrary.simpleMessage("レインボー"),
    "rawConfig": MessageLookupByLibrary.simpleMessage("Mihomo Raw 設定"),
    "redirPort": MessageLookupByLibrary.simpleMessage("Redirポート"),
    "redo": MessageLookupByLibrary.simpleMessage("やり直す"),
    "remote": MessageLookupByLibrary.simpleMessage("リモート"),
    "remoteBackupDesc": MessageLookupByLibrary.simpleMessage(
      "WebDAVにデータをバックアップ",
    ),
    "remoteDestination": MessageLookupByLibrary.simpleMessage("リモート宛先"),
    "remove": MessageLookupByLibrary.simpleMessage("削除"),
    "rename": MessageLookupByLibrary.simpleMessage("リネーム"),
    "request": MessageLookupByLibrary.simpleMessage("リクエスト"),
    "requests": MessageLookupByLibrary.simpleMessage("リクエスト"),
    "requestsDesc": MessageLookupByLibrary.simpleMessage("最近のリクエスト記録を表示"),
    "reset": MessageLookupByLibrary.simpleMessage("リセット"),
    "resetPageChangesTip": MessageLookupByLibrary.simpleMessage(
      "現在のページに変更があります。リセットしてもよろしいですか？",
    ),
    "resetTip": MessageLookupByLibrary.simpleMessage("リセットを確定"),
    "resources": MessageLookupByLibrary.simpleMessage("リソース"),
    "resourcesDesc": MessageLookupByLibrary.simpleMessage("外部リソース関連情報"),
    "respectRules": MessageLookupByLibrary.simpleMessage("ルール尊重"),
    "respectRulesDesc": MessageLookupByLibrary.simpleMessage(
      "DNS接続がルールに従う（proxy-server-nameserverの設定が必要）",
    ),
    "restart": MessageLookupByLibrary.simpleMessage("再起動"),
    "restartCoreTip": MessageLookupByLibrary.simpleMessage("コアを再起動してもよろしいですか？"),
    "restore": MessageLookupByLibrary.simpleMessage("復元"),
    "restoreAllData": MessageLookupByLibrary.simpleMessage("すべてのデータを復元する"),
    "restoreException": MessageLookupByLibrary.simpleMessage("復元例外"),
    "restoreFromFileDesc": MessageLookupByLibrary.simpleMessage(
      "ファイルを介してデータを復元する",
    ),
    "restoreFromWebDAVDesc": MessageLookupByLibrary.simpleMessage(
      "WebDAVを介してデータを復元する",
    ),
    "restoreOnlyConfig": MessageLookupByLibrary.simpleMessage("設定ファイルのみを復元する"),
    "restoreStrategy": MessageLookupByLibrary.simpleMessage("復元ストラテジー"),
    "restoreStrategy_compatible": MessageLookupByLibrary.simpleMessage("互換"),
    "restoreStrategy_override": MessageLookupByLibrary.simpleMessage("上書き"),
    "restoreSuccess": MessageLookupByLibrary.simpleMessage("復元に成功しました"),
    "routeAddress": MessageLookupByLibrary.simpleMessage("ルートアドレス"),
    "routeAddressDesc": MessageLookupByLibrary.simpleMessage("ルートアドレスを設定"),
    "routeMode": MessageLookupByLibrary.simpleMessage("ルートモード"),
    "routeMode_bypassPrivate": MessageLookupByLibrary.simpleMessage(
      "プライベートルートをバイパス",
    ),
    "routeMode_config": MessageLookupByLibrary.simpleMessage("設定を使用"),
    "ru": MessageLookupByLibrary.simpleMessage("ロシア語"),
    "rule": MessageLookupByLibrary.simpleMessage("ルール"),
    "ruleActionAndDesc": MessageLookupByLibrary.simpleMessage("論理ルール AND"),
    "ruleActionDomainDesc": MessageLookupByLibrary.simpleMessage(
      "完全なドメインをマッチング",
    ),
    "ruleActionDomainKeywordDesc": MessageLookupByLibrary.simpleMessage(
      "ドメインキーワードをマッチング",
    ),
    "ruleActionDomainRegexDesc": MessageLookupByLibrary.simpleMessage(
      "ワイルドカードマッチング（*と?のみサポート）",
    ),
    "ruleActionDomainSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "ドメイン接尾辞をマッチング",
    ),
    "ruleActionDscpDesc": MessageLookupByLibrary.simpleMessage(
      "DSCPマークをマッチング (tproxy udp inboundのみ)",
    ),
    "ruleActionDstPortDesc": MessageLookupByLibrary.simpleMessage(
      "宛先ポート範囲をマッチング",
    ),
    "ruleActionGeoipDesc": MessageLookupByLibrary.simpleMessage(
      "IPの国コードをマッチング",
    ),
    "ruleActionGeositeDesc": MessageLookupByLibrary.simpleMessage(
      "Match domains within Geosite",
    ),
    "ruleActionInNameDesc": MessageLookupByLibrary.simpleMessage(
      "インバウンド名をマッチング",
    ),
    "ruleActionInPortDesc": MessageLookupByLibrary.simpleMessage(
      "インバウンドポートをマッチング",
    ),
    "ruleActionInTypeDesc": MessageLookupByLibrary.simpleMessage(
      "インバウンドタイプをマッチング",
    ),
    "ruleActionInUserDesc": MessageLookupByLibrary.simpleMessage(
      "インバウンドユーザー名をマッチング（/で複数指定可）",
    ),
    "ruleActionIpAsnDesc": MessageLookupByLibrary.simpleMessage("IPのASNをマッチング"),
    "ruleActionIpCidr6Desc": MessageLookupByLibrary.simpleMessage(
      "IPアドレス範囲をマッチング（IP-CIDR6はエイリアスです）",
    ),
    "ruleActionIpCidrDesc": MessageLookupByLibrary.simpleMessage(
      "IPアドレス範囲をマッチング",
    ),
    "ruleActionIpSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "IP接尾辞範囲をマッチング",
    ),
    "ruleActionMatchDesc": MessageLookupByLibrary.simpleMessage(
      "すべてのリクエストにマッチ（条件なし）",
    ),
    "ruleActionNetworkDesc": MessageLookupByLibrary.simpleMessage(
      "TCPまたはUDPをマッチング",
    ),
    "ruleActionNotDesc": MessageLookupByLibrary.simpleMessage("論理ルール NOT"),
    "ruleActionOrDesc": MessageLookupByLibrary.simpleMessage("論理ルール OR"),
    "ruleActionProcessNameDesc": MessageLookupByLibrary.simpleMessage(
      "プロセス名でマッチング（Androidではパッケージ名）",
    ),
    "ruleActionProcessNameRegexDesc": MessageLookupByLibrary.simpleMessage(
      "プロセス名正規表現でマッチング（Androidではパッケージ名）",
    ),
    "ruleActionProcessPathDesc": MessageLookupByLibrary.simpleMessage(
      "フルプロセスパスでマッチング",
    ),
    "ruleActionProcessPathRegexDesc": MessageLookupByLibrary.simpleMessage(
      "プロセスパス正規表現でマッチング",
    ),
    "ruleActionRuleSetDesc": MessageLookupByLibrary.simpleMessage(
      "ルールセットを参照。rule-providersの設定が必要",
    ),
    "ruleActionSrcGeoipDesc": MessageLookupByLibrary.simpleMessage(
      "送信元IPの国コードをマッチング",
    ),
    "ruleActionSrcIpAsnDesc": MessageLookupByLibrary.simpleMessage(
      "送信元IPのASNをマッチング",
    ),
    "ruleActionSrcIpCidrDesc": MessageLookupByLibrary.simpleMessage(
      "送信元IPアドレス範囲をマッチング",
    ),
    "ruleActionSrcIpSuffixDesc": MessageLookupByLibrary.simpleMessage(
      "送信元IP接尾辞範囲をマッチング",
    ),
    "ruleActionSrcPortDesc": MessageLookupByLibrary.simpleMessage(
      "送信元ポート範囲をマッチング",
    ),
    "ruleActionSubRuleDesc": MessageLookupByLibrary.simpleMessage(
      "サブルールにマッチング。括弧の使用に注意",
    ),
    "ruleActionUidDesc": MessageLookupByLibrary.simpleMessage(
      "Linux USER IDをマッチング",
    ),
    "ruleEmpty": MessageLookupByLibrary.simpleMessage("ルールが空です"),
    "ruleName": MessageLookupByLibrary.simpleMessage("ルール名"),
    "ruleProviders": MessageLookupByLibrary.simpleMessage("ルールプロバイダー"),
    "ruleSet": MessageLookupByLibrary.simpleMessage("ルールセット"),
    "ruleTarget": MessageLookupByLibrary.simpleMessage("ルール対象"),
    "save": MessageLookupByLibrary.simpleMessage("保存"),
    "saveChanges": MessageLookupByLibrary.simpleMessage("変更を保存しますか？"),
    "script": MessageLookupByLibrary.simpleMessage("スクリプト"),
    "scriptModeDesc": MessageLookupByLibrary.simpleMessage(
      "スクリプトモード、外部拡張スクリプトを使用し、ワンクリックで設定を上書きする機能を提供",
    ),
    "search": MessageLookupByLibrary.simpleMessage("検索"),
    "seconds": MessageLookupByLibrary.simpleMessage("秒"),
    "secondsCount": m24,
    "selectAll": MessageLookupByLibrary.simpleMessage("すべて選択"),
    "selectChainTarget": MessageLookupByLibrary.simpleMessage("チェーンターゲットを選択"),
    "selectProxies": MessageLookupByLibrary.simpleMessage("プロキシを選択"),
    "selectProxyProviders": MessageLookupByLibrary.simpleMessage(
      "プロキシプロバイダーを選択",
    ),
    "selectRuleSet": MessageLookupByLibrary.simpleMessage("ルールセットを選択してください"),
    "selectSplitStrategy": MessageLookupByLibrary.simpleMessage(
      "分流戦略を選択してください",
    ),
    "selectSubRule": MessageLookupByLibrary.simpleMessage("サブルールを選択してください"),
    "selected": MessageLookupByLibrary.simpleMessage("選択済み"),
    "selectedCountTitle": m25,
    "server": MessageLookupByLibrary.simpleMessage("サーバー"),
    "setDefault": MessageLookupByLibrary.simpleMessage("デフォルトに設定"),
    "settings": MessageLookupByLibrary.simpleMessage("設定"),
    "show": MessageLookupByLibrary.simpleMessage("表示"),
    "shrink": MessageLookupByLibrary.simpleMessage("縮小"),
    "silentLaunch": MessageLookupByLibrary.simpleMessage("バックグラウンド起動"),
    "silentLaunchDesc": MessageLookupByLibrary.simpleMessage("バックグラウンドで起動"),
    "size": MessageLookupByLibrary.simpleMessage("サイズ"),
    "socksPort": MessageLookupByLibrary.simpleMessage("Socksポート"),
    "sort": MessageLookupByLibrary.simpleMessage("並び替え"),
    "source": MessageLookupByLibrary.simpleMessage("ソース"),
    "sourceIp": MessageLookupByLibrary.simpleMessage("送信元IP"),
    "specialProxy": MessageLookupByLibrary.simpleMessage("特殊プロキシ"),
    "specialRules": MessageLookupByLibrary.simpleMessage("特殊ルール"),
    "speedStatistics": MessageLookupByLibrary.simpleMessage("速度統計"),
    "splitStrategy": MessageLookupByLibrary.simpleMessage("分流戦略"),
    "splitStrategyNotEmpty": MessageLookupByLibrary.simpleMessage(
      "分流戦略は空にできません",
    ),
    "ssidsEmpty": MessageLookupByLibrary.simpleMessage("SSIDs is empty"),
    "stackMode": MessageLookupByLibrary.simpleMessage("スタックモード"),
    "stale": MessageLookupByLibrary.simpleMessage("古い"),
    "standard": MessageLookupByLibrary.simpleMessage("標準"),
    "standardModeDesc": MessageLookupByLibrary.simpleMessage(
      "標準モード、基本設定を上書きし、シンプルなルール追加機能を提供",
    ),
    "start": MessageLookupByLibrary.simpleMessage("開始"),
    "startVpn": MessageLookupByLibrary.simpleMessage("VPNを開始中..."),
    "status": MessageLookupByLibrary.simpleMessage("ステータス"),
    "statusDesc": MessageLookupByLibrary.simpleMessage("無効時はシステムDNSを使用"),
    "stop": MessageLookupByLibrary.simpleMessage("停止"),
    "stopVpn": MessageLookupByLibrary.simpleMessage("VPNを停止中..."),
    "strictRoute": MessageLookupByLibrary.simpleMessage("厳格ルーティング"),
    "strictRouteDesc": MessageLookupByLibrary.simpleMessage(
      "仮想アダプターを迂回する通信を遮断し、DNS と WebRTC の漏洩を防ぎます。仮想マシンや LAN アクセスに影響する場合があります",
    ),
    "style": MessageLookupByLibrary.simpleMessage("スタイル"),
    "subRule": MessageLookupByLibrary.simpleMessage("サブルール"),
    "subRuleEmpty": MessageLookupByLibrary.simpleMessage("サブルールが空です"),
    "subRuleNotEmpty": MessageLookupByLibrary.simpleMessage("サブルールは空にできません"),
    "submit": MessageLookupByLibrary.simpleMessage("送信"),
    "suspended": MessageLookupByLibrary.simpleMessage("一時停止中..."),
    "sync": MessageLookupByLibrary.simpleMessage("同期"),
    "system": MessageLookupByLibrary.simpleMessage("システム"),
    "systemApp": MessageLookupByLibrary.simpleMessage("システムアプリ"),
    "systemProxy": MessageLookupByLibrary.simpleMessage("システムプロキシ"),
    "systemProxyDesc": MessageLookupByLibrary.simpleMessage(
      "HTTPプロキシをVpnServiceに接続",
    ),
    "tab": MessageLookupByLibrary.simpleMessage("タブ"),
    "tabAnimation": MessageLookupByLibrary.simpleMessage("タブアニメーション"),
    "tabAnimationDesc": MessageLookupByLibrary.simpleMessage("モバイル表示でのみ有効"),
    "tailscale": MessageLookupByLibrary.simpleMessage("Tailscale"),
    "tailscaleDesc": MessageLookupByLibrary.simpleMessage(
      "Tailscale ネットワークを設定",
    ),
    "tapToAuthorize": MessageLookupByLibrary.simpleMessage("タップして許可"),
    "tcpConcurrent": MessageLookupByLibrary.simpleMessage("TCP並列処理"),
    "tcpConcurrentDesc": MessageLookupByLibrary.simpleMessage("TCP並列処理を許可"),
    "testInterval": MessageLookupByLibrary.simpleMessage("テスト間隔"),
    "testUrl": MessageLookupByLibrary.simpleMessage("URLテスト"),
    "testWhenUsed": MessageLookupByLibrary.simpleMessage("使用時にテスト"),
    "textScale": MessageLookupByLibrary.simpleMessage("テキストスケーリング"),
    "theme": MessageLookupByLibrary.simpleMessage("テーマ"),
    "themeColor": MessageLookupByLibrary.simpleMessage("テーマカラー"),
    "themeDesc": MessageLookupByLibrary.simpleMessage("ダークモードの設定、色の調整"),
    "themeMode": MessageLookupByLibrary.simpleMessage("テーマモード"),
    "tight": MessageLookupByLibrary.simpleMessage("密"),
    "time": MessageLookupByLibrary.simpleMessage("時間"),
    "timeout": MessageLookupByLibrary.simpleMessage("タイムアウト"),
    "tip": MessageLookupByLibrary.simpleMessage("ヒント"),
    "toggle": MessageLookupByLibrary.simpleMessage("トグル"),
    "tonalSpotScheme": MessageLookupByLibrary.simpleMessage("トーンスポット"),
    "tools": MessageLookupByLibrary.simpleMessage("ツール"),
    "tproxyPort": MessageLookupByLibrary.simpleMessage("Tproxyポート"),
    "trafficUsage": MessageLookupByLibrary.simpleMessage("トラフィック使用量"),
    "tsAcceptRoutes": MessageLookupByLibrary.simpleMessage("サブネットルートを使用"),
    "tsAcceptRoutesDesc": MessageLookupByLibrary.simpleMessage(
      "TUN 経由で共有サブネットに接続",
    ),
    "tsAccepted": MessageLookupByLibrary.simpleMessage("適用済み"),
    "tsActive": MessageLookupByLibrary.simpleMessage("適用済み"),
    "tsAll": MessageLookupByLibrary.simpleMessage("すべて"),
    "tsAllPublic": MessageLookupByLibrary.simpleMessage("全インターネット通信"),
    "tsApplyFailed": MessageLookupByLibrary.simpleMessage("設定の適用に失敗。以前の設定を維持"),
    "tsApprovedRoutes": MessageLookupByLibrary.simpleMessage("サブネットルート"),
    "tsAuthExpired": MessageLookupByLibrary.simpleMessage("認証キーの期限切れ"),
    "tsAuthInvalid": MessageLookupByLibrary.simpleMessage("認証キーが無効"),
    "tsAuthKey": MessageLookupByLibrary.simpleMessage("認証キー"),
    "tsAuthRejected": MessageLookupByLibrary.simpleMessage("サーバーがログインを拒否"),
    "tsAuthUsed": MessageLookupByLibrary.simpleMessage("認証キーは使用済み"),
    "tsAuthorizing": MessageLookupByLibrary.simpleMessage("認証待ち"),
    "tsAutoRoute": MessageLookupByLibrary.simpleMessage("自動ルーティング"),
    "tsAutoRouteDesc": MessageLookupByLibrary.simpleMessage(
      "ルールモードで Tailscale 端末に接続",
    ),
    "tsAvailable": MessageLookupByLibrary.simpleMessage("利用可能"),
    "tsBackendDisconnected": MessageLookupByLibrary.simpleMessage("接続が切断されました"),
    "tsBackendError": MessageLookupByLibrary.simpleMessage(
      "操作に失敗しました。再試行してください",
    ),
    "tsBlocked": MessageLookupByLibrary.simpleMessage("対象の接続を停止"),
    "tsBrowserLogin": MessageLookupByLibrary.simpleMessage("ブラウザーでログイン"),
    "tsCachedWarning": MessageLookupByLibrary.simpleMessage("保存済みの情報を表示中"),
    "tsCancelLogin": MessageLookupByLibrary.simpleMessage("認証をキャンセル"),
    "tsCancelled": MessageLookupByLibrary.simpleMessage("キャンセル済み"),
    "tsCaptureFailed": MessageLookupByLibrary.simpleMessage(
      "ルーティング失敗。ネットワーク設定を確認",
    ),
    "tsCapturePending": MessageLookupByLibrary.simpleMessage("ルーティングの適用待ち"),
    "tsConnecting": MessageLookupByLibrary.simpleMessage("接続中"),
    "tsControlServer": MessageLookupByLibrary.simpleMessage("サーバー URL"),
    "tsControlWarning": MessageLookupByLibrary.simpleMessage("サーバー接続に問題があります"),
    "tsCustomServer": MessageLookupByLibrary.simpleMessage("カスタムサーバー"),
    "tsDerpPath": MessageLookupByLibrary.simpleMessage("リレー"),
    "tsDevices": MessageLookupByLibrary.simpleMessage("端末"),
    "tsDirectPath": MessageLookupByLibrary.simpleMessage("直接接続"),
    "tsEmbeddedNote": MessageLookupByLibrary.simpleMessage(
      "ログインしても端末のサービスは公開されません",
    ),
    "tsExit": MessageLookupByLibrary.simpleMessage("出口ノード"),
    "tsExitDesc": MessageLookupByLibrary.simpleMessage("出口ノード経由でインターネットに接続"),
    "tsExitDevice": MessageLookupByLibrary.simpleMessage("出口ノード"),
    "tsFallback": MessageLookupByLibrary.simpleMessage("元のルーティングを使用中"),
    "tsGroupSemantics": MessageLookupByLibrary.simpleMessage(
      "ルールで直接選ばれたグループのみ対象",
    ),
    "tsIPv6Missing": MessageLookupByLibrary.simpleMessage("IPv6 は未適用"),
    "tsInactive": MessageLookupByLibrary.simpleMessage("未適用"),
    "tsIntro": MessageLookupByLibrary.simpleMessage("Tailscale ネットワークに接続"),
    "tsInvalidAuthURL": MessageLookupByLibrary.simpleMessage(
      "ログインリンクが無効です。再試行してください",
    ),
    "tsInvalidServer": MessageLookupByLibrary.simpleMessage(
      "有効なアドレスを入力。リモート接続には HTTPS が必要",
    ),
    "tsKeepLocal": MessageLookupByLibrary.simpleMessage("ローカルを維持"),
    "tsKeyExpiry": MessageLookupByLibrary.simpleMessage("キーの有効期限"),
    "tsKeyLogin": MessageLookupByLibrary.simpleMessage("キーでログイン"),
    "tsLastSeen": MessageLookupByLibrary.simpleMessage("最終オンライン"),
    "tsLoading": MessageLookupByLibrary.simpleMessage("読み込み中"),
    "tsLoggedIn": MessageLookupByLibrary.simpleMessage("ログイン済み"),
    "tsLoggedOut": MessageLookupByLibrary.simpleMessage("未ログイン"),
    "tsLogout": MessageLookupByLibrary.simpleMessage("ログアウト"),
    "tsLogoutConfirm": MessageLookupByLibrary.simpleMessage(
      "ログアウトして端末のログイン情報を削除しますか？",
    ),
    "tsLogoutFailed": MessageLookupByLibrary.simpleMessage(
      "ログアウトが完了していません。再試行してください",
    ),
    "tsMissingBinding": MessageLookupByLibrary.simpleMessage("一部のグループが見つかりません"),
    "tsMissingExit": MessageLookupByLibrary.simpleMessage("出口ノードを利用できません"),
    "tsMissingGroup": MessageLookupByLibrary.simpleMessage("グループが見つかりません"),
    "tsNeedsLogin": MessageLookupByLibrary.simpleMessage("再ログインが必要"),
    "tsNoBinding": MessageLookupByLibrary.simpleMessage("グループ未選択"),
    "tsNoDevices": MessageLookupByLibrary.simpleMessage("他の端末がありません"),
    "tsNoGroups": MessageLookupByLibrary.simpleMessage("利用可能なグループがありません"),
    "tsNoProfile": MessageLookupByLibrary.simpleMessage("プロファイル未選択"),
    "tsNoSearchResults": MessageLookupByLibrary.simpleMessage("一致する端末がありません"),
    "tsNotProvided": MessageLookupByLibrary.simpleMessage("情報なし"),
    "tsNotTested": MessageLookupByLibrary.simpleMessage("未テスト"),
    "tsOS": MessageLookupByLibrary.simpleMessage("OS"),
    "tsOff": MessageLookupByLibrary.simpleMessage("未使用"),
    "tsOffline": MessageLookupByLibrary.simpleMessage("オフライン"),
    "tsOnline": MessageLookupByLibrary.simpleMessage("オンライン"),
    "tsOpenBrowser": MessageLookupByLibrary.simpleMessage("ブラウザーを開く"),
    "tsOriginalRouting": MessageLookupByLibrary.simpleMessage("切り替え時に対象の接続を終了"),
    "tsPartial": MessageLookupByLibrary.simpleMessage("一部適用"),
    "tsPause": MessageLookupByLibrary.simpleMessage("一時停止"),
    "tsPaused": MessageLookupByLibrary.simpleMessage("一時停止中"),
    "tsPeerRelay": MessageLookupByLibrary.simpleMessage("端末リレー"),
    "tsPending": MessageLookupByLibrary.simpleMessage("適用待ち"),
    "tsProbeExpired": MessageLookupByLibrary.simpleMessage("結果の期限切れ"),
    "tsProbeExplanation": MessageLookupByLibrary.simpleMessage("端末への接続を確認"),
    "tsProbeFailed": MessageLookupByLibrary.simpleMessage("テスト失敗"),
    "tsProbeSuccess": MessageLookupByLibrary.simpleMessage("テスト成功"),
    "tsProxyOnly": MessageLookupByLibrary.simpleMessage("プロキシ通信のみ対象"),
    "tsQRCode": MessageLookupByLibrary.simpleMessage("認証 QR コード"),
    "tsRefreshDevices": MessageLookupByLibrary.simpleMessage("端末を更新"),
    "tsRemoteWarning": MessageLookupByLibrary.simpleMessage(
      "リモートルートを使用しますか？このサブネットへのローカル接続に影響します",
    ),
    "tsResume": MessageLookupByLibrary.simpleMessage("再開"),
    "tsRetry": MessageLookupByLibrary.simpleMessage("再試行"),
    "tsReturnOriginal": MessageLookupByLibrary.simpleMessage("元のルーティングを使用"),
    "tsRouting": MessageLookupByLibrary.simpleMessage("ルーティング"),
    "tsRuleRequired": MessageLookupByLibrary.simpleMessage("ルールモードでのみ有効"),
    "tsSearch": MessageLookupByLibrary.simpleMessage("端末を検索"),
    "tsSelectDevice": MessageLookupByLibrary.simpleMessage("端末の詳細を表示"),
    "tsSelectedGroups": MessageLookupByLibrary.simpleMessage("選択したグループ"),
    "tsServerUnreachable": MessageLookupByLibrary.simpleMessage(
      "サーバー接続に失敗しました",
    ),
    "tsServiceStopped": MessageLookupByLibrary.simpleMessage("サービス停止中"),
    "tsSplit": MessageLookupByLibrary.simpleMessage("ルーティング"),
    "tsStopConnections": MessageLookupByLibrary.simpleMessage("関連する接続を停止"),
    "tsStopTests": MessageLookupByLibrary.simpleMessage("テストをキャンセル"),
    "tsStopping": MessageLookupByLibrary.simpleMessage("停止中"),
    "tsSubnetConflict": MessageLookupByLibrary.simpleMessage("ローカルネットワークと重複"),
    "tsTest": MessageLookupByLibrary.simpleMessage("接続をテスト"),
    "tsTestAll": MessageLookupByLibrary.simpleMessage("一覧の端末をテスト"),
    "tsTesting": MessageLookupByLibrary.simpleMessage("テスト中"),
    "tsThisDevice": MessageLookupByLibrary.simpleMessage("この端末"),
    "tsUnapprovedExit": MessageLookupByLibrary.simpleMessage("出口ノード未承認"),
    "tsUnknown": MessageLookupByLibrary.simpleMessage("不明"),
    "tsUnsupported": MessageLookupByLibrary.simpleMessage(
      "このバージョンでは Tailscale は有効になっていません",
    ),
    "tsUseExit": MessageLookupByLibrary.simpleMessage("出口に設定"),
    "tsUseRemote": MessageLookupByLibrary.simpleMessage("リモートを使用"),
    "tsWaitingApproval": MessageLookupByLibrary.simpleMessage("承認待ち"),
    "tsWhenUnavailable": MessageLookupByLibrary.simpleMessage("出口が利用できない場合"),
    "tun": MessageLookupByLibrary.simpleMessage("TUN"),
    "tunDesc": MessageLookupByLibrary.simpleMessage("管理者モードでのみ有効"),
    "tunIpv6": MessageLookupByLibrary.simpleMessage("TUN IPv6"),
    "tunIpv6Desc": MessageLookupByLibrary.simpleMessage(
      "仮想アダプターに IPv6 を担当させます。IPv6 がトンネルを迂回しなくなりますが、直結通信は本機に有効な IPv6 接続があることが前提になります",
    ),
    "turnOff": MessageLookupByLibrary.simpleMessage("オフ"),
    "turnOn": MessageLookupByLibrary.simpleMessage("オン"),
    "unbind": MessageLookupByLibrary.simpleMessage("バインド解除"),
    "undo": MessageLookupByLibrary.simpleMessage("元に戻す"),
    "unifiedDelay": MessageLookupByLibrary.simpleMessage("統一遅延"),
    "unifiedDelayDesc": MessageLookupByLibrary.simpleMessage(
      "ハンドシェイクなどの余分な遅延を削除",
    ),
    "unknown": MessageLookupByLibrary.simpleMessage("不明"),
    "unknownNetworkError": MessageLookupByLibrary.simpleMessage("不明なネットワークエラー"),
    "unnamed": MessageLookupByLibrary.simpleMessage("無題"),
    "update": MessageLookupByLibrary.simpleMessage("更新"),
    "upload": MessageLookupByLibrary.simpleMessage("アップロード"),
    "url": MessageLookupByLibrary.simpleMessage("URL"),
    "urlDesc": MessageLookupByLibrary.simpleMessage("URL経由でプロファイルを取得"),
    "urlTip": m26,
    "useHosts": MessageLookupByLibrary.simpleMessage("ホストを使用"),
    "useSystemHosts": MessageLookupByLibrary.simpleMessage("システムホストを使用"),
    "userAgent": MessageLookupByLibrary.simpleMessage("ユーザーエージェント"),
    "username": MessageLookupByLibrary.simpleMessage("ユーザー名"),
    "value": MessageLookupByLibrary.simpleMessage("値"),
    "vibrantScheme": MessageLookupByLibrary.simpleMessage("ビブラント"),
    "view": MessageLookupByLibrary.simpleMessage("表示"),
    "vpnConfigChangeDetected": MessageLookupByLibrary.simpleMessage(
      "VPN設定の変更が検出されました",
    ),
    "vpnEnableDesc": MessageLookupByLibrary.simpleMessage(
      "VpnService経由で全システムトラフィックをルーティング",
    ),
    "vpnTip": MessageLookupByLibrary.simpleMessage("変更はVPN再起動後に有効"),
    "webDAVConfiguration": MessageLookupByLibrary.simpleMessage("WebDAV設定"),
    "whitelistMode": MessageLookupByLibrary.simpleMessage("ホワイトリストモード"),
    "yearsAgo": m27,
    "zh_CN": MessageLookupByLibrary.simpleMessage("簡体字中国語"),
  };
}
