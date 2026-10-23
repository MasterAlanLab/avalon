#!/usr/bin/env python3
"""Check released and reviewed candidate Cloud contracts without network access.

Dependency: python3 -m pip install -r tool/requirements-cloud-contract.txt
Usage: python3 tool/check_cloud_contract.py [--server-root ../avalon-cloud]
"""

import argparse
import hashlib
import json
from pathlib import Path
import re
import sys


class ContractError(Exception):
    """A reviewed contract or its copy changed."""


FIRST_BATCH = {
    ("/v1/auth/email/start", "post"),
    ("/v1/auth/email/verify", "post"),
    ("/v1/auth/refresh", "post"),
    ("/v1/auth/logout", "post"),
    ("/v1/account", "get"),
    ("/v1/account", "delete"),
    ("/v1/devices/{id}", "delete"),
}
HTTP_METHODS = {"get", "put", "post", "delete", "options", "head", "patch", "trace"}
# Candidate review locks do not publish a release or move the canonical contract.
# Keeping this inventory explicit makes deleting a lock entry fail closed.
REQUIRED_CANDIDATES = {
    "0.3.0": {"README.md", "cloud.openapi.yaml", "SYNC_PROTOCOL.md"},
    "0.4.0": {
        "README.md", "cloud.openapi.yaml", "SYNC_PROTOCOL.md", "AUTH_BILLING_PROTOCOL.md"
    },
}


def read_file(path):
    try:
        return path.read_bytes()
    except OSError as error:
        raise ContractError(f"无法读取契约文件 {path}：{error.strerror}") from error


def unique_mapping(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ContractError(f"契约锁含重复字段：{key}")
        result[key] = value
    return result


def load_yaml(path):
    try:
        import yaml
    except ImportError as error:
        raise ContractError(
            "缺少 PyYAML；请运行 python3 -m pip install -r "
            "tool/requirements-cloud-contract.txt 后重试。"
        ) from error

    class UniqueLoader(yaml.SafeLoader):
        pass

    def construct_mapping(loader, node, deep=False):
        result = {}
        for key_node, value_node in node.value:
            key = loader.construct_object(key_node, deep=deep)
            if key in result:
                raise ContractError(f"OpenAPI 含重复 YAML key：{key}（{path}）")
            result[key] = loader.construct_object(value_node, deep=deep)
        return result

    UniqueLoader.add_constructor(
        yaml.resolver.BaseResolver.DEFAULT_MAPPING_TAG, construct_mapping
    )
    try:
        document = yaml.load(read_file(path).decode("utf-8"), Loader=UniqueLoader)
    except (yaml.YAMLError, UnicodeError, TypeError) as error:
        raise ContractError(f"OpenAPI 解析失败：{path}") from error
    if not isinstance(document, dict):
        raise ContractError(f"OpenAPI 顶层必须是对象：{path}")
    return document


def references(value):
    pending = [value]
    seen = set()
    while pending:
        item = pending.pop()
        if isinstance(item, (dict, list)):
            if id(item) in seen:
                continue
            seen.add(id(item))
            if isinstance(item, dict):
                if "$ref" in item:
                    yield item["$ref"]
                pending.extend(item.values())
            else:
                pending.extend(item)


def resolve_ref(document, ref):
    if not isinstance(ref, str) or not ref.startswith("#/"):
        raise ContractError(f"只允许本地 OpenAPI $ref：{ref}")
    value = document
    for part in ref[2:].split("/"):
        if re.search(r"~(?![01])", part):
            raise ContractError(f"非法 OpenAPI $ref：{ref}")
        key = part.replace("~1", "/").replace("~0", "~")
        try:
            if isinstance(value, dict):
                value = value[key]
            elif isinstance(value, list) and re.fullmatch(r"0|[1-9][0-9]*", key):
                value = value[int(key)]
            else:
                raise KeyError(key)
        except (KeyError, IndexError) as error:
            raise ContractError(f"OpenAPI $ref 无法解析：{ref}") from error
    return value


def operations(document):
    paths = document.get("paths")
    if not isinstance(paths, dict):
        raise ContractError("OpenAPI 缺少 paths 对象")
    result = {}
    identifiers = set()
    for path, path_item in paths.items():
        if not isinstance(path_item, dict):
            raise ContractError(f"OpenAPI path 必须是对象：{path}")
        for method, operation in path_item.items():
            if method not in HTTP_METHODS:
                continue
            if not isinstance(operation, dict):
                raise ContractError(f"OpenAPI operation 必须是对象：{method} {path}")
            identifier = operation.get("operationId")
            if not isinstance(identifier, str) or not identifier:
                raise ContractError(f"OpenAPI 缺少 operationId：{method} {path}")
            if identifier in identifiers:
                raise ContractError(f"OpenAPI operationId 重复：{identifier}")
            identifiers.add(identifier)
            result[(path, method)] = operation
    return result


def check_first_batch(previous, current):
    old_operations = operations(previous)
    new_operations = operations(current)
    if set(old_operations) != FIRST_BATCH:
        raise ContractError("0.1.1 归档必须包含已批准的首批七个操作")
    if current.get("security") != previous.get("security"):
        raise ContractError("既有顶层认证规则已改变")
    pending_refs = set()
    for (path, method), old_operation in old_operations.items():
        if new_operations.get((path, method)) != old_operation:
            raise ContractError(f"首批操作发生变更：{method.upper()} {path}")
        for key in ("parameters", "servers", "$ref"):
            old_value = previous["paths"][path].get(key)
            if current["paths"][path].get(key) != old_value:
                raise ContractError(f"首批 path 的 {key} 已改变：{path}")
            pending_refs.update(references(old_value))
        pending_refs.update(references(old_operation))

    # Security schemes are named in security requirements, not through $ref.
    old_schemes = previous.get("components", {}).get("securitySchemes", {})
    new_schemes = current.get("components", {}).get("securitySchemes", {})
    for name, scheme in old_schemes.items():
        if new_schemes.get(name) != scheme:
            raise ContractError(f"既有认证定义已改变：{name}")
        pending_refs.update(references(scheme))

    checked = set()
    while pending_refs:
        ref = pending_refs.pop()
        if ref in checked:
            continue
        checked.add(ref)
        old_value = resolve_ref(previous, ref)
        if resolve_ref(current, ref) != old_value:
            raise ContractError(f"首批引用定义发生变更：{ref}")
        pending_refs.update(references(old_value))


def check_additive_wire(previous, current):
    """Keep the existing protocol 2 operations and definitions unchanged."""
    if current.get("security") != previous.get("security"):
        raise ContractError("候选版本改变既有顶层认证规则")
    for path, value in previous["paths"].items():
        if current["paths"].get(path) != value:
            raise ContractError(f"候选版本改变既有 wire：paths/{path}")
    old_components = previous.get("components", {})
    new_components = current.get("components", {})
    if not isinstance(old_components, dict) or not isinstance(new_components, dict):
        raise ContractError("候选 OpenAPI components 必须是对象")
    for category, entries in old_components.items():
        if not isinstance(entries, dict) or not isinstance(new_components.get(category), dict):
            raise ContractError(f"候选 OpenAPI components/{category} 必须是对象")
        for name, value in entries.items():
            if new_components.get(category, {}).get(name) != value:
                raise ContractError(
                    f"候选版本改变既有 wire：components/{category}/{name}"
                )


def check_candidates(api, baseline, server_api=None):
    """Verify the full review inventory even when both repository copies change."""
    lock_path = api / "candidates.lock.json"
    if lock_path.is_symlink():
        raise ContractError("候选契约锁必须是普通文件")
    lock_bytes = read_file(lock_path)
    try:
        lock = json.loads(lock_bytes, object_pairs_hook=unique_mapping)
    except (ValueError, UnicodeError) as error:
        raise ContractError("candidates.lock.json 不是有效 JSON") from error
    if (
        not isinstance(lock, dict)
        or set(lock) != {"lockVersion", "candidates"}
        or type(lock.get("lockVersion")) is not int
        or lock["lockVersion"] != 1
    ):
        raise ContractError("不支持的候选契约锁；需要 lockVersion=1 和 candidates")
    candidates = lock["candidates"]
    if not isinstance(candidates, dict) or set(candidates) != set(REQUIRED_CANDIDATES):
        raise ContractError("候选契约锁必须完整列出 0.3.0 和 0.4.0")
    if (api / "drafts").is_symlink():
        raise ContractError("候选契约目录不得使用符号链接")
    if server_api is not None:
        if (server_api / "candidates.lock.json").is_symlink():
            raise ContractError("服务端候选契约锁必须是普通文件")
        if read_file(server_api / "candidates.lock.json") != lock_bytes:
            raise ContractError("服务端 candidates.lock.json 与客户端逐字节不同")
        if (server_api / "drafts").is_symlink():
            raise ContractError("服务端候选契约目录不得使用符号链接")

    documents = {}
    for version, required_files in REQUIRED_CANDIDATES.items():
        files = candidates[version]
        if not isinstance(files, dict):
            raise ContractError(f"候选契约文件清单必须是对象：{version}")
        for name in files:
            if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_.-]*", name):
                raise ContractError(f"非法候选契约文件名：{name}")
        if set(files) != required_files:
            raise ContractError(f"候选契约文件清单不完整或含未知文件：{version}")
        directory = api / "drafts" / version
        if directory.is_symlink():
            raise ContractError(f"候选契约目录不得使用符号链接：{version}")
        try:
            actual_files = {path.name for path in directory.iterdir()}
        except OSError as error:
            raise ContractError(f"无法读取候选契约目录：{version}") from error
        if actual_files != required_files:
            raise ContractError(f"候选契约目录与完整清单不同：{version}")
        if server_api is not None:
            server_directory = server_api / "drafts" / version
            if server_directory.is_symlink():
                raise ContractError(f"服务端候选契约目录不得使用符号链接：{version}")
            try:
                server_files = {path.name for path in server_directory.iterdir()}
            except OSError as error:
                raise ContractError(f"无法读取服务端候选契约目录：{version}") from error
            if server_files != required_files:
                raise ContractError(f"服务端候选契约目录与完整清单不同：{version}")
        for name, digest in files.items():
            if not isinstance(digest, str) or not re.fullmatch(r"[0-9a-f]{64}", digest):
                raise ContractError(f"非法候选 SHA-256：{version}/{name}")
            path = directory / name
            if path.is_symlink():
                raise ContractError(f"候选契约不得使用符号链接：{version}/{name}")
            content = read_file(path)
            if hashlib.sha256(content).hexdigest() != digest:
                raise ContractError(f"候选契约偏离审阅摘要：{version}/{name}")
            if server_api is not None:
                server_path = server_directory / name
                if server_path.is_symlink():
                    raise ContractError(f"服务端候选契约不得使用符号链接：{version}/{name}")
                if read_file(server_path) != content:
                    raise ContractError(f"服务端候选契约与客户端不同：{version}/{name}")
        document = load_yaml(directory / "cloud.openapi.yaml")
        info = document.get("info")
        if (
            document.get("openapi") != "3.0.3"
            or not isinstance(info, dict)
            or info.get("version") != version
        ):
            raise ContractError(f"候选 OpenAPI 版本与清单不同：{version}")
        operations(document)
        for ref in references(document):
            resolve_ref(document, ref)
        check_first_batch(baseline, document)
        documents[version] = document
    check_additive_wire(documents["0.3.0"], documents["0.4.0"])
    return sorted(documents)


def check_contract(client_root, server_root=None):
    api = Path(client_root) / "docs" / "api"
    lock_bytes = read_file(api / "contract.lock.json")
    try:
        lock = json.loads(lock_bytes, object_pairs_hook=unique_mapping)
    except (ValueError, UnicodeError) as error:
        raise ContractError("contract.lock.json 不是有效 JSON") from error
    if (
        not isinstance(lock, dict)
        or type(lock.get("lockVersion")) is not int
        or lock["lockVersion"] != 1
    ):
        raise ContractError("不支持的契约锁版本；需要 lockVersion=1")
    current_version = lock.get("currentVersion")
    releases = lock.get("releases")
    current_files = lock.get("currentFiles")
    if not isinstance(releases, dict) or not releases:
        raise ContractError("契约锁缺少 releases")
    if (
        not isinstance(current_files, list)
        or not all(isinstance(name, str) for name in current_files)
        or len(current_files) != len(set(current_files))
        or not {"cloud.openapi.yaml", "SYNC_PROTOCOL.md"}.issubset(current_files)
    ):
        raise ContractError("currentFiles 必须包含唯一的 OpenAPI 与同步规范文件名")
    if (
        not isinstance(current_version, str)
        or current_version not in releases
        or "0.1.1" not in releases
    ):
        raise ContractError("契约锁缺少当前版本或 0.1.1 兼容基线")

    archive_bytes = {}
    documents = {}
    for version, files in releases.items():
        if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", version):
            raise ContractError(f"非法契约版本路径：{version}")
        if not isinstance(files, dict) or "cloud.openapi.yaml" not in files:
            raise ContractError(f"归档版本缺少 OpenAPI：{version}")
        for name, digest in files.items():
            if not re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_.-]*", name):
                raise ContractError(f"非法契约文件名：{name}")
            if not isinstance(digest, str) or not re.fullmatch(r"[0-9a-f]{64}", digest):
                raise ContractError(f"非法 SHA-256：{version}/{name}")
            content = read_file(api / "releases" / version / name)
            if hashlib.sha256(content).hexdigest() != digest:
                raise ContractError(f"不可变归档已改变：releases/{version}/{name}")
            archive_bytes[(version, name)] = content
        path = api / "releases" / version / "cloud.openapi.yaml"
        document = load_yaml(path)
        info = document.get("info")
        if not isinstance(info, dict) or info.get("version") != version:
            raise ContractError(f"OpenAPI info.version 与归档版本不同：{version}")
        operations(document)
        for ref in references(document):
            resolve_ref(document, ref)
        documents[version] = document

    if set(current_files) != set(releases[current_version]):
        raise ContractError("currentFiles 与当前版本归档清单不同")
    for name in current_files:
        if read_file(api / name) != archive_bytes[(current_version, name)]:
            raise ContractError(f"当前契约与已审定归档不同：{name}")
    check_first_batch(documents["0.1.1"], documents[current_version])

    server_api = None if server_root is None else Path(server_root) / "docs" / "api"
    if server_api is not None:
        if read_file(server_api / "contract.lock.json") != lock_bytes:
            raise ContractError("服务端 contract.lock.json 与客户端逐字节不同")
        for name in current_files:
            if read_file(server_api / name) != read_file(api / name):
                raise ContractError(f"服务端当前契约与客户端不同：{name}")
        for (version, name), content in archive_bytes.items():
            if read_file(server_api / "releases" / version / name) != content:
                raise ContractError(f"服务端归档与客户端不同：releases/{version}/{name}")

    candidates = check_candidates(api, documents["0.1.1"], server_api)

    return {
        "version": current_version,
        "releases": len(releases),
        "operations": len(operations(documents[current_version])),
        "candidates": candidates,
        "server_copy_checked": server_root is not None,
    }


def main():
    parser = argparse.ArgumentParser(description="本地核对 Cloud 固定契约与两仓副本")
    parser.add_argument("--client-root", type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument("--server-root", type=Path)
    args = parser.parse_args()
    try:
        result = check_contract(args.client_root, args.server_root)
    except ContractError as error:
        print(f"契约检查失败：{error}。请核对审定归档和契约锁后重试。", file=sys.stderr)
        return 1
    print(json.dumps(result, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    sys.exit(main())
