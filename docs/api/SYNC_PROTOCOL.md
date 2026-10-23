# Avalon 同步协议 1（OpenAPI 0.2.0）

状态：2026-10-12 按用户授权完成设计冻结（D96），**三个同步接口和客户端 SyncEngine 尚未实现或验收**。七个账号接口沿用 0.1.1 wire 定义；D96 的单会话登录替换行为仍需服务端适配。本文件由唯一公开 [OpenAPI](cloud.openapi.yaml) 引用，是其规范性组成部分。MUST／必须、MUST NOT／不得均为实施和验收要求，不是建议。

## 1. 权威、版本与变更

- 唯一可编辑源为客户端 `docs/api/cloud.openapi.yaml` 及本文件。服务端 `docs/api/` 是逐字节副本，不能自行修订。客户端、服务端各自的实施设计解释接线，不重新定义 wire。
- `releases/<version>/` 是不可覆盖的发布设计归档；`contract.lock.json` 记录当前版本和所有归档 SHA-256。当前文件必须逐字节等于当前归档。不得用重新计算旧摘要的方式掩盖修改。
- 文档版本 `0.2.0`、同步语义版本 `1`、payload `schemaVersion=1` 与两端数据库版本是四个不同概念。三个同步请求 MUST 携带 `Avalon-Sync-Version: 1`；成功响应 MUST 携带同值。缺失或未知请求版本返回 `426 SCHEMA_UNSUPPORTED`；客户端拒绝应用缺失／未知响应版本。
- 必要变更先记录具体原因、旧客户端影响、迁移／回滚和双端验证，涉及产品行为须用户确认并先记 DECISIONS。随后发布新文档版本、必要时新同步／payload 版本；保留旧归档和其 SHA，不原地改旧版本。破坏性版本不得仅靠字段默认值、忽略字段或降低功能兼容。
- 上线版本必须同时支持已承诺的旧同步版本与它七天内的幂等结果；撤下旧版本须另行确认迁移与支持期限，不能用部署顺序迫使客户端丢数据。未知版本停止同步，保留本地内容、dirty 与 cursor，不影响代理。
- 验证：`python3 tool/check_cloud_contract.py --server-root ../avalon-cloud`。校验摘要与相同副本只能防协作漂移；有仓库写权限的人可修改文件和锁，因此还必须审阅 diff 与历史。它不证明客户端身份，也不替代服务端授权。

## 2. 信任边界与通用 HTTP

公开客户端是不可信输入方。嵌入 API key、客户端源码秘密、包名、User-Agent、文件 SHA 和 installationId 均不得授予权限。原生应用静态共享秘密不能作为保密身份依据，见 [RFC 8252 §8.5](https://www.rfc-editor.org/rfc/rfc8252.html#section-8.5)。

生产 MUST HTTPS／TLS 1.2+、正常证书验证、HSTS；不提供跳过证书校验。只有显式开发预览允许 loopback HTTP／USB reverse；不能自动退回 HTTP 或其他 origin。Bearer 和同步正文不跟随 Cloud API 重定向。

成功直接 camelCase JSON；错误 `{"error":{"code":"…","message":"…"}}`，按 code 分支，不解析 message。所有同步响应含 `Cache-Control: no-store`；禁止代理／CDN缓存、请求响应正文日志、数据库参数日志、秘密 metrics 标签及 trace 载荷。message 脱敏且不含 URL、邮箱、节点密码、SQL 或 stack。公开契约可描述字段和安全规则，服务端密钥、私有部署地址和内网结构不得写入。

JSON MUST UTF-8、唯一大小写准确字段、拒绝重复键／尾随 JSON／无效 Unicode、非有限数与超出字段范围的数。对象除 `SyncHeaders`、`SyncSecrets` 明示 map 外拒绝未知字段；nullable 必须显式 null，其他字段不得 null。未知记录 type 或 schemaVersion 是 `426`；已知类型下错误字段／缺字段／类型不匹配是 `400 VALIDATION`。全批先查版本和结构，不能跳过坏记录继续成功。同步成功输出使用紧凑JCS编码；不得因HTML／Unicode额外转义使试算预算和实际正文不一致，尤其最大记录仍必须能完整装入单页。

push 仅 `application/json`，请求 Content-Encoding 仅 identity（省略视为 identity），其他为 `415 VALIDATION`。响应可 identity 或 gzip，客户端按**解压后**正文预算限制流式读取，超限立即终止并保留原 mutation。拒绝 gzip 爆弹，不能仅信 Content-Length。activate／pull 不接受正文；activate 不接受 query，push 不接受 query；pull 仅 cursor／limit，拒绝重复键、未知键、空值和非规范整数（`0` 或无前导零十进制数字）。

## 3. 授权、单会话与激活

每个 activate、每条 mutation 的事务、每页 pull MUST 从已验证 JWT 得到 accountId／deviceId／sessionId，不接受正文/query里的账号、设备、权益、授权或 revision 分配声明。取得账号行锁后**重新**检查账号存在且未删除、会话未撤销且未到期、设备属该账号且未移除；时间比较使用完整当前时间，达到到期时刻即失效。权限与读写在同一事务，不只信入口中间件。所有 SQL、缓存、幂等键、密钥查找都带账号作用域。跨账号 recordId 不查询其他账号，即使碰巧相同也无影响。对应风险见 [OWASP 对象级授权](https://api-security.owasp.org/editions/2023/en/0xa1-broken-object-level-authorization/)。

客户端只有一个活动账号／会话，换账号先完成本地退出并加密排队原会话撤销，再允许新登录；旧队列只以 proof 撤销旧会话，不携新账号 Bearer。服务端保证 `(accountId, installationId)` 仅一个有效会话：再次登录同账号同安装，在创建新会话的同一事务撤销旧会话，保留该设备已有激活。此替换不是普通 logout。不得凭可伪造的 installationId 撤销其他账号或声称已经证明真实物理设备。全局硬件绑定不在协议 1 范围。

付费资格必须 `entitlement.status=active`、`expiresAt>now` 且 plan／source 为当前已知支持值；客户端开关或非 null 权益都不能证明资格。无资格三个同步接口均 `402 NO_ENTITLEMENT`。到期保留激活、内容和密钥，但每次 push/pull 立即拒绝；续费后原设备可恢复。免费登录、账号查询、退出和全部本地功能不受此限制。

`POST /v1/sync/activate` 无请求正文，设备取自 JWT。账号锁内清理不再有有效会话的旧占位，检查权益，再对已激活设备幂等返回 200；新设备只有当前激活计数小于10才设为激活。达到10时 `409 DEVICE_LIMIT`、不改变任何激活；设备列表沿用 account GET，不在错误中复制另一种 DTO。响应为 `{deviceId,syncActive:true,deviceLimit:10,syncActiveDeviceCount,serverTime}`。

登录不占名额。普通退出／撤销后，只有该设备不再存在有效会话时才释放激活；移除撤销其全部会话并释放，最后会话自然到期也释放。已被新登录替换的旧proof迟到撤销仅作用于旧会话，不能释放新会话沿用的激活；90天没有有效会话的设备不得继续占位。现存历史多会话需迁移成单会话：保留最新创建的有效会话，相同时间用 sessionId 固定排序，撤销其余，不跨账号处理。active 标记是设备级，不能因同设备新登录替换而释放。push/pull 有有效权益但当前未激活时 `409 SYNC_NOT_ACTIVE`，不得误报 NO_ENTITLEMENT、直接继续或绕过 activate。

## 4. 标识与完整 payload

OpenAPI 的所有 `Sync*` schemas 是字段、必填、nullable、枚举和基础上限权威。本节补充机器 schema 无法表达的关联约束。不能直接用 Dart generated `toJson/fromJson` 或 Go数据库行替代此 DTO；以后内部重构不改变 wire。

| type | recordId | payload |
| --- | --- | --- |
| configuration | 小写 UUID | subscription：name／autoUpdate／createdAt／source{url,headers}，不含下载内容；file：name／autoUpdate=false／createdAt／format／content{model,secrets}，不含 source |
| node | 小写 UUID | name／server／port／params／secrets／createdAt／memberships；protocol 仅在 params.protocol，不重复顶层 |
| chain | 小写 UUID | name（可 null）／hops／createdAt／memberships |
| policy | `policy` | jsonOverride（可 null）／geo{autoUpdate,interval,via}，只上传用户编辑过的值 |
| selection | `sel:<configurationId>:<hash>` | configurationId／groupKey／member，只上传手动选择 |

UUID 都是标准36字符小写带横线格式，创建使用随机 UUID。selection hash 为 groupKey **原字符串 UTF-8** 的 SHA-256 → base64url（无 `=`）→ 前22字符，不做大小写／Unicode／URL归一化；其 ID 必须与 payload 重新计算一致。`self` 仅为内置配置引用，不创建 configuration 云记录。recordId 的 type 首次创建后不可变，即使已是墓碑；更改 type 为400。

账号是这些 ID 的命名空间，包括固定 policy 和 selection。客户端不得把 remoteId 直接当作跨账号全局本地主键；必须用 `(accountId,recordId)` 映射隔离，不得按同名／同 UUID 绑定另一账号实体。references 必须保持同账号解释，不能让本机另一账号的同 ID 恰好补齐引用。

createdAt／editedAt 是 Unix UTC 毫秒整数，非 RFC3339 字符串；serverTime 是既有 UTC RFC3339 Z 时间。revision／cursor 是 JSON安全整数（0..2^53−1），正记录 revision>=1；达到上界停止写入，不能绕回。字符串长度按 Unicode scalar 数，JSON字节按 UTF-8；不能分别用 Dart UTF-16 length 与 Go bytes 作不等价限制。所有数字必须是相应整数字段允许值。

params 严格为九个协议分支，TLS／transport 字段显式完整。秘密字段只能 `{"$secretRef":"sN"}`；secrets 必须恰好覆盖整个 node 或 file.model 使用的引用，不能多带秘密、缺秘密、夹 `$secret`、本机 secretId／nonce／密钥。接收端 join 后校验并重新加密。用户名、完整 URL、headers、JSON override 也按秘密处理，即使某些字段不走 `$secretRef`，整个远端镜像不得明文落库。

file.model 固定 nodes／groups／rules／ruleSets／finalTarget／defaultRules；不传 warnings／usage／下载时间或原始文件。节点与组 key 唯一（互不冲突）；组类型和 displayType 一致；URLTest 有 test、Selector test=null。模型内部的成员、target、detour、ruleSet 引用与环路必须校验，不得为通过校验静默丢弃。已知协议的实际内核不可用参数按原产品规则保留并显示不可用，不能回退 direct。无关节点不能因此让客户端丢弃整份合法结构。

membership 是 configurationId／groupKey 的唯一集合；内置 `self/custom` 关系由客户端推导，不制造重复 membership。chain hops 2..64，身份不能重复，类型只能 source节点／selfNode／tailnetExit，不允许组、chain 或 builtin；目标尚未到达则保留不可用，不能按名称补齐。tailnet只同步稳定引用，不上传身份、令牌或控制权限；其可用性仍由本机 Tailnet 账号核对。

配置、成员、selection 的跨记录引用可能跨 pull 页到达或被远端删除，必须先持久保存受保护的完整记录和未解析引用，不能因外键拒绝丢引用后推进 cursor。服务端只验证结构与同账号语义，不要求目标已存在，不下载来源、不编译 sing-box。

## 5. 上传、时间裁决与事务

请求 `{mutations:[{mutationId,recordId,type,baseRevision,editedAt,deleted,schemaVersion,payload}]}`。一个批次 mutationId 和 recordId 各自唯一；本地对同记录多次编辑合并成当前编辑，但**已经发出且结果未知**的 mutation 保持原正文／ID冻结，不能复用 ID 改内容。baseRevision 是该客户端已见 revision，新记录为0，不得大于账号已提交最大值；它不赋予覆盖权。

完整批次结构／版本／数量／字节、ID、秘密引用与 payload 约束先检查；这一步失败不产生该请求的新同步记录或幂等结果。随后按请求顺序，每 mutation 一事务；整批不是一个大事务。每事务按 §3 重新授权，在同一账号锁下处理：

1. 查 `(accountId,mutationId)` 未过期幂等结果，若原请求不同则400，若相同返回原结果，不重读最新记录、不重新截断时间。
2. 新 mutation 的有效编辑时间为 `min(request.editedAt,floor(serverNow UTC ms))`。不存在记录则接受；存在记录**只有严格更大**才接受。相等保留先提交者，较旧／相同时间删除也不能覆盖，墓碑只被严格更晚的编辑复活。
3. applied 在账号锁下分配 `account.sync_revision+1`、更新记录／墓碑，保存完整原结果；superseded 不增加 revision，保存此刻完整胜出记录。AES加密、记录、revision、原结果、配额计数同事务，失败全部回滚。
4. 试算实际结果和完整 HTTP envelope 的响应字节。下一条装不进64MiB时，不提交该条，立即返回已提交连续前缀。至少一条必须能装下；最大记录32MiB保证这一点。

200 返回 `{results,processedCount,hasMore,serverTime}`；results 是按输入顺序的连续前缀，`processedCount=results.length>=1`、`hasMore=(processedCount<mutations.length)`。applied 为 `{mutationId,status:"applied",revision,editedAt}`，editedAt 是有效时间；superseded 为 `{mutationId,status:"superseded",record}`，record 包括完整胜出 payload 或墓碑。未处理尾部保持原 ID 续传。不能用同一个200暗示尾部已提交。

后续事务认证／依赖／配额失败可能使此前前缀已经提交而 HTTP 返回错误或丢失；客户端将整个原批次视为结果未知，用原 mutationId／原正文重试，依靠原结果去重。401等需要先恢复合法会话；禁止为了重试产生新 ID。事务超时／服务重启／网络断开不能变成整批成功或整批未提交的假设。

所有分配 revision 的账号锁必须保持到**提交完成**。不得仅用 PostgreSQL sequence／预分配范围：若rev1未提交而rev2先被pull看到，cursor=2会永久跳过rev1。撤销、refresh重放、设备移除、删号、激活和同步用同账号锁形成明确先后；锁等待后重新检查期限。独立账号仍可并行。

## 6. 七天原结果幂等

首次原结果的 `createdAt` 定义为该事务取得账号锁、完成结果加密后、即将插入原结果时采样的服务端UTC时间（生产可用数据库 `clock_timestamp()`）；仅提交成功后该时间和窗口生效，不是请求到达／事务开始时间，也不要求获取不可观测的精确物理COMMIT时刻。保证窗口 `[createdAt,createdAt+604800秒)`；精确到第七天不再保证原结果，即使清理尚未执行。到期可把同 ID 视作新处理；客户端不得承诺永久 exactly-once。仍有本地原 mutation 时重发同 ID，不擅改正文；服务端永久墓碑／时间裁决继续保护记录。

比较的是**时间截断前**完整 mutation JSON，按 [RFC8785 JCS](https://www.rfc-editor.org/rfc/rfc8785.html) 规范化；字段顺序不重要，array顺序、字符串内容及 null重要，不额外归一化字符串。JSON输入满足该规范的 Unicode／数值前提。服务端用账号用途隔离的 HMAC-SHA256 得到私有请求指纹，记录所用key版本；轮换后在承诺窗口内用原key版本比较，不能以新key重算而误报正文变更；客户端不发送／验证该指纹来鉴权，不能用普通秘密哈希留给离线猜测。

同 ID／不同内容为 `400 VALIDATION`，不覆盖原结果，不处理该 mutation。重放时重新核验当前账号／会话／权益／激活；幂等不能绕过已撤销权限。返回首次 applied 的 revision／editedAt，或首次 superseded 的**完整当时记录**，即使当前记录已再变化。结果整份加密（含 superseded 密码），不能存明文 result_json，也不能只存 recordId后读取最新内容。

## 7. 下载与 cursor

`GET /v1/sync/pull?cursor=0&limit=500`。cursor必填，limit可省略默认500，范围1..500。账号锁内重新授权和资格校验，在一致读取快照中按 `revision>cursor` 严格升序读取**每条当前最新记录**，同时受字节预算限制；cursor超过该账号已提交最大revision为400，不退回0或静默跳过。

200 `{records,nextCursor,hasMore,serverTime}`。非空 nextCursor 是最后一条返回的 revision，不是账号最高值；空页 nextCursor等于请求cursor，hasMore=false。只要同一快照还有满足条件且未返回的记录，hasMore=true；有数据时不能返回不前进的空页。不能按500×32MiB一次加载全部密文后再截断；使用wire-size元数据预算与有界读取。

不设全量快照水位；翻页期间同一记录更新到更高revision可以后页重现，客户端按账号／recordId／revision幂等。服务器存的是当前记录，不是完整历史事件流。永久墓碑参与 cursor=0 和增量，不能因保留期或权益到期被清理。删除 payload 必须显式null，并保持 type、ID、revision、editedAt、editedByDeviceId。

客户端先验证成功header、整页结构／版本／顺序／字节／nextCursor，再在一个本地事务中持久化远端镜像、重加密秘密、更新可投影内容和cursor。任一记录不支持或校验失败，整页不应用、不推进cursor，停止并报告真实错误。跨页未解析引用存加密镜像不代表跳过数据。多页最后仍可有新编辑，下一轮继续增量。

## 8. 客户端合并和失败收敛

一个串行 worker：activate → pull到末页 → push当前dirty。本地用户编辑的内容、加密秘密、引用、归属、dirty、editedAt和随机mutationId同事务。订阅后台刷新／测速／自动选择／默认policy不得制造 mutation。本地commit后2秒防抖；启动、回前台、前台5分钟和手动触发，离线保留数据并有界退避。

网络响应应用必须再次匹配当前 `accountId/sessionId/本地登录代次`；退出／换账号后旧回包不能写新账号cursor、绑定内容、清dirty或激活显示。账号资料更新不能覆盖令牌／刷新guard。获取access的刷新仍遵循0.1.1单次合并轮换规则，不能重放旧refresh。

pull时本地dirty且其editedAt严格较新可保留本地内容，推进已见remoteRevision；否则应用远端winner。push已知原结果另有规则：若该记录当前mutationId仍是所发ID，applied回写revision和**有效editedAt**并清dirty；superseded必须应用该原winner并清dirty，不能因本地未来时间仍大而循环重新上传。若期间产生新ID，更新已见remoteRevision但不得清新dirty／覆盖新编辑。旧原結果 revision不能降低当前已见revision，已应用更高远端镜像时不能用旧winner倒退内容。

首次同步先完整pull，再对**未绑定其他账号**的本地订阅做原URL字符串完全相同合并，采用云端ID；本地实体映射、外键、chain／membership／selection 的JSON引用同事务改写。不得按hostname、忽略token或名称合并。其余未绑定本机内容才能绑定当前账号；引用依赖其他账号的实体不得改绑、上传或按碰巧相同 ID 解析，保留本地并报告绑定问题。对同URL但不同headers的首次合并采用云端完整来源，不拼接本地凭据。若同一exact URL两端各有多个记录，则各端按自己的小写recordId／localId字典序排序，一对一配对到较少的一侧为止；不得多对一合并或删除多余记录，未配对的本地项按正常未绑定内容处理。

退出保留本机内容、代理凭据、各账号加密镜像及dirty；切到B不得上传／覆盖A的canonical记录。全局policy／selection需要账号快照和当前投影，不能用一行固定ID表达两账号的所有权。没有B规则时不把当前A规则自动上传B。账户删除只解除其本地绑定并保留内容，远端删除不是本地引用拒删动作。

远端新订阅／source变更在同事务清空旧下载内容，再按来源策略重新下载，不能以旧节点假装新来源已成功。远端删除保留失效chain／selection引用显示不可用；删除当前运行配置清除本地选中，已启动旧会话继续到停止／切换。规则或选择的运行生效仍按D10／D12，失败报告发生处，不能换节点／direct。

## 9. 固定预算与错误

MiB=1024²。以下初始工程预算属于本版本规范，不能在一端改数字。HTTP层可以增加并发／超时／IP保护，但不得宣称超限请求已经成功。

| 范围 | 上限／规则 |
| --- | --- |
| 一个 mutation 或 pull record | JCS紧凑UTF-8整个envelope≤32MiB |
| push请求／push响应／pull响应 | 实际decoded UTF-8正文≤64MiB（含envelope、array符号） |
| push条数／pull条数 | 1..100／0..500；同时按字节拆批／分页 |
| JSON深度 | root深度1，最高64；policy字符串里的JSON另按64校验 |
| 账号live payload | 每账号非删除payload的JCS字节总计≤256MiB |
| 账号记录数 | 含永久墓碑≤100000，新ID会增加；删除／复活旧ID不增加 |
| 七天原结果 | 每账号密文与envelope总计≤512MiB且≤1000000条 |
| 限流 | 每账号activate、push、pull各60次／UTC固定分钟，跨实例共享，重试也计次 |

account锁中原子计数／替换差值，先验限额再提交；缓存容量不足不能提前删除承诺期原结果，新mutation `409 SYNC_QUOTA_EXCEEDED`，已存在合法重放仍可返回。墓碑只清payload，不清记录。最晚到期后可清幂等结果，普通活跃payload配额不会因权益到期删除内容。合法本地file可能超出Cloud限额，必须明确报告、保留本地而不上传；不得缩减规则、节点或秘密。限制批次操作、分页、文件和内存用于控制资源消耗，参见 [OWASP API4](https://api-security.owasp.org/editions/2023/en/0xa4-unrestricted-resource-consumption/)。

| HTTP/code | 两端行为 |
| --- | --- |
| 400 VALIDATION | 固定输入／幂等冲突，报告不自动改正文重试 |
| 401 AUTH_REQUIRED／SESSION_REVOKED | 遵循既有刷新／重新登录，保留本地与dirty |
| 402 NO_ENTITLEMENT | 暂停上下行，保留内容与激活 |
| 409 DEVICE_LIMIT | 拒绝新激活，用户可沿原设备页移除设备 |
| 409 SYNC_NOT_ACTIVE | 合法账户需先activate，不能绕过资格 |
| 409 SYNC_QUOTA_EXCEEDED | 保留dirty，报告配额，不截断数据或删除幂等结果 |
| 413／415 VALIDATION | 超大小／不支持编码或MIME；报告固定边界 |
| 426 SCHEMA_UNSUPPORTED | 停止同步、提示更新、不推进cursor |
| 429 RATE_LIMITED | 必带整数秒Retry-After（窗口剩余，向上取整至少1） |
| 500／503 INTERNAL_ERROR | 脱敏；未知批次用原ID重试，503带Retry-After:30 |

这些新同步错误仅在新操作的 `SyncCloudError` 中定义，不扩改0.1.1既有账号ErrorCode。现有五种阻塞原因继续表示离线／设备上限／权益过期／需要更新／认证过期；配额和校验在当前同步动作报告，不伪装成成功。实际响应与大小校验不信客户端申报计数。请勿把旧账号接口64KiB限制全局放宽来接入同步。

## 10. 云端来源与本机访问

即使来自已认证同账号，云端payload也不得获得本机直接输入的信任权限。持久provenance标记为 cloud；首次同URL合并、自动刷新、App重启、后台Android服务、providers、规则集和JSONoverride的后续连接均保持此限制，不能只在第一下载传一个临时false。

云端subscription／规则资源仅http或https的合法URL，禁止userinfo、fragment、file/data/custom scheme、设备路径和绕过解析的URL。每次DNS解析、实际连接IP及每个重定向都执行公共地址策略：拒绝loopback、private、link-local、unspecified、multicast、保留地址和云metadata；IPv4-mapped IPv6按IPv4同样判断，防DNS rebinding。来源URL内的token保留为秘密。协议不授权访问这些URL；服务端**从不抓取**它们。该策略也覆盖远端file的URLTest `test.url`、override DNS URL及所有远端定义引起的自动资源／探测／代理端点连接；不得遗漏由core主动拨号的地址。它只约束这些来源引起的连接，不改写用户正常TUN流量或路由的地址匹配值。

headers名称须HTTP token、最长256、大小写不重复；值无CR/LF/NUL。允许 Authorization、Cookie、User-Agent、Accept、Accept-Language、Referer、Origin及`X-*`自定义头（禁止X-Forwarded-*与X-Real-IP）；禁止Host、Connection、Proxy-*、Content-Length、Transfer-Encoding、Upgrade、TE、Trailer、Keep-Alive及自动管理Accept-Encoding。未知头不丢弃，校验报错并保留本地。所有来源自带头在跨scheme/host/port的redirect中移除，Cloud Bearer绝不作订阅凭据。

JSONoverride只能用 CONFIG_PIPELINE §5已登记键，必须验证嵌套结构、未知字段和危险文件／命令／控制器／日志／证书路径；不能把远端 `path`、执行命令、tun、入站、控制端口交给宿主。允许的业务路由matcher `processPath` 是匹配值，不是文件读取授权。远端override／file规则资源在计划前必须通过受控下载生成本机可信缓存路径；缺缓存报真实原因，**禁止让core remote rule_set或任意出站remote功能绕过地址检查**。用代理下载也需最终IP/redirect策略；如果宿主无法保证就拒绝该资源，不能假称已有Dart Fetcher已覆盖core。

## 11. 加密、销毁与生产门槛

沿用D02：普通账号HTTPS同步，授权服务端可以读取，**不是端到端加密**。每账号独立随机256位DEK，AES-256-GCM；每次加密独立随机nonce，固定版本密文envelope。记录AAD绑定accountId、用途、recordId、type、schemaVersion、revision、editedAt、editedByDeviceId及deleted；墓碑清除旧秘密但存储认证的null／空内容密文envelope，使其同步metadata也可验证；wire payload仍显式null。幂等结果独立用途绑定accountId、mutationId和结果格式。目的和边界字段由服务端计算，不能使用客户端声明的AAD。交换账号／记录／用途／revision或改密文必须验证失败，不能返回空payload。

repository/sqlc只接收密文，不出现payload／原结果的明文副本；账号索引与revision等最少metadata可明文。客户端所有接收镜像／待解析完整payload入加密秘密表，主密钥仅OS安全存储；本地public投影仍遵守DATA_MODEL，不上传本机钥匙或明文SQLite文件。HTTP过程中明文只在受控内存，禁止临时body文件和排队明文。

服务端必须具有独立账号key provider；不能复用JWT签名key、challenge用途key或所有账号一个共享DEK。测试provider只能在隔离测试；持久本机provider仅显式sandbox，密钥不随业务备份。生产无合格KMS/provider、不可验证账号销毁机制或密钥不可用时fail closed，不接受未加密写入、不推进revision、不以测试密钥开放。

删除账号首先以事务停止授权、撤销会话并登记所有key版本销毁，独立任务执行；旧业务备份中wrapped DEK不能仍被共享KMS解包。销毁事实必须在恢复域外维护，恢复业务库前重应用，删除不可因还原数据库而复活。仅删在线wrapped DEK或可取消的scheduled deletion不证明不可恢复。生产KMS、最终不可逆时限、删除回执及运维备份能力另需选择验收，不改变现有DELETE wire成功含义，也不宣称当前在线删除完成这些保证。

## 12. 实施与验收边界

客户端接线和最少迁移见 [client-sync-implementation.md](client-sync-implementation.md)，服务端见私有仓库 `docs/sync-implementation.md`。公开schema只约束wire，不暴露SQL／KMS私有实现。新设计的校验通过不等于三endpoint已可用。

开放开发预览之前必须用专用PostgreSQL库验证账号A/B隔离、并发首次记录／第11台、精确期限、同步对撤销／删号竞争、相等／旧编辑／未来截断／墓碑复活、同ID不同内容、七天截止、响应前缀续传及丢包、分页期间更新／commit顺序、未知schema整页／整批拒绝、配额与压缩预算。加密验证tamper／跨用途移用／无明文落库及KMS不可用回滚。

客户端双隔离实例验证换账号固定policy与相同ID不串用、未解析引用跨页、dirty请求期间新编辑、未来时间superseded收敛、同URL合并及凭据不拼接、离线未知重试、迟到旧账号响应、cloud URL/private IP/redirect/provider/override/core下载闭环。属性测试针对合并收敛和随机断网编辑，不写字段getter或mock复刻实现的测试。

生产另需真实KMS、删除前备份无法解密被删账号且其他账号仍可恢复、公网TLS与运维验证；真机开发测试不能替代它们。实现／测试／平台产物各自按 IMPLEMENTATION_PLAN 记证据，不能因本文件被冻结把C2标完成。
