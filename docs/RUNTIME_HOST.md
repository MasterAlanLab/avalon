# 运行宿主与生命周期

本文定义 Core Bridge 与 HostGateway 接口、会话状态、生效策略、观察、系统接管、五平台宿主和桌面壳。编译出的计划见 [CONFIG_PIPELINE](CONFIG_PIPELINE.md)，实现与平台验收范围见 [当前状态](STATUS.md#platform-status)。

## 1. 组件与职责

| 组件 | 位置 | 职责 |
| --- | --- | --- |
| RuntimeCoordinator | Dart，应用级单例 | 持有运行意图；把偏好变化映射为命令（§5）；串行发送命令；轮询快照；把外部修改写回偏好（D30） |
| HostGateway | Dart 类：把 §2 的命令做成有类型的方法，经一条「传输」把 Bridge 的 JSON 原样送到宿主。Android／Apple 使用平台通道，Windows 使用命名管道，Linux 使用 Unix socket（D73、D85、D124） | 唯一的宿主调用入口 |
| 平台原生层 | Kotlin／Swift | Android、Apple 上转发 JSON 命令，与宿主进程通信 |
| 宿主 | VpnService／Packet Tunnel／helper | 拥有 TUN 与内核；UI 退出后继续运行；只执行收到的计划 |
| Core Bridge | Go，嵌入宿主 | 包装 sing-box；命令、观察、日志缓冲、流量计数、Tailscale 状态 |

Flutter 进程从不加载内核（iOS 未连接测速的临时实例例外，见 CONFIG_PIPELINE §9）。页面关闭、provider 销毁、应用进入后台都不会停止隧道。

## 2. Core Bridge API

各平台通用同一组 JSON 消息，传输方式见 §8。改变状态的命令带唯一 `requestId`；只读命令不需要。宿主保存最近 64 条命令的结果，供超时后查询。

| 命令 | 请求 | 响应 |
| --- | --- | --- |
| `start` | requestId、plan／planPath、planHash、utcOffsetSeconds?（设备时区） | sessionId |
| `reload` | requestId、sessionId、plan／planPath、planHash、utcOffsetSeconds? | sessionId（原地替换时不变，重启时为新值）、method（`inPlace`／`restart`）。sing-box 1.14 只有重启，`inPlace` 保留给今后 |
| `stop` | requestId | — |
| `setMode` | requestId、sessionId、mode | — |
| `select` | requestId、sessionId、groupTag、memberTag | — |
| `urlTest` | requestId、sessionId（运行中）或 plan／planPath（未运行时的探测）、tags、url、timeoutMs | `{results: {tag: {delayMs} 或 {error}}}`；error 为 `timeout` 或内核原话 |
| `fetch` | requestId、sessionId、outboundTag、url、maxBytes、destPath?、timeoutMs?、publicOnly? | `{status, size, body?, path?}`：经运行中会话的该出站（组或节点）发 GET，跟随重定向；给了 destPath 时正文写入该文件（规则集），否则放在 `body` 里返回（只用于小的响应，回答要跨进程）；超过 maxBytes 报错，超时默认 30 秒、最长 5 分钟。Cloud 资源使用 `publicOnly`，逐次连接与重定向检查并固定公开目标 IP |
| `queryCommand` | requestId | `pending`／`done`（附结果）／`failed`（附错误）／`unknown` |
| `snapshot` | — | 见 §6 |
| `connections` | sessionId | `{connections: [{id, host, network, process, rule, chain, upload, download, createdAt}]}`，最新的在前；chain 为出站 tag，从规则命中的目标到实际出口 |
| `closeConnection` | requestId、sessionId、id | —（连接已不存在也算成功） |
| `closeAllConnections` | requestId、sessionId | — |
| `capabilities` | — | protocolVersion、coreVersion、platform、tun?、publicNetworkVersion |
| `logs` | afterSeq、limit | entries（seq、time、level、message）、nextSeq、dropped |
| `tailnetStatus` | — | state、loginUrl?、tailnet?、self?、peers[]；设备包含稳定 id、名称、系统、IPs、online、exitCapable；来自实际内嵌端点 |
| `tailnetLogin`／`tailnetLogout` | requestId | 操作后的实际 Tailnet 状态，字段同 `tailnetStatus` |

**错误**：统一结构 `{code, message, detail?}`。code 取值：`PLAN_INVALID`、`PORT_IN_USE`、`PERMISSION_DENIED`、`SESSION_MISMATCH`、`CORE_FAILED`、`TIMEOUT`、`UNSUPPORTED`。所有 message 均已脱敏。

## 3. HostGateway

D85 确定一条通用 JSON 命令通道，有类型封装只在 Dart 侧定义：

- **消息只有一种形态**：各平台传的都是 Bridge 的 JSON（§2），方法通道与 IPC 转发层原样转发命令内容，不定义第二套命令模型；原生层读取命令标识、路径和超时等字段以完成路由、权限检查与平台生命周期。宿主在快照中补充由自己拥有的实际系统状态（§6）。
- **`HostTransport`**（Dart 接口，`runtime/host_gateway.dart`）：`Future<String> call(String command, String request)`，把一条命令送到宿主并取回应答。

  | 实现 | 平台 | 通道 |
  | --- | --- | --- |
  | `ChannelHost` | Android、iOS、macOS | 方法通道 `dev.avalon/host` 的 `call`；原生层转发到宿主（§8） |
  | 命名管道传输 | Windows | Dart 通过 Win32 FFI 经当前用户命名管道访问 helper，原样传递 JSON（D124）；不经 C++ 平台通道 |
  | socket 传输 | Linux | Dart 直接经 Unix socket 向 helper 发同样的 JSON（§8）；不经平台通道 |

- **`HostGateway`**（Dart 类）：有类型的方法与 §2 的命令一一对应（`capabilities`、`start`、`reload`、`stop`、`setMode`、`select`、`snapshot`、`logs`……），负责编码请求、解码应答、把错误变成 `HostException`，以及超时后的 `queryCommand`（§4）。这是命令在 Dart 侧唯一的定义，五个平台共用。
- **`HostSystem`**（Dart 接口）：宿主里属于平台而不属于 Bridge 的四件事——`facts()`（提供可写宿主目录与设备名，供计划编译和文件写入）、`prepare(tun)`（系统授权：Android 的 VPN 同意与通知权限）、`release()`（没有会话时放开宿主，让它不必常驻内存）、`configure(options)`（宿主自己要用的设置，见 §8「宿主选项」；D87）。
- **原生错误**：`call` 与四个系统方法统一将 `PlatformException` 转为 `HostException`，保留 `UNSUPPORTED`、`PERMISSION_DENIED` 等已登记的 wire code；未知通道错误或插件未注册才归为 `HOST_UNREACHABLE`。例如模拟器不能建立 Packet Tunnel 属于平台不支持，不能伪装成宿主失联。
- **计划按文件传递**：`start`／`reload` 带宿主目录内候选文件 `plan.next.json` 的 `planPath`，成功后才改名为 `plan.json`（§5）。计划可达数 MB，而 Android 进程间调用上限 1 MB。各平台的接受计划恢复见 §8；Bridge 也接受内联 `plan`（helper 与测试使用）。
- 页面不接触网关：只读 `runtimeProvider`（RuntimeCoordinator 的状态）并调用它的 `connect`／`disconnect`／`toggle`。这一点由架构测试强制。

通道取舍理由见 D85。Dart 与 Go 的协议测试分别在 `app/test/runtime/`、`core/bridge/*_test.go`，实际宿主还需端到端验收。

Windows／Linux 的系统代理由应用的桌面平台层管理，不经 core helper：Windows 方法通道调用 WinINet 默认连接选项 API，Linux 使用 GNOME／Unity 会话的 `gsettings`，其他桌面明确报不支持。Windows 程序列表由原生通道枚举开始菜单、App Paths 与卸载项，Linux 在 Dart 侧解析 XDG `.desktop` 文件；不执行枚举出的程序。Android 的应用列表走自己的方法通道（`dev.avalon/apps`）。

### 3.1 协议版本

- Bridge 消息格式带整数 `protocolVersion`，由 `capabilities` 返回；应用内置自己支持的版本。
- 协议不一致时不得发送计划；桌面宿主须提示「Avalon 服务需要更新」并提供对应更新入口：Windows 重新安装服务，macOS 替换系统扩展，Linux 更新 helper。Android 与 iOS 的宿主随应用一起升级。各平台检查与更新入口的实现范围见 [当前状态](STATUS.md#platform-status)。
- 只增加可选字段时不提升版本号；删除或改变语义时提升（D74）。
- **公开地址能力（D105）**：`publicNetworkVersion=1` 表示 Bridge 能处理计划的 `_avalon_public_network` 来源标记和 `fetch(publicOnly)`。需要此能力而宿主未报告时拒绝计划／下载，不忽略标记。每次启动、重载与未连接测速均重新解析并校验受限端点，向内核交付固定公开 IP，保留 TLS 名称和传输 Host；链逐跳检查。自动 URLTest、原生远端资源与非空 Cloud 覆写等未覆盖路径继续拒绝，见 CONFIG_PIPELINE §6。该能力不是 Cloud 公共接口的新字段。

## 4. 运行意图与会话状态

- **两个独立意图**：
  - `proxyEnabled`：仪表盘、托盘、快捷键启停时修改；启动时由「启动后自动连接」决定，本身不持久化。
  - `tailnetEnabled`：Tailscale 页开关，持久化。
- **会话**：两个意图合成一个计划，由一个会话运行：都开为完整计划；只开 Tailnet 为 Tailnet-only 计划；都关则停止会话。
- **会话状态**：`stopped` → `starting` → `running` ⇄ `reloading`；任意状态可经 `stopping` 回到 `stopped`；失败进入 `failed`（附错误）。快照分别报告 `proxyActive` 与 `tailnetActive`。
- **命令串行**：RuntimeCoordinator 用单一队列，一次一条。
  - 新的启停意图会取消队列中尚未发送的重载。
  - 停止优先于等待中的启动；用户在 VPN 授权弹窗期间按了停止，授权完成后不再启动。
- **超时**：start／reload 30 秒，其他 5 秒；测速与下载按各自请求时限延长。Dart 等待超时或原生 IPC 返回 `TIMEOUT` 后均用原来的 `requestId` 调用 `queryCommand`：已完成则采用结果，已失败则保留原错误，`unknown` 时以快照为准，不自动换新 `requestId` 重发。
- **附着**：应用启动或回到前台时先读快照，宿主有会话即沿用。
- **宿主一侧的启停**（D75）：用户在系统设置关闭 VPN、点通知栏停止，或系统按需连接，宿主会话随之变化。RuntimeCoordinator 从快照得知后把 `proxyEnabled` 同步为实际状态，不自动重连。
- **Tailnet 状态（D106、D110）**：Bridge 查询固定内核内嵌端点的真实本地后台，交互登录／注销也调用该端点。只有可信的 Tailscale HTTPS 登录地址可交给浏览器，地址不进入日志。endpoint 启用与登录成功是不同事实；出口选用、出口广告及所有链位置仍拒绝，已保存的选择允许清除。

## 5. 生效策略

| 变化 | 未运行 | 运行中 |
| --- | --- | --- |
| 选择配置 | 保存 | 重载为新配置 |
| Selector 组选择 | 保存 | `select`；失败则报错并保留原选择的实际状态 |
| 出站模式 | 保存 | `setMode`；失败则报错并保留实际状态 |
| 当前配置内容变化（订阅更新、编辑、删除成员、Cloud 接收、规则集更新） | — | 1 秒防抖后重载 |
| JSON 覆写、高级设置、混合端口、LAN、分应用、Tailscale 选项或出口 | 保存 | 重载 |
| 启用 TUN、系统代理（Android／Apple） | 保存 | 保存后立即排队重载 |
| 系统代理（Windows／Linux） | 保存 | 应用的 `platform/` 直接设置或恢复，不重载 |
| 非当前配置的变化、测速地址、超时、外观、语言 | 保存 | 无动作 |

- **实现**：会话运行期间，RuntimeCoordinator 订阅当前配置的全部输入（配置、内容、自建节点与链、选择、设备设置）和 Policy。任何变化都走同一条路：重新编译，比较 planHash——不同则重载；相同则把计划里的「选择」（各 selector 的成员、出站模式）与快照比较，只对不同的发 `select`／`setMode`；都相同就什么也不发。成员或模式变化、TUN／系统代理开关立即排队处理，其余后台变化先等 1 秒（D10）；Windows／Linux 系统代理由平台层直接处理。附着到已有会话后也立即做一次同样的对照。
- **跳过无变化的重载**：新计划的 planHash 与运行中相同时不发送。
- **重载方式**：sing-box 1.14 的重载是「关闭旧实例、建立新实例」，没有原地替换，所以每次重载都是重启：会话 ID 改变，已建立的连接全部断开，界面显示「正在重新连接」。中断测量与验收范围见 [内核验证](STATUS.md#runtime-validation)。移动端宿主在新接口建立之后才关闭旧接口的描述符，重载期间流量不会绕过隧道直出。
- **计划优先于内核的记忆**：内核把每个选择组的当前选择和出站模式存进 cache.db，下次启动时优先于计划里的默认值。计划由用户保存的选择编译而来（可能是在未运行时改的），因此 Bridge 在每次启动和重载成功后，把计划中各 selector 的 `default` 与 `default_mode` 重新应用一遍。运行中经外部面板做的修改仍按 D30 写回偏好，下一份计划自然带上它们。
- **模式名**：快照里的模式是内核原样返回的字符串，计划写 `rule` 就返回 `rule`，计划不写时内核自己的默认是 `Rule`；Dart 侧比较时不区分大小写。
- **重载失败**：旧会话仍在运行则保留，并在仪表盘显示错误；旧会话已停止则进入 `failed`。不自动改为直连，不自动换节点。由于内核的重载是先关后开（D82），Bridge 在关闭旧实例之前先把新计划单独加载一遍：内核不接受的计划直接返回 `PLAN_INVALID`，旧会话不受影响；能加载但启动失败的（如端口被占）则旧会话已经没了，进入 `failed`。应用把新计划先写到 `plan.next.json`，宿主接受后才替换 `plan.json`，被拒绝的计划不会成为「重启后恢复」所用的计划。
- **编译失败**：运行中的改动编译不出计划时（覆写引用了不存在的出站、所选配置被清空等），不发任何命令，会话按原计划继续运行，仪表盘显示原因。
- **TUN 在运行中关闭**（Android）：重载后的计划没有 TUN，宿主在内核启动完成后关闭上一份计划留下的 VPN 接口，服务继续在前台只提供本地端口；再次开启时重新建立接口。
- **外部修改的写回**（D30）：RuntimeCoordinator 记着会话「应当」运行的选择——计划里的，加上自己发出的 `select`／`setMode`。某次快照与之不同、且这次快照与自己的任何命令都没有重叠（命令执行期间或期间发出的快照不算），就是外部面板改的：模式写入设备设置，selector 成员写入选择记录（按手动选择，随 D12 同步）。写入后重新编译的计划与正在运行的一致，不会再发命令把它改回去。按延迟选择的组（urltest）自己变化是正常的，不在比较之内。
- **Cloud 接收**：Cloud 接收的选择记录与本机选择相同处理（D12）。

## 6. 观察

快照（`HostSnapshot`）：sessionId、revision（同一会话内单调递增）、state、proxyActive、tailnetActive、tunActive、systemProxyActive、clashApiListen、planHash（仅在 `running` 时非空）、mode、各组实际选择（tag）、上下行速率、今日上传／下载、错误。

**活动与控制器字段**：字段描述当前成功启动的会话，不取设备保存偏好或正尝试加载的计划。没有运行实例时四个活动标志为 `false`，`clashApiListen` 为空字符串。

| 字段 | 当前事实来源与语义 |
| --- | --- |
| `proxyActive` | 运行实例中存在 mixed／HTTP／SOCKS 代理入站；仅 Tailnet 的 TUN 不据此视为代理已启用 |
| `tailnetActive` | 运行实例中存在 Tailscale endpoint，表示本地 endpoint 已启用；登录、设备与在线事实另读 `tailnetStatus`，不据此认定出口可用 |
| `tunActive` | 运行实例中有 TUN 入站；Android／Apple 还确认已建立或已成功应用的原生隧道 |
| `systemProxyActive` | Android／Apple 成功应用的原生 HTTP 代理（Android 需自动路由开启且为 10+）；macOS 无 TUN 时也可由扩展只设代理。Windows／Linux 的 helper 不管理用户代理，界面改读桌面平台层核对的 OS 状态 |
| `clashApiListen` | 成功接受计划的 `experimental.clash_api.external_controller`，不包含控制器密钥；控制器关闭或没有运行实例时为空字符串 |

新增字段按 D74 保持协议版本 1。Dart 把旧宿主缺少的这些字段保留为 `null`，表示未知；仪表盘在连接／重连时使用实际 TUN 与系统代理状态，缺字段显示「—」，断开时显示下一次启动的保存偏好。编译失败或新计划在预检中被拒时，旧会话的快照与接管状态继续有效；新计划加载后启动失败、会话已失去时，快照如实报告失败和未启用。

仪表盘的 TUN 开关控制普通代理接管：结合最后成功接受的计划与宿主 `tunActive` 判断，不把仅服务 Tailnet 固定路由的隧道显示为普通代理 TUN 开启。接管外部会话时先匹配计划；旧宿主缺失原生事实仍显示未知。点击 TUN／系统代理后立即显示用户意图，保存成功即排队同步（同值写入也同步）；重载完成或失败后回到已接受的实际状态，较早的重载不得覆盖后续点击。

- **轮询**：仪表盘、代理页、Tailscale 页可见时每秒查询快照；连接页可见时每秒查询 `connections`；日志页按 `nextSeq` 增量读取。页面不可见时停止轮询，宿主不受影响。每个通道同时最多一个在途请求；同一会话中 revision 较小的快照丢弃。
- **今日累计**：Bridge 从内核流量统计累加，每 30 秒及停止时写入宿主状态目录的日文件，按本地日期分日；宿主被杀时最多丢失 30 秒。UI 只显示快照中的值，不在前台自行累计。
- **日志**：Bridge 保留 2000 条环形缓冲，按序号读取，溢出时返回 `dropped`。序号跨会话连续，重载不清空（启动失败的原因还查得到）。内核会把所有级别的日志都交给宿主，并带终端格式（Android 上有颜色控制符、级别与运行秒数前缀）；Bridge 只保留计划 `log.level` 允许的级别，并去掉这些格式，只存正文。
- **Android 速度通知**：前台服务每秒用 Bridge 的快照更新通知（「通知栏显示实时速度」开启时）；屏幕关闭时不更新，速度不变时不重发。

## 7. 系统接管与恢复

- **TUN**：由宿主随会话创建和销毁；Android／Apple 的隧道内 HTTP 代理随隧道一起移除。
- **Windows／Linux 系统代理（D111）**：在用户桌面会话中管理。Windows 用 `InternetQueryOptionW`／`InternetSetOptionW` 读写默认连接的 FLAGS、SERVER、BYPASS、AUTOCONFIG_URL，并通知设置改变；Linux 仅管理支持的 GNOME／Unity 会话设置。
  1. 每次设置前将原值与本次目标值写入加密 `secrets` 表的固定恢复条目；可能含原 PAC 凭据的值不写明文文件、日志、备份或同步。写入或回读失败保留可恢复的操作记录。
  2. 恢复将代理模式与端点看作一个关联组：整组当前值仍属于原值或本次目标值时，只恢复 Avalon 已改过的字段；出现外部修改则保留整组并放弃所有权，不关闭用户新选的代理。
  3. 启动后恢复中断的操作；停止、关闭系统代理或显式退出时执行恢复。清理失败保留加密条目供重试，退出失败时保留窗口并显示错误。
  4. 目标端口来自成功接受的运行计划；被拒重载保留旧实际端口。附着或外部计划变化后端口未知时不以保存偏好代填，也不声称系统代理已接管。后台只核对活动状态及重试停止后的清理，不周期性覆盖用户设置。
- **崩溃**：UI 崩溃时宿主继续运行；宿主崩溃时快照为 `stopped` 并附错误，不自动重启（移动端系统按需连接除外）。
- **退出**：桌面显式退出依次停止会话、恢复系统代理、退出进程。移动端关闭界面不停止隧道。
- **卸载与升级**：卸载与升级前停止宿主；Windows 服务和 Linux helper 随卸载移除，不留常驻提权进程。

## 8. 平台宿主

| 平台 | 宿主 | Bridge 形态 | Flutter ↔ 宿主 | 授权 |
| --- | --- | --- | --- | --- |
| Android | 独立进程 `:vpn` 的前台服务；TUN 开时为 VpnService，关时只运行本地端口 | gomobile AAR | 方法通道（Kotlin，原样转发）→ AIDL 绑定服务的 `call(command, request)` | `VpnService.prepare`；Android 13+ 通知权限 |
| iOS | NEPacketTunnelProvider 扩展 | gomobile xcframework（扩展；App 内仅用于未连接测速） | 方法通道（Swift，原样转发）→ `NETunnelProviderSession.sendProviderMessage`；计划文件放 App Group 容器（数据保护级别 completeUntilFirstUserAuthentication） | 添加 VPN 配置的系统授权 |
| macOS | 直装采用 System Extension Packet Tunnel；商店采用 App Extension。TUN 关时不加路由，只设置代理或仅开放端口 | xcframework，只链接扩展 | 方法通道 → provider message；受保护 App Group 计划 | 有效团队签名；批准系统扩展；添加 VPN 配置 |
| Windows | `avalon-helper`：TUN 开时以每 SID 的 Windows 服务（LocalSystem）运行并使用固定 sing-tun 内嵌 wintun；TUN 关时以用户子进程运行 | Go 可执行文件 | Dart `WindowsHost` → Win32 命名管道；客户端核对服务身份，服务端核对用户 SID（D124） | 首次启用 TUN 时 UAC 安装服务 |
| Linux | `avalon-helper` 用户进程；TUN 需要 CAP_NET_ADMIN | Go 可执行文件 | Dart `SocketHost` → `$XDG_RUNTIME_DIR` 下的 Unix socket（0600，helper 校验 SO_PEERCRED） | root／包管理器安装固定 helper 并 setcap |

表格描述目标宿主；当前实现与平台验收以 [当前状态](STATUS.md#platform-status) 为准。

- **Android 宿主**（`app/android/…/host/`）：
  - `AvalonVpnService` 在 `:vpn` 进程里持有 Bridge 与 VPN 接口。有会话时它是「已启动」的前台服务并显示通知，界面进程退出后继续运行；没有会话时只在被绑定期间存在。前台服务类型：已获 VPN 授权时为 `systemExempted`，TUN 关闭只跑本地端口时为 `specialUse`。
  - `HostChannel` 在界面进程里：按需绑定服务，把 `call` 转给它；`prepare` 请求 VPN 同意（TUN 开启时）并顺带请求通知权限（不等结果，被拒绝只是不显示通知）。
  - 用户在系统里关掉 VPN、或被别的 VPN 顶替时（`onRevoke`），宿主自行停止会话；RuntimeCoordinator 从快照得知（§4）。
  - 实际接管状态：`AndroidPlatform` 在成功建立 VPN 后，把描述符与实际安装的 HTTP 代理配置放在同一个跨线程可见的状态对象中，快照结合 Bridge 运行入站后回报。启动／重载命令返回后依据当前运行计划有无 TUN 决定释放旧接口；无效新计划被拒时保留旧接口与代理，同一 `requestId` 的幂等成功应答也不会因没有再次调用 `openTun` 而误关接口。
  - 分应用：只把本机已安装的包交给 `VpnService.Builder`（先用 PackageManager 判断）。未安装的包名，新版 Android 会留作一个谁都匹配不上的过滤条件，旧版会拒绝；白名单里一个已安装的都没有时宿主拒绝建立隧道（开机恢复这类没有界面的启动也一样），应用在启动前先检查并给出原因（PRODUCT_SPEC §3.11）。
  - 通知：标题「Avalon 已连接」，正文为上下行速度（「通知栏显示实时速度」开启时，§6），带「停止」按钮；点按钮由宿主自行停止会话，界面同上从快照得知。通知文字按应用的语言（宿主选项里的 `language`）取 Android 资源，未设置时跟随系统。
  - 宿主选项（D87）：`configure` 把 `{speedNotification, startAtBoot, language}` 写入宿主目录的 `host-options.json`（界面进程直接写，宿主在运行时随即重读），宿主和开机接收器在没有界面时也读得到。`startAtBoot` 为「开机自动启动」与「启动后自动连接」同时开启。RuntimeCoordinator 在设备设置变化时下发，未变的设置不重发。
  - 恢复（D87）：开机广播（`startAtBoot` 时）与系统的「始终开启的 VPN」都会在没有界面时拉起宿主；宿主立即进入前台，再用宿主目录的 `plan.json` 与最近一次成功启动记下的 `plan-hash` 启动。已有会话时不重复启动；没有计划或启动失败时回到空闲。之后打开应用，RuntimeCoordinator 接管这个会话（计划哈希一致，不重载）。
  - 计划文件随选择更新：运行中切换成员或出站模式不重启内核（§5），但 RuntimeCoordinator 同时把新计划写回 `plan.json`（哈希不变），恢复时用的是当前的选择而不是上次启动时的。
  - 应用的系统备份关闭（`allowBackup=false`）：私有目录里有节点秘密和运行中的计划。
  - 调试构建把内核日志镜像到 logcat（标签 `AvalonCore`），发行构建不做。
  - <a id="background-updates"></a>**后台更新（D75）**：有网络时 WorkManager 每小时运行 `UpdateWorker`；界面运行时由前台调度器负责，否则启动无界面 `backgroundMain`，与前台共享 Drift isolate。订阅与规则集更新改变当前计划时，只重载已运行的会话，不自动启动代理；最多等待 9 分钟后结束后台引擎，超时下次重试。调试入口 `RunUpdatesNow` 可立即触发检查。
  - 构建依赖 `core/out/avalon-core.aar`：缺失或比 `core/` 的源码旧时，Gradle 直接报错并提示运行 `core/build.sh android`。默认构建 arm64、armv7、x86_64 三个架构（Flutter 的发行引擎只有这三种）；开发时可只构建 arm64：`core/build.sh android arm64`。
  - 发行构建用 R8 完整模式压缩。内核 AAR 自带保留规则（`go.**`、`dev.avalon.core.**`，JNI 要用）；`app/android/app/proguard-rules.pro` 另外保留 Room 数据库类的无参构造函数——WorkManager（D75）的任务库靠反射创建它，Room 2.6 自带的规则不能覆盖完整模式，缺少保留规则会令发行版在启动时崩溃。改动原生依赖后要装发行版走一遍启动、连接、测速。
- **Linux 宿主**：
  - `avalon-helper -state <宿主目录> -socket <路径>` 在 Unix socket 上提供 Bridge 的逐行 JSON。socket 在 `$XDG_RUNTIME_DIR/avalon/host.sock`，目录 0700、socket 0600，每个连接用 SO_PEERCRED 校验对端是同一用户，不是则直接关闭；同一路径已有 helper 应答时，第二个 helper 拒绝启动。
  - Dart 的 `SocketHost`（`app/lib/runtime/host/socket_host.dart`）每条命令开一个连接、一行请求一行应答，长时间的启动不会挡住快照；连不上时先拉起 helper，再重试最多 5 秒。显式开发环境变量 `AVALON_HELPER` 优先；正常发现顺序为 `/usr/lib/avalon/avalon-helper`、可执行文件旁的 `lib/avalon-helper`、同目录 helper。helper 是用户进程，应用退出后继续运行；宿主目录为 `$XDG_STATE_HOME/avalon`。
  - TUN：helper 在 `capabilities` 里报告 `tun`（root，或有效能力集里有 CAP_NET_ADMIN）。启用 TUN 而 helper 没有这个能力时，`prepare` 返回拒绝，不会启动到一半才失败。
  - 安装／卸载（D112）：`core/install_linux_helper.sh` 由 root／包管理器调用，只向固定 `/usr/lib/avalon/avalon-helper` 安装 root:root、0755、`cap_net_admin=ep` 的 ELF。源须先在 root 所有且普通用户不可替换的目录中暂存，源和目标拒绝符号链接；能力在私有暂存目录内设置。替换与卸载阻止新的旧文件执行并拒绝运行中的 helper，卸载保留用户 XDG 状态与无关文件。Flutter 和随应用放置的普通 helper 均不提权。
- **iOS 宿主**：
  - Runner 的 `dev.avalon/host` 通道管理 `NETunnelProviderManager`、添加 VPN 配置的授权和 `NETunnelProviderSession.sendProviderMessage`；命令内容仍为 Bridge 原始 JSON。`PacketTunnelProvider` 在独立扩展进程拥有真实 `MobileHost`；生命周期命令串行执行，观察命令另行处理，不因 Flutter 页面关闭而停机。
  - `ApplePlatform` 将内核的 TUN 地址、路由、DNS、MTU 和 HTTP 代理配置转换为 `NEPacketTunnelNetworkSettings`，使用官方 libbox 的 Darwin 隧道描述符方法；`NWPathMonitor` 先报告初始默认接口，再监听网络变化。快照中的 TUN／系统代理状态以成功应用的原生网络配置细化，拒绝重载不清除旧会话事实。
  - Runner 与扩展共用受保护的 App Group 宿主目录。计划只从其 `state/` 读取，下载目标只允许 `state/rulesets/`，拒绝内部符号链接及越界路径；目录不包含 Flutter 数据库、vault 或主密钥。系统容器路径先规范化，再把路径返回给 Dart。原先在 Runner 支持目录下载的规则集只按已登记文件名与 SHA-256 校验迁入，未知文件、符号链接、损坏内容不复制；旧缓存缺失时走正常资源下载。
  - 恢复使用原子写入的 `accepted-plan.json`，将成功接受的计划内容与结构哈希保存在同一份受保护文件中，不依赖 Flutter 随后重命名候选文件。成功的 `select`／`setMode` 同步真实选择；快照观察到的外部面板更改在生命周期队列内重新采样后保存，只有当前运行哈希与接受哈希一致时更新，相同选择不重写。持久化失败停止内核并报告错误。启动失败保留已脱敏的原始 Bridge 错误供应用读取；查询结果不会被后续原生持久化失败的旧成功缓存覆盖。
  - 未连接测速依 CONFIG_PIPELINE §9，在 Runner 内创建无入站／不建 TUN 的临时真实内核；连接中测速经扩展中的现有会话。无 App Group 权限的模拟器只为前一种测速使用自身私有目录，正式 VPN 目录不会退回普通容器。模拟器的 VPN 授权与启动始终返回 `UNSUPPORTED`；设备缺少 App Group／VPN 权限时返回明确错误，不降级成应用进程代理。
  - 应用与扩展分别链接固定的 `AvalonCore.xcframework`，标识符在 `app/ios/Shared/Host.xcconfig` 中统一配置。
- **Windows 宿主（D124）**：
  - 普通 helper 的状态在当前用户 `LocalAppData/Avalon/host`；服务执行固定 `ProgramFiles/Avalon/helper/avalon-helper.exe`，使用按 SID 隔离的 `ProgramData/Avalon/<SID>/shared` 候选计划与规则集，以及只有 SYSTEM／管理员可写的私有运行目录。GUI 和普通 helper 不提权，安装／更新／卸载经 UAC；卸载保留本地内容与运行状态。
  - 一条命令对应一条命名管道连接。管道拒绝远程访问，服务只授予所属用户数据读写权限；客户端发送计划前核对 SCM 配置、服务 PID 和实际映像路径，普通 helper 则核对用户 SID 与映像路径。Win32 调用在独立 isolate 中执行，读写使用可取消的期限，丢失回答沿用原 requestId 查询结果。
  - 提权边界只接受白名单命令与规范字段。计划与已校验规则集以调用用户权限读取并快照到私有运行目录；内核的缓存、Tailnet 与面板目录重写到该目录，拒绝任意文件路径和执行字段。下载先写入私有目录，再以调用用户权限交付到共享目录。
  - Windows 运行协调、计划编译和规则集缓存共用一个宿主实例。运行中切换 TUN 时先准备目标宿主并预检候选，成功后停止旧会话，在受保护管道内迁移固定清单的缓存、当日流量与 Tailnet 身份，再启动目标；迁移不将秘密写入普通临时文件。最后使用的宿主位置保存在用户私有目录，空闲重开仍读取同一份状态。
  - 每次启用 TUN 前核对安装副本是否与当前 helper 匹配；空闲旧服务停止后通过 UAC 更新，活动会话先保留并提示停止后更新。发送候选计划和未连接测速计划前校验协议版本，不兼容时拒绝计划；停止与读取状态仍可使用。普通 helper 退出后可在下一次连接时重建同一用户宿主。
  - 安装复制前锁定源目录与文件，将文件内容与已启动提权映像的摘要核对。此摘要只用于安装完整性，不能代替 Authenticode 签名。
- **macOS 正式宿主（D109）**：
  - 最低 macOS 13。Runner 只持有 `NETunnelProviderManager`、`OSSystemExtensionRequest` 与 `dev.avalon/host` 通道，不导入或链接 AvalonCore，也没有 iOS 的 App 内测速实例；Core 只链接在嵌入的 System Extension 中。
  - 扩展复用 Apple 的 `HostStorage`、`ApplePlatform` 与 `PacketTunnelProvider`。App Group 内的计划、接受计划和下载路径采用与 iOS 相同的保护与验证；无 TUN 模式不设置默认路由或 DNS，按宿主选项只应用实际系统代理。选择、模式变化和被拒重载保留旧代理设置。
  - `prepare`／`start` 核对有效团队签名、扩展安装与 App Group 权限、Applications 安装位置；系统批准未完成、需重启或添加 VPN 配置被拒均返回明确错误。调试未签名构建可使用本地 UI 与私有计划目录，不能借此启动隧道或退回应用进程内核。
  - `Host.xcconfig` 统一团队 App Group、扩展标识与权限配置；扩展构建前检查 XCFramework 是否比 Go 源码旧。
- **Bridge 的构成**（D81）：`core/bridge` 建在 sing-box 官方的 `daemon.StartedService` 之上，命令、快照、日志缓冲与结果缓存都在这一层，各平台共用。移动端用 `core/mobile` 经 gomobile 导出，并与官方的 `experimental/libbox` 一起绑定：宿主用 Kotlin／Swift 实现 libbox 的 `PlatformInterface`，其余全部走 Bridge 的 JSON 命令。桌面的 `avalon-helper` 直接构造同一个服务，不需要平台接口。
- **移动端宿主必须实现的平台接口**：建立 TUN（Android 用 `VpnService.Builder`，按内核给出的地址、路由、DNS、包名单配置，返回描述符；内核自行复制）；保护出站套接字不进隧道（Android `protect(fd)`；Apple 不需要）；默认网络监听（Android 用「非 VPN 且可上网」的最佳网络回调，Apple 用 `NWPathMonitor`），网络变化时把接口名和序号告诉内核；枚举网络接口（名称、序号、地址前缀、标志位、类型、DNS）；按连接五元组查应用（Android 10 起用 `getConnectionOwnerUid`，供「查找进程」）。通知、WiFi 状态、邻居表、Shell、桥接等接口 Avalon 不用，返回空或不支持。
- **默认网络须立即报告**：内核在 `startDefaultInterfaceMonitor` 返回后马上开始拨号。Android 宿主在注册回调之前先同步报告当前的非 VPN 网络，再由回调跟进变化；Apple 宿主同理，避免未连接测速因缺少初始接口而失败。
- **平台 DNS**：计划里的 `local` DNS 服务器由宿主提供系统解析（libbox 的 `LocalDNSTransport`）。查询发往「不经 VPN 时应用会用的网络」的 DNS，不会绕回隧道：Android 10 起用 `DnsResolver.rawQuery` 转交完整的查询报文；更早的版本只能按名解析 A／AAAA。目前只有仅 Tailnet 的计划用到 `local`。
- **重启后恢复**：Android 与 Apple 的系统可在 App 不在场时重启隧道（always-on、按需连接）。Android 使用宿主目录的 `plan.json` 与成功接受时保存的哈希；Apple 使用上文的原子接受计划与哈希，并同步最后成功的模式和节点选择。恢复文件位于受保护的平台宿主目录，不进入备份与日志。
- **宿主目录**：存放 cache.db、Tailscale 状态、流量日文件、计划文件。Android 为应用私有目录；Apple 为 App Group 容器；Windows 区分上述普通用户目录、服务共享计划目录与私有运行目录；Linux 为 `$XDG_STATE_HOME/avalon`。

## 9. 桌面壳

- **职责**（D93）：`app/lib/app/desktop_shell.dart` 跟随运行状态与设置，平台部分在 `app/lib/platform/desktop/`。
- **单实例**：应用支持目录里的文件锁加本机回环端口（端口号写在锁旁）；第二个实例连上第一个、请它显示窗口后退出。
- **桌面设置**：Windows／Linux 的登录启动、自动连接和系统代理由应用的桌面层及本地设置管理；`configure` 不持久化移动宿主选项。
- **窗口**：window_manager 接管关闭按钮：「关闭窗口时保留」开启且托盘可用时隐藏窗口，否则走退出流程（先停止代理、恢复系统设置）。各桌面 runner 启动时保留窗口隐藏，由 Dart 在本地数据与托盘可用后决定显示；开发画廊入口主动显示。Windows／Linux 的设计标题栏调用原生最小化、最大化、关闭、拖动与双击通道。
- **系统退出与重开**：系统退出请求转入同一个桌面清理流程，等待连接／停止队列结束并恢复系统代理；失败时保留窗口供重试。macOS 不在最后窗口关闭时自动结束进程，Dock 重开会恢复主窗口，窗口位置由 AppKit 保存；启动失败窗口没有桌面壳时仍可正常退出。单实例激活连接收发后及时关闭，后启动的进程不等待主进程退出。
- **托盘或菜单栏**：tray_manager 实现 D31 的菜单（显示主窗口、启动／停止代理、出站模式子菜单、退出），按应用的语言显示；图标为品牌包的状态标记，未连接灰色、已连接金色（`app/assets/tray/`，由 `tool/branding/render_icons.sh` 生成，Windows 用 .ico）。没有宿主的平台上「启动代理」置灰。托盘不可用时按 PRODUCT_SPEC §7 处理。
- **快捷键**：三个全局快捷键分别启停代理、轮换出站模式、显示主窗口。macOS 用 Carbon `RegisterEventHotKey`，Windows 用 `RegisterHotKey`，Linux X11 使用键抓取并处理锁定键掩码；占用时显示「已被占用」，不支持的会话（包括当前 Wayland 实现）显示「暂不支持」（D93、D108）。
- **开机启动**（D93）：macOS 用 `SMAppService.mainApp`（macOS 13 起，更早的系统报不支持），Windows 写 `HKCU\…\Run`，Linux 写 `$XDG_CONFIG_HOME/autostart/avalon.desktop`；随「开机自动启动」开关同步。调试构建不注册，只记日志。
  - 桌面登录项修改串行执行；系统拒绝或 macOS 等待用户批准时，在基础设置原行显示实际结果。关闭待批准的 macOS 登录项也会注销该项目。

## 10. 外部控制

- **Clash API**：由内核提供，监听地址与密钥来自设置；LAN 开关不影响控制器。监听地址不是回环地址时，设置页显示风险提示。
- **外部修改**：第三方面板修改模式或组选择后，RuntimeCoordinator 在快照中发现实际值与偏好不同，且不是自己的命令造成的，就写回偏好（D30），随后按普通编辑同步。
- **Web 面板**：由内核按 `external_ui_download_url` 下载到宿主目录；设置页先等待一次成功的即时快照查询，再用 `clashApiListen` 构造 `http://<监听地址>/ui` 并打开系统浏览器。通配监听地址 `0.0.0.0`／`::` 分别改用回环地址 `127.0.0.1`／`::1`，IPv6 保留方括号；URL 不带控制器密钥。重载被拒时沿用快照里的旧控制器地址。未接入宿主、未运行、控制器关闭、字段缺失／查询失败／地址无法解析、浏览器启动失败均在设置页解释原因；查询失败时不使用缓存地址打开。

## 11. 应用版本与更新渠道

- V2 应用标识为 `app.getavalon.avalon`（D117），Apple Packet Tunnel 为 `app.getavalon.avalon.PacketTunnel`，App Group 与所属平台的签名配置保持一致。更换应用标识不提供跨沙箱与安全存储自动迁移；此前 V2 开发安装可导出当前格式的密码备份、在新标识下恢复，不直接复制数据库或密钥。跨代备份兼容范围见 [本地数据状态](STATUS.md#local-data)。
- 关于页使用 `package_info_plus` 读取原生实际版本与构建号；宿主 `coreVersion` 独立显示。备份格式与 User-Agent 的源码版本须与 pubspec 一致，不用原稿版本替代已安装版本。
- 直装版本仅检查 `MasterAlanLab/avalon` 的公开 GitHub Releases。只接纳非草稿、非预发布、tag 为 `v<version>` 的当前客户端发行；发行页和下载地址必须为同仓库同 tag 的可信 HTTPS GitHub 路径，不接受 userinfo、query、fragment 或跨发行 manifest。
- 发行须包含 `avalon-client-release.json`（16 KiB 上限），字段为 `schema: 1`、`application: app.getavalon.avalon`、`engine: sing-box`、`hostProtocol: 1`、三段版本 `version`、字符串数组 `platforms`。版本须与 tag 一致且包含本平台；缺 manifest 的旧实现发行不提供更新。比较合格发行的版本后，只向用户提供对应发行页，不下载或安装制品。
- 商店渠道从实际安装来源或 `AVALON_DISTRIBUTION_CHANNEL` 判断。Apple 商店须配置有效 `AVALON_APP_STORE_URL`，Google Play 须匹配本应用包名；渠道未知或未配置时隐藏检查入口，不改用直装源。浏览器失败或检查失败在关于页报告，异步结果只更新仍存在的页面。

## 12. 失败处理

| 情况 | 结果 |
| --- | --- |
| 编译失败 | 不发命令；在触发操作的位置显示错误 |
| 端口被占用 | `PORT_IN_USE`，提示更换混合端口 |
| 用户拒绝系统授权 | 保持未连接，说明需要的授权 |
| 当前路径必需的规则集缺失且下载失败 | 启动失败并说明；不去掉规则后启动 |
| 选中成员不可用 | 启动或切换失败，指出成员名称；不自动换成员 |
| 宿主无响应 | 显示「无法连接到 Avalon 服务」，提供重试；不假定已停止 |
