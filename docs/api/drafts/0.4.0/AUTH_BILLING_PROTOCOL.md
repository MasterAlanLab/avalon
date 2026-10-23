# 第三方认证与订阅协议 0.4.0（开发草案）

本文件与同目录OpenAPI共同定义新增wire。用户于2026-10-15授权按已确认产品规则实现服务端；版本号0.4.0用于独立评审候选，未发布、未冻结，保留canonical 0.2.0、原SHA锁和release，0.3.0既有wire保持不变。首七账号wire、六个同步操作与同步版本头2保持不变；同步语义沿用0.3.0候选。必要候选修改须说明原因、兼容与迁移影响，经双端验证后显式更新 candidates.lock.json；候选锁不等于正式发布或验收。客户端SDK、商店环境和真实支付尚需配套验收。

## 认证

- profile是服务端注册的provider、native/web、OS和OAuth client映射；请求不能指定issuer、JWKS、任意redirect或替换完成阶段的设备资料。Apple和Google相同邮箱不自动合并。
- native start返回challengeId、challengeSecret、nonce、5分钟UTC绝对期限。把nonce原文传选定SDK，完成以`X-Avalon-Login-Secret`携带秘密。Apple需identityToken和authorizationCode，Google需identityToken。签名、固定issuer、audience、exp/iat、nonce、subject及配置的Google azp均校验。
- web start返回sessionId、authorizationUrl、pollingSecret、displayCode、expiresAt和intervalSeconds。只把authorizationUrl交系统浏览器；pollingSecret只存在发起客户端。launch URL携带独立一次性秘密，绑定`__Host-avalon-auth-{sessionId}`安全cookie。原绑定浏览器可重开；不能覆盖绑定。
- launch先显示设备名和配对短码，用户核对后以表单`POST /v1/auth/web/launch/{sessionId}/continue`提交唯一字段confirmationToken（43位base64url）。服务端同时验证原cookie及页面CSRF证明，才303进入固定provider；重复确认不重置state／nonce。状态改变或过期后拒绝，不能由GET自动替用户确认。
- Google浏览器流程使用S256 PKCE、state与nonce；Apple采用confidential code flow和form_post，专用cookie为Secure/HttpOnly/Path=/、SameSite=None。回调页不含Avalon令牌，显示核对码；发起端核对displayCode后明确确认，再claim。
- attempt状态为pending、launched、exchanging、ready、issued、delivered，或failed、expired、restartRequired、superseded。poll只返回状态与期限，不返回令牌。未知ID和错误秘密不能用于判断他人登录状态。
- 第一次native complete或web claim在账号事务中创建会话并加密保存原TokenResponse。未ACK且未到原attempt绝对期限时可恢复原结果（native自start起固定5分钟，web自start起固定10分钟；重试不延长）。ACK、第一次成功refresh、logout、移除设备、替换会话和删号关闭回执；不会用旧attempt恢复已轮换refresh。客户端先原子落盘再ACK，换账号或登录代次后丢弃迟到结果。
- 较旧attempt不能替换该账号同安装较新已接受attempt的会话。删号前的挑战不能直接创建新账号；重新授权从新挑战开始。恢复旧资料后全部旧attempt和会话必须失效。
- Apple换码后的可撤销凭据单独加密保存；删号先持久化撤销任务。最多12次自动尝试后进入manualRequired，旧任务确认解决前不接受同subject新授权。重新尝试必须执行真实撤销，不能无证据清除待处理状态。

新增认证与账务接口使用独立IntegrationError对象`{error:{code,message}}`，不扩展首七账号接口的ErrorCode枚举。code为稳定字符串，未知code按HTTP状态处理，不解析message。无效第三方身份、attempt秘密、浏览器cookie或确认表单证明返回400 INVALID_PROVIDER_PROOF；参数错误为400 VALIDATION；登录或购买状态冲突为409；缺渠道资源或渠道不可用为503，基础设施内部失败为500 INTERNAL_ERROR。返回Retry-After时按其等待。

## 单订阅与入账

- Apple、Google、网页Stripe共享账号级购买占位。先purchase-context，再以返回version调用start，原生再打开SDK；网页checkout同样绑定预留。ownerRef用于appAccountToken或obfuscatedExternalAccountId，不是邮箱。
- 未交接reserved预留5分钟可释放。starting、pending、未知外部结果不能只因TTL或工作租约到期释放；重试同操作、同幂等键、同参数，不盲目开第二笔。客户端取消UI不是付款已终止的证明。
- Apple/Google购买接口或restore传渠道凭据；服务端查询实际应用、环境、商品、绑定、当前状态及交易历史。通知先验签并持久接收，再核验实际渠道事实。通知本身、客户端声称成功、Stripe返回页均不是权益。
- 正常每账号一个当前订阅；取消续费仍在有效付费期时继续有效。外部重订、跨渠道在途支付等现实冲突记录全部真实购买，只提供一份能力、不累加重叠天数，进入取消/退款核对，不能隐瞒已发生扣款。
- 同一商店账号删号后，新Avalon账号只有在渠道证明新购买、新绑定且旧整链操作已解决时，才能获得未来新付费段。旧段、旧资料、剩余期限和历史归属不转移；自动续费、restore、单纯晚于删号时间均不充分。
- 完整核验绑定账号购买集合revision及各链verification revision；提交和退休时 MUST 原子核对账号、购买归属、完整集合及当前版本。旧worker、迟到乱序响应、旧owner通知不能覆盖更新归属。
- 所有真实合法未撤销服务段用于投影。历史换渠道不累加重叠服务期；退款/撤销按渠道事实更新，不把部分退款默认为整条订阅作废。未知状态不假定付款失败或永久到期。

## 同步生命周期与恢复

从空间持久化E、R开始，按真实EstablishedAt逐段重放有效历史。严格早于当前R建立的续费才能延续原代次，再延长E及R；恰在R或之后无法跨越断档。当前已过期也须考虑历史续费，不能只看最新active/expiry。历史不全、待核对事件或proof版本变动置verificationPending，不永久退休。已持久退休事实不回退，后续有效权益只能显式重建新代次。

恢复旧资料 MUST NOT 撤回最新账号删除、退休、购买归属、版本及未决操作事实。恢复后旧登录、attempt与回执 MUST 失效，购买占位及未决操作必须保持有效并重新核验实际渠道；未核对的旧active投影不得开放同步。必要密钥或权威事实缺失时 MUST 拒绝相应处理，不能视为空账号或无购买而绕过检查。

云端内容普通受控备份仍按原UTC创建最多30天清理。最小交易归属、防滥用记录及未决账务任务是独立账务/安全记录，不随账号或云端备份删除而释放；正式政策说明目的和请求渠道，不编造固定法定保留年限。

## 可用性与验收边界

未配置渠道返回PROVIDER_NOT_CONFIGURED，其他已配置渠道和邮箱服务继续可用；不能把测试结果作为公开付费权益。正式发布前仍需客户端适配、真实渠道购买核验、删除重购／退款／通知、适用真机及恢复隔离验收；候选契约检查不能代替这些验收。
