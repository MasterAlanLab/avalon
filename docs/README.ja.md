<div align="center">
  <img src="../tool/branding/icon.svg" width="144" height="144" alt="Avalon Gate icon">
  <h1>Avalon</h1>
  <p><strong>Route · Connect · Control</strong></p>
  <p>
    <a href="https://github.com/MasterAlanLab/avalon/releases"><img src="https://img.shields.io/github/v/release/MasterAlanLab/avalon?display_name=tag&amp;style=flat-square&amp;logo=github&amp;logoColor=white&amp;label=Release&amp;color=E3A72F&amp;cacheSeconds=300" alt="Latest release"></a>
    <a href="https://github.com/MasterAlanLab/avalon/actions/workflows/build.yaml"><img src="https://img.shields.io/github/actions/workflow/status/MasterAlanLab/avalon/build.yaml?style=flat-square&amp;logo=githubactions&amp;logoColor=white&amp;label=Build" alt="Build status"></a>
    <a href="../LICENSE"><img src="https://img.shields.io/badge/License-AGPL--3.0-17191D?style=flat-square&amp;logo=gnu&amp;logoColor=white" alt="AGPL-3.0 license"></a>
    <a href="https://github.com/MasterAlanLab/avalon/releases"><img src="https://img.shields.io/badge/Android-arm64%20%7C%20armv7%20%7C%20x86__64-3DDC84?style=flat-square&amp;logo=android&amp;logoColor=white" alt="Android: arm64, armv7, x86_64"></a>
    <a href="https://github.com/MasterAlanLab/avalon/releases"><img src="https://img.shields.io/badge/Windows-x64-0078D4?style=flat-square&amp;logo=windows11&amp;logoColor=white" alt="Windows: x64"></a>
    <a href="https://github.com/MasterAlanLab/avalon/releases"><img src="https://img.shields.io/badge/macOS-ARM64-000000?style=flat-square&amp;logo=apple&amp;logoColor=white" alt="macOS: ARM64"></a>
    <a href="https://github.com/MasterAlanLab/avalon/releases"><img src="https://img.shields.io/badge/Linux-x64-FCC624?style=flat-square&amp;logo=linux&amp;logoColor=17191D" alt="Linux: x64"></a>
  </p>
</div>

[简体中文](../README.md) · [English](README.en.md) · [العربية](README.ar.md) · [Deutsch](README.de.md) · [Español](README.es.md) · [Italiano](README.it.md) · [日本語](README.ja.md) · [한국어](README.ko.md)

Android、Windows、macOS、Linux 向けのプロキシクライアント。[mihomo](https://github.com/MetaCubeX/mihomo) をコアに採用し、独立したノード管理、サブスクリプション管理、マルチホップのプロキシチェーンに対応しています。Flutter で開発されています。

> Avalon は [FlClash](https://github.com/chen08209/FlClash) をベースに開発されています。

各プラットフォームのインストールパッケージは [Releases](https://github.com/MasterAlanLab/avalon/releases) からダウンロードできます。

## 主な機能

- 対応プロトコル：VLESS、VMess、Shadowsocks、Trojan、Hysteria2、TUIC、AnyTLS、SOCKS4/4a/5、HTTP(S) など。
- ノード管理：ノードを個別に管理し、追加、編集、複製、プロファイルへの関連付けに対応。
- サブスクリプション管理：URL やローカルファイルからプロファイルをインポートし、サブスクリプションを自動更新。
- プロキシチェーン：ノード、プロキシグループ、ローカルのプロキシエンドポイントを組み合わせ、前段プロキシ、マルチホップ接続、経路プレビューに対応。
- プロファイル生成：チェーンから実行可能なプロファイルを作成するほか、既存プロファイルのプロキシグループにチェーンを追加。
- インポート・エクスポート：ノード URI、QR コード、YAML / JSON に対応。ノードやチェーンを関連ファイルとまとめてエクスポート可能。
- ルーティングルール：Rule、Global、Direct モードに対応し、ルールやプロキシグループを編集可能。
- ネットワーク診断：ノードの遅延テスト、リアルタイムの接続確認、実行ログ。
- データ同期：ローカルのバックアップ・復元、WebDAV による同期。
- テーマ：デスクトップ・モバイル向けレイアウト、ダークモード、配色のカスタマイズ。
- Tailscale：デバイスの確認、Tailnet のルーティング、リモートサブネットと出口ノードの設定。

## 動作モード

| モード | 説明 |
| :--- | :--- |
| Rule | プロファイルのルールに従って接続経路を選択 |
| Global | コアに入るすべての通信を、グローバルプロキシグループで選択した経路に転送 |
| Direct | プロキシノードを使わず、接続先へ直接接続 |

デスクトップはシステムプロキシと TUN、Android は VPN サービスで通信を取り込みます。システムプロキシの対象はプロキシ設定に従うアプリのみです。TUN/VPN の対象はルート、IPv6、アクセス制御の設定に従います。

## コアエンジン

[mihomo](https://github.com/MetaCubeX/mihomo) がプロキシ接続、DNS 解決、ルールベースのルーティング、TUN 通信を処理します。プロトコル別の入力フォームに加え、Raw YAML / JSON でほかの mihomo ノードタイプを設定できます。

サブスクリプション、ノードライブラリ、プロキシチェーンを統合して実行設定を生成します。チェーンは `dialer-proxy` で各ホップをつなぎ、「クライアント → 前段プロキシ → メインノード → 後段プロキシ → 接続先」の順に、単一のコアインスタンスで接続を処理します。

## 開発

リポジトリのルートで実行します。CI は Flutter 3.44.4 と Go 1.26.4 を使用し、ネイティブコンポーネントには Rust と各プラットフォームのツールチェーンも必要です。

```bash
flutter pub get
flutter analyze --no-fatal-infos
flutter test
```

## ドキュメント

- [開発とビルド（中国語）](development.md)：環境設定、コアとアプリのビルド、テスト、コード生成、CI。
- [Tailscale（中国語）](tailscale.md)：ログイン、ルーティング、出口ノード、ID 管理、既知の問題。
- [リリースワークフロー](../.github/workflows/build.yaml)：プラットフォーム別のパッケージとリリース設定。

## 技術スタック

- 言語：Dart、Go、Rust
- UI フレームワーク：Flutter / Material Design
- 状態管理：Riverpod
- データベース：SQLite / Drift
- プロキシコア：mihomo
- パッケージ管理：Pub、Go Modules、Cargo

## おすすめリソース

一部のリンクはアフィリエイトリンクです。リンク経由の登録や購入により、作者に報酬が入る場合があります。サービス内容と価格は各サイトをご確認ください。

| カテゴリ | プロジェクト / サービス | 説明 |
| :--- | :--- | :--- |
| プロキシプール | [Free Proxy](https://github.com/MasterAlanLab/free-proxy) | ノードライブラリやチェーンで使えるセルフホスト型プロキシプール |
| VPS | [BandwagonHost](https://cutt.ly/qywJNWzd) · [DMIT](https://cutt.ly/YywJIzY0) | ノードやアプリのホスティング |
| 仮想クレジットカード | [海外向け仮想カード](https://cutt.ly/IyrMR4Mg) | 海外サービスの支払い |
| リソース検索 | [Telegram 検索ボット](https://cutt.ly/2yeh3GOE) | Telegram 内のリソース検索 |
| アカウント・SIM | [海外アカウント・SIM カード](https://cutt.ly/dywt86NC) | アカウント・通信サービス |
| フィンガープリントブラウザ | [BitBrowser](https://client.bitbrowser.cn/register?lang=zh&code=Alan123) | 独立したブラウザ環境の管理 |
| メールホスティング | [Emailbox](https://github.com/MasterAlanLab/emailbox) | メールの一括管理とプロキシのグループ分け |
| CAPTCHA サービス | [Captcha.run](https://captcha.run/sso?inviter=542f4f4f-31b6-4b70-b485-c4762c45d1e8) · [YesCaptcha](https://cutt.ly/Mywt39r0) | CAPTCHA 認識 |
| AI API | [CC / GPT 中継](https://cutt.ly/JywJG3G5) | モデル API サービス |
| サブスクリプション共有 | [サブスクリプション共有サービス](https://cutt.ly/5ywt8vb4) | サブスクリプションの共同利用 |

## ライセンス

[AGPL-3.0](../LICENSE)。サードパーティのコードにはそれぞれのライセンスが適用されます。著作権とライセンスの詳細は [NOTICE](../NOTICE) を参照してください。

## 謝辞

- [FlClash](https://github.com/chen08209/FlClash)
- [mihomo](https://github.com/MetaCubeX/mihomo)
- [Surfboard](https://github.com/getsurfboard/surfboard)
