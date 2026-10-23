#!/usr/bin/env python3
"""Contract drift regressions using temporary repositories only.

Run: python3 -m unittest discover -s tool -p test_cloud_contract.py
Dependency: python3 -m pip install -r tool/requirements-cloud-contract.txt
"""

from copy import deepcopy
import hashlib
import json
from pathlib import Path
import shutil
from tempfile import TemporaryDirectory
import unittest

from check_cloud_contract import (
    ContractError,
    FIRST_BATCH,
    REQUIRED_CANDIDATES,
    check_contract,
)


class CloudContractTest(unittest.TestCase):
    def setUp(self):
        self.temporary = TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.client = Path(self.temporary.name) / "client"
        self.server = Path(self.temporary.name) / "server"
        self.api = self.client / "docs" / "api"
        self.api.mkdir(parents=True)
        self.previous = {
            "openapi": "3.0.3",
            "info": {"version": "0.1.1", "title": "Fixture"},
            "security": [{"Bearer": []}],
            "paths": {},
            "components": {
                "securitySchemes": {
                    "Bearer": {"type": "http", "scheme": "bearer"}
                },
                "schemas": {
                    "Envelope": {
                        "type": "object",
                        "required": ["account"],
                        "properties": {
                            "account": {"$ref": "#/components/schemas/Account"}
                        },
                    },
                    "Account": {
                        "type": "object",
                        "required": ["id"],
                        "properties": {"id": {"type": "string"}},
                    },
                },
            },
        }
        for index, (path, method) in enumerate(sorted(FIRST_BATCH)):
            self.previous["paths"].setdefault(path, {})[method] = {
                "operationId": f"firstBatch{index}",
                "responses": {
                    "200": {
                        "description": "Fixture only",
                        "content": {
                            "application/json": {
                                "schema": {"$ref": "#/components/schemas/Envelope"}
                            }
                        },
                    }
                },
            }
        self.current = deepcopy(self.previous)
        self.current["info"]["version"] = "0.2.0"
        self.current["components"]["schemas"]["SyncPayload"] = {
            "type": "object",
            "properties": {"recordId": {"type": "string"}},
        }
        for name, method in (("activate", "post"), ("push", "post"), ("pull", "get")):
            self.current["paths"][f"/v1/sync/{name}"] = {
                method: {
                    "operationId": f"sync{name.title()}",
                    "responses": {
                        "200": {
                            "description": "Fixture only",
                            "content": {
                                "application/json": {
                                    "schema": {"$ref": "#/components/schemas/SyncPayload"}
                                }
                            },
                        }
                    },
                }
            }
        self.lock = {
            "lockVersion": 1,
            "currentVersion": "0.2.0",
            "currentFiles": ["cloud.openapi.yaml", "SYNC_PROTOCOL.md"],
            "releases": {"0.1.1": {}, "0.2.0": {}},
        }
        self.archive("0.1.1", "cloud.openapi.yaml", self.encode(self.previous))
        self.archive("0.2.0", "cloud.openapi.yaml", self.encode(self.current))
        self.archive("0.2.0", "SYNC_PROTOCOL.md", b"# Reviewed fixture protocol\n")
        self.write_lock()
        self.candidate_lock = {"lockVersion": 1, "candidates": {}}
        self.candidates = {}
        for version, files in REQUIRED_CANDIDATES.items():
            document = deepcopy(self.current)
            document["info"]["version"] = version
            self.candidates[version] = document
            self.candidate_lock["candidates"][version] = {}
            for name in files:
                content = (
                    self.encode(document)
                    if name == "cloud.openapi.yaml"
                    else b"# Candidate fixture\nServer authorizes each account in a transaction.\n"
                )
                self.candidate_file(version, name, content)
        self.write_candidate_lock()
        shutil.copytree(self.api, self.server / "docs" / "api")

    @staticmethod
    def encode(document):
        # JSON is valid YAML; fixtures do not require a second YAML emitter.
        return (json.dumps(document, indent=2) + "\n").encode()

    def archive(self, version, name, content):
        path = self.api / "releases" / version / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(content)
        self.lock["releases"][version][name] = hashlib.sha256(content).hexdigest()
        if version == self.lock["currentVersion"]:
            (self.api / name).write_bytes(content)

    def write_lock(self):
        (self.api / "contract.lock.json").write_bytes(self.encode(self.lock))

    def approve_current(self):
        self.archive("0.2.0", "cloud.openapi.yaml", self.encode(self.current))
        self.write_lock()

    def candidate_file(self, version, name, content):
        path = self.api / "drafts" / version / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(content)
        self.candidate_lock["candidates"][version][name] = hashlib.sha256(content).hexdigest()

    def write_candidate_lock(self):
        (self.api / "candidates.lock.json").write_bytes(self.encode(self.candidate_lock))

    def approve_candidate(self, version):
        self.candidate_file(version, "cloud.openapi.yaml", self.encode(self.candidates[version]))
        self.write_candidate_lock()

    def test_matching_repositories_and_frozen_first_batch_pass(self):
        self.assertEqual(
            check_contract(self.client, self.server),
            {
                "version": "0.2.0",
                "releases": 2,
                "operations": 10,
                "candidates": ["0.3.0", "0.4.0"],
                "server_copy_checked": True,
            },
        )

    def test_current_openapi_change_is_rejected(self):
        with (self.api / "cloud.openapi.yaml").open("ab") as file:
            file.write(b"\n# unreviewed\n")
        with self.assertRaisesRegex(ContractError, "当前契约与已审定归档不同"):
            check_contract(self.client)

    def test_current_protocol_change_is_rejected(self):
        (self.api / "SYNC_PROTOCOL.md").write_bytes(b"# changed protocol\n")
        with self.assertRaisesRegex(ContractError, "SYNC_PROTOCOL.md"):
            check_contract(self.client)

    def test_historical_archive_change_is_rejected(self):
        path = self.api / "releases" / "0.1.1" / "cloud.openapi.yaml"
        with path.open("ab") as file:
            file.write(b"\n# edited history\n")
        with self.assertRaisesRegex(ContractError, "不可变归档已改变"):
            check_contract(self.client)

    def test_missing_archive_is_rejected(self):
        (self.api / "releases" / "0.2.0" / "SYNC_PROTOCOL.md").unlink()
        with self.assertRaisesRegex(ContractError, "无法读取契约文件"):
            check_contract(self.client)

    def test_server_current_copy_change_is_rejected(self):
        (self.server / "docs" / "api" / "SYNC_PROTOCOL.md").write_bytes(b"changed\n")
        with self.assertRaisesRegex(ContractError, "服务端当前契约与客户端不同"):
            check_contract(self.client, self.server)

    def test_server_lock_formatting_change_is_rejected(self):
        path = self.server / "docs" / "api" / "contract.lock.json"
        path.write_bytes(json.dumps(self.lock).encode())
        with self.assertRaisesRegex(ContractError, "服务端 contract.lock.json"):
            check_contract(self.client, self.server)

    def test_server_historical_copy_change_is_rejected(self):
        path = self.server / "docs" / "api" / "releases" / "0.1.1" / "cloud.openapi.yaml"
        path.write_bytes(b"changed history\n")
        with self.assertRaisesRegex(ContractError, "服务端归档与客户端不同"):
            check_contract(self.client, self.server)

    def test_server_missing_archive_is_rejected(self):
        path = self.server / "docs" / "api" / "releases" / "0.2.0" / "SYNC_PROTOCOL.md"
        path.unlink()
        with self.assertRaisesRegex(ContractError, "无法读取契约文件"):
            check_contract(self.client, self.server)

    def test_reviewed_new_release_cannot_remove_first_batch_operation(self):
        del self.current["paths"]["/v1/auth/refresh"]["post"]
        self.approve_current()
        with self.assertRaisesRegex(ContractError, "首批操作发生变更"):
            check_contract(self.client)

    def test_reviewed_new_release_cannot_change_nested_auth_schema(self):
        self.current["components"]["schemas"]["Account"]["required"] = []
        self.approve_current()
        with self.assertRaisesRegex(ContractError, "首批引用定义发生变更"):
            check_contract(self.client)

    def test_reviewed_new_release_cannot_change_auth_scheme(self):
        self.current["components"]["securitySchemes"]["Bearer"]["scheme"] = "basic"
        self.approve_current()
        with self.assertRaisesRegex(ContractError, "既有认证定义已改变"):
            check_contract(self.client)

    def test_unresolved_new_sync_reference_is_rejected(self):
        self.current["components"]["schemas"]["SyncPayload"]["properties"]["recordId"] = {
            "$ref": "#/components/schemas/Missing"
        }
        self.approve_current()
        with self.assertRaisesRegex(ContractError, r"\$ref 无法解析"):
            check_contract(self.client)

    def test_external_reference_is_rejected_without_network_access(self):
        self.current["components"]["schemas"]["SyncPayload"] = {
            "$ref": "https://example.invalid/schema.yaml"
        }
        self.approve_current()
        with self.assertRaisesRegex(ContractError, "只允许本地 OpenAPI"):
            check_contract(self.client)

    def test_duplicate_yaml_keys_are_rejected_even_with_matching_hash(self):
        content = b'{"info": {},' + self.encode(self.current)[1:]
        self.archive("0.2.0", "cloud.openapi.yaml", content)
        self.write_lock()
        with self.assertRaisesRegex(ContractError, "重复 YAML key"):
            check_contract(self.client)

    def test_duplicate_operation_ids_are_rejected(self):
        self.current["paths"]["/v1/sync/push"]["post"]["operationId"] = "syncActivate"
        self.approve_current()
        with self.assertRaisesRegex(ContractError, "operationId 重复"):
            check_contract(self.client)

    def test_version_path_cannot_escape_archive(self):
        self.lock["releases"]["../outside"] = self.lock["releases"]["0.1.1"]
        self.write_lock()
        with self.assertRaisesRegex(ContractError, "非法契约版本路径"):
            check_contract(self.client)

    def test_baseline_cannot_be_removed_from_lock(self):
        del self.lock["releases"]["0.1.1"]
        self.write_lock()
        with self.assertRaisesRegex(ContractError, "0.1.1 兼容基线"):
            check_contract(self.client)

    def test_candidate_authorization_text_change_is_rejected(self):
        path = self.api / "drafts" / "0.3.0" / "SYNC_PROTOCOL.md"
        path.write_bytes(b"# Account authorization removed\n")
        with self.assertRaisesRegex(ContractError, "候选契约偏离审阅摘要"):
            check_contract(self.client)

    def test_changing_both_candidate_copies_cannot_bypass_review_digest(self):
        for root in (self.client, self.server):
            path = root / "docs/api/drafts/0.4.0/AUTH_BILLING_PROTOCOL.md"
            path.write_bytes(b"# Unreviewed shared change\n")
        with self.assertRaisesRegex(ContractError, "候选契约偏离审阅摘要"):
            check_contract(self.client, self.server)

    def test_every_candidate_readme_is_locked(self):
        for version in REQUIRED_CANDIDATES:
            with self.subTest(version=version):
                path = self.api / "drafts" / version / "README.md"
                original = path.read_bytes()
                path.write_bytes(b"# Unreviewed scope change\n")
                with self.assertRaisesRegex(ContractError, "候选契约偏离审阅摘要"):
                    check_contract(self.client)
                path.write_bytes(original)

    def test_missing_candidate_lock_cannot_silently_skip_check(self):
        (self.api / "candidates.lock.json").unlink()
        with self.assertRaisesRegex(ContractError, "无法读取契约文件"):
            check_contract(self.client)

    def test_candidate_entry_cannot_be_deleted(self):
        del self.candidate_lock["candidates"]["0.3.0"]
        self.write_candidate_lock()
        with self.assertRaisesRegex(ContractError, "必须完整列出"):
            check_contract(self.client)

    def test_candidate_file_cannot_be_removed_from_lock(self):
        del self.candidate_lock["candidates"]["0.4.0"]["AUTH_BILLING_PROTOCOL.md"]
        self.write_candidate_lock()
        with self.assertRaisesRegex(ContractError, "候选契约文件清单不完整"):
            check_contract(self.client)

    def test_candidate_file_cannot_be_deleted(self):
        (self.api / "drafts/0.3.0/SYNC_PROTOCOL.md").unlink()
        with self.assertRaisesRegex(ContractError, "候选契约目录与完整清单不同"):
            check_contract(self.client)

    def test_unknown_candidate_document_cannot_be_ignored(self):
        (self.api / "drafts/0.4.0/UNLOCKED.md").write_bytes(b"# Unlocked extension\n")
        with self.assertRaisesRegex(ContractError, "候选契约目录与完整清单不同"):
            check_contract(self.client)

    def test_candidate_lock_rejects_path_traversal(self):
        self.candidate_lock["candidates"]["0.3.0"]["../../outside.md"] = "a" * 64
        self.write_candidate_lock()
        with self.assertRaisesRegex(ContractError, "非法候选契约文件名"):
            check_contract(self.client)

    def test_candidate_version_cannot_escape_directory(self):
        self.candidate_lock["candidates"]["../outside"] = {}
        self.write_candidate_lock()
        with self.assertRaisesRegex(ContractError, "必须完整列出"):
            check_contract(self.client)

    def test_candidate_lock_rejects_duplicate_keys(self):
        content = b'{"lockVersion":1,' + self.encode(self.candidate_lock)[1:]
        (self.api / "candidates.lock.json").write_bytes(content)
        with self.assertRaisesRegex(ContractError, "重复字段"):
            check_contract(self.client)

    def test_candidate_lock_rejects_duplicate_file_digest(self):
        content = self.encode(self.candidate_lock).replace(
            b'"README.md":', b'"README.md": "' + b"0" * 64 + b'", "README.md":', 1
        )
        (self.api / "candidates.lock.json").write_bytes(content)
        with self.assertRaisesRegex(ContractError, "重复字段"):
            check_contract(self.client)

    def test_candidate_lock_rejects_boolean_version(self):
        self.candidate_lock["lockVersion"] = True
        self.write_candidate_lock()
        with self.assertRaisesRegex(ContractError, "不支持的候选契约锁"):
            check_contract(self.client)

    def test_candidate_digest_must_be_sha256(self):
        self.candidate_lock["candidates"]["0.4.0"]["README.md"] = "not-a-digest"
        self.write_candidate_lock()
        with self.assertRaisesRegex(ContractError, "非法候选 SHA-256"):
            check_contract(self.client)

    def test_candidate_file_symlink_is_rejected(self):
        target = self.client / "outside.md"
        path = self.api / "drafts/0.3.0/README.md"
        target.write_bytes(path.read_bytes())
        path.unlink()
        path.symlink_to(target)
        with self.assertRaisesRegex(ContractError, "不得使用符号链接"):
            check_contract(self.client)

    def test_candidate_openapi_version_is_checked_after_review(self):
        self.candidates["0.3.0"]["info"]["version"] = "0.4.0"
        self.approve_candidate("0.3.0")
        with self.assertRaisesRegex(ContractError, "候选 OpenAPI 版本与清单不同"):
            check_contract(self.client)

    def test_candidate_openapi_dialect_is_checked_after_review(self):
        self.candidates["0.4.0"]["openapi"] = "3.1.0"
        self.approve_candidate("0.4.0")
        with self.assertRaisesRegex(ContractError, "候选 OpenAPI 版本与清单不同"):
            check_contract(self.client)

    def test_candidate_duplicate_yaml_key_is_rejected_after_review(self):
        document = self.candidates["0.3.0"]
        self.candidate_file("0.3.0", "cloud.openapi.yaml", b'{"info":{},' + self.encode(document)[1:])
        self.write_candidate_lock()
        with self.assertRaisesRegex(ContractError, "重复 YAML key"):
            check_contract(self.client)

    def test_candidate_external_reference_is_rejected_after_review(self):
        self.candidates["0.4.0"]["components"]["schemas"]["New"] = {
            "$ref": "https://example.invalid/schema.yaml"
        }
        self.approve_candidate("0.4.0")
        with self.assertRaisesRegex(ContractError, "只允许本地 OpenAPI"):
            check_contract(self.client)

    def test_candidate_missing_reference_is_rejected_after_review(self):
        self.candidates["0.4.0"]["components"]["schemas"]["New"] = {
            "$ref": "#/components/schemas/Missing"
        }
        self.approve_candidate("0.4.0")
        with self.assertRaisesRegex(ContractError, r"\$ref 无法解析"):
            check_contract(self.client)

    def test_candidate_duplicate_operation_id_is_rejected_after_review(self):
        self.candidates["0.4.0"]["paths"]["/new"] = {
            "get": {"operationId": "syncActivate", "responses": {}}
        }
        self.approve_candidate("0.4.0")
        with self.assertRaisesRegex(ContractError, "operationId 重复"):
            check_contract(self.client)

    def test_candidate_operation_id_is_required_after_review(self):
        self.candidates["0.4.0"]["paths"]["/new"] = {"get": {"responses": {}}}
        self.approve_candidate("0.4.0")
        with self.assertRaisesRegex(ContractError, "缺少 operationId"):
            check_contract(self.client)

    def test_candidate_first_batch_cannot_be_changed_after_review(self):
        self.candidates["0.3.0"]["components"]["schemas"]["Account"]["required"] = []
        self.approve_candidate("0.3.0")
        with self.assertRaisesRegex(ContractError, "首批引用定义发生变更"):
            check_contract(self.client)

    def test_new_candidate_cannot_rewrite_existing_sync_operation(self):
        self.candidates["0.4.0"]["paths"]["/v1/sync/push"]["post"]["responses"] = {}
        self.approve_candidate("0.4.0")
        with self.assertRaisesRegex(ContractError, "候选版本改变既有 wire"):
            check_contract(self.client)

    def test_new_candidate_cannot_rewrite_existing_sync_component(self):
        self.candidates["0.4.0"]["components"]["schemas"]["SyncPayload"]["required"] = ["recordId"]
        self.approve_candidate("0.4.0")
        with self.assertRaisesRegex(ContractError, "候选版本改变既有 wire"):
            check_contract(self.client)

    def test_server_candidate_readme_must_match(self):
        path = self.server / "docs/api/drafts/0.3.0/README.md"
        path.write_bytes(b"# Different scope\n")
        with self.assertRaisesRegex(ContractError, "服务端候选契约与客户端不同"):
            check_contract(self.client, self.server)

    def test_server_candidate_lock_is_byte_exact(self):
        path = self.server / "docs/api/candidates.lock.json"
        path.write_bytes(json.dumps(self.candidate_lock).encode())
        with self.assertRaisesRegex(ContractError, "服务端 candidates.lock.json"):
            check_contract(self.client, self.server)

    def test_server_candidate_lock_cannot_be_a_symlink(self):
        path = self.server / "docs/api/candidates.lock.json"
        path.unlink()
        path.symlink_to(self.api / "candidates.lock.json")
        with self.assertRaisesRegex(ContractError, "服务端候选契约锁必须是普通文件"):
            check_contract(self.client, self.server)

    def test_server_candidate_directory_cannot_omit_a_locked_file(self):
        (self.server / "docs/api/drafts/0.4.0/README.md").unlink()
        with self.assertRaisesRegex(ContractError, "服务端候选契约目录与完整清单不同"):
            check_contract(self.client, self.server)


if __name__ == "__main__":
    unittest.main()
