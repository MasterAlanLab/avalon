#!/usr/bin/env python3
"""Exercise the actual desktop executable over Avalon's framed IPC, without accounts.
Usage: python3 tool/tailscale_ipc_smoke.py /absolute/path/to/AvalonCore
"""
import json
import socket
import struct
import subprocess
import sys
import tempfile
from pathlib import Path


def main():
    binary = Path(sys.argv[1]).resolve()
    secret = "fixture-auth-secret-redaction"
    url = "https://HOST/register/fixture-url-token"
    seen = []
    with tempfile.TemporaryDirectory(prefix="avalon-ts-", dir="/tmp") as root:
        server = socket.socket(socket.AF_UNIX)
        address = str(Path(root) / "ipc")
        server.bind(address)
        server.listen(1)
        server.settimeout(10)
        log_path = Path(root) / "core.log"
        with log_path.open("wb") as output:
            process = subprocess.Popen([str(binary), address], stdout=output, stderr=output)
            conn = None
            try:
                conn, _ = server.accept()
                conn.settimeout(10)
                number = 0

                def read_exact(size):
                    data = b""
                    while len(data) < size:
                        chunk = conn.recv(size - len(data))
                        if not chunk:
                            raise RuntimeError("core disconnected")
                        data += chunk
                    return data

                def send(data):
                    conn.sendall(struct.pack("<I", len(data)) + data)

                def rpc(method, arguments=None):
                    nonlocal number
                    number += 1
                    identifier = str(number)
                    send(json.dumps({"id": identifier, "method": method, "arguments": arguments}).encode())
                    while True:
                        size = struct.unpack("<I", read_exact(4))[0]
                        assert size <= 64 * 1024 * 1024
                        frame = json.loads(read_exact(size))
                        seen.append(frame)
                        if frame.get("id") == identifier:
                            return frame

                assert rpc("initClash", {"home-dir": str(Path(root)/"home"), "version": 0})["result"] is True
                capabilities = rpc("tailscaleCapabilities")["result"]
                assert capabilities == {"supported": True, "protocol": 2}, capabilities
                before = rpc("tailscaleSnapshot")["result"]
                assert before["session"] == "loggedOut" and before["devices"] == []
                assert not before["service"] and before["split"] == "inactive"
                # Both invalid requests return categorical errors without starting tsnet.
                invalid = rpc("tailscaleLogin", {"kind": "key", "control": url+"?TOKEN="+secret, "authKey": secret})
                assert invalid["error"]["code"] == "invalid_control_url", invalid
                empty = rpc("tailscaleLogin", {"kind": "key", "authKey": ""})
                assert empty["error"]["code"] == "empty_auth_key", empty
                assert rpc("tailscaleResume")["error"]["code"] == "needs_login"
                # A malformed frame must not leak its contents and must not break later RPC.
                send(b'{"authKey":"'+secret.encode()+b'","url":"'+url.encode()+b'",BROKEN')
                after = rpc("tailscaleSnapshot")["result"]
                assert after["session"] == "loggedOut"
                cancelled = rpc("tailscaleCancel")["result"]
                assert cancelled["generation"] > before["generation"]
                assert not cancelled.get("authUrl")
                assert cancelled["session"] == "loggedOut"
                logs = rpc("getLogs")
                assert rpc("shutdown")["result"] is True
                all_output = json.dumps(seen)+json.dumps(logs)+log_path.read_text()
                assert secret not in all_output and url not in all_output, "credential or authorization URL leaked"
                print(json.dumps({"binary": str(binary), "supported": True, "protocol": 2, "rpcChecks": number, "accountsUsed": False, "redaction": "passed"}))
            finally:
                if conn:
                    conn.close()
                server.close()
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    process.terminate()
                    process.wait(timeout=5)


if __name__ == "__main__":
    main()
