# Avalon 客户端

Avalon 的 Flutter 应用，真实入口为 `lib/main.dart`。本文说明开发、检查和设备运行；功能约定见 [产品规格](../docs/PRODUCT_SPEC.md)，当前实现与待验收项见 [当前状态](../docs/STATUS.md)，完整文档见 [导航](../docs/README.md)。

共享设计系统位于 `../packages/av_design/`，纯 Dart 领域模型与配置管线位于 `../packages/av_core/`。V3 复刻画廊位于 `gallery/`，在 `lib/` 之外，仅用于开发，不进入发布构建。

官网为 [getavalon.app](https://getavalon.app)。V2 应用标识为 `app.getavalon.avalon`（D117）；此前 V2 开发包切换应用标识前，先导出密码保护的备份，再在新安装中恢复。更换标识不会自动迁移旧安装的数据或密钥；保留原安装和备份，直到恢复结果核对完成。V1 跨代备份兼容尚未验收。

## 开发

在仓库根目录准备固定版本的 Flutter 和 workspace 依赖：

```sh
mise install
mise exec -- flutter pub get
```

随后在 `app/` 运行：

```sh
mise exec -- flutter run
```

Android 构建前需要 AAR，iOS／macOS 构建前需要 Apple xcframework，均由 [Core Bridge 构建脚本](../core/README.md) 生成。运行画廊使用 `mise exec -- flutter run -t gallery/main.dart`。

### 检查

在 `app/` 执行：

```sh
mise exec -- dart format lib gallery test integration_test tool
mise exec -- flutter analyze --no-pub
mise exec -- flutter test --no-pub
```

一次完整变更还需要检查两个 workspace 包与 Go Bridge。界面复测使用 `tool/fidelity/`，步骤见 [UI_DESIGN_SYSTEM §4](../docs/UI_DESIGN_SYSTEM.md#4-如何复测)；按需画布渲染需要 macOS 系统字体。

### V2 CI

[V2 CI](../.github/workflows/ci.yml) 在推送 `main`、向 `main` 提交 PR 或手动触发时只运行三个 workspace 包、Go Bridge、配置加载、公开契约及打包工具等检查，无需发行签名。

[V2 Release](../.github/workflows/release.yml) 仅在推送与 `app/pubspec.yaml` 一致的三段版本标签 `vX.Y.Z` 时构建和发布；先复用完整检查，使用 [V1 发行说明模板](../.github/release_template.md)，保留既有标签和 Releases。当前可发行制品为正式签名的 Android 三 ABI APK、更新 manifest、源码与许可信息及校验和；其他平台构建保存为 Actions 验证制品，正式发行条件见 [D118](../docs/DECISIONS.md)。

Android 发行需要四个 Actions secrets：`KEYSTORE`（base64 编码的 keystore）、`KEY_ALIAS`、`STORE_PASSWORD`、`KEY_PASSWORD`；缺少任何一项均停止发行。同标识升级沿用相同正式密钥。本地 Release 使用 `AVALON_KEYSTORE_PATH`、`AVALON_KEY_ALIAS`、`AVALON_STORE_PASSWORD`、`AVALON_KEY_PASSWORD`；全部缺失时仅生成 unsigned 验证包，部分配置报错。

## 账号与同步客户端

账号、设备和同步的客户端规则见 [CLOUD_SYNC](../docs/CLOUD_SYNC.md)，公开字段与凭据边界见 [API 文档](../docs/api/README.md)，已测范围与剩余验收见 [Cloud 状态](../docs/STATUS.md#cloud)。

正式 Release 的 Cloud 入口仍隐藏。开发预览须在构建时同时传入 `--dart-define=AVALON_CLOUD_PREVIEW=true` 和 `--dart-define=AVALON_CLOUD_BASE_URL=<获授权的接口地址>`；使用 HTTPS，HTTP 仅允许 loopback。默认使用协议1；协议2生命周期预览还需 `--dart-define=AVALON_CLOUD_SYNC_VERSION=2`。覆盖安装预览包时保留所需参数；开关不改变账号权益或同步资格，也不自动降级协议。

外部接口联调用例仅在显式提供获授权的隔离环境时运行；环境跳过不计为通过。日志不得包含邮箱、验证码、令牌、代理凭据或请求／响应正文。

<a id="android-device-testing"></a>

## 在 Android 真机上测试

手机开启开发者选项与 USB 调试，解锁后允许电脑调试。使用 Android SDK 的 `adb devices -l` 确认目标状态为 `device`；`unauthorized` 需要手机授权，`offline` 需要恢复 USB 连接。部分手机还会单独询问是否允许通过 USB 安装。

在 `app/` 构建 arm64 Profile 包并安装到指定手机；Profile 使用开发签名，适合真机交互与性能调试：

```sh
mise exec -- flutter build apk --profile --target-platform android-arm64 --split-per-abi -t lib/main.dart
adb -s <Android设备序列号> install -r build/app/outputs/flutter-apk/app-arm64-v8a-profile.apk
adb -s <Android设备序列号> shell am start -n app.getavalon.avalon/.MainActivity
```

`install -r` 保留同标识安装的本地数据；同包名升级需要相同签名。其他架构应选择匹配的 APK。验证 Release 时，先配置上述四项本地签名变量，再将构建模式与文件名中的 `profile` 改为 `release`；未配置时只会生成 unsigned 验证 APK，不能安装到手机。正式发行签名与渠道验收另行准备。

1. 「配置 → 添加 → 独立节点」粘贴分享链接，点击「解析」并「保存」；在「代理」页确认目标节点被选中，点击「测速」。首次安装保存独立节点后会选择自建来源。
2. 在「仪表盘」选择「全局模式」，确认 TUN 开启，点击电源按钮；按实际提示允许通知和 VPN。连接状态应为「已连接」。
3. 在浏览器访问 HTTPS 页面并核对出口 IP，同时检查仪表盘流量和「工具 → 连接」。测速成功不能单独证明其他应用的流量已进入 VPN。
4. 返回桌面、锁屏后再联网；回到应用确认连接保持。然后停止代理，核对系统 VPN 已停止及直接联网恢复。完整 DNS／IPv6 泄漏、耗电与中断恢复的已测范围见 [平台状态](../docs/STATUS.md#platform-status)。

若启动失败，记录弹窗详情和「工具 → 日志」的实际错误。Android 每个用户只能有一个活动 VPN，测试前应确认其他 VPN 或始终开启的 VPN 是否会影响接管；不自动关闭其他应用。

<a id="update-the-main-app-on-an-ios-simulator"></a>

## 更新 iOS 模拟器主应用

在 `app/` 构建真实入口，并覆盖运行中模拟器的安装：

```sh
mise exec -- flutter build ios --simulator --debug -t lib/main.dart
AVALON_SIM=booted
xcrun simctl terminate "$AVALON_SIM" app.getavalon.avalon 2>/dev/null || true
xcrun simctl install "$AVALON_SIM" build/ios/iphonesimulator/Runner.app
xcrun simctl launch "$AVALON_SIM" app.getavalon.avalon
```

同时运行多个模拟器时，用指定 UDID 替代 `booted`，可通过 `xcrun simctl list devices booted` 列出。结束进程时可能提示应用已经停止。覆盖相同 bundle ID 会保留本机数据；先卸载则会删除数据容器。

主应用与画廊共用 bundle ID 和构建输出路径，因此安装前须重新构建目标入口。`tool/fidelity/ios.sh` 驱动画廊开发专用的远程入口（`gallery/main.dart` 或真实应用测试包装 `gallery/app_main.dart`）；普通 `lib/main.dart` 安装使用上述 `simctl` 命令。模拟器覆盖安装不提供签名 VPN 授权，也不构成 Packet Tunnel 验收。

<a id="iphone-device-testing"></a>

## 在 iPhone 上测试

Avalon 包含 Packet Tunnel 扩展。真机代理测试需要有开发签名权限的 Apple Developer Program 团队；免费 Personal Team 不支持 Network Extensions（[Apple 能力表](https://developer.apple.com/help/account/reference/supported-capabilities-ios/)）。

1. USB 连接并解锁 iPhone，在设备上接受「信任此电脑」。在 Xcode 的设备窗口完成配对；iPhone「设置 → 隐私与安全性 → 开发者模式」开启后，按提示重启并确认启用。
2. 在 Xcode 设置中登录有团队权限的 Apple 账号，打开 `ios/Runner.xcworkspace`。给 `Runner`、`PacketTunnel` 选择同一 Team 并启用自动签名，确认两者具有 `Network Extensions` 的 `Packet Tunnel` 能力及同一 `App Groups` 标识。
3. 当前主应用标识为 `app.getavalon.avalon`，扩展为 `app.getavalon.avalon.PacketTunnel`，iOS App Group 为 `group.app.getavalon.avalon`；macOS 使用 `$(DEVELOPMENT_TEAM).app.getavalon.avalon`。若团队需要不同的注册标识，统一修改 Runner 的 Debug／Profile／Release bundle ID 与对应平台的 `Host.xcconfig`；应用和扩展的 Group 必须一致。
4. 配对和签名完成后，在 `app/` 执行以下命令，使用设备列表中的真实 iPhone ID：

   ```sh
   mise exec -- flutter devices
   mise exec -- flutter run --profile -d <iPhone设备ID> -t lib/main.dart
   ```

5. 导入节点并选中，先测速，再开启代理并允许系统添加 VPN。确认实际出口与流量，验证模式和节点切换；随后测试后台／锁屏后联网及停止代理。扩展峰值内存、泄漏与中断恢复的已测范围见 [平台状态](../docs/STATUS.md#platform-status)。

`--no-codesign` 构建只检查真机目标编译，生成的应用仍需有效签名才能部署。

<a id="ios-runtime-development"></a>

## iOS 运行宿主开发

构建应用前，在仓库根目录用 `core/build.sh apple` 生成 `core/out/AvalonCore.xcframework`。宿主、测速实例与受保护存储的职责见 [RUNTIME_HOST §8](../docs/RUNTIME_HOST.md#8-平台宿主)。模拟器可验证原生通道与无入站测速，VPN prepare／start 返回 `UNSUPPORTED`；真实隧道、后台存活与 扩展内存验收使用签名真机应用。

在 macOS 上运行 `tool/check_ios_storage.sh`，可不签名、不启动 VPN 地检查受保护路径、原子恢复与已保存选择。Xcode 的 `tool/check_apple_core.sh` 阶段会拒绝缺失或过期的内核 slice。

开发专用入口 `gallery/ios_host_probe.dart` 在模拟器上检查真实通道、内核版本、停止快照与无入站 HTTP 测速，同时确认 VPN prepare 返回 `UNSUPPORTED`。用 `mise exec -- flutter build ios --simulator --debug -t gallery/ios_host_probe.dart` 构建，再按上述方式安装与启动；安全结果写入应用容器的 `tmp/avalon-ios-host-probe.json`。完成后重新构建并安装 `lib/main.dart`；probe 在 `lib/` 外，不属于主应用。
