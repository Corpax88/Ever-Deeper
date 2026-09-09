#!/usr/bin/env python3
"""Run authenticated task-local Xvfb and Godot in one process namespace."""
from __future__ import annotations

import argparse
import os
from pathlib import Path
import secrets
import socket
import struct
import subprocess
import tempfile
import time


def field(value: bytes) -> bytes:
    return struct.pack(">H", len(value)) + value


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True, type=Path)
    parser.add_argument("--xvfb", required=True, type=Path)
    parser.add_argument("--project", type=Path, default=Path.cwd())
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--resolution", default="2328x1260")
    parser.add_argument("--timeout", type=int, default=480)
    parser.add_argument("godot_args", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    env = os.environ.copy()
    # Main's ordinary startup initializes user:// before the opt-in fixture runs.
    # Isolate that first load as well as the fixture's explicit save file.
    env["XDG_DATA_HOME"] = str((args.output / "userdata").resolve())
    libraries = args.xvfb.resolve().parent.parent / "lib" / "x86_64-linux-gnu"
    env["LD_LIBRARY_PATH"] = str(libraries) + (":" + env["LD_LIBRARY_PATH"] if env.get("LD_LIBRARY_PATH") else "")
    env["LIBGL_ALWAYS_SOFTWARE"] = "1"
    display = 89
    env["DISPLAY"] = f"127.0.0.1:{display}"
    extra = args.godot_args
    if extra and extra[0] == "--":
        extra = extra[1:]
    with tempfile.TemporaryDirectory(prefix="ever-deeper-render-") as temporary:
        authority = Path(temporary) / "Xauthority"
        cookie = secrets.token_bytes(16)
        protocol = field(str(display).encode()) + field(b"MIT-MAGIC-COOKIE-1") + field(cookie)
        # Xlib can classify loopback TCP as the local hostname. Supply both
        # explicit identities with the same private cookie; authentication stays on.
        authority.write_bytes(
            struct.pack(">H", 0) + field(socket.inet_aton("127.0.0.1")) + protocol
            + struct.pack(">H", 256) + field(socket.gethostname().encode()) + protocol
        )
        authority.chmod(0o600)
        env["XAUTHORITY"] = str(authority)
        with (args.output / "xvfb.log").open("w") as server_log, (args.output / "godot.log").open("w") as game_log:
            server = subprocess.Popen(
                [str(args.xvfb), f":{display}", "-screen", "0", "2560x1440x24", "-nolisten", "unix", "-nolisten", "local", "-listen", "tcp", "-auth", str(authority), "-noreset"],
                env=env, stdout=server_log, stderr=subprocess.STDOUT,
            )
            try:
                deadline = time.monotonic() + 15
                ready = False
                while time.monotonic() < deadline and server.poll() is None:
                    try:
                        with socket.create_connection(("127.0.0.1", 6000 + display), timeout=0.2):
                            ready = True
                            break
                    except OSError:
                        time.sleep(0.1)
                if not ready:
                    print("Xvfb did not become ready; inspect", args.output / "xvfb.log")
                    return 2
                command = [str(args.godot), "--path", str(args.project.resolve()), "--display-driver", "x11", "--resolution", args.resolution, "--audio-driver", "Dummy"] + extra
                result = subprocess.run(command, env=env, stdout=game_log, stderr=subprocess.STDOUT, timeout=args.timeout)
                print("Godot exit:", result.returncode, "log:", args.output / "godot.log")
                return result.returncode
            except subprocess.TimeoutExpired:
                print("Rendered check timed out; inspect", args.output / "godot.log")
                return 124
            finally:
                server.terminate()
                try:
                    server.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    server.kill()
                    server.wait()


if __name__ == "__main__":
    raise SystemExit(main())
