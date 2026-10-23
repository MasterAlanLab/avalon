# 许可、来源与发行

2026-10-21。本文负责授权、第三方来源、对应源码和渠道发行义务。

## 1. 授权

- **Avalon 自有代码**：本仓库的全部内容（客户端、Core Bridge、helper、工具）统一采用 AGPL-3.0-only。全文见 [LICENSE](../LICENSE)，授权与权利人见 [COPYRIGHT](../COPYRIGHT)。
- **第三方**：各自保留原许可，不重新授权为 AGPL。
- **商业模式**：收费的托管 Cloud 同步服务；本地代理、节点与链、TUN、DNS、规则、Tailscale 集成和文件备份全部免费（D04）。
- **Cloud 服务端**：闭源的独立程序，不在本仓库（D91），只经公开的 HTTP 接口与客户端通信，不受客户端 AGPL 的约束。它不得包含本仓库的代码；需要复用时，只能是权利人自有的部分，由权利人另行授权（他人贡献的代码只按 AGPL 授权）。

## 2. 上游与组件

| 组件 | 许可 | 用法 | 义务 |
| --- | --- | --- | --- |
| sing-box v1.14.2（`af6e64c3b69e6132ebaee0e1a3d24e93903f6709`） | GPL-3.0-or-later | 编译进 Core Bridge | 保留版权与许可；遵守上游的名称与关联声明（不暗示上游背书）；提供对应源码。[上游 LICENSE](https://github.com/SagerNet/sing-box/blob/af6e64c3b69e6132ebaee0e1a3d24e93903f6709/LICENSE)、[本地原文](licenses/sing-box-LICENSE.txt) |
| sing-box 的 Go 依赖（含 Tailscale 相关模块） | 各自许可 | 编译进 Bridge | 版本由 `core/go.sum` 锁定。发行前用 `go-licenses` 按 `core/BUILD_TAGS` 生成清单并逐项核对 |
| `github.com/sagernet/gomobile` v0.1.13 | BSD-3-Clause | 构建工具与绑定运行时，编译进 Android 与 Apple 原生库 | 保留版权声明 |
| gomobile（golang.org/x/mobile） | BSD-3-Clause | 构建工具 | 保留声明 |
| Wintun 0.14.1 | 官方预编译二进制许可 | 固定 sing-tun 模块内嵌官方 Windows TUN DLL | [许可原文](licenses/wintun-0.14.1-LICENSE.txt) 随应用打包并在关于页展示；发行前按实际目标架构核对官方二进制来源与渠道义务 |
| `github.com/tailscale/go-winio`（版本由 `core/go.mod` 固定） | MIT | Windows 本地命名管道 | 保留 [许可原文](licenses/go-winio-LICENSE.txt)，随应用打包并在关于页展示 |
| ffi 2.2.0 | BSD-3-Clause | Dart 直接调用 Windows 命名管道与 UAC API（D124） | 保留 pub 包许可，由 Flutter LicenseRegistry 展示 |
| Flutter 与 Dart 包 | 多为 BSD／MIT／Apache-2.0 | 客户端 | 每次发行按锁定的依赖版本生成清单；Flutter 的 LicenseRegistry 在关于页展示 |
| Material Symbols Rounded（`material_symbols_icons` 包内字体） | Apache-2.0 | 随应用分发的图标字体 | 保留许可声明；发行版按实际使用的字形做字体裁剪 |
| flutter_svg | MIT | 渲染应用与登录按钮的品牌标志 | 保留许可声明 |
| file_picker | MIT | 系统打开／保存文件对话框（D78） | 保留许可声明 |
| share_plus | BSD-3-Clause | 日志分享（系统分享面板） | 保留许可声明 |
| package_info_plus、package_info_plus_platform_interface | BSD-3-Clause | 读取已安装应用的实际版本与构建号（D107） | 保留版权、许可与免责声明；在关于页展示 |
| desktop_drop | Apache-2.0 | 桌面拖入配置文件 | 保留许可与 NOTICE |
| flutter_zxing（内含 zxing-cpp、zint） | MIT；zxing-cpp 为 Apache-2.0，zint 为 BSD-3-Clause | 扫描订阅二维码（D79） | zxing-cpp（Apache-2.0）与 zint（BSD-3-Clause）的许可随应用打包（`app/assets/licenses/`），在关于页「许可与第三方声明」中显示；zxing-cpp 的许可全文取自标准 Apache-2.0 文本，发行前与上游仓库的 LICENSE 核对 |
| window_manager、tray_manager，及其依赖 screen_retriever、menu_base、uni_platform | MIT | 桌面窗口与托盘（D93） | 保留许可声明 |
| shortid（tray_manager 引入） | BSD-3-Clause | 托盘菜单项的标识 | 保留许可声明 |
| AndroidX WorkManager（`androidx.work:work-runtime` 2.10.0） | Apache-2.0 | Android 无界面的定时更新（D75） | 保留许可声明 |
| camera、image_picker、cross_file | BSD-3-Clause（Flutter 团队） | 相机预览（Android 侧为 CameraX，Apache-2.0）；image_picker 由 flutter_zxing 引入，应用不调用 | 保留许可声明 |
| Avalon 图标、启动动画与品牌 SVG（`app/branding/`、`packages/av_design/assets/brand/avalon.svg`、各平台图标） | 本项目（AGPL-3.0），作者 MasterAlanLab | 应用图标、启动动画、应用内标志（D90） | 保留作者与许可声明 |
| Apple 标志、Google G 标（`packages/av_design/assets/brand/`） | 商标；Apple 标志的矢量数据来自 Simple Icons（CC0-1.0） | 仅用于对应的登录按钮（D65） | 按 Apple 与 Google 的登录按钮规范使用，发行前复核 |
| SF Pro、SF Mono、苹方（宿主 macOS 系统字体） | Apple 系统字体许可 | 仅在按需参考画布渲染时从本机读取（D68、D119）；不维护页面截图基线，生成图片不入库，字体文件不随项目分发 | 不得把字体文件复制进仓库或安装包 |
| metacubexd 面板 | 以上游为准 | 由内核在运行时从上游下载，不随应用分发 | 关于页注明来源 |
| sing-geosite／sing-geoip 规则集 | 以上游及其数据源为准 | 运行时从上游下载，不随应用分发 | 关于页注明来源；不将数据打包进安装包 |
| mihomo | GPL-3.0 | 不使用，仅保留许可原文作历史审计证据 | [本地原文](licenses/mihomo-LICENSE.txt) |

GPLv3 与 AGPLv3 第 13 条允许二者组合：GPL 部分仍受 GPL 约束，Avalon 部分仍受 AGPL 约束。进程或 wrapper 边界不构成许可豁免。

## 3. 来源政策

- **新增依赖**：优先选择 MIT、BSD、Apache-2.0、ISC 许可；许可未知或来源不明的依赖不得加入。生成式改写不能消除受限代码的来源义务。

## 4. 对应源码与发行记录

- **发行记录**：每次发行记录 Avalon commit、sing-box tag 与 commit、build tags、Flutter／Dart／Go 与平台 SDK 版本、依赖清单与许可、权限、制品哈希。
- **客户端对应源码**：随发行提供完整对应源码（Corresponding Source）及构建说明；不能只给可变的上游链接。
- **源码与机密分离**：源码不包含生产数据、凭据、签名密钥或加密密钥。

## 5. 渠道

| 渠道 | 发行前必须确认 |
| --- | --- |
| 直装（GitHub Releases 等） | 依赖清单、对应源码、签名或公证、安装与卸载对系统设置的恢复 |
| Google Play | 以上各项，加 VPN 声明、账号删除要求、Play Billing、隐私政策；`QUERY_ALL_PACKAGES`（分应用代理列出应用，D80）需在 Play Console 提交权限用途声明 |
| Apple App Store | 以上各项，加 GPL／AGPL 与商店条款（EULA／使用规则）的兼容性审查、NetworkExtension 权限、StoreKit；不在中国大陆店区上架（D50） |
| Mac App Store | 同 App Store，网络扩展采用 App Extension 形态 |

- 许可兼容不等于渠道审核通过；其他同类应用已上架也不能证明本组合合规。冲突需要权利人授权，或改选合规渠道。
- macOS 直装宿主按 D73／D109 使用 System Extension，内核只链接进扩展；Mac App Store 渠道使用 App Extension。签名、系统批准及各渠道的验收状态见 [平台状态](STATUS.md#platform-status)。
- 关于页显示实际版本、内核版本、许可与源码链接，随包附带离线可读的第三方声明。
- 发布与部署是对外动作，在发行阶段另行取得用户授权。

## 6. 使用范围与免责声明（D102）

**Avalon 不支持在中国大陆地区使用。** 根 [README](../README.md) 默认英文，另提供 [简体中文版本](../README.zh-CN.md)；两个版本均在顶部显著展示本说明。

使用者自行承担使用本项目的一切行为及其后果，并有责任遵守所在地及其他适用的法律法规。在适用法律允许的最大范围内，作者与贡献者不对使用者的行为、因使用或无法使用本项目产生的损害、损失或法律后果承担责任。本项目按现有状态提供，不提供任何明示或默示担保。

该声明说明项目的支持范围和责任限制，不修改 [AGPL-3.0-only](../LICENSE) 授予的权利；担保及责任限制以许可证第15、16条和适用法律为准。
