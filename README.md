<div align="center">
  <img src="tool/branding/icon.svg" width="144" height="144" alt="Avalon Gate 图标">
  <h1>Avalon</h1>
  <p><strong>Route · Connect · Control</strong></p>
  <p>
    <a href="https://github.com/MasterAlanLab/avalon/releases"><img src="https://img.shields.io/github/v/release/MasterAlanLab/avalon?display_name=tag&amp;style=flat-square&amp;logo=github&amp;logoColor=white&amp;label=Release&amp;color=E3A72F&amp;cacheSeconds=300" alt="最新版本"></a>
    <a href="https://github.com/MasterAlanLab/avalon/actions/workflows/build.yaml"><img src="https://img.shields.io/github/actions/workflow/status/MasterAlanLab/avalon/build.yaml?style=flat-square&amp;logo=githubactions&amp;logoColor=white&amp;label=Build" alt="构建状态"></a>
    <a href="LICENSE"><img src="https://img.shields.io/badge/License-AGPL--3.0-17191D?style=flat-square&amp;logo=gnu&amp;logoColor=white" alt="AGPL-3.0 许可证"></a>
    <a href="https://github.com/MasterAlanLab/avalon/releases"><img src="https://img.shields.io/badge/Android-arm64%20%7C%20armv7%20%7C%20x86__64-3DDC84?style=flat-square&amp;logo=android&amp;logoColor=white" alt="Android: arm64, armv7, x86_64"></a>
    <a href="https://github.com/MasterAlanLab/avalon/releases"><img src="https://img.shields.io/badge/Windows-x64-0078D4?style=flat-square&amp;logo=windows11&amp;logoColor=white" alt="Windows: x64"></a>
    <a href="https://github.com/MasterAlanLab/avalon/releases"><img src="https://img.shields.io/badge/macOS-ARM64-000000?style=flat-square&amp;logo=apple&amp;logoColor=white" alt="macOS: ARM64"></a>
    <a href="https://github.com/MasterAlanLab/avalon/releases"><img src="https://img.shields.io/badge/Linux-x64-FCC624?style=flat-square&amp;logo=linux&amp;logoColor=17191D" alt="Linux: x64"></a>
  </p>
</div>

[简体中文](README.md) · [English](docs/README.en.md) · [العربية](docs/README.ar.md) · [Deutsch](docs/README.de.md) · [Español](docs/README.es.md) · [Italiano](docs/README.it.md) · [日本語](docs/README.ja.md) · [한국어](docs/README.ko.md)

Android、Windows、macOS 和 Linux 平台的代理客户端，基于 [mihomo](https://github.com/MetaCubeX/mihomo) 内核，支持独立节点、订阅管理和多跳代理链。使用 Flutter 编写。

> Avalon 基于 [FlClash](https://github.com/chen08209/FlClash) 二次开发。

从 [Releases](https://github.com/MasterAlanLab/avalon/releases) 下载对应平台的安装包。

## 功能特性

- 多协议支持：VLESS、VMess、Shadowsocks、Trojan、Hysteria2、TUIC、AnyTLS、SOCKS4/4a/5、HTTP(S) 等。
- 节点管理：独立管理单个节点，支持添加、编辑、复制和配置绑定。
- 订阅管理：通过链接或本地文件导入配置，支持订阅自动更新。
- 代理链：组合节点、策略组和本地代理端口，支持前置代理、多跳连接与路径预览。
- 配置生成：从链路创建可直接运行的配置，也可将链路加入已有配置的策略组。
- 导入导出：支持节点 URI、二维码、YAML / JSON，节点与链路可连同附件打包导出。
- 路由规则：支持规则、全局和直连模式，可编辑分流规则与策略组。
- 网络诊断：节点延迟测试、实时连接查看与运行日志。
- 数据同步：本地备份与恢复，支持 WebDAV 同步。
- 界面主题：适配桌面和移动端，支持深色模式与自定义配色。
- Tailscale：查看设备、配置 Tailnet 分流、远端子网和出口节点。

## 运行模式

| 模式 | 说明 |
| :--- | :--- |
| Rule | 按配置中的规则匹配出站策略 |
| Global | 所有进入内核的流量使用全局策略组选定的出站 |
| Direct | 直接连接目标，不使用代理节点 |

桌面端支持系统代理和 TUN；Android 通过 VPN 服务接入流量。系统代理仅覆盖遵循代理设置的应用，TUN/VPN 按配置的路由、IPv6 和访问控制设置接管流量。

## 核心引擎

使用 [mihomo](https://github.com/MetaCubeX/mihomo) 处理代理连接、DNS 解析、规则分流与 TUN 流量。除协议表单外，也支持使用 Raw YAML / JSON 配置其他 mihomo 节点类型。

订阅、节点库和代理链统一生成运行配置。代理链通过 `dialer-proxy` 串联各跳，按「客户端 → 前置 → 主节点 → 后置 → 目标」的顺序连接，由单个内核实例运行。

## 开发

在仓库根目录运行。当前 CI 使用 Flutter 3.44.4、Go 1.26.4；原生组件还需要 Rust 和各平台工具链。

```bash
flutter pub get
flutter analyze --no-fatal-infos
flutter test
```

## 文档

- [开发与构建](docs/development.md)：环境初始化、核心与应用构建、测试、代码生成和 CI。
- [Tailscale](docs/tailscale.md)：登录、分流、出口、身份管理及已知问题。
- [发布工作流](.github/workflows/build.yaml)：分平台打包与发布配置。

## 技术栈

- 语言：Dart、Go、Rust
- 界面框架：Flutter / Material Design
- 状态管理：Riverpod
- 数据库：SQLite / Drift
- 代理内核：mihomo
- 包管理：Pub、Go Modules、Cargo

## 资源推荐

部分链接为推广链接，通过链接注册或购买，作者可能获得佣金。服务内容与价格以对应网站为准。

| 类别 | 项目 / 服务 | 说明 |
| :--- | :--- | :--- |
| 代理池 | [Free Proxy](https://github.com/MasterAlanLab/free-proxy) | 自建代理池，可接入节点库或代理链 |
| VPS | [搬瓦工](https://cutt.ly/qywJNWzd) · [DMIT](https://cutt.ly/YywJIzY0) | 节点与应用部署 |
| 虚拟信用卡 | [海外虚拟卡](https://cutt.ly/IyrMR4Mg) | 海外服务支付 |
| 资源搜索 | [Telegram 搜索机器人](https://cutt.ly/2yeh3GOE) | Telegram 资源检索 |
| 账号与电话卡 | [海外账号与电话卡](https://cutt.ly/dywt86NC) | 账号及通信服务 |
| 指纹浏览器 | [比特指纹浏览器](https://client.bitbrowser.cn/register?lang=zh&code=Alan123) | 独立浏览器环境管理 |
| 邮箱托管 | [Emailbox](https://github.com/MasterAlanLab/emailbox) | 批量邮箱管理与代理分组 |
| 验证码服务 | [Captcha.run](https://captcha.run/sso?inviter=542f4f4f-31b6-4b70-b485-c4762c45d1e8) · [YesCaptcha](https://cutt.ly/Mywt39r0) | 验证码识别 |
| AI 接口 | [CC / GPT 中转](https://cutt.ly/JywJG3G5) | 模型接口服务 |
| 订阅合租 | [订阅合租平台](https://cutt.ly/5ywt8vb4) | 订阅共享 |

## License

[AGPL-3.0](LICENSE)。第三方代码保留各自许可，版权与许可说明见 [NOTICE](NOTICE)。

## 致谢

- [FlClash](https://github.com/chen08209/FlClash)
- [mihomo](https://github.com/MetaCubeX/mihomo)
- [Surfboard](https://github.com/getsurfboard/surfboard)
