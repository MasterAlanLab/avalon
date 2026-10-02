# Tailscale

Avalon 通过内嵌 Tailscale 节点连接一个 Tailnet，提供设备查看、分流、远端子网和出口节点配置。入口为 **工具 → Tailscale**，手机与桌面共用三个页签：设备、分流、出口节点。

## 登录与设备

登录只建立 Tailscale 会话，不启动 Avalon 主服务，也不申请 VPN/TUN 权限。主服务和配置仍在原有仪表盘、配置页管理。

- **浏览器登录**：点击页面的浏览器登录，等待真实授权链接，打开浏览器完成登录；也可复制链接或扫描二维码。需要管理员批准的设备按 Tailnet 现有流程批准。
- **Auth Key**：有相应管理角色的用户在 [Keys 控制台](https://console.tailscale.com/admin/settings/keys) 选择 `Generate auth key`，配置选项后生成，将 Key 直接粘贴到 Avalon 的 Auth Key 输入框。单设备持久身份测试可使用一次性、非 Ephemeral、短有效期 Key；具体选项见 [Tailscale Auth keys 文档](https://tailscale.com/docs/features/access-control/auth-keys)。
- **自定义服务器**：启用自定义控制服务器，填写实际 HTTPS Headscale 地址，再登录；设备批准由相应服务器管理。

Auth Key 只在应用输入，分享问题时省略 Key、完整授权链接及身份文件。取消登录会使旧授权流程的结果失效。

登录后顶部只显示会话状态和“更多”菜单；暂停、恢复、注销从菜单操作。设备页显示“此设备”主要地址及 peer 列表，完整地址、账号/标签、到期日期放在详情中。支持搜索、筛选、复制和单个/批量连接测试。桌面宽度达到 1000 时使用列表/详情双栏，其余宽度采用列表及详情弹窗。

仪表盘可添加 Tailscale 卡片：有效会话显示本机主要地址，其他状态显示一个短标签；地址不是流量已接管的证明，实际状态在分流与出口页查看。

## 分流与子网

流量分流需主服务运行、配置有效、处于规则模式，并实际进入 Avalon。登录成功与偏好开关开启均不等于网络接管生效。

- Tailnet 地址、后端实际设备 IP、真实 MagicDNS 后缀/FQDN 和可识别短名用于受管理分流；保留原明确 REJECT/REJECT-DROP，包括嵌套组当前选中的拒绝。
- 接受子网只采用后端获准的远端路由，排除出口默认路由和设备自身地址。支持多个发布者、IPv4/IPv6 重叠判断和最长前缀。
- 子网访问需要 TUN；与本地网段冲突时默认使用本地网络，明确选择远端后才接管。
- 保留用户的 IPv6、访问控制、绕过私有路由及排除应用设置，只合并必要网络前缀与 DNS policy。MagicDNS 使用真实后缀，不做全域 DNS 劫持。
- 系统代理只覆盖使用代理且未被 bypass 的应用；IPv6 关闭时保留用户选择，不将未捕获流量计为已接管。
- 暂停或认证失效时，仍由功能拥有的 Tailnet/子网请求停止，不进入公网回退。

页面使用实际安装的 TUN/VPN 路由判断捕获状态，服务停止、配置错误、非规则模式、冲突等原因在相关页签按需展示。

## 出口节点

仅使用当前 Tailnet 后端批准的出口设备，按稳定设备 ID 选择；设备失去资格、消失或离线时停止使用。

| 配置 | 行为 |
| :--- | :--- |
| 指定策略组 | 只覆盖原规则直接指向的所选组，不隐式绑定嵌套子组；绑定按当前 profile 隔离 |
| 全部公网流量 | 转发 Avalon 在规则模式下实际接管的公网连接；保留本地 LAN、特殊地址、Tailnet、子网和原拒绝规则 |
| 停止相关连接 | 默认失效策略；出口不可用时停止所选公网请求 |
| 使用原路由 | 明确选择后，新连接按当前原规则和用户组选择处理；切换时断开受影响连接 |

目的地址尚未确定、原域名解析失败时，不将请求直接判为公网并回退。Tailnet/子网请求始终与公网回退分开处理。偏好变化仅关闭受影响的连接，不迁移或重放已经发送的 TCP/UDP 数据。

出口健康检查使用同一 tsnet 访问两个公共站点的 TCP 443；任一个成功即可，连续三轮失败才撤销健康状态。它是 TCP 可用性判断，不代表 UDP、HTTPS 内容或出口公网 IP 已验收。实际 `ExitNodeStatus` 需匹配选定设备；LAN access 偏好保持开启。

## 身份与会话

- 一个活动 Tailnet；暂停关闭后台实例、保持本机身份，配置重载不自动恢复用户暂停。恢复后由真实后端确认登录状态。
- 注销先调用真实 Logout，再关闭实例、清理当前服务器身份。失败保留待注销标记，重启不自动连接，重试继续清理；更换服务器先完成旧身份注销。
- 缓存设备图用于离线展示和路由所有权判断，明确标记旧数据，不凭缓存显示认证成功。控制面异常不把所有缓存设备改为离线。
- Auth Key 只用于一次注册，不写入 YAML、数据库、偏好、应用备份或导出；日志省略参数和授权链接，错误使用分类文案。Go/Dart 的字符串清理不等同于全内存擦除。
- 身份根目录为应用支持目录下的 `managed-tailscale-v2/`，按控制地址散列隔离；Unix 根目录 0700、偏好文件 0600。应用 ZIP/WebDAV、节点导出及 Android cloud backup / device transfer 排除此目录；macOS 设置 Time Machine 排除元数据。
- Windows 使用同一用户 Local AppData 下的 `Avalon/managed-tailscale-v2/`，配置保护 DACL，避免 Roaming AppData 复制。Linux 备份产品及 Windows 第三方备份/磁盘镜像需单独配置目录排除，身份文件不跨机器恢复。

当前范围不含入站服务发布、本机子网/出口发布、SSH、Serve/Funnel、Taildrop 和多账号切换。普通 `type: tailscale` 代理节点保持独立目录和懒启动机制，不由页面会话接管。

## 实现与维护

| 层 | 源码与职责 |
| :--- | :--- |
| 会话管理 | [tailscale_manager.go](../core/tailscale_manager.go)：唯一实例、订阅、身份与偏好；generation/revision/sequence 排除过期结果 |
| 后端 | [tailscale_native.go](../core/tailscale_native.go)：现有 `github.com/metacubex/tailscale/tsnet` / LocalClient |
| 网络覆盖 | [tailscale_routing.go](../core/tailscale_routing.go)、[tailscale_connection.go](../core/tailscale_connection.go)：规则、DNS/TUN、连接清理 |
| RPC | [tailscale_rpc.go](../core/tailscale_rpc.go)：桌面 IPC / Android FFI 共用 protocol 2 |
| 界面 | [lib/features/tailscale](../lib/features/tailscale/)、[tailscale.dart](../lib/views/tailscale.dart)、[仪表盘卡片](../lib/views/dashboard/widgets/tailscale.dart) |
| Android | [VpnService.kt](../android/service/src/main/java/com/masteralanlab/avalon/service/VpnService.kt)、[Core.kt](../android/core/src/main/java/com/masteralanlab/avalon/core/Core.kt)：socket protect、VPN 重建与安装结果 |

保留命名空间为 `__avalon_managed_tailnet_v2` 和 `__avalon_ts_exit/`，导入配置冲突时在应用前报错。包装出站的 Close 不拥有全局 tsnet。注册/恢复显式启动，订阅持续反馈状态并处理重订阅；暂停、取消、注销与重连隔离旧 context。Android 安装 socket protect 后重建托管实例，桌面使用原系统 dialer，控制连接不经覆盖后的出口组。

网络覆盖在用户脚本、规则及 DNS 覆写之后解析验证，并保留最终用户源配置用于撤销。偏好/设备图更新只重算 DNS/TUN，不重新实例化普通代理/provider，不覆盖模式和组选项；失败恢复上一份网络与偏好。Android VPN 重建失败恢复旧 VPN，不额外重置全部普通连接。

生产构建需 `with_gvisor` 且无 `no_tailscale`；其他构建返回 `supported:false`。子模块版本、可复现补丁、核心构建和检查命令统一见 [开发与构建](development.md)。

## 验证状态与已知问题

以下是 **2026-10-02 本地验证范围**，不是发布承诺或远端 CI 结果：

- Flutter 全量 882 项通过；静态分析无 error/warning，保留 43 项 info。buildkit 30 项、Go 默认/真实后端/禁用标签 test/vet、race 及受影响子模块包检查通过。
- macOS arm64、Android arm64 核心及 Android debug APK 构建通过；实际 macOS 核心完成 10 个无账户 IPC 检查。Windows/Linux 核心仅交叉编译，Windows 测试二进制编译但未在 Windows 执行。
- Android 16 arm64 模拟器覆盖安装、原生三个页签和卡片跳转已检查，已有登录身份在重启后保留。该观察不等同于浏览器/Auth Key 全流程验收，未启动主服务完成真实流量验证。
- macOS 完整应用打包仍需补齐完整 Xcode；桌面组件测试及宽屏渲染不是原生桌面应用验收。Windows ACL 与宿主运行待 Windows 验证；备份产品排除策略待人工确认。

**未解决的 Android 核心崩溃**：2026-10-02 12:19:38 +08:00 曾在 VPN HTTP proxy 设置阶段观察到原生核心 SIGABRT / Go nil pointer panic。故障符号定位到 `github.com/metacubex/mihomo/tunnel.handleTCPConn.func3`、`core/Clash.Meta/tunnel/tunnel.go:596`；这只是符号定位，完整 Go stack、当时配置和可复现步骤仍缺失，根因及修复尚未确认。后续页面启动未见新崩溃，不作为 VPN 稳定性通过的依据。

### 待真实网络验收

需要可注册账户、普通 peer、获准子网路由器/NAS 和获准出口设备，使用有效 Avalon profile，分别检查：

1. 浏览器、Auth Key、Headscale 与管理员批准；取消后旧流程失效，更换控制服务器清理旧身份。
2. 核心/app 重启、暂停/恢复、注销失败重试及身份不进入导出/备份。
3. Android VPN 权限拒绝/授予、IPv6 与访问控制保留、重建失败回滚；桌面系统代理与 TUN 的实际覆盖边界。
4. Tailnet IPv4/IPv6、MagicDNS、NAS 子网，多发布者、本地冲突选择、Wi-Fi 切换及原拒绝优先。
5. profile 组绑定隔离、全部公网真实出口 IP、TCP/UDP，LAN 与 Tailnet/子网保持各自路径。
6. 出口离线、资格撤销、控制面断开、健康检查失败，以及默认停止/显式原路由回退、恢复与撤销。
7. Android 历史核心崩溃复现与 VPN 实机稳定性；各桌面宿主完整应用运行。

测试后更新本节的日期、实际验证条件和仍未完成项；账号、设备地址、临时日志路径及逐轮产物哈希不作为长期文档内容。
