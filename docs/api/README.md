# 账号与同步公开契约

本目录保存客户端需要的公开接口约定。[OpenAPI](cloud.openapi.yaml) 定义请求、响应和错误，[SYNC_PROTOCOL](SYNC_PROTOCOL.md) 定义同步语义与安全约束。客户端接线、持久化与失败恢复规则统一维护在 [客户端账号与同步](../CLOUD_SYNC.md)，不重新定义接口。

## 版本与变更

- 当前公开版本为 **0.2.0**，同步 payload 使用 schema 1。
- `releases/` 保存不可变的 0.1.1、0.2.0 归档，`contract.lock.json` 固定 SHA-256。首批账号操作的 0.1.1 wire 保持不变。
- [0.3.0 草案](drafts/0.3.0/README.md) 定义显式协议2预览；[0.4.0 候选](drafts/0.4.0/README.md) 在其上增加第三方认证与订阅。两版尚未发布，不能覆盖现行契约或旧归档。
- `candidates.lock.json` 独立锁定实际采用的候选正文、说明和双端副本；必要修改须说明原因、兼容与迁移影响，完成双端验证后显式更新候选摘要。已采用候选的互操作及安全约束必须遵守；候选锁不表示正式发布或完整验收。
- 非必要不得修改接口。必要变更需说明原因、兼容与迁移方案，经双方验证后发布新版本；用户可见行为先记入 [决策记录](../DECISIONS.md)。
- 本目录只保存公开契约和客户端说明，不记录服务端实现、部署或测试环境信息（D103）。

在仓库根目录检查：

```sh
python3 -m pip install -r tool/requirements-cloud-contract.txt
python3 tool/check_cloud_contract.py
python3 -m unittest discover -s tool -p test_cloud_contract.py
```

校验覆盖已发布与候选摘要、归档及双端副本一致性、首批 wire、operationId、重复 YAML key 和本地引用；不替代 HTTP、真机或安全验收。

## 接口范围

现行契约包含邮箱登录、刷新与退出、账号与设备管理，以及激活、上传和下载同步操作。完整路径、operationId、字段、预算、分页、期限和认证要求直接查阅 [OpenAPI](cloud.openapi.yaml)，不在导航页维护第二份表格。成功正文直接返回业务 JSON；错误按 `error.code` 处理，不能解析脱敏 `message` 推导行为。

## 客户端边界

- 邮箱挑战、刷新和退出证明严格使用契约指定的凭据；退出补发不得携带另一账号的 Bearer。
- 未知权益不能视为同步资格。退出或删除账号保留本地内容及代理凭据。
- 上传结果未知时保留并重发原请求；下载先完整校验，再推进游标和应用投影。
- 同步代次、重建与清理状态只在显式协议2预览中使用；不自动降级。
- 日志、缓存和截图不得包含令牌、验证码、订阅认证 URL、节点秘密或请求响应正文。

产品行为见 [客户端账号与同步](../CLOUD_SYNC.md) 和 [产品规格](../PRODUCT_SPEC.md)；当前实现与剩余验收见 [Cloud 状态](../STATUS.md#cloud)。
