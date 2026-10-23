#!/usr/bin/env python3
"""Loopback-only bridge for native sandbox tests; emits no mail contents/logs."""

import argparse
import json
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
import re

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("mailbox", type=Path)
parser.add_argument("--port", type=int, default=21424)
args = parser.parse_args()
mailbox = args.mailbox.resolve(strict=True)
if not mailbox.is_dir():
    raise SystemExit("Configure an existing sandbox mailbox directory.")


class Mailbox(BaseHTTPRequestHandler):
    def log_message(self, *_):
        pass

    def do_GET(self):
        challenge = self.path.removeprefix("/")
        if not re.fullmatch(r"[0-9a-fA-F-]{36}", challenge):
            self.send_error(400)
            return
        file = mailbox / (challenge + ".json")
        try:
            if file.is_symlink() or file.stat().st_size > 65536:
                raise ValueError()
            code = json.loads(file.read_text())["code"]
            if not isinstance(code, str) or not re.fullmatch(r"[0-9]{6}", code):
                raise ValueError()
        except (OSError, ValueError, KeyError, TypeError):
            self.send_error(404)
            return
        body = json.dumps({"code": code}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Cache-Control", "no-store")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


print("Sandbox mailbox bridge ready on loopback.", flush=True)
server = HTTPServer(("127.0.0.1", args.port), Mailbox)
try:
    server.serve_forever()
except KeyboardInterrupt:
    pass
finally:
    server.server_close()
