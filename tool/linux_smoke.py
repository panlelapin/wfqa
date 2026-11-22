"""Run in a private D-Bus/X11 session; uses a disposable outbox and no API key."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time

binary = Path(sys.argv[1]).resolve()


def visible():
    return subprocess.run(
        ["xdotool", "search", "--onlyvisible", "--name", "^WorkFlowy Quick Add$"],
        capture_output=True, text=True,
    ).stdout.splitlines()


def until(check):
    deadline = time.monotonic() + 20
    while time.monotonic() < deadline:
        value = check()
        if value:
            return value
        time.sleep(0.1)
    raise RuntimeError(f"Window assertion timed out: {check}")


def type_text(window, text):
    subprocess.run(["xdotool", "windowfocus", "--sync", window], check=True)
    subprocess.run(["xdotool", "type", "--clearmodifiers", text], check=True)


with tempfile.TemporaryDirectory() as data:
    env = {**os.environ, "XDG_DATA_HOME": data, "GDK_BACKEND": "x11"}
    primary = subprocess.Popen([binary], env=env)
    try:
        first, = until(visible)
        type_text(first, "offline capture")
        subprocess.run(["xdotool", "key", "ctrl+Return"], check=True)
        until(lambda: not visible())
        assert primary.poll() is None, "Saving must not stop the process"
        queue = Path(data, "wf_quick_add", "outbox.json")
        original = json.loads(queue.read_text())
        assert [e["text"] for e in original["entries"]] == ["offline capture"]
        subprocess.run([binary], env=env, check=True, timeout=10)
        second, = until(visible)
        assert second == first, "Relaunch must reuse the single window"
        type_text(second, "discard me")
        subprocess.run(["xdotool", "key", "Escape"], check=True)
        until(lambda: not visible())
        assert primary.poll() is None
        assert json.loads(queue.read_text()) == original
    finally:
        if primary.poll() is None:
            primary.terminate()
        primary.wait(timeout=10)
