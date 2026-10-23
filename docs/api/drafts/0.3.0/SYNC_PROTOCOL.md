# Avalon Cloud 同步协议 2（0.3.0 评审草案）

状态：**开发预览，未发布、未冻结，完整验收未完成**。本目录供双端适配，不替代唯一已发布的 [0.2.0](../../cloud.openapi.yaml) 与其 [规范](../../SYNC_PROTOCOL.md)。固定 UTC 30 天、服务端管理加密和普通受控灾备政策已由用户于2026-10-14确认（D100）；正式发布、历史政策迁移、真实购买核验与客户端兼容仍需独立验收。首七账号操作及可达 wire 定义保持原样。

本文件中的 MUST／MUST NOT 是**显式采用此候选协议时双端必须遵守**的互操作与安全约束。候选仍未正式发布，不能修改已冻结 0.1.1／0.2.0、SHA 或未采用新版政策的现有资料，也不能替代完整验收。引用的 0.2.0 规范只有下文明确替代的部分改变；schema 1、严格解析、秘密、来源限制及未替代约束继续适用。

## 1. 版本、信任与生命周期

所有本版同步操作 MUST 发送 `Avalon-Sync-Version: 2`，同步成功和错误响应 MUST 回同值及 `Cache-Control: no-store`。缺失／未知版本为 `426 SCHEMA_UNSUPPORTED`。同步协议、OpenAPI 版本、payload schema、本机数据版本与 Cloud `syncGeneration` 是独立概念；不得代替或自动降级。

`syncGeneration` 是服务端生成且永不复用的随机 UUID，只确定账号同步空间，不能证明权限。账号、会话和设备 MUST 取自已验证的有效会话；服务端 MUST 重新核验撤销、期限、设备归属、权益及激活。所有生命周期变更、revision 分配、控制、结果保存和删除 MUST 按账号保持原子一致；授权、当前权益版本、目标代次和时间 MUST 与相应提交一致，防止并发撤销、续费或清理绕过授权。客户端声明的账号、设备、权益或标识不得替代这些检查。

草案保留期定义为 `retentionUntil=E+2592000秒`，E 为权威权益实际到期的 UTC 时刻，不是取消续费、webhook 到达、任务发现或客户端打开时间。用户已确认采用固定UTC30天；历史账号仍须通知并遵守一次性过渡截止，不能据此提前清理未迁移账号。

| 服务端事实 | 同步与控制 | 空间 |
| --- | --- | --- |
| 有效权益，now<E | 可激活；ready 才可普通上下行 | 原代次继续 |
| E≤now<retentionUntil，无有效续费 | activate／push／pull／重建控制均 402 | 资料、墓碑、密钥和激活保留；免费状态可读 |
| 截止已到，权威核验未知 | 暂停，返回 503 SYNC_ENTITLEMENT_UNVERIFIED 或已确定的 402；不得下载 | verificationPending；不先永久退休、换代次或毁钥 |
| 截止已到，已权威确认无截止前有效续费 | 原子退休并确定旧代次的清理范围 | 旧代次永久不可重新开放，物理清理可异步 |
| 截止前已有效续费，即使通知迟到 | 保持原代次／映射／密钥 | 先核验，再取消旧周期清理 |
| 截止后才生效的续费，旧空间已合法退休 | 创建新 UUID 和独立加密空间；rebuildRequired | 不因旧资料尚未物理清理而恢复旧空间 |

首次从未有空间的付费账号通过 activate `{syncGeneration:null}` 原子创建首个 UUID 和受账号隔离加密保护的空 ready 空间，spaceOrigin=initial，继续原首次同步规则。null 重试只可复取从未退休的该 initial 空间，不能新建第二个代次；既有 legacy／rebuilt 或任何已退休账号的 null 为 SYNC_GENERATION_MISMATCH。响应丢失后先读取免费状态或原样重试初次 activate。只有已退休空间的替代代次进入 rebuildRequired，spaceOrigin=rebuilt；它的 UUID 由服务端在权威续费核验后原子生成，不能由客户端 null 请求跨过退休核验。密钥缺失或初始化失败 MUST 拒绝相应处理，不能用替代密钥解释旧内容。账号身份、有效会话和设备不随到期空间清理删除；主动 DELETE account 按第1.1节的新政策处理，不与订阅到期的保留期混同。

退休和删除事实 MUST 持久有效，恢复旧数据不得使其回退。清理 MUST 仅影响确定已退休代次的对应资源，迟到清理不能删除当前新空间或其密钥。核验失败、在线物理清理、密钥资源移除与受控灾备到期清理是不同事实；客户端不得按本机日期宣布已删除，也不能将在线密钥移除解释为密码学不可恢复。

### 1.1 服务端管理加密、删号与受控灾备

服务端 MUST 管理同步内容的加密保护，按账号及代次隔离密钥和内容，限制密钥访问，并保证内容与所属账号、代次、适用重建尝试及记录上下文的完整性绑定。payload、原结果、manifest 与控制回执 MUST 分别保持用途隔离，防止跨账号、跨代次、跨尝试或跨用途替换。用户无需保管云端密钥；客户端本机主密钥 MUST NOT 上传。已有内容所需密钥缺失、损坏或完整性校验失败时 MUST 停止相应处理，不能自动补钥、返回伪造空内容或用新钥解释旧内容。具体加密存储方式不属于公开接口约定。

用户批准的普通受控灾备政策为：每份备份从**原始UTC创建时刻**起最多保留2592000秒；复制、轮转、恢复、转存不得重置期限，全部受控副本到期清除。此灾备时钟与账号资料的`E+2592000秒`保留截止独立。备份 MUST 保持加密和账号隔离；保留期内仍可能恢复解密，本版**不承诺即时或最终密码学不可解密**，也不把在线密钥移除当作删除灾备证明。备份不得绕过到期同步或删号授权拒绝，向用户提供旧内容。

主动删号 MUST 立即拒绝该不可复用账号UUID、撤销会话并删除在线关联数据，在线密钥资源按对应账号精确移除；同邮箱重新认证只建立全新UUID，不继承旧权益、激活或内容。`DELETE /v1/account`的原响应字段及状态码不变，200表示在线删除和该UUID的持续拒绝已生效，**不表示**所有灾备已清除或不可解密；响应丢失仍为未确认，不提供新的删除回执。删除拒绝一旦生效 MUST NOT 因随后失败或旧数据恢复而撤回；未完成时返回脱敏失败，不能把失败当作旧身份仍可用的证明。

恢复后的服务 MUST 继续拒绝所有已删除账号、保持已退休空间关闭，并使恢复出的旧登录凭据（含access、refresh及可证明旧会话的材料）失效，要求重新认证。恢复旧资料 MUST NOT 回退最新删除、退休或授权事实，不得因同邮箱重新注册而复用旧UUID。其他未删账号仍有效的内容应可恢复；单账号清理 MUST NOT 影响其他账号。

这是对采用本新版政策的协议2账号的**显式保证变更**：替代0.2.0规范中删号后使旧备份不可恢复、账号密钥最终不可逆销毁的相关要求；也明确覆盖为保持首七操作对象不变而留存的`deleteAccount`旧说明中“销毁账号数据密钥”的含义，改为在线密钥资源移除及有限受控灾备清理。首七账号操作与可达wire定义逐字不改，旧0.2.0归档、SHA锁和未迁移账号的原承诺继续有效。不能只切一个全局配置就改变未迁移账号的保证；正式启用须完成通知、政策迁移和双端兼容。

采用本新版加密政策的账号 MUST 拒绝协议1同步，只配套已识别`SyncCleanupKeyState.deleted`的客户端；既有账号不得未经政策迁移改变原承诺。协议头仍为2，不得以未知枚举静默降级或把deleted显示为密码学销毁。

## 2. 操作与固定 wire

| 操作 | 权益 | 输入／输出 |
| --- | --- | --- |
| GET /v1/sync/status | 免费，有效会话 | 一致生命周期状态，不含 payload |
| POST /v1/sync/activate | 付费 | body `{syncGeneration}`；回该代次与 backupState，不认领重建 |
| POST /v1/sync/push | 付费且激活 | `{syncGeneration,rebuildAttemptId,mutations}`；回同上下文、writeState 与原连续前缀结果 |
| GET /v1/sync/pull | 付费且激活 | query `syncGeneration,cursor,limit`；只读当前 ready 正式数据，响应 attempt=null |
| GET /v1/sync/rebuild | 免费，有效会话 | query `syncGeneration,attemptId`；本账号指定尝试的元数据／进度，未知或跨账号统一 404 |
| POST /v1/sync/rebuild | 付费且激活 | 单一控制操作，action=start／claim／cancel／complete；持久 operationId 回执 |

所有对象 MUST 严格拒绝缺字段、未知字段、未知枚举、重复 JSON key、不合法 Unicode／数值和预算超限；nullable 字段必须显式 null。schema 1 的完整 mutation／record 与语义 payload 不改。成功响应中的 generation、attempt、操作 ID、记录 ID 和前缀顺序 MUST 与冻结请求核对后才允许落库。

状态字段固定为 `accountId,deviceId,syncGeneration,spaceOrigin,headRevision,spaceState,backupState,entitlementExpiresAt,retentionUntil,rebuild,cleanup,serverTime`。未有空间时 generation／origin／head=null、spaceState=noSpace／backupState=none；active 有有效权益，retained 为暂停保留，verificationPending 为权威核验未知，retired 为永久结束。spaceOrigin=initial 表示从未退休的首个新空间，legacy 表示0.2.0在线空间的无损部署迁移，rebuilt 表示退休后的新空间；这是服务端事实，不接受客户端声明。headRevision 是正式已提交最大revision，未发布新空间为0。active、retained、verificationPending 的 backupState 为 ready、rebuildRequired 或 rebuilding；rebuildRequired／rebuilding 只适用于 spaceOrigin=rebuilt。retired 的 backupState=none。ready 仅表示存在正式备份，不表示权益仍有效。rebuild 非 null 只表示当前 staging 尝试；cancel／claim 后历史尝试仍由指定 attempt 查询。

`cleanup` 聚合所有已退休空间的在线清理事实：pendingGenerationCount、latestRetiredGeneration、latestRetiredAt、onlineState、keyState。onlineState=complete仅在全部相关在线清理均完成时使用；keyState引用`SyncCleanupKeyState`：none／pending／waiting／failed／deleted／destroyed。deleted只用于服务端管理模式全部相关在线密钥资源已移除，灾备仍可能解密并按原创建时刻最多UTC30天清理；destroyed仅保留旧模式的不可逆拒绝含义，不是本新版政策的完成状态或灾备销毁证明。failed优先于running／pending，none表示没有该类清理；仍活跃的新代次密钥不计入。这个对象没有逐份灾备清除回执，不能推导所有副本已删除。

## 3. 正常上下行及上下文隔离

activate 先核验有效权益和显式 generation，保持 D96 同安装会话替换与最多 10 台激活规则；到期不解除激活。发现代次不同返回 `409 SYNC_GENERATION_MISMATCH`，不得改请求正文或悄悄拉 cursor=0。已激活设备重复成功，但不授予重建 owner。

普通 push 必须 `rebuildAttemptId=null` 且当前 backupState=ready；required／rebuilding 分别为 `SYNC_REBUILD_REQUIRED`／`SYNC_REBUILD_IN_PROGRESS`。普通 pull 不接受 attempt，不读 staging 或退休空间。同代次延续 0.2.0 的严格时间 LWW、永久墓碑、连续 revision、字节分页、前缀及七天原结果规则。旧代次高 cursor 不与新代次比较，不能退回 0 当作普通恢复。

push 响应 `writeState=published` 仅确认正式空间；staged 仅确认指定尝试。原结果重放必须保留首次 generation／attempt／writeState。旧代次、旧 attempt 的合法原结果可以作为原请求事实被识别，但不能写入当前镜像、清当前 dirty、授权当前 owner 或发布当前空间。

pull 仍是当前最新记录的增量，不提供完整历史或任意时点快照。每页在同一读取快照中返回 `headRevision`，必须 `nextCursor≤headRevision`，末页 `hasMore=false` 必须 `nextCursor=headRevision`；cursor超过正式head仍400，不能从状态head擅自跳过数据。整页验证和本机事务回滚规则继续适用；普通同步仍保留未解析引用，不能把重建发布的闭包要求误套为拒收普通增量页。

隔离全量恢复从cursor=0捕获首个head H，要求全部页同generation且head=H、末页hasMore=false且nextCursor=H，再取免费status确认同generation／head=H，才可原子切换完整镜像；期间head变化保留原本机内容，放弃该不一致暂存视图并有界重试。稳定head证明该轮正式资料未发生提交变化，不提供过去任意时间点历史；繁忙账号可能需要等待稳定窗口，不能在恢复未完成时声称成功。最终状态确认之后出现的新合法编辑由下一轮H之后增量处理。

## 4. 持久控制与单一重建者

所有 POST 控制先冻结 `operationId`（随机 UUID）、完整 JCS 正文及目标上下文。operationId 在 `(accountId,syncGeneration,deviceId)` 内唯一；同 ID 不同完整正文为 400 VALIDATION。回执与状态同事务持久化加密，首次提交后七天返回完全相同的首次回执；HTTP 丢响应或杀进程时重发原 ID／正文并查询状态，不新建另一尝试。会话更换但同安装设备可继续；不能伪造旧 refresh proof。

合法首次回执的查找与正文核对 MUST 在当前 generation／attempt CAS、owner 和新操作配额检查之前完成，仍先重新验证账号、会话、原提交设备身份、当前权益、激活及当前生命周期可同步状态，并受固定限流约束。当前空间待核验或尚未完成退休后续费核验时MUST暂停，不因本地权益投影显示active而放行；当前新空间有效时可合法核实旧上下文首次回执。回执保证窗口内的 start 重放因此不能因当前已 rebuilding 而返回冲突，cancel／complete 重放也不能因当前已终结而拒绝；只返回首次回执，不重新执行控制。

此规范中已识别的 control 非 2xx 响应 MUST NOT 创建、接管、取消或发布本次新控制结果，也不能同时落下该操作的成功回执。服务端以一个事务提交控制和首次回执，失败完整回滚；独立的权威权益核验／空间退休事实由免费状态接口报告，不冒充控制成功。4xx 只说明本次调用没有新控制提交，**不证明历史原请求从未成功**，特别是七天回执窗口外。协议没有 403；owner／attempt 冲突按下表 409 固定代码。

客户端保持 transport／timeout／5xx／解析失败／成功但上下文不符的冻结请求为未知，不改 ID 或正文；`402／426／429` 暂停并保留原控制。已验证的 `400／404／409／413／415` 可隔离原控制并刷新当前状态，再依据 generation、manifest、owner 和 attempt 事实决定恢复或提供显式新操作；隔离保留加密原正文和原因，不把拒绝当作未发生证明，更不能自动 claim。恢复后的本机工作进度不只依据原回执推断。

| action | 前置状态与输入 | 原子结果 |
| --- | --- | --- |
| start | rebuildRequired、没有当前 staging；expectedAttemptId=null；完整 manifest | 服务端生成新 attempt UUID，绑定当前 JWT device 为 owner，phase=staging |
| claim | rebuilding；expectedAttemptId 必须是当前 staging UUID；新的完整 manifest | 旧尝试 superseded，新 UUID／owner／独立暂存区；不是复用旧半份数据 |
| cancel | expectedAttemptId 为当前 staging，调用设备是 owner | 该尝试 cancelled；backupState=rebuildRequired，当前 rebuild=null；本机数据保留 |
| complete | expectedAttemptId 是当前 staging，当前 owner，manifestId 与开始时一致 | 验证完整内容／预算／引用后原子发布，phase=published，backupState=ready |

claim 是显式接管／重新开始，不是后台抢占；客户端产品确认细节待评审。相同设备断网或重启恢复同 attempt，不自动 claim。start 与 claim 取得新尝试；取消后 start 也取得新尝试，旧结果和暂存不能混用。

不匹配当前 expectedAttemptId 为 SYNC_REBUILD_ATTEMPT_MISMATCH；当前 attempt 但错误 owner 为 SYNC_REBUILD_OWNER_CHANGED。unknown／跨账号 GET 统一 SYNC_REBUILD_NOT_FOUND。这些 UUID 不授予任何权限。owner 的有效会话被撤销／设备移除立即失去写入和 complete 权限；其他已激活设备可显式 claim，不依据未知网络状态或本机时钟自动偷权。

GET rebuild 返回 `syncGeneration,attemptId,ownerDeviceId,manifestId,phase,recordCount,stagedRecordCount,publishedCursor,startedAt,finishedAt,serverTime`；不返回 payload 或 manifest entries。publishedCursor 仅 published 非 null；terminal 有 finishedAt，staging 没有。响应是当前事实；POST 幂等回执是首次事实，start／claim 回执 recordCount 必须等于请求 manifest 长度且 stagedRecordCount=0。客户端不得把七天内旧回执当作当前状态。

## 5. 完整 manifest、分批暂存和发布

manifest 为 `{manifestId,entries:[{recordId,type,mutationId}]}`。manifestId 是随机 UUID；entries 按 recordId 字典序严格升序，recordId 和 mutationId 各唯一，0..100000 条。允许空快照，也允许没有某种类型；不制造默认 policy、不上传设备设置、下载缓存、Clash API 密钥、Tailscale 身份或未编辑自动选择。显式选定起点设备后，从其可读、合法、符合上传范围的**当前 live 语义内容**确定不可变快照，旧墓碑不宣称能恢复历史删除。

清单只列 IDs／类型，避免生成或明文保存包含秘密 payload 的公开正文摘要作为离线猜测材料。每个清单 mutationId MUST 绑定实际原始 schema1 mutation；同 ID 的内容一旦提交就不可改变。服务端 MUST 独立核对 IDs、类型、精确集合、完整原正文及其上下文，不能信任客户端计数或 digest，也不能以持有这些标识证明权限。

staging push 必须带当前 generation 和 attempt，且当前 owner。每条必须在 manifest 中逐一匹配 recordId／type／mutationId，`baseRevision=0,deleted=false,schemaVersion=1`；没有列出的记录、重复替换 ID 或 tombstone 为 400 VALIDATION。仍限制每批 1..100 条，并按 64MiB 请求预算切分。清单已规定每个recordId唯一，暂存结果只允许applied（没有同recordId的另一LWW正文）；合法原回执同样返回首次applied。暂存采用独立 attempt 范围的 revision，从 1 连续增加；原始真实 editedAt 保留，仍按原规则做未来时间有效裁决，不把全部时间改成 now。

未完成跨批引用可留在加密暂存；任何数据不得向普通 pull 暴露。stagedRecordCount 只统计确已持久提交且属于精确 manifest 的记录。暂存确认不建立普通远端镜像或推进正式 cursor。

complete MUST 在同一原子发布中确认：

1. 权限、当前 generation、owner、attempt、manifestId、权益及设备激活仍匹配。
2. 暂存集合与 manifest **完全相同**，无缺项／额外项／错误类型／未获确认正文；全部 schema1、payload、秘密引用及预算验证成功。
3. 五类的跨记录引用指向本 manifest 的正确类型或规范定义的 implicit `self`／builtin。node／chain 的 memberships、chain hops、selection 的 configuration/member 均核对。file 内容中可判定的 node/group/rule-set 名称、分组环路及选择引用按语义校验；不得静默省略坏记录。正常增量允许的失效引用不等于新完整重建已通过。
4. subscription 只同步元数据，server **不抓取 URL**，不能验证下载缓存里的 nodeKey／动态 groupKey；只验证父 configuration 属于清单且引用格式合法，下载后未解析项按已有本机规则保留为不可用。tailnet 仅保留语义引用，不要求／上传本机 Tailscale 身份；不能伪造它已可用。
5. 无法完整确认时 `409 SYNC_REBUILD_MANIFEST_MISMATCH`，保留可重试暂存和本机内容。不得补默认项、截断、静默删除或发布半份备份。

发布按本 attempt 已提交 revision 顺序建立新代次正式记录，正式 head 为 staged 最大 revision（空快照为 0），正常后续 revision 连续前进。正式内容、空间状态和 complete 首次回执 MUST 原子生效；其他设备在提交前后只能分别看到未发布拒绝或全部已发布内容。

从暂存转为正式内容后，服务端 MUST 继续保证账号、代次、原始尝试及记录上下文的完整性绑定；不得因发布而允许跨范围替换或读取。发布后的正常编辑仍受同等保护；同代次的全量与增量只读取正式集合。

客户端在完整发布确认前只保存加密暂存镜像和进度。重建期间的本机新编辑与固定快照分开保留，发布后再以真实编辑时间和新 mutationId 裁决。其他设备先建立新代次镜像，保留独立本机内容及真实离线编辑，旧镜像不能整份置 dirty 回灌；无法区分的本机材料留作待处理项，不静默删除。

## 6. 七天原结果、旧请求与清理

mutation 原结果的隔离范围是 `(accountId,syncGeneration,rebuildAttemptId,mutationId)`；正常 attempt=null。服务端 MUST 验证完整上下文及时间截断前的原 mutation JCS，拒绝同 ID 异文和跨范围替换。原结果、完整 superseded 记录及控制回执 MUST 与所属账号、代次、适用尝试及原始记录元数据保持完整性绑定。请求内容匹配不能代替有效会话、对象归属或当前授权检查。

每个首次已提交结果从采样 createdAt 起 `[createdAt,createdAt+604800秒)` 保证七天。退休、claim、cancel、配额不足及清理 MUST NOT 提前删除仍在窗口的首次结果或使其无法核验与解密；弃用尝试同样保留。密钥轮换不能中断此保证。保证结果容量不足时拒绝新操作，不删既有承诺结果腾空间。

合法原结果重放仍重新验证当前账号、会话、权益、激活、当前生命周期可同步状态和该结果原提交设备／适用 owner 身份。当前空间待核验或尚未完成退休后续费核验时MUST暂停含payload的原结果和控制回执，不以本地权益投影active放行；当前新空间有效时才允许核实合法旧上下文。对已经提交的原 mutation／operation，先匹配原不可变上下文和正文；在七天窗口内即使该 attempt 已 superseded/cancelled/published，也只返回首次原结果，不作新写入、不夺回 owner、不发布当前尝试。首次结果不表明当前空间仍开放，客户端只用于核实原上下文并另取当前状态。

不存在原结果、窗外、内容不符或未授权的旧 generation／attempt 请求必须拒绝；不能以重放名义写入新空间。窗外仍活动的正常当前代次 mutation 沿用 0.2.0 同 ID 重处理规则；已退休 generation 或 terminal rebuild attempt **不能**因此重新写入。客户端不得换 generation／attempt／正文重发未知旧请求，也不能把已清理当成成功证明。

到期后三个同步接口与控制仍 402，所以最后合法普通原结果通常早于 30 天截止；物理清理仍检查实际保证窗口和钥匙，不以“通常”提前销毁。主动删号立即授权拒绝、在线密钥移除与受控灾备边界按第1.1节；不得让幂等绕过删号撤销。

## 7. 预算与固定错误

延续单 mutation／record 32MiB、同步 JSON decoded 正文 64MiB、push 100／pull 500、深度 64、账号 live payload 256MiB、记录含同代次永久墓碑 100000、七天结果 512MiB／1000000条。manifest 也受 64MiB body，最多 100000 entries。控制 receipt 和其 manifest 的密文计入七天结果预算；暂存及旧未清尝试的 payload 计入账号 payload 预算，替换尝试不能重新获得全额或无界堆积。

账号级限流组 activate／push／pull 仍各60次／UTC固定分钟；新增免费 status+rebuild GET 共用 state 组60次；所有 rebuild POST actions 共用 control 组60次，跨实例共享。attempt、generation、替换设备和重试不重置账号预算／限流。清理只扣确已清掉的计数，不先报空空间成功。

正文读取前的会话、权益及相关操作所需激活资格预检仅用于提前拒绝，MUST NOT 代替提交时对当前授权和对象归属的完整核验。资源繁忙可返回 `429 RATE_LIMITED` 及 `Retry-After`；客户端 MUST 保留原请求及原 mutationId／operationId，按其等待后原样重试，不把限流当作首次请求从未提交的证明。

| HTTP／code | 行为 |
| --- | --- |
| 400 VALIDATION | malformed、同 ID 异文、manifest mutation不符；不自动改正文 |
| 401 AUTH_REQUIRED／SESSION_REVOKED | 保留本机／隔离材料，既有登录／refresh规则不变 |
| 402 NO_ENTITLEMENT | 停止上下行与控制；免费状态继续可读 |
| 404 SYNC_REBUILD_NOT_FOUND | 本账号指定attempt不存在／跨账号，统一失败 |
| 409 DEVICE_LIMIT／SYNC_NOT_ACTIVE／SYNC_QUOTA_EXCEEDED | 既有设备、激活及配额处理，本机内容保留 |
| 409 SYNC_GENERATION_MISMATCH／SYNC_SPACE_RETIRED | 停旧worker，取免费状态；不把 cursor 归零或整镜像上传 |
| 409 SYNC_REBUILD_REQUIRED／SYNC_REBUILD_IN_PROGRESS | 普通同步暂停，显式重建或等待正式发布 |
| 409 SYNC_REBUILD_ATTEMPT_MISMATCH／SYNC_REBUILD_OWNER_CHANGED | 不写旧attempt、不自动claim；隔离迟到响应 |
| 409 SYNC_REBUILD_MANIFEST_MISMATCH | 不发布，保留暂存并报告完整性／引用失败 |
| 413／415 VALIDATION | 预算／格式，不能截断内容 |
| 426 SCHEMA_UNSUPPORTED | 停止并提示升级，禁止降级为协议1 |
| 429 RATE_LIMITED | 整数秒 Retry-After≥1 |
| 500 INTERNAL_ERROR | 脱敏，未知请求保留原 ID／正文 |
| 503 INTERNAL_ERROR／SYNC_ENTITLEMENT_UNVERIFIED | 必须 Retry-After:30；不先接受写入、退休或毁钥 |

错误仅用于新同步操作，首批 CloudError/ErrorCode 不增加枚举。消息脱敏且客户端不按 message 分支；不附 current payload、钥匙、URL、SQL或原请求正文。状态与数据只给已验证本账号会话。

## 8. 发布兼容、迁移和恢复边界

必要性：0.2.0的到期长期保留、永久墓碑、账号内连续cursor与新目标不可兼容；单方删除数据或revision归零会复活旧请求或错过记录。服务端托管加密与有限受控灾备保留不提供旧备份密码学销毁保证，故按第1.1节明确修改保证，而不是声称旧保证仍成立。本草案用新版本和显式政策迁移隔离，不能当作0.2.0补丁。

正式发布须经双方评审与验证，按新版本更新唯一现行 OpenAPI／规范并新增对应不可变归档与SHA；0.1.1／0.2.0归档及其SHA不变。候选正文由 `candidates.lock.json` 单独锁定并核对双端一致；必要修改须说明原因、兼容与迁移影响，完成双端验证并显式更新候选摘要，不能用候选锁代替正式发布或验收。首七账号可达schema保持完全相同，账号状态不加字段。已迁移账号一律要求协议2，协议1请求426；未迁移账号只能继续旧承诺，不能一边允许协议1一边执行新退休。客户端不能自动降级。

历史空间转换 MUST 原子且无损：仅分配一次UUID并标记spaceOrigin=legacy，保留原recordId/type/revision、墓碑、最高head、有效editedAt、七天首次结果及真实购买expiresAt，不能以删除重建替代。旧首次结果仍须按时间截断前的原mutation JCS核验；v2新增外层generation／header不视为原mutation正文变化。原结果仅归入已确认legacy generation/attempt=null范围，并保留原范围内的完整性与可核验性，不复用退休generation。

仅当客户端旧schema材料没有已知generation，且服务端已明确返回同account的spaceOrigin=legacy时，才允许为旧cursor/maps及冻结原mutation附加这个迁移范围；原envelope、mutationId和editedAt不变，未知请求重放仍返回原applied／完整superseded结果，不能作为新处理。该例外只用于首次无损部署迁移，不适用于明确旧generation变化、origin=rebuilt、退休后空间或另一账号。不满足证明就阻断并保留未知材料，不能假claim兼容。门槛切换期间必须保留原七天结果及其可核验性；历史到期账号先通知并设一次性过渡截止，日期待上线计划，不改购买expiresAt。

客户端 v3 迁移保留账号归属、canonical内容、真实 editedAt、加密 pending/in-flight及来源限制；旧代次未知时待服务器确认，不自行赋generation=1。不使用 detachAccount、清 cursor 或 bootstrap 整份回灌来代替退休隔离。新增秘密引用须纳入 deleteIfUnowned／deleteOrphans 所有权；本机schema迁移不把解密内容落盘。

代次变更，即使 account/session 不变，也使旧worker失效。所有落库事务重查 account/session/worker epoch/generation/attempt及模式；旧pull、superseded、ack、控制回执不得覆盖新镜像或清新dirty。

本机主钥恢复与云端加密保护独立，云端密钥不下发客户端。一次钥匙读取／条目认证失败不换钥、不造空payload／墓碑；明确永久失钥后独立重新认证并核对accountUUID，保留其他账号坏材料，按当前代次及第3节稳定head窗口规则隔离下载和加密暂存。不承诺找回未上传编辑、设备秘密、订阅缓存或历史版本。文件备份密码仍独立。

## 9. 必须通过的验收与发布前待办

- 到期E和保留截止精确边界；截止前有效续费、通知迟到、核验失败、续费／清理并发竞争，无误删和旧任务毁新钥。
- 账号同会话跨generation迟到响应；旧高cursor／旧mutation正文不换代次；旧协议426，首七wire完全不变。
- start/claim/cancel/complete响应丢失与杀进程；原operationId回执持久；单owner CAS；旧owner可合法重放首次结果但不能写／发布新尝试。
- 空快照、五类完整清单、跨批引用、缺项／额外项／错type／同ID异文、subscription不可判定节点及tailnet未配置边界；不发布半份备份。
- claim/cancel/retire后七天结果、原始上下文的完整性与可核验性；配额不足拒绝新操作、不提前删除原结果；无旧请求复活。
- 发布原子可见和丢响应恢复、重建中真实编辑、其他设备旧镜像不回灌；全部本机资料／来源限制保留。
- v3升级保留冻结双槽与真实时间；多账号钥匙失效不互相清资料；有旧密文读null不换钥。

- 跨账号、代次及尝试隔离；缺钥与完整性失败拒绝；单账号清理不影响其他账号；拒绝协议1，不擅自改变既有账号保证。
- 新客户端完整识别deleted，未知枚举拒绝；首七操作及可达wire不变。
- 原始UTC30天期限与全部受控副本到期清除；在线deleted与灾备保留期内仍可解密的边界准确，不误标密码学销毁。
- 恢复后继续拒绝已删账号及旧凭据，保持退休空间关闭；另一账号仍有效内容可恢复。

已确认：固定UTC30天、服务端统一加密和普通受控灾备保留政策。正式发布前仍须完成历史通知／过渡日、重建交互与清理文案、客户端兼容、恢复隔离、真实购买核验及公开政策说明；本草案不增加删除回执。候选摘要校验不替代双端、适用真机及安全验收。
