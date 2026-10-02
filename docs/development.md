# 开发与构建

从仓库根目录执行下列命令。应用功能见 [README](../README.md)，Tailscale 使用与已知问题见 [Tailscale](tailscale.md)。

## 环境与初始化

| 工具 | 仓库当前配置 |
| :--- | :--- |
| Flutter | CI 使用 3.44.4，Dart 随 Flutter SDK 安装 |
| Go | CI 使用 1.26.4 |
| Rust | stable 工具链；依赖使用各组件的 Cargo.lock |
| Android | JDK 21、SDK 36、NDK 28.2.13676358；最低 API 23 |
| Windows | Visual Studio C++ 桌面工具、GCC、Inno Setup |
| macOS | 完整 Xcode、Swift Package Manager、CocoaPods、Node.js / npm |
| Linux | Ubuntu/Debian 构建环境；GTK、AppIndicator、Keybinder、libsecret 等 |

版本来源：[发布工作流](../.github/workflows/build.yaml)、[Android 配置](../android/gradle/libs.versions.toml)。macOS 完整应用构建需要完整 Xcode，单独安装 Command Line Tools 只满足部分命令行构建。Swift Package Manager 可用 `flutter config --enable-swift-package-manager` 启用。

```bash
git clone https://github.com/MasterAlanLab/avalon.git
cd avalon
# 子模块配置使用 GitHub SSH；以下单次配置使用 HTTPS 下载，不更改全局 Git 设置。
git -c url.https://github.com/.insteadOf=git@github.com: submodule update --init --recursive
flutter pub get
```

已有工作区只需补齐子模块和依赖，保留本地改动。将 Flutter、Go、Cargo 加入 PATH；设置 `FLUTTER_ROOT` 时应指向同一个 Flutter SDK。

## 核心构建

[buildkit](../plugins/setup/buildkit/build_tool/lib/src/build_tool.dart) 是 Go 核心和桌面 helper 的构建入口，Flutter 平台构建也会调用它。默认标签为 `with_gvisor`；输入指纹未变化时复用产物，`--force` 强制重建。

```bash
# macOS：其余桌面平台使用 linux / windows，架构使用 amd64 / arm64。
bash plugins/setup/buildkit/run_build_tool.sh macos --arch arm64 --force

# Android：ANDROID_NDK 指向已安装的 NDK 目录。
export ANDROID_NDK="$HOME/Library/Android/sdk/ndk/28.2.13676358"
bash plugins/setup/buildkit/run_build_tool.sh android --arch arm64 --force
```

Android 架构参数为 `arm`、`arm64`、`amd64`；省略时构建全部 ABI。SDK/NDK 路径按宿主实际安装位置设置。Windows PowerShell 可直接从 `plugins/setup/buildkit/build_tool` 执行 `dart run bin/build_tool.dart windows --arch amd64 --root-dir <仓库绝对路径>`，先在该目录执行 `dart pub get`。

| 平台 | 核心产物 |
| :--- | :--- |
| macOS | `libclash/macos/AvalonCore` |
| Linux | `libclash/linux/AvalonCore` |
| Windows | `libclash/windows/AvalonCore.exe`，另构建 `AvalonHelperService.exe` |
| Android | `libclash/android/<ABI>/libclash.so` |

### mihomo 子模块补丁

当前 gitlink 固定为 `0f7f05adff5e2c49775a112dcfe05a6aa36fda0c`。Tailscale 扩展保存在 [tailscale-v2.patch](../core/patches/tailscale-v2.patch)。buildkit 在计算指纹前检查并应用补丁；已应用时跳过，版本或内容冲突时退出，并保留原工作区改动。

直接运行 Go 检查前执行：

```bash
bash tool/apply_tailscale_patch.sh
```

升级子模块时需重基补丁，同步 shell 脚本与 buildkit 中的固定 revision，并复验干净检出、重复应用和冲突处理。只更新 gitlink 或 revision 会留下补丁不匹配的问题。

## 应用与发布包

```bash
dart setup.dart android --arch arm64
# 以下桌面命令分别在对应操作系统执行。
dart setup.dart windows
dart setup.dart macos
dart setup.dart linux
```

`setup.dart` 默认环境为 `pre`；`--env dev|pre|stable` 设置应用环境，`--targets` 选择打包格式，`-v` 输出详细构建日志。脚本生成 `env.json`，安装所需 distributor，并将发布包输出至 `dist/`。Linux 依赖安装使用 apt/sudo；macOS DMG 打包使用 appdmg 与仓库的 hdiutil 重试脚本。

Android 正式签名读取 `android/app/keystore.jks` 及 `android/local.properties` 中的 `storePassword`、`keyAlias`、`keyPassword`。缺少签名配置时使用 debug 签名，并带 `.dev` 应用 ID 后缀；该产物适合本地测试。签名文件与密码保留在本机或 CI secrets。

发布 CI 由 `v*` 标签触发；稳定标签使用 `stable` 环境并发布 GitHub Release，带连字符的标签使用预发布环境。下载文件名来自 [.github/release_template.md](../.github/release_template.md)，发布说明由 [.github/scripts/generate_release_notes.sh](../.github/scripts/generate_release_notes.sh) 生成。

### Android 模拟器

```bash
flutter build apk --debug --target-platform android-arm64
adb devices
adb -s <设备序列号> install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s <设备序列号> shell am start -n com.masteralanlab.avalon.dev/.MainActivity
```

按模拟器 ABI 选择 `android-arm`、`android-arm64` 或 `android-x64`。覆盖安装保留应用数据；避免为了验证页面清除账户或配置。APK 位于 `build/app/outputs/flutter-apk/`；Gradle 可能 strip Go 库，可用 `go tool buildid` 比较提取的 APK 库和 buildkit 产物，核对核心来源。

## 检查与测试

```bash
flutter analyze --no-fatal-infos
flutter test --reporter expanded

# Go 默认、真实 Tailscale 后端、禁用 Tailscale、race 及子模块受影响包。
bash tool/verify_tailscale_core.sh

(cd plugins/setup/buildkit/build_tool && dart pub get && dart analyze && dart test)
cargo fmt --manifest-path services/helper/Cargo.toml -- --check
cargo test --manifest-path services/helper/Cargo.toml
cargo fmt --manifest-path plugins/rust_api/rust/Cargo.toml -- --check
cargo test --manifest-path plugins/rust_api/rust/Cargo.toml

bash .github/scripts/generate_release_notes_test.sh
bash tool/macos_hdiutil_shim/hdiutil_test.sh
```

Go race 检查需要 CGO 和宿主 C 工具链；Windows 原生执行以 [Tailscale 工作流](../.github/workflows/tailscale-v2.yaml) 的分平台命令为准。Windows helper 另执行 `cargo test --manifest-path services/helper/Cargo.toml --features windows-service`。

本地插件在各自目录执行 `flutter pub get`、`flutter analyze --no-fatal-infos`；`plugins/proxy` 和 `plugins/wifi_ssid` 另有 `flutter test`。真实桌面核心的无账户 IPC 检查可在 macOS/Linux 执行：

```bash
python3 tool/tailscale_ipc_smoke.py "$(pwd)/libclash/macos/AvalonCore"
```

该脚本检查实际二进制的能力、快照、错误分类、取消、隐私和 shutdown，不代表真实账户或流量验收。网络验收清单与未解决问题见 [Tailscale 验证状态](tailscale.md#验证状态与已知问题)。

## 代码生成与模块说明

```bash
dart run intl_utils:generate
dart run build_runner build --delete-conflicting-outputs
```

ARB 是本地化源文件；Freezed、JSON 和 Drift 修改从源定义重新生成。Rust 桥接生成方式见 [rust_api](../plugins/rust_api/README.md)。提交时保留与修改相关的生成文件，检查是否混入不相关生成差异。

| 模块 | 入口与说明 |
| :--- | :--- |
| 系统代理 | [plugins/proxy](../plugins/proxy/README.md)，桌面系统代理设置 |
| 窗口扩展 | [plugins/window_ext](../plugins/window_ext/README.md)，原生窗口事件 |
| 桌面 IPC | [plugins/rust_api](../plugins/rust_api/README.md)，Rust socket / named pipe |
| Tailscale | [docs/tailscale.md](tailscale.md)，身份、会话、分流、出口与验收边界 |
| 后台 UI 调度 | [activity.dart](../lib/common/activity.dart)、[setup.dart](../lib/providers/actions/setup.dart)、[render.dart](../lib/common/render.dart) |

后台调度已经按实际 UI 活跃状态运行：前台有仪表盘/托盘消费者时按秒采样，后台仅 macOS 托盘速率标题保留 5 秒采样，其余停止 UI 遥测。日志/请求页后台缓存事件，恢复时发布快照；隐藏/最小化窗口使用 300ms 渲染暂停延迟，普通空闲为 5 秒。失焦只影响 UI 活跃状态，不直接冻结仍可见窗口；代理核心生命周期独立。这些是实现行为，性能收益需在相同设备、配置和负载下另行测量。

## 文档维护

README 保留功能概览和入口，构建步骤统一维护在本文件，Tailscale 细节统一维护在功能文档。完成的任务、消融过程、逐轮截图和本机产物哈希留在开发记录或 CI artifacts；仓库文档只保留当前行为、可复验命令及未解决问题。更新功能时同时检查各语言 README、帮助文案、发布下载模板和相互引用。
