# 数据模型与存储

本文定义领域模型、Drift 表、秘密存储、事务规则和备份文件格式，当前 schema 为 v4（D98）。所有表位于同一个应用数据库；原生宿主不访问此数据库，只接收编译好的运行计划。同步实现与生命周期预览的范围见 [Cloud 状态](STATUS.md#cloud)。

## 1. 领域模型

### 1.1 配置

| 类型 | 字段 | 说明 |
| --- | --- | --- |
| `Configuration` | id、kind（`subscription`／`file`／`self`）、name、source?、autoUpdate、content?、usage?、lastSuccessAt、lastError、createdAt、editedAt | id 为 UUID；内置「自建节点」配置固定 id `self` |
| `SubscriptionSource` | url、headers（秘密） | 只存在于订阅 |
| `Usage` | upload、download、total、expireAt | 仅来自订阅响应头 |
| `ConfigContent` | nodes、groups、rules、ruleSets、finalTarget、warnings | 导入后的类型化内容，不含秘密；`self` 配置不存内容，编译时生成 |
| `NodeDef` | key、name、protocol、server、port、params、detourKey? | key 在配置内唯一（§1.3）；params 是按协议区分的 sealed 类型；`detourKey` 来自 Clash `dialer-proxy` |
| `GroupDef` | key、name、type（`selector`／`urltest`）、displayType（Selector／URLTest／Fallback／LoadBalance）、members、test? | test 为 url、interval、tolerance |
| `RuleDef` | 匹配项（domain、domainSuffix、domainKeyword、domainRegex、ipCidr、srcIpCidr、ruleSet、processName、processPath、port、network、invert）、target | target 是 MemberRef 或 direct／reject |
| `RuleSetRef` | tag、url、format（`binary`／`source`／Clash 的 domain、ipcidr、classical 各两种：yaml、text） | 以（url, format）对应 `rule_resources` 里的缓存；tag 只是该配置里的名字（D86） |

### 1.2 用户自建内容与偏好

| 类型 | 字段 | 说明 |
| --- | --- | --- |
| `SelfNode` | id、name、protocol、server、port、params、secretId、createdAt、editedAt | 九种协议之一 |
| `Chain` | id、name?、hops（`List<HopRef>`，≥2）、createdAt、editedAt | name 为空时显示由跳名拼接 |
| `Membership` | ownerId（节点或链）、configurationId、groupKey | 自建节点／链加入某配置的 Selector 组 |
| `Selection` | configurationId、groupKey、member、manual、editedAt | 只有 `manual=true` 的选择参与同步 |
| `DeviceSettings` | PRODUCT_SPEC §4 中除 JSON 覆写和 GEO 更新设置外的全部设置，以及分应用名单 | 设备设置，不同步，进入备份 |
| `Policy` | jsonOverride（秘密）、geoAutoUpdate、geoInterval、geoVia、editedAt? | `editedAt` 为空表示从未被用户修改，不上传 |
| `RuleResource` | url、format、file?、sha256?、size?、updatedAt?、checkedAt?、lastError?、skipped | 规则集的下载缓存，以（url, format）识别。定义不入库：用到哪些规则集由默认目录和配置内容推导（D86）。file 为 `rulesets/` 下的文件名；checkedAt 为最近一次下载尝试（成功或失败）；skipped 为 Clash 转换时跳过的不支持的规则数 |

### 1.3 引用

```dart
sealed class MemberRef {}
class SourceMember extends MemberRef { String configurationId; String key; } // 来源节点或来源组
class SelfNodeRef  extends MemberRef { String id; }
class ChainRef     extends MemberRef { String id; }
class TailnetExitRef extends MemberRef { String tailnet; String nodeStableId; String name; }
class BuiltinRef   extends MemberRef { Builtin kind; } // direct / reject

// HopRef 只允许 SourceMember（节点）、SelfNodeRef、TailnetExitRef；不允许组或链。
```

- **来源 key**：
  - Clash：`proxy:<name>`、`group:<name>`；provider 节点为 `provider:<providerName>/<name>`。
  - sing-box：`tag:<tag>`。
  - URI 列表：去重后的名称，同名依次加 ` (2)`、` (3)`。
  - 每个配置都注入的「自定义」组，groupKey 固定为 `custom`。
- **身份规则**：名称只用于显示；同一 key 在刷新后仍存在即视为同一成员。
- **引用失效**：成员消失时保留引用，界面显示「不可用」（PRODUCT_SPEC §3.2），不按名称或相似度重新绑定。
- **跨配置链跳**：链跳可引用任何配置的来源节点；编译时按该配置当前内容解析，配置被删除则链不可用。
- **Tailscale 出口**：`TailnetExitRef` 保留对已存引用的兼容；出口选用、广告和所有代理链位置按 D110 禁用，已存选择允许清除。

## 2. Drift 表

以下列出基础表与字段；schema v4 的生命周期扩展见 [§4](#4-事务与不变量)。列名为 snake_case；时间为 UTC 毫秒整数。`FK` 均为 `ON DELETE CASCADE ON UPDATE CASCADE`（`ON UPDATE` 用于 D27 的配置改 id）。

```text
configurations  id PK, kind, name, source_secret_id NULL, source_display NULL, auto_update,
                content_id NULL, usage_upload/download/total NULL, expire_at NULL,
                last_success_at NULL, last_attempt_at NULL, last_error NULL,
                created_at, edited_at, cloud_account_id NULL
contents        id PK, configuration_id FK, format, model_json, secret_id, node_count, digest, warnings_json, created_at
self_nodes      id PK, name, protocol, server, port, params_json, secret_id, created_at, edited_at, cloud_account_id NULL
chains          id PK, name NULL, hops_json, created_at, edited_at, cloud_account_id NULL
memberships     owner_kind('node'|'chain'), owner_id, configuration_id FK, group_key, created_at
                PK(owner_kind, owner_id, configuration_id, group_key)
                -- owner 无外键：删除节点或链时由 Repository 在同一事务内删除其成员关系
selections      configuration_id FK, group_key, member_json, manual, edited_at, cloud_account_id NULL, document_id NULL
                PK(configuration_id, group_key)
device_settings id=1, json, secret_id NULL, edited_at   -- secret_id：设置中的秘密（Clash API 密钥）
policy          id=1, override_secret_id NULL, geo_auto_update, geo_interval, geo_via, edited_at NULL, cloud_account_id NULL, document_id NULL
rule_resources  url(sha256:<地址摘要>), format, file NULL, sha256 NULL, size NULL, updated_at NULL, checked_at NULL, last_error NULL, skipped DEFAULT 0
                PK(url, format)   -- 只是下载缓存，不进备份（D86）
secrets         id PK, nonce, ciphertext, created_at
cloud_session   id=1 活动会话／安装身份；id=2 加密待撤销队列所有者；account_id, email, display_name, device_id, installation_id,
                access_secret_id, refresh_secret_id, entitlement_json, logged_in, updated_at
sync_meta       account_id, record_id, type, document_id, remote_revision NULL, dirty, deleted, edited_at, mutation_id NULL,
                pending_envelope_secret_id NULL, in_flight_mutation_id NULL, in_flight_envelope_secret_id NULL
                PK(account_id, record_id)
sync_documents  document_id PK, account_id NULL, record_id, type, local_id NULL,
                remote_revision/remote_edited_at/remote_deleted/remote_schema_version NULL, remote_payload_secret_id NULL,
                local_payload_secret_id NULL, local_edited_at, local_deleted, local_schema_version DEFAULT 1
                UNIQUE(account_id, record_id)
source_provenance document_id PK, origin, origin_account_id NULL, source_generation, private_consent_generation NULL
sync_state      account_id PK, cursor, last_sync_at NULL, blocked_reason NULL, bootstrap_completed DEFAULT false
```

- 数据库创建时插入 `configurations(id='self', kind='self')`。「自建节点」卡只在存在自建节点或链时显示。
- `contents` 每个配置只保留当前一份。更新时在同一事务中插入新行、切换 `content_id`、删除旧行及其秘密。
- 当前选中的配置 id、出站模式、Tailscale 开关与出口选择存于 `device_settings`。
- `installation_id` 在首次启动时生成，不进入备份；Cloud 用它识别设备（[CLOUD_SYNC §3](CLOUD_SYNC.md#3-认证与设备)）。
- `cloud_session(id=1)` 退出后保留未登录哨兵行和 installationId；access／refresh、期限和 sessionId 仅在加密秘密条目中。刷新前通过事务原子抢占 `refreshUncertain`，成功保存新令牌时一并清除；账号资料更新核对原 sessionId，仅修改资料列，不覆盖 guard 或最新令牌引用。刷新与失败行为见 [CLOUD_SYNC §3](CLOUD_SYNC.md#3-认证与设备)。
- `cloud_session(id=2)` 不表示登录会话，仅以 `refresh_secret_id` 拥有加密待撤销队列（sessionId、refreshToken proof、该 proof 原 refreshExpiresAt）。旧队列缺期限时按 null 读取；新项保存 UTC 时间，与 token 成对替换。退出事务同时入队并清除活动令牌；定向删除核对原 sessionId 与 token。两个 Cloud 所有者行及其凭据均不进备份，秘密孤儿清理保留两行引用；队列不另增 schema 版本。撤销响应及重试规则见 [CLOUD_SYNC §3](CLOUD_SYNC.md#3-认证与设备)。

## 3. 秘密（Vault）

- **主密钥**：32 字节随机数，存于系统安全存储：Keychain、Android Keystore（经 flutter_secure_storage）、Windows 凭据存储、Linux Secret Service。Linux 仅在原生检查明确确认 Secret Service 不可用、且允许首次初始化时，创建 `$XDG_DATA_HOME/avalon/master.key`（权限 0600；未设有效 XDG 路径时用 `$HOME/.local/share`），并在关于页提示（D23、D108）。已有文件回退安装继续使用原文件；锁定、拒绝访问、超时或未知存储错误不触发回退。macOS 的调试构建没有团队签名、用不了钥匙串，同样存为容器内的 0600 文件（D77）；发布构建不走这条路。
- **首次创建边界（D97）**：有旧加密条目时读取不到主密钥，停止打开Vault并保留密文；不能自动生成替代钥匙。存储读取／写入异常与缺钥分别报告，读取值须满足合法编码及32字节长度。Android明确禁用错误后的自动重置，保持既有算法与namespace；文件回退同样不在有旧密文时自动重建。单条认证失败不证明永久失钥；按账号的隔离恢复入口是独立工作项。
- **秘密条目**：每个对象一个，明文为 JSON（例如 `{"uuid": "...", "password": "..."}`），用 XChaCha20-Poly1305 加密，AAD 为条目 id，存入 `secrets` 表。
- **哪些是秘密**：订阅 URL 和请求头、节点的用户名／UUID／密码／混淆密码／私钥类字段、内容中的 URL、JSON 覆写全文、Cloud token、Clash API 密钥、桌面系统代理恢复原值（可能包含 PAC 地址或凭据）。服务器地址、端口、SNI、公钥、Short ID 不是秘密。
- **修改**：写入新条目 → 更新所有者的 `secret_id` → 删除旧条目，三步在同一事务内完成。
- **清理**：启动时删除没有任何所有者引用的条目；固定设备恢复条目也是有效所有者。
- **系统代理恢复（D111）**：Windows／Linux 应用平台层在改动系统设置前，将后端标识、记录版本、原值与本次目标值加密写入固定条目 `avalon.runtime.system-proxy`；不新增数据库表或 schema 版本。该条目不属于用户内容，不进入备份或同步，也不被孤儿清理删除。写入／恢复失败时保留，恢复成功或确认外部接管后删除；关联组比较与端口来源规则见 [RUNTIME_HOST §7](RUNTIME_HOST.md#7-系统接管与恢复)。
- **存法**：带秘密的模型（配置内容、自建节点参数、设备设置、订阅来源）先经 `SecretCodec` 把全部秘密值拆出，公开部分存入所有者的 JSON 列，拆出的值作为一个条目加密存入 `secrets`。内容／节点适配器 `ContentSecrets` 同时保护领域模型里仍为 String 的 username 与 URL；规则集缓存仅保存地址摘要，真实地址从解密后的内容取得。完整同步 payload 和冻结请求正文也只在秘密条目中加密保存，不把本机条目 id 发到 Cloud。
- **不可解密材料**：有效主密钥下单条认证失败使用既有凭据恢复提示，不能据此认定整次安装永久失钥。有旧密文但 OS 主密钥缺失或读取失败时拒绝打开 Vault，启动失败页保留全部本机资料，不自动重置或造空凭据。恢复入口的实现范围见 [本地数据状态](STATUS.md#local-data)。

## 4. 事务与不变量

- 一次用户操作对应一个 SQLite 事务：内容、秘密、成员关系、选择和 `sync_meta` 一起提交，失败则整体回滚。
- 自建节点被任一链引用时不能删除，由 Repository 检查（PRODUCT_SPEC §3.4）。
- 删除配置时级联删除其内容、选择、成员关系；链中引用该配置节点的跳保留，链变为不可用。
- **订阅刷新提交前检查**：确认配置仍存在，且 `source_secret_id` 未在下载期间变化（例如被编辑或被同步替换）；否则丢弃结果。
- 同步与本地编辑的冲突规则只有 LWW 一条（[CLOUD_SYNC §6](CLOUD_SYNC.md#6-同步协议)），不建额外版本体系。
- 原生宿主的实际状态不写入数据库；外部面板的修改由 RuntimeCoordinator 写回偏好（D30）。

### 同步文档与投影（D96）

`sync_meta` 使用账号／recordId 复合主键，canonical 文档与持久来源分别存表。`SyncRepository` 保存账号作用域 localId 映射、完整加密本地／远端 payload、pending 与 in-flight 两个冻结请求槽；跨页未解析引用随镜像保存，暂不能投影时也不丢引用。较新编辑替换 pending，结果未知的已发正文保留在 in-flight，确认使用原 mutationId，旧结果不能清掉新编辑或倒退已观察的远端 revision。

`SyncProjection` 将文档投影到用户内容表。policy／selection 的单行仅是当前可见投影，分别指向 canonical owner，其他账号快照继续加密保存。用户内容编辑与 dirty／秘密提交同事务；整页验证后，镜像、业务投影、cursor 同事务；HTTP 返回后在提交事务内再次核对 account、session 与 worker 代次。首次订阅配对以原 URL 字符串完全相同为准，多项按 ID 排序一对一绑定，并原子改写成员／链跳／选择引用。

退出保留账号文档和 dirty；删除账号的本机清理见下文。来源 `cloud` 与 source generation 持久保存，账号解绑不会赋予私网许可。账号隔离、上传范围及来源行为见 [CLOUD_SYNC §7](CLOUD_SYNC.md#7-客户端同步引擎)。

### 同步生命周期存储（D98，协议 2）

schema v4 在现有文档、outbox 和账号状态增加 Cloud `syncGeneration`。升级不解密或重写旧冻结 wire：服务端明确 `spaceOrigin=legacy` 时绑定原 cursor／mutation／镜像，明确 `rebuilt` 时加密归档旧作用域、清远端基线并保留 canonical 身份和真实离线修改；缺少证据则停止同步。实际用户变更用 `pendingMerge` 与旧基线区分，旧镜像不会整份标 dirty。

`sync_archives` 保存加密隔离材料，`sync_archive_references` 显式拥有其全部秘密引用。`sync_rebuild_entries` 以账号／代次／本机尝试隔离固定 envelope 和已确认前缀；服务器尝试 ID 与本机 manifest ID 分开。控制请求在 HTTP 前加密持久化，未知结果只重放原 operationId／正文；确认拒绝先归档再解除控制。`sync_pull_stages`／`sync_pull_stage_entries` 保存加密完整下载阶段，只有相同代次和稳定 head 全部收齐、复核状态后才原子投影并推进 cursor。半轮失败或投影失败不改变可见内容，重启可继续已存阶段。

所有 archive、清单、control 与下载 stage 的秘密引用纳入孤儿保护。HTTP 提交同时检查账号、会话、本机 worker、Cloud 代次及尝试；档案和阶段不进入普通文件备份。重建指定设备显式绑定选择的内容；其他设备仅加入远端投影，不自动绑定未上传本机资料。schema v4 不自动替换丢失的本机主密钥。

删除账号先在同一事务中加密归档该账号活动文档、未知请求、清单、控制正文及下载暂存，并持有其秘密引用，再解除活动代次与远端基线、清除 outbox／重建／下载阶段和账号状态。本机 canonical 内容、凭据、持久来源限制及其他账号不变；归档不能作为自动上传来源。没有活动材料的重复解绑不再建档，归档或清理失败全部回滚。普通退出继续保留账号待同步材料。

## 5. 迁移

- Drift `schemaVersion` 从 1 开始，每一步迁移都有测试（从每个历史版本迁移到最新）：`app/test/data/schemas/v<N>.sqlite` 保存每个历史版本的空库，测试把它升级到最新后与新建的库逐表比对结构。
- 版本 2（D86）：`rule_resources` 改为以（url, format）为主键的下载缓存，迁移丢弃旧表重建。
- 版本 3（D96）：重建账号复合键 `sync_meta`，保留旧元数据，新增 `sync_documents`／`source_provenance`，给 policy／selection 增加 owner 文档引用和首次同步状态。迁移先保留旧归属，Vault 可用后再补齐加密 payload；迁移不写入解密业务 JSON。历史 v1／v2 fixture 与非空归属升级由迁移回归覆盖。
- 版本4（D98）：新增代次／pendingMerge列及加密档案、重建和完整下载阶段表；v3升级不修改冻结wire和密文。历史v1／v2／v3fixture结构与非空旧请求保留由迁移回归覆盖。
- 迁移在事务中执行，失败时保留原文件并显示错误，绝不清库。
- 数据库版本高于应用支持的版本时只显示「请更新 Avalon」，不读写。
- 数据库 schema、导入格式、备份格式、Cloud payload 各自独立设版本号。

## 6. 备份文件格式（D18）

```text
.avalonbackup =
  magic "AVBK" (4B) | version u8 = 1
  | kdf: argon2id, salt 16B, memory_kib u32 = 65536, iterations u32 = 3, parallelism u8 = 1
  | nonce 24B
  | ciphertext = XChaCha20-Poly1305(key = Argon2id(password), plaintext = gzip(JSON), aad = 以上头部)
```

整数为大端序。读取方按文件头里的 KDF 参数派生密钥，但拒绝超出上限的参数（内存 ≤ 1 GiB、迭代 ≤ 16、并行度 ≤ 8），以免一个恶意文件耗尽内存。各表的行按列名原样写入，但不含 Cloud 绑定（`cloudAccountId`）；列的增减即备份格式的变更，由测试固定。

明文 JSON：

```json
{
  "format": "avalon-backup", "schema": 1, "createdAt": "…", "app": {"version": "…", "platform": "android"},
  "configurations": [], "contents": [], "selfNodes": [], "chains": [], "memberships": [],
  "selections": [], "policy": {}, "deviceSettings": {},
  "secrets": {"<secretId>": {"…": "明文，仅存在于加密文件内"}}
}
```

- **导出**：在同一个只读事务中读取用户内容及其秘密；Cloud 会话、同步运行材料和固定系统代理恢复条目不进入备份。解密秘密后写入密码加密文件，内存中的明文用后即弃。
- **恢复**：
  1. 解密并校验格式、版本和数量上限（配置 ≤1000、节点 ≤50000、文件 ≤64 MiB）。
  2. 在一个事务中按 D18 合并：秘密按本机主密钥重新加密，并生成新的条目 id、改写所有者的 `secret_id`；被覆盖对象的旧秘密条目一并删除。规则集缓存不在备份里（D86），恢复后由 ResourceService 按需重新下载；早期备份里的 `ruleResources` 读入时忽略。
  3. 绑定了 Cloud 的对象若发生变化，标记 `dirty`。
- 恢复不改变 `cloud_session`、`sync_state`、`installation_id` 或本机系统代理恢复条目。
