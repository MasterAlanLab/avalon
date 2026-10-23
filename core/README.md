# Avalon Core Bridge

客户端本地运行内核的 Go 模块，以 [RUNTIME_HOST §2](../docs/RUNTIME_HOST.md#2-core-bridge-api) 的 JSON 命令封装官方 sing-box。内核版本固定在 `go.mod`（D03）；Android 服务与 Apple 网络扩展通过 gomobile 绑定，Windows／Linux 使用 `avalon-helper`。

账号与同步由客户端 `app/lib/cloud/` 实现，公开协议见 [API 文档](../docs/api/README.md)，不属于本模块职责。

各平台实现与待设备验收范围见 [平台状态](../docs/STATUS.md#platform-status)；快照语义与原生宿主职责由 [RUNTIME_HOST](../docs/RUNTIME_HOST.md) 定义。制品构建成功不代表对应平台 VPN、系统授权或正式发行已验收。

## 结构

| 路径 | 用途 |
| --- | --- |
| `bridge/` | 单会话内核、命令、快照与日志缓冲；纯 Go，测试会在 loopback 启动真实内核 |
| `mobile/` | gomobile Bridge 与 sing-box libbox 绑定；Android 服务和 Apple 扩展实现 `PlatformInterface` |
| `cmd/avalon-helper/` | 每行一个 JSON 命令的独立进程；Linux 使用校验用户身份的 Unix socket，Windows 使用按用户 SID 隔离的命名管道与按需服务（D124） |
| `internal/windowshost/` | Windows 提权边界的计划、请求与状态迁移校验；平台无关的安全策略测试 |
| `build.sh` | 固定工具链与各平台制品构建，结果写入不提交的 `out/` |
| `check_plans.sh` | 用 Avalon Dart 编译器生成夹具计划，再由固定版本内核实际加载；修改编译器或 pin 后运行 |
| `check_protocols.sh` | 使用固定版本的官方 sing-box Docker 镜像与编译计划验证协议／传输／安全组合；矩阵未覆盖的边界见 [内核验证](../docs/STATUS.md#runtime-validation) |
| `check_linux_helper.sh` | 在 Docker 中验证 Unix socket 访问控制、能力报告和 TUN 流量／生命周期 |
| `spikes/s1-apple/` | 尚待 Apple 设备验收的 Swift 桥接实验；由维护中的宿主检查覆盖后再删除。模拟器通道检查使用 `app/gallery/ios_host_probe.dart`，均不替代 Packet Tunnel 验收 |

## 开发与构建

以下命令在 `core/` 运行。首次安装固定版本的 gomobile 工具，再按目标构建：

```sh
./build.sh tools
./build.sh android
./build.sh apple
./build.sh helper OS ARCH
```

`OS`／`ARCH` 替换为目标系统与 Go 架构，例如 `./build.sh helper linux amd64`。Android 默认构建 Flutter 发行引擎支持的 arm64、arm、amd64 三个 ABI；仅构建 arm64 可用 `./build.sh android arm64`。

Android 应用链接 `out/avalon-core.aar`，Apple 构建使用 `out/AvalonCore.xcframework`。修改本模块后须重新生成制品；Android Gradle 和 Apple Xcode 构建阶段都会拒绝缺失或过期的内核库。Apple 签名、模拟器限制与宿主检查见 [客户端开发说明](../app/README.md#ios-runtime-development)。

Windows 使用 `./build.sh helper windows amd64` 构建，并将输出作为 `avalon-helper.exe` 放在 Flutter 程序旁。该 helper 提供 `-windows-action init|status|install|uninstall|start-service`；普通用户入口只接受当前用户 SID，安装与卸载需要提升权限，为指定用户管理服务。应用首次启用 TUN 时调用同一安装入口并请求 UAC，服务运行管理员保护目录内的副本；普通端口模式仍使用用户进程。服务、私有目录和管道的安全约束见 [RUNTIME_HOST §8](../docs/RUNTIME_HOST.md#8-平台宿主)。

Windows 构建会将唯一自映像摘要槽写入既有 helper 制品。安装器锁定源目录和文件，将源内容与已经启动的提权进程中保存的摘要核对，防止确认 UAC 后原路径被替换。这是安装完整性检查，正式 Authenticode 签名及其与摘要流程的集成仍属于发行验收；不能在摘要写入后直接修改二进制。

### 检查

在 `core/` 执行：

```sh
gofmt -l bridge mobile cmd internal tools.go
./build.sh test
```

`gofmt -l` 无输出表示这些 Go 源码格式正确；`build.sh test` 执行 `go vet` 与 `go test`。`BUILD_TAGS` 固定 Avalon 使用的 sing-box 功能标签，构建与测试都必须传入；链接参数沿用上游的 `-checklinkname=0`。单独运行测试时使用：

```sh
go test -tags "$(cat BUILD_TAGS)" -ldflags "-checklinkname=0" ./...
```

普通 Go 回归不代替计划加载、协议矩阵、Linux Docker TUN 或各平台设备验收；按改动范围补跑上述专项脚本。

## 许可

sing-box 为 GPL-3.0-or-later，Avalon 自有代码为 AGPL-3.0-only。修改 pin、功能标签或准备发行前，请查看 [许可与发行](../docs/LICENSING.md)。
