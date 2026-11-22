"""Rebuild the visual candidate from the verified DEV15.65 pack."""
import hashlib
import json
import os
import re
import shutil
import struct
import sys
from pathlib import Path

root = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(root / ".github/five-mods"))
from pack_helpers import identity, unpack

baseline_sha = "b326e0984886a5f59235ed66c187bf17e0e13ae2062fc45390e34712ccb852ac"
web = (
    "index.html", "index.js", "index.wasm", "index.pck", "index.png",
    "index.icon.png", "index.apple-touch-icon.png", "index.audio.worklet.js",
    "index.audio.position.worklet.js",
)


def main(_engine, baseline, output):
    output.mkdir(parents=True, exist_ok=True)
    original = baseline.read_bytes()
    assert hashlib.sha256(original).hexdigest() == baseline_sha, "Requires the public DEV15.65 pack"
    base, entries = unpack(original)

    def raw(name):
        offset, size, *_ = entries[name]
        return original[base + offset:base + offset + size]

    replacements = {}
    for path in (
        "scripts/main.gd",
        "scripts/state/run_state.gd",
        "scripts/world/surface_world.gd",
        "scripts/ui/premium_menu.gd",
        "scripts/progression/mara_quests.gd",
    ):
        replacements[path] = (root / path).read_bytes()
        if path + ".remap" in entries:
            replacements[path + ".remap"] = f'[remap]\npath="res://{path}"\n'.encode()

    data = bytearray(original[:base])
    directory = {}
    for name in sorted(set(entries) | set(replacements)):
        payload = replacements[name] if name in replacements else raw(name)
        data += b"\0" * (-len(data) % 32)
        directory[name] = (len(data) - base, len(payload), hashlib.md5(payload).digest(), 0)
        data += payload
    struct.pack_into("<Q", data, 32, len(data))
    data += struct.pack("<I", len(directory))
    for name, entry in directory.items():
        key = name.encode()
        key += b"\0" * (-len(key) % 4)
        data += struct.pack("<I", len(key)) + key + struct.pack("<QQ16sI", *entry)
    out_base, out_entries = unpack(data)
    assert set(out_entries) == set(directory)
    for name, (offset, size, *_rest) in out_entries.items():
        expected = replacements[name] if name in replacements else raw(name)
        assert data[out_base + offset:out_base + offset + size] == expected, name
    (output / "index.pck").write_bytes(data)
    for name in web:
        if name != "index.pck":
            shutil.copyfile(baseline.parent / name, output / name)
    html_path = output / "index.html"
    html = html_path.read_text()
    config = re.search(r"const GODOT_CONFIG = (\{[^\r\n]+\});", html)
    assert config
    values = json.loads(config[1])
    assert not values["args"]
    values["fileSizes"]["index.pck"] = len(data)
    html_path.write_text(html[:config.start(1)] + json.dumps(values, separators=(",", ":")) + html[config.end(1):])
    manifest = {name: identity(output / name) for name in web}
    (output / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    receipt = {
        "source": os.environ.get("GITHUB_SHA"),
        "version": "1.0.0-dev.15.66",
        "baseline_pck": identity(baseline),
        "replaced": sorted(replacements),
        "retained_payloads_verified": True,
        "files": manifest,
    }
    (output / "qa-build-receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print(manifest["index.pck"])


if __name__ == "__main__":
    main(str(Path(sys.argv[1]).resolve()), Path(sys.argv[2]), Path(sys.argv[3]))
