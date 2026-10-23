# 导入、覆写与编译

本文定义订阅与文件的取得、解析映射、JSON 覆写、编译成 sing-box 配置、规则集资源和测速。解析器与编译器位于 `packages/av_core/lib/src/pipeline/`，为纯 Dart 代码。sing-box 字段名以固定版本 v1.14.2 官方文档为准；字段核对、协议矩阵与平台验收见 [内核验证](STATUS.md#runtime-validation)。

## 1. 总览

```text
订阅 URL／文件／二维码／拖入 ─▶ 取得内容 ─▶ 识别格式 ─▶ 解析（isolate）─▶ ConfigContent＋秘密 ─▶ 事务保存
分享链接 ─▶ URI 解析 ─▶ 填入节点表单

启动／重载：一致读取（配置内容、自建节点／链、成员关系、选择、设置、覆写、Tailnet、规则集缓存）
           ─▶ Compiler.compile ─▶ sing-box JSON（含秘密）＋ planHash ＋ 运行映射 ─▶ HostGateway
```

## 2. 取得内容

- **请求**：HTTP GET，User-Agent `Avalon/<版本> clash.meta`（多数服务据此返回 Clash YAML；sing-box JSON 与 URI 列表同样接受）。
- **上限**：连接超时 10 秒，总超时 60 秒；响应 ≤16 MiB；最多 5 次重定向。
- **地址策略**：在实际建立的连接上检查目标 IP（通过自定义 `connectionFactory`），而不是只解析一次域名。
  - 用户输入的地址可以是本机或私网，表示用户明确授权。
  - 重定向目标、provider、规则集等由内容带出的地址，只有在原始来源也属于本机或私网时，才允许访问本机或私网。
- **凭据**：URL 中的认证信息和请求头不随跨域重定向转发；始终校验 TLS。
- **Cloud 来源**：同步投影持久保存 cloud 来源及 source generation。该来源的订阅和 provider 刷新传入 `cloudSource=true`，禁止私网／loopback／保留地址；实际 socket 与每次重定向都检查，不因 DNS 首次解析、用户本地同 URL 或账号解绑获得许可。Cloud URL 拒绝 userinfo／fragment，请求头按冻结协议校验，跨源不转发来源凭据。刷新读取一致的来源快照，内容、未变化结果、用量和错误提交均核对原来源与 generation，迟到结果不污染新来源。
- **响应头**：
  - `subscription-userinfo`：用量（upload、download、total、expire）。
  - `profile-title`：名称，支持 `base64:` 前缀。
  - `Content-Disposition` 的文件名：作为后备名称。
- **Clash proxy-provider**：provider URL 在同一次刷新内一起下载；任一失败则整次刷新失败，保留旧内容。
- **网络路径**：订阅下载使用应用自身网络。TUN 运行时，下载请求同样按路由规则处理。
- **定时更新**：
  - 桌面：应用运行期间按计时器执行。
  - Android：WorkManager 周期任务，唤起无界面 Dart 入口，与前台共用同一个数据库 isolate（D75）。
  - iOS：BGAppRefreshTask，系统尽力调度。
  - 同一配置的刷新串行执行。
  - `SubscriptionUpdater` 在应用启动时和此后每小时检查一次，依次更新开启自动更新且距上次成功已满 12 小时的订阅；失败后在下一次检查重试。手动与定时更新共用进行中状态，同一订阅不并发下载。内容变化后的运行计划生效见 [RUNTIME_HOST §5](RUNTIME_HOST.md#5-生效策略)，Android 无界面调度见 [后台更新](RUNTIME_HOST.md#background-updates)。

## 3. 格式识别与上限

| 格式 | 识别条件 |
| --- | --- |
| sing-box JSON | JSON 对象，含 `outbounds` |
| Clash／Mihomo YAML | YAML 映射，含 `proxies` 或 `proxy-providers` |
| URI 列表 | 每行都是 `scheme://` 形式的链接；整体为 Base64（标准或 URL-safe，可无填充）时先解码。不支持的协议或读不了的行跳过并记入 warnings，至少要有一个可用节点 |

- 文件扩展名和 Content-Type 只作提示，以内容为准。
- **上限**：解码后 ≤16 MiB；JSON 深度 ≤64；YAML 不支持自定义 tag；YAML 别名展开后的节点数 ≤200,000。
- **规模**：每个配置节点 ≤5000、组 ≤500、规则 ≤50,000。超限时报错，不截断。

## 4. 解析映射

**节点类型**：

| 来源 | 映射 |
| --- | --- |
| Clash `ss`／`vmess`／`vless`／`trojan`／`hysteria2`／`tuic`／`socks5`／`http`／`anytls` | 对应九种协议 |
| Clash 其他类型（ssr、snell、wireguard、hysteria v1、ssh 等） | 跳过，记入 warnings；引用它的组移除该成员 |
| sing-box 九种协议的出站 | 直接映射 |
| sing-box 其他出站、endpoints | 跳过，记入 warnings |
| Clash `dialer-proxy` | `NodeDef.detourKey` |

**组**：

| 来源 | 映射 |
| --- | --- |
| Clash `select`、sing-box `selector` | `selector` |
| Clash `url-test`、sing-box `urltest` | `urltest` |
| Clash `fallback`／`load-balance` | `urltest`，displayType 保留原类型名，记入 warnings（D28） |
| Clash `relay` | 跳过，记入 warnings |

**规则**：

| 来源 | 映射 |
| --- | --- |
| DOMAIN、DOMAIN-SUFFIX、DOMAIN-KEYWORD、DOMAIN-REGEX、IP-CIDR／IP-CIDR6、SRC-IP-CIDR、PROCESS-NAME、PROCESS-PATH、DST-PORT、NETWORK、MATCH | 对应 `RuleDef` 匹配项；MATCH → `finalTarget` |
| GEOSITE,xxx／GEOIP,xx | 规则集 `geosite-xxx`／`geoip-xx`，来源同默认目录（§8） |
| RULE-SET（rule-provider） | 下载 yaml／text 后转换为 sing-box source 格式的本地规则集 |
| 其他规则类型 | 跳过，记入 warnings |

**TLS 选项**：导入内容中的 `skip-cert-verify`／`insecure` 按原样保留，warnings 中提示「N 个节点关闭了证书验证」。手动添加节点的表单不提供此选项。

**被忽略的部分**（D29，记入 warnings）：sing-box 的 `dns`、`inbounds`、`log`、`experimental`；Clash 的 `dns`、`tun`、端口和 `mode` 字段。

**finalTarget 与主选择组**：

- finalTarget 取 MATCH 或 `route.final` 指向的目标；都没有时为 direct，并记入 warnings。
- 主选择组：finalTarget 若是 Selector 组，就是该组；否则取第一个 Selector 组（不含注入的「自定义」）。
- 没有 Selector 组时主选择组为空：全局模式与远程 DNS 的出口改用 finalTarget；节点保存不加入任何组；仪表盘当前节点卡显示 finalTarget。
- 主选择组用于：全局模式出口、远程 DNS 出口、经代理下载、出口 IP 探测、当前节点卡、新节点的默认加入组。

**`self` 配置**：只有「自定义」组，主选择组与 finalTarget 都是「自定义」；规则使用默认模板（§6）。

**URI 列表**：生成两个组：「节点选择」（selector，成员为「自动选择」加全部节点）和「自动选择」（urltest，全部节点）。规则使用默认模板（§6），finalTarget 为「节点选择」。

**分享链接解析**：

| scheme | 结构 |
| --- | --- |
| `vless://` | `uuid@host:port?type=&security=&sni=&pbk=&sid=&flow=&path=&host=&serviceName=&udp=true#name` |
| `vmess://` | Base64 JSON（v2 格式） |
| `trojan://` | `password@host:port?sni=&type=&path=&host=&serviceName=#name` |
| `ss://` | SIP002 或 `Base64(method:password)@host:port#name` |
| `hysteria2://`、`hy2://` | `auth@host:port?obfs=salamander&obfs-password=&sni=#name` |
| `tuic://` | `uuid:password@host:port?congestion_control=&sni=#name` |
| `socks://`、`socks5://` | `user:pass@host:port#name` |
| `http://`、`https://` | `user:pass@host:port#name`；https 即 TLS |
| `anytls://` | `password@host:port?sni=&insecure=1&udp=true#name` |

参数无法识别时报错并指出参数名；不丢弃后继续，也不猜测协议。

AnyTLS 的 `udp=true`（同样接受 `1`、`yes`，值不区分大小写）只重述固定内核已启用的 UDP 能力，不改变编译计划。省略此参数时行为相同。`false`／`0`／`no`、空值和其他值仍报 `udp` 参数错误：固定版本 AnyTLS 没有可表达禁用 UDP 的出站选项，不能接受后丢弃限制。重复 `udp` 参数逐项校验，不能用后一个真值覆盖前面的禁用值。内核依据见 [v1.14.2 AnyTLS 出站](https://github.com/SagerNet/sing-box/blob/v1.14.2/protocol/anytls/outbound.go)；`udp` 是分享链接兼容扩展，[AnyTLS URI 规范](https://github.com/anytls/anytls-go/blob/main/docs/uri_scheme.md)只定义 `sni` 与 `insecure`。

VLESS 同样接受上述启用 UDP 的真值并逐项校验，保留 Reality／Vision／SNI／fingerprint。固定内核默认同时启用 TCP 与 UDP，未指定 `packet_encoding` 时使用 XUDP，Vision 的 UDP 也经该路径；分享链接的 `type=tcp` 表示传输方式，不应编译为只允许 TCP 的 `network`。Avalon 当前节点模型没有 UDP 禁用设置，`udp=false`／`0`／`no`、空值和其他值仍明确报错，不能静默丢弃限制；内核本身可以用 `network:"tcp"` 表达禁用，当前模型不扩展该选项。依据见 [固定版本 VLESS 出站](https://github.com/SagerNet/sing-box/blob/v1.14.2/protocol/vless/outbound.go)、[默认 network](https://github.com/SagerNet/sing-box/blob/v1.14.2/option/types.go) 与 [Vision XUDP 客户端](https://github.com/SagerNet/sing-vmess/blob/v0.2.8/vless/client.go)。

分享链接填入节点表单及已有节点编辑保存时，必须保留同协议 TLS 中表单未提供控件的 `insecure`、ALPN、fingerprint 等参数；SNI 和 Reality 仍由当前表单值决定。重新解析的链接参数优先于原节点，不把隐藏选项迁移到其他协议。旧版本保存时已丢失的隐藏参数无法从现存节点推断恢复；应在设备上编辑该节点，重新解析原链接并保存。

**错误与警告**：错误包含字段路径和脱敏摘要，原始内容不进入日志或数据库明文。warnings 随内容保存；保存成功后的提示条不展示 `ignoredSection` 与 `approximatedGroupType`（D122），其余警告正常列出。过滤后为空时不显示提示条。

## 5. JSON 覆写

作用于所有导入配置，不作用于「自建节点」（D19）。内容是 sing-box JSON 片段，只允许以下键：

| 路径 | 合并方式 |
| --- | --- |
| `outbounds[]` | 追加；tag 与生成的 tag 冲突则报错 |
| `route.rules[]` | 插入到配置自身规则之前、固定规则之后（§6 第 7 位） |
| `route.rule_set[]` | 追加；tag 冲突报错 |
| `route.final` | 替换 |
| `dns.servers[]` | 追加；tag 冲突报错 |
| `dns.rules[]` | 插入到 DNS 默认规则之前、Tailscale 规则之后 |

- 保存时依次校验 JSON 语法、允许的键、字段类型，以及引用的 tag 能否在生成配置或覆写自身中解析。错误标出路径。
- 生成配置中的 tag 是内部名（§7）。覆写引用组或节点时使用显示名，编译器按当前配置映射；映射不到时，编译报错并指出名称。
- 覆写全文作为秘密保存。「查看生成的配置」会遮蔽已知秘密字段。
- **Cloud 覆写的开发限制（D105）**：同步可保留加密 canonical 覆写；适用的非空 cloud 覆写仍在计划校验阶段拒绝。当前原生公开地址限制只覆盖已登记的端点与下载路径，不能证明任意覆写引入的 DNS、资源或拨号路径安全；不能通过改写、删除字段或直接连接回退绕过。

## 6. 编译为 sing-box 配置

**输入**：选中配置（或 `self` 模板）、自建节点／链与成员关系、选择、模式、DeviceSettings、Policy、Tailnet 状态、规则集缓存、平台能力、运行意图（普通代理、Tailnet 分别是否启用）。

**Cloud 运行安全边界（D105，开发实现）**：`PlanSnapshotRepository` 带入持久来源信息；`PlanService` 将受限端点 tag 写入仅供宿主读取的 `_avalon_public_network`（version 1），链中的各具体跳均标记，来源限制也纳入计划哈希。宿主须报告 `publicNetworkVersion=1`，否则拒绝运行。Bridge 在每次启动、重载及未连接测速时重新解析受限端点，检查全部 DNS 回答均为公开地址，向内核提交固定 IP 并保留 TLS 名称与传输 Host；选择组、detour 与链逐跳检查，未覆盖的协议选项拒绝。保存计划保留原始域名，冷启动重新校验，不延用历史许可。用户流量的目的地和本地明确授权的端点不因该标记改写。

适用的非空 Cloud 覆写、Cloud 配置中的自动 URLTest 与仍需内核下载的远端规则集继续返回 `cloud.networkGuard`；不能把这些尚未覆盖的路径当作原生端点限制已支持。Cloud 规则集可经受限 Dart 下载或 `fetch(publicOnly)` 经代理下载，后者对每次实际拨号及重定向重新校验并固定公开目标地址；验证后使用本地缓存。上述来源标记与能力是客户端宿主机制，不修改 Cloud 公共接口。

**输出骨架**：

```jsonc
{
  "log": {"level": "<内核日志等级>"},
  "dns": {
    "servers": [
      {"tag": "remote", "type": "https", "server": "1.1.1.1", "path": "/dns-query", "detour": "<主选择组>"},
      {"tag": "direct", "type": "udp", "server": "223.5.5.5"},
      {"tag": "fakeip", "type": "fakeip", "inet4_range": "198.18.0.0/15"},   // FakeIP 开
      {"tag": "ts", "type": "tailscale", "endpoint": "ts-ep", "accept_search_domain": true} // Tailnet 且 MagicDNS
    ],
    "rules": [
      // 1 preferred_by=ts／*.ts.net → ts   2 clash_mode=direct → direct   3 JSON 覆写 dns.rules
      // 4 geosite-cn → direct   5 A/AAAA 且 FakeIP 开 → fakeip
    ],
    "final": "remote",
    "strategy": "<解析策略；IPv6 关时 ipv4_only>"
  },
  "inbounds": [
    {"type": "tun", "tag": "tun-in", "address": ["172.19.0.1/30" /*, IPv6 开时加 fdfe:dcba:9876::1/126 */],
     "mtu": 9000, "auto_route": true, "strict_route": true, "stack": "mixed",
     "platform": {"http_proxy": {/* Android／Apple 且系统代理开 */}},
     "include_package": [], "exclude_package": []               /* Android 分应用 */},
    {"type": "mixed", "tag": "mixed-in", "listen": "127.0.0.1 | 0.0.0.0(LAN)", "listen_port": 7890}
  ],
  "endpoints": [{"type": "tailscale", "tag": "ts-ep", "state_directory": "<宿主目录>", "hostname": "<设备名>",
                 "accept_routes": true, "advertise_exit_node": false}], // 出口选用与广告当前拒绝（D110）
  "outbounds": [/* 节点、链实例、组、direct、block */],
  "route": {
    "rules": [/* 见下表 */],
    "rule_set": [/* 有缓存：local＋path；无缓存：remote＋download_detour（D46） */],
    "final": "<finalTarget>",
    "auto_detect_interface": true, "find_process": true, "default_domain_resolver": "direct"
  },
  "experimental": {
    "clash_api": {"external_controller": "127.0.0.1:9090", "secret": "<密钥>", "external_ui": "ui",
                  "external_ui_download_url": "<metacubexd 发布包>", "external_ui_download_detour": "<主选择组>",
                  "default_mode": "<模式>"},
    "cache_file": {"enabled": true, "path": "<宿主目录>/cache.db", "store_fakeip": true}
  }
}
```

**路由规则顺序**：

| 序号 | 规则 | 条件 |
| --- | --- | --- |
| 1 | `action: sniff` | 流量嗅探开。sing-box 1.14 的嗅探动作只有 `sniffer` 与 `timeout`，不能用嗅探到的域名覆盖目标（旧的入站字段已移除），该设置不提供（D84） |
| 2 | `protocol: dns` → `hijack-dns` | 始终 |
| 3 | `100.64.0.0/10`、`fd7a:115c:a1e0::/48`、`domain_suffix: ts.net`、`preferred_by: ts-ep` → `ts-ep` | Tailnet 启用；位于模式规则之前；由 endpoint 接受的子网与设备名按其真实路由匹配 |
| 4 | 分应用（桌面）：白名单为「进程不在名单中 → direct」，黑名单为「进程在名单中 → direct」 | 名单非空（D13）；需要「查找进程」开启，否则编译报错「分应用代理需要开启查找进程」；Android 改用 include／exclude_package，不依赖查找进程。名单项为进程路径，写入 `process_path`；macOS 上以 `.app` 结尾的项是应用包，写入 `process_path_regex`（`^<转义后的包路径>/`），匹配包内全部进程（D80） |
| 5 | `ip_is_private` → direct | 绕过局域网开 |
| 6 | `clash_mode: direct` → direct；`clash_mode: global` → 主选择组 | 始终 |
| 7 | JSON 覆写 `route.rules` | 导入配置 |
| 8 | 配置规则，或默认模板：`geosite-cn` → direct、`geoip-cn` → direct | — |

`route.final` 取 finalTarget，`self` 为「自定义」组。

**节点与组**：

- **自定义组**：每个配置都注入「自定义」selector，成员为全部可用自建节点与链；已有 Tailscale 出口引用保留但按 D110 判为不可用。
- **自动测速间隔**：保留导入组的 interval；超过固定内核默认 30 分钟空闲超时的 URLTest／Fallback／LoadBalance 组，额外输出 `idle_timeout = interval`，满足内核的启动约束，不缩短原测速间隔。默认与较短间隔仍使用内核默认空闲超时。
- **成员关系**：Membership 把自建节点／链追加到对应组的成员末尾。
- **选择**：Selector 的 `default` 取 Selection（手动选择，否则首个成员）；Selection 指向的成员不存在时用首个成员。
- **Tailscale 出口（D110）**：当前固定内核尚无完整验证的稳定身份与失败时拒绝直连路径。选用出口、`advertise_exit_node` 与任何代理链位置均拒绝；编译器与 Bridge 都检查，旧偏好或原始计划不能绕过。清除已有出口／广告后可使用普通 Tailnet。
- **代理链**：链 `[A, B, C]` 生成独立实例 `c:<id>:0` = A、`c:<id>:1` = B（detour → 实例 0）、`c:<id>:2` = C（detour → 实例 1），链对外使用最后一个实例。同一节点被多条链使用时各自生成实例，不修改共享节点。含 Tailscale 出口的链按 D110 不可用。
- **dialer-proxy**：`detourKey` 映射为该节点的 `detour`。
- **不可用成员**：引用失效、协议不支持、跳缺失或成环的链，只在被本次计划实际选中、被路由引用或作为 urltest 候选时才导致编译失败；仅出现在 Selector 中而未被选中的不可用成员不编译进计划，界面显示「不可用」。含不可用候选的 urltest 组整体不可用，按同一规则处理。
- **密钥格式**：内核加载计划时会检查 Reality 公钥（base64url 无填充，32 字节）、Reality short id（最多 8 字节的十六进制）和 Shadowsocks 2022 的密钥（标准 base64，长度与方法一致，ChaCha20 只能一把），任何一个节点格式不对，整份计划都会被拒。因此这样的节点按「协议不支持」处理为不可用（`NodeKeys`，原因 `reality-key`、`reality-short-id`、`shadowsocks-key`），导入的订阅里有一个坏节点也不影响其余节点；添加或编辑自建节点时表单直接报「格式不正确」。
- **全部写入**：配置的全部节点、组、自建节点与链都写入计划（不可用的除外），以便运行中对任一成员测速；只有计划需要的部分出错才导致编译失败。
- **REJECT 成员**：sing-box 1.14 仍有 `block` 出站。选择组里的 REJECT 成员编译为共用的一个 `{type: block, tag: reject}`，可以被选中，排在第一位时就是默认；按延迟选择的组（urltest）跳过它。没有组用到 REJECT 时不输出该出站。指向 REJECT 的规则编译为 `action: reject`，最终目标为 REJECT 时在规则末尾追加 `action: reject`。

**设备设置映射**：

| 设置 | 映射 |
| --- | --- |
| 启用 TUN | 是否生成 tun 入站；iOS 始终生成 |
| 系统代理 | Android／Apple TUN：tun `platform.http_proxy`；macOS 无 TUN：扩展读取宿主选项只设代理；Windows／Linux：由应用的桌面平台层使用实际接受的 mixed 端口设置系统代理（[RUNTIME_HOST §7](RUNTIME_HOST.md#7-系统接管与恢复)） |
| 允许局域网连接 | mixed 入站监听地址；不影响 Clash API |
| 外部控制器关 | 不暴露监听地址；模式切换仍经 Bridge `setMode` 生效（D84） |
| 内核日志等级 | `log.level`；Bridge 接管日志输出 |
| 下载方式（GEO） | remote 规则集与面板的 `download_detour`：经代理为主选择组，直连为 direct |

**Tailnet-only 计划**（普通代理关、Tailnet 开）：

- tun 只路由 Tailscale 地址段与 `100.100.100.100/32`（`route_address`）。
- MagicDNS 开时，Tailscale DNS 使用 `accept_search_domain=true`，`preferred_by: ts` 与 `*.ts.net` 交给 `ts`，其余为 `local`；关时不注入 Tailscale DNS。Tailnet 路由也使用 endpoint 的 `preferred_by` 匹配已接受子网与设备名。
- 路由 final 为 direct，不生成 mixed 入站。

**编译失败**：返回带字段位置的错误，不生成部分计划，不删除内容来让编译通过。

## 7. planHash 与运行映射

- **planHash**：对规范化 JSON（键排序）计算 SHA-256，并加入 Bridge 与内核版本。秘密值以安装级密钥的 HMAC-SHA256 代入（该密钥由本机主密钥派生：`HMAC-SHA256(主密钥, "avalon.plan-hash")`，不另行存储）：秘密变化时哈希随之变化，哈希本身不泄露秘密。Selector 的 `default` 和出站模式 `default_mode` 不计入：成员选择由 `select`、模式由 `setMode` 即时生效，不算计划变化。这两样合称计划的「选择」，可用 `PlanChoices` 从计划里读出。同一 planHash 表示运行内容相同，RuntimeCoordinator 据此跳过无变化的重载。
- **内部 tag 规则**：节点 `n:<配置id前8位>:<key哈希>`，自建 `s:<id>`，链实例 `c:<id>:<i>`，组 `g:<key哈希>`，自定义组 `g:custom`。
- **运行映射**：内部 tag → MemberRef 与显示名，随计划交给 RuntimeCoordinator，用于把快照中的实际组选择、连接链路映射回界面。

**与真实内核对照**：`core/check_plans.sh` 用固定版本的内核加载编译器为夹具输出的全部计划，改动编译器或升级内核后必须运行。内核的硬性要求中已遇到的两条：带域名的端点或出站需要解析器，因此仅 Tailnet 的计划也输出 `route.default_domain_resolver`（指向 `local`）；Reality 的 `public_key` 必须是合法密钥（32 字节的 base64url），否则整份计划加载失败。

## 8. 规则集资源

**默认目录**：

| tag | URL |
| --- | --- |
| geosite-cn | `https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-cn.srs` |
| geosite-geolocation-!cn | `https://raw.githubusercontent.com/SagerNet/sing-geosite/rule-set/geosite-geolocation-!cn.srs` |
| geoip-cn | `https://raw.githubusercontent.com/SagerNet/sing-geoip/rule-set/geoip-cn.srs` |

导入配置引用的 `geosite-*`／`geoip-*` 使用同一来源；rule-provider 和 sing-box remote 规则集使用其自身 URL。

**ResourceService**（D86）：

- **身份**：规则集以「地址＋格式」识别，tag 只是各配置里的名字；不同配置把同一 tag 指向不同地址时各自缓存。编译输入 `ruleSetCache` 的键为 `ruleSetKeyOf(url, format)`（`"<format> <url>"`），值为本地文件路径。用到哪些规则集不入库，由 `RuleSetCatalog`（默认目录加各配置 DNS 规则与路由规则引用的）推导，GEO 页、编译器与更新共用。
- **缓存**：文件存于宿主目录的 `rulesets/<sha256>.<srs|json>`，内容不可变（Apple 平台放在 App Group 容器）；单个文件上限 32 MiB。下载先写临时文件，校验通过后改名就位，再记入 `rule_resources`（DATA_MODEL §1.2）。校验：binary 检查 SRS 文件头；source 检查 JSON 结构；Clash rule-provider 转换为 source（版本 2）——`DOMAIN`、`DOMAIN-SUFFIX`、`DOMAIN-KEYWORD`、`DOMAIN-REGEX`、`IP-CIDR(6)`、`SRC-IP-CIDR`、`PROCESS-NAME`、`PROCESS-PATH`、`DST-PORT`（含端口范围），其余规则跳过并记数（`skipped`）。旧文件在下一次启动或重载后删除（只删不再被任何记录引用的文件）。下载与清理轮流进行、互不重叠，写入中的文件以 `.` 开头，清理跳过它们。
- **下载**：
  - 直连：Dart HTTP，规则同 §2。
  - 经代理：代理运行时经 Bridge `fetch`（RUNTIME_HOST §2）由主选择组下载，正文直接写入宿主目录；代理未运行时，手动更新提示原因，自动更新推迟到下次启动。
- **缺缓存时**：编译为 `remote` 规则集，`download_detour` 按下载方式设置，由内核首次取得（D46）。每次启动或重载换了会话后，应用把所选配置里还没缓存的规则集经该会话下载保存；运行中的计划已经有它们的规则，不为此重载，下次编译改读本地文件。Clash rule-provider（yaml／text）内核不能直接读取：启动前缺缓存时由应用直接下载并转换（不论下载方式，此时还没有会话可借道），再编译；仍取不到时编译报错「规则集尚未下载」。
- **自动更新**：每小时检查一次。未下载过的、或距上次成功超过间隔（每天／每周）的为到期；上次失败的一小时内不再试。「经代理」且代理未运行时跳过，下次启动后立即检查。下载得到的内容与原文件不同时同步计划：当前计划引用了该规则集则按 D10 重载，否则不动。界面关闭时，Android 的后台入口每小时做同样的检查（D75）。
- **失败**：保留旧缓存，记录错误码（`fetch.*`、`resource.format`、`resource.storage`、`resource.proxy`）与检查时间；GEO 页该行显示「下载失败」。
- **实现**：`app/lib/services/resource_service.dart`（下载、校验、缓存、清理）、`app/lib/app/rule_set_updates.dart`（手动更新、定时更新、会话起来后补存）、`app/lib/data/repositories/rule_resource_repository.dart`、`packages/av_core/lib/src/pipeline/rule_set_convert.dart`（Clash 转换）、`core/bridge/fetch.go`。

## 9. 测速与出口 IP

- **测速结果**：以（configurationId, MemberRef）为键保存在内存；同一键上较早请求的晚到结果丢弃；会话变化或测速地址变化后，旧结果标记为过期（灰色显示），不删除。
  - 同一成员在不同组共用结果；测速地址变化后标为过期，让用户看到最近一次测量及其有效性。
- **实现**（`core/bridge/urltest.go`、`app/lib/runtime/latency.dart`）：
  - 运行中：Bridge 在当前会话里对每个 tag 用内核的 `urltest.URLTest` 经该出站访问测速地址，8 个并发，每个受超时限制；结果为毫秒或错误（`timeout` 或内核原话）。
  - 未运行：应用把计划写到宿主目录的 `probe.json`，Bridge 去掉入站、控制器、路由规则与规则集（这些会接管设备或在启动前下载）后只启动出站，测完立即关闭；探测期间不存在会话，启动命令会等它结束；有会话运行时拒绝探测，应在会话里测。
  - 代理链测的是末跳出站（`CompiledPlan.tagOf`），末跳经 detour 走完整条路径。REJECT 不测。
  - 宿主须在内核开始拨号前就报告当前的默认网络（RUNTIME_HOST §8）；探测不建 TUN，启动后立刻拨号。
- **出口 IP**（`app/lib/services/exit_ip.dart`、`app/lib/runtime/exit_ip_probe.dart`）：默认服务为 Cloudflare trace（D89），`--dart-define=AVALON_EXIT_IP_URL=…` 可替换，传空值则关闭探测并显示「—」。默认回答只有国家代码，不带城市；服务地址须写入隐私政策。
  - 运行中经 Bridge `fetch`（不写文件、正文随回答返回，上限 64 KiB，超时 15 秒）走主选择组；未运行时用应用自身网络直接请求。「实际出口」为从主选择组沿各组的实际选择一直跟到的出站，会话或它变化时丢弃旧结果并重测；启动、重载、停止的过程中不显示结果。
  - 读得懂这类服务的常见回答：JSON（地址取 `ip`／`query`，国家取 `country_code`／`countryCode`／两位的 `country`，国家名取 `country_name`／`country`，城市取 `city`），或 `ip=`、`loc=` 的逐行文本。卡片上方显示国旗与「城市, 国家」（知道多少显示多少），下方显示地址；读不出地址或请求失败时显示「—」。
  - 只在有页面显示出口 IP 时探测（仪表盘离开屏幕时监听暂停，D88），不在后台反复请求。
