# 当前状态

更新于 2026-10-23。这里只记录已验证范围、已知问题和验收缺口；产品行为见 [PRODUCT_SPEC](PRODUCT_SPEC.md)。源码接入、构建成功、设备运行和正式发行分别判断。

<a id="platform-status"></a>

## 平台

| 平台 | 已验证范围 | 未验收或未支持 |
| --- | --- | --- |
| Android | API 36 模拟器端到端；API 34 arm64 Profile 真机导入、编辑节点／链、测速、TUN、浏览器 HTTPS／HTTP3、模式切换、后台更新和停止；三 ABI APK 构建，新标识 arm64 覆盖安装 | 完整 DNS／IPv6 泄漏、耗电、锁屏、跨午夜与断网恢复；armv7／x86_64 运行；正式签名 |
| iOS | 内核切片、App／Packet Tunnel 未签名构建；模拟器原生通道与无入站测速 | 有真实 iPhone，尚无 Apple 开发者账号；团队签名、Network Extension 权限、VPN／后台恢复、重载中断；500 节点＋GEO＋Tailnet 的扩展内存与体积，内存保留 20% 余量 |
| macOS | arm64 Release App／System Extension 未签名构建；隔离 Debug App 的菜单栏、静默启动、关窗隐藏、双进程聚焦、最小化恢复及退出清理；Carbon 三快捷键注册与回调测试 | 团队签名、扩展批准、VPN／系统代理与内存；真实快捷键、登录项、窗口持久恢复、截图视觉及 Intel 构建。隔离检查未使用正式用户数据、真实登录项或 VPN |
| Windows | 命名管道、UAC 安装／更新／卸载、按需服务与 TUN 切换已接入；amd64 helper 交叉构建／自映像摘要、Windows vet／测试交叉编译 | Windows 上的管道、UAC、服务、wintun 流量、跨账号、升级／恢复均未实跑；完整 Flutter 打包与安装包签名。交叉编译不计为 Windows 测试运行 |
| Linux | 固定 helper 安装／卸载、Unix socket、跨 UID 拒绝、普通 UID 仅 NET_ADMIN 的真实 TUN／HTTP、GNOME 代理设置／恢复；X11 窗口／快捷键、程序枚举和密钥回退源码 | 图形应用、浏览器、登录项、deb／rpm／AppImage；Wayland 快捷键和非 GNOME 系统代理未支持 |

<a id="local-data"></a>

## 本地数据

导入／编译、节点与代理链编辑、Drift schema v4、加密秘密表及密码备份已有核心回归；覆盖解析预算、事务回滚、秘密不落明文、错误密码和损坏备份拒绝。完整升级／恢复、V1 跨代备份兼容、真机备份往返、永久失钥多账号恢复，以及桌面系统对话框和实际进程匹配仍未完整验收。

<a id="runtime-validation"></a>

## 内核与 Tailnet

- 固定 sing-box 的字段、模式与代表性编译计划已验证；协议矩阵通过 29 项 TCP、25 项 UDP，包含 WebSocket early data 和经 Shadowsocks 的代理链。矩阵由 `packages/av_core/tool/protocol_matrix.dart` 与 `core/check_protocols.sh` 维护；SOCKS5 两项 UDP 中继、Hysteria2 连接中端口跳跃及真机重载中断时长未覆盖。
- Tailnet 真实登录、独立启停、本机地址、MagicDNS 与身份恢复通过；跨在线设备 TCP／UDP、子网服务、动态子网路由和关闭嗅探时的自身地址转发仍待验收。出口选用、出口广告及全部代理链位置按 D110 禁用。

<a id="cloud"></a>

## 账号与同步

正式 Cloud 入口隐藏，账号与同步仅为开发预览。邮箱登录、会话恢复与撤销、设备移除、删号保留本机内容，以及协议 2 的代次／重建／原请求恢复已有验证。Android 覆盖持久数据升级、编辑上传、引用、前后台恢复、中断续传、权益到期／恢复与账号切换；电脑与 Android 测试进程完成五类内容的有序双向编辑、引用和删除，使用隔离内存数据库，不代表完整桌面 UI 或持久化重启验收。

第三方登录、购买／恢复、网页删号入口、真实渠道与邮件投递、多设备随机并发收敛、订阅更新后的真实会话生效、永久失钥恢复、移动网络／公网 HTTPS／长期后台及签名 iOS 同步未完整验收。公开契约仍为 0.2.0；0.3.0／0.4.0 是锁定候选，候选校验通过不代表发布或完整验收。

<a id="known-issues"></a>

## 已知问题

- 小米首次授予已安装应用权限后列表为空，退出重进才加载。
- 仅选择 Chrome 的白名单进入 VPN UID 范围后，浏览器仍停滞；重启浏览器／代理可复现，清空名单恢复，同期本地混合端口 HTTPS 正常。
- Android 保持 VPN 连接时覆盖安装，可能遗留旧隧道的 UID 收包过滤并导致拨号超时。更新前先断开 VPN；出现更新后持续超时时，可重启设备恢复。
- Android 添加弹层绘制仍有超预算样本；其他机型、负载和完整显示流畅度未覆盖。

性能采样仅限 API 34／MT6855（PowerVR BXM）、60 Hz、arm64 Profile、Skia：根标签 929 帧中 1 帧为 17.27 ms，设置子页 514 帧中 2 帧绘制超预算，添加弹层 425 帧中 46 帧绘制超预算。Raster 超过 16.67 ms 不等于显示掉帧率，UI 与 Raster 耗时不能相加计算帧率；运动中文字有轻微采样差异。

<a id="checks"></a>

## 检查与发行

2026-10-23 的检查结果：三包格式／分析通过，app 577 项测试通过、11 项环境跳过，av_core 106 项、av_design 10 项通过；Go 格式、固定功能标签的 vet／test、重载相关 race、公开契约检查及本机开发 helper 的真实 socket 启停通过。消融后的保留测试能检出代表性编译、数据安全、桌面生命周期及权限边界故障。复测命令见 [客户端开发](../app/README.md) 与 [Core Bridge](../core/README.md)。

V2 使用 `2.0.0+1`、`app.getavalon.avalon`，尚未发布 V2。[源码 CI](https://github.com/MasterAlanLab/avalon/actions/runs/39563750898) 于 2026-10-21 通过；正式 Android 签名、各平台渠道安装／升级和发行验收仍待完成。直装支付服务商未确定；Android 原生库按用户要求暂保留未压缩方式，发行前须比较下载大小与安装占用。发行规则与许可义务见 [客户端开发](../app/README.md#v2-ci) 和 [LICENSING](LICENSING.md)，发布须用户明确授权。
