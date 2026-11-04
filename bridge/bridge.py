"""AI Computer bridge: lets the iPhone app talk to Claude Code on this PC.

The app sends a message, this server runs `claude -p` (which uses your
Claude subscription) and sends the reply back. It listens only on this
PC's Tailscale address and every request must carry the secret token.

Run:  python bridge.py
"""

import hmac
import json
import os
import secrets
import shutil
import subprocess
import sys
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

HERE = Path(__file__).resolve().parent
TOKEN_FILE = HERE / ".token"
WORKSPACE = Path(os.environ.get("BRIDGE_WORKSPACE", Path.home() / "AIComputerWorkspace"))
PORT = int(os.environ.get("BRIDGE_PORT", "8787"))
CLAUDE_TIMEOUT = 300  # seconds per message
MAX_BODY = 64 * 1024
busy = threading.Semaphore(2)  # at most two Claude runs at once


def load_token() -> str:
    if TOKEN_FILE.exists():
        return TOKEN_FILE.read_text().strip()
    token = secrets.token_urlsafe(24)
    TOKEN_FILE.write_text(token)
    return token


def tailscale_ip() -> str | None:
    exe = shutil.which("tailscale") or r"C:\Program Files\Tailscale\tailscale.exe"
    try:
        out = subprocess.run([exe, "ip", "-4"], capture_output=True, text=True, timeout=10)
    except (OSError, subprocess.TimeoutExpired):
        return None
    lines = out.stdout.split()
    if out.returncode != 0 or not lines or not lines[0].startswith("100."):
        return None
    return lines[0]


def run_claude(message: str, session_id: str | None) -> dict:
    claude = shutil.which("claude")
    if not claude:
        raise RuntimeError("Claude Code (claude) is not on PATH")
    # Skip the PC's user-level settings (plugins, hooks): about 3x faster per message.
    cmd = [claude, "-p", "--output-format", "json", "--setting-sources", "project"]
    if session_id:
        cmd += ["--resume", session_id]
    proc = subprocess.run(
        cmd, input=message, capture_output=True, text=True, encoding="utf-8",
        cwd=WORKSPACE, timeout=CLAUDE_TIMEOUT,
    )
    try:
        data = json.loads(proc.stdout)
    except json.JSONDecodeError:
        raise RuntimeError((proc.stderr or proc.stdout or "Claude Code returned nothing").strip()[:500])
    if data.get("is_error"):
        raise RuntimeError(str(data.get("result") or "Claude Code reported an error")[:500])
    return {"reply": data.get("result", ""), "session_id": data.get("session_id")}


class Handler(BaseHTTPRequestHandler):
    token = ""

    def log_message(self, fmt, *args):
        sys.stderr.write(f"{time.strftime('%H:%M:%S')} {self.address_string()} {fmt % args}\n")

    def send_json(self, status: int, body: dict):
        raw = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(raw)))
        self.end_headers()
        self.wfile.write(raw)

    def authorized(self) -> bool:
        header = self.headers.get("Authorization", "")
        given = header[7:] if header.startswith("Bearer ") else ""
        if hmac.compare_digest(given, self.token):
            return True
        self.send_json(401, {"error": "Wrong or missing token"})
        return False

    def do_GET(self):
        if self.path != "/health":
            return self.send_json(404, {"error": "Not found"})
        if self.authorized():
            self.send_json(200, {"ok": True, "claude": bool(shutil.which("claude"))})

    def do_POST(self):
        if self.path != "/chat":
            return self.send_json(404, {"error": "Not found"})
        if not self.authorized():
            return
        length = int(self.headers.get("Content-Length") or 0)
        if not 0 < length <= MAX_BODY:
            return self.send_json(413, {"error": "Message is empty or too long"})
        try:
            body = json.loads(self.rfile.read(length))
            message = str(body["message"]).strip()
            session_id = body.get("session_id") or None
        except (ValueError, KeyError, TypeError):
            return self.send_json(400, {"error": "Expected JSON with a 'message' field"})
        if not message:
            return self.send_json(400, {"error": "Message is empty"})
        if not busy.acquire(timeout=5):
            return self.send_json(429, {"error": "The PC is busy with other messages, try again shortly"})
        try:
            self.send_json(200, run_claude(message, session_id))
        except subprocess.TimeoutExpired:
            self.send_json(504, {"error": "Claude Code took too long to answer"})
        except RuntimeError as e:
            self.send_json(502, {"error": str(e)})
        finally:
            busy.release()


def main():
    WORKSPACE.mkdir(parents=True, exist_ok=True)
    Handler.token = load_token()
    host = os.environ.get("BRIDGE_HOST")
    while not host:
        host = tailscale_ip()
        if not host:
            print("Waiting for Tailscale to connect...", flush=True)
            time.sleep(15)
    server = ThreadingHTTPServer((host, PORT), Handler)
    print(f"AI Computer bridge on http://{host}:{PORT}", flush=True)
    print(f"Token file: {TOKEN_FILE}", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
